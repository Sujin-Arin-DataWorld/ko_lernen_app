import 'content_id.dart';
import 'curriculum.dart';
import 'productive_mastery.dart';
import 'scenario_corpus_generation.dart';

/// A scored scenario checkpoint. It is separate from answer evidence because
/// one scenario result may summarize many individual questions.
class ScenarioCheckpointEvidence {
  final String id;
  final String scenarioId;
  final String? courseUnitId;
  final String? missionContentLinkId;
  final double score;
  final DateTime occurredAt;

  /// See [MasteryEvidence.courseEligible]. Browsed future scenarios remain in
  /// history but can never become an unlock input after the fact.
  final bool courseEligible;

  ScenarioCheckpointEvidence({
    String? id,
    required this.scenarioId,
    this.courseUnitId,
    this.missionContentLinkId,
    required this.score,
    required this.occurredAt,
    this.courseEligible = false,
  }) : id =
           id ??
           stableContentId('scenario_checkpoint', [
             scenarioId,
             courseUnitId,
             missionContentLinkId,
             score,
             occurredAt.toUtc().toIso8601String(),
             courseEligible,
           ]);

  factory ScenarioCheckpointEvidence.fromJson(Map<String, dynamic> json) {
    final scenarioId = json['scenarioId']?.toString().trim() ?? '';
    final courseUnitId = json['courseUnitId']?.toString().trim();
    final missionContentLinkId = json['missionContentLinkId']
        ?.toString()
        .trim();
    final rawScore = json['score'];
    if (rawScore is! num) {
      throw const FormatException(
        'Scenario checkpoint evidence score must be numeric.',
      );
    }
    final score = rawScore.toDouble();
    final occurredAt = DateTime.tryParse(json['occurredAt']?.toString() ?? '');
    final rawEligible = json['courseEligible'];
    if (scenarioId.isEmpty ||
        !score.isFinite ||
        score < 0 ||
        score > 1 ||
        occurredAt == null ||
        !occurredAt.isUtc ||
        occurredAt.millisecondsSinceEpoch == 0 ||
        (rawEligible != null && rawEligible is! bool) ||
        (rawEligible == true &&
            (courseUnitId == null || courseUnitId.isEmpty)) ||
        (missionContentLinkId != null &&
            missionContentLinkId.isNotEmpty &&
            (courseUnitId == null || courseUnitId.isEmpty))) {
      throw const FormatException('Invalid scenario checkpoint evidence.');
    }
    return ScenarioCheckpointEvidence(
      id: json['id']?.toString(),
      scenarioId: scenarioId,
      courseUnitId: courseUnitId == null || courseUnitId.isEmpty
          ? null
          : courseUnitId,
      missionContentLinkId:
          missionContentLinkId == null || missionContentLinkId.isEmpty
          ? null
          : missionContentLinkId,
      score: score,
      occurredAt: occurredAt,
      courseEligible: rawEligible == true,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'scenarioId': scenarioId,
    if (courseUnitId != null) 'courseUnitId': courseUnitId,
    if (missionContentLinkId != null)
      'missionContentLinkId': missionContentLinkId,
    'score': score,
    'occurredAt': occurredAt.toUtc().toIso8601String(),
    'courseEligible': courseEligible,
  };
}

/// Durable local snapshot for the sequential course only. Vocabulary SRS,
/// pack progress, and browse filters intentionally live in their own stores.
class CourseMasterySnapshot {
  static const int currentVersion = 3;

  final int version;
  final String curriculumGeneration;
  final String? placementLevel;
  final String? currentCourseUnitId;
  final List<String> completedUnitIds;
  final List<String> bypassedPrerequisiteUnitIds;
  final List<MasteryEvidence> evidence;
  final List<ScenarioCheckpointEvidence> scenarioCheckpoints;
  final List<ProductiveMasteryEvidence> productiveEvidence;
  final List<ProductiveProjectStepEvidence> productiveProjectStepEvidence;
  final List<ProductiveMasteryEvidence> archivedProductiveEvidence;
  final List<ProductiveProjectStepEvidence>
  archivedProductiveProjectStepEvidence;

