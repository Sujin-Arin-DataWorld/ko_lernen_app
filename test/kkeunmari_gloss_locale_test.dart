import 'package:flutter_test/flutter_test.dart';
import 'package:ko_lernen_app/services/kkeunmari_engine.dart';

void main() {
  test(
    'reviewed word uses the selected UI language, including locale variants',
    () {
      final word = KkeunmariWord.fromJson({
        'word': '사실',
        'german': 'Tatsache / Wahrheit',
        'english': 'fact; truth',
      });
      expect(word.meaning('en'), 'fact; truth');
      expect(word.meaning('en-US'), 'fact; truth');
      expect(word.meaning('de-DE'), 'Tatsache / Wahrheit');
    },
  );

  test('unreviewed English gloss does not show a German fallback', () {
    final word = KkeunmariWord.fromJson({'word': '사과', 'german': 'Apfel'});
    expect(word.meaning('en'), isEmpty);
    expect(word.meaning('de'), 'Apfel');
    expect(KkeunmariWord.dictionary('사과').meaning('en'), isEmpty);
  });
}
