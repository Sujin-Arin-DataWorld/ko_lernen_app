import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart' show LocaleStringAttribute;
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ko_lernen_app/screens/onboarding_v2/onboarding_companion_screen.dart';
import 'package:ko_lernen_app/screens/onboarding_v2/onboarding_v2_copy.dart';
import 'package:ko_lernen_app/screens/onboarding_v2/onboarding_setup_screen.dart';
import 'package:ko_lernen_app/screens/onboarding_v2/onboarding_story_screen.dart';
import 'package:ko_lernen_app/screens/onboarding_v2/onboarding_v2_presentation.dart';
import 'package:ko_lernen_app/l10n/generated/app_localizations.dart';
import 'package:ko_lernen_app/theme.dart';
import 'package:ko_lernen_app/widgets/sori/button.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('story is coordinator-driven, mandatory, and resume-ready', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    final copy = _copy();
    String? continuedPage;
    String? previousPage;

    await tester.pumpWidget(
      _host(
        OnboardingStoryScreen(
          copy: copy,
          pageIndex: 3,
          onContinue: (id) => continuedPage = id,
          onPrevious: (id) => previousPage = id,
        ),
      ),
    );

    expect(find.text('Play and rewards'), findsOneWidget);
    expect(
      tester
          .getSemantics(
            find.byKey(const ValueKey('onboarding-v2-story-progress')),
          )
          .getSemanticsData()
          .label,
      'Page 4 of 7',
    );
    expect(find.text('Reward examples — nothing is granted here'), findsOne);
    expect(find.textContaining('Skip'), findsNothing);
    expect(find.byKey(const ValueKey('onboarding-v2-story-hero')), findsOne);
    final heading = tester
        .getSemantics(find.bySemanticsLabel('Page 4 of 7. Play and rewards'))
        .getSemanticsData();
    expect(heading.flagsCollection.isHeader, isTrue);
    expect(heading.flagsCollection.isLiveRegion, isFalse);
    expect(
      FocusManager.instance.primaryFocus?.debugLabel,
      'onboarding-v2-heading',
    );
    final statusSemantics = tester
        .getSemantics(find.byKey(const ValueKey('onboarding-v2-story-status')))
        .getSemanticsData();
    expect(
      statusSemantics.label,
      contains('Reward examples — nothing is granted here'),
    );
    final highlightSemantics = tester
        .getSemantics(find.text('Game hints'))
        .getSemanticsData();
    expect(highlightSemantics.label, contains('Play and rewards preview'));
    expect(highlightSemantics.flagsCollection.isButton, isTrue);

    await tester.tap(find.byKey(const ValueKey('onboarding-v2-story-back')));
    expect(previousPage, OnboardingV2Ids.storyGamesAndRewards);

    await tester.tap(find.byKey(const ValueKey('onboarding-v2-story-next')));
    expect(continuedPage, OnboardingV2Ids.storyGamesAndRewards);
    semantics.dispose();
  });

  testWidgets('story explains favorite and review without false promises', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(
        OnboardingStoryScreen(
          copy: _copy(),
          pageIndex: 2,
          onContinue: (_) {},
          onPrevious: (_) {},
        ),
      ),
    );

    expect(find.text('Heart = favorite'), findsOneWidget);
    expect(find.text('Bookmark = save for learning'), findsOneWidget);
    expect(find.textContaining('without adding a review task'), findsOneWidget);
    expect(find.textContaining('Netflix'), findsNothing);
    expect(find.textContaining('AI-generated'), findsNothing);
  });

  testWidgets('each mandatory story page starts at the top', (tester) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      _host(_StoryPagingHarness(copy: _copy(), initialPage: 3), textScale: 2),
    );

    final pageFourScroll = find.byKey(
      const ValueKey(
        'onboarding-v2-story-scroll-${OnboardingV2Ids.storyGamesAndRewards}',
      ),
    );
    await tester.drag(pageFourScroll, const Offset(0, -700));
    await tester.pump();
    expect(tester.getTopLeft(find.text('Play and rewards')).dy, lessThan(0));

    await tester.tap(find.byKey(const ValueKey('onboarding-v2-story-next')));
    await tester.pump();

    expect(find.text('Your stamp book, bojagi, and hanok'), findsOneWidget);
    expect(
      tester.getTopLeft(find.text('Your stamp book, bojagi, and hanok')).dy,
      greaterThanOrEqualTo(0),
    );
  });

  testWidgets('setup requires both goal and level before emitting a draft', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    OnboardingSetupSelection? submitted;
    await tester.pumpWidget(
      _host(
        _SetupHarness(
          copy: _copy(),
          onSubmitted: (selection) => submitted = selection,
        ),
      ),
    );

    expect(_button(tester, 'onboarding-v2-setup-continue').onTap, isNull);

    final purpose = find.byKey(
      const ValueKey(
        'onboarding-v2-purpose-${OnboardingV2Ids.purposeKContent}',
      ),
    );
    await tester.ensureVisible(purpose);
    await tester.tap(purpose);
    await tester.pump();
    await tester.tap(
      find.byKey(const ValueKey('onboarding-v2-setup-continue')),
    );
    await tester.pump();
    await tester.ensureVisible(
      find.byKey(const ValueKey('onboarding-v2-level-B2')),
    );
    await tester.tap(find.byKey(const ValueKey('onboarding-v2-level-B2')));
    await tester.pump();

    expect(find.text('The meeting is running long.'), findsOneWidget);
    final koreanExample = tester
        .getSemantics(
          find.byKey(const ValueKey('onboarding-v2-level-example-ko')),
        )
        .getSemanticsData();
    expect(
      koreanExample.attributedLabel.attributes
          .whereType<LocaleStringAttribute>()
          .map((attribute) => attribute.locale.languageCode),
      contains('ko'),
    );
    expect(_button(tester, 'onboarding-v2-setup-continue').onTap, isNotNull);

    await tester.tap(
      find.byKey(const ValueKey('onboarding-v2-setup-continue')),
    );
    expect(submitted?.purposeId, OnboardingV2Ids.purposeKContent);
    expect(submitted?.levelCode, 'B2');
    semantics.dispose();
  });

  testWidgets('level comparison has an explicit close and no diagnostic CTA', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(_SetupHarness(copy: _copy(), onSubmitted: (_) {}), textScale: 2),
    );

    final purpose = find.byKey(
      const ValueKey(
        'onboarding-v2-purpose-${OnboardingV2Ids.purposeLifeTravel}',
      ),
    );
    await tester.ensureVisible(purpose);
    await tester.tap(purpose);
    await tester.pump();
    await tester.tap(
      find.byKey(const ValueKey('onboarding-v2-setup-continue')),
    );
    await tester.pump();

    final compare = find.byKey(const ValueKey('onboarding-v2-level-compare'));
    await tester.ensureVisible(compare);
    await _focusWithKeyboard(tester, compare);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();

    expect(find.text('Which starting point fits?'), findsOneWidget);
    expect(
      FocusManager.instance.primaryFocus?.debugLabel,
      'onboarding-v2-level-comparison-heading',
    );
    final sheetContext = tester.element(
      find.text('Which starting point fits?'),
    );
    expect(MediaQuery.textScalerOf(sheetContext).scale(1), 2);
    expect(find.textContaining('8 questions'), findsNothing);
    expect(
      find.byKey(const ValueKey('onboarding-v2-level-compare-close')),
      findsOneWidget,
    );

    await tester.tap(
      find.byKey(const ValueKey('onboarding-v2-level-compare-close')),
    );
    await tester.pumpAndSettle();
    expect(find.text('Which starting point fits?'), findsNothing);
    expect(_primaryFocusIsWithin(compare), isTrue);
  });

  testWidgets('companion choice is mandatory and has no none or skip option', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    String? submitted;
    await tester.pumpWidget(
      _host(
        _CompanionHarness(copy: _copy(), onSubmitted: (id) => submitted = id),
      ),
    );

    expect(_button(tester, 'onboarding-v2-companion-continue').onTap, isNull);
    expect(find.text('Skip'), findsNothing);
    expect(find.text('None'), findsNothing);

    await tester.tap(
      find.byKey(
        const ValueKey(
          'onboarding-v2-companion-${OnboardingV2Ids.companionJoy}',
        ),
      ),
    );
    await tester.pump();
    final joySemantics = tester
        .getSemantics(
          find.byKey(
            const ValueKey(
              'onboarding-v2-companion-semantics-${OnboardingV2Ids.companionJoy}',
            ),
          ),
        )
        .getSemanticsData();
    expect(
      joySemantics.attributedLabel.attributes
          .whereType<LocaleStringAttribute>()
          .map((attribute) => attribute.locale.languageCode),
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
    semantics.dispose();
  });

  testWidgets('confirmation CTA works independently from decorative preview', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    var previewBuilds = 0;
    var starts = 0;

    await tester.pumpWidget(
      _host(
        OnboardingCompanionConfirmationScreen(
          copy: _copy(),
          companionId: OnboardingV2Ids.companionTaego,
          previewBuilder: (context, id) {
            previewBuilds += 1;
            return const ColoredBox(color: Colors.transparent);
          },
          onStart: () => starts += 1,
          onChange: () {},
        ),
        disableAnimations: false,
      ),
    );
    await tester.pump();

    expect(previewBuilds, greaterThan(0));
    expect(starts, 0);
    expect(find.text('Taego has been selected.'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('onboarding-v2-confirmation-start')),
      findsOneWidget,
    );
    final headingData = tester
        .getSemantics(
          find.byKey(const ValueKey('onboarding-v2-confirmation-live-heading')),
        )
        .getSemanticsData();
    expect(headingData.flagsCollection.isHeader, isTrue);
    expect(headingData.flagsCollection.isLiveRegion, isTrue);
    expect(
      FocusManager.instance.primaryFocus?.debugLabel,
      'onboarding-v2-companion-confirmation-heading',
    );
    expect(find.bySemanticsLabel('Taego has been selected.'), findsOneWidget);

    await tester.tap(
      find.byKey(const ValueKey('onboarding-v2-confirmation-start')),
    );
    expect(starts, 1);
    semantics.dispose();
  });

  testWidgets('reduce motion skips preview but keeps static confirmation CTA', (
    tester,
  ) async {
    var previewBuilds = 0;
    var starts = 0;
    await tester.pumpWidget(
      _host(
        OnboardingCompanionConfirmationScreen(
          copy: _copy(),
          companionId: OnboardingV2Ids.companionJoy,
          previewBuilder: (context, id) {
            previewBuilds += 1;
            return const ColoredBox(color: Colors.black);
          },
          onStart: () => starts += 1,
          onChange: () {},
        ),
      ),
    );
    await tester.pump();

    expect(previewBuilds, 0);
    expect(find.text('Joy has been selected.'), findsOneWidget);
    await tester.tap(
      find.byKey(const ValueKey('onboarding-v2-confirmation-start')),
    );
    expect(starts, 1);
  });

  testWidgets(
    '320x640 at 200 percent text keeps body scrollable and CTA fixed',
    (tester) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        _host(
          OnboardingStoryScreen(
            copy: _copy(),
            pageIndex: 4,
            onContinue: (_) {},
            onPrevious: (_) {},
          ),
          textScale: 2,
        ),
      );
      expect(tester.takeException(), isNull);
      _expectMinimumTarget(
        tester,
        find.byKey(const ValueKey('onboarding-v2-story-next')),
      );
      expect(find.byType(SingleChildScrollView), findsOneWidget);

      await tester.pumpWidget(
        _host(
          _CompanionHarness(copy: _copy(), onSubmitted: (_) {}),
          textScale: 2,
        ),
      );
      await tester.pump();
      expect(tester.takeException(), isNull);
      _expectMinimumTarget(
        tester,
        find.byKey(const ValueKey('onboarding-v2-companion-continue')),
      );
    },
  );

  testWidgets('real German copy stays usable at 320x640 and 200 percent text', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        locale: const Locale('de'),
        supportedLocales: AppL10n.supportedLocales,
        localizationsDelegates: AppL10n.localizationsDelegates,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: const TextScaler.linear(2),
            disableAnimations: true,
          ),
          child: child ?? const SizedBox.shrink(),
        ),
        home: Builder(
          builder: (context) => OnboardingStoryScreen(
            copy: onboardingV2Copy(AppL10n.of(context)),
            pageIndex: 4,
            onContinue: (_) {},
            onPrevious: (_) {},
          ),
        ),
      ),
    );
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(find.byType(SingleChildScrollView), findsOneWidget);
    _expectMinimumTarget(
      tester,
      find.byKey(const ValueKey('onboarding-v2-story-next')),
    );
    expect(
      find.byKey(const ValueKey('onboarding-v2-story-progress')),
      findsOneWidget,
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        locale: const Locale('de'),
        supportedLocales: AppL10n.supportedLocales,
        localizationsDelegates: AppL10n.localizationsDelegates,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: const TextScaler.linear(2),
            disableAnimations: true,
          ),
          child: child ?? const SizedBox.shrink(),
        ),
        home: Builder(
          builder: (context) => _SetupHarness(
            copy: onboardingV2Copy(AppL10n.of(context)),
            onSubmitted: (_) {},
          ),
        ),
      ),
    );
    await tester.pump();
    expect(tester.takeException(), isNull);
    expect(find.byType(SingleChildScrollView), findsOneWidget);
    _expectMinimumTarget(
      tester,
      find.byKey(const ValueKey('onboarding-v2-setup-continue')),
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        locale: const Locale('de'),
        supportedLocales: AppL10n.supportedLocales,
        localizationsDelegates: AppL10n.localizationsDelegates,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: const TextScaler.linear(2),
            disableAnimations: true,
          ),
          child: child ?? const SizedBox.shrink(),
        ),
        home: Builder(
          builder: (context) => OnboardingCompanionConfirmationScreen(
            copy: onboardingV2Copy(AppL10n.of(context)),
            companionId: OnboardingV2Ids.companionJoy,
            onStart: () {},
            onChange: () {},
          ),
        ),
      ),
    );
    await tester.pump();
    expect(tester.takeException(), isNull);
    expect(find.byType(SingleChildScrollView), findsOneWidget);
    _expectMinimumTarget(
      tester,
      find.byKey(const ValueKey('onboarding-v2-confirmation-start')),
    );
  });
}

