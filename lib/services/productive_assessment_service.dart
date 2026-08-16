import 'dart:convert';
import 'dart:typed_data';

import '../models/can_do_segment.dart';
import '../models/content_id.dart';
import '../models/curriculum.dart';
import '../models/learner_level.dart';
import '../models/productive_mastery.dart';
import 'book_analysis_text.dart';
import 'course_segment_catalog.dart';
import 'pronunciation_assessment_client.dart';

enum ProductiveCriterionKind {
  meaningSlot,
  tokenSequence,
  sentenceEnding,
  exactAnswer,
  sameIdentityAcrossRegisters,
}

extension ProductiveCriterionKindX on ProductiveCriterionKind {
  String get code => name;

  static ProductiveCriterionKind? tryFromCode(String? value) {
    for (final kind in ProductiveCriterionKind.values) {
      if (kind.code == value) {
        return kind;
      }
    }
    return null;
  }
}

final class ProductiveTextCriterion {
  ProductiveTextCriterion({
    required String id,
    required this.kind,
    required Iterable<String> acceptedVariants,
    required this.weight,
    required this.requiredForPass,
  }) : id = _requiredId(id, 'criterion id'),
       acceptedVariants = List.unmodifiable(
         acceptedVariants.map(
           (value) => _requiredText(value, 'criterion accepted variant'),
         ),
       ) {
    if (this.acceptedVariants.isEmpty) {
      throw const FormatException(
        'Productive text criteria require an accepted variant.',
      );
    }
    if (!weight.isFinite || weight <= 0) {
      throw const FormatException(
        'Productive text criterion weight must be positive.',
      );
    }
  }

  factory ProductiveTextCriterion.fromJson(Map<String, dynamic> json) {
    final kind = ProductiveCriterionKindX.tryFromCode(json['kind']?.toString());
    final variants = json['acceptedVariants'];
    final weight = json['weight'];
    final requiredForPass = json['requiredForPass'];
    if (kind == null ||
        variants is! List ||
        weight is! num ||
        requiredForPass is! bool) {
      throw const FormatException('Invalid productive text criterion.');
    }
    return ProductiveTextCriterion(
      id: json['id']?.toString() ?? '',
      kind: kind,
      acceptedVariants: variants.map((value) => value.toString()),
      weight: weight.toDouble(),
      requiredForPass: requiredForPass,
    );
  }

  final String id;
  final ProductiveCriterionKind kind;
  final List<String> acceptedVariants;
  final double weight;
  final bool requiredForPass;
}

final class ProductiveTextRubric {
  ProductiveTextRubric({
    required Iterable<ProductiveTextCriterion> criteria,
    this.minInputCodePoints = 1,
    this.maxInputCodePoints = 240,
    Iterable<String> requiredStructuredSlotIds = const [],
    this.minimumDistinctSourceSpanIds = 0,
    Iterable<String> requiredSourceSnippetIds = const [],
    Iterable<Iterable<String>> oneOfSourceGroups = const [],
    Iterable<Iterable<String>> discourseMarkerGroups = const [],
  }) : criteria = List.unmodifiable(criteria),
       requiredStructuredSlotIds = List.unmodifiable(
         requiredStructuredSlotIds.map(
           (value) => _requiredId(value, 'structured writing slot ID'),
         ),
       ),
       requiredSourceSnippetIds = Set<String>.unmodifiable(
         requiredSourceSnippetIds.map(
           (value) => _requiredId(value, 'required writing source ID'),
         ),
       ),
       oneOfSourceGroups = List<Set<String>>.unmodifiable(
         oneOfSourceGroups.map(
           (group) => Set<String>.unmodifiable(
             group.map(
               (value) => _requiredId(value, 'writing one-of source ID'),
             ),
           ),
         ),
       ),
       discourseMarkerGroups = List<List<String>>.unmodifiable(
         discourseMarkerGroups.map(
           (group) => List<String>.unmodifiable(
             group.map((value) => _requiredText(value, 'discourse marker')),
           ),
         ),
       ) {
    if (this.criteria.isEmpty ||
        minInputCodePoints <= 0 ||
        maxInputCodePoints < minInputCodePoints) {
      throw const FormatException('Invalid productive text rubric.');
    }
    _requireUnique(this.criteria.map((criterion) => criterion.id), 'criterion');
    _requireUnique(this.requiredStructuredSlotIds, 'structured writing slot');
    if (minimumDistinctSourceSpanIds < 0 ||
        this.oneOfSourceGroups.any((group) => group.isEmpty) ||
        this.discourseMarkerGroups.any((group) => group.isEmpty)) {
      throw const FormatException('Invalid structured writing rubric.');
    }
  }

  factory ProductiveTextRubric.fromJson(Map<String, dynamic> json) {
    final rawCriteria = json['criteria'];
    final rawMinimum = json['minInputCodePoints'];
    final rawMaximum = json['maxInputCodePoints'];
    final rawSlots = json['requiredStructuredSlotIds'];
    final rawMinimumSources = json['minimumDistinctSourceSpanIds'];
    final rawRequiredSources = json['requiredSourceSnippetIds'];
    final rawOneOfSourceGroups = json['oneOfSourceGroups'];
    final rawMarkerGroups = json['discourseMarkerGroups'];
    if (rawCriteria is! List ||
        rawMinimum is! num ||
        rawMaximum is! num ||
        rawSlots is! List ||
        rawMinimumSources is! num ||
        rawRequiredSources is! List ||
        rawOneOfSourceGroups is! List ||
        rawMarkerGroups is! List) {
      throw const FormatException('Invalid productive text rubric.');
    }
    return ProductiveTextRubric(
      minInputCodePoints: rawMinimum.toInt(),
      maxInputCodePoints: rawMaximum.toInt(),
      requiredStructuredSlotIds: rawSlots.map((value) => value.toString()),
      minimumDistinctSourceSpanIds: rawMinimumSources.toInt(),
      requiredSourceSnippetIds: rawRequiredSources.map(
        (value) => value.toString(),
      ),
      oneOfSourceGroups: rawOneOfSourceGroups.map((rawGroup) {
        if (rawGroup is! List) {
          throw const FormatException(
            'Writing one-of source group must be a list.',
          );
        }
        return rawGroup.map((value) => value.toString());
      }),
      discourseMarkerGroups: rawMarkerGroups.map((rawGroup) {
        if (rawGroup is! List) {
          throw const FormatException('Discourse marker group must be a list.');
        }
        return rawGroup.map((value) => value.toString());
      }),
      criteria: rawCriteria.map(
        (value) => ProductiveTextCriterion.fromJson(
          _stringMap(value, 'productive text criterion'),
        ),
      ),
    );
  }

  final List<ProductiveTextCriterion> criteria;
  final int minInputCodePoints;
  final int maxInputCodePoints;
  final List<String> requiredStructuredSlotIds;
  final int minimumDistinctSourceSpanIds;
  final Set<String> requiredSourceSnippetIds;
  final List<Set<String>> oneOfSourceGroups;
  final List<List<String>> discourseMarkerGroups;

  bool get requiresStructuredSubmission =>
      requiredStructuredSlotIds.isNotEmpty ||
      minimumDistinctSourceSpanIds > 0 ||
      requiredSourceSnippetIds.isNotEmpty ||
      oneOfSourceGroups.isNotEmpty ||
      discourseMarkerGroups.isNotEmpty;
}

enum ProductiveEvidenceRole {
  support,
  contrast,
  limitation,
  complement,
  context,
  stakeholderPerspective,
  counterexample,
}

extension ProductiveEvidenceRoleX on ProductiveEvidenceRole {
  String get code => name;

  static ProductiveEvidenceRole? tryFromCode(String? value) {
    for (final role in ProductiveEvidenceRole.values) {
      if (role.code == value) {
        return role;
      }
    }
    return null;
  }
}

final class ProductiveEvidenceRelationshipRequirement {
  ProductiveEvidenceRelationshipRequirement({
    required String id,
    required this.role,
    required Iterable<String> oneOfSourceSnippetIds,
  }) : id = _requiredId(id, 'evidence relationship ID'),
       oneOfSourceSnippetIds = Set.unmodifiable(
         oneOfSourceSnippetIds.map(
           (value) => _requiredId(value, 'relationship source snippet ID'),
         ),
       ) {
    if (this.oneOfSourceSnippetIds.isEmpty) {
      throw const FormatException(
        'Evidence relationship requires an authored source answer key.',
      );
    }
  }

  factory ProductiveEvidenceRelationshipRequirement.fromJson(
    Map<String, dynamic> json,
  ) {
    final role = ProductiveEvidenceRoleX.tryFromCode(json['role']?.toString());
    final rawSources = json['oneOfSourceSnippetIds'];
    if (role == null || rawSources is! List) {
      throw const FormatException('Invalid evidence relationship answer key.');
    }
    return ProductiveEvidenceRelationshipRequirement(
      id: json['id']?.toString() ?? '',
      role: role,
      oneOfSourceSnippetIds: rawSources.map((value) => value.toString()),
    );
  }

  final String id;
  final ProductiveEvidenceRole role;
  final Set<String> oneOfSourceSnippetIds;
}

final class ProductiveConnectedEvidenceRubric {
  ProductiveConnectedEvidenceRubric({
    this.minimumSourceNodes = 2,
    required Iterable<ProductiveEvidenceRole> requiredRoles,
    Iterable<String> requiredSourceSnippetIds = const [],
    Iterable<Iterable<String>> oneOfSourceGroups = const [],
    required Iterable<ProductiveEvidenceRelationshipRequirement>
    relationshipRequirements,
    this.requireProvenance = true,
  }) : requiredRoles = Set.unmodifiable(requiredRoles),
       requiredSourceSnippetIds = Set.unmodifiable(
         requiredSourceSnippetIds.map(
           (value) => _requiredId(value, 'required source snippet ID'),
         ),
       ),
       oneOfSourceGroups = List<Set<String>>.unmodifiable(
         oneOfSourceGroups.map(
           (group) => Set<String>.unmodifiable(
             group.map(
               (value) => _requiredId(value, 'one-of source snippet ID'),
             ),
           ),
         ),
       ),
       relationshipRequirements = List.unmodifiable(relationshipRequirements) {
    if (minimumSourceNodes < 2 ||
        this.requiredRoles.isEmpty ||
        this.relationshipRequirements.isEmpty ||
        this.oneOfSourceGroups.any((group) => group.isEmpty)) {
      throw const FormatException('Invalid connected-evidence rubric.');
    }
    _requireUnique(
      this.relationshipRequirements.map((requirement) => requirement.id),
      'evidence relationship',
    );
  }

  factory ProductiveConnectedEvidenceRubric.fromJson(
    Map<String, dynamic> json,
  ) {
    final rawMinimum = json['minimumSourceNodes'];
    final rawRoles = json['requiredRoles'];
    final rawRequiredSources = json['requiredSourceSnippetIds'];
    final rawOneOfGroups = json['oneOfSourceGroups'];
    final rawRelationships = json['relationshipRequirements'];
    final rawProvenance = json['requireProvenance'];
    if (rawMinimum is! num ||
        rawRoles is! List ||
        rawRequiredSources is! List ||
        rawOneOfGroups is! List ||
        rawRelationships is! List ||
        rawProvenance is! bool) {
      throw const FormatException('Invalid connected-evidence rubric.');
    }
    final roles = <ProductiveEvidenceRole>[];
    for (final rawRole in rawRoles) {
      final role = ProductiveEvidenceRoleX.tryFromCode(rawRole.toString());
      if (role == null) {
        throw const FormatException('Unknown connected-evidence role.');
      }
      roles.add(role);
    }
    return ProductiveConnectedEvidenceRubric(
      minimumSourceNodes: rawMinimum.toInt(),
      requiredRoles: roles,
      requiredSourceSnippetIds: rawRequiredSources.map(
        (value) => value.toString(),
      ),
      oneOfSourceGroups: rawOneOfGroups.map((rawGroup) {
        if (rawGroup is! List) {
          throw const FormatException(
            'Connected-evidence one-of group must be a list.',
          );
        }
        return rawGroup.map((value) => value.toString());
      }),
      relationshipRequirements: rawRelationships.map(
        (value) => ProductiveEvidenceRelationshipRequirement.fromJson(
          _stringMap(value, 'evidence relationship requirement'),
        ),
      ),
      requireProvenance: rawProvenance,
    );
  }

  final int minimumSourceNodes;
  final Set<ProductiveEvidenceRole> requiredRoles;
  final Set<String> requiredSourceSnippetIds;
  final List<Set<String>> oneOfSourceGroups;
  final List<ProductiveEvidenceRelationshipRequirement>
  relationshipRequirements;
  final bool requireProvenance;
}

