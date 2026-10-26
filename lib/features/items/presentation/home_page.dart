import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/providers.dart';
import '../../../core/widgets/empty_state.dart';
import '../domain/cost_calculations.dart';
import '../domain/item_query.dart';
import '../domain/owned_item.dart';
import '../domain/usage_calculations.dart';
import 'items_providers.dart';
import 'widgets/home_filter_bar.dart';
import 'widgets/item_card.dart';
import 'widgets/overview_panel.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final today = ref.watch(todayProvider);
    final itemsAsync = ref.watch(allItemsProvider);
    final overviewAsync = ref.watch(overviewProvider);
    final usageAsync = ref.watch(usageOverviewProvider);
    final usageCounts = ref.watch(usageCountsProvider);
    final filteredAsync = ref.watch(filteredItemsProvider);
    final filter = ref.watch(homeFilterProvider);

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/items/new'),
        icon: const Icon(Icons.add_rounded),
        label: const Text('添加物品'),
      ),
      body: SafeArea(
        bottom: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: RefreshIndicator(
              onRefresh: () => _refresh(ref),
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics(),
                ),
                slivers: [
                  const SliverPadding(
                    padding: EdgeInsets.fromLTRB(18, 22, 18, 0),
                    sliver: SliverToBoxAdapter(child: _HomeHeader()),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
                    sliver: SliverToBoxAdapter(
                      child: overviewAsync.when(
                        data: (overview) => OverviewPanel(
                          overview: overview,
                          usage:
                              usageAsync.value ?? const UsageOverview.empty(),
                        ),
                        loading: () => const OverviewPanelSkeleton(),
                        error: (error, stackTrace) => const SizedBox.shrink(),
                      ),
                    ),
                  ),
                  ..._buildContent(
                    context: context,
                    ref: ref,
                    today: today,
                    itemsAsync: itemsAsync,
                    filteredAsync: filteredAsync,
                    filterActive: !filter.isDefault,
                    usageCounts: usageCounts,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildContent({
    required BuildContext context,
    required WidgetRef ref,
    required DateTime today,
    required AsyncValue<List<OwnedItem>> itemsAsync,
    required AsyncValue<List<OwnedItem>> filteredAsync,
    required bool filterActive,
    required Map<String, int> usageCounts,
  }) {
    if (itemsAsync.isLoading && !itemsAsync.hasValue) {
      return const [
        SliverFillRemaining(
          hasScrollBody: false,
          child: Padding(
            padding: EdgeInsets.only(bottom: 100),
            child: Center(
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2.4),
              ),
            ),
          ),
        ),
      ];
    }

    if (itemsAsync.hasError && !itemsAsync.hasValue) {
      return [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 80),
            child: InlineErrorView(
              message: '读取本地物品数据时出现问题。你的数据仍保存在设备上。',
              onRetry: () => ref.invalidate(allItemsProvider),
            ),
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 112)),
      ];
    }

    final items = itemsAsync.value ?? const <OwnedItem>[];
    if (items.isEmpty) {
      return [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.only(top: 8, bottom: 72),
            child: EmptyState(
              icon: Icons.confirmation_number_outlined,
              title: '从第一件物品开始',
              message: '记录价格和购买日期，看看它每天值多少钱。',
              action: FilledButton.icon(
                onPressed: () => context.push('/items/new'),
                icon: const Icon(Icons.add_rounded),
                label: const Text('添加第一件物品'),
              ),
            ),
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 112)),
      ];
    }

    final filtered = filteredAsync.value ?? const <OwnedItem>[];
    return [
      const SliverPadding(
        padding: EdgeInsets.fromLTRB(16, 16, 16, 0),
        sliver: SliverToBoxAdapter(child: HomeFilterBar()),
      ),
      SliverPadding(
        padding: const EdgeInsets.fromLTRB(18, 18, 16, 10),
        sliver: SliverToBoxAdapter(
          child: _ResultsHeader(
            count: filtered.length,
            filterActive: filterActive,
            onReset: () => ref.read(homeFilterProvider.notifier).reset(),
          ),
        ),
      ),
      if (filtered.isEmpty)
        SliverToBoxAdapter(
          child: EmptyState(
            compact: true,
            icon: Icons.search_off_rounded,
            title: '没有找到匹配的物品',
            message: '试试其他关键词或分类，也可以清除当前筛选。',
            action: TextButton.icon(
              onPressed: () => ref.read(homeFilterProvider.notifier).reset(),
              icon: const Icon(Icons.filter_alt_off_rounded),
              label: const Text('清除筛选'),
            ),
          ),
        )
      else
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          sliver: SliverList.builder(
            itemCount: filtered.length,
            itemBuilder: (context, index) {
              final item = filtered[index];
              final metrics = calculateItemMetrics(item, today);
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: ItemCard(
                  item: item,
                  metrics: metrics,
                  usageCount: usageCounts[item.id] ?? 0,
                  onTap: () => context.push('/items/${item.id}'),
                ),
              );
            },
          ),
        ),
      const SliverToBoxAdapter(child: SizedBox(height: 112)),
    ];
  }

  Future<void> _refresh(WidgetRef ref) async {
    ref.invalidate(todayProvider);
    ref.invalidate(allItemsProvider);
    try {
      await ref.read(allItemsProvider.future);
    } catch (_) {
      // The error state is rendered by the page.
    }
  }
}

