import 'package:flutter/material.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../../core/utils/date_utils.dart';
import '../../../../core/utils/money.dart';
import '../../domain/cost_calculations.dart';
import '../../domain/owned_item.dart';
import 'item_image.dart';
import 'status_badge.dart';

class ItemCard extends StatelessWidget {
  const ItemCard({
    super.key,
    required this.item,
    required this.metrics,
    required this.onTap,
    this.usageCount = 0,
  });

  final OwnedItem item;
  final ItemMetrics metrics;
  final VoidCallback onTap;
  final int usageCount;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final target = metrics.target;

    return Material(
      color: scheme.surfaceContainerLowest,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: scheme.outlineVariant),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
          child: Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ItemImage(
                    category: item.category,
                    imagePath: item.imagePath,
                    size: 62,
                    borderRadius: 17,
                    heroTag: 'item-image-${item.id}',
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(
                                item.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            StatusBadge(status: item.status),
                          ],
                        ),
                        const SizedBox(height: 5),
                        Wrap(
                          spacing: 8,
                          runSpacing: 3,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            CategoryLabel(category: item.category),
                            Text(
                              '购入 ${formatIsoDate(item.purchaseDate)}',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: scheme.onSurfaceVariant,
                              ),
                            ),
                            if (usageCount > 0)
                              _UsageChip(count: usageCount),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            Text(
                              '日均成本',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: scheme.onSurfaceVariant,
                              ),
                            ),
                            if (item.status == ItemStatus.ended) ...[
                              const SizedBox(width: 5),
                              Text(
                                '已固定',
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: scheme.secondary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 1),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.baseline,
                            textBaseline: TextBaseline.alphabetic,
                            children: [
                              Text(
                                formatDailyCost(metrics.dailyCostCents),
                                style: AppTheme.tabular(
                                  theme.textTheme.headlineSmall!.copyWith(
                                    fontSize: 26,
                                    fontWeight: FontWeight.w800,
                                    color: scheme.onSurface,
                                    letterSpacing: -0.7,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '/ 天',
                                style: theme.textTheme.labelMedium?.copyWith(
                                  color: scheme.onSurfaceVariant,
                                ),
                              ),
                              // Per-use cost only exists once a use is recorded.
                              if (usageCount > 0) ...[
                                const SizedBox(width: 8),
                                Text(
                                  '·',
                                  style: theme.textTheme.labelMedium?.copyWith(
                                    color: scheme.outline,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  '次均 ',
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: scheme.onSurfaceVariant,
                                  ),
                                ),
                                Text(
                                  formatYuan(
                                    item.purchasePriceCents / usageCount,
                                  ),
                                  style: AppTheme.tabular(
                                    theme.textTheme.labelLarge?.copyWith(
                                      color: scheme.onSurfaceVariant,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Divider(color: scheme.outlineVariant, height: 1),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _Meta(
                      label: '购入价格',
                      value: formatYuan(item.purchasePriceCents),
                    ),
                  ),
                  Expanded(
                    child: _Meta(label: '已经持有', value: '${metrics.heldDays} 天'),
                  ),
                  Expanded(
                    child: _Meta(
                      label: '目标进度',
                      value: target == null
                          ? '未设置'
                          : target.achieved
                          ? '已达成'
                          : formatProgressPercent(target.progress),
                      color: target?.achieved == true ? scheme.primary : null,
                    ),
                  ),
                  Icon(
                    Icons.chevron_right_rounded,
                    size: 20,
                    color: scheme.onSurfaceVariant,
                  ),
                ],
              ),
              if (target != null) ...[
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    value: target.progress,
                    minHeight: 4,
                    backgroundColor: scheme.surfaceContainerHigh,
                    color: target.achieved
                        ? scheme.primary
                        : scheme.primary.withValues(alpha: 0.72),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Only rendered for items that already have at least one usage record.
class _UsageChip extends StatelessWidget {
  const _UsageChip({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: scheme.primaryContainer.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.touch_app_outlined, size: 12, color: scheme.primary),
          const SizedBox(width: 3),
          Text(
            '使用 $count 次',
            style: theme.textTheme.labelSmall?.copyWith(
              color: scheme.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _Meta extends StatelessWidget {
  const _Meta({required this.label, required this.value, this.color});

  final String label;
  final String value;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.labelSmall?.copyWith(
            color: scheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 2),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(
            value,
            maxLines: 1,
            style: AppTheme.tabular(
              theme.textTheme.labelLarge?.copyWith(
                color: color ?? scheme.onSurface,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
