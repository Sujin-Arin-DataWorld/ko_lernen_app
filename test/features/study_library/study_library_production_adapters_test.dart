import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:ko_lernen_app/features/study_library/study_library.dart';
import 'package:ko_lernen_app/models/book_page.dart';
import 'package:ko_lernen_app/models/custom_pack.dart';
import 'package:ko_lernen_app/services/custom_pack_service.dart';
import 'package:ko_lernen_app/services/liked_content_service.dart';
import 'package:ko_lernen_app/services/storage_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    Storage.resetForTesting();
    await Storage.init();
  });

  test('legacy CustomPack rows stay word and legacyFlattened', () async {
    final pack = CustomPack.manual(
      id: 'cp-legacy',
      name: 'Legacy',
      words: <ExtractedWord>[
        ExtractedWord.manual(korean: '-고 있다', translationDe: 'gerade tun'),
      ],
      createdAt: DateTime.utc(2026, 1, 1),
    );
    await Storage.setCustomPacksRawJson(
      jsonEncode(<String, Object>{pack.id: pack.toLocalJson()}),
    );

    final records = await const ProductionStudyLibraryCustomPackReader(
      languageCode: 'en',
    ).readCustomPackItems();

    expect(records, hasLength(1));
    expect(records.single.key.type, StudyLibraryItemType.word);
    expect(
      records.single.sources.map((source) => source.origin),
      containsAll(<StudyLibraryOrigin>{
        StudyLibraryOrigin.customPack,
        StudyLibraryOrigin.legacyFlattened,
      }),
    );
  });

  test(
    'only quick wordbook rows are marked as compatibility mirrors',
    () async {
      final quick = CustomPack.manual(
        id: CustomPackService.quickPackId,
        name: 'Quick',
        words: <ExtractedWord>[
          ExtractedWord.manual(korean: '-고 있다', translationDe: 'Verlauf'),
        ],
        createdAt: DateTime.utc(2026, 1, 1),
      );
      final personal = CustomPack.manual(
        id: 'personal-pack',
        name: 'Personal',
        words: <ExtractedWord>[
          ExtractedWord.manual(korean: '학교', translationDe: 'Schule'),
        ],
        createdAt: DateTime.utc(2026, 1, 1),
      );
      await Storage.setCustomPacksRawJson(
        jsonEncode(<String, Object>{
          quick.id: quick.toLocalJson(),
          personal.id: personal.toLocalJson(),
        }),
      );

      final records = await const ProductionStudyLibraryCustomPackReader(
        languageCode: 'en',
      ).readCustomPackItems();

      expect(
        records
            .singleWhere((record) => record.key.id == '-고 있다')
            .sources
            .map((source) => source.origin),
        contains(StudyLibraryOrigin.wordbookMirror),
      );
      expect(
        records
            .singleWhere((record) => record.key.id == '학교')
            .sources
            .map((source) => source.origin),
        isNot(contains(StudyLibraryOrigin.wordbookMirror)),
      );
    },
  );

  test('safe liked ids resolve as learner-facing text', () async {
    for (final (kind, id) in const <(String, String)>[
      (LikedContentService.vocab, '학교'),
      (LikedContentService.grammar, '-고 있다'),
      (LikedContentService.hangul, 'ㅏ'),
    ]) {
      await LikedContentService.toggle(kind: kind, id: id);
    }

    final records = await const ProductionStudyLibraryLikedReader().readLiked();

    expect(records, hasLength(3));
    expect(records.map((record) => record.primaryText).toSet(), <String>{
      '학교',
      '-고 있다',
      'ㅏ',
    });
  });

  test(
    'production readers preserve types and compose without source writes',
    () async {
      final pack = CustomPack.manual(
        id: 'cp-legacy',
        name: 'Legacy',
        words: <ExtractedWord>[
          ExtractedWord.manual(korean: '-고 있다', translationDe: 'Verlauf'),
        ],
        createdAt: DateTime.utc(2026, 1, 1),
      );
      final page = BookPage(
        id: 'page-1',
        localThumbnailPath: null,
        extractedText: '책을 읽고 있어요.',
        note: '',
        words: <ExtractedWord>[
          ExtractedWord.manual(korean: '책', translationDe: 'Buch'),
        ],
        grammar: const <GrammarHit>[
          GrammarHit(
            patternId: 'g-progressive',
            nameDe: 'Verlaufsform',
            matchedText: '읽고 있어요',
            level: 'A2',
            explanationDe: 'Eine laufende Handlung.',
          ),
        ],
        sentences: const <TranslatedSentence>[
          TranslatedSentence(
            korean: '책을 읽고 있어요.',
            translationDe: 'Ich lese gerade ein Buch.',
          ),
        ],
        expressions: const <ExtractedExpression>[
          ExtractedExpression(
            korean: '시간이 나다',
            translationDe: 'Zeit haben',
            translationEn: 'have time',
            translationLanguage: 'de',
            sourceUnitId: 'source-expression',
          ),
        ],
        capturedAtIso: '2026-01-02T00:00:00.000Z',
        customPackId: null,
      );
      final typedPayload = jsonEncode(<String, Object>{
        'version': 1,
        'items': <Object>[
          <String, Object>{
            'type': 'sentence',
            'id': '직접 저장한 문장',
            'primaryText': '직접 저장한 문장',
            'secondaryText': 'Ein direkt gespeicherter Satz.',
          },
        ],
      });
      final initial = <String, Object>{
        'kl_liked_content_v1': <String>['vocab|책', 'future|opaque-1'],
        'kl_custom_packs_v1': jsonEncode(<String, Object>{
          pack.id: pack.toLocalJson(),
        }),
        'kl_bookshelf_v1': jsonEncode(<String, Object>{
          page.id: page.toLocalJson(),
        }),
        'kl_srs_v1': jsonEncode(<String, Object>{
          '책': <String, Object>{'e': 2.5, 'i': 3, 'n': '2026-01-01', 'r': 2},
        }),
        Storage.typedStudyBookmarksPreferenceKey: typedPayload,
      };
      SharedPreferences.setMockInitialValues(initial);
      Storage.resetForTesting();
      await Storage.init();
      final preferences = await SharedPreferences.getInstance();
      final before = <String, Object?>{
        for (final key in initial.keys) key: preferences.get(key),
      };

      final snapshot = await createProductionStudyLibraryRepository(
        languageCode: 'en',
      ).load();

      expect(snapshot.bookmarkHealth, StudyLibraryBookmarkHealth.healthy);
      expect(
        snapshot.entries.map((entry) => entry.key.type).toSet(),
        containsAll(<StudyLibraryItemType>{
          StudyLibraryItemType.word,
          StudyLibraryItemType.grammar,
          StudyLibraryItemType.sentence,
          StudyLibraryItemType.expression,
        }),
      );
      final legacy = snapshot.entries.singleWhere(
        (entry) => entry.key.id == '-고 있다',
      );
      expect(legacy.key.type, StudyLibraryItemType.word);
      expect(legacy.origins, contains(StudyLibraryOrigin.legacyFlattened));

      final grammar = snapshot.entries.singleWhere(
        (entry) => entry.key.id == 'g-progressive',
      );
      expect(grammar.key.type, StudyLibraryItemType.grammar);
      final typedSentence = snapshot.entries.singleWhere(
        (entry) => entry.key.id == '직접 저장한 문장',
      );
      expect(typedSentence.key.type, StudyLibraryItemType.sentence);
      expect(typedSentence.isSaved, isTrue);

      final book = snapshot.entries.singleWhere((entry) => entry.key.id == '책');
      expect(book.isLiked, isTrue);
      expect(book.isSaved, isTrue);
      expect(book.isDue, isTrue);
      expect(snapshot.due, <StudyLibraryEntry>[book]);

      final unresolved = snapshot.entries.singleWhere(
        (entry) => entry.key.id == 'future:opaque-1',
      );
      expect(unresolved.isResolved, isFalse);
      expect(unresolved.isLiked, isTrue);

      final after = <String, Object?>{
        for (final key in initial.keys) key: preferences.get(key),
      };
      expect(after, before);
    },
  );

  test('production SRS adapter ignores never-reviewed rows', () async {
    await Storage.setSrsRawJson(
      jsonEncode(<String, Object>{
        '새것': <String, Object>{'e': 2.5, 'i': 0, 'n': '', 'r': 0},
        '복습': <String, Object>{'e': 2.5, 'i': 1, 'n': '2026-01-01', 'r': 1},
      }),
    );

    final records = await ProductionStudyLibrarySrsReader(
      now: () => DateTime(2026, 8, 26),
    ).readSrsRecords();

    expect(records.map((record) => record.key.id), <String>['복습']);
    expect(records.single.isDue, isTrue);
  });
}
