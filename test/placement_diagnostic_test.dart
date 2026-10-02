import 'package:flutter_test/flutter_test.dart';
import 'package:ko_lernen_app/services/placement_diagnostic.dart';

void main() {
  final questions = placementDiagnosticQuestions;
  test(
    'all six levels have independent evidence and reachable recommendations',
    () {
      expect(questions, hasLength(18));
      const levels = ['a1', 'a2', 'b1', 'b2', 'c1', 'c2'];
      for (var band = 0; band < levels.length; band++) {
        expect(questions.where((q) => q.level == levels[band]), hasLength(3));
        final answers = [
          for (var i = 0; i < questions.length; i++)
            i < (band + 1) * 3 ? questions[i].correctIndex : -1,
        ];
        expect(recommendPlacement(answers), levels[band]);
      }
    },
  );
  test(
    'beginner answers or a fixed answer position cannot imply advanced proficiency',
    () {
      expect(recommendPlacement(List.filled(18, 0)), 'a1');
      expect(recommendPlacement(List.filled(18, -1)), 'a1');
      expect(recommendPlacement([]), 'a1');
      final advancedOnly = [
        for (var i = 0; i < questions.length; i++)
          i >= 12 ? questions[i].correctIndex : -1,
      ];
      expect(recommendPlacement(advancedOnly), 'a1');
    },
  );
  test('choices preserve locale mapping and never duplicate an answer', () {
    for (final q in questions) {
      expect(q.choicesDe, hasLength(4));
      expect(q.choicesEn, hasLength(4));
      expect(q.choicesDe.toSet(), hasLength(4));
      expect(q.choicesEn.toSet(), hasLength(4));
      expect(q.correctIndex, inInclusiveRange(0, 3));
    }
    expect(questions.map((q) => q.correctIndex).toSet(), {0, 1, 2, 3});
  });
  test('longest-option guessing cannot pass advanced bands', () {
    for (final locale in ['de', 'en']) {
      final answers = <int>[];
      for (var i = 0; i < questions.length; i++) {
        final choices = questions[i].choices(locale);
        var longest = 0;
        for (var j = 1; j < choices.length; j++) {
          if (choices[j].length > choices[longest].length) longest = j;
        }
        answers.add(i < 6 ? questions[i].correctIndex : longest);
      }
      expect(['a1', 'a2', 'b1'], contains(recommendPlacement(answers)));
    }
  });
  test('neither length extreme passes a B1-C2 band in either locale', () {
    const levels = ['a1', 'a2', 'b1', 'b2', 'c1', 'c2'];
    for (final locale in ['de', 'en']) {
      for (var band = 2; band < 6; band++) {
        for (final shortest in [true, false]) {
          final answers = <int>[];
          for (var i = 0; i < questions.length; i++) {
            final choices = questions[i].choices(locale);
            var guessed = 0;
            for (var j = 1; j < choices.length; j++) {
              if (shortest
                  ? choices[j].length < choices[guessed].length
                  : choices[j].length > choices[guessed].length) {
                guessed = j;
              }
            }
            answers.add(
              i < band * 3
                  ? questions[i].correctIndex
                  : i < (band + 1) * 3
                  ? guessed
                  : -1,
            );
          }
          expect(
            recommendPlacement(answers),
            levels[band - 1],
            reason: '$locale ${levels[band]} shortest=$shortest',
          );
        }
      }
    }
  });
}
