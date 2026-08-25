import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ko_lernen_app/config/tester_feedback_feature.dart';
import 'package:ko_lernen_app/l10n/generated/app_localizations.dart';
import 'package:ko_lernen_app/models/content_feedback.dart';
import 'package:ko_lernen_app/services/content_feedback_service.dart';
import 'package:ko_lernen_app/widgets/sori/button.dart';
import 'package:ko_lernen_app/widgets/sori/content_feedback_card.dart';
import 'package:ko_lernen_app/widgets/sori/content_feedback_sheet.dart';
import 'package:ko_lernen_app/widgets/sori/chip.dart';
import 'package:ko_lernen_app/widgets/sori/game_reward.dart';
import 'package:ko_lernen_app/widgets/sori/character_clip.dart';
import 'package:ko_lernen_app/widgets/sori/mascot.dart';
import 'package:ko_lernen_app/widgets/sori/mascot_preference.dart';
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

const _bookFeedbackContext = ContentFeedbackContext(
  completionId: 'completion-book-1',
  contentType: 'book_analysis',
  contentId: 'book-analysis:result',
  contentLabel: 'Book analysis',
  scoreSummary: 'online:3-2-1',
);

const _questFeedbackContext = ContentFeedbackContext(
  completionId: 'completion-quest-1',
  contentType: 'quest_reward',
  contentId: 'quest:daily-1',
  contentLabel: 'Daily quest',
  scoreSummary: 'daily:1',
);

