import 'package:flutter/material.dart';

import 'sori/button.dart';
import '../l10n/generated/app_localizations.dart';
import '../screens/phase_task_screen.dart';
import '../services/course_progress_service.dart';
import '../services/account/cloud_write_session.dart';
import '../services/learning_phase_catalog.dart';
import '../services/phase_task_catalog.dart';

/// A task counts toward step completion when its current-revision attempt was
/// passed, or when an unassessed (practice/speaking) attempt was scored.
bool phaseTaskDone(PhaseTask task, PhaseAttemptEvidence? e) =>
    e != null &&
    task.isCurrent(e) &&
    (task.passedBy(e) || (e.score != null && !e.assessment));

/// Per-step completion in step order; never gates access to any task.
List<bool> phaseStepCompletion(
  List<LearningPhaseStep> steps,
  Map<String, PhaseTask> tasksById,
  Map<String, PhaseAttemptEvidence> history,
) => [
  for (final step in steps)
    step.taskIds.every((id) => phaseTaskDone(tasksById[id]!, history[id])),
];

class PhaseTaskPanel extends StatefulWidget {
  const PhaseTaskPanel({super.key, required this.phaseId});
  final String phaseId;
  @override
  State<PhaseTaskPanel> createState() => _PhaseTaskPanelState();
}

class _PhaseTaskPanelState extends State<PhaseTaskPanel> {
  late Future<(List<PhaseTask>, Map<String, PhaseAttemptEvidence>)> _data =
      _load();
  List<LearningPhaseStep> _steps = const [];
  @override
  void initState() {
    super.initState();
    cloudWriteSessionController.changes.addListener(_reload);
  }

  void _reload() {
    if (mounted) {
      setState(() => _data = _load());
    }
  }

  @override
  void didUpdateWidget(covariant PhaseTaskPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.phaseId != widget.phaseId) {
      _data = _load();
    }
  }

  @override
  void dispose() {
    cloudWriteSessionController.changes.removeListener(_reload);
    super.dispose();
  }

  Future<(List<PhaseTask>, Map<String, PhaseAttemptEvidence>)> _load() async {
    final session = cloudWriteSessionController.current;
    final catalog = await PhaseTaskCatalog.load();
    final tasks = catalog.forPhase(widget.phaseId);
    final phases = await LearningPhaseCatalog.load();
    _steps =
        phases.where((p) => p.id == widget.phaseId).firstOrNull?.steps ??
        const [];
    if (tasks.isEmpty) {
      return (tasks, <String, PhaseAttemptEvidence>{});
    }
    if (session != cloudWriteSessionController.current ||
        (session != null && session.mode != CloudWriteMode.ready)) {
      return (tasks, <String, PhaseAttemptEvidence>{});
    }
    final snapshot = await CourseProgressService.shared.readForDisplay();
    if (session != cloudWriteSessionController.current) {
      return (tasks, <String, PhaseAttemptEvidence>{});
    }
    final evidence =
        snapshot?.phaseTaskEvidence ?? const <PhaseAttemptEvidence>[];
    final history = <String, PhaseAttemptEvidence>{};
    for (final task in tasks) {
      final attempts = evidence.where((e) => e.taskId == task.id).toList()
        ..sort((a, b) => b.occurredAt.compareTo(a.occurredAt));
      if (attempts.isNotEmpty) {
        history[task.id] =
            attempts.where(task.passedBy).firstOrNull ?? attempts.first;
      }
    }
    return (tasks, history);
  }

  List<Widget> _body(
    BuildContext context,
    AppL10n t,
    String lang,
    List<PhaseTask> tasks,
    Map<String, PhaseAttemptEvidence> history,
  ) {
    Widget card(PhaseTask task) {
      return Card(
        child: ListTile(
          key: ValueKey('phase-task-${task.id}'),
          title: Text(task.title.pick(lang)),
          subtitle: history[task.id] == null
              ? null
              : Text(
                  !task.isCurrent(history[task.id]!)
                      ? t.phaseTaskEarlierRevision
                      : task.passedBy(history[task.id]!)
                      ? t.phaseTaskHistory
                      : history[task.id]!.score == null
                      ? t.phaseTaskUnscored
                      : !history[task.id]!.assessment
                      ? t.phaseTaskPracticeComplete
                      : t.phaseTaskNeedsPractice,
                ),
          trailing: const Icon(Icons.chevron_right),
          onTap: () async {
            await Navigator.of(context).pushNamed(
              '/learning-phase/task',
              arguments: PhaseTaskRoute(widget.phaseId, task.id),
            );
            if (mounted) {
              setState(() => _data = _load());
            }
          },
        ),
      );
    }

    if (_steps.isEmpty) {
      return [for (final task in tasks) card(task)];
    }
    final byId = {for (final task in tasks) task.id: task};
    final complete = phaseStepCompletion(_steps, byId, history);
    final next = complete.indexOf(false);
    return [
      if (next >= 0)
        Padding(
          key: const ValueKey('phase-next-step'),
          padding: const EdgeInsets.only(top: 8),
          child: Text(
            _nextStep(lang, _steps[next].title.pick(lang)),
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
      for (var i = 0; i < _steps.length; i++) ...[
        Padding(
          key: ValueKey('phase-step-${_steps[i].id}'),
          padding: const EdgeInsets.only(top: 16, bottom: 4),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  '${i + 1}. ${_steps[i].title.pick(lang)}',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              if (complete[i])
                Icon(
                  Icons.check_circle,
                  key: ValueKey('phase-step-done-${_steps[i].id}'),
                  semanticLabel: _stepDone(lang),
                  color: Theme.of(context).colorScheme.primary,
                ),
            ],
          ),
        ),
        for (final id in _steps[i].taskIds) card(byId[id]!),
      ],
    ];
  }

  // Step chrome is new copy; kept local so no ARB regeneration is needed.
  static String _stepDone(String lang) => switch (lang) {
    'ko' => '단계 완료',
    'de' => 'Schritt abgeschlossen',
    _ => 'Step completed',
  };

  static String _nextStep(String lang, String title) => switch (lang) {
    'ko' => '다음 단계: $title',
    'de' => 'Nächster Schritt: $title',
    _ => 'Next step: $title',
  };

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context),
        lang = Localizations.localeOf(context).languageCode;
    return FutureBuilder<(List<PhaseTask>, Map<String, PhaseAttemptEvidence>)>(
      future: _data,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const SizedBox.shrink();
        }
        if (snapshot.hasError) {
          return SoriButton.ghost(
            onTap: () => setState(() => _data = _load()),
            label: t.loadErrorTryAgain,
          );
        }
        if (!snapshot.hasData || snapshot.data!.$1.isEmpty) {
          return const SizedBox.shrink();
        }
        final (tasks, history) = snapshot.data!;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              t.phaseTasksTitle,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(t.phaseTasksScope),
            ..._body(context, t, lang, tasks, history),
            const SizedBox(height: 24),
          ],
        );
      },
    );
  }
}
