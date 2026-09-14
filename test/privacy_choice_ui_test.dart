import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_platform_interface.dart';
import 'package:ko_lernen_app/l10n/generated/app_localizations.dart';
import 'package:ko_lernen_app/models/pronunciation_phrase.dart';
import 'package:ko_lernen_app/models/scenario.dart';
import 'package:ko_lernen_app/screens/settings_screen.dart';
import 'package:ko_lernen_app/screens/pronunciation_studio_screen.dart';
import 'package:ko_lernen_app/services/storage_service.dart';
import 'package:ko_lernen_app/services/privacy_consent_service.dart';
import 'package:ko_lernen_app/services/pronunciation_recorder.dart';
import 'package:ko_lernen_app/services/pronunciation_playback.dart';
import 'package:ko_lernen_app/services/pronunciation_assessment_client.dart';
import 'package:ko_lernen_app/theme.dart';
import 'package:ko_lernen_app/widgets/sori/age_gate_prompt.dart';
import 'package:ko_lernen_app/widgets/sori/consent_invite_sheet.dart';
import 'package:ko_lernen_app/widgets/sori/privacy_choice_feedback.dart';
import 'package:ko_lernen_app/widgets/sori/button.dart';
import 'package:ko_lernen_app/widgets/sori/speakable.dart';
import 'support/privacy_preferences_platform.dart';
import 'support/real_fonts.dart';

Future<void> _pump(WidgetTester tester) async {
  for (var i = 0; i < 8; i++) {
    await tester.pump(const Duration(milliseconds: 40));
  }
}

Future<void> _mount(
  WidgetTester tester,
  Widget child, {
  String locale = 'en',
  double scale = 1,
  bool dark = false,
}) async {
  await tester.pumpWidget(const SizedBox.shrink());
  await _pump(tester);
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = const Size(320, 640);
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetPhysicalSize);
  await tester.pumpWidget(
    MaterialApp(
      locale: Locale(locale),
      localizationsDelegates: AppL10n.localizationsDelegates,
      supportedLocales: AppL10n.supportedLocales,
      theme: dark ? AppTheme.dark : AppTheme.light,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(
          textScaler: TextScaler.linear(scale),
          disableAnimations: true,
        ),
        child: child!,
      ),
      home: child,
    ),
  );
  await _pump(tester);
}

Future<void> _tap(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await _pump(tester);
  await tester.tap(finder);
  await _pump(tester);
}

