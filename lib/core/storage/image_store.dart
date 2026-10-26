import 'dart:io';
import 'dart:typed_data';

import 'package:path/path.dart' as p;
import 'package:uuid/uuid.dart';

/// Stores item images inside the app's private support directory.
///
/// Callers only persist paths like `images/<file>`. That keeps the database
/// portable and avoids depending on temporary paths returned by image_picker.
class ImageStore {
  ImageStore(this.imagesDirectory);

  final Directory imagesDirectory;

  static const String relativePrefix = 'images/';
  static final RegExp _fileNamePattern = RegExp(
    r'^[A-Za-z0-9][A-Za-z0-9._-]{0,127}$',
  );
  static const Set<String> _allowedExtensions = {
    '.jpg',
    '.jpeg',
    '.png',
    '.webp',
    '.heic',
    '.gif',
  };

  static bool isValidRelativePath(String path) {
    if (!path.startsWith(relativePrefix)) {
      return false;
    }
    final fileName = path.substring(relativePrefix.length);
    return fileName.isNotEmpty &&
        !fileName.contains('/') &&
        !fileName.contains(r'\') &&
        _fileNamePattern.hasMatch(fileName);
  }

  static String fileNameOf(String relativePath) {
    if (!isValidRelativePath(relativePath)) {
      throw const FormatException('无效的图片路径');
    }
    return relativePath.substring(relativePrefix.length);
  }

  File fileFor(String relativePath) {
    return File(p.join(imagesDirectory.path, fileNameOf(relativePath)));
  }

  bool exists(String relativePath) {
    try {
      return fileFor(relativePath).existsSync();
    } on FormatException {
      return false;
    }
  }

  Future<String> saveBytes(
    Uint8List bytes, {
    required String sourceName,
  }) async {
    if (bytes.isEmpty) {
      throw const ImageStoreException('图片内容为空');
    }
    await imagesDirectory.create(recursive: true);
    final rawExtension = p.extension(sourceName).toLowerCase();
    final extension = _allowedExtensions.contains(rawExtension)
        ? rawExtension
        : '.jpg';
    final fileName = '${const Uuid().v4()}$extension';
    final file = File(p.join(imagesDirectory.path, fileName));
    await file.writeAsBytes(bytes, flush: true);
    return '$relativePrefix$fileName';
  }

  Future<Uint8List> read(String relativePath) async {
    final file = fileFor(relativePath);
    if (!await file.exists()) {
      throw ImageStoreException('图片文件不存在：$relativePath');
    }
    return file.readAsBytes();
  }

  Future<void> delete(String? relativePath) async {
    if (relativePath == null) {
      return;
    }
    final file = fileFor(relativePath);
    if (await file.exists()) {
      await file.delete();
    }
  }

  /// Removes images no longer referenced by an item row.
  Future<void> deleteUnreferenced(Iterable<String> referencedPaths) async {
    if (!await imagesDirectory.exists()) {
      return;
    }
    final referencedNames = <String>{};
    for (final path in referencedPaths) {
      if (isValidRelativePath(path)) {
        referencedNames.add(fileNameOf(path));
      }
    }
    await for (final entity in imagesDirectory.list(followLinks: false)) {
      if (entity is! File) {
        continue;
      }
      if (!referencedNames.contains(p.basename(entity.path))) {
        try {
          await entity.delete();
        } on FileSystemException {
          // A later cleanup can retry; failing to remove an orphan should not
          // prevent the app from opening.
        }
      }
    }
  }

  /// Recovers from an import interrupted by process termination.
  Future<void> recoverInterruptedOperations() async {
    await imagesDirectory.parent.create(recursive: true);
    final parent = imagesDirectory.parent;
    final backups = <Directory>[];
    final staging = <Directory>[];

    await for (final entity in parent.list(followLinks: false)) {
      if (entity is! Directory) {
        continue;
      }
      final name = p.basename(entity.path);
      if (name.startsWith('.images_backup_')) {
        backups.add(entity);
      } else if (name.startsWith('.images_staging_')) {
        staging.add(entity);
      }
    }

    if (!await imagesDirectory.exists() && backups.isNotEmpty) {
      backups.sort(
        (a, b) => b.statSync().modified.compareTo(a.statSync().modified),
      );
      final newest = backups.removeAt(0);
      try {
        await newest.rename(imagesDirectory.path);
      } on FileSystemException {
        // Leave the backup on disk; the caller can still continue with an
        // empty image directory.
      }
    }

    for (final directory in [...backups, ...staging]) {
      try {
        await directory.delete(recursive: true);
      } on FileSystemException {
        // Best effort only.
      }
    }
    await imagesDirectory.create(recursive: true);
  }

  /// Atomically replaces the image directory and then runs [commit].
  ///
  /// The previous directory is restored if [commit] fails. This is used by
  /// backup import so the database and referenced images stay consistent.
  Future<void> replaceAll(
    Map<String, Uint8List> images,
    Future<void> Function() commit,
  ) async {
    for (final entry in images.entries) {
      if (!isValidRelativePath(entry.key)) {
        throw const FormatException('备份中包含无效的图片路径');
      }
      if (entry.value.isEmpty) {
        throw const ImageStoreException('备份中包含空图片');
      }
    }

    await imagesDirectory.parent.create(recursive: true);
    final suffix =
        '${DateTime.now().microsecondsSinceEpoch}_${const Uuid().v4()}';
    final staging = Directory(
      p.join(imagesDirectory.parent.path, '.images_staging_$suffix'),
    );
    Directory? previous;
    final oldDirectory = Directory(imagesDirectory.path);

    try {
      await staging.create(recursive: true);
      for (final entry in images.entries) {
        final file = File(p.join(staging.path, fileNameOf(entry.key)));
        await file.writeAsBytes(entry.value, flush: true);
      }

      if (await oldDirectory.exists()) {
        previous = Directory(
          p.join(imagesDirectory.parent.path, '.images_backup_$suffix'),
        );
        await oldDirectory.rename(previous.path);
      }

      await staging.rename(imagesDirectory.path);
      await commit();

      if (previous != null && await previous.exists()) {
        try {
          await previous.delete(recursive: true);
        } on FileSystemException {
          // The restored data is already valid. A stale backup can be removed
          // the next time the app starts.
        }
      }
    } catch (_) {
      try {
        if (await imagesDirectory.exists()) {
          await imagesDirectory.delete(recursive: true);
        }
        if (previous != null && await previous.exists()) {
          await previous.rename(imagesDirectory.path);
        }
        if (await staging.exists()) {
          await staging.delete(recursive: true);
        }
      } on FileSystemException {
        // Preserve the original failure below.
      }
      rethrow;
    } finally {
      if (await staging.exists()) {
        try {
          await staging.delete(recursive: true);
        } on FileSystemException {
          // Best effort.
        }
      }
      await imagesDirectory.create(recursive: true);
    }
  }
}

class ImageStoreException implements Exception {
  const ImageStoreException(this.message);

  final String message;

  @override
  String toString() => message;
}
