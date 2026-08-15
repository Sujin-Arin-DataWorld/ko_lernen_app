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

    test('English analysis provenance survives local and cloud JSON', () {
      final source = BookPage(
        id: 'p_en',
        localThumbnailPath: null,
        extractedText: '저는 학생이에요.',
        note: '',
        words: const [
          ExtractedWord(
            korean: '학생',
            romanization: 'haksaeng',
            posDe: 'noun',
            translationDe: 'student',
            translationEn: 'student',
            translationLanguage: 'en',
            exampleKorean: '저는 학생이에요.',
            exampleDe: 'I am a student.',
            savedToPackId: null,
          ),
        ],
        grammar: const [],
        sentences: const [
          TranslatedSentence(
            korean: '저는 학생이에요.',
            translationDe: 'I am a student.',
            translationLanguage: 'en',
          ),
        ],
        capturedAtIso: '2026-08-15T12:00:00Z',
        customPackId: null,
        analysisLanguage: 'en',
      );

      final restored = BookPage.fromJson(source.id, source.toLocalJson());
      expect(restored.analysisLanguage, 'en');
      expect(restored.words.single.translationLanguage, 'en');
      expect(restored.sentences.single.translationLanguage, 'en');
      expect(source.toFirestoreJson()['analysisLanguage'], 'en');
    });

    test('fromJson with missing fields uses safe defaults', () {
      final p = BookPage.fromJson('x', const <String, dynamic>{});
      expect(p.id, 'x');
      expect(p.extractedText, '');
      expect(p.words, isEmpty);
      expect(p.grammar, isEmpty);
      expect(p.sentences, isEmpty);
    });

    test(
      'legacy local and Firestore data cannot restore unsafe learning text',
      () {
        final page = BookPage.fromJson('legacy', {
          'localThumbnailPath': 'book:legacy.jpg',
          'extractedText': 'Berlin에 K-pop 음악\u202E العربية\nNur Deutsch',
          'note': 'Lektion 7',
          'words': [
            {
              'korean': '학\u200B생 العربية',
              'romanization': 'haksaeng\u202E العربية',
              'posDe': 'Nomen\u007F\u0085 العربية',
              'translationDe': 'Schüler العربية',
              'translationEn': 'student العربية',
              'translationLanguage': 'en',
              'exampleKorean': '저는 학생이에요.\u2066 العربية',
              'exampleDe': 'Ich bin Schüler. العربية',
              'definitionKo': '배우는 사람 العربية',
              'imagePath': 'word:legacy.jpg',
            },
            {'korean': 'العربية', 'translationDe': 'Arabisch'},
            {'korean': '책', 'translationDe': 'العربية'},
          ],
          'grammar': [
            {
              'patternId': 'g_topic\u202E',
              'nameDe': 'Thema العربية',
              'matchedText': '저는\u200F العربية',
              'level': 'A1\u0000',
              'explanationDe': 'Markiert das Thema. العربية',
            },
            {'matchedText': 'العربية'},
          ],
          'sentences': [
            {
              'korean': '저는 학생이에요.\u202D العربية',
              'translationDe': 'I am a student. العربية',
              'translationLanguage': 'en',
            },
            {'korean': 'العربية', 'translationDe': 'Arabic'},
          ],
          'capturedAt': '2026-08-15T12:00:00Z',
          'analysisLanguage': 'en',
        });

        expect(page.localThumbnailPath, 'book:legacy.jpg');
        expect(page.extractedText, 'Berlin에 K-pop 음악');
        expect(page.note, 'Lektion 7');
        expect(page.analysisLanguage, 'en');

        expect(page.words, hasLength(1));
        final word = page.words.single;
        expect(word.korean, '학생');
        expect(word.translationDe, 'Schüler');
        expect(word.translationEn, 'student');
        expect(word.translationLanguage, 'en');
        expect(word.imagePath, 'word:legacy.jpg');
        expect(word.exampleKorean, '저는 학생이에요.');

        expect(page.grammar, hasLength(1));
        expect(page.grammar.single.matchedText, '저는');
        expect(page.sentences, hasLength(1));
        expect(page.sentences.single.korean, '저는 학생이에요.');
        expect(page.sentences.single.translationLanguage, 'en');

        final restoredLearningText = [
          page.extractedText,
          ...page.words.expand(
            (entry) => [
              entry.korean,
              entry.romanization,
              entry.posDe,
              entry.translationDe,
              entry.translationEn,
              entry.exampleKorean,
              entry.exampleDe,
              entry.definitionKo,
            ],
          ),
          ...page.grammar.expand(
            (entry) => [
              entry.patternId,
              entry.nameDe,
              entry.matchedText,
              entry.level,
              entry.explanationDe,
            ],
          ),
          ...page.sentences.expand(
            (entry) => [entry.korean, entry.translationDe],
          ),
        ].join('\n');
        expect(_containsUnsupportedLegacyText(restoredLearningText), isFalse);
      },
    );

    test('portable legacy restore applies the same fail-closed filters', () {
      final page = BookPage.fromPortableJson('portable', {
        'localThumbnailPath': 'book:must-not-restore.jpg',
        'extractedText': '먹을 음식\u061C العربية',
        'words': [
          {
            'korean': '음식\u202E العربية',
            'translationDe': 'food العربية',
            'translationEn': 'food العربية',
            'translationLanguage': 'en',
            'imagePath': 'word:must-not-restore.jpg',
          },
          {'korean': '단어', 'translationDe': '\u202E العربية'},
        ],
        'grammar': [
          {'matchedText': '먹을\u200B العربية'},
          {'matchedText': '\u202E العربية'},
        ],
        'sentences': [
          {
            'korean': '먹을 음식이에요. العربية',
            'translationDe': 'It is food. العربية',
            'translationLanguage': 'en',
          },
        ],
        'analysisLanguage': 'en',
      });

      expect(page.localThumbnailPath, isNull);
      expect(page.extractedText, '먹을 음식');
      expect(page.words, hasLength(1));
      expect(page.words.single.korean, '음식');
      expect(page.words.single.translationEn, 'food');
      expect(page.words.single.translationLanguage, 'en');
      expect(page.words.single.imagePath, isEmpty);
      expect(page.grammar, hasLength(1));
      expect(page.grammar.single.matchedText, '먹을');
      expect(page.sentences.single.korean, '먹을 음식이에요.');
      expect(
        _containsUnsupportedLegacyText(
          [
            page.extractedText,
            page.words.single.korean,
            page.words.single.translationDe,
            page.words.single.translationEn,
            page.grammar.single.matchedText,
            page.sentences.single.korean,
            page.sentences.single.translationDe,
          ].join('\n'),
        ),
        isFalse,
      );
    });
  });

  group('Book analysis safety contract', () {
    const meaningfulSentence = TranslatedSentence(
      korean: '저는 학생이에요.',
      translationDe: '',
    );

    test('translation outage keeps Korean content saveable', () {
      const result = BookAnalysisResult(
        words: [],
        grammar: [],
        sentences: [meaningfulSentence],
        warnings: ['translation_unavailable'],
      );

      expect(result.hasMeaningfulResult, isTrue);
      expect(result.isSaveable, isTrue);
    });

    test('empty or contaminated results cannot be saved', () {
      const empty = BookAnalysisResult(
        words: [],
        grammar: [],
        sentences: [],
        warnings: [],
      );
      const contaminated = BookAnalysisResult(
        words: [],
        grammar: [],
        sentences: [meaningfulSentence],
        warnings: ['invalid_response_filtered'],
      );

      expect(empty.hasMeaningfulResult, isFalse);
      expect(empty.isSaveable, isFalse);
      expect(contaminated.hasMeaningfulResult, isTrue);
      expect(contaminated.isSaveable, isFalse);
    });

    test('editable English meanings preserve both language slots', () {
      final source = ExtractedWord.manual(
        korean: '학생',
        translationDe: 'Schüler',
      );
      final edited = source.copyWithEditable(
        translationDe: 'student',
        translationEn: 'student',
        translationLanguage: 'en',
      );

      expect(edited.translationDe, 'student');
      expect(edited.translationEn, 'student');
      expect(edited.translationLanguage, 'en');
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

bool _containsUnsupportedLegacyText(String value) => RegExp(
  r'[\u0600-\u06FF\u200B-\u200F\u202A-\u202E\u2060-\u206F\u0000-\u0008\u000B\u000C\u000E-\u001F\u007F-\u009F]',
).hasMatch(value);
