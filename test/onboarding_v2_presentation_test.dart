import 'dart:ui' show Tristate;
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart' show LocaleStringAttribute;
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ko_lernen_app/l10n/generated/app_localizations.dart';
import 'package:ko_lernen_app/models/learner_level.dart';
import 'package:ko_lernen_app/screens/onboarding_v2/onboarding_companion_screen.dart';
import 'package:ko_lernen_app/screens/onboarding_v2/onboarding_games_demo.dart';
import 'package:ko_lernen_app/screens/onboarding_v2/onboarding_journey_scenes.dart';
import 'package:ko_lernen_app/screens/onboarding_v2/onboarding_learning_demo.dart';
import 'package:ko_lernen_app/screens/onboarding_v2/onboarding_setup_screen.dart';
import 'package:ko_lernen_app/screens/onboarding_v2/onboarding_story_screen.dart';
import 'package:ko_lernen_app/screens/onboarding_v2/onboarding_v2_copy.dart';
import 'package:ko_lernen_app/screens/onboarding_v2/onboarding_v2_presentation.dart';
import 'package:ko_lernen_app/screens/onboarding_v2/onboarding_v2_shell.dart';
import 'package:ko_lernen_app/theme.dart';
import 'package:ko_lernen_app/widgets/sori/button.dart';
import 'support/real_fonts.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(loadSoriRealFonts);
  setUp(() => SharedPreferences.setMockInitialValues({}));
  const ids = [
    OnboardingV2Ids.storyPersonalCurriculum,
    OnboardingV2Ids.storyLearn,
    OnboardingV2Ids.storyGamesAndRewards,
    OnboardingV2Ids.storySaveAndReview,
    OnboardingV2Ids.storyHeritageJourney,
  ];
  const scenes = [
    OnboardingPathScene,
    OnboardingLearningDemo,
    OnboardingGamesDemo,
    OnboardingBookScene,
    OnboardingHanokScene,
  ];
  for (var index = 0; index < ids.length; index++) {
    testWidgets(
      'restored story page ${ids[index]} exposes its exact navigation and progress',
      (tester) async {
        final semantics = tester.ensureSemantics();
        String? next;
        String? back;
        await _pump(
          tester,
          Builder(
            builder: (context) => OnboardingStoryScreen(
              copy: onboardingV2Copy(AppL10n.of(context)),
              pageIndex: index,
              selectedLevel: LearnerLevel.b2,
              onContinue: (id) => next = id,
              onPrevious: (id) => back = id,
            ),
          ),
        );
        expect(find.byType(scenes[index]), findsOneWidget);
        final progress = tester
            .getSemantics(
              find.byKey(const ValueKey('onboarding-v2-story-progress')),
            )
            .getSemanticsData();
        expect(progress.label, 'Page ${index + 2} of 7');
        final title = find.byKey(const ValueKey('onboarding-v2-story-title'));
        expect(
          tester
              .getSemantics(title)
              .getSemanticsData()
              .flagsCollection
              .isHeader,
          isTrue,
        );
        expect(find.text('Skip'), findsNothing);
        final nextButton = find.byKey(
          const ValueKey('onboarding-v2-story-next'),
        );
        expect(tester.getSize(nextButton).height, greaterThanOrEqualTo(48));
        await tester.tap(
          find.byKey(const ValueKey('onboarding-v2-story-back')),
        );
        expect(back, ids[index]);
        await tester.tap(nextButton);
        expect(next, ids[index]);
        expect(
          find.byType(scenes[index]),
          findsOneWidget,
          reason:
              'Presentation emits intent; the coordinator owns advancement.',
        );
        expect(tester.takeException(), isNull);
        semantics.dispose();
      },
    );
  }

  testWidgets('New and A1 remain distinct drafts and purpose is optional', (
    tester,
  ) async {
    OnboardingSetupSelection? submitted;
    final key = GlobalKey<_SetupState>();
    await _pump(
      tester,
      _Setup(key: key, onSubmitted: (value) => submitted = value),
    );
    expect(_button(tester, 'onboarding-v2-setup-continue').onTap, isNull);
    final newChoice = find.byKey(const ValueKey('onboarding-v3-new'));
    await _focusWithKeyboard(tester, newChoice);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();
    expect(key.currentState!.beginner, isTrue);
    expect(key.currentState!.level, 'A1');
    await tester.tap(
      find.byKey(const ValueKey('onboarding-v2-setup-continue')),
    );
    expect(submitted?.purposeId, isNull);
    expect(submitted?.levelCode, 'A1');
    await tester.tap(find.byKey(const ValueKey('onboarding-v3-returning')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('onboarding-v2-level-A1')));
    await tester.pump();
    expect(key.currentState!.beginner, isFalse);
    expect(key.currentState!.level, 'A1');
    expect(
      find.byKey(const ValueKey('onboarding-v2-purpose-picker')),
      findsNothing,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'book capture and save are a resettable preview with no learner writes',
    (tester) async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('earned_xp', 17);
      final before = {for (final key in prefs.getKeys()) key: prefs.get(key)};
      Widget book() => Builder(
        builder: (context) => OnboardingStoryScreen(
          copy: onboardingV2Copy(AppL10n.of(context)),
          pageIndex: 3,
          selectedLevel: LearnerLevel.b2,
          onContinue: (_) {},
          onPrevious: (_) {},
        ),
      );
      await _pump(tester, book());
      final action = find.byKey(const ValueKey('onboarding-v3-book-action'));
      final t = AppL10n.of(tester.element(find.byType(OnboardingBookScene)));
      expect(find.text(t.onboardingJourneySampleOnly), findsOneWidget);
      await tester.tap(action);
      await tester.pump();
      expect(find.text(t.onboardingJourneyFromBook), findsOneWidget);
      await tester.tap(action);
      await tester.pump();
      expect(find.text(t.onboardingJourneySaved), findsOneWidget);
      expect({for (final key in prefs.getKeys()) key: prefs.get(key)}, before);
      await tester.pumpWidget(const SizedBox.shrink());
      await _pump(tester, book());
      expect(find.text(t.onboardingJourneyTakePhoto), findsOneWidget);
      expect(find.text(t.onboardingJourneySaved), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'path source details restore keyboard focus without changing pages',
    (tester) async {
      await _pump(
        tester,
        Builder(
          builder: (context) => OnboardingStoryScreen(
            copy: onboardingV2Copy(AppL10n.of(context)),
            pageIndex: 0,
            selectedLevel: LearnerLevel.a2,
            onContinue: (_) {},
            onPrevious: (_) {},
          ),
        ),
      );
      final details = find.byType(OnboardingV2DetailsButton);
      await _focusWithKeyboard(tester, details);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await _finite(tester);
      final t = AppL10n.of(tester.element(find.byType(OnboardingStoryScreen)));
      expect(find.text(t.onboardingJourneyMethodBody), findsOneWidget);
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await _finite(tester);
      expect(find.text(t.onboardingJourneyMethodBody), findsNothing);
      expect(_withinFocus(details), isTrue);
      expect(find.byType(OnboardingPathScene), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'companion is mandatory and its final CTA does not wait for video',
    (tester) async {
      final semantics = tester.ensureSemantics();
      String? submitted;
      await _pump(
        tester,
        _Companion(onSubmitted: (value) => submitted = value),
      );
      expect(_button(tester, 'onboarding-v2-companion-continue').onTap, isNull);
      expect(find.text('None'), findsNothing);
      expect(find.text('Skip'), findsNothing);
      final choice = find.byKey(const ValueKey('onboarding-v2-companion-joy'));
      await tester.scrollUntilVisible(
        choice,
        300,
        scrollable: find.byType(Scrollable).last,
      );
      await tester.pump();
      await tester.tap(choice);
      await tester.pump();
      final data = tester
          .getSemantics(
            find.byKey(const ValueKey('onboarding-v2-companion-semantics-joy')),
          )
          .getSemanticsData();
      expect(data.flagsCollection.isSelected, Tristate.isTrue);
      expect(
        data.attributedLabel.attributes.whereType<LocaleStringAttribute>().map(
          (attribute) => attribute.locale.languageCode,
        ),
        contains('ko'),
      );
      expect(
        _button(tester, 'onboarding-v2-companion-continue').onTap,
        isNotNull,
      );
      await tester.tap(
        find.byKey(const ValueKey('onboarding-v2-companion-continue')),
      );
      expect(submitted, OnboardingV2Ids.companionJoy);
      expect(find.byType(OnboardingCompanionConfirmationScreen), findsNothing);
      expect(tester.takeException(), isNull);
      semantics.dispose();
    },
  );
}

Future<void> _pump(WidgetTester tester, Widget child) async {
  tester.view.physicalSize = const Size(720, 1152);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light,
      locale: const Locale('en'),
      supportedLocales: AppL10n.supportedLocales,
      localizationsDelegates: AppL10n.localizationsDelegates,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(disableAnimations: true),
        child: child!,
      ),
      home: child,
    ),
  );
  await _finite(tester);
}

Future<void> _finite(WidgetTester tester) async {
  for (var i = 0; i < 20; i++) {
    await tester.pump(const Duration(milliseconds: 20));
  }
}

SoriButton _button(WidgetTester tester, String key) =>
    tester.widget<SoriButton>(find.byKey(ValueKey(key)));
Future<void> _focusWithKeyboard(WidgetTester tester, Finder target) async {
  for (var i = 0; i < 40; i++) {
    if (_withinFocus(target)) {
      return;
    }
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
  }
  fail('Keyboard traversal did not reach target.');
}

bool _withinFocus(Finder target) {
  final elements = target.evaluate();
  final context = FocusManager.instance.primaryFocus?.context;
  if (elements.length != 1 || context == null) {
    return false;
  }
  if (identical(context, elements.single)) {
    return true;
  }
  var within = false;
  context.visitAncestorElements((ancestor) {
    if (identical(ancestor, elements.single)) {
      within = true;
      return false;
    }
    return true;
  });
  return within;
}

class _Setup extends StatefulWidget {
  const _Setup({super.key, required this.onSubmitted});
  final ValueChanged<OnboardingSetupSelection> onSubmitted;
  @override
  State<_Setup> createState() => _SetupState();
}

class _SetupState extends State<_Setup> {
  String? level;
  bool beginner = false;
  @override
  Widget build(BuildContext context) => OnboardingSetupScreen(
    copy: onboardingV2Copy(AppL10n.of(context)),
    selectedPurposeId: null,
    selectedLevelCode: level,
    beginnerSelected: beginner,
    onPurposeChanged: (_) {},
    onBeginnerSelected: () => setState(() {
      level = 'A1';
      beginner = true;
    }),
    onLevelChanged: (value) => setState(() {
      level = value;
      beginner = false;
    }),
    onContinue: widget.onSubmitted,
  );
}

class _Companion extends StatefulWidget {
  const _Companion({required this.onSubmitted});
  final ValueChanged<String> onSubmitted;
  @override
  State<_Companion> createState() => _CompanionState();
}

class _CompanionState extends State<_Companion> {
  String? companion;
  @override
  Widget build(BuildContext context) => OnboardingCompanionScreen(
    copy: onboardingV2Copy(AppL10n.of(context)),
    selectedCompanionId: companion,
    onCompanionChanged: (value) => setState(() => companion = value),
    onContinue: widget.onSubmitted,
  );
}