final class ProductiveOralRubric {
  ProductiveOralRubric({
    required this.minimumPronunciation,
    required this.minimumAccuracy,
    required this.minimumFluency,
    required this.minimumDurationMilliseconds,
    required this.maximumDurationMilliseconds,
    required this.minimumTranscriptCodePoints,
    required Iterable<String> requiredSemanticSlotIds,
    required Map<String, Iterable<String>> semanticSlotMentionVariants,
    required Iterable<String> requiredSourceSnippetIds,
    required Iterable<Iterable<String>> oneOfSourceGroups,
    required Map<String, Iterable<String>> sourceMentionVariants,
    required Iterable<Iterable<String>> discourseMarkerGroups,
  }) : requiredSemanticSlotIds = List.unmodifiable(
         requiredSemanticSlotIds.map(
           (value) => _requiredId(value, 'oral semantic slot ID'),
         ),
       ),
       semanticSlotMentionVariants = Map<String, List<String>>.unmodifiable({
         for (final entry in semanticSlotMentionVariants.entries)
           _requiredId(
             entry.key,
             'oral semantic slot mention ID',
           ): List<String>.unmodifiable(
             entry.value.map(
               (value) => _requiredText(value, 'oral semantic slot mention'),
             ),
           ),
       }),
       requiredSourceSnippetIds = Set.unmodifiable(
         requiredSourceSnippetIds.map(
           (value) => _requiredId(value, 'oral source snippet ID'),
         ),
       ),
       oneOfSourceGroups = List<Set<String>>.unmodifiable(
         oneOfSourceGroups.map(
           (group) => Set<String>.unmodifiable(
             group.map((value) => _requiredId(value, 'oral one-of source ID')),
           ),
         ),
       ),
       sourceMentionVariants = Map<String, List<String>>.unmodifiable({
         for (final entry in sourceMentionVariants.entries)
           _requiredId(
             entry.key,
             'oral source mention ID',
           ): List<String>.unmodifiable(
             entry.value.map(
               (value) => _requiredText(value, 'oral source mention'),
             ),
           ),
       }),
       discourseMarkerGroups = List<List<String>>.unmodifiable(
         discourseMarkerGroups.map(
           (group) => List<String>.unmodifiable(
             group.map(
               (value) => _requiredText(value, 'oral discourse marker'),
             ),
           ),
         ),
       ) {
    _validScore(minimumPronunciation, 'minimumPronunciation');
    _validScore(minimumAccuracy, 'minimumAccuracy');
    _validScore(minimumFluency, 'minimumFluency');
    _requireUnique(this.requiredSemanticSlotIds, 'oral semantic slot');
    if (minimumDurationMilliseconds < 45000 ||
        maximumDurationMilliseconds > 120000 ||
        maximumDurationMilliseconds < minimumDurationMilliseconds ||
        minimumTranscriptCodePoints < 120 ||
        this.requiredSemanticSlotIds.length < 4 ||
        this.semanticSlotMentionVariants.values.any(
          (variants) => variants.isEmpty,
        ) ||
        this.requiredSourceSnippetIds.length < 2 ||
        this.oneOfSourceGroups.any((group) => group.isEmpty) ||
        this.sourceMentionVariants.values.any((variants) => variants.isEmpty) ||
        this.discourseMarkerGroups.length < 3 ||
        this.discourseMarkerGroups.any((group) => group.isEmpty)) {
      throw const FormatException(
        'Oral production requires a 45-120 second semantic, source-linked discourse rubric.',
      );
    }
    if (!_sameSet(
      this.semanticSlotMentionVariants.keys,
      this.requiredSemanticSlotIds,
    )) {
      throw const FormatException(
        'Oral semantic mention variants must exactly cover required semantic slots.',
      );
    }
    final mentionedSources = this.sourceMentionVariants.keys.toSet();
    final authoredSources = <String>{
      ...this.requiredSourceSnippetIds,
      for (final group in this.oneOfSourceGroups) ...group,
    };
    if (!_sameSet(mentionedSources, authoredSources)) {
      throw const FormatException(
        'Oral source mention variants must exactly cover authored source requirements.',
      );
    }
  }

  factory ProductiveOralRubric.fromJson(Map<String, dynamic> json) {
    return ProductiveOralRubric(
      minimumPronunciation: _numericScore(
        json['minimumPronunciation'],
        'minimumPronunciation',
      ),
      minimumAccuracy: _numericScore(
        json['minimumAccuracy'],
        'minimumAccuracy',
      ),
      minimumFluency: _numericScore(json['minimumFluency'], 'minimumFluency'),
      minimumDurationMilliseconds: _wholeNumber(
        json['minimumDurationMilliseconds'],
        'minimumDurationMilliseconds',
      ),
      maximumDurationMilliseconds: _wholeNumber(
        json['maximumDurationMilliseconds'],
        'maximumDurationMilliseconds',
      ),
      minimumTranscriptCodePoints: _wholeNumber(
        json['minimumTranscriptCodePoints'],
        'minimumTranscriptCodePoints',
      ),
      requiredSemanticSlotIds: _stringValues(
        json['requiredSemanticSlotIds'],
        'requiredSemanticSlotIds',
      ),
      semanticSlotMentionVariants: _stringListMap(
        json['semanticSlotMentionVariants'],
        'semanticSlotMentionVariants',
      ),
      requiredSourceSnippetIds: _stringValues(
        json['requiredSourceSnippetIds'],
        'requiredSourceSnippetIds',
      ),
      oneOfSourceGroups: _stringGroups(
        json['oneOfSourceGroups'],
        'oral oneOfSourceGroups',
      ),
      sourceMentionVariants: _stringListMap(
        json['sourceMentionVariants'],
        'sourceMentionVariants',
      ),
      discourseMarkerGroups: _stringGroups(
        json['discourseMarkerGroups'],
        'oral discourseMarkerGroups',
      ),
    );
  }

  final double minimumPronunciation;
  final double minimumAccuracy;
  final double minimumFluency;
  final int minimumDurationMilliseconds;
  final int maximumDurationMilliseconds;
  final int minimumTranscriptCodePoints;
  final List<String> requiredSemanticSlotIds;
  final Map<String, List<String>> semanticSlotMentionVariants;
  final Set<String> requiredSourceSnippetIds;
  final List<Set<String>> oneOfSourceGroups;
  final Map<String, List<String>> sourceMentionVariants;
  final List<List<String>> discourseMarkerGroups;
}

/// The authored, executable definition behind one assessment authority.
/// Recognition-only content cannot construct this type without a productive
/// rubric matching its declared evidence mode.
final class ProductiveAssessmentDefinition {
  ProductiveAssessmentDefinition({
    required String canDoSegmentId,
    required String assessmentItemId,
    required String missionContentLinkId,
    required this.level,
    required String courseUnitId,
    required Iterable<String> conceptIds,
    required this.evidenceMode,
    required this.rubricVersion,
    required this.minimumScore,
    required CurriculumText prompt,
    required CurriculumText roleInstruction,
    Iterable<String> prerequisiteAssessmentItemIds = const [],
    Iterable<String> grammarReferenceIds = const [],
    Iterable<String> authoredContextExamples = const [],
    this.textRubric,
    this.connectedEvidenceRubric,
    this.oralRubric,
  }) : canDoSegmentId = _requiredId(canDoSegmentId, 'canDoSegmentId'),
       assessmentItemId = _requiredId(assessmentItemId, 'assessmentItemId'),
       missionContentLinkId = _requiredId(
         missionContentLinkId,
         'missionContentLinkId',
       ),
       courseUnitId = _requiredId(courseUnitId, 'courseUnitId'),
       conceptIds = List.unmodifiable(
         conceptIds.map((value) => _requiredId(value, 'conceptId')),
       ),
       prerequisiteAssessmentItemIds = List.unmodifiable(
         prerequisiteAssessmentItemIds.map(
           (value) => _requiredId(value, 'prerequisite assessment ID'),
         ),
       ),
       grammarReferenceIds = List.unmodifiable(
         grammarReferenceIds.map(
           (value) => _requiredId(value, 'grammar reference ID'),
         ),
       ),
       authoredContextExamples = List.unmodifiable(
         authoredContextExamples.map(
           (value) => _requiredText(value, 'authored context example'),
         ),
       ),
       prompt = _validLocalizedText(prompt, 'assessment prompt'),
       roleInstruction = _validLocalizedText(
         roleInstruction,
         'assessment role instruction',
       ) {
    if (this.conceptIds.isEmpty || rubricVersion <= 0) {
      throw const FormatException('Invalid productive assessment identity.');
    }
    _requireUnique(this.conceptIds, 'assessment concept');
    _requireUnique(
      this.prerequisiteAssessmentItemIds,
      'prerequisite assessment',
    );
    _validScore(minimumScore, 'minimumScore');
    if (minimumScore < CourseSegmentCatalog.minimumPermanentMasteryScore) {
      throw const FormatException(
        'Productive assessment minimumScore must be at least 0.7.',
      );
    }
    if (!this.canDoSegmentId.startsWith('segment_')) {
      throw const FormatException(
        'Productive canDoSegmentId must use the canonical segment_ prefix.',
      );
    }
    final suffix = this.canDoSegmentId.substring('segment_'.length);
    final modeSuffix = _snakeEvidenceMode(evidenceMode);
    if (this.assessmentItemId != 'assess_${suffix}_${modeSuffix}_v1' ||
        this.missionContentLinkId != 'mission_${suffix}_${modeSuffix}_v1') {
      throw FormatException(
        'Productive assessment IDs must be canonical for ${this.canDoSegmentId}.',
      );
    }
    final rubricCount = [
      textRubric,
      connectedEvidenceRubric,
      oralRubric,
    ].whereType<Object>().length;
    if (rubricCount != 1 || !_rubricMatchesMode) {
      throw const FormatException(
        'Productive assessment mode must have one matching executable rubric.',
      );
    }
  }

  factory ProductiveAssessmentDefinition.fromJson(Map<String, dynamic> json) {
    final level = LearnerLevel.fromCode(json['level']?.toString());
    final mode = SegmentEvidenceModeX.tryFromCode(
      json['evidenceMode']?.toString(),
    );
    final rawConceptIds = json['conceptIds'];
    final rawRubricVersion = json['rubricVersion'];
    final rawMinimumScore = json['minimumScore'];
    if (level == null ||
        mode == null ||
        rawConceptIds is! List ||
        rawRubricVersion is! num ||
        rawMinimumScore is! num) {
      throw const FormatException('Invalid productive assessment definition.');
    }
    return ProductiveAssessmentDefinition(
      canDoSegmentId: json['canDoSegmentId']?.toString() ?? '',
      assessmentItemId: json['assessmentItemId']?.toString() ?? '',
      missionContentLinkId: json['missionContentLinkId']?.toString() ?? '',
      level: level,
      courseUnitId: json['courseUnitId']?.toString() ?? '',
      conceptIds: rawConceptIds.map((value) => value.toString()),
      evidenceMode: mode,
      rubricVersion: rawRubricVersion.toInt(),
      minimumScore: rawMinimumScore.toDouble(),
      prompt: _localizedText(json['prompt'], 'assessment prompt'),
      roleInstruction: _localizedText(
        json['roleInstruction'],
        'assessment role instruction',
      ),
      prerequisiteAssessmentItemIds: _stringValues(
        json['prerequisiteAssessmentItemIds'],
        'prerequisiteAssessmentItemIds',
      ),
      grammarReferenceIds: _stringValues(
        json['grammarReferenceIds'],
        'grammarReferenceIds',
      ),
      authoredContextExamples: _stringValues(
        json['authoredContextExamples'],
        'authoredContextExamples',
      ),
      textRubric: json['textRubric'] == null
          ? null
          : ProductiveTextRubric.fromJson(
              _stringMap(json['textRubric'], 'textRubric'),
            ),
      connectedEvidenceRubric: json['connectedEvidenceRubric'] == null
          ? null
          : ProductiveConnectedEvidenceRubric.fromJson(
              _stringMap(
                json['connectedEvidenceRubric'],
                'connectedEvidenceRubric',
              ),
            ),
      oralRubric: json['oralRubric'] == null
          ? null
          : ProductiveOralRubric.fromJson(
              _stringMap(json['oralRubric'], 'oralRubric'),
            ),
    );
  }

  final String canDoSegmentId;
  final String assessmentItemId;
  final String missionContentLinkId;
  final LearnerLevel level;
  final String courseUnitId;
  final List<String> conceptIds;
  final SegmentEvidenceMode evidenceMode;
  final int rubricVersion;
  final double minimumScore;
  final CurriculumText prompt;
  final CurriculumText roleInstruction;
  final List<String> prerequisiteAssessmentItemIds;
  final List<String> grammarReferenceIds;
  final List<String> authoredContextExamples;
  final ProductiveTextRubric? textRubric;
  final ProductiveConnectedEvidenceRubric? connectedEvidenceRubric;
  final ProductiveOralRubric? oralRubric;

  /// Opaque identity of the exact executable rubric and its provenance.
  /// Results carry this fingerprint so a caller cannot grade against an easier
  /// shadow definition that reuses canonical IDs.
  String get authorityFingerprint => stableContentId(
    'productive_assessment_definition',
    [jsonEncode(_fingerprintPayload)],
  );

  Map<String, Object?> get _fingerprintPayload => <String, Object?>{
    'canDoSegmentId': canDoSegmentId,
    'assessmentItemId': assessmentItemId,
    'missionContentLinkId': missionContentLinkId,
    'level': level.code,
    'courseUnitId': courseUnitId,
    'conceptIds': [...conceptIds]..sort(),
    'evidenceMode': evidenceMode.code,
    'rubricVersion': rubricVersion,
    'minimumScore': minimumScore,
    'prompt': prompt.toJson(),
    'roleInstruction': roleInstruction.toJson(),
    'prerequisiteAssessmentItemIds': [...prerequisiteAssessmentItemIds]..sort(),
    'grammarReferenceIds': [...grammarReferenceIds]..sort(),
    'authoredContextExamples': authoredContextExamples,
    if (textRubric != null)
      'textRubric': <String, Object?>{
        'minInputCodePoints': textRubric!.minInputCodePoints,
        'maxInputCodePoints': textRubric!.maxInputCodePoints,
        'requiredStructuredSlotIds': textRubric!.requiredStructuredSlotIds,
        'minimumDistinctSourceSpanIds':
            textRubric!.minimumDistinctSourceSpanIds,
        'requiredSourceSnippetIds':
            textRubric!.requiredSourceSnippetIds.toList()..sort(),
        'oneOfSourceGroups': [
          for (final group in textRubric!.oneOfSourceGroups)
            group.toList()..sort(),
        ],
        'discourseMarkerGroups': textRubric!.discourseMarkerGroups,
        'criteria': [
          for (final criterion in textRubric!.criteria)
            <String, Object?>{
              'id': criterion.id,
              'kind': criterion.kind.code,
              'acceptedVariants': criterion.acceptedVariants,
              'weight': criterion.weight,
              'requiredForPass': criterion.requiredForPass,
            },
        ],
      },
    if (connectedEvidenceRubric != null)
      'connectedEvidenceRubric': <String, Object?>{
        'minimumSourceNodes': connectedEvidenceRubric!.minimumSourceNodes,
        'requiredRoles':
            connectedEvidenceRubric!.requiredRoles
                .map((role) => role.code)
                .toList()
              ..sort(),
        'requiredSourceSnippetIds':
            connectedEvidenceRubric!.requiredSourceSnippetIds.toList()..sort(),
        'oneOfSourceGroups': [
          for (final group in connectedEvidenceRubric!.oneOfSourceGroups)
            group.toList()..sort(),
        ],
        'relationshipRequirements': [
          for (final relationship
              in connectedEvidenceRubric!.relationshipRequirements)
            <String, Object?>{
              'id': relationship.id,
              'role': relationship.role.code,
              'oneOfSourceSnippetIds':
                  relationship.oneOfSourceSnippetIds.toList()..sort(),
            },
        ],
        'requireProvenance': connectedEvidenceRubric!.requireProvenance,
      },
    if (oralRubric != null)
      'oralRubric': <String, Object?>{
        'minimumPronunciation': oralRubric!.minimumPronunciation,
        'minimumAccuracy': oralRubric!.minimumAccuracy,
        'minimumFluency': oralRubric!.minimumFluency,
        'minimumDurationMilliseconds': oralRubric!.minimumDurationMilliseconds,
        'maximumDurationMilliseconds': oralRubric!.maximumDurationMilliseconds,
        'minimumTranscriptCodePoints': oralRubric!.minimumTranscriptCodePoints,
        'requiredSemanticSlotIds': oralRubric!.requiredSemanticSlotIds,
        'semanticSlotMentionVariants': <String, Object?>{
          for (final entry in oralRubric!.semanticSlotMentionVariants.entries)
            entry.key: entry.value,
        },
        'requiredSourceSnippetIds':
            oralRubric!.requiredSourceSnippetIds.toList()..sort(),
        'oneOfSourceGroups': [
          for (final group in oralRubric!.oneOfSourceGroups)
            group.toList()..sort(),
        ],
        'sourceMentionVariants': <String, Object?>{
          for (final entry in oralRubric!.sourceMentionVariants.entries)
            entry.key: entry.value,
        },
        'discourseMarkerGroups': oralRubric!.discourseMarkerGroups,
      },
  };

