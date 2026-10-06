import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:ko_lernen_app/models/foundation_progress.dart';

void main() {
  test('opening and choosing A1 never manufactures practice', () {
    final progress = FoundationProgress()
        .withOpened(FoundationStep.tracing, cursorUpdatedAt: 10)
        .withContinueA1();
    expect(progress.currentStep, FoundationStep.tracing);
    expect(progress.continuedToA1, isTrue);
    expect(progress.hasOpened(FoundationStep.tracing), isTrue);
    expect(progress.practicedCount, 0);
    expect(progress.isComplete, isFalse);
    expect(progress.nextStep, FoundationStep.sounds);
  });

  test('round trip preserves actual tasks, last opened step and A1 choice', () {
    final before = FoundationProgress()
        .withOpened(FoundationStep.sounds, cursorUpdatedAt: 10)
        .withPractice(FoundationTask.soundG)
        .withOpened(FoundationStep.tracing, cursorUpdatedAt: 20)
        .withContinueA1();
    final restored = FoundationProgress.decode(before.encode());
    expect(restored.encode(), before.encode());
    expect(restored.currentStep, FoundationStep.tracing);
    expect(restored.practicedTasks, {FoundationTask.soundG});
    expect(restored.continuedToA1, isTrue);
    expect(restored.isComplete, isFalse);
  });

  test('cloud merge is monotonic, deterministic and idempotent', () {
    final local = FoundationProgress()
        .withOpened(FoundationStep.sounds, cursorUpdatedAt: 10)
        .withPractice(FoundationTask.soundG)
        .withContinueA1();
    final cloud = FoundationProgress()
        .withOpened(FoundationStep.firstWords, cursorUpdatedAt: 20)
        .withPractice(FoundationTask.wordBag);
    final merged = local.merge(cloud);
    expect(merged.practicedTasks, {
      FoundationTask.soundG,
      FoundationTask.wordBag,
    });
    expect(merged.currentStep, FoundationStep.firstWords);
    expect(merged.continuedToA1, isTrue);
    expect(cloud.merge(local).encode(), merged.encode());
    expect(merged.merge(merged).encode(), merged.encode());
    expect(merged.isComplete, isFalse);
  });

  test(
    'equal cloud cursor times have a stable merge-order-independent tie',
    () {
      final a = FoundationProgress().withOpened(
        FoundationStep.sounds,
        cursorUpdatedAt: 10,
      );
      final b = FoundationProgress().withOpened(
        FoundationStep.tracing,
        cursorUpdatedAt: 10,
      );
      expect(a.merge(b).encode(), b.merge(a).encode());
      expect(a.merge(b).currentStep, FoundationStep.tracing);
    },
  );

  test(
    'legacy v1 practice remains intact when new cursor fields are absent',
    () {
      final legacy = FoundationProgress.decode(
        jsonEncode({
          'version': 1,
          'openedSteps': ['sounds'],
          'practicedTasks': ['sound_g'],
        }),
      );
      expect(legacy.practicedTasks, {FoundationTask.soundG});
      expect(legacy.currentStep, isNull);
      expect(legacy.continuedToA1, isFalse);
      final opened = legacy.withOpened(
        FoundationStep.syllables,
        cursorUpdatedAt: 20,
      );
      expect(opened.hasPracticed(FoundationTask.soundG), isTrue);
    },
  );

  test('only all twelve concrete tasks complete the foundation path', () {
    final progress = FoundationProgress(
      openedSteps: FoundationStep.values,
      practicedTasks: FoundationTask.values,
      currentStep: FoundationStep.firstWords,
      cursorUpdatedAt: 20,
    );
    expect(progress.isComplete, isTrue);
    expect(progress.nextStep, isNull);
    expect(progress.continuedToA1, isFalse);
    expect(progress.practicedCount, 12);
  });

  test('no practice can be recorded before its step was opened', () {
    expect(
      () => FoundationProgress().withPractice(FoundationTask.readGa),
      throwsStateError,
    );
  });

  test('native corruption and unsupported schemas stay explicit', () {
    final valid = FoundationProgress().toJson();
    for (final value in [
      [],
      {...valid, 'version': 2},
      {
        ...valid,
        'practicedTasks': ['sound_g'],
      },
      {
        ...valid,
        'openedSteps': ['sounds', 'sounds'],
      },
      {
        ...valid,
        'openedSteps': ['unknown'],
      },
      {...valid, 'continuedToA1': 'true'},
      {...valid, 'currentStep': 'sounds'},
      {...valid, 'currentStep': 'unknown'},
      {...valid, 'cursorUpdatedAt': -1},
      {...valid, 'extra': true},
    ]) {
      expect(
        () => FoundationProgress.decode(jsonEncode(value)),
        throwsFormatException,
      );
    }
    expect(() => FoundationProgress.decode('{broken'), throwsFormatException);
    expect(
      () => FoundationProgress.decode(' ' * (FoundationProgress.maxBytes + 1)),
      throwsFormatException,
    );
  });

  test('progress snapshots do not expose mutable sets', () {
    final progress = FoundationProgress();
    expect(
      () => progress.openedSteps.add(FoundationStep.sounds),
      throwsUnsupportedError,
    );
    expect(
      () => progress.practicedTasks.add(FoundationTask.soundG),
      throwsUnsupportedError,
    );
  });
}
