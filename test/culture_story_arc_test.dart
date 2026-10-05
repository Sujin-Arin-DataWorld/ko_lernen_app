import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:ko_lernen_app/models/culture_story_arc.dart';
import 'package:ko_lernen_app/services/culture_story_arc_repository.dart';

void main() {
  test('parses a derived read-only culture story arc', () {
    final catalog = CultureStoryArcCatalog.fromJsonString(r'''
{
  "schemaVersion": 1,
  "arcs": [
    {
      "arcId": "sample_arc",
      "title": {"ko": "표본", "de": "Beispiel", "en": "Sample"},
      "summary": {"ko": "요약", "de": "Zusammenfassung", "en": "Summary"},
      "progressMode": "derived_read_only",
      "steps": [
        {
          "scenarioId": "scene_a",
          "personaIds": ["maya"],
          "termIds": ["hanok"]
        }
      ]
    }
  ]
}
''');

    expect(catalog.arcs, hasLength(1));
    final arc = catalog.arcs.single;
    expect(arc.arcId, 'sample_arc');
    expect(arc.title.forLanguage('de'), 'Beispiel');
    expect(arc.title.forLanguage('fr'), 'Sample');
    expect(arc.steps.single.scenarioId, 'scene_a');
  });

  test('rejects a culture story arc that owns progress', () {
    expect(
      () => CultureStoryArcCatalog.fromJsonString(r'''
{
  "schemaVersion": 1,
  "arcs": [
    {
      "arcId": "bad_arc",
      "title": {"ko": "표본", "de": "Beispiel", "en": "Sample"},
      "summary": {"ko": "요약", "de": "Zusammenfassung", "en": "Summary"},
      "progressMode": "persistent_mastery",
      "steps": [
        {
          "scenarioId": "scene_a",
          "personaIds": ["maya"],
          "termIds": ["hanok"]
        }
      ]
    }
  ]
}
'''),
      throwsFormatException,
    );
  });

  test('live arc catalog contains promoted Batch 38 arc', () {
    final raw = File(CultureStoryArcRepository.assetPath).readAsStringSync();
    final catalog = CultureStoryArcCatalog.fromJsonString(raw);

    expect(catalog.arcs, hasLength(1));
    final arc = catalog.arcs.single;
    expect(arc.arcId, 'found_around_nammun');
    expect(arc.progressMode, 'derived_read_only');
    expect(arc.steps, hasLength(4));
    expect(
      arc.steps.map((step) => step.scenarioId),
      contains('b1_dongsun_norigae_shop_post'),
    );
    expect(
      arc.steps.map((step) => step.scenarioId),
      contains('a2_jun_hwaseong_school_slide'),
    );
  });

  test('arc model contains no persistence or reward ownership', () {
    final source = File('lib/models/culture_story_arc.dart').readAsStringSync();
    final repository = File(
      'lib/services/culture_story_arc_repository.dart',
    ).readAsStringSync();

    for (final forbidden in [
      'SharedPreferences',
      'setStringList',
      'Yeopjeon',
      'grant',
      'unlock',
    ]) {
      expect(source, isNot(contains(forbidden)));
      expect(repository, isNot(contains(forbidden)));
    }
  });
}