Future<void> _focusWithKeyboard(WidgetTester tester, Finder target) async {
  for (var attempt = 0; attempt < 40; attempt++) {
    if (_primaryFocusIsWithin(target)) {
      return;
    }
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
  }
  fail('Keyboard traversal did not reach $target.');
}

bool _primaryFocusIsWithin(Finder target) {
  final targetElements = target.evaluate();
  final focusContext = FocusManager.instance.primaryFocus?.context;
  if (targetElements.length != 1 || focusContext == null) {
    return false;
  }
  final targetElement = targetElements.single;
  if (identical(focusContext, targetElement)) {
    return true;
  }
  var isWithin = false;
  focusContext.visitAncestorElements((ancestor) {
    if (identical(ancestor, targetElement)) {
      isWithin = true;
      return false;
    }
    return true;
  });
  return isWithin;
}

Widget _host(
  Widget child, {
  double textScale = 1,
  bool disableAnimations = true,
}) => MaterialApp(
  theme: AppTheme.light,
  home: child,
  builder: (context, child) => MediaQuery(
    data: MediaQuery.of(context).copyWith(
      textScaler: TextScaler.linear(textScale),
      disableAnimations: disableAnimations,
    ),
    child: child ?? const SizedBox.shrink(),
  ),
);

SoriButton _button(WidgetTester tester, String key) =>
    tester.widget<SoriButton>(find.byKey(ValueKey(key)));

