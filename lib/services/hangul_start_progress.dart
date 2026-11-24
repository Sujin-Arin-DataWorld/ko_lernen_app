import 'dart:async';
import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'catalog_history_lease.dart';
import 'hangul_foundation_catalog.dart';

enum HangulStartEntry { map, resume, quiz }

@immutable
class HangulStartCursor {
  const HangulStartCursor(this.lessonId, this.stage, this.item);

  final String lessonId;
  final int stage;
  final int item;

  factory HangulStartCursor.fromJson(Map<String, dynamic> json) {
    final lessonId = json['lesson'];
    final stage = json['stage'];
    final item = json['item'];
    if (lessonId is! String ||
        stage is! int ||
        item is! int ||
        stage < 0 ||
        stage > 6 ||
        item < 0) {
      throw const FormatException('Invalid Hangul Start cursor');
    }
    return HangulStartCursor(lessonId, stage, item);
  }

  Map<String, Object> toJson() => {
    'lesson': lessonId,
    'stage': stage,
    'item': item,
  };
}

@immutable
class HangulStartProgress {
  const HangulStartProgress({
    this.completed = const {},
    this.cursor,
    this.passed = false,
  });

  final Set<String> completed;
  final HangulStartCursor? cursor;
  final bool passed;

  bool get started => cursor != null || completed.isNotEmpty;

  factory HangulStartProgress.fromJson(Map<String, dynamic> json) {
    if (json['version'] != 1 ||
        json['completed'] is! List ||
        json['passed'] is! bool) {
      throw const FormatException('Invalid Hangul Start progress');
    }
    return HangulStartProgress(
      completed: Set.unmodifiable(
        (json['completed'] as List).whereType<String>(),
      ),
      cursor: json['cursor'] is Map<String, dynamic>
          ? HangulStartCursor.fromJson(json['cursor'] as Map<String, dynamic>)
          : null,
      passed: json['passed'] as bool,
    );
  }

  Map<String, Object?> toJson() => {
    'version': 1,
    'completed': completed.toList()..sort(),
    'cursor': cursor?.toJson(),
    'passed': passed,
  };
}

/// A read-only projection of the same saved lesson state displayed in Today.
@immutable
class HangulStartHome {
  const HangulStartHome(this.catalog, this.progress);

  final HangulFoundation catalog;
  final HangulStartProgress progress;

  int get completedCount => catalog.lessons
      .where((lesson) => progress.completed.contains(lesson.id))
      .length;
  bool get finished =>
      progress.passed || completedCount == catalog.lessons.length;

  FoundationLesson? get nextLesson {
    final cursor = progress.cursor;
    if (cursor != null && !progress.completed.contains(cursor.lessonId)) {
      final lesson = catalog.lessonById(cursor.lessonId);
      if (lesson != null) return lesson;
    }
    for (final lesson in catalog.lessons) {
      if (!progress.completed.contains(lesson.id)) return lesson;
    }
    return null;
  }
}

/// Versioned local progress. Writes are serialized and associated with the
/// account and local-data lifetime captured by the screen that initiated them.
final class HangulStartProgressStore {
  HangulStartProgressStore({CatalogHistoryLease? lease})
    : _lease = lease ?? CatalogHistoryLease.capture();

  static Future<void>? _pending;
  final CatalogHistoryLease _lease;

  bool get isCurrent => _lease.isCurrent;

  String get _key {
    final uid = _lease.session?.uid;
    final scope = uid == null
        ? 'local'
        : sha256.convert(utf8.encode(uid)).toString();
    return 'kl_hangul_start_progress_v1_$scope';
  }

  void _check() {
    if (!isCurrent) throw StateError('Hangul Start account changed');
  }

  HangulStartProgress _read(SharedPreferences prefs) {
    final raw = prefs.getString(_key);
    if (raw == null) return const HangulStartProgress();
    try {
      final decoded = jsonDecode(raw);
      return decoded is Map<String, dynamic>
          ? HangulStartProgress.fromJson(decoded)
          : const HangulStartProgress();
    } on FormatException {
      return const HangulStartProgress();
    }
  }

  Future<T> _serialize<T>(Future<T> Function() operation) {
    final before = _pending;
    final result = before == null
        ? Future<T>.sync(operation)
        : before.then((_) => operation());
    final tail = result.then<void>(
      (_) {},
      onError: (Object _, StackTrace _) {},
    );
    _pending = tail;
    unawaited(
      tail.then((_) {
        if (identical(_pending, tail)) _pending = null;
      }),
    );
    return result;
  }

  Future<HangulStartProgress> load() => _serialize(() async {
    _check();
    final prefs = await SharedPreferences.getInstance();
    _check();
    return _read(prefs);
  });

  Future<HangulStartProgress> setCursor(HangulStartCursor cursor) => _update(
    (old) => HangulStartProgress(
      completed: old.completed,
      cursor: cursor,
      passed: old.passed,
    ),
  );

  Future<HangulStartProgress> complete(String lessonId) => _update(
    (old) => HangulStartProgress(
      completed: Set.unmodifiable({...old.completed, lessonId}),
      cursor: old.cursor?.lessonId == lessonId ? null : old.cursor,
      passed: old.passed,
    ),
  );

  Future<HangulStartProgress> pass() => _update(
    (old) => HangulStartProgress(
      completed: old.completed,
      cursor: old.cursor,
      passed: true,
    ),
  );

  Future<HangulStartProgress> _update(
    HangulStartProgress Function(HangulStartProgress) change,
  ) => _serialize(() async {
    _check();
    final prefs = await SharedPreferences.getInstance();
    _check();
    final progress = change(_read(prefs));
    if (!await prefs.setString(_key, jsonEncode(progress.toJson()))) {
      throw StateError('Hangul Start progress could not be saved');
    }
    _check();
    return progress;
  });
}
