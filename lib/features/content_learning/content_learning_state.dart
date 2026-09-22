import 'dart:convert';
import 'package:flutter/foundation.dart' show setEquals, listEquals;
import 'content_learning_models.dart';

/// Portable versioned state with a pure deterministic account/device merge.
abstract final class ContentLearningState {
  static Map<String, dynamic> decode(String raw) {
    if (raw.isEmpty) {
      return {
        'version': 1,
        'goals': <String, dynamic>{},
        'lessons': <String, dynamic>{},
        'days': <String, dynamic>{},
      };
    }
    try {
      final state = jsonDecode(raw) as Map<String, dynamic>;
      if (state['version'] != 1) {
        throw const FormatException('Unsupported content learning version.');
      }
      for (final key in ['goals', 'lessons', 'days']) {
        final records = state[key] as Map<String, dynamic>;
        for (final entry in records.entries) {
          if (entry.key.isEmpty) {
            throw const FormatException('Missing record ID.');
          }
          final value = entry.value as Map<String, dynamic>;
          DateTime.parse(value['updatedAt'] as String);
          if (key == 'lessons') {
            final progress = ContentLessonProgress.fromJson(value);
            _scope(value);
            _string(value['topicId']);
            _attempt(value);
            _strings(value['seenIds']);
            final answers = _answers(value['answers']);
            final times = value['answerTimes'] as Map<String, dynamic>;
            if (!setEquals(answers.keys.toSet(), times.keys.toSet())) {
              throw const FormatException('Missing answer timestamps.');
            }
            for (final time in times.values) {
              DateTime.parse(time as String);
            }
            final missed = _strings(value['missedQuestionIds']).toSet();
            if (!setEquals(
              missed,
              answers.keys.where((id) => !answers[id]!).toSet(),
            )) {
              throw const FormatException('Inconsistent review history.');
            }
            if (progress.completed) {
              _date(value['completionDate']);
            } else if (value['completionDate'] != null) {
              throw const FormatException(
                'Completion date without completion.',
              );
            }
            if (value['resumeBeforeReview'] != null) {
              _attempt(value['resumeBeforeReview'] as Map<String, dynamic>);
            }
          } else {
            final scope = _scope(value);
            final target = value['target'] as int;
            if (target < 0 || target > 3) {
              throw const FormatException('Invalid goal size.');
            }
            if (key == 'days') {
              final ids = _strings(value['lessonIds']);
              final date = _date(value['date']);
              DateTime.parse(value['createdAt'] as String);
              if (value['reserveIds'] != null) {
                final reserve = _strings(value['reserveIds']);
                if (!listEquals(ids, reserve.take(ids.length).toList())) {
                  throw const FormatException(
                    'Daily plan outside frozen reserve.',
                  );
                }
              }
              if (entry.key != '$date.$scope' || target > ids.length) {
                throw const FormatException('Invalid daily plan.');
              }
            } else if (entry.key != scope) {
              throw const FormatException('Invalid goal key.');
            }
          }
        }
      }
      return state;
    } on Object catch (error) {
      throw FormatException('Invalid content learning data: $error');
    }
  }

  static String mergeJson(String left, String right) =>
      jsonEncode(merge(decode(left), decode(right)));

