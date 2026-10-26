import 'cost_calculations.dart';
import 'owned_item.dart';

/// Available list orderings on the home page.
enum ItemSort {
  dailyCostHighToLow('日均成本：高到低'),
  dailyCostLowToHigh('日均成本：低到高'),
  purchaseDateNewestFirst('购入日期：新到旧'),
  purchaseDateOldestFirst('购入日期：旧到新'),
  usageHighToLow('使用次数：多到少'),
  usageLowToHigh('使用次数：少到多');

  const ItemSort(this.label);

  final String label;
}

/// Applies name search, category filter and ordering to the item list.
///
/// [usageCounts] maps item IDs to their recorded usage count. It only affects
/// the two usage orderings and defaults to an empty map for callers that do not
/// track usage.
List<OwnedItem> queryItems(
  List<OwnedItem> items, {
  required String query,
  required ItemCategory? category,
  required ItemSort sort,
  required DateTime today,
  Map<String, int> usageCounts = const {},
}) {
  final normalizedQuery = query.trim().toLowerCase();
  final filtered = items.where((item) {
    if (category != null && item.category != category) {
      return false;
    }
    if (normalizedQuery.isEmpty) {
      return true;
    }
    return item.name.toLowerCase().contains(normalizedQuery);
  }).toList();

  int compareByDate(OwnedItem a, OwnedItem b, {required bool newestFirst}) {
    final result = a.purchaseDate.compareTo(b.purchaseDate);
    return newestFirst ? -result : result;
  }

  switch (sort) {
    case ItemSort.dailyCostHighToLow:
      filtered.sort((a, b) {
        final comparison = calculateItemMetrics(b, today).dailyCostCents
            .compareTo(calculateItemMetrics(a, today).dailyCostCents);
        return comparison != 0
            ? comparison
            : compareByDate(a, b, newestFirst: true);
      });
      break;
    case ItemSort.dailyCostLowToHigh:
      filtered.sort((a, b) {
        final comparison = calculateItemMetrics(a, today).dailyCostCents
            .compareTo(calculateItemMetrics(b, today).dailyCostCents);
        return comparison != 0
            ? comparison
            : compareByDate(a, b, newestFirst: true);
      });
      break;
    case ItemSort.purchaseDateNewestFirst:
      filtered.sort((a, b) => compareByDate(a, b, newestFirst: true));
      break;
    case ItemSort.purchaseDateOldestFirst:
      filtered.sort((a, b) => compareByDate(a, b, newestFirst: false));
      break;
    case ItemSort.usageHighToLow:
      filtered.sort((a, b) {
        final comparison = (usageCounts[b.id] ?? 0).compareTo(
          usageCounts[a.id] ?? 0,
        );
        return comparison != 0
            ? comparison
            : compareByDate(a, b, newestFirst: true);
      });
      break;
    case ItemSort.usageLowToHigh:
      filtered.sort((a, b) {
        final comparison = (usageCounts[a.id] ?? 0).compareTo(
          usageCounts[b.id] ?? 0,
        );
        return comparison != 0
            ? comparison
            : compareByDate(a, b, newestFirst: true);
      });
      break;
  }

  return filtered;
}
