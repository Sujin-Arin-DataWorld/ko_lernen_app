import 'package:flutter/material.dart';

import 'sori/button.dart';
import 'sori/hangul_start_material.dart';
import '../l10n/generated/app_localizations.dart';
import '../screens/phase_task_screen.dart';
import '../services/course_progress_service.dart';
import '../services/account/cloud_write_session.dart';
import '../services/learning_phase_catalog.dart';
import '../services/phase_task_catalog.dart';

/// A task counts toward step completion once any current-revision attempt
/// either passed its assessment, or could not be machine-judged (`score` is
/// null: speaking, free text, or a sentence outside the known answers). A
/// scored practice attempt alone does not count, so a wrong answer never
/// marks a step done. Older revisions never count.
bool phaseTaskDone(PhaseTask task, Iterable<PhaseAttemptEvidence> attempts) =>
    attempts.any(
      (e) => task.isCurrent(e) && (task.passedBy(e) || e.score == null),
    );

/// Per-step completion in step order; never gates access to any task. A step
/// naming a task missing from the catalog is reported as not done.
List<bool> phaseStepCompletion(
  List<LearningPhaseStep> steps,
  Map<String, PhaseTask> tasksById,
  Map<String, List<PhaseAttemptEvidence>> attempts,
) => [
  for (final step in steps)
    step.taskIds.every((id) {
      final task = tasksById[id];
      return task != null &&
          phaseTaskDone(task, attempts[id] ?? const <PhaseAttemptEvidence>[]);
    }),
];

typedef _PanelData = (
  List<PhaseTask> tasks,
  Map<String, PhaseAttemptEvidence> history,
  Map<String, List<PhaseAttemptEvidence>> attempts,
);

class PhaseTaskPanel extends StatefulWidget {
  const PhaseTaskPanel({
    super.key,
    required this.phaseId,
    this.steps = const [],
    this.hangulStart = false,
  });
  final String phaseId;
  final bool hangulStart;

  /// The Phase's step grouping; empty shows one flat list.
  final List<LearningPhaseStep> steps;
  @override
  State<PhaseTaskPanel> createState() => _PhaseTaskPanelState();
}

class _PhaseTaskPanelState extends State<PhaseTaskPanel> {
  late Future<_PanelData> _data = _load();
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

  Future<_PanelData> _load() async {
    final session = cloudWriteSessionController.current;
    final catalog = await PhaseTaskCatalog.load();
    final tasks = catalog.forPhase(widget.phaseId);
    _PanelData empty() => (
      tasks,
      <String, PhaseAttemptEvidence>{},
      <String, List<PhaseAttemptEvidence>>{},
    );
    if (tasks.isEmpty) {
      return empty();
    }
    if (session != cloudWriteSessionController.current ||
        (session != null && session.mode != CloudWriteMode.ready)) {
      return empty();
    }
    final snapshot = await CourseProgressService.shared.readForDisplay();
    if (session != cloudWriteSessionController.current) {
      return empty();
    }
    final evidence =
        snapshot?.phaseTaskEvidence ?? const <PhaseAttemptEvidence>[];
    final history = <String, PhaseAttemptEvidence>{};
    final byTask = <String, List<PhaseAttemptEvidence>>{};
    for (final task in tasks) {
      final attempts = evidence.where((e) => e.taskId == task.id).toList()
        ..sort((a, b) => b.occurredAt.compareTo(a.occurredAt));
      if (attempts.isNotEmpty) {
        // The card label keeps showing the passed or latest attempt; step
        // completion looks at every attempt so a later practice run cannot
        // hide an earlier submission.
        history[task.id] =
            attempts.where(task.passedBy).firstOrNull ?? attempts.first;
        byTask[task.id] = List.unmodifiable(attempts);
      }
    }
    return (tasks, history, byTask);
  }