  static Map<String, dynamic> merge(
    Map<String, dynamic> left,
    Map<String, dynamic> right,
  ) {
    final result = decode('');
    for (final field in ['goals', 'lessons', 'days']) {
      final a = left[field] as Map<String, dynamic>,
          b = right[field] as Map<String, dynamic>;
      final output = result[field] as Map<String, dynamic>;
      for (final id in {...a.keys, ...b.keys}.toList()..sort()) {
        if (!a.containsKey(id) || !b.containsKey(id)) {
          output[id] = a[id] ?? b[id];
          continue;
        }
        final x = a[id] as Map<String, dynamic>,
            y = b[id] as Map<String, dynamic>;
        final winner = _newer(x, y);
        final merged = Map<String, dynamic>.from(winner);
        if (field == 'lessons') {
          merged['seenIds'] = {
            ...(x['seenIds'] as List),
            ...(y['seenIds'] as List),
          }.toList()..sort();
          final answers = <String, bool>{}, times = <String, String>{};
          final ax = x['answers'] as Map, ay = y['answers'] as Map;
          for (final q in {...ax.keys, ...ay.keys}.cast<String>()) {
            final tx = (x['answerTimes'] as Map)[q] as String?;
            final ty = (y['answerTimes'] as Map)[q] as String?;
            final useX =
                ty == null || (tx != null && _compareTime(tx, ty) >= 0);
            // Equal-clock concurrent answers retain review need conservatively.
            answers[q] = tx != null && ty != null && _compareTime(tx, ty) == 0
                ? ax[q] == true && ay[q] == true
                : (useX ? ax[q] : ay[q]) as bool;
            times[q] = (useX ? tx : ty)!;
          }
          merged['answers'] = answers;
          merged['answerTimes'] = times;
          merged['missedQuestionIds'] =
              answers.keys.where((q) => !answers[q]!).toList()..sort();
          if (x['attemptId'] == y['attemptId']) {
            merged['attemptAnswers'] = {
              ...x['attemptAnswers'] as Map,
              ...y['attemptAnswers'] as Map,
              ...winner['attemptAnswers'] as Map,
            };
          }
          final completed =
              [x, y].where((v) => v['completedAt'] != null).toList()..sort(
                (a, b) => _compareTime(
                  a['completedAt'] as String,
                  b['completedAt'] as String,
                ),
              );
          if (completed.isNotEmpty) {
            merged['completedAt'] = completed.first['completedAt'];
            merged['completionDate'] = completed.first['completionDate'];
          }
        } else if (field == 'days') {
          // The first explicitly started plan stays stable across devices.
          final originOrder = _compareTime(
            x['createdAt'] as String,
            y['createdAt'] as String,
          );
          var first =
              originOrder < 0 ||
                  (originOrder == 0 &&
                      jsonEncode(x['reserveIds'] ?? x['lessonIds']).compareTo(
                            jsonEncode(y['reserveIds'] ?? y['lessonIds']),
                          ) <=
                          0)
              ? x
              : y;
          if (originOrder == 0 &&
              listEquals(
                x['reserveIds'] as List? ?? x['lessonIds'] as List,
                y['reserveIds'] as List? ?? y['lessonIds'] as List,
              )) {
            first =
                (x['lessonIds'] as List).length >=
                    (y['lessonIds'] as List).length
                ? x
                : y;
          }
          merged['lessonIds'] = first['lessonIds'];
          merged['createdAt'] = first['createdAt'];
          merged['reserveIds'] = first['reserveIds'] ?? first['lessonIds'];
          final ids = (merged['lessonIds'] as List).cast<String>().toList();
          for (final id in (merged['reserveIds'] as List).cast<String>()) {
            if (ids.length >= (merged['target'] as int)) {
              break;
            }
            if (!ids.contains(id)) {
              ids.add(id);
            }
          }
          merged['lessonIds'] = ids;
          merged['target'] = (merged['target'] as int).clamp(0, ids.length);
        }
        output[id] = merged;
      }
    }
    return result;
  }

  static Map<String, dynamic> _newer(
    Map<String, dynamic> a,
    Map<String, dynamic> b,
  ) {
    final compared = _compareTime(
      a['updatedAt'] as String,
      b['updatedAt'] as String,
    );
    if (compared == 0) {
      return jsonEncode(a).compareTo(jsonEncode(b)) >= 0 ? a : b;
    }
    return compared > 0 ? a : b;
  }

  static int _compareTime(String a, String b) =>
      DateTime.parse(a).compareTo(DateTime.parse(b));

  static String _string(Object? value) {
    if (value is! String || value.trim().isEmpty) {
      throw const FormatException('Expected nonempty ID.');
    }
    return value;
  }

  static List<String> _strings(Object? value) {
    if (value is! List) {
      throw const FormatException('Expected ID list.');
    }
    final result = value.map(_string).toList();
    if (result.toSet().length != result.length) {
      throw const FormatException('Duplicate IDs.');
    }
    return result;
  }

  static Map<String, bool> _answers(Object? value) {
    if (value is! Map) {
      throw const FormatException('Expected answer map.');
    }
    return {for (final e in value.entries) _string(e.key): e.value as bool};
  }

  static String _scope(Map<String, dynamic> value) {
    LearningContentKind.values.byName(value['kind'] as String);
    if (!const ['a1', 'a2', 'b1', 'b2', 'c1', 'c2'].contains(value['level'])) {
      throw const FormatException('Invalid content level.');
    }
    return '${value['kind']}.${value['level']}';
  }

  static String _date(Object? value) {
    final date = _string(value);
    if (!RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(date) ||
        DateTime.parse(date).toIso8601String().substring(0, 10) != date) {
      throw const FormatException('Invalid learning date.');
    }
    return date;
  }

  static void _attempt(Map<String, dynamic> value) {
    ContentLessonPhase.values.byName(value['phase'] as String);
    if (value['position'] is! int ||
        (value['position'] as int) < 0 ||
        value['reviewMode'] is! bool) {
      throw const FormatException('Invalid practice cursor.');
    }
    if (value['cursorId'] != null) {
      _string(value['cursorId']);
    }
    DateTime.parse(value['attemptId'] as String);
    final queue = _strings(value['practiceQuestionIds']);
    final answers = _answers(value['attemptAnswers']);
    if (!answers.keys.every(queue.contains)) {
      throw const FormatException('Answer outside current attempt.');
    }
  }
}
