import 'can_do_segment.dart';
import 'content_id.dart';

/// Version of the deterministic, local productive evaluator that produced a
/// durable proof. This is catalog-integrity metadata, not an anti-cheat or
/// remote-attestation guarantee.
const String productiveEvaluatorVersion = 'productive_evaluator_v1';

/// Durable, non-raw proof summary returned by a trusted unscripted-speaking
/// authority. The recognized transcript and audio deliberately never enter
/// this model. Completeness is intentionally absent because it is a scripted
/// read-aloud metric, not an unscripted production metric.
final class ProductiveOralScore {
  factory ProductiveOralScore({
    required double pronunciation,
    required double accuracy,
    required double fluency,
    required int durationMilliseconds,
    required int transcriptCodePoints,
    required Iterable<String> semanticSlotIds,
    required Iterable<String> sourceSnippetIds,
    required Iterable<String> discourseMarkerGroupIds,
  }) {
    if (durationMilliseconds <= 0 || transcriptCodePoints <= 0) {
      throw const FormatException(
        'Productive oral duration and transcript length must be positive.',
      );
    }
    return ProductiveOralScore._(
      pronunciation: _validScore(pronunciation, 'pronunciation'),
      accuracy: _validScore(accuracy, 'accuracy'),
      fluency: _validScore(fluency, 'fluency'),
      durationMilliseconds: durationMilliseconds,
      transcriptCodePoints: transcriptCodePoints,
      semanticSlotIds: _uniqueIds(semanticSlotIds, 'semanticSlotIds'),
      sourceSnippetIds: _uniqueIds(sourceSnippetIds, 'sourceSnippetIds'),
      discourseMarkerGroupIds: _uniqueIds(
        discourseMarkerGroupIds,
        'discourseMarkerGroupIds',
      ),
    );
  }

  const ProductiveOralScore._({
    required this.pronunciation,
    required this.accuracy,
    required this.fluency,
    required this.durationMilliseconds,
    required this.transcriptCodePoints,
    required this.semanticSlotIds,
    required this.sourceSnippetIds,
    required this.discourseMarkerGroupIds,
  });

  factory ProductiveOralScore.fromJson(Map<String, dynamic> json) {
    return ProductiveOralScore(
      pronunciation: _numericScore(json['pronunciation'], 'pronunciation'),
      accuracy: _numericScore(json['accuracy'], 'accuracy'),
      fluency: _numericScore(json['fluency'], 'fluency'),
      durationMilliseconds: _integer(
        json['durationMilliseconds'],
        'durationMilliseconds',
      ),
      transcriptCodePoints: _integer(
        json['transcriptCodePoints'],
        'transcriptCodePoints',
      ),
      semanticSlotIds: _idValues(json['semanticSlotIds'], 'semanticSlotIds'),
      sourceSnippetIds: _idValues(json['sourceSnippetIds'], 'sourceSnippetIds'),
      discourseMarkerGroupIds: _idValues(
        json['discourseMarkerGroupIds'],
        'discourseMarkerGroupIds',
      ),
    );
  }

  final double pronunciation;
  final double accuracy;
  final double fluency;
  final int durationMilliseconds;
  final int transcriptCodePoints;
  final List<String> semanticSlotIds;
  final List<String> sourceSnippetIds;
  final List<String> discourseMarkerGroupIds;

  Map<String, dynamic> toJson() => {
    'pronunciation': pronunciation,
    'accuracy': accuracy,
    'fluency': fluency,
    'durationMilliseconds': durationMilliseconds,
    'transcriptCodePoints': transcriptCodePoints,
    'semanticSlotIds': semanticSlotIds,
    'sourceSnippetIds': sourceSnippetIds,
    'discourseMarkerGroupIds': discourseMarkerGroupIds,
  };
}

