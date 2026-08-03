import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

import '../models/curriculum.dart';
import '../models/grammar.dart';
import '../models/scenario.dart';
import '../models/smalltalk.dart';
import '../models/vocab.dart';
import 'cloze_loader.dart';
import 'data_loader.dart';
import 'satz_loader.dart';
import 'scenario_loader.dart';
import 'smalltalk_loader.dart';

/// Loads the curriculum graph through auditable semantic rules. Missing rules
/// are integrity errors; this catalog never selects a first-in-level fallback.
class CurriculumCatalog {
  static const assetPath = 'assets/data/curriculum_manifest.json';
  static CurriculumCatalog? _cache;

  final List<CourseUnit> courseUnits;
  final List<Concept> concepts;
  final List<SurfaceForm> surfaceForms;
  final List<FormFamily> formFamilies;
  final List<ScenarioContext> scenarioContexts;
  final List<ContentLink> contentLinks;
  final List<String> validationIssues;

  final Map<String, CourseUnit> _unitById;
  final Map<String, Concept> _conceptById;
  final Map<String, SurfaceForm> _surfaceFormById;
  final Map<String, FormFamily> _formFamilyById;
  final Map<String, ScenarioContext> _scenarioContextById;
  final Map<String, List<ContentLink>> _linksByContentKey;
  final Map<String, List<ContentLink>> _linksByUnitId;

  CurriculumCatalog._({
    required this.courseUnits,
    required this.concepts,
    required this.surfaceForms,
    required this.formFamilies,
    required this.scenarioContexts,
    required this.contentLinks,
    required List<String> validationIssues,
  }) : validationIssues = List.unmodifiable(validationIssues),
       _unitById = {for (final unit in courseUnits) unit.id: unit},
       _conceptById = {for (final concept in concepts) concept.id: concept},
       _surfaceFormById = {
         for (final surfaceForm in surfaceForms) surfaceForm.id: surfaceForm,
       },
       _formFamilyById = {for (final family in formFamilies) family.id: family},
       _scenarioContextById = {
         for (final context in scenarioContexts) context.scenarioId: context,
       },
       _linksByContentKey = _groupByContentKey(contentLinks),
       _linksByUnitId = _groupByUnitId(contentLinks);

  static Future<CurriculumCatalog> load() async {
    if (_cache != null) return _cache!;
    final raw = await rootBundle.loadString(assetPath);
    final decoded = jsonDecode(raw);
    if (decoded is! Map) {
      throw const FormatException('curriculum_manifest.json must be an object');
    }

    final vocabFuture = DataLoader.loadVocab();
    final grammarFuture = DataLoader.loadGrammar();
    final scenarioFuture = ScenarioLoader.load();
    final clozeFuture = ClozeLoader.load();
    final satzFuture = SatzLoader.load();
    await SmalltalkLoader.load();

    _cache = fromDataForTesting(
      manifestJson: _copyMap(decoded),
      vocab: await vocabFuture,
      grammar: await grammarFuture,
      smalltalk: SmalltalkLoader.phrases,
      cloze: await clozeFuture,
      satz: await satzFuture,
      scenarios: await scenarioFuture,
    );
    return _cache!;
  }

  /// Pure construction seam for data tooling and order-independence tests.
  static CurriculumCatalog fromDataForTesting({
    required Map<String, dynamic> manifestJson,
    required List<Vocab> vocab,
    required List<Grammar> grammar,
    required List<SmalltalkPhrase> smalltalk,
    required List<ClozeItem> cloze,
    required List<SatzSentence> satz,
    required List<Scenario> scenarios,
  }) {
    final manifest = _Manifest.fromJson(manifestJson);
    final build = _buildLinks(
      manifest: manifest,
      vocab: vocab,
      grammar: grammar,
      smalltalk: smalltalk,
      cloze: cloze,
      satz: satz,
      scenarios: scenarios,
    );
    final contexts = scenarios.map(_contextForScenario).toList(growable: false);
    final issues = <String>[
      ..._validateDefinitions(manifest, build.links),
      ...build.issues,
      ..._validateContent(
        manifest: manifest,
        links: build.links,
        vocab: vocab,
        grammar: grammar,
        smalltalk: smalltalk,
        cloze: cloze,
        satz: satz,
        scenarios: scenarios,
        scenarioContexts: contexts,
      ),
    ];
    return CurriculumCatalog._(
      courseUnits: List.unmodifiable(manifest.courseUnits),
      concepts: List.unmodifiable(manifest.concepts),
      surfaceForms: List.unmodifiable(manifest.surfaceForms),
      formFamilies: List.unmodifiable(manifest.formFamilies),
      scenarioContexts: List.unmodifiable(contexts),
      contentLinks: List.unmodifiable(build.links),
      validationIssues: _sortedDistinct(issues),
    );
  }

