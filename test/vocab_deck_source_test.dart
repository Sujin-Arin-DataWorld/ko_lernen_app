import 'package:flutter_test/flutter_test.dart';
import 'package:ko_lernen_app/models/book_page.dart';
import 'package:ko_lernen_app/models/scenario.dart';
import 'package:ko_lernen_app/services/kkeunmari_engine.dart';
import 'package:ko_lernen_app/services/vocab_deck_source.dart';

KkeunmariWord word(String text) => KkeunmariWord(
  word: text,
  first: text[0],
  last: text[text.length - 1],
  level: 'A2',
  german: text,
  topic: 'test',
  nextCount: 99,
  isDeadEnd: false,
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  tearDown(KkeunmariEngine.reset);

  test(
    'captures ordered rows and original meanings without changing the pack',
    () {
      final rows = [
        ExtractedWord.manual(
          korean: '학교',
          translationDe: 'meine Schule',
          translationEn: 'my school',
        ),
        ExtractedWord.manual(korean: '학교', translationDe: 'zweite Bedeutung'),
        ExtractedWord.manual(
          korean: 'ABC',
          translationDe: '',
          translationEn: 'alphabet',
        ),
      ];
      final source = VocabDeckSource(packId: 'own-pack', words: rows);
      rows.clear();
      expect(source.packId, 'own-pack');
      expect(source.words, hasLength(3));
      // The manual-entry model sanitizes non-Korean text before this boundary.
      expect(source.vocabulary.map((w) => w.korean), ['학교', '학교']);
      expect(source.vocabulary.first.german, 'meine Schule');
      expect(source.vocabulary.first.english, 'my school');
      expect(source.meaningFor('학교', 'de'), 'meine Schule');
      expect(source.meaningFor('학교', 'en'), 'my school');
      expect(source.meaningFor('교실', 'de'), isEmpty);
      expect(source.chosung.map((w) => w.korean), ['학교', '학교']);
      expect(() => source.words.clear(), throwsUnsupportedError);
      expect(() => source.chosung.clear(), throwsUnsupportedError);
    },
  );

  test(
    'word chain requires exact dictionary membership and deduplicates rows',
    () {
      final source = VocabDeckSource(
        packId: 'p',
        words: [
          for (final text in ['학교', '학교', '교실', '학교에 가요', '뢔뷁'])
            ExtractedWord.manual(korean: text, translationDe: ''),
        ],
      );
      final pool = source.wordChainPool([
        word('학교'),
        word('교실'),
        word('실내'),
        word('학교'),
      ]);
      expect(pool.map((w) => w.word), ['학교', '교실']);
      expect(() => pool.clear(), throwsUnsupportedError);
      expect(KkeunmariEngine.hasChain(pool), isTrue);
      expect(KkeunmariEngine.hasChain([word('학교'), word('나무')]), isFalse);
      expect(KkeunmariEngine.hasChain([word('기러기')]), isFalse);
      expect(KkeunmariEngine.hasChain([]), isFalse);
    },
  );

  test(
    'custom start, replies, validation and level fallback stay in their source',
    () {
      final normal = [word('학교'), word('교실'), word('실내'), word('내일')];
      KkeunmariEngine.setPoolForTesting(normal);
      final selected = [word('학교'), word('교실')];
      expect(
        KkeunmariEngine.pickStart(
          source: selected,
          maxLevel: LearnerLevel.a1,
        ).word,
        '학교',
      );
      expect(
        KkeunmariEngine.nextCountFor('실', {'학교', '교실'}, source: selected),
        0,
      );
      expect(
        KkeunmariEngine.pickTigerNext('실', {'학교', '교실'}, source: selected),
        isNull,
      );
      expect(
        KkeunmariEngine.validateUserWord('실내', '실', {}, source: selected).$1,
        isFalse,
      );
      expect(
        KkeunmariEngine.validateUserWord('교실', '교', {
          '교실',
        }, source: selected).$2,
        'already_used',
      );
      expect(
        KkeunmariEngine.validateUserWord('교실', '교', {}, source: selected).$1,
        isTrue,
      );
      expect(KkeunmariEngine.pool, normal);
      expect(KkeunmariEngine.pickTigerNext('실', {'학교', '교실'})!.word, '실내');
      expect(KkeunmariEngine.nextCountFor('실', {}, source: []), 0);
    },
  );
}
