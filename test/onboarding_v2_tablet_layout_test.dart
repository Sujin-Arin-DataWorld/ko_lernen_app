import 'dart:ui' show Tristate;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ko_lernen_app/l10n/generated/app_localizations.dart';
import 'package:ko_lernen_app/screens/onboarding_v2/onboarding_character_media.dart';
import 'package:ko_lernen_app/screens/onboarding_v2/onboarding_companion_screen.dart';
import 'package:ko_lernen_app/screens/onboarding_v2/onboarding_v2_copy.dart';
import 'package:ko_lernen_app/screens/onboarding_v2/onboarding_v2_presentation.dart';
import 'package:ko_lernen_app/screens/onboarding_v2/onboarding_v2_shell.dart';
import 'package:ko_lernen_app/theme.dart';
import 'package:ko_lernen_app/widgets/sori/button.dart';

import 'support/real_fonts.dart';

const _safeInsets = EdgeInsets.only(top: 44, bottom: 34);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(loadSoriRealFonts);

  testWidgets(
    'tablet screenshot geometry stays vertical in portrait and splits only '
    'on a genuinely wide landscape',
    (tester) async {
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      for (final testCase in const <({Size size, double dpr, bool split})>[
        (size: Size(720, 1152), dpr: 2.5, split: false),
        (size: Size(1000, 720), dpr: 1, split: false),
        (size: Size(1152, 1152), dpr: 1, split: false),
        (size: Size(1152, 720), dpr: 1, split: true),
      ]) {
        _setViewport(tester, testCase.size, testCase.dpr);
        await tester.pumpWidget(_app(const _GeometryScreen()));
        await tester.pump();

        final titleRect = tester.getRect(
          find.byKey(const ValueKey('tablet-layout-title')),
        );
        final stageRect = tester.getRect(
          find.byKey(const ValueKey('tablet-layout-stage')),
        );
        final bodyRect = tester.getRect(
          find.byKey(const ValueKey('tablet-layout-body')),
        );
        final supportingText = tester.widget<Text>(
          find.text('Centered supporting text'),
        );
        final footer = find.byKey(const ValueKey('tablet-layout-continue'));
        final footerRect = tester.getRect(footer);
        final evidence = '${testCase.size} @${testCase.dpr}';

        expect(supportingText.textAlign, TextAlign.center, reason: evidence);
        expect(titleRect.bottom, lessThan(stageRect.top), reason: evidence);
        expect(stageRect.height, lessThanOrEqualTo(360.5), reason: evidence);
        expect(stageRect.width / stageRect.height, closeTo(1.6, 0.02));
        if (testCase.split) {
          expect(stageRect.left, lessThan(bodyRect.left), reason: evidence);
          expect(
            (stageRect.center.dy - bodyRect.center.dy).abs(),
            lessThan(1),
            reason: evidence,
          );
        } else {
          expect(stageRect.bottom, lessThan(bodyRect.top), reason: evidence);
        }

        _expectLabeled48DpButton(tester, footer);
        _expectInsideSafeViewport(tester, footer, testCase.size);
        expect(
          find.descendant(
            of: find.byKey(const ValueKey('tablet-layout-body-column')),
            matching: find.byType(Scrollable),
          ),
          findsNothing,
          reason: evidence,
        );
        expect(
          bodyRect.bottom,
          lessThanOrEqualTo(footerRect.top),
          reason: evidence,
        );
        _expectInsideSafeViewport(
          tester,
          find.byKey(const ValueKey('tablet-layout-body')),
          testCase.size,
        );
        _expectInsideSafeViewport(tester, footer, testCase.size);
        expect(tester.takeException(), isNull, reason: evidence);
      }
    },
  );

  testWidgets(
    'companion cards preserve visual order and the 30th rapid choice exactly',
    (tester) async {
      const size = Size(720, 1152);
      _setViewport(tester, size, 2.5);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final semantics = tester.ensureSemantics();

      final harnessKey = GlobalKey<_CompanionHarnessState>();
      await tester.pumpWidget(_app(_CompanionHarness(key: harnessKey)));
      await _pumpFinite(tester);
      final copy = onboardingV2Copy(lookupAppL10n(const Locale('en')));
      final taego = copy.companion.companion(OnboardingV2Ids.companionTaego);
      final joy = copy.companion.companion(OnboardingV2Ids.companionJoy);
      final taegoTile = find.byKey(
        const ValueKey('onboarding-v2-companion-taego'),
      );
      final joyTile = find.byKey(const ValueKey('onboarding-v2-companion-joy'));

      expect(
        tester.getRect(find.text(copy.companion.title)).bottom,
        lessThan(tester.getRect(taegoTile).top),
        reason: 'The heading must introduce the companion experience.',
      );
      expect(
        tester.widget<Text>(find.text(copy.companion.title)).textAlign,
        TextAlign.center,
      );
      expect(
        tester.getCenter(taegoTile).dx,
        lessThan(tester.getCenter(joyTile).dx),
      );
      for (final (tile, companion) in [(taegoTile, taego), (joyTile, joy)]) {
        final artwork = find.descendant(
          of: tile,
          matching: find.byType(OnboardingCharacterMedia),
        );
        final name = find.descendant(
          of: tile,
          matching: find.text(companion.name),
        );
        final rhythm = find.descendant(
          of: tile,
          matching: find.text(companion.rhythm),
        );
        final body = find.descendant(
          of: tile,
          matching: find.text(companion.body),
        );
        expect(
          tester.getRect(artwork).bottom,
          lessThan(tester.getRect(name).top),
        );
        expect(
          tester.getRect(name).bottom,
          lessThan(tester.getRect(rhythm).top),
        );
        expect(
          tester.getRect(rhythm).bottom,
          lessThan(tester.getRect(body).top),
        );
        expect(
          tester.getRect(body).bottom,
          lessThanOrEqualTo(tester.getRect(tile).bottom),
        );
        for (final textFinder in [name, rhythm, body]) {
          expect(tester.widget<Text>(textFinder).textAlign, TextAlign.center);
        }
        expect(tester.getSize(tile).height, greaterThanOrEqualTo(48));
      }

      for (var index = 0; index < 30; index++) {
        await tester.tap(index.isEven ? taegoTile : joyTile);
      }
      await tester.pump();

      expect(
        harnessKey.currentState?.selectedCompanionId,
        OnboardingV2Ids.companionJoy,
      );
      final taegoSemantics = tester
          .getSemantics(
            find.byKey(
              const ValueKey('onboarding-v2-companion-semantics-taego'),
            ),
          )
          .getSemanticsData();
      final joySemantics = tester
          .getSemantics(
            find.byKey(const ValueKey('onboarding-v2-companion-semantics-joy')),
          )
          .getSemanticsData();
      expect(taegoSemantics.flagsCollection.isSelected, Tristate.isFalse);
      expect(joySemantics.flagsCollection.isSelected, Tristate.isTrue);
      expect(joySemantics.flagsCollection.isButton, isTrue);

      final cta = find.byKey(
        const ValueKey('onboarding-v2-companion-continue'),
      );
      _expectLabeled48DpButton(tester, cta);
      _expectInsideSafeViewport(tester, cta, size);
      expect(find.byType(SingleChildScrollView), findsNothing);
      await tester.tap(cta);
      expect(
        harnessKey.currentState?.submittedCompanionId,
        OnboardingV2Ids.companionJoy,
      );
      expect(tester.takeException(), isNull);
      semantics.dispose();
    },
  );
}

