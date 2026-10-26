import 'package:flutter_test/flutter_test.dart';
import 'package:ownworth/core/utils/money.dart';

void main() {
  group('parseYuanToCents', () {
    test('parses integer and decimal amounts exactly', () {
      expect(parseYuanToCents('3000'), 300000);
      expect(parseYuanToCents('3000.5'), 300050);
      expect(parseYuanToCents('3000.50'), 300050);
      expect(parseYuanToCents('0.01'), 1);
      expect(parseYuanToCents(' 12.34 '), 1234);
      expect(parseYuanToCents('¥1,234.56'), 123456);
    });

    test('rejects zero, negative, malformed and over-precise amounts', () {
      expect(parseYuanToCents('0'), isNull);
      expect(parseYuanToCents('0.00'), isNull);
      expect(parseYuanToCents('-1'), isNull);
      expect(parseYuanToCents('12.345'), isNull);
      expect(parseYuanToCents('abc'), isNull);
      expect(parseYuanToCents(''), isNull);
      expect(parseYuanToCents('1000000000'), isNull);
    });
  });

  group('formatting', () {
    test('formats cents with grouping and two decimals', () {
      expect(formatYuan(300000), '¥3,000.00');
      expect(formatYuan(852), '¥8.52');
      expect(formatYuan(123456789), '¥1,234,567.89');
      expect(formatYuan(0), '¥0.00');
    });

    test('rounds derived daily costs to display precision only', () {
      expect(formatDailyCost(852.4), '¥8.52');
      expect(formatDailyCost(852.5), '¥8.53');
      expect(formatDailyCost(1000), '¥10.00');
    });

    test('renders editable yuan input with exactly two decimals', () {
      expect(yuanInputFromCents(300050), '3000.50');
      expect(yuanInputFromCents(1), '0.01');
    });

    test('formats progress with one decimal', () {
      expect(formatProgressPercent(0.587), '58.7%');
      expect(formatProgressPercent(1), '100.0%');
      expect(formatProgressPercent(-1), '0.0%');
    });
  });
}
