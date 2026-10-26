import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ownworth/core/database/app_database.dart';
import 'package:sqlite3/sqlite3.dart';

/// The database shipped with version 1 had only the items table.
void main() {
  late Directory tempDirectory;
  late File databaseFile;

  setUp(() async {
    tempDirectory = await Directory.systemTemp.createTemp(
      'ownworth_migration_',
    );
    databaseFile = File('${tempDirectory.path}/ownworth.sqlite');
  });

  tearDown(() async {
    if (await tempDirectory.exists()) {
      await tempDirectory.delete(recursive: true);
    }
  });

  void createVersionOneDatabase() {
    final raw = sqlite3.open(databaseFile.path);
    try {
      raw.execute('''
        CREATE TABLE items (
          id TEXT NOT NULL PRIMARY KEY,
          name TEXT NOT NULL,
          purchase_price_cents INTEGER NOT NULL,
          purchase_date TEXT NOT NULL,
          category TEXT NOT NULL,
          image_path TEXT NULL,
          target_daily_cost_cents INTEGER NULL,
          status TEXT NOT NULL,
          end_date TEXT NULL,
          note TEXT NULL,
          created_at INTEGER NOT NULL,
          updated_at INTEGER NOT NULL
        );
      ''');
      raw.execute('PRAGMA user_version = 1');
      raw.execute(
        '''
        INSERT INTO items (
          id, name, purchase_price_cents, purchase_date, category,
          image_path, target_daily_cost_cents, status, end_date, note,
          created_at, updated_at
        ) VALUES (?, ?, ?, ?, ?, NULL, NULL, ?, NULL, NULL, ?, ?)
        ''',
        [
          'legacy-item',
          '旧相机',
          499999,
          '2025-03-18',
          'digital',
          'ACTIVE',
          1742265600,
          1742265600,
        ],
      );
    } finally {
      raw.close();
    }
  }

  test('upgrading a version 1 database keeps items and adds usage', () async {
    createVersionOneDatabase();

    final database = AppDatabase(NativeDatabase(databaseFile));
    addTearDown(database.close);

    final items = await database.select(database.itemEntries).get();
    expect(items, hasLength(1));
    expect(items.single.id, 'legacy-item');
    expect(items.single.name, '旧相机');
    expect(items.single.purchasePriceCents, 499999);

    await database
        .into(database.usageEntries)
        .insert(
          UsageEntriesCompanion.insert(
            id: 'legacy-usage',
            itemId: 'legacy-item',
            usedAt: DateTime.utc(2026, 10, 20, 9),
          ),
        );

    final usages = await database.select(database.usageEntries).get();
    expect(usages, hasLength(1));
    expect(usages.single.itemId, 'legacy-item');
    expect(usages.single.usedAt.toUtc(), DateTime.utc(2026, 10, 20, 9));
  });
}
