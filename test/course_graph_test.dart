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
          vocab.where((item) => item.level.toLowerCase() == level).map(
                (item) => item.id,
              ),
          level,
        );
        expectLevelLinks(
          CurriculumContentKind.grammar,
          grammar.where((item) => item.level.toLowerCase() == level).map(
                (item) => item.id,
              ),
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
          expect(parts, hasLength(2), reason: '$checkpoint must be a content key');
          final kind = CurriculumContentKindX.tryFromCode(parts.first);
          expect(kind, isNotNull, reason: '$checkpoint has an unknown kind');
          final assessments = catalog
              .linksForContent(kind!, parts.last)
              .where(
                (link) =>
                    link.courseUnitId == unit.id &&
                    link.role == ContentLinkRole.assess &&
                    unit.requiredConceptIds.every(link.conceptIds.contains),
              );
          expect(
            assessments,
            isNotEmpty,
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
            links.any(
              (link) =>
                  link.courseUnitId == unit.id &&
                  link.role == ContentLinkRole.assess &&
                  link.conceptIds.toSet().containsAll(unit.requiredConceptIds),
            ),
            isTrue,
            reason: '$checkpoint needs an assessment link for ${unit.id}',
          );
        }
      }
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
