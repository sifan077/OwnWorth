import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ownworth/core/database/app_database.dart';
import 'package:ownworth/features/items/data/item_repository.dart';
import 'package:ownworth/features/items/domain/cost_calculations.dart';
import 'package:ownworth/features/items/domain/owned_item.dart';

import '../helpers/fixtures.dart';

void main() {
  late Directory tempDirectory;
  late File databaseFile;
  late AppDatabase database;
  late ItemRepository repository;

  AppDatabase openDatabase() {
    return AppDatabase(NativeDatabase(databaseFile));
  }

  setUp(() async {
    tempDirectory = await Directory.systemTemp.createTemp('ownworth_db_');
    databaseFile = File('${tempDirectory.path}/ownworth.sqlite');
    database = openDatabase();
    repository = ItemRepository(database);
  });

  tearDown(() async {
    await database.close();
    if (await tempDirectory.exists()) {
      await tempDirectory.delete(recursive: true);
    }
  });

  test('saves and reads every field', () async {
    final purchaseDate = DateTime.utc(2025, 3, 18);
    final endDate = DateTime.utc(2026, 1, 2);
    final createdAt = DateTime.utc(2025, 3, 18, 12, 30);
    final updatedAt = DateTime.utc(2026, 1, 2, 9, 15);
    final item = buildItem(
      id: 'full-item',
      name: '测试相机',
      purchasePriceCents: 499999,
      purchaseDate: purchaseDate,
      category: ItemCategory.entertainment,
      imagePath: 'images/example.jpg',
      targetDailyCostCents: 500,
      status: ItemStatus.ended,
      endDate: endDate,
      note: '含 24-70 镜头',
      createdAt: createdAt,
      updatedAt: updatedAt,
    );

    await repository.save(item);
    final loaded = await repository.findById('full-item');

    expect(loaded, isNotNull);
    expect(loaded!.id, item.id);
    expect(loaded.name, item.name);
    expect(loaded.purchasePriceCents, item.purchasePriceCents);
    expect(loaded.purchaseDate, purchaseDate);
    expect(loaded.category, ItemCategory.entertainment);
    expect(loaded.imagePath, 'images/example.jpg');
    expect(loaded.targetDailyCostCents, 500);
    expect(loaded.status, ItemStatus.ended);
    expect(loaded.endDate, endDate);
    expect(loaded.note, '含 24-70 镜头');
    expect(loaded.createdAt, createdAt);
    expect(loaded.updatedAt, updatedAt);
  });

  test('data survives closing and reopening the database', () async {
    await repository.save(
      buildItem(
        id: 'persistent',
        name: '机械键盘',
        purchasePriceCents: 89900,
        targetDailyCostCents: 100,
      ),
    );
    await database.close();

    database = openDatabase();
    repository = ItemRepository(database);
    final items = await repository.getAll();

    expect(items, hasLength(1));
    expect(items.single.name, '机械键盘');
    expect(items.single.purchasePriceCents, 89900);
    expect(items.single.targetDailyCostCents, 100);
  });

  test('streaming list refreshes after edit and delete', () async {
    final item = buildItem(
      id: 'streamed',
      purchaseDate: DateTime.utc(2026, 10, 1),
    );
    await repository.save(item);

    final edits = expectLater(
      repository.watchAll(),
      emitsThrough(
        predicate<List<OwnedItem>>(
          (items) =>
              items.length == 1 && items.single.purchasePriceCents == 500000,
        ),
      ),
    );
    await repository.save(item.copyWith(purchasePriceCents: 500000));
    await edits;

    final deletions = expectLater(
      repository.watchAll(),
      emitsThrough(predicate<List<OwnedItem>>((items) => items.isEmpty)),
    );
    await repository.deleteById('streamed');
    await deletions;
  });

  test('overview is recalculated from edited values', () async {
    await repository.save(
      buildItem(
        id: 'stats',
        purchaseDate: DateTime.utc(2026, 10, 20),
        purchasePriceCents: 300000,
      ),
    );
    var items = await repository.getAll();
    var overview = summarizeItems(items, DateTime.utc(2026, 10, 25));
    expect(overview.activeDailyCostCents, 50000);

    final loaded = await repository.findById('stats');
    await repository.save(
      loaded!.copyWith(
        purchasePriceCents: 600000,
        purchaseDate: DateTime.utc(2026, 10, 21),
      ),
    );
    items = await repository.getAll();
    overview = summarizeItems(items, DateTime.utc(2026, 10, 25));
    expect(overview.totalPurchaseCents, 600000);
    expect(overview.activeDailyCostCents, 120000);

    await repository.deleteById('stats');
    items = await repository.getAll();
    overview = summarizeItems(items, DateTime.utc(2026, 10, 25));
    expect(items, isEmpty);
    expect(overview.totalCount, 0);
    expect(overview.totalPurchaseCents, 0);
    expect(overview.activeDailyCostCents, 0);
  });

  test('replaceAll is transactional', () async {
    await repository.save(buildItem(id: 'original', name: '原有物品'));
    final duplicate = buildItem(id: 'duplicate', name: 'A');
    final duplicateAgain = buildItem(id: 'duplicate', name: 'B');

    await expectLater(
      repository.replaceAll([duplicate, duplicateAgain]),
      throwsA(anything),
    );

    final items = await repository.getAll();
    expect(items, hasLength(1));
    expect(items.single.name, '原有物品');
  });

  test('returns referenced image paths for cleanup', () async {
    await repository.save(buildItem(id: 'a', imagePath: 'images/a.jpg'));
    await repository.save(buildItem(id: 'b', name: 'B'));
    final paths = await repository.referencedImagePaths();
    expect(paths, {'images/a.jpg'});
  });

  test('stores usage records newest first per item', () async {
    await repository.save(buildItem(id: 'a'));
    await repository.save(buildItem(id: 'b', name: 'B'));
    await repository.saveUsage(
      buildUsage(
        id: 'first',
        itemId: 'a',
        usedAt: DateTime.utc(2026, 10, 1, 8),
      ),
    );
    await repository.saveUsage(
      buildUsage(
        id: 'second',
        itemId: 'a',
        usedAt: DateTime.utc(2026, 10, 2, 8),
      ),
    );
    await repository.saveUsage(
      buildUsage(
        id: 'other',
        itemId: 'b',
        usedAt: DateTime.utc(2026, 10, 3, 8),
      ),
    );

    final forItem = await repository.watchUsagesForItem('a').first;
    expect(forItem.map((usage) => usage.id), ['second', 'first']);
    expect(forItem.first.usedAt, DateTime.utc(2026, 10, 2, 8));

    final all = await repository.getAllUsages();
    expect(all.map((usage) => usage.id), ['first', 'second', 'other']);

    await repository.deleteUsageById('second');
    expect(
      (await repository.watchUsagesForItem('a').first).map((usage) => usage.id),
      ['first'],
    );
  });

  test('deleting an item deletes its usage records only', () async {
    await repository.save(buildItem(id: 'a'));
    await repository.save(buildItem(id: 'b', name: 'B'));
    await repository.saveUsage(buildUsage(id: 'a1', itemId: 'a'));
    await repository.saveUsage(buildUsage(id: 'b1', itemId: 'b'));

    await repository.deleteById('a');

    final usages = await repository.getAllUsages();
    expect(usages.map((usage) => usage.id), ['b1']);
  });

  test('replaceAll replaces items and usage records together', () async {
    await repository.save(buildItem(id: 'old'));
    await repository.saveUsage(buildUsage(id: 'old-use', itemId: 'old'));

    await repository.replaceAll(
      [buildItem(id: 'new', name: '新物品')],
      usages: [buildUsage(id: 'new-use', itemId: 'new')],
    );

    final items = await repository.getAll();
    expect(items.map((item) => item.id), ['new']);
    final usages = await repository.getAllUsages();
    expect(usages.map((usage) => usage.id), ['new-use']);
  });

  test('rejects a usage record for a missing item', () async {
    await expectLater(
      repository.saveUsage(buildUsage(id: 'orphan', itemId: 'missing')),
      throwsA(anything),
    );
  });
}
