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
import 'package:ownworth/features/items/presentation/item_detail_page.dart';

import '../helpers/fixtures.dart';

void main() {
  late Directory tempDirectory;
  late AppDatabase database;
  late ItemRepository repository;
  late ImageStore imageStore;
  final today = DateTime.utc(2026, 10, 25);

  setUp(() async {
    tempDirectory = await Directory.systemTemp.createTemp('ownworth_detail_');
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

  Future<void> pumpDetail(WidgetTester tester, String itemId) async {
    tester.view.physicalSize = const Size(1080, 2424);
    tester.view.devicePixelRatio = 2.625;
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
          home: ItemDetailPage(itemId: itemId),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> disposeDetail(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 10));
    await tester.pump(const Duration(milliseconds: 10));
  }

  testWidgets('shows target progress and supports end and re-enable', (
    tester,
  ) async {
    await repository.save(
      buildItem(
        id: 'detail-item',
        name: '降噪耳机',
        purchasePriceCents: 300000,
        purchaseDate: DateTime.utc(2026, 9, 1),
        targetDailyCostCents: 1000,
      ),
    );
    await pumpDetail(tester, 'detail-item');

    expect(find.text('降噪耳机'), findsOneWidget);
    expect(find.text('当前日均成本'), findsOneWidget);
    expect(find.text('目标日均成本'), findsOneWidget);
    expect(find.text('18.3%'), findsOneWidget);
    // No usage recorded yet, so per-use figures stay hidden.
    expect(find.text('累计使用'), findsNothing);
    expect(find.text('单次使用成本'), findsNothing);
    expect(find.text('本月使用'), findsNothing);
    expect(find.text('最近一次'), findsNothing);

    await tester.scrollUntilVisible(
      find.text('结束使用'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('结束使用'));
    await tester.pumpAndSettle();
    expect(find.text('结束使用'), findsWidgets);
    await tester.tap(find.text('确认结束'));
    await tester.pumpAndSettle();

    var stored = await repository.findById('detail-item');
    expect(stored!.status, ItemStatus.ended);
    expect(stored.endDate, today);

    // Let the confirmation snackbar disappear before tapping the action bar
    // behind it.
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('重新启用'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('重新启用'), findsOneWidget);

    await tester.tap(find.text('重新启用'));
    await tester.pumpAndSettle();
    expect(find.text('重新启用？'), findsOneWidget);
    await tester.tap(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.widgetWithText(FilledButton, '重新启用'),
      ),
    );
    await tester.pumpAndSettle();

    stored = await repository.findById('detail-item');
    expect(stored!.status, ItemStatus.active);
    expect(stored.endDate, isNull);

    await disposeDetail(tester);
  });

  testWidgets('records and undoes usage', (tester) async {
    await repository.save(
      buildItem(
        id: 'used-item',
        name: '通勤自行车',
        purchasePriceCents: 300000,
        purchaseDate: DateTime.utc(2026, 9, 1),
      ),
    );
    await repository.saveUsage(
      buildUsage(
        id: 'use-1',
        itemId: 'used-item',
        usedAt: DateTime(2026, 10, 20, 10).toUtc(),
      ),
    );
    await repository.saveUsage(
      buildUsage(
        id: 'use-2',
        itemId: 'used-item',
        usedAt: DateTime(2026, 9, 15, 10).toUtc(),
      ),
    );
    await pumpDetail(tester, 'used-item');

    await tester.scrollUntilVisible(
      find.text('使用统计'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('使用统计'), findsOneWidget);
    expect(find.text('本月使用'), findsOneWidget);
    expect(find.text('最近一次'), findsOneWidget);
    expect(find.text('¥1,500.00'), findsOneWidget);

    await tester.tap(find.text('用一次'));
    await tester.pumpAndSettle();
    expect(find.text('已记录一次使用'), findsOneWidget);
    expect(await repository.getAllUsages(), hasLength(3));

    // Let the snackbar clear before tapping the undo action.
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text('撤销最近一次'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('撤销最近一次'));
    await tester.pumpAndSettle();
    expect(find.text('已撤销最近一次使用记录'), findsOneWidget);
    expect(await repository.getAllUsages(), hasLength(2));

    await disposeDetail(tester);
  });
}
