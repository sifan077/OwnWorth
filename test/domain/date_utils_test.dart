import 'package:flutter_test/flutter_test.dart';
import 'package:ownworth/core/utils/date_utils.dart';

void main() {
  group('calendar dates', () {
    test('normalizes time away without shifting the day', () {
      final value = DateTime(2026, 10, 25, 23, 59, 59);
      expect(normalizeDate(value), DateTime.utc(2026, 10, 25));
    });

    test('today purchase day is day one', () {
      expect(
        daysBetweenCalendar(
              DateTime.utc(2026, 10, 25),
              DateTime.utc(2026, 10, 25),
            ) +
            1,
        1,
      );
    });

    test('computes natural calendar days across month boundaries', () {
      expect(
        daysBetweenCalendar(
              DateTime.utc(2026, 2, 27),
              DateTime.utc(2026, 3, 2),
            ) +
            1,
        4,
      );
    });

    test('handles leap years', () {
      expect(
        daysBetweenCalendar(
              DateTime.utc(2028, 2, 28),
              DateTime.utc(2028, 3, 1),
            ) +
            1,
        3,
      );
      expect(
        addCalendarDays(DateTime.utc(2028, 2, 28), 1),
        DateTime.utc(2028, 2, 29),
      );
    });

    test('handles year boundaries', () {
      expect(
        daysBetweenCalendar(
              DateTime.utc(2025, 12, 31),
              DateTime.utc(2026, 1, 2),
            ) +
            1,
        3,
      );
    });

    test('strict ISO parser rejects rollover dates', () {
      expect(parseIsoDate('2024-02-29'), DateTime.utc(2024, 2, 29));
      expect(() => parseIsoDate('2025-02-29'), throwsFormatException);
      expect(() => parseIsoDate('2025-13-01'), throwsFormatException);
      expect(() => parseIsoDate('2025/01/01'), throwsFormatException);
    });

    test('formats dates in ISO and Chinese forms', () {
      expect(formatIsoDate(DateTime.utc(2026, 3, 8)), '2026-03-08');
      expect(formatChineseDate(DateTime.utc(2026, 3, 8)), '2026年3月8日');
    });
  });

  group('date picker helpers', () {
    test('adds calendar months without rolling over short months', () {
      expect(
        addCalendarMonths(DateTime.utc(2026, 1, 31), 1),
        DateTime.utc(2026, 2, 28),
      );
      expect(
        addCalendarMonths(DateTime.utc(2028, 1, 31), 1),
        DateTime.utc(2028, 2, 29),
      );
      expect(
        addCalendarMonths(DateTime.utc(2026, 3, 31), -1),
        DateTime.utc(2026, 2, 28),
      );
      expect(
        addCalendarMonths(DateTime.utc(2026, 1, 15), -13),
        DateTime.utc(2024, 12, 15),
      );
    });

    test('converts containers to local dates for the calendar picker', () {
      final local = toLocalDate(DateTime.utc(2026, 10, 25));
      expect(local.isUtc, isFalse);
      expect((local.year, local.month, local.day), (2026, 10, 25));
    });

    test('clamps dates into the allowed range', () {
      final first = DateTime.utc(2020, 1, 1);
      final last = DateTime.utc(2026, 10, 25);
      expect(clampCalendarDate(DateTime.utc(2019, 5, 5), first, last), first);
      expect(clampCalendarDate(DateTime.utc(2027, 1, 1), first, last), last);
      expect(
        clampCalendarDate(DateTime(2026, 10, 20, 18), first, last),
        DateTime.utc(2026, 10, 20),
      );
    });

    test('describes day offsets and holding periods', () {
      final today = DateTime.utc(2026, 10, 25);
      expect(describeDayOffset(today, today), '今天');
      expect(describeDayOffset(DateTime.utc(2026, 10, 24), today), '昨天');
      expect(describeDayOffset(DateTime.utc(2026, 10, 20), today), '5 天前');
      expect(describeDayOffset(DateTime.utc(2026, 10, 26), today), '明天');

      expect(describeHoldingPeriod(today, today), '今天购入');
      expect(
        describeHoldingPeriod(DateTime.utc(2025, 10, 25), today),
        '已持有 365 天',
      );
    });
  });
}