  const CourseMasterySnapshot({
    this.version = currentVersion,
    this.curriculumGeneration = ScenarioCorpusGeneration.legacy,
    this.placementLevel,
    this.currentCourseUnitId,
    this.completedUnitIds = const [],
    this.bypassedPrerequisiteUnitIds = const [],
    this.evidence = const [],
    this.scenarioCheckpoints = const [],
    this.productiveEvidence = const [],
    this.productiveProjectStepEvidence = const [],
    this.archivedProductiveEvidence = const [],
    this.archivedProductiveProjectStepEvidence = const [],
  });

  const CourseMasterySnapshot.empty()
    : version = currentVersion,
      curriculumGeneration = ScenarioCorpusGeneration.legacy,
      placementLevel = null,
      currentCourseUnitId = null,
      completedUnitIds = const [],
      bypassedPrerequisiteUnitIds = const [],
      evidence = const [],
      scenarioCheckpoints = const [],
      productiveEvidence = const [],
      productiveProjectStepEvidence = const [],
      archivedProductiveEvidence = const [],
      archivedProductiveProjectStepEvidence = const [];

  factory CourseMasterySnapshot.fromJson(Map<String, dynamic> json) =>
      CourseMasterySnapshot.decodeAndMigrate(json);

  /// Accepts retained v1/v2 local shapes and returns canonical v3. Productive
  /// proof is never inferred from historical unit completion during migration.
  /// Future schemas are deliberately rejected so a newer installation's state
  /// can never be silently overwritten by this version of the app.
  factory CourseMasterySnapshot.decodeAndMigrate(Map<String, dynamic> json) {
    final sourceVersion = CourseMasterySnapshot.sourceVersionFor(json);
    if (sourceVersion == 2) {
      _validateCanonicalV2Shape(json);
    } else if (sourceVersion == currentVersion) {
      _validateCanonicalV3Shape(json);
    }
    final rawEvidence = json['evidence'];
    final rawCheckpoints = json['scenarioCheckpoints'];
    // V1/V2 never owned productive authority. Ignore even a forged field
    // rather than backfilling a seal during migration.
    final rawProductiveEvidence = sourceVersion < 3
        ? null
        : json['productiveEvidence'];
    final rawProjectStepEvidence = sourceVersion < 3
        ? null
        : json['productiveProjectStepEvidence'];
    final rawArchivedProductiveEvidence = sourceVersion < 3
        ? null
        : json['archivedProductiveEvidence'];
    final rawArchivedProjectStepEvidence = sourceVersion < 3
        ? null
        : json['archivedProductiveProjectStepEvidence'];
    if (rawEvidence != null && rawEvidence is! List) {
      throw const FormatException('Course mastery evidence must be a list.');
    }
    if (rawCheckpoints != null && rawCheckpoints is! List) {
      throw const FormatException(
        'Course mastery scenarioCheckpoints must be a list.',
      );
    }
    if (rawProductiveEvidence != null && rawProductiveEvidence is! List) {
      throw const FormatException(
        'Course mastery productiveEvidence must be a list.',
      );
    }
    if (rawProjectStepEvidence != null && rawProjectStepEvidence is! List) {
      throw const FormatException(
        'Course mastery productiveProjectStepEvidence must be a list.',
      );
    }
    if (rawArchivedProductiveEvidence != null &&
        rawArchivedProductiveEvidence is! List) {
      throw const FormatException(
        'Course mastery archivedProductiveEvidence must be a list.',
      );
    }
    if (rawArchivedProjectStepEvidence != null &&
        rawArchivedProjectStepEvidence is! List) {
      throw const FormatException(
        'Course mastery archivedProductiveProjectStepEvidence must be a list.',
      );
    }
    return CourseMasterySnapshot(
      version: currentVersion,
      curriculumGeneration:
          _nullableString(json['curriculumGeneration']) ??
          ScenarioCorpusGeneration.legacy,
      placementLevel: _nullableString(json['placementLevel']),
      currentCourseUnitId: _nullableString(json['currentCourseUnitId']),
      completedUnitIds: _stringList(json['completedUnitIds']),
      bypassedPrerequisiteUnitIds: _stringList(
        json['bypassedPrerequisiteUnitIds'],
      ),
      evidence: (rawEvidence as List? ?? const [])
          .map((item) => MasteryEvidence.fromJson(_map(item, 'evidence')))
          .toList(growable: false),
      scenarioCheckpoints: (rawCheckpoints as List? ?? const [])
          .map(
            (item) => ScenarioCheckpointEvidence.fromJson(
              _map(item, 'scenario checkpoint'),
            ),
          )
          .toList(growable: false),
      productiveEvidence: (rawProductiveEvidence as List? ?? const [])
          .map(
            (item) => ProductiveMasteryEvidence.fromJson(
              _map(item, 'productive evidence'),
            ),
          )
          .toList(growable: false),
      productiveProjectStepEvidence:
          (rawProjectStepEvidence as List? ?? const [])
              .map(
                (item) => ProductiveProjectStepEvidence.fromJson(
                  _map(item, 'productive project step evidence'),
                ),
              )
              .toList(growable: false),
      archivedProductiveEvidence:
          (rawArchivedProductiveEvidence as List? ?? const [])
              .map(
                (item) => ProductiveMasteryEvidence.fromJson(
                  _map(item, 'archived productive evidence'),
                ),
              )
              .toList(growable: false),
      archivedProductiveProjectStepEvidence:
          (rawArchivedProjectStepEvidence as List? ?? const [])
              .map(
                (item) => ProductiveProjectStepEvidence.fromJson(
                  _map(item, 'archived productive project step evidence'),
                ),
              )
              .toList(growable: false),
    );
  }