  bool get _rubricMatchesMode => switch (evidenceMode) {
    SegmentEvidenceMode.guidedProduction ||
    SegmentEvidenceMode.dictation ||
    SegmentEvidenceMode.connectedProduction ||
    SegmentEvidenceMode.openWriting =>
      textRubric != null &&
          connectedEvidenceRubric == null &&
          oralRubric == null,
    SegmentEvidenceMode.connectedEvidence =>
      textRubric == null &&
          connectedEvidenceRubric != null &&
          oralRubric == null,
    SegmentEvidenceMode.oralProduction =>
      textRubric == null &&
          connectedEvidenceRubric == null &&
          oralRubric != null,
  };

  SegmentAssessmentAuthority get authority => SegmentAssessmentAuthority(
    assessmentItemId: assessmentItemId,
    missionContentLinkId: missionContentLinkId,
    level: level,
    courseUnitId: courseUnitId,
    conceptIds: conceptIds,
    evidenceMode: evidenceMode,
    rubricVersion: rubricVersion,
    minimumScore: minimumScore,
    isAssessEdge: true,
    courseEligible: true,
  );
}

final class ProductiveProjectStep {
  ProductiveProjectStep({
    required String id,
    required this.order,
    required Iterable<String> snippetIds,
    required Iterable<String> prerequisiteStepIds,
    required CurriculumText action,
    required Iterable<String> assessmentItemIds,
  }) : id = _requiredId(id, 'project step ID'),
       snippetIds = List.unmodifiable(
         snippetIds.map((value) => _requiredId(value, 'snippet ID')),
       ),
       prerequisiteStepIds = List.unmodifiable(
         prerequisiteStepIds.map(
           (value) => _requiredId(value, 'prerequisite step ID'),
         ),
       ),
       action = _validLocalizedText(action, 'project step action'),
       assessmentItemIds = List.unmodifiable(
         assessmentItemIds.map(
           (value) => _requiredId(value, 'step assessment ID'),
         ),
       ) {
    if (order < 1 || order > 4) {
      throw const FormatException('Project step order must be 1 through 4.');
    }
    _requireUnique(this.snippetIds, 'project step snippet');
    _requireUnique(this.prerequisiteStepIds, 'project step prerequisite');
    _requireUnique(this.assessmentItemIds, 'project step assessment');
  }

  final String id;
  final int order;
  final List<String> snippetIds;
  final List<String> prerequisiteStepIds;
  final CurriculumText action;
  final List<String> assessmentItemIds;
}

final class ProductiveProjectDefinition {
  ProductiveProjectDefinition({
    required String id,
    required Iterable<ProductiveProjectStep> steps,
  }) : id = _requiredId(id, 'project ID'),
       steps = List.unmodifiable(steps) {
    final orders = this.steps.map((step) => step.order).toList()..sort();
    if (orders.length != 4 || orders.join(',') != '1,2,3,4') {
      throw const FormatException(
        'Each productive project requires four ordered steps.',
      );
    }
    _requireUnique(this.steps.map((step) => step.id), 'project step');
    final byId = {for (final step in this.steps) step.id: step};
    for (final step in this.steps) {
      for (final prerequisiteId in step.prerequisiteStepIds) {
        final prerequisite = byId[prerequisiteId];
        if (prerequisite == null || prerequisite.order >= step.order) {
          throw FormatException(
            'Project step ${step.id} has an invalid prerequisite $prerequisiteId.',
          );
        }
      }
      if (step.order == 1 && step.prerequisiteStepIds.isNotEmpty) {
        throw const FormatException(
          'The first project step cannot have a prerequisite.',
        );
      }
      if (step.order > 1) {
        final previous = this.steps.singleWhere(
          (candidate) => candidate.order == step.order - 1,
        );
        if (!step.prerequisiteStepIds.contains(previous.id)) {
          throw FormatException(
            'Project step ${step.id} must depend on ${previous.id}.',
          );
        }
      }
    }
  }

  final String id;
  final List<ProductiveProjectStep> steps;
}

final class ProductiveSourceSnippet {
  ProductiveSourceSnippet({
    required String id,
    required String projectId,
    required String stepId,
    required CurriculumText provenance,
    required CurriculumText text,
    required Iterable<ProductiveEvidenceRole> supportedRoles,
  }) : id = _requiredId(id, 'source snippet ID'),
       projectId = _requiredId(projectId, 'source project ID'),
       stepId = _requiredId(stepId, 'source step ID'),
       provenance = _validLocalizedText(provenance, 'source provenance'),
       text = _validLocalizedText(text, 'source text'),
       supportedRoles = Set.unmodifiable(supportedRoles) {
    if (this.supportedRoles.isEmpty) {
      throw const FormatException(
        'Productive source snippet requires support metadata.',
      );
    }
  }

  final String id;
  final String projectId;
  final String stepId;
  final CurriculumText provenance;
  final CurriculumText text;
  final Set<ProductiveEvidenceRole> supportedRoles;
}

final class ProductiveAssessmentBundle {
  ProductiveAssessmentBundle({
    required String canDoSegmentId,
    required String projectId,
    required String stepId,
    required Iterable<String> assessmentItemIds,
  }) : canDoSegmentId = _requiredId(canDoSegmentId, 'bundle segment ID'),
       projectId = _requiredId(projectId, 'bundle project ID'),
       stepId = _requiredId(stepId, 'bundle step ID'),
       assessmentItemIds = List.unmodifiable(
         assessmentItemIds.map(
           (value) => _requiredId(value, 'bundle assessment ID'),
         ),
       ) {
    _requireUnique(this.assessmentItemIds, 'bundle assessment');
  }

  final String canDoSegmentId;
  final String projectId;
  final String stepId;
  final List<String> assessmentItemIds;
}

/// Canonical executable assessment registry. It is loaded before the segment
/// catalog so [.authorities] can be the sole trusted authority source, then
/// [bind] proves the two immutable catalogs cover each other exactly.
final class ProductiveAssessmentCatalog {
  static const int supportedSchemaVersion = 1;

  /// Learner-facing assessment copy remains closed until Jin's per-ID review
  /// ledger is integrated. The draft fixture lives outside Flutter assets;
  /// service and persistence tests inject it explicitly.
  static const bool runtimeContentApproved = false;

  ProductiveAssessmentCatalog.fromDefinitions(
    Iterable<ProductiveAssessmentDefinition> definitions, {
    this.schemaVersion = supportedSchemaVersion,
    Iterable<ProductiveProjectDefinition> projects = const [],
    Iterable<ProductiveSourceSnippet> sourceSnippets = const [],
    Iterable<ProductiveAssessmentBundle> bundles = const [],
  }) : definitions = List.unmodifiable(definitions),
       projects = List.unmodifiable(projects),
       sourceSnippets = List.unmodifiable(sourceSnippets),
       bundles = List.unmodifiable(bundles),
       definitionsById = Map.unmodifiable({
         for (final definition in definitions)
           definition.assessmentItemId: definition,
       }),
       projectsById = Map.unmodifiable({
         for (final project in projects) project.id: project,
       }),
       snippetsById = Map.unmodifiable({
         for (final snippet in sourceSnippets) snippet.id: snippet,
       }) {
    _validateStandalone();
  }

  factory ProductiveAssessmentCatalog.fromJson(Map<String, dynamic> json) {
    final rawVersion = json['schemaVersion'];
    final rawDefinitions = json['definitions'];
    final rawProjects = json['projects'];
    final rawSnippets = json['sourceSnippets'];
    final rawBundles = json['bundles'];
    if (rawVersion != supportedSchemaVersion ||
        rawDefinitions is! List ||
        rawProjects is! List ||
        rawSnippets is! List ||
        rawBundles is! List) {
      throw const FormatException('Invalid productive assessment catalog.');
    }
    return ProductiveAssessmentCatalog.fromDefinitions(
      rawDefinitions.map(
        (value) => ProductiveAssessmentDefinition.fromJson(
          _stringMap(value, 'productive assessment definition'),
        ),
      ),
      schemaVersion: rawVersion as int,
      projects: rawProjects.map(_projectFromJson),
      sourceSnippets: rawSnippets.map(_snippetFromJson),
      bundles: rawBundles.map(_bundleFromJson),
    );
  }

  final int schemaVersion;
  final List<ProductiveAssessmentDefinition> definitions;
  final List<ProductiveProjectDefinition> projects;
  final List<ProductiveSourceSnippet> sourceSnippets;
  final List<ProductiveAssessmentBundle> bundles;
  final Map<String, ProductiveAssessmentDefinition> definitionsById;
  final Map<String, ProductiveProjectDefinition> projectsById;
  final Map<String, ProductiveSourceSnippet> snippetsById;

  List<SegmentAssessmentAuthority> get authorities =>
      List.unmodifiable(definitions.map((definition) => definition.authority));

  ProductiveAssessmentDefinition? definitionFor(String assessmentItemId) =>
      definitionsById[assessmentItemId];

  ProductiveAssessmentBundle? bundleForSegment(String canDoSegmentId) {
    for (final bundle in bundles) {
      if (bundle.canDoSegmentId == canDoSegmentId) {
        return bundle;
      }
    }
    return null;
  }

  ProductiveAssessmentBundle? nextBundleInProject(String canDoSegmentId) {
    final current = bundleForSegment(canDoSegmentId);
    if (current == null) {
      return null;
    }
    final currentStep = projectStepFor(current.projectId, current.stepId);
    if (currentStep == null) {
      throw const FormatException('Productive bundle has an unknown step.');
    }
    ProductiveAssessmentBundle? next;
    int? nextOrder;
    for (final candidate in bundles) {
      if (candidate.projectId != current.projectId) {
        continue;
      }
      final candidateStep = projectStepFor(
        candidate.projectId,
        candidate.stepId,
      );
      if (candidateStep == null || candidateStep.order <= currentStep.order) {
        continue;
      }
      if (nextOrder == null || candidateStep.order < nextOrder) {
        next = candidate;
        nextOrder = candidateStep.order;
      }
    }
    return next;
  }

  ProductiveProjectStep? projectStepFor(String projectId, String stepId) {
    final project = projectsById[projectId];
    if (project == null) {
      return null;
    }
    for (final step in project.steps) {
      if (step.id == stepId) {
        return step;
      }
    }
    return null;
  }

  Set<String> introducedSourceIdsForStep(String projectId, String stepId) {
    final project = projectsById[projectId];
    final step = projectStepFor(projectId, stepId);
    if (project == null || step == null) {
      throw const FormatException('Unknown productive project step.');
    }
    final previousSources = step.order == 1
        ? const <String>{}
        : project.steps
              .singleWhere((candidate) => candidate.order == step.order - 1)
              .snippetIds
              .toSet();
    return Set.unmodifiable(
      step.snippetIds.toSet().difference(previousSources),
    );
  }

  String courseUnitIdForProjectStep(String projectId, String stepId) {
    final project = projectsById[projectId];
    final step = projectStepFor(projectId, stepId);
    if (project == null ||
        step == null ||
        (step.order != 1 && step.order != 3)) {
      throw const FormatException('Project review must be step 1 or 3.');
    }
    final assessedStep = project.steps.singleWhere(
      (candidate) => candidate.order == step.order + 1,
    );
    final matchingBundles = bundles
        .where(
          (bundle) =>
              bundle.projectId == projectId && bundle.stepId == assessedStep.id,
        )
        .toList(growable: false);
    if (matchingBundles.length != 1 ||
        matchingBundles.single.assessmentItemIds.isEmpty) {
      throw const FormatException(
        'Project review step has no exact assessed successor.',
      );
    }
    final unitIds = matchingBundles.single.assessmentItemIds
        .map((id) => definitionsById[id]?.courseUnitId)
        .whereType<String>()
        .toSet();
    if (unitIds.length != 1) {
      throw const FormatException(
        'Project review successor must belong to one course unit.',
      );
    }
    return unitIds.single;
  }

  String projectStepAuthorityFingerprint(String projectId, String stepId) {
    final step = projectStepFor(projectId, stepId);
    if (step == null || (step.order != 1 && step.order != 3)) {
      throw const FormatException('Project review must be step 1 or 3.');
    }
    final introduced = introducedSourceIdsForStep(projectId, stepId).toList()
      ..sort();
    return stableContentId('productive_project_step_authority', [
      jsonEncode(<String, Object?>{
        'schemaVersion': schemaVersion,
        'projectId': projectId,
        'stepId': step.id,
        'stepOrder': step.order,
        'courseUnitId': courseUnitIdForProjectStep(projectId, stepId),
        'prerequisiteStepIds': [...step.prerequisiteStepIds]..sort(),
        'action': step.action.toJson(),
        'introducedSources': [
          for (final sourceId in introduced)
            <String, Object?>{
              'id': sourceId,
              'provenance': snippetsById[sourceId]!.provenance.toJson(),
              'text': snippetsById[sourceId]!.text.toJson(),
              'supportedRoles':
                  snippetsById[sourceId]!.supportedRoles
                      .map((role) => role.code)
                      .toList()
                    ..sort(),
            },
        ],
      }),
    ]);
  }

