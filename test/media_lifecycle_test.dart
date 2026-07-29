import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:ko_lernen_app/models/book_page.dart';
import 'package:ko_lernen_app/models/custom_pack.dart';
import 'package:ko_lernen_app/services/book_image_service.dart';
import 'package:ko_lernen_app/services/custom_pack_service.dart';
import 'package:ko_lernen_app/services/media_workflow.dart';
import 'package:ko_lernen_app/services/storage_service.dart';
import 'package:ko_lernen_app/services/word_image_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

ExtractedWord detailedWord(String imagePath) => ExtractedWord(
  korean: '한국어',
  romanization: 'hangugeo',
  posDe: 'Nomen',
  translationDe: 'Koreanisch',
  translationEn: 'Korean',
  exampleKorean: '한국어를 배워요.',
  exampleDe: 'Ich lerne Koreanisch.',
  definitionKo: '한국의 말',
  imagePath: imagePath,
  savedToPackId: 'cp_original',
);

void main() {
  late Directory sandbox;
  late ManagedMediaStore store;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    Storage.resetForTesting();
    await Storage.init();
    sandbox = await Directory.systemTemp.createTemp('media_lifecycle_');
    final docs = Directory('${sandbox.path}${Platform.pathSeparator}docs')
      ..createSync();
    final cache = Directory('${sandbox.path}${Platform.pathSeparator}cache')
      ..createSync();
    store = ManagedMediaStore(
      documentsDirectory: docs,
      temporaryDirectory: cache,
      nonce: () => DateTime.now().microsecondsSinceEpoch.toString(),
    );
    BookImageService.setStoreForTesting(store);
  });

  tearDown(() async {
    BookImageService.setStoreForTesting(null);
    await sandbox.delete(recursive: true);
  });

  test('book promote persists strictly then finalizes exactly once', () async {
    final source = File('${sandbox.path}${Platform.pathSeparator}book.jpg')
      ..writeAsBytesSync([1]);
    final pending = await store.stage(source, ManagedMediaKind.book);
    var writes = 0;
    final workflow = BookMediaSaveWorkflow(
      store: store,
      persist: (ref) async {
        writes++;
        expect(await store.resolve(ref), isNotNull);
      },
    );

    final first = await workflow.save(pending);
    final second = await workflow.save(pending);

    expect(first, second);
    expect(writes, 1);
    expect(await source.exists(), isTrue);
  });

  test('book persistence failure rolls back promoted file', () async {
    final source = File('${sandbox.path}${Platform.pathSeparator}book.jpg')
      ..writeAsBytesSync([1]);
    final pending = await store.stage(source, ManagedMediaKind.book);
    final workflow = BookMediaSaveWorkflow(
      store: store,
      persist: (_) async => throw StateError('strict write failed'),
    );

    await expectLater(workflow.save(pending), throwsStateError);

    expect(await store.listCommitted(ManagedMediaKind.book), isEmpty);
    expect(await store.pendingFile(pending).exists(), isTrue);
  });

  test(
    'post-persist finalization failure is committed success exactly once',
    () async {
      final source = File('${sandbox.path}${Platform.pathSeparator}book.jpg')
        ..writeAsBytesSync([1]);
      final pending = await store.stage(source, ManagedMediaKind.book);
      var writes = 0;
      final failingStore = _FinalizeFailingStore.from(store);
      final workflow = BookMediaSaveWorkflow(
        store: failingStore,
        persist: (_) async => writes++,
      );

      final first = await workflow.save(pending);
      final second = await workflow.save(pending);

      expect(first, second);
      expect(writes, 1);
      expect(await failingStore.resolve(first), isNotNull);
    },
  );

  test('book promote failure retains lease for a later retry', () async {
    final source = File('${sandbox.path}${Platform.pathSeparator}book.jpg')
      ..writeAsBytesSync([1]);
    final pending = await store.stage(source, ManagedMediaKind.book);
    final transientStore = _TransientPromoteStore.from(store);

    await expectLater(
      BookMediaSaveWorkflow(
        store: transientStore,
        persist: (_) async {},
      ).save(pending),
      throwsStateError,
    );
    expect(await transientStore.resolvePending(pending), isNotNull);

    final reference = await BookMediaSaveWorkflow(
      store: transientStore,
      persist: (_) async {},
    ).save(pending);
    expect(await transientStore.resolve(reference), isNotNull);
  });

  test('picker marker clear failure preserves durable staged word', () async {
    final source = File(
      '${sandbox.path}${Platform.pathSeparator}cache'
      '${Platform.pathSeparator}picked.jpg',
    )..writeAsBytesSync([5]);

    await expectLater(
      WordImageService.pickPending(
        ImageSource.gallery,
        workflowId: 'pack:word',
        picker: _FilePicker(XFile(source.path)),
        markLaunch: ({required purpose, required workflowId}) async {},
        clearLaunch: () async => throw StateError('strict clear failed'),
      ),
      throwsStateError,
    );

    final pendingDirectory = Directory(
      '${store.root.path}${Platform.pathSeparator}pending',
    );
    expect(
      await pendingDirectory.exists()
          ? await pendingDirectory.list().toList()
          : const <FileSystemEntity>[],
      hasLength(1),
    );
    expect(Storage.recoveredWordLease, contains('pack:word'));
    expect(await source.exists(), isFalse);
  });

  test(
    'non-Android word picker creates no marker but durable ownership',
    () async {
      if (Platform.isAndroid) {
        return;
      }
      final source = File(
        '${sandbox.path}${Platform.pathSeparator}cache'
        '${Platform.pathSeparator}ordinary.jpg',
      )..writeAsBytesSync([6]);

      final lease = await WordImageService.pickPending(
        ImageSource.gallery,
        workflowId: 'stable-word-target',
        picker: _FilePicker(XFile(source.path)),
      );

      expect(lease, isNotNull);
      expect(Storage.pickerRecoveryMarkerJson, isEmpty);
      expect(Storage.recoveredWordLease, contains('stable-word-target'));
      expect(await store.resolvePending(lease!), isNotNull);
    },
  );

  test(
    'shifted edited word is rejected under lock and incoming lease discarded',
    () async {
      final original = detailedWord('');
      final pack = CustomPack.manual(
        id: 'pack',
        name: 'Pack',
        words: [original],
      );
      await Storage.setCustomPacksRawJson(
        jsonEncode({'pack': pack.toLocalJson()}),
      );
      final source = File('${sandbox.path}${Platform.pathSeparator}word.jpg')
        ..writeAsBytesSync([2]);
      final pending = await store.stage(source, ManagedMediaKind.word);
      final staleExpected = original.copyWithEditable(korean: 'shifted');

      await expectLater(
        CustomPackService.updateWordWithMedia(
          packId: 'pack',
          index: 0,
          expectedOriginal: staleExpected,
          word: original.copyWithEditable(translationDe: 'Neu'),
          pendingLease: pending,
        ),
        throwsStateError,
      );

      expect(
        CustomPackService.getById('pack')!.words.single.toLocalJson(),
        original.toLocalJson(),
      );
      expect(await store.resolvePending(pending), isNull);
      expect(await store.listCommitted(ManagedMediaKind.word), isEmpty);
    },
  );

  test('word recovery workflow fingerprints full homograph identity', () {
    final first = detailedWord('').copyWithEditable(translationDe: 'Bank');
    final homograph = first.copyWithEditable(translationDe: 'Sitzbank');

    expect(
      CustomPackService.mediaWorkflowId('pack', 0, first),
      isNot(CustomPackService.mediaWorkflowId('pack', 0, homograph)),
    );
    expect(
      CustomPackService.mediaWorkflowId('pack', null, null),
      'word:pack:new',
    );
  });

  test(
    'missing edited target throws conflict and releases incoming lease',
    () async {
      final original = detailedWord('');
      await Storage.setCustomPacksRawJson(
        jsonEncode({
          'pack': CustomPack.manual(
            id: 'pack',
            name: 'Pack',
            words: [original],
          ).toLocalJson(),
        }),
      );
      for (final target in <(String, int)>[('missing', 0), ('pack', 4)]) {
        final source = File(
          '${sandbox.path}${Platform.pathSeparator}'
          '${target.$1}_${target.$2}.jpg',
        )..writeAsBytesSync([7]);
        final pending = await store.stage(source, ManagedMediaKind.word);

        await expectLater(
          CustomPackService.updateWordWithMedia(
            packId: target.$1,
            index: target.$2,
            expectedOriginal: original,
            word: original,
            pendingLease: pending,
          ),
          throwsStateError,
        );
        expect(await store.resolvePending(pending), isNull);
      }
      expect(
        CustomPackService.getById('pack')!.words.single.toLocalJson(),
        original.toLocalJson(),
      );
    },
  );

  test(
    'failed strict recovered-book claim preserves record and pending lease',
    () async {
      final source = File('${sandbox.path}${Platform.pathSeparator}book.jpg')
        ..writeAsBytesSync([3]);
      final pending = await store.stage(source, ManagedMediaKind.book);
      final record = jsonEncode({
        'workflowId': 'book-flow',
        'lease': pending.encoded,
      });
      await Storage.setRecoveredBookLease(record);

      await expectLater(
        Storage.claimRecoveredBookLease(preferences: _FalseStringStore()),
        throwsA(isA<PreferenceWriteException>()),
      );

      expect(Storage.recoveredBookLease, record);
      expect(await store.resolvePending(pending), isNotNull);
    },
  );

  test(
    'late malformed migration input performs no partial migration',
    () async {
      final legacy = Directory(
        '${store.documentsDirectory.path}${Platform.pathSeparator}book_images',
      )..createSync();
      final source = File('${legacy.path}${Platform.pathSeparator}page.jpg')
        ..writeAsBytesSync([4]);
      final original = jsonEncode({
        'first': {'localThumbnailPath': source.path, 'words': const []},
        'late-bad': {
          'words': ['not-a-map'],
        },
      });
      await Storage.setBookshelfRawJson(original);
      await Storage.setCustomPacksRawJson('{}');

      await BookImageService.initialize();

      expect(Storage.bookshelfRawJson, original);
      expect(await store.listCommitted(ManagedMediaKind.book), isEmpty);
      expect(await source.exists(), isTrue);
    },
  );

  test(
    'malformed startup still expires pending while preserving committed',
    () async {
      final committedSource = File(
        '${sandbox.path}${Platform.pathSeparator}committed.jpg',
      )..writeAsBytesSync([8]);
      final committedLease = await store.stage(
        committedSource,
        ManagedMediaKind.word,
      );
      final promotion = await store.promote(committedLease);
      await store.finalize(promotion);
      final pendingSource = File(
        '${sandbox.path}${Platform.pathSeparator}pending.jpg',
      )..writeAsBytesSync([9]);
      final pending = await store.stage(pendingSource, ManagedMediaKind.book);
      await store.pendingFile(pending).setLastModified(DateTime.utc(2000));
      await Storage.setBookshelfRawJson('{broken');
      await Storage.setCustomPacksRawJson('{}');

      await BookImageService.initialize();

      expect(await store.resolve(promotion.reference), isNotNull);
      expect(await store.resolvePending(pending), isNull);
    },
  );

  test(
    'second strict migration write failure restores prefs and removes files',
    () async {
      final bookLegacy = Directory(
        '${store.documentsDirectory.path}${Platform.pathSeparator}book_images',
      )..createSync();
      final wordLegacy = Directory(
        '${store.documentsDirectory.path}${Platform.pathSeparator}'
        'wordbook_images',
      )..createSync();
      final bookSource = File(
        '${bookLegacy.path}${Platform.pathSeparator}page.jpg',
      )..writeAsBytesSync([5]);
      final wordSource = File(
        '${wordLegacy.path}${Platform.pathSeparator}word.jpg',
      )..writeAsBytesSync([6]);
      final originalBookshelf = jsonEncode({
        'page': {'localThumbnailPath': bookSource.path, 'words': const []},
      });
      final originalPacks = jsonEncode({
        'pack': {
          'words': [
            {'imagePath': wordSource.path},
          ],
        },
      });
      await Storage.setBookshelfRawJson(originalBookshelf);
      await Storage.setCustomPacksRawJson(originalPacks);
      var packWrites = 0;

      await expectLater(
        BookImageService.initialize(
          writeBookshelf: Storage.setBookshelfRawJsonStrict,
          writeCustomPacks: (value) async {
            packWrites++;
            if (packWrites == 1) {
              throw StateError('second strict write failed');
            }
            await Storage.setCustomPacksRawJsonStrict(value);
          },
        ),
        throwsStateError,
      );

      expect(Storage.bookshelfRawJson, originalBookshelf);
      expect(Storage.customPacksRawJson, originalPacks);
      expect(await store.listCommitted(ManagedMediaKind.book), isEmpty);
      expect(await store.listCommitted(ManagedMediaKind.word), isEmpty);
      expect(await bookSource.exists(), isTrue);
      expect(await wordSource.exists(), isTrue);
    },
  );

  test(
    'word cancel, dismiss, reselect, and remove release only pending lease',
    () async {
      final oldSource = File('${sandbox.path}${Platform.pathSeparator}old.jpg')
        ..writeAsBytesSync([1]);
      final oldPending = await store.stage(oldSource, ManagedMediaKind.word);
      final oldPromotion = await store.promote(oldPending);
      await store.finalize(oldPromotion);
      final controller = WordMediaEditWorkflow(
        store: store,
        originalReference: oldPromotion.reference,
      );
      final firstSource = File(
        '${sandbox.path}${Platform.pathSeparator}one.jpg',
      )..writeAsBytesSync([2]);
      final secondSource = File(
        '${sandbox.path}${Platform.pathSeparator}two.jpg',
      )..writeAsBytesSync([3]);

      final first = await store.stage(firstSource, ManagedMediaKind.word);
      await controller.select(first);
      final second = await store.stage(secondSource, ManagedMediaKind.word);
      await controller.select(second);
      expect(await store.pendingFile(first).exists(), isFalse);
      await controller.removePhoto();
      expect(await store.pendingFile(second).exists(), isFalse);
      await controller.cancel();

      expect(await store.resolve(oldPromotion.reference), isNotNull);
    },
  );

  test(
    'failed word update preserves old ref and deletes promoted replacement',
    () async {
      final oldSource = File('${sandbox.path}${Platform.pathSeparator}old.jpg')
        ..writeAsBytesSync([1]);
      final oldPending = await store.stage(oldSource, ManagedMediaKind.word);
      final oldPromotion = await store.promote(oldPending);
      await store.finalize(oldPromotion);
      final newSource = File('${sandbox.path}${Platform.pathSeparator}new.jpg')
        ..writeAsBytesSync([2]);
      final newPending = await store.stage(newSource, ManagedMediaKind.word);
      final workflow = WordMediaEditWorkflow(
        store: store,
        originalReference: oldPromotion.reference,
      );
      await workflow.select(newPending);

      await expectLater(
        workflow.commit(
          persist: (_) async => throw StateError('strict write failed'),
          referencesAfterWrite: () =>
              const ManagedMediaReferenceSnapshot.valid({}),
        ),
        throwsStateError,
      );

      expect(await store.resolve(oldPromotion.reference), isNotNull);
      expect(await store.listCommitted(ManagedMediaKind.word), hasLength(1));
      expect(await store.pendingFile(newPending).exists(), isFalse);
    },
  );

  test(
    'editing a word preserves every field and can explicitly clear photo',
    () {
      final original = detailedWord('word:old.jpg');

      final edited = original.copyWithEditable(
        korean: '한국말',
        translationDe: 'Koreanische Sprache',
        exampleKorean: '한국말을 해요.',
        clearImage: true,
      );

      expect(edited.korean, '한국말');
      expect(edited.translationDe, 'Koreanische Sprache');
      expect(edited.exampleKorean, '한국말을 해요.');
      expect(edited.imagePath, isEmpty);
      expect(edited.romanization, original.romanization);
      expect(edited.posDe, original.posDe);
      expect(edited.translationEn, original.translationEn);
      expect(edited.exampleDe, original.exampleDe);
      expect(edited.definitionKo, original.definitionKo);
      expect(edited.savedToPackId, original.savedToPackId);
    },
  );
}

