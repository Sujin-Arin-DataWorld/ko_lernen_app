import 'package:flutter/material.dart';
import 'sori/button.dart';
import '../l10n/generated/app_localizations.dart';
import '../screens/phase_task_screen.dart';
import '../services/course_progress_service.dart';
import '../services/account/cloud_write_session.dart';
import '../services/phase_task_catalog.dart';

class PhaseTaskPanel extends StatefulWidget {
  const PhaseTaskPanel({super.key, required this.phaseId});
  final String phaseId;
  @override
  State<PhaseTaskPanel> createState() => _PhaseTaskPanelState();
}

class _PhaseTaskPanelState extends State<PhaseTaskPanel> {
  late Future<(List<PhaseTask>, Map<String, PhaseAttemptEvidence>)> _data =
      _load();
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
            for (final task in tasks)
              Card(
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
              ),
            const SizedBox(height: 24),
          ],
        );
      },
    );
  }
}
