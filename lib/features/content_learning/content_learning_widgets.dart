import '../../services/local_data_lifetime.dart';
import 'package:flutter/material.dart';

import '../../l10n/generated/app_localizations.dart';
import '../../widgets/sori/button.dart';
import '../../widgets/sori/card.dart';
import '../../widgets/sori/study_frame.dart';
import '../../widgets/sori/tokens.dart';
import 'content_learning_models.dart';
import 'content_learning_layout.dart';
import 'content_learning_day_refresh.dart';
import 'content_learning_service.dart';

String contentKindTitle(AppL10n t, LearningContentKind kind) =>
    kind == LearningContentKind.smalltalk ? t.smalltalkTitle : t.listeningTitle;

class ContentLearningFailure extends StatefulWidget {
  const ContentLearningFailure({super.key, required this.onRetry});
  final VoidCallback onRetry;
  @override
  State<ContentLearningFailure> createState() => _ContentLearningFailureState();
}

class _ContentLearningFailureState extends State<ContentLearningFailure> {
  final _lifetime = LocalDataLifetime.capture();
  bool _retrying = false;
  Future<void> _retry() async {
    if (_retrying) {
      return;
    }
    setState(() => _retrying = true);
    try {
      _lifetime.assertCurrent();
      await ContentLearningService.refresh();
      _lifetime.assertCurrent();
      if (mounted) {
        widget.onRetry();
      }
    } catch (_) {
      // Preserve the failure surface; do not reset or overwrite unreadable data.
    } finally {
      if (mounted) {
        setState(() => _retrying = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(liveRegion: true, child: Text(t.contentLearningError)),
        const SizedBox(height: Spacing.sm),
        SoriButton.outlined(
          label: t.contentLearningRetry,
          onTap: _retrying ? null : _retry,
        ),
      ],
    );
  }
}

/// Shared per-level editor. A failed write keeps the choices visible for retry.
class ContentGoalEditor extends StatefulWidget {
  const ContentGoalEditor({
    super.key,
    required this.kind,
    required this.level,
    this.onSaved,
    this.fillViewport = false,
  });
  final LearningContentKind kind;
  final String level;
  final VoidCallback? onSaved;
  final bool fillViewport;
  @override
  State<ContentGoalEditor> createState() => _ContentGoalEditorState();
}

class _ContentGoalEditorState extends State<ContentGoalEditor> {
  final _lifetime = LocalDataLifetime.capture();
  bool _saving = false;
  int? _failed;
  Future<void> _save(int value) async {
    if (_saving) {
      return;
    }
    setState(() {
      _saving = true;
      _failed = null;
    });
    try {
      _lifetime.assertCurrent();
      await ContentLearningService.setGoal(widget.kind, widget.level, value);
      if (mounted) {
        widget.onSaved?.call();
      }
    } catch (_) {
      if (mounted) {
        setState(() => _failed = value);
      }
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);
    int? goal;
    try {
      goal = ContentLearningService.goal(widget.kind, widget.level);
    } catch (_) {
      return ContentLearningFailure(
        onRetry: () {
          if (_failed case final value?) {
            _save(value);
          } else {
            setState(() {});
          }
        },
      );
    }
    final body = <Widget>[
      Text(
        t.contentLearningGoal(widget.level.toUpperCase()),
        style: widget.fillViewport
            ? SoriTextTheme.of(context).h2
            : SoriTextTheme.of(context).h3,
      ),
      const SizedBox(height: Spacing.sm),
      Text(t.contentLearningGoalIntro, style: SoriTextTheme.of(context).body),
    ];
    final actions = <Widget>[
      for (final value in [1, 2, 3, 0])
        Padding(
          padding: const EdgeInsets.only(bottom: Spacing.xs),
          child: SoriButton.outlined(
            key: ValueKey('content-goal-$value'),
            label: value == 0
                ? t.contentLearningFree
                : t.contentLearningGoalCount(value),
            icon: goal == value ? Icons.check_circle_outline : null,
            onTap: _saving ? null : () => _save(value),
            fullWidth: true,
          ),
        ),
      if (_saving) const LinearProgressIndicator(),
      if (_failed != null)
        ContentLearningFailure(onRetry: () => _save(_failed!)),
    ];
    if (widget.fillViewport) {
      return ContentLearningLayout(body: body, actions: actions);
    }
    return SoriCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ...body,
          const SizedBox(height: Spacing.md),
          ...actions,
        ],
      ),
    );
  }
}

