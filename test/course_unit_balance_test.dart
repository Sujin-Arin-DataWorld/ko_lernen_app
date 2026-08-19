import 'package:flutter_test/flutter_test.dart';
import 'package:ko_lernen_app/models/curriculum.dart';
import 'package:ko_lernen_app/services/curriculum_catalog.dart';
import 'package:ko_lernen_app/services/data_loader.dart';
import 'package:ko_lernen_app/services/scenario_loader.dart';
import 'package:ko_lernen_app/services/smalltalk_loader.dart';

/// 레벨별 콘텐츠가 한 유닛에 몰리지 않는지 지키는 래칫.
///
/// batch 10–16 이 시나리오 130 편을 레벨마다 유닛 하나
/// (`a1_16_survival_capstone`·`a2_07_travel_repair`·
/// `b1_05_complaint_resolution`·`b2_04_complaint_resolution`)에 통째로 넣어
/// A1 은 한 유닛이 레벨 시나리오의 54%, A2 는 63%, B1 58%, B2 60% 를 쥐고
/// 나머지 주제 유닛은 1–5 편만 남았다 (2026-08-19 Jin: "레벨별로 몇 개
/// 배치가 하나도 안 돼 있다").  `shelf` 기준 재배정 후 최대 점유율은 30% 다.
///
/// 새 배치를 넣을 때 `courseUnitId` 를 다시 한 유닛에 몰아 넣으면 여기서
/// 걸린다. 고치는 도구는 `tools/content_factory/rebalance_scenario_units.py`.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    DataLoader.reset();
    ScenarioLoader.reset();
    SmalltalkLoader.reset();
    CurriculumCatalog.reset();
  });

  test('한 코스 유닛이 자기 레벨 시나리오의 40% 를 넘지 않는다', () async {
    final catalog = await CurriculumCatalog.load();
    final levelOf = {
      for (final unit in catalog.courseUnits) unit.id: unit.level,
    };

    // 링크가 아니라 **서로 다른 시나리오 수**를 센다. 퀘스트 개념 팬아웃이
    // 시나리오 한 편에 링크를 여러 개 만들어서, 링크로 세면 배치가 아니라
    // 퀘스트 태깅 밀도를 재게 된다.
    final perLevel = <String, Set<String>>{};
    final perUnit = <String, Set<String>>{};
    for (final link in catalog.contentLinks) {
      if (link.contentKind != CurriculumContentKind.scenario) {
        continue;
      }
      final level = levelOf[link.courseUnitId];
      if (level == null) {
        continue;
      }
      perLevel.putIfAbsent(level, () => <String>{}).add(link.contentId);
      perUnit
          .putIfAbsent(link.courseUnitId, () => <String>{})
          .add(link.contentId);
    }

    final hoarders = <String>[];
    for (final entry in perUnit.entries) {
      final total = perLevel[levelOf[entry.key]]?.length ?? 0;
      if (total == 0) {
        continue;
      }
      final share = entry.value.length / total;
      if (share > 0.40) {
        hoarders.add(
          '${entry.key} ${entry.value.length}/$total '
          '(${(share * 100).round()}%)',
        );
      }
    }

    expect(
      hoarders,
      isEmpty,
      reason:
          '한 유닛이 레벨 시나리오를 독점하면 나머지 유닛의 코스 미션이 비고, '
          '학습자는 레벨을 올려도 같은 유닛만 반복하게 된다. '
          'tools/content_factory/rebalance_scenario_units.py 로 재배정할 것.',
    );
  });

  test('모든 코스 유닛이 시나리오를 최소 1편 갖는다', () async {
    final catalog = await CurriculumCatalog.load();
    final withScenario = catalog.contentLinks
        .where((link) => link.contentKind == CurriculumContentKind.scenario)
        .map((link) => link.courseUnitId)
        .toSet();

    final empty = catalog.courseUnits
        .map((unit) => unit.id)
        .where((id) => !withScenario.contains(id))
        .toList(growable: false);

    expect(empty, isEmpty, reason: '시나리오 0 편인 유닛은 듣기·역할극 미션을 만들 수 없다');
  });
}
