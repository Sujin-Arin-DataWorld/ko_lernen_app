import 'dart:collection';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'curriculum.dart';
import 'learner_level.dart';

Object? _canonical(Object? value) {
  if (value is Map) {
    return SplayTreeMap<String, Object?>.from({
      for (final e in value.entries) e.key as String: _canonical(e.value),
    });
  }
  if (value is List) {
    return value.map(_canonical).toList();
  }
  return value;
}

String phaseFingerprint(Map<String, dynamic> json) =>
    sha256.convert(utf8.encode(jsonEncode(_canonical(json)))).toString();

String _text(Object? v) {
  if (v is! String || v.trim().isEmpty) {
    throw const FormatException('Missing Phase text');
  }
  return v;
}

Map<String, dynamic> _map(Object? v) {
  if (v is! Map<String, dynamic>) {
    throw const FormatException('Invalid Phase object');
  }
  return v;
}

List<String> _strings(Object? v) {
  if (v is! List) {
    throw const FormatException('Invalid Phase list');
  }
  final list = v.map(_text).toList();
  if (list.toSet().length != list.length) {
    throw const FormatException('Duplicate Phase reference');
  }
  return List.unmodifiable(list);
}

int _revision(Object? v) {
  if (v is! int || v < 1) {
    throw const FormatException('Invalid Phase revision');
  }
  return v;
}

CurriculumText _localized(Object? v) {
  final m = _map(v);
  for (final lang in ['ko', 'en', 'de']) {
    _text(m[lang]);
  }
  return CurriculumText.fromJson(m);
}

class PhaseQuestion {
  PhaseQuestion.fromJson(Map<String, dynamic> json)
    : id = _text(json['id']),
      prompt = _localized(json['prompt']),
      explanation = _localized(json['explanation']),
      kind = _text(json['kind']),
      acceptedAnswers = _strings(json['acceptedAnswers']),
      rejectedAnswers = _strings(json['rejectedAnswers'] ?? const []),
      requiredForPass = json['required'] as bool,
      options = Map.unmodifiable({
        for (final o in json['options'] as List)
          _text(o['id']): _text(o['text']),
      }) {
    if ((acceptedAnswers.isEmpty && kind != 'freeText') ||
        !['choice', 'field', 'boundedSentence', 'freeText'].contains(kind) ||
        (kind == 'freeText' &&
            (acceptedAnswers.isNotEmpty ||
                rejectedAnswers.isNotEmpty ||
                !requiredForPass)) ||
        (kind != 'choice' && options.isNotEmpty) ||
        rejectedAnswers.any(acceptedAnswers.contains) ||
        (kind == 'boundedSentence' && rejectedAnswers.isEmpty) ||
        (kind == 'choice' &&
            (options.length < 2 ||
                options.length != (json['options'] as List).length ||
                !acceptedAnswers.every(options.containsKey) ||
                acceptedAnswers.length >= options.length))) {
      throw const FormatException('Invalid Phase answer contract');
    }
  }
  final String id, kind;
  final CurriculumText prompt, explanation;
  final List<String> acceptedAnswers, rejectedAnswers;
  final bool requiredForPass;
  final Map<String, String> options;
  bool accepts(String answer) =>
      acceptedAnswers.any((v) => v.trim() == answer.trim());
  bool isUnscored(String answer) =>
      (kind == 'freeText' || kind == 'boundedSentence') &&
      answer.trim().isNotEmpty &&
      !accepts(answer) &&
      !rejectedAnswers.contains(answer.trim());
}

class PhaseTaskPacket {
  PhaseTaskPacket.fromJson(Map<String, dynamic> json)
    : sourceKind = _text(json['sourceKind']),
      sourceKo = _text(json['sourceKo']),
      questions = List.unmodifiable(
        (json['questions'] as List).map((q) => PhaseQuestion.fromJson(_map(q))),
      ) {
    if (!['text', 'sign', 'form', 'audio'].contains(sourceKind) ||
        questions.map((q) => q.id).toSet().length != questions.length) {
      throw const FormatException('Invalid Phase material');
    }
  }
  final String sourceKind, sourceKo;
  final List<PhaseQuestion> questions;
}

