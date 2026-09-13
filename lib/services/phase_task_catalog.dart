import 'dart:convert';
import 'package:flutter/services.dart';
import '../models/phase_task.dart';
import '../models/phase_objective_binding.dart';
export '../models/phase_task.dart';
export '../models/phase_objective_binding.dart';

class PhaseTaskCatalog {
  PhaseTaskCatalog._(this.tasks, this.objectives, this.publications);
  static const assetPath = 'assets/data/phase_tasks.json';
  final List<PhaseTask> tasks;
  final List<PhaseObjectiveBinding> objectives;
  final List<PhasePublication> publications;
  static Future<PhaseTaskCatalog> load() async {
    final json =
        jsonDecode(await rootBundle.loadString(assetPath))
            as Map<String, dynamic>;
    final phases =
        jsonDecode(
              await rootBundle.loadString('assets/data/learning_phases.json'),
            )
            as Map<String, dynamic>;
    final catalog = parse(json);
    if (phases['schemaVersion'] != 2 ||
        phases['phaseTaskSourceSha256'] != phaseFingerprint(json)) {
      throw const FormatException(
        'Phase publication is not bound to the catalogue',
      );
    }
    final linked = <String>{};
    for (final phase in phases['phases'] as List) {
      final ids = (phase['taskIds'] as List).cast<String>();
      final actual = catalog.forPhase(phase['id'] as String);
      if (ids.toSet().length != ids.length ||
          actual.length != ids.length ||
          actual.any((t) => t.level != phase['level'] || !ids.contains(t.id))) {
        throw const FormatException('Invalid Phase task binding');
      }
      linked.addAll(ids);
    }
    if (linked.length != catalog.tasks.length) {
      throw const FormatException('Unbound published Phase task');
    }
    return catalog;
  }

  static PhaseTaskCatalog parse(Map<String, dynamic> json) {
    if (![1, 2].contains(json['schemaVersion']) ||
        json['publications'] is! Map ||
        json['tasks'] is! List) {
      throw const FormatException('Unsupported Phase task catalogue');
    }
    final tasks = (json['tasks'] as List)
        .map((t) => PhaseTask.fromJson(t as Map<String, dynamic>))
        .toList();
    final byId = {for (final task in tasks) task.id: task};
    if (byId.length != tasks.length ||
        tasks.map((t) => t.objectiveId).toSet().length != tasks.length ||
        tasks.any((t) => json['publications'][t.phaseId] != 'partial')) {
      throw const FormatException('Invalid Phase publication');
    }
    final visited = <String>{}, active = <String>{};
    void visit(String id) {
      if (active.contains(id) || !byId.containsKey(id)) {
        throw const FormatException('Missing/cyclic Phase prerequisite');
      }
      if (visited.contains(id)) {
        return;
      }
      active.add(id);
      for (final p in byId[id]!.prerequisites) {
        visit(p);
      }
      active.remove(id);
      visited.add(id);
    }

    for (final id in byId.keys) {
      visit(id);
    }
    final objectives = <PhaseObjectiveBinding>[];
    final publications = <PhasePublication>[];
    if (json['schemaVersion'] == 2) {
      objectives.addAll(
        (json['objectives'] as List).map(
          (o) => PhaseObjectiveBinding.fromJson(o as Map<String, dynamic>),
        ),
      );
      publications.addAll(
        (json['publicationRecords'] as List).map(
          (o) => PhasePublication.fromJson(o as Map<String, dynamic>),
        ),
      );
      if (objectives.isEmpty ||
          objectives.map((o) => o.id).toSet().length != objectives.length ||
          publications.map((p) => p.phaseId).toSet().length !=
              publications.length ||
          publications.length != (json['publications'] as Map).length) {
        throw const FormatException(
          'Missing/duplicate Phase publication objectives',
        );
      }
      for (final publication in publications) {
        final actual = tasks.where((t) => t.phaseId == publication.phaseId);
        if (actual.length != publication.taskHashes.length ||
            actual.any((t) => publication.taskHashes[t.id] != t.contentHash) ||
            json['publications'][publication.phaseId] != publication.status) {
          throw const FormatException('Unpublished task content');
        }
      }
      for (final objective in objectives) {
        for (final link in objective.bindings) {
          final task = byId[link.taskId];
          if (task == null ||
              task.phaseId != objective.phaseId ||
              task.level != objective.level ||
              task.mode != objective.mode ||
              (objective.skill != null && task.skill != objective.skill)) {
            throw const FormatException('Invalid objective task or level');
          }
          link.validate(task);
        }
      }
    }
    return PhaseTaskCatalog._(
      List.unmodifiable(tasks),
      List.unmodifiable(objectives),
      List.unmodifiable(publications),
    );
  }

  List<PhaseTask> forPhase(String id) =>
      tasks.where((t) => t.phaseId == id).toList(growable: false);
  PhaseTask byId(String id) => tasks.firstWhere(
    (t) => t.id == id,
    orElse: () => throw const FormatException('Unknown Phase task'),
  );
  bool accepts(PhaseTaskResult result) =>
      byId(result.task.id).contentHash == result.task.contentHash;
}
