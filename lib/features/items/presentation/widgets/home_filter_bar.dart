import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_theme.dart';
import '../../domain/owned_item.dart';
import '../items_providers.dart';

class HomeFilterBar extends ConsumerStatefulWidget {
  const HomeFilterBar({super.key});

  @override
  ConsumerState<HomeFilterBar> createState() => _HomeFilterBarState();
}

class _HomeFilterBarState extends ConsumerState<HomeFilterBar> {
  late final TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(
      text: ref.read(homeFilterProvider).query,
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filter = ref.watch(homeFilterProvider);
    final scheme = Theme.of(context).colorScheme;

    ref.listen<String>(homeFilterProvider.select((value) => value.query), (
      previous,
      next,
    ) {
      if (_searchController.text != next) {
        _searchController.value = TextEditingValue(
          text: next,
          selection: TextSelection.collapsed(offset: next.length),
        );
      }
    });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _searchController,
          textInputAction: TextInputAction.search,
          onChanged: (value) {
            ref.read(homeFilterProvider.notifier).setQuery(value);
            setState(() {});
          },
          decoration: InputDecoration(
            hintText: '搜索物品名称',
            prefixIcon: const Icon(Icons.search_rounded),
            suffixIcon: filter.query.isEmpty
                ? null
                : IconButton(
                    tooltip: '清除搜索',
                    icon: const Icon(Icons.close_rounded, size: 20),
                    onPressed: () {
                      _searchController.clear();
                      ref.read(homeFilterProvider.notifier).setQuery('');
                      setState(() {});
                    },
                  ),
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 14,
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 38,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              _CategoryChip(
                label: '全部',
                selected: filter.category == null,
                onSelected: () {
                  ref.read(homeFilterProvider.notifier).setCategory(null);
                },
              ),
              for (final category in ItemCategory.values) ...[
                const SizedBox(width: 8),
                _CategoryChip(
                  label: category.label,
                  icon: AppTheme.categoryIcon(category),
                  color: AppTheme.categoryColor(category, scheme),
                  selected: filter.category == category,
                  onSelected: () {
                    ref.read(homeFilterProvider.notifier).setCategory(category);
                  },
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({
    required this.label,
    required this.selected,
    required this.onSelected,
    this.icon,
    this.color,
  });

  final String label;
  final bool selected;
  final VoidCallback onSelected;
  final IconData? icon;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final foreground = selected
        ? scheme.onPrimaryContainer
        : scheme.onSurfaceVariant;
    return Material(
      color: selected ? scheme.primaryContainer : scheme.surfaceContainerLowest,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: selected
              ? scheme.primary.withValues(alpha: 0.32)
              : scheme.outlineVariant,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onSelected,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(
                  icon,
                  size: 15,
                  color: selected ? foreground : (color ?? foreground),
                ),
                const SizedBox(width: 5),
              ],
              Text(
                label,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: foreground,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
