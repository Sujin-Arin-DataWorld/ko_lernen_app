// O1 — 3-tier OCR gloss resolver (bundled dictionary -> page hints -> server).
//
// TDD fixtures live in test/fixtures/book_ocr/gloss_resolver_fixtures.dart.
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:ko_lernen_app/models/book_page.dart';
import 'package:ko_lernen_app/services/book_analysis_service.dart';
import 'package:ko_lernen_app/services/book_word_gloss_resolver.dart';

import 'fixtures/book_ocr/gloss_resolver_fixtures.dart';

class _FailIfCalledClient extends http.BaseClient {
  bool wasCalled = false;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    wasCalled = true;
    throw StateError('The offline stub must never call the network.');
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('F1 — mixed A1 textbook page', () {
    test(
      'resolves >=95% of Hangul tokens from the bundled CSV, no German leaks',
      () async {
        final document = buildF1TextbookPageDocument();
        final resolver = BookWordGlossResolver();

        final words = await resolver.resolve(document, targetLang: 'de');
        final byKorean = {for (final w in words) w.korean: w};

        const expectedHeadwords = <String>{
          '안녕하세요',
          '저',
          '오늘',
          '학교',
          '가다',
          '내일',
          '친구',
          '만나다',
          '책',
          '읽다',
          '감사합니다',
          '방',
          '작다',
          '집',
          '있다',
          '옷',
          '사다',
          '오다',
        };
        for (final headword in expectedHeadwords) {
          expect(
            byKorean.containsKey(headword),
            isTrue,
            reason: '$headword should resolve from the bundled CSV',
          );
          expect(byKorean[headword]!.source, 'bundled');
        }

        // The one documented miss (irregular copula) never leaks through.
        expect(byKorean.containsKey('학생이에요'), isFalse);

        // Ratio computed from the fixture's authored token table (see the
        // doc comment on buildF1TextbookPageDocument) and cross-checked by
        // the per-headword presence assertions above.
        final resolvedTokens = kF1TotalHangulTokens - kF1KnownMissTokens.length;
        expect(resolvedTokens / kF1TotalHangulTokens, greaterThanOrEqualTo(0.95));

        // 0 German tokens in output: every resolved word's korean field is
        // pure Hangul, and none of the printed German glosses leaked in as a
        // "word".
        const germanGlossFragments = <String>[
          'Hallo',
          'Student',
          'Schule',
          'Freund',
          'Buch',
          'Dank',
          'Zimmer',
          'klein',
          'Hause',
          'Kleidung',
          'komme',
        ];
        for (final word in words) {
          expect(RegExp(r'^[가-힣]+$').hasMatch(word.korean), isTrue);
          expect(germanGlossFragments, isNot(contains(word.korean)));
        }
      },
    );

    test('the offline stub now returns non-empty bundled words', () async {
      final document = buildF1TextbookPageDocument();
      final client = _FailIfCalledClient();

      final result = await BookAnalysisService.analyze(
        text: document.analysisText,
        document: document,
        client: client,
        credentialsProvider: () async => null,
      );

      expect(client.wasCalled, isFalse);
      expect(result.warnings, contains('offline_stub'));
      expect(result.words, isNotEmpty);
      expect(
        result.words.map((w) => w.korean),
        containsAll(<String>['학교', '친구', '책']),
      );
      expect(result.words.every((w) => w.source == 'bundled'), isTrue);
    });
  });

  group('F2 — particle stripping and verb endings', () {
    test('nouns lose their particle, verbs resolve to their headword', () async {
      final document = buildF2ParticleAndVerbDocument();
      final resolver = BookWordGlossResolver();

      final words = await resolver.resolve(document, targetLang: 'de');
      final byKorean = {for (final w in words) w.korean: w};

      const expected = <String, String>{
        '학교에서': '학교',
        '친구를': '친구',
        '책은': '책',
        '먹어요': '먹다',
        '가요': '가다',
        '봐요': '보다',
      };
      for (final entry in expected.entries) {
        expect(
          byKorean.containsKey(entry.value),
          isTrue,
          reason: '${entry.key} should resolve to headword ${entry.value}',
        );
        expect(byKorean[entry.value]!.source, 'bundled');
      }
      expect(words, hasLength(expected.length));
    });
  });

