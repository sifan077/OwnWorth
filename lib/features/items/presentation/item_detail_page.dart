import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

import '../../../app/theme/app_theme.dart';
import '../../../core/providers.dart';
import '../../../core/utils/date_utils.dart';
import '../../../core/utils/money.dart';
import '../../../core/widgets/date_picker_sheet.dart';
import '../../../core/widgets/empty_state.dart';
import '../domain/cost_calculations.dart';
import '../domain/item_usage.dart';
import '../domain/owned_item.dart';
import '../domain/usage_calculations.dart';
import 'widgets/status_badge.dart';

class ItemDetailPage extends ConsumerWidget {
  const ItemDetailPage({super.key, required this.itemId});

  final String itemId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final itemAsync = ref.watch(itemByIdProvider(itemId));
    final usagesAsync = ref.watch(itemUsagesProvider(itemId));
    final today = ref.watch(todayProvider);

    return itemAsync.when(
      loading: () => Scaffold(
        appBar: AppBar(title: const Text('物品详情')),
        body: const Center(
          child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(strokeWidth: 2.4),
          ),
        ),
      ),
      error: (error, stackTrace) => Scaffold(
        appBar: AppBar(title: const Text('物品详情')),
        body: InlineErrorView(
          message: '读取物品信息失败。',
          onRetry: () => ref.invalidate(itemByIdProvider(itemId)),
        ),
      ),
      data: (item) {
        if (item == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('物品详情')),
            body: EmptyState(
              icon: Icons.inventory_2_outlined,
              title: '找不到这件物品',
              message: '它可能已经被删除。',
              action: FilledButton.tonal(
                onPressed: () => context.go('/'),
                child: const Text('返回首页'),
              ),
            ),
          );
        }
        return _ItemDetailView(
          item: item,
          usages: usagesAsync.value ?? const <ItemUsage>[],
          usage: calculateUsageMetrics(
            item: item,
            usages: usagesAsync.value ?? const <ItemUsage>[],
            today: today,
          ),
          metrics: calculateItemMetrics(item, today),
          today: today,
        );
      },
    );
  }
}

class _ItemDetailView extends ConsumerStatefulWidget {
  const _ItemDetailView({
    required this.item,
    required this.metrics,
    required this.usages,
    required this.usage,
    required this.today,
  });

  final OwnedItem item;
  final ItemMetrics metrics;
  final List<ItemUsage> usages;
  final UsageMetrics usage;
  final DateTime today;

  @override
  ConsumerState<_ItemDetailView> createState() => _ItemDetailViewState();
}

class _ItemDetailViewState extends ConsumerState<_ItemDetailView> {
  bool _busy = false;
  bool _usageBusy = false;

  OwnedItem get item => widget.item;
  ItemMetrics get metrics => widget.metrics;
  UsageMetrics get usage => widget.usage;
  List<ItemUsage> get usages => widget.usages;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final target = metrics.target;

