import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';

import '../../features/items/data/item_repository.dart';
import '../../features/items/domain/item_usage.dart';
import '../../features/items/domain/owned_item.dart';
import '../storage/image_store.dart';
import '../utils/date_utils.dart';
import '../utils/money.dart';

/// A validated, in-memory backup ready to be restored.
class BackupContents {
  BackupContents({
    required this.preview,
    required List<OwnedItem> items,
    required List<ItemUsage> usages,
    required Map<String, Uint8List> images,
  }) : items = List.unmodifiable(items),
       usages = List.unmodifiable(usages),
       images = Map.unmodifiable(images);

  final BackupPreview preview;
  final List<OwnedItem> items;
  final List<ItemUsage> usages;

  /// Keys are app-relative paths such as `images/abc.jpg`.
  final Map<String, Uint8List> images;
}

class BackupPreview {
  const BackupPreview({
    required this.exportedAt,
    required this.itemCount,
    required this.imageCount,
    required this.usageCount,
    required this.appVersion,
  });

  final DateTime exportedAt;
  final int itemCount;
  final int imageCount;
  final int usageCount;
  final String? appVersion;
}

/// Creates and restores versioned ZIP backups.
class BackupService {
  BackupService(
    this._repository,
    this._imageStore, {
    DateTime Function()? clock,
  }) : _clock = clock ?? DateTime.now;

  final ItemRepository _repository;
  final ImageStore _imageStore;
  final DateTime Function() _clock;

  static const String format = 'ownworth-backup';
  static const int formatVersion = 2;

  /// Version 1 backups contain items and images but no usage records.
  static const int minFormatVersion = 1;
  static const int maxArchiveBytes = 200 * 1024 * 1024;
  static const int maxImageBytes = 25 * 1024 * 1024;
  static const int maxTotalImageBytes = 300 * 1024 * 1024;
  static const int maxItems = 10000;
  static const int maxUsages = 200000;
  static const int maxManifestBytes = 5 * 1024 * 1024;

  Future<Uint8List> exportBackup({required String appVersion}) async {
    final items = await _repository.getAll();
    final usages = await _repository.getAllUsages();
    final images = <String, Uint8List>{};

    for (final item in items) {
      final imagePath = item.imagePath;
      if (imagePath == null) {
        continue;
      }
      if (!ImageStore.isValidRelativePath(imagePath)) {
        throw BackupException('物品「${item.name}」的图片路径无效，无法备份。');
      }
      if (images.containsKey(imagePath)) {
        continue;
      }
      try {
        final bytes = await _imageStore.read(imagePath);
        if (bytes.isEmpty) {
          throw BackupException('物品「${item.name}」的图片为空，无法备份。');
        }
        images[imagePath] = bytes;
      } on ImageStoreException {
        throw BackupException('物品「${item.name}」的图片文件缺失，无法导出完整备份。');
      }
    }

    final manifest = <String, Object?>{
      'format': format,
      'formatVersion': formatVersion,
      'appVersion': appVersion,
      'exportedAt': _clock().toUtc().toIso8601String(),
      'itemCount': items.length,
      'imageCount': images.length,
      'usageCount': usages.length,
      'items': items.map(_itemToJson).toList(growable: false),
      'usages': usages.map(_usageToJson).toList(growable: false),
    };

    final archive = Archive();
    archive.add(
      ArchiveFile.string(
        'manifest.json',
        const JsonEncoder.withIndent('  ').convert(manifest),
      ),
    );
    for (final entry in images.entries) {
      archive.add(ArchiveFile.bytes(entry.key, entry.value));
    }

    try {
      final encoded = ZipEncoder().encode(archive);
      return Uint8List.fromList(encoded);
    } catch (error) {
      throw BackupException('生成备份文件失败：$error');
    }
  }