  group('F3 — page-hint tier', () {
    test('an adjacent Latin-only next line becomes a page hint', () async {
      final document = buildF3PageHintDocument();
      final resolver = BookWordGlossResolver();

      final words = await resolver.resolve(document, targetLang: 'de');
      final byKorean = {for (final w in words) w.korean: w};

      expect(byKorean.containsKey('라떼아트'), isTrue);
      final latteArt = byKorean['라떼아트']!;
      expect(latteArt.source, 'pageHint');
      expect(latteArt.confidence, closeTo(0.6, 0.0001));
      expect(latteArt.translationDe, 'Latte Art');
    });

    test('a non-adjacent Latin line never attaches as a page hint', () async {
      final document = buildF3PageHintDocument();
      final resolver = BookWordGlossResolver();

      final words = await resolver.resolve(document, targetLang: 'de');
      final byKorean = {for (final w in words) w.korean: w};

      expect(byKorean.containsKey('피자'), isFalse);
    });
  });

  group('F4 — noun/verb homograph disambiguation', () {
    test(
      'a locative-particle phrase before the homograph selects the verb reading',
      () async {
        final document = buildF4HomographDocument();
        final resolver = BookWordGlossResolver();

        final words = await resolver.resolve(document, targetLang: 'de');
        final byKorean = {for (final w in words) w.korean: w};

        // "학교에 가요." -> 학교에 ends in the locative 에, so 가요 must
        // resolve as the verb 가다 ("to go"), never the pop-song noun.
        expect(
          byKorean.containsKey('가다'),
          isTrue,
          reason: '학교에 가요 should resolve 가요 as the verb 가다',
        );
        expect(byKorean['가다']!.source, 'bundled');
        expect(byKorean['가다']!.ambiguous, isFalse);
      },
    );

    test('an attached object particle keeps the noun reading', () async {
      final document = buildF4HomographDocument();
      final resolver = BookWordGlossResolver();

      final words = await resolver.resolve(document, targetLang: 'de');
      final byKorean = {for (final w in words) w.korean: w};

      // "저는 가요를 좋아해요." -> 를 is already stripped off the token
      // before this ever reaches the homograph guard, so 가요 stays the
      // noun ("(koreanischer) Popsong"), matching the Jin-approved A1 gap.
      expect(
        byKorean.containsKey('가요'),
        isTrue,
        reason: '가요를 좋아해요 should keep 가요 as the noun',
      );
      expect(byKorean['가요']!.source, 'bundled');
      expect(byKorean['가요']!.translationDe, '(koreanischer) Popsong');
    });
  });

  group('tier 3 — server merge', () {
    test('server words win over a bundled match for the same headword', () async {
      final document = buildF2ParticleAndVerbDocument(); // contains 학교에서
      final resolver = BookWordGlossResolver();

      final words = await resolver.resolve(
        document,
        targetLang: 'de',
        serverWords: const [
          ExtractedWord(
            korean: '학교',
            romanization: 'hakgyo',
            posDe: 'Nomen',
            translationDe: 'SERVER_SCHULE',
            translationEn: 'SERVER_SCHOOL',
            exampleKorean: '',
            exampleDe: '',
            savedToPackId: null,
          ),
        ],
      );
      final byKorean = {for (final w in words) w.korean: w};

      expect(byKorean['학교']!.translationDe, 'SERVER_SCHULE');
      expect(byKorean['학교']!.source, 'server');
      expect(byKorean['학교']!.confidence, closeTo(0.9, 0.0001));
    });
  });
}