  /// Parser-only validation for editors and focused tests.
  static List<String> validateManifestForTesting(
    Map<String, dynamic> manifestJson,
  ) {
    final manifest = _Manifest.fromJson(manifestJson);
    return _sortedDistinct(
      _validateDefinitions(manifest, manifest.explicitLinks),
    );
  }

  static void reset() => _cache = null;

  CourseUnit? courseUnitFor(String id) => _unitById[id];
  Concept? conceptFor(String id) => _conceptById[id];
  SurfaceForm? surfaceFormFor(String id) => _surfaceFormById[id];
  FormFamily? formFamilyFor(String id) => _formFamilyById[id];
  ScenarioContext? scenarioContextFor(String scenarioId) =>
      _scenarioContextById[scenarioId];

  /// Reverse lookup for games and scenario results: evidence can fan out to
  /// every concept linked to the completed content.
  List<ContentLink> linksForContent(
    CurriculumContentKind kind,
    String contentId,
  ) => List.unmodifiable(
    _linksByContentKey[_contentKey(kind, contentId)] ?? const <ContentLink>[],
  );

  List<ContentLink> linksForCourseUnit(String courseUnitId) =>
      List.unmodifiable(_linksByUnitId[courseUnitId] ?? const <ContentLink>[]);

  bool hasLink(CurriculumContentKind kind, String contentId) =>
      linksForContent(kind, contentId).isNotEmpty;

  List<ContentLink> linksForConcept(String conceptId) => List.unmodifiable(
    contentLinks
        .where((link) => link.conceptIds.contains(conceptId))
        .toList(growable: false),
  );

  bool get hasPrerequisiteCycle {
    final visiting = <String>{};
    final visited = <String>{};
    bool visit(String id) {
      if (visited.contains(id)) return false;
      if (!visiting.add(id)) return true;
      final unit = _unitById[id];
      if (unit != null) {
        for (final prerequisite in unit.prerequisiteUnitIds) {
          if (visit(prerequisite)) return true;
        }
      }
      visiting.remove(id);
      visited.add(id);
      return false;
    }

    return courseUnits.any((unit) => visit(unit.id));
  }
}

class _Manifest {
  final List<CourseUnit> courseUnits;
  final List<Concept> concepts;
  final List<SurfaceForm> surfaceForms;
  final List<FormFamily> formFamilies;
  final List<ContentLink> explicitLinks;
  final Map<String, String> vocabPackUnitMap;
  final Map<String, _ContentRule> smalltalkCategoryUnitMap;
  final Map<String, _ContentRule> smalltalkCheckpointPhraseMap;
  final Map<String, String> clozeTopicUnitMap;
  final Map<String, _ContentRule> grammarRuleMap;
  final List<String> parseIssues;

  const _Manifest({
    required this.courseUnits,
    required this.concepts,
    required this.surfaceForms,
    required this.formFamilies,
    required this.explicitLinks,
    required this.vocabPackUnitMap,
    required this.smalltalkCategoryUnitMap,
    required this.smalltalkCheckpointPhraseMap,
    required this.clozeTopicUnitMap,
    required this.grammarRuleMap,
    required this.parseIssues,
  });

  factory _Manifest.fromJson(Map<String, dynamic> json) {
    final concepts = _mapList(json['concepts']).map(Concept.fromJson).toList();
    final links = _mapList(
      json['contentLinks'],
    ).map(ContentLink.fromJson).toList();
    final issues = <String>[];
    for (final concept in concepts) {
      if (concept.invalidKindCode != null) {
        issues.add(
          ['invalid', 'concept', 'kind', concept.invalidKindCode!].join(' '),
        );
      }
    }
    for (final link in links) {
      if (link.invalidContentKindCode != null) {
        issues.add(
          [
            'invalid',
            'content',
            'kind',
            link.invalidContentKindCode!,
          ].join(' '),
        );
      }
      if (link.invalidRoleCode != null) {
        issues.add(
          [
            'invalid',
            'content',
            'link',
            'role',
            link.invalidRoleCode!,
          ].join(' '),
        );
      }
    }
    if (_mapList(json['scenarioContexts']).isNotEmpty) {
      issues.add('scenarioContexts must live in scenarios.json');
    }
    return _Manifest(
      courseUnits: _mapList(
        json['courseUnits'],
      ).map(CourseUnit.fromJson).toList(),
      concepts: concepts,
      surfaceForms: _mapList(
        json['surfaceForms'],
      ).map(SurfaceForm.fromJson).toList(),
      formFamilies: _mapList(
        json['formFamilies'],
      ).map(FormFamily.fromJson).toList(),
      explicitLinks: links,
      vocabPackUnitMap: _normalizedMap(json['vocabPackUnitMap']),
      smalltalkCategoryUnitMap: _contentRules(json['smalltalkCategoryUnitMap']),
      smalltalkCheckpointPhraseMap: _contentRules(
        json['smalltalkCheckpointPhraseMap'],
      ),
      clozeTopicUnitMap: _normalizedMap(json['clozeTopicUnitMap']),
      grammarRuleMap: _contentRules(json['grammarRuleMap']),
      parseIssues: issues,
    );
  }
}

