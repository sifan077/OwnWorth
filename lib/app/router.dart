import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/items/presentation/home_page.dart';
import '../features/items/presentation/item_detail_page.dart';
import '../features/items/presentation/item_form_page.dart';
import '../features/settings/presentation/settings_page.dart';
import 'app_shell.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final router = GoRouter(
    initialLocation: '/',
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return AppShell(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/',
                name: 'home',
                builder: (context, state) => const HomePage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/settings',
                name: 'settings',
                builder: (context, state) => const SettingsPage(),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: '/items/new',
        name: 'item-new',
        builder: (context, state) => const ItemFormPage(),
      ),
      GoRoute(
        path: '/items/:id/edit',
        name: 'item-edit',
        builder: (context, state) {
          return ItemFormPage(itemId: state.pathParameters['id']);
        },
      ),
      GoRoute(
        path: '/items/:id',
        name: 'item-detail',
        builder: (context, state) {
          return ItemDetailPage(itemId: state.pathParameters['id']!);
        },
      ),
    ],
    errorBuilder: (context, state) {
      return Scaffold(
        appBar: AppBar(title: const Text('页面不存在')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.explore_off_rounded,
                  size: 48,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                const SizedBox(height: 16),
                const Text('找不到这个页面'),
                const SizedBox(height: 20),
                FilledButton.tonal(
                  onPressed: () => context.go('/'),
                  child: const Text('返回首页'),
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
  ref.onDispose(router.dispose);
  return router;
});