  /// Fails closed if any immutable published/retired segment requirement lacks
  /// an executable definition or claims different provenance. Retired
  /// definitions remain append-only so previously earned evidence survives a
  /// same-construct replacement.
  void bind(CourseSegmentCatalog segmentCatalog) {
    final expected = <String, (CanDoSegment, SegmentAssessmentRequirement)>{};
    for (final segment in segmentCatalog.assessmentAuthoritySegments) {
      for (final requirement in segment.assessmentRequirements) {
        if (expected.containsKey(requirement.assessmentItemId)) {
          throw FormatException(
            'Immutable assessment ${requirement.assessmentItemId} is shared.',
          );
        }
        expected[requirement.assessmentItemId] = (segment, requirement);
      }
    }
    if (expected.length != definitionsById.length ||
        !expected.keys.toSet().containsAll(definitionsById.keys) ||
        !definitionsById.keys.toSet().containsAll(expected.keys)) {
      throw const FormatException(
        'Immutable segment requirements and productive definitions must have exact coverage.',
      );
    }
    for (final entry in expected.entries) {
      final (segment, requirement) = entry.value;
      final definition = definitionsById[entry.key]!;
      if (definition.canDoSegmentId != segment.id ||
          definition.courseUnitId != segment.parentCourseUnitId ||
          definition.level != segment.level ||
          definition.missionContentLinkId != requirement.missionContentLinkId ||
          definition.evidenceMode != requirement.evidenceMode ||
          definition.rubricVersion != requirement.rubricVersion ||
          definition.minimumScore != requirement.minimumScore ||
          !_sameSet(definition.conceptIds, segment.requiredConceptIds)) {
        throw FormatException(
          'Productive definition ${definition.assessmentItemId} does not exactly join segment ${segment.id}.',
        );
      }
    }
    _validateAdvancedBundles(segmentCatalog);
  }

  void _validateStandalone() {
    if (schemaVersion != supportedSchemaVersion || definitions.isEmpty) {
      throw const FormatException('Invalid productive assessment catalog.');
    }
    _requireUnique(
      definitions.map((definition) => definition.assessmentItemId),
      'productive assessment',
    );
    _requireUnique(
      definitions.map((definition) => definition.missionContentLinkId),
      'productive mission link',
    );
    _requireUnique(projects.map((project) => project.id), 'productive project');
    _requireUnique(
      sourceSnippets.map((snippet) => snippet.id),
      'productive source snippet',
    );
    _requireUnique(
      bundles.map((bundle) => bundle.canDoSegmentId),
      'productive bundle segment',
    );
    _requireUnique(
      bundles.map((bundle) => '${bundle.projectId}:${bundle.stepId}'),
      'productive bundle project step',
    );
    for (final definition in definitions) {
      if (definition.prerequisiteAssessmentItemIds.contains(
        definition.assessmentItemId,
      )) {
        throw FormatException(
          'Assessment ${definition.assessmentItemId} cannot depend on itself.',
        );
      }
      for (final prerequisite in definition.prerequisiteAssessmentItemIds) {
        if (!definitionsById.containsKey(prerequisite)) {
          throw FormatException(
            'Assessment ${definition.assessmentItemId} has unknown prerequisite $prerequisite.',
          );
        }
      }
    }
    _validateDependencyCycles();
    for (final snippet in sourceSnippets) {
      final project = projectsById[snippet.projectId];
      if (project == null ||
          !project.steps.any((step) => step.id == snippet.stepId) ||
          !project.steps
              .firstWhere((step) => step.id == snippet.stepId)
              .snippetIds
              .contains(snippet.id)) {
        throw FormatException(
          'Source snippet ${snippet.id} does not join its project step.',
        );
      }
    }
    for (final project in projects) {
      final availableSnippetIds = project.steps
          .expand((step) => step.snippetIds)
          .toSet();
      final authoredSnippetIds = sourceSnippets
          .where((snippet) => snippet.projectId == project.id)
          .map((snippet) => snippet.id)
          .toSet();
      if (availableSnippetIds.length != 4 ||
          !_sameSet(availableSnippetIds, authoredSnippetIds)) {
        throw FormatException(
          'Project ${project.id} must own exactly four source snippets.',
        );
      }
      for (var order = 2; order <= 4; order++) {
        final previous = project.steps.singleWhere(
          (step) => step.order == order - 1,
        );
        final current = project.steps.singleWhere(
          (step) => step.order == order,
        );
        if (!current.snippetIds.toSet().containsAll(previous.snippetIds)) {
          throw FormatException(
            'Project ${project.id} step $order must retain earlier source access.',
          );
        }
      }
      final stepAssessmentIds = project.steps
          .expand((step) => step.assessmentItemIds)
          .toList();
      _requireUnique(stepAssessmentIds, 'project step assessment');
      for (final assessmentId in stepAssessmentIds) {
        if (!definitionsById.containsKey(assessmentId)) {
          throw FormatException(
            'Project ${project.id} references unknown assessment $assessmentId.',
          );
        }
      }
    }
    for (final bundle in bundles) {
      final project = projectsById[bundle.projectId];
      if (project == null ||
          !project.steps.any((step) => step.id == bundle.stepId)) {
        throw FormatException(
          'Bundle ${bundle.canDoSegmentId} has an unknown project step.',
        );
      }
      final step = project.steps.singleWhere(
        (candidate) => candidate.id == bundle.stepId,
      );
      if (!_sameSet(step.assessmentItemIds, bundle.assessmentItemIds)) {
        throw FormatException(
          'Bundle ${bundle.canDoSegmentId} does not match its serialized project step.',
        );
      }
      for (final assessmentId in bundle.assessmentItemIds) {
        final definition = definitionsById[assessmentId];
        if (definition == null ||
            definition.canDoSegmentId != bundle.canDoSegmentId) {
          throw FormatException(
            'Bundle ${bundle.canDoSegmentId} has an invalid assessment $assessmentId.',
          );
        }
      }
    }
    for (final definition in definitions) {
      final connectedRubric = definition.connectedEvidenceRubric;
      final textRubric = definition.textRubric;
      if (connectedRubric == null &&
          (textRubric == null || !textRubric.requiresStructuredSubmission)) {
        continue;
      }
      final bundle = bundleForSegment(definition.canDoSegmentId);
      final project = bundle == null ? null : projectsById[bundle.projectId];
      if (project == null) {
        throw FormatException(
          'Structured assessment ${definition.assessmentItemId} has no project.',
        );
      }
      final allowedSources = project.steps
          .singleWhere((step) => step.id == bundle!.stepId)
          .snippetIds
          .toSet();
      final declaredSources = <String>{
        if (textRubric != null) ...textRubric.requiredSourceSnippetIds,
        if (textRubric != null)
          ...textRubric.oneOfSourceGroups.expand((group) => group),
        if (connectedRubric != null)
          ...connectedRubric.requiredSourceSnippetIds,
        if (connectedRubric != null)
          ...connectedRubric.oneOfSourceGroups.expand((group) => group),
        if (connectedRubric != null)
          ...connectedRubric.relationshipRequirements.expand(
            (requirement) => requirement.oneOfSourceSnippetIds,
          ),
      };
      if (!allowedSources.containsAll(declaredSources)) {
        throw FormatException(
          'Structured assessment ${definition.assessmentItemId} cites a source outside its current project step.',
        );
      }
      for (final relationship
          in connectedRubric?.relationshipRequirements ?? const []) {
        for (final sourceId in relationship.oneOfSourceSnippetIds) {
          if (snippetsById[sourceId]?.supportedRoles.contains(
                relationship.role,
              ) !=
              true) {
            throw FormatException(
              'Source $sourceId does not support ${relationship.role.code}.',
            );
          }
        }
      }
    }
  }

  void _validateDependencyCycles() {
    final visiting = <String>{};
    final visited = <String>{};
    void visit(String assessmentId) {
      if (visited.contains(assessmentId)) {
        return;
      }
      if (!visiting.add(assessmentId)) {
        throw FormatException(
          'Productive assessment dependency cycle at $assessmentId.',
        );
      }
      for (final prerequisite
          in definitionsById[assessmentId]!.prerequisiteAssessmentItemIds) {
        visit(prerequisite);
      }
      visiting.remove(assessmentId);
      visited.add(assessmentId);
    }

    for (final definition in definitions) {
      visit(definition.assessmentItemId);
    }
  }

  void _validateAdvancedBundles(CourseSegmentCatalog segmentCatalog) {
    final advancedSegments = segmentCatalog.assessmentAuthoritySegments
        .where(
          (segment) =>
              segment.level == LearnerLevel.c1 ||
              segment.level == LearnerLevel.c2,
        )
        .toList(growable: false);
    if (advancedSegments.isEmpty) {
      if (bundles.isNotEmpty ||
          projects.isNotEmpty ||
          sourceSnippets.isNotEmpty) {
        throw const FormatException(
          'Advanced productive project data has no immutable C authority.',
        );
      }
      return;
    }
    if (bundles.length != advancedSegments.length) {
      throw const FormatException(
        'Every published or retired C1/C2 authority requires one project bundle.',
      );
    }
    for (final segment in advancedSegments) {
      final bundle = bundleForSegment(segment.id);
      if (bundle == null ||
          bundle.assessmentItemIds.length != 3 ||
          !_sameSet(
            bundle.assessmentItemIds,
            segment.assessmentRequirements.map(
              (requirement) => requirement.assessmentItemId,
            ),
          )) {
        throw FormatException(
          'Advanced segment ${segment.id} requires writing, oral, and evidence definitions.',
        );
      }
      final modes = bundle.assessmentItemIds
          .map((id) => definitionsById[id]!.evidenceMode)
          .toSet();
      if (!_sameSet(modes, const {
        SegmentEvidenceMode.openWriting,
        SegmentEvidenceMode.oralProduction,
        SegmentEvidenceMode.connectedEvidence,
      })) {
        throw FormatException(
          'Advanced segment ${segment.id} has the wrong three-axis bundle.',
        );
      }
      final oral = bundle.assessmentItemIds
          .map((id) => definitionsById[id]!)
          .singleWhere(
            (definition) =>
                definition.evidenceMode == SegmentEvidenceMode.oralProduction,
          );
      final writingId = bundle.assessmentItemIds
          .map((id) => definitionsById[id]!)
          .singleWhere(
            (definition) =>
                definition.evidenceMode == SegmentEvidenceMode.openWriting,
          )
          .assessmentItemId;
      final writing = definitionsById[writingId]!;
      final writingRubric = writing.textRubric;
      final oralRubric = oral.oralRubric!;
      final connected = bundle.assessmentItemIds
          .map((id) => definitionsById[id]!)
          .singleWhere(
            (definition) =>
                definition.evidenceMode ==
                SegmentEvidenceMode.connectedEvidence,
          );
      final connectedRubric = connected.connectedEvidenceRubric!;
      if (writingRubric == null ||
          writingRubric.requiredStructuredSlotIds.length < 4 ||
          writingRubric.minimumDistinctSourceSpanIds < 2 ||
          writingRubric.discourseMarkerGroups.length < 3 ||
          writingRubric.minInputCodePoints < 120) {
        throw FormatException(
          'Advanced writing $writingId requires four slots, distinct sources, three discourse markers, and a 120-code-point minimum.',
        );
      }
      if (!connectedRubric.requireProvenance ||
          !connectedRubric.requiredRoles.every(
            (role) => connectedRubric.relationshipRequirements.any(
              (relationship) => relationship.role == role,
            ),
          )) {
        throw FormatException(
          'Advanced evidence ${connected.assessmentItemId} requires provenance and an authored relationship for every required role.',
        );
      }
      if (!_sameSet(
            oralRubric.requiredSemanticSlotIds,
            writingRubric.requiredStructuredSlotIds,
          ) ||
          oralRubric.minimumDurationMilliseconds < 45000 ||
          oralRubric.maximumDurationMilliseconds > 120000 ||
          oralRubric.minimumTranscriptCodePoints < 120 ||
          oralRubric.discourseMarkerGroups.length < 3) {
        throw FormatException(
          'Advanced oral ${oral.assessmentItemId} requires the authored 45-120 second semantic discourse contract.',
        );
      }
      final project = projectsById[bundle.projectId]!;
      final step = project.steps.singleWhere(
        (candidate) => candidate.id == bundle.stepId,
      );
      final stepTwo = project.steps.singleWhere(
        (candidate) => candidate.order == 2,
      );
      final requiredSources = step.order == 2
          ? stepTwo.snippetIds.toSet()
          : step.snippetIds.toSet().difference(stepTwo.snippetIds.toSet());
      final oneOfSources = step.order == 2
          ? const <String>{}
          : stepTwo.snippetIds.toSet();
      final writingOneOf = writingRubric.oneOfSourceGroups;
      final connectedOneOf = connectedRubric.oneOfSourceGroups;
      if (!_sameSet(writingRubric.requiredSourceSnippetIds, requiredSources) ||
          !_sameSet(
            connectedRubric.requiredSourceSnippetIds,
            requiredSources,
          ) ||
          (oneOfSources.isEmpty
              ? writingOneOf.isNotEmpty || connectedOneOf.isNotEmpty
              : writingOneOf.length != 1 ||
                    connectedOneOf.length != 1 ||
                    !_sameSet(writingOneOf.single, oneOfSources) ||
                    !_sameSet(connectedOneOf.single, oneOfSources))) {
        throw FormatException(
          'Advanced segment ${segment.id} does not enforce its authored step sources.',
        );
      }
      if (!_sameSet(oralRubric.requiredSourceSnippetIds, requiredSources) ||
          (oneOfSources.isEmpty
              ? oralRubric.oneOfSourceGroups.isNotEmpty
              : oralRubric.oneOfSourceGroups.length != 1 ||
                    !_sameSet(
                      oralRubric.oneOfSourceGroups.single,
                      oneOfSources,
                    ))) {
        throw FormatException(
          'Advanced oral ${oral.assessmentItemId} does not enforce its authored step sources.',
        );
      }
      if (!oral.prerequisiteAssessmentItemIds.contains(writingId)) {
        throw FormatException(
          'Oral assessment ${oral.assessmentItemId} requires its open-writing proof.',
        );
      }
    }
    for (final project in projects) {
      final stepTwo = project.steps.singleWhere((step) => step.order == 2);
      final stepFour = project.steps.singleWhere((step) => step.order == 4);
      final earlier = bundles
          .where(
            (bundle) =>
                bundle.projectId == project.id && bundle.stepId == stepTwo.id,
          )
          .toList(growable: false);
      final later = bundles
          .where(
            (bundle) =>
                bundle.projectId == project.id && bundle.stepId == stepFour.id,
          )
          .toList(growable: false);
      if (earlier.length != 1 || later.length != 1) {
        throw FormatException(
          'Project ${project.id} requires one CARE and one TRANSMIT bundle.',
        );
      }
      final prerequisiteIds = earlier.single.assessmentItemIds.toSet();
      for (final assessmentId in later.single.assessmentItemIds) {
        final actual = definitionsById[assessmentId]!
            .prerequisiteAssessmentItemIds
            .toSet();
        if (!actual.containsAll(prerequisiteIds)) {
          throw FormatException(
            'Project ${project.id} TRANSMIT assessment $assessmentId bypasses CARE.',
          );
        }
      }
    }
  }
}

