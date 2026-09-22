import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../../services/storage_service.dart';
import 'content_learning_models.dart';
import 'content_learning_state.dart';

/// No read method writes progress, selects a daily plan, or grants rewards.
abstract final class ContentLearningService {
  static ValueNotifier<int> get changes => Storage.contentLearningChanges;
  @visibleForTesting
  static DateTime Function() clock = DateTime.now;
  static DateTime get localNow => clock().toLocal();
  static String? _cachedRaw;
  static Map<String, dynamic>? _cachedState;
  static Map<String, dynamic> _read() {
    final raw = Storage.contentLearningRawJson;
    if (raw == _cachedRaw && _cachedState != null) {
      return _cachedState!;
    }
    final decoded = ContentLearningState.decode(raw);
    _cachedRaw = raw;
    return _cachedState = decoded;
  }

  static String _scope(LearningContentKind kind, String level) {
    if (!const ['a1', 'a2', 'b1', 'b2', 'c1', 'c2'].contains(level)) {
      throw ArgumentError.value(level, 'level');
    }
    return '${kind.name}.$level';
  }

  static String _date() => localNow.toIso8601String().substring(0, 10);
  static String _dayKey(LearningContentKind kind, String level) =>
      '${_date()}.${_scope(kind, level)}';
  static String _stamp(Map<String, dynamic> state) {
    var instant = clock().toUtc();
    for (final field in ['goals', 'lessons', 'days']) {
      for (final value in (state[field] as Map).values) {
        final previous = DateTime.parse(value['updatedAt'] as String);
        if (!instant.isAfter(previous)) {
          instant = previous.add(const Duration(microseconds: 1));
        }
      }
    }
    return instant.toIso8601String();
  }

  static Future<void> _mutate(
    void Function(Map<String, dynamic>, String) action,
  ) => Storage.mutateContentLearning((raw) {
    final state = ContentLearningState.decode(raw);
    action(state, _stamp(state));
    return jsonEncode(state);
  });

  static int? goal(LearningContentKind kind, String level) =>
      (_read()['goals'] as Map)[_scope(kind, level)]?['target'] as int?;

  /// Explicit retry resolves an uncertain native write without advancing work.
  static Future<void> refresh() async {
    await Storage.mutateContentLearning((raw) {
      ContentLearningState.decode(raw);
      return raw;
    });
    changes.value++;
  }

  static Future<void> setGoal(
    LearningContentKind kind,
    String level,
    int target,
  ) {
    if (target < 0 || target > 3) {
      throw ArgumentError.value(target, 'target');
    }
    final scope = _scope(kind, level);
    return _mutate((state, stamp) {
      state['goals'][scope] = {
        'kind': kind.name,
        'level': level,
        'target': target,
        'updatedAt': stamp,
      };
      final day = state['days'][_dayKey(kind, level)] as Map<String, dynamic>?;
      if (day != null) {
        // Only an explicit goal edit may extend the plan, from the reserve
        // frozen at its start. New catalog entries never reshuffle this day.
        final ids = (day['lessonIds'] as List).cast<String>().toList();
        final reserve = (day['reserveIds'] as List? ?? const []).cast<String>();
        for (final id in reserve) {
          if (ids.length >= target) {
            break;
          }
          if (!ids.contains(id)) {
            ids.add(id);
          }
        }
        day['lessonIds'] = ids;
        day['target'] = target.clamp(0, (day['lessonIds'] as List).length);
        day['updatedAt'] = stamp;
      }
    });
  }

  static ContentLessonProgress progress(String lessonId) {
    final raw = _read()['lessons'][lessonId] as Map<String, dynamic>?;
    return raw == null
        ? const ContentLessonProgress()
        : ContentLessonProgress.fromJson(raw);
  }

  static Map<String, dynamic> _newProgress(
    ContentLesson lesson,
    String stamp,
  ) => {
    'kind': lesson.kind.name,
    'level': lesson.level,
    'topicId': lesson.topicId,
    'phase': 'learn',
    'position': 0,
    'cursorId': lesson.contentIds.first,
    'seenIds': <String>[],
    'answers': <String, bool>{},
    'answerTimes': <String, String>{},
    'attemptAnswers': <String, bool>{},
    'attemptId': stamp,
    'missedQuestionIds': <String>[],
    'completedAt': null,
    'completionDate': null,
    'reviewMode': false,
    'practiceQuestionIds': <String>[],
    'updatedAt': stamp,
  };
  static Map<String, dynamic> _progress(
    Map<String, dynamic> state,
    ContentLesson lesson,
    String stamp,
  ) =>
      (state['lessons'][lesson.id] ??= _newProgress(lesson, stamp))
          as Map<String, dynamic>;

