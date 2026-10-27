import 'package:flutter/material.dart';

import '../../app/theme/app_theme.dart';
import '../utils/date_utils.dart';

/// Opens a bottom sheet with a day calendar, plus year / month pickers that
/// only appear after tapping the matching part of the header.
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
  String Function(DateTime date)? previewBuilder,
}) {
  final first = normalizeDate(firstDate);
  final last = normalizeDate(lastDate);
  if (last.isBefore(first)) {
    throw ArgumentError('lastDate must not be before firstDate');
  }
  final today = normalizeDate(referenceDate ?? currentLocalDate());
  final selected = clampCalendarDate(initialDate, first, last);

  return showModalBottomSheet<DateTime>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (sheetContext) {
      return _DatePickerSheet(
        title: title,
        description: description,
        selected: selected,
        today: today,
        firstDate: first,
        lastDate: last,
        previewBuilder: previewBuilder,
      );
    },
  );
}

class _DatePickerSheet extends StatefulWidget {
  const _DatePickerSheet({
    required this.title,
    required this.description,
    required this.selected,
    required this.today,
    required this.firstDate,
    required this.lastDate,
    required this.previewBuilder,
  });

  final String title;
  final String? description;
  final DateTime selected;
  final DateTime today;
  final DateTime firstDate;
  final DateTime lastDate;
  final String Function(DateTime date)? previewBuilder;

  @override
  State<_DatePickerSheet> createState() => _DatePickerSheetState();
}

/// Which grid the sheet is currently showing. The day grid is the resting
/// state; year and month are transient overlays opened from the header.
enum _CalendarLevel { day, year, month }

class _DatePickerSheetState extends State<_DatePickerSheet> {
  static const double _bodyHeight = 320;
  static const double _spacing = 8;
  static const int _yearColumns = 3;
  static const double _yearTileHeight = 44;
  static const double _yearRowExtent = _yearTileHeight + _spacing;

  late final ScrollController _yearController;
  bool _pendingYearScroll = false;

  late _CalendarLevel _level;
  late int _visibleYear;
  late int _visibleMonth;

  DateTime get _first => widget.firstDate;
  DateTime get _last => widget.lastDate;
  DateTime get _selected => widget.selected;

  @override
  void initState() {
    super.initState();
    _level = _CalendarLevel.day;
    _visibleYear = _selected.year;
    _visibleMonth = _selected.month;
    _yearController = ScrollController(
      initialScrollOffset: _yearOffsetFor(
        _yearRowExtent,
        _last.year - _visibleYear,
      ),
    );
  }