final class ProductiveCriterionOutcome {
  const ProductiveCriterionOutcome({
    required this.id,
    required this.matched,
    required this.weight,
  });

  final String id;
  final bool matched;
  final double weight;
}

/// Ephemeral grading result. It cannot be serialized. The normalized writing
/// reference is private to this library and is retained only long enough for a
/// consented oral assessment in the same local session.
final class ProductiveAssessmentResult {
  const ProductiveAssessmentResult._({
    required this.assessmentItemId,
    required this.canDoSegmentId,
    required this.definitionFingerprint,
    required this.score,
    required this.passed,
    required this.occurredAt,
    required this.criteria,
    required this.coverage,
    required this.supportingEvidenceIds,
    required this.oralScore,
    required this.assessmentAttemptId,
    required this._localReferenceText,
  });

  final String assessmentItemId;
  final String canDoSegmentId;
  final String definitionFingerprint;
  final String evaluatorVersion = productiveEvaluatorVersion;
  final double score;
  final bool passed;
  final DateTime occurredAt;
  final List<ProductiveCriterionOutcome> criteria;
  final ProductiveEvidenceCoverage coverage;
  final List<String> supportingEvidenceIds;
  final ProductiveOralScore? oralScore;
  final String? assessmentAttemptId;
  final String? _localReferenceText;
}

/// Ephemeral, deterministic result for an odd project source-review step.
/// It is intentionally separate from language assessment and cannot satisfy a
/// segment's productive all-of policy by itself.
final class ProductiveProjectStepReviewResult {
  const ProductiveProjectStepReviewResult._({
    required this.projectId,
    required this.stepId,
    required this.stepOrder,
    required this.courseUnitId,
    required this.authorityFingerprint,
    required this.evaluatorVersion,
    required this.reviewedSourceSnippetIds,
    required this.passed,
  });

  final String projectId;
  final String stepId;
  final int stepOrder;
  final String courseUnitId;
  final String authorityFingerprint;
  final String evaluatorVersion;
  final List<String> reviewedSourceSnippetIds;
  final bool passed;
}

final class ProductiveProjectStepReviewEngine {
  const ProductiveProjectStepReviewEngine();

  ProductiveProjectStepReviewResult evaluate({
    required ProductiveAssessmentCatalog catalog,
    required String projectId,
    required String stepId,
    required Iterable<String> reviewedSourceSnippetIds,
    required Iterable<String> openedProvenanceSnippetIds,
  }) {
    final step = catalog.projectStepFor(projectId, stepId);
    if (step == null || (step.order != 1 && step.order != 3)) {
      throw const FormatException(
        'Only authored source-review steps 1 and 3 can be evaluated.',
      );
    }
    final expected = catalog.introducedSourceIdsForStep(projectId, stepId);
    final reviewed = reviewedSourceSnippetIds.map((id) => id.trim()).toSet();
    final provenance = openedProvenanceSnippetIds
        .map((id) => id.trim())
        .toSet();
    final passed =
        reviewed.length == reviewedSourceSnippetIds.length &&
        provenance.length == openedProvenanceSnippetIds.length &&
        _sameSet(reviewed, expected) &&
        _sameSet(provenance, expected);
    final sortedReviewed = reviewed.toList()..sort();
    return ProductiveProjectStepReviewResult._(
      projectId: projectId,
      stepId: stepId,
      stepOrder: step.order,
      courseUnitId: catalog.courseUnitIdForProjectStep(projectId, stepId),
      authorityFingerprint: catalog.projectStepAuthorityFingerprint(
        projectId,
        stepId,
      ),
      evaluatorVersion: productiveEvaluatorVersion,
      reviewedSourceSnippetIds: List.unmodifiable(sortedReviewed),
      passed: passed,
    );
  }
}

/// Local-only structured writing submission. Slot text and source links are
/// consumed by the deterministic evaluator and are never serializable proof.
final class ProductiveStructuredWritingSubmission {
  ProductiveStructuredWritingSubmission({
    required this.text,
    required Map<String, String> slotValues,
    required Map<String, Iterable<String>> linkedSourceSpanIds,
  }) : slotValues = Map.unmodifiable(slotValues),
       linkedSourceSpanIds = Map<String, List<String>>.unmodifiable({
         for (final entry in linkedSourceSpanIds.entries)
           entry.key: List<String>.unmodifiable(entry.value),
       });

  final String text;
  final Map<String, String> slotValues;
  final Map<String, List<String>> linkedSourceSpanIds;
}

final class ProductiveTextAssessmentEngine {
  const ProductiveTextAssessmentEngine();

  ProductiveAssessmentResult evaluate({
    required ProductiveAssessmentDefinition definition,
    required String input,
    required DateTime occurredAt,
  }) {
    final rubric = definition.textRubric;
    if (rubric == null) {
      throw FormatException(
        '${definition.evidenceMode.code} is not a text assessment.',
      );
    }
    if (rubric.requiresStructuredSubmission) {
      throw const FormatException(
        'This writing assessment requires structured slot evidence.',
      );
    }
    return _evaluate(
      definition: definition,
      input: input,
      occurredAt: occurredAt,
    );
  }

  ProductiveAssessmentResult evaluateStructured({
    required ProductiveAssessmentCatalog catalog,
    required ProductiveAssessmentDefinition definition,
    required ProductiveStructuredWritingSubmission submission,
    required DateTime occurredAt,
  }) {
    final rubric = definition.textRubric;
    if (rubric == null || !rubric.requiresStructuredSubmission) {
      throw const FormatException(
        'This assessment does not declare a structured writing rubric.',
      );
    }
    final bundle = catalog.bundleForSegment(definition.canDoSegmentId);
    final project = bundle == null
        ? null
        : catalog.projectsById[bundle.projectId];
    if (project == null) {
      throw const FormatException(
        'Structured writing must join an authored project.',
      );
    }
    final step = project.steps.singleWhere(
      (candidate) => candidate.id == bundle!.stepId,
    );
    final allowedSourceIds = step.snippetIds.toSet();
    final structuredOutcomes = <ProductiveCriterionOutcome>[];
    final distinctSources = <String>{};
    final coveredSlots = <String>{};
    final slotSourceBindings = <ProductiveSlotSourceBinding>[];
    final normalizedText = _normalizeWriting(submission.text);
    for (final slotId in rubric.requiredStructuredSlotIds) {
      final normalizedSlot = _normalizeWriting(
        submission.slotValues[slotId] ?? '',
      );
      final linked = submission.linkedSourceSpanIds[slotId] ?? const [];
      final validLinks =
          linked.isNotEmpty &&
          linked.every(allowedSourceIds.contains) &&
          linked.length == linked.toSet().length;
      final matched =
          normalizedSlot.isNotEmpty &&
          BookAnalysisTextPreprocessor.containsHangulSyllable(normalizedSlot) &&
          normalizedText.contains(normalizedSlot) &&
          validLinks;
      if (matched) {
        coveredSlots.add(slotId);
        for (final sourceId in linked) {
          distinctSources.add(sourceId);
          slotSourceBindings.add(
            ProductiveSlotSourceBinding(
              semanticSlotId: slotId,
              sourceSnippetId: sourceId,
            ),
          );
        }
      }
      structuredOutcomes.add(
        ProductiveCriterionOutcome(
          id: 'slot:$slotId',
          matched: matched,
          weight: 1,
        ),
      );
    }
    structuredOutcomes.add(
      ProductiveCriterionOutcome(
        id: 'distinct_sources',
        matched: distinctSources.length >= rubric.minimumDistinctSourceSpanIds,
        weight: 1,
      ),
    );
    for (final sourceId in rubric.requiredSourceSnippetIds) {
      structuredOutcomes.add(
        ProductiveCriterionOutcome(
          id: 'required_source:$sourceId',
          matched: distinctSources.contains(sourceId),
          weight: 1,
        ),
      );
    }
    for (var index = 0; index < rubric.oneOfSourceGroups.length; index++) {
      structuredOutcomes.add(
        ProductiveCriterionOutcome(
          id: 'source_group:$index',
          matched: rubric.oneOfSourceGroups[index].any(
            distinctSources.contains,
          ),
          weight: 1,
        ),
      );
    }
    for (var index = 0; index < rubric.discourseMarkerGroups.length; index++) {
      final markers = rubric.discourseMarkerGroups[index];
      structuredOutcomes.add(
        ProductiveCriterionOutcome(
          id: 'discourse:$index',
          matched: markers.any(
            (marker) => _containsBoundedPhrase(
              normalizedText,
              _normalizeWriting(marker),
            ),
          ),
          weight: 1,
        ),
      );
    }
    return _evaluate(
      definition: definition,
      input: submission.text,
      occurredAt: occurredAt,
      additionalRequiredOutcomes: structuredOutcomes,
      semanticSlotIds: coveredSlots,
      sourceSnippetIds: distinctSources,
      slotSourceBindings: slotSourceBindings,
    );
  }

  ProductiveAssessmentResult _evaluate({
    required ProductiveAssessmentDefinition definition,
    required String input,
    required DateTime occurredAt,
    List<ProductiveCriterionOutcome> additionalRequiredOutcomes = const [],
    Iterable<String> semanticSlotIds = const [],
    Iterable<String> sourceSnippetIds = const [],
    Iterable<ProductiveSlotSourceBinding> slotSourceBindings = const [],
  }) {
    final rubric = definition.textRubric!;
    final normalized = _normalizeWriting(input);
    final validInput =
        normalized.isNotEmpty &&
        normalized.runes.length >= rubric.minInputCodePoints &&
        normalized.runes.length <= rubric.maxInputCodePoints &&
        BookAnalysisTextPreprocessor.containsHangulSyllable(normalized);
    final outcomes = <ProductiveCriterionOutcome>[
      ...additionalRequiredOutcomes,
    ];
    var matchedWeight = 0.0;
    var totalWeight = 0.0;
    var requiredPassed = validInput;
    for (final outcome in additionalRequiredOutcomes) {
      totalWeight += outcome.weight;
      if (outcome.matched) {
        matchedWeight += outcome.weight;
      } else {
        requiredPassed = false;
      }
    }
    for (final criterion in rubric.criteria) {
      final matched = validInput && _matchesCriterion(normalized, criterion);
      outcomes.add(
        ProductiveCriterionOutcome(
          id: criterion.id,
          matched: matched,
          weight: criterion.weight,
        ),
      );
      totalWeight += criterion.weight;
      if (matched) {
        matchedWeight += criterion.weight;
      }
      if (criterion.requiredForPass && !matched) {
        requiredPassed = false;
      }
    }
    final score = totalWeight == 0 ? 0.0 : matchedWeight / totalWeight;
    final passed = requiredPassed && score >= definition.minimumScore;
    final matchedSemanticCriteria = <String>{
      for (final criterion in rubric.criteria)
        if ((criterion.kind == ProductiveCriterionKind.meaningSlot ||
                criterion.kind ==
                    ProductiveCriterionKind.sameIdentityAcrossRegisters) &&
            outcomes.any(
              (outcome) => outcome.id == criterion.id && outcome.matched,
            ))
          criterion.id,
    };
    return ProductiveAssessmentResult._(
      assessmentItemId: definition.assessmentItemId,
      canDoSegmentId: definition.canDoSegmentId,
      definitionFingerprint: definition.authorityFingerprint,
      score: score,
      passed: passed,
      occurredAt: _validTimestamp(occurredAt),
      criteria: List.unmodifiable(outcomes),
      coverage: ProductiveEvidenceCoverage(
        matchedCriterionIds: outcomes
            .where((outcome) => outcome.matched)
            .map((outcome) => outcome.id),
        semanticSlotIds: {...semanticSlotIds, ...matchedSemanticCriteria},
        sourceSnippetIds: sourceSnippetIds,
        slotSourceBindings: slotSourceBindings,
      ),
      supportingEvidenceIds: const [],
      oralScore: null,
      assessmentAttemptId: null,
      localReferenceText:
          passed && definition.evidenceMode == SegmentEvidenceMode.openWriting
          ? normalized
          : null,
    );
  }
}

final class ProductiveEvidenceNode {
  ProductiveEvidenceNode({
    required String sourceSnippetId,
    required Iterable<ProductiveEvidenceRole> roles,
  }) : sourceSnippetId = _requiredId(sourceSnippetId, 'source snippet ID'),
       roles = Set.unmodifiable(roles) {
    if (this.roles.isEmpty) {
      throw const FormatException(
        'Connected-evidence node requires a relationship role.',
      );
    }
  }

  final String sourceSnippetId;
  final Set<ProductiveEvidenceRole> roles;
}

final class ProductiveConnectedEvidenceEngine {
  const ProductiveConnectedEvidenceEngine();

