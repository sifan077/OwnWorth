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
import 'package:ownworth/features/items/presentation/item_form_page.dart';

void main() {
  late Directory tempDirectory;
  late AppDatabase database;
  late ImageStore imageStore;

  setUp(() async {
    tempDirectory = await Directory.systemTemp.createTemp('ownworth_form_');
    final imagesDirectory = Directory('${tempDirectory.path}/images');
    await imagesDirectory.create(recursive: true);
    imageStore = ImageStore(imagesDirectory);
    database = AppDatabase(NativeDatabase.memory());
  });

  tearDown(() async {
    await database.close();
    if (await tempDirectory.exists()) {
      await tempDirectory.delete(recursive: true);
    }
  });

  testWidgets('add form renders all fields and is scrollable', (tester) async {
    tester.view.physicalSize = const Size(1080, 2424);
    tester.view.devicePixelRatio = 2.625;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWithValue(database),
          imageStoreProvider.overrideWithValue(imageStore),
          todayProvider.overrideWithValue(DateTime.utc(2026, 10, 25)),
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
          home: const ItemFormScaffold(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('添加物品'), findsWidgets);
    expect(find.text('物品名称'), findsOneWidget);
    expect(find.text('购买价格'), findsOneWidget);
    expect(find.text('购买日期'), findsOneWidget);
    expect(find.text('保存'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('备注（可选）'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('备注（可选）'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 10));
  });
}
