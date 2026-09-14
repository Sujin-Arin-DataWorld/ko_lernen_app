import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ko_lernen_app/features/onboarding_v2/curriculum_evidence_projector.dart';
import 'package:ko_lernen_app/l10n/generated/app_localizations.dart';
import 'package:ko_lernen_app/models/learner_level.dart';
import 'package:ko_lernen_app/screens/onboarding_v2/onboarding_story_screen.dart';
import 'package:ko_lernen_app/screens/onboarding_v2/onboarding_v2_copy.dart';
import 'package:ko_lernen_app/theme.dart';
import 'support/real_fonts.dart';

void main() {
  setUpAll(() => loadSoriRealFonts(materialIcons: true));
  testWidgets('path presents the validated official source names', (
    tester,
  ) async {
    await _show(
      tester,
      evidence: OnboardingCurriculumEvidenceProjector.project,
    );
    await tester.tap(find.text('The structure'));
    await tester.pumpAndSettle();
    for (final reference
        in OnboardingCurriculumEvidenceProjector.project()!.references) {
      expect(find.text(reference.documentName), findsOneWidget);
      final link = find.ancestor(
        of: find.text(reference.documentName),
        matching: find.byType(TextButton),
      );
      expect(tester.widget<TextButton>(link).onPressed, isNotNull);
    }
    expect(
      find.textContaining('A1 to C2 identify the learning stages in this app.'),
      findsOneWidget,
    );
    await tester.tap(find.text(lookupAppL10n(const Locale('en')).btnClose));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('onboarding-v2-story-next')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });
  testWidgets(
    'a rejected curriculum projection cannot expose official source links',
    (tester) async {
      await _show(tester, evidence: () => null);
      await tester.tap(find.text('The structure'));
      await tester.pumpAndSettle();
      for (final reference
          in OnboardingCurriculumEvidenceProjector.project()!.references) {
        expect(find.text(reference.documentName), findsNothing);
      }
      expect(find.textContaining('European reference framework'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'advanced learners can preview later chapters without unlocking them',
    (tester) async {
      await _show(
        tester,
        level: LearnerLevel.c1,
        evidence: OnboardingCurriculumEvidenceProjector.project,
      );
      expect(find.text('C1'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('onboarding-v3-path-1')));
      await tester.pumpAndSettle();
      expect(find.textContaining('certainty'), findsOneWidget);
      await tester.tap(
        find
            .byTooltip(lookupAppL10n(const Locale('en')).onboardingDemoNext)
            .last,
      );
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('onboarding-v3-path-5')),
        findsOneWidget,
      );
      await tester.tap(find.byKey(const ValueKey('onboarding-v3-path-5')));
      await tester.pumpAndSettle();
      expect(find.textContaining('appropriate tone'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}

Future<void> _show(
  WidgetTester tester, {
  required OnboardingCurriculumEvidenceProjection? Function() evidence,
  LearnerLevel level = LearnerLevel.a1,
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = const Size(720, 1152);
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    MaterialApp(
      key: UniqueKey(),
      theme: AppTheme.light,
      locale: const Locale('en'),
      localizationsDelegates: AppL10n.localizationsDelegates,
      supportedLocales: AppL10n.supportedLocales,
      home: OnboardingStoryScreen(
        copy: onboardingV2Copy(lookupAppL10n(const Locale('en'))),
        pageIndex: 0,
        selectedLevel: level,
        onContinue: (_) {},
        onPrevious: (_) {},
        curriculumEvidenceProjector: evidence,
      ),
    ),
  );
  await tester.pumpAndSettle();
}