    return Scaffold(
      appBar: AppBar(
        title: const Text('物品详情'),
        actions: [
          IconButton(
            tooltip: '编辑',
            onPressed: _busy
                ? null
                : () => context.push('/items/${item.id}/edit'),
            icon: const Icon(Icons.edit_outlined),
          ),
          PopupMenuButton<_DetailAction>(
            enabled: !_busy,
            tooltip: '更多',
            onSelected: (action) {
              switch (action) {
                case _DetailAction.delete:
                  _deleteItem();
              }
            },
            itemBuilder: (context) {
              return [
                PopupMenuItem(
                  value: _DetailAction.delete,
                  child: Row(
                    children: [
                      Icon(Icons.delete_outline_rounded, color: scheme.error),
                      const SizedBox(width: 10),
                      Text('删除物品', style: TextStyle(color: scheme.error)),
                    ],
                  ),
                ),
              ];
            },
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            if (_busy) const LinearProgressIndicator(minHeight: 2),
            Expanded(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 720),
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 36),
                    children: [
                      _HeroImage(item: item),
                      const SizedBox(height: 18),
                      Text(
                        item.name,
                        style: theme.textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 12,
                        runSpacing: 6,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          CategoryLabel(category: item.category),
                          StatusBadge(status: item.status),
                          Text(
                            '购入于 ${formatChineseDate(item.purchaseDate)}',
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 22),
                      _DailyCostPanel(item: item, metrics: metrics),
                      const SizedBox(height: 14),
                      _UsagePanel(
                        usage: usage,
                        active: item.isActive,
                        canRecord: item.isActive && !_usageBusy,
                        onRecord: _recordUsage,
                        onUndo: _usageBusy || usages.isEmpty
                            ? null
                            : _undoLastUsage,
                      ),
                      const SizedBox(height: 14),
                      if (target != null)
                        _TargetPanel(item: item, target: target)
                      else
                        _NoTargetPanel(
                          onSetTarget: _busy
                              ? null
                              : () => context.push('/items/${item.id}/edit'),
                        ),
                      const SizedBox(height: 14),
                      _MetaPanel(item: item),
                      if (item.note != null && item.note!.isNotEmpty) ...[
                        const SizedBox(height: 14),
                        _NotePanel(note: item.note!),
                      ],
                      const SizedBox(height: 22),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: _busy
                                  ? null
                                  : () =>
                                        context.push('/items/${item.id}/edit'),
                              icon: const Icon(Icons.edit_outlined),
                              label: const Text('编辑'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 2,
                            child: FilledButton.tonalIcon(
                              onPressed: _busy
                                  ? null
                                  : item.isActive
                                  ? _endUse
                                  : _reactivate,
                              icon: Icon(
                                item.isActive
                                    ? Icons.stop_circle_outlined
                                    : Icons.play_circle_outline_rounded,
                              ),
                              label: Text(item.isActive ? '结束使用' : '重新启用'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _endUse() async {
    final selected = await _showEndDateDialog();
    if (selected == null || !mounted) {
      return;
    }
    final updated = item.copyWith(
      status: ItemStatus.ended,
      endDate: selected,
      updatedAt: DateTime.now().toUtc(),
    );
    await _saveUpdate(updated, successMessage: '已结束使用，日均成本将保持不变。');
  }

  Future<DateTime?> _showEndDateDialog() async {
    final today = normalizeDate(widget.today);
    var selected = today;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final firstDate = normalizeDate(item.purchaseDate);
    if (selected.isBefore(firstDate)) {
      selected = firstDate;
    }

    return showDialog<DateTime>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('结束使用'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '选择结束日期后，持有天数和日均成本会固定下来，不再继续变化。之后仍可重新启用。',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Material(
                    color: scheme.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(14),
                    clipBehavior: Clip.antiAlias,
                    child: InkWell(
                      onTap: () async {
                        final picked = await showAppDatePicker(
                          context: dialogContext,
                          initialDate: selected,
                          firstDate: firstDate,
                          lastDate: today,
                          title: '选择结束日期',
                          description: '不能早于购买日期，也不能晚于今天。',
                          referenceDate: today,
                          previewBuilder: (date) {
                            final days = daysBetweenCalendar(
                              item.purchaseDate,
                              date,
                            );
                            return days <= 0 ? '当天结束使用' : '共使用 $days 天';
                          },
                        );
                        if (picked != null) {
                          setDialogState(() {
                            selected = normalizeDate(picked);
                          });
                        }
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Row(
                          children: [
                            Icon(
                              Icons.event_available_outlined,
                              color: scheme.primary,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                formatChineseDate(selected),
                                style: AppTheme.tabular(
                                  theme.textTheme.titleMedium,
                                ),
                              ),
                            ),
                            Icon(
                              Icons.chevron_right_rounded,
                              color: scheme.onSurfaceVariant,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('取消'),
                ),
                FilledButton.tonal(
                  onPressed: () => Navigator.of(dialogContext).pop(selected),
                  child: const Text('确认结束'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _reactivate() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('重新启用？'),
          content: const Text('重新启用后，持有天数和日均成本会继续随时间变化。'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('取消'),
            ),
            FilledButton.tonal(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('重新启用'),
            ),
          ],
        );
      },
    );
    if (confirmed != true || !mounted) {
      return;
    }
    final updated = item.copyWith(
      status: ItemStatus.active,
      endDate: null,
      updatedAt: DateTime.now().toUtc(),
    );
    await _saveUpdate(updated, successMessage: '已重新启用');
  }

  Future<void> _recordUsage() async {
    if (_usageBusy || !item.isActive) {
      return;
    }
    setState(() => _usageBusy = true);
    try {
      await ref
          .read(itemRepositoryProvider)
          .saveUsage(
            ItemUsage(
              id: const Uuid().v4(),
              itemId: item.id,
              usedAt: DateTime.now().toUtc(),
            ),
          );
      if (mounted) {
        _showMessage('已记录一次使用');
      }
    } catch (error) {
      if (mounted) {
        _showMessage('记录失败，请重试。');
      }
    } finally {
      if (mounted) {
        setState(() => _usageBusy = false);
      }
    }
  }

  Future<void> _undoLastUsage() async {
    if (_usageBusy || usages.isEmpty) {
      return;
    }
    final latest = usages.first;
    setState(() => _usageBusy = true);
    try {
      await ref.read(itemRepositoryProvider).deleteUsageById(latest.id);
      if (mounted) {
        _showMessage('已撤销最近一次使用记录');
      }
    } catch (error) {
      if (mounted) {
        _showMessage('撤销失败，请重试。');
      }
    } finally {
      if (mounted) {
        setState(() => _usageBusy = false);
      }
    }
  }

  Future<void> _saveUpdate(
    OwnedItem updated, {
    required String successMessage,
  }) async {
    setState(() => _busy = true);
    try {
      await ref.read(itemRepositoryProvider).save(updated);
      if (mounted) {
        _showMessage(successMessage);
      }
    } catch (error) {
      if (mounted) {
        _showMessage('操作失败，请重试。');
      }
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  Future<void> _deleteItem() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        final scheme = Theme.of(dialogContext).colorScheme;
        return AlertDialog(
          title: Text('删除「${item.name}」？'),
          content: const Text('这件物品的记录和图片会被永久删除，此操作无法撤销。'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('取消'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: scheme.error,
                foregroundColor: scheme.onError,
              ),
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('删除'),
            ),
          ],
        );
      },
    );
    if (confirmed != true || !mounted) {
      return;
    }

    setState(() => _busy = true);
    final imagePath = item.imagePath;
    try {
      await ref.read(itemRepositoryProvider).deleteById(item.id);
      if (imagePath != null) {
        try {
          await ref.read(imageStoreProvider).delete(imagePath);
        } catch (_) {
          // Orphan cleanup runs at startup.
        }
      }
      if (!mounted) {
        return;
      }
      final messenger = ScaffoldMessenger.of(context);
      context.go('/');
      messenger.showSnackBar(SnackBar(content: Text('已删除「${item.name}」')));
    } catch (error) {
      if (mounted) {
        setState(() => _busy = false);
        _showMessage('删除失败，请重试。');
      }
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }
}

enum _DetailAction { delete }

class _HeroImage extends ConsumerWidget {
  const _HeroImage({required this.item});

  final OwnedItem item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final store = ref.watch(imageStoreProvider);
    final path = item.imagePath;
    final hasImage = path != null && store.exists(path);
    final color = AppTheme.categoryColor(item.category, scheme);

    Widget content;
    if (hasImage) {
      content = Image.file(
        File(store.fileFor(path).path),
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        errorBuilder: (context, error, stackTrace) =>
            _placeholder(context, color),
      );
    } else {
      content = _placeholder(context, color);
    }

    return AspectRatio(
      aspectRatio: 16 / 9,
      child: Hero(
        tag: 'item-image-${item.id}',
        child: Material(
          type: MaterialType.transparency,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Stack(
              fit: StackFit.expand,
              children: [
                content,
                Positioned(
                  top: 12,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 2,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: scheme.surface.withValues(alpha: 0.9),
                      borderRadius: BorderRadius.circular(9),
                    ),
                    child: StatusBadge(status: item.status),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _placeholder(BuildContext context, Color color) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color.withValues(alpha: 0.2),
            color.withValues(alpha: 0.06),
            scheme.surfaceContainerLow,
          ],
        ),
      ),
      child: Center(
        child: Icon(
          AppTheme.categoryIcon(item.category),
          size: 72,
          color: color.withValues(alpha: 0.8),
        ),
      ),
    );
  }
}

class _DailyCostPanel extends StatelessWidget {
  const _DailyCostPanel({required this.item, required this.metrics});

  final OwnedItem item;
  final ItemMetrics metrics;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: scheme.outlineVariant),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            scheme.primaryContainer.withValues(alpha: 0.7),
            scheme.surfaceContainerLowest,
          ],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                '当前日均成本',
                style: theme.textTheme.labelLarge?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
              const Spacer(),
              if (!item.isActive)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: scheme.surface.withValues(alpha: 0.7),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: scheme.outlineVariant),
                  ),
                  child: Text(
                    '已固定',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
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
                    theme.textTheme.displaySmall!.copyWith(
                      fontSize: 44,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -1.4,
                      color: scheme.onSurface,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  '/ 天',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 5),
          Text(
            item.isActive
                ? '购买成本按持有天数持续摊薄'
                : '已于 ${formatChineseDate(item.endDate!)} 结束使用，成本不再变化',
            style: theme.textTheme.bodySmall?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),
          Divider(color: scheme.outlineVariant),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _InfoValue(
                  label: '购入价格',
                  value: formatYuan(item.purchasePriceCents),
                ),
              ),
              Expanded(
                child: _InfoValue(
                  label: '已经持有',
                  value: '${metrics.heldDays} 天',
                ),
              ),
              Expanded(
                child: _InfoValue(
                  label: '购入日期',
                  value: formatIsoDate(item.purchaseDate),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _InfoValue extends StatelessWidget {
  const _InfoValue({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: scheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 3),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(
            value,
            style: AppTheme.tabular(
              theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
            ),
          ),
        ),
      ],
    );
  }
}

class _UsagePanel extends StatelessWidget {
  const _UsagePanel({
    required this.usage,
    required this.active,
    required this.canRecord,
    required this.onRecord,
    required this.onUndo,
  });

  final UsageMetrics usage;

  /// Whether the item is still active. Ended items keep their history but
  /// cannot record new uses.
  final bool active;
  final bool canRecord;
  final VoidCallback? onRecord;
  final VoidCallback? onUndo;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final lastUsed = usage.lastUsedAt;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: scheme.secondaryContainer,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.touch_app_rounded,
                  size: 19,
                  color: scheme.onSecondaryContainer,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('使用统计', style: theme.textTheme.titleSmall),
                    const SizedBox(height: 2),
                    Text(
                      usage.hasUsage ? '按每次使用记录实时统计' : '每用一次记一下，算出单次成本',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              FilledButton.tonalIcon(
                onPressed: canRecord ? onRecord : null,
                style: FilledButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                ),
                icon: const Icon(Icons.add_rounded, size: 18),
                label: const Text('用一次'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '累计使用',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 1),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          '${usage.totalCount}',
                          style: AppTheme.tabular(
                            theme.textTheme.displaySmall!.copyWith(
                              fontSize: 36,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -1,
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '次',
                          style: theme.textTheme.titleSmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '单次使用成本',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    usage.costPerUseCents == null
                        ? '—'
                        : formatYuan(usage.costPerUseCents!),
                    style: AppTheme.tabular(
                      theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: usage.hasUsage
                            ? scheme.primary
                            : scheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: scheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _UsageFact(
                    label: '本月使用',
                    value: '${usage.monthCount} 次',
                  ),
                ),
                Expanded(
                  child: _UsageFact(
                    label: '最近一次',
                    value: lastUsed == null
                        ? '暂无记录'
                        : formatChineseDate(lastUsed),
                  ),
                ),
              ],
            ),
          ),
          if (usage.hasUsage)
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: onUndo,
                style: TextButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  foregroundColor: scheme.onSurfaceVariant,
                ),
                icon: const Icon(Icons.undo_rounded, size: 17),
                label: const Text('撤销最近一次'),
              ),
            ),
          if (!active) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(
                  Icons.info_outline_rounded,
                  size: 14,
                  color: scheme.onSurfaceVariant,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    '物品已结束使用，重新启用后可继续记录。',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _UsageFact extends StatelessWidget {
  const _UsageFact({required this.label, required this.value});

  final String label;
  final String value;

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
            style: AppTheme.tabular(
              theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
            ),
          ),
        ),
      ],
    );
  }
}

