import 'content_id.dart';
import 'curriculum.dart';

/// A scored scenario checkpoint. It is separate from answer evidence because
/// one scenario result may summarize many individual questions.
class ScenarioCheckpointEvidence {
  final String id;
  final String scenarioId;
  final String? courseUnitId;
  final double score;
  final DateTime occurredAt;

  /// See [MasteryEvidence.courseEligible]. Browsed future scenarios remain in
  /// history but can never become an unlock input after the fact.
  final bool courseEligible;

  ScenarioCheckpointEvidence({
    String? id,
    required this.scenarioId,
    this.courseUnitId,
    required this.score,
    required this.occurredAt,
    this.courseEligible = false,
  }) : id =
           id ??
           stableContentId('scenario_checkpoint', [
             scenarioId,
             courseUnitId,
             score,
             occurredAt.toUtc().toIso8601String(),
             courseEligible,
           ]);

  factory ScenarioCheckpointEvidence.fromJson(Map<String, dynamic> json) {
    final scenarioId = json['scenarioId']?.toString().trim() ?? '';
    final courseUnitId = json['courseUnitId']?.toString().trim();
    final rawScore = json['score'];
    final score = (rawScore as num?)?.toDouble();
    final occurredAt = DateTime.tryParse(json['occurredAt']?.toString() ?? '');
    final rawEligible = json['courseEligible'];
    if (scenarioId.isEmpty ||
        rawScore is! num ||
        score == null ||
        !score.isFinite ||
        score < 0 ||
        score > 1 ||
        occurredAt == null ||
        !occurredAt.isUtc ||
        occurredAt.millisecondsSinceEpoch == 0 ||
        (rawEligible != null && rawEligible is! bool) ||
        (rawEligible == true &&
            (courseUnitId == null || courseUnitId.isEmpty))) {
      throw const FormatException('Invalid scenario checkpoint evidence.');
    }
    return ScenarioCheckpointEvidence(
      id: json['id']?.toString(),
      scenarioId: scenarioId,
      courseUnitId: courseUnitId == null || courseUnitId.isEmpty
          ? null
          : courseUnitId,
      score: score,
      occurredAt: occurredAt,
      courseEligible: rawEligible == true,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'scenarioId': scenarioId,
    if (courseUnitId != null) 'courseUnitId': courseUnitId,
    'score': score,
    'occurredAt': occurredAt.toUtc().toIso8601String(),
    'courseEligible': courseEligible,
  };
}

/// Durable local snapshot for the sequential course only. Vocabulary SRS,
/// pack progress, and browse filters intentionally live in their own stores.
class CourseMasterySnapshot {
  static const int currentVersion = 1;

  final int version;
  final String? placementLevel;
  final String? currentCourseUnitId;
  final List<String> completedUnitIds;
  final List<String> bypassedPrerequisiteUnitIds;
  final List<MasteryEvidence> evidence;
  final List<ScenarioCheckpointEvidence> scenarioCheckpoints;

  const CourseMasterySnapshot({
    this.version = currentVersion,
    this.placementLevel,
    this.currentCourseUnitId,
    this.completedUnitIds = const [],
    this.bypassedPrerequisiteUnitIds = const [],
    this.evidence = const [],
    this.scenarioCheckpoints = const [],
  });

  const CourseMasterySnapshot.empty()
    : version = currentVersion,
      placementLevel = null,
      currentCourseUnitId = null,
      completedUnitIds = const [],
      bypassedPrerequisiteUnitIds = const [],
      evidence = const [],
      scenarioCheckpoints = const [];

  factory CourseMasterySnapshot.fromJson(Map<String, dynamic> json) {
    final rawVersion = json['version'];
    if (rawVersion != null && rawVersion is! num) {
      throw const FormatException('Course mastery version must be numeric.');
    }
    final rawEvidence = json['evidence'];
    final rawCheckpoints = json['scenarioCheckpoints'];
    if (rawEvidence != null && rawEvidence is! List) {
      throw const FormatException('Course mastery evidence must be a list.');
    }
    if (rawCheckpoints != null && rawCheckpoints is! List) {
      throw const FormatException(
        'Course mastery scenarioCheckpoints must be a list.',
      );
    }
    return CourseMasterySnapshot(
      version: (rawVersion as num?)?.toInt() ?? currentVersion,
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
    );
  }

  CourseMasterySnapshot copyWith({
    String? placementLevel,
    bool clearPlacementLevel = false,
    String? currentCourseUnitId,
    bool clearCurrentCourseUnitId = false,
    List<String>? completedUnitIds,
    List<String>? bypassedPrerequisiteUnitIds,
    List<MasteryEvidence>? evidence,
    List<ScenarioCheckpointEvidence>? scenarioCheckpoints,
  }) => CourseMasterySnapshot(
    version: version,
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
  );

  Map<String, dynamic> toJson() => {
    'version': currentVersion,
    if (placementLevel != null) 'placementLevel': placementLevel,
    if (currentCourseUnitId != null) 'currentCourseUnitId': currentCourseUnitId,
    'completedUnitIds': completedUnitIds,
    'bypassedPrerequisiteUnitIds': bypassedPrerequisiteUnitIds,
    'evidence': evidence.map((item) => item.toJson()).toList(),
    'scenarioCheckpoints': scenarioCheckpoints
        .map((item) => item.toJson())
        .toList(),
  };
}

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
