// Phase 5 (stately-rising-jongga) — BookPage / Bookshelf JSON round-trip.

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ko_lernen_app/models/book_page.dart';
import 'package:ko_lernen_app/services/bookshelf_service.dart';
import 'package:ko_lernen_app/services/storage_service.dart';

BookPage _samplePage({String id = 'p_test_1'}) => BookPage(
  id: id,
  localThumbnailPath: 'book:img.jpg',
  extractedText: '한국어 공부를 하고 있어요.',
  note: 'Lektion 5',
  words: const [
    ExtractedWord(
      korean: '공부',
      romanization: 'gongbu',
      posDe: 'Nomen',
      translationDe: 'Studium',
      translationEn: 'studying',
      exampleKorean: '한국어 공부를 하고 있어요.',
      exampleDe: 'Ich lerne gerade Koreanisch.',
      savedToPackId: null,
    ),
  ],
  grammar: const [
    GrammarHit(
      patternId: 'g_progressive',
      nameDe: 'Progressiv (-고 있다)',
      matchedText: '하고 있어요',
      level: 'A2',
      explanationDe: 'Beschreibt eine gerade ablaufende Handlung.',
    ),
  ],
  sentences: const [
    TranslatedSentence(
      korean: '한국어 공부를 하고 있어요.',
      translationDe: 'Ich lerne gerade Koreanisch.',
    ),
  ],
  capturedAtIso: '2026-05-31T12:00:00Z',
  customPackId: null,
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    Storage.resetForTesting();
    SharedPreferences.setMockInitialValues({});
    await Storage.init();
  });

  group('BookPage round-trip', () {
    test('toLocalJson → fromJson preserves all fields', () {
      final p = _samplePage();
      final json = p.toLocalJson();
      final p2 = BookPage.fromJson(p.id, json);
      expect(p2.id, p.id);
      expect(p2.localThumbnailPath, p.localThumbnailPath);
      expect(p2.extractedText, p.extractedText);
      expect(p2.note, p.note);
      expect(p2.words.length, p.words.length);
      expect(p2.words[0].korean, '공부');
      expect(p2.grammar.length, 1);
      expect(p2.grammar[0].patternId, 'g_progressive');
      expect(p2.sentences[0].korean, p.sentences[0].korean);
      expect(p2.capturedAtIso, p.capturedAtIso);
    });

    test('toFirestoreJson omits localThumbnailPath', () {
      final json = _samplePage().toFirestoreJson();
      expect(json.containsKey('localThumbnailPath'), isFalse);
      expect(json['extractedText'], isNotNull);
    });

    test('fromJson with missing fields uses safe defaults', () {
      final p = BookPage.fromJson('x', const <String, dynamic>{});
      expect(p.id, 'x');
      expect(p.extractedText, '');
      expect(p.words, isEmpty);
      expect(p.grammar, isEmpty);
      expect(p.sentences, isEmpty);
    });
  });

  group('BookshelfService local', () {
    test('save → getById returns same page', () async {
      final p = _samplePage(id: 'p_a');
      await BookshelfService.save(p);
      final fetched = BookshelfService.getById('p_a');
      expect(fetched, isNotNull);
      expect(fetched!.extractedText, p.extractedText);
    });

    test('getAllLocal sorted by capturedAt desc', () async {
      await BookshelfService.save(
        BookPage(
          id: 'a',
          localThumbnailPath: null,
          extractedText: 'A',
          note: '',
          words: const [],
          grammar: const [],
          sentences: const [],
          capturedAtIso: '2026-01-01T00:00:00Z',
          customPackId: null,
        ),
      );
      await BookshelfService.save(
        BookPage(
          id: 'b',
          localThumbnailPath: null,
          extractedText: 'B',
          note: '',
          words: const [],
          grammar: const [],
          sentences: const [],
          capturedAtIso: '2026-05-01T00:00:00Z',
          customPackId: null,
        ),
      );
      final all = BookshelfService.getAllLocal();
      expect(all.length, 2);
      expect(all.first.id, 'b'); // most recent first
    });

    test('delete removes page', () async {
      await BookshelfService.save(_samplePage(id: 'gone'));
      await BookshelfService.delete('gone');
      expect(BookshelfService.getById('gone'), isNull);
    });

    test('generateId returns unique values + p_ prefix', () {
      final ids = <String>{};
      for (var i = 0; i < 50; i++) {
        ids.add(BookshelfService.generateId());
      }
      expect(ids.length, 50);
      for (final id in ids) {
        expect(id.startsWith('p_'), isTrue);
      }
    });
  });

  group('Storage book snap quota', () {
    test('default 0, increments to limit', () async {
      expect(Storage.bookSnapCountToday(), 0);
      expect(Storage.bookSnapQuotaReached, isFalse);
      for (var i = 0; i < Storage.kBookSnapDailyLimit; i++) {
        await Storage.incBookSnapCountToday();
      }
      expect(Storage.bookSnapCountToday(), Storage.kBookSnapDailyLimit);
      expect(Storage.bookSnapQuotaReached, isTrue);
    });
  });
}
