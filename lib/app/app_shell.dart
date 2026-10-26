import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

/// Bottom-navigation shell shared by the home and settings tabs.
class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isHome = navigationShell.currentIndex == 0;
    final overlayStyle =
        (isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark)
            .copyWith(
              statusBarColor: Colors.transparent,
              systemNavigationBarColor: scheme.surface,
              systemNavigationBarIconBrightness: isDark
                  ? Brightness.light
                  : Brightness.dark,
              systemNavigationBarDividerColor: Colors.transparent,
            );

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: overlayStyle,
      child: PopScope(
        canPop: isHome,
        onPopInvokedWithResult: (didPop, result) {
          if (!didPop) {
            navigationShell.goBranch(0);
          }
        },
        child: Scaffold(
          body: navigationShell,
          bottomNavigationBar: DecoratedBox(
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: scheme.outlineVariant)),
            ),
            child: NavigationBar(
              selectedIndex: navigationShell.currentIndex,
              onDestinationSelected: (index) {
                navigationShell.goBranch(
                  index,
                  initialLocation: index == navigationShell.currentIndex,
                );
              },
              destinations: const [
                NavigationDestination(
                  icon: Icon(Icons.space_dashboard_outlined),
                  selectedIcon: Icon(Icons.space_dashboard_rounded),
                  label: '物品',
                ),
                NavigationDestination(
                  icon: Icon(Icons.tune_outlined),
                  selectedIcon: Icon(Icons.tune_rounded),
                  label: '设置',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
