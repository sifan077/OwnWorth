import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Owns the private app directories used by the database and item images.
class AppStorage {
  AppStorage.forRoot(this.rootDirectory);

  final Directory rootDirectory;

  Directory get imagesDirectory =>
      Directory(p.join(rootDirectory.path, 'images'));

  File get databaseFile => File(p.join(rootDirectory.path, 'ownworth.sqlite'));

  Directory get backupDirectory =>
      Directory(p.join(rootDirectory.path, 'backups'));

  static Future<AppStorage> initialize() async {
    final support = await getApplicationSupportDirectory();
    final root = Directory(p.join(support.path, 'ownworth'));
    final storage = AppStorage.forRoot(root);
    await storage.ensureDirectories();
    return storage;
  }

  Future<void> ensureDirectories() async {
    await rootDirectory.create(recursive: true);
    await imagesDirectory.create(recursive: true);
    await backupDirectory.create(recursive: true);
  }
}
