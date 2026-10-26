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

  testWidgets('quick picks return a calendar day and hide out-of-range ones', (
    tester,
  ) async {
    final read = await pumpLauncher(
      tester,
      firstDate: DateTime.utc(2026, 9, 1),
      lastDate: today,
    );

    expect(find.text('选择购买日期'), findsOneWidget);
    expect(find.text('2026年10月25日'), findsOneWidget);
    expect(find.text('今天购入'), findsOneWidget);
    // 1 周前 is inside the range, 3 个月前 / 半年前 / 1 年前 are not.
    expect(find.text('1 周前'), findsOneWidget);
    expect(find.text('3 个月前'), findsNothing);
    expect(find.text('半年前'), findsNothing);

    await tester.tap(find.text('1 周前'));
    await tester.pumpAndSettle();

    expect(read(), DateTime.utc(2026, 10, 18));
  });

  testWidgets('calendar entry point is reachable from the sheet', (
    tester,
  ) async {
    await pumpLauncher(
      tester,
      firstDate: DateTime.utc(2026, 1, 1),
      lastDate: today,
    );

    await tester.tap(find.text('在日历中选择'));
    await tester.pumpAndSettle();

    expect(find.text('确定'), findsOneWidget);
    expect(find.text('取消'), findsOneWidget);
  });

  testWidgets('out-of-range initial dates are clamped', (tester) async {
    await pumpLauncher(
      tester,
      firstDate: DateTime.utc(2026, 1, 1),
      lastDate: today,
      initialDate: DateTime.utc(2027, 3, 1),
    );

    expect(find.text('2026年10月25日'), findsOneWidget);
    expect(find.text('今天购入'), findsOneWidget);
  });
}
