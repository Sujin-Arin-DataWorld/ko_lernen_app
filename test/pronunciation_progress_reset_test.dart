import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:ko_lernen_app/services/account/cloud_write_session.dart';
import 'package:ko_lernen_app/services/local_data_lifetime.dart';
import 'package:ko_lernen_app/services/storage_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_platform_interface.dart';

import 'support/reward_preferences_platform.dart';

const _progressKey = 'kl_pronunciation_progress_v2';

class _HeldRemovalPlatform extends RewardPreferencesPlatform {
  final removalEntered = Completer<void>();
  final releaseRemoval = Completer<void>();

  @override
  Future<bool> remove(String key) async {
    if (key == 'flutter.kl_tut_scenario') {
      removalEntered.complete();
      await releaseRemoval.future;
    }
    return super.remove(key);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final original = SharedPreferencesStorePlatform.instance;
  late RewardPreferencesPlatform native;

  setUp(() async {
    Storage.resetForTesting();
    SharedPreferences.setMockInitialValues({});
    native = RewardPreferencesPlatform();
    SharedPreferencesStorePlatform.instance = native;
    await Storage.init();
  });

  tearDown(() {
    cloudWriteSessionController.clear();
    Storage.resetForTesting();
    SharedPreferences.setMockInitialValues({});
    SharedPreferencesStorePlatform.instance = original;
  });

  void holdSuccessfulWrite(Completer<void> entered, Completer<void> release) {
    native
      ..rejectKey = _progressKey
      ..writeEntered = entered
      ..releaseWrite = release
      ..commitBeforeFailure = true
      ..successfulReply = true;
  }

  for (final strict in [false, true]) {
    test(
      'reset strict=$strict drains a real delayed pronunciation commit',
      () async {
        final entered = Completer<void>();
        final release = Completer<void>();
        holdSuccessfulWrite(entered, release);
        final saving = Storage.recordPronunciationPass(
          'assessment-old',
          91,
        ).then<Object>((value) => value, onError: (Object error) => error);
        await entered.future;
        expect(native.values[_progressKey], isNull);
        var resetFinished = false;
        final reset = (strict ? Storage.resetAllStrict() : Storage.resetAll())
            .then((_) => resetFinished = true);
        await Future<void>.delayed(Duration.zero);
        final finishedBeforeWrite = resetFinished;
        release.complete();
        await saving;
        await reset;
        await (await SharedPreferences.getInstance()).reload();
        expect(finishedBeforeWrite, isFalse);
        expect(native.writes[_progressKey], 1);
        expect(native.values[_progressKey], isNull);
        expect(Storage.pronunciationPassCount, 0);
      },
    );

    test(
      'reset strict=$strict rejects new pronunciation admission during deletion',
      () async {
        final held = _HeldRemovalPlatform();
        native = held;
        Storage.resetForTesting();
        SharedPreferences.setMockInitialValues({});
        SharedPreferencesStorePlatform.instance = native;
        await Storage.init();
        final reset = strict ? Storage.resetAllStrict() : Storage.resetAll();
        await held.removalEntered.future;
        final outcome = await Storage.recordPronunciationPass(
          'assessment-new',
          91,
        ).then<Object>((value) => value, onError: (Object error) => error);
        held.releaseRemoval.complete();
        await reset;
        expect(outcome, isA<StaleLocalDataLifetimeException>());
        expect(native.writes[_progressKey], isNull);
        expect(native.values[_progressKey], isNull);
      },
    );
  }

  test('queued pronunciation pass cannot enter a changed identity', () async {
    cloudWriteSessionController.acquire('pronunciation-owner-a');
    final entered = Completer<void>();
    final release = Completer<void>();
    holdSuccessfulWrite(entered, release);
    final first = Storage.recordPronunciationPass('assessment-first', 91);
    await entered.future;
    final queued = Storage.recordPronunciationPass(
      'assessment-queued',
      92,
    ).then<Object>((value) => value, onError: (Object error) => error);
    cloudWriteSessionController.acquire('pronunciation-owner-b');
    release.complete();
    await first.then<Object>(
      (value) => value,
      onError: (Object error) => error,
    );
    final outcome = await queued;
    expect(outcome, isA<StaleLocalDataLifetimeException>());
    expect(native.writes[_progressKey], 1);
    expect(
      jsonDecode(native.values[_progressKey]! as String).toString(),
      isNot(contains('assessment-queued')),
    );
  });

  test(
    'synchronous test reset waits for pronunciation native work before init',
    () async {
      final entered = Completer<void>();
      final release = Completer<void>();
      holdSuccessfulWrite(entered, release);
      final saving = Storage.recordPronunciationPass(
        'assessment-retired',
        91,
      ).then<Object>((value) => value, onError: (Object error) => error);
      await entered.future;
      Storage.resetForTesting();
      SharedPreferences.setMockInitialValues({});
      var initialized = false;
      final init = Storage.init().then((_) => initialized = true);
      await Future<void>.delayed(Duration.zero);
      final initializedBeforeWrite = initialized;
      final newAdmission = await Storage.recordPronunciationPass(
        'assessment-new',
        91,
      ).then<Object>((value) => value, onError: (Object error) => error);
      release.complete();
      final outcome = await saving;
      await init;
      expect(initializedBeforeWrite, isFalse);
      expect(newAdmission, isA<StaleLocalDataLifetimeException>());
      expect(outcome, isA<StaleLocalDataLifetimeException>());
      expect(Storage.pronunciationPassCount, 0);
    },
  );
}
