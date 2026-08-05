import 'package:flutter_test/flutter_test.dart';
import 'package:ko_lernen_app/models/personal_hanok.dart';
import 'package:ko_lernen_app/services/hanok_stage_service.dart';

/// P2-b: [PersonalHanokProjection.studyFraction] is the *continuous* overall
/// study ratio that drives Home's Hanok growth bar. Unlike the discrete
/// [constructionFraction] (which only steps as milestones unlock), it must move
/// as soon as any single pack clears — that is the whole point of the feature.
double _fraction(double a1, double a2, double b1, double b2) =>
    PersonalHanokProjection.from(
      LevelRatios(a1: a1, a2: a2, b1: b1, b2: b2),
    ).studyFraction;

void main() {
  test('zero study → 0, full study → 1', () {
    expect(_fraction(0, 0, 0, 0), 0);
    expect(_fraction(1, 1, 1, 1), 1);
  });

  test('is the mean of the four level ratios', () {
    expect(_fraction(0.5, 0, 0, 0), closeTo(0.125, 1e-9));
    expect(_fraction(1, 0, 0, 0), closeTo(0.25, 1e-9));
    expect(_fraction(1, 1, 0, 0), closeTo(0.5, 1e-9));
    expect(_fraction(1, 1, 1, 0), closeTo(0.75, 1e-9));
  });

  test('advances within a single level before any milestone unlocks', () {
    // A1 partly done: no construction milestone has unlocked yet (that needs
    // A1 & A2 both complete, then B1 >= .25), so constructionFraction is flat…
    final low = PersonalHanokProjection.from(
      const LevelRatios(a1: 0.2, a2: 0, b1: 0, b2: 0),
    );
    final high = PersonalHanokProjection.from(
      const LevelRatios(a1: 0.6, a2: 0, b1: 0, b2: 0),
    );
    expect(low.constructionFraction, 0);
    expect(high.constructionFraction, 0);
    // …yet studyFraction strictly grows with the extra cleared packs.
    expect(high.studyFraction, greaterThan(low.studyFraction));
    expect(low.studyFraction, closeTo(0.05, 1e-9));
    expect(high.studyFraction, closeTo(0.15, 1e-9));
  });

  test('is monotonic as each level fills', () {
    final seq = <double>[
      _fraction(0, 0, 0, 0),
      _fraction(0.5, 0, 0, 0),
      _fraction(1, 0, 0, 0),
      _fraction(1, 0.5, 0, 0),
      _fraction(1, 1, 0, 0),
      _fraction(1, 1, 0.5, 0),
      _fraction(1, 1, 1, 0),
      _fraction(1, 1, 1, 0.5),
      _fraction(1, 1, 1, 1),
    ];
    for (var i = 1; i < seq.length; i++) {
      expect(seq[i], greaterThan(seq[i - 1]), reason: 'step $i must increase');
    }
  });

  test('clamps out-of-range ratios into 0..1', () {
    expect(_fraction(2, 2, 2, 2), 1);
    expect(_fraction(-1, -1, -1, -1), 0);
    expect(_fraction(2, 0, 0, 0), closeTo(0.25, 1e-9)); // a1 clamps to 1
  });
}
