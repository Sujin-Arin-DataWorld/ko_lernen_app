import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:ko_lernen_app/models/cultural_glossary.dart';
import 'package:ko_lernen_app/models/scenario_culture_link.dart';
import 'package:ko_lernen_app/services/cultural_glossary_repository.dart';
import 'package:ko_lernen_app/services/scenario_culture_link_repository.dart';
import 'package:ko_lernen_app/services/scenario_loader.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'production culture-link catalog parses and references live catalogs',
    () async {
      final raw = await File(
        ScenarioCultureLinkRepository.assetPath,
      ).readAsString();
      final catalog = ScenarioCultureLinkCatalog.fromJsonString(raw);

      final glossaryRaw = await File(
        CulturalGlossaryRepository.assetPath,
      ).readAsString();
      final glossary = CulturalGlossary.fromJsonString(glossaryRaw);

      ScenarioLoader.reset();
      final scenarios = await ScenarioLoader.load();
      expect(ScenarioLoader.fullCorpusError, isNull);

      catalog.validateReferences(
        scenarioIds: scenarios.map((scenario) => scenario.id).toSet(),
        termIds: glossary.entries.map((entry) => entry.termId).toSet(),
      );
      expect(catalog.schemaVersion, 1);
    },
  );

  test('catalog supports multiple terms for one scenario', () {
    const raw = '''
      {
        "schemaVersion": 1,
        "links": [
          {
            "scenarioId": "scene_1",
            "termIds": ["norigae", "maedeup"]
          }
        ]
      }
    ''';

    final catalog = ScenarioCultureLinkCatalog.fromJsonString(raw);
    expect(catalog.termIdsForScenario('scene_1'), ['norigae', 'maedeup']);
    expect(catalog.scenarioIdsForTerm('maedeup'), ['scene_1']);
    expect(catalog.termIdsForScenario('missing'), isEmpty);
  });

  test('parser rejects duplicate scenario entries and duplicate term IDs', () {
    const duplicateScenario = '''
      {
        "schemaVersion": 1,
        "links": [
          {"scenarioId": "scene_1", "termIds": ["a"]},
          {"scenarioId": "scene_1", "termIds": ["b"]}
        ]
      }
    ''';
    const duplicateTerms = '''
      {
        "schemaVersion": 1,
        "links": [
          {"scenarioId": "scene_1", "termIds": ["a", "a"]}
        ]
      }
    ''';

    expect(
      () => ScenarioCultureLinkCatalog.fromJsonString(duplicateScenario),
      throwsA(isA<FormatException>()),
    );
    expect(
      () => ScenarioCultureLinkCatalog.fromJsonString(duplicateTerms),
      throwsA(isA<FormatException>()),
    );
  });

  test('reference validator rejects unknown scenarios and terms', () {
    const raw = '''
      {
        "schemaVersion": 1,
        "links": [
          {"scenarioId": "scene_1", "termIds": ["term_1"]}
        ]
      }
    ''';
    final catalog = ScenarioCultureLinkCatalog.fromJsonString(raw);

    expect(
      () => catalog.validateReferences(
        scenarioIds: const {'other_scene'},
        termIds: const {'term_1'},
      ),
      throwsA(isA<FormatException>()),
    );
    expect(
      () => catalog.validateReferences(
        scenarioIds: const {'scene_1'},
        termIds: const {'other_term'},
      ),
      throwsA(isA<FormatException>()),
    );
  });

  test('repository caches optional load result', () async {
    addTearDown(ScenarioCultureLinkRepository.resetForTesting);
    final catalog = ScenarioCultureLinkCatalog(
      schemaVersion: 1,
      links: const [],
    );
    var calls = 0;
    ScenarioCultureLinkRepository.setLoaderForTesting(() async {
      calls++;
      return catalog;
    });

    expect(await ScenarioCultureLinkRepository.load(), same(catalog));
    expect(await ScenarioCultureLinkRepository.load(), same(catalog));
    expect(calls, 1);
  });
}
