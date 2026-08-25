import 'dart:convert';
import 'dart:io';
// Phase 2 (stately-rising-jongga) — DancheongStamp motif mapping tests.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ko_lernen_app/l10n/generated/app_localizations.dart';
import 'package:ko_lernen_app/widgets/sori/dancheong_stamp.dart';

void main() {
  test('도장 카탈로그는 기존 19종과 생활문화 6종을 고유 spec으로 제공한다', () {
    final specs = DancheongMotif.values.map((motif) => motif.spec).toList();

    expect(
      specs.where((spec) => spec.series == StampSeries.dancheong),
      hasLength(19),
    );
    expect(
      specs.where((spec) => spec.series == StampSeries.livingCulture),
      hasLength(6),
    );
    expect(specs.map((spec) => spec.slug).toSet(), hasLength(specs.length));
    expect(
      specs.map((spec) => spec.assetPath).toSet(),
      hasLength(specs.length),
    );
  });

  test('도장 안내 문구의 개수가 실제 카탈로그와 일치한다', () async {
    final en = await AppL10n.delegate.load(const Locale('en'));
    final de = await AppL10n.delegate.load(const Locale('de'));

    expect(en.coachDojangBody, contains('${DancheongMotif.values.length}'));
    expect(de.coachDojangBody, contains('${DancheongMotif.values.length}'));
  });

  group('motifForPackId', () {
    test('greetings/intro → lotus, family → bok', () {
      expect(motifForPackId('a1_greetings_1'), DancheongMotif.lotus);
      expect(motifForPackId('a1_greetings_2'), DancheongMotif.lotus);
      expect(motifForPackId('a1_self_intro'), DancheongMotif.lotus);
      expect(motifForPackId('a1_family'), DancheongMotif.bok);
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

    test('work → bamboo, education → munbangsau', () {
      expect(motifForPackId('a2_work'), DancheongMotif.bamboo);
      expect(motifForPackId('a2_education'), DancheongMotif.munbangsau);
      expect(motifForPackId('b1_work'), DancheongMotif.bamboo);
      expect(motifForPackId('b2_work'), DancheongMotif.bamboo);
      expect(motifForPackId('b2_education'), DancheongMotif.munbangsau);
    });

    test('weather → cloud (2026-08-25: 건강은 suryeon 으로 분리)', () {
      expect(motifForPackId('a2_weather'), DancheongMotif.cloud);
      expect(motifForPackId('a1_weather_layer'), DancheongMotif.cloud);
    });

    test('food → soban, shopping → octagon', () {
      expect(motifForPackId('a1_food'), DancheongMotif.soban);
      expect(motifForPackId('a2_food'), DancheongMotif.soban);
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

    // ── 2026-08-25 신설 4종 ──
    // 새 문양은 "PNG 만 넣고 배선은 안 한" 상태로 조용히 죽기 쉽다.
    // 각 문양마다 실제로 도달하는 팩이 있는지 여기서 못 박는다.
    test('집·주거 안전 → wadang, 계약·분쟁 → changsal', () {
      expect(motifForPackId('a2_home'), DancheongMotif.wadang);
      expect(motifForPackId('a2_household'), DancheongMotif.wadang);
      expect(motifForPackId('b1_housing_contract'), DancheongMotif.changsal);
      expect(motifForPackId('b2_housing_dispute'), DancheongMotif.changsal);
      expect(motifForPackId('a2_housing_search_2026'), DancheongMotif.changsal);
    });

    test('몸·건강·돌봄 → crane', () {
      expect(motifForPackId('a2_health_misc'), DancheongMotif.crane);
      expect(motifForPackId('b1_health_education'), DancheongMotif.crane);
      expect(motifForPackId('b1_health_hospital'), DancheongMotif.crane);
      expect(motifForPackId('a1_pharmacy_ask'), DancheongMotif.crane);
    });

    test('제도·행정·공공 절차 → noemun', () {
      expect(motifForPackId('b1_public_office'), DancheongMotif.noemun);
      expect(motifForPackId('a1_post_office'), DancheongMotif.noemun);
      expect(motifForPackId('a1_city_services_2026'), DancheongMotif.noemun);
      expect(motifForPackId('b2_civic_meeting'), DancheongMotif.noemun);
      expect(motifForPackId('c2_institutional_voice'), DancheongMotif.noemun);
    });

    test('명절·축하 → bok, 의례 → mugunghwa', () {
      expect(motifForPackId('a1_partner_seollal_basic'), DancheongMotif.bok);
      expect(motifForPackId('a2_partner_chuseok_day'), DancheongMotif.bok);
      expect(
        motifForPackId('b2_partner_ancestral_rite'),
        DancheongMotif.mugunghwa,
      );
      expect(motifForPackId('b2_events_culture'), DancheongMotif.bok);
    });

    test('축하 행사는 bok, 관계·예의 → moran', () {
      expect(motifForPackId('b1_social_events'), DancheongMotif.bok);
      expect(motifForPackId('b2_manners_society'), DancheongMotif.moran);
      expect(motifForPackId('b2_honorifics'), DancheongMotif.moran);
      expect(motifForPackId('b2_partner_marriage_talk'), DancheongMotif.moran);
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

    test('모든 문양이 실제로 도달 가능하다 — 죽은 문양이 없다', () {
      final manifest =
          jsonDecode(
                File('assets/data/curriculum_manifest.json').readAsStringSync(),
              )
              as Map<String, dynamic>;
      final packs = manifest['vocabPackUnitMap'] as Map<String, dynamic>;
      final reached = packs.keys.map(motifForPackId).toSet();
      expect(
        DancheongMotif.values.toSet().difference(reached),
        isEmpty,
        reason:
            '이 문양은 어떤 팩에서도 나오지 않아 도장첩에서 영원히 잠깁니다. '
            'motifForPackId 에 주제를 배정하세요',
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
