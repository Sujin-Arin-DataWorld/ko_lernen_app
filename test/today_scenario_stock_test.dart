import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ko_lernen_app/features/scenarios/scenario_quest_stock.dart';
import 'package:ko_lernen_app/models/scenario.dart';
import 'package:ko_lernen_app/services/scenario_loader.dart';
import 'package:ko_lernen_app/services/storage_service.dart';
import 'package:ko_lernen_app/services/today_learning_snapshot.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  for (final level in LearnerLevel.values) {
    test(
      'Today skips sparse ${level.code} lessons without writing progress',
      () async {
        ScenarioLoader.reset();
        final corpus = await ScenarioLoader.load();
        expect(ScenarioLoader.fullCorpusError, isNull);
        final stock = ScenarioQuestStock.fromCorpus(corpus);
        final levelLessons = corpus.where((s) => s.level == level).toList();
        final sparseIndex = levelLessons.indexWhere(
          (s) => !stock.allowsScenario(s),
        );
        expect(sparseIndex, greaterThanOrEqualTo(0));
        final completed = levelLessons
            .take(sparseIndex)
            .map((s) => s.id)
            .toList();
        final next = levelLessons
            .skip(sparseIndex + 1)
            .firstWhere(stock.allowsScenario);
        SharedPreferences.setMockInitialValues({
          'kl_user_level': level.code,
          'kl_completed_scenarios': completed,
        });
        Storage.resetForTesting();
        await Storage.init();
        final before = List<String>.of(Storage.completedScenarios);
        expect(before, containsAll(completed));

        final snapshot = await TodayLearningSnapshotLoader.load(
          networkStatusReader: () async => TodayNetworkStatus.online,
        );

        expect(
          snapshot.unavailableSources,
          isNot(contains(TodayLearningSource.scenario)),
        );
        expect(snapshot.scenario?.id, next.id);
        expect(Storage.completedScenarios, before);
        expect(
          Storage.completedScenarios,
          isNot(contains(levelLessons[sparseIndex].id)),
        );
      },
    );
  }
}
