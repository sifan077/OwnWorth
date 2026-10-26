import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../features/items/domain/owned_item.dart';

/// Central light and dark themes. A muted teal seed keeps the app calm and
/// tool-like rather than resembling a generic template.
abstract final class AppTheme {
  static const Color _seed = Color(0xFF306B5B);
  static const List<FontFeature> tabularFigureFeatures = [
    FontFeature.tabularFigures(),
  ];

  static final ThemeData light = _build(Brightness.light);
  static final ThemeData dark = _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final seeded = ColorScheme.fromSeed(
      seedColor: _seed,
      brightness: brightness,
      dynamicSchemeVariant: DynamicSchemeVariant.fidelity,
    );
    final scheme = seeded.copyWith(
      surface: isDark ? const Color(0xFF1B201C) : const Color(0xFFF8F9F6),
      surfaceContainerLowest: isDark
          ? const Color(0xFF242B25)
          : const Color(0xFFFFFFFF),
      surfaceContainerLow: isDark
          ? const Color(0xFF29312A)
          : const Color(0xFFF3F5F1),
      surfaceContainer: isDark
          ? const Color(0xFF2E372F)
          : const Color(0xFFEDF0EA),
      surfaceContainerHigh: isDark
          ? const Color(0xFF343E36)
          : const Color(0xFFE5E9E2),
      surfaceContainerHighest: isDark
          ? const Color(0xFF3C473E)
          : const Color(0xFFDDE3DA),
      outline: isDark ? const Color(0xFF4D5A51) : const Color(0xFFC8D0C5),
      outlineVariant: isDark
          ? const Color(0xFF374139)
          : const Color(0xFFE1E6DC),
      primary: isDark ? const Color(0xFF9DD3BE) : const Color(0xFF2F6B5A),
      onPrimary: isDark ? const Color(0xFF00382B) : const Color(0xFFFFFFFF),
      primaryContainer: isDark
          ? const Color(0xFF244F41)
          : const Color(0xFFD3EDE2),
      onPrimaryContainer: isDark
          ? const Color(0xFFC6F0DF)
          : const Color(0xFF163D31),
      secondary: isDark ? const Color(0xFFD9C48A) : const Color(0xFF7A6230),
      secondaryContainer: isDark
          ? const Color(0xFF3D3420)
          : const Color(0xFFF4E8C8),
    );