  static Future<void> startLesson(
    ContentLesson lesson,
    List<ContentLesson> scope,
  ) => _mutate((state, stamp) {
    if (lesson.contentIds.isEmpty || lesson.questions.isEmpty) {
      throw StateError('Cannot start an empty lesson.');
    }
    final p = _progress(state, lesson, stamp);
    if (p['completedAt'] == null &&
        p['phase'] == 'complete' &&
        p['resumeBeforeReview'] is Map) {
      p.addAll(
        Map<String, dynamic>.from(p.remove('resumeBeforeReview') as Map),
      );
      p['updatedAt'] = stamp;
    }
    final target =
        state['goals'][_scope(lesson.kind, lesson.level)]?['target'] as int? ??
        0;
    if (p['completedAt'] != null ||
        target == 0 ||
        state['days'].containsKey(_dayKey(lesson.kind, lesson.level))) {
      return;
    }
    final available = scope
        .where(
          (l) =>
              l.kind == lesson.kind &&
              l.level == lesson.level &&
              state['lessons'][l.id]?['completedAt'] == null,
        )
        .toList();
    // Selected lesson first, then resume unfinished work before unseen lessons.
    available.sort((a, b) {
      int rank(ContentLesson l) => l.id == lesson.id
          ? 0
          : state['lessons'].containsKey(l.id)
          ? 1
          : l.topicId == lesson.topicId
          ? 2
          : 3;
      final compared = rank(a).compareTo(rank(b));
      return compared == 0
          ? scope.indexOf(a).compareTo(scope.indexOf(b))
          : compared;
    });
    final reserve = <String>{
      lesson.id,
      ...available.map((l) => l.id).where((id) => id != lesson.id),
    }.take(3).toList();
    final ids = reserve.take(target).toList();
    state['days'][_dayKey(lesson.kind, lesson.level)] = {
      'kind': lesson.kind.name,
      'level': lesson.level,
      'date': _date(),
      'target': ids.length,
      'lessonIds': ids,
      'reserveIds': reserve,
      'createdAt': stamp,
      'updatedAt': stamp,
    };
  });

  static Future<void> savePosition(
    ContentLesson lesson,
    ContentLessonPhase phase,
    int position, {
    bool sourcesComplete = false,
  }) => _mutate((state, stamp) {
    if (position < 0 || phase == ContentLessonPhase.complete) {
      throw ArgumentError('Completion must go through finish.');
    }
    final p = _progress(state, lesson, stamp);
    p['phase'] = phase.name;
    p['position'] = position;
    final seen = (p['seenIds'] as List).cast<String>().toSet();
    if (sourcesComplete) {
      seen.addAll(lesson.contentIds);
    }
    if (phase == ContentLessonPhase.learn) {
      if (lesson.kind == LearningContentKind.smalltalk) {
        seen.addAll(lesson.contentIds.take(position));
        p['cursorId'] = position < lesson.contentIds.length
            ? lesson.contentIds[position]
            : null;
      } else {
        p['cursorId'] = lesson.contentIds.first;
      }
    } else {
      seen.addAll(lesson.contentIds);
      if ((p['practiceQuestionIds'] as List).isEmpty) {
        p['practiceQuestionIds'] = lesson.questions.map((q) => q.id).toList();
      }
      final queue = p['practiceQuestionIds'] as List;
      p['cursorId'] = position < queue.length ? queue[position] : null;
    }
    p['seenIds'] = seen.toList();
    p['updatedAt'] = stamp;
  });

  static Future<void> answer(
    ContentLesson lesson,
    String questionId,
    bool correct,
  ) => _mutate((state, stamp) {
    final p = _progress(state, lesson, stamp);
    final queue = (p['practiceQuestionIds'] as List).cast<String>();
    if (p['phase'] != 'practice' ||
        !queue.contains(questionId) ||
        !lesson.questions.any((q) => q.id == questionId)) {
      throw StateError('Question is not in this practice attempt.');
    }
    p['answers'][questionId] = correct;
    p['answerTimes'][questionId] = stamp;
    p['attemptAnswers'][questionId] = correct;
    p['missedQuestionIds'] = (p['answers'] as Map).keys
        .where((id) => p['answers'][id] == false)
        .toList();
    final next = queue.indexWhere(
      (id) => !(p['attemptAnswers'] as Map).containsKey(id),
    );
    p['position'] = next < 0 ? queue.length : next;
    p['cursorId'] = next < 0 ? null : queue[next];
    p['updatedAt'] = stamp;
  });

