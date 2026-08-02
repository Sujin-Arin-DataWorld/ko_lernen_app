import 'content_id.dart';

/// Legacy content families that can participate in the curriculum graph.
enum CurriculumContentKind { vocab, grammar, scenario, smalltalk, cloze, satz }

extension CurriculumContentKindX on CurriculumContentKind {
  String get code => name;

  static CurriculumContentKind? tryFromCode(String? value) {
    final normalized = value?.trim().toLowerCase();
    return CurriculumContentKind.values
        .cast<CurriculumContentKind?>()
        .firstWhere((kind) => kind?.code == normalized, orElse: () => null);
  }

  static CurriculumContentKind fromCode(String? value) {
    return tryFromCode(value) ?? CurriculumContentKind.vocab;
  }
}

/// The instructional purpose of a content node for a concept.
enum ContentLinkRole { introduce, practice, assess, review }

extension ContentLinkRoleX on ContentLinkRole {
  String get code => name;

  static ContentLinkRole? tryFromCode(String? value) {
    final normalized = value?.trim().toLowerCase();
    return ContentLinkRole.values.cast<ContentLinkRole?>().firstWhere(
      (role) => role?.code == normalized,
      orElse: () => null,
    );
  }

  static ContentLinkRole fromCode(String? value) {
    return tryFromCode(value) ?? ContentLinkRole.practice;
  }
}

/// A learner-facing state for an item in the course path.
enum CourseContentState {
  preview,
  introduced,
  practiceAvailable,
  checkpointPassed,
  reviewDue,
  stableMastery,
}

extension CourseContentStateX on CourseContentState {
  String get code => name;

  static CourseContentState fromCode(String? value) {
    final normalized = value?.trim();
    return CourseContentState.values.firstWhere(
      (state) => state.code == normalized,
      orElse: () => CourseContentState.preview,
    );
  }
}

/// Why an answer needs a targeted repair activity instead of vocabulary-only
/// SRS. The names intentionally match the product's feedback vocabulary.
enum MasteryErrorReason {
  batchim,
  particleRole,
  wordOrder,
  speechStyle,
  spellingSpacing,
  listening,
  vocabularyRecall,
  unknown,
}

extension MasteryErrorReasonX on MasteryErrorReason {
  String get code => name;

  static MasteryErrorReason? tryFromCode(String? value) {
    final normalized = value?.trim();
    return MasteryErrorReason.values.cast<MasteryErrorReason?>().firstWhere(
      (reason) => reason?.code == normalized,
      orElse: () => null,
    );
  }

  static MasteryErrorReason fromCode(String? value) {
    return tryFromCode(value) ?? MasteryErrorReason.unknown;
  }
}

enum ConceptKind {
  vocabulary,
  particle,
  conjugation,
  speechStyle,
  pronunciation,
  situation,
}

extension ConceptKindX on ConceptKind {
  String get code => name;

  static ConceptKind? tryFromCode(String? value) {
    final normalized = value?.trim().toLowerCase();
    return ConceptKind.values.cast<ConceptKind?>().firstWhere(
      (kind) => kind?.code.toLowerCase() == normalized,
      orElse: () => null,
    );
  }

  static ConceptKind fromCode(String? value) {
    return tryFromCode(value) ?? ConceptKind.situation;
  }
}

/// Speech style is separate from relationship context. `formal` is accepted
/// only as a backwards-compatible input and normalizes to [business].
enum SpeechStyle { polite, casual, business, intimate }

extension SpeechStyleX on SpeechStyle {
  String get code => name;

  static SpeechStyle? tryFromCode(String? value) {
    final normalized = value?.trim().toLowerCase();
    if (normalized == 'formal') return SpeechStyle.business;
    return SpeechStyle.values.cast<SpeechStyle?>().firstWhere(
      (style) => style?.code == normalized,
      orElse: () => null,
    );
  }

  static SpeechStyle fromCode(String? value) {
    return tryFromCode(value) ?? SpeechStyle.polite;
  }
}

/// A compact DE/EN/KO text contract shared by curriculum metadata.
class CurriculumText {
  final String ko;
  final String de;
  final String en;

  const CurriculumText({required this.ko, required this.de, required this.en});

  factory CurriculumText.fromJson(Map<String, dynamic>? json) => CurriculumText(
    ko: json?['ko']?.toString() ?? '',
    de: json?['de']?.toString() ?? '',
    en: json?['en']?.toString() ?? '',
  );

  Map<String, String> toJson() => {'ko': ko, 'de': de, 'en': en};

