import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:ko_lernen_app/services/data_loader.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'new A1 Korean-life scenarios have linkable metadata and identified quests',
    () async {
      final scenariosJson =
          jsonDecode(File('assets/data/scenarios.json').readAsStringSync())
              as Map<String, dynamic>;
      final manifestJson =
          jsonDecode(
                File('assets/data/curriculum_manifest.json').readAsStringSync(),
              )
              as Map<String, dynamic>;
      final scenarios = <String, Map<String, dynamic>>{
        for (final raw in scenariosJson['scenarios'] as List)
          (raw as Map<String, dynamic>)['id'] as String: raw,
      };
      final knownUnits = (manifestJson['courseUnits'] as List)
          .cast<Map<String, dynamic>>()
          .map((unit) => unit['id'] as String)
          .toSet();
      final knownConcepts = (manifestJson['concepts'] as List)
          .cast<Map<String, dynamic>>()
          .map((concept) => concept['id'] as String)
          .toSet();
      final conceptKinds = <String, String>{
        for (final concept
            in (manifestJson['concepts'] as List).cast<Map<String, dynamic>>())
          concept['id'] as String: concept['kind'] as String,
      };
      final knownSurfaceForms = (manifestJson['surfaceForms'] as List)
          .cast<Map<String, dynamic>>()
          .map((surface) => surface['id'] as String)
          .toSet();
      final knownGrammarIds = (await DataLoader.loadGrammar())
          .map((grammar) => grammar.id)
          .toSet();

      const expected = <String, String>{
        'first_class_meeting': 'a1_15_first_class_work',
        'phone_messenger_reply': 'a1_07_contact_address',
        'delivery_address_confirmation': 'a1_14_payment_delivery',
        'clarify_repeat': 'a1_08_clarify_repair',
        'titles_relationship_distance': 'a1_11_titles_relationships',
        'clinic_safety': 'a1_10_health_safety',
      };

      for (final entry in expected.entries) {
        final scenario = scenarios[entry.key];
        expect(scenario, isNotNull, reason: '${entry.key} must be present');
        expect(scenario!['level'], 'a1');
        expect(scenario['courseUnitId'], entry.value);
        expect(knownUnits, contains(scenario['courseUnitId']));
        expect(scenario['speechStyle'], isNotEmpty);
        expect(scenario['relationshipContext'], isNotEmpty);
        expect(scenario['intent'], isNotEmpty);

        final grammarIds = (scenario['grammarIds'] as List).cast<String>();
        expect(grammarIds, isNotEmpty);
        expect(grammarIds.every(knownGrammarIds.contains), isTrue);

        final conceptIds = (scenario['conceptIds'] as List).cast<String>();
        expect(conceptIds, isNotEmpty);
        expect(conceptIds.every(knownConcepts.contains), isTrue);

        final surfaceFormIds = (scenario['surfaceFormIds'] as List)
            .cast<String>();
        expect(surfaceFormIds, isNotEmpty);
        expect(surfaceFormIds.every(knownSurfaceForms.contains), isTrue);

        final quests = (scenario['quests'] as List)
            .cast<Map<String, dynamic>>();
        expect(quests.length, greaterThanOrEqualTo(5));
        final questIds = quests.map((quest) => quest['id'] as String).toList();
        expect(questIds.toSet(), hasLength(quests.length));
        expect(questIds.every((id) => id.trim().isNotEmpty), isTrue);
        for (final quest in quests) {
          final questConceptIds = ((quest['conceptIds'] as List?) ?? const [])
              .cast<String>();
          expect(questConceptIds.every(knownConcepts.contains), isTrue);
        }
      }

      final a1Scenarios = scenarios.values.where(
        (scenario) => scenario['level'] == 'a1',
      );
      for (final scenario in a1Scenarios) {
        final scenarioId = scenario['id'] as String;
        final quests = (scenario['quests'] as List)
            .cast<Map<String, dynamic>>();
        final correctionQuests = quests.where((quest) {
          final concepts = ((quest['conceptIds'] as List?) ?? const [])
              .cast<String>();
          return quest['type'] == 'particlePop' ||
              quest['type'] == 'batchimDrop' ||
              concepts.any((id) => conceptKinds[id] == 'pronunciation') ||
              concepts.any((id) => conceptKinds[id] == 'conjugation');
        }).toList();
        expect(
          correctionQuests,
          isNotEmpty,
          reason:
              '$scenarioId needs a particle, batchim, or conjugation correction quest',
        );
        expect(
          correctionQuests.any(
            (quest) => (quest['id'] as String?)?.trim().isNotEmpty == true,
          ),
          isTrue,
          reason: '$scenarioId needs an identified correction quest',
        );
        expect(
          quests.any(
            (quest) =>
                quest['type'] == 'satzBauen' || quest['type'] == 'diktat',
          ),
          isTrue,
          reason: '$scenarioId needs a direct-output quest',
        );
      }
    },
  );
}
