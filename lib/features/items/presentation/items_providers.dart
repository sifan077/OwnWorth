import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers.dart';
import '../domain/cost_calculations.dart';
import '../domain/item_query.dart';
import '../domain/owned_item.dart';

const Object _categoryUnset = Object();

/// Search, category and order selected on the home page.
class HomeFilter {
  const HomeFilter({
    this.query = '',
    this.category,
    this.sort = ItemSort.dailyCostHighToLow,
  });

  final String query;
  final ItemCategory? category;
  final ItemSort sort;

  bool get isDefault =>
      query.trim().isEmpty &&
      category == null &&
      sort == ItemSort.dailyCostHighToLow;

  /// Whether search or category narrows the list below the full set. Sorting
  /// alone does not change the aggregated numbers, so it does not count.
  bool get isNarrowed => query.trim().isNotEmpty || category != null;

  HomeFilter copyWith({
    String? query,
    Object? category = _categoryUnset,
    ItemSort? sort,
  }) {
    return HomeFilter(
      query: query ?? this.query,
      category: identical(category, _categoryUnset)
          ? this.category
          : category as ItemCategory?,
      sort: sort ?? this.sort,
    );
  }
}

class HomeFilterNotifier extends Notifier<HomeFilter> {
  @override
  HomeFilter build() => const HomeFilter();

  void setQuery(String value) {
    state = state.copyWith(query: value);
  }

  void setCategory(ItemCategory? value) {
    state = state.copyWith(category: value);
  }

  void setSort(ItemSort value) {
    state = state.copyWith(sort: value);
  }

  void reset() {
    state = const HomeFilter();
  }
}

final homeFilterProvider = NotifierProvider<HomeFilterNotifier, HomeFilter>(
  HomeFilterNotifier.new,
);

/// The list after applying search, category filter and sorting.
final filteredItemsProvider = Provider<AsyncValue<List<OwnedItem>>>((ref) {
  final items = ref.watch(allItemsProvider);
  final filter = ref.watch(homeFilterProvider);
  final today = ref.watch(todayProvider);
  final usageCounts = ref.watch(usageCountsProvider);
  return items.whenData(
    (value) => queryItems(
      value,
      query: filter.query,
      category: filter.category,
      sort: filter.sort,
      today: today,
      usageCounts: usageCounts,
    ),
  );
});

/// Aggregated numbers for the list currently on screen.
///
/// It reads [filteredItemsProvider] so the overview follows the active search
/// and category filter instead of always describing every record.
final overviewProvider = Provider<AsyncValue<OwnedItemsOverview>>((ref) {
  final filtered = ref.watch(filteredItemsProvider);
  final today = ref.watch(todayProvider);
  return filtered.whenData((value) => summarizeItems(value, today));
});

/// Recorded usage count per item ID. Empty while the usage stream is loading.
final usageCountsProvider = Provider<Map<String, int>>((ref) {
  final usages = ref.watch(allUsagesProvider).value;
  if (usages == null || usages.isEmpty) {
    return const <String, int>{};
  }
  final counts = <String, int>{};
  for (final usage in usages) {
    counts.update(usage.itemId, (value) => value + 1, ifAbsent: () => 1);
  }
  return Map.unmodifiable(counts);
});