  String pick(String languageCode) {
    if (languageCode == 'ko') return ko;
    if (languageCode == 'en') return en.isNotEmpty ? en : de;
    return de.isNotEmpty ? de : en;
  }
}

/// A sequential mission in the course. Library browsing can remain free; only
/// these prerequisite/checkpoint fields govern path unlocks.
class CourseUnit {
  final String id;
  final String level;
  final int order;
  final CurriculumText title;
  final CurriculumText canDo;
  final List<String> prerequisiteUnitIds;
  final List<String> requiredConceptIds;
  final List<String> checkpointContentIds;
  final double passThreshold;
  final bool isPilot;

  const CourseUnit({
    required this.id,
    required this.level,
    required this.order,
    required this.title,
    required this.canDo,
    this.prerequisiteUnitIds = const [],
    this.requiredConceptIds = const [],
    this.checkpointContentIds = const [],
    this.passThreshold = .7,
    this.isPilot = false,
  });

  factory CourseUnit.fromJson(Map<String, dynamic> json) => CourseUnit(
    id: json['id']?.toString() ?? '',
    level: json['level']?.toString().toLowerCase() ?? '',
    order: (json['order'] as num?)?.toInt() ?? 0,
    title: CurriculumText.fromJson(_stringMap(json['title'])),
    canDo: CurriculumText.fromJson(_stringMap(json['canDo'])),
    prerequisiteUnitIds: _stringList(json['prerequisiteUnitIds']),
    requiredConceptIds: _stringList(json['requiredConceptIds']),
    checkpointContentIds: _stringList(json['checkpointContentIds']),
    passThreshold: (json['passThreshold'] as num?)?.toDouble() ?? .7,
    isPilot: json['isPilot'] == true,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'level': level,
    'order': order,
    'title': title.toJson(),
    'canDo': canDo.toJson(),
    'prerequisiteUnitIds': prerequisiteUnitIds,
    'requiredConceptIds': requiredConceptIds,
    'checkpointContentIds': checkpointContentIds,
    'passThreshold': passThreshold,
    'isPilot': isPilot,
  };
}

/// A teachable unit of knowledge tracked independently from raw content.
class Concept {
  final String id;
  final String level;
  final ConceptKind kind;
  final CurriculumText title;
  final CurriculumText explanation;
  final String? invalidKindCode;

  const Concept({
    required this.id,
    required this.level,
    required this.kind,
    required this.title,
    required this.explanation,
    this.invalidKindCode,
  });

  factory Concept.fromJson(Map<String, dynamic> json) {
    final rawKind = json['kind']?.toString();
    final kind = ConceptKindX.tryFromCode(rawKind);
    return Concept(
      id: json['id']?.toString() ?? '',
      level: json['level']?.toString().toLowerCase() ?? '',
      kind: kind ?? ConceptKind.situation,
      title: CurriculumText.fromJson(_stringMap(json['title'])),
      explanation: CurriculumText.fromJson(_stringMap(json['explanation'])),
      invalidKindCode: rawKind != null && kind == null ? rawKind : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'level': level,
    'kind': kind.code,
    'title': title.toJson(),
    'explanation': explanation.toJson(),
  };
}

/// A visible form which may be reused by vocabulary, grammar, scenario and
/// correction activities without pretending it is a dictionary headword.
class SurfaceForm {
  final String id;
  final String ko;
  final String headword;
  final CurriculumText meaning;
  final List<String> conceptIds;
  final String usageContext;

  const SurfaceForm({
    required this.id,
    required this.ko,
    required this.headword,
    required this.meaning,
    this.conceptIds = const [],
    this.usageContext = '',
  });

  factory SurfaceForm.fromJson(Map<String, dynamic> json) => SurfaceForm(
    id: json['id']?.toString() ?? '',
    ko: json['ko']?.toString() ?? '',
    headword: json['headword']?.toString() ?? '',
    meaning: CurriculumText.fromJson(_stringMap(json['meaning'])),
    conceptIds: _stringList(json['conceptIds']),
    usageContext: json['usageContext']?.toString() ?? '',
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'ko': ko,
    'headword': headword,
    'meaning': meaning.toJson(),
    'conceptIds': conceptIds,
    'usageContext': usageContext,
  };
}

/// Groups transformations that mean a closely-related intent but change due
/// to batchim, grammar role, relationship or setting.
class FormFamily {
  final String id;
  final CurriculumText title;
  final List<String> conceptIds;
  final List<String> surfaceFormIds;
  final List<String> changeAxes;

