import 'package:flutter_test/flutter_test.dart';
import 'package:ko_lernen_app/models/scenario.dart';
import 'package:ko_lernen_app/services/scenario_loader.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(ScenarioLoader.reset);

  test(
    'A1 first-90-days scenarios cover real-life contexts with repair and production',
    () async {
      final scenarios = await ScenarioLoader.load();
      final a1 = scenarios
          .where((scenario) => scenario.level == LearnerLevel.a1)
          .toList();
      final byId = {for (final scenario in a1) scenario.id: scenario};

      expect(a1, hasLength(21));
      expect(
        byId.keys,
        containsAll(<String>[
          'first_class_meeting',
          'kakao_contact_after_class',
          'bakery_payment_bag',
          'clarify_repeat',
          'favorite_korean_music',
          'break_glass_apology',
        ]),
      );

      for (final scenario in a1) {
        expect(
          scenario.quests.any(
            (quest) =>
                quest.hasExplicitId &&
                quest.type == QuestType.satzBauen &&
                quest.conceptIds.toSet().containsAll(scenario.conceptIds),
          ),
          isTrue,
          reason: '${scenario.id} needs direct, concept-tagged evidence',
        );
        expect(
          scenario.quests.any((quest) => quest.type == QuestType.satzBauen),
          isTrue,
          reason: '${scenario.id} needs a productive output activity',
        );
      }
    },
  );
}