class _TargetPanel extends StatelessWidget {
  const _TargetPanel({required this.item, required this.target});

  final OwnedItem item;
  final TargetMetrics target;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final endedBeforeGoal = !item.isActive && !target.achieved;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: scheme.secondaryContainer,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.flag_rounded,
                  size: 19,
                  color: scheme.onSecondaryContainer,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('目标日均成本', style: theme.textTheme.labelMedium),
                    Text(
                      '${formatYuan(item.targetDailyCostCents!)} / 天',
                      style: AppTheme.tabular(
                        theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                formatProgressPercent(target.progress),
                style: AppTheme.tabular(
                  theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: target.achieved
                        ? scheme.primary
                        : endedBeforeGoal
                        ? scheme.error
                        : scheme.onSurface,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: target.progress,
              minHeight: 8,
              backgroundColor: scheme.surfaceContainerHigh,
              color: target.achieved
                  ? scheme.primary
                  : endedBeforeGoal
                  ? scheme.error
                  : scheme.primary.withValues(alpha: 0.8),
            ),
          ),
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: endedBeforeGoal
                  ? scheme.errorContainer.withValues(alpha: 0.42)
                  : scheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(
                  target.achieved
                      ? Icons.check_circle_rounded
                      : endedBeforeGoal
                      ? Icons.cancel_outlined
                      : Icons.timelapse_rounded,
                  size: 19,
                  color: target.achieved
                      ? scheme.primary
                      : endedBeforeGoal
                      ? scheme.error
                      : scheme.onSurfaceVariant,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _statusText(endedBeforeGoal),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: endedBeforeGoal
                          ? scheme.error
                          : target.achieved
                          ? scheme.primary
                          : scheme.onSurface,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          _TargetRow(
            label: endedBeforeGoal ? '原预计达成日期' : '目标达成日期',
            value: formatChineseDate(target.targetDate),
          ),
          const SizedBox(height: 8),
          _TargetRow(label: '达成所需总天数', value: '${target.requiredDays} 天'),
          if (endedBeforeGoal) ...[
            const SizedBox(height: 8),
            _TargetRow(label: '结束时所差天数', value: '${target.remainingDays} 天'),
          ],
        ],
      ),
    );
  }

  String _statusText(bool endedBeforeGoal) {
    if (target.achieved) {
      return '目标已达成';
    }
    if (endedBeforeGoal) {
      return '未达成';
    }
    return '预计还需要 ${target.remainingDays} 天';
  }
}