  const FormFamily({
    required this.id,
    required this.title,
    required this.conceptIds,
    required this.surfaceFormIds,
    this.changeAxes = const [],
  });

  factory FormFamily.fromJson(Map<String, dynamic> json) => FormFamily(
    id: json['id']?.toString() ?? '',
    title: CurriculumText.fromJson(_stringMap(json['title'])),
    conceptIds: _stringList(json['conceptIds']),
    surfaceFormIds: _stringList(json['surfaceFormIds']),
    changeAxes: _stringList(json['changeAxes']),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title.toJson(),
    'conceptIds': conceptIds,
    'surfaceFormIds': surfaceFormIds,
    'changeAxes': changeAxes,
  };
}

/// One directed graph edge from legacy content to course mission(s) and the
/// concept(s) it introduces, practises, assesses or repairs.
class ContentLink {
  final String id;
  final CurriculumContentKind contentKind;
  final String contentId;
  final String courseUnitId;
  final List<String> conceptIds;
  final ContentLinkRole role;
  final String? invalidContentKindCode;
  final String? invalidRoleCode;

  ContentLink({
    String? id,
    required this.contentKind,
    required this.contentId,
    required this.courseUnitId,
    required this.conceptIds,
    required this.role,
    this.invalidContentKindCode,
    this.invalidRoleCode,
  }) : id =
           id ??
           stableContentId('link', [
             contentKind.code,
             contentId,
             courseUnitId,
             conceptIds.join('|'),
             role.code,
           ]);

  String get contentKey => '${contentKind.code}:$contentId';

  factory ContentLink.fromJson(Map<String, dynamic> json) {
    final rawKind = json['contentKind']?.toString();
    final rawRole = json['role']?.toString();
    final contentKind = CurriculumContentKindX.tryFromCode(rawKind);
    final role = ContentLinkRoleX.tryFromCode(rawRole);
    return ContentLink(
      id: json['id']?.toString(),
      contentKind: contentKind ?? CurriculumContentKind.vocab,
      contentId: json['contentId']?.toString() ?? '',
      courseUnitId: json['courseUnitId']?.toString() ?? '',
      conceptIds: _stringList(json['conceptIds']),
      role: role ?? ContentLinkRole.practice,
      invalidContentKindCode: rawKind != null && contentKind == null
          ? rawKind
          : null,
      invalidRoleCode: rawRole != null && role == null ? rawRole : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'contentKind': contentKind.code,
    'contentId': contentId,
    'courseUnitId': courseUnitId,
    'conceptIds': conceptIds,
    'role': role.code,
  };
}

/// Context required to make a scenario's speech style and social safety
/// explicit. The catalog derives this normalized view from the direct
/// scenario JSON metadata so consumers do not need a competing sidecar.
class ScenarioContext {
  final String scenarioId;
  final String courseUnitId;
  final String relationshipContext;
  final String intent;
  final SpeechStyle speechStyle;
  final List<String> conceptIds;
  final String? invalidSpeechStyleCode;

  const ScenarioContext({
    required this.scenarioId,
    required this.courseUnitId,
    required this.relationshipContext,
    required this.intent,
    required this.speechStyle,
    required this.conceptIds,
    this.invalidSpeechStyleCode,
  });

  factory ScenarioContext.fromJson(Map<String, dynamic> json) {
    final rawStyle = json['speechStyle']?.toString();
    final style = SpeechStyleX.tryFromCode(rawStyle);
    return ScenarioContext(
      scenarioId: json['scenarioId']?.toString() ?? '',
      courseUnitId: json['courseUnitId']?.toString() ?? '',
      relationshipContext: json['relationshipContext']?.toString() ?? '',
      intent: json['intent']?.toString() ?? '',
      speechStyle: style ?? SpeechStyle.polite,
      conceptIds: _stringList(json['conceptIds']),
      invalidSpeechStyleCode: rawStyle != null && style == null
          ? rawStyle
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'scenarioId': scenarioId,
    'courseUnitId': courseUnitId,
    'relationshipContext': relationshipContext,
    'intent': intent,
    'speechStyle': speechStyle.code,
    'conceptIds': conceptIds,
  };
}

/// A stored answer observation. It is intentionally independent of any quiz
/// screen so all game and scenario engines can write the same evidence later.
class MasteryEvidence {
  final String id;
  final String conceptId;
  final CurriculumContentKind contentKind;
  final String contentId;

