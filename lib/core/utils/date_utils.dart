/// Calendar helpers used by all date-sensitive calculations.
///
/// Dates that represent a calendar day are stored as a UTC [DateTime] whose
/// year, month and day are the values the user picked. UTC is used purely as a
/// date container: differences between two such values are exact calendar day
/// differences and are unaffected by time zones or daylight-saving changes.
library;

/// Converts any [DateTime] into a calendar-day container.
DateTime normalizeDate(DateTime value) {
  return DateTime.utc(value.year, value.month, value.day);
}

/// Today's local calendar date, represented as a calendar-day container.
///
/// Only the local year/month/day are used, never the current hour.
DateTime currentLocalDate([DateTime? now]) {
  final local = now ?? DateTime.now();
  return normalizeDate(local);
}

/// Number of whole calendar days from [from] to [to].
///
/// The time-of-day component is ignored.
int daysBetweenCalendar(DateTime from, DateTime to) {
  return normalizeDate(to).difference(normalizeDate(from)).inDays;
}

/// Adds calendar days while letting [DateTime] normalize month/year rollovers.
DateTime addCalendarDays(DateTime date, int days) {
  return DateTime.utc(date.year, date.month, date.day + days);
}

/// Adds calendar months, clamping the day to the last valid day of the target
/// month so `1月31日 + 1个月` becomes `2月28/29日` instead of rolling into March.
DateTime addCalendarMonths(DateTime date, int months) {
  final totalMonths = date.month - 1 + months;
  final yearOffset = (totalMonths / 12).floor();
  final year = date.year + yearOffset;
  final month = totalMonths - yearOffset * 12 + 1;
  final lastDayOfMonth = DateTime.utc(year, month + 1, 0).day;
  final day = date.day > lastDayOfMonth ? lastDayOfMonth : date.day;
  return DateTime.utc(year, month, day);
}

/// Converts a calendar-day container back into a local [DateTime].
///
/// Material date pickers work with local dates; passing a UTC container
/// directly would shift the day for time zones west of UTC.
DateTime toLocalDate(DateTime date) {
  return DateTime(date.year, date.month, date.day);
}

/// Clamps [date] into the inclusive range `[min, max]`.
DateTime clampCalendarDate(DateTime date, DateTime min, DateTime max) {
  final normalized = normalizeDate(date);
  final lower = normalizeDate(min);
  final upper = normalizeDate(max);
  if (normalized.isBefore(lower)) {
    return lower;
  }
  if (normalized.isAfter(upper)) {
    return upper;
  }
  return normalized;
}

/// Whether two values fall on the same calendar day.
bool isSameCalendarDay(DateTime a, DateTime b) {
  return a.year == b.year && a.month == b.month && a.day == b.day;
}

/// Human readable distance from [today] to [date], e.g. `今天`, `3 天前`.
String describeDayOffset(DateTime date, DateTime today) {
  final difference = daysBetweenCalendar(today, date);
  return switch (difference) {
    0 => '今天',
    1 => '明天',
    -1 => '昨天',
    > 1 => '$difference 天后',
    _ => '${-difference} 天前',
  };
}

/// How long an item purchased on [purchaseDate] has been in use.
String describeHoldingPeriod(DateTime purchaseDate, DateTime today) {
  final days = daysBetweenCalendar(purchaseDate, today);
  if (days <= 0) {
    return '今天购入';
  }
  return '已持有 $days 天';
}

/// Formats a date as `yyyy-MM-dd`.
String formatIsoDate(DateTime date) {
  final year = date.year.toString().padLeft(4, '0');
  final month = date.month.toString().padLeft(2, '0');
  final day = date.day.toString().padLeft(2, '0');
  return '$year-$month-$day';
}

/// Formats a date as `yyyy年M月d日` for the Chinese UI.
String formatChineseDate(DateTime date) {
  return '${date.year}年${date.month}月${date.day}日';
}

/// Strictly parses a `yyyy-MM-dd` calendar date.
///
/// Values such as `2026-02-30` are rejected instead of silently rolling over.
DateTime parseIsoDate(String value) {
  final match = RegExp(r'^(\d{4})-(\d{2})-(\d{2})$').firstMatch(value.trim());
  if (match == null) {
    throw FormatException('日期格式应为 yyyy-MM-dd', value);
  }
  final year = int.parse(match.group(1)!);
  final month = int.parse(match.group(2)!);
  final day = int.parse(match.group(3)!);
  final parsed = DateTime.utc(year, month, day);
  if (parsed.year != year || parsed.month != month || parsed.day != day) {
    throw FormatException('无效日期', value);
  }
  return parsed;
}

/// Formats a timestamp for a backup file name, e.g. `20261025-1830`.
String formatFileTimestamp(DateTime time) {
  final year = time.year.toString().padLeft(4, '0');
  final month = time.month.toString().padLeft(2, '0');
  final day = time.day.toString().padLeft(2, '0');
  final hour = time.hour.toString().padLeft(2, '0');
  final minute = time.minute.toString().padLeft(2, '0');
  return '$year$month$day-$hour$minute';
}
