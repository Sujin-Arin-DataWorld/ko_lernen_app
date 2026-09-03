// Phase 1 (stately-rising-jongga) — VocabPack model + service tests.
//
// Verifiziert:
//   - Vocab.fromRow handles 8-col (legacy) and 11-col (with pack info) rows
//   - VocabPack.baseId / subIndex parse 'a1_greetings_2' correctly
//   - VocabPackService groups by pack_id, sorts by pack_order
//   - bossWords / normalWords filtering
//   - packsForLevel / findById
//   - displayLabel falls back to id when unknown

import 'package:flutter_test/flutter_test.dart';

import 'package:ko_lernen_app/models/vocab.dart';
import 'package:ko_lernen_app/models/vocab_pack.dart';
import 'package:ko_lernen_app/services/data_loader.dart';
import 'package:ko_lernen_app/services/vocab_pack_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Vocab.fromRow', () {
    test('handles legacy 8-column row (no pack info)', () {
      final v = Vocab.fromRow(const [
        '안녕',
        'annyeong',
        'Hallo',
        'A1',
        'Ausdruck',
        '안녕!',
        'Hallo!',
        'Begrüßung',
      ]);
      expect(v.korean, '안녕');
      expect(v.packId, '');
      expect(v.packOrder, 0);
      expect(v.isReviewBoss, false);
    });

    test('handles 11-column row (with pack info)', () {
      final v = Vocab.fromRow(const [
        '안녕',
        'annyeong',
        'Hallo',
        'A1',
        'Ausdruck',
        '안녕!',
        'Hallo!',
        'Begrüßung',
        'a1_greetings_1',
        '2',
        'true',
      ]);
      expect(v.packId, 'a1_greetings_1');
      expect(v.packOrder, 2);
      expect(v.isReviewBoss, true);
    });

    test('handles is_review_boss capitalization variants', () {
      final v1 = Vocab.fromRow(const [
        'a',
        'a',
        'A',
        'A1',
        '',
        '',
        '',
        'T',
        'p',
        '1',
        'TRUE',
      ]);
      expect(v1.isReviewBoss, true);

      final v2 = Vocab.fromRow(const [
        'a',
        'a',
        'A',
        'A1',
        '',
        '',
        '',
        'T',
        'p',
        '1',
        'False',
      ]);
      expect(v2.isReviewBoss, false);
    });

    test('handles short row without crashing (defensive)', () {
      final v = Vocab.fromRow(const ['only', 'two']);
      expect(v.korean, 'only');
      expect(v.romanization, 'two');
      expect(v.german, '');
      expect(v.packId, '');
    });
  });

  group('VocabPack', () {
    test('baseId strips trailing _N', () {
      const p = VocabPack(id: 'a1_greetings_2', level: 'A1', words: []);
      expect(p.baseId, 'a1_greetings');
      expect(p.subIndex, 2);
    });

    test('baseId returns id if no sub-index', () {
      const p = VocabPack(id: 'a1_greetings', level: 'A1', words: []);
      expect(p.baseId, 'a1_greetings');
      expect(p.subIndex, null);
    });

    test('handles multi-word base ids correctly', () {
      const p = VocabPack(id: 'b1_health_education', level: 'B1', words: []);
      expect(p.baseId, 'b1_health_education');
      expect(p.subIndex, null);
    });

    test('bossWords stay in the current pack learn set', () {
      final words = [
        _v('a', packId: 'p', packOrder: 1, isBoss: false),
        _v('b', packId: 'p', packOrder: 2, isBoss: false),
        _v('c', packId: 'p', packOrder: 3, isBoss: true),
        _v('d', packId: 'p', packOrder: 4, isBoss: true),
      ];
      final p = VocabPack(id: 'p', level: 'A1', words: words);
      expect(p.bossWords.map((v) => v.korean), ['c', 'd']);
      expect(p.normalWords.map((v) => v.korean), ['a', 'b']);
      expect(p.learnWords.map((v) => v.korean), ['a', 'b', 'c', 'd']);
      expect(p.total, 4);
    });
  });

  group('VocabPackService.displayLabel', () {
    test('every shipped pack has a localized DE and EN title', () async {
      final packIds = (await DataLoader.loadVocab())
          .map((word) => word.packId)
          .where((id) => id.isNotEmpty)
          .toSet();
      expect(packIds, isNotEmpty);
      for (final language in ['de', 'en']) {
        final missing = packIds.where(
          (id) => VocabPackService.displayLabel(id, lang: language) == id,
        );
        expect(missing, isEmpty, reason: '$language pack titles are missing');
      }
    });

    test('known pack → DE label', () {
      expect(
        VocabPackService.displayLabel('a1_greetings', lang: 'de'),
        'Begrüßung & Höflichkeit',
      );
    });

    test('known pack → EN label', () {
      expect(
        VocabPackService.displayLabel('a1_greetings', lang: 'en'),
        'Greetings & Politeness',
      );
    });

    test('split pack appends (N)', () {
      expect(
        VocabPackService.displayLabel('a1_greetings_2', lang: 'de'),
        'Begrüßung & Höflichkeit (2)',
      );
    });

    test('unknown pack falls back to id', () {
      expect(
        VocabPackService.displayLabel('zz_unknown_99', lang: 'de'),
        'zz_unknown_99',
      );
    });
  });

  group('VocabPackService.packOrderInLevel', () {
    test('A1 greetings is order 1', () {
      expect(VocabPackService.packOrderInLevel['a1_greetings'], 1);
    });

    test('A1 misc is last (order 13)', () {
      expect(VocabPackService.packOrderInLevel['a1_misc'], 13);
    });

    test('all keys present have matching displayMap entry', () {
      for (final key in VocabPackService.packOrderInLevel.keys) {
        expect(
          VocabPackService.packDisplayMap.containsKey(key),
          true,
          reason: '$key in packOrderInLevel but not in packDisplayMap',
        );
      }
    });
  });
}

Vocab _v(
  String korean, {
  String packId = '',
  int packOrder = 0,
  bool isBoss = false,
  String level = 'A1',
}) => Vocab(
  korean: korean,
  romanization: korean,
  german: korean,
  level: level,
  posDe: '',
  exampleKorean: '',
  exampleGerman: '',
  topic: '',
  packId: packId,
  packOrder: packOrder,
  isReviewBoss: isBoss,
);
