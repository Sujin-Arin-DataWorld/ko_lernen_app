import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:ko_lernen_app/models/cultural_glossary.dart';
import 'package:ko_lernen_app/models/scenario_culture_link.dart';
import 'package:ko_lernen_app/services/cultural_glossary_repository.dart';
import 'package:ko_lernen_app/services/culture_discovery_service.dart';

void main() {
  late CulturalGlossary glossary;

  setUpAll(() async {
    glossary = CulturalGlossary.fromJsonString(
      await File(CulturalGlossaryRepository.assetPath).readAsString(),
    );
  });

  ScenarioCultureLinkCatalog links() => ScenarioCultureLinkCatalog(
    schemaVersion: 1,
    links: [
      ScenarioCultureLink(
        scenarioId: 'scene_a',
        termIds: const ['hanok', 'gye'],
      ),
      ScenarioCultureLink(
        scenarioId: 'scene_b',
        termIds: const ['gye', 'bojagi'],
      ),
      ScenarioCultureLink(scenarioId: 'scene_c', termIds: const ['hanok']),
    ],
  );

  test('projects unique glossary terms from current completed scenarios', () {
    final snapshot = CultureDiscoveryService.project(
      completedScenarioIds: const {'scene_a', 'scene_b', 'unlinked'},
      links: links(),
      glossary: glossary,
    );

    expect(snapshot.catalogAvailable, isTrue);
    expect(snapshot.availableTermCount, 3);
    expect(snapshot.discoveredCount, 3);
    expect(snapshot.entries.map((entry) => entry.termId).toSet(), {
      'hanok',
      'gye',
      'bojagi',
    });
    expect(snapshot.completionScenarioIds, contains('unlinked'));
  });

  test('does not discover culture from an incomplete linked scenario', () {
    final snapshot = CultureDiscoveryService.project(
      completedScenarioIds: const {'scene_c'},
      links: links(),
      glossary: glossary,
    );

    expect(snapshot.discoveredCount, 1);
    expect(snapshot.entries.single.termId, 'hanok');
    expect(snapshot.availableTermCount, 3);
  });

  test('deduplicates one cultural term discovered in several scenarios', () {
    final snapshot = CultureDiscoveryService.project(
      completedScenarioIds: const {'scene_a', 'scene_b', 'scene_c'},
      links: links(),
      glossary: glossary,
    );

    expect(
      snapshot.entries.where((entry) => entry.termId == 'hanok'),
      hasLength(1),
    );
    expect(
      snapshot.entries.where((entry) => entry.termId == 'gye'),
      hasLength(1),
    );
  });

  test('ignores culture terms missing from the glossary', () {
    final snapshot = CultureDiscoveryService.project(
      completedScenarioIds: const {'scene'},
      links: ScenarioCultureLinkCatalog(
        schemaVersion: 1,
        links: [
          ScenarioCultureLink(
            scenarioId: 'scene',
            termIds: const ['hanok', 'missing_term'],
          ),
        ],
      ),
      glossary: glossary,
    );

    expect(snapshot.availableTermCount, 1);
    expect(snapshot.entries.single.termId, 'hanok');
  });

  test(
    'loader union can represent local and cloud-restored completion evidence',
    () async {
      final service = CultureDiscoveryService(
        completionScenarioIdsLoader: () async => {
          'local_scene',
          'cloud_checkpoint_scene',
        },
        linkCatalogLoader: () async => ScenarioCultureLinkCatalog(
          schemaVersion: 1,
          links: [
            ScenarioCultureLink(
              scenarioId: 'local_scene',
              termIds: const ['hanok'],
            ),
            ScenarioCultureLink(
              scenarioId: 'cloud_checkpoint_scene',
              termIds: const ['bojagi'],
            ),
          ],
        ),
        glossaryLoader: () async => glossary,
      );

      final snapshot = await service.load();

      expect(snapshot.entries.map((entry) => entry.termId).toSet(), {
        'hanok',
        'bojagi',
      });
    },
  );

  test(
    'missing optional catalog fails closed without inventing discovery',
    () async {
      final service = CultureDiscoveryService(
        completionScenarioIdsLoader: () async => {'scene_a'},
        linkCatalogLoader: () async => null,
        glossaryLoader: () async => glossary,
      );

      final snapshot = await service.load();

      expect(snapshot.catalogAvailable, isFalse);
      expect(snapshot.entries, isEmpty);
      expect(snapshot.availableTermCount, 0);
    },
  );

  test('service source adds no culture-specific persistence key', () {
    final source = File(
      'lib/services/culture_discovery_service.dart',
    ).readAsStringSync();

    expect(source, isNot(contains('discoveredCultureIds')));
    expect(source, isNot(contains('setStringList')));
    expect(source, isNot(contains('SharedPreferences')));
    expect(source, isNot(contains('addCompletedScenario')));
    expect(source, isNot(contains('recordScenarioCheckpoint')));
    expect(source, isNot(contains('Yeopjeon')));
    expect(source, contains('Storage.completedScenarios'));
    expect(source, contains('scenarioCheckpoints'));
  });
}
