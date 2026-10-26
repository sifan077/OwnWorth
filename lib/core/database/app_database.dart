import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';

part 'app_database.g.dart';

/// SQLite table for all tracked possessions.
@DataClassName('ItemRow')
class ItemEntries extends Table {
  @override
  String get tableName => 'items';

  TextColumn get id => text()();
  TextColumn get name => text()();
  IntColumn get purchasePriceCents => integer()();
  // Calendar dates are stored as ISO-8601 text so they can never shift by a
  // day when the database is read in a different time zone.
  TextColumn get purchaseDate => text()();
  TextColumn get category => text()();
  TextColumn get imagePath => text().nullable()();
  IntColumn get targetDailyCostCents => integer().nullable()();
  TextColumn get status => text()();
  TextColumn get endDate => text().nullable()();
  TextColumn get note => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

/// One recorded use of an item.
///
/// Records are kept in their own table so usage history can be shown and
/// corrected one entry at a time. The foreign key removes a record when its
/// item is deleted.
@DataClassName('UsageRow')
class UsageEntries extends Table {
  @override
  String get tableName => 'item_usages';

  TextColumn get id => text()();
  TextColumn get itemId =>
      text().references(ItemEntries, #id, onDelete: KeyAction.cascade)();
  DateTimeColumn get usedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DriftDatabase(tables: [ItemEntries, UsageEntries])
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.executor);

  /// Opens the app database in a background isolate.
  factory AppDatabase.open(File file) {
    return AppDatabase(NativeDatabase.createInBackground(file));
  }

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (migrator) async {
        await migrator.createAll();
      },
      onUpgrade: (migrator, from, to) async {
        if (from < 2) {
          await migrator.createTable(usageEntries);
        }
      },
      beforeOpen: (details) async {
        await customStatement('PRAGMA foreign_keys = ON');
        if (details.wasCreated) {
          await customStatement('PRAGMA journal_mode = WAL');
        }
      },
    );
  }
}
