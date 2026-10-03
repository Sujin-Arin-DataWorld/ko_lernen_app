import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ko_lernen_app/features/personas/persona_dialogue_index.dart';
import 'package:ko_lernen_app/models/persona_presentation.dart';
import 'package:ko_lernen_app/models/scenario.dart';
import 'package:ko_lernen_app/models/scenario_character.dart';

import 'support/scenario_json.dart';

void main() {
  test(
    'all eleven approved originals retain their bytes and stable identity',
    () {
      final manifest =
          jsonDecode(
                File(
                  'docs/assets/persona_set_v3_manifest.json',
                ).readAsStringSync(),
              )
              as Map<String, dynamic>;
      final files = (manifest['files'] as List).cast<Map<String, dynamic>>();
      expect(files, hasLength(11));
      expect(PersonaPresentationCatalog.people.map((p) => p.characterId), [
        'sujin',
        'christian',
        'maya',
        'hyuna',
        'andrea',
        'lena',
        'daniel',
        'minho',
        'dongsun',
        'byeongcheol',
        'jun',
      ]);
      for (final person in PersonaPresentationCatalog.people) {
        expect(
          ScenarioCharacterCatalog.profileFor(person.characterId),
          isNotNull,
        );
        final entry = files.singleWhere(
          (f) => f['characterId'] == person.characterId,
        );
        expect(person.assetPath, entry['path']);
        final bytes = File(person.assetPath).readAsBytesSync();
        expect(bytes.length, entry['bytes']);
        expect(sha256.convert(bytes).toString(), entry['sha256']);
        for (final lang in ['ko', 'de', 'en']) {
          expect(person.intro.pick(lang), isNotEmpty);
          expect(person.practiceSummary.pick(lang), isNotEmpty);
          expect(person.interests, hasLength(2));
          for (final interest in person.interests) {
            expect(interest.pick(lang), isNotEmpty);
          }
        }
        for (final relation in person.relations) {
          expect(
            PersonaPresentationCatalog.presentationFor(relation.characterId),
            isNotNull,
          );
        }
      }
      expect(
        PersonaPresentationCatalog.presentationFor('jun')!.assetPath,
        endsWith('jun-16.png'),
      );
      expect(PersonaPresentationCatalog.presentationFor('professor'), isNull);
      expect(PersonaPresentationCatalog.presentationFor('manager'), isNull);
    },
  );

  test(
    'index distinguishes actual interlocutors from learner roles and absent participants',
    () {
      final corpus = allScenarioJson().map(Scenario.fromJson).toList();
      final index = PersonaDialogueIndex.fromCorpus(corpus);
      for (final id in [
        'sujin',
        'maya',
        'hyuna',
        'andrea',
        'lena',
        'daniel',
        'dongsun',
      ]) {
        final scenes = index.conversationsFor(
          id,
          preferredLevel: LearnerLevel.a1,
        );
        expect(scenes, isNotEmpty, reason: id);
        for (final scene in scenes) {
          expect(scene.dialog.any((line) => line.speaker == id), isTrue);
          expect(
            scene.voiceForSpeaker(id),
            ScenarioCharacterCatalog.profileFor(id)!.voice,
          );
        }
      }
      for (final scene in index.rolesFor('christian')) {
        expect(scene.playerCharacterId, 'christian');
        expect(
          scene.speakerDisplayName(
            'user',
            fallbackYou: 'Du',
            fallbackNarrator: 'Erzähler',
          ),
          '크리스티안',
        );
      }
      // The approved A2 additions satisfy the existing stock threshold, including
      // Christian's authored counterpart scene, with stable learner speaker IDs.
      for (final person in PersonaPresentationCatalog.people) {
        expect(
          index.conversationsFor(person.characterId),
          isNotEmpty,
          reason: person.characterId,
        );
      }
      final scene = Scenario.fromJson({
        'id': 'participant_only',
        'level': 'a1',
        'playerCharacterId': 'lena',
        'participantIds': ['lena', 'jun'],
        'dialog': [
          {'speaker': 'user', 'ko': '안녕하세요.', 'de': 'Hallo.', 'en': 'Hello.'},
          {
            'speaker': 'professor',
            'ko': '반가워요.',
            'de': 'Freut mich.',
            'en': 'Nice to meet you.',
          },
        ],
      });
      expect(PersonaDialogueIndex.interlocutorIds(scene), isEmpty);
    },
  );

  test(
    'Jun writer bible matches approved sixteen-year-old art without changing identity',
    () {
      final bible = jsonDecode(
        File(
          'tools/content_factory/canonical_scenarios/character_profiles.json',
        ).readAsStringSync(),
      );
      final jun = (bible['recurringCharacters'] as List)
          .cast<Map<String, dynamic>>()
          .singleWhere((p) => p['id'] == 'jun');
      expect(jun['ageGroup'], 'teen');
      expect(jun['background']['relativeAge'], '16세');
      expect(jun['background']['role'], '고등학교 1학년 학생');
      expect(jun['relationships']['andrea'], '엄마');
      expect(jun['relationships']['minho'], '아빠');
      expect(ScenarioCharacterCatalog.profileFor('jun')!.voice, 'male');
    },
  );
}
