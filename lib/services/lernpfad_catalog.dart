import 'dart:convert';
import 'package:flutter/services.dart';
import '../models/course_mastery.dart';
import '../models/lernpfad.dart';
import 'phase_task_catalog.dart';

class LernpfadProjection {
  const LernpfadProjection(
    this.band,
    this.completedIds,
    this.independentIds,
    this.requiredCount,
    this.confirmedSkills,
    this.next,
  );
  final LernpfadBand band;
  final Set<String> completedIds, independentIds;
  final int requiredCount;
  final Map<String, int> confirmedSkills;
  final LernpfadActivity? next;
  int get completed => completedIds.length;
  int get independent => independentIds.length;
  bool get isComplete =>
      band.coverage == 'complete' && completed == requiredCount;
}

class LernpfadCatalog implements LernpfadSchema {
  LernpfadCatalog._(
    this.version,
    this.bands,
    this.activities,
    this.lessons,
    this.phases,
  );
  final String version;
  final List<LernpfadBand> bands;
  final List<LernpfadActivity> activities;
  final Map<String, FoundationLesson> lessons;
  final PhaseTaskCatalog phases;
  static Future<LernpfadCatalog> load() async {
    final values = await Future.wait([
      rootBundle.loadString('assets/data/lernpfad_v2.json'),
      rootBundle.loadString('assets/data/lernpfad_foundation.json'),
    ]);
    return LernpfadCatalog.parse(
      jsonDecode(values[0]),
      jsonDecode(values[1]),
      await PhaseTaskCatalog.load(),
    );
  }

  factory LernpfadCatalog.parse(
    Map<String, dynamic> data,
    Map<String, dynamic> foundation,
    PhaseTaskCatalog phases,
  ) {
    if (data['schemaVersion'] != 1 || foundation['schemaVersion'] != 1) {
      throw const FormatException('Unsupported path catalog');
    }
    final bands = (data['bands'] as List)
        .map((b) => LernpfadBand.fromJson(b))
        .toList();
    final activities = (data['activities'] as List)
        .map((a) => LernpfadActivity.fromJson(a))
        .toList();
    final lessons = (foundation['lessons'] as List)
        .map((l) => FoundationLesson.fromJson(l))
        .toList();
    final byId = {for (final a in activities) a.id: a};
    if (bands.map((b) => b.id).toSet().length != bands.length ||
        byId.length != activities.length ||
        lessons.map((l) => l.id).toSet().length != lessons.length) {
      throw const FormatException('Duplicate path IDs');
    }
    final bound = <String>{};
    for (final band in bands) {
      for (final id in band.activityIds) {
        if (byId[id]?.bandId != band.id || !bound.add(id)) {
          throw const FormatException('Invalid band binding');
        }
      }
    }
    if (bound.length != activities.length) {
      throw const FormatException('Unbound path activity');
    }
    for (final activity in activities) {
      switch (activity.kind) {
        case 'phaseTask':
          final task = phases.byId(activity.taskId!);
          for (final id in activity.preparationTaskIds) {
            phases.byId(id);
          }
          if (task.contentHash != activity.contentHash) {
            throw const FormatException('Stale path task');
          }
        case 'foundation':
          if (!lessons.any((l) => l.id == activity.id)) {
            throw const FormatException('Missing teaching');
          }
        case 'pending':
          break;
        default:
          throw const FormatException('Unknown activity type');
      }
    }
    return LernpfadCatalog._(
      data['curriculumVersion'],
      List.unmodifiable(bands),
      List.unmodifiable(activities),
      Map.unmodifiable({for (final l in lessons) l.id: l}),
      phases,
    );
  }
  @override
  bool hasBand(String id) => bands.any((b) => b.id == id);
  @override
  FoundationLesson? lessonById(String id) => lessons[id];
  LernpfadBand band(String id) => bands.firstWhere((b) => b.id == id);
  List<LernpfadActivity> forBand(String id) =>
      activities.where((a) => a.bandId == id).toList();

  List<String> preparationFor(
    LernpfadActivity activity,
    CourseMasterySnapshot? mastery,
  ) => activity.preparationTaskIds
      .where(
        (id) =>
            !(mastery?.phaseTaskEvidence.any(phases.byId(id).passedBy) ??
                false),
      )
      .toList();

  /// Read-only projection: no creation, promotion or retention of v5 evidence.
  LernpfadProjection project(
    LernpfadState state,
    CourseMasterySnapshot? mastery,
  ) {
    final selected = band(state.selectedBandId);
    final required = forBand(
      selected.id,
    ).where((a) => a.required && a.kind != 'pending').toList();
    final completed = <String>{}, independent = <String>{};
    final skills = <String, int>{};
    for (final activity in required) {
      if (activity.kind == 'foundation') {
        final lesson = lessons[activity.id]!;
        final proof = state.receipts.where((r) => r.run.complete(lesson));
        if (proof.isNotEmpty) {
          completed.add(activity.id);
        }
        if (proof.any((r) => r.independent(lesson))) {
          independent.add(activity.id);
          skills.update('reading', (n) => n + 1, ifAbsent: () => 1);
        }
      } else if (activity.kind == 'phaseTask') {
        final task = phases.byId(activity.taskId!);
        final proof =
            mastery?.phaseTaskEvidence.where(task.isCurrent).toList() ?? [];
        if (proof.any((e) {
          if (e.assessment) {
            return task.passedBy(e);
          }
          // Unscored productive submissions show practice completion only.
          if (e.score == null) {
            return task.mode == 'P';
          }
          final questions = task.practice.questions;
          final ids = questions.map((q) => q.id).toSet();
          return ids.isNotEmpty &&
              e.passedCriterionIds.every(ids.contains) &&
              (e.score! - e.passedCriterionIds.length / ids.length).abs() <
                  1e-9 &&
              e.score! >= task.minimumScore &&
              questions
                  .where((q) => q.requiredForPass)
                  .every((q) => e.passedCriterionIds.contains(q.id));
        })) {
          completed.add(activity.id);
        }
        if (proof.any(task.passedBy)) {
          independent.add(activity.id);
          skills.update(task.skill, (n) => n + 1, ifAbsent: () => 1);
        }
      }
    }
    final next = required
        .where((a) => a.kind != 'pending' && !completed.contains(a.id))
        .firstOrNull;
    return LernpfadProjection(
      selected,
      Set.unmodifiable(completed),
      Set.unmodifiable(independent),
      required.length,
      Map.unmodifiable(skills),
      next,
    );
  }
}
