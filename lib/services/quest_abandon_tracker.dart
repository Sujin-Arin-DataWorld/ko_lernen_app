import 'analytics_service.dart';

/// Fires `quest_abandon` when a lesson/quiz/game screen is left before it
/// produced its own completion event. This is the mid-session drop-off
/// signal `Analytics.questAbandoned` exists for — distinct from
/// `Analytics.questFailed`, which needs a real pass/fail outcome to fire.
///
/// Usage: create one in the screen's `initState`, call [markCompleted] right
/// beside the screen's existing `Analytics.lessonCompleted`/`gameCompleted`/
/// `quizCompleted` call (on every exit path, including early-exit/skip), and
/// call [dispose] from the screen's own `dispose()`.
typedef QuestAbandonReporter =
    Future<void> Function({
      required String questType,
      String? questId,
      required String lastStepReached,
    });

class QuestAbandonTracker {
  QuestAbandonTracker({
    required this.questType,
    this.questId,
    required this.lastStepReached,
    QuestAbandonReporter? onAbandon,
  }) : _onAbandon = onAbandon ?? Analytics.questAbandoned;

  final String questType;
  final String? questId;

  /// Cheap, current-state getter for a bounded step marker (question index,
  /// stage name, …) — never free text. Only read if the screen is abandoned.
  final String Function() lastStepReached;

  /// Defaults to [Analytics.questAbandoned]; injectable so tests can assert
  /// on calls without a live Firebase/consent stack.
  final QuestAbandonReporter _onAbandon;

  bool _completed = false;

  void markCompleted() {
    _completed = true;
  }

  void dispose() {
    if (_completed) {
      return;
    }
    _onAbandon(
      questType: questType,
      questId: questId,
      lastStepReached: lastStepReached(),
    );
  }
}