/// Immutable proof that one exact productive assessment succeeded for one
/// concept. Multi-concept assessment results produce one record per concept.
///
/// The learner's answer, recording, transcript, source notes, and reference
/// text are intentionally absent. They may exist transiently in the local
/// evaluator, but this is the only productive object stored or synchronized.
final class ProductiveMasteryEvidence {
  factory ProductiveMasteryEvidence({
    String? id,
    required String assessmentItemId,
    required String canDoSegmentId,
    required String courseUnitId,
    required String missionContentLinkId,
    required String conceptId,
    required SegmentEvidenceMode evidenceMode,
    required int rubricVersion,
    required double score,
    required DateTime occurredAt,
    required bool courseEligible,
    required String definitionFingerprint,
    String evaluatorVersion = productiveEvaluatorVersion,
    String? resultFingerprint,
    List<String> prerequisiteEvidenceIds = const [],
    ProductiveOralScore? oralScore,
    String? assessmentAttemptId,
  }) {
    final normalizedAssessmentId = _requiredId(
      assessmentItemId,
      'assessmentItemId',
    );
    final normalizedSegmentId = _requiredId(canDoSegmentId, 'canDoSegmentId');
    final normalizedUnitId = _requiredId(courseUnitId, 'courseUnitId');
    final normalizedLinkId = _requiredId(
      missionContentLinkId,
      'missionContentLinkId',
    );
    final normalizedConceptId = _requiredId(conceptId, 'conceptId');
    final normalizedDefinitionFingerprint = _requiredId(
      definitionFingerprint,
      'definitionFingerprint',
    );
    final normalizedEvaluatorVersion = _requiredId(
      evaluatorVersion,
      'evaluatorVersion',
    );
    if (rubricVersion <= 0) {
      throw const FormatException(
        'Productive mastery rubricVersion must be positive.',
      );
    }
    final normalizedScore = _validScore(score, 'score');
    final normalizedOccurredAt = occurredAt.toUtc();
    if (normalizedOccurredAt.millisecondsSinceEpoch == 0) {
      throw const FormatException(
        'Productive mastery occurredAt must not be the epoch.',
      );
    }
    if (evidenceMode == SegmentEvidenceMode.oralProduction &&
        (oralScore == null || assessmentAttemptId == null)) {
      throw const FormatException(
        'Oral productive mastery evidence requires trusted score dimensions and attempt provenance.',
      );
    }
    if (evidenceMode != SegmentEvidenceMode.oralProduction &&
        (oralScore != null || assessmentAttemptId != null)) {
      throw const FormatException(
        'Only oral productive mastery evidence may contain oral scores.',
      );
    }
    final normalizedPrerequisites = _uniqueIds(
      prerequisiteEvidenceIds,
      'prerequisiteEvidenceIds',
    );
    final normalizedAttemptId = assessmentAttemptId == null
        ? null
        : _requiredId(assessmentAttemptId, 'assessmentAttemptId');
    final generatedResultFingerprint = productiveResultFingerprint(
      definitionFingerprint: normalizedDefinitionFingerprint,
      evaluatorVersion: normalizedEvaluatorVersion,
      assessmentItemId: normalizedAssessmentId,
      canDoSegmentId: normalizedSegmentId,
      courseUnitId: normalizedUnitId,
      missionContentLinkId: normalizedLinkId,
      conceptId: normalizedConceptId,
      evidenceMode: evidenceMode,
      rubricVersion: rubricVersion,
      score: normalizedScore,
      occurredAt: normalizedOccurredAt,
      courseEligible: courseEligible,
      prerequisiteEvidenceIds: normalizedPrerequisites,
      oralScore: oralScore,
      assessmentAttemptId: normalizedAttemptId,
    );
    final normalizedResultFingerprint = resultFingerprint == null
        ? generatedResultFingerprint
        : _requiredId(resultFingerprint, 'resultFingerprint');
    if (normalizedResultFingerprint != generatedResultFingerprint) {
      throw const FormatException(
        'Productive mastery result fingerprint does not match its non-raw proof summary.',
      );
    }
    final generatedId = stableContentId('productive_mastery', [
      normalizedAssessmentId,
      normalizedSegmentId,
      normalizedUnitId,
      normalizedLinkId,
      normalizedConceptId,
      evidenceMode.code,
      rubricVersion,
      normalizedScore,
      normalizedOccurredAt.toIso8601String(),
      courseEligible,
      normalizedDefinitionFingerprint,
      normalizedEvaluatorVersion,
      normalizedResultFingerprint,
      normalizedPrerequisites.join(','),
      if (oralScore != null) ...[
        normalizedAttemptId,
        oralScore.pronunciation,
        oralScore.accuracy,
        oralScore.fluency,
        oralScore.durationMilliseconds,
        oralScore.transcriptCodePoints,
        oralScore.semanticSlotIds.join(','),
        oralScore.sourceSnippetIds.join(','),
        oralScore.discourseMarkerGroupIds.join(','),
      ],
    ]);
    final normalizedId = id == null ? generatedId : _requiredId(id, 'id');
    return ProductiveMasteryEvidence._(
      id: normalizedId,
      assessmentItemId: normalizedAssessmentId,
      canDoSegmentId: normalizedSegmentId,
      courseUnitId: normalizedUnitId,
      missionContentLinkId: normalizedLinkId,
      conceptId: normalizedConceptId,
      evidenceMode: evidenceMode,
      rubricVersion: rubricVersion,
      score: normalizedScore,
      occurredAt: normalizedOccurredAt,
      courseEligible: courseEligible,
      definitionFingerprint: normalizedDefinitionFingerprint,
      evaluatorVersion: normalizedEvaluatorVersion,
      resultFingerprint: normalizedResultFingerprint,
      prerequisiteEvidenceIds: normalizedPrerequisites,
      oralScore: oralScore,
      assessmentAttemptId: normalizedAttemptId,
    );
  }

