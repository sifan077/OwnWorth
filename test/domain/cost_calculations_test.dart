import 'package:flutter_test/flutter_test.dart';
import 'package:ownworth/features/items/domain/cost_calculations.dart';
import 'package:ownworth/features/items/domain/owned_item.dart';

import '../helpers/fixtures.dart';

void main() {
  group('held days', () {
    test('today purchase counts as one day', () {
      final item = buildItem(purchaseDate: DateTime.utc(2026, 10, 25));
      final metrics = calculateItemMetrics(item, DateTime.utc(2026, 10, 25));
      expect(metrics.heldDays, 1);
      expect(metrics.dailyCostCents, 300000);
    });

    test('ten calendar days is ten days regardless of time', () {
      final item = buildItem(purchaseDate: DateTime.utc(2026, 10, 16));
      final metrics = calculateItemMetrics(
        item,
        DateTime(2026, 10, 25, 23, 58),
      );
      expect(metrics.heldDays, 10);
    });

    test('ended items freeze on their end date', () {
      final item = buildItem(
        purchaseDate: DateTime.utc(2025, 1, 1),
        status: ItemStatus.ended,
        endDate: DateTime.utc(2026, 1, 1),
      );
      final early = calculateItemMetrics(item, DateTime.utc(2026, 10, 25));
      final late = calculateItemMetrics(item, DateTime.utc(2030, 10, 25));
      expect(early.heldDays, 366);
      expect(late.heldDays, 366);
      expect(late.dailyCostCents, early.dailyCostCents);
    });
  });

  group('daily cost', () {
    test('handles fractional yuan precisely', () {
      final item = buildItem(
        purchasePriceCents: 499999,
        purchaseDate: DateTime.utc(2026, 1, 1),
      );
      final metrics = calculateItemMetrics(item, DateTime.utc(2026, 1, 10));
      expect(metrics.heldDays, 10);
      expect(metrics.dailyCostCents, closeTo(49999.9, 0.0001));
    });
  });

  group('target progress', () {
    test('exactly reaching the target is 100 percent', () {
      final item = buildItem(
        purchasePriceCents: 300000,
        targetDailyCostCents: 1000,
        purchaseDate: DateTime.utc(2026, 1, 1),
      );
      final target = calculateItemMetrics(
        item,
        DateTime.utc(2026, 10, 27),
      ).target!;
      expect(target.requiredDays, 300);
      expect(target.achieved, isTrue);
      expect(target.remainingDays, 0);
      expect(target.progress, 1);
      expect(target.targetDate, DateTime.utc(2026, 10, 27));
    });

    test('exceeding the target keeps progress at 100 percent', () {
      final item = buildItem(
        purchasePriceCents: 300000,
        targetDailyCostCents: 1000,
        purchaseDate: DateTime.utc(2026, 1, 1),
      );
      final target = calculateItemMetrics(
        item,
        DateTime.utc(2027, 1, 1),
      ).target!;
      expect(target.achieved, isTrue);
      expect(target.remainingDays, 0);
      expect(target.progress, 1);
      expect(target.targetDate, DateTime.utc(2026, 10, 27));
    });

    test('a very small target produces a long countdown', () {
      final item = buildItem(
        purchasePriceCents: 300000,
        targetDailyCostCents: 1,
        purchaseDate: DateTime.utc(2026, 1, 1),
      );
      final target = calculateItemMetrics(
        item,
        DateTime.utc(2026, 1, 2),
      ).target!;
      expect(target.requiredDays, 300000);
      expect(target.remainingDays, 299998);
      expect(target.achieved, isFalse);
      expect(target.progress, closeTo(2 / 300000, 1e-12));
      expect(target.targetDate, DateTime.utc(2847, 5, 16));
    });

    test('ended item below target reports an unachieved fixed goal', () {
      final item = buildItem(
        purchasePriceCents: 300000,
        targetDailyCostCents: 1000,
        purchaseDate: DateTime.utc(2026, 1, 1),
        status: ItemStatus.ended,
        endDate: DateTime.utc(2026, 1, 10),
      );
      final target = calculateItemMetrics(
        item,
        DateTime.utc(2030, 1, 1),
      ).target!;
      expect(target.achieved, isFalse);
      expect(target.remainingDays, 290);
      expect(target.progress, closeTo(10 / 300, 1e-12));
    });

    test('no target returns null and no progress', () {
      final metrics = calculateItemMetrics(
        buildItem(),
        DateTime.utc(2026, 10, 25),
      );
      expect(metrics.target, isNull);
      expect(metrics.hasTarget, isFalse);
    });
  });

  group('overview', () {
    test('sums all purchases but only active daily costs', () {
      final items = [
        buildItem(
          id: 'a',
          name: 'A',
          purchasePriceCents: 300000,
          purchaseDate: DateTime.utc(2026, 10, 16),
        ),
        buildItem(
          id: 'b',
          name: 'B',
          purchasePriceCents: 100000,
          purchaseDate: DateTime.utc(2026, 10, 1),
        ),
        buildItem(
          id: 'c',
          name: 'C',
          purchasePriceCents: 50000,
          purchaseDate: DateTime.utc(2026, 1, 1),
          status: ItemStatus.ended,
          endDate: DateTime.utc(2026, 1, 10),
        ),
      ];
      final overview = summarizeItems(items, DateTime.utc(2026, 10, 25));
      expect(overview.activeCount, 2);
      expect(overview.totalCount, 3);
      expect(overview.totalPurchaseCents, 450000);
      expect(overview.activeDailyCostCents, closeTo(34000, 0.0001));
    });

    test('reflects updated prices and dates', () {
      final item = buildItem(purchaseDate: DateTime.utc(2026, 10, 20));
      final before = summarizeItems([item], DateTime.utc(2026, 10, 25));
      final updated = item.copyWith(
        purchasePriceCents: 600000,
        purchaseDate: DateTime.utc(2026, 10, 21),
      );
      final after = summarizeItems([updated], DateTime.utc(2026, 10, 25));
      expect(before.totalPurchaseCents, 300000);
      expect(before.activeDailyCostCents, 50000);
      expect(after.totalPurchaseCents, 600000);
      expect(after.activeDailyCostCents, 120000);
    });

    test('reflects a deletion', () {
      final items = [
        buildItem(id: 'a', purchasePriceCents: 300000),
        buildItem(id: 'b', purchasePriceCents: 100000, name: 'B'),
      ];
      final before = summarizeItems(items, DateTime.utc(2026, 10, 25));
      final after = summarizeItems(
        items.where((item) => item.id != 'a').toList(),
        DateTime.utc(2026, 10, 25),
      );
      expect(before.totalCount, 2);
      expect(before.totalPurchaseCents, 400000);
      expect(after.totalCount, 1);
      expect(after.totalPurchaseCents, 100000);
    });
  });
}