  /// Validates a source schema number before any migration or range logic.
  static int sourceVersionFor(Map<String, dynamic> json) {
    final rawVersion = json['version'];
    if (rawVersion == null) {
      return 1;
    }
    if (rawVersion is! num ||
        !rawVersion.isFinite ||
        rawVersion != rawVersion.toInt()) {
      throw const FormatException('Course mastery version must be numeric.');
    }
    final sourceVersion = rawVersion.toInt();
    if (sourceVersion < 1 || sourceVersion > currentVersion) {
      throw FormatException(
        'Unsupported course mastery version $sourceVersion.',
      );
    }
    return sourceVersion;
  }

  CourseMasterySnapshot copyWith({
    String? curriculumGeneration,
    String? placementLevel,
    bool clearPlacementLevel = false,
    String? currentCourseUnitId,
    bool clearCurrentCourseUnitId = false,
    List<String>? completedUnitIds,
    List<String>? bypassedPrerequisiteUnitIds,
    List<MasteryEvidence>? evidence,
    List<ScenarioCheckpointEvidence>? scenarioCheckpoints,
    List<ProductiveMasteryEvidence>? productiveEvidence,
    List<ProductiveProjectStepEvidence>? productiveProjectStepEvidence,
    List<ProductiveMasteryEvidence>? archivedProductiveEvidence,
    List<ProductiveProjectStepEvidence>? archivedProductiveProjectStepEvidence,
  }) => CourseMasterySnapshot(
    version: version,
    curriculumGeneration: curriculumGeneration ?? this.curriculumGeneration,
    placementLevel: clearPlacementLevel
        ? null
        : (placementLevel ?? this.placementLevel),
    currentCourseUnitId: clearCurrentCourseUnitId
        ? null
        : (currentCourseUnitId ?? this.currentCourseUnitId),
    completedUnitIds: completedUnitIds ?? this.completedUnitIds,
    bypassedPrerequisiteUnitIds:
        bypassedPrerequisiteUnitIds ?? this.bypassedPrerequisiteUnitIds,
    evidence: evidence ?? this.evidence,
    scenarioCheckpoints: scenarioCheckpoints ?? this.scenarioCheckpoints,
    productiveEvidence: productiveEvidence ?? this.productiveEvidence,
    productiveProjectStepEvidence:
        productiveProjectStepEvidence ?? this.productiveProjectStepEvidence,
    archivedProductiveEvidence:
        archivedProductiveEvidence ?? this.archivedProductiveEvidence,
    archivedProductiveProjectStepEvidence:
        archivedProductiveProjectStepEvidence ??
        this.archivedProductiveProjectStepEvidence,
  );

