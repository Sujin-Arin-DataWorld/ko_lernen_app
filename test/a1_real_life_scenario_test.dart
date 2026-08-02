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

      expect(a1, hasLength(greaterThanOrEqualTo(13)));
      expect(
        byId.keys,
        containsAll(<String>[
          'first_class_meeting',
          'phone_messenger_reply',
          'delivery_address_confirmation',
          'clarify_repeat',
          'titles_relationship_distance',
          'clinic_safety',
        ]),
      );

      for (final scenario in a1) {
        expect(
          scenario.quests.any(
            (quest) =>
                quest.hasExplicitId && quest.conceptIds.isNotEmpty,
          ),
          isTrue,
          reason: '${scenario.id} needs targeted corrective evidence',
        );
        expect(
          scenario.quests.any(
            (quest) =>
                quest.type == QuestType.satzBauen ||
                quest.type == QuestType.diktat,
          ),
          isTrue,
          reason: '${scenario.id} needs a productive output activity',
        );
      }
    },
  );
}
