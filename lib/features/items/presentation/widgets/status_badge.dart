import 'package:flutter/material.dart';

import '../../../../app/theme/app_theme.dart';
import '../../domain/owned_item.dart';

class StatusBadge extends StatelessWidget {
  const StatusBadge({super.key, required this.status});

  final ItemStatus status;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final active = status == ItemStatus.active;
    final background = active
        ? scheme.primaryContainer
        : scheme.surfaceContainerHighest;
    final foreground = active
        ? scheme.onPrimaryContainer
        : scheme.onSurfaceVariant;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(7),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 5,
            height: 5,
            decoration: BoxDecoration(
              color: active ? scheme.primary : scheme.outline,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 5),
          Text(
            status.label,
            style: Theme.of(context).textTheme.labelSmall
                ?.copyWith(color: foreground, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

class CategoryLabel extends StatelessWidget {
  const CategoryLabel({super.key, required this.category});

  final ItemCategory category;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = AppTheme.categoryColor(category, scheme);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(AppTheme.categoryIcon(category), size: 13, color: color),
        const SizedBox(width: 4),
        Text(
          category.label,
          style: Theme.of(context).textTheme.labelMedium
              ?.copyWith(color: color, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}