void main() {
  setUpAll(loadSoriRealFonts);
  late PrivacyPreferencesPlatform native;
  late PrivacyFakeAnalytics analytics;
  late PrivacyFakeCrash crash;
  setUp(() async {
    SoriSpeech.resetForTesting();
    SoriSpeech.stopImpl = () async {};
    Storage.resetForTesting();
    SharedPreferences.setMockInitialValues({});
    native = PrivacyPreferencesPlatform();
    native.values.addAll({
      'kl_birth_year': DateTime.now().year - 25,
      'kl_consent_accepted': true,
    });
    SharedPreferencesStorePlatform.instance = native;
    await Storage.init();
    analytics = PrivacyFakeAnalytics();
    crash = PrivacyFakeCrash();
    PrivacyConsentService.configureForTesting(
      analytics: analytics,
      crash: crash,
    );
    ConsentInviteSheet.resetForTesting();
  });
  tearDown(() {
    if (native.release case final held? when !held.isCompleted) {
      held.complete();
    }
    SoriSpeech.resetForTesting();
  });

  testWidgets(
    'local reset clears settled consent switches in the same process',
    (tester) async {
      for (final purpose in PrivacyPurpose.values) {
        await PrivacyConsentService.setChoice(purpose, true);
      }
      Widget choices() => Scaffold(
        body: Column(
          children: [
            for (final purpose in PrivacyPurpose.values)
              PrivacyChoiceControl(
                purpose: purpose,
                title: purpose.name,
                description: 'Optional',
                icon: Icons.privacy_tip_outlined,
              ),
          ],
        ),
      );
      await _mount(tester, choices());
      expect(
        tester
            .widgetList<SwitchListTile>(find.byType(SwitchListTile))
            .every((tile) => tile.value),
        isTrue,
      );

      await Storage.resetAll();
      await PrivacyChoiceStorage.refresh();
      await PrivacyConsentService.applyStored();
      await _pump(tester);
      for (final purpose in PrivacyPurpose.values) {
        expect(PrivacyChoiceStorage.admitted(purpose), isFalse);
        expect(
          tester
              .widget<SwitchListTile>(
                find.byKey(ValueKey('privacy-choice-${purpose.name}')),
              )
              .value,
          isFalse,
        );
      }
      expect(analytics.applied, isFalse);
      expect(crash.applied, isFalse);
      await _mount(tester, choices());
      expect(
        tester
            .widgetList<SwitchListTile>(find.byType(SwitchListTile))
            .every((tile) => !tile.value),
        isTrue,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'real settings retains failed withdrawal and retries its false value',
    (tester) async {
      await PrivacyConsentService.setAnalytics(true);
      await _mount(tester, const SettingsScreen());
      final choice = find.byKey(const ValueKey('privacy-choice-analytics'));
      await tester.scrollUntilVisible(
        choice,
        400,
        scrollable: find.byType(Scrollable).first,
        maxScrolls: 60,
      );
      await _pump(tester);
      native.rejectKey = 'kl_analytics_consent';
      await _tap(tester, choice);
      expect(PrivacyConsentService.canCollectAnalytics, isFalse);
      expect(tester.widget<SwitchListTile>(choice).value, isFalse);
      expect(find.textContaining('before closing the app'), findsOneWidget);
      expect(native.values['kl_analytics_consent'], isTrue);
      native.rejectKey = null;
      await _tap(tester, find.widgetWithText(SoriButton, 'Try again'));
      expect(native.values['kl_analytics_consent'], isFalse);
      expect(find.textContaining('before closing the app'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'post-result invite keeps partial selection and retries only failed purpose',
    (tester) async {
      native.rejectKey = 'kl_crash_consent';
      await _mount(
        tester,
        const Scaffold(body: ConsentInviteTrigger(child: SizedBox())),
      );
      final t = AppL10n.of(tester.element(find.byType(ConsentInviteTrigger)));
      await _tap(tester, find.widgetWithText(SoriButton, t.consentInviteYes));
      expect(native.values['kl_analytics_consent'], isTrue);
      expect(native.values['kl_crash_consent'], isNull);
      expect(find.byType(PrivacyChoiceFeedback), findsOneWidget);
      expect(
        tester.widgetList<Switch>(find.byType(Switch)).map((s) => s.value),
        [true, true],
      );
      final before = native.calls
          .where((s) => s.startsWith('kl_analytics_consent='))
          .length;
      native.rejectKey = null;
      await _tap(tester, find.widgetWithText(SoriButton, t.btnRetry));
      expect(
        native.calls.where((s) => s.startsWith('kl_analytics_consent=')).length,
        before,
      );
      expect(native.values['kl_crash_consent'], isTrue);
      expect(find.byType(PrivacyChoiceFeedback), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'age prompt keeps rejected input and reports allowed only after native retry',
    (tester) async {
      await Storage.setBirthYear(0);
      bool? allowed;
      await _mount(
        tester,
        Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () async {
                allowed = await ensureGyeAgeAllowed(context);
              },
              child: const Text('Open'),
            ),
          ),
        ),
      );
      await _tap(tester, find.text('Open'));
      await tester.enterText(
        find.byType(TextField),
        '${DateTime.now().year - 25}',
      );
      native.rejectKey = 'kl_birth_year';
      await _tap(tester, find.widgetWithText(SoriButton, 'OK'));
      expect(allowed, isNull);
      expect(find.byType(TextField), findsOneWidget);
      expect(Storage.birthYear, 0);
      native.rejectKey = null;
      await _tap(tester, find.widgetWithText(SoriButton, 'Try again'));
      expect(allowed, isTrue);
      expect(native.values['kl_birth_year'], DateTime.now().year - 25);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'dismissed pending pronunciation choice cannot navigate from late callback',
    (tester) async {
      native.rejectKey = 'kl_pronunciation_consent_v1';
      native.release = Completer<void>();
      bool? accepted;
      await _mount(
        tester,
        Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () async {
                accepted = await ensurePronunciationPrivacyConsent(context);
              },
              child: const Text('Open'),
            ),
          ),
        ),
      );
      try {
        await _tap(tester, find.text('Open'));
        final t = AppL10n.of(tester.element(find.byType(Scaffold).first));
        await _tap(
          tester,
          find.widgetWithText(SoriButton, t.pronunciationConsentAccept),
        );
        expect(PrivacyConsentService.canSubmitPronunciation, isFalse);
        await tester.binding.handlePopRoute();
        await _pump(tester);
        expect(accepted, isFalse);
        if (!native.release!.isCompleted) {
          native.release!.complete();
        }
        await _pump(tester);
        expect(find.text('Open'), findsOneWidget);
        expect(tester.takeException(), isNull);
      } finally {
        if (!native.release!.isCompleted) {
          native.release!.complete();
        }
        await _pump(tester);
        await PrivacyChoiceStorage.drain();
        await tester.pumpWidget(const SizedBox.shrink());
        await _pump(tester);
      }
    },
  );

  for (final locale in ['de', 'en']) {
    for (final scale in [1.0, 2.0]) {
      for (final dark in [false, true]) {
        testWidgets(
          'native failure controls $locale ${scale * 100}% dark=$dark at 320dp',
          (tester) async {
            final semantics = tester.ensureSemantics();
            try {
              native.rejectKey = 'kl_pronunciation_consent_v1';
              await _mount(
                tester,
                Scaffold(
                  body: Builder(
                    builder: (context) => TextButton(
                      onPressed: () =>
                          ensurePronunciationPrivacyConsent(context),
                      child: const Text('Open'),
                    ),
                  ),
                ),
                locale: locale,
                scale: scale,
                dark: dark,
              );
              final t = AppL10n.of(tester.element(find.byType(Scaffold)));
              await _tap(tester, find.text('Open'));
              final accept = find.widgetWithText(
                SoriButton,
                t.pronunciationConsentAccept,
              );
              final decline = find.widgetWithText(
                SoriButton,
                t.pronunciationConsentDecline,
              );
              await _tap(tester, accept);
              expect(Storage.pronunciationConsent, isFalse);
              final retry = find.widgetWithText(SoriButton, t.btnRetry);
              await tester.ensureVisible(retry);
              expect(tester.getSize(retry).height, greaterThanOrEqualTo(48));
              expect(tester.getSize(accept).height, greaterThanOrEqualTo(48));
              expect(tester.getSize(decline).height, greaterThanOrEqualTo(48));
              expect(tester.takeException(), isNull);
              await _tap(tester, decline);
              expect(PrivacyConsentService.canSubmitPronunciation, isFalse);
              native.rejectKey = 'kl_analytics_consent';
              await _mount(
                tester,
                const Scaffold(
                  body: SingleChildScrollView(
                    child: PrivacyChoiceControl(
                      purpose: PrivacyPurpose.analytics,
                      title: 'Analytics',
                      description: 'Optional',
                      icon: Icons.insights,
                    ),
                  ),
                ),
                locale: locale,
                scale: scale,
                dark: dark,
              );
              await _tap(tester, find.byType(SwitchListTile));
              expect(find.text(t.privacyChoiceUnconfirmed), findsOneWidget);
              expect(
                tester
                    .getSize(find.widgetWithText(SoriButton, t.btnRetry))
                    .height,
                greaterThanOrEqualTo(48),
              );
              await _tap(tester, find.byType(SwitchListTile));
              native.rejectKey = null;
              await Storage.setBirthYear(0);
              await _mount(
                tester,
                Scaffold(
                  body: Builder(
                    builder: (context) => TextButton(
                      onPressed: () => ensureGyeAgeAllowed(context),
                      child: const Text('Age'),
                    ),
                  ),
                ),
                locale: locale,
                scale: scale,
                dark: dark,
              );
              await _tap(tester, find.text('Age'));
              await tester.enterText(
                find.byType(TextField),
                '${DateTime.now().year - 25}',
              );
              native.rejectKey = 'kl_birth_year';
              await _tap(tester, find.widgetWithText(SoriButton, t.btnConfirm));
              await tester.ensureVisible(
                find.widgetWithText(SoriButton, t.btnRetry),
              );
              expect(
                tester
                    .getSize(find.widgetWithText(SoriButton, t.btnRetry))
                    .height,
                greaterThanOrEqualTo(48),
              );
              await _tap(tester, find.text(t.btnCancel));
              expect(Storage.birthYear, 0);
              native.rejectKey = null;
              await Storage.setBirthYear(DateTime.now().year - 25);
              native.rejectKey = 'kl_crash_consent';
              await _mount(
                tester,
                const Scaffold(
                  body: ConsentInviteTrigger(child: Text('Result')),
                ),
                locale: locale,
                scale: scale,
                dark: dark,
              );
              await _tap(
                tester,
                find.widgetWithText(SoriButton, t.consentInviteYes),
              );
              await tester.ensureVisible(
                find.widgetWithText(SoriButton, t.btnRetry),
              );
              expect(
                tester
                    .getSize(find.widgetWithText(SoriButton, t.btnRetry))
                    .height,
                greaterThanOrEqualTo(48),
              );
              await _tap(
                tester,
                find.widgetWithText(SoriButton, t.consentInviteNo),
              );
              expect(tester.takeException(), isNull);
              await tester.pumpWidget(const SizedBox.shrink());
              await _pump(tester);
            } finally {
              semantics.dispose();
            }
          },
        );
      }
    }
  }

  testWidgets(
    'real pronunciation assessment never uploads after consent rejection',
    (tester) async {
      final recorder = _Recorder();
      final gateway = _Gateway();
      await _mount(
        tester,
        PronunciationStudioScreen(
          recorder: recorder,
          playback: _Playback(),
          gateway: gateway,
          cloudAssessmentEnabled: true,
          phrases: const [
            PronunciationPhrase(
              id: 'hello',
              ko: '안녕하세요',
              de: 'Hallo',
              en: 'Hello',
              level: LearnerLevel.a1,
              focus: 'vowels',
            ),
          ],
        ),
      );
      await _tap(
        tester,
        find.byKey(const ValueKey('pronunciation-record-action')),
      );
      await _tap(
        tester,
        find.byKey(const ValueKey('pronunciation-record-action')),
      );
      await _pump(tester);
      await tester.runAsync(
        () async => Future<void>.delayed(const Duration(milliseconds: 20)),
      );
      await _pump(tester);
      native.rejectKey = 'kl_pronunciation_consent_v1';
      await _tap(
        tester,
        find.byKey(const ValueKey('pronunciation-assess-action')),
      );
      final t = AppL10n.of(
        tester.element(find.byType(PronunciationStudioScreen)),
      );
      await _tap(
        tester,
        find.widgetWithText(SoriButton, t.pronunciationConsentAccept),
      );
      expect(gateway.calls, 0);
      expect(native.values['kl_pronunciation_consent_v1'], isNull);
      await tester.binding.handlePopRoute();
      await _pump(tester);
      expect(
        find.byKey(const ValueKey('pronunciation-replay-action')),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      await _pump(tester);
    },
  );
  testWidgets('saved choice with failed SDK has distinct retry feedback', (
    tester,
  ) async {
    analytics.rejectEnable = true;
    await _mount(
      tester,
      const Scaffold(
        body: PrivacyChoiceControl(
          purpose: PrivacyPurpose.analytics,
          title: 'Analytics',
          description: 'Optional',
          icon: Icons.insights,
        ),
      ),
    );
    await _tap(tester, find.byType(SwitchListTile));
    final t = AppL10n.of(tester.element(find.byType(Scaffold)));
    expect(native.values['kl_analytics_consent'], isTrue);
    expect(find.text(t.privacyApplicationUnconfirmed), findsOneWidget);
    expect(find.text(t.privacyChoiceUnconfirmed), findsNothing);
    expect(PrivacyConsentService.canCollectAnalytics, isFalse);
    analytics.rejectEnable = false;
    await _tap(tester, find.widgetWithText(SoriButton, t.btnRetry));
    expect(PrivacyConsentService.canCollectAnalytics, isTrue);
    expect(analytics.applied, isTrue);
  });

  for (final retire in [false, true]) {
    testWidgets(
      'issued assessment response respects off versus retirement $retire',
      (tester) async {
        await Storage.setPronunciationConsent(true);
        final gateway = _Gateway()
          ..response = Completer<PronunciationAssessmentResult>();
        await _mount(
          tester,
          PronunciationStudioScreen(
            recorder: _Recorder(),
            playback: _Playback(),
            gateway: gateway,
            cloudAssessmentEnabled: true,
            phrases: const [
              PronunciationPhrase(
                id: 'hello',
                ko: '안녕하세요',
                de: 'Hallo',
                en: 'Hello',
                level: LearnerLevel.a1,
                focus: 'vowels',
              ),
            ],
          ),
        );
        try {
          await _tap(
            tester,
            find.byKey(const ValueKey('pronunciation-record-action')),
          );
          await _tap(
            tester,
            find.byKey(const ValueKey('pronunciation-record-action')),
          );
          await tester.runAsync(
            () async => Future<void>.delayed(const Duration(milliseconds: 20)),
          );
          await _pump(tester);
          await _tap(
            tester,
            find.byKey(const ValueKey('pronunciation-assess-action')),
          );
          expect(gateway.calls, 1);
          await PrivacyConsentService.setChoice(
            PrivacyPurpose.pronunciation,
            false,
          );
          if (retire) {
            PrivacyConsentService.retireForImport();
          }
          gateway.response!.complete(
            PronunciationAssessmentResult(
              assessmentId: gateway.assessmentId!,
              pronunciationScore: 90,
              accuracyScore: 90,
              fluencyScore: 90,
              completenessScore: 90,
            ),
          );
          await _pump(tester);
          await tester.runAsync(
            () async => Future<void>.delayed(const Duration(milliseconds: 20)),
          );
          await _pump(tester);
          expect(PrivacyConsentService.canSubmitPronunciation, isFalse);
          expect(Storage.pronunciationPassCount, retire ? 0 : 1);
          expect(gateway.calls, 1);
          expect(
            find.byKey(const ValueKey('pronunciation-replay-action')),
            findsOneWidget,
          );
          expect(tester.takeException(), isNull);
        } finally {
          if (!gateway.response!.isCompleted) {
            gateway.response!.complete(
              const PronunciationAssessmentResult(
                assessmentId: 'cleanup',
                pronunciationScore: 0,
                accuracyScore: 0,
                fluencyScore: 0,
                completenessScore: 0,
              ),
            );
          }
          await _pump(tester);
          await tester.pumpWidget(const SizedBox.shrink());
          await _pump(tester);
        }
      },
    );
  }
  testWidgets(
    'review1 explicit decline supersedes held grant after draft edits',
    (tester) async {
      native.rejectKey = 'kl_analytics_consent';
      native.commitBeforeFailure = true;
      native.release = Completer<void>();
      await _mount(
        tester,
        const Scaffold(body: ConsentInviteTrigger(child: SizedBox())),
      );
      final t = AppL10n.of(tester.element(find.byType(ConsentInviteTrigger)));
      try {
        await _tap(tester, find.widgetWithText(SoriButton, t.consentInviteYes));
        await _tap(tester, find.byType(Switch).at(0));
        await _tap(tester, find.byType(Switch).at(1));
        await _tap(tester, find.widgetWithText(SoriButton, t.consentInviteNo));
        final immediatelyDenied =
            !PrivacyConsentService.canCollectAnalytics &&
            !PrivacyConsentService.canCollectCrash;
        native.release!.complete();
        await _pump(tester);
        expect(immediatelyDenied, isTrue);
        expect(native.values['kl_analytics_consent'], isFalse);
        expect(native.values['kl_crash_consent'], isFalse);
      } finally {
        if (!native.release!.isCompleted) {
          native.release!.complete();
        }
        await _pump(tester);
        await tester.pumpWidget(const SizedBox.shrink());
        await _pump(tester);
      }
    },
  );
  for (final supersede in [false, true]) {
    testWidgets(
      'review1 late choice feedback follows current success supersede=$supersede',
      (tester) async {
        native.rejectKey = 'kl_analytics_consent';
        native.commitBeforeFailure = !supersede;
        native.release = Completer<void>();
        PrivacyConsentService.waitLimit = supersede
            ? const Duration(seconds: 5)
            : const Duration(milliseconds: 5);
        await _mount(
          tester,
          const Scaffold(
            body: PrivacyChoiceControl(
              purpose: PrivacyPurpose.analytics,
              title: 'Analytics',
              description: 'Optional',
              icon: Icons.insights,
            ),
          ),
        );
        try {
          await _tap(tester, find.byType(SwitchListTile));
          if (supersede) {
            await _tap(tester, find.byType(SwitchListTile));
            native.rejectKey = null;
          }
          native.release!.complete();
          await _pump(tester);
          expect(PrivacyConsentService.canCollectAnalytics, !supersede);
          expect(native.values['kl_analytics_consent'], !supersede);
          expect(find.byType(PrivacyChoiceFeedback), findsNothing);
        } finally {
          if (!native.release!.isCompleted) {
            native.release!.complete();
          }
          await _pump(tester);
          await tester.pumpWidget(const SizedBox.shrink());
          await _pump(tester);
        }
      },
    );
  }
  testWidgets('review1 mounted withdrawal retry uses fresh cache lifetime', (
    tester,
  ) async {
    await PrivacyConsentService.setAnalytics(true);
    native.rejectKey = 'kl_analytics_consent';
    await PrivacyConsentService.setAnalytics(false).catchError((Object _) {});
    await _mount(
      tester,
      const Scaffold(
        body: PrivacyChoiceControl(
          purpose: PrivacyPurpose.analytics,
          title: 'Analytics',
          description: 'Optional',
          icon: Icons.insights,
        ),
      ),
    );
    Storage.resetCachesAfterExternalWrite();
    await PrivacyChoiceStorage.refresh();
    await _pump(tester);
    native.rejectKey = null;
    final t = AppL10n.of(tester.element(find.byType(Scaffold)));
    await _tap(tester, find.widgetWithText(SoriButton, t.btnRetry));
    expect(native.values['kl_analytics_consent'], isFalse);
    expect(PrivacyConsentService.canCollectAnalytics, isFalse);
    expect(analytics.applied, isFalse);
    expect(find.byType(PrivacyChoiceFeedback), findsNothing);
  });
  for (final surface in ['invite', 'pronunciation', 'age']) {
    testWidgets(
      'review1 $surface late success clears failure without late navigation',
      (tester) async {
        if (surface == 'age') {
          await Storage.setBirthYear(0);
        }
        native.rejectKey = switch (surface) {
          'invite' => 'kl_analytics_consent',
          'age' => 'kl_birth_year',
          _ => 'kl_pronunciation_consent_v1',
        };
        native.commitBeforeFailure = true;
        native.release = Completer<void>();
        PrivacyConsentService.waitLimit = const Duration(milliseconds: 5);
        bool? accepted;
        final child = surface == 'invite'
            ? const ConsentInviteTrigger(child: SizedBox())
            : Builder(
                builder: (context) => TextButton(
                  onPressed: () async {
                    accepted = surface == 'age'
                        ? await ensureGyeAgeAllowed(context)
                        : await ensurePronunciationPrivacyConsent(context);
                  },
                  child: const Text('Open'),
                ),
              );
        await _mount(tester, Scaffold(body: child));
        final t = AppL10n.of(tester.element(find.byType(Scaffold)));
        try {
          if (surface != 'invite') {
            await _tap(tester, find.text('Open'));
          }
          if (surface == 'age') {
            await tester.enterText(
              find.byType(TextField),
              '${DateTime.now().year - 25}',
            );
          }
          final label = switch (surface) {
            'invite' => t.consentInviteYes,
            'age' => t.btnConfirm,
            _ => t.pronunciationConsentAccept,
          };
          await _tap(tester, find.widgetWithText(SoriButton, label));
          expect(find.byType(PrivacyChoiceFeedback), findsOneWidget);
          native.release!.complete();
          await _pump(tester);
          expect(find.byType(PrivacyChoiceFeedback), findsNothing);
          if (surface == 'invite') {
            expect(PrivacyConsentService.canCollectAnalytics, isTrue);
            expect(
              find.widgetWithText(SoriButton, t.consentInviteSave),
              findsOneWidget,
            );
            await _tap(
              tester,
              find.widgetWithText(SoriButton, t.consentInviteSave),
            );
            expect(
              find.widgetWithText(SoriButton, t.consentInviteSave),
              findsNothing,
            );
          } else {
            expect(accepted, isNull);
            expect(
              surface == 'age'
                  ? Storage.birthYear > 0
                  : PrivacyConsentService.canSubmitPronunciation,
              isTrue,
            );
            await _tap(tester, find.widgetWithText(SoriButton, label));
            expect(accepted, isTrue);
          }
        } finally {
          if (!native.release!.isCompleted) {
            native.release!.complete();
          }
          await _pump(tester);
          await tester.pumpWidget(const SizedBox.shrink());
          await _pump(tester);
        }
      },
    );
  }
  testWidgets(
    'review2 edited age draft cannot retain failed feedback for settled request',
    (tester) async {
      await PrivacyConsentService.setAnalytics(true);
      await PrivacyConsentService.setCrash(true);
      await Storage.setBirthYear(0);
      final submitted = DateTime.now().year - 25;
      final draft = DateTime.now().year - 30;
      native.rejectKey = 'kl_birth_year';
      native.commitBeforeFailure = true;
      native.release = Completer<void>();
      PrivacyConsentService.waitLimit = const Duration(milliseconds: 5);
      bool? accepted;
      await _mount(
        tester,
        Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () async {
                accepted = await ensureGyeAgeAllowed(context);
              },
              child: const Text('Open'),
            ),
          ),
        ),
      );
      final t = AppL10n.of(tester.element(find.byType(Scaffold)));
      try {
        await _tap(tester, find.text('Open'));
        await tester.enterText(find.byType(TextField), '$submitted');
        await _tap(tester, find.widgetWithText(SoriButton, t.btnConfirm));
        expect(find.text(t.privacyChoiceUnconfirmed), findsOneWidget);
        await tester.enterText(find.byType(TextField), '$draft');
        native.release!.complete();
        await _pump(tester);
        expect(Storage.birthYear, submitted);
        expect(native.values['kl_birth_year'], submitted);
        expect(PrivacyConsentService.canCollectAnalytics, isTrue);
        expect(PrivacyConsentService.canCollectCrash, isTrue);
        expect(analytics.applied, isTrue);
        expect(crash.applied, isTrue);
        expect(accepted, isNull);
        expect(
          tester.widget<TextField>(find.byType(TextField)).controller!.text,
          '$draft',
        );
        expect(find.text(t.privacyChoiceUnconfirmed), findsNothing);
        expect(find.byType(PrivacyChoiceFeedback), findsNothing);
      } finally {
        if (!native.release!.isCompleted) {
          native.release!.complete();
        }
        await _pump(tester);
        await tester.pumpWidget(const SizedBox.shrink());
        await _pump(tester);
      }
    },
  );
}