  static Future<void> finish(ContentLesson lesson) => _mutate((state, stamp) {
    final p = _progress(state, lesson, stamp);
    final queue = (p['practiceQuestionIds'] as List).cast<String>();
    if (queue.isEmpty ||
        !queue.every((id) => (p['attemptAnswers'] as Map).containsKey(id))) {
      throw StateError('Practice has unanswered questions.');
    }
    // Practising only already seen cards cannot complete an unfinished lesson.
    if (p['completedAt'] == null &&
        lesson.questions.every(
          (q) => (p['answers'] as Map).containsKey(q.id),
        )) {
      p['completedAt'] = stamp;
      p['completionDate'] = _date();
    }
    p['phase'] = 'complete';
    p['updatedAt'] = stamp;
  });

  static Future<void> beginReview(
    ContentLesson lesson, {
    bool mistakesOnly = false,
  }) => _mutate((state, stamp) {
    final p = _progress(state, lesson, stamp);
    final seen = (p['seenIds'] as List).cast<String>().toSet();
    final questions = lesson.questions
        .where(
          (q) =>
              q.sourceIds.every(seen.contains) &&
              (!mistakesOnly ||
                  (p['missedQuestionIds'] as List).contains(q.id)),
        )
        .map((q) => q.id)
        .toList();
    if (questions.isEmpty) {
      throw StateError('No studied questions available for review.');
    }
    questions.shuffle();
    if (p['completedAt'] == null && p['reviewMode'] == false) {
      p['resumeBeforeReview'] = {
        for (final key in [
          'phase',
          'position',
          'cursorId',
          'practiceQuestionIds',
          'attemptAnswers',
          'attemptId',
          'reviewMode',
        ])
          key: p[key],
      };
    }
    p['phase'] = 'practice';
    p['position'] = 0;
    p['cursorId'] = questions.first;
    p['reviewMode'] = true;
    p['practiceQuestionIds'] = questions;
    p['attemptAnswers'] = <String, bool>{};
    p['attemptId'] = stamp;
    p['updatedAt'] = stamp;
  });

  /// Reopens source learning without undoing completion or awarding it again.
  static Future<void> restartLearning(ContentLesson lesson) =>
      _mutate((state, stamp) {
        final p = _progress(state, lesson, stamp);
        p['phase'] = 'learn';
        p['position'] = 0;
        p['cursorId'] = lesson.contentIds.first;
        p['reviewMode'] = p['completedAt'] != null;
        p['practiceQuestionIds'] = <String>[];
        p['attemptAnswers'] = <String, bool>{};
        p['attemptId'] = stamp;
        p.remove('resumeBeforeReview');
        p['updatedAt'] = stamp;
      });

  static ContentDailyProgress daily(LearningContentKind kind, String level) =>
      _daily(_read(), kind, level);
  static ContentDailyProgress _daily(
    Map<String, dynamic> state,
    LearningContentKind kind,
    String level,
  ) {
    final value = state['days'][_dayKey(kind, level)] as Map<String, dynamic>?;
    final ids = value == null
        ? <String>[]
        : (value['lessonIds'] as List).cast<String>();
    return ContentDailyProgress(
      kind: kind,
      level: level,
      date: _date(),
      target: value?['target'] as int? ?? 0,
      lessonIds: List.unmodifiable(ids),
      completedIds: Set.unmodifiable(
        ids.where((id) => state['lessons'][id]?['completionDate'] == _date()),
      ),
    );
  }

  static List<ContentDailyProgress> activeDaily() {
    final state = _read();
    return List.unmodifiable(
      (state['days'] as Map).values
          .where((d) => d['date'] == _date() && d['target'] > 0)
          .map(
            (d) => _daily(
              state,
              LearningContentKind.values.byName(d['kind'] as String),
              d['level'] as String,
            ),
          ),
    );
  }

  static Future<void> mergeCloudJson(
    String remote, {
    void Function()? beforeWrite,
  }) => Storage.mutateContentLearning(
    (local) => ContentLearningState.mergeJson(local, remote),
    assertCurrentWrite: beforeWrite,
  );
}
