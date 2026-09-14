import 'dart:async';
import 'package:flutter/widgets.dart';
import '../models/sori_stage_progression.dart';

/// Ephemeral evidence, captured by existing activity finish transactions only.
/// It never writes learning progress or grants rewards.
class LearningAttempt {
  LearningAttempt._(this.journey, this.id);
  final LearningJourney journey;
  final int id;
  bool completed = false;
  bool saveFailed = false;
  bool? passed;
  final Map<String, int> _shown = {};

  void complete({bool? passed}) {
    completed = true;
    saveFailed = false;
    this.passed = passed;
  }

  void failed() => saveFailed = true;

  /// Call from the native result's visible frame, after persistence succeeds.
  void shown(SoriRewardKind kind, int amount, {String? identity}) {
    if (!completed || saveFailed || amount <= 0) {
      return;
    }
    final key = '${kind.name}:${identity ?? ''}';
    final previous = _shown[key] ?? 0;
    if (amount > previous) {
      _shown[key] = amount;
    }
  }
}

class LearningJourneyResult {
  const LearningJourneyResult({
    required this.completedAttempts,
    required this.failedSaves,
    required this.cancelled,
  });
  final int completedAttempts;
  final int failedSaves;
  final bool cancelled;
  bool get completed => completedAttempts > 0;
  bool get abandoned =>
      !cancelled && completedAttempts == 0 && failedSaves == 0;
}

class LearningJourney {
  LearningJourney._(this.origin);
  final Route<dynamic> origin;
  final List<LearningAttempt> attempts = [];
  final Map<String, Future<void> Function(BuildContext)> afterReturn = {};
  final Set<Future<void>> _pending = {};
  final Completer<void> _returned = Completer<void>();
  bool cancelled = false;
  bool departed = false;
  Future<void> get returned => _returned.future;
  bool get hadCompletedAttempt => attempts.any((a) => a.completed);
  bool get hadSaveFailure => attempts.any((a) => a.saveFailed);
  bool get abandoned => !hadCompletedAttempt && !hadSaveFailure;
  LearningJourneyResult get result => LearningJourneyResult(
    completedAttempts: attempts.where((a) => a.completed).length,
    failedSaves: attempts.where((a) => a.saveFailed).length,
    cancelled: cancelled,
  );

  LearningAttempt beginAttempt() {
    final attempt = LearningAttempt._(this, attempts.length);
    attempts.add(attempt);
    return attempt;
  }

  Future<T> track<T>(Future<T> work, LearningAttempt attempt) {
    final settled = work.then<void>(
      (_) {},
      onError: (Object _, StackTrace __) {
        attempt.failed();
      },
    );
    _pending.add(settled);
    unawaited(settled.whenComplete(() => _pending.remove(settled)));
    return work;
  }

  Future<void> settle() async {
    while (_pending.isNotEmpty) {
      await Future.wait(_pending.toList());
    }
  }

  RewardReceipt unshown(RewardReceipt receipt) {
    final amounts = <String, int>{};
    final unique = <String>{};
    for (final attempt in attempts) {
      for (final entry in attempt._shown.entries) {
        final kind = entry.key.split(':').first;
        if (kind != SoriRewardKind.xp.name && !unique.add(entry.key)) {
          continue;
        }
        amounts[entry.key] = (amounts[entry.key] ?? 0) + entry.value;
      }
    }
    final items = <RewardReceiptItem>[];
    for (final item in receipt.items) {
      final key = '${item.kind.name}:${item.identity ?? ''}';
      final remaining = (item.amount ?? 0) - (amounts[key] ?? 0);
      if (remaining > 0) {
        items.add(
          RewardReceiptItem(
            kind: item.kind,
            label: item.label,
            identity: item.identity,
            amount: remaining,
          ),
        );
      }
    }
    return RewardReceipt(
      activityId: receipt.activityId,
      receiptId: receipt.receiptId,
      items: items,
      sarangchaeStageBefore: receipt.sarangchaeStageBefore,
      sarangchaeStageAfter: receipt.sarangchaeStageAfter,
      b2ConstructionStageBefore: receipt.b2ConstructionStageBefore,
      b2ConstructionStageAfter: receipt.b2ConstructionStageAfter,
    );
  }
}

/// Root Navigator observer, separate from media RouteAware observers.
class LearningJourneyObserver extends NavigatorObserver {
  static final shared = LearningJourneyObserver();
  static final Map<NavigatorState, LearningJourneyObserver> _owners = {};
  final List<Route<dynamic>> _stack = [];
  LearningJourney? active;
  static LearningAttempt? beginAttempt() => shared.active?.beginAttempt();

  static LearningJourneyObserver? forContext(BuildContext context) =>
      _owners[Navigator.of(context, rootNavigator: true)];

  LearningJourney? begin(Route<dynamic> origin) {
    if (active != null || !_stack.contains(origin)) {
      return null;
    }
    return active = LearningJourney._(origin);
  }

  bool returnHome(BuildContext context) {
    final journey = active;
    if (journey == null ||
        !_stack.contains(journey.origin) ||
        ModalRoute.of(context) == journey.origin) {
      return false;
    }
    navigator!.popUntil((route) => identical(route, journey.origin));
    return true;
  }

  void cancel() {
    final journey = active;
    if (journey == null) {
      return;
    }
    journey.cancelled = true;
    active = null;
    if (!journey._returned.isCompleted) {
      journey._returned.complete();
    }
  }

  void _changed() {
    if (navigator case final nav?) {
      _owners[nav] = this;
    }
    final journey = active;
    if (journey == null) {
      return;
    }
    if (!_stack.contains(journey.origin)) {
      cancel();
      return;
    }
    if (_stack.last != journey.origin) {
      journey.departed = true;
    }
    scheduleMicrotask(() {
      if (!identical(active, journey)) {
        return;
      }
      if (journey.departed &&
          _stack.isNotEmpty &&
          identical(_stack.last, journey.origin)) {
        active = null;
        journey._returned.complete();
      }
    });
  }

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _stack.add(route);
    _changed();
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _stack.remove(route);
    _changed();
  }

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _stack.remove(route);
    _changed();
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    final index = oldRoute == null ? -1 : _stack.indexOf(oldRoute);
    if (index >= 0) {
      if (newRoute == null) {
        _stack.removeAt(index);
      } else {
        _stack[index] = newRoute;
      }
    }
    _changed();
  }
}

/// Wraps an existing terminal persistence operation without adding any writes.
Future<T> trackLearningPersistence<T>(
  LearningAttempt? attempt,
  Future<T> work, {
  bool? passed,
}) async {
  final result = await (attempt == null
      ? work
      : attempt.journey.track(work, attempt));
  attempt?.complete(passed: passed);
  return result;
}
