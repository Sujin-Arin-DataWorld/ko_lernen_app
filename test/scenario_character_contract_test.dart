import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:ko_lernen_app/models/scenario.dart';
import 'package:ko_lernen_app/models/scenario_character.dart';
import 'package:ko_lernen_app/models/scenario_corpus_generation.dart';

void main() {
  test('runtime generation matches the canonical corpus manifest', () {
    final payload =
        jsonDecode(
              File(
                'tools/content_factory/canonical_scenarios/scenario_corpus_manifest.json',
              ).readAsStringSync(),
            )
            as Map<String, dynamic>;

    expect(payload['generationId'], ScenarioCorpusGeneration.canonical120);
    expect(payload['status'], 'review_only');
  });

  test('runtime character names and voices match the canonical writer bible', () {
    final payload =
        jsonDecode(
              File(
                'tools/content_factory/canonical_scenarios/character_profiles.json',
              ).readAsStringSync(),
            )
            as Map<String, dynamic>;
    final expected = <String, (String, String)>{};
    for (final raw in payload['recurringCharacters'] as List<dynamic>) {
      final item = raw as Map<String, dynamic>;
      final names = item['displayNames'] as Map<String, dynamic>;
      expected[item['id'] as String] = (
        names['ko'] as String,
        item['voice'] as String,
      );
    }
    final roles = payload['runtimeRoleProfiles'] as Map<String, dynamic>;
    for (final entry in roles.entries) {
      final item = entry.value as Map<String, dynamic>;
      expected[entry.key] = (
        item['displayNameKo'] as String,
        item['voice'] as String,
      );
    }

    expect(
      ScenarioCharacterCatalog.profiles.keys.toSet(),
      expected.keys.toSet(),
    );
    for (final entry in expected.entries) {
      final runtime = ScenarioCharacterCatalog.profileFor(entry.key)!;
      expect(runtime.nameKo, entry.value.$1, reason: entry.key);
      expect(runtime.voice, entry.value.$2, reason: entry.key);
    }
  });

  test('scenario JSON resolves user through its player character', () {
    final scenario = Scenario.fromJson({
      'id': 'speaker_contract',
      'level': 'b1',
      'playerCharacterId': 'christian',
      'participantIds': ['christian', 'sujin'],
      'dialog': [
        {
          'speaker': 'user',
          'ko': '미안해.',
          'de': 'Tut mir leid.',
          'en': 'Sorry.',
        },
        {
          'speaker': 'sujin',
          'ko': '괜찮아.',
          'de': 'Schon gut.',
          'en': 'It is okay.',
        },
      ],
    });

    expect(scenario.playerCharacterId, 'christian');
    expect(scenario.participantIds, ['christian', 'sujin']);
    expect(scenario.resolvedCharacterIdForSpeaker('user'), 'christian');
    expect(scenario.voiceForSpeaker('user'), 'male');
    expect(scenario.voiceForSpeaker('sujin'), 'female');
    expect(
      scenario.speakerDisplayName(
        'user',
        languageCode: 'de',
        fallbackYou: 'Du',
        fallbackNarrator: 'Erzähler',
      ),
      '크리스티안 (나)',
    );
  });

  test('legacy scenario keeps the old user and NPC voice fallback', () {
    const scenario = Scenario(
      id: 'legacy',
      level: LearnerLevel.a1,
      emoji: '💬',
      register: Register.polite,
      title: LocalizedText(ko: '', de: '', en: ''),
      intro: LocalizedText(ko: '', de: '', en: ''),
      vocab: [],
      grammarIds: [],
      dialog: [],
      quests: [],
    );

    expect(scenario.voiceForSpeaker('user'), 'female');
    expect(scenario.voiceForSpeaker('unknown_npc'), 'male');
  });
}
