import '../../models/scenario.dart';

enum LearningContentKind { smalltalk, listening }

enum ContentLessonPhase { learn, practice, complete }

class ContentLesson {
  const ContentLesson({
    required this.id,
    required this.kind,
    required this.level,
    required this.topicId,
    required this.title,
    required this.intro,
    required this.contentIds,
    required this.questions,
  });
  final String id, level, topicId;
  final LearningContentKind kind;
  final LocalizedText title, intro;
  final List<String> contentIds;
  final List<ContentLessonQuestion> questions;

  factory ContentLesson.fromJson(Map<String, dynamic> json) => ContentLesson(
    id: json['id'] as String,
    kind: LearningContentKind.values.byName(json['kind'] as String),
    level: json['level'] as String,
    topicId: json['topicId'] as String,
    title: LocalizedText.fromJson(json['title'] as Map<String, dynamic>),
    intro: LocalizedText.fromJson(json['intro'] as Map<String, dynamic>),
    contentIds: List<String>.unmodifiable(json['contentIds'] as List),
    questions: List.unmodifiable(
      (json['questions'] as List).map(
        (q) => ContentLessonQuestion.fromJson(q as Map<String, dynamic>),
      ),
    ),
  );
}

class ContentLessonQuestion {
  const ContentLessonQuestion({
    required this.id,
    required this.type,
    required this.skill,
    required this.prompt,
    required this.explanation,
    required this.sourceIds,
    this.options = const [],
    this.correctIndex = 0,
    this.audioKo = '',
    this.evidenceKo = '',
    this.targetKo = '',
  });
  final String id, type, skill, audioKo, evidenceKo, targetKo;
  final LocalizedText prompt, explanation;
  final List<LocalizedText> options;
  final int correctIndex;
  final List<String> sourceIds;

  factory ContentLessonQuestion.fromJson(Map<String, dynamic> json) =>
      ContentLessonQuestion(
        id: json['id'] as String,
        type: json['type'] as String,
        skill: json['skill'] as String,
        prompt: LocalizedText.fromJson(json['prompt'] as Map<String, dynamic>),
        explanation: LocalizedText.fromJson(
          json['explanation'] as Map<String, dynamic>,
        ),
        sourceIds: List<String>.unmodifiable(json['sourceIds'] as List),
        options: List.unmodifiable(
          ((json['options'] as List?) ?? const []).map(
            (o) => LocalizedText.fromJson(o as Map<String, dynamic>),
          ),
        ),
        correctIndex: json['correctIndex'] as int? ?? 0,
        audioKo: json['audioKo'] as String? ?? '',
        evidenceKo: json['evidenceKo'] as String? ?? '',
        targetKo: json['targetKo'] as String? ?? '',
      );
}

class ContentLessonProgress {
  const ContentLessonProgress({
    this.phase = ContentLessonPhase.learn,
    this.position = 0,
    this.seenIds = const {},
    this.answers = const {},
    this.missedQuestionIds = const {},
    this.completed = false,
    this.reviewMode = false,
    this.practiceQuestionIds = const [],
    this.lastUpdatedAt,
    this.completedAt,
    this.cursorId,
  });
  final ContentLessonPhase phase;
  final int position;
  final Set<String> seenIds, missedQuestionIds;
  final Map<String, bool> answers;
  final bool completed, reviewMode;
  final List<String> practiceQuestionIds;
  final DateTime? lastUpdatedAt, completedAt;

  /// Stable card/question ID; [position] is only the fallback line/queue offset.
  final String? cursorId;

  factory ContentLessonProgress.fromJson(Map<String, dynamic> json) =>
      ContentLessonProgress(
        phase: ContentLessonPhase.values.byName(json['phase'] as String),
        position: json['position'] as int,
        seenIds: Set.unmodifiable((json['seenIds'] as List).cast<String>()),
        answers: Map.unmodifiable(
          (json['answers'] as Map).cast<String, bool>(),
        ),
        missedQuestionIds: Set.unmodifiable(
          (json['missedQuestionIds'] as List).cast<String>(),
        ),
        completed: json['completedAt'] != null,
        completedAt: json['completedAt'] == null
            ? null
            : DateTime.parse(json['completedAt'] as String),
        reviewMode: json['reviewMode'] as bool,
        practiceQuestionIds: List<String>.unmodifiable(
          json['practiceQuestionIds'] as List,
        ),
        lastUpdatedAt: DateTime.parse(json['updatedAt'] as String),
        cursorId: json['cursorId'] as String?,
      );
}

class ContentDailyProgress {
  const ContentDailyProgress({
    required this.kind,
    required this.level,
    this.target = 0,
    this.lessonIds = const [],
    this.completedIds = const {},
    this.date = '',
  });
  final LearningContentKind kind;
  final String level, date;
  final int target;
  final List<String> lessonIds;
  final Set<String> completedIds;
  int get completedCount => completedIds.intersection(lessonIds.toSet()).length;
  bool get isComplete => target > 0 && completedCount >= target;
}
