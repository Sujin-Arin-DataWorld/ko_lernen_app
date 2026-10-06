import 'dart:convert';

/// A small, optional practice path. Its completion never grants CEFR mastery,
/// course completion, XP, money or an assessment result.
enum FoundationStep {
  sounds('sounds'),
  syllables('syllables'),
  tracing('tracing'),
  firstWords('first_words');

  const FoundationStep(this.id);
  final String id;

  List<FoundationTask> get tasks => List.unmodifiable(
    FoundationTask.values.where((task) => task.step == this),
  );
}

/// Stable identities describe the actual starter exercise, not an arbitrary
/// number of interactions or a tutorial dismissal.
enum FoundationTask {
  soundG('sound_g', FoundationStep.sounds),
  soundN('sound_n', FoundationStep.sounds),
  soundA('sound_a', FoundationStep.sounds),
  soundI('sound_i', FoundationStep.sounds),
  readGa('read_ga', FoundationStep.syllables),
  readNa('read_na', FoundationStep.syllables),
  readHan('read_han', FoundationStep.syllables),
  traceG('trace_g', FoundationStep.tracing),
  traceA('trace_a', FoundationStep.tracing),
  wordBag('word_bag', FoundationStep.firstWords),
  wordTree('word_tree', FoundationStep.firstWords),
  greetingHello('greeting_hello', FoundationStep.firstWords);

  const FoundationTask(this.id, this.step);
  final String id;
  final FoundationStep step;
}

final class FoundationProgress {
  FoundationProgress({
    Iterable<FoundationStep> openedSteps = const [],
    Iterable<FoundationTask> practicedTasks = const [],
    this.currentStep,
    this.cursorUpdatedAt = 0,
    this.continuedToA1 = false,
  }) : openedSteps = Set.unmodifiable(openedSteps),
       practicedTasks = Set.unmodifiable(practicedTasks) {
    if (this.practicedTasks.any(
      (task) => !this.openedSteps.contains(task.step),
    )) {
      throw const FormatException('Foundation practice has no opened step.');
    }
    if (cursorUpdatedAt < 0 ||
        (currentStep == null && cursorUpdatedAt != 0) ||
        (currentStep != null && !this.openedSteps.contains(currentStep))) {
      throw const FormatException('Invalid foundation cursor.');
    }
  }

  static const schemaVersion = 1;
  static const maxBytes = 16384;
  final Set<FoundationStep> openedSteps;
  final Set<FoundationTask> practicedTasks;
  final FoundationStep? currentStep;
  final int cursorUpdatedAt;
  final bool continuedToA1;

  bool get isComplete => practicedTasks.length == FoundationTask.values.length;
  int get practicedCount => practicedTasks.length;
  int get totalTasks => FoundationTask.values.length;
  bool hasOpened(FoundationStep step) => openedSteps.contains(step);
  bool hasPracticed(FoundationTask task) => practicedTasks.contains(task);
  int practicedIn(FoundationStep step) =>
      step.tasks.where(practicedTasks.contains).length;
  bool isStepPracticed(FoundationStep step) =>
      step.tasks.every(practicedTasks.contains);

  FoundationStep? get nextStep {
    for (final step in FoundationStep.values) {
      if (!isStepPracticed(step)) {
        return step;
      }
    }
    return null;
  }

  FoundationProgress withOpened(
    FoundationStep step, {
    required int cursorUpdatedAt,
  }) => FoundationProgress(
    openedSteps: {...openedSteps, step},
    practicedTasks: practicedTasks,
    currentStep: step,
    cursorUpdatedAt: cursorUpdatedAt,
    continuedToA1: continuedToA1,
  );

  FoundationProgress withPractice(FoundationTask task) {
    if (!hasOpened(task.step)) {
      throw StateError('Open a foundation step before recording practice.');
    }
    return FoundationProgress(
      openedSteps: openedSteps,
      practicedTasks: {...practicedTasks, task},
      currentStep: currentStep,
      cursorUpdatedAt: cursorUpdatedAt,
      continuedToA1: continuedToA1,
    );
  }