void _expectMinimumTarget(WidgetTester tester, Finder finder) {
  final data = tester.getSemantics(finder).getSemanticsData();
  expect(data.flagsCollection.isButton, isTrue);
  expect(tester.getSize(finder).height, greaterThanOrEqualTo(48));
}

class _SetupHarness extends StatefulWidget {
  const _SetupHarness({required this.copy, required this.onSubmitted});

  final OnboardingV2Copy copy;
  final ValueChanged<OnboardingSetupSelection> onSubmitted;

  @override
  State<_SetupHarness> createState() => _SetupHarnessState();
}

class _StoryPagingHarness extends StatefulWidget {
  const _StoryPagingHarness({required this.copy, required this.initialPage});

  final OnboardingV2Copy copy;
  final int initialPage;

  @override
  State<_StoryPagingHarness> createState() => _StoryPagingHarnessState();
}

class _StoryPagingHarnessState extends State<_StoryPagingHarness> {
  late int pageIndex = widget.initialPage;

  @override
  Widget build(BuildContext context) => OnboardingStoryScreen(
    copy: widget.copy,
    pageIndex: pageIndex,
    onContinue: (_) => setState(() => pageIndex += 1),
    onPrevious: (_) => setState(() => pageIndex -= 1),
  );
}

class _SetupHarnessState extends State<_SetupHarness> {
  String? purposeId;
  String? levelCode;