class PhaseTask {
  PhaseTask.fromJson(Map<String, dynamic> json)
    : id = _text(json['id']),
      phaseId = _text(json['phaseId']),
      level = _text(json['level']),
      objectiveId = _text(json['objectiveId']),
      skill = _text(json['skill']),
      mode = _text(json['mode']),
      contentHash = _text(json['contentHash']),
      contentRevision = _revision(json['contentRevision']),
      rubricVersion = _revision(json['rubricVersion']),
      title = _localized(json['title']),
      teaching = _localized(json['teaching']),
      examplesKo = _strings(json['examplesKo']),
      requirementKeys = _strings(json['requirementKeys']),
      prerequisites = _strings(json['prerequisiteTaskIds']),
      minimumScore = (json['minimumScore'] as num).toDouble(),
      practice = PhaseTaskPacket.fromJson(_map(json['practice'])),
      assessment = PhaseTaskPacket.fromJson(_map(json['assessment'])) {
    final body = Map<String, dynamic>.from(json)..remove('contentHash');
    if (phaseFingerprint(body) != contentHash ||
        !id.startsWith('$phaseId:') ||
        !objectiveId.startsWith('$phaseId:') ||
        !LearnerLevel.values.any((item) => item.display == level) ||
        !['listening', 'reading', 'writing', 'speaking'].contains(skill) ||
        mode != (['writing', 'speaking'].contains(skill) ? 'P' : 'R') ||
        !minimumScore.isFinite ||
        minimumScore <= 0 ||
        minimumScore > 1 ||
        (mode == 'P' && minimumScore < .7) ||
        practice.sourceKo == assessment.sourceKo) {
      throw const FormatException('Invalid or changed Phase task');
    }
    for (final p in [practice, assessment]) {
      if ((p.questions.isEmpty && skill != 'speaking') ||
          (skill == 'listening' && p.sourceKind != 'audio')) {
        throw const FormatException('Missing Phase assessment material');
      }
    }
  }
  final String id, phaseId, level, objectiveId, skill, mode, contentHash;
  final int contentRevision, rubricVersion;
  final CurriculumText title, teaching;
  final List<String> examplesKo, requirementKeys, prerequisites;
  final double minimumScore;
  final PhaseTaskPacket practice, assessment;

  PhaseTaskResult evaluate(
    Map<String, String> answers, {
    required bool assessment,
  }) {
    final packet = assessment ? this.assessment : practice;
    if (answers.keys.any((key) => !packet.questions.any((q) => q.id == key))) {
      throw const FormatException('Unknown Phase response');
    }
    final passedIds = packet.questions
        .where((q) => q.accepts(answers[q.id] ?? ''))
        .map((q) => q.id)
        .toList();
    final score =
        skill == 'speaking' ||
            packet.questions.any((q) => q.isUnscored(answers[q.id] ?? ''))
        ? null
        : passedIds.length / packet.questions.length;
    return PhaseTaskResult._(
      this,
      assessment,
      score,
      List.unmodifiable(score == null ? <String>[] : passedIds),
      assessment &&
          score != null &&
          score >= minimumScore &&
          packet.questions
              .where((q) => q.requiredForPass)
              .every((q) => passedIds.contains(q.id)),
    );
  }

  bool isCurrent(PhaseAttemptEvidence e) =>
      e.phaseId == phaseId &&
      e.taskId == id &&
      e.contentHash == contentHash &&
      e.contentRevision == contentRevision &&
      e.rubricVersion == rubricVersion &&
      e.minimumScore == minimumScore &&
      e.evaluatorVersion == PhaseTaskResult.evaluatorVersion;
  bool passedBy(PhaseAttemptEvidence e) {
    if (!isCurrent(e) ||
        !e.assessment ||
        skill == 'speaking' ||
        e.score == null) {
      return false;
    }
    final ids = assessment.questions.map((q) => q.id).toSet();
    final unscorable = assessment.questions
        .where((q) => q.kind == 'freeText')
        .map((q) => q.id);
    if (e.passedCriterionIds.any(unscorable.contains) ||
        !e.passedCriterionIds.every(ids.contains) ||
        (e.score! - e.passedCriterionIds.length / ids.length).abs() > 1e-9) {
      return false;
    }
    return e.score! >= minimumScore &&
        assessment.questions
            .where((q) => q.requiredForPass)
            .every((q) => e.passedCriterionIds.contains(q.id));
  }
}