class _ContentRule {
  final String courseUnitId;
  final List<String> conceptIds;
  final bool declaresConceptIds;

  const _ContentRule({
    required this.courseUnitId,
    this.conceptIds = const [],
    this.declaresConceptIds = false,
  });

  factory _ContentRule.fromRaw(dynamic raw) {
    if (raw is String) return _ContentRule(courseUnitId: raw.trim());
    if (raw is Map) {
      return _ContentRule(
        courseUnitId: raw['courseUnitId']?.toString().trim() ?? '',
        conceptIds: _stringList(raw['conceptIds']),
        declaresConceptIds: true,
      );
    }
    return const _ContentRule(courseUnitId: '');
  }
}

class _LinkBuild {
  final List<ContentLink> links = <ContentLink>[];
  final List<String> issues = <String>[];
}

_LinkBuild _buildLinks({
  required _Manifest manifest,
  required List<Vocab> vocab,
  required List<Grammar> grammar,
  required List<SmalltalkPhrase> smalltalk,
  required List<ClozeItem> cloze,
  required List<SatzSentence> satz,
  required List<Scenario> scenarios,
}) {
  final result = _LinkBuild()..links.addAll(manifest.explicitLinks);
  final units = {for (final unit in manifest.courseUnits) unit.id: unit};
  final unitsByRequiredConcept = <String, List<CourseUnit>>{};
  for (final unit in manifest.courseUnits) {
    for (final conceptId in unit.requiredConceptIds) {
      unitsByRequiredConcept
          .putIfAbsent(conceptId, () => <CourseUnit>[])
          .add(unit);
    }
  }

  void addMapped({
    required CurriculumContentKind kind,
    required String contentId,
    required String? courseUnitId,
    required String ruleLabel,
    required ContentLinkRole role,
    List<String> conceptIds = const [],
  }) {
    final unit = courseUnitId == null ? null : units[courseUnitId];
    if (unit == null) {
      result.issues.add(
        ['missing', ruleLabel, 'mapping', 'for', contentId].join(' '),
      );
      return;
    }
    final concepts = conceptIds.isEmpty ? unit.requiredConceptIds : conceptIds;
    if (concepts.isEmpty) {
      result.issues.add(
        [
          'empty',
          'semantic',
          'concepts',
          'for',
          ruleLabel,
          contentId,
        ].join(' '),
      );
      return;
    }
    final link = ContentLink(
      contentKind: kind,
      contentId: contentId,
      courseUnitId: unit.id,
      conceptIds: concepts,
      role: role,
    );
    // A scenario can be both its source mission's practice and a later
    // mission's checkpoint. Avoid manufacturing a duplicate when those two
    // semantic declarations happen to be identical.
    if (!result.links.any((existing) => existing.id == link.id)) {
      result.links.add(link);
    }
  }

  for (final item in vocab) {
    final pack = _packBase(item.packId);
    final unitId = manifest.vocabPackUnitMap[pack];
    addMapped(
      kind: CurriculumContentKind.vocab,
      contentId: item.id,
      courseUnitId: unitId,
      ruleLabel: ['vocab', 'pack', pack].join(' '),
      role: _roleForUnit(units[unitId]),
    );
  }
  for (final item in grammar) {
    final rule = manifest.grammarRuleMap[item.id];
    addMapped(
      kind: CurriculumContentKind.grammar,
      contentId: item.id,
      courseUnitId: rule?.courseUnitId,
      ruleLabel: ['grammar', 'rule', item.id].join(' '),
      // A grammar card contributes course evidence only through its explicit
      // checkpoint question. Keeping these edges as `assess` lets the mastery
      // service reject a passive library visit or a forged practice context.
      role: ContentLinkRole.assess,
      conceptIds: rule?.conceptIds ?? const [],
    );
  }
  for (final item in smalltalk) {
    final key = _semanticKey(item.level, item.category);
    final rule = manifest.smalltalkCategoryUnitMap[key];
    addMapped(
      kind: CurriculumContentKind.smalltalk,
      contentId: item.id,
      courseUnitId: rule?.courseUnitId,
      ruleLabel: ['smalltalk', 'category', key].join(' '),
      role: ContentLinkRole.practice,
      conceptIds: rule?.conceptIds ?? const [],
    );
    final checkpointRule = manifest.smalltalkCheckpointPhraseMap[item.id];
    if (checkpointRule != null) {
      // Category links keep the legacy discussion/topic browse scope. Only
      // manually reviewed phrases with a relationship/style question that
      // directly measures a speech-style concept become assessment edges.
      addMapped(
        kind: CurriculumContentKind.smalltalk,
        contentId: item.id,
        courseUnitId: checkpointRule.courseUnitId,
        ruleLabel: ['smalltalk', 'checkpoint', 'phrase', item.id].join(' '),
        role: ContentLinkRole.assess,
        conceptIds: checkpointRule.conceptIds,
      );
    }
  }
  for (final item in cloze) {
    final key = _semanticKey(item.level, item.topic);
    final unitId = manifest.clozeTopicUnitMap[key];
    addMapped(
      kind: CurriculumContentKind.cloze,
      contentId: item.id,
      courseUnitId: unitId,
      ruleLabel: ['cloze', 'topic', key].join(' '),
      role: ContentLinkRole.practice,
    );
  }

  final vocabBySource = <String, List<Vocab>>{};
  for (final item in vocab) {
    vocabBySource
        .putIfAbsent(_semanticKey(item.level, item.korean), () => <Vocab>[])
        .add(item);
  }
  for (final item in satz) {
    final source =
        vocabBySource[_semanticKey(item.level, item.vocabKo)] ??
        const <Vocab>[];
    if (source.length != 1) {
      result.issues.add(
        [
          source.isEmpty ? 'missing' : 'ambiguous',
          'source',
          'vocab',
          'for',
          'satz',
          item.id,
        ].join(' '),
      );
      continue;
    }
    final pack = _packBase(source.single.packId);
    final unitId = manifest.vocabPackUnitMap[pack];
    addMapped(
      kind: CurriculumContentKind.satz,
      contentId: item.id,
      courseUnitId: unitId,
      ruleLabel: ['satz', 'source', 'vocab', 'pack', pack].join(' '),
      role: ContentLinkRole.practice,
    );
  }
  for (final item in scenarios) {
    final unitId = item.courseUnitId.trim();
    addMapped(
      kind: CurriculumContentKind.scenario,
      contentId: item.id,
      courseUnitId: unitId,
      ruleLabel: ['scenario', 'context', item.id].join(' '),
      role: _roleForUnit(units[unitId], scenario: true),
      conceptIds: item.conceptIds,
    );
    // Only pilot quests that declare a concrete concept become answer-level
    // evidence. The rest of the legacy scenarios still contribute their
    // aggregate checkpoint, rather than falsely fanning one answer out to
    // every concept in the scenario.
    for (final quest in item.quests) {
      if (!quest.hasExplicitId || quest.conceptIds.isEmpty) continue;
      for (final conceptId in quest.conceptIds) {
        final targets =
            unitsByRequiredConcept[conceptId] ?? const <CourseUnit>[];
        if (targets.isEmpty) {
          result.issues.add(
            [
              'missing',
              'quest',
              'concept',
              conceptId,
              'for',
              quest.id,
            ].join(' '),
          );
          continue;
        }
        for (final target in targets) {
          addMapped(
            kind: CurriculumContentKind.scenario,
            contentId: item.id,
            courseUnitId: target.id,
            ruleLabel: ['scenario', 'quest', quest.id].join(' '),
            role: ContentLinkRole.practice,
            conceptIds: [conceptId],
          );
        }
      }
    }
  }
  // Checkpoints are intentional graph edges, not a UI-only list. A scenario
  // may be reused by several later missions (for example, first meetings are
  // revisited for titles and register). Add one assess edge per declared
  // checkpoint so its result can unlock exactly that mission; its required
  // concepts define the evidence scope at that point in the course.
  for (final unit in manifest.courseUnits) {
    for (final checkpoint in unit.checkpointContentIds) {
      final pieces = checkpoint.split(':');
      if (pieces.length != 2 ||
          pieces.first != CurriculumContentKind.scenario.code ||
          pieces.last.trim().isEmpty) {
        result.issues.add(
          ['invalid', 'scenario', 'checkpoint', checkpoint].join(' '),
        );
        continue;
      }
      addMapped(
        kind: CurriculumContentKind.scenario,
        contentId: pieces.last,
        courseUnitId: unit.id,
        ruleLabel: ['scenario', 'checkpoint', unit.id].join(' '),
        role: ContentLinkRole.assess,
        conceptIds: unit.requiredConceptIds,
      );
    }
  }
  return result;
}

