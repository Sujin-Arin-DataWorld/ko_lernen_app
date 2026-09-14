import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_platform_interface.dart';
import 'package:ko_lernen_app/services/storage_service.dart';
import 'package:ko_lernen_app/services/privacy_consent_service.dart';
import 'package:ko_lernen_app/services/age_gate_service.dart';
import 'package:ko_lernen_app/services/analytics_service.dart';
import 'support/privacy_preferences_platform.dart';
import 'package:ko_lernen_app/services/diagnostics_service.dart';
import 'package:ko_lernen_app/services/cloud_sync.dart';
import 'package:ko_lernen_app/services/push_service.dart';
import 'package:ko_lernen_app/services/account/cloud_write_session.dart';
import 'package:ko_lernen_app/services/custom_pack_service.dart';
import 'package:ko_lernen_app/models/book_page.dart';

class _Push implements PushTokenOwner {
  @override
  Future<void> bindCurrentUser() async {}
  @override
  Future<void> removeTokenFrom(String uid) async {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late PrivacyPreferencesPlatform native;
  late PrivacyFakeAnalytics analytics;
  late PrivacyFakeCrash crash;
  late PrivacyConsentController controller;
  setUp(() async {
    Storage.resetForTesting();
    SharedPreferences.setMockInitialValues({});
    native = PrivacyPreferencesPlatform();
    native.values['kl_birth_year'] = DateTime.now().year - 25;
    SharedPreferencesStorePlatform.instance = native;
    await Storage.init();
    analytics = PrivacyFakeAnalytics();
    crash = PrivacyFakeCrash();
    PrivacyConsentService.configureForTesting(
      analytics: analytics,
      crash: crash,
    );
    Analytics.configureForTesting(client: analytics);
    DiagnosticsService.configureForTesting(sink: crash);
    controller = PrivacyConsentController(
      analyticsConsent: () => Storage.analyticsConsent,
      crashConsent: () => Storage.crashConsent,
      persistAnalyticsConsent: Storage.setAnalyticsConsent,
      persistCrashConsent: Storage.setCrashConsent,
      analyticsClient: analytics,
      crashClient: crash,
      presentFlutterError: (_) {},
    );
  });
  tearDown(() {
    if (native.release case final release? when !release.isCompleted) {
      release.complete();
    }
    if (native.releaseRead case final release? when !release.isCompleted) {
      release.complete();
    }
    if (analytics.enable case final enable? when !enable.isCompleted) {
      enable.complete();
    }
  });

  for (final operation in [
    'refresh',
    'bool reconciliation',
    'int reconciliation',
  ]) {
    test(
      'privacy native snapshot preserves learner cache during $operation',
      () async {
        final prefs = await SharedPreferences.getInstance();
        final readRelease = Completer<void>();
        native.releaseRead = readRelease;
        native.readEntered = Completer<void>();
        final entered = native.readEntered!.future;
        final Future<void> reading;
        if (operation == 'refresh') {
          PrivacyChoiceStorage.retire();
          reading = PrivacyChoiceStorage.refresh();
        } else {
          native.rejectKey = operation == 'bool reconciliation'
              ? 'kl_analytics_consent'
              : 'kl_birth_year';
          reading =
              (operation == 'bool reconciliation'
                      ? PrivacyChoiceStorage.set(PrivacyPurpose.analytics, true)
                      : PrivacyChoiceStorage.setAge(1990))
                  .catchError((Object _) {});
        }
        final word = ExtractedWord(
          korean: '사과',
          romanization: '',
          posDe: 'Nomen',
          translationDe: 'Apfel',
          translationEn: 'apple',
          exampleKorean: '',
          exampleDe: '',
          definitionKo: '',
          imagePath: '',
          savedToPackId: null,
        );
        try {
          await entered;
          expect(
            await CustomPackService.quickAdd(
              defaultPackName: 'Words',
              word: word,
            ),
            WordbookAddResult.added,
          );
          await VocabProgressAttempt(
            correctDelta: 1,
            seenId: 'cache-race-word',
          ).save();
          final savedPack = native.values['kl_custom_packs_v1'];
          expect(savedPack, contains('사과'));
          expect(native.values['kl_vok_correct'], 1);
          expect(native.values['kl_vok_seen_ids'], ['cache-race-word']);
          // Learner writes finish while the older native read is still held.
          expect(prefs.getString('kl_custom_packs_v1'), savedPack);
          readRelease.complete();
          await reading;
          final observations = <String, Object?>{
            'native pack': native.values['kl_custom_packs_v1'],
            'native correct': native.values['kl_vok_correct'],
            'native seen': native.values['kl_vok_seen_ids'],
            'cached pack': prefs.getString('kl_custom_packs_v1'),
            'cached correct': prefs.getInt('kl_vok_correct'),
            'cached seen': prefs.getStringList('kl_vok_seen_ids'),
            'domain pack': Storage.customPacksRawJson,
            'domain correct': Storage.vokCorrect,
            'domain seen': Storage.vokSeenIds,
            'duplicate': await CustomPackService.quickAdd(
              defaultPackName: 'Words',
              word: word,
            ),
          };
          expect(observations, {
            'native pack': savedPack,
            'native correct': 1,
            'native seen': ['cache-race-word'],
            'cached pack': savedPack,
            'cached correct': 1,
            'cached seen': ['cache-race-word'],
            'domain pack': savedPack,
            'domain correct': 1,
            'domain seen': ['cache-race-word'],
            'duplicate': WordbookAddResult.alreadyExists,
          });
        } finally {
          if (!readRelease.isCompleted) {
            readRelease.complete();
          }
          await reading;
        }
      },
    );
  }

  test('native rejection cannot authorize analytics grant', () async {
    native.rejectKey = 'kl_analytics_consent';
    await controller.setAnalytics(true).catchError((Object _) {});
    expect(native.values['kl_analytics_consent'], isNull);
    expect(Storage.analyticsConsent, isFalse);
    expect(analytics.calls, isNot(contains(true)));
  });
  test('held native grant cannot authorize application analytics', () async {
    native.rejectKey = 'kl_analytics_consent';
    native.entered = Completer<void>();
    native.release = Completer<void>();
    final entered = native.entered!.future;
    final pending = controller.setAnalytics(true).catchError((Object _) {});
    try {
      await entered;
      expect(Analytics.canCollect, isFalse);
      expect(analytics.calls, isNot(contains(true)));
    } finally {
      native.release!.complete();
      await pending;
    }
  });
  test('crash grant cannot enable before native persistence', () async {
    native.rejectKey = 'kl_crash_consent';
    native.entered = Completer<void>();
    native.release = Completer<void>();
    final entered = native.entered!.future;
    final pending = controller.setCrash(true).catchError((Object _) {});
    try {
      await entered;
      expect(crash.calls, isNot(contains('collection:true')));
    } finally {
      native.release!.complete();
      await pending;
    }
  });
  test('withdrawal exception still attempts SDK disable', () async {
    await controller.setCrash(true);
    crash.calls.clear();
    native.rejectKey = 'kl_crash_consent';
    native.throwReply = true;
    await controller.setCrash(false).catchError((Object _) {});
    controller.handlePlatformError(StateError('after off'), StackTrace.current);
    expect(crash.calls, contains('collection:false'));
    expect(crash.calls, isNot(contains('platform')));
  });
  test('late startup enable is followed by final disable', () async {
    await Storage.setAnalyticsConsent(true);
    analytics.enable = Completer<void>();
    final startup = controller.applyStored();
    try {
      await Future<void>.delayed(Duration.zero);
      final off = controller.setAnalytics(false);
      expect(controller.analyticsAdmitted, isFalse);
      analytics.enable!.complete();
      await off;
      await startup;
      await Future<void>.delayed(Duration.zero);
      expect(
        analytics.calls.where((value) => !value).length,
        greaterThanOrEqualTo(2),
      );
      expect(analytics.calls.last, isFalse);
      expect(analytics.applied, isFalse);
      expect(controller.analyticsAdmitted, isFalse);
    } finally {
      if (!analytics.enable!.isCompleted) {
        analytics.enable!.complete();
      }
      await startup;
    }
  });
  test('rejected pronunciation consent is not stored authority', () async {
    native.rejectKey = 'kl_pronunciation_consent_v1';
    await Storage.setPronunciationConsent(true).catchError((Object _) {});
    expect(native.values['kl_pronunciation_consent_v1'], isNull);
    expect(Storage.pronunciationConsent, isFalse);
  });
  test(
    'rejected plausible birth year is not successful age authority',
    () async {
      await Storage.setBirthYear(0);
      native.rejectKey = 'kl_birth_year';
      var saved = false;
      try {
        saved = await AgeGateService.saveBirthYear(DateTime.now().year - 25);
      } on Object {
        /* Expected failed boundary. */
      }
      expect(saved, isFalse);
      expect(native.values['kl_birth_year'], 0);
      expect(AgeGateService.isGyeAllowed, isFalse);
    },
  );

  test(
    'production events and diagnostics close before withdrawal write',
    () async {
      await PrivacyConsentService.setAnalytics(true);
      await PrivacyConsentService.setCrash(true);
      await Analytics.logEvent('before');
      await DiagnosticsService.logBreadcrumb('before');
      native.rejectKey = 'kl_crash_consent';
      native.entered = Completer<void>();
      native.release = Completer<void>();
      final entered = native.entered!.future;
      final off = PrivacyConsentService.setCrash(
        false,
      ).catchError((Object _) {});
      try {
        expect(PrivacyConsentService.canCollectCrash, isFalse);
        await entered;
        final calls = List<String>.of(crash.calls);
        await DiagnosticsService.logBreadcrumb('after');
        await DiagnosticsService.setKey(DiagnosticKey.windowClass, 'compact');
        expect(crash.calls, calls);
        expect(PrivacyConsentService.canCollectAnalytics, isTrue);
        await PrivacyConsentService.setAnalytics(false);
        await Analytics.logEvent('after');
        await Analytics.logScreenView('after');
        await Analytics.setUserProperty('after', 'no');
        expect(analytics.events, ['before']);
      } finally {
        native.release!.complete();
        await off;
      }
      expect(native.values['kl_crash_consent'], isTrue);
      expect(PrivacyConsentService.canCollectCrash, isFalse);
      expect(PrivacyChoiceStorage.choice(PrivacyPurpose.crash).failed, isTrue);
    },
  );

  test('lost reply reconciles against actual native bytes', () async {
    native.rejectKey = 'kl_analytics_consent';
    native.throwReply = true;
    native.commitBeforeFailure = true;
    await PrivacyConsentService.setAnalytics(true);
    expect(native.values['kl_analytics_consent'], isTrue);
    expect(PrivacyConsentService.canCollectAnalytics, isTrue);
  });

  test(
    'caller timeout retains actual native grant and coalesces retry',
    () async {
      PrivacyConsentService.waitLimit = const Duration(milliseconds: 15);
      native.rejectKey = 'kl_analytics_consent';
      native.commitBeforeFailure = true;
      native.release = Completer<void>();
      try {
        await expectLater(
          PrivacyConsentService.setAnalytics(true),
          throwsA(isA<TimeoutException>()),
        );
        expect(PrivacyConsentService.canCollectAnalytics, isFalse);
        await expectLater(
          PrivacyConsentService.setAnalytics(true),
          throwsA(isA<TimeoutException>()),
        );
        expect(
          native.calls
              .where((call) => call.startsWith('kl_analytics_consent='))
              .length,
          1,
        );
      } finally {
        native.release!.complete();
        await PrivacyChoiceStorage.drain();
        await Future<void>.delayed(Duration.zero);
      }
      expect(native.values['kl_analytics_consent'], isTrue);
      expect(PrivacyConsentService.canCollectAnalytics, isTrue);
    },
  );

  test(
    'superseding off drains late native grant then writes final false',
    () async {
      native.rejectKey = 'kl_analytics_consent';
      native.commitBeforeFailure = true;
      native.entered = Completer<void>();
      native.release = Completer<void>();
      final entered = native.entered!.future;
      final grant = PrivacyConsentService.setAnalytics(
        true,
      ).catchError((Object _) {});
      await entered;
      final off = PrivacyConsentService.setAnalytics(false);
      try {
        expect(PrivacyConsentService.canCollectAnalytics, isFalse);
        native.rejectKey = null;
        native.release!.complete();
        await Future.wait([grant, off]);
        expect(native.values['kl_analytics_consent'], isFalse);
        expect(analytics.calls, isNot(contains(true)));
      } finally {
        if (!native.release!.isCompleted) {
          native.release!.complete();
        }
        await Future.wait([grant, off]);
      }
    },
  );

  test(
    'SDK failure retains native crash selection and retry preserves reports',
    () async {
      crash.rejectEnable = true;
      await expectLater(PrivacyConsentService.setCrash(true), throwsStateError);
      expect(native.values['kl_crash_consent'], isTrue);
      expect(Storage.crashConsent, isTrue);
      expect(PrivacyConsentService.canCollectCrash, isFalse);
      expect(
        PrivacyConsentService.status(PrivacyPurpose.crash),
        PrivacyApplicationStatus.retryRequired,
      );
      crash.rejectEnable = false;
      await PrivacyConsentService.setCrash(true);
      expect(crash.calls.where((call) => call == 'delete').length, 1);
      expect(PrivacyConsentService.canCollectCrash, isTrue);
    },
  );

  test('age failure disables SDKs despite older native adult bytes', () async {
    await PrivacyConsentService.setAnalytics(true);
    await PrivacyConsentService.setCrash(true);
    await Storage.setPronunciationConsent(true);
    native.rejectKey = 'kl_birth_year';
    final saved = AgeGateService.saveBirthYear(DateTime.now().year - 10);
    expect(PrivacyConsentService.canCollectAnalytics, isFalse);
    expect(PrivacyConsentService.canCollectCrash, isFalse);
    expect(await saved, isFalse);
    expect(AgeGateService.isGyeAllowed, isFalse);
    expect(analytics.calls.last, isFalse);
    expect(crash.applied, isFalse);
    final calls = crash.calls.length;
    await DiagnosticsService.logBreadcrumb('ineligible');
    expect(crash.calls.length, calls);
    expect(PrivacyConsentService.canSubmitPronunciation, isTrue);
    native.rejectKey = null;
    expect(
      await AgeGateService.saveBirthYear(DateTime.now().year - 25),
      isTrue,
    );
    await Future<void>.delayed(Duration.zero);
    expect(PrivacyConsentService.canCollectCrash, isTrue);
  });

  test(
    'reset drains actual native work before deleting late consent',
    () async {
      native.rejectKey = 'kl_analytics_consent';
      native.commitBeforeFailure = true;
      native.entered = Completer<void>();
      native.release = Completer<void>();
      final entered = native.entered!.future;
      final grant = PrivacyConsentService.setAnalytics(
        true,
      ).catchError((Object _) {});
      await entered;
      var resetFinished = false;
      final reset = Storage.resetAll().then((_) => resetFinished = true);
      try {
        await Future<void>.delayed(Duration.zero);
        expect(resetFinished, isFalse);
        expect(PrivacyConsentService.canCollectAnalytics, isFalse);
        native.release!.complete();
        await Future.wait([grant, reset]);
        await PrivacyChoiceStorage.refresh();
        expect(native.values.containsKey('kl_analytics_consent'), isFalse);
        expect(Storage.analyticsConsent, isFalse);
        expect(analytics.applied, isFalse);
      } finally {
        if (!native.release!.isCompleted) {
          native.release!.complete();
        }
        await Future.wait([grant, reset]);
      }
    },
  );

  test(
    'actual ownership producer fences before identity and preserves failed off',
    () async {
      final sessions = CloudWriteSessionController()..acquire('source');
      PrivacyConsentService.bindAccountSessions(sessions);
      await PrivacyChoiceStorage.refresh();
      await PrivacyConsentService.setAnalytics(true);
      native.rejectKey = 'kl_analytics_consent';
      await expectLater(
        PrivacyConsentService.setAnalytics(false),
        throwsA(isA<PreferenceWriteException>()),
      );
      final coordinator = PushOwnershipTransitionCoordinator(
        push: _Push(),
        notificationsEnabled: () => false,
        sessions: sessions,
      );
      final result = await coordinator.run(
        oldUid: 'source',
        transition: () async {
          expect(sessions.current!.mode, CloudWriteMode.quiesced);
          expect(PrivacyConsentService.canCollectAnalytics, isFalse);
          sessions.acquire('target');
        },
      );
      expect(result, CloudWriteResult.stale);
      await PrivacyChoiceStorage.refresh();
      await Future<void>.delayed(Duration.zero);
      expect(native.values['kl_analytics_consent'], isTrue);
      expect(PrivacyConsentService.canCollectAnalytics, isFalse);
      expect(
        PrivacyChoiceStorage.choice(PrivacyPurpose.analytics).failed,
        isTrue,
      );
    },
  );

  test('live import cannot resurrect withdrawal or export consent', () async {
    await PrivacyConsentService.setAnalytics(true);
    native.rejectKey = 'kl_analytics_consent';
    await expectLater(
      PrivacyConsentService.setAnalytics(false),
      throwsA(isA<PreferenceWriteException>()),
    );
    await CloudSync.applyRestorePayload({
      'kl_analytics_consent': true,
      'kl_birth_year': 1990,
    });
    await PrivacyChoiceStorage.refresh();
    expect(PrivacyConsentService.canCollectAnalytics, isFalse);
    final backup = await CloudSync.buildBackupPayload();
    expect(backup.keys, isNot(contains('kl_analytics_consent')));
    expect(backup.keys, isNot(contains('kl_birth_year')));
  });

  test('whole-cache read cannot erase later native-confirmed choice', () async {
    final prefs = await SharedPreferences.getInstance();
    final readRelease = Completer<void>();
    native.releaseRead = readRelease;
    native.readEntered = Completer<void>();
    final entered = native.readEntered!.future;
    final read = Storage.reloadForPackCompletion(prefs);
    await entered;
    try {
      await PrivacyConsentService.setAnalytics(true);
      expect(PrivacyConsentService.canCollectAnalytics, isTrue);
      readRelease.complete();
      await read;
      expect(prefs.getBool('kl_analytics_consent'), isNull);
      expect(Storage.analyticsConsent, isTrue);
      expect(PrivacyConsentService.canCollectAnalytics, isTrue);
    } finally {
      if (!readRelease.isCompleted) {
        readRelease.complete();
      }
      await read;
    }
  });

  test('malformed native choices fail closed without backfill', () async {
    Storage.resetForTesting();
    SharedPreferences.setMockInitialValues({});
    native.values.addAll({
      'kl_analytics_consent': 'true',
      'kl_crash_consent': 1,
      'kl_birth_year': '1990',
    });
    SharedPreferencesStorePlatform.instance = native;
    await Storage.init();
    PrivacyConsentService.configureForTesting(
      analytics: analytics,
      crash: crash,
    );
    await PrivacyConsentService.applyStored();
    expect(PrivacyConsentService.canCollectAnalytics, isFalse);
    expect(PrivacyConsentService.canCollectCrash, isFalse);
    expect(native.values['kl_analytics_consent'], 'true');
    expect(native.values['kl_birth_year'], '1990');
  });
  test('latest on waits for a held earlier off and becomes applied', () async {
    await PrivacyConsentService.setAnalytics(true);
    analytics.disable = Completer<void>();
    final off = PrivacyConsentService.setAnalytics(false);
    final on = PrivacyConsentService.setAnalytics(true);
    try {
      await Future<void>.delayed(Duration.zero);
      expect(PrivacyConsentService.canCollectAnalytics, isFalse);
      expect(analytics.calls.where((v) => v), hasLength(1));
      analytics.disable!.complete();
      await Future.wait([off, on]);
      expect(analytics.applied, isTrue);
      expect(PrivacyConsentService.canCollectAnalytics, isTrue);
      expect(native.values['kl_analytics_consent'], isTrue);
    } finally {
      if (!analytics.disable!.isCompleted) {
        analytics.disable!.complete();
      }
      await Future.wait([off, on]);
    }
  });

  test(
    'timed out SDK enable stays owned through off and final failed disable',
    () async {
      PrivacyConsentService.waitLimit = const Duration(milliseconds: 5);
      analytics.enable = Completer<void>();
      await expectLater(
        PrivacyConsentService.setAnalytics(true),
        throwsA(isA<TimeoutException>()),
      );
      expect(native.values['kl_analytics_consent'], isTrue);
      expect(PrivacyConsentService.canCollectAnalytics, isFalse);
      final off = PrivacyConsentService.setAnalytics(
        false,
      ).catchError((Object _) {});
      try {
        await Future<void>.delayed(Duration.zero);
        expect(analytics.applied, isFalse);
        analytics.rejectDisable = true;
        analytics.enable!.complete();
        await off;
        await Future<void>.delayed(Duration.zero);
        expect(analytics.applied, isTrue);
        expect(PrivacyConsentService.canCollectAnalytics, isFalse);
        expect(native.values['kl_analytics_consent'], isFalse);
        expect(
          PrivacyConsentService.status(PrivacyPurpose.analytics),
          PrivacyApplicationStatus.retryRequired,
        );
        analytics.rejectDisable = false;
        await PrivacyConsentService.setAnalytics(false);
        expect(analytics.applied, isFalse);
        expect(
          PrivacyConsentService.status(PrivacyPurpose.analytics),
          PrivacyApplicationStatus.inactive,
        );
      } finally {
        if (!analytics.enable!.isCompleted) {
          analytics.enable!.complete();
        }
        await off;
      }
    },
  );

  test(
    'external invalidation retains pending SDK compensation ownership',
    () async {
      await Storage.setAnalyticsConsent(true);
      analytics.enable = Completer<void>();
      final startup = PrivacyConsentService.applyStored();
      try {
        await Future<void>.delayed(Duration.zero);
        Storage.resetCachesAfterExternalWrite();
        await PrivacyChoiceStorage.refresh();
        expect(PrivacyConsentService.canCollectAnalytics, isFalse);
        expect(
          PrivacyConsentService.status(PrivacyPurpose.analytics),
          PrivacyApplicationStatus.pending,
        );
        analytics.enable!.complete();
        await startup;
        await Future<void>.delayed(Duration.zero);
        // Eligible confirmed device-local consent may reapply after fresh authority.
        await PrivacyConsentService.applyStored();
        expect(analytics.applied, isTrue);
        expect(PrivacyConsentService.canCollectAnalytics, isTrue);
      } finally {
        if (!analytics.enable!.isCompleted) {
          analytics.enable!.complete();
        }
        await startup;
      }
    },
  );
  test(
    'session-only reset restores confirmed local authority after retirement',
    () async {
      await PrivacyConsentService.setAnalytics(true);
      await Storage.resetSession();
      await PrivacyChoiceStorage.refresh();
      await PrivacyConsentService.applyStored();
      expect(native.values['kl_analytics_consent'], isTrue);
      expect(PrivacyConsentService.canCollectAnalytics, isTrue);
      expect(analytics.applied, isTrue);
      await PrivacyConsentService.setAnalytics(false);
      expect(native.values['kl_analytics_consent'], isFalse);
    },
  );
  test(
    'failed session reset preserves failed withdrawal and allows explicit retry',
    () async {
      await PrivacyConsentService.setAnalytics(true);
      native.rejectKey = 'kl_analytics_consent';
      await expectLater(
        PrivacyConsentService.setAnalytics(false),
        throwsA(isA<PreferenceWriteException>()),
      );
      native.values['kl_vok_correct'] = 5;
      await (await SharedPreferences.getInstance()).reload();
      native.rejectKey = 'kl_vok_correct';
      await expectLater(
        Storage.resetSession(),
        throwsA(isA<PreferenceWriteException>()),
      );
      await PrivacyChoiceStorage.refresh();
      await PrivacyConsentService.applyStored();
      expect(native.values['kl_analytics_consent'], isTrue);
      expect(PrivacyConsentService.canCollectAnalytics, isFalse);
      expect(
        PrivacyChoiceStorage.choice(PrivacyPurpose.analytics).failed,
        isTrue,
      );
      native.rejectKey = null;
      await PrivacyConsentService.setAnalytics(false);
      expect(native.values['kl_analytics_consent'], isFalse);
      expect(analytics.applied, isFalse);
    },
  );
  test(
    'held first-action marker cannot admit its old event after an age change',
    () async {
      await Storage.setHasCompletedOnboardingStrict(true);
      await PrivacyConsentService.setAnalytics(true);
      native.rejectKey = Storage.consentedFirstLearningActionClaimPreferenceKey;
      native.commitBeforeFailure = true;
      native.entered = Completer<void>();
      native.release = Completer<void>();
      final entered = native.entered!.future;
      final action = Analytics.learningActionStarted(
        ConsentedFirstLearningAction.vocabulary,
      );
      try {
        await entered;
        await AgeGateService.saveBirthYear(DateTime.now().year - 26);
        await PrivacyConsentService.applyStored();
        expect(PrivacyConsentService.canCollectAnalytics, isTrue);
        expect(analytics.applied, isTrue);
        native.release!.complete();
        await action;
        expect(Storage.hasClaimedConsentedFirstLearningAction, isTrue);
        expect(analytics.events, isEmpty);
        await Analytics.learningActionStarted(
          ConsentedFirstLearningAction.vocabulary,
        );
        expect(analytics.events, isEmpty);
      } finally {
        if (!native.release!.isCompleted) {
          native.release!.complete();
        }
        await action;
      }
    },
  );
  test(
    'review1 initial crash deletion owns barrier through timeout off and on',
    () async {
      final release = Completer<void>();
      crash.deleteRelease = release;
      crash.deleteEntered = Completer<void>();
      final entered = crash.deleteEntered!.future;
      PrivacyConsentService.waitLimit = const Duration(milliseconds: 5);
      final first = PrivacyConsentService.setCrash(
        true,
      ).catchError((Object _) {});
      await entered;
      await first;
      PrivacyConsentService.waitLimit = const Duration(seconds: 5);
      final off = PrivacyConsentService.setCrash(false);
      final latest = PrivacyConsentService.setCrash(true);
      try {
        await Future<void>.delayed(Duration.zero);
        final enabledBeforeCleanup = crash.calls.contains('collection:true');
        final admittedBeforeCleanup = PrivacyConsentService.canCollectCrash;
        release.complete();
        await Future.wait([off, latest]);
        crash.reports.add('valid-consented-report');
        await Future<void>.delayed(Duration.zero);
        expect(enabledBeforeCleanup, isFalse);
        expect(admittedBeforeCleanup, isFalse);
        expect(crash.applied, isTrue);
        expect(crash.reports, ['valid-consented-report']);
      } finally {
        if (!release.isCompleted) {
          release.complete();
        }
        await Future.wait([off, latest]);
      }
    },
  );
}