  @override
  Widget build(BuildContext context) => OnboardingSetupScreen(
    copy: widget.copy,
    selectedPurposeId: purposeId,
    selectedLevelCode: levelCode,
    onPurposeChanged: (value) => setState(() => purposeId = value),
    onLevelChanged: (value) => setState(() => levelCode = value),
    onContinue: widget.onSubmitted,
  );
}

class _CompanionHarness extends StatefulWidget {
  const _CompanionHarness({required this.copy, required this.onSubmitted});

  final OnboardingV2Copy copy;
  final ValueChanged<String> onSubmitted;

  @override
  State<_CompanionHarness> createState() => _CompanionHarnessState();
}

class _CompanionHarnessState extends State<_CompanionHarness> {
  String? companionId;

  @override
  Widget build(BuildContext context) => OnboardingCompanionScreen(
    copy: widget.copy,
    selectedCompanionId: companionId,
    onCompanionChanged: (value) => setState(() => companionId = value),
    onContinue: widget.onSubmitted,
  );
}

OnboardingV2Copy _copy() => OnboardingV2Copy(
  brandLatin: 'Hangeul Sori',
  brandKorean: '한글소리',
  syllableGa: '가',
  navigation: const OnboardingNavigationCopy(
    back: 'Back',
    next: 'Next',
    finishStory: 'Choose my starting point',
    progressTemplate: 'Page {current} of {total}',
  ),
  storyPages: [
    _story(
      id: OnboardingV2Ids.storyPersonalCurriculum,
      title: 'Your learning path — and your own book',
      kind: OnboardingStoryVisualKind.personalCurriculum,
      firstTitle: 'A1–C2 learning path',
      secondTitle: 'Photograph your book',
    ),
    _story(
      id: OnboardingV2Ids.storyLearn,
      title: 'From your first letter to a conversation',
      kind: OnboardingStoryVisualKind.learn,
      firstTitle: 'Hangeul',
      secondTitle: 'Listening & pronunciation',
    ),
    _story(
      id: OnboardingV2Ids.storySaveAndReview,
      title: 'Keep what matters to you',
      kind: OnboardingStoryVisualKind.saveAndReview,
      firstTitle: 'Turn a card over',
      secondTitle: 'Swipe onward',
      thirdTitle: 'Heart = favorite',
      thirdBody: 'Keep something you like without adding a review task.',
      fourthTitle: 'Bookmark = save for learning',
    ),
    _story(
      id: OnboardingV2Ids.storyGamesAndRewards,
      title: 'Play and rewards',
      kind: OnboardingStoryVisualKind.gamesAndRewards,
      firstTitle: 'Game hints',
      secondTitle: 'XP & personal bests',
      status: 'Reward examples — nothing is granted here',
    ),
    _story(
      id: OnboardingV2Ids.storyHeritageJourney,
      title: 'Your stamp book, bojagi, and hanok',
      kind: OnboardingStoryVisualKind.heritageJourney,
      firstTitle: 'Stamp book',
      secondTitle: 'Bojagi & accessories',
      status: 'First journey · Ildu Gotaek · In preparation',
    ),
  ],
  setup: OnboardingSetupCopy(
    eyebrow: 'Your personal start',
    title: 'Why are you learning, and where will you start?',
    body:
        'Your goal changes only recommendations, never difficulty or rewards.',
    purposeHeading: '1. Choose your goal',
    levelHeading: '2. Choose your starting point',
    levelHelp: 'This staged path draws on CEFR and NIKL learning goals.',
    selectLevelPrompt: 'Choose a level to see an example.',
    exampleLabel: 'Example at this level',
    canDoLabel: 'What you can probably do already',
    learnHereLabel: 'What you start with here',
    compareAction: 'Compare levels',
    compareTitle: 'Which starting point fits?',
    compareBody: 'A direct choice is a starting point, not proof of mastery.',
    compareClose: 'Close comparison',
    continueAction: 'Use these choices',
    purposes: const [
      OnboardingPurposeSpec(
        id: OnboardingV2Ids.purposeLifeTravel,
        title: 'Everyday life & travel',
        body: 'Daily situations',
        icon: Icons.travel_explore_outlined,
      ),
      OnboardingPurposeSpec(
        id: OnboardingV2Ids.purposePeopleCulture,
        title: 'People & culture',
        body: 'Conversations and context',
        icon: Icons.people_outline_rounded,
      ),
      OnboardingPurposeSpec(
        id: OnboardingV2Ids.purposeStudyWork,
        title: 'Study & work',
        body: 'Class and work',
        icon: Icons.work_outline_rounded,
      ),
      OnboardingPurposeSpec(
        id: OnboardingV2Ids.purposeKContent,
        title: 'K-content',
        body: 'Music, series, films, and podcasts',
        icon: Icons.subscriptions_outlined,
      ),
    ],
    levels: _levels,
  ),
  companion: const OnboardingCompanionCopy(
    eyebrow: 'Your study buddy',
    title: 'Who will learn with you?',
    body: 'Choose Taego or Joy.',
    equalLearningNote: 'Content, answers, XP, and rewards are identical.',
    continueAction: 'Confirm my choice',
    confirmationEyebrow: 'Ready to begin',
    confirmationBody: 'The video is decorative. You can continue at any time.',
    startAction: 'Start together',
    changeAction: 'Choose another study buddy',
    companions: [
      OnboardingCompanionSpec(
        id: OnboardingV2Ids.companionTaego,
        name: 'Taego',
        koreanName: '태고',
        rhythm: 'Calm and step by step',
        body: 'Puts the same guidance in a clear order.',
        selectedMessage: 'Taego has been selected.',
      ),
      OnboardingCompanionSpec(
        id: OnboardingV2Ids.companionJoy,
        name: 'Joy',
        koreanName: '조이',
        rhythm: 'Short cues, straight into practice',
        body: 'Gives the same guidance as short prompts.',
        selectedMessage: 'Joy has been selected.',
      ),
    ],
  ),
);

