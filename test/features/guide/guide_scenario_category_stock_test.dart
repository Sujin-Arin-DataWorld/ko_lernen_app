import 'package:flutter_test/flutter_test.dart';
import 'package:ko_lernen_app/data/chaekgado_shelf.dart';
import 'package:ko_lernen_app/features/guide/guide_scenario_category_stock.dart';
import 'package:ko_lernen_app/models/scenario.dart';
import 'package:ko_lernen_app/services/scenario_loader.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  tearDown(ScenarioLoader.reset);

  test('browse-level resolution mirrors the non-progress library filter', () {
    expect(
      resolveGuideScenarioBrowseLevel(
        browseLevelCode: ' B2 ',
        userLevelCode: 'a1',
      ),
      LearnerLevel.b2,
    );
    expect(
      resolveGuideScenarioBrowseLevel(
        browseLevelCode: null,
        userLevelCode: 'c1',
      ),
      LearnerLevel.c1,
    );
    expect(
      resolveGuideScenarioBrowseLevel(
        browseLevelCode: 'not-a-level',
        userLevelCode: null,
      ),
      LearnerLevel.a1,
    );
  });

  test('projects exact stocked shelves in canonical slot order', () {
    final stock = GuideScenarioCategoryStockLoader.project(
      level: LearnerLevel.a1,
      corpus: [
        _scenario(id: 'eat', level: LearnerLevel.a1, shelf: 'a1_eat'),
        _scenario(id: 'transit-1', level: LearnerLevel.a1, shelf: 'a1_transit'),
        _scenario(id: 'unknown', level: LearnerLevel.a1, shelf: 'a1_guessed'),
        _scenario(
          id: 'wrong-level',
          level: LearnerLevel.a2,
          shelf: 'a1_transit',
        ),
        _scenario(id: 'transit-2', level: LearnerLevel.a1, shelf: 'a1_transit'),
      ],
    );

    expect(stock.map((category) => category.destination.shelfId), [
      'a1_transit',
      'a1_eat',
    ]);
    expect(stock.map((category) => category.scenarioCount), [2, 1]);
    expect(stock.first.destination.level, LearnerLevel.a1);
    expect(stock.first.imageKey, 'A1Transit');
  });

  test('loads only the requested level before projecting stock', () async {
    final requested = <LearnerLevel>[];
    final stock = await GuideScenarioCategoryStockLoader.loadLevel(
      LearnerLevel.b1,
      loadScenarios: (level) async {
        requested.add(level);
        return [_scenario(id: 'team', level: level, shelf: 'b1_team')];
      },
    );

    expect(requested, [LearnerLevel.b1]);
    expect(stock, hasLength(1));
    expect(stock.single.destination.shelfId, 'b1_team');
    expect(stock.single.scenarioCount, 1);
  });

  test(
    'bundled counts match current ScenarioLoader shards and slots',
    () async {
      for (final level in LearnerLevel.values) {
        final corpus = await ScenarioLoader.loadLevel(level);
        final stock = GuideScenarioCategoryStockLoader.project(
          level: level,
          corpus: corpus,
        );
        final expected = <String, int>{};
        for (final slot in kChaekgadoSlots[level]!) {
          final shelfId = chaekgadoShelfId(level, slot.slug);
          final count = corpus
              .where(
                (scenario) =>
                    scenario.level == level && scenario.shelf == shelfId,
              )
              .length;
          if (count > 0) {
            expected[shelfId] = count;
          }
        }

        expect(
          {
            for (final category in stock)
              category.destination.shelfId: category.scenarioCount,
          },
          expected,
          reason: level.code,
        );
        expect(
          stock.fold<int>(
            0,
            (total, category) => total + category.scenarioCount,
          ),
          expected.values.fold<int>(0, (total, count) => total + count),
          reason: level.code,
        );
      }
    },
  );

  test(
    'loader failures and zero stock never produce category counts',
    () async {
      await expectLater(
        GuideScenarioCategoryStockLoader.loadLevel(
          LearnerLevel.a1,
          loadScenarios: (_) async => throw StateError('shard failed'),
        ),
        throwsStateError,
      );
      expect(
        await GuideScenarioCategoryStockLoader.loadLevel(
          LearnerLevel.a1,
          loadScenarios: (_) async => const [],
        ),
        isEmpty,
      );
    },
  );
}

Scenario _scenario({
  required String id,
  required LearnerLevel level,
  required String shelf,
}) => Scenario(
  id: id,
  level: level,
  emoji: '📖',
  register: Register.polite,
  title: LocalizedText(ko: id, de: id, en: id),
  intro: const LocalizedText(ko: '', de: '', en: ''),
  vocab: const [],
  grammarIds: const [],
  dialog: const [],
  quests: const [],
  shelf: shelf,
);