class _Recorder implements PronunciationRecorder {
  StreamController<Uint8List>? stream;
  @override
  Future<bool> requestPermission() async => true;
  @override
  Future<Stream<Uint8List>> startPcm16Stream() async {
    stream = StreamController<Uint8List>();
    stream!.add(Uint8List.fromList([1, 0, 2, 0]));
    return stream!.stream;
  }

  @override
  Future<void> stop() async {
    await stream?.close();
  }

  @override
  Future<void> dispose() async {
    await stream?.close();
  }
}

class _Playback implements PronunciationPlayback {
  @override
  Future<void> play(Uint8List pcm16) async {}
  @override
  Future<void> stop() async {}
  @override
  Future<void> dispose() async {}
}

class _Gateway implements PronunciationAssessmentGateway {
  int calls = 0;
  String? assessmentId;
  Completer<PronunciationAssessmentResult>? response;
  @override
  Future<PronunciationAssessmentResult> assess({
    required Uint8List pcm16,
    required String referenceText,
    required String assessmentId,
  }) async {
    calls++;
    this.assessmentId = assessmentId;
    if (response != null) {
      return response!.future;
    }
    throw const PronunciationAssessmentFailure(
      PronunciationAssessmentFailureCategory.unavailable,
      retryable: true,
    );
  }
}