class _TargetRow extends StatelessWidget {
  const _TargetRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Row(
      children: [
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: scheme.onSurfaceVariant,
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: AppTheme.tabular(
            theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }
}

class _NoTargetPanel extends StatelessWidget {
  const _NoTargetPanel({required this.onSetTarget});

  final VoidCallback? onSetTarget;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Row(
        children: [
          Icon(Icons.flag_outlined, color: scheme.onSurfaceVariant, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('还没有设置目标', style: theme.textTheme.titleSmall),
                const SizedBox(height: 3),
                Text(
                  '设置目标日均成本，看看还需要用多久。',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          TextButton(onPressed: onSetTarget, child: const Text('去设置')),
        ],
      ),
    );
  }
}

class _MetaPanel extends StatelessWidget {
  const _MetaPanel({required this.item});

  final OwnedItem item;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Column(
        children: [
          _MetaRow(
            icon: Icons.category_outlined,
            label: '分类',
            value: item.category.label,
          ),
          Divider(color: scheme.outlineVariant),
          _MetaRow(
            icon: Icons.calendar_month_outlined,
            label: '购入日期',
            value: formatChineseDate(item.purchaseDate),
          ),
          if (item.endDate != null) ...[
            Divider(color: scheme.outlineVariant),
            _MetaRow(
              icon: Icons.event_busy_outlined,
              label: '结束日期',
              value: formatChineseDate(item.endDate!),
            ),
          ],
        ],
      ),
    );
  }
}

class _MetaRow extends StatelessWidget {
  const _MetaRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Icon(icon, size: 19, color: scheme.onSurfaceVariant),
          const SizedBox(width: 10),
          Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
          const Spacer(),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: AppTheme.tabular(
                theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NotePanel extends StatelessWidget {
  const _NotePanel({required this.note});

  final String note;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.sticky_note_2_outlined,
                size: 18,
                color: scheme.onSurfaceVariant,
              ),
              const SizedBox(width: 8),
              Text('备注', style: theme.textTheme.titleSmall),
            ],
          ),
          const SizedBox(height: 9),
          Text(
            note,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: scheme.onSurfaceVariant,
              height: 1.55,
            ),
          ),
        ],
      ),
    );
  }
}