  Map<String, dynamic> toJson() => {
    'version': currentVersion,
    if (curriculumGeneration != ScenarioCorpusGeneration.legacy)
      'curriculumGeneration': curriculumGeneration,
    if (placementLevel != null) 'placementLevel': placementLevel,
    if (currentCourseUnitId != null) 'currentCourseUnitId': currentCourseUnitId,
    'completedUnitIds': completedUnitIds,
    'bypassedPrerequisiteUnitIds': bypassedPrerequisiteUnitIds,
    'evidence': evidence.map((item) => item.toJson()).toList(),
    'scenarioCheckpoints': scenarioCheckpoints
        .map((item) => item.toJson())
        .toList(),
    'productiveEvidence': productiveEvidence
        .map((item) => item.toJson())
        .toList(),
    'productiveProjectStepEvidence': productiveProjectStepEvidence
        .map((item) => item.toJson())
        .toList(),
    if (archivedProductiveEvidence.isNotEmpty)
      'archivedProductiveEvidence': archivedProductiveEvidence
          .map((item) => item.toJson())
          .toList(),
    if (archivedProductiveProjectStepEvidence.isNotEmpty)
      'archivedProductiveProjectStepEvidence':
          archivedProductiveProjectStepEvidence
              .map((item) => item.toJson())
              .toList(),
  };

  /// Archived proof remains eligible to justify already-earned Hanok grants,
  /// but course progression and reassessment read only the active lists.
  List<ProductiveMasteryEvidence> get rewardProductiveEvidence =>
      List.unmodifiable([...archivedProductiveEvidence, ...productiveEvidence]);

  List<ProductiveProjectStepEvidence> get rewardProductiveProjectStepEvidence =>
      List.unmodifiable([
        ...archivedProductiveProjectStepEvidence,
        ...productiveProjectStepEvidence,
      ]);
}

enum CourseMasteryMergeConflictKind {
  placement,
  version,
  generation,
  evidence,
  checkpoint,
  productiveEvidence,
  productiveProjectStepEvidence,
  progression,
}

class CourseMasteryMergeConflict {
  const CourseMasteryMergeConflict({required this.kind, required this.id});

  final CourseMasteryMergeConflictKind kind;
  final String id;

  @override
  bool operator ==(Object other) =>
      other is CourseMasteryMergeConflict &&
      other.kind == kind &&
      other.id == id;

  @override
  int get hashCode => Object.hash(kind, id);
}

class CourseMasteryMergeResult {
  const CourseMasteryMergeResult._({this.snapshot, required this.conflicts});

  const CourseMasteryMergeResult.merged(CourseMasterySnapshot snapshot)
    : this._(snapshot: snapshot, conflicts: const []);

  const CourseMasteryMergeResult.conflicted(
    List<CourseMasteryMergeConflict> conflicts,
  ) : this._(conflicts: conflicts);

  final CourseMasterySnapshot? snapshot;
  final List<CourseMasteryMergeConflict> conflicts;

