import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ko_lernen_app/config/tester_feedback_feature.dart';
import 'package:ko_lernen_app/l10n/generated/app_localizations.dart';
import 'package:ko_lernen_app/models/content_feedback.dart';
import 'package:ko_lernen_app/services/content_feedback_service.dart';
import 'package:ko_lernen_app/widgets/sori/content_feedback_card.dart';
import 'package:ko_lernen_app/widgets/sori/game_reward.dart';
import 'package:ko_lernen_app/widgets/sori/mascot.dart';
import 'package:ko_lernen_app/widgets/sori/progress.dart';
import 'package:ko_lernen_app/widgets/sori/sheet.dart';

const _feedbackContext = ContentFeedbackContext(
  completionId: 'completion-1',
  contentType: 'scenario',
  contentId: 'scenario:cafe',
  contentLabel: 'Cafe',
  level: 'A1',
  scoreSummary: '4/5',
);

const _nextFeedbackContext = ContentFeedbackContext(
  completionId: 'completion-2',
  contentType: 'listening',
  contentId: 'listening:market',
  contentLabel: 'Market listening',
  level: 'A2',
  scoreSummary: '5/5',
);

void main() {
  testWidgets('disabled feedback gate renders no card', (tester) async {
    var passportReads = 0;
    await tester.pumpWidget(
      _host(
        gate: const TesterFeedbackFeatureGate(enabled: false),
        submitFeedback: (_, __) => throw StateError('must not submit'),
        readPassportState: () async {
          passportReads += 1;
          return const <String>{'beta_scenario'};
        },
      ),
    );
    await tester.pump();

    expect(find.byKey(const Key('content-feedback-card')), findsNothing);
    expect(find.byType(SoriSheetShell), findsNothing);
    expect(passportReads, 0);
  });

  testWidgets('card restores passport progress through controller scope', (
    tester,
  ) async {
    var passportReads = 0;
    await tester.pumpWidget(
      _host(
        gate: const TesterFeedbackFeatureGate(enabled: true),
        submitFeedback: (_, __) async => const ContentFeedbackSubmitResult(
          status: ContentFeedbackSubmitStatus.accepted,
        ),
        readPassportState: () async {
          passportReads += 1;
          return const <String>{'beta_scenario', 'beta_listening'};
        },
      ),
    );
    await tester.pump();

    expect(passportReads, 1);
    expect(
      tester.widget<SoriProgressBar>(find.byType(SoriProgressBar)).value,
      0.4,
    );
  });

  testWidgets('authoritative submission state wins over an in-flight restore', (
    tester,
  ) async {
    final restore = Completer<Set<String>>();
    await tester.pumpWidget(
      _host(
        gate: const TesterFeedbackFeatureGate(enabled: true),
        submitFeedback: (_, __) async => const ContentFeedbackSubmitResult(
          status: ContentFeedbackSubmitStatus.accepted,
          passportStateAuthoritative: true,
          stampAccepted: true,
          passportCompletedMissionIds: <String>{'beta_scenario'},
          nextMissionId: 'beta_word_work',
        ),
        readPassportState: () => restore.future,
      ),
    );
    await tester.pump();

    await _openSheet(tester);
    await tester.tap(find.byKey(const Key('feedback-category-content')));
    await tester.pump();
    await _tapVisible(tester, const Key('feedback-signal-right'));
    await _tapVisible(tester, const Key('feedback-submit'));
    await tester.pumpAndSettle();
    expect(
      tester.widget<SoriProgressBar>(find.byType(SoriProgressBar)).value,
      0.2,
    );

    restore.complete(const <String>{
      'beta_scenario',
      'beta_word_work',
      'beta_listening',
    });
    await tester.pump();

    expect(
      tester.widget<SoriProgressBar>(find.byType(SoriProgressBar)).value,
      0.2,
    );
  });

  testWidgets('malformed delivery keeps valid restored passport progress', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(
        gate: const TesterFeedbackFeatureGate(enabled: true),
        submitFeedback: (_, __) async => const ContentFeedbackSubmitResult(
          status: ContentFeedbackSubmitStatus.accepted,
          passportStateAuthoritative: false,
        ),
        readPassportState: () async => const <String>{
          'beta_scenario',
          'beta_listening',
        },
      ),
    );
    await tester.pump();
    expect(
      tester.widget<SoriProgressBar>(find.byType(SoriProgressBar)).value,
      0.4,
    );

    await _openSheet(tester);
    await tester.tap(find.byKey(const Key('feedback-category-content')));
    await tester.pump();
    await _tapVisible(tester, const Key('feedback-signal-right'));
    await _tapVisible(tester, const Key('feedback-submit'));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('content-feedback-delivered')), findsOneWidget);
    expect(
      tester.widget<SoriProgressBar>(find.byType(SoriProgressBar)).value,
      0.4,
    );
  });

  testWidgets('enabled feedback card never auto-opens its sheet', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(
        gate: const TesterFeedbackFeatureGate(enabled: true),
        submitFeedback: (_, __) async => const ContentFeedbackSubmitResult(
          status: ContentFeedbackSubmitStatus.accepted,
        ),
      ),
    );
    await tester.pump();

    expect(find.byKey(const Key('content-feedback-card')), findsOneWidget);
    expect(find.byType(SoriSheetShell), findsNothing);
  });

  testWidgets('card opens feedback through the Sori sheet', (tester) async {
    await tester.pumpWidget(
      _host(
        gate: const TesterFeedbackFeatureGate(enabled: true),
        submitFeedback: (_, __) async => const ContentFeedbackSubmitResult(
          status: ContentFeedbackSubmitStatus.accepted,
        ),
      ),
    );

    await tester.tap(find.byKey(const Key('content-feedback-open')));
    await tester.pumpAndSettle();

    expect(find.byType(SoriSheetShell), findsOneWidget);
    expect(find.byKey(const Key('feedback-category-bug')), findsOneWidget);
    expect(find.byKey(const Key('feedback-category-content')), findsOneWidget);
    expect(find.byKey(const Key('feedback-category-other')), findsOneWidget);
  });

  testWidgets('bug feedback requires a message and can become pending', (
    tester,
  ) async {
    ContentFeedbackDraft? submitted;
    await tester.pumpWidget(
      _host(
        gate: const TesterFeedbackFeatureGate(enabled: true),
        submitFeedback: (_, draft) async {
          submitted = draft;
          return const ContentFeedbackSubmitResult(
            status: ContentFeedbackSubmitStatus.pending,
          );
        },
      ),
    );
    await _openSheet(tester);

    await tester.tap(find.byKey(const Key('feedback-category-bug')));
    await tester.pump();
    expect(find.byKey(const Key('feedback-issue-area-fields')), findsOneWidget);
    expect(
      find.byKey(const Key('feedback-content-signal-fields')),
      findsNothing,
    );

    await _tapVisible(tester, const Key('feedback-submit'));
    await tester.pump();
    expect(find.byKey(const Key('feedback-validation-error')), findsOneWidget);
    expect(submitted, isNull);

    await tester.ensureVisible(find.byKey(const Key('feedback-message')));
    await tester.enterText(
      find.byKey(const Key('feedback-message')),
      'The answer button stopped responding.',
    );
    await _tapVisible(tester, const Key('feedback-issue-answer'));
    await _tapVisible(tester, const Key('feedback-submit'));
    await tester.pumpAndSettle();

    expect(submitted?.category, FeedbackCategory.bug);
    expect(submitted?.issueArea, FeedbackIssueArea.answer);
    expect(submitted?.message, 'The answer button stopped responding.');
    expect(find.byKey(const Key('content-feedback-pending')), findsOneWidget);
  });

  testWidgets('content feedback accepts structured ratings without a message', (
    tester,
  ) async {
    ContentFeedbackDraft? submitted;
    await tester.pumpWidget(
      _host(
        gate: const TesterFeedbackFeatureGate(enabled: true),
        submitFeedback: (_, draft) async {
          submitted = draft;
          return const ContentFeedbackSubmitResult(
            status: ContentFeedbackSubmitStatus.accepted,
            passportStateAuthoritative: true,
            stampAccepted: true,
            passportCompletedMissionIds: <String>{'beta_scenario'},
            nextMissionId: 'beta_word_work',
          );
        },
      ),
    );
    await _openSheet(tester);

    await tester.tap(find.byKey(const Key('feedback-category-content')));
    await tester.pump();
    expect(
      find.byKey(const Key('feedback-content-signal-fields')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('feedback-content-focus-fields')),
      findsOneWidget,
    );
    expect(find.byKey(const Key('feedback-issue-area-fields')), findsNothing);

    await _tapVisible(tester, const Key('feedback-submit'));
    await tester.pump();
    expect(find.byKey(const Key('feedback-validation-error')), findsOneWidget);
    expect(submitted, isNull);

    await _tapVisible(tester, const Key('feedback-signal-right'));
    await _tapVisible(tester, const Key('feedback-focus-examples'));
    await _tapVisible(tester, const Key('feedback-submit'));
    await tester.pumpAndSettle();

    expect(submitted?.category, FeedbackCategory.content);
    expect(submitted?.contentSignal, FeedbackContentSignal.right);
    expect(submitted?.contentFocus, FeedbackContentFocus.examples);
    expect(submitted?.message, isEmpty);
    expect(find.byKey(const Key('content-feedback-delivered')), findsOneWidget);
    expect(
      find.byKey(const Key('content-feedback-next-mission')),
      findsOneWidget,
    );
  });

  testWidgets('other feedback requires text and hides structured fields', (
    tester,
  ) async {
    ContentFeedbackDraft? submitted;
    await tester.pumpWidget(
      _host(
        gate: const TesterFeedbackFeatureGate(enabled: true),
        submitFeedback: (_, draft) async {
          submitted = draft;
          return const ContentFeedbackSubmitResult(
            status: ContentFeedbackSubmitStatus.accepted,
          );
        },
      ),
    );
    await _openSheet(tester);

    await tester.tap(find.byKey(const Key('feedback-category-other')));
    await tester.pump();
    expect(find.byKey(const Key('feedback-issue-area-fields')), findsNothing);
    expect(
      find.byKey(const Key('feedback-content-signal-fields')),
      findsNothing,
    );

    await _tapVisible(tester, const Key('feedback-submit'));
    await tester.pump();
    expect(find.byKey(const Key('feedback-validation-error')), findsOneWidget);
    expect(submitted, isNull);

    await tester.ensureVisible(find.byKey(const Key('feedback-message')));
    await tester.enterText(
      find.byKey(const Key('feedback-message')),
      'I have another suggestion.',
    );
    await _tapVisible(tester, const Key('feedback-submit'));
    await tester.pumpAndSettle();

    expect(submitted?.category, FeedbackCategory.other);
    expect(submitted?.message, 'I have another suggestion.');
  });

  testWidgets(
    'GameOverCard adds feedback only for a supplied context and keeps actions usable',
    (tester) async {
      var actionTaps = 0;
      await tester.pumpWidget(_gameOverHost(action: () => actionTaps += 1));
      await tester.pump();

      expect(find.byKey(const Key('content-feedback-card')), findsNothing);
      await tester.tap(find.byKey(const Key('game-over-action')));
      expect(actionTaps, 1);

      await tester.pumpWidget(
        _gameOverHost(
          feedbackContext: _feedbackContext,
          action: () => actionTaps += 1,
        ),
      );
      await tester.pump();

      expect(find.byKey(const Key('content-feedback-card')), findsOneWidget);
      await tester.tap(find.byKey(const Key('game-over-action')));
      expect(actionTaps, 2);
    },
  );

  testWidgets('reduce motion keeps the delivered card static', (tester) async {
    await tester.pumpWidget(
      _host(
        disableAnimations: true,
        gate: const TesterFeedbackFeatureGate(enabled: true),
        submitFeedback: (_, __) async => const ContentFeedbackSubmitResult(
          status: ContentFeedbackSubmitStatus.accepted,
          passportStateAuthoritative: true,
          stampAccepted: true,
          passportCompletedMissionIds: <String>{'beta_scenario'},
          nextMissionId: 'beta_word_work',
        ),
      ),
    );
    await _openSheet(tester);
    await tester.tap(find.byKey(const Key('feedback-category-content')));
    await tester.pump();
    await _tapVisible(tester, const Key('feedback-signal-right'));
    await _tapVisible(tester, const Key('feedback-submit'));
    await tester.pumpAndSettle();

    final mascot = tester.widget<Mascot>(find.byType(Mascot));
    expect(mascot.animate, isFalse);
    expect(find.byKey(const Key('content-feedback-delivered')), findsOneWidget);
    expect(tester.binding.hasScheduledFrame, isFalse);
  });

  testWidgets('submission closes the sheet before delivery completes', (
    tester,
  ) async {
    final delivery = Completer<ContentFeedbackSubmitResult>();
    var actionTaps = 0;
    await tester.pumpWidget(
      _gameOverHost(
        feedbackContext: _feedbackContext,
        feedbackSubmitter: (_, __) => delivery.future,
        action: () => actionTaps += 1,
      ),
    );
    await tester.pump();

    await _tapVisible(tester, const Key('content-feedback-open'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('feedback-category-content')));
    await tester.pump();
    await _tapVisible(tester, const Key('feedback-signal-right'));
    await _tapVisible(tester, const Key('feedback-submit'));
    await tester.pumpAndSettle();

    expect(find.byType(SoriSheetShell), findsNothing);
    expect(find.byKey(const Key('content-feedback-pending')), findsOneWidget);
    await tester.tap(find.byKey(const Key('game-over-action')));
    expect(actionTaps, 1);

    delivery.complete(
      const ContentFeedbackSubmitResult(
        status: ContentFeedbackSubmitStatus.accepted,
        passportStateAuthoritative: true,
        stampAccepted: true,
        passportCompletedMissionIds: <String>{'beta_scenario'},
        nextMissionId: 'beta_word_work',
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('content-feedback-delivered')), findsOneWidget);
  });

  testWidgets('pending delivery cannot update a newer completion card', (
    tester,
  ) async {
    final delivery = Completer<ContentFeedbackSubmitResult>();
    var passportReads = 0;
    Future<Set<String>> readPassportState() async {
      passportReads += 1;
      return passportReads == 1
          ? const <String>{}
          : const <String>{'beta_scenario', 'beta_listening'};
    }

    Future<ContentFeedbackSubmitResult> submitFeedback(
      ContentFeedbackContext _,
      ContentFeedbackDraft __,
    ) => delivery.future;

    await tester.pumpWidget(
      _host(
        gate: const TesterFeedbackFeatureGate(enabled: true),
        submitFeedback: submitFeedback,
        readPassportState: readPassportState,
      ),
    );
    await tester.pump();
    await _openSheet(tester);
    await tester.tap(find.byKey(const Key('feedback-category-content')));
    await tester.pump();
    await _tapVisible(tester, const Key('feedback-signal-right'));
    await _tapVisible(tester, const Key('feedback-submit'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('content-feedback-pending')), findsOneWidget);

    await tester.pumpWidget(
      _host(
        feedbackContext: _nextFeedbackContext,
        gate: const TesterFeedbackFeatureGate(enabled: true),
        submitFeedback: submitFeedback,
        readPassportState: readPassportState,
      ),
    );
    await tester.pump();
    expect(find.byKey(const Key('content-feedback-pending')), findsNothing);
    expect(find.byKey(const Key('content-feedback-open')), findsOneWidget);
    expect(
      tester.widget<SoriProgressBar>(find.byType(SoriProgressBar)).value,
      0.4,
    );

    delivery.complete(
      const ContentFeedbackSubmitResult(
        status: ContentFeedbackSubmitStatus.accepted,
        passportStateAuthoritative: true,
        stampAccepted: true,
        passportCompletedMissionIds: <String>{'beta_scenario'},
        nextMissionId: 'beta_word_work',
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('content-feedback-delivered')), findsNothing);
    expect(find.byKey(const Key('content-feedback-open')), findsOneWidget);
    expect(
      tester.widget<SoriProgressBar>(find.byType(SoriProgressBar)).value,
      0.4,
    );
  });

  testWidgets('accepted feedback does not infer that a stamp was accepted', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(
        disableAnimations: true,
        gate: const TesterFeedbackFeatureGate(enabled: true),
        submitFeedback: (_, __) async => const ContentFeedbackSubmitResult(
          status: ContentFeedbackSubmitStatus.accepted,
        ),
      ),
    );
    await _openSheet(tester);
    await tester.tap(find.byKey(const Key('feedback-category-content')));
    await tester.pump();
    await _tapVisible(tester, const Key('feedback-signal-right'));
    await _tapVisible(tester, const Key('feedback-submit'));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('content-feedback-delivered')), findsOneWidget);
    expect(
      find.byKey(const Key('content-feedback-next-mission')),
      findsNothing,
    );
  });

  testWidgets('GameOverCard resolves its submitter from feedback scope', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: AppL10n.localizationsDelegates,
        supportedLocales: AppL10n.supportedLocales,
        home: ContentFeedbackControllerScope(
          featureGate: const TesterFeedbackFeatureGate(enabled: true),
          submitFeedback: (_, __) async => const ContentFeedbackSubmitResult(
            status: ContentFeedbackSubmitStatus.accepted,
          ),
          child: const Scaffold(
            body: GameOverCard(
              headline: 'Result',
              xpGained: 0,
              celebrate: false,
              feedbackContext: _feedbackContext,
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.byKey(const Key('content-feedback-card')), findsOneWidget);
  });
}