ContentLinkRole _roleForUnit(CourseUnit? unit, {bool scenario = false}) {
  if (scenario && unit?.isPilot == true) return ContentLinkRole.assess;
  return unit?.isPilot == true
      ? ContentLinkRole.introduce
      : ContentLinkRole.practice;
}

ScenarioContext _contextForScenario(Scenario scenario) => ScenarioContext(
  scenarioId: scenario.id,
  courseUnitId: scenario.courseUnitId,
  relationshipContext: scenario.relationshipContext,
  intent: scenario.intent,
  speechStyle:
      scenario.speechStyle ?? _speechStyleForRegister(scenario.register),
  conceptIds: scenario.conceptIds,
  invalidSpeechStyleCode: scenario.speechStyle == null ? 'missing' : null,
);

SpeechStyle _speechStyleForRegister(Register register) {
  switch (register) {
    case Register.polite:
      return SpeechStyle.polite;
    case Register.casual:
      return SpeechStyle.casual;
    case Register.business:
      return SpeechStyle.business;
    case Register.intimate:
      return SpeechStyle.intimate;
  }
}

List<String> _validateDefinitions(
  _Manifest manifest,
  Iterable<ContentLink> links,
) {
  final issues = <String>[...manifest.parseIssues];
  final unitIds = manifest.courseUnits.map((item) => item.id).toSet();
  final units = {for (final unit in manifest.courseUnits) unit.id: unit};
  final conceptIds = manifest.concepts.map((item) => item.id).toSet();
  final conceptsById = {
    for (final concept in manifest.concepts) concept.id: concept,
  };
  final surfaceIds = manifest.surfaceForms.map((item) => item.id).toSet();

  void unique(String label, Iterable<String> ids) {
    final values = ids.toList();
    if (values.any((id) => id.trim().isEmpty)) {
      issues.add(['empty', label, 'ID'].join(' '));
    }
    if (values.toSet().length != values.length) {
      issues.add(['duplicate', label, 'IDs'].join(' '));
    }
  }

  unique('course unit', manifest.courseUnits.map((item) => item.id));
  unique('concept', manifest.concepts.map((item) => item.id));
  unique('surface form', manifest.surfaceForms.map((item) => item.id));
  unique('form family', manifest.formFamilies.map((item) => item.id));
  unique('content link', links.map((item) => item.id));

  for (final unit in manifest.courseUnits) {
    if (!_validLevel(unit.level)) {
      issues.add(['invalid', 'unit', 'level', unit.id].join(' '));
    }
    for (final prerequisite in unit.prerequisiteUnitIds) {
      if (!unitIds.contains(prerequisite)) {
        issues.add(['missing', 'prerequisite', prerequisite].join(' '));
      }
    }
    for (final conceptId in unit.requiredConceptIds) {
      if (!conceptIds.contains(conceptId)) {
        issues.add(['missing', 'unit', 'concept', conceptId].join(' '));
      }
    }
    if (unit.passThreshold < 0 || unit.passThreshold > 1) {
      issues.add(['invalid', 'pass', 'threshold', unit.id].join(' '));
    }
  }
  for (final surface in manifest.surfaceForms) {
    for (final conceptId in surface.conceptIds) {
      if (!conceptIds.contains(conceptId)) {
        issues.add(['missing', 'surface', 'concept', conceptId].join(' '));
      }
    }
  }
  for (final family in manifest.formFamilies) {
    for (final conceptId in family.conceptIds) {
      if (!conceptIds.contains(conceptId)) {
        issues.add(['missing', 'family', 'concept', conceptId].join(' '));
      }
    }
    for (final surfaceId in family.surfaceFormIds) {
      if (!surfaceIds.contains(surfaceId)) {
        issues.add(['missing', 'family', 'surface', surfaceId].join(' '));
      }
    }
  }
  void validateMap(Map<String, String> map, String label) {
    for (final entry in map.entries) {
      if (!unitIds.contains(entry.value)) {
        issues.add(['missing', label, 'map', 'unit', entry.key].join(' '));
      }
    }
  }

  void validateContentRules(
    Map<String, _ContentRule> rules,
    String label, {
    bool requireSpeechStyle = false,
    bool requireSingleConcept = false,
  }) {
    for (final entry in rules.entries) {
      final unit = units[entry.value.courseUnitId];
      if (unit == null) {
        issues.add(['missing', label, 'map', 'unit', entry.key].join(' '));
        continue;
      }
      if (entry.value.declaresConceptIds && entry.value.conceptIds.isEmpty) {
        issues.add(['empty', label, 'map', 'concepts', entry.key].join(' '));
      }
      if (requireSingleConcept && entry.value.conceptIds.length != 1) {
        issues.add(['invalid', label, 'map', 'concepts', entry.key].join(' '));
      }
      for (final conceptId in entry.value.conceptIds) {
        if (!conceptIds.contains(conceptId)) {
          issues.add(['missing', label, 'map', 'concept', conceptId].join(' '));
        } else if (!unit.requiredConceptIds.contains(conceptId)) {
          issues.add(
            ['unrelated', label, 'map', 'concept', conceptId].join(' '),
          );
        } else if (requireSpeechStyle &&
            conceptsById[conceptId]?.kind != ConceptKind.speechStyle) {
          issues.add(
            ['invalid', label, 'map', 'concept-kind', conceptId].join(' '),
          );
        }
      }
    }
  }

  validateMap(manifest.vocabPackUnitMap, 'vocab');
  validateContentRules(manifest.smalltalkCategoryUnitMap, 'smalltalk');
  validateContentRules(
    manifest.smalltalkCheckpointPhraseMap,
    'smalltalk checkpoint phrase',
    requireSpeechStyle: true,
    requireSingleConcept: true,
  );
  validateMap(manifest.clozeTopicUnitMap, 'cloze');
  validateContentRules(manifest.grammarRuleMap, 'grammar');
  for (final link in links) {
    if (!unitIds.contains(link.courseUnitId)) {
      issues.add(['missing', 'link', 'unit', link.contentKey].join(' '));
    }
    if (link.conceptIds.isEmpty) {
      issues.add(['empty', 'link', 'concepts', link.contentKey].join(' '));
    }
    for (final conceptId in link.conceptIds) {
      if (!conceptIds.contains(conceptId)) {
        issues.add(['missing', 'link', 'concept', conceptId].join(' '));
      }
    }
  }

  // Grammar and small-talk screens have generic checkpoint widgets. Their
  // answer can only be trusted when each assessed source item maps to exactly
  // one concept in that mission. Do not leave a future duplicate edge to be
  // resolved by UI ordering or an arbitrary caller-supplied concept ID.
  final assessmentGroups = <String, List<ContentLink>>{};
  for (final link in links) {
    if ((link.contentKind != CurriculumContentKind.grammar &&
            link.contentKind != CurriculumContentKind.smalltalk) ||
        link.role != ContentLinkRole.assess) {
      continue;
    }
    final key = [link.courseUnitId, link.contentKey].join(' ');
    assessmentGroups.putIfAbsent(key, () => <ContentLink>[]).add(link);
  }
  for (final entry in assessmentGroups.entries) {
    if (entry.value.length != 1 || entry.value.single.conceptIds.length != 1) {
      issues.add(['ambiguous', 'checkpoint', 'link', entry.key].join(' '));
    }
  }
  for (final link in links.where(
    (link) =>
        link.contentKind == CurriculumContentKind.smalltalk &&
        link.role == ContentLinkRole.assess,
  )) {
    final concept = link.conceptIds.length == 1
        ? conceptsById[link.conceptIds.single]
        : null;
    if (concept?.kind != ConceptKind.speechStyle) {
      issues.add(
        [
          'invalid',
          'smalltalk',
          'checkpoint',
          'concept-kind',
          link.contentKey,
        ].join(' '),
      );
    }
  }
  return issues;
}