  /// Fully validates a backup without modifying the database or images.
  Future<BackupContents> inspectBackup(Uint8List bytes) async {
    if (bytes.isEmpty) {
      throw const BackupException('备份文件为空。');
    }
    if (bytes.length > maxArchiveBytes) {
      throw const BackupException('备份文件过大，无法导入。');
    }

    try {
      final archive = ZipDecoder().decodeBytes(bytes);
      final entries = <String, ArchiveFile>{};
      for (final file in archive.files) {
        final name = file.name;
        if (!file.isFile) {
          throw const BackupException('备份文件中包含无效的目录条目。');
        }
        if (name.contains('..') ||
            name.contains(r'\') ||
            name.startsWith('/')) {
          throw const BackupException('备份文件包含不安全的路径。');
        }
        if (entries.containsKey(name)) {
          throw const BackupException('备份文件包含重复条目。');
        }
        if (name != 'manifest.json' && !ImageStore.isValidRelativePath(name)) {
          throw const BackupException('备份文件包含未知内容。');
        }
        entries[name] = file;
      }

      final manifestFile = entries.remove('manifest.json');
      if (manifestFile == null) {
        throw const BackupException('备份缺少 manifest.json。');
      }
      if (manifestFile.size > maxManifestBytes) {
        throw const BackupException('备份清单过大。');
      }
      final manifestBytes = _readEntry(manifestFile, maxManifestBytes);
      final dynamic decoded;
      try {
        decoded = jsonDecode(utf8.decode(manifestBytes));
      } on FormatException {
        throw const BackupException('备份清单不是有效的 JSON。');
      }
      if (decoded is! Map<String, dynamic>) {
        throw const BackupException('备份清单格式错误。');
      }

      if (decoded['format'] != format) {
        throw const BackupException('不支持的备份格式或版本。');
      }
      final version = decoded['formatVersion'];
      if (version is! int ||
          version < minFormatVersion ||
          version > formatVersion) {
        throw const BackupException('不支持的备份格式或版本。');
      }

      final exportedAt = _readInstant(decoded['exportedAt'], '备份时间');
      final appVersionValue = decoded['appVersion'];
      final appVersion = appVersionValue is String ? appVersionValue : null;

      final rawItems = decoded['items'];
      if (rawItems is! List) {
        throw const BackupException('备份清单缺少物品列表。');
      }
      if (rawItems.length > maxItems) {
        throw const BackupException('备份中的物品数量超出限制。');
      }
      final declaredItemCount = decoded['itemCount'];
      if (declaredItemCount is int && declaredItemCount != rawItems.length) {
        throw const BackupException('备份物品数量与清单不一致。');
      }

      final today = currentLocalDate(_clock());
      final items = <OwnedItem>[];
      final ids = <String>{};
      final referencedImages = <String>{};

      for (var index = 0; index < rawItems.length; index++) {
        final raw = rawItems[index];
        if (raw is! Map<String, dynamic>) {
          throw BackupException('第 ${index + 1} 件物品的数据格式错误。');
        }
        final item = _itemFromJson(raw, index: index, today: today);
        if (!ids.add(item.id)) {
          throw const BackupException('备份中存在重复的物品 ID。');
        }
        items.add(item);
        if (item.imagePath != null) {
          referencedImages.add(item.imagePath!);
        }
      }

      final rawUsages = decoded['usages'];
      final usages = <ItemUsage>[];
      if (rawUsages != null) {
        if (rawUsages is! List) {
          throw const BackupException('备份清单中的使用记录格式错误。');
        }
        if (rawUsages.length > maxUsages) {
          throw const BackupException('备份中的使用记录数量超出限制。');
        }
        final usageIds = <String>{};
        for (var index = 0; index < rawUsages.length; index++) {
          final raw = rawUsages[index];
          if (raw is! Map<String, dynamic>) {
            throw BackupException('第 ${index + 1} 条使用记录的数据格式错误。');
          }
          final usage = _usageFromJson(
            raw,
            index: index,
            exportedAt: exportedAt,
          );
          if (!ids.contains(usage.itemId)) {
            throw BackupException('第 ${index + 1} 条使用记录关联的物品不存在。');
          }
          if (!usageIds.add(usage.id)) {
            throw const BackupException('备份中存在重复的使用记录 ID。');
          }
          usages.add(usage);
        }
      }
      final declaredUsageCount = decoded['usageCount'];
      if (declaredUsageCount is int && declaredUsageCount != usages.length) {
        throw const BackupException('备份使用记录数量与清单不一致。');
      }

      final images = <String, Uint8List>{};
      var totalImageBytes = 0;
      for (final entry in referencedImages) {
        final file = entries.remove(entry);
        if (file == null) {
          throw BackupException('备份缺少图片：${ImageStore.fileNameOf(entry)}');
        }
        if (file.size > maxImageBytes) {
          throw const BackupException('备份中的单张图片过大。');
        }
        totalImageBytes += file.size;
        if (totalImageBytes > maxTotalImageBytes) {
          throw const BackupException('备份中的图片总量过大。');
        }
        final imageBytes = _readEntry(file, maxImageBytes);
        if (imageBytes.isEmpty) {
          throw const BackupException('备份中包含空图片。');
        }
        images[entry] = imageBytes;
      }

      if (entries.isNotEmpty) {
        throw const BackupException('备份中存在未被物品引用的图片。');
      }

      final declaredImageCount = decoded['imageCount'];
      if (declaredImageCount is int && declaredImageCount != images.length) {
        throw const BackupException('备份图片数量与清单不一致。');
      }

      final preview = BackupPreview(
        exportedAt: exportedAt,
        itemCount: items.length,
        imageCount: images.length,
        usageCount: usages.length,
        appVersion: appVersion,
      );
      return BackupContents(
        preview: preview,
        items: items,
        usages: usages,
        images: images,
      );
    } on BackupException {
      rethrow;
    } on ArchiveException catch (error) {
      throw BackupException('无法读取备份文件，文件可能已损坏。${error.message}');
    } catch (error) {
      throw BackupException('备份文件校验失败：$error');
    }
  }

  /// Restores a previously validated backup and runs the database replacement
  /// inside a transaction. Images are rolled back if the DB transaction fails.
  Future<void> restoreBackup(BackupContents contents) async {
    await _imageStore.replaceAll(contents.images, () {
      return _repository.replaceAll(contents.items, usages: contents.usages);
    });
  }

  Uint8List _readEntry(ArchiveFile file, int maxBytes) {
    if (file.size > maxBytes) {
      throw const BackupException('备份中的文件过大。');
    }
    final bytes = file.readBytes();
    if (bytes == null) {
      throw const BackupException('无法读取备份中的文件。');
    }
    if (bytes.length > maxBytes) {
      throw const BackupException('备份中的文件解压后超出大小限制。');
    }
    final expectedCrc = file.crc32;
    if (expectedCrc != null && getCrc32(bytes) != expectedCrc) {
      throw const BackupException('备份文件校验失败（CRC 不一致）。');
    }
    return bytes;
  }

  Map<String, Object?> _itemToJson(OwnedItem item) {
    return {
      'id': item.id,
      'name': item.name,
      'purchasePriceCents': item.purchasePriceCents,
      'purchaseDate': formatIsoDate(item.purchaseDate),
      'category': item.category.id,
      'imagePath': item.imagePath,
      'targetDailyCostCents': item.targetDailyCostCents,
      'status': item.status.storageValue,
      'endDate': item.endDate == null ? null : formatIsoDate(item.endDate!),
      'note': item.note,
      'createdAt': item.createdAt.toUtc().toIso8601String(),
      'updatedAt': item.updatedAt.toUtc().toIso8601String(),
    };
  }

  OwnedItem _itemFromJson(
    Map<String, dynamic> json, {
    required int index,
    required DateTime today,
  }) {
    final prefix = '第 ${index + 1} 件物品';
    final id = _readString(json['id'], '$prefix的 ID');
    if (id.isEmpty || id.length > 64) {
      throw BackupException('$prefix的 ID 无效。');
    }
    final name = _readString(json['name'], '$prefix的名称');
    if (name.trim().isEmpty || name.length > 200) {
      throw BackupException('$prefix的名称无效。');
    }

    final price = _readPositiveInt(json['purchasePriceCents'], '$prefix的价格');
    if (price > maxAmountCents) {
      throw BackupException('$prefix的价格超出范围。');
    }

    final purchaseDate = _parseDate(json['purchaseDate'], '$prefix的购买日期');
    if (purchaseDate.isAfter(today)) {
      throw BackupException('$prefix的购买日期晚于今天。');
    }

    final categoryId = _readString(json['category'], '$prefix的分类');
    ItemCategory? category;
    for (final value in ItemCategory.values) {
      if (value.id == categoryId) {
        category = value;
        break;
      }
    }
    if (category == null) {
      throw BackupException('$prefix的分类未知。');
    }

    final statusValue = _readString(json['status'], '$prefix的状态');
    final ItemStatus status;
    if (statusValue == ItemStatus.active.storageValue) {
      status = ItemStatus.active;
    } else if (statusValue == ItemStatus.ended.storageValue) {
      status = ItemStatus.ended;
    } else {
      throw BackupException('$prefix的状态无效。');
    }

    DateTime? endDate;
    if (json['endDate'] != null) {
      endDate = _parseDate(json['endDate'], '$prefix的结束日期');
      if (endDate.isBefore(purchaseDate)) {
        throw BackupException('$prefix的结束日期早于购买日期。');
      }
      if (endDate.isAfter(today)) {
        throw BackupException('$prefix的结束日期晚于今天。');
      }
    }
    if (status == ItemStatus.ended && endDate == null) {
      throw BackupException('$prefix已结束，但缺少结束日期。');
    }
    if (status == ItemStatus.active && endDate != null) {
      throw BackupException('$prefix尚未结束，但包含结束日期。');
    }

    int? targetDailyCostCents;
    if (json['targetDailyCostCents'] != null) {
      targetDailyCostCents = _readPositiveInt(
        json['targetDailyCostCents'],
        '$prefix的目标日均成本',
      );
    }

    String? imagePath;
    if (json['imagePath'] != null) {
      imagePath = _readString(json['imagePath'], '$prefix的图片路径');
      if (!ImageStore.isValidRelativePath(imagePath)) {
        throw BackupException('$prefix的图片路径无效。');
      }
    }

    String? note;
    if (json['note'] != null) {
      note = _readString(json['note'], '$prefix的备注');
      if (note.length > 1000) {
        throw BackupException('$prefix的备注过长。');
      }
    }

    final createdAt = _readInstant(json['createdAt'], '$prefix的创建时间');
    final updatedAt = _readInstant(json['updatedAt'], '$prefix的修改时间');
    if (updatedAt.isBefore(createdAt)) {
      throw BackupException('$prefix的修改时间早于创建时间。');
    }

    return OwnedItem(
      id: id,
      name: name,
      purchasePriceCents: price,
      purchaseDate: purchaseDate,
      category: category,
      imagePath: imagePath,
      targetDailyCostCents: targetDailyCostCents,
      status: status,
      endDate: endDate,
      note: note,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  Map<String, Object?> _usageToJson(ItemUsage usage) {
    return {
      'id': usage.id,
      'itemId': usage.itemId,
      'usedAt': usage.usedAt.toUtc().toIso8601String(),
    };
  }

  ItemUsage _usageFromJson(
    Map<String, dynamic> json, {
    required int index,
    required DateTime exportedAt,
  }) {
    final prefix = '第 ${index + 1} 条使用记录';
    final id = _readString(json['id'], '$prefix的 ID');
    if (id.isEmpty || id.length > 64) {
      throw BackupException('$prefix的 ID 无效。');
    }
    final itemId = _readString(json['itemId'], '$prefix的物品 ID');
    if (itemId.isEmpty || itemId.length > 64) {
      throw BackupException('$prefix的物品 ID 无效。');
    }
    final usedAt = _readInstant(json['usedAt'], '$prefix的时间');
    if (usedAt.isAfter(exportedAt)) {
      throw BackupException('$prefix的时间晚于备份时间。');
    }
    return ItemUsage(id: id, itemId: itemId, usedAt: usedAt);
  }

  String _readString(Object? value, String label) {
    if (value is! String) {
      throw BackupException('$label格式错误。');
    }
    return value;
  }

  int _readPositiveInt(Object? value, String label) {
    if (value is! int || value <= 0) {
      throw BackupException('$label必须是正整数。');
    }
    return value;
  }

  DateTime _parseDate(Object? value, String label) {
    if (value is! String) {
      throw BackupException('$label格式错误。');
    }
    try {
      return parseIsoDate(value);
    } on FormatException {
      throw BackupException('$label不是有效日期。');
    }
  }

  DateTime _readInstant(Object? value, String label) {
    if (value is! String) {
      throw BackupException('$label格式错误。');
    }
    final parsed = DateTime.tryParse(value);
    if (parsed == null) {
      throw BackupException('$label格式错误。');
    }
    return parsed.toUtc();
  }
}

class BackupException implements Exception {
  const BackupException(this.message);

  final String message;

  @override
  String toString() => message;
}