  @override
  void dispose() {
    _yearController.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------- helpers

  bool _isMonthEnabled(int year, int month) {
    final monthStart = DateTime.utc(year, month, 1);
    final monthEnd = DateTime.utc(year, month + 1, 0);
    return !monthEnd.isBefore(_first) && !monthStart.isAfter(_last);
  }

  bool _isDayEnabled(DateTime date) {
    return !date.isBefore(_first) && !date.isAfter(_last);
  }

  /// Keeps the same month when switching years, unless the range cuts it off.
  int _coerceMonth(int year, int month) {
    if (_isMonthEnabled(year, month)) {
      return month;
    }
    if (DateTime.utc(year, month, 1).isAfter(_last)) {
      for (var candidate = 12; candidate >= 1; candidate--) {
        if (_isMonthEnabled(year, candidate)) {
          return candidate;
        }
      }
    }
    for (var candidate = 1; candidate <= 12; candidate++) {
      if (_isMonthEnabled(year, candidate)) {
        return candidate;
      }
    }
    return month;
  }

  /// Pixel offset of the row that holds [index], leaving one row of context
  /// above so the browsed year does not sit at the very top edge of the grid.
  double _yearOffsetFor(double extent, int index) {
    if (index < 0) {
      return 0;
    }
    final offset = ((index ~/ _yearColumns) - 1) * extent;
    return offset < 0 ? 0 : offset;
  }

  void _scrollYearIntoView(int index) {
    if (!_pendingYearScroll) {
      return;
    }
    _pendingYearScroll = false;
    final target = _yearOffsetFor(_yearRowExtent, index);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_yearController.hasClients) {
        return;
      }
      final max = _yearController.position.maxScrollExtent;
      _yearController.jumpTo(target.clamp(0.0, max));
    });
  }

  // ------------------------------------------------------------ navigation

  void _openYearGrid() {
    if (_level == _CalendarLevel.year) {
      return;
    }
    setState(() {
      _level = _CalendarLevel.year;
      _pendingYearScroll = true;
    });
  }

  void _openMonthGrid() {
    if (_level == _CalendarLevel.month) {
      return;
    }
    setState(() => _level = _CalendarLevel.month);
  }

  void _backToDays() {
    if (_level == _CalendarLevel.day) {
      return;
    }
    setState(() => _level = _CalendarLevel.day);
  }

  void _selectYear(int year) {
    setState(() {
      _visibleYear = year;
      _visibleMonth = _coerceMonth(year, _visibleMonth);
      _level = _CalendarLevel.day;
    });
  }

  void _selectMonth(int month) {
    setState(() {
      _visibleMonth = month;
      _level = _CalendarLevel.day;
    });
  }

  void _selectDay(DateTime date) {
    Navigator.of(context).pop(clampCalendarDate(date, _first, _last));
  }

  // ---------------------------------------------------------------- build

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return SafeArea(
      top: false,
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.title,
                      style: theme.textTheme.titleLarge,
                    ),
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('取消'),
                  ),
                ],
              ),
              if (widget.description != null) ...[
                const SizedBox(height: 2),
                Text(
                  widget.description!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
              const SizedBox(height: 10),
              _buildHeader(context),
              const SizedBox(height: 10),
              _buildBody(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final style = theme.textTheme.titleMedium?.copyWith(
      fontWeight: FontWeight.w700,
    );

    final crumbs = <Widget>[];
    if (_level == _CalendarLevel.year) {
      crumbs.add(
        _HeaderCrumb(
          label: '$_visibleYear年',
          style: style,
          expanded: true,
          onTap: _backToDays,
        ),
      );
    } else {
      crumbs.add(
        _HeaderCrumb(
          label: '$_visibleYear年',
          style: style,
          expanded: false,
          onTap: _openYearGrid,
        ),
      );
      crumbs.add(
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2),
          child: Icon(
            Icons.chevron_right_rounded,
            size: 18,
            color: scheme.onSurfaceVariant,
          ),
        ),
      );
      crumbs.add(
        _HeaderCrumb(
          label: '$_visibleMonth月',
          style: style,
          expanded: _level == _CalendarLevel.month,
          onTap: _level == _CalendarLevel.month
              ? _backToDays
              : _openMonthGrid,
        ),
      );
    }

    final preview = widget.previewBuilder?.call(_selected);

    return Row(
      children: [
        ...crumbs,
        const Spacer(),
        if (preview != null && preview.isNotEmpty)
          Text(
            preview,
            style: theme.textTheme.labelSmall?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
      ],
    );
  }

  Widget _buildBody(BuildContext context) {
    return switch (_level) {
      _CalendarLevel.day => _buildDayGrid(context),
      _CalendarLevel.year => _buildYearGrid(context),
      _CalendarLevel.month => _buildMonthGrid(context),
    };
  }

  // -------------------------------------------------------------- day view

  Widget _buildDayGrid(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    final daysInMonth = DateTime.utc(_visibleYear, _visibleMonth + 1, 0).day;
    final firstWeekday = DateTime.utc(_visibleYear, _visibleMonth, 1).weekday;
    // Monday-first grid, matching the Chinese calendar convention.
    final leading = firstWeekday - 1;
    final totalCells = leading + daysInMonth;
    final rows = (totalCells / 7).ceil();

    return SizedBox(
      height: _bodyHeight,
      child: Column(
        children: [
          Row(
            children: [
              for (final label in const ['一', '二', '三', '四', '五', '六', '日'])
                Expanded(
                  child: Center(
                    child: Text(
                      label,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          Expanded(
            child: GridView.builder(
              padding: EdgeInsets.zero,
              physics: const ClampingScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7,
                mainAxisSpacing: 2,
                crossAxisSpacing: 2,
                mainAxisExtent: 44,
              ),
              itemCount: rows * 7,
              itemBuilder: (context, index) {
                final dayNumber = index - leading + 1;
                if (dayNumber < 1 || dayNumber > daysInMonth) {
                  return const SizedBox.shrink();
                }
                final date = DateTime.utc(_visibleYear, _visibleMonth, dayNumber);
                final enabled = _isDayEnabled(date);
                return _DayCell(
                  date: date,
                  selected: isSameCalendarDay(date, _selected),
                  isToday: isSameCalendarDay(date, widget.today),
                  enabled: enabled,
                  onTap: enabled ? () => _selectDay(date) : null,
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------- year view

  Widget _buildYearGrid(BuildContext context) {
    final years = [
      for (var year = _last.year; year >= _first.year; year--) year,
    ];
    _scrollYearIntoView(years.indexOf(_visibleYear));

    return SizedBox(
      height: _bodyHeight,
      child: GridView.builder(
        controller: _yearController,
        padding: const EdgeInsets.only(bottom: 8),
        physics: const ClampingScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: _yearColumns,
          mainAxisSpacing: _spacing,
          crossAxisSpacing: _spacing,
          mainAxisExtent: _yearTileHeight,
        ),
        itemCount: years.length,
        itemBuilder: (context, index) {
          final year = years[index];
          return _GridTile(
            label: '$year年',
            selected: year == _visibleYear,
            onTap: () => _selectYear(year),
          );
        },
      ),
    );
  }

  // ------------------------------------------------------------ month view

  Widget _buildMonthGrid(BuildContext context) {
    return SizedBox(
      height: _bodyHeight,
      child: GridView.builder(
        padding: const EdgeInsets.only(bottom: 8),
        physics: const ClampingScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          mainAxisSpacing: _spacing,
          crossAxisSpacing: _spacing,
          mainAxisExtent: 56,
        ),
        itemCount: 12,
        itemBuilder: (context, index) {
          final month = index + 1;
          final enabled = _isMonthEnabled(_visibleYear, month);
          return _GridTile(
            label: '$month月',
            selected: month == _visibleMonth,
            enabled: enabled,
            onTap: enabled ? () => _selectMonth(month) : null,
          );
        },
      ),
    );
  }
}

class _HeaderCrumb extends StatelessWidget {
  const _HeaderCrumb({
    required this.label,
    required this.style,
    required this.expanded,
    required this.onTap,
  });

  final String label;
  final TextStyle? style;
  final bool expanded;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(label, style: style?.copyWith(color: scheme.primary)),
            Icon(
              expanded ? Icons.expand_less_rounded : Icons.expand_more_rounded,
              size: 18,
              color: scheme.primary,
            ),
          ],
        ),
      ),
    );
  }
}

class _GridTile extends StatelessWidget {
  const _GridTile({
    required this.label,
    required this.selected,
    required this.onTap,
    this.enabled = true,
  });

  final String label;
  final bool selected;
  final bool enabled;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Material(
      color: selected ? scheme.primaryContainer : scheme.surfaceContainerLowest,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: selected
              ? scheme.primary.withValues(alpha: 0.5)
              : scheme.outlineVariant,
          width: selected ? 1.4 : 1,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Center(
          child: Text(
            label,
            style: AppTheme.tabular(
              theme.textTheme.labelLarge?.copyWith(
                color: enabled
                    ? (selected
                          ? scheme.onPrimaryContainer
                          : scheme.onSurface)
                    : scheme.onSurface.withValues(alpha: 0.35),
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DayCell extends StatelessWidget {
  const _DayCell({
    required this.date,
    required this.selected,
    required this.isToday,
    required this.enabled,
    required this.onTap,
  });

  final DateTime date;
  final bool selected;
  final bool isToday;
  final bool enabled;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    final Color foreground;
    if (selected) {
      foreground = scheme.onPrimary;
    } else if (!enabled) {
      foreground = scheme.onSurface.withValues(alpha: 0.3);
    } else {
      foreground = scheme.onSurface;
    }

    return InkResponse(
      onTap: onTap,
      radius: 24,
      containedInkWell: false,
      child: Center(
        child: Container(
          width: 36,
          height: 36,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: selected ? scheme.primary : null,
            border: !selected && isToday
                ? Border.all(color: scheme.primary, width: 1.2)
                : null,
          ),
          child: Text(
            '${date.day}',
            style: AppTheme.tabular(
              theme.textTheme.bodyMedium?.copyWith(
                color: foreground,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