List<String> _validateContent({
  required _Manifest manifest,
  required List<ContentLink> links,
  required List<Vocab> vocab,
  required List<Grammar> grammar,
  required List<SmalltalkPhrase> smalltalk,
  required List<ClozeItem> cloze,
  required List<SatzSentence> satz,
  required List<Scenario> scenarios,
  required List<ScenarioContext> scenarioContexts,
}) {
  final issues = <String>[];
  final known = <CurriculumContentKind, Set<String>>{
    CurriculumContentKind.vocab: vocab.map((item) => item.id).toSet(),
    CurriculumContentKind.grammar: grammar.map((item) => item.id).toSet(),
    CurriculumContentKind.smalltalk: smalltalk.map((item) => item.id).toSet(),
    CurriculumContentKind.cloze: cloze.map((item) => item.id).toSet(),
    CurriculumContentKind.satz: satz.map((item) => item.id).toSet(),
    CurriculumContentKind.scenario: scenarios.map((item) => item.id).toSet(),
  };
  final byContent = _groupByContentKey(links);
  for (final entry in known.entries) {
    for (final id in entry.value) {
      if (!byContent.containsKey(_contentKey(entry.key, id))) {
        issues.add(['orphan', entry.key.code, id].join(' '));
      }
    }
  }
  for (final link in links) {
    if (!(known[link.contentKind] ?? const <String>{}).contains(
      link.contentId,
    )) {
      issues.add(['unknown', 'content', link.contentKey].join(' '));
    }
  }

  _uniqueRawIds('vocab', vocab.map((item) => item.id), issues);
  _uniqueRawIds('grammar', grammar.map((item) => item.id), issues);
  _uniqueRawIds('smalltalk', smalltalk.map((item) => item.id), issues);
  _uniqueRawIds('cloze', cloze.map((item) => item.id), issues);
  _uniqueRawIds('satz', satz.map((item) => item.id), issues);
  _uniqueRawIds('scenario', scenarios.map((item) => item.id), issues);
  _uniqueRawIds(
    'declared quest',
    scenarios
        .expand((scenario) => scenario.quests)
        .where((quest) => quest.hasExplicitId)
        .map((quest) => quest.id),
    issues,
  );

  void requireExplicitId(String kind, bool hasExplicitId, String label) {
    if (!hasExplicitId) {
      issues.add([kind, 'requires', 'explicit', 'ID', label].join(' '));
    }
  }

  for (final item in vocab) {
    requireExplicitId('vocab', item.hasExplicitId, item.korean);
  }
  for (final item in grammar) {
    requireExplicitId('grammar', item.hasExplicitId, item.pattern);
  }
  for (final item in smalltalk) {
    requireExplicitId('smalltalk', item.hasExplicitId, item.ko);
  }
  for (final item in cloze) {
    requireExplicitId('cloze', item.hasExplicitId, item.fullKo);
  }
  for (final item in satz) {
    requireExplicitId('satz', item.hasExplicitId, item.targetKo);
  }
  for (final item in scenarios) {
    requireExplicitId('scenario', item.hasExplicitId, item.id);
  }

  final grammarIds = known[CurriculumContentKind.grammar] ?? const <String>{};
  final smalltalkIds =
      known[CurriculumContentKind.smalltalk] ?? const <String>{};
  for (final item in grammar) {
    if (!manifest.grammarRuleMap.containsKey(item.id)) {
      issues.add(['missing', 'grammar', 'rule', item.id].join(' '));
    }
  }
  for (final id in manifest.grammarRuleMap.keys) {
    if (!grammarIds.contains(id)) {
      issues.add(['unknown', 'grammar', 'rule', id].join(' '));
    }
  }
  final smalltalkById = {for (final item in smalltalk) item.id: item};
  final unitsById = {for (final unit in manifest.courseUnits) unit.id: unit};
  for (final entry in manifest.smalltalkCheckpointPhraseMap.entries) {
    final phrase = smalltalkById[entry.key];
    if (phrase == null || !smalltalkIds.contains(entry.key)) {
      issues.add(
        ['unknown', 'smalltalk', 'checkpoint', 'phrase', entry.key].join(' '),
      );
      continue;
    }
    final unit = unitsById[entry.value.courseUnitId];
    if (unit != null &&
        phrase.level.trim().toLowerCase() != unit.level.trim().toLowerCase()) {
      issues.add(
        ['unrelated', 'smalltalk', 'checkpoint', 'level', entry.key].join(' '),
      );
    }
  }

  void validateSemanticKeys(
    Set<String> actual,
    Iterable<String> mappedKeys,
    String label,
  ) {
    final mapped = mappedKeys.toSet();
    for (final key in actual) {
      if (!mapped.contains(key)) {
        issues.add(['missing', label, 'map', key].join(' '));
      }
    }
    for (final key in mapped) {
      if (!actual.contains(key)) {
        issues.add(['unknown', label, 'map', key].join(' '));
      }
    }
  }

  validateSemanticKeys(
    smalltalk.map((item) => _semanticKey(item.level, item.category)).toSet(),
    manifest.smalltalkCategoryUnitMap.keys,
    'smalltalk category',
  );
  validateSemanticKeys(
    cloze.map((item) => _semanticKey(item.level, item.topic)).toSet(),
    manifest.clozeTopicUnitMap.keys,
    'cloze topic',
  );
  validateSemanticKeys(
    vocab.map((item) => _packBase(item.packId)).toSet(),
    manifest.vocabPackUnitMap.keys,
    'vocab pack',
  );

  final unitIds = manifest.courseUnits.map((item) => item.id).toSet();
  final conceptIds = manifest.concepts.map((item) => item.id).toSet();
  final surfaceIds = manifest.surfaceForms.map((item) => item.id).toSet();
  final contexts = {for (final item in scenarioContexts) item.scenarioId: item};
  for (final scenario in scenarios) {
    if (!unitIds.contains(scenario.courseUnitId)) {
      issues.add(
        ['missing', 'scenario', 'unit', scenario.courseUnitId].join(' '),
      );
    }
    if (scenario.relationshipContext.trim().isEmpty ||
        scenario.intent.trim().isEmpty ||
        scenario.speechStyle == null) {
      issues.add(['incomplete', 'scenario', 'context', scenario.id].join(' '));
    }
    if (contexts[scenario.id] == null) {
      issues.add(['missing', 'scenario', 'context', scenario.id].join(' '));
    }
    if (scenario.grammarIds.isEmpty) {
      issues.add(['empty', 'scenario', 'grammar', scenario.id].join(' '));
    }
    for (final grammarId in scenario.grammarIds) {
      if (!grammarIds.contains(grammarId)) {
        issues.add(['unknown', 'scenario', 'grammar', grammarId].join(' '));
      }
    }
    for (final conceptId in scenario.conceptIds) {
      if (!conceptIds.contains(conceptId)) {
        issues.add(['missing', 'scenario', 'concept', conceptId].join(' '));
      }
    }
    for (final quest in scenario.quests) {
      if (quest.conceptIds.isNotEmpty && !quest.hasExplicitId) {
        issues.add(
          ['quest', 'concepts', 'require', 'ID', scenario.id].join(' '),
        );
      }
      for (final conceptId in quest.conceptIds) {
        if (!conceptIds.contains(conceptId)) {
          issues.add(['missing', 'quest', 'concept', conceptId].join(' '));
        }
      }
    }
    for (final surfaceId in scenario.surfaceFormIds) {
      if (!surfaceIds.contains(surfaceId)) {
        issues.add(['missing', 'scenario', 'surface', surfaceId].join(' '));
      }
    }
    for (final reference in scenario.vocab) {
      if (reference.korean.trim().isEmpty) {
        issues.add(['empty', 'scenario', 'vocab', scenario.id].join(' '));
      }
    }
  }

  for (final unit in manifest.courseUnits) {
    for (final checkpoint in unit.checkpointContentIds) {
      if (!byContent.containsKey(checkpoint)) {
        issues.add(
          ['missing', 'checkpoint', checkpoint, 'for', unit.id].join(' '),
        );
      }
    }
  }
  return issues;
}

