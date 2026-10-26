import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ownworth/core/backup/backup_service.dart';
import 'package:ownworth/core/database/app_database.dart';
import 'package:ownworth/core/storage/image_store.dart';
import 'package:ownworth/features/items/data/item_repository.dart';
import 'package:ownworth/features/items/domain/owned_item.dart';

import '../helpers/fixtures.dart';

void main() {
  late Directory tempDirectory;
  late AppDatabase database;
  late ItemRepository repository;
  late ImageStore imageStore;
  late BackupService service;

  final fixedNow = DateTime.utc(2026, 10, 25, 10, 30);

  setUp(() async {
    tempDirectory = await Directory.systemTemp.createTemp('ownworth_backup_');
    final imagesDirectory = Directory('${tempDirectory.path}/images');
    await imagesDirectory.create(recursive: true);
    imageStore = ImageStore(imagesDirectory);
    database = AppDatabase(NativeDatabase.memory());
    repository = ItemRepository(database);
    service = BackupService(repository, imageStore, clock: () => fixedNow);
  });

  tearDown(() async {
    await database.close();
    if (await tempDirectory.exists()) {
      await tempDirectory.delete(recursive: true);
    }
  });

  Future<OwnedItem> seedData() async {
    final imagePath = await imageStore.saveBytes(
      Uint8List.fromList([137, 80, 78, 71, 1, 2, 3, 4]),
      sourceName: 'camera.png',
    );
    final item = buildItem(
      id: 'camera',
      name: '旅行相机',
      purchasePriceCents: 499999,
      purchaseDate: DateTime.utc(2025, 3, 18),
      category: ItemCategory.digital,
      imagePath: imagePath,
      targetDailyCostCents: 500,
      note: '含镜头和电池',
      createdAt: DateTime.utc(2025, 3, 18, 3, 4, 5),
      updatedAt: DateTime.utc(2026, 1, 2, 4, 5, 6),
    );
    await repository.save(item);
    await repository.save(
      buildItem(
        id: 'coat',
        name: '羊毛大衣',
        purchasePriceCents: 89900,
        purchaseDate: DateTime.utc(2025, 11, 11),
        category: ItemCategory.clothing,
        status: ItemStatus.ended,
        endDate: DateTime.utc(2026, 3, 1),
        createdAt: DateTime.utc(2025, 11, 11, 1, 2, 3),
        updatedAt: DateTime.utc(2026, 3, 1, 2, 3, 4),
      ),
    );
    await repository.saveUsage(
      buildUsage(
        id: 'camera-use-1',
        itemId: 'camera',
        usedAt: DateTime.utc(2025, 6, 1, 9),
      ),
    );
    await repository.saveUsage(
      buildUsage(
        id: 'camera-use-2',
        itemId: 'camera',
        usedAt: DateTime.utc(2026, 10, 1, 9),
      ),
    );
    await repository.saveUsage(
      buildUsage(
        id: 'coat-use-1',
        itemId: 'coat',
        usedAt: DateTime.utc(2026, 2, 1, 9),
      ),
    );
    return item;
  }

  test('exports and restores records and images consistently', () async {
    final original = await seedData();
    final bytes = await service.exportBackup(appVersion: '1.0.0 (1)');

    final contents = await service.inspectBackup(bytes);
    expect(contents.preview.itemCount, 2);
    expect(contents.preview.imageCount, 1);
    expect(contents.preview.usageCount, 3);
    expect(contents.preview.appVersion, '1.0.0 (1)');
    expect(contents.preview.exportedAt, fixedNow);

    // Replace local state with different data before restoring.
    await repository.replaceAll([buildItem(id: 'temporary', name: '临时记录')]);
    await imageStore.replaceAll({
      'images/other.jpg': Uint8List.fromList([7, 7, 7]),
    }, () async {});

    await service.restoreBackup(contents);

    final restored = await repository.getAll();
    expect(restored, hasLength(2));
    final camera = restored.firstWhere((item) => item.id == 'camera');
    expect(camera.name, original.name);
    expect(camera.purchasePriceCents, original.purchasePriceCents);
    expect(camera.purchaseDate, original.purchaseDate);
    expect(camera.category, original.category);
    expect(camera.targetDailyCostCents, original.targetDailyCostCents);
    expect(camera.note, original.note);
    expect(camera.createdAt, original.createdAt);
    expect(camera.updatedAt, original.updatedAt);
    expect(camera.imagePath, original.imagePath);
    expect(await imageStore.read(camera.imagePath!), originalImageBytes);

    final coat = restored.firstWhere((item) => item.id == 'coat');
    expect(coat.status, ItemStatus.ended);
    expect(coat.endDate, DateTime.utc(2026, 3, 1));

    final usages = await repository.getAllUsages();
    expect(usages.map((usage) => usage.id), [
      'camera-use-1',
      'coat-use-1',
      'camera-use-2',
    ]);
    expect(usages.first.usedAt, DateTime.utc(2025, 6, 1, 9));
    expect(usages.first.itemId, 'camera');

    expect(imageStore.exists('images/other.jpg'), isFalse);
  });

  test('restoring an empty backup removes all records and images', () async {
    await seedData();
    await repository.replaceAll([]);
    await imageStore.replaceAll({}, () async {});
    final emptyBytes = await service.exportBackup(appVersion: '1.0.0');
    final contents = await service.inspectBackup(emptyBytes);

    await seedData();
    await service.restoreBackup(contents);

    expect(await repository.getAll(), isEmpty);
    final files = await Directory('${tempDirectory.path}/images')
        .list()
        .toList();
    expect(files.whereType<File>(), isEmpty);
  });

  test('rejects corrupt archives without touching current data', () async {
    await seedData();
    final bytes = await service.exportBackup(appVersion: '1.0.0');
    final corrupted = Uint8List.fromList(bytes);
    corrupted[corrupted.length ~/ 2] ^= 0xFF;

    await expectLater(
      service.inspectBackup(corrupted),
      throwsA(isA<BackupException>()),
    );
    expect(await repository.getAll(), hasLength(2));
    expect(
      await imageStore.read('images/${_imageName(await repository.getAll())}'),
      originalImageBytes,
    );
  });

  test('rejects a backup that references a missing image', () async {
    await seedData();
    final bytes = await service.exportBackup(appVersion: '1.0.0');
    final invalid = await _rewriteManifest(bytes, (manifest) {
      final items = manifest['items'] as List;
      (items.first as Map<String, dynamic>)['imagePath'] = 'images/missing.jpg';
      return manifest;
    });

    await expectLater(
      service.inspectBackup(invalid),
      throwsA(
        isA<BackupException>().having(
          (error) => error.message,
          'message',
          contains('缺少图片'),
        ),
      ),
    );
  });

  test('rejects an unknown format version', () async {
    await seedData();
    final bytes = await service.exportBackup(appVersion: '1.0.0');
    final invalid = await _rewriteManifest(bytes, (manifest) {
      manifest['formatVersion'] = 99;
      return manifest;
    });

    await expectLater(
      service.inspectBackup(invalid),
      throwsA(isA<BackupException>()),
    );
  });

  test('rejects future purchase dates and invalid statuses', () async {
    await seedData();
    final bytes = await service.exportBackup(appVersion: '1.0.0');
    final invalid = await _rewriteManifest(bytes, (manifest) {
      final items = manifest['items'] as List;
      (items.first as Map<String, dynamic>)['purchaseDate'] = '2027-01-01';
      return manifest;
    });

    await expectLater(
      service.inspectBackup(invalid),
      throwsA(isA<BackupException>()),
    );
  });

  test('imports version 1 backups without usage records', () async {
    await seedData();
    final bytes = await service.exportBackup(appVersion: '1.0.0');
    final versionOne = await _rewriteManifest(bytes, (manifest) {
      manifest['formatVersion'] = 1;
      manifest.remove('usages');
      manifest.remove('usageCount');
      return manifest;
    });

    final contents = await service.inspectBackup(versionOne);
    expect(contents.usages, isEmpty);
    expect(contents.preview.usageCount, 0);

    await service.restoreBackup(contents);
    expect(await repository.getAll(), hasLength(2));
    expect(await repository.getAllUsages(), isEmpty);
  });

  test('rejects usage records that reference a missing item', () async {
    await seedData();
    final bytes = await service.exportBackup(appVersion: '1.0.0');
    final invalid = await _rewriteManifest(bytes, (manifest) {
      final usages = manifest['usages'] as List;
      (usages.first as Map<String, dynamic>)['itemId'] = 'missing';
      return manifest;
    });

    await expectLater(
      service.inspectBackup(invalid),
      throwsA(
        isA<BackupException>().having(
          (error) => error.message,
          'message',
          contains('物品不存在'),
        ),
      ),
    );
  });

  test('rejects usage records later than the backup time', () async {
    await seedData();
    final bytes = await service.exportBackup(appVersion: '1.0.0');
    final invalid = await _rewriteManifest(bytes, (manifest) {
      final usages = manifest['usages'] as List;
      (usages.first as Map<String, dynamic>)['usedAt'] = fixedNow
          .add(const Duration(minutes: 1))
          .toIso8601String();
      return manifest;
    });

    await expectLater(
      service.inspectBackup(invalid),
      throwsA(
        isA<BackupException>().having(
          (error) => error.message,
          'message',
          contains('晚于备份时间'),
        ),
      ),
    );
  });
}

final Uint8List originalImageBytes = Uint8List.fromList([
  137,
  80,
  78,
  71,
  1,
  2,
  3,
  4,
]);

String _imageName(List<OwnedItem> items) {
  final path = items.firstWhere((item) => item.imagePath != null).imagePath!;
  return ImageStore.fileNameOf(path);
}

Future<Uint8List> _rewriteManifest(
  Uint8List backup,
  Map<String, dynamic> Function(Map<String, dynamic> manifest) update,
) async {
  final archive = ZipDecoder().decodeBytes(backup);
  final entries = <String, Uint8List>{};
  for (final file in archive.files) {
    final bytes = file.readBytes();
    if (bytes != null) {
      entries[file.name] = bytes;
    }
  }
  final manifestBytes = entries.remove('manifest.json')!;
  final manifest =
      jsonDecode(utf8.decode(manifestBytes)) as Map<String, dynamic>;
  final updated = update(manifest);
  final result = Archive()
    ..add(ArchiveFile.string('manifest.json', jsonEncode(updated)));
  for (final entry in entries.entries) {
    result.add(ArchiveFile.bytes(entry.key, entry.value));
  }
  return Uint8List.fromList(ZipEncoder().encode(result));
}
