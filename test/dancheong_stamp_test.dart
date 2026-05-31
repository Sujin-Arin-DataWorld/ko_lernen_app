// Phase 2 (stately-rising-jongga) — DancheongStamp motif mapping tests.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ko_lernen_app/widgets/sori/dancheong_stamp.dart';

void main() {
  group('motifForPackId', () {
    test('greetings/family/intro → lotus', () {
      expect(motifForPackId('a1_greetings_1'), DancheongMotif.lotus);
      expect(motifForPackId('a1_greetings_2'), DancheongMotif.lotus);
      expect(motifForPackId('a1_self_intro'),  DancheongMotif.lotus);
      expect(motifForPackId('a1_family'),      DancheongMotif.lotus);
    });

    test('time/numbers → chrysanthemum', () {
      expect(motifForPackId('a1_time'),        DancheongMotif.chrysanthemum);
      expect(motifForPackId('a1_numbers_1'),   DancheongMotif.chrysanthemum);
      expect(motifForPackId('a1_numbers_3'),   DancheongMotif.chrysanthemum);
    });

    test('feelings/descriptions → plum', () {
      expect(motifForPackId('a1_descriptions'),    DancheongMotif.plum);
      expect(motifForPackId('a2_descriptions'),    DancheongMotif.plum);
      expect(motifForPackId('a2_feelings'),        DancheongMotif.plum);
      expect(motifForPackId('b1_emotions_relations'), DancheongMotif.plum);
    });

    test('work/education → bamboo', () {
      expect(motifForPackId('a2_work'),       DancheongMotif.bamboo);
      expect(motifForPackId('a2_education'),  DancheongMotif.bamboo);
      expect(motifForPackId('b1_work'),       DancheongMotif.bamboo);
      expect(motifForPackId('b2_work'),       DancheongMotif.bamboo);
      expect(motifForPackId('b2_education'),  DancheongMotif.bamboo);
    });

    test('weather/health/misc → cloud', () {
      expect(motifForPackId('a2_weather'),           DancheongMotif.cloud);
      expect(motifForPackId('a2_health_misc'),       DancheongMotif.cloud);
      expect(motifForPackId('b1_health_education'),  DancheongMotif.cloud);
    });

    test('food/shopping → octagon', () {
      expect(motifForPackId('a1_food'),       DancheongMotif.octagon);
      expect(motifForPackId('a2_food'),       DancheongMotif.octagon);
      expect(motifForPackId('a2_shopping'),   DancheongMotif.octagon);
    });

    test('transport → mountain', () {
      expect(motifForPackId('a1_transport'),  DancheongMotif.mountain);
      expect(motifForPackId('a2_transport'),  DancheongMotif.mountain);
    });

    test('body/colors/position → swastika (pinwheel variant)', () {
      expect(motifForPackId('a1_body'),       DancheongMotif.swastika);
      expect(motifForPackId('a1_colors'),     DancheongMotif.swastika);
      expect(motifForPackId('a1_position'),   DancheongMotif.swastika);
    });

    test('unknown pack → fallback lotus', () {
      expect(motifForPackId('xx_unknown_99'), DancheongMotif.lotus);
    });
  });

  group('DancheongStamp widget', () {
    testWidgets('renders without animate', (tester) async {
      await tester.pumpWidget(const _Harness(
        child: DancheongStamp(motif: DancheongMotif.lotus, size: 48),
      ));
      expect(find.byType(DancheongStamp), findsOneWidget);
    });

    testWidgets('animates without exception', (tester) async {
      await tester.pumpWidget(const _Harness(
        child: DancheongStamp(
          motif: DancheongMotif.chrysanthemum,
          size: 96,
          animate: true,
          stamped: true,
        ),
      ));
      // pump through the 700ms animation
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.byType(DancheongStamp), findsOneWidget);
    });
  });
}

class _Harness extends StatelessWidget {
  final Widget child;
  const _Harness({required this.child});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(home: Scaffold(body: Center(child: child)));
  }
}