void _uniqueRawIds(String label, Iterable<String> ids, List<String> issues) {
  final values = ids.toList();
  if (values.any((id) => id.trim().isEmpty)) {
    issues.add(['empty', 'raw', label, 'ID'].join(' '));
  }
  if (values.toSet().length != values.length) {
    issues.add(['duplicate', 'raw', label, 'IDs'].join(' '));
  }
}

Map<String, List<ContentLink>> _groupByContentKey(Iterable<ContentLink> links) {
  final result = <String, List<ContentLink>>{};
  for (final link in links) {
    result.putIfAbsent(link.contentKey, () => <ContentLink>[]).add(link);
  }
  return {
    for (final entry in result.entries)
      entry.key: List.unmodifiable(entry.value),
  };
}

Map<String, List<ContentLink>> _groupByUnitId(Iterable<ContentLink> links) {
  final result = <String, List<ContentLink>>{};
  for (final link in links) {
    result.putIfAbsent(link.courseUnitId, () => <ContentLink>[]).add(link);
  }
  return {
    for (final entry in result.entries)
      entry.key: List.unmodifiable(entry.value),
  };
}

Map<String, _ContentRule> _contentRules(dynamic raw) {
  if (raw is! Map) return const {};
  return {
    for (final entry in raw.entries)
      entry.key.toString().trim(): _ContentRule.fromRaw(entry.value),
  };
}