  FoundationProgress withContinueA1() => FoundationProgress(
    openedSteps: openedSteps,
    practicedTasks: practicedTasks,
    currentStep: currentStep,
    cursorUpdatedAt: cursorUpdatedAt,
    continuedToA1: true,
  );

  /// Same-account cloud restore preserves every locally confirmed exercise.
  /// Both inputs must have been decoded successfully before they are merged.
  FoundationProgress merge(FoundationProgress other) {
    // Equal timestamps choose a stable step, so merge order/device cannot
    // change the displayed cursor. A cursor never manufactures task evidence.
    final chooseOther =
        other.cursorUpdatedAt > cursorUpdatedAt ||
        (other.cursorUpdatedAt == cursorUpdatedAt &&
            (other.currentStep?.index ?? -1) > (currentStep?.index ?? -1));
    final cursor = chooseOther ? other : this;
    return FoundationProgress(
      openedSteps: {...openedSteps, ...other.openedSteps},
      practicedTasks: {...practicedTasks, ...other.practicedTasks},
      currentStep: cursor.currentStep,
      cursorUpdatedAt: cursor.cursorUpdatedAt,
      continuedToA1: continuedToA1 || other.continuedToA1,
    );
  }

  Map<String, Object?> toJson() => {
    'version': schemaVersion,
    'openedSteps': [
      for (final step in FoundationStep.values)
        if (openedSteps.contains(step)) step.id,
    ],
    'practicedTasks': [
      for (final task in FoundationTask.values)
        if (practicedTasks.contains(task)) task.id,
    ],
    'currentStep': currentStep?.id,
    'cursorUpdatedAt': cursorUpdatedAt,
    'continuedToA1': continuedToA1,
  };

  String encode() => jsonEncode(toJson());

  factory FoundationProgress.decode(String raw) {
    if (raw.isEmpty) {
      return FoundationProgress();
    }
    if (utf8.encode(raw).length > maxBytes) {
      throw const FormatException('Foundation progress is too large.');
    }
    final data = jsonDecode(raw);
    const legacyKeys = {'version', 'openedSteps', 'practicedTasks'};
    const currentKeys = {
      ...legacyKeys,
      'currentStep',
      'cursorUpdatedAt',
      'continuedToA1',
    };
    if (data is! Map<String, dynamic> ||
        !((data.length == 3 && legacyKeys.containsAll(data.keys)) ||
            (data.length == 6 && currentKeys.containsAll(data.keys))) ||
        data['version'] != schemaVersion) {
      throw const FormatException('Unsupported foundation progress.');
    }

    Set<T> ids<T>(String key, List<T> values, String Function(T) id) {
      final rawIds = data[key];
      if (rawIds is! List ||
          rawIds.length > values.length ||
          rawIds.any((value) => value is! String) ||
          rawIds.toSet().length != rawIds.length) {
        throw const FormatException('Invalid foundation progress identities.');
      }
      final lookup = {for (final value in values) id(value): value};
      if (rawIds.any((value) => !lookup.containsKey(value))) {
        throw const FormatException('Unknown foundation exercise.');
      }
      return {for (final value in rawIds) lookup[value]!};
    }

    final hasCursor = data.length == 6;
    final rawCursor = data['currentStep'];
    FoundationStep? cursor;
    if (rawCursor != null) {
      for (final step in FoundationStep.values) {
        if (step.id == rawCursor) {
          cursor = step;
          break;
        }
      }
      if (cursor == null) {
        throw const FormatException('Unknown foundation cursor.');
      }
    }
    if (hasCursor &&
        (data['cursorUpdatedAt'] is! int || data['continuedToA1'] is! bool)) {
      throw const FormatException('Invalid foundation continuation.');
    }
    return FoundationProgress(
      openedSteps: ids('openedSteps', FoundationStep.values, (step) => step.id),
      practicedTasks: ids(
        'practicedTasks',
        FoundationTask.values,
        (task) => task.id,
      ),
      currentStep: cursor,
      cursorUpdatedAt: hasCursor ? data['cursorUpdatedAt'] as int : 0,
      continuedToA1: hasCursor ? data['continuedToA1'] as bool : false,
    );
  }
}