  ProductiveAssessmentResult evaluate({
    required ProductiveAssessmentCatalog catalog,
    required ProductiveAssessmentDefinition definition,
    required Iterable<ProductiveEvidenceNode> nodes,
    required DateTime occurredAt,
  }) {
    final rubric = definition.connectedEvidenceRubric;
    if (rubric == null) {
      throw FormatException(
        '${definition.evidenceMode.code} is not connected evidence.',
      );
    }
    final bundle = catalog.bundleForSegment(definition.canDoSegmentId);
    final project = bundle == null
        ? null
        : catalog.projectsById[bundle.projectId];
    final step = project?.steps.singleWhere(
      (candidate) => candidate.id == bundle!.stepId,
    );
    final allowedSnippetIds = step?.snippetIds.toSet() ?? const <String>{};
    final uniqueNodes = <String, ProductiveEvidenceNode>{};
    var allProvenanceValid = true;
    for (final node in nodes) {
      if (!allowedSnippetIds.contains(node.sourceSnippetId)) {
        allProvenanceValid = false;
        continue;
      }
      final snippet = catalog.snippetsById[node.sourceSnippetId];
      if (snippet == null ||
          snippet.provenance.ko.trim().isEmpty ||
          !snippet.supportedRoles.containsAll(node.roles)) {
        allProvenanceValid = false;
        continue;
      }
      uniqueNodes[node.sourceSnippetId] = node;
    }
    final roles = uniqueNodes.values.expand((node) => node.roles).toSet();
    final allowedPairs = <String>{
      for (final relationship in rubric.relationshipRequirements)
        for (final sourceId in relationship.oneOfSourceSnippetIds)
          '$sourceId|${relationship.role.code}',
    };
    final submittedPairs = <String>{
      for (final node in uniqueNodes.values)
        for (final role in node.roles) '${node.sourceSnippetId}|${role.code}',
    };
    final outcomes = <ProductiveCriterionOutcome>[
      ProductiveCriterionOutcome(
        id: 'source_nodes',
        matched: uniqueNodes.length >= rubric.minimumSourceNodes,
        weight: 1,
      ),
      for (final role in rubric.requiredRoles)
        ProductiveCriterionOutcome(
          id: role.code,
          matched: roles.contains(role),
          weight: 1,
        ),
      for (final sourceId in rubric.requiredSourceSnippetIds)
        ProductiveCriterionOutcome(
          id: 'required_source:$sourceId',
          matched: uniqueNodes.containsKey(sourceId),
          weight: 1,
        ),
      for (var index = 0; index < rubric.oneOfSourceGroups.length; index++)
        ProductiveCriterionOutcome(
          id: 'source_group:$index',
          matched: rubric.oneOfSourceGroups[index].any(uniqueNodes.containsKey),
          weight: 1,
        ),
      for (final relationship in rubric.relationshipRequirements)
        ProductiveCriterionOutcome(
          id: 'relationship:${relationship.id}',
          matched: relationship.oneOfSourceSnippetIds.any(
            (sourceId) =>
                uniqueNodes[sourceId]?.roles.contains(relationship.role) ==
                true,
          ),
          weight: 1,
        ),
      ProductiveCriterionOutcome(
        id: 'relationship_mapping',
        matched:
            submittedPairs.isNotEmpty &&
            submittedPairs.every(allowedPairs.contains),
        weight: 1,
      ),
      ProductiveCriterionOutcome(
        id: 'provenance',
        matched:
            !rubric.requireProvenance ||
            (uniqueNodes.isNotEmpty && allProvenanceValid),
        weight: 1,
      ),
    ];
    final matched = outcomes.where((outcome) => outcome.matched).length;
    final score = matched / outcomes.length;
    final passed =
        outcomes.every((outcome) => outcome.matched) &&
        score >= definition.minimumScore;
    return ProductiveAssessmentResult._(
      assessmentItemId: definition.assessmentItemId,
      canDoSegmentId: definition.canDoSegmentId,
      definitionFingerprint: definition.authorityFingerprint,
      score: score,
      passed: passed,
      occurredAt: _validTimestamp(occurredAt),
      criteria: List.unmodifiable(outcomes),
      coverage: ProductiveEvidenceCoverage(
        matchedCriterionIds: outcomes
            .where((outcome) => outcome.matched)
            .map((outcome) => outcome.id),
        sourceSnippetIds: uniqueNodes.keys,
        sourceRoleBindings: [
          for (final node in uniqueNodes.values)
            for (final role in node.roles)
              ProductiveSourceRoleBinding(
                sourceSnippetId: node.sourceSnippetId,
                roleCode: role.code,
              ),
        ],
      ),
      supportingEvidenceIds: const [],
      oralScore: null,
      assessmentAttemptId: null,
      localReferenceText: null,
    );
  }
}

/// Ephemeral response from a trusted continuous, unscripted Korean speech
/// authority. Callers must discard [recognizedTranscript] after deterministic
/// client-side semantic scoring. No implementation ships in PR2.
final class ProductiveOralProductionAuthorityResult {
  const ProductiveOralProductionAuthorityResult({
    required this.assessmentAttemptId,
    required this.recognizedTranscript,
    required this.durationMilliseconds,
    required this.pronunciation,
    required this.accuracy,
    required this.fluency,
  });

  final String assessmentAttemptId;
  final String recognizedTranscript;
  final int durationMilliseconds;
  final double pronunciation;
  final double accuracy;
  final double fluency;
}

abstract interface class ProductiveOralProductionAuthority {
  Future<ProductiveOralProductionAuthorityResult> assessUnscripted({
    required Uint8List pcm16,
    required String locale,
    required String assessmentAttemptId,
  });
}

final class ProductiveOralAssessmentEngine {
  const ProductiveOralAssessmentEngine();

  /// A scripted pronunciation/read-aloud gateway is practice-only and can
  /// never mint course-eligible oral-production evidence.
  @Deprecated('Use evaluateProduction with a trusted unscripted authority.')
  Future<ProductiveAssessmentResult> evaluate({
    required ProductiveAssessmentDefinition definition,
    required ProductiveAssessmentResult referenceWritingResult,
    required ProductiveMasteryEvidence referenceWritingEvidence,
    required PronunciationAssessmentGateway gateway,
    required Uint8List pcm16,
    required bool userConsented,
    required DateTime occurredAt,
  }) async => _failedOralResult(definition, occurredAt);

  Future<ProductiveAssessmentResult> evaluateProduction({
    required ProductiveAssessmentCatalog catalog,
    required ProductiveAssessmentDefinition definition,
    required ProductiveAssessmentResult referenceWritingResult,
    required ProductiveMasteryEvidence referenceWritingEvidence,
    required ProductiveStructuredWritingSubmission referenceWritingSubmission,
    required ProductiveOralProductionAuthority authority,
    required Uint8List pcm16,
    required bool userConsented,
    required DateTime occurredAt,
  }) async {
    final rubric = definition.oralRubric;
    if (rubric == null) {
      throw FormatException(
        '${definition.evidenceMode.code} is not an oral assessment.',
      );
    }
    final localReference = referenceWritingResult._localReferenceText;
    final validReference =
        referenceWritingResult.passed &&
        localReference != null &&
        localReference == _normalizeWriting(referenceWritingSubmission.text) &&
        referenceWritingEvidence.courseEligible &&
        referenceWritingEvidence.evidenceMode ==
            SegmentEvidenceMode.openWriting &&
        referenceWritingEvidence.assessmentItemId ==
            referenceWritingResult.assessmentItemId &&
        referenceWritingEvidence.canDoSegmentId ==
            referenceWritingResult.canDoSegmentId &&
        definition.prerequisiteAssessmentItemIds.contains(
          referenceWritingEvidence.assessmentItemId,
        );
    if (!userConsented || !validReference || pcm16.isEmpty) {
      return _failedOralResult(definition, occurredAt);
    }
    catalog.definitionFor(definition.assessmentItemId) ??
        (throw const FormatException(
          'Oral production requires a canonical assessment catalog.',
        ));
    final timestamp = _validTimestamp(occurredAt);
    final attemptId = stableContentId('productive_oral_attempt', [
      definition.assessmentItemId,
      referenceWritingEvidence.id,
      timestamp.toIso8601String(),
    ]).replaceFirst(':', '_');
    ProductiveOralProductionAuthorityResult result;
    try {
      result = await authority.assessUnscripted(
        pcm16: pcm16,
        locale: 'ko-KR',
        assessmentAttemptId: attemptId,
      );
    } on Object {
      return _failedOralResult(definition, occurredAt);
    }
    final transcript = _normalizeWriting(result.recognizedTranscript);
    final materialParaphrase = _isMaterialOralParaphrase(
      transcript: transcript,
      referenceWriting: referenceWritingSubmission.text,
    );
    final rawDimensions = [
      result.pronunciation,
      result.accuracy,
      result.fluency,
    ];
    if (result.assessmentAttemptId != attemptId ||
        rawDimensions.any(
          (score) => !score.isFinite || score < 0 || score > 1,
        )) {
      return _failedOralResult(definition, occurredAt);
    }

    final coveredSlots = <String>{};
    for (final entry in rubric.semanticSlotMentionVariants.entries) {
      if (entry.value.any(
        (variant) =>
            _containsBoundedPhrase(transcript, _normalizeWriting(variant)),
      )) {
        coveredSlots.add(entry.key);
      }
    }
    final mentionedSources = <String>{};
    for (final entry in rubric.sourceMentionVariants.entries) {
      if (entry.value.any(
        (variant) => transcript.contains(_normalizeWriting(variant)),
      )) {
        mentionedSources.add(entry.key);
      }
    }
    final linkedSources = referenceWritingSubmission.linkedSourceSpanIds.values
        .expand((ids) => ids)
        .toSet();
    final sourceCoverage = mentionedSources.intersection(linkedSources);
    final markerOutcomes = <ProductiveCriterionOutcome>[
      for (var index = 0; index < rubric.discourseMarkerGroups.length; index++)
        ProductiveCriterionOutcome(
          id: 'oral_discourse:$index',
          matched: rubric.discourseMarkerGroups[index].any(
            (marker) => _containsBoundedPhrase(transcript, marker),
          ),
          weight: 1,
        ),
    ];
    final outcomes = <ProductiveCriterionOutcome>[
      ProductiveCriterionOutcome(
        id: 'duration',
        matched:
            result.durationMilliseconds >= rubric.minimumDurationMilliseconds &&
            result.durationMilliseconds <= rubric.maximumDurationMilliseconds,
        weight: 1,
      ),
      ProductiveCriterionOutcome(
        id: 'transcript_length',
        matched: transcript.runes.length >= rubric.minimumTranscriptCodePoints,
        weight: 1,
      ),
      ProductiveCriterionOutcome(
        id: 'not_near_verbatim_read_aloud',
        matched: materialParaphrase,
        weight: 1,
      ),
      ProductiveCriterionOutcome(
        id: 'pronunciation',
        matched: result.pronunciation >= rubric.minimumPronunciation,
        weight: 1,
      ),
      ProductiveCriterionOutcome(
        id: 'accuracy',
        matched: result.accuracy >= rubric.minimumAccuracy,
        weight: 1,
      ),
      ProductiveCriterionOutcome(
        id: 'fluency',
        matched: result.fluency >= rubric.minimumFluency,
        weight: 1,
      ),
      ProductiveCriterionOutcome(
        id: 'semantic_slots',
        matched: coveredSlots.containsAll(rubric.requiredSemanticSlotIds),
        weight: 1,
      ),
      ProductiveCriterionOutcome(
        id: 'required_sources',
        matched: sourceCoverage.containsAll(rubric.requiredSourceSnippetIds),
        weight: 1,
      ),
      for (var index = 0; index < rubric.oneOfSourceGroups.length; index++)
        ProductiveCriterionOutcome(
          id: 'oral_source_group:$index',
          matched: rubric.oneOfSourceGroups[index].any(sourceCoverage.contains),
          weight: 1,
        ),
      ...markerOutcomes,
    ];
    final score = (result.pronunciation + result.accuracy + result.fluency) / 3;
    final passed =
        outcomes.every((outcome) => outcome.matched) &&
        score >= definition.minimumScore;
    final oralScore = passed
        ? ProductiveOralScore(
            pronunciation: result.pronunciation,
            accuracy: result.accuracy,
            fluency: result.fluency,
            durationMilliseconds: result.durationMilliseconds,
            transcriptCodePoints: transcript.runes.length,
            semanticSlotIds: coveredSlots.toList()..sort(),
            sourceSnippetIds: sourceCoverage.toList()..sort(),
            discourseMarkerGroupIds:
                markerOutcomes
                    .where((outcome) => outcome.matched)
                    .map((outcome) => outcome.id)
                    .toList()
                  ..sort(),
          )
        : null;
    return ProductiveAssessmentResult._(
      assessmentItemId: definition.assessmentItemId,
      canDoSegmentId: definition.canDoSegmentId,
      definitionFingerprint: definition.authorityFingerprint,
      score: score,
      passed: passed,
      occurredAt: timestamp,
      criteria: List.unmodifiable(outcomes),
      coverage: ProductiveEvidenceCoverage(
        matchedCriterionIds: outcomes
            .where((outcome) => outcome.matched)
            .map((outcome) => outcome.id),
        semanticSlotIds: coveredSlots,
        sourceSnippetIds: sourceCoverage,
      ),
      supportingEvidenceIds: passed ? [referenceWritingEvidence.id] : const [],
      oralScore: oralScore,
      assessmentAttemptId: passed ? attemptId : null,
      localReferenceText: null,
    );
  }

  ProductiveAssessmentResult _failedOralResult(
    ProductiveAssessmentDefinition definition,
    DateTime occurredAt,
  ) {
    return ProductiveAssessmentResult._(
      assessmentItemId: definition.assessmentItemId,
      canDoSegmentId: definition.canDoSegmentId,
      definitionFingerprint: definition.authorityFingerprint,
      score: 0,
      passed: false,
      occurredAt: _validTimestamp(occurredAt),
      criteria: const [],
      coverage: ProductiveEvidenceCoverage(),
      supportingEvidenceIds: const [],
      oralScore: null,
      assessmentAttemptId: null,
      localReferenceText: null,
    );
  }
}

