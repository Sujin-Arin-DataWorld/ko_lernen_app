import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ko_lernen_app/l10n/generated/app_localizations.dart';
import 'package:ko_lernen_app/models/learner_level.dart';
import 'package:ko_lernen_app/screens/onboarding_v2/onboarding_companion_screen.dart';
import 'package:ko_lernen_app/screens/onboarding_v2/onboarding_setup_screen.dart';
import 'package:ko_lernen_app/screens/onboarding_v2/onboarding_story_screen.dart';
import 'package:ko_lernen_app/screens/onboarding_v2/onboarding_v2_copy.dart';
import 'package:ko_lernen_app/theme.dart';
import 'package:ko_lernen_app/widgets/sori/tiger_video.dart';
import 'package:ko_lernen_app/widgets/sori/type_scale.dart';
import 'support/real_fonts.dart';
import 'support/sori_speech_stubs.dart';

// Opt-in rendered evidence, following the existing Sori Stage capture contract.
// Pass --dart-define=ONBOARDING_EVIDENCE_DIR=<absolute directory> --update-goldens.
const _evidenceDir = String.fromEnvironment('ONBOARDING_EVIDENCE_DIR');

void main() {
  setUpAll(() => loadSoriRealFonts(materialIcons: true));
  setUp(() {
    stubSoriSpeech();
    TigerStageVideo.videoReady = false;
  });
  for (final size in const [Size(390, 844), Size(720, 1152), Size(320, 640)]) {
    for (var step = 0; step < 7; step++) {
      testWidgets(
        'render step ${step + 1} at ${size.width}',
        skip: _evidenceDir.isEmpty,
        (tester) async {
          tester.view.devicePixelRatio = 1;
          tester.view.physicalSize = size;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          final copy = onboardingV2Copy(lookupAppL10n(const Locale('de')));
          final Widget screen;
          if (step == 0) {
            screen = OnboardingSetupScreen(
              copy: copy,
              selectedPurposeId: null,
              selectedLevelCode: null,
              onPurposeChanged: (_) {},
              onLevelChanged: (_) {},
              onContinue: (_) {},
            );
          } else if (step == 6) {
            screen = OnboardingCompanionScreen(
              copy: copy,
              selectedCompanionId: 'joy',
              onCompanionChanged: (_) {},
              onContinue: (_) {},
              mediaEnabled: false,
            );
          } else {
            screen = OnboardingStoryScreen(
              copy: copy,
              pageIndex: step - 1,
              selectedLevel: LearnerLevel.a1,
              beginner: true,
              onContinue: (_) {},
              onPrevious: (_) {},
            );
          }
          await tester.pumpWidget(
            MaterialApp(
              theme: AppTheme.light,
              locale: const Locale('de'),
              localizationsDelegates: AppL10n.localizationsDelegates,
              supportedLocales: AppL10n.supportedLocales,
              builder: (context, child) => MediaQuery(
                data: MediaQuery.of(context).copyWith(
                  padding: const EdgeInsets.only(top: 24, bottom: 24),
                  viewPadding: const EdgeInsets.only(top: 24, bottom: 24),
                  disableAnimations: true,
                  textScaler: TextScaler.linear(size.width == 320 ? 2 : 1),
                ),
                child: RepaintBoundary(
                  key: const ValueKey('capture'),
                  child: SoriTypeScale(child: child!),
                ),
              ),
              home: screen,
            ),
          );
          await tester.pumpAndSettle();
          final context = tester.element(find.byType(MaterialApp));
          final providers = tester
              .widgetList<Image>(find.byType(Image))
              .map((image) => image.image)
              .toList();
          await tester.runAsync(() async {
            await Future.wait([
              for (final provider in providers)
                precacheImage(provider, context),
            ]);
          });
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
          await expectLater(
            find.byKey(const ValueKey('capture')),
            matchesGoldenFile(
              Uri.file(
                '$_evidenceDir/native-${size.width.toInt()}-${step + 1}.png',
              ),
            ),
          );
        },
      );
    }
  }
}
