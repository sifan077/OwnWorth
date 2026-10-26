import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:ownworth/core/storage/image_store.dart';

void main() {
  late Directory tempDirectory;
  late Directory imagesDirectory;
  late ImageStore store;

  setUp(() async {
    tempDirectory = await Directory.systemTemp.createTemp('ownworth_images_');
    imagesDirectory = Directory('${tempDirectory.path}/images');
    await imagesDirectory.create(recursive: true);
    store = ImageStore(imagesDirectory);
  });

  tearDown(() async {
    if (await tempDirectory.exists()) {
      await tempDirectory.delete(recursive: true);
    }
  });

  test('saves, reads and removes images with a relative path', () async {
    final path = await store.saveBytes(
      Uint8List.fromList([1, 2, 3, 4]),
      sourceName: 'photo.png',
    );
    expect(path, startsWith('images/'));
    expect(path, endsWith('.png'));
    expect(store.exists(path), isTrue);
    expect(await store.read(path), [1, 2, 3, 4]);

    await store.delete(path);
    expect(store.exists(path), isFalse);
  });

  test('deletes only unreferenced images', () async {
    final kept = await store.saveBytes(
      Uint8List.fromList([1]),
      sourceName: 'kept.jpg',
    );
    final orphan = await store.saveBytes(
      Uint8List.fromList([2]),
      sourceName: 'orphan.jpg',
    );
    await store.deleteUnreferenced({kept});
    expect(store.exists(kept), isTrue);
    expect(store.exists(orphan), isFalse);
  });

  test('restores the old image directory when the commit fails', () async {
    final oldPath = await store.saveBytes(
      Uint8List.fromList([9, 9, 9]),
      sourceName: 'old.jpg',
    );

    await expectLater(
      store.replaceAll(
        {
          'images/new.jpg': Uint8List.fromList([1, 1, 1]),
        },
        () async {
          throw StateError('database failed');
        },
      ),
      throwsStateError,
    );

    expect(store.exists(oldPath), isTrue);
    expect(store.exists('images/new.jpg'), isFalse);
    expect(await store.read(oldPath), [9, 9, 9]);
  });

  test('replaces all images after a successful commit', () async {
    final oldPath = await store.saveBytes(
      Uint8List.fromList([9]),
      sourceName: 'old.jpg',
    );

    await store.replaceAll({
      'images/new.jpg': Uint8List.fromList([1, 2]),
    }, () async {});

    expect(store.exists(oldPath), isFalse);
    expect(store.exists('images/new.jpg'), isTrue);
    expect(await store.read('images/new.jpg'), [1, 2]);
  });

  test('rejects unsafe relative paths', () {
    expect(ImageStore.isValidRelativePath('images/a.jpg'), isTrue);
    expect(ImageStore.isValidRelativePath('images/../a.jpg'), isFalse);
    expect(ImageStore.isValidRelativePath('../a.jpg'), isFalse);
    expect(ImageStore.isValidRelativePath('/images/a.jpg'), isFalse);
    expect(ImageStore.isValidRelativePath('images/a/b.jpg'), isFalse);
    expect(ImageStore.isValidRelativePath('images/'), isFalse);
  });
}
