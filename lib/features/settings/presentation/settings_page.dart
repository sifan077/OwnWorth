import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/backup/backup_service.dart';
import '../../../core/providers.dart';
import '../../../core/utils/date_utils.dart';
import 'theme_providers.dart';

class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  bool _working = false;
  String _workingLabel = '';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final themeMode = ref.watch(themeModeProvider);
    final versionAsync = ref.watch(appVersionProvider);

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: Column(
              children: [
                if (_working)
                  LinearProgressIndicator(minHeight: 2, color: scheme.primary),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(18, 22, 18, 32),
                    children: [
                      Text(
                        '设置',
                        style: theme.textTheme.headlineLarge?.copyWith(
                          fontSize: 31,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        '让这个工具更适合长期使用',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                      if (_working) ...[
                        const SizedBox(height: 14),
                        _WorkingBanner(label: _workingLabel),
                      ],
                      const SizedBox(height: 26),
                      const _SectionTitle(title: '外观', subtitle: '选择你喜欢的界面配色。'),
                      const SizedBox(height: 12),
                      _SettingsCard(
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: SegmentedButton<ThemeMode>(
                            expandedInsets: EdgeInsets.zero,
                            showSelectedIcon: false,
                            segments: const [
                              ButtonSegment<ThemeMode>(
                                value: ThemeMode.system,
                                label: Text('跟随系统'),
                              ),
                              ButtonSegment<ThemeMode>(
                                value: ThemeMode.light,
                                label: Text('浅色'),
                              ),
                              ButtonSegment<ThemeMode>(
                                value: ThemeMode.dark,
                                label: Text('深色'),
                              ),
                            ],
                            selected: {themeMode},
                            onSelectionChanged: _working
                                ? null
                                : (selection) {
                                    ref
                                        .read(themeModeProvider.notifier)
                                        .setMode(selection.first);
                                  },
                          ),
                        ),
                      ),
                      const SizedBox(height: 26),
                      const _SectionTitle(
                        title: '本地备份',
                        subtitle: '完整保留物品记录和图片，方便换机或防止意外丢失。',
                      ),
                      const SizedBox(height: 12),
                      _SettingsCard(
                        child: Column(
                          children: [
                            const _OfflineNote(),
                            Divider(height: 1, color: scheme.outlineVariant),
                            _SettingsTile(
                              icon: Icons.upload_file_rounded,
                              title: '导出备份',
                              subtitle: '生成 ZIP 文件，包含全部记录和图片',
                              enabled: !_working,
                              onTap: _exportBackup,
                              trailing: const Icon(
                                Icons.ios_share_rounded,
                                size: 20,
                              ),
                            ),
                            Divider(
                              height: 1,
                              indent: 68,
                              color: scheme.outlineVariant,
                            ),
                            _SettingsTile(
                              icon: Icons.download_rounded,
                              title: '导入备份',
                              subtitle: '校验后全量恢复，覆盖现有数据',
                              enabled: !_working,
                              onTap: _importBackup,
                              trailing: const Icon(
                                Icons.chevron_right_rounded,
                                size: 20,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        '导入前会先校验备份完整性，校验失败不会改动现有数据。恢复时会全量覆盖本机记录，建议先导出当前备份。',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 26),
                      const _SectionTitle(
                        title: '关于',
                        subtitle: '一个完全离线的个人物品成本追踪器。',
                      ),
                      const SizedBox(height: 12),
                      _SettingsCard(
                        child: Column(
                          children: [
                            const _AboutHeader(),
                            Divider(
                              height: 1,
                              indent: 68,
                              color: scheme.outlineVariant,
                            ),
                            _SettingsTile(
                              icon: Icons.info_outline_rounded,
                              title: '应用版本',
                              subtitle: versionAsync.when(
                                data: (version) => version,
                                loading: () => '读取中…',
                                error: (error, stackTrace) => '未知',
                              ),
                              enabled: false,
                              onTap: null,
                            ),
                            Divider(
                              height: 1,
                              indent: 68,
                              color: scheme.outlineVariant,
                            ),
                            _SettingsTile(
                              icon: Icons.cloud_off_rounded,
                              title: '数据存储',
                              subtitle: 'SQLite 本地数据库 · 仅保存在本机',
                              enabled: false,
                              onTap: null,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),
                      Center(
                        child: Text(
                          '值回票价 · OwnWorth',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                            letterSpacing: 0.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _exportBackup() async {
    if (_working) {
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() {
      _working = true;
      _workingLabel = '正在整理备份…';
    });

    try {
      String version = '未知';
      try {
        version = await ref.read(appVersionProvider.future);
      } catch (_) {
        // A version label is nice to have, not required for a valid backup.
      }

      final bytes = await ref
          .read(backupServiceProvider)
          .exportBackup(appVersion: version);
      if (!mounted) {
        return;
      }
      final fileName =
          'ownworth-backup-${formatFileTimestamp(DateTime.now())}.zip';
      final saved = await FilePicker.saveFile(
        dialogTitle: '导出备份',
        fileName: fileName,
        bytes: bytes,
        mimeType: 'application/zip',
      );
      if (!mounted) {
        return;
      }
      if (saved != null) {
        _showMessage('备份已导出');
      }
    } on BackupException catch (error) {
      if (mounted) {
        await _showError('无法导出备份', error.message);
      }
    } catch (error) {
      if (mounted) {
        await _showError('无法导出备份', '保存文件时出现问题，请重试。如果问题持续出现，请检查设备剩余存储空间。');
      }
    } finally {
      if (mounted) {
        setState(() {
          _working = false;
          _workingLabel = '';
        });
      }
    }
  }

  Future<void> _importBackup() async {
    if (_working) {
      return;
    }
    FocusScope.of(context).unfocus();

    PlatformFile? picked;
    try {
      picked = await FilePicker.pickFile(
        dialogTitle: '选择备份文件',
        type: FileType.custom,
        allowedExtensions: const ['zip'],
      );
    } catch (error) {
      if (mounted) {
        await _showError('无法选择文件', '打开文件选择器时出现问题，请重试。');
      }
      return;
    }
    if (picked == null || !mounted) {
      return;
    }

    setState(() {
      _working = true;
      _workingLabel = '正在校验备份…';
    });

    try {
      final length = picked.lengthSync() ?? await picked.length();
      if (length != null && length > BackupService.maxArchiveBytes) {
        throw const BackupException('备份文件过大，无法导入。');
      }
      final Uint8List bytes = await picked.readAsBytes();
      final contents = await ref
          .read(backupServiceProvider)
          .inspectBackup(bytes);
      if (!mounted) {
        return;
      }

      setState(() => _working = false);
      final confirmed = await _confirmImport(contents, picked.name);
      if (confirmed != true || !mounted) {
        return;
      }

      setState(() {
        _working = true;
        _workingLabel = '正在恢复数据…';
      });
      await ref.read(backupServiceProvider).restoreBackup(contents);
      ref.invalidate(allItemsProvider);
      ref.invalidate(allUsagesProvider);
      ref.invalidate(todayProvider);
      if (!mounted) {
        return;
      }
      _showMessage(
        '已恢复 ${contents.preview.itemCount} 件物品、${contents.preview.imageCount} 张图片与 ${contents.preview.usageCount} 条使用记录',
      );
    } on BackupException catch (error) {
      if (mounted) {
        await _showError('无法导入备份', error.message);
      }
    } catch (error) {
      if (mounted) {
        await _showError('无法导入备份', '恢复数据时出现问题，请重试。');
      }
    } finally {
      if (mounted) {
        setState(() {
          _working = false;
          _workingLabel = '';
        });
      }
    }
  }

  Future<bool?> _confirmImport(BackupContents contents, String fileName) {
    final preview = contents.preview;
    final localTime = preview.exportedAt.toLocal();
    final time =
        '${formatIsoDate(localTime)} ${localTime.hour.toString().padLeft(2, '0')}:${localTime.minute.toString().padLeft(2, '0')}';
    final scheme = Theme.of(context).colorScheme;

    return showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('导入备份？'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                fileName,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(dialogContext).textTheme.labelMedium
                    ?.copyWith(color: scheme.onSurfaceVariant),
              ),
              const SizedBox(height: 14),
              _PreviewRow(label: '备份时间', value: time),
              _PreviewRow(
                label: '包含内容',
                value:
                    '${preview.itemCount} 件物品 · ${preview.imageCount} 张图片 · ${preview.usageCount} 次使用',
              ),
              if (preview.appVersion != null)
                _PreviewRow(label: '备份版本', value: preview.appVersion!),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: scheme.errorContainer.withValues(alpha: 0.45),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.warning_amber_rounded,
                      size: 18,
                      color: scheme.error,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '导入将覆盖本机现有的全部物品记录、使用记录和图片，且无法撤销。',
                        style: Theme.of(dialogContext).textTheme.bodySmall
                            ?.copyWith(color: scheme.onErrorContainer),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('取消'),
            ),
            FilledButton.tonal(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('覆盖并恢复'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showError(String title, String message) {
    return showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            FilledButton.tonal(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('知道了'),
            ),
          ],
        );
      },
    );
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
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

class _SettingsCard extends StatelessWidget {
  const _SettingsCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: scheme.outlineVariant),
      ),
      clipBehavior: Clip.antiAlias,
      child: child,
    );
  }
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.enabled,
    required this.onTap,
    this.trailing,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool enabled;
  final VoidCallback? onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final effectiveOnTap = enabled ? onTap : null;
    return InkWell(
      onTap: effectiveOnTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: scheme.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                size: 20,
                color: enabled
                    ? scheme.onSurfaceVariant
                    : scheme.onSurfaceVariant.withValues(alpha: 0.55),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: enabled
                          ? scheme.onSurface
                          : scheme.onSurface.withValues(alpha: 0.7),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            if (trailing != null) ...[
              const SizedBox(width: 8),
              IconTheme(
                data: IconThemeData(color: scheme.onSurfaceVariant, size: 20),
                child: trailing!,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _OfflineNote extends StatelessWidget {
  const _OfflineNote();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.shield_outlined, size: 18, color: scheme.primary),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              '所有数据仅保存在本机。不需要账号，也不会联网上传。',
              style: theme.textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AboutHeader extends StatelessWidget {
  const _AboutHeader();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [scheme.primary, scheme.secondary],
              ),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Icon(
              Icons.confirmation_number_rounded,
              color: scheme.onPrimary,
              size: 25,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '值回票价',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '记录购入成本，看它如何被时间摊薄。',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _WorkingBanner extends StatelessWidget {
  const _WorkingBanner({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: scheme.primaryContainer.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 15,
            height: 15,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: scheme.primary,
            ),
          ),
          const SizedBox(width: 9),
          Text(
            label,
            style: theme.textTheme.labelMedium?.copyWith(
              color: scheme.onPrimaryContainer,
            ),
          ),
        ],
      ),
    );
  }
}

class _PreviewRow extends StatelessWidget {
  const _PreviewRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 76,
            child: Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
