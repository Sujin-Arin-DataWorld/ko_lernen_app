import 'package:flutter_test/flutter_test.dart';

import 'package:ko_lernen_app/models/book_page.dart';
import 'package:ko_lernen_app/services/vocab_nuance_service.dart';

ExtractedWord _w(String korean, String meaning) => ExtractedWord.manual(
  korean: korean,
  translationDe: meaning,
);

void main() {
  test('clusters synonym pairs from the learner list', () {
    final clusters = VocabNuanceService.clustersFor(<ExtractedWord>[
      _w('시작', 'Anfang'),
      _w('개시', 'Beginn'),
      _w('사과', 'Apfel'),
    ]);

    expect(clusters, isNotEmpty);
    expect(
      clusters.first.words.map((word) => word.korean),
      containsAll(<String>['시작', '개시']),
    );
  });

  test('asks which synonym is more formal and explains with Hanja', () {
    final questions = VocabNuanceService.questionsFor(<ExtractedWord>[
      _w('시작', 'Anfang'),
      _w('개시', 'Beginn'),
    ]);

    final register = questions.firstWhere(
      (question) => question.kind == VocabNuanceQuestionKind.register,
    );
    expect(register.correctKorean, '개시');
    expect(register.explanationDe, contains('開始'));
    expect(register.explanationDe, contains('始作'));
  });

  test('asks which word carries a Hanja root', () {
    final questions = VocabNuanceService.questionsFor(<ExtractedWord>[
      _w('학교', 'Schule'),
      _w('친구', 'Freund'),
    ]);

    expect(
      questions.any(
        (question) => question.kind == VocabNuanceQuestionKind.hanjaRoot,
      ),
      isTrue,
    );
  });
}
