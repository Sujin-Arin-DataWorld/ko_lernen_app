import 'dart:ui' show PointerDeviceKind;

import 'package:flutter/material.dart';
import 'package:ko_lernen_app/l10n/generated/app_localizations.dart';
import 'package:ko_lernen_app/models/learner_level.dart';
import 'package:ko_lernen_app/screens/onboarding_v2/onboarding_companion_screen.dart';
import 'package:ko_lernen_app/screens/onboarding_v2/onboarding_setup_screen.dart';
import 'package:ko_lernen_app/screens/onboarding_v2/onboarding_story_screen.dart';
import 'package:ko_lernen_app/screens/onboarding_v2/onboarding_v2_copy.dart';
import 'package:ko_lernen_app/widgets/sori/c_gallery/c_materials.dart';

/// Runs the actual app screen widgets. All review choices stay in memory; the
/// durable app journey keeps using FirstRunCoordinator and its commit gateway.
class COnboardingPreviewApp extends StatefulWidget {
  const COnboardingPreviewApp({super.key});
  @override
  State<COnboardingPreviewApp> createState() => _COnboardingPreviewAppState();
}

class _COnboardingPreviewAppState extends State<COnboardingPreviewApp> {
  late int step =
      ((int.tryParse(Uri.base.queryParameters['step'] ?? '') ?? 1) - 1).clamp(
        0,
        6,
      );
  late String? level = LearnerLevel.fromCode(
    Uri.base.queryParameters['level'],
  )?.display;
  late bool beginner = Uri.base.queryParameters['beginner'] == '1';
  String? purpose;
  String? companion;
  bool finished = false;

  @override
  void initState() {
    super.initState();
    if (beginner) level = 'A1';
  }

  @override
  Widget build(BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner: false,
    locale: Locale(Uri.base.queryParameters['lang'] == 'en' ? 'en' : 'de'),
    supportedLocales: AppL10n.supportedLocales,
    localizationsDelegates: AppL10n.localizationsDelegates,
    scrollBehavior: const _CIntroScrollBehavior(),
    theme: ThemeData(
      useMaterial3: true,
      fontFamily: 'Paperlogy',
      colorScheme: ColorScheme.fromSeed(seedColor: CPalette.jade),
    ),
    builder: (context, child) => MediaQuery(
      data: MediaQuery.of(context).copyWith(
        textScaler: TextScaler.linear(
          double.tryParse(Uri.base.queryParameters['scale'] ?? '') ?? 1,
        ),
        disableAnimations: Uri.base.queryParameters['reduce'] == '1',
      ),
      child: child!,
    ),
    home: Builder(
      builder: (context) {
        final t = AppL10n.of(context);
        final copy = onboardingV2Copy(t);
        if (finished) {
          return Scaffold(
            backgroundColor: CPalette.deepJade,
            body: SafeArea(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: CMaterialAction(
                    label: t.onboardingV2Next,
                    onTap: () => setState(() {
                      finished = false;
                      step = 0;
                    }),
                  ),
                ),
              ),
            ),
          );
        }
        if (step == 0) {
          return OnboardingSetupScreen(
            copy: copy,
            selectedPurposeId: purpose,
            selectedLevelCode: level,
            beginnerSelected: beginner,
            onBeginnerSelected: () => setState(() {
              beginner = true;
              level = 'A1';
            }),
            onLevelChanged: (value) => setState(() {
              beginner = false;
              level = value;
            }),
            onPurposeChanged: (value) => setState(() => purpose = value),
            onContinue: (_) => setState(() => step = 1),
          );
        }
        if (step < 6) {
          return OnboardingStoryScreen(
            key: ValueKey(step),
            copy: copy,
            pageIndex: step - 1,
            selectedLevel: LearnerLevel.fromCode(level),
            beginner: beginner,
            onContinue: (_) => setState(() => step++),
            onPrevious: (_) => setState(() => step--),
          );
        }
        return OnboardingCompanionScreen(
          copy: copy,
          selectedCompanionId: companion,
          onCompanionChanged: (value) => setState(() => companion = value),
          onContinue: (_) => setState(() => finished = true),
          onBack: () => setState(() => step = 5),
        );
      },
    ),
  );
}

class _CIntroScrollBehavior extends MaterialScrollBehavior {
  const _CIntroScrollBehavior();
  @override
  Set<PointerDeviceKind> get dragDevices => {
    PointerDeviceKind.touch,
    PointerDeviceKind.mouse,
    PointerDeviceKind.trackpad,
    PointerDeviceKind.stylus,
    PointerDeviceKind.invertedStylus,
  };
}