    final base = ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: scheme.surface,
      visualDensity: VisualDensity.standard,
    );

    final textTheme = base.textTheme.copyWith(
      headlineLarge: base.textTheme.headlineLarge?.copyWith(
        fontWeight: FontWeight.w800,
        letterSpacing: -0.8,
      ),
      headlineMedium: base.textTheme.headlineMedium?.copyWith(
        fontWeight: FontWeight.w700,
        letterSpacing: -0.5,
      ),
      titleLarge: base.textTheme.titleLarge?.copyWith(
        fontWeight: FontWeight.w700,
        letterSpacing: -0.2,
      ),
      titleMedium: base.textTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.w600,
      ),
      bodyMedium: base.textTheme.bodyMedium?.copyWith(height: 1.45),
      bodySmall: base.textTheme.bodySmall?.copyWith(height: 1.4),
      labelLarge: base.textTheme.labelLarge?.copyWith(
        fontWeight: FontWeight.w600,
      ),
    );

    final rounded = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(20),
    );

    return base.copyWith(
      textTheme: textTheme,
      splashFactory: InkRipple.splashFactory,
      appBarTheme: AppBarThemeData(
        backgroundColor: scheme.surface,
        surfaceTintColor: Colors.transparent,
        foregroundColor: scheme.onSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: textTheme.titleLarge?.copyWith(
          color: scheme.onSurface,
          fontWeight: FontWeight.w700,
        ),
        systemOverlayStyle: isDark
            ? SystemUiOverlayStyle.light.copyWith(
                statusBarColor: Colors.transparent,
                systemNavigationBarColor: scheme.surface,
              )
            : SystemUiOverlayStyle.dark.copyWith(
                statusBarColor: Colors.transparent,
                systemNavigationBarColor: scheme.surface,
              ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        margin: EdgeInsets.zero,
        color: scheme.surfaceContainerLowest,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: scheme.outlineVariant),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: scheme.outlineVariant,
        thickness: 1,
        space: 1,
      ),
      inputDecorationTheme: InputDecorationThemeData(
        filled: true,
        fillColor: isDark
            ? scheme.surfaceContainerLow
            : scheme.surfaceContainerLowest,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        hintStyle: TextStyle(color: scheme.onSurfaceVariant),
        labelStyle: TextStyle(color: scheme.onSurfaceVariant),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: scheme.outlineVariant),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: scheme.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: scheme.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: scheme.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: scheme.error, width: 1.5),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(64, 52),
          padding: const EdgeInsets.symmetric(horizontal: 22),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: textTheme.labelLarge,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(64, 52),
          padding: const EdgeInsets.symmetric(horizontal: 22),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          side: BorderSide(color: scheme.outline),
          textStyle: textTheme.labelLarge,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: textTheme.labelLarge,
        ),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            return states.contains(WidgetState.selected)
                ? scheme.primaryContainer
                : scheme.surfaceContainerLowest;
          }),
          foregroundColor: WidgetStateProperty.resolveWith((states) {
            return states.contains(WidgetState.selected)
                ? scheme.onPrimaryContainer
                : scheme.onSurfaceVariant;
          }),
          side: WidgetStatePropertyAll(
            BorderSide(color: scheme.outlineVariant),
          ),
          textStyle: WidgetStatePropertyAll(textTheme.labelLarge),
        ),
      ),
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        side: BorderSide(color: scheme.outlineVariant),
        backgroundColor: scheme.surfaceContainerLowest,
        selectedColor: scheme.primaryContainer,
        labelStyle: textTheme.labelLarge?.copyWith(color: scheme.onSurface),
        showCheckmark: false,
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 72,
        elevation: 0,
        backgroundColor: scheme.surface,
        surfaceTintColor: Colors.transparent,
        indicatorColor: scheme.primaryContainer,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return textTheme.labelMedium?.copyWith(
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            color: selected ? scheme.onSurface : scheme.onSurfaceVariant,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return IconThemeData(
            size: 24,
            color: selected
                ? scheme.onPrimaryContainer
                : scheme.onSurfaceVariant,
          );
        }),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: isDark
            ? scheme.surfaceContainerHighest
            : const Color(0xFF26332E),
        contentTextStyle: textTheme.bodyMedium?.copyWith(color: Colors.white),
        actionTextColor: isDark ? scheme.primary : const Color(0xFFA8DCC8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        insetPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: scheme.surfaceContainerLowest,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        titleTextStyle: textTheme.titleLarge?.copyWith(color: scheme.onSurface),
        contentTextStyle: textTheme.bodyMedium?.copyWith(
          color: scheme.onSurfaceVariant,
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: scheme.surfaceContainerLowest,
        surfaceTintColor: Colors.transparent,
        showDragHandle: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: scheme.primary,
        linearTrackColor: scheme.surfaceContainerHigh,
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: scheme.primary,
        foregroundColor: scheme.onPrimary,
        elevation: 2,
        highlightElevation: 3,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: scheme.primary,
        selectionColor: scheme.primary.withValues(alpha: 0.25),
        selectionHandleColor: scheme.primary,
      ),
      listTileTheme: ListTileThemeData(
        shape: rounded,
        iconColor: scheme.onSurfaceVariant,
      ),
    );
  }

  static TextStyle? tabular(TextStyle? style) {
    return style?.copyWith(fontFeatures: tabularFigureFeatures);
  }

  static Color categoryColor(ItemCategory category, ColorScheme scheme) {
    final isDark = scheme.brightness == Brightness.dark;
    final base = switch (category) {
      ItemCategory.digital => const Color(0xFF4C7FB8),
      ItemCategory.appliance => const Color(0xFFBF7A3A),
      ItemCategory.home => const Color(0xFF578468),
      ItemCategory.clothing => const Color(0xFFB5677B),
      ItemCategory.entertainment => const Color(0xFF8C6AB0),
      ItemCategory.other => const Color(0xFF7A827B),
    };
    return isDark ? Color.lerp(base, Colors.white, 0.3)! : base;
  }

  static IconData categoryIcon(ItemCategory category) {
    return switch (category) {
      ItemCategory.digital => Icons.devices_rounded,
      ItemCategory.appliance => Icons.kitchen_rounded,
      ItemCategory.home => Icons.chair_rounded,
      ItemCategory.clothing => Icons.checkroom_rounded,
      ItemCategory.entertainment => Icons.sports_esports_rounded,
      ItemCategory.other => Icons.inventory_2_rounded,
    };
  }
}
