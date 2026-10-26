import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';

import '../../../app/theme/app_theme.dart';
import '../../../core/providers.dart';
import '../../../core/utils/date_utils.dart';
import '../../../core/utils/money.dart';
import '../../../core/widgets/date_picker_sheet.dart';
import '../../../core/widgets/empty_state.dart';
import '../domain/owned_item.dart';

class ItemFormPage extends ConsumerWidget {
  const ItemFormPage({super.key, this.itemId});

  final String? itemId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (itemId == null) {
      return const ItemFormScaffold();
    }

    final itemAsync = ref.watch(itemByIdProvider(itemId!));
    return itemAsync.when(
      data: (item) {
        if (item == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('编辑物品')),
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
        return ItemFormScaffold(key: ValueKey(item.id), initialItem: item);
      },
      loading: () => Scaffold(
        appBar: AppBar(title: const Text('编辑物品')),
        body: const Center(
          child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(strokeWidth: 2.4),
          ),
        ),
      ),
      error: (error, stackTrace) => Scaffold(
        appBar: AppBar(title: const Text('编辑物品')),
        body: InlineErrorView(
          message: '读取物品信息失败。',
          onRetry: () => ref.invalidate(itemByIdProvider(itemId!)),
        ),
      ),
    );
  }
}

class ItemFormScaffold extends ConsumerStatefulWidget {
  const ItemFormScaffold({super.key, this.initialItem});

  final OwnedItem? initialItem;

  @override
  ConsumerState<ItemFormScaffold> createState() => _ItemFormScaffoldState();
}

