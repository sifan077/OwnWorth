import 'package:flutter/material.dart';

import '../../app/theme/app_theme.dart';
import '../utils/date_utils.dart';

/// One shortcut shown in the date sheet, resolved against the reference day.
class DateQuickPick {
  const DateQuickPick(this.label, this.resolve);

  final String label;
  final DateTime Function(DateTime today) resolve;
}

/// Default shortcuts: the moments people actually bought something.
const List<DateQuickPick> defaultDateQuickPicks = [
  DateQuickPick('今天', _today),
  DateQuickPick('昨天', _yesterday),
  DateQuickPick('3 天前', _threeDaysAgo),
  DateQuickPick('1 周前', _oneWeekAgo),
  DateQuickPick('1 个月前', _oneMonthAgo),
  DateQuickPick('3 个月前', _threeMonthsAgo),
  DateQuickPick('半年前', _halfYearAgo),
  DateQuickPick('1 年前', _oneYearAgo),
];

DateTime _today(DateTime today) => today;
DateTime _yesterday(DateTime today) => addCalendarDays(today, -1);
DateTime _threeDaysAgo(DateTime today) => addCalendarDays(today, -3);
DateTime _oneWeekAgo(DateTime today) => addCalendarDays(today, -7);
DateTime _oneMonthAgo(DateTime today) => addCalendarMonths(today, -1);
DateTime _threeMonthsAgo(DateTime today) => addCalendarMonths(today, -3);
DateTime _halfYearAgo(DateTime today) => addCalendarMonths(today, -6);
DateTime _oneYearAgo(DateTime today) => addCalendarMonths(today, -12);

/// Opens a bottom sheet that combines quick shortcuts with the full calendar.
///
/// Returns a calendar-day container (see `date_utils.dart`) or `null` when the
/// user dismisses the sheet. All dates are clamped into `[firstDate, lastDate]`
/// so callers never receive an out-of-range value.
Future<DateTime?> showAppDatePicker({
  required BuildContext context,
  required DateTime initialDate,
  required DateTime firstDate,
  required DateTime lastDate,
  required String title,
  String? description,
  DateTime? referenceDate,
  List<DateQuickPick>? quickPicks,
  String Function(DateTime date)? previewBuilder,
}) {
  final first = normalizeDate(firstDate);
  final last = normalizeDate(lastDate);
  if (last.isBefore(first)) {
    throw ArgumentError('lastDate must not be before firstDate');
  }
  final today = normalizeDate(referenceDate ?? currentLocalDate());
  final selected = clampCalendarDate(initialDate, first, last);

  final picks = <DateQuickPick>[];
  final seenDays = <String>{};
  for (final pick in quickPicks ?? defaultDateQuickPicks) {
    final resolved = normalizeDate(pick.resolve(today));
    if (resolved.isBefore(first) || resolved.isAfter(last)) {
      continue;
    }
    if (seenDays.add(formatIsoDate(resolved))) {
      picks.add(DateQuickPick(pick.label, (_) => resolved));
    }
  }

  return showModalBottomSheet<DateTime>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (sheetContext) {
      return _DatePickerSheet(
        title: title,
        description: description,
        selected: selected,
        firstDate: first,
        lastDate: last,
        quickPicks: picks,
        previewBuilder: previewBuilder,
      );
    },
  );
}

class _DatePickerSheet extends StatelessWidget {
  const _DatePickerSheet({
    required this.title,
    required this.description,
    required this.selected,
    required this.firstDate,
    required this.lastDate,
    required this.quickPicks,
    required this.previewBuilder,
  });

  final String title;
  final String? description;
  final DateTime selected;
  final DateTime firstDate;
  final DateTime lastDate;
  final List<DateQuickPick> quickPicks;
  final String Function(DateTime date)? previewBuilder;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return SafeArea(
      top: false,
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: theme.textTheme.titleLarge),
              if (description != null) ...[
                const SizedBox(height: 6),
                Text(
                  description!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
              const SizedBox(height: 16),
              _SelectedDateTile(
                selected: selected,
                preview: previewBuilder?.call(selected),
                onTap: () => _openCalendar(context),
              ),
              if (quickPicks.isNotEmpty) ...[
                const SizedBox(height: 20),
                Text(
                  '快捷选择',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final pick in quickPicks)
                      _QuickPickChip(
                        label: pick.label,
                        selected: isSameCalendarDay(
                          pick.resolve(selected),
                          selected,
                        ),
                        onTap: () => Navigator.of(context).pop(
                          clampCalendarDate(
                            pick.resolve(selected),
                            firstDate,
                            lastDate,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openCalendar(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: toLocalDate(selected),
      firstDate: toLocalDate(firstDate),
      lastDate: toLocalDate(lastDate),
      initialDatePickerMode: DatePickerMode.day,
      helpText: title,
      cancelText: '取消',
      confirmText: '确定',
    );
    if (picked == null || !context.mounted) {
      return;
    }
    Navigator.of(context).pop(clampCalendarDate(picked, firstDate, lastDate));
  }
}

class _SelectedDateTile extends StatelessWidget {
  const _SelectedDateTile({
    required this.selected,
    required this.preview,
    required this.onTap,
  });

  final DateTime selected;
  final String? preview;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Material(
      color: scheme.primaryContainer.withValues(alpha: 0.55),
      borderRadius: BorderRadius.circular(18),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
          child: Row(
            children: [
              Icon(
                Icons.calendar_month_rounded,
                size: 22,
                color: scheme.onPrimaryContainer,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      formatChineseDate(selected),
                      style: AppTheme.tabular(
                        theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: scheme.onPrimaryContainer,
                        ),
                      ),
                    ),
                    if (preview != null && preview!.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        preview!,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: scheme.onPrimaryContainer.withValues(
                            alpha: 0.75,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '在日历中选择',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: scheme.onPrimaryContainer,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                size: 20,
                color: scheme.onPrimaryContainer,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuickPickChip extends StatelessWidget {
  const _QuickPickChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Material(
      color: selected ? scheme.primaryContainer : scheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: selected
              ? scheme.primary.withValues(alpha: 0.45)
              : scheme.outlineVariant,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          child: Text(
            label,
            style: theme.textTheme.labelLarge?.copyWith(
              color: selected ? scheme.onPrimaryContainer : scheme.onSurface,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}