Future<void> _openSheet(WidgetTester tester) async {
  await tester.tap(find.byKey(const Key('content-feedback-open')));
  await tester.pumpAndSettle();
}

Future<void> _tapVisible(WidgetTester tester, Key key) async {
  final finder = find.byKey(key);
  await tester.ensureVisible(finder);
  await tester.pump();
  await tester.tap(finder);
  await tester.pump();
}

Widget _host({
  bool disableAnimations = false,
  ContentFeedbackContext feedbackContext = _feedbackContext,
  required TesterFeedbackFeatureGate gate,
  required Future<ContentFeedbackSubmitResult> Function(
    ContentFeedbackContext context,
    ContentFeedbackDraft draft,
  )
  submitFeedback,
  ContentFeedbackPassportStateReader? readPassportState,
}) {
  return MaterialApp(
    locale: const Locale('en'),
    localizationsDelegates: AppL10n.localizationsDelegates,
    supportedLocales: AppL10n.supportedLocales,
    home: ContentFeedbackControllerScope(
      featureGate: gate,
      submitFeedback: submitFeedback,
      readPassportState: readPassportState ?? _emptyPassportState,
      child: MediaQuery(
        data: MediaQueryData(disableAnimations: disableAnimations),
        child: Scaffold(
          body: ContentFeedbackCard(
            feedbackContext: feedbackContext,
            featureGate: gate,
            submitFeedback: submitFeedback,
          ),
        ),
      ),
    ),
  );
}

Future<Set<String>> _emptyPassportState() async => const <String>{};

Widget _gameOverHost({
  ContentFeedbackContext? feedbackContext,
  Future<ContentFeedbackSubmitResult> Function(
    ContentFeedbackContext context,
    ContentFeedbackDraft draft,
  )?
  feedbackSubmitter,
  required VoidCallback action,
}) {
  return MaterialApp(
    locale: const Locale('en'),
    localizationsDelegates: AppL10n.localizationsDelegates,
    supportedLocales: AppL10n.supportedLocales,
    home: MediaQuery(
      data: const MediaQueryData(disableAnimations: true),
      child: Scaffold(
        body: GameOverCard(
          headline: 'Result',
          xpGained: 0,
          celebrate: false,
          feedbackContext: feedbackContext,
          feedbackFeatureGate: const TesterFeedbackFeatureGate(enabled: true),
          feedbackSubmitter:
              feedbackSubmitter ??
              (_, __) async => const ContentFeedbackSubmitResult(
                status: ContentFeedbackSubmitStatus.accepted,
              ),
          actions: [
            ElevatedButton(
              key: const Key('game-over-action'),
              onPressed: action,
              child: const Text('Continue'),
            ),
          ],
        ),
      ),
    ),
  );
}
