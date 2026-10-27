import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ownworth/app/theme/app_theme.dart';
import 'package:ownworth/core/database/app_database.dart';
import 'package:ownworth/core/providers.dart';
import 'package:ownworth/core/storage/image_store.dart';
import 'package:ownworth/features/items/data/item_repository.dart';
import 'package:ownworth/features/items/domain/owned_item.dart';
import 'package:ownworth/features/items/presentation/home_page.dart';

import '../helpers/fixtures.dart';

void main() {
  late Directory tempDirectory;
  late AppDatabase database;
  late ItemRepository repository;
  late ImageStore imageStore;
  final today = DateTime.utc(2026, 10, 25);

  setUp(() async {
    tempDirectory = await Directory.systemTemp.createTemp('ownworth_widget_');
    final imagesDirectory = Directory('${tempDirectory.path}/images');
    await imagesDirectory.create(recursive: true);
    imageStore = ImageStore(imagesDirectory);
    database = AppDatabase(NativeDatabase.memory());
    repository = ItemRepository(database);
  });

  tearDown(() async {
    await database.close();
    if (await tempDirectory.exists()) {
      await tempDirectory.delete(recursive: true);
    }
  });

  Future<void> pumpHome(WidgetTester tester) async {
    tester.view.physicalSize = const Size(900, 1800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWithValue(database),
          imageStoreProvider.overrideWithValue(imageStore),
          todayProvider.overrideWithValue(today),
        ],
        child: MaterialApp(
          theme: AppTheme.light,
          locale: const Locale('zh', 'CN'),
          supportedLocales: const [Locale('zh', 'CN')],
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: const HomePage(),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> disposeHome(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 10));
    await tester.pump(const Duration(milliseconds: 10));
  }

  testWidgets('empty state guides the first item', (tester) async {
    await pumpHome(tester);

    expect(find.text('值回票价'), findsOneWidget);
    expect(find.text('从第一件物品开始'), findsOneWidget);
    expect(find.text('添加第一件物品'), findsOneWidget);
    expect(find.text('日均成本合计'), findsOneWidget);
    await disposeHome(tester);
  });

  testWidgets('shows cards and overview values', (tester) async {
    await repository.save(
      buildItem(
        id: 'coffee',
        name: '咖啡机',
        purchasePriceCents: 300000,
        purchaseDate: DateTime.utc(2026, 9, 1),
        category: ItemCategory.appliance,
        targetDailyCostCents: 1000,
      ),
    );
    await repository.save(
      buildItem(
        id: 'coat',
        name: '羊毛大衣',
        purchasePriceCents: 80000,
        purchaseDate: DateTime.utc(2026, 1, 1),
        category: ItemCategory.clothing,
        status: ItemStatus.ended,
        endDate: DateTime.utc(2026, 2, 1),
      ),
    );
    await repository.saveUsage(
      buildUsage(
        id: 'coffee-1',
        itemId: 'coffee',
        usedAt: DateTime.utc(2026, 10, 20, 8),
      ),
    );
    await repository.saveUsage(
      buildUsage(
        id: 'coffee-2',
        itemId: 'coffee',
        usedAt: DateTime.utc(2026, 9, 20, 8),
      ),
    );
    await pumpHome(tester);

    expect(find.text('咖啡机'), findsOneWidget);
    expect(find.text('羊毛大衣'), findsOneWidget);
    expect(find.text('日均成本合计'), findsOneWidget);
    expect(find.text('累计购入'), findsOneWidget);
    expect(find.text('目标进度'), findsNWidgets(2));
    expect(find.text('已达成'), findsNothing);
    expect(find.text('使用统计'), findsOneWidget);
    expect(find.text('使用 2 次'), findsOneWidget);
    expect(find.text('次均 '), findsOneWidget);
    expect(find.text('¥1,500.00'), findsOneWidget);
    expect(find.text('未记录使用'), findsNothing);
    await disposeHome(tester);
  });

  testWidgets('hides usage figures until a use is recorded', (tester) async {
    await repository.save(
      buildItem(
        id: 'desk',
        name: '书桌',
        purchasePriceCents: 120000,
        purchaseDate: DateTime.utc(2026, 9, 1),
        category: ItemCategory.home,
      ),
    );
    await pumpHome(tester);

    expect(find.text('书桌'), findsOneWidget);
    expect(find.text('日均成本合计'), findsOneWidget);
    expect(find.text('使用统计'), findsNothing);
    expect(find.text('未记录使用'), findsNothing);
    expect(find.text('次均 '), findsNothing);
    await disposeHome(tester);
  });

  testWidgets('search filters the list', (tester) async {
    await repository.save(
      buildItem(
        id: 'earphones',
        name: 'Sony 耳机',
        purchaseDate: DateTime.utc(2026, 10, 20),
      ),
    );
    await repository.save(
      buildItem(
        id: 'coffee',
        name: '咖啡机',
        category: ItemCategory.appliance,
        purchasePriceCents: 100000,
        purchaseDate: DateTime.utc(2026, 9, 1),
      ),
    );
    await pumpHome(tester);

    await tester.enterText(find.byType(TextField), '咖啡');
    await tester.pumpAndSettle();

    expect(find.text('咖啡机'), findsOneWidget);
    expect(find.text('Sony 耳机'), findsNothing);
    await disposeHome(tester);
  });

  testWidgets('deleting and editing records refreshes the list', (
    tester,
  ) async {
    await repository.save(
      buildItem(
        id: 'earphones',
        name: 'Sony 耳机',
        purchasePriceCents: 300000,
        purchaseDate: DateTime.utc(2026, 10, 20),
      ),
    );
    await repository.save(
      buildItem(
        id: 'coffee',
        name: '咖啡机',
        category: ItemCategory.appliance,
        purchasePriceCents: 100000,
        purchaseDate: DateTime.utc(2026, 9, 1),
      ),
    );
    await pumpHome(tester);

    await repository.deleteById('coffee');
    await tester.pumpAndSettle();
    expect(find.text('咖啡机'), findsNothing);
    expect(find.text('Sony 耳机'), findsOneWidget);

    final item = await repository.findById('earphones');
    await repository.save(item!.copyWith(purchasePriceCents: 600000));
    await tester.pumpAndSettle();
    expect(find.text('¥6,000.00'), findsWidgets);
    await disposeHome(tester);
  });
}
