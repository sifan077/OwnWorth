import 'package:flutter/material.dart';

class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.action,
    this.compact = false,
  });

  final IconData icon;
  final String title;
  final String message;
  final Widget? action;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 360),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: 28,
            vertical: compact ? 20 : 40,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: compact ? 68 : 88,
                height: compact ? 68 : 88,
                decoration: BoxDecoration(
                  color: scheme.primaryContainer.withValues(alpha: 0.7),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  size: compact ? 30 : 38,
                  color: scheme.onPrimaryContainer,
                ),
              ),
              const SizedBox(height: 22),
              Text(
                title,
                style: Theme.of(context).textTheme.titleLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                message,
                style: Theme.of(context).textTheme.bodyMedium
                    ?.copyWith(color: scheme.onSurfaceVariant),
                textAlign: TextAlign.center,
              ),
              if (action != null) ...[const SizedBox(height: 24), action!],
            ],
          ),
        ),
      ),
    );
  }
}

class InlineErrorView extends StatelessWidget {
  const InlineErrorView({
    super.key,
    required this.message,
    required this.onRetry,
    this.title = '加载失败',
  });

  final String title;
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return EmptyState(
      icon: Icons.error_outline_rounded,
      title: title,
      message: message,
      compact: true,
      action: FilledButton.tonalIcon(
        onPressed: onRetry,
        icon: const Icon(Icons.refresh_rounded),
        label: const Text('重试'),
      ),
    );
  }
}
