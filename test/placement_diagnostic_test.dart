import 'package:flutter_test/flutter_test.dart';

import 'package:ko_lernen_app/services/placement_diagnostic.dart';

void main() {
  test('eight-question diagnostic recommends but never forces a level', () {
    expect(recommendPlacement(0), 'a1');
    expect(recommendPlacement(3), 'a1');
    expect(recommendPlacement(4), 'a2');
    expect(recommendPlacement(5), 'a2');
    expect(recommendPlacement(6), 'b1');
    expect(recommendPlacement(7), 'b1');
    expect(recommendPlacement(8), 'b2');
    expect(recommendPlacement(99), 'b2');
  });

  test(
    'diagnostic question set spans meaning, particles, order, and register',
    () {
      expect(placementDiagnosticQuestions, hasLength(8));
      expect(
        placementDiagnosticQuestions.map((question) => question.skill).toSet(),
        containsAll(<PlacementDiagnosticSkill>{
          PlacementDiagnosticSkill.listening,
          PlacementDiagnosticSkill.meaning,
          PlacementDiagnosticSkill.particle,
          PlacementDiagnosticSkill.wordOrder,
          PlacementDiagnosticSkill.speechStyle,
        }),
      );
    },
  );
}