  const ProductiveMasteryEvidence._({
    required this.id,
    required this.assessmentItemId,
    required this.canDoSegmentId,
    required this.courseUnitId,
    required this.missionContentLinkId,
    required this.conceptId,
    required this.evidenceMode,
    required this.rubricVersion,
    required this.score,
    required this.occurredAt,
    required this.courseEligible,
    required this.definitionFingerprint,
    required this.evaluatorVersion,
    required this.resultFingerprint,
    required this.prerequisiteEvidenceIds,
    required this.oralScore,
    required this.assessmentAttemptId,
  });

  factory ProductiveMasteryEvidence.fromJson(Map<String, dynamic> json) {
    final mode = SegmentEvidenceModeX.tryFromCode(
      json['evidenceMode']?.toString(),
    );
    if (mode == null) {
      throw const FormatException(
        'Productive mastery evidenceMode is invalid.',
      );
    }
    final rawRubricVersion = json['rubricVersion'];
    final rawScore = json['score'];
    final rawEligible = json['courseEligible'];
    final occurredAt = DateTime.tryParse(json['occurredAt']?.toString() ?? '');
    if (rawRubricVersion is! num ||
        !rawRubricVersion.isFinite ||
        rawRubricVersion != rawRubricVersion.toInt() ||
        rawScore is! num ||
        rawEligible is! bool ||
        occurredAt == null ||
        !occurredAt.isUtc) {
      throw const FormatException('Invalid productive mastery evidence.');
    }
    final rawPrerequisites = json['prerequisiteEvidenceIds'];
    if (rawPrerequisites != null && rawPrerequisites is! List) {
      throw const FormatException(
        'Productive prerequisiteEvidenceIds must be a list.',
      );
    }
    final rawOralScore = json['oralScore'];
    if (rawOralScore != null && rawOralScore is! Map) {
      throw const FormatException('Productive oralScore must be an object.');
    }
    return ProductiveMasteryEvidence(
      id: json['id']?.toString(),
      assessmentItemId: json['assessmentItemId']?.toString() ?? '',
      canDoSegmentId: json['canDoSegmentId']?.toString() ?? '',
      courseUnitId: json['courseUnitId']?.toString() ?? '',
      missionContentLinkId: json['missionContentLinkId']?.toString() ?? '',
      conceptId: json['conceptId']?.toString() ?? '',
      evidenceMode: mode,
      rubricVersion: rawRubricVersion.toInt(),
      score: rawScore.toDouble(),
      occurredAt: occurredAt,
      courseEligible: rawEligible,
      definitionFingerprint: json['definitionFingerprint']?.toString() ?? '',
      evaluatorVersion: json['evaluatorVersion']?.toString() ?? '',
      resultFingerprint: json['resultFingerprint']?.toString() ?? '',
      prerequisiteEvidenceIds: (rawPrerequisites as List? ?? const [])
          .map((value) => value.toString())
          .toList(growable: false),
      oralScore: rawOralScore == null
          ? null
          : ProductiveOralScore.fromJson(
              rawOralScore.map((key, value) => MapEntry(key.toString(), value)),
            ),
      assessmentAttemptId: json['assessmentAttemptId']?.toString(),
    );
  }

  final String id;
  final String assessmentItemId;
  final String canDoSegmentId;
  final String courseUnitId;
  final String missionContentLinkId;
  final String conceptId;
  final SegmentEvidenceMode evidenceMode;
  final int rubricVersion;
  final double score;
  final DateTime occurredAt;
  final bool courseEligible;
  final String definitionFingerprint;
  final String evaluatorVersion;
  final String resultFingerprint;
  final List<String> prerequisiteEvidenceIds;
  final ProductiveOralScore? oralScore;
  final String? assessmentAttemptId;

  /// One durable proof is retained for each exact assessment/concept/rubric
  /// slot. A stronger or newer successful retry deterministically replaces it.
  String get logicalSlotId =>
      [assessmentItemId, canDoSegmentId, conceptId, rubricVersion].join('|');