/// Derives verified segment identities from immutable successful proof only.
/// There is intentionally no writable `verifiedCanDoSegmentIds` authority.
Set<String> verifiedCanDoSegmentIds({
  required Iterable<ProductiveMasteryEvidence> evidence,
  required Iterable<ProductiveProjectStepEvidence> projectStepEvidence,
  required CourseSegmentCatalog segmentCatalog,
  required ProductiveAssessmentCatalog assessmentCatalog,
}) {
  assessmentCatalog.bind(segmentCatalog);
  final result = <String>{};
  final records = trustedProductiveMasteryEvidence(
    evidence: evidence,
    assessmentCatalog: assessmentCatalog,
  );
  final trustedSteps = trustedProductiveProjectStepEvidence(
    evidence: projectStepEvidence,
    assessmentCatalog: assessmentCatalog,
  );
  for (final segment in segmentCatalog.assessmentAuthoritySegments) {
    if (segment.evidencePolicy != SegmentEvidencePolicy.allOf) {
      continue;
    }
    final bundle = assessmentCatalog.bundleForSegment(segment.id);
    if (bundle != null) {
      final project = assessmentCatalog.projectsById[bundle.projectId]!;
      final assessedStep = project.steps.singleWhere(
        (step) => step.id == bundle.stepId,
      );
      final reviewStep = project.steps.singleWhere(
        (step) => step.order == assessedStep.order - 1,
      );
      if (!trustedSteps.any(
        (entry) =>
            entry.projectId == project.id && entry.stepId == reviewStep.id,
      )) {
        continue;
      }
      if (assessedStep.order == 4) {
        final stepTwo = project.steps.singleWhere((step) => step.order == 2);
        final earlierBundle = assessmentCatalog.bundles.singleWhere(
          (candidate) =>
              candidate.projectId == project.id &&
              candidate.stepId == stepTwo.id,
        );
        if (!result.contains(earlierBundle.canDoSegmentId)) {
          continue;
        }
      }
    }
    var segmentPassed = true;
    for (final requirement in segment.assessmentRequirements) {
      for (final conceptId in segment.requiredConceptIds) {
        final matching = records.where(
          (entry) =>
              entry.canDoSegmentId == segment.id &&
              entry.assessmentItemId == requirement.assessmentItemId &&
              entry.missionContentLinkId == requirement.missionContentLinkId &&
              entry.courseUnitId == segment.parentCourseUnitId &&
              entry.conceptId == conceptId &&
              entry.evidenceMode == requirement.evidenceMode &&
              entry.rubricVersion == requirement.rubricVersion &&
              entry.score >= requirement.minimumScore,
        );
        if (matching.isEmpty) {
          segmentPassed = false;
          break;
        }
      }
      if (!segmentPassed) {
        break;
      }
    }
    if (segmentPassed) {
      result.add(segment.id);
    }
  }
  return Set.unmodifiable(result);
}

/// Keeps only odd-step receipts that still match the exact first-party
/// project topology and source provenance in the current catalog.
List<ProductiveProjectStepEvidence> trustedProductiveProjectStepEvidence({
  required Iterable<ProductiveProjectStepEvidence> evidence,
  required ProductiveAssessmentCatalog assessmentCatalog,
}) {
  final trusted = <ProductiveProjectStepEvidence>[];
  final seen = <String>{};
  for (final entry in evidence) {
    if (!seen.add(entry.id)) {
      throw const FormatException(
        'Project source-review receipt IDs must be unique.',
      );
    }
    final step = assessmentCatalog.projectStepFor(
      entry.projectId,
      entry.stepId,
    );
    if (step == null ||
        step.order != entry.stepOrder ||
        (step.order != 1 && step.order != 3) ||
        entry.courseUnitId !=
            assessmentCatalog.courseUnitIdForProjectStep(
              entry.projectId,
              entry.stepId,
            ) ||
        entry.authorityFingerprint !=
            assessmentCatalog.projectStepAuthorityFingerprint(
              entry.projectId,
              entry.stepId,
            ) ||
        entry.evaluatorVersion != productiveEvaluatorVersion ||
        !_sameSet(
          entry.reviewedSourceSnippetIds,
          assessmentCatalog.introducedSourceIdsForStep(
            entry.projectId,
            entry.stepId,
          ),
        )) {
      continue;
    }
    trusted.add(entry);
  }
  trusted.sort((left, right) {
    final project = left.projectId.compareTo(right.projectId);
    return project != 0 ? project : left.stepOrder.compareTo(right.stepOrder);
  });
  return List.unmodifiable(trusted);
}

/// Returns only evidence whose exact catalog authority and complete typed
/// prerequisite chain can be proven from the same immutable evidence set.
///
/// Callers at both the write boundary and projection boundary use this helper
/// to detect catalog drift, incomplete dependency chains, and corrupted
/// non-raw summaries. This is catalog-validated integrity, not adversarial
/// anti-cheat or remote attestation.
List<ProductiveMasteryEvidence> trustedProductiveMasteryEvidence({
  required Iterable<ProductiveMasteryEvidence> evidence,
  required ProductiveAssessmentCatalog assessmentCatalog,
}) {
  final records = evidence.where((entry) => entry.courseEligible).toList();
  final recordsById = <String, ProductiveMasteryEvidence>{};
  for (final record in records) {
    if (recordsById.containsKey(record.id)) {
      throw const FormatException(
        'Productive evidence IDs must be unique before projection.',
      );
    }
    recordsById[record.id] = record;
  }
  final trust = _ProductiveEvidenceTrustIndex(
    assessmentCatalog: assessmentCatalog,
    recordsById: recordsById,
  );
  final trusted = records.where(trust.isTrusted).toList()
    ..sort((left, right) => left.id.compareTo(right.id));
  return List.unmodifiable(trusted);
}

final class _ProductiveEvidenceTrustIndex {
  _ProductiveEvidenceTrustIndex({
    required this.assessmentCatalog,
    required this.recordsById,
  });

  final ProductiveAssessmentCatalog assessmentCatalog;
  final Map<String, ProductiveMasteryEvidence> recordsById;
  final Map<String, bool> _trustedMemo = <String, bool>{};
  final Set<String> _visiting = <String>{};

  bool isTrusted(ProductiveMasteryEvidence record) {
    final cached = _trustedMemo[record.id];
    if (cached != null) {
      return cached;
    }
    if (!_visiting.add(record.id)) {
      return false;
    }
    final definition = assessmentCatalog.definitionFor(record.assessmentItemId);
    var trusted =
        definition != null &&
        definition.canDoSegmentId == record.canDoSegmentId &&
        definition.courseUnitId == record.courseUnitId &&
        definition.missionContentLinkId == record.missionContentLinkId &&
        definition.conceptIds.contains(record.conceptId) &&
        definition.evidenceMode == record.evidenceMode &&
        definition.rubricVersion == record.rubricVersion &&
        definition.authorityFingerprint == record.definitionFingerprint &&
        record.evaluatorVersion == productiveEvaluatorVersion &&
        record.score >= definition.minimumScore &&
        _coverageMatches(definition, record) &&
        _oralResultMatches(definition, record);
    if (trusted) {
      for (final prerequisiteId in definition.prerequisiteAssessmentItemIds) {
        final prerequisite = assessmentCatalog.definitionFor(prerequisiteId)!;
        for (final conceptId in prerequisite.conceptIds) {
          final candidates = record.prerequisiteEvidenceIds
              .map((id) => recordsById[id])
              .whereType<ProductiveMasteryEvidence>()
              .where(
                (candidate) =>
                    candidate.assessmentItemId == prerequisiteId &&
                    candidate.conceptId == conceptId,
              );
          if (!candidates.any(isTrusted)) {
            trusted = false;
            break;
          }
        }
        if (!trusted) {
          break;
        }
      }
    }
    _visiting.remove(record.id);
    _trustedMemo[record.id] = trusted;
    return trusted;
  }

  bool _oralResultMatches(
    ProductiveAssessmentDefinition definition,
    ProductiveMasteryEvidence record,
  ) {
    if (definition.evidenceMode != SegmentEvidenceMode.oralProduction) {
      return record.oralScore == null && record.assessmentAttemptId == null;
    }
    final rubric = definition.oralRubric;
    final score = record.oralScore;
    if (rubric == null || score == null || record.assessmentAttemptId == null) {
      return false;
    }
    final expectedScore =
        (score.pronunciation + score.accuracy + score.fluency) / 3;
    return score.pronunciation >= rubric.minimumPronunciation &&
        score.accuracy >= rubric.minimumAccuracy &&
        score.fluency >= rubric.minimumFluency &&
        score.durationMilliseconds >= rubric.minimumDurationMilliseconds &&
        score.durationMilliseconds <= rubric.maximumDurationMilliseconds &&
        score.transcriptCodePoints >= rubric.minimumTranscriptCodePoints &&
        score.semanticSlotIds.toSet().containsAll(
          rubric.requiredSemanticSlotIds,
        ) &&
        score.sourceSnippetIds.toSet().containsAll(
          rubric.requiredSourceSnippetIds,
        ) &&
        rubric.oneOfSourceGroups.every(
          (group) => group.any(score.sourceSnippetIds.contains),
        ) &&
        score.discourseMarkerGroupIds.toSet().containsAll({
          for (
            var index = 0;
            index < rubric.discourseMarkerGroups.length;
            index++
          )
            'oral_discourse:$index',
        }) &&
        (expectedScore - record.score).abs() < 0.000000001;
  }

  bool _coverageMatches(
    ProductiveAssessmentDefinition definition,
    ProductiveMasteryEvidence record,
  ) {
    final coverage = record.coverage;
    switch (definition.evidenceMode) {
      case SegmentEvidenceMode.guidedProduction:
      case SegmentEvidenceMode.dictation:
      case SegmentEvidenceMode.connectedProduction:
      case SegmentEvidenceMode.openWriting:
        return _textCoverageMatches(definition, record);
      case SegmentEvidenceMode.connectedEvidence:
        return _connectedCoverageMatches(definition, record);
      case SegmentEvidenceMode.oralProduction:
        final oral = record.oralScore;
        if (oral == null ||
            !_sameSet(coverage.semanticSlotIds, oral.semanticSlotIds) ||
            !_sameSet(coverage.sourceSnippetIds, oral.sourceSnippetIds) ||
            coverage.slotSourceBindings.isNotEmpty ||
            coverage.sourceRoleBindings.isNotEmpty) {
          return false;
        }
        final rubric = definition.oralRubric!;
        final expectedCriteria = <String>{
          'duration',
          'transcript_length',
          'not_near_verbatim_read_aloud',
          'pronunciation',
          'accuracy',
          'fluency',
          'semantic_slots',
          'required_sources',
          for (var index = 0; index < rubric.oneOfSourceGroups.length; index++)
            'oral_source_group:$index',
          for (
            var index = 0;
            index < rubric.discourseMarkerGroups.length;
            index++
          )
            'oral_discourse:$index',
        };
        return _sameSet(coverage.matchedCriterionIds, expectedCriteria);
    }
  }

  bool _textCoverageMatches(
    ProductiveAssessmentDefinition definition,
    ProductiveMasteryEvidence record,
  ) {
    final rubric = definition.textRubric;
    if (rubric == null ||
        record.oralScore != null ||
        record.assessmentAttemptId != null ||
        record.coverage.sourceRoleBindings.isNotEmpty) {
      return false;
    }
    final coverage = record.coverage;
    final matched = coverage.matchedCriterionIds.toSet();
    final syntheticIds = <String>{
      if (rubric.requiresStructuredSubmission) ...{
        for (final slotId in rubric.requiredStructuredSlotIds) 'slot:$slotId',
        'distinct_sources',
        for (final sourceId in rubric.requiredSourceSnippetIds)
          'required_source:$sourceId',
        for (var index = 0; index < rubric.oneOfSourceGroups.length; index++)
          'source_group:$index',
        for (
          var index = 0;
          index < rubric.discourseMarkerGroups.length;
          index++
        )
          'discourse:$index',
      },
    };
    final criterionById = {
      for (final criterion in rubric.criteria) criterion.id: criterion,
    };
    final knownIds = {...criterionById.keys, ...syntheticIds};
    if (!knownIds.containsAll(matched) ||
        rubric.criteria.any(
          (criterion) =>
              criterion.requiredForPass && !matched.contains(criterion.id),
        ) ||
        !matched.containsAll(syntheticIds)) {
      return false;
    }
    final totalWeight =
        syntheticIds.length +
        rubric.criteria.fold<double>(
          0,
          (total, criterion) => total + criterion.weight,
        );
    final matchedWeight =
        syntheticIds.where(matched.contains).length +
        rubric.criteria
            .where((criterion) => matched.contains(criterion.id))
            .fold<double>(0, (total, criterion) => total + criterion.weight);
    final expectedScore = totalWeight == 0 ? 0.0 : matchedWeight / totalWeight;
    if ((expectedScore - record.score).abs() >= 0.000000001) {
      return false;
    }
    final semanticCriteria = rubric.criteria
        .where(
          (criterion) =>
              matched.contains(criterion.id) &&
              (criterion.kind == ProductiveCriterionKind.meaningSlot ||
                  criterion.kind ==
                      ProductiveCriterionKind.sameIdentityAcrossRegisters),
        )
        .map((criterion) => criterion.id)
        .toSet();
    if (!rubric.requiresStructuredSubmission) {
      return _sameSet(coverage.semanticSlotIds, semanticCriteria) &&
          coverage.sourceSnippetIds.isEmpty &&
          coverage.slotSourceBindings.isEmpty;
    }
    final expectedSlots = {
      ...rubric.requiredStructuredSlotIds,
      ...semanticCriteria,
    };
    if (!_sameSet(coverage.semanticSlotIds, expectedSlots)) {
      return false;
    }
    final step = _projectStepForDefinition(definition);
    if (step == null) {
      return false;
    }
    final allowedSources = step.snippetIds.toSet();
    final boundSources = <String>{};
    final boundSlots = <String>{};
    for (final binding in coverage.slotSourceBindings) {
      if (!rubric.requiredStructuredSlotIds.contains(binding.semanticSlotId) ||
          !allowedSources.contains(binding.sourceSnippetId)) {
        return false;
      }
      boundSlots.add(binding.semanticSlotId);
      boundSources.add(binding.sourceSnippetId);
    }
    return boundSlots.containsAll(rubric.requiredStructuredSlotIds) &&
        _sameSet(coverage.sourceSnippetIds, boundSources) &&
        boundSources.length >= rubric.minimumDistinctSourceSpanIds &&
        boundSources.containsAll(rubric.requiredSourceSnippetIds) &&
        rubric.oneOfSourceGroups.every(
          (group) => group.any(boundSources.contains),
        );
  }

