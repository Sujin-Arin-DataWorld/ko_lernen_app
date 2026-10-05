import 'dart:convert';
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

  test('live arc catalog contains three derived culture paths', () {
    final raw = File(CultureStoryArcRepository.assetPath).readAsStringSync();
    final catalog = CultureStoryArcCatalog.fromJsonString(raw);

    expect(catalog.arcs, hasLength(3));
    final byId = {for (final arc in catalog.arcs) arc.arcId: arc};

    expect(byId.keys, {
      'found_around_nammun',
      'made_by_hand_in_korea',
      'memory_to_record',
    });
    expect(byId['found_around_nammun']!.steps, hasLength(4));
    expect(byId['made_by_hand_in_korea']!.steps, hasLength(2));
    expect(byId['memory_to_record']!.steps, hasLength(3));
    expect(
      byId['made_by_hand_in_korea']!.steps.map((step) => step.scenarioId),
      contains('b2_daniel_hyuna_hanji_filming_scope'),
    );
    expect(
      byId['memory_to_record']!.steps.map((step) => step.scenarioId),
      contains('c1_maya_hyuna_daniel_talchum_shortform'),
    );
  });

  test('every live arc step is backed by the live culture-link registry', () {
    final rawArcs = jsonDecode(
      File(CultureStoryArcRepository.assetPath).readAsStringSync(),
    ) as Map<String, dynamic>;
    final rawLinks = jsonDecode(
      File('assets/data/scenario_culture_links.json').readAsStringSync(),
    ) as Map<String, dynamic>;
    final termsByScenario = <String, Set<String>>{
      for (final rawLink in rawLinks['links'] as List<dynamic>)
        (rawLink as Map<String, dynamic>)['scenarioId'] as String:
            ((rawLink['termIds'] as List<dynamic>).cast<String>()).toSet(),
    };

    for (final rawArc in rawArcs['arcs'] as List<dynamic>) {
      final arc = rawArc as Map<String, dynamic>;
      for (final rawStep in arc['steps'] as List<dynamic>) {
        final step = rawStep as Map<String, dynamic>;
        final scenarioId = step['scenarioId'] as String;
        final linkedTerms = termsByScenario[scenarioId];
        final reason = '${arc['arcId']}/$scenarioId';
        expect(linkedTerms, isNotNull, reason: reason);
        expect(
          linkedTerms!.containsAll(
            (step['termIds'] as List<dynamic>).cast<String>(),
          ),
          isTrue,
          reason: reason,
        );
      }
    }
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
