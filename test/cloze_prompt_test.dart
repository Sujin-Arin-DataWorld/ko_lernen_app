import 'package:flutter_test/flutter_test.dart';
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
}
