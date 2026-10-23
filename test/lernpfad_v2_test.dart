import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:ko_lernen_app/models/lernpfad.dart';
import 'package:ko_lernen_app/models/course_mastery.dart';
import 'package:ko_lernen_app/services/lernpfad_catalog.dart';
import 'package:ko_lernen_app/services/phase_task_catalog.dart';

void main() {
  late LernpfadCatalog catalog;
  setUp(() {
    catalog = LernpfadCatalog.parse(
      jsonDecode(File('assets/data/lernpfad_v2.json').readAsStringSync()),
      jsonDecode(
        File('assets/data/lernpfad_foundation.json').readAsStringSync(),
      ),
      PhaseTaskCatalog.parse(
        jsonDecode(File('assets/data/phase_tasks.json').readAsStringSync()),
      ),
    );
  });

  test('chosen C2 remains C2 with no proof and no foundation completion', () {
    final state = LernpfadState.empty().selectBand('C2.2', catalog);
    final view = catalog.project(state, null);
    expect(view.band.id, 'C2.2');
    expect(view.completed, 0);
    expect(view.independent, 0);
    expect(view.isComplete, isFalse);
  });

  test('all legacy tasks link to exactly one display band', () {
    final tasks = catalog.activities.where((a) => a.kind == 'phaseTask');
    expect(tasks.length, 902);
    expect(tasks.map((a) => a.id).toSet().length, 902);
    expect(catalog.bands.length, 16);
  });

  test('help solves the story without making independent literacy proof', () {
    final lesson = catalog.lessons.values.first;
    final run = finish(lesson, helped: true);
    final state = LernpfadState.empty().record(run, lesson);
    final view = catalog.project(state, null);
    expect(view.completed, 1);
    expect(view.independent, 0);
    expect(view.isComplete, isFalse); // remaining curriculum is not authored.
    expect(state.receipts.length, 1);
    expect(state.record(run, lesson).receipts.length, 1);
  });

  test(
    'new independent check has a narrow reading scope, never listening or A1',
    () {
      final lesson = catalog.lessons.values.first;
      final run = finish(lesson);
      final state = LernpfadState.empty().record(run, lesson);
      final receipt = state.receipts.single;
      expect(receipt.independent(lesson), isTrue);
      expect(receipt.scope, 'taught_symbol_recognition');
      expect(catalog.project(state, null).confirmedSkills, {'reading': 1});
      expect(
        catalog.project(state.selectBand('A1.1', catalog), null).completed,
        0,
      );
    },
  );

  test('wrong check answer remains supported even after correction', () {
    final lesson = catalog.lessons.values.first;
    var run = FoundationRun.start(
      lesson,
      'mistake',
      DateTime.utc(2026, 10, 23),
    );
    for (var i = 0; i < 3; i++) {
      run = run.advance(lesson);
    }
    for (final q in lesson.practice) {
      run = run.answer(lesson, q.answer);
    }
    run = run.answer(lesson, '아'); // first check asks 어
    expect(run.step, 5);
    run = run.answer(lesson, '어').answer(lesson, '아');
    expect(run.helped, isTrue);
    expect(run.responses.where((r) => r['correct'] == false), hasLength(1));
    expect(
      LernpfadState.empty()
          .record(run, lesson)
          .receipts
          .single
          .independent(lesson),
      isFalse,
    );
  });

  test('restart resumes the exact saved step and support status', () {
    final lesson = catalog.lessons.values.first;
    final run = FoundationRun.start(
      lesson,
      'resume',
      DateTime.utc(2026, 10, 23),
    ).advance(lesson).withHelp();
    final before = LernpfadState.empty().withRun(run);
    final after = LernpfadState.decode(before.encode(), catalog);
    expect(after.active!.step, 1);
    expect(after.active!.helped, isTrue);
    expect(after.active!.attemptId, 'resume');
  });

  test(
    'future schema and invalid steps fail closed without inventing progress',
    () {
      expect(
        () => LernpfadState.decode('{"version":99}', catalog),
        throwsFormatException,
      );
      final json =
          jsonDecode(LernpfadState.empty().encode()) as Map<String, dynamic>;
      final lesson = catalog.lessons.values.first;
      json['active'] = FoundationRun.start(
        lesson,
        'bad',
        DateTime.utc(2026, 10, 23),
      ).toJson()..['step'] = 100;
      expect(
        () => LernpfadState.decode(jsonEncode(json), catalog),
        throwsFormatException,
      );
    },
  );

  test('changed content preserves receipt but cannot prove revised task', () {
    final lesson = catalog.lessons.values.first;
    final receipt = LernpfadState.empty()
        .record(finish(lesson), lesson)
        .receipts
        .single;
    final modified = FoundationLesson.fromJson({
      ...lesson.source,
      'revision': 2,
    });
    expect(receipt.independent(modified), isFalse);
  });

  test('retrying an old receipt never deletes a newer active lesson', () {
    final lesson = catalog.lessons.values.first;
    final done = finish(lesson);
    final newer = FoundationRun.start(lesson, 'newer', DateTime.now());
    final state = LernpfadState.empty().record(done, lesson).withRun(newer);
    expect(state.record(done, lesson).active?.attemptId, 'newer');
  });

  test('an incorrect phase submission is not a completed activity', () {
    final activity = catalog
        .forBand('A1.1')
        .firstWhere((a) => a.kind == 'phaseTask');
    final task = catalog.phases.byId(activity.taskId!);
    final failed = task
        .evaluate({}, assessment: false)
        .evidence('failed', DateTime.now());
    final state = LernpfadState.empty().selectBand('A1.1', catalog);
    final view = catalog.project(
      state,
      CourseMasterySnapshot(phaseTaskEvidence: [failed]),
    );
    expect(view.completedIds, isNot(contains(task.id)));
    expect(view.next?.id, task.id);
  });

  test('JSON key order alone does not invalidate a lesson receipt', () {
    final lesson = catalog.lessons.values.first;
    final reordered = FoundationLesson.fromJson(
      Map.fromEntries(lesson.source.entries.toList().reversed),
    );
    expect(reordered.hash, lesson.hash);
  });

  test('a shorter revised lesson preserves the stale cursor for restart', () {
    final lesson = catalog.lessons.values.first;
    final completed = finish(lesson);
    final oldState = LernpfadState.empty().withRun(completed);
    final revised = FoundationLesson.fromJson({
      ...lesson.source,
      'revision': 2,
      'assessment': [(lesson.source['assessment'] as List).first],
    });
    final decoded = LernpfadState.decode(
      oldState.encode(),
      _RevisedSchema(catalog, revised),
    );
    expect(decoded.active!.step, lesson.endStep);
    expect(decoded.active!.current(revised), isFalse);
  });
}

class _RevisedSchema implements LernpfadSchema {
  _RevisedSchema(this.catalog, this.lesson);
  final LernpfadCatalog catalog;
  final FoundationLesson lesson;
  @override
  bool hasBand(String id) => catalog.hasBand(id);
  @override
  FoundationLesson? lessonById(String id) =>
      id == lesson.id ? lesson : catalog.lessonById(id);
}

FoundationRun finish(FoundationLesson lesson, {bool helped = false}) {
  var run = FoundationRun.start(
    lesson,
    'attempt-1',
    DateTime.utc(2026, 10, 23),
  );
  if (helped) {
    run = run.withHelp();
  }
  for (var i = 0; i < 3; i++) {
    run = run.advance(lesson);
  }
  for (final q in [...lesson.practice, ...lesson.assessment]) {
    run = run.answer(lesson, q.answer);
  }
  return run;
}