const _milestoneFeedbackContext = ContentFeedbackContext(
  completionId: 'completion-milestone-1',
  contentType: 'milestone',
  contentId: 'milestone:streak-7',
  contentLabel: 'Seven day streak',
  scoreSummary: 'streak:7',
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
    await _submitLearningPulse(tester);
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
    await _submitLearningPulse(tester);
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
    expect(
      find.descendant(
        of: find.byType(SoriSheetShell),
        matching: find.text('Tiger Pulse'),
      ),
      findsOneWidget,
    );
    expect(find.byKey(const Key('pulse-signal-right')), findsOneWidget);
    expect(find.byKey(const Key('pulse-focus-fields')), findsNothing);
    expect(find.byKey(const Key('feedback-category-bug')), findsOneWidget);
    expect(find.byKey(const Key('feedback-category-other')), findsOneWidget);
    expect(find.byKey(const Key('feedback-category-content')), findsNothing);
  });

  testWidgets('메시지-온리 버그 신고를 보낼 수 있다 — 구조화 필드 없이도', (
    tester,
  ) async {
    // draft.validate()·서버 validatePayload 는 처음부터 메시지-온리 버그를
    // 허용했는데 시트 _canSubmit 만 구조화 전부를 요구해 UI에서 막혀 있었다.
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

    await tester.ensureVisible(find.byKey(const Key('feedback-message')));
    await tester.enterText(
      find.byKey(const Key('feedback-message')),
      'The audio stopped after the first line.',
    );
    await tester.pump();
    expect(
      tester.widget<SoriButton>(find.byKey(const Key('feedback-submit'))).onTap,
      isNotNull,
    );
    await _tapVisible(tester, const Key('feedback-submit'));
    await tester.pumpAndSettle();

    expect(submitted?.category, FeedbackCategory.bug);
    expect(submitted?.message, 'The audio stopped after the first line.');
    // 빈 컨트롤러의 '' 가 와이어로 새면 서버 optionalString(minLength 1)이
    // 페이로드 전체를 거부한다 — null 로 남는 것까지가 계약이다.
    expect(submitted?.expectedOutcome, isNull);
    expect(submitted?.actualOutcome, isNull);
    expect(submitted?.bugFrequency, isNull);
    expect(submitted?.bugImpact, isNull);
  });

  testWidgets('bug feedback rejects an incomplete structured form', (
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
    expect(find.byKey(const Key('bug-expected-outcome')), findsOneWidget);
    expect(find.byKey(const Key('bug-actual-outcome')), findsOneWidget);
    expect(find.byKey(const Key('bug-frequency-everyTime')), findsOneWidget);
    expect(find.byKey(const Key('bug-impact-canContinue')), findsOneWidget);

    expect(
      tester.widget<SoriButton>(find.byKey(const Key('feedback-submit'))).onTap,
      isNull,
    );
    await _tapVisible(tester, const Key('feedback-submit'));
    expect(submitted, isNull);

    await tester.ensureVisible(find.byKey(const Key('bug-expected-outcome')));
    await tester.enterText(
      find.byKey(const Key('bug-expected-outcome')),
      'The next question should open.',
    );
    await tester.ensureVisible(find.byKey(const Key('bug-actual-outcome')));
    await tester.enterText(
      find.byKey(const Key('bug-actual-outcome')),
      'The button stayed disabled.',
    );
    await _tapVisible(tester, const Key('feedback-issue-answer'));
    await _tapVisible(tester, const Key('bug-frequency-sometimes'));
    expect(
      tester.widget<SoriButton>(find.byKey(const Key('feedback-submit'))).onTap,
      isNull,
    );
    await _tapVisible(tester, const Key('bug-impact-slowsLearning'));
    expect(
      tester.widget<SoriButton>(find.byKey(const Key('feedback-submit'))).onTap,
      isNotNull,
    );
    await _tapVisible(tester, const Key('feedback-submit'));
    await tester.pumpAndSettle();

    expect(submitted?.category, FeedbackCategory.bug);
    expect(submitted?.issueArea, FeedbackIssueArea.answer);
    expect(submitted?.expectedOutcome, 'The next question should open.');
    expect(submitted?.actualOutcome, 'The button stayed disabled.');
    expect(submitted?.bugFrequency, FeedbackBugFrequency.sometimes);
    expect(submitted?.bugImpact, FeedbackBugImpact.slowsLearning);
    expect(find.byKey(const Key('content-feedback-pending')), findsOneWidget);
  });

  testWidgets('learning Tiger Pulse needs a signal and focus before send', (
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

    await _tapVisible(tester, const Key('pulse-signal-right'));
    expect(find.byKey(const Key('pulse-focus-fields')), findsOneWidget);
    expect(
      tester.widget<SoriButton>(find.byKey(const Key('feedback-submit'))).onTap,
      isNull,
    );
    await _tapVisible(tester, const Key('pulse-focus-examples'));
    expect(
      tester.widget<SoriButton>(find.byKey(const Key('feedback-submit'))).onTap,
      isNotNull,
    );
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

  testWidgets('book Tiger Pulse yields experience fields', (tester) async {
    ContentFeedbackDraft? submitted;
    await tester.pumpWidget(
      _host(
        feedbackContext: _bookFeedbackContext,
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

    expect(find.byKey(const Key('pulse-experience-positive')), findsOneWidget);
    expect(find.byKey(const Key('pulse-signal-right')), findsNothing);
    await _tapVisible(tester, const Key('pulse-experience-mixed'));
    expect(
      find.byKey(const Key('pulse-experience-focus-fields')),
      findsOneWidget,
    );
    await _tapVisible(tester, const Key('pulse-experience-focus-grammar'));
    await _tapVisible(tester, const Key('feedback-submit'));
    await tester.pumpAndSettle();

    expect(submitted?.category, FeedbackCategory.content);
    expect(submitted?.experienceSignal, FeedbackExperienceSignal.mixed);
    expect(submitted?.experienceFocus, FeedbackExperienceFocus.grammar);
    expect(submitted?.contentSignal, isNull);
    expect(submitted?.contentFocus, isNull);
    expect(
      find.text('Thanks. Your feedback helps us improve.'),
      findsOneWidget,
    );
  });

  testWidgets('quest and milestone use context-specific experience choices', (
    tester,
  ) async {
    for (final testCase in const [
      (
        context: _questFeedbackContext,
        signalLabel: 'Very motivating',
        focusKey: Key('pulse-experience-focus-goal'),
        expectedFocus: FeedbackExperienceFocus.goal,
      ),
      (
        context: _milestoneFeedbackContext,
        signalLabel: 'Loved it',
        focusKey: Key('pulse-experience-focus-timing'),
        expectedFocus: FeedbackExperienceFocus.timing,
      ),
    ]) {
      ContentFeedbackDraft? submitted;
      await tester.pumpWidget(
        _host(
          feedbackContext: testCase.context,
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

      expect(find.text(testCase.signalLabel), findsOneWidget);
      await _tapVisible(tester, const Key('pulse-experience-positive'));
      await _tapVisible(tester, testCase.focusKey);
      await _tapVisible(tester, const Key('feedback-submit'));
      await tester.pumpAndSettle();

      expect(submitted?.experienceSignal, FeedbackExperienceSignal.positive);
      expect(submitted?.experienceFocus, testCase.expectedFocus);
    }
  });

  testWidgets('context change discards stale experience selections', (
    tester,
  ) async {
    final feedbackContext = ValueNotifier<ContentFeedbackContext>(
      _bookFeedbackContext,
    );
    addTearDown(feedbackContext.dispose);
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: AppL10n.localizationsDelegates,
        supportedLocales: AppL10n.supportedLocales,
        home: const Scaffold(body: SizedBox.shrink()),
      ),
    );
    final navigator = tester.state<NavigatorState>(find.byType(Navigator));
    final result = navigator.push<ContentFeedbackDraft>(
      MaterialPageRoute(
        builder: (_) => ValueListenableBuilder<ContentFeedbackContext>(
          valueListenable: feedbackContext,
          builder: (_, currentContext, __) => Scaffold(
            body: SoriSheetShell(
              showHandle: false,
              child: ContentFeedbackSheet(feedbackContext: currentContext),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await _tapVisible(tester, const Key('pulse-experience-mixed'));
    await _tapVisible(tester, const Key('pulse-experience-focus-grammar'));
    expect(
      tester.widget<SoriButton>(find.byKey(const Key('feedback-submit'))).onTap,
      isNotNull,
    );

    feedbackContext.value = _questFeedbackContext;
    await tester.pump();

    expect(
      find.byKey(const Key('pulse-experience-focus-fields')),
      findsNothing,
    );
    expect(
      tester.widget<SoriButton>(find.byKey(const Key('feedback-submit'))).onTap,
      isNull,
    );
    await _tapVisible(tester, const Key('pulse-experience-positive'));
    expect(
      tester.widget<SoriButton>(find.byKey(const Key('feedback-submit'))).onTap,
      isNull,
    );
    await _tapVisible(tester, const Key('pulse-experience-focus-goal'));
    expect(
      tester.widget<SoriButton>(find.byKey(const Key('feedback-submit'))).onTap,
      isNotNull,
    );
    await _tapVisible(tester, const Key('feedback-submit'));
    await tester.pumpAndSettle();

    final submitted = await result;
    expect(submitted?.experienceSignal, FeedbackExperienceSignal.positive);
    expect(submitted?.experienceFocus, FeedbackExperienceFocus.goal);
  });

  testWidgets('feedback-only context hides Passport UI and restore', (
    tester,
  ) async {
    var passportReads = 0;
    await tester.pumpWidget(
      _host(
        feedbackContext: _bookFeedbackContext,
        gate: const TesterFeedbackFeatureGate(enabled: true),
        submitFeedback: (_, __) async => const ContentFeedbackSubmitResult(
          status: ContentFeedbackSubmitStatus.accepted,
        ),
        readPassportState: () async {
          passportReads += 1;
          return const <String>{'beta_scenario'};
        },
      ),
    );
    await tester.pump();

    expect(find.byType(SoriProgressBar), findsNothing);
    expect(passportReads, 0);
  });

  testWidgets(
    'structured feedback choices stay tappable with 44px targets on a phone',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        _host(
          locale: const Locale('de'),
          gate: const TesterFeedbackFeatureGate(enabled: true),
          submitFeedback: (_, __) async => const ContentFeedbackSubmitResult(
            status: ContentFeedbackSubmitStatus.accepted,
          ),
        ),
      );
      await _openSheet(tester);

      expect(
        find.descendant(
          of: find.byType(SoriSheetShell),
          matching: find.text('Tiger-Check'),
        ),
        findsOneWidget,
      );
      await _expectTargetHeight(tester, const Key('feedback-category-bug'));
      await _expectTargetHeight(tester, const Key('feedback-category-other'));
      await _expectInteractiveChoiceTargets(tester, [
        for (final signal in FeedbackContentSignal.values)
          Key('pulse-signal-${signal.name}'),
      ]);
      await _expectInteractiveChoiceTargets(tester, const [
        Key('pulse-focus-explanation'),
        Key('pulse-focus-examples'),
        Key('pulse-focus-questions'),
        Key('pulse-focus-pace'),
        Key('pulse-focus-audio'),
        Key('pulse-focus-translation'),
      ]);

      await _tapVisible(tester, const Key('feedback-category-bug'));
      await _expectInteractiveChoiceTargets(tester, [
        for (final area in FeedbackIssueArea.values)
          Key('feedback-issue-${area.name}'),
      ]);
      await _expectInteractiveChoiceTargets(tester, [
        for (final frequency in FeedbackBugFrequency.values)
          Key('bug-frequency-${frequency.name}'),
        for (final impact in FeedbackBugImpact.values)
          Key('bug-impact-${impact.name}'),
      ]);
    },
  );

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
    expect(find.byKey(const Key('pulse-signal-fields')), findsNothing);

    expect(
      tester.widget<SoriButton>(find.byKey(const Key('feedback-submit'))).onTap,
      isNull,
    );
    await _tapVisible(tester, const Key('feedback-submit'));
    expect(submitted, isNull);

    await tester.ensureVisible(find.byKey(const Key('feedback-message')));
    await tester.enterText(
      find.byKey(const Key('feedback-message')),
      'I have another suggestion.',
    );
    await tester.pump();
    expect(
      tester.widget<SoriButton>(find.byKey(const Key('feedback-submit'))).onTap,
      isNotNull,
    );
    await _tapVisible(tester, const Key('feedback-submit'));
    await tester.pumpAndSettle();

    expect(submitted?.category, FeedbackCategory.other);
    expect(submitted?.message, 'I have another suggestion.');
  });

  testWidgets(
    'returning from Bug or Other to Tiger Pulse does not submit hidden route state',
    (tester) async {
      for (final testCase in const [
        (name: 'Bug', categoryKey: Key('feedback-category-bug'), other: false),
        (
          name: 'Other',
          categoryKey: Key('feedback-category-other'),
          other: true,
        ),
      ]) {
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
        await tester.pump();
        await _openSheet(tester);
        await _tapVisible(tester, testCase.categoryKey);

        if (testCase.other) {
          await tester.ensureVisible(find.byKey(const Key('feedback-message')));
          await tester.enterText(
            find.byKey(const Key('feedback-message')),
            'Other-only note that must not become a Pulse note.',
          );
        } else {
          await _tapVisible(tester, const Key('feedback-issue-answer'));
          await tester.ensureVisible(
            find.byKey(const Key('bug-expected-outcome')),
          );
          await tester.enterText(
            find.byKey(const Key('bug-expected-outcome')),
            'The next question should open.',
          );
          await tester.ensureVisible(
            find.byKey(const Key('bug-actual-outcome')),
          );
          await tester.enterText(
            find.byKey(const Key('bug-actual-outcome')),
            'The button stayed disabled.',
          );
          await tester.ensureVisible(find.byKey(const Key('feedback-message')));
          await tester.enterText(
            find.byKey(const Key('feedback-message')),
            'Bug-only note that must not become a Pulse note.',
          );
        }

        await _scrollFeedbackSheetToBottom(tester);
        await _tapVisible(tester, const Key('feedback-cancel'));
        expect(
          find.byKey(const Key('pulse-signal-fields')),
          findsOneWidget,
          reason: '${testCase.name} must return to the learning Pulse.',
        );
        await _submitLearningPulse(tester);
        await tester.pumpAndSettle();

        expect(submitted?.category, FeedbackCategory.content);
        expect(submitted?.message, isEmpty);
        expect(submitted?.contentSignal, FeedbackContentSignal.right);
        expect(submitted?.contentFocus, FeedbackContentFocus.examples);
        expect(submitted?.issueArea, isNull);
        expect(submitted?.expectedOutcome, isNull);
        expect(submitted?.actualOutcome, isNull);
        expect(submitted?.bugFrequency, isNull);
        expect(submitted?.bugImpact, isNull);
        expect(submitted?.experienceSignal, isNull);
        expect(submitted?.experienceFocus, isNull);

        // A fresh root prevents the previous MaterialApp Navigator from
        // retaining a delivered card between the two route variants.
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pumpAndSettle();
      }
    },
  );

  testWidgets(
    'large system text keeps feedback-only experience routes usable without overflow',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(360, 640));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      for (final route in const [
        (
          context: _bookFeedbackContext,
          focusKey: Key('pulse-experience-focus-grammar'),
          expectedFocus: FeedbackExperienceFocus.grammar,
        ),
        (
          context: _questFeedbackContext,
          focusKey: Key('pulse-experience-focus-goal'),
          expectedFocus: FeedbackExperienceFocus.goal,
        ),
        (
          context: _milestoneFeedbackContext,
          focusKey: Key('pulse-experience-focus-timing'),
          expectedFocus: FeedbackExperienceFocus.timing,
        ),
      ]) {
        ContentFeedbackDraft? submitted;
        await tester.pumpWidget(
          _host(
            feedbackContext: route.context,
            textScaler: TextScaler.linear(2),
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

        final sheetContext = tester.element(find.byType(ContentFeedbackSheet));
        expect(
          MediaQuery.textScalerOf(sheetContext).scale(10),
          lessThanOrEqualTo(13.01),
        );
        await _tapVisible(tester, const Key('pulse-experience-positive'));
        await _tapVisible(tester, route.focusKey);
        expect(tester.takeException(), isNull);
        await _tapVisible(tester, const Key('feedback-submit'));
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(submitted?.category, FeedbackCategory.content);
        expect(submitted?.experienceSignal, FeedbackExperienceSignal.positive);
        expect(submitted?.experienceFocus, route.expectedFocus);
      }
    },
  );

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
    await _submitLearningPulse(tester);
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
    await _submitLearningPulse(tester);
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
    await _submitLearningPulse(tester);
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

  testWidgets('accepted feedback does not infer Passport celebration', (
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
    await _openSheet(tester);
    await _submitLearningPulse(tester);
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.byKey(const Key('content-feedback-delivered')), findsOneWidget);
    expect(
      tester.widget<Mascot>(find.byType(Mascot)).emotion,
      MascotEmotion.smile,
    );
    expect(_hasCelebrationPainter(), isFalse);
    expect(
      find.byKey(const Key('content-feedback-next-mission')),
      findsNothing,
    );
  });

  testWidgets('non-authoritative stampAccepted does not celebrate', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(
        gate: const TesterFeedbackFeatureGate(enabled: true),
        submitFeedback: (_, __) async => const ContentFeedbackSubmitResult(
          status: ContentFeedbackSubmitStatus.accepted,
          passportStateAuthoritative: false,
          stampAccepted: true,
          passportCompletedMissionIds: <String>{'beta_scenario'},
          nextMissionId: 'beta_word_work',
        ),
      ),
    );
    await _openSheet(tester);
    await _submitLearningPulse(tester);
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('Stamp earned!'), findsNothing);
    expect(
      tester.widget<Mascot>(find.byType(Mascot)).emotion,
      MascotEmotion.smile,
    );
    expect(_hasCelebrationPainter(), isFalse);
    expect(
      find.byKey(const Key('content-feedback-next-mission')),
      findsNothing,
    );
  });

  testWidgets('stampAccepted alone triggers Passport celebration', (
    tester,
  ) async {
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
      ),
    );
    await _openSheet(tester);
    await _submitLearningPulse(tester);
    await tester.pump(const Duration(milliseconds: 500));

    expect(
      tester.widget<Mascot>(find.byType(Mascot)).emotion,
      MascotEmotion.celebrate,
    );
    expect(_hasCelebrationPainter(), isTrue);
    await tester.pumpAndSettle();
  });

  testWidgets(
    'pending retry delivers the queued feedback without submitting it again',
    (tester) async {
      var submitCalls = 0;
      var resumeCalls = 0;
      final retry = Completer<ContentFeedbackResumeResult>();
      await tester.pumpWidget(
        _host(
          gate: const TesterFeedbackFeatureGate(enabled: true),
          submitFeedback: (_, __) async {
            submitCalls += 1;
            return const ContentFeedbackSubmitResult(
              status: ContentFeedbackSubmitStatus.pending,
              feedbackId: 'feedback-pending',
            );
          },
          resumePending: () {
            resumeCalls += 1;
            return retry.future;
          },
        ),
      );
      await _openSheet(tester);
      await _submitLearningPulse(tester);
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('content-feedback-pending')), findsOneWidget);
      final retryButton = find.byKey(
        const Key('content-feedback-retry-pending'),
      );
      expect(retryButton, findsOneWidget);

      await tester.tap(retryButton);
      await tester.pump();

      expect(resumeCalls, 1);
      expect(tester.widget<SoriButton>(retryButton).onTap, isNull);
      retry.complete(
        const ContentFeedbackResumeResult(
          deliveredFeedbackIds: <String>{'feedback-pending'},
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('content-feedback-delivered')),
        findsOneWidget,
      );
      expect(find.byKey(const Key('content-feedback-pending')), findsNothing);
      expect(submitCalls, 1);
      expect(_hasCelebrationPainter(), isFalse);
    },
  );

  testWidgets(
    'automatic resume reconciles only its matching pending feedback ID',
    (tester) async {
      var submitCalls = 0;
      final deliveries = ContentFeedbackResumeDeliveryNotifier();
      addTearDown(deliveries.dispose);
      await tester.pumpWidget(
        _host(
          gate: const TesterFeedbackFeatureGate(enabled: true),
          resumeDeliveryNotifier: deliveries,
          submitFeedback: (_, __) async {
            submitCalls += 1;
            return const ContentFeedbackSubmitResult(
              status: ContentFeedbackSubmitStatus.pending,
              feedbackId: 'feedback-pending',
            );
          },
        ),
      );
      await _openSheet(tester);
      await _submitLearningPulse(tester);
      await tester.pumpAndSettle();

      deliveries.report(
        const ContentFeedbackResumeResult(
          deliveredFeedbackIds: <String>{'other-feedback'},
        ),
      );
      await tester.pump();

      expect(find.byKey(const Key('content-feedback-pending')), findsOneWidget);
      expect(
        find.byKey(const Key('content-feedback-retry-pending')),
        findsOneWidget,
      );

      deliveries.report(
        const ContentFeedbackResumeResult(
          deliveredFeedbackIds: <String>{'feedback-pending'},
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('content-feedback-delivered')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('content-feedback-retry-pending')),
        findsNothing,
      );
      expect(submitCalls, 1);
      expect(_hasCelebrationPainter(), isFalse);
      expect(
        find.byKey(const Key('content-feedback-next-mission')),
        findsNothing,
      );
    },
  );

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
          resumePending: _emptyResumeResult,
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

  testWidgets(
    'GameOverCard forwards the selected preferred mascot to feedback when no override is set',
    (tester) async {
      final originalKind = MascotPreference.kind.value;
      final originalPreference = MascotPreference.preference.value;
      addTearDown(() {
        MascotPreference.kind.value = originalKind;
        MascotPreference.preference.value = originalPreference;
      });
      MascotPreference.kind.value = MascotKind.magpie;
      MascotPreference.preference.value = CompanionPreference.magpie;

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
            resumePending: _emptyResumeResult,
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

      final feedbackCard = tester.widget<ContentFeedbackCard>(
        find.byType(ContentFeedbackCard),
      );
      expect(feedbackCard.mascotKind, MascotKind.magpie);
    },
  );

  testWidgets('GameOverCard keeps an explicit no-companion result neutral', (
    tester,
  ) async {
    final original = MascotPreference.preference.value;
    MascotPreference.preference.value = CompanionPreference.none;
    addTearDown(() => MascotPreference.preference.value = original);

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: GameOverCard(headline: 'Result', xpGained: 0, celebrate: false),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Result'), findsOneWidget);
    expect(find.byType(Mascot), findsNothing);
    expect(find.byType(CharacterClipPlayer), findsNothing);
  });
}