class _HomeHeader extends StatelessWidget {
  const _HomeHeader();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '值回票价',
                style: theme.textTheme.headlineLarge?.copyWith(
                  fontSize: 31,
                  color: scheme.onSurface,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                '把每件物品的成本，摊进每一天',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Container(
          width: 54,
          height: 54,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                scheme.primary,
                Color.lerp(scheme.primary, scheme.secondary, 0.35)!,
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: scheme.primary.withValues(alpha: 0.18),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Icon(
            Icons.confirmation_number_rounded,
            color: scheme.onPrimary,
            size: 27,
          ),
        ),
      ],
    );
  }
}

class _ResultsHeader extends ConsumerWidget {
  const _ResultsHeader({
    required this.count,
    required this.filterActive,
    required this.onReset,
  });

  final int count;
  final bool filterActive;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final filter = ref.watch(homeFilterProvider);
    return Row(
      children: [
        Icon(
          Icons.inventory_2_outlined,
          size: 17,
          color: scheme.onSurfaceVariant,
        ),
        const SizedBox(width: 6),
        Text(
          '物品列表',
          style: theme.textTheme.labelLarge?.copyWith(
            color: scheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(width: 7),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
          decoration: BoxDecoration(
            color: scheme.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            '$count',
            style: theme.textTheme.labelSmall?.copyWith(
              color: scheme.onSurfaceVariant,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const Spacer(),
        PopupMenuButton<ItemSort>(
          tooltip: '排序',
          initialValue: filter.sort,
          onSelected: (value) {
            ref.read(homeFilterProvider.notifier).setSort(value);
          },
          itemBuilder: (context) {
            return [
              for (final sort in ItemSort.values)
                PopupMenuItem<ItemSort>(
                  value: sort,
                  child: Row(
                    children: [
                      Icon(
                        sort == filter.sort
                            ? Icons.check_rounded
                            : Icons.sort_rounded,
                        size: 18,
                        color: sort == filter.sort
                            ? scheme.primary
                            : scheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 10),
                      Text(sort.label),
                    ],
                  ),
                ),
            ];
          },
          child: Container(
            height: 32,
            padding: const EdgeInsets.symmetric(horizontal: 9),
            decoration: BoxDecoration(
              color: scheme.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: scheme.outlineVariant),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.swap_vert_rounded,
                  size: 17,
                  color: scheme.onSurfaceVariant,
                ),
                const SizedBox(width: 3),
                Text(
                  '排序',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
        if (filterActive)
          IconButton(
            onPressed: onReset,
            tooltip: '清除筛选',
            visualDensity: VisualDensity.compact,
            icon: Icon(
              Icons.filter_alt_off_rounded,
              size: 19,
              color: scheme.onSurfaceVariant,
            ),
          ),
      ],
    );
  }
}