  Map<String, dynamic> toJson() => {
    'id': id,
    'assessmentItemId': assessmentItemId,
    'canDoSegmentId': canDoSegmentId,
    'courseUnitId': courseUnitId,
    'missionContentLinkId': missionContentLinkId,
    'conceptId': conceptId,
    'evidenceMode': evidenceMode.code,
    'rubricVersion': rubricVersion,
    'score': score,
    'occurredAt': occurredAt.toUtc().toIso8601String(),
    'courseEligible': courseEligible,
    'definitionFingerprint': definitionFingerprint,
    'evaluatorVersion': evaluatorVersion,
    'resultFingerprint': resultFingerprint,
    'prerequisiteEvidenceIds': prerequisiteEvidenceIds,
    if (oralScore != null) 'oralScore': oralScore!.toJson(),
    if (assessmentAttemptId != null) 'assessmentAttemptId': assessmentAttemptId,
  };
}

/// Immutable, non-linguistic receipt that the learner completed an authored
/// source-review gate at project step 1 or 3. It never acts as a productive
/// seal by itself and stores no answer, note, source body, audio, or transcript.
final class ProductiveProjectStepEvidence {
  factory ProductiveProjectStepEvidence({
    String? id,
    required String projectId,
    required String stepId,
    required int stepOrder,
    required String courseUnitId,
    required String authorityFingerprint,
    String evaluatorVersion = productiveEvaluatorVersion,
    required Iterable<String> reviewedSourceSnippetIds,
    String? resultFingerprint,
  }) {
    if (stepOrder != 1 && stepOrder != 3) {
      throw const FormatException(
        'Only project source-review steps 1 and 3 may create receipts.',
      );
    }
    final normalizedProjectId = _requiredId(projectId, 'projectId');
    final normalizedStepId = _requiredId(stepId, 'stepId');
    final normalizedUnitId = _requiredId(courseUnitId, 'courseUnitId');
    final normalizedAuthority = _requiredId(
      authorityFingerprint,
      'authorityFingerprint',
    );
    final normalizedEvaluator = _requiredId(
      evaluatorVersion,
      'evaluatorVersion',
    );
    final reviewedIds = _uniqueIds(
      reviewedSourceSnippetIds,
      'reviewedSourceSnippetIds',
    ).toList()..sort();
    if (reviewedIds.isEmpty) {
      throw const FormatException(
        'Project source-review receipt requires reviewed source IDs.',
      );
    }
    final generatedResultFingerprint =
        stableContentId('productive_project_step_result_integrity', [
          normalizedProjectId,
          normalizedStepId,
          stepOrder,
          normalizedUnitId,
          normalizedAuthority,
          normalizedEvaluator,
          reviewedIds.join(','),
        ]);
    final normalizedResult = resultFingerprint == null
        ? generatedResultFingerprint
        : _requiredId(resultFingerprint, 'resultFingerprint');
    if (normalizedResult != generatedResultFingerprint) {
      throw const FormatException(
        'Project source-review result fingerprint is invalid.',
      );
    }
    final generatedId = stableContentId('productive_project_step', [
      normalizedProjectId,
      normalizedStepId,
      stepOrder,
      normalizedUnitId,
      normalizedAuthority,
      normalizedResult,
    ]);
    final normalizedId = id == null ? generatedId : _requiredId(id, 'id');
    if (normalizedId != generatedId) {
      throw const FormatException(
        'Project source-review receipt ID is not deterministic.',
      );
    }
    return ProductiveProjectStepEvidence._(
      id: normalizedId,
      projectId: normalizedProjectId,
      stepId: normalizedStepId,
      stepOrder: stepOrder,
      courseUnitId: normalizedUnitId,
      authorityFingerprint: normalizedAuthority,
      evaluatorVersion: normalizedEvaluator,
      reviewedSourceSnippetIds: List.unmodifiable(reviewedIds),
      resultFingerprint: normalizedResult,
    );
  }

  const ProductiveProjectStepEvidence._({
    required this.id,
    required this.projectId,
    required this.stepId,
    required this.stepOrder,
    required this.courseUnitId,
    required this.authorityFingerprint,
    required this.evaluatorVersion,
    required this.reviewedSourceSnippetIds,
    required this.resultFingerprint,
  });