class _ItemFormScaffoldState extends ConsumerState<ItemFormScaffold> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _priceController = TextEditingController();
  final _targetController = TextEditingController();
  final _noteController = TextEditingController();
  final _imagePicker = ImagePicker();

  late DateTime _purchaseDate;
  late ItemCategory _category;

  Uint8List? _pickedImageBytes;
  String? _pickedImageName;
  bool _removeExistingImage = false;
  bool _saving = false;
  bool _dirty = false;

  OwnedItem? get _initial => widget.initialItem;
  bool get _isEditing => _initial != null;

  @override
  void initState() {
    super.initState();
    final item = _initial;
    final targetCents = item?.targetDailyCostCents;
    _nameController.text = item?.name ?? '';
    _priceController.text = item == null
        ? ''
        : yuanInputFromCents(item.purchasePriceCents);
    _targetController.text = targetCents == null
        ? ''
        : yuanInputFromCents(targetCents);
    _noteController.text = item?.note ?? '';
    _purchaseDate = normalizeDate(item?.purchaseDate ?? currentLocalDate());
    _category = item?.category ?? ItemCategory.other;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _targetController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  void _markDirty() {
    if (!_dirty) {
      setState(() => _dirty = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final today = ref.watch(todayProvider);

    return PopScope(
      canPop: !_dirty && !_saving,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop || _saving) {
          return;
        }
        final discard = await _confirmDiscard();
        if (discard && mounted) {
          Navigator.of(this.context).pop();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            tooltip: '关闭',
            onPressed: _saving ? null : _handleClose,
            icon: const Icon(Icons.close_rounded),
          ),
          title: Text(_isEditing ? '编辑物品' : '添加物品'),
        ),
        body: Form(
          key: _formKey,
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 680),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(18, 8, 18, 28),
                children: [
                  _ImageEditor(
                    category: _category,
                    existingImagePath: _removeExistingImage
                        ? null
                        : _initial?.imagePath,
                    pickedBytes: _pickedImageBytes,
                    onPick: _pickImage,
                    onRemove: _removeImage,
                    enabled: !_saving,
                  ),
                  const SizedBox(height: 26),
                  _SectionTitle(title: '基本信息', subtitle: '价格和日期会用于计算日均成本。'),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _nameController,
                    enabled: !_saving,
                    textInputAction: TextInputAction.next,
                    maxLength: 60,
                    onChanged: (_) => _markDirty(),
                    decoration: const InputDecoration(
                      labelText: '物品名称',
                      hintText: '例如：降噪耳机',
                      counterText: '',
                      prefixIcon: Icon(Icons.label_outline_rounded),
                    ),
                    validator: (value) {
                      final trimmed = value?.trim() ?? '';
                      if (trimmed.isEmpty) {
                        return '请填写物品名称';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _priceController,
                    enabled: !_saving,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    textInputAction: TextInputAction.next,
                    inputFormatters: const [_AmountInputFormatter()],
                    onChanged: (_) => _markDirty(),
                    decoration: const InputDecoration(
                      labelText: '购买价格',
                      hintText: '0.00',
                      prefixText: '¥ ',
                      helperText: '人民币，最多两位小数',
                      prefixIcon: Icon(Icons.payments_outlined),
                    ),
                    validator: (value) {
                      if (parseYuanToCents(value ?? '') == null) {
                        return '请输入大于 0 的有效金额';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 14),
                  _DateField(
                    label: '购买日期',
                    value: _purchaseDate,
                    hint: describeHoldingPeriod(_purchaseDate, today),
                    onTap: _saving ? null : _pickPurchaseDate,
                  ),
                  if (_isEditing && _initial!.status == ItemStatus.ended) ...[
                    const SizedBox(height: 8),
                    _InfoNote(
                      icon: Icons.lock_clock_rounded,
                      text:
                          '这件物品已结束使用（${formatIsoDate(_initial!.endDate!)}），日均成本已固定。如需重新启用，请回到详情页操作。',
                    ),
                  ],
                  const SizedBox(height: 26),
                  const _SectionTitle(title: '分类', subtitle: '用于筛选和整理你的物品。'),
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final category in ItemCategory.values)
                        _CategoryOption(
                          category: category,
                          selected: category == _category,
                          onTap: _saving
                              ? null
                              : () {
                                  setState(() => _category = category);
                                  _markDirty();
                                },
                        ),
                    ],
                  ),
                  const SizedBox(height: 26),
                  const _SectionTitle(
                    title: '目标日均成本',
                    subtitle: '可选。设置一个目标，观察成本何时摊薄到目标以下。',
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _targetController,
                    enabled: !_saving,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    textInputAction: TextInputAction.next,
                    inputFormatters: const [_AmountInputFormatter()],
                    onChanged: (_) => _markDirty(),
                    decoration: const InputDecoration(
                      labelText: '目标金额（可选）',
                      hintText: '例如 10.00',
                      prefixText: '¥ ',
                      suffixText: '/ 天',
                      helperText: '留空表示不设置目标',
                      prefixIcon: Icon(Icons.flag_outlined),
                    ),
                    validator: (value) {
                      final text = value?.trim() ?? '';
                      if (text.isEmpty) {
                        return null;
                      }
                      if (parseYuanToCents(text) == null) {
                        return '请输入大于 0 的有效金额';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 26),
                  const _SectionTitle(title: '备注', subtitle: '记录型号、购买渠道或其他信息。'),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _noteController,
                    enabled: !_saving,
                    minLines: 3,
                    maxLines: 6,
                    maxLength: 500,
                    textInputAction: TextInputAction.newline,
                    onChanged: (_) => _markDirty(),
                    decoration: const InputDecoration(
                      labelText: '备注（可选）',
                      hintText: '写点什么……',
                      alignLabelWithHint: true,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        bottomNavigationBar: Container(
          decoration: BoxDecoration(
            color: scheme.surface,
            border: Border(top: BorderSide(color: scheme.outlineVariant)),
          ),
          child: SafeArea(
            top: false,
            minimum: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: Align(
              alignment: Alignment.center,
              heightFactor: 1,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 680),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _saving ? null : _handleClose,
                        child: const Text('取消'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: FilledButton.icon(
                        onPressed: _saving ? null : _save,
                        icon: _saving
                            ? SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: scheme.onPrimary,
                                ),
                              )
                            : const Icon(Icons.check_rounded),
                        label: Text(_saving ? '保存中…' : '保存'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _handleClose() async {
    if (_saving) {
      return;
    }
    if (!_dirty) {
      Navigator.of(context).pop();
      return;
    }
    final discard = await _confirmDiscard();
    if (discard && mounted) {
      Navigator.of(context).pop();
    }
  }

  Future<bool> _confirmDiscard() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('放弃未保存的修改？'),
          content: const Text('当前填写的内容还没有保存。'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('继续编辑'),
            ),
            FilledButton.tonal(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('放弃修改'),
            ),
          ],
        );
      },
    );
    return result ?? false;
  }

  Future<void> _pickImage() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.photo_library_outlined),
                  title: const Text('从相册选择'),
                  onTap: () => Navigator.of(context).pop(ImageSource.gallery),
                ),
                ListTile(
                  leading: const Icon(Icons.photo_camera_outlined),
                  title: const Text('拍照'),
                  onTap: () => Navigator.of(context).pop(ImageSource.camera),
                ),
              ],
            ),
          ),
        );
      },
    );
    if (source == null || !mounted) {
      return;
    }

    try {
      final picked = await _imagePicker.pickImage(
        source: source,
        maxWidth: 2000,
        maxHeight: 2000,
        imageQuality: 88,
        requestFullMetadata: false,
      );
      if (picked == null) {
        return;
      }
      final bytes = await picked.readAsBytes();
      if (bytes.isEmpty) {
        throw const FormatException('图片内容为空');
      }
      if (bytes.length > 25 * 1024 * 1024) {
        _showMessage('图片过大，请选择 25MB 以内的图片。');
        return;
      }
      if (!mounted) {
        return;
      }
      setState(() {
        _pickedImageBytes = bytes;
        _pickedImageName = picked.name.isNotEmpty ? picked.name : picked.path;
        _removeExistingImage = false;
        _dirty = true;
      });
    } catch (error) {
      if (mounted) {
        _showMessage('无法读取所选图片，请重试。');
      }
    }
  }

  void _removeImage() {
    setState(() {
      _pickedImageBytes = null;
      _pickedImageName = null;
      _removeExistingImage = true;
      _dirty = true;
    });
  }

  Future<void> _pickPurchaseDate() async {
    final today = ref.read(todayProvider);
    final endDate = _initial?.endDate;
    var lastDate = today;
    if (_initial?.status == ItemStatus.ended &&
        endDate != null &&
        endDate.isBefore(today)) {
      lastDate = endDate;
    }
    final picked = await showAppDatePicker(
      context: context,
      initialDate: _purchaseDate,
      firstDate: DateTime.utc(1970),
      lastDate: lastDate,
      title: '选择购买日期',
      description: '购买日期决定日均成本从哪天开始摊薄，不能晚于今天。',
      referenceDate: today,
      previewBuilder: (date) => describeHoldingPeriod(date, today),
    );
    if (picked != null && mounted) {
      setState(() {
        _purchaseDate = normalizeDate(picked);
        _dirty = true;
      });
    }
  }

  Future<void> _save() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final priceCents = parseYuanToCents(_priceController.text);
    final targetText = _targetController.text.trim();
    final targetCents = targetText.isEmpty
        ? null
        : parseYuanToCents(targetText);
    if (priceCents == null || (targetText.isNotEmpty && targetCents == null)) {
      return;
    }

    final endDate = _initial?.endDate;
    if (_initial?.status == ItemStatus.ended &&
        endDate != null &&
        _purchaseDate.isAfter(endDate)) {
      _showMessage('购买日期不能晚于结束日期。');
      return;
    }

    setState(() => _saving = true);
    final imageStore = ref.read(imageStoreProvider);
    String? savedImagePath;
    var didSave = false;

    try {
      if (_pickedImageBytes != null) {
        savedImagePath = await imageStore.saveBytes(
          _pickedImageBytes!,
          sourceName: _pickedImageName ?? 'image.jpg',
        );
      }

      final now = DateTime.now().toUtc();
      final oldImagePath = _initial?.imagePath;
      final nextImagePath =
          savedImagePath ?? (_removeExistingImage ? null : oldImagePath);
      final note = _noteController.text.trim();
      final item = OwnedItem(
        id: _initial?.id ?? const Uuid().v4(),
        name: _nameController.text.trim(),
        purchasePriceCents: priceCents,
        purchaseDate: _purchaseDate,
        category: _category,
        imagePath: nextImagePath,
        targetDailyCostCents: targetCents,
        status: _initial?.status ?? ItemStatus.active,
        endDate: _initial?.endDate,
        note: note.isEmpty ? null : note,
        createdAt: _initial?.createdAt ?? now,
        updatedAt: now,
      );

      await ref.read(itemRepositoryProvider).save(item);

      if (oldImagePath != null && oldImagePath != nextImagePath) {
        try {
          await imageStore.delete(oldImagePath);
        } catch (_) {
          // Startup cleanup removes orphans if this fails.
        }
      }

      if (!mounted) {
        return;
      }
      setState(() {
        _dirty = false;
        _saving = false;
      });
      didSave = true;
      final messenger = ScaffoldMessenger.of(context);
      Navigator.of(context).pop();
      messenger.showSnackBar(
        SnackBar(content: Text(_isEditing ? '已保存修改' : '已添加「${item.name}」')),
      );
    } catch (error) {
      if (savedImagePath != null) {
        try {
          await imageStore.delete(savedImagePath);
        } catch (_) {
          // Ignore cleanup failure; the save itself already failed.
        }
      }
      if (mounted) {
        _showMessage('保存失败，请稍后重试。');
      }
    } finally {
      if (mounted && !didSave) {
        setState(() => _saving = false);
      }
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }
}

