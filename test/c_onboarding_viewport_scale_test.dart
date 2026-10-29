import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ko_lernen_app/l10n/generated/app_localizations.dart';
import 'package:ko_lernen_app/models/learner_level.dart';
import 'package:ko_lernen_app/screens/onboarding_v2/c_intro_reference_setup.dart';
import 'package:ko_lernen_app/screens/onboarding_v2/onboarding_setup_screen.dart';
import 'package:ko_lernen_app/screens/onboarding_v2/onboarding_story_screen.dart';
import 'package:ko_lernen_app/screens/onboarding_v2/onboarding_v2_copy.dart';
import 'package:ko_lernen_app/screens/onboarding_v2/onboarding_v2_presentation.dart';
import 'package:ko_lernen_app/screens/onboarding_v2/welcome_screen.dart';
import 'package:ko_lernen_app/theme.dart';
import 'package:ko_lernen_app/widgets/sori/type_scale.dart';

import 'support/einleitung_capture_assets.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(loadEinleitungFonts);

  test('viewport rebasing preserves a nonlinear custom scaler unchanged', () {
    const base = _NonlinearScaler();
    final window = SoriComfortTextScaler(base, 1.1);
    final pane = SoriTypeScale.forViewport(window, 402);
    expect(pane, same(base));
    for (final size in [16.0, 40.0]) {
      expect(pane.scale(size), base.scale(size));
      final widerPane = SoriTypeScale.forViewport(window, 720);
      expect(widerPane.scale(size), closeTo(base.scale(size) * 1.1, .0001));
      expect(
        SoriTypeScale.forViewport(widerPane, 402).scale(size),
        base.scale(size),
      );
    }
  });

  for (final scaler in <TextScaler>[
    TextScaler.noScaling,
    const TextScaler.linear(1.3),
    const TextScaler.linear(2),
    const _NonlinearScaler(),
  ]) {
    final reference = scaler == TextScaler.noScaling;
    testWidgets('desktop pane and level modal retain base scaler $scaler', (
      tester,
    ) async {
      final t = lookupAppL10n(const Locale('de'));
      String? selected;
      await _pumpDesktop(
        tester,
        scaler,
        OnboardingSetupScreen(
          copy: onboardingV2Copy(t),
          selectedPurposeId: OnboardingV2Ids.purposeLifeTravel,
          selectedLevelCode: 'A2',
          onPurposeChanged: (_) {},
          onLevelChanged: (value) => selected = value,
          onContinue: (_) {},
        ),
      );
      _expectWindowComfort(tester, scaler);
      expect(
        find.byType(IntroReferenceSetup),
        reference ? findsOneWidget : findsNothing,
      );
      _expectBaseScale(tester, find.text(t.onboardingCStartLevel), scaler);

      final change = find.byKey(const ValueKey('c-onboarding-change-level'));
      await tester.ensureVisible(change);
      await tester.tap(change);
      await tester.pumpAndSettle();
      expect(find.byType(BottomSheet), findsOneWidget);
      expect(
        find.byType(IntroReferenceLevelSheet),
        reference ? findsOneWidget : findsNothing,
      );
      _expectBaseScale(tester, find.text(t.introChooseLevel), scaler);
      final level = find.byKey(const ValueKey('onboarding-v2-level-B2'));
      await tester.ensureVisible(level);
      await tester.tap(level);
      await tester.pumpAndSettle();
      final apply = find.byKey(const ValueKey('intro-level-apply'));
      await tester.ensureVisible(apply);
      await tester.tap(apply);
      await tester.pumpAndSettle();
      expect(selected, 'B2');
      expect(find.byType(BottomSheet), findsNothing);
      _expectWindowComfort(tester, scaler);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('desktop 130% sound title displays its full natural height', (
    tester,
  ) async {
    final t = lookupAppL10n(const Locale('de'));
    const scaler = TextScaler.linear(1.3);
    await _pumpDesktop(
      tester,
      scaler,
      OnboardingStoryScreen(
        copy: onboardingV2Copy(t),
        pageIndex: 1,
        selectedLevel: LearnerLevel.a2,
        onContinue: (_) {},
        onPrevious: (_) {},
      ),
    );
    final title = find.text(t.onboardingCSoundTitle);
    _expectBaseScale(tester, title, scaler);
    final paragraph = tester.renderObject<RenderParagraph>(title);
    final natural = TextPainter(
      text: paragraph.text,
      textDirection: paragraph.textDirection,
      textScaler: paragraph.textScaler,
      locale: paragraph.locale,
      strutStyle: paragraph.strutStyle,
      textHeightBehavior: paragraph.textHeightBehavior,
    )..layout(maxWidth: paragraph.size.width);
    expect(paragraph.size.height, greaterThanOrEqualTo(natural.height - .01));
    natural.dispose();
    expect(tester.takeException(), isNull);
  });

  for (final scale in [1.0, 1.3, 2.0]) {
    testWidgets('desktop Welcome preserves real user scale $scale', (
      tester,
    ) async {
      final scaler = TextScaler.linear(scale);
      var starts = 0;
      await _pumpDesktop(
        tester,
        scaler,
        WelcomeScreen(onStart: () async => starts++, onLater: () {}),
      );
      expect(
        find.byKey(const ValueKey('welcome-reference-scene')),
        scale == 1 ? findsOneWidget : findsNothing,
      );
      final t = lookupAppL10n(const Locale('de'));
      _expectBaseScale(tester, find.text(t.welcomeTitle), scaler);
      _expectWindowComfort(tester, scaler);
      final start = find.byKey(const ValueKey('welcome-start'));
      await tester.ensureVisible(start);
      await tester.tap(start);
      await tester.pumpAndSettle();
      expect(starts, 1);
      expect(tester.takeException(), isNull);
    });
  }
}

Future<void> _pumpDesktop(
  WidgetTester tester,
  TextScaler scaler,
  Widget home,
) async {
  tester.view.physicalSize = const Size(1280, 720);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light,
      locale: const Locale('de'),
      supportedLocales: AppL10n.supportedLocales,
      localizationsDelegates: AppL10n.localizationsDelegates,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(
          context,
        ).copyWith(textScaler: scaler, disableAnimations: true),
        child: SoriTypeScale(child: child!),
      ),
      home: home,
    ),
  );
  await tester.pumpAndSettle();
}

void _expectBaseScale(WidgetTester tester, Finder finder, TextScaler expected) {
  final actual = MediaQuery.textScalerOf(tester.element(finder));
  for (final size in [16.0, 40.0]) {
    expect(actual.scale(size), closeTo(expected.scale(size), .0001));
  }
}

void _expectWindowComfort(WidgetTester tester, TextScaler expected) {
  final actual = MediaQuery.textScalerOf(
    tester.element(find.byType(Navigator).first),
  );
  for (final size in [16.0, 40.0]) {
    expect(actual.scale(size), closeTo(expected.scale(size) * 1.1, .0001));
  }
}

class _NonlinearScaler extends TextScaler {
  const _NonlinearScaler();
  @override
  double scale(double fontSize) => fontSize * 1.3 + fontSize * fontSize / 1000;
  @override
  double get textScaleFactor => scale(14) / 14;
}