Map<String, String> _normalizedMap(dynamic raw) {
  if (raw is! Map) return const {};
  return {
    for (final entry in raw.entries)
      entry.key.toString().trim().toLowerCase(): entry.value.toString().trim(),
  };
}

List<Map<String, dynamic>> _mapList(dynamic raw) =>
    (raw as List? ?? const []).whereType<Map>().map(_copyMap).toList();

Map<String, dynamic> _copyMap(Map raw) =>
    raw.map((key, value) => MapEntry(key.toString(), value));

List<String> _stringList(dynamic raw) =>
    (raw as List? ?? const []).map((value) => value.toString()).toList();

String _contentKey(CurriculumContentKind kind, String id) =>
    [kind.code, id].join(':');

String _semanticKey(String level, String value) =>
    [level.trim().toLowerCase(), value.trim().toLowerCase()].join(':');

String _packBase(String packId) {
  final parts = packId.trim().toLowerCase().split('_');
  if (parts.length > 1 && int.tryParse(parts.last) != null) {
    parts.removeLast();
  }
  return parts.join('_');
}

bool _validLevel(String value) =>
    const {'a1', 'a2', 'b1', 'b2'}.contains(value.trim().toLowerCase());

List<String> _sortedDistinct(Iterable<String> values) =>
    values.toSet().toList()..sort();