  List<Widget> _body(
    BuildContext context,
    AppL10n t,
    String lang,
    List<PhaseTask> tasks,
    Map<String, PhaseAttemptEvidence> history,
    Map<String, List<PhaseAttemptEvidence>> attempts,
  ) {
    Future<void> open(PhaseTask task) async {
      await Navigator.of(context).pushNamed(
        '/learning-phase/task',
        arguments: PhaseTaskRoute(
          widget.phaseId,
          task.id,
          hangulStart: widget.hangulStart,
        ),
      );
      _reload();
    }

    Widget card(PhaseTask task) {
      final evidence = history[task.id];
      final status = evidence == null
          ? null
          : !task.isCurrent(evidence)
          ? t.phaseTaskEarlierRevision
          : task.passedBy(evidence)
          ? t.phaseTaskHistory
          : evidence.score == null
          ? t.phaseTaskUnscored
          : !evidence.assessment
          ? t.phaseTaskPracticeComplete
          : t.phaseTaskNeedsPractice;
      if (widget.hangulStart) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: HangulStartTile(
            key: ValueKey('phase-task-${task.id}'),
            onTap: () => open(task),
            child: Row(
              children: [
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    task.title.pick(lang),
                    style: HangulStartStyle.body(context, 14, strong: true),
                  ),
                ),
                if (status != null)
                  Expanded(
                    child: Text(
                      status,
                      textAlign: TextAlign.end,
                      style: HangulStartStyle.body(
                        context,
                        12,
                        color: HangulStartStyle.muted,
                      ),
                    ),
                  ),
                const Icon(
                  Icons.chevron_right,
                  size: 16,
                  color: HangulStartStyle.deep,
                ),
              ],
            ),
          ),
        );
      }
      return Card(
        child: ListTile(
          key: ValueKey('phase-task-${task.id}'),
          title: Text(task.title.pick(lang)),
          subtitle: status == null ? null : Text(status),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => open(task),
        ),
      );
    }

    if (widget.steps.isEmpty) {
      return [for (final task in tasks) card(task)];
    }
    final byId = {for (final task in tasks) task.id: task};
    final complete = phaseStepCompletion(widget.steps, byId, attempts);
    final next = complete.indexOf(false);
    if (widget.hangulStart) {
      final nextTask = next < 0
          ? null
          : widget.steps[next].taskIds
                .map((id) => byId[id])
                .whereType<PhaseTask>()
                .where(
                  (task) => !phaseTaskDone(task, attempts[task.id] ?? const []),
                )
                .firstOrNull;
      return [
        if (next >= 0)
          DecoratedBox(
            key: const ValueKey('phase-next-step'),
            decoration: BoxDecoration(
              color: HangulStartStyle.mist,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Padding(
              padding: const EdgeInsets.all(9),
              child: Text(
                t.phaseStepNext(widget.steps[next].title.pick(lang)),
                style: HangulStartStyle.body(
                  context,
                  14,
                  color: HangulStartStyle.deep,
                ),
              ),
            ),
          ),
        for (final (i, step) in widget.steps.indexed)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: HangulStartPanel(
              padding: const EdgeInsets.symmetric(horizontal: 7),
              child: ExpansionTile(
                key: ValueKey('phase-step-${step.id}'),
                initiallyExpanded: i == 0,
                tilePadding: const EdgeInsets.symmetric(horizontal: 5),
                shape: const Border(),
                collapsedShape: const Border(),
                leading: Icon(
                  complete[i] ? Icons.check_circle : Icons.bookmark,
                  size: 16,
                  semanticLabel: complete[i] ? t.phaseStepDone : null,
                  color: complete[i]
                      ? HangulStartStyle.jade
                      : HangulStartStyle.wrong,
                ),
                title: Text(
                  '${i + 1}. ${step.title.pick(lang)}',
                  style: HangulStartStyle.heading(context, 14),
                ),
                children: [
                  for (final id in step.taskIds)
                    if (byId[id] case final task?) card(task),
                ],
              ),
            ),
          ),
        if (nextTask != null)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: HangulStartAction(
              label: t.hangulStartNext,
              onTap: () => open(nextTask),
            ),
          ),
      ];
    }
    return [
      if (next >= 0)
        Padding(
          key: const ValueKey('phase-next-step'),
          padding: const EdgeInsets.only(top: 8),
          child: Text(
            t.phaseStepNext(widget.steps[next].title.pick(lang)),
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
      for (var i = 0; i < widget.steps.length; i++) ...[
        Padding(
          key: ValueKey('phase-step-${widget.steps[i].id}'),
          padding: const EdgeInsets.only(top: 16, bottom: 4),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  '${i + 1}. ${widget.steps[i].title.pick(lang)}',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              if (complete[i])
                Icon(
                  Icons.check_circle,
                  key: ValueKey('phase-step-done-${widget.steps[i].id}'),
                  semanticLabel: t.phaseStepDone,
                  color: Theme.of(context).colorScheme.primary,
                ),
            ],
          ),
        ),
        for (final id in widget.steps[i].taskIds)
          if (byId[id] case final task?) card(task),
      ],
    ];
  }

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context),
        lang = Localizations.localeOf(context).languageCode;
    return FutureBuilder<_PanelData>(
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
        final (tasks, history, attempts) = snapshot.data!;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (!widget.hangulStart) ...[
              Text(
                t.phaseTasksTitle,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(t.phaseTasksScope),
            ],
            ..._body(context, t, lang, tasks, history, attempts),
            const SizedBox(height: 24),
          ],
        );
      },
    );
  }
}
