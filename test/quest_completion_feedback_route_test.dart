import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ko_lernen_app/config/tester_feedback_feature.dart';
import 'package:ko_lernen_app/data/quest_catalog.dart';
import 'package:ko_lernen_app/l10n/generated/app_localizations.dart';
import 'package:ko_lernen_app/models/quest.dart';
import 'package:ko_lernen_app/screens/quests_screen.dart';
import 'package:ko_lernen_app/services/content_feedback_service.dart';
import 'package:ko_lernen_app/services/storage_service.dart';
import 'package:ko_lernen_app/theme.dart';
import 'package:ko_lernen_app/widgets/sori/button.dart';
import 'package:ko_lernen_app/widgets/sori/content_feedback_card.dart';
import 'package:ko_lernen_app/widgets/sori/progress.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({'kl_tut_quests': true});
    Storage.resetForTesting();
    await Storage.init();
  });

  testWidgets(
    'a newly completed quest keeps feedback visible through barrier and system Back until Continue',
    (tester) async {
      const sensitiveDisplayName = 'private-tester@example.invalid';
      const sensitiveHistory = 'completed three earlier quests';
      const completedQuest = QuestProgress(
        questId: 'q_jangdokdae',
        current: 50,
        target: 50,
        active: true,
        completed: true,
        completedAtIso: null,
      );

      await tester.pumpWidget(
        _feedbackHost(
          QuestsScreen(
            loadQuests: () async => const [completedQuest],
            persistNewCompletions: (_) async {},
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 1201));
      await tester.pump(const Duration(milliseconds: 1501));
      await tester.pump();

      expect(find.byType(Dialog), findsOneWidget);
      expect(find.byType(ContentFeedbackCard), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(ContentFeedbackCard),
          matching: find.byType(SoriProgressBar),
        ),
        findsNothing,
      );
      final context = tester
          .widget<ContentFeedbackCard>(find.byType(ContentFeedbackCard))
          .feedbackContext;
      expect(context.contentType, 'quest_reward');
      expect(context.contentId, 'q_jangdokdae');
      expect(context.contentLabel, 'quest_reward');
      expect(
        context.scoreSummary,
        'type:standing; target:${kQuestById['q_jangdokdae']!.target}',
      );
      expect(
        context.toWire().values.whereType<String>(),
        isNot(contains(sensitiveDisplayName)),
      );
      expect(
        context.toWire().values.whereType<String>(),
        isNot(contains(sensitiveHistory)),
      );

      await tester.tapAt(const Offset(1, 1));
      await tester.pump();
      expect(find.byType(ContentFeedbackCard), findsOneWidget);

      final systemBackHandled = await tester.binding.handlePopRoute();
      await tester.pump(const Duration(milliseconds: 200));
      expect(systemBackHandled, isTrue);
      expect(find.byType(Dialog), findsOneWidget);
      expect(find.byType(ContentFeedbackCard), findsOneWidget);

      final continueButton = tester.widget<SoriButton>(
        find.byKey(const Key('quest-completion-continue')),
      );
      expect(continueButton.onTap, isNotNull);
      continueButton.onTap!();
      await _pumpUntilGone(tester, find.byType(Dialog));

      expect(find.byType(Dialog), findsNothing);
      expect(find.byType(ContentFeedbackCard), findsNothing);
      expect(find.byType(QuestsScreen), findsOneWidget);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(milliseconds: 601));
    },
  );

  testWidgets(
    'DE and EN completion dialog stays reachable at 320x640 and 200% text',
    (tester) async {
      const completedQuest = QuestProgress(
        questId: 'q_jangdokdae',
        current: 50,
        target: 50,
        active: true,
        completed: true,
        completedAtIso: null,
      );
      await _configureView(tester, const Size(320, 640));

      for (final locale in const [Locale('de'), Locale('en')]) {
        await tester.pumpWidget(
          _feedbackHost(
            QuestsScreen(
              loadQuests: () async => const [completedQuest],
              persistNewCompletions: (_) async {},
            ),
            locale: locale,
            textScale: 2,
            safeInsets: const EdgeInsets.only(top: 44, bottom: 34),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 1201));
        await tester.pump(const Duration(milliseconds: 1501));
        await tester.pump();

        final definition = kQuestById['q_jangdokdae']!;
        final questName = locale.languageCode == 'en'
            ? definition.name.en
            : definition.name.de;
        final context = tester.element(find.byType(QuestsScreen));
        final t = AppL10n.of(context);

        expect(find.byType(Dialog), findsOneWidget);
        expect(find.text(questName), findsOneWidget);
        expect(find.text(t.questsCompletionCelebration), findsOneWidget);

        final continueFinder = find.byKey(
          const Key('quest-completion-continue'),
        );
        await tester.scrollUntilVisible(
          continueFinder,
          160,
          scrollable: find
              .descendant(
                of: find.byType(Dialog),
                matching: find.byType(Scrollable),
              )
              .last,
        );
        expect(
          find.byKey(const Key('quest-completion-open-gift')),
          findsOneWidget,
        );
        expect(continueFinder, findsOneWidget);
        expect(tester.takeException(), isNull);

        tester.widget<SoriButton>(continueFinder).onTap!();
        await _pumpUntilGone(tester, find.byType(Dialog));
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pump(const Duration(milliseconds: 601));
      }
    },
  );
}

Future<void> _configureView(WidgetTester tester, Size size) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

Future<void> _pumpUntilGone(WidgetTester tester, Finder finder) async {
  for (var attempt = 0; attempt < 15; attempt++) {
    await tester.pump(const Duration(milliseconds: 100));
    if (finder.evaluate().isEmpty) return;
  }
  expect(finder, findsNothing);
}

Widget _feedbackHost(
  Widget child, {
  Locale locale = const Locale('en'),
  double textScale = 1,
  EdgeInsets safeInsets = EdgeInsets.zero,
}) => MaterialApp(
  debugShowCheckedModeBanner: false,
  theme: AppTheme.light,
  locale: locale,
  supportedLocales: AppL10n.supportedLocales,
  localizationsDelegates: AppL10n.localizationsDelegates,
  builder: (context, routeChild) {
    final media = MediaQuery.of(context);
    return MediaQuery(
      data: media.copyWith(
        padding: safeInsets,
        viewPadding: safeInsets,
        textScaler: TextScaler.linear(textScale),
        disableAnimations: true,
      ),
      child: ContentFeedbackControllerScope(
        featureGate: const TesterFeedbackFeatureGate(enabled: true),
        submitFeedback: (_, __) async => const ContentFeedbackSubmitResult(
          status: ContentFeedbackSubmitStatus.accepted,
        ),
        resumePending: () async => const ContentFeedbackResumeResult(),
        child: routeChild ?? const SizedBox.shrink(),
      ),
    );
  },
  home: child,
);
