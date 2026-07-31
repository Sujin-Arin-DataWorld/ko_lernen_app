import 'package:flutter_test/flutter_test.dart';
import 'package:ko_lernen_app/config/tester_feedback_feature.dart';
import 'package:ko_lernen_app/data/beta_mission_catalog.dart';
import 'package:ko_lernen_app/models/content_feedback.dart';

void main() {
  const context = ContentFeedbackContext(
    completionId: 'completion-42',
    contentType: 'scenario',
    contentId: 'cafe-order',
    contentLabel: 'At the cafe',
    level: 'A1',
    scoreSummary: '7/10',
  );

  group('ContentFeedbackDraft', () {
    test('rejects a bug report without a message', () {
      const draft = ContentFeedbackDraft(category: FeedbackCategory.bug);

      expect(draft.validate().isValid, isFalse);
    });

    test('accepts content feedback with structured signals and no message', () {
      const draft = ContentFeedbackDraft(
        category: FeedbackCategory.content,
        contentSignal: FeedbackContentSignal.tooHard,
        contentFocus: FeedbackContentFocus.examples,
      );

      expect(draft.validate().isValid, isTrue);
      expect(draft.toWire()['message'], '');
    });

    test('rejects free text beyond 1,000 characters', () {
      final draft = ContentFeedbackDraft(
        category: FeedbackCategory.other,
        message: 'x' * 1001,
      );

      expect(draft.validate().isValid, isFalse);
    });

    test('serializes feedback and completion identifiers separately', () {
      const submission = ContentFeedbackSubmission(
        feedbackId: 'retry-token-7',
        context: context,
        draft: ContentFeedbackDraft(
          category: FeedbackCategory.bug,
          message: 'The audio stops after one word.',
          issueArea: FeedbackIssueArea.audio,
        ),
        appVersion: '2.0.1+6',
        platform: 'android',
        locale: 'de',
      );

      final wire = submission.toWire();

      expect(submission.validate().isValid, isTrue);
      expect(wire['feedbackId'], 'retry-token-7');
      expect(wire['completionId'], 'completion-42');
      expect(wire.containsKey('rawAnswer'), isFalse);
      expect(wire['issueArea'], 'audio');
    });
  });

  group('TesterFeedbackFeatureGate', () {
    test('is disabled by default without a Dart define', () {
      expect(const TesterFeedbackFeatureGate().isEnabled, isFalse);
    });

    test('allows tests to inject an enabled gate without a Dart define', () {
      expect(const TesterFeedbackFeatureGate(enabled: true).isEnabled, isTrue);
    });
  });

  group('BetaMissionCatalog', () {
    test('maps every supported content type to its stable mission', () {
      expect(missionFor(context)?.id, 'beta_scenario');
      expect(
        missionFor(
          const ContentFeedbackContext(
            completionId: 'completion-43',
            contentType: 'review',
            contentId: 'today',
            contentLabel: 'Today',
            scoreSummary: '4 cards',
          ),
        )?.id,
        'beta_word_work',
      );
      expect(
        missionFor(
          const ContentFeedbackContext(
            completionId: 'completion-44',
            contentType: 'grammar_session',
            contentId: 'particles',
            contentLabel: 'Particles',
            scoreSummary: 'complete',
          ),
        )?.id,
        'beta_language_form',
      );
    });

    test('selects the first incomplete matching mission', () {
      final mission = nextMission({'beta_scenario'}, context);

      expect(mission, isNull);
      expect(nextMission(const <String>{}, context)?.id, 'beta_scenario');
    });
  });
}