  /// Mission context captured at answer time. Together with
  /// [courseEligible], this prevents a future library attempt from becoming
  /// unlock evidence when the learner eventually reaches that mission.
  final String? courseUnitId;
  final bool isCorrect;
  final DateTime occurredAt;
  final MasteryErrorReason? errorReason;
  final double? score;

  /// Whether the attempt was made through the active course mission at the
  /// time it happened. Free library browsing is retained as learning history,
  /// but must never unlock a mission retroactively.
  final bool courseEligible;

  MasteryEvidence({
    String? id,
    required this.conceptId,
    required this.contentKind,
    required this.contentId,
    this.courseUnitId,
    required this.isCorrect,
    required this.occurredAt,
    this.errorReason,
    this.score,
    this.courseEligible = false,
  }) : id =
           id ??
           stableContentId('evidence', [
             conceptId,
             contentKind.code,
             contentId,
             courseUnitId,
             isCorrect,
             occurredAt.toUtc().toIso8601String(),
             errorReason?.code,
             score,
           ]);

  String get contentKey => '${contentKind.code}:$contentId';

  factory MasteryEvidence.fromJson(Map<String, dynamic> json) {
    final rawContentKind = json['contentKind']?.toString();
    final contentKind = CurriculumContentKindX.tryFromCode(rawContentKind);
    if (contentKind == null) {
      throw FormatException(
        'Invalid mastery evidence contentKind: ${rawContentKind ?? '<missing>'}',
      );
    }
    final conceptId = json['conceptId']?.toString().trim() ?? '';
    final contentId = json['contentId']?.toString().trim() ?? '';
    final courseUnitId = json['courseUnitId']?.toString().trim();
    if (conceptId.isEmpty || contentId.isEmpty) {
      throw const FormatException(
        'Mastery evidence requires nonempty conceptId and contentId.',
      );
    }
    if (json['isCorrect'] is! bool) {
      throw const FormatException('Mastery evidence isCorrect must be a bool.');
    }
    final occurredAt = DateTime.tryParse(json['occurredAt']?.toString() ?? '');
    if (occurredAt == null ||
        !occurredAt.isUtc ||
        occurredAt.millisecondsSinceEpoch == 0) {
      throw const FormatException(
        'Mastery evidence requires a non-epoch UTC occurredAt timestamp.',
      );
    }
    final rawErrorReason = json['errorReason'];
    final errorReason = rawErrorReason == null
        ? null
        : MasteryErrorReasonX.tryFromCode(rawErrorReason.toString());
    if (rawErrorReason != null && errorReason == null) {
      throw FormatException(
        'Invalid mastery evidence errorReason: $rawErrorReason',
      );
    }
    final rawScore = json['score'];
    if (rawScore != null && rawScore is! num) {
      throw const FormatException('Mastery evidence score must be numeric.');
    }
    final score = (rawScore as num?)?.toDouble();
    if (score != null && (!score.isFinite || score < 0 || score > 1)) {
      throw const FormatException(
        'Mastery evidence score must be between 0 and 1.',
      );
    }
    final rawCourseEligible = json['courseEligible'];
    if (rawCourseEligible != null && rawCourseEligible is! bool) {
      throw const FormatException(
        'Mastery evidence courseEligible must be a bool.',
      );
    }
    if (rawCourseEligible == true &&
        (courseUnitId == null || courseUnitId.isEmpty)) {
      throw const FormatException(
        'Eligible mastery evidence requires a courseUnitId.',
      );
    }
    return MasteryEvidence(
      id: json['id']?.toString(),
      conceptId: conceptId,
      contentKind: contentKind,
      contentId: contentId,
      courseUnitId: courseUnitId == null || courseUnitId.isEmpty
          ? null
          : courseUnitId,
      isCorrect: json['isCorrect'] as bool,
      occurredAt: occurredAt,
      errorReason: errorReason,
      score: score,
      courseEligible: rawCourseEligible == true,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'conceptId': conceptId,
    'contentKind': contentKind.code,
    'contentId': contentId,
    if (courseUnitId != null) 'courseUnitId': courseUnitId,
    'isCorrect': isCorrect,
    'occurredAt': occurredAt.toUtc().toIso8601String(),
    if (errorReason != null) 'errorReason': errorReason!.code,
    if (score != null) 'score': score,
    'courseEligible': courseEligible,
  };
}

Map<String, dynamic>? _stringMap(dynamic raw) {
  if (raw is! Map) return null;
  return raw.map((key, value) => MapEntry(key.toString(), value));
}

List<String> _stringList(dynamic raw) =>
    (raw as List? ?? const []).map((value) => value.toString()).toList();