  bool _connectedCoverageMatches(
    ProductiveAssessmentDefinition definition,
    ProductiveMasteryEvidence record,
  ) {
    final rubric = definition.connectedEvidenceRubric;
    final step = _projectStepForDefinition(definition);
    final coverage = record.coverage;
    if (rubric == null ||
        step == null ||
        record.oralScore != null ||
        record.assessmentAttemptId != null ||
        coverage.semanticSlotIds.isNotEmpty ||
        coverage.slotSourceBindings.isNotEmpty) {
      return false;
    }
    final allowedSources = step.snippetIds.toSet();
    final rolesBySource = <String, Set<ProductiveEvidenceRole>>{};
    for (final binding in coverage.sourceRoleBindings) {
      final role = ProductiveEvidenceRoleX.tryFromCode(binding.roleCode);
      final snippet = assessmentCatalog.snippetsById[binding.sourceSnippetId];
      if (role == null ||
          !allowedSources.contains(binding.sourceSnippetId) ||
          snippet == null ||
          !snippet.supportedRoles.contains(role)) {
        return false;
      }
      rolesBySource.putIfAbsent(binding.sourceSnippetId, () => {}).add(role);
    }
    if (!_sameSet(coverage.sourceSnippetIds, rolesBySource.keys) ||
        rolesBySource.length < rubric.minimumSourceNodes) {
      return false;
    }
    final allRoles = rolesBySource.values.expand((roles) => roles).toSet();
    if (!allRoles.containsAll(rubric.requiredRoles) ||
        !rolesBySource.keys.toSet().containsAll(
          rubric.requiredSourceSnippetIds,
        ) ||
        !rubric.oneOfSourceGroups.every(
          (group) => group.any(rolesBySource.containsKey),
        ) ||
        !rubric.relationshipRequirements.every(
          (relationship) => relationship.oneOfSourceSnippetIds.any(
            (sourceId) =>
                rolesBySource[sourceId]?.contains(relationship.role) == true,
          ),
        )) {
      return false;
    }
    final expectedCriteria = <String>{
      'source_nodes',
      for (final role in rubric.requiredRoles) role.code,
      for (final sourceId in rubric.requiredSourceSnippetIds)
        'required_source:$sourceId',
      for (var index = 0; index < rubric.oneOfSourceGroups.length; index++)
        'source_group:$index',
      for (final relationship in rubric.relationshipRequirements)
        'relationship:${relationship.id}',
      'relationship_mapping',
      'provenance',
    };
    return _sameSet(coverage.matchedCriterionIds, expectedCriteria) &&
        (record.score - 1).abs() < 0.000000001;
  }

  ProductiveProjectStep? _projectStepForDefinition(
    ProductiveAssessmentDefinition definition,
  ) {
    final bundle = assessmentCatalog.bundleForSegment(
      definition.canDoSegmentId,
    );
    if (bundle == null) {
      return null;
    }
    return assessmentCatalog.projectStepFor(bundle.projectId, bundle.stepId);
  }
}

bool _matchesCriterion(
  String normalizedInput,
  ProductiveTextCriterion criterion,
) {
  final normalizedVariants = criterion.acceptedVariants
      .map(_normalizeWriting)
      .where((variant) => variant.isNotEmpty);
  switch (criterion.kind) {
    case ProductiveCriterionKind.exactAnswer:
      final input = _stripTerminalPunctuation(normalizedInput);
      return normalizedVariants.any(
        (variant) => input == _stripTerminalPunctuation(variant),
      );
    case ProductiveCriterionKind.sentenceEnding:
      final input = _stripTerminalPunctuation(normalizedInput);
      return normalizedVariants.any(
        (variant) => input.endsWith(_stripTerminalPunctuation(variant)),
      );
    case ProductiveCriterionKind.meaningSlot:
    case ProductiveCriterionKind.tokenSequence:
      return normalizedVariants.any(
        (variant) => _containsBoundedPhrase(normalizedInput, variant),
      );
    case ProductiveCriterionKind.sameIdentityAcrossRegisters:
      return _usesSameIdentityAcrossRegisters(normalizedInput);
  }
}

bool _usesSameIdentityAcrossRegisters(String input) {
  String? capture(RegExp pattern) => pattern.firstMatch(input)?.group(1);

  final formal = capture(
    RegExp(r'(?:저는|제 이름은)\s+([가-힣A-Za-z][가-힣A-Za-z0-9_-]*?)\s*입니다'),
  );
  final polite = capture(
    RegExp(r'(?:저는|제 이름은)\s+([가-힣A-Za-z][가-힣A-Za-z0-9_-]*?)\s*(?:이에요|예요)'),
  );
  final casual = capture(
    RegExp(r'(?:나는|난|나)\s+([가-힣A-Za-z][가-힣A-Za-z0-9_-]*?)\s*(?:이야|야)'),
  );
  if (formal == null || polite == null || casual == null) {
    return false;
  }
  final identity = formal.toLowerCase();
  return identity == polite.toLowerCase() && identity == casual.toLowerCase();
}

bool _containsBoundedPhrase(String input, String phrase) {
  if (phrase.isEmpty) {
    return false;
  }
  var index = input.indexOf(phrase);
  while (index >= 0) {
    final before = index == 0 ? null : input.codeUnitAt(index - 1);
    final afterIndex = index + phrase.length;
    final after = afterIndex >= input.length
        ? null
        : input.codeUnitAt(afterIndex);
    if (!_isWordCodeUnit(before) && !_isWordCodeUnit(after)) {
      return true;
    }
    index = input.indexOf(phrase, index + 1);
  }
  return false;
}

bool _isWordCodeUnit(int? value) {
  if (value == null) {
    return false;
  }
  return (value >= 0x30 && value <= 0x39) ||
      (value >= 0x41 && value <= 0x5a) ||
      (value >= 0x61 && value <= 0x7a) ||
      (value >= 0xac00 && value <= 0xd7a3);
}

String _normalizeWriting(String input) {
  return BookAnalysisTextPreprocessor.normalizeNfc(input)
      .replaceAll(RegExp(r'[\u00a0\u2000-\u200a\u202f\u205f\u3000]'), ' ')
      .replaceAll('，', ',')
      .replaceAll('。', '.')
      .replaceAll('！', '!')
      .replaceAll('？', '?')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
}

const double _nearVerbatimLcsThreshold = 0.9;
const int _maximumOralComparisonRunes = 4096;

/// Compares punctuation- and spacing-independent lexical sequences. A
/// transcript must materially re-formulate the prior writing; punctuation,
/// spacing, or a token/ending edit is still read-aloud practice, not a new
/// oral-production performance.
bool _isMaterialOralParaphrase({
  required String transcript,
  required String referenceWriting,
}) {
  final spoken = _oralLexicalRunes(transcript);
  final written = _oralLexicalRunes(referenceWriting);
  if (spoken.isEmpty ||
      written.isEmpty ||
      spoken.length > _maximumOralComparisonRunes ||
      written.length > _maximumOralComparisonRunes) {
    return false;
  }
  final longerLength = spoken.length > written.length
      ? spoken.length
      : written.length;
  final shorterLength = spoken.length < written.length
      ? spoken.length
      : written.length;
  final commonLength = _longestCommonSubsequenceLength(spoken, written);
  return commonLength / longerLength < _nearVerbatimLcsThreshold &&
      commonLength / shorterLength < _nearVerbatimLcsThreshold;
}

List<int> _oralLexicalRunes(String input) => _normalizeWriting(
  input,
).runes.where(_isOralLexicalRune).toList(growable: false);

bool _isOralLexicalRune(int rune) {
  return (rune >= 0x30 && rune <= 0x39) ||
      (rune >= 0x41 && rune <= 0x5a) ||
      (rune >= 0x61 && rune <= 0x7a) ||
      (rune >= 0x00c0 && rune <= 0x024f) ||
      (rune >= 0x1100 && rune <= 0x11ff) ||
      (rune >= 0x3130 && rune <= 0x318f) ||
      (rune >= 0x3400 && rune <= 0x9fff) ||
      (rune >= 0xa960 && rune <= 0xa97f) ||
      (rune >= 0xac00 && rune <= 0xd7a3) ||
      (rune >= 0xd7b0 && rune <= 0xd7ff);
}

int _longestCommonSubsequenceLength(List<int> left, List<int> right) {
  final longer = left.length >= right.length ? left : right;
  final shorter = identical(longer, left) ? right : left;
  var previous = List<int>.filled(shorter.length + 1, 0);
  var current = List<int>.filled(shorter.length + 1, 0);
  for (final longerRune in longer) {
    current[0] = 0;
    for (var index = 1; index <= shorter.length; index++) {
      current[index] = longerRune == shorter[index - 1]
          ? previous[index - 1] + 1
          : (previous[index] > current[index - 1]
                ? previous[index]
                : current[index - 1]);
    }
    final swap = previous;
    previous = current;
    current = swap;
  }
  return previous.last;
}

String _stripTerminalPunctuation(String value) {
  return value.replaceFirst(RegExp(r'[.!?]+$'), '').trimRight();
}

DateTime _validTimestamp(DateTime value) {
  final normalized = value.toUtc();
  if (normalized.millisecondsSinceEpoch == 0) {
    throw const FormatException(
      'Productive assessment time must not be epoch.',
    );
  }
  return normalized;
}

double _numericScore(Object? value, String field) {
  if (value is! num) {
    throw FormatException('Productive $field must be numeric.');
  }
  return value.toDouble();
}

int _wholeNumber(Object? value, String field) {
  if (value is! num || !value.isFinite || value != value.toInt()) {
    throw FormatException('Productive $field must be an integer.');
  }
  return value.toInt();
}

double _validScore(double value, String field) {
  if (!value.isFinite || value < 0 || value > 1) {
    throw FormatException('Productive $field must be between 0 and 1.');
  }
  return value;
}

String _requiredId(String value, String field) {
  final normalized = value.trim();
  if (normalized.isEmpty || normalized.contains(RegExp(r'\s'))) {
    throw FormatException('Productive $field must be a nonempty stable ID.');
  }
  return normalized;
}

String _requiredText(String value, String field) {
  final normalized = value.trim();
  if (normalized.isEmpty) {
    throw FormatException('Productive $field must not be empty.');
  }
  return normalized;
}

CurriculumText _localizedText(Object? raw, String field) {
  return _validLocalizedText(
    CurriculumText.fromJson(_stringMap(raw, field)),
    field,
  );
}

CurriculumText _validLocalizedText(CurriculumText value, String field) {
  if (value.ko.trim().isEmpty ||
      value.de.trim().isEmpty ||
      value.en.trim().isEmpty) {
    throw FormatException('Productive $field requires nonempty ko/de/en text.');
  }
  return CurriculumText(
    ko: value.ko.trim(),
    de: value.de.trim(),
    en: value.en.trim(),
  );
}

void _requireUnique(Iterable<String> source, String label) {
  final values = source.toList();
  if (values.length != values.toSet().length) {
    throw FormatException('Duplicate $label IDs are not allowed.');
  }
}

bool _sameSet<T>(Iterable<T> first, Iterable<T> second) {
  final firstSet = first.toSet();
  final secondSet = second.toSet();
  return firstSet.length == secondSet.length && firstSet.containsAll(secondSet);
}

String _snakeEvidenceMode(SegmentEvidenceMode mode) => switch (mode) {
  SegmentEvidenceMode.guidedProduction => 'guided_production',
  SegmentEvidenceMode.dictation => 'dictation',
  SegmentEvidenceMode.connectedProduction => 'connected_production',
  SegmentEvidenceMode.openWriting => 'open_writing',
  SegmentEvidenceMode.oralProduction => 'oral_production',
  SegmentEvidenceMode.connectedEvidence => 'connected_evidence',
};

Map<String, dynamic> _stringMap(Object? value, String label) {
  if (value is! Map) {
    throw FormatException('$label must be an object.');
  }
  return value.map((key, item) => MapEntry(key.toString(), item));
}

Iterable<String> _stringValues(Object? raw, String label) {
  if (raw == null) {
    return const [];
  }
  if (raw is! List) {
    throw FormatException('$label must be a list.');
  }
  return raw.map((value) => value.toString());
}

Iterable<Iterable<String>> _stringGroups(Object? raw, String label) {
  if (raw is! List) {
    throw FormatException('$label must be a list.');
  }
  return raw.map((group) {
    if (group is! List) {
      throw FormatException('$label entries must be lists.');
    }
    return group.map((value) => value.toString());
  });
}

Map<String, Iterable<String>> _stringListMap(Object? raw, String label) {
  final map = _stringMap(raw, label);
  return {
    for (final entry in map.entries)
      entry.key: _stringValues(entry.value, '$label.${entry.key}'),
  };
}

ProductiveProjectDefinition _projectFromJson(Object? raw) {
  final json = _stringMap(raw, 'productive project');
  final rawSteps = json['steps'];
  if (rawSteps is! List) {
    throw const FormatException('Productive project steps must be a list.');
  }
  return ProductiveProjectDefinition(
    id: json['id']?.toString() ?? '',
    steps: rawSteps.map((value) {
      final step = _stringMap(value, 'productive project step');
      final rawOrder = step['order'];
      if (rawOrder is! num) {
        throw const FormatException('Project step order must be numeric.');
      }
      return ProductiveProjectStep(
        id: step['id']?.toString() ?? '',
        order: rawOrder.toInt(),
        snippetIds: _stringValues(step['snippetIds'], 'snippetIds'),
        prerequisiteStepIds: _stringValues(
          step['prerequisiteStepIds'],
          'prerequisiteStepIds',
        ),
        action: _localizedText(step['action'], 'project step action'),
        assessmentItemIds: _stringValues(
          step['assessmentItemIds'],
          'assessmentItemIds',
        ),
      );
    }),
  );
}

ProductiveSourceSnippet _snippetFromJson(Object? raw) {
  final json = _stringMap(raw, 'productive source snippet');
  final rawRoles = json['supportedRoles'];
  if (rawRoles is! List) {
    throw const FormatException('Snippet supportedRoles must be a list.');
  }
  final roles = <ProductiveEvidenceRole>[];
  for (final rawRole in rawRoles) {
    final role = ProductiveEvidenceRoleX.tryFromCode(rawRole.toString());
    if (role == null) {
      throw const FormatException('Unknown snippet support role.');
    }
    roles.add(role);
  }
  return ProductiveSourceSnippet(
    id: json['id']?.toString() ?? '',
    projectId: json['projectId']?.toString() ?? '',
    stepId: json['stepId']?.toString() ?? '',
    provenance: _localizedText(json['provenance'], 'source provenance'),
    text: _localizedText(json['text'], 'source text'),
    supportedRoles: roles,
  );
}

ProductiveAssessmentBundle _bundleFromJson(Object? raw) {
  final json = _stringMap(raw, 'productive assessment bundle');
  return ProductiveAssessmentBundle(
    canDoSegmentId: json['canDoSegmentId']?.toString() ?? '',
    projectId: json['projectId']?.toString() ?? '',
    stepId: json['stepId']?.toString() ?? '',
    assessmentItemIds: _stringValues(
      json['assessmentItemIds'],
      'assessmentItemIds',
    ),
  );
}
