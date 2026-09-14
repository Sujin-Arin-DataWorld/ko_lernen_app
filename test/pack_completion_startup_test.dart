import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_platform_interface.dart';
import 'package:ko_lernen_app/main.dart';
import 'package:ko_lernen_app/features/onboarding_v2/first_run_runtime.dart';
import 'package:ko_lernen_app/l10n/generated/app_localizations.dart';
import 'package:ko_lernen_app/screens/consent_screen.dart';
import 'package:ko_lernen_app/screens/settings_screen.dart';
import 'package:ko_lernen_app/screens/vocab_pack_screen.dart';
import 'package:ko_lernen_app/screens/vocab_pack_result_screen.dart';
import 'package:ko_lernen_app/services/course_progress_service.dart';
import 'package:ko_lernen_app/services/decoration_reward_service.dart';
import 'package:ko_lernen_app/services/data_migration_service.dart';
import 'package:ko_lernen_app/services/storage_service.dart';
import 'package:ko_lernen_app/services/pack_completion_record.dart';
import 'package:ko_lernen_app/services/pack_completion_owner.dart';
import 'package:ko_lernen_app/services/vocab_pack_finish_coordinator.dart';
import 'package:ko_lernen_app/widgets/sori/pack_completion_recovery_banner.dart';
import 'package:ko_lernen_app/widgets/sori/button.dart';
import 'support/real_fonts.dart';
import 'support/reward_preferences_platform.dart';
import 'support/sori_speech_stubs.dart';
import 'support/pack_completion_test_data.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(loadSoriRealFonts);
  late RewardPreferencesPlatform native;
  setUp(() async {
    stubSoriSpeech();
    Storage.resetForTesting();
    DataMigrationService.resetForTesting();
    CourseProgressService.shared.resetForTesting();
    DecorationRewardService.resetForTesting();
    PackCompletionOwner.identityForTesting = null;
    SharedPreferences.setMockInitialValues({});
    native = RewardPreferencesPlatform();
    SharedPreferencesStorePlatform.instance = native;
    await Storage.init();
    DefaultVocabPackFinishOperations.initializeRecovery();
  });
  Future<void> frames(WidgetTester tester) async {
    for (var i = 0; i < 25; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  Future<void> coldApp(WidgetTester tester) async {
    await (await SharedPreferences.getInstance()).reload();
    Storage.resetForTesting();
    await Storage.init();
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      KoLernenApp(
        splashDisplayDuration: Duration.zero,
        firstRunCoordinator: FirstRunRuntime.createCoordinator(),
      ),
    );
    await frames(tester);
    expect(find.byType(ConsentScreen), findsOneWidget);
    expect(tester.takeException(), isNull);
  }

  testWidgets(
    'cold malformed journal preserves real consent settings and guards direct routes',
    (tester) async {
      const malformed = '{"version":99}';
      native.values[PackCompletionRecord.key] = malformed;
      await coldApp(tester);
      final navigator = tester.state<NavigatorState>(
        find.byType(Navigator).first,
      );
      for (final route in ['/vocab/pack', '/vocab/result', '/stats']) {
        unawaited(
          navigator.pushNamed(route, arguments: {'packId': 'not-authority'}),
        );
        await frames(tester);
        expect(find.byType(PackCompletionRecoveryScreen), findsOneWidget);
        expect(find.byType(VocabPackScreen), findsNothing);
        expect(find.byType(VocabPackResultScreen), findsNothing);
        expect(tester.takeException(), isNull);
        navigator.pop();
        await frames(tester);
        expect(find.byType(ConsentScreen), findsOneWidget);
      }
      unawaited(navigator.pushNamed('/settings'));
      await frames(tester);
      expect(find.byType(SettingsScreen), findsOneWidget);
      expect(find.byType(PackCompletionRecoveryScreen), findsNothing);
      navigator.pop();
      await frames(tester);
      unawaited(navigator.pushNamed('/onboarding'));
      await frames(tester);
      expect(find.byType(ConsentScreen), findsOneWidget);
      navigator.pop();
      await frames(tester);
      expect(native.values[PackCompletionRecord.key], malformed);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  testWidgets(
    'cold pending pack permits real startup and retry with native write outstanding',
    (tester) async {
      late VocabPackFinishRequest request;
      await tester.runAsync(() async {
        request = await packCompletionRequest();
        native.rejectKey = PackCompletionRecord.xpKey;
        await expectLater(
          VocabPackFinishCoordinator(
            DefaultVocabPackFinishOperations(),
          ).finish(request),
          throwsA(isA<PreferenceWriteException>()),
        );
      });
      await coldApp(tester);
      final release = Completer<void>();
      native.releaseWrite = release;
      native.commitBeforeFailure = true;
      addTearDown(() {
        if (!release.isCompleted) {
          release.complete();
        }
      });
      final effects = <String>[];
      var complete = false;
      unawaited(
        finishPostMigrationStartup(
          const DataMigrationResult(
            status: DataMigrationStatus.upToDate,
            fromVersion: 1,
            toVersion: 1,
          ),
          applyAudioContext: () async => effects.add('audio'),
          initializeManagedMedia: () async => effects.add('media'),
          recoverCrop: () async => effects.add('crop'),
          recoverPicker: () async => effects.add('picker'),
        ).then((_) => complete = true),
      );
      await tester.pump();
      await tester.pump(const Duration(seconds: 6));
      expect(complete, isTrue);
      expect(effects, ['audio', 'media', 'crop', 'picker']);
      expect(PackCompletionStorage.pending, isTrue);
      expect(release.isCompleted, isFalse);
      expect(find.byType(ConsentScreen), findsOneWidget);
      final navigator = tester.state<NavigatorState>(
        find.byType(Navigator).first,
      );
      unawaited(
        navigator.pushNamed(
          '/vocab/pack',
          arguments: {'packId': request.pack.id},
        ),
      );
      await frames(tester);
      expect(find.byType(VocabPackScreen), findsOneWidget);
      expect(find.byType(PackCompletionRecoveryScreen), findsOneWidget);
      final writes = native.writes[PackCompletionRecord.xpKey];
      final t = AppL10n.of(
        tester.element(find.byType(PackCompletionRecoveryScreen)),
      );
      final retry = find.descendant(
        of: find.byType(PackCompletionRecoveryScreen),
        matching: find.widgetWithText(SoriButton, t.btnRetry),
      );
      await tester.ensureVisible(retry);
      await tester.tap(retry);
      await frames(tester);
      expect(native.writes[PackCompletionRecord.xpKey], writes);
      expect(release.isCompleted, isFalse);
      release.complete();
      await frames(tester);
      expect(PackCompletionStorage.pending, isFalse);
      expect(find.byType(VocabPackResultScreen), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
}