class _ImageEditor extends ConsumerWidget {
  const _ImageEditor({
    required this.category,
    required this.existingImagePath,
    required this.pickedBytes,
    required this.onPick,
    required this.onRemove,
    required this.enabled,
  });

  final ItemCategory category;
  final String? existingImagePath;
  final Uint8List? pickedBytes;
  final VoidCallback onPick;
  final VoidCallback onRemove;
  final bool enabled;

  bool get _hasImage => pickedBytes != null || existingImagePath != null;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final store = ref.watch(imageStoreProvider);
    final hasExisting =
        existingImagePath != null && store.exists(existingImagePath!);

    Widget image;
    if (pickedBytes != null) {
      image = Image.memory(
        pickedBytes!,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        gaplessPlayback: true,
      );
    } else if (hasExisting) {
      image = Image.file(
        File(store.fileFor(existingImagePath!).path),
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        errorBuilder: (context, error, stackTrace) =>
            _placeholder(context, category),
      );
    } else {
      image = _placeholder(context, category);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AspectRatio(
          aspectRatio: 16 / 9,
          child: Material(
            color: scheme.surfaceContainerLow,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(22),
              side: BorderSide(color: scheme.outlineVariant),
            ),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: enabled ? onPick : null,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  image,
                  if (_hasImage)
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      child: Container(
                        padding: const EdgeInsets.fromLTRB(12, 30, 12, 10),
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [Colors.transparent, Color(0xB3000000)],
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            _OverlayAction(
                              icon: Icons.photo_camera_back_outlined,
                              label: '更换',
                              onTap: enabled ? onPick : null,
                            ),
                            const SizedBox(width: 8),
                            _OverlayAction(
                              icon: Icons.delete_outline_rounded,
                              label: '移除',
                              onTap: enabled ? onRemove : null,
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    const Positioned(
                      right: 14,
                      top: 14,
                      child: _AddPhotoHint(),
                    ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          _hasImage ? '点击图片可更换照片' : '添加一张照片，之后更容易认出它（可选）',
          style: Theme.of(context).textTheme.labelSmall
              ?.copyWith(color: scheme.onSurfaceVariant),
        ),
      ],
    );
  }

  Widget _placeholder(BuildContext context, ItemCategory category) {
    final scheme = Theme.of(context).colorScheme;
    final color = AppTheme.categoryColor(category, scheme);
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [color.withValues(alpha: 0.16), scheme.surfaceContainerLow],
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(AppTheme.categoryIcon(category), size: 44, color: color),
          const SizedBox(height: 10),
          Text(
            '添加物品图片',
            style: Theme.of(context).textTheme.labelLarge
                ?.copyWith(color: scheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

class _AddPhotoHint extends StatelessWidget {
  const _AddPhotoHint();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: scheme.surface.withValues(alpha: 0.82),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.add_a_photo_outlined, size: 14, color: scheme.primary),
          const SizedBox(width: 4),
          Text(
            '照片',
            style: Theme.of(context).textTheme.labelSmall
                ?.copyWith(color: scheme.primary, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

class _OverlayAction extends StatelessWidget {
  const _OverlayAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withValues(alpha: 0.45),
      borderRadius: BorderRadius.circular(999),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 14, color: Colors.white),
              const SizedBox(width: 4),
              Text(
                label,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, this.subtitle});

  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: theme.textTheme.titleMedium),
        if (subtitle != null) ...[
          const SizedBox(height: 3),
          Text(
            subtitle!,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ],
    );
  }
}

class _DateField extends StatelessWidget {
  const _DateField({
    required this.label,
    required this.value,
    required this.onTap,
    this.hint,
  });

  final String label;
  final DateTime value;
  final String? hint;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Material(
      color: scheme.surfaceContainerLowest,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: scheme.outlineVariant),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
          child: Row(
            children: [
              Icon(
                Icons.calendar_today_outlined,
                size: 20,
                color: scheme.onSurfaceVariant,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      formatChineseDate(value),
                      style: AppTheme.tabular(
                        theme.textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (hint != null && hint!.isNotEmpty) ...[
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: scheme.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    hint!,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 4),
              ],
              Icon(Icons.chevron_right_rounded, color: scheme.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}

class _CategoryOption extends StatelessWidget {
  const _CategoryOption({
    required this.category,
    required this.selected,
    required this.onTap,
  });

  final ItemCategory category;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final color = AppTheme.categoryColor(category, scheme);
    return Material(
      color: selected
          ? scheme.primaryContainer.withValues(alpha: 0.8)
          : scheme.surfaceContainerLowest,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: selected
              ? scheme.primary.withValues(alpha: 0.5)
              : scheme.outlineVariant,
          width: selected ? 1.4 : 1,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          width: 94,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 11),
            child: Column(
              children: [
                Icon(AppTheme.categoryIcon(category), size: 21, color: color),
                const SizedBox(height: 5),
                Text(
                  category.label,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: selected
                        ? scheme.onPrimaryContainer
                        : scheme.onSurface,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _InfoNote extends StatelessWidget {
  const _InfoNote({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: scheme.secondaryContainer.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: scheme.onSecondaryContainer),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: theme.textTheme.bodySmall?.copyWith(
                color: scheme.onSecondaryContainer,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AmountInputFormatter extends TextInputFormatter {
  const _AmountInputFormatter();

  static final RegExp _pattern = RegExp(r'^\d{0,9}(?:\.\d{0,2})?$');

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (_pattern.hasMatch(newValue.text)) {
      return newValue;
    }
    return oldValue;
  }
}
