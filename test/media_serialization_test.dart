import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:ko_lernen_app/models/book_page.dart';
import 'package:ko_lernen_app/models/custom_pack.dart';
import 'package:ko_lernen_app/services/cloud_sync.dart';
import 'package:ko_lernen_app/services/bookshelf_service.dart';
import 'package:ko_lernen_app/services/custom_pack_service.dart';
import 'package:ko_lernen_app/services/storage_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

ExtractedWord fullWord({String imagePath = 'word:photo.jpg'}) => ExtractedWord(
  korean: '사과',
  romanization: 'sagwa',
  posDe: 'Nomen',
  translationDe: 'Apfel',
  translationEn: 'apple',
  exampleKorean: '사과를 먹어요.',
  exampleDe: 'Ich esse einen Apfel.',
  definitionKo: '과일',
  imagePath: imagePath,
  savedToPackId: 'cp_saved',
);

enum _MutationResult {
  returnsTrue,
  falseButCommitted,
  throwButCommitted,
  falseAndRejected,
  throwAndRejected,
  thirdState,
  reloadFailure,
}

class _CacheMutatingStringStore implements PreferenceStringStore {
  _CacheMutatingStringStore({
    required Map<String, String> initial,
    required this.result,
  }) : cache = Map<String, String>.from(initial),
       durable = Map<String, String>.from(initial);

  final Map<String, String> cache;
  final Map<String, String> durable;
  _MutationResult result;
  int setCalls = 0;

  @override
  bool containsKey(String key) => cache.containsKey(key);

  @override
  String? getString(String key) => cache[key];

  @override
  Future<void> reload() async {
    if (result == _MutationResult.reloadFailure) {
      throw StateError('reload failed');
    }
    cache
      ..clear()
      ..addAll(durable);
  }

  @override
  Future<bool> remove(String key) async {
    cache.remove(key);
    switch (result) {
      case _MutationResult.returnsTrue:
        durable.remove(key);
        return true;
      case _MutationResult.falseButCommitted:
        durable.remove(key);
        return false;
      case _MutationResult.throwButCommitted:
        durable.remove(key);
        throw StateError('remove reported failure after commit');
      case _MutationResult.falseAndRejected:
        return false;
      case _MutationResult.throwAndRejected:
      case _MutationResult.reloadFailure:
        throw StateError('remove failed');
      case _MutationResult.thirdState:
        durable[key] = 'third';
        return false;
    }
  }

