import 'package:flutter_test/flutter_test.dart';
import 'package:ko_lernen_app/data/cloze_topic_groups.dart';
import 'package:ko_lernen_app/services/cloze_loader.dart';
import 'package:ko_lernen_app/widgets/sori/cloze_prompt.dart';

void main() {
  group('splitEmphasis', () {
    test('exact substring is emphasized (Zebrastreifen)', () {
      final segs = splitEmphasis(
        'Bitte am Zebrastreifen überqueren.',
        'Zebrastreifen',
      );
      expect(segs.length, 3);
      expect(segs[0], const TextSegment('Bitte am ', false));
      expect(segs[1], const TextSegment('Zebrastreifen', true));
      expect(segs[2], const TextSegment(' überqueren.', false));
    });

    test('match is case-insensitive but preserves original casing', () {
      final segs = splitEmphasis('Ich mag Lila.', 'lila');
      final emph = segs.firstWhere((s) => s.emph);
      expect(emph.text, 'Lila'); // original casing from the sentence
    });

    test('picks a matching alternative from a slash gloss', () {
      final segs = splitEmphasis('Ich mag Lila.', 'lila / violett');
      expect(segs.any((s) => s.emph && s.text == 'Lila'), isTrue);
    });

    test('strips parenthetical from candidates', () {
      final segs = splitEmphasis(
        'Guten Tag, willkommen!',
        'Guten Tag / Hallo (formell)',
      );
      expect(segs.any((s) => s.emph && s.text == 'Guten Tag'), isTrue);
    });

    test('no match → single non-emphasized segment (sentence intact)', () {
      final segs = splitEmphasis('Wir treffen uns dort.', 'Kreuzung');
      expect(segs, [const TextSegment('Wir treffen uns dort.', false)]);
    });

    test('null gloss → single non-emphasized segment', () {
      final segs = splitEmphasis('Ein Satz.', null);
      expect(segs, [const TextSegment('Ein Satz.', false)]);
    });

    test('empty gloss → single non-emphasized segment', () {
      final segs = splitEmphasis('Ein Satz.', '   ');
      expect(segs, [const TextSegment('Ein Satz.', false)]);
    });

    test('empty sentence → empty list', () {
      expect(splitEmphasis('', 'Nein'), isEmpty);
    });

    test('match at start → no empty leading segment', () {
      final segs = splitEmphasis('Nein, das ist falsch.', 'Nein');
      expect(segs.first, const TextSegment('Nein', true));
      expect(segs.every((s) => s.text.isNotEmpty), isTrue);
    });
  });

  group('cloze filter composition', () {
    final items = [
      _filterItem(id: 'a1-home', level: 'a1', topic: 'Alltag'),
      _filterItem(id: 'a1-people', level: 'a1', topic: 'Familie'),
      _filterItem(id: 'a2-home', level: 'a2', topic: 'Wohnen'),
      _filterItem(id: 'a2-tech', level: 'a2', topic: 'Technologie'),
      _filterItem(id: 'a2-tech-2', level: 'a2', topic: 'Wissenschaft'),
    ];

    test('All keeps the old input sequence without exposing it to shuffle', () {
      final filtered = ClozeTopicGroups.filterItems(items);

      expect(filtered.map((item) => item.id), items.map((item) => item.id));
      expect(identical(filtered, items), isFalse);
      filtered.shuffle();
      expect(items.map((item) => item.id), [
        'a1-home',
        'a1-people',
        'a2-home',
        'a2-tech',
        'a2-tech-2',
      ]);
    });

    test('level is applied before exact group membership', () {
      final filtered = ClozeTopicGroups.filterItems(
        items,
        level: 'a2',
        group: ClozeTopicGroupId.technologyScience,
      );

      expect(filtered.map((item) => item.id), ['a2-tech', 'a2-tech-2']);
    });

    test('group counts recompute from the selected level pool', () {
      final a1 = ClozeTopicGroups.countsForLevel(items, level: 'a1');
      final a2 = ClozeTopicGroups.countsForLevel(items, level: 'a2');

      expect(a1[ClozeTopicGroupId.everydayHome], 1);
      expect(a1[ClozeTopicGroupId.peopleRelationships], 1);
      expect(a1[ClozeTopicGroupId.technologyScience], 0);
      expect(a2[ClozeTopicGroupId.everydayHome], 1);
      expect(a2[ClozeTopicGroupId.peopleRelationships], 0);
      expect(a2[ClozeTopicGroupId.technologyScience], 2);
    });
  });
}

ClozeItem _filterItem({
  required String id,
  required String level,
  required String topic,
}) => ClozeItem(
  id: id,
  level: level,
  sentenceKo: '$id ＿＿＿',
  answer: '정답',
  fullKo: '$id 정답',
  de: id,
  en: id,
  distractors: const ['오답1', '오답2', '오답3'],
  topic: topic,
);
