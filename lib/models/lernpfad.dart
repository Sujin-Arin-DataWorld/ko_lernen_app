import 'dart:convert';
import 'phase_task.dart' show phaseFingerprint;

typedef PathText = Map<String, String>;
PathText pathText(Object? raw) {
  final map = Map<String, String>.from(raw as Map);
  if (['ko', 'en', 'de'].any((lang) => map[lang]?.trim().isNotEmpty != true)) {
    throw const FormatException('Missing path translation');
  }
  return Map.unmodifiable(map);
}

abstract interface class LernpfadSchema {
  bool hasBand(String id);
  FoundationLesson? lessonById(String id);
}

class FoundationCursorConflict extends StateError {
  FoundationCursorConflict()
    : super('Foundation cursor changed; reload before continuing');
}

class LernpfadBand {
  LernpfadBand.fromJson(Map<String, dynamic> json)
    : id = json['id'] as String,
      level = json['level'] as String,
      title = pathText(json['title']),
      outcome = pathText(json['outcome']),
      coverage = json['coverage'] as String,
      activityIds = List.unmodifiable(
        (json['activityIds'] as List).cast<String>(),
      );
  final String id, level, coverage;
  final PathText title, outcome;
  final List<String> activityIds;
}

class LernpfadActivity {
  LernpfadActivity.fromJson(Map<String, dynamic> json)
    : id = json['id'] as String,
      kind = json['kind'] as String,
      bandId = json['bandId'] as String,
      title = pathText(json['title']),
      taskId = json['taskId'] as String?,
      contentHash = json['contentHash'] as String?,
      preparationTaskIds = List.unmodifiable(
        (json['preparationTaskIds'] as List? ?? []).cast<String>(),
      ),
      required = json['required'] == true;
  final String id, kind, bandId;
  final String? taskId, contentHash;
  final PathText title;
  final bool required;
  final List<String> preparationTaskIds;
}

class FoundationQuestion {
  FoundationQuestion.fromJson(Map<String, dynamic> json)
    : id = json['id'] as String,
      parts = List.unmodifiable((json['parts'] as List).cast<String>()),
      answer = json['answer'] as String,
      options = List.unmodifiable((json['options'] as List).cast<String>());
  final String id, answer;
  final List<String> parts, options;
}

class FoundationLesson {
  FoundationLesson.fromJson(Map<String, dynamic> json)
    : source = Map.unmodifiable(json),
      id = json['id'] as String,
      revision = json['revision'] as int,
      scope = json['evidenceScope'] as String,
      title = pathText(json['title']),
      story = pathText(json['story']),
      followup = pathText(json['followup']),
      teaching = List.unmodifiable(
        (json['teaching'] as List).cast<Map<String, dynamic>>(),
      ),
      practice = List.unmodifiable(
        (json['practice'] as List).map((q) => FoundationQuestion.fromJson(q)),
      ),
      assessment = List.unmodifiable(
        (json['assessment'] as List).map((q) => FoundationQuestion.fromJson(q)),
      ),
      hash = phaseFingerprint(json) {
    final questions = [...practice, ...assessment];
    if (revision < 1 ||
        teaching.isEmpty ||
        practice.isEmpty ||
        assessment.isEmpty ||
        questions.map((q) => q.id).toSet().length != questions.length ||
        questions.any(
          (q) =>
              !q.options.contains(q.answer) ||
              q.options.toSet().length != q.options.length,
        )) {
      throw const FormatException('Invalid foundation lesson');
    }
  }
  final Map<String, dynamic> source;
  final String id, scope, hash;
  final int revision;
  final PathText title, story, followup;
  final List<Map<String, dynamic>> teaching;
  final List<FoundationQuestion> practice, assessment;
  int get questionStart => 1 + teaching.length;
  int get checkStart => questionStart + practice.length;
  int get endStep => checkStart + assessment.length;
  FoundationQuestion questionAt(int step) =>
      [...practice, ...assessment][step - questionStart];
}