class ContentGoalSettingsScreen extends StatefulWidget {
  const ContentGoalSettingsScreen({super.key});
  @override
  State<ContentGoalSettingsScreen> createState() =>
      _ContentGoalSettingsScreenState();
}

class _ContentGoalSettingsScreenState extends State<ContentGoalSettingsScreen> {
  LearningContentKind _kind = LearningContentKind.smalltalk;
  String _level = 'a1';
  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);
    return SoriStudyFrame(
      title: t.contentLearningGoals,
      child: Column(
        children: [
          DropdownButtonFormField<LearningContentKind>(
            initialValue: _kind,
            isExpanded: true,
            items: [
              for (final kind in LearningContentKind.values)
                DropdownMenuItem(
                  value: kind,
                  child: Text(contentKindTitle(t, kind)),
                ),
            ],
            onChanged: (value) {
              if (value != null) {
                setState(() => _kind = value);
              }
            },
          ),
          const SizedBox(height: Spacing.md),
          DropdownButtonFormField<String>(
            initialValue: _level,
            items: [
              for (final level in ['a1', 'a2', 'b1', 'b2', 'c1', 'c2'])
                DropdownMenuItem(
                  value: level,
                  child: Text(level.toUpperCase()),
                ),
            ],
            onChanged: (value) {
              if (value != null) {
                setState(() => _level = value);
              }
            },
          ),
          const SizedBox(height: Spacing.lg),
          Expanded(
            child: ContentGoalEditor(
              key: ValueKey('$_kind-$_level'),
              kind: _kind,
              level: _level,
              fillViewport: true,
            ),
          ),
        ],
      ),
    );
  }
}

/// Only explicitly configured positive targets appear. Reading never starts a day.
class ContentDailyGoals extends StatefulWidget {
  const ContentDailyGoals({super.key});
  @override
  State<ContentDailyGoals> createState() => _ContentDailyGoalsState();
}

class _ContentDailyGoalsState extends State<ContentDailyGoals>
    with ContentLearningDayRefresh<ContentDailyGoals> {
  @override
  Widget build(BuildContext context) => ValueListenableBuilder<int>(
    valueListenable: ContentLearningService.changes,
    builder: (context, _, _) {
      List<ContentDailyProgress> goals;
      try {
        goals = ContentLearningService.activeDaily();
      } catch (_) {
        return ContentLearningFailure(onRetry: () => setState(() {}));
      }
      if (goals.isEmpty) {
        return const SizedBox.shrink();
      }
      final t = AppL10n.of(context);
      return Padding(
        padding: const EdgeInsets.only(top: Spacing.lg),
        child: SoriCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(t.contentLearningGoals, style: SoriTextTheme.of(context).h3),
              for (final goal in goals)
                Material(
                  type: MaterialType.transparency,
                  child: ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      '${contentKindTitle(t, goal.kind)} · ${goal.level.toUpperCase()}',
                    ),
                    subtitle: Text(
                      [
                        t.contentLearningToday(
                          goal.completedCount,
                          goal.target,
                        ),
                        if (goal.isComplete) t.contentLearningTodayDone,
                      ].join('\n'),
                    ),
                    trailing: Icon(
                      goal.isComplete
                          ? Icons.check_circle_outline
                          : Icons.chevron_right,
                    ),
                    onTap: () => Navigator.of(context).pushNamed(
                      goal.kind == LearningContentKind.smalltalk
                          ? '/smalltalk'
                          : '/listening',
                      arguments: goal.level,
                    ),
                  ),
                ),
            ],
          ),
        ),
      );
    },
  );
}
