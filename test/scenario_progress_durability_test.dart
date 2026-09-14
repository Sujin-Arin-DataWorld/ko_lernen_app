import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:ko_lernen_app/services/storage_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_platform_interface.dart';

import 'support/reward_preferences_platform.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final originalPlatform = SharedPreferencesStorePlatform.instance;
  late RewardPreferencesPlatform platform;

  setUp(() async {
    Storage.resetForTesting();
    SharedPreferences.setMockInitialValues({});
    platform = RewardPreferencesPlatform();
    SharedPreferencesStorePlatform.instance = platform;
    await Storage.init();
  });

  tearDown(() {
    Storage.resetForTesting();
    SharedPreferences.setMockInitialValues({});
    SharedPreferencesStorePlatform.instance = originalPlatform;
  });

  test('rejected stars are neither successful nor cached as durable', () async {
    platform.rejectKey = 'kl_scenario_stars';
    await expectLater(
      Storage.setScenarioStars('scene', 3),
      throwsA(isA<PreferenceWriteException>()),
    );
    expect(Storage.scenarioStars, isNot(contains('scene')));
    platform.rejectKey = null;
    await Storage.setScenarioStars('scene', 3);
    expect(Storage.scenarioStars['scene'], 3);
    expect(platform.values['kl_scenario_stars'], contains('scene'));
  });

  test('rejected completion remains retryable', () async {
    platform.rejectKey = 'kl_completed_scenarios';
    await expectLater(
      Storage.addCompletedScenario('scene'),
      throwsA(isA<PreferenceWriteException>()),
    );
    expect(Storage.completedScenarios, isNot(contains('scene')));
    platform.rejectKey = null;
    await Storage.addCompletedScenario('scene');
    expect(platform.values['kl_completed_scenarios'], contains('scene'));
  });

  test('rejected badge remains retryable', () async {
    platform.rejectKey = 'kl_earned_badges';
    await expectLater(
      Storage.earnBadge('cafe_starter'),
      throwsA(isA<PreferenceWriteException>()),
    );
    expect(Storage.earnedBadges, isNot(contains('cafe_starter')));
    platform.rejectKey = null;
    await Storage.earnBadge('cafe_starter');
    expect(platform.values['kl_earned_badges'], contains('cafe_starter'));
  });

  for (final key in [
    'kl_scenario_stars',
    'kl_completed_scenarios',
    'kl_earned_badges',
  ]) {
    Future<void> write(String id) => switch (key) {
      'kl_scenario_stars' => Storage.setScenarioStars(id, 3),
      'kl_completed_scenarios' => Storage.addCompletedScenario(id),
      _ => Storage.earnBadge(id),
    };
    Iterable<String> visible() => switch (key) {
      'kl_scenario_stars' => Storage.scenarioStars.keys,
      'kl_completed_scenarios' => Storage.completedScenarios,
      _ => Storage.earnedBadges,
    };

    test('concurrent $key updates preserve both entries', () async {
      await Future.wait([write('first'), write('second')]);
      expect(visible(), containsAll(['first', 'second']));
    });

    test('pending $key is hidden even when its reply is rejected', () async {
      await write('before');
      final entered = Completer<void>();
      final release = Completer<void>();
      platform
        ..rejectKey = key
        ..writeEntered = entered
        ..releaseWrite = release;
      final rejected = expectLater(
        write('after'),
        throwsA(isA<PreferenceWriteException>()),
      );
      await entered.future;
      final pendingVisible = visible().toList();
      release.complete();
      await rejected;
      expect(pendingVisible, isNot(contains('after')));
      expect(visible(), contains('before'));
      expect(visible(), isNot(contains('after')));
    });

    for (final committed in [false, true]) {
      test(
        'unknown $key stays hidden and recovers; committed=$committed',
        () async {
          await write('before');
          platform
            ..rejectKey = key
            ..throwReply = true
            ..commitBeforeFailure = committed
            ..failReloadAfterWrite = true;
          await expectLater(
            write('after'),
            throwsA(isA<PreferenceOutcomeUnknownException>()),
          );
          expect(visible(), contains('before'));
          expect(visible(), isNot(contains('after')));
          await expectLater(
            write('after'),
            throwsA(isA<PreferenceOutcomeUnknownException>()),
          );
          expect(platform.writes[key], 2);
          platform
            ..unavailable = false
            ..rejectKey = null;
          await write('after');
          expect(visible(), containsAll(['before', 'after']));
          expect(platform.writes[key], committed ? 2 : 3);
        },
      );
    }
  }
}
