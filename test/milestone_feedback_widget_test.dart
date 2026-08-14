import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ko_lernen_app/config/tester_feedback_feature.dart';
import 'package:ko_lernen_app/data/milestone.dart';
import 'package:ko_lernen_app/l10n/generated/app_localizations.dart';
import 'package:ko_lernen_app/models/feedback_completion.dart';

import 'package:ko_lernen_app/services/content_feedback_service.dart';
import 'package:ko_lernen_app/services/storage_service.dart';
import 'package:ko_lernen_app/theme.dart';
import 'package:ko_lernen_app/widgets/sori/button.dart';
import 'package:ko_lernen_app/widgets/sori/content_feedback_card.dart';
import 'package:ko_lernen_app/widgets/sori/milestone_celebration.dart';
import 'package:ko_lernen_app/widgets/sori/progress.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    Storage.resetForTesting();
    await Storage.init();
  });

  testWidgets(
    'milestone celebration renders optional feedback before Continue',
    (tester) async {
      const sensitiveVocabularyId = 'private-vocabulary-id-42';
      const sensitiveHistory = 'all seven earlier streak dates';
      final completion = FeedbackCompletion.milestone(
        createId: () => 'milestone-widget-completion',
        milestoneId: 'streak_7',
        milestoneType: 'streak',
        value: 7,
      );

      await tester.pumpWidget(
        _feedbackHost(
          Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: ElevatedButton(
                  key: const Key('open-milestone-celebration'),
                  onPressed: () => showMilestoneCelebration(
                    context,
                    const Milestone(MilestoneType.streak, 7),
                    feedbackContext: completion.context,
                  ),
                  child: const Text('Open milestone'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.byKey(const Key('open-milestone-celebration')));
      await tester.pump();

      expect(find.byType(ContentFeedbackCard), findsOneWidget);
      expect(find.byType(SoriProgressBar), findsNothing);
      final context = tester
          .widget<ContentFeedbackCard>(find.byType(ContentFeedbackCard))
          .feedbackContext;
      expect(context.contentType, 'milestone');
      expect(context.contentId, 'streak_7');
      expect(context.contentLabel, 'milestone');
      expect(context.scoreSummary, 'type:streak; value:7');
      expect(
        context.toWire().values.whereType<String>(),
        isNot(contains(sensitiveVocabularyId)),
      );
      expect(
        context.toWire().values.whereType<String>(),
        isNot(contains(sensitiveHistory)),
      );

      final continueButton = tester.widget<SoriButton>(
        find.byKey(const Key('milestone-celebration-continue')),
      );
      expect(continueButton.onTap, isNotNull);
      continueButton.onTap!();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(ContentFeedbackCard), findsNothing);
    },
  );

  testWidgets(
    'Home persists only the displayed top milestone and presents the next one later',
    (tester) async {
      SharedPreferences.setMockInitialValues({
        'kl_tut_home_tour': true,
        'kl_motivation_asked': true,
        'kl_streak_days': 3,
        'kl_xp': 400,
        'kl_hanok_stages_seen_v1': ['empty'],
      });
      Storage.resetForTesting();
      await Storage.init();

      await tester.pumpWidget(_feedbackHost(const Scaffold()));
      await _pumpUntilMilestoneIsStored(tester);

      expect(Storage.celebratedMilestones.toSet(), {'streak_3'});
      expect(find.byType(ContentFeedbackCard), findsOneWidget);
      expect(
        tester
            .widget<ContentFeedbackCard>(find.byType(ContentFeedbackCard))
            .feedbackContext
            .scoreSummary,
        'type:streak; value:3',
      );

      tester
          .widget<SoriButton>(
            find.byKey(const Key('milestone-celebration-continue')),
          )
          .onTap!();
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();

      await tester.pumpWidget(_feedbackHost(const Scaffold()));
      await _pumpUntilMilestoneIsStored(tester, expectedCount: 2);

      expect(Storage.celebratedMilestones.toSet(), {'streak_3', 'level_5'});
      expect(find.byType(ContentFeedbackCard), findsOneWidget);
      expect(
        tester
            .widget<ContentFeedbackCard>(find.byType(ContentFeedbackCard))
            .feedbackContext
            .scoreSummary,
        'type:level; value:5',
      );
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(seconds: 2));
    },
  );
}

Future<void> _pumpUntilMilestoneIsStored(
  WidgetTester tester, {
  int expectedCount = 1,
}) async {
  for (var attempt = 0; attempt < 30; attempt++) {
    await tester.pump(const Duration(milliseconds: 100));
    if (Storage.celebratedMilestones.length == expectedCount) return;
  }
  expect(Storage.celebratedMilestones, hasLength(expectedCount));
}

Widget _feedbackHost(Widget child) => MaterialApp(
  debugShowCheckedModeBanner: false,
  theme: AppTheme.light,
  locale: const Locale('en'),
  supportedLocales: AppL10n.supportedLocales,
  localizationsDelegates: AppL10n.localizationsDelegates,
  builder: (context, routeChild) => ContentFeedbackControllerScope(
    featureGate: const TesterFeedbackFeatureGate(enabled: true),
    submitFeedback: (_, __) async => const ContentFeedbackSubmitResult(
      status: ContentFeedbackSubmitStatus.accepted,
    ),
    resumePending: () async => const ContentFeedbackResumeResult(),
    child: routeChild ?? const SizedBox.shrink(),
  ),
  home: child,
);
