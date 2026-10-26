/// Money helpers.
///
/// All persisted amounts are integer cents. Floating point values only exist
/// when a derived per-day cost is displayed, never when money is stored.
library;

/// Largest amount accepted by the form: 999,999,999.99 yuan.
const int maxAmountCents = 99999999999;

final RegExp _decimalPattern = RegExp(r'^\d{1,9}(?:\.\d{1,2})?$');

/// Parses a positive yuan string with at most two decimal places.
///
/// Returns `null` for empty, zero, negative or malformed input.
int? parseYuanToCents(String raw) {
  final cleaned = raw.replaceAll('¥', '').replaceAll(',', '').trim();
  if (!_decimalPattern.hasMatch(cleaned)) {
    return null;
  }
  final parts = cleaned.split('.');
  final whole = int.parse(parts.first);
  final fraction = parts.length == 1 ? 0 : int.parse(parts[1].padRight(2, '0'));
  final cents = whole * 100 + fraction;
  if (cents <= 0 || cents > maxAmountCents) {
    return null;
  }
  return cents;
}

/// Formats an amount in cents using the yuan symbol and two decimals.
///
/// Grouping is done manually to keep the output stable and independent of the
/// user's locale.
String formatYuan(num cents, {bool showSymbol = true}) {
  final rounded = cents.round();
  final negative = rounded < 0;
  final absolute = rounded.abs();
  final yuan = absolute ~/ 100;
  final fraction = (absolute % 100).toString().padLeft(2, '0');
  final grouped = _groupThousands(yuan.toString());
  final sign = negative ? '-' : '';
  return '${showSymbol ? '¥' : ''}$sign$grouped.$fraction';
}

/// Formats an integer amount in cents, without the currency symbol.
String formatCentsPlain(int cents) => formatYuan(cents, showSymbol: false);

/// Formats the per-day cost, rounded to two decimal yuan for display.
String formatDailyCost(double dailyCostCents) {
  return formatYuan(dailyCostCents);
}

/// Renders cents as a plain editable amount, always with two decimals.
String yuanInputFromCents(int cents) {
  final absolute = cents.abs();
  final integer = absolute ~/ 100;
  final fraction = (absolute % 100).toString().padLeft(2, '0');
  return '${cents < 0 ? '-' : ''}$integer.$fraction';
}

/// Formats a 0..1 ratio as a one-decimal percentage.
String formatProgressPercent(double progress) {
  final clamped = progress.isNaN ? 0.0 : progress.clamp(0.0, 1.0);
  return '${(clamped * 100).toStringAsFixed(1)}%';
}

String _groupThousands(String digits) {
  final buffer = StringBuffer();
  for (var index = 0; index < digits.length; index++) {
    final remaining = digits.length - index;
    buffer.write(digits[index]);
    if (remaining > 1 && remaining % 3 == 1) {
      buffer.write(',');
    }
  }
  return buffer.toString();
}
