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

class _FalseStringStore implements PreferenceStringStore {
  @override
  Future<bool> remove(String key) async => false;

  @override
  Future<bool> setString(String key, String value) async => false;
}

class _ThrowingStringStore implements PreferenceStringStore {
  @override
  Future<bool> remove(String key) async => throw StateError('remove failed');

  @override
  Future<bool> setString(String key, String value) async =>
      throw StateError('write failed');
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

      final backup = CloudSync.buildBackupPayload();
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

  test('strict structured writes reject false and propagate exceptions', () {
    expect(
      Storage.setBookshelfRawJsonStrict('{}', preferences: _FalseStringStore()),
      throwsA(isA<PreferenceWriteException>()),
    );
    expect(
      Storage.setCustomPacksRawJsonStrict(
        '{}',
        preferences: _ThrowingStringStore(),
      ),
      throwsStateError,
    );
  });

  test('cloud backup omits malformed structured local collections', () async {
    await Storage.setBookshelfRawJson('{broken');
    await Storage.setCustomPacksRawJson('[]');

    final payload = CloudSync.buildBackupPayload();

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
