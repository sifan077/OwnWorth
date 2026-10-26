import 'package:flutter_test/flutter_test.dart';
import 'package:ownworth/features/items/domain/item_query.dart';
import 'package:ownworth/features/items/domain/owned_item.dart';

import '../helpers/fixtures.dart';

void main() {
  final today = DateTime.utc(2026, 10, 25);
  final items = [
    buildItem(
      id: 'a',
      name: 'Sony 耳机',
      category: ItemCategory.digital,
      purchasePriceCents: 300000,
      purchaseDate: DateTime.utc(2026, 10, 20),
    ),
    buildItem(
      id: 'b',
      name: '咖啡机',
      category: ItemCategory.appliance,
      purchasePriceCents: 100000,
      purchaseDate: DateTime.utc(2026, 9, 1),
    ),
    buildItem(
      id: 'c',
      name: '羊毛大衣',
      category: ItemCategory.clothing,
      purchasePriceCents: 80000,
      purchaseDate: DateTime.utc(2026, 1, 1),
      status: ItemStatus.ended,
      endDate: DateTime.utc(2026, 2, 1),
    ),
  ];

  test('search is case-insensitive and name-only', () {
    final result = queryItems(
      items,
      query: 'sony',
      category: null,
      sort: ItemSort.purchaseDateNewestFirst,
      today: today,
    );
    expect(result.map((e) => e.id), ['a']);
  });

  test('category filter combines with search', () {
    final result = queryItems(
      items,
      query: '机',
      category: ItemCategory.appliance,
      sort: ItemSort.purchaseDateNewestFirst,
      today: today,
    );
    expect(result.map((e) => e.id), ['b']);
  });

  test('sorts by daily cost, handling ended items with fixed cost', () {
    final result = queryItems(
      items,
      query: '',
      category: null,
      sort: ItemSort.dailyCostLowToHigh,
      today: today,
    );
    // a: 300000 / 6 = 50000, b: 100000 / 55, c: 80000 / 32.
    expect(result.map((e) => e.id), ['b', 'c', 'a']);
  });

  test('sorts by purchase date', () {
    final newest = queryItems(
      items,
      query: '',
      category: null,
      sort: ItemSort.purchaseDateNewestFirst,
      today: today,
    );
    expect(newest.map((e) => e.id), ['a', 'b', 'c']);

    final oldest = queryItems(
      items,
      query: '',
      category: null,
      sort: ItemSort.purchaseDateOldestFirst,
      today: today,
    );
    expect(oldest.map((e) => e.id), ['c', 'b', 'a']);
  });

  test('sorts by usage count', () {
    final counts = {'a': 5, 'b': 1, 'c': 3};

    final high = queryItems(
      items,
      query: '',
      category: null,
      sort: ItemSort.usageHighToLow,
      today: today,
      usageCounts: counts,
    );
    expect(high.map((item) => item.id), ['a', 'c', 'b']);

    final low = queryItems(
      items,
      query: '',
      category: null,
      sort: ItemSort.usageLowToHigh,
      today: today,
      usageCounts: counts,
    );
    expect(low.map((item) => item.id), ['b', 'c', 'a']);
  });

  test('items without usage records sort as zero uses', () {
    final result = queryItems(
      items,
      query: '',
      category: null,
      sort: ItemSort.usageHighToLow,
      today: today,
      usageCounts: {'b': 2},
    );
    expect(result.first.id, 'b');
    expect(result.skip(1).map((item) => item.id).toSet(), {'a', 'c'});
  });

  test('empty query and filter return every item', () {
    final result = queryItems(
      items,
      query: '   ',
      category: null,
      sort: ItemSort.purchaseDateNewestFirst,
      today: today,
    );
    expect(result.length, 3);
  });
}
