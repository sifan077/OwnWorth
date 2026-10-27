import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ownworth/app/theme/app_theme.dart';
import 'package:ownworth/core/utils/date_utils.dart';
import 'package:ownworth/core/widgets/date_picker_sheet.dart';

void main() {
  final today = DateTime.utc(2026, 10, 25);

  Future<DateTime? Function()> pumpLauncher(
    WidgetTester tester, {
    required DateTime firstDate,
    required DateTime lastDate,
    DateTime? initialDate,
  }) async {
    DateTime? result;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        locale: const Locale('zh', 'CN'),
        supportedLocales: const [Locale('zh', 'CN')],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: Scaffold(
          body: Builder(
            builder: (context) {
              return Center(
                child: FilledButton(
                  onPressed: () async {
                    result = await showAppDatePicker(
                      context: context,
                      initialDate: initialDate ?? today,
                      firstDate: firstDate,
                      lastDate: lastDate,
                      title: '选择购买日期',
                      description: '不能晚于今天。',
                      referenceDate: today,
                      previewBuilder: (date) =>
                          describeHoldingPeriod(date, today),
                    );
                  },
                  child: const Text('打开'),
                ),
              );
            },
          ),
        ),
      ),
    );
    await tester.tap(find.text('打开'));
    await tester.pumpAndSettle();
    return () => result;
  }

  testWidgets('opens on the day grid of the selected month', (tester) async {
    await pumpLauncher(
      tester,
      firstDate: DateTime.utc(1980, 1, 1),
      lastDate: today,
    );

    expect(find.text('选择购买日期'), findsOneWidget);
    expect(find.text('2026年'), findsOneWidget);
    expect(find.text('10月'), findsOneWidget);
    expect(find.text('25'), findsOneWidget);
    expect(find.text('今天购入'), findsOneWidget);
    // Year and month pickers stay hidden until asked for.
    expect(find.text('选择年份'), findsNothing);
    expect(find.text('1月'), findsNothing);
  });

  testWidgets('year crumb opens the year grid and picking a year returns', (
    tester,
  ) async {
    final read = await pumpLauncher(
      tester,
      firstDate: DateTime.utc(1980, 1, 1),
      lastDate: today,
    );

    await tester.tap(find.text('2026年'));
    await tester.pumpAndSettle();

    expect(find.text('2015年'), findsOneWidget);
    expect(find.text('1月'), findsNothing);

    await tester.tap(find.text('2015年'));
    await tester.pumpAndSettle();

    // Back on the day grid, same month, new year.
    expect(find.text('2015年'), findsOneWidget);
    expect(find.text('10月'), findsOneWidget);

    await tester.tap(find.text('15'));
    await tester.pumpAndSettle();

    expect(read(), DateTime.utc(2015, 10, 15));
  });

  testWidgets('month crumb shows all twelve months at once', (tester) async {
    final read = await pumpLauncher(
      tester,
      firstDate: DateTime.utc(1980, 1, 1),
      lastDate: today,
    );

    await tester.tap(find.text('10月'));
    await tester.pumpAndSettle();

    expect(find.text('1月'), findsOneWidget);
    expect(find.text('6月'), findsOneWidget);
    expect(find.text('12月'), findsOneWidget);

    await tester.tap(find.text('3月'));
    await tester.pumpAndSettle();

    expect(find.text('3月'), findsOneWidget);

    await tester.tap(find.text('15'));
    await tester.pumpAndSettle();

    expect(read(), DateTime.utc(2026, 3, 15));
  });

  testWidgets('tapping the expanded year crumb collapses it', (tester) async {
    final read = await pumpLauncher(
      tester,
      firstDate: DateTime.utc(1980, 1, 1),
      lastDate: today,
    );

    await tester.tap(find.text('2026年'));
    await tester.pumpAndSettle();
    expect(find.text('1月'), findsNothing);

    // The header crumb comes before the grid in the tree.
    await tester.tap(find.text('2026年').first);
    await tester.pumpAndSettle();

    expect(find.text('10月'), findsOneWidget);
    expect(find.text('25'), findsOneWidget);
    expect(read(), isNull);
  });

  testWidgets('days outside the range cannot be selected', (tester) async {
    final read = await pumpLauncher(
      tester,
      firstDate: DateTime.utc(2026, 10, 10),
      lastDate: today,
    );

    await tester.tap(find.text('5'));
    await tester.pumpAndSettle();
    expect(read(), isNull);

    await tester.tap(find.text('12'));
    await tester.pumpAndSettle();
    expect(read(), DateTime.utc(2026, 10, 12));
  });

  testWidgets('out-of-range initial dates are clamped', (tester) async {
    await pumpLauncher(
      tester,
      firstDate: DateTime.utc(2026, 1, 1),
      lastDate: today,
      initialDate: DateTime.utc(2027, 3, 1),
    );

    expect(find.text('2026年'), findsOneWidget);
    expect(find.text('10月'), findsOneWidget);
    expect(find.text('今天购入'), findsOneWidget);
  });

  testWidgets('lays out without overflow on a narrow phone', (tester) async {
    tester.view.physicalSize = const Size(360 * 3, 640 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await pumpLauncher(
      tester,
      firstDate: DateTime.utc(2020, 1, 1),
      lastDate: today,
    );

    expect(tester.takeException(), isNull);

    await tester.tap(find.text('2026年'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    await tester.tap(find.text('2025年'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    await tester.tap(find.text('10月'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