Future<void> _openSheet(WidgetTester tester) async {
  await tester.tap(find.byKey(const Key('content-feedback-open')));
  await tester.pumpAndSettle();
}

Future<void> _submitLearningPulse(WidgetTester tester) async {
  await _tapVisible(tester, const Key('pulse-signal-right'));
  await _tapVisible(tester, const Key('pulse-focus-examples'));
  await _tapVisible(tester, const Key('feedback-submit'));
}

Future<void> _scrollFeedbackSheetToBottom(WidgetTester tester) async {
  final scrollable = find.descendant(
    of: find.byType(SoriSheetShell),
    matching: find.byType(Scrollable),
  );
  await tester.drag(scrollable.first, const Offset(0, -600));
  await tester.pumpAndSettle();
}

Future<void> _tapVisible(WidgetTester tester, Key key) async {
  final finder = find.byKey(key);
  await tester.ensureVisible(finder);
  await tester.pump();
  await tester.tap(finder);
  await tester.pump();
}

Future<void> _expectTargetHeight(WidgetTester tester, Key key) async {
  final target = find.byKey(key);
  await tester.ensureVisible(target);
  await tester.pump();
  expect(tester.getSize(target).height, greaterThanOrEqualTo(44));
}

bool _hasCelebrationPainter() => find
    .byWidgetPredicate(
      (widget) =>
          widget is CustomPaint &&
          widget.painter?.runtimeType.toString() == '_ConfettiPainter',
    )
    .evaluate()
    .isNotEmpty;