OnboardingStoryPageSpec _story({
  required String id,
  required String title,
  required OnboardingStoryVisualKind kind,
  required String firstTitle,
  required String secondTitle,
  String firstBody = 'A truthful preview.',
  String thirdTitle = 'More context',
  String thirdBody = 'No permission is requested here.',
  String fourthTitle = 'Your choice',
  String? status,
}) => OnboardingStoryPageSpec(
  id: id,
  eyebrow: 'Hangul Sori',
  title: title,
  body: 'Learn how this part of the app works before you begin.',
  heroSemanticLabel: '$title preview',
  visualKind: kind,
  statusLabel: status,
  highlights: [
    OnboardingStoryHighlight(
      title: firstTitle,
      body: firstBody,
      icon: Icons.looks_one_outlined,
    ),
    OnboardingStoryHighlight(
      title: secondTitle,
      body: 'A truthful preview.',
      icon: Icons.looks_two_outlined,
    ),
    OnboardingStoryHighlight(
      title: thirdTitle,
      body: thirdBody,
      icon: Icons.info_outline_rounded,
    ),
    OnboardingStoryHighlight(
      title: fourthTitle,
      body: 'Nothing is changed by this preview.',
      icon: Icons.touch_app_outlined,
    ),
  ],
);

const _levels = <OnboardingLevelSpec>[
  OnboardingLevelSpec(
    code: 'A1',
    name: 'Beginner',
    exampleKorean: '안녕하세요.',
    exampleTranslation: 'Hello.',
    canDo: 'You may know a few words.',
    learnHere: 'Read and write Hangeul.',
  ),
  OnboardingLevelSpec(
    code: 'A2',
    name: 'Basic',
    exampleKorean: '아메리카노 한 잔 주세요.',
    exampleTranslation: 'An americano, please.',
    canDo: 'You know simple greetings.',
    learnHere: 'Order and ask for directions.',
  ),
  OnboardingLevelSpec(
    code: 'B1',
    name: 'Intermediate',
    exampleKorean: '어제 친구를 만났어요.',
    exampleTranslation: 'I met a friend yesterday.',
    canDo: 'You handle simple conversations.',
    learnHere: 'Tell stories and give opinions.',
  ),
  OnboardingLevelSpec(
    code: 'B2',
    name: 'Advanced',
    exampleKorean: '회의가 길어져서 조금 늦을 것 같아요.',
    exampleTranslation: 'The meeting is running long.',
    canDo: 'You speak fluently about daily topics.',
    learnHere: 'Work with nuance and idioms.',
  ),
  OnboardingLevelSpec(
    code: 'C1',
    name: 'Proficient',
    exampleKorean: '확인된 사실과 해석을 나누어 설명하겠습니다.',
    exampleTranslation: 'I will separate facts from interpretation.',
    canDo: 'You can discuss difficult topics.',
    learnHere: 'Work with evidence and uncertainty.',
  ),
  OnboardingLevelSpec(
    code: 'C2',
    name: 'Expert',
    exampleKorean: '질문의 전제가 참여를 제한할 수 있습니다.',
    exampleTranslation: 'A question’s framing can limit participation.',
    canDo: 'You can unpack framing and official language.',
    learnHere: 'Analyze discourse and interpretation.',
  ),
];
