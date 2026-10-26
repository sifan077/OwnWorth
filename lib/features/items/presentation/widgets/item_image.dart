import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../../core/providers.dart';
import '../../domain/owned_item.dart';

class ItemImage extends ConsumerWidget {
  const ItemImage({
    super.key,
    required this.category,
    this.imagePath,
    this.size = 64,
    this.borderRadius = 16,
    this.heroTag,
    this.fit = BoxFit.cover,
  });

  final ItemCategory category;
  final String? imagePath;
  final double size;
  final double borderRadius;
  final String? heroTag;
  final BoxFit fit;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final radius = BorderRadius.circular(borderRadius);
    final store = ref.watch(imageStoreProvider);
    final path = imagePath;
    Widget image;

    if (path != null && store.exists(path)) {
      final dpr = MediaQuery.devicePixelRatioOf(context);
      image = Image.file(
        File(store.fileFor(path).path),
        width: size,
        height: size,
        fit: fit,
        cacheWidth: (size * dpr).round(),
        gaplessPlayback: true,
        errorBuilder: (context, error, stackTrace) {
          return _Placeholder(category: category, size: size);
        },
      );
    } else {
      image = _Placeholder(category: category, size: size);
    }

    final clipped = ClipRRect(
      borderRadius: radius,
      child: SizedBox.square(dimension: size, child: image),
    );

    final framed = DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: radius,
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: clipped,
    );

    if (heroTag == null) {
      return framed;
    }
    return Hero(
      tag: heroTag!,
      child: Material(type: MaterialType.transparency, child: framed),
    );
  }
}

class _Placeholder extends StatelessWidget {
  const _Placeholder({required this.category, required this.size});

  final ItemCategory category;
  final double size;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = AppTheme.categoryColor(category, scheme);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color.withValues(alpha: 0.18),
            color.withValues(alpha: 0.08),
          ],
        ),
      ),
      child: Icon(
        AppTheme.categoryIcon(category),
        size: size * 0.4,
        color: color,
      ),
    );
  }
}
