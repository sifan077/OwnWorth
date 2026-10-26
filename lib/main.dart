import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app/app.dart';
import 'app/theme/app_theme.dart';
import 'core/database/app_database.dart';
import 'core/providers.dart';
import 'core/storage/app_storage.dart';
import 'core/storage/image_store.dart';
import 'features/items/data/item_repository.dart';
import 'features/settings/presentation/theme_providers.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

  final preferences = await SharedPreferences.getInstance();

  AppDatabase? database;
  try {
    final storage = await AppStorage.initialize();
    final imageStore = ImageStore(storage.imagesDirectory);
    await imageStore.recoverInterruptedOperations();

    database = AppDatabase.open(storage.databaseFile);
    final repository = ItemRepository(database);
    await imageStore.deleteUnreferenced(
      await repository.referencedImagePaths(),
    );

    runApp(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(preferences),
          appDatabaseProvider.overrideWithValue(database),
          imageStoreProvider.overrideWithValue(imageStore),
        ],
        child: const OwnWorthApp(),
      ),
    );
  } catch (error, stackTrace) {
    await database?.close();
    runApp(BootstrapFailureApp(error: error, stackTrace: stackTrace));
  }
}

/// Shown when the local database or app directories cannot be opened.
class BootstrapFailureApp extends StatelessWidget {
  const BootstrapFailureApp({
    super.key,
    required this.error,
    required this.stackTrace,
  });

  final Object error;
  final StackTrace stackTrace;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '值回票价',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      home: Scaffold(
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Padding(
                padding: const EdgeInsets.all(28),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.storage_rounded,
                      size: 56,
                      color: Theme.of(context).colorScheme.error,
                    ),
                    const SizedBox(height: 20),
                    Text(
                      '无法打开本地数据',
                      style: Theme.of(context).textTheme.headlineSmall,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '请确认设备存储空间充足，然后重新启动应用。现有数据不会被自动删除。',
                      style: Theme.of(context).textTheme.bodyMedium,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Theme.of(context)
                            .colorScheme
                            .surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        error.toString(),
                        style: Theme.of(context).textTheme.bodySmall,
                        maxLines: 5,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(height: 20),
                    FilledButton.icon(
                      onPressed: () => exit(0),
                      icon: const Icon(Icons.refresh_rounded),
                      label: const Text('退出应用'),
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
}