Future<void> _expectInteractiveChoiceTargets(
  WidgetTester tester,
  Iterable<Key> keys,
) async {
  final sheet = find.byType(SoriSheetShell);
  for (final key in keys) {
    final choice = find.byKey(key);
    await tester.ensureVisible(choice);
    await tester.pump();
    expect(tester.getSize(choice).height, greaterThanOrEqualTo(44));
    final choiceRect = tester.getRect(choice);
    final sheetRect = tester.getRect(sheet);
    expect(choiceRect.top, greaterThanOrEqualTo(sheetRect.top));
    expect(choiceRect.bottom, lessThanOrEqualTo(sheetRect.bottom));

    await tester.tap(choice);
    await tester.pump();
    final widget = tester.widget<Widget>(choice);
    if (widget is SoriChip) {
      expect(widget.selected, isTrue);
    } else if (widget is SoriButton) {
      expect(widget.variant, SoriButtonVariant.filled);
    } else {
      fail('Expected a feedback choice to be a SoriChip or SoriButton.');
    }
  }
}

Widget _host({
  bool disableAnimations = false,
  TextScaler? textScaler,
  Locale locale = const Locale('en'),
  ContentFeedbackContext feedbackContext = _feedbackContext,
  required TesterFeedbackFeatureGate gate,
  required Future<ContentFeedbackSubmitResult> Function(
    ContentFeedbackContext context,
    ContentFeedbackDraft draft,
  )
  submitFeedback,
  Future<ContentFeedbackResumeResult> Function() resumePending =
      _emptyResumeResult,
  ContentFeedbackResumeDeliveryNotifier? resumeDeliveryNotifier,
  ContentFeedbackPassportStateReader? readPassportState,
}) {
  return MaterialApp(
    locale: locale,
    localizationsDelegates: AppL10n.localizationsDelegates,
    supportedLocales: AppL10n.supportedLocales,
    home: ContentFeedbackControllerScope(
      featureGate: gate,
      submitFeedback: submitFeedback,
      resumePending: resumePending,
      resumeDeliveryNotifier: resumeDeliveryNotifier,
      readPassportState: readPassportState ?? _emptyPassportState,
      child: MediaQuery(
        data: MediaQueryData(
          disableAnimations: disableAnimations,
          textScaler: textScaler ?? TextScaler.noScaling,
        ),
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

Future<ContentFeedbackResumeResult> _emptyResumeResult() async =>
    const ContentFeedbackResumeResult();

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
