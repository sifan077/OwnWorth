import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../features/items/data/item_repository.dart';
import '../features/items/domain/item_usage.dart';
import '../features/items/domain/owned_item.dart';
import 'backup/backup_service.dart';
import 'database/app_database.dart';
import 'storage/image_store.dart';
import 'utils/date_utils.dart';

/// Replaced in `main.dart` after the app directories and database are ready.
final appDatabaseProvider = Provider<AppDatabase>((ref) {
  throw StateError('AppDatabase has not been initialized.');
});

/// Replaced in `main.dart`.
final imageStoreProvider = Provider<ImageStore>((ref) {
  throw StateError('ImageStore has not been initialized.');
});

final itemRepositoryProvider = Provider<ItemRepository>((ref) {
  return ItemRepository(ref.watch(appDatabaseProvider));
});

final backupServiceProvider = Provider<BackupService>((ref) {
  return BackupService(
    ref.watch(itemRepositoryProvider),
    ref.watch(imageStoreProvider),
  );
});

/// Today's local calendar date. Invalidated when the app resumes or the date
/// changes at midnight, so derived costs refresh without writing to SQLite.
final todayProvider = Provider<DateTime>((ref) {
  return currentLocalDate();
});

final allItemsProvider = StreamProvider<List<OwnedItem>>((ref) {
  return ref.watch(itemRepositoryProvider).watchAll();
});

final itemByIdProvider = StreamProvider.family<OwnedItem?, String>((
  ref,
  String id,
) {
  return ref.watch(itemRepositoryProvider).watchById(id);
});

/// Every usage record, newest first. The usage panels update reactively when a
/// use is recorded or removed.
final allUsagesProvider = StreamProvider<List<ItemUsage>>((ref) {
  return ref.watch(itemRepositoryProvider).watchAllUsages();
});

/// Usage records of a single item, newest first.
final itemUsagesProvider = StreamProvider.family<List<ItemUsage>, String>((
  ref,
  String itemId,
) {
  return ref.watch(itemRepositoryProvider).watchUsagesForItem(itemId);
});

final appVersionProvider = FutureProvider<String>((ref) async {
  final info = await PackageInfo.fromPlatform();
  final build = info.buildNumber.trim();
  return build.isEmpty ? info.version : '${info.version} ($build)';
});
