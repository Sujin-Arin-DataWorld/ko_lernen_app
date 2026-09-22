import 'dart:convert';
import 'package:flutter/services.dart';
import '../../models/learner_level.dart';
import 'content_learning_models.dart';

/// Authored stable lessons. Adding sources never repartitions existing lessons.
abstract final class ContentLearningCatalog {
  static final _cache = <LearningContentKind, List<ContentLesson>>{};
  static Future<List<ContentLesson>> load(LearningContentKind kind) async {
    if (_cache[kind] case final cached?) {
      return cached;
    }
    final path = switch (kind) {
      LearningContentKind.smalltalk => 'assets/data/smalltalk_lessons.json',
      LearningContentKind.listening => 'assets/data/listening_lessons.json',
    };
    final raw =
        jsonDecode(await rootBundle.loadString(path)) as Map<String, dynamic>;
    if (raw['version'] != 1) {
      throw const FormatException('Unsupported content lesson catalog.');
    }
    final lessons = List<ContentLesson>.unmodifiable(
      (raw['lessons'] as List).map(
        (j) => ContentLesson.fromJson(j as Map<String, dynamic>),
      ),
    );
    validate(lessons, kind);
    _cache[kind] = lessons;
    return lessons;
  }

  static void validate(List<ContentLesson> lessons, LearningContentKind kind) {
    final ids = <String>{}, sourceIds = <String>{}, questionIds = <String>{};
    for (final lesson in lessons) {
      if (lesson.id.isEmpty ||
          !ids.add(lesson.id) ||
          lesson.kind != kind ||
          LearnerLevel.fromCode(lesson.level)?.code != lesson.level ||
          lesson.topicId.isEmpty ||
          lesson.contentIds.isEmpty ||
          lesson.questions.isEmpty) {
        throw FormatException('Invalid lesson ${lesson.id}');
      }
      for (final id in lesson.contentIds) {
        if (id.isEmpty || !sourceIds.add(id)) {
          throw FormatException('Repeated or missing source $id');
        }
      }
      for (final question in lesson.questions) {
        if (!questionIds.add(question.id) ||
            question.sourceIds.isEmpty ||
            !question.sourceIds.every(lesson.contentIds.contains) ||
            !const ['choice', 'order'].contains(question.type) ||
            (question.type == 'choice' &&
                (question.options.length < 2 ||
                    question.correctIndex < 0 ||
                    question.correctIndex >= question.options.length)) ||
            (question.type == 'order' && question.targetKo.trim().isEmpty)) {
          throw FormatException('Invalid question ${question.id}');
        }
      }
    }
  }

  static void reset() => _cache.clear();
}
