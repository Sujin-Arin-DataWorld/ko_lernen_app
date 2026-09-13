import 'phase_task.dart';

/// Immutable publication manifest; changes to a task require a new content hash.
class PhasePublication {
  PhasePublication.fromJson(Map<String, dynamic> json)
    : phaseId = json['phaseId'] as String,
      status = json['status'] as String,
      contentHash = json['contentHash'] as String,
      taskHashes = Map.unmodifiable(
        (json['taskHashes'] as Map).cast<String, String>(),
      ) {
    if (status != 'partial' ||
        taskHashes.isEmpty ||
        contentHash !=
            phaseFingerprint(Map<String, dynamic>.from(taskHashes))) {
      throw const FormatException('Invalid Phase publication manifest');
    }
  }
  final String phaseId, status, contentHash;
  final Map<String, String> taskHashes;
}

class PhaseObjectiveTaskLink {
  PhaseObjectiveTaskLink.fromJson(Map<String, dynamic> json)
    : taskId = json['taskId'] as String,
      taskHash = json['taskHash'] as String,
      materialIds = List.unmodifiable(
        (json['materialIds'] as List).cast<String>(),
      ),
      practiceId = json['practiceId'] as String,
      assessmentId = json['assessmentId'] as String,
      criterionIds = List.unmodifiable(
        (json['criterionIds'] as List).cast<String>(),
      ),
      evaluationScope = json['evaluationScope'] as String;
  final String taskId, taskHash, practiceId, assessmentId, evaluationScope;
  final List<String> materialIds, criterionIds;

  void validate(PhaseTask task) {
    final questions = task.assessment.questions.where(
      (q) => criterionIds.contains(q.id),
    );
    final unscored =
        task.skill == 'speaking' ||
        questions.any(
          (q) => q.kind == 'freeText' || q.kind == 'boundedSentence',
        );
    if (taskHash != task.contentHash ||
        practiceId != '$taskId/practice' ||
        assessmentId != '$taskId/assessment' ||
        materialIds.length != 2 ||
        materialIds.toSet().length != 2 ||
        !materialIds.contains('$taskId/practice/material') ||
        !materialIds.contains('$taskId/assessment/material') ||
        criterionIds.toSet().length != criterionIds.length ||
        questions.length != criterionIds.length ||
        (criterionIds.isEmpty && task.skill != 'speaking') ||
        evaluationScope !=
            (unscored ? 'includes_unscored' : 'structured_only')) {
      throw const FormatException(
        'Invalid objective material or assessment link',
      );
    }
  }
}

/// One stable source requirement, including requirements with no task yet.
/// A connected path samples the objective; it does not certify full mastery.
class PhaseObjectiveBinding {
  PhaseObjectiveBinding.fromJson(Map<String, dynamic> json)
    : id = json['id'] as String,
      phaseId = json['phaseId'] as String,
      level = json['level'] as String,
      sourceRequirementKey = json['sourceRequirementKey'] as String,
      sourceHash = json['sourceHash'] as String,
      mode = json['mode'] as String,
      skill = json['skill'] as String?,
      bindings = List.unmodifiable(
        (json['bindings'] as List).map(
          (b) => PhaseObjectiveTaskLink.fromJson(b as Map<String, dynamic>),
        ),
      ) {
    if (id != '$phaseId:objective:$sourceRequirementKey:$mode' ||
        sourceRequirementKey.isEmpty ||
        !['R', 'P'].contains(mode) ||
        !RegExp(r'^[a-f0-9]{64}$').hasMatch(sourceHash) ||
        json['mastery'] != 'unverified' ||
        json['coverage'] !=
            (bindings.isEmpty ? 'unverified' : 'task_path_connected') ||
        bindings.map((b) => b.taskId).toSet().length != bindings.length) {
      throw const FormatException('Invalid Phase source objective');
    }
  }
  final String id, phaseId, level, sourceRequirementKey, sourceHash, mode;
  final String? skill;
  final List<PhaseObjectiveTaskLink> bindings;
}
