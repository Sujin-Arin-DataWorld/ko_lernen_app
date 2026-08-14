import 'dart:convert';
import 'dart:io';
// Phase 2 (stately-rising-jongga) — DancheongStamp motif mapping tests.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ko_lernen_app/widgets/sori/dancheong_stamp.dart';

void main() {
  group('motifForPackId', () {
    test('greetings/family/intro → lotus', () {
      expect(motifForPackId('a1_greetings_1'), DancheongMotif.lotus);
      expect(motifForPackId('a1_greetings_2'), DancheongMotif.lotus);
      expect(motifForPackId('a1_self_intro'), DancheongMotif.lotus);
      expect(motifForPackId('a1_family'), DancheongMotif.lotus);
    });

    test('time/numbers → chrysanthemum', () {
      expect(motifForPackId('a1_time'), DancheongMotif.chrysanthemum);
      expect(motifForPackId('a1_numbers_1'), DancheongMotif.chrysanthemum);
      expect(motifForPackId('a1_numbers_3'), DancheongMotif.chrysanthemum);
    });

    test('feelings/descriptions → plum', () {
      expect(motifForPackId('a1_descriptions'), DancheongMotif.plum);
      expect(motifForPackId('a2_descriptions'), DancheongMotif.plum);
      expect(motifForPackId('a2_feelings'), DancheongMotif.plum);
      expect(motifForPackId('b1_emotions_relations'), DancheongMotif.plum);
    });

    test('work/education → bamboo', () {
      expect(motifForPackId('a2_work'), DancheongMotif.bamboo);
      expect(motifForPackId('a2_education'), DancheongMotif.bamboo);
      expect(motifForPackId('b1_work'), DancheongMotif.bamboo);
      expect(motifForPackId('b2_work'), DancheongMotif.bamboo);
      expect(motifForPackId('b2_education'), DancheongMotif.bamboo);
    });

    test('weather/health/misc → cloud', () {
      expect(motifForPackId('a2_weather'), DancheongMotif.cloud);
      expect(motifForPackId('a2_health_misc'), DancheongMotif.cloud);
      expect(motifForPackId('b1_health_education'), DancheongMotif.cloud);
    });

    test('food/shopping → octagon', () {
      expect(motifForPackId('a1_food'), DancheongMotif.octagon);
      expect(motifForPackId('a2_food'), DancheongMotif.octagon);
      expect(motifForPackId('a2_shopping'), DancheongMotif.octagon);
    });

    test('transport → mountain', () {
      expect(motifForPackId('a1_transport'), DancheongMotif.mountain);
      expect(motifForPackId('a2_transport'), DancheongMotif.mountain);
    });

    test('body/colors/position → manja (2026-08-04 swastika 에서 개명)', () {
      expect(motifForPackId('a1_body'), DancheongMotif.manja);
      expect(motifForPackId('a1_colors'), DancheongMotif.manja);
      expect(motifForPackId('a1_position'), DancheongMotif.manja);
    });

    test('unknown pack → fallback lotus', () {
      expect(motifForPackId('xx_unknown_99'), DancheongMotif.lotus);
    });
  });

  group('DancheongStamp widget', () {
    testWidgets('renders without animate', (tester) async {
      await tester.pumpWidget(
        const _Harness(
          child: DancheongStamp(motif: DancheongMotif.lotus, size: 48),
        ),
      );
      expect(find.byType(DancheongStamp), findsOneWidget);
    });

    testWidgets('animates without exception', (tester) async {
      await tester.pumpWidget(
        const _Harness(
          child: DancheongStamp(
            motif: DancheongMotif.chrysanthemum,
            size: 96,
            animate: true,
            stamped: true,
          ),
        ),
      );
      // pump through the 700ms animation
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.byType(DancheongStamp), findsOneWidget);
    });
  });

  group('팩 → 문양 매핑 무결성 가드 (2026-08-04)', () {
    /// `motifForPackId` 의 switch 에 **명시된** base 주제들.
    /// 함수를 호출해선 fallback(`_ => lotus`)으로 샌 것인지 알 수 없어서
    /// 소스를 읽는다 — 이 앱의 다른 guard 테스트와 같은 방식.
    Set<String> mappedBases() {
      final src = File(
        'lib/widgets/sori/dancheong_stamp.dart',
      ).readAsStringSync();
      final start = src.indexOf('DancheongMotif motifForPackId');
      expect(start, greaterThanOrEqualTo(0), reason: 'motifForPackId 를 찾지 못함');
      final end = src.indexOf('\n}', start);
      expect(end, greaterThan(start));
      return RegExp(
        r"'([a-z0-9_]+)'",
      ).allMatches(src.substring(start, end)).map((m) => m.group(1)!).toSet();
    }

    String baseOf(String packId) {
      final parts = packId.split('_');
      return int.tryParse(parts.last) != null
          ? parts.sublist(0, parts.length - 1).join('_')
          : packId;
    }

    test('모든 팩 주제가 switch 에 명시돼 있다 — fallback 으로 새지 않는다', () {
      final manifest =
          jsonDecode(
                File('assets/data/curriculum_manifest.json').readAsStringSync(),
              )
              as Map<String, dynamic>;
      final packs = manifest['vocabPackUnitMap'] as Map<String, dynamic>;
      expect(packs, isNotEmpty);

      final missing = packs.keys.map(baseOf).toSet().difference(mappedBases());
      expect(
        missing,
        isEmpty,
        reason:
            '이 주제들은 `_ => lotus` 로 떨어져 도장이 전부 연꽃이 됩니다. '
            'motifForPackId 의 switch 에 추가하세요',
      );
    });

    test('모든 DancheongMotif 에 도장 PNG 가 실재한다', () {
      for (final m in DancheongMotif.values) {
        expect(
          File('assets/illustrations/stamps/stamp_${m.name}.png').existsSync(),
          isTrue,
          reason:
              'assets/illustrations/stamps/stamp_${m.name}.png 없음 — '
              '문양만 추가하고 그림을 빠뜨렸습니다',
        );
      }
    });
  });
}

class _Harness extends StatelessWidget {
  final Widget child;
  const _Harness({required this.child});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(body: Center(child: child)),
    );
  }
}