  @override
  Future<bool> setString(String key, String value) async {
    setCalls++;
    cache[key] = value;
    switch (result) {
      case _MutationResult.returnsTrue:
        durable[key] = value;
        return true;
      case _MutationResult.falseButCommitted:
        durable[key] = value;
        return false;
      case _MutationResult.throwButCommitted:
        durable[key] = value;
        throw StateError('write reported failure after commit');
      case _MutationResult.falseAndRejected:
        return false;
      case _MutationResult.throwAndRejected:
      case _MutationResult.reloadFailure:
        throw StateError('write failed');
      case _MutationResult.thirdState:
        durable[key] = 'third';
        return false;
    }
  }
}

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    Storage.resetForTesting();
    await Storage.init();
  });

  test('local round trip keeps valid opaque refs and every word field', () {
    final original = fullWord();
    final decoded = ExtractedWord.fromLocalJson(original.toLocalJson());

    expect(decoded.toLocalJson(), original.toLocalJson());
  });

  test('portable word and pack serialization strips all local refs', () {
    final word = fullWord();
    final pack = CustomPack.manual(id: 'cp', name: 'Pack', words: [word]);

    expect(word.toPortableJson().containsKey('imagePath'), isFalse);
    final portable = pack.toPortableJson();
    expect(
      (portable['words'] as List).single as Map<String, dynamic>,
      isNot(contains('imagePath')),
    );
    expect(
      CustomPack.fromPortableJson('remote', {
        ...portable,
        'words': [
          {...word.toLocalJson(), 'imagePath': r'C:\hostile.jpg'},
        ],
      }).words.single.imagePath,
      isEmpty,
    );
  });

  test('Firestore BookPage strips thumbnail and nested word image refs', () {
    final page = BookPage(
      id: 'p',
      localThumbnailPath: 'book:page.jpg',
      extractedText: 'text',
      note: '',
      words: [fullWord()],
      grammar: const [],
      sentences: const [],
      capturedAtIso: '2026-07-29T00:00:00.000Z',
      customPackId: null,
    );

    final firestore = page.toFirestoreJson();
    expect(firestore.containsKey('localThumbnailPath'), isFalse);
    expect(
      (firestore['words'] as List).single as Map<String, dynamic>,
      isNot(contains('imagePath')),
    );
    expect(
      BookPage.fromPortableJson('remote', {
        ...firestore,
        'localThumbnailPath': '/tmp/hostile.jpg',
      }).localThumbnailPath,
      isNull,
    );
  });

  test(
    'cloud backup and restore deliberately remove local media refs',
    () async {
      await Storage.setCustomPacksRawJson(
        jsonEncode({
          'cp': {
            'name': 'Pack',
            'sourcePageId': '',
            'createdAt': '2026-07-29T00:00:00.000Z',
            'words': [fullWord().toLocalJson()],
          },
        }),
      );
      await Storage.setBookshelfRawJson(
        jsonEncode({
          'p': {
            'localThumbnailPath': 'book:page.jpg',
            'extractedText': 'text',
            'note': '',
            'words': [fullWord().toLocalJson()],
            'grammar': const [],
            'sentences': const [],
            'capturedAt': '2026-07-29T00:00:00.000Z',
          },
        }),
      );

      final backup = await CloudSync.buildBackupPayload();
      expect(backup['custom_packs_json'], isNot(contains('word:photo.jpg')));
      expect(backup['bookshelf_json'], isNot(contains('book:page.jpg')));

      await Storage.resetAll();
      await CloudSync.applyRestorePayload({
        'custom_packs_json': jsonEncode({
          'cp': {
            'words': [
              {...fullWord().toLocalJson(), 'imagePath': r'\\host\share\x.jpg'},
            ],
          },
        }),
        'bookshelf_json': jsonEncode({
          'p': {
            'localThumbnailPath': '/tmp/x.jpg',
            'words': [fullWord().toLocalJson()],
          },
        }),
      });

      expect(Storage.customPacksRawJson, isNot(contains('imagePath')));
      expect(Storage.bookshelfRawJson, isNot(contains('localThumbnailPath')));
      expect(Storage.bookshelfRawJson, isNot(contains('imagePath')));
    },
  );

  test(
    'strict writes accept false or throw when reload proves durable commit',
    () async {
      for (final result in const [
        _MutationResult.falseButCommitted,
        _MutationResult.throwButCommitted,
      ]) {
        final store = _CacheMutatingStringStore(
          initial: const {'kl_bookshelf_v1': 'original'},
          result: result,
        );

        await Storage.setBookshelfRawJsonStrict(
          'requested',
          preferences: store,
        );

        expect(store.cache['kl_bookshelf_v1'], 'requested');
        expect(store.durable['kl_bookshelf_v1'], 'requested');
      }
    },
  );

  test(
    'strict writes restore cache and reject when reload proves prior value',
    () async {
      for (final result in const [
        _MutationResult.falseAndRejected,
        _MutationResult.throwAndRejected,
      ]) {
        final store = _CacheMutatingStringStore(
          initial: const {'kl_custom_packs_v1': 'original'},
          result: result,
        );

        await expectLater(
          Storage.setCustomPacksRawJsonStrict('requested', preferences: store),
          throwsA(isA<PreferenceWriteException>()),
        );

        expect(store.cache['kl_custom_packs_v1'], 'original');
        expect(store.durable['kl_custom_packs_v1'], 'original');
      }
    },
  );

  test(
    'strict writes type unknown outcomes and require refresh before retry',
    () async {
      final thirdState = _CacheMutatingStringStore(
        initial: const {'kl_bookshelf_v1': 'original'},
        result: _MutationResult.thirdState,
      );

      await expectLater(
        Storage.setBookshelfRawJsonStrict('requested', preferences: thirdState),
        throwsA(isA<PreferenceOutcomeUnknownException>()),
      );
      expect(thirdState.cache['kl_bookshelf_v1'], 'third');
      expect(thirdState.durable['kl_bookshelf_v1'], 'third');

      thirdState.result = _MutationResult.returnsTrue;
      await expectLater(
        Storage.setBookshelfRawJsonStrict('retry', preferences: thirdState),
        throwsA(isA<PreferenceWriteException>()),
      );
      expect(thirdState.setCalls, 1);
      expect(thirdState.cache['kl_bookshelf_v1'], 'third');
      expect(thirdState.durable['kl_bookshelf_v1'], 'third');

      await Storage.setBookshelfRawJsonStrict('retry', preferences: thirdState);
      expect(thirdState.setCalls, 2);
      expect(thirdState.durable['kl_bookshelf_v1'], 'retry');

      Storage.resetForTesting();
      final reloadFailure = _CacheMutatingStringStore(
        initial: const {'kl_bookshelf_v1': 'original'},
        result: _MutationResult.reloadFailure,
      );
      await expectLater(
        Storage.setBookshelfRawJsonStrict(
          'requested',
          preferences: reloadFailure,
        ),
        throwsA(isA<PreferenceOutcomeUnknownException>()),
      );
      expect(reloadFailure.cache['kl_bookshelf_v1'], 'requested');
      expect(reloadFailure.durable['kl_bookshelf_v1'], 'original');
    },
  );

  test(
    'structured retry aborts stale payload then rereads durable model',
    () async {
      const key = 'kl_custom_packs_v1';
      final store = _CacheMutatingStringStore(
        initial: const {key: '{"durable":{"name":"kept"}}'},
        result: _MutationResult.reloadFailure,
      );

      Future<void> addEntry(String id) async {
        final decoded = (jsonDecode(store.getString(key)!) as Map)
            .cast<String, dynamic>();
        decoded[id] = {'name': id};
        await Storage.setCustomPacksRawJsonStrict(
          jsonEncode(decoded),
          preferences: store,
        );
      }

      await expectLater(
        addEntry('optimistic'),
        throwsA(isA<PreferenceOutcomeUnknownException>()),
      );
      expect(store.setCalls, 1);
      expect(store.durable[key], '{"durable":{"name":"kept"}}');
      expect(store.cache[key], contains('optimistic'));

      store.result = _MutationResult.returnsTrue;
      await expectLater(
        addEntry('stale-retry'),
        throwsA(isA<PreferenceWriteException>()),
      );
      expect(store.setCalls, 1);
      expect(store.cache[key], '{"durable":{"name":"kept"}}');
      expect(store.durable[key], '{"durable":{"name":"kept"}}');

      await addEntry('fresh-retry');
      expect(store.setCalls, 2);
      expect(jsonDecode(store.durable[key]!) as Map, {
        'durable': {'name': 'kept'},
        'fresh-retry': {'name': 'fresh-retry'},
      });
    },
  );

  test('cloud backup omits malformed structured local collections', () async {
    await Storage.setBookshelfRawJson('{broken');
    await Storage.setCustomPacksRawJson('[]');

    final payload = await CloudSync.buildBackupPayload();

    expect(payload, isNot(contains('bookshelf_json')));
    expect(payload, isNot(contains('custom_packs_json')));
  });

  test('tolerant UI reads skip malformed nested entries', () async {
    await Storage.setBookshelfRawJson(
      jsonEncode({
        'bad': {
          'words': ['not-a-map'],
        },
      }),
    );
    await Storage.setCustomPacksRawJson(
      jsonEncode({
        'bad': {
          'words': ['not-a-map'],
        },
      }),
    );

    expect(BookshelfService.getAllLocal(), isEmpty);
    expect(BookshelfService.getById('bad'), isNull);
    expect(CustomPackService.getAll(), isEmpty);
    expect(CustomPackService.getById('bad'), isNull);
  });
}