/// Scope and content identity are fixed at launch. A screen can submit an
/// answer or request help; it cannot submit a mastery/success flag.
class FoundationRun {
  const FoundationRun._(
    this.attemptId,
    this.lessonId,
    this.contentHash,
    this.scope,
    this.startedAt,
    this.step,
    this.helped,
    this.answers,
    this.responses,
  );
  factory FoundationRun.start(
    FoundationLesson lesson,
    String id,
    DateTime now,
  ) => FoundationRun._(
    id,
    lesson.id,
    lesson.hash,
    lesson.scope,
    now.toUtc(),
    0,
    false,
    const {},
    const [],
  );
  final String attemptId, lessonId, contentHash, scope;
  final DateTime startedAt;
  final int step;
  final bool helped;
  final Map<String, String> answers;
  final List<Map<String, Object?>> responses;

  bool current(FoundationLesson lesson) =>
      lessonId == lesson.id &&
      contentHash == lesson.hash &&
      scope == lesson.scope;
  void _validate(FoundationLesson lesson) {
    if (!current(lesson) || step < 0 || step > lesson.endStep) {
      throw const FormatException('Foundation run requires a fresh start');
    }
  }

  FoundationRun _copy({
    int? step,
    bool? helped,
    Map<String, String>? answers,
    List<Map<String, Object?>>? responses,
  }) => FoundationRun._(
    attemptId,
    lessonId,
    contentHash,
    scope,
    startedAt,
    step ?? this.step,
    helped ?? this.helped,
    Map.unmodifiable(answers ?? this.answers),
    List.unmodifiable(responses ?? this.responses),
  );
  FoundationRun withHelp() => _copy(helped: true);
  FoundationRun advance(FoundationLesson lesson) {
    _validate(lesson);
    if (step >= lesson.questionStart) {
      throw StateError('An answer is required');
    }
    return _copy(step: step + 1);
  }

  FoundationRun answer(FoundationLesson lesson, String answer) {
    _validate(lesson);
    if (step < lesson.questionStart || step == lesson.endStep) {
      throw StateError('Not at a question');
    }
    final question = lesson.questionAt(step);
    if (!question.options.contains(answer)) {
      throw const FormatException('Unknown answer');
    }
    final recorded = <Map<String, Object?>>[
      ...responses,
      Map.unmodifiable({
        'questionId': question.id,
        'step': step,
        'answer': answer,
        'correct': answer == question.answer,
        'assessment': step >= lesson.checkStart,
        'helpedBeforeAnswer': helped,
      }),
    ];
    if (answer != question.answer) {
      return _copy(
        helped: helped || step >= lesson.checkStart,
        responses: recorded,
      );
    }
    return _copy(
      step: step + 1,
      answers: {...answers, question.id: answer},
      responses: recorded,
    );
  }

  bool complete(FoundationLesson lesson) =>
      current(lesson) &&
      step == lesson.endStep &&
      [
        ...lesson.practice,
        ...lesson.assessment,
      ].every((q) => answers[q.id] == q.answer);
  Map<String, dynamic> toJson() => {
    'attemptId': attemptId,
    'lessonId': lessonId,
    'contentHash': contentHash,
    'scope': scope,
    'startedAt': startedAt.toIso8601String(),
    'step': step,
    'helped': helped,
    'answers': answers,
    'responses': responses,
  };
  factory FoundationRun.fromJson(Map<String, dynamic> json) {
    if (json['attemptId'] is! String ||
        (json['attemptId'] as String).isEmpty ||
        json['lessonId'] is! String ||
        json['contentHash'] is! String ||
        json['scope'] is! String ||
        json['step'] is! int ||
        json['helped'] is! bool ||
        json['answers'] is! Map ||
        json['responses'] is! List ||
        json['startedAt'] is! String) {
      throw const FormatException('Invalid foundation attempt');
    }
    final date = DateTime.tryParse(json['startedAt']);
    if (date == null || !date.isUtc) {
      throw const FormatException('Invalid attempt date');
    }
    final responses = <Map<String, Object?>>[];
    for (final raw in json['responses'] as List) {
      if (raw is! Map ||
          raw['questionId'] is! String ||
          raw['step'] is! int ||
          raw['answer'] is! String ||
          raw['correct'] is! bool ||
          raw['assessment'] is! bool ||
          raw['helpedBeforeAnswer'] is! bool) {
        throw const FormatException('Invalid original response');
      }
      responses.add(Map.unmodifiable(Map<String, Object?>.from(raw)));
    }
    return FoundationRun._(
      json['attemptId'],
      json['lessonId'],
      json['contentHash'],
      json['scope'],
      date,
      json['step'],
      json['helped'],
      Map.unmodifiable(Map<String, String>.from(json['answers'])),
      List.unmodifiable(responses),
    );
  }
}

