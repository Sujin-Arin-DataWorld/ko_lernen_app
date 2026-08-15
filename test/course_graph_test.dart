import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:ko_lernen_app/models/curriculum.dart';
import 'package:ko_lernen_app/models/grammar.dart';
import 'package:ko_lernen_app/models/scenario.dart';
import 'package:ko_lernen_app/models/smalltalk.dart';
import 'package:ko_lernen_app/models/vocab.dart';
import 'package:ko_lernen_app/services/cloze_loader.dart';
import 'package:ko_lernen_app/services/curriculum_catalog.dart';
import 'package:ko_lernen_app/services/data_loader.dart';
import 'package:ko_lernen_app/services/satz_loader.dart';
import 'package:ko_lernen_app/services/scenario_loader.dart';
import 'package:ko_lernen_app/services/smalltalk_loader.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    DataLoader.reset();
    ScenarioLoader.reset();
    SmalltalkLoader.reset();
    CurriculumCatalog.reset();
  });

  test('production content has durable, unique explicit source IDs', () async {
    final vocab = await DataLoader.loadVocab();
    final grammar = await DataLoader.loadGrammar();
    await SmalltalkLoader.load();
    final cloze = await ClozeLoader.load();
    final satz = await SatzLoader.load();

    void expectUnique(Iterable<String> ids, String label) {
      final all = ids.toList();
      expect(all, isNotEmpty, reason: '$label must not be empty');
      expect(all.toSet(), hasLength(all.length), reason: '$label IDs collide');
      expect(
        all.every((id) => RegExp(r'^[a-z0-9_]+$').hasMatch(id)),
        isTrue,
        reason: '$label IDs must be raw, human-auditable source IDs',
      );
    }

    expectUnique(vocab.map((item) => item.id), 'vocab');
    expectUnique(grammar.map((item) => item.id), 'grammar');
    expectUnique(SmalltalkLoader.phrases.map((item) => item.id), 'smalltalk');
    expectUnique(cloze.map((item) => item.id), 'cloze');
    expectUnique(satz.map((item) => item.id), 'satz');
    expect(vocab.every((item) => item.hasExplicitId), isTrue);
    expect(grammar.every((item) => item.hasExplicitId), isTrue);
    expect(SmalltalkLoader.phrases.every((item) => item.hasExplicitId), isTrue);
    expect(cloze.every((item) => item.hasExplicitId), isTrue);
    expect(satz.every((item) => item.hasExplicitId), isTrue);
  });

  test(
    'production grammar and smalltalk mappings declare their exact concept targets',
    () async {
      final raw =
          jsonDecode(
                File('assets/data/curriculum_manifest.json').readAsStringSync(),
              )
              as Map<String, dynamic>;
      final catalog = await CurriculumCatalog.load();
      final grammar = await DataLoader.loadGrammar();
      await SmalltalkLoader.load();
      final units = {for (final unit in catalog.courseUnits) unit.id: unit};

      void expectRuleTargets(
        String label,
        Object? rawRule,
        Iterable<ContentLink> links,
        ContentLinkRole role,
      ) {
        expect(rawRule, isA<Map>(), reason: '$label needs explicit targets');
        if (rawRule is! Map) return;
        final rule = rawRule.map(
          (key, value) => MapEntry(key.toString(), value),
        );
        final unitId = rule['courseUnitId'];
        final rawConceptIds = rule['conceptIds'];
        expect(unitId, isA<String>(), reason: '$label needs a course unit');
        expect(rawConceptIds, isA<List>(), reason: '$label needs concept IDs');
        if (unitId is! String || rawConceptIds is! List) return;
        final conceptIds = rawConceptIds.cast<String>();
        expect(
          conceptIds,
          isNotEmpty,
          reason: '$label needs one or more concepts',
        );
        final unit = units[unitId];
        expect(unit, isNotNull, reason: '$label targets an existing unit');
        if (unit == null) return;
        expect(
          unit.requiredConceptIds,
          containsAll(conceptIds),
          reason: '$label only credits concepts required by its unit',
        );
        final matching = links
            .where((link) => link.courseUnitId == unitId && link.role == role)
            .toList(growable: false);
        expect(matching, hasLength(1), reason: '$label has one graph edge');
        if (matching.length == 1) {
          expect(
            matching.single.conceptIds,
            orderedEquals(conceptIds),
            reason: '$label does not fan out to unrelated concepts',
          );
        }
      }

      final grammarRules = raw['grammarRuleMap'] as Map<String, dynamic>;
      for (final entry in grammarRules.entries) {
        expect(
          grammar.map((item) => item.id),
          contains(entry.key),
          reason: 'grammar map only names a real source item',
        );
        expectRuleTargets(
          'grammar:${entry.key}',
          entry.value,
          catalog.linksForContent(CurriculumContentKind.grammar, entry.key),
          ContentLinkRole.assess,
        );
      }

      final smalltalkRules =
          raw['smalltalkCategoryUnitMap'] as Map<String, dynamic>;
      for (final entry in smalltalkRules.entries) {
        final parts = entry.key.split(':');
        expect(parts, hasLength(2), reason: 'smalltalk key is level:category');
        if (parts.length != 2) continue;
        final phrases = SmalltalkLoader.phrases
            .where(
              (phrase) =>
                  phrase.level == parts.first && phrase.category == parts.last,
            )
            .toList(growable: false);
        expect(phrases, isNotEmpty, reason: 'smalltalk map has source phrases');
        for (final phrase in phrases) {
          expectRuleTargets(
            'smalltalk:${entry.key}:${phrase.id}',
            entry.value,
            catalog.linksForContent(CurriculumContentKind.smalltalk, phrase.id),
            ContentLinkRole.practice,
          );
        }
      }

      final checkpointRules =
          raw['smalltalkCheckpointPhraseMap'] as Map<String, dynamic>;
      expect(checkpointRules, isNotEmpty);
      for (final entry in checkpointRules.entries) {
        final phrase = SmalltalkLoader.phrases.singleWhere(
          (item) => item.id == entry.key,
        );
        expectRuleTargets(
          'smalltalk checkpoint:${entry.key}',
          entry.value,
          catalog.linksForContent(CurriculumContentKind.smalltalk, phrase.id),
          ContentLinkRole.assess,
        );
        final rule = entry.value as Map<String, dynamic>;
        final conceptId = (rule['conceptIds'] as List).single as String;
        expect(
          catalog.conceptFor(conceptId)?.kind,
          ConceptKind.speechStyle,
          reason:
              'relationship checkpoint only measures a speech-style concept',
        );
        expect(
          catalog.courseUnitFor(rule['courseUnitId'] as String)?.level,
          phrase.level,
          reason: 'checkpoint phrase and its mission stay in the same level',
        );
      }
    },
  );

  test('stable IDs ignore translated copy, examples, and distractors', () {
    const vocabSource = Vocab(
      korean: '커피',
      romanization: 'keopi',
      german: 'Kaffee',
      english: 'coffee',
      level: 'a1',
      posDe: 'Nomen',
      posEn: 'noun',
      exampleKorean: '커피를 마셔요.',
      exampleGerman: 'Ich trinke Kaffee.',
      exampleEnglish: 'I drink coffee.',
      topic: 'Essen',
      packId: 'a1_food_1',
      packOrder: 1,
    );
    const vocabCopyEdit = Vocab(
      korean: '커피',
      romanization: 'keopi',
      german: 'Kaffee (Getränk)',
      english: 'coffee drink',
      level: 'a1',
      posDe: 'Substantiv',
      posEn: 'noun',
      exampleKorean: '저는 커피를 마셔요.',
      exampleGerman: 'Ich trinke einen Kaffee.',
      exampleEnglish: 'I am having coffee.',
      topic: 'Essen',
      packId: 'a1_food_1',
      packOrder: 1,
    );
    expect(vocabCopyEdit.id, vocabSource.id);

    final grammarSource = Grammar.fromRow([
      'N은/는',
      'A1',
      'Thema-Partikel',
      'original explanation',
      '저는 학생이에요.',
      'Ich bin Student.',
      'original note',
      'Topic particle',
      'original English explanation',
      'I am a student.',
      'original English note',
      'grammar_a1_topic_particle',
    ]);
    final grammarCopyEdit = Grammar.fromRow([
      'N은/는 (Anzeige)',
      'A1',
      'Thema-Partikel (überarbeitet)',
      'new explanation',
      '수진은 학생이에요.',
      'Sujin ist Studentin.',
      'new note',
      'Topic particle (revised)',
      'new English explanation',
      'Sujin is a student.',
      'new English note',
      'grammar_a1_topic_particle',
    ]);
    expect(grammarSource.id, 'grammar_a1_topic_particle');
    expect(grammarCopyEdit.id, grammarSource.id);

    const smalltalkSource = SmalltalkPhrase(
      category: 'food',
      level: 'a1',
      kind: 'reaction',
      ko: '맛있어요.',
      de: 'Lecker.',
      en: 'Tasty.',
    );
    const smalltalkCopyEdit = SmalltalkPhrase(
      category: 'food',
      level: 'a1',
      kind: 'reaction',
      ko: '맛있어요.',
      de: 'Das schmeckt richtig gut.',
      en: 'This tastes great.',
    );
    expect(smalltalkCopyEdit.id, smalltalkSource.id);

    const clozeSource = ClozeItem(
      level: 'a1',
      sentenceKo: '저는 ___ 마셔요.',
      answer: '커피를',
      fullKo: '저는 커피를 마셔요.',
      de: 'Ich trinke Kaffee.',
      en: 'I drink coffee.',
      distractors: ['물을', '차를'],
      topic: 'Essen & Trinken',
    );
    const clozeCopyEdit = ClozeItem(
      level: 'a1',
      sentenceKo: '저는 ___ 마셔요.',
      answer: '커피를',
      fullKo: '저는 커피를 마셔요.',
      de: 'Ich trinke gern Kaffee.',
      en: 'I like to drink coffee.',
      distractors: ['우유를', '주스를'],
      topic: 'Essen & Trinken',
    );
    expect(clozeCopyEdit.id, clozeSource.id);

    const satzSource = SatzSentence(
      level: 'a1',
      targetKo: '저는 커피를 마셔요.',
      promptDe: 'Ich trinke Kaffee.',
      promptEn: 'I drink coffee.',
      distractors: ['우유를'],
      vocabKo: '커피',
    );
    const satzCopyEdit = SatzSentence(
      level: 'a1',
      targetKo: '저는 커피를 마셔요.',
      promptDe: 'Ich trinke gern Kaffee.',
      promptEn: 'I like to drink coffee.',
      distractors: ['주스를'],
      vocabKo: '커피',
    );
    expect(satzCopyEdit.id, satzSource.id);
  });

  test(
    'raw scenario grammar links are nonempty, known, and no longer formal',
    () async {
      final raw =
          jsonDecode(File('assets/data/scenarios.json').readAsStringSync())
              as Map<String, dynamic>;
      final rawScenarios = (raw['scenarios'] as List)
          .cast<Map<String, dynamic>>();
      final grammar = await DataLoader.loadGrammar();
      final grammarIds = grammar.map((item) => item.id).toSet();

      for (final scenario in rawScenarios) {
        final ids = (scenario['grammarIds'] as List? ?? const [])
            .cast<String>();
        expect(ids, isNotEmpty, reason: '${scenario['id']} needs grammar IDs');
        expect(
          ids.every(grammarIds.contains),
          isTrue,
          reason: '${scenario['id']} references an unknown grammar ID',
        );
        expect(scenario['register'], isNot('formal'));
        expect(scenario['speechStyle'], isNotNull);
        expect(scenario['relationshipContext'], isNotNull);
        expect(scenario['intent'], isNotNull);
        expect(scenario['conceptIds'], isNotNull);
      }
    },
  );

  test(
    'semantic content mappings are stable when the source lists are reordered',
    () async {
      final rawManifest =
          jsonDecode(
                File('assets/data/curriculum_manifest.json').readAsStringSync(),
              )
              as Map<String, dynamic>;
      final vocab = await DataLoader.loadVocab();
      final grammar = await DataLoader.loadGrammar();
      await SmalltalkLoader.load();
      final smalltalk = SmalltalkLoader.phrases;
      final cloze = await ClozeLoader.load();
      final satz = await SatzLoader.load();
      final scenarios = await ScenarioLoader.load();

      final forward = CurriculumCatalog.fromDataForTesting(
        manifestJson: rawManifest,
        vocab: vocab,
        grammar: grammar,
        smalltalk: smalltalk,
        cloze: cloze,
        satz: satz,
        scenarios: scenarios,
      );
      final reversed = CurriculumCatalog.fromDataForTesting(
        manifestJson: rawManifest,
        vocab: vocab.reversed.toList(),
        grammar: grammar.reversed.toList(),
        smalltalk: smalltalk.reversed.toList(),
        cloze: cloze.reversed.toList(),
        satz: satz.reversed.toList(),
        scenarios: scenarios.reversed.toList(),
      );

      expect(forward.validationIssues, isEmpty);
      expect(reversed.validationIssues, isEmpty);

      const selected = <CurriculumContentKind>{
        CurriculumContentKind.vocab,
        CurriculumContentKind.grammar,
        CurriculumContentKind.smalltalk,
        CurriculumContentKind.cloze,
        CurriculumContentKind.satz,
        CurriculumContentKind.scenario,
      };
      Map<String, Set<String>> targetsFor(CurriculumCatalog catalog) {
        final targets = <String, Set<String>>{};
        for (final link in catalog.contentLinks) {
          if (!selected.contains(link.contentKind)) continue;
          targets
              .putIfAbsent(link.contentKey, () => <String>{})
              .add(link.courseUnitId);
        }
        return targets;
      }

      final forwardTargets = targetsFor(forward);
      final reversedTargets = targetsFor(reversed);
      expect(reversedTargets, forwardTargets);

      final introduction = scenarios.singleWhere(
        (scenario) => scenario.id == 'introduce_yourself',
      );
      final scenarioLinks = forward.linksForContent(
        CurriculumContentKind.scenario,
        introduction.id,
      );
      expect(scenarioLinks, isNotEmpty);
      expect(
        scenarioLinks.expand((link) => link.conceptIds),
        contains('concept_identity_formal'),
      );
    },
  );

  test(
    'B1/B2 source content belongs to level-linked missions and checkpoints assess exactly',
    () async {
      final catalog = await CurriculumCatalog.load();
      final vocab = await DataLoader.loadVocab();
      final grammar = await DataLoader.loadGrammar();
      await SmalltalkLoader.load();
      final cloze = await ClozeLoader.load();
      final satz = await SatzLoader.load();
      final scenarios = await ScenarioLoader.load();
      const levels = {'b1', 'b2'};

      void expectLevelLinks(
        CurriculumContentKind kind,
        Iterable<String> ids,
        String level,
      ) {
        final sourceIds = ids.toList(growable: false);
        expect(sourceIds, isNotEmpty, reason: '$level must have $kind sources');
        for (final id in sourceIds) {
          final links = catalog.linksForContent(kind, id);
          expect(
            links.any(
              (link) =>
                  catalog.courseUnitFor(link.courseUnitId)?.level == level &&
                  link.conceptIds.isNotEmpty,
            ),
            isTrue,
            reason: '$level $kind:$id is not connected to a mission concept',
          );
        }
      }

      for (final level in levels) {
        expectLevelLinks(
          CurriculumContentKind.vocab,
          vocab
              .where((item) => item.level.toLowerCase() == level)
              .map((item) => item.id),
          level,
        );
        expectLevelLinks(
          CurriculumContentKind.grammar,
          grammar
              .where((item) => item.level.toLowerCase() == level)
              .map((item) => item.id),
          level,
        );
        expectLevelLinks(
          CurriculumContentKind.smalltalk,
          SmalltalkLoader.phrases
              .where((item) => item.level.toLowerCase() == level)
              .map((item) => item.id),
          level,
        );
        expectLevelLinks(
          CurriculumContentKind.cloze,
          cloze.where((item) => item.level == level).map((item) => item.id),
          level,
        );
        expectLevelLinks(
          CurriculumContentKind.satz,
          satz.where((item) => item.level == level).map((item) => item.id),
          level,
        );
        expectLevelLinks(
          CurriculumContentKind.scenario,
          scenarios
              .where((item) => item.level.code == level)
              .map((item) => item.id),
          level,
        );
      }

      for (final unit in catalog.courseUnits.where(
        (item) => levels.contains(item.level),
      )) {
        for (final checkpoint in unit.checkpointContentIds) {
          final parts = checkpoint.split(':');
          expect(
            parts,
            hasLength(2),
            reason: '$checkpoint must be a content key',
          );
          final kind = CurriculumContentKindX.tryFromCode(parts.first);
          expect(kind, isNotNull, reason: '$checkpoint has an unknown kind');
          final assessments = catalog
              .linksForContent(kind!, parts.last)
              .where(
                (link) =>
                    link.courseUnitId == unit.id && link.exactlyAssesses(unit),
              );
          expect(
            assessments,
            hasLength(1),
            reason: '$checkpoint lacks an assessment link for ${unit.id}',
          );
        }
      }
    },
  );

  test('manifest enum and mapping errors remain visible to validation', () {
    final issues = CurriculumCatalog.validateManifestForTesting({
      'courseUnits': const [],
      'concepts': const [],
      'surfaceForms': const [],
      'formFamilies': const [],
      'contentLinks': const [
        {
          'contentKind': 'not-a-kind',
          'contentId': 'x',
          'courseUnitId': 'missing',
          'conceptIds': ['missing'],
          'role': 'not-a-role',
        },
      ],
      'vocabPackUnitMap': const {'a1_test': 'missing_unit'},
      'smalltalkCategoryUnitMap': const {},
      'clozeTopicUnitMap': const {},
      'grammarRuleMap': const {},
    });

    expect(issues, contains('invalid content kind not-a-kind'));
    expect(issues, contains('invalid content link role not-a-role'));
    expect(issues, contains('missing link unit vocab:x'));
    expect(issues, contains('missing vocab map unit a1_test'));
  });

  test('ambiguous generic checkpoint edges fail catalog validation closed', () {
    final issues = CurriculumCatalog.validateManifestForTesting({
      'courseUnits': [
        {
          'id': 'a1_test',
          'level': 'a1',
          'order': 1,
          'title': {'ko': '시험', 'de': 'Test', 'en': 'Test'},
          'canDo': {'ko': '시험', 'de': 'Test', 'en': 'Test'},
          'requiredConceptIds': ['concept_one', 'concept_two'],
          'checkpointContentIds': const <String>[],
        },
      ],
      'concepts': [
        {
          'id': 'concept_one',
          'level': 'a1',
          'kind': 'particle',
          'title': {'ko': '하나', 'de': 'Eins', 'en': 'One'},
          'explanation': {'ko': '하나', 'de': 'Eins', 'en': 'One'},
        },
        {
          'id': 'concept_two',
          'level': 'a1',
          'kind': 'particle',
          'title': {'ko': '둘', 'de': 'Zwei', 'en': 'Two'},
          'explanation': {'ko': '둘', 'de': 'Zwei', 'en': 'Two'},
        },
      ],
      'surfaceForms': const [],
      'formFamilies': const [],
      'contentLinks': const [
        {
          'id': 'grammar_one',
          'contentKind': 'grammar',
          'contentId': 'grammar_test',
          'courseUnitId': 'a1_test',
          'conceptIds': ['concept_one'],
          'role': 'assess',
        },
        {
          'id': 'grammar_two',
          'contentKind': 'grammar',
          'contentId': 'grammar_test',
          'courseUnitId': 'a1_test',
          'conceptIds': ['concept_two'],
          'role': 'assess',
        },
      ],
      'vocabPackUnitMap': const {},
      'smalltalkCategoryUnitMap': const {},
      'smalltalkCheckpointPhraseMap': const {},
      'clozeTopicUnitMap': const {},
      'grammarRuleMap': const {},
    });

    expect(
      issues,
      contains('ambiguous checkpoint link a1_test grammar:grammar_test'),
    );
  });

  test(
    'a relationship checkpoint cannot credit a non-speech-style concept',
    () {
      final issues = CurriculumCatalog.validateManifestForTesting({
        'courseUnits': [
          {
            'id': 'a1_test',
            'level': 'a1',
            'order': 1,
            'title': {'ko': '시험', 'de': 'Test', 'en': 'Test'},
            'canDo': {'ko': '시험', 'de': 'Test', 'en': 'Test'},
            'requiredConceptIds': ['concept_particle'],
            'checkpointContentIds': const <String>[],
          },
        ],
        'concepts': [
          {
            'id': 'concept_particle',
            'level': 'a1',
            'kind': 'particle',
            'title': {'ko': '조사', 'de': 'Partikel', 'en': 'Particle'},
            'explanation': {'ko': '조사', 'de': 'Partikel', 'en': 'Particle'},
          },
        ],
        'surfaceForms': const [],
        'formFamilies': const [],
        'contentLinks': const [
          {
            'id': 'unsafe_smalltalk_checkpoint',
            'contentKind': 'smalltalk',
            'contentId': 'smalltalk_test',
            'courseUnitId': 'a1_test',
            'conceptIds': ['concept_particle'],
            'role': 'assess',
          },
        ],
        'vocabPackUnitMap': const {},
        'smalltalkCategoryUnitMap': const {},
        'smalltalkCheckpointPhraseMap': const {},
        'clozeTopicUnitMap': const {},
        'grammarRuleMap': const {},
      });

      expect(
        issues,
        contains(
          'invalid smalltalk checkpoint concept-kind smalltalk:smalltalk_test',
        ),
      );
    },
  );

  test(
    'legacy string dynamic maps remain usable in focused test manifests',
    () {
      final issues = CurriculumCatalog.validateManifestForTesting({
        'courseUnits': [
          {
            'id': 'a1_test',
            'level': 'a1',
            'order': 1,
            'title': {'ko': '시험', 'de': 'Test', 'en': 'Test'},
            'canDo': {'ko': '시험', 'de': 'Test', 'en': 'Test'},
            'requiredConceptIds': ['concept_test'],
            'checkpointContentIds': const <String>[],
          },
        ],
        'concepts': [
          {
            'id': 'concept_test',
            'level': 'a1',
            'kind': 'situation',
            'title': {'ko': '시험', 'de': 'Test', 'en': 'Test'},
            'explanation': {'ko': '시험', 'de': 'Test', 'en': 'Test'},
          },
        ],
        'surfaceForms': const [],
        'formFamilies': const [],
        'contentLinks': const [],
        'vocabPackUnitMap': const {},
        'smalltalkCategoryUnitMap': const {'a1:test': 'a1_test'},
        'clozeTopicUnitMap': const {},
        'grammarRuleMap': const {'grammar_test': 'a1_test'},
      });

      expect(
        issues,
        isNot(contains('empty grammar map concepts grammar_test')),
      );
      expect(issues, isNot(contains('empty smalltalk map concepts a1:test')));
    },
  );

  test(
    'manifest creates a complete, acyclic level-linked content graph',
    () async {
      final catalog = await CurriculumCatalog.load();
      final vocab = await DataLoader.loadVocab();
      final grammar = await DataLoader.loadGrammar();
      await SmalltalkLoader.load();
      final cloze = await ClozeLoader.load();
      final satz = await SatzLoader.load();
      final scenarios = await ScenarioLoader.load();

      expect(catalog.validationIssues, isEmpty);
      expect(catalog.hasPrerequisiteCycle, isFalse);
      expect(
        catalog.courseUnits.where((unit) => unit.level == 'a1'),
        hasLength(16),
      );
      expect(
        catalog.courseUnits.map((unit) => unit.id).toSet(),
        hasLength(catalog.courseUnits.length),
      );
      expect(
        catalog.concepts.map((concept) => concept.id).toSet(),
        hasLength(catalog.concepts.length),
      );
      expect(
        catalog.formFamilies.map((family) => family.id).toSet(),
        hasLength(catalog.formFamilies.length),
      );

      for (final entry in vocab) {
        expect(
          catalog.hasLink(CurriculumContentKind.vocab, entry.id),
          isTrue,
          reason: 'orphan vocab ${entry.korean}',
        );
      }
      for (final entry in grammar) {
        expect(
          catalog.hasLink(CurriculumContentKind.grammar, entry.id),
          isTrue,
          reason: 'orphan grammar ${entry.pattern}',
        );
      }
      for (final entry in SmalltalkLoader.phrases) {
        expect(
          catalog.hasLink(CurriculumContentKind.smalltalk, entry.id),
          isTrue,
          reason: 'orphan smalltalk ${entry.ko}',
        );
      }
      for (final entry in cloze) {
        expect(
          catalog.hasLink(CurriculumContentKind.cloze, entry.id),
          isTrue,
          reason: 'orphan cloze ${entry.fullKo}',
        );
      }
      for (final entry in satz) {
        expect(
          catalog.hasLink(CurriculumContentKind.satz, entry.id),
          isTrue,
          reason: 'orphan satz ${entry.targetKo}',
        );
      }
      for (final entry in scenarios) {
        expect(
          catalog.hasLink(CurriculumContentKind.scenario, entry.id),
          isTrue,
          reason: 'orphan scenario ${entry.id}',
        );
      }
    },
  );

  test(
    'every declared scenario checkpoint has an assessment link for its exact mission',
    () async {
      final catalog = await CurriculumCatalog.load();

      for (final unit in catalog.courseUnits) {
        for (final checkpoint in unit.checkpointContentIds) {
          final pieces = checkpoint.split(':');
          expect(
            pieces,
            hasLength(2),
            reason: 'invalid checkpoint $checkpoint',
          );
          expect(pieces.first, CurriculumContentKind.scenario.code);

          final links = catalog.linksForContent(
            CurriculumContentKind.scenario,
            pieces.last,
          );
          expect(
            links.where((link) => link.exactlyAssesses(unit)),
            hasLength(1),
            reason: '$checkpoint needs an assessment link for ${unit.id}',
          );
        }
      }
    },
  );

  test(
    'every required concept uses its audited quest in the declared checkpoint',
    () async {
      final catalog = await CurriculumCatalog.load();
      final scenarios = await ScenarioLoader.load();
      final scenarioById = {for (final item in scenarios) item.id: item};

      const auditedQuestByUnitAndConcept = <String, Map<String, String>>{
        'a1_01_greetings_hangul': {
          'concept_hangul_batchim': 'quest_airport_arrival_02',
          'concept_greeting_politeness': 'quest_airport_arrival_04',
        },
        'a1_02_self_intro_identity': {
          'concept_identity_formal': 'quest_introduce_yourself_07',
          'concept_identity_polite': 'quest_introduce_yourself_07',
          'concept_identity_casual': 'quest_introduce_yourself_07',
        },
        'a1_03_topic_subject_particles': {
          'concept_topic_particle': 'quest_mart_grocery_02',
          'concept_subject_particle': 'quest_mart_grocery_06',
        },
        'a1_04_order_request_object': {
          'concept_object_particle': 'quest_bunshik_tteokbokki_06',
          'concept_request_polite': 'quest_bunshik_tteokbokki_03',
        },
        'a1_05_numbers_time': {
          'concept_a1_time_numbers': 'quest_hotel_checkin_03',
        },
        'a1_06_transport_directions': {
          'concept_a1_directions': 'quest_taxi_kakao_06',
        },
        'a1_07_contact_address': {
          'concept_a1_contact_address': 'quest_phone_messenger_reply_06',
        },
        'a1_08_clarify_repair': {
          'concept_a1_clarification': 'quest_clarify_repeat_06',
        },
        'a1_09_home_daily_life': {
          'concept_a1_home_daily': 'quest_home_morning_routine_05',
        },
        'a1_10_health_safety': {
          'concept_a1_health_safety': 'quest_clinic_safety_06',
        },
        'a1_11_titles_relationships': {
          'concept_a1_titles_relationships':
              'quest_titles_relationship_distance_01',
        },
        'a1_12_daily_negation': {
          'concept_a1_negation': 'quest_mart_grocery_07',
        },
        'a1_13_register_switching': {
          'concept_a1_register_switch': 'quest_introduce_yourself_06',
          'concept_action_formal': 'quest_introduce_yourself_06',
          'concept_action_polite': 'quest_introduce_yourself_06',
          'concept_action_casual': 'quest_introduce_yourself_06',
        },
        'a1_14_payment_delivery': {
          'concept_a1_payment_delivery':
              'quest_delivery_address_confirmation_06',
        },
        'a1_15_first_class_work': {
          'concept_a1_first_meeting': 'quest_first_class_meeting_06',
        },
        'a1_16_survival_capstone': {
          'concept_a1_survival': 'quest_survival_day_capstone_05',
        },
        'a2_01_haeyo_transition': {
          'concept_action_formal': 'quest_cafe_starbucks_basic_05',
          'concept_action_polite': 'quest_cafe_starbucks_basic_05',
        },
        'a2_02_plans_proposals': {
          'concept_proposal_formal': 'quest_plans_with_friend_04',
          'concept_proposal_polite': 'quest_plans_with_friend_04',
          'concept_proposal_casual': 'quest_plans_with_friend_04',
        },
        'a2_03_chat_relationships': {
          'concept_a2_relationships': 'quest_running_late_04',
        },
        'a2_04_feelings_health': {
          'concept_a2_feelings': 'quest_pharmacy_headache_05',
        },
        'a2_05_delivery_services': {
          'concept_a2_services': 'quest_myeongdong_shopping_04',
        },
        'a2_06_study_work': {'concept_a2_work_study': 'quest_cafe_study_06'},
        'a2_07_travel_repair': {
          'concept_a2_travel_repair': 'quest_subway_transfer_05',
        },
        'a2_08_home_money': {
          'concept_a2_home_money': 'quest_rent_bank_transfer_05',
        },
        'b1_01_experience_reasons': {
          'concept_b1_reasons_experience': 'quest_postpone_plans_04',
        },
        'b1_02_indirect_speech': {
          'concept_b1_indirect_speech': 'quest_company_dinner_hoeshik_04',
        },
        'b1_03_work_softening': {
          'concept_b1_softening': 'quest_company_dinner_hoeshik_05',
        },
        'b1_04_relationships': {
          'concept_b1_relationships': 'quest_warm_encouragement_04',
        },
        'b1_05_complaint_resolution': {
          'concept_b1_complaint_resolution': 'quest_food_delivery_02',
        },
        'b1_06_life_capstone': {'concept_b1_life': 'quest_couple_argument_04'},
        'b2_01_formal_opening': {
          'concept_b2_formal_opening': 'quest_business_meeting_intro_04',
        },
        'b2_02_professional_opinion': {
          'concept_b2_opinion': 'quest_business_meeting_intro_05',
        },
        'b2_03_precise_requests': {
          'concept_b2_precise_requests': 'quest_doctor_consultation_04',
        },
        'b2_04_complaint_resolution': {
          'concept_b2_complaint': 'quest_complaint_delivery_04',
        },
        'b2_05_interview': {'concept_b2_interview': 'quest_job_interview_04'},
        'b2_06_advanced_capstone': {
          'concept_b2_advanced': 'quest_job_interview_05',
        },
      };

      final scenarioBackedUnits = catalog.courseUnits
          .where(
            (unit) => unit.checkpointContentIds.every(
              (checkpoint) => checkpoint.startsWith('scenario:'),
            ),
          )
          .toList(growable: false);
      expect(
        auditedQuestByUnitAndConcept.keys.toSet(),
        equals(scenarioBackedUnits.map((unit) => unit.id).toSet()),
        reason: 'the scenario semantic audit must cover every scenario unit',
      );

      for (final unit in scenarioBackedUnits) {
        final expected = auditedQuestByUnitAndConcept[unit.id]!;
        expect(
          expected.keys.toSet(),
          equals(unit.requiredConceptIds.toSet()),
          reason: '${unit.id} audit must match the exact required concepts',
        );
        expect(
          unit.checkpointContentIds,
          hasLength(1),
          reason: '${unit.id} must have one declared checkpoint scene',
        );
        final checkpoint = unit.checkpointContentIds.single.split(':');
        expect(checkpoint.first, CurriculumContentKind.scenario.code);
        final scenario = scenarioById[checkpoint.last];
        expect(
          scenario,
          isNotNull,
          reason: '${unit.id} checkpoint ${checkpoint.last} must exist',
        );
        if (scenario == null) continue;

        for (final entry in expected.entries) {
          final matching = scenario.quests
              .where((quest) => quest.id == entry.value)
              .toList();
          expect(
            matching,
            hasLength(1),
            reason:
                '${unit.id}:${entry.key} must use ${entry.value} in ${scenario.id}',
          );
          if (matching.isEmpty) continue;
          expect(
            matching.single.conceptIds,
            contains(entry.key),
            reason: '${entry.value} must explicitly assess ${entry.key}',
          );
        }
      }
    },
  );

  test(
    'C1/C2 units expose every advanced activity and one exact checkpoint',
    () async {
      final catalog = await CurriculumCatalog.load();
      final advancedUnits = catalog.courseUnits
          .where((unit) => const {'c1', 'c2'}.contains(unit.level))
          .toList(growable: false);

      expect(catalog.validationIssues, isEmpty);
      expect(advancedUnits, hasLength(4));
      const requiredKinds = {
        CurriculumContentKind.vocab,
        CurriculumContentKind.grammar,
        CurriculumContentKind.smalltalk,
        CurriculumContentKind.cloze,
        CurriculumContentKind.satz,
      };
      for (final unit in advancedUnits) {
        final links = catalog.linksForCourseUnit(unit.id);
        expect(unit.checkpointContentIds, hasLength(1));
        for (final kind in requiredKinds) {
          expect(
            links.any((link) => link.contentKind == kind),
            isTrue,
            reason: '${unit.id} has no ${kind.code} content',
          );
        }

        final checkpoint = unit.checkpointContentIds.single.split(':');
        final checkpointKind = CurriculumContentKindX.tryFromCode(
          checkpoint.first,
        );
        expect(checkpointKind, isNotNull);
        final exact = links
            .where(
              (link) =>
                  link.contentKind == checkpointKind &&
                  link.contentId == checkpoint.last &&
                  link.exactlyAssesses(unit),
            )
            .toList(growable: false);
        expect(
          exact,
          hasLength(1),
          reason: '${unit.id} checkpoint must resolve to one assessment edge',
        );
      }
    },
  );

  test(
    'audited checkpoint answers and rejected semantic tags stay exact',
    () async {
      final scenarios = await ScenarioLoader.load();
      final scenarioById = {for (final item in scenarios) item.id: item};
      final questById = <String, QuestSpec>{};
      for (final scenario in scenarios) {
        for (final quest in scenario.quests.where(
          (item) => item.hasExplicitId,
        )) {
          expect(
            questById.containsKey(quest.id),
            isFalse,
            reason: 'duplicate scenario quest ID ${quest.id}',
          );
          questById[quest.id] = quest;
        }
      }

      String correctKoreanAnswer(QuestSpec quest) {
        final target = quest.data['targetKo'];
        if (target is String) return target;
        final options = quest.data['options'];
        final index = (quest.data['correctIndex'] as num?)?.toInt();
        if (options is! List ||
            index == null ||
            index < 0 ||
            index >= options.length) {
          return '';
        }
        final option = options[index];
        if (option is Map) return option['ko']?.toString() ?? '';
        return option?.toString() ?? '';
      }

      const criticalAnswers = <String, String>{
        'quest_cafe_starbucks_basic_05': '주문 도와드리겠습니다. / 주문 도와드릴게요.',
        'quest_introduce_yourself_06': '연락처를 보내겠습니다. / 연락처를 보낼게요. / 연락처 보낼게.',
        'quest_introduce_yourself_07': '저는 안나입니다. / 저는 안나예요. / 나는 안나야.',
        'quest_food_delivery_02': '콜라가 빠졌어요. 가능하면 지금 다시 보내 주시겠어요?',
        'quest_job_interview_04':
            '해외 프로젝트를 3년 동안 관리한 경험이 있으며, 세부 사항을 꼼꼼하게 조율하는 것이 제 강점입니다.',
        'quest_job_interview_05':
            '검토 시간을 연장해 주시기 바랍니다. / 가능하시다면 검토 시간을 조금 더 주실 수 있을까요?',
        'quest_home_morning_routine_05': '집에서 7시에 일어나서 씻고 아침을 먹어요.',
        'quest_survival_day_capstone_05':
            '안녕하세요. 저는 안나입니다. / 떡볶이 한 인분 주세요. / 지하철역에 어떻게 가요? / 잘 못 알아들었어요. 천천히 다시 말씀해 주세요.',
        'quest_rent_bank_transfer_05':
            '월세는 70만 원이고 관리비는 별도예요. 자동이체는 25일로 해 주세요. 수수료가 있어요?',
      };
      for (final entry in criticalAnswers.entries) {
        final quest = questById[entry.key];
        expect(quest, isNotNull, reason: 'missing critical quest ${entry.key}');
        if (quest == null) continue;
        expect(
          correctKoreanAnswer(quest),
          entry.value,
          reason: '${entry.key} must keep its audited semantic answer',
        );
      }

      const rejectedTags = <List<String>>[
        [
          'airport_arrival',
          'quest_airport_arrival_01',
          'concept_greeting_politeness',
        ],
        [
          'airport_arrival',
          'quest_airport_arrival_03',
          'concept_identity_polite',
        ],
        [
          'introduce_yourself',
          'quest_introduce_yourself_02',
          'concept_identity_polite',
        ],
        [
          'introduce_yourself',
          'quest_introduce_yourself_03',
          'concept_identity_formal',
        ],
        [
          'introduce_yourself',
          'quest_introduce_yourself_05',
          'concept_identity_polite',
        ],
        ['mart_grocery', 'quest_mart_grocery_01', 'concept_topic_particle'],
        [
          'bunshik_tteokbokki',
          'quest_bunshik_tteokbokki_05',
          'concept_identity_polite',
        ],
        [
          'hotel_checkin',
          'quest_hotel_checkin_01',
          'concept_a1_contact_address',
        ],
        [
          'hotel_checkin',
          'quest_hotel_checkin_04',
          'concept_a1_contact_address',
        ],
        [
          'clarify_repeat',
          'quest_clarify_repeat_01',
          'concept_a1_clarification',
        ],
        [
          'food_delivery',
          'quest_food_delivery_01',
          'concept_b1_complaint_resolution',
        ],
        ['job_interview', 'quest_job_interview_02', 'concept_b2_interview'],
        ['job_interview', 'quest_job_interview_03', 'concept_b2_interview'],
      ];
      for (final rejected in rejectedTags) {
        final scenario = scenarioById[rejected[0]]!;
        final matching = scenario.quests
            .where((quest) => quest.id == rejected[1])
            .toList();
        expect(matching, hasLength(1));
        if (matching.isEmpty) continue;
        expect(
          matching.single.conceptIds,
          isNot(contains(rejected[2])),
          reason: '${rejected[1]} must not claim ${rejected[2]}',
        );
      }

      expect(
        scenarioById['cafe_starbucks_basic']!.conceptIds,
        isNot(contains('concept_action_formal')),
      );
      expect(
        scenarioById['introduce_yourself']!.conceptIds,
        isNot(contains('concept_a1_register_switch')),
      );
      expect(
        scenarioById['mart_grocery']!.conceptIds,
        isNot(contains('concept_a1_negation')),
      );
      expect(
        scenarioById['job_interview']!.conceptIds,
        isNot(contains('concept_b2_advanced')),
      );
    },
  );

  test(
    'all scenarios have normalized relationship, intent, speech style, and concepts',
    () async {
      final catalog = await CurriculumCatalog.load();
      final scenarios = await ScenarioLoader.load();

      expect(catalog.scenarioContexts, hasLength(scenarios.length));
      for (final scenario in scenarios) {
        final context = catalog.scenarioContextFor(scenario.id);
        expect(
          context,
          isNotNull,
          reason: 'missing context for ${scenario.id}',
        );
        expect(context!.relationshipContext.trim(), isNotEmpty);
        expect(context.intent.trim(), isNotEmpty);
        expect(context.conceptIds, isNotEmpty);
        expect(context.courseUnitId.trim(), isNotEmpty);
      }

      expect(
        catalog.scenarioContextFor('business_meeting_intro')!.speechStyle,
        SpeechStyle.business,
      );
      expect(
        catalog.scenarioContextFor('job_interview')!.speechStyle,
        SpeechStyle.business,
      );
      expect(Register.fromCode('formal'), Register.business);
    },
  );

  test(
    'A1 pilot and expression families expose the realistic first choices',
    () async {
      final catalog = await CurriculumCatalog.load();
      const pilotIds = {
        'a1_01_greetings_hangul',
        'a1_02_self_intro_identity',
        'a1_03_topic_subject_particles',
        'a1_04_order_request_object',
      };

      final pilot = catalog.courseUnits.where((unit) => unit.isPilot).toList();
      expect(pilot.map((unit) => unit.id).toSet(), pilotIds);
      for (final unit in pilot) {
        expect(unit.canDo.ko.trim(), isNotEmpty);
        expect(unit.canDo.de.trim(), isNotEmpty);
        expect(unit.canDo.en.trim(), isNotEmpty);
        expect(unit.requiredConceptIds, isNotEmpty);
      }

      final identity = catalog.formFamilyFor('form_identity_registers')!;
      expect(
        identity.surfaceFormIds,
        containsAll(<String>[
          'surface_imnida',
          'surface_ieyo_yeyo',
          'surface_iya_ya',
        ]),
      );
      final action = catalog.formFamilyFor('form_action_registers')!;
      expect(
        action.surfaceFormIds,
        containsAll(<String>[
          'surface_hamnida',
          'surface_haeyo',
          'surface_hae',
        ]),
      );
      final proposal = catalog.formFamilyFor('form_proposal_registers')!;
      expect(
        proposal.surfaceFormIds,
        containsAll(<String>[
          'surface_halkkayo',
          'surface_hallaeyo',
          'surface_haja',
          'surface_hallae',
        ]),
      );
      final particles = catalog.formFamilyFor(
        'form_particles_topic_subject_object',
      )!;
      expect(
        particles.surfaceFormIds,
        containsAll(<String>[
          'surface_sujineun',
          'surface_sujiniga',
          'surface_babeul',
          'surface_keopireul',
        ]),
      );

      expect(catalog.surfaceFormFor('surface_deweo_juseyo')!.ko, '데워 주세요');
      expect(
        catalog.surfaceFormFor('surface_automatic_payment_ieyo')!.ko,
        '자동 결제예요',
      );
    },
  );

  test('A1 pilot quests record only their audited concept evidence', () async {
    final catalog = await CurriculumCatalog.load();
    final scenarios = await ScenarioLoader.load();
    const pilotScenarioIds = <String>{
      'airport_arrival',
      'introduce_yourself',
      'mart_grocery',
      'bunshik_tteokbokki',
    };

    for (final scenario in scenarios.where(
      (item) => pilotScenarioIds.contains(item.id),
    )) {
      expect(scenario.quests, isNotEmpty);
      for (final quest in scenario.quests) {
        expect(quest.hasExplicitId, isTrue, reason: '${scenario.id} quest ID');
        for (final conceptId in quest.conceptIds) {
          expect(catalog.conceptFor(conceptId), isNotNull);
          expect(
            catalog
                .linksForContent(CurriculumContentKind.scenario, scenario.id)
                .any((link) => link.conceptIds.contains(conceptId)),
            isTrue,
          );
        }
      }
    }

    final introductionLinks = catalog.linksForContent(
      CurriculumContentKind.scenario,
      'introduce_yourself',
    );
    expect(
      introductionLinks.any(
        (link) =>
            link.courseUnitId == 'a1_03_topic_subject_particles' &&
            link.conceptIds.contains('concept_topic_particle'),
      ),
      isTrue,
    );
    expect(
      introductionLinks.any(
        (link) =>
            link.courseUnitId == 'a1_01_greetings_hangul' &&
            link.conceptIds.contains('concept_hangul_batchim'),
      ),
      isTrue,
    );
  });
}