  factory ProductiveProjectStepEvidence.fromJson(Map<String, dynamic> json) {
    final rawOrder = json['stepOrder'];
    final rawSources = json['reviewedSourceSnippetIds'];
    if (rawOrder is! num ||
        !rawOrder.isFinite ||
        rawOrder != rawOrder.toInt() ||
        rawSources is! List) {
      throw const FormatException('Invalid project source-review receipt.');
    }
    return ProductiveProjectStepEvidence(
      id: json['id']?.toString(),
      projectId: json['projectId']?.toString() ?? '',
      stepId: json['stepId']?.toString() ?? '',
      stepOrder: rawOrder.toInt(),
      courseUnitId: json['courseUnitId']?.toString() ?? '',
      authorityFingerprint: json['authorityFingerprint']?.toString() ?? '',
      evaluatorVersion: json['evaluatorVersion']?.toString() ?? '',
      reviewedSourceSnippetIds: rawSources.map((value) => value.toString()),
      resultFingerprint: json['resultFingerprint']?.toString() ?? '',
    );
  }

  final String id;
  final String projectId;
  final String stepId;
  final int stepOrder;
  final String courseUnitId;
  final String authorityFingerprint;
  final String evaluatorVersion;
  final List<String> reviewedSourceSnippetIds;
  final String resultFingerprint;

  Map<String, dynamic> toJson() => {
    'id': id,
    'projectId': projectId,
    'stepId': stepId,
    'stepOrder': stepOrder,
    'courseUnitId': courseUnitId,
    'authorityFingerprint': authorityFingerprint,
    'evaluatorVersion': evaluatorVersion,
    'reviewedSourceSnippetIds': reviewedSourceSnippetIds,
    'resultFingerprint': resultFingerprint,
  };
}

/// Deterministic integrity checksum over the complete non-raw result summary.
/// It detects schema/catalog drift and accidental or casual JSON mutation while
/// allowing normal cross-device synchronization. It is deliberately not
/// presented as cryptographic exam attestation.
String productiveResultFingerprint({
  required String definitionFingerprint,
  required String evaluatorVersion,
  required String assessmentItemId,
  required String canDoSegmentId,
  required String courseUnitId,
  required String missionContentLinkId,
  required String conceptId,
  required SegmentEvidenceMode evidenceMode,
  required int rubricVersion,
  required double score,
  required DateTime occurredAt,
  required bool courseEligible,
  required Iterable<String> prerequisiteEvidenceIds,
  ProductiveOralScore? oralScore,
  String? assessmentAttemptId,
}) {
  final prerequisites = prerequisiteEvidenceIds.toList()..sort();
  final semanticSlots = oralScore == null
      ? null
      : (oralScore.semanticSlotIds.toList()..sort());
  final sourceSnippets = oralScore == null
      ? null
      : (oralScore.sourceSnippetIds.toList()..sort());
  final markerGroups = oralScore == null
      ? null
      : (oralScore.discourseMarkerGroupIds.toList()..sort());
  return stableContentId('productive_result_integrity', [
    definitionFingerprint,
    evaluatorVersion,
    assessmentItemId,
    canDoSegmentId,
    courseUnitId,
    missionContentLinkId,
    conceptId,
    evidenceMode.code,
    rubricVersion,
    score,
    occurredAt.toUtc().toIso8601String(),
    courseEligible,
    prerequisites.join(','),
    if (oralScore != null) ...[
      assessmentAttemptId,
      oralScore.pronunciation,
      oralScore.accuracy,
      oralScore.fluency,
      oralScore.durationMilliseconds,
      oralScore.transcriptCodePoints,
      semanticSlots!.join(','),
      sourceSnippets!.join(','),
      markerGroups!.join(','),
    ],
  ]);
}

double _numericScore(Object? value, String field) {
  if (value is! num) {
    throw FormatException('Productive oral $field must be numeric.');
  }
  return value.toDouble();
}

int _integer(Object? value, String field) {
  if (value is! num || !value.isFinite || value != value.toInt()) {
    throw FormatException('Productive oral $field must be an integer.');
  }
  return value.toInt();
}

Iterable<String> _idValues(Object? value, String field) {
  if (value is! List) {
    throw FormatException('Productive oral $field must be a list.');
  }
  return value.map((entry) => entry.toString());
}

double _validScore(double value, String field) {
  if (!value.isFinite || value < 0 || value > 1) {
    throw FormatException('Productive $field must be between 0 and 1.');
  }
  return value;
}

String _requiredId(String value, String field) {
  final normalized = value.trim();
  if (normalized.isEmpty) {
    throw FormatException('Productive mastery $field must not be empty.');
  }
  return normalized;
}

List<String> _uniqueIds(Iterable<String> source, String field) {
  final result = <String>[];
  final seen = <String>{};
  for (final value in source) {
    final normalized = _requiredId(value, field);
    if (!seen.add(normalized)) {
      throw FormatException('Productive mastery $field contains duplicates.');
    }
    result.add(normalized);
  }
  return List.unmodifiable(result);
}
