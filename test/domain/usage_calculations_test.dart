import 'package:flutter_test/flutter_test.dart';
import 'package:ownworth/features/items/domain/usage_calculations.dart';

import '../helpers/fixtures.dart';

void main() {
  final today = DateTime.utc(2026, 10, 25);
  final item = buildItem(id: 'a', purchasePriceCents: 300000);

  group('item usage metrics', () {
    test('no records means no cost and no last use', () {
      final metrics = calculateUsageMetrics(
        item: item,
        usages: const [],
        today: today,
      );

      expect(metrics.totalCount, 0);
      expect(metrics.monthCount, 0);
      expect(metrics.lastUsedAt, isNull);
      expect(metrics.costPerUseCents, isNull);
      expect(metrics.hasUsage, isFalse);
    });

    test('counts all uses, the current local month, and the latest use', () {
      final usages = [
        buildUsage(
          id: 'u1',
          itemId: 'a',
          usedAt: DateTime(2026, 10, 24, 23, 30).toUtc(),
        ),
        buildUsage(
          id: 'u2',
          itemId: 'a',
          usedAt: DateTime(2026, 10, 1, 0, 5).toUtc(),
        ),
        buildUsage(
          id: 'u3',
          itemId: 'a',
          usedAt: DateTime(2026, 9, 30, 23, 55).toUtc(),
        ),
      ];

      final metrics = calculateUsageMetrics(
        item: item,
        usages: usages,
        today: today,
      );

      expect(metrics.totalCount, 3);
      expect(metrics.monthCount, 2);
      expect(metrics.lastUsedAt, DateTime(2026, 10, 24, 23, 30));
      expect(metrics.costPerUseCents, closeTo(100000, 0.0001));
      expect(metrics.hasUsage, isTrue);
    });

    test('ignores records belonging to another item', () {
      final metrics = calculateUsageMetrics(
        item: item,
        usages: [
          buildUsage(itemId: 'a', usedAt: DateTime(2026, 10, 22).toUtc()),
          buildUsage(
            id: 'other',
            itemId: 'b',
            usedAt: DateTime(2026, 10, 23).toUtc(),
          ),
        ],
        today: today,
      );

      expect(metrics.totalCount, 1);
      expect(metrics.costPerUseCents, 300000);
    });

    test('a use from a previous month still counts toward the total', () {
      final metrics = calculateUsageMetrics(
        item: item,
        usages: [
          buildUsage(
            id: 'old',
            itemId: 'a',
            usedAt: DateTime(2026, 8, 15, 10).toUtc(),
          ),
        ],
        today: today,
      );

      expect(metrics.totalCount, 1);
      expect(metrics.monthCount, 0);
      expect(metrics.lastUsedAt, DateTime(2026, 8, 15, 10));
    });
  });
}