class _GeometryScreen extends StatelessWidget {
  const _GeometryScreen();

  @override
  Widget build(BuildContext context) => OnboardingV2PageShell(
    brandLatin: 'Hangeul Sori',
    brandKorean: '한글소리',
    currentStep: 1,
    progressLabel: 'Page 1 of 7',
    heading: const OnboardingV2Heading(
      eyebrow: 'Start here',
      title: 'A clear starting point',
      body: 'Centered supporting text',
      titleKey: ValueKey('tablet-layout-title'),
    ),
    stageKey: const ValueKey('tablet-layout-stage'),
    stage: const ColoredBox(color: Colors.teal),
    bodyKey: const ValueKey('tablet-layout-body-column'),
    body: const ColoredBox(
      key: ValueKey('tablet-layout-body'),
      color: Colors.orange,
      child: Center(child: Text('Learning experience')),
    ),
    footer: SoriButton.filled(
      key: const ValueKey('tablet-layout-continue'),
      label: 'Continue',
      fullWidth: true,
      onTap: () {},
    ),
  );
}

class _CompanionHarness extends StatefulWidget {
  const _CompanionHarness({super.key});

  @override
  State<_CompanionHarness> createState() => _CompanionHarnessState();
}

class _CompanionHarnessState extends State<_CompanionHarness> {
  String? selectedCompanionId;
  String? submittedCompanionId;

  @override
  Widget build(BuildContext context) => OnboardingCompanionScreen(
    copy: onboardingV2Copy(AppL10n.of(context)),
    selectedCompanionId: selectedCompanionId,
    onCompanionChanged: (value) {
      setState(() => selectedCompanionId = value);
    },
    onContinue: (value) {
      setState(() => submittedCompanionId = value);
    },
  );
}

Widget _app(Widget home) => MaterialApp(
  debugShowCheckedModeBanner: false,
  theme: AppTheme.light,
  locale: const Locale('en'),
  supportedLocales: AppL10n.supportedLocales,
  localizationsDelegates: AppL10n.localizationsDelegates,
  builder: (context, child) => MediaQuery(
    data: MediaQuery.of(context).copyWith(
      padding: _safeInsets,
      viewPadding: _safeInsets,
      disableAnimations: true,
    ),
    child: child ?? const SizedBox.shrink(),
  ),
  home: home,
);

void _setViewport(WidgetTester tester, Size size, double dpr) {
  tester.view.physicalSize = Size(size.width * dpr, size.height * dpr);
  tester.view.devicePixelRatio = dpr;
}

void _expectLabeled48DpButton(WidgetTester tester, Finder finder) {
  final data = tester.getSemantics(finder).getSemanticsData();
  expect(data.flagsCollection.isButton, isTrue);
  expect(data.label.trim(), isNotEmpty);
  expect(tester.getSize(finder).width, greaterThanOrEqualTo(48));
  expect(tester.getSize(finder).height, greaterThanOrEqualTo(48));
}

void _expectInsideSafeViewport(WidgetTester tester, Finder finder, Size size) {
  final rect = tester.getRect(finder);
  expect(rect.left, greaterThanOrEqualTo(0));
  expect(rect.right, lessThanOrEqualTo(size.width));
  expect(rect.top, greaterThanOrEqualTo(_safeInsets.top));
  expect(rect.bottom, lessThanOrEqualTo(size.height - _safeInsets.bottom));
}

Future<void> _pumpFinite(WidgetTester tester) async {
  for (var frame = 0; frame < 8; frame++) {
    await tester.pump(const Duration(milliseconds: 10));
  }
}
