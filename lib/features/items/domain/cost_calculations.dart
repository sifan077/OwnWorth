import 'dart:math' as math;

import '../../../core/utils/date_utils.dart';
import 'owned_item.dart';

/// Target-related values derived from an item's price and goal.
class TargetMetrics {
  const TargetMetrics({
    required this.requiredDays,
    required this.targetDate,
    required this.remainingDays,
    required this.achieved,
    required this.progress,
  });

  /// ceil(price / target daily cost).
  final int requiredDays;

  /// The day on which the target is reached.
  final DateTime targetDate;

  /// Days still needed. Always zero once achieved.
  final int remainingDays;
  final bool achieved;

  /// 0.0..1.0.
  final double progress;
}

/// Values that change as calendar days pass, but are never stored.
class ItemMetrics {
  const ItemMetrics({
    required this.heldDays,
    required this.dailyCostCents,
    required this.target,
  });

  /// Purchase day is day 1.
  final int heldDays;

  /// Price per held day, in cents, with internal fractional precision.
  final double dailyCostCents;
  final TargetMetrics? target;

  bool get hasTarget => target != null;
}

/// Calculates the number of held calendar days.
///
/// An active item is counted through today. An ended item is frozen on its
/// end date. The purchase day itself counts as day one.
int calculateHeldDays({
  required DateTime purchaseDate,
  required ItemStatus status,
  required DateTime today,
  DateTime? endDate,
}) {
  final start = normalizeDate(purchaseDate);
  final effectiveEnd = status == ItemStatus.ended
      ? normalizeDate(endDate ?? today)
      : normalizeDate(today);
  if (effectiveEnd.isBefore(start)) {
    // Defensive fallback for a damaged record. Validation prevents this case.
    return 1;
  }
  return daysBetweenCalendar(start, effectiveEnd) + 1;
}

/// Calculates the goal values for an item.
///
/// Returns `null` when no positive target was set.
TargetMetrics? calculateTargetMetrics({
  required int purchasePriceCents,
  required int? targetDailyCostCents,
  required DateTime purchaseDate,
  required int heldDays,
}) {
  if (targetDailyCostCents == null || targetDailyCostCents <= 0) {
    return null;
  }

  final requiredDays =
      (purchasePriceCents + targetDailyCostCents - 1) ~/ targetDailyCostCents;
  final targetDate = addCalendarDays(purchaseDate, requiredDays - 1);
  final achieved = heldDays >= requiredDays;
  final remainingDays = math.max(0, requiredDays - heldDays);
  final progress = (heldDays / requiredDays).clamp(0.0, 1.0).toDouble();

  return TargetMetrics(
    requiredDays: requiredDays,
    targetDate: targetDate,
    remainingDays: remainingDays,
    achieved: achieved,
    progress: progress,
  );
}

/// Computes all date-sensitive values for a single item.
ItemMetrics calculateItemMetrics(OwnedItem item, DateTime today) {
  final heldDays = calculateHeldDays(
    purchaseDate: item.purchaseDate,
    status: item.status,
    endDate: item.endDate,
    today: today,
  );
  return ItemMetrics(
    heldDays: heldDays,
    dailyCostCents: item.purchasePriceCents / heldDays,
    target: calculateTargetMetrics(
      purchasePriceCents: item.purchasePriceCents,
      targetDailyCostCents: item.targetDailyCostCents,
      purchaseDate: item.purchaseDate,
      heldDays: heldDays,
    ),
  );
}

/// Aggregated home-page numbers.
class OwnedItemsOverview {
  const OwnedItemsOverview({
    required this.activeCount,
    required this.totalCount,
    required this.totalPurchaseCents,
    required this.activeDailyCostCents,
  });

  final int activeCount;
  final int totalCount;

  /// Includes active and ended items, as required by the home overview.
  final int totalPurchaseCents;

  /// Sum of the current daily costs of active items only.
  final double activeDailyCostCents;
}

OwnedItemsOverview summarizeItems(List<OwnedItem> items, DateTime today) {
  var activeCount = 0;
  var totalPurchaseCents = 0;
  var activeDailyCostCents = 0.0;

  for (final item in items) {
    totalPurchaseCents += item.purchasePriceCents;
    if (item.isActive) {
      activeCount += 1;
      activeDailyCostCents += calculateItemMetrics(item, today).dailyCostCents;
    }
  }

  return OwnedItemsOverview(
    activeCount: activeCount,
    totalCount: items.length,
    totalPurchaseCents: totalPurchaseCents,
    activeDailyCostCents: activeDailyCostCents,
  );
}