class FoundationReceipt {
  const FoundationReceipt._(this.run);
  final FoundationRun run;
  String get scope => run.scope;
  bool independent(FoundationLesson lesson) =>
      run.complete(lesson) &&
      !run.helped &&
      !run.responses.any(
        (r) =>
            r['assessment'] == true &&
            (r['correct'] != true || r['helpedBeforeAnswer'] == true),
      );
}

/// No CEFR award or currency fields. Original attempts are retained, rather
/// than replaced by a Boolean which could outlive their content revision.
class LernpfadState {
  const LernpfadState._(this.selectedBandId, this.active, this.receipts);
  factory LernpfadState.empty() => const LernpfadState._('F0.1', null, []);
  final String selectedBandId;
  final FoundationRun? active;
  final List<FoundationReceipt> receipts;
  LernpfadState selectBand(String id, LernpfadSchema schema) {
    if (!schema.hasBand(id)) {
      throw const FormatException('Unknown path band');
    }
    return LernpfadState._(id, active, receipts);
  }

  LernpfadState withRun(FoundationRun run) =>
      LernpfadState._(selectedBandId, run, receipts);
  LernpfadState record(FoundationRun run, FoundationLesson lesson) {
    if (!run.complete(lesson)) {
      throw StateError('Cannot record unfinished lesson');
    }
    final previous = receipts
        .where((r) => r.run.attemptId == run.attemptId)
        .firstOrNull;
    if (previous != null &&
        jsonEncode(previous.run.toJson()) != jsonEncode(run.toJson())) {
      throw const FormatException('Conflicting attempt ID');
    }
    return LernpfadState._(
      selectedBandId,
      active?.attemptId == run.attemptId ? null : active,
      List.unmodifiable([
        ...receipts,
        if (previous == null) FoundationReceipt._(run),
      ]),
    );
  }

  String encode() => jsonEncode({
    'version': 1,
    'selectedBandId': selectedBandId,
    'active': active?.toJson(),
    'receipts': receipts.map((r) => r.run.toJson()).toList(),
  });
  factory LernpfadState.decode(String raw, LernpfadSchema schema) {
    if (raw.isEmpty) {
      return LernpfadState.empty();
    }
    final data = jsonDecode(raw);
    if (data is! Map<String, dynamic> ||
        data['version'] != 1 ||
        data['selectedBandId'] is! String ||
        !schema.hasBand(data['selectedBandId']) ||
        data['receipts'] is! List) {
      throw const FormatException('Unsupported path state');
    }
    final active = data['active'] == null
        ? null
        : FoundationRun.fromJson(data['active']);
    if (active != null) {
      final lesson = schema.lessonById(active.lessonId);
      if (active.step < 0 ||
          (lesson != null &&
              active.current(lesson) &&
              active.step > lesson.endStep)) {
        throw const FormatException('Invalid saved step');
      }
    }
    final receipts = (data['receipts'] as List)
        .map((r) => FoundationReceipt._(FoundationRun.fromJson(r)))
        .toList();
    if (receipts.map((r) => r.run.attemptId).toSet().length !=
        receipts.length) {
      throw const FormatException('Duplicate attempt IDs');
    }
    return LernpfadState._(
      data['selectedBandId'],
      active,
      List.unmodifiable(receipts),
    );
  }
}
