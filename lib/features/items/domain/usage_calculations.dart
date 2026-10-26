import 'item_usage.dart';
import 'owned_item.dart';

/// Usage values derived for a single item.
class UsageMetrics {
  const UsageMetrics({
    required this.totalCount,
    required this.monthCount,
    required this.lastUsedAt,
    required this.costPerUseCents,
  });

  /// All recorded uses, including uses before the current month.
  final int totalCount;

  /// Uses in the current local calendar month.
  final int monthCount;

  /// Local time of the most recent use, or `null` when never used.
  final DateTime? lastUsedAt;

  /// Price divided by [totalCount], or `null` when there is no record.
  final double? costPerUseCents;

  bool get hasUsage => totalCount > 0;
}

/// Computes usage values for [item] from its usage records.
///
/// [today] is a calendar-day container holding the local year, month and day,
/// as produced by `currentLocalDate`.
UsageMetrics calculateUsageMetrics({
  required OwnedItem item,
  required List<ItemUsage> usages,
  required DateTime today,
}) {
  var totalCount = 0;
  var monthCount = 0;
  DateTime? lastUsedAt;

  for (final usage in usages) {
    // Records are fetched per item, but stay defensive if a caller mixes them.
    if (usage.itemId != item.id) {
      continue;
    }
    totalCount += 1;
    final local = usage.usedAt.toLocal();
    if (local.year == today.year && local.month == today.month) {
      monthCount += 1;
    }
    if (lastUsedAt == null || local.isAfter(lastUsedAt)) {
      lastUsedAt = local;
    }
  }

  return UsageMetrics(
    totalCount: totalCount,
    monthCount: monthCount,
    lastUsedAt: lastUsedAt,
    costPerUseCents: totalCount == 0
        ? null
        : item.purchasePriceCents / totalCount,
  );
}

/// Aggregated usage numbers for the home overview.
class UsageOverview {
  const UsageOverview({
    required this.totalUses,
    required this.monthUses,
    required this.usedItemCount,
  });

  const UsageOverview.empty() : totalUses = 0, monthUses = 0, usedItemCount = 0;

  /// Every recorded use across all items.
  final int totalUses;

  /// Uses in the current local calendar month.
  final int monthUses;

  /// Distinct items with at least one usage record.
  final int usedItemCount;
}

/// Summarizes every usage record for the home page.
UsageOverview summarizeUsage(List<ItemUsage> usages, DateTime today) {
  final itemIds = <String>{};
  var monthUses = 0;

  for (final usage in usages) {
    itemIds.add(usage.itemId);
    final local = usage.usedAt.toLocal();
    if (local.year == today.year && local.month == today.month) {
      monthUses += 1;
    }
  }

  return UsageOverview(
    totalUses: usages.length,
    monthUses: monthUses,
    usedItemCount: itemIds.length,
  );
}
