import 'package:drift/drift.dart';

import '../../../core/database/app_database.dart';
import '../../../core/utils/date_utils.dart';
import '../domain/item_usage.dart';
import '../domain/owned_item.dart';

/// Repository around the Drift database. All persistence details stay here.
class ItemRepository {
  ItemRepository(this._database);

  final AppDatabase _database;

  Stream<List<OwnedItem>> watchAll() {
    final query = _database.select(_database.itemEntries)
      ..orderBy([
        (row) => OrderingTerm.desc(row.purchaseDate),
        (row) => OrderingTerm.desc(row.createdAt),
      ]);
    return query.watch().map(
      (rows) => rows.map(_toDomain).toList(growable: false),
    );
  }

  Stream<OwnedItem?> watchById(String id) {
    final query = _database.select(_database.itemEntries)
      ..where((row) => row.id.equals(id));
    return query.watchSingleOrNull().map(
      (row) => row == null ? null : _toDomain(row),
    );
  }

  Future<OwnedItem?> findById(String id) async {
    final query = _database.select(_database.itemEntries)
      ..where((row) => row.id.equals(id));
    final row = await query.getSingleOrNull();
    return row == null ? null : _toDomain(row);
  }

  Future<List<OwnedItem>> getAll() async {
    final query = _database.select(_database.itemEntries)
      ..orderBy([(row) => OrderingTerm.asc(row.createdAt)]);
    final rows = await query.get();
    return rows.map(_toDomain).toList(growable: false);
  }

  Future<void> save(OwnedItem item) async {
    await _database
        .into(_database.itemEntries)
        .insertOnConflictUpdate(_toCompanion(item));
  }

  Future<void> deleteById(String id) async {
    await _database.transaction(() async {
      await (_database.delete(
        _database.usageEntries,
      )..where((row) => row.itemId.equals(id))).go();
      await (_database.delete(
        _database.itemEntries,
      )..where((row) => row.id.equals(id))).go();
    });
  }

  /// Every usage record, newest first.
  Stream<List<ItemUsage>> watchAllUsages() {
    final query = _database.select(_database.usageEntries)
      ..orderBy([
        (row) => OrderingTerm.desc(row.usedAt),
        (row) => OrderingTerm.desc(row.id),
      ]);
    return query.watch().map(
      (rows) => rows.map(_usageToDomain).toList(growable: false),
    );
  }

  /// Usage records of one item, newest first.
  Stream<List<ItemUsage>> watchUsagesForItem(String itemId) {
    final query = _database.select(_database.usageEntries)
      ..where((row) => row.itemId.equals(itemId))
      ..orderBy([
        (row) => OrderingTerm.desc(row.usedAt),
        (row) => OrderingTerm.desc(row.id),
      ]);
    return query.watch().map(
      (rows) => rows.map(_usageToDomain).toList(growable: false),
    );
  }

  Future<List<ItemUsage>> getAllUsages() async {
    final query = _database.select(_database.usageEntries)
      ..orderBy([(row) => OrderingTerm.asc(row.usedAt)]);
    final rows = await query.get();
    return rows.map(_usageToDomain).toList(growable: false);
  }

  Future<void> saveUsage(ItemUsage usage) async {
    await _database
        .into(_database.usageEntries)
        .insert(_usageToCompanion(usage));
  }

  Future<void> deleteUsageById(String id) async {
    await (_database.delete(
      _database.usageEntries,
    )..where((row) => row.id.equals(id))).go();
  }

  /// Replaces every item and usage record in one transaction. Used by backup
  /// restore.
  Future<void> replaceAll(
    List<OwnedItem> items, {
    List<ItemUsage> usages = const [],
  }) async {
    await _database.transaction(() async {
      await _database.delete(_database.usageEntries).go();
      await _database.delete(_database.itemEntries).go();
      for (final item in items) {
        await _database.into(_database.itemEntries).insert(_toCompanion(item));
      }
      for (final usage in usages) {
        await _database
            .into(_database.usageEntries)
            .insert(_usageToCompanion(usage));
      }
    });
  }

  /// Image paths currently referenced by any item.
  Future<Set<String>> referencedImagePaths() async {
    final query = _database.selectOnly(_database.itemEntries)
      ..addColumns([_database.itemEntries.imagePath])
      ..where(_database.itemEntries.imagePath.isNotNull());
    final rows = await query.get();
    return rows
        .map((row) => row.read(_database.itemEntries.imagePath))
        .whereType<String>()
        .toSet();
  }

  OwnedItem _toDomain(ItemRow row) {
    return OwnedItem(
      id: row.id,
      name: row.name,
      purchasePriceCents: row.purchasePriceCents,
      purchaseDate: parseIsoDate(row.purchaseDate),
      category: ItemCategory.fromId(row.category),
      imagePath: row.imagePath,
      targetDailyCostCents: row.targetDailyCostCents,
      status: ItemStatus.fromStorage(row.status),
      endDate: row.endDate == null ? null : parseIsoDate(row.endDate!),
      note: row.note,
      createdAt: row.createdAt.toUtc(),
      updatedAt: row.updatedAt.toUtc(),
    );
  }

  ItemUsage _usageToDomain(UsageRow row) {
    return ItemUsage(
      id: row.id,
      itemId: row.itemId,
      usedAt: row.usedAt.toUtc(),
    );
  }

  UsageEntriesCompanion _usageToCompanion(ItemUsage usage) {
    return UsageEntriesCompanion.insert(
      id: usage.id,
      itemId: usage.itemId,
      usedAt: usage.usedAt,
    );
  }

  ItemEntriesCompanion _toCompanion(OwnedItem item) {
    return ItemEntriesCompanion.insert(
      id: item.id,
      name: item.name,
      purchasePriceCents: item.purchasePriceCents,
      purchaseDate: formatIsoDate(item.purchaseDate),
      category: item.category.id,
      imagePath: Value(item.imagePath),
      targetDailyCostCents: Value(item.targetDailyCostCents),
      status: item.status.storageValue,
      endDate: Value(
        item.endDate == null ? null : formatIsoDate(item.endDate!),
      ),
      note: Value(item.note),
      createdAt: item.createdAt,
      updatedAt: item.updatedAt,
    );
  }
}