class _FinalizeFailingStore extends ManagedMediaStore {
  _FinalizeFailingStore.from(ManagedMediaStore source)
    : super(
        documentsDirectory: source.documentsDirectory,
        temporaryDirectory: source.temporaryDirectory,
        nonce: () => DateTime.now().microsecondsSinceEpoch.toString(),
      );

  @override
  Future<void> finalize(ManagedMediaPromotion promotion) async {
    throw FileSystemException('pending cleanup failed');
  }
}

class _TransientPromoteStore extends ManagedMediaStore {
  _TransientPromoteStore.from(ManagedMediaStore source)
    : super(
        documentsDirectory: source.documentsDirectory,
        temporaryDirectory: source.temporaryDirectory,
        nonce: () => DateTime.now().microsecondsSinceEpoch.toString(),
      );

  var _fail = true;

  @override
  Future<ManagedMediaPromotion> promote(PendingMediaLease lease) {
    if (_fail) {
      _fail = false;
      throw StateError('copy failed');
    }
    return super.promote(lease);
  }
}

class _FilePicker extends ImagePicker {
  _FilePicker(this.file);

  final XFile file;

  @override
  Future<XFile?> pickImage({
    required ImageSource source,
    double? maxWidth,
    double? maxHeight,
    int? imageQuality,
    CameraDevice preferredCameraDevice = CameraDevice.rear,
    bool requestFullMetadata = true,
  }) async => file;
}

class _FalseStringStore implements PreferenceStringStore {
  @override
  Future<bool> remove(String key) async => false;

  @override
  Future<bool> setString(String key, String value) async => false;
}
