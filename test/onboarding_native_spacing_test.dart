import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ko_lernen_app/l10n/generated/app_localizations.dart';
import 'package:ko_lernen_app/models/learner_level.dart';
import 'package:ko_lernen_app/screens/onboarding_v2/c_intro_art.dart';
import 'package:ko_lernen_app/screens/onboarding_v2/onboarding_companion_screen.dart';
import 'package:ko_lernen_app/screens/onboarding_v2/onboarding_journey_scenes.dart';
import 'package:ko_lernen_app/screens/onboarding_v2/onboarding_story_screen.dart';
import 'package:ko_lernen_app/screens/onboarding_v2/onboarding_v2_copy.dart';
import 'package:ko_lernen_app/theme.dart';

import 'support/einleitung_capture_assets.dart';
import 'support/sori_speech_stubs.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(loadEinleitungFonts);
  setUp(stubSoriSpeech);
  for (final language in ['de', 'en']) {
    for (final size in [const Size(320, 640), const Size(393, 873)]) {
      testWidgets(
        '$language $size sound keeps art beside its heading and action',
        (tester) async {
          final t = lookupAppL10n(Locale(language));
          await _show(
            tester,
            language,
            size,
            1,
            OnboardingStoryScreen(
              copy: onboardingV2Copy(t),
              pageIndex: 1,
              onContinue: (_) {},
              onPrevious: (_) {},
            ),
          );
          final preview = find.byKey(const ValueKey('c-onboarding-preview-3'));
          final artwork = find
              .descendant(of: preview, matching: find.byType(ClipRect))
              .first;
          final artRect = _transformedRect(tester, artwork);
          final title = tester.getRect(find.text(t.onboardingCSoundTitle));
          final listen = tester.getRect(
            find.byKey(const ValueKey('c-onboarding-original-listen')),
          );
          expect(artRect.top - title.bottom, inInclusiveRange(0, 8));
          expect(listen.top - artRect.bottom, inInclusiveRange(4, 8));
          _fits(tester, size, 'onboarding-v2-story-next');
        },
      );

      testWidgets(
        '$language $size companions keep native portrait and role gaps',
        (tester) async {
          final t = lookupAppL10n(Locale(language));
          await _show(
            tester,
            language,
            size,
            1,
            OnboardingCompanionScreen(
              copy: onboardingV2Copy(t),
              selectedCompanionId: 'taego',
              onCompanionChanged: (_) {},
              onContinue: (_) {},
              onBack: () {},
            ),
          );
          for (final id in ['taego', 'joy']) {
            final card = find.byKey(ValueKey('onboarding-v2-companion-$id'));
            final art = find.descendant(
              of: card,
              matching: find.byWidgetPredicate(
                (widget) => widget is CIntroArt && widget.name == '$id-close',
              ),
            );
            final raw = find.descendant(
              of: art,
              matching: find.byType(RawImage),
            );
            final render = tester.renderObject<RenderImage>(raw);
            final image = render.image!;
            final fitted = applyBoxFit(
              BoxFit.contain,
              Size(image.width.toDouble(), image.height.toDouble()),
              render.size,
            );
            final painted = MatrixUtils.transformRect(
              render.getTransformTo(null),
              Alignment.center.inscribe(
                fitted.destination,
                Offset.zero & render.size,
              ),
            );
            final name = tester.getRect(
              find.descendant(
                of: card,
                matching: find.text(id == 'taego' ? 'Taego' : 'Joy'),
              ),
            );
            final role = tester.getRect(
              find.descendant(
                of: card,
                matching: find.text(
                  id == 'taego' ? t.onboardingCTaegoRole : t.onboardingCJoyRole,
                ),
              ),
            );
            expect(name.top - painted.bottom, inInclusiveRange(0, 8));
            expect(role.top - name.bottom, inInclusiveRange(0, 8));
          }
          _fits(tester, size, 'onboarding-v2-companion-continue');
        },
      );

      testWidgets(
        '$language $size 200% speaking groups its microphone and model',
        (tester) async {
          final t = lookupAppL10n(Locale(language));
          await _show(
            tester,
            language,
            size,
            2,
            OnboardingStoryScreen(
              copy: onboardingV2Copy(t),
              pageIndex: 1,
              selectedLevel: LearnerLevel.a1,
              onContinue: (_) {},
              onPrevious: (_) {},
            ),
          );
          for (final key in [
            'c-onboarding-preview-3',
            'demo-area-0',
            'demo-skill-1',
            'demo-own-turn',
          ]) {
            final action = find.byKey(ValueKey(key));
            await tester.ensureVisible(action);
            await tester.pumpAndSettle();
            await tester.tap(action);
            await tester.pumpAndSettle();
          }
          final microphone = tester.getRect(
            find.byKey(const ValueKey('demo-speaking-microphone')),
          );
          final model = find.byKey(const ValueKey('demo-speaking-model'));
          expect(tester.getRect(model).top - microphone.bottom, closeTo(8, .1));
          await tester.ensureVisible(model);
          await tester.pumpAndSettle();
          expect(tester.getSize(model).height, greaterThanOrEqualTo(48));
          expect(model.hitTestable(), findsOneWidget);
          await tester.tap(model);
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
        },
      );
    }
    testWidgets(
      '$language book groups its complete artwork and native example',
      (tester) async {
        final t = lookupAppL10n(Locale(language));
        await _show(
          tester,
          language,
          const Size(393, 873),
          1,
          OnboardingStoryScreen(
            copy: onboardingV2Copy(t),
            pageIndex: 3,
            selectedLevel: LearnerLevel.a1,
            onContinue: (_) {},
            onPrevious: (_) {},
          ),
        );
        for (final key in [
          'c-onboarding-preview-5',
          'onboarding-v3-book-action',
        ]) {
          final action = find.byKey(ValueKey(key));
          await tester.ensureVisible(action);
          await tester.pumpAndSettle();
          await tester.tap(action);
          await tester.pumpAndSettle();
        }
        await settleEinleitungCaptureAssets(tester);
        final artwork = find.byKey(
          const ValueKey('onboarding-v3-book-extract'),
        );
        final raw = find.descendant(
          of: artwork,
          matching: find.byType(RawImage),
        );
        final render = tester.renderObject<RenderImage>(raw);
        final image = render.image!;
        final fitted = applyBoxFit(
          BoxFit.contain,
          Size(image.width.toDouble(), image.height.toDouble()),
          render.size,
        );
        final painted = MatrixUtils.transformRect(
          render.getTransformTo(null),
          Alignment.center.inscribe(
            fitted.destination,
            Offset.zero & render.size,
          ),
        );
        final reading = find
            .descendant(
              of: find.byType(OnboardingBookScene),
              matching: find.byType(JourneyReading),
            )
            .first;
        final text = find.descendant(
          of: reading,
          matching: find.text(tester.widget<JourneyReading>(reading).text),
        );
        expect(
          tester.getRect(text).top - painted.bottom,
          inInclusiveRange(4, 10),
        );
        final save = find.byKey(const ValueKey('onboarding-v3-book-action'));
        expect(tester.getSize(save).height, greaterThanOrEqualTo(48));
        expect(save.hitTestable(), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  }
}

Future<void> _show(
  WidgetTester tester,
  String language,
  Size size,
  double scale,
  Widget screen,
) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    MaterialApp(
      locale: Locale(language),
      theme: AppTheme.light,
      supportedLocales: AppL10n.supportedLocales,
      localizationsDelegates: AppL10n.localizationsDelegates,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(
          padding: const EdgeInsets.symmetric(vertical: 24),
          viewPadding: const EdgeInsets.symmetric(vertical: 24),
          textScaler: TextScaler.linear(scale),
          disableAnimations: true,
        ),
        child: child!,
      ),
      home: screen,
    ),
  );
  await tester.pumpAndSettle();
  await settleEinleitungCaptureAssets(tester);
  expect(tester.takeException(), isNull);
}

Rect _transformedRect(WidgetTester tester, Finder finder) {
  final render = tester.renderObject<RenderBox>(finder);
  return MatrixUtils.transformRect(
    render.getTransformTo(null),
    Offset.zero & render.size,
  );
}

void _fits(WidgetTester tester, Size size, String actionKey) {
  final action = find.byKey(ValueKey(actionKey));
  final rect = tester.getRect(action);
  expect(rect.height, greaterThanOrEqualTo(48));
  expect(rect.bottom, lessThanOrEqualTo(size.height - 24));
  expect(action.hitTestable(), findsOneWidget);
  expect(find.byType(Scrollable), findsNothing);
  expect(tester.takeException(), isNull);
}