/// Only the task evaluator can construct this result; UI cannot provide a pass flag.
final class PhaseTaskResult {
  const PhaseTaskResult._(
    this.task,
    this.assessment,
    this.score,
    this.passedCriterionIds,
    this.passed,
  );
  static const evaluatorVersion = 'phase-structured-v1';
  final PhaseTask task;
  final bool assessment, passed;
  final double? score;
  final List<String> passedCriterionIds;
  PhaseAttemptEvidence evidence(String id, DateTime time) =>
      PhaseAttemptEvidence.fromJson({
        'attemptId': id,
        'phaseId': task.phaseId,
        'taskId': task.id,
        'contentHash': task.contentHash,
        'contentRevision': task.contentRevision,
        'rubricVersion': task.rubricVersion,
        'minimumScore': task.minimumScore,
        'evaluatorVersion': evaluatorVersion,
        'mode': assessment ? 'assessment' : 'practice',
        'score': score,
        'passedCriterionIds': passedCriterionIds,
        'occurredAt': time.toUtc().toIso8601String(),
      });
}

class PhaseAttemptEvidence {
  PhaseAttemptEvidence.fromJson(Map<String, dynamic> json)
    : attemptId = _text(json['attemptId']),
      phaseId = _text(json['phaseId']),
      taskId = _text(json['taskId']),
      contentHash = _text(json['contentHash']),
      contentRevision = _revision(json['contentRevision']),
      rubricVersion = _revision(json['rubricVersion']),
      minimumScore = (json['minimumScore'] as num).toDouble(),
      evaluatorVersion = _text(json['evaluatorVersion']),
      assessment = json['mode'] == 'assessment',
      score = json['score'] == null ? null : (json['score'] as num).toDouble(),
      passedCriterionIds = _strings(json['passedCriterionIds']),
      occurredAt = DateTime.parse(_text(json['occurredAt'])) {
    const keys = {
      'attemptId',
      'phaseId',
      'taskId',
      'contentHash',
      'contentRevision',
      'rubricVersion',
      'minimumScore',
      'evaluatorVersion',
      'mode',
      'score',
      'passedCriterionIds',
      'occurredAt',
    };
    if (json.keys.toSet().difference(keys).isNotEmpty ||
        keys.difference(json.keys.toSet()).isNotEmpty ||
        !RegExp(r'^KP\d{2}$').hasMatch(phaseId) ||
        !taskId.startsWith('$phaseId:') ||
        !RegExp(r'^[a-f0-9]{64}$').hasMatch(contentHash) ||
        !['practice', 'assessment'].contains(json['mode']) ||
        !minimumScore.isFinite ||
        minimumScore <= 0 ||
        minimumScore > 1 ||
        !occurredAt.isUtc ||
        occurredAt.millisecondsSinceEpoch <= 0 ||
        (score != null && (!score!.isFinite || score! < 0 || score! > 1)) ||
        (score == null && passedCriterionIds.isNotEmpty)) {
      throw const FormatException('Invalid Phase attempt evidence');
    }
  }
  final String attemptId, phaseId, taskId, contentHash, evaluatorVersion;
  final int contentRevision, rubricVersion;
  final double minimumScore;
  final bool assessment;
  final double? score;
  final List<String> passedCriterionIds;
  final DateTime occurredAt;
  Map<String, dynamic> toJson() => {
    'attemptId': attemptId,
    'phaseId': phaseId,
    'taskId': taskId,
    'contentHash': contentHash,
    'contentRevision': contentRevision,
    'rubricVersion': rubricVersion,
    'minimumScore': minimumScore,
    'evaluatorVersion': evaluatorVersion,
    'mode': assessment ? 'assessment' : 'practice',
    'score': score,
    'passedCriterionIds': passedCriterionIds,
    'occurredAt': occurredAt.toUtc().toIso8601String(),
  };
}