  bool get isValid => snapshot != null && conflicts.isEmpty;
}

typedef CourseMasteryReconciliationMerger =
    CourseMasteryMergeResult Function({
      required CourseMasterySnapshot? local,
      required CourseMasterySnapshot? remote,
    });

String? _nullableString(Object? value) {
  final string = value?.toString().trim() ?? '';
  return string.isEmpty ? null : string;
}

List<String> _stringList(Object? value) {
  if (value == null) return const [];
  if (value is! List) {
    throw const FormatException('Course mastery ID collections must be lists.');
  }
  final values = <String>[];
  for (final item in value) {
    if (item is! String || item.trim().isEmpty) {
      throw const FormatException(
        'Course mastery IDs must be nonempty strings.',
      );
    }
    values.add(item.trim());
  }
  return values;
}

Map<String, dynamic> _map(Object? value, String label) {
  if (value is! Map) {
    throw FormatException('Course mastery $label entry must be an object.');
  }
  return value.map((key, item) => MapEntry(key.toString(), item));
}

void _validateCanonicalV2Shape(Map<String, dynamic> json) {
  _requireOptionalNonemptyString(json, 'placementLevel');
  _requireOptionalNonemptyString(json, 'currentCourseUnitId');
  _validateCanonicalEntries(
    json['evidence'],
    label: 'evidence',
    requiredStringFields: const ['id', 'conceptId', 'contentKind', 'contentId'],
    optionalStringFields: const [
      'courseUnitId',
      'missionContentLinkId',
      'errorReason',
    ],
  );
  _validateCanonicalEntries(
    json['scenarioCheckpoints'],
    label: 'scenario checkpoint',
    requiredStringFields: const ['id', 'scenarioId'],
    optionalStringFields: const ['courseUnitId', 'missionContentLinkId'],
  );
}

void _validateCanonicalV3Shape(Map<String, dynamic> json) {
  _validateCanonicalV2Shape(json);
  if (!json.containsKey('productiveEvidence') ||
      json['productiveEvidence'] is! List) {
    throw const FormatException(
      'Canonical v3 course mastery requires productiveEvidence.',
    );
  }
  _validateCanonicalEntries(
    json['productiveEvidence'],
    label: 'productive evidence',
    requiredStringFields: const [
      'id',
      'assessmentItemId',
      'canDoSegmentId',
      'courseUnitId',
      'missionContentLinkId',
      'conceptId',
      'evidenceMode',
      'definitionFingerprint',
      'evaluatorVersion',
      'resultFingerprint',
    ],
    optionalStringFields: const [],
  );
  if (!json.containsKey('productiveProjectStepEvidence') ||
      json['productiveProjectStepEvidence'] is! List) {
    throw const FormatException(
      'Canonical v3 course mastery requires productiveProjectStepEvidence.',
    );
  }
  _validateCanonicalEntries(
    json['productiveProjectStepEvidence'],
    label: 'productive project step evidence',
    requiredStringFields: const [
      'id',
      'projectId',
      'stepId',
      'courseUnitId',
      'authorityFingerprint',
      'evaluatorVersion',
      'resultFingerprint',
    ],
    optionalStringFields: const [],
  );
  _validateCanonicalEntries(
    json['archivedProductiveEvidence'],
    label: 'archived productive evidence',
    requiredStringFields: const [
      'id',
      'assessmentItemId',
      'canDoSegmentId',
      'courseUnitId',
      'missionContentLinkId',
      'conceptId',
      'evidenceMode',
      'definitionFingerprint',
      'evaluatorVersion',
      'resultFingerprint',
    ],
    optionalStringFields: const [],
  );
  _validateCanonicalEntries(
    json['archivedProductiveProjectStepEvidence'],
    label: 'archived productive project step evidence',
    requiredStringFields: const [
      'id',
      'projectId',
      'stepId',
      'courseUnitId',
      'authorityFingerprint',
      'evaluatorVersion',
      'resultFingerprint',
    ],
    optionalStringFields: const [],
  );
}

void _validateCanonicalEntries(
  Object? raw, {
  required String label,
  required List<String> requiredStringFields,
  required List<String> optionalStringFields,
}) {
  if (raw == null) return;
  if (raw is! List) {
    throw FormatException('Course mastery $label must be a list.');
  }
  for (final item in raw) {
    if (item is! Map) {
      throw FormatException('Course mastery $label entry must be an object.');
    }
    final entry = item.map((key, value) => MapEntry(key.toString(), value));
    for (final field in requiredStringFields) {
      _requireNonemptyString(entry, field, label: label);
    }
    for (final field in optionalStringFields) {
      _requireOptionalNonemptyString(entry, field, label: label);
    }
  }
}

void _requireNonemptyString(
  Map<String, dynamic> json,
  String field, {
  String label = 'snapshot',
}) {
  final value = json[field];
  if (value is! String || value.trim().isEmpty) {
    throw FormatException(
      'Canonical course mastery $label $field must be a nonempty string.',
    );
  }
}

void _requireOptionalNonemptyString(
  Map<String, dynamic> json,
  String field, {
  String label = 'snapshot',
}) {
  if (!json.containsKey(field)) return;
  _requireNonemptyString(json, field, label: label);
}
