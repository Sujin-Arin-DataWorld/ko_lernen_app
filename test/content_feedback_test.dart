import 'package:flutter/foundation.dart';
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
    test('accepts a complete structured bug report', () {
      final draft = ContentFeedbackDraft(
        category: FeedbackCategory.bug,
        issueArea: FeedbackIssueArea.audio,
        expectedOutcome: 'The next line should play.',
        actualOutcome: 'Playback stopped after one line.',
        bugFrequency: FeedbackBugFrequency.everyTime,
        bugImpact: FeedbackBugImpact.slowsLearning,
      );

      expect(draft.validate().isValid, isTrue);
      expect(draft.toWire()['bugFrequency'], 'every_time');
    });

    test('rejects a partial structured bug report', () {
      final draft = ContentFeedbackDraft(
        category: FeedbackCategory.bug,
        expectedOutcome: 'The next line should play.',
      );

      expect(draft.validate().isValid, isFalse);
    });

    test('keeps a legacy message-only bug draft valid', () {
      const draft = ContentFeedbackDraft(
        category: FeedbackCategory.bug,
        message: 'The audio stopped.',
      );

      expect(draft.validate().isValid, isTrue);
    });

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

    test('serializes paired experience feedback for a Book Result', () {
      const draft = ContentFeedbackDraft(
        category: FeedbackCategory.content,
        experienceSignal: FeedbackExperienceSignal.mixed,
        experienceFocus: FeedbackExperienceFocus.translation,
      );

      expect(draft.validate().isValid, isTrue);
      expect(draft.toWire()['experienceSignal'], 'mixed');
      expect(draft.toWire()['experienceFocus'], 'translation');
    });

    test('serializes audio as a learning content focus', () {
      const draft = ContentFeedbackDraft(
        category: FeedbackCategory.content,
        contentFocus: FeedbackContentFocus.audio,
      );

      expect(draft.validate().isValid, isTrue);
      expect(draft.toWire()['contentFocus'], 'audio');
    });

    test('accepts exactly 1,000 characters and rejects 1,001', () {
      final accepted = ContentFeedbackDraft(
        category: FeedbackCategory.other,
        message: 'x' * contentFeedbackMaxMessageLength,
      );
      final rejected = ContentFeedbackDraft(
        category: FeedbackCategory.other,
        message: 'x' * (contentFeedbackMaxMessageLength + 1),
      );

      expect(accepted.validate().isValid, isTrue);
      expect(rejected.validate().isValid, isFalse);
    });

    test('rejects other feedback without nonblank text', () {
      const draft = ContentFeedbackDraft(
        category: FeedbackCategory.other,
        message: '   ',
      );

      expect(draft.validate().isValid, isFalse);
      expect(draft.validate().errors, contains('messageRequired'));
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

  group('ContentFeedbackContext', () {
    test('rejects Firestore-invalid completion document IDs', () {
      const invalidIds = <String>['contains/slash', '.', '..'];

      for (final completionId in invalidIds) {
        final invalid = ContentFeedbackContext(
          completionId: completionId,
          contentType: 'scenario',
          contentId: 'cafe-order',
          contentLabel: 'At the cafe',
          level: 'A1',
          scoreSummary: '7/10',
        ).validate();
        expect(invalid.isValid, isFalse, reason: completionId);
        expect(invalid.errors, contains('completionId'), reason: completionId);
      }

      const uuidContext = ContentFeedbackContext(
        completionId: '550e8400-e29b-41d4-a716-446655440000',
        contentType: 'scenario',
        contentId: 'cafe-order',
        contentLabel: 'At the cafe',
        level: 'A1',
        scoreSummary: '7/10',
      );
      expect(uuidContext.validate().isValid, isTrue);
    });
  });

  group('TesterFeedbackFeatureGate', () {
    test('is disabled by default on Android without a Dart define', () {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      addTearDown(() => debugDefaultTargetPlatformOverride = null);

      expect(const TesterFeedbackFeatureGate().isEnabled, isFalse);
    });

    test('allows tests to inject an enabled gate without a Dart define', () {
      expect(const TesterFeedbackFeatureGate(enabled: true).isEnabled, isTrue);
    });
  });

  group('BetaMissionCatalog', () {
    test('maps every supported content type to the stable mission catalog', () {
      const expectedCatalog = <String, ({String labelKey, Set<String> types})>{
        'beta_scenario': (
          labelKey: 'testerFeedbackMissionScenario',
          types: {'scenario'},
        ),
        'beta_word_work': (
          labelKey: 'testerFeedbackMissionWordWork',
          types: {
            'vocab_pack',
            'review',
            'custom_wordbook',
            'custom_wordbook_game',
            'legacy_vocab',
          },
        ),
        'beta_listening': (
          labelKey: 'testerFeedbackMissionListening',
          types: {'listening'},
        ),
        'beta_games': (labelKey: 'testerFeedbackMissionGames', types: {'game'}),
        'beta_language_form': (
          labelKey: 'testerFeedbackMissionLanguageForm',
          types: {
            'grammar_session',
            'hangul_cards',
            'hangul_writing',
            'daily_hangul',
          },
        ),
      };

      expect(betaMissionCatalogVersion, 1);
      expect(
        betaMissionCatalog.map((mission) => mission.id),
        expectedCatalog.keys,
      );

      for (final mission in betaMissionCatalog) {
        final expected = expectedCatalog[mission.id];
        expect(expected, isNotNull, reason: mission.id);
        expect(mission.labelKey, expected!.labelKey, reason: mission.id);
        expect(mission.allowedContentTypes, expected.types, reason: mission.id);

        for (final contentType in expected.types) {
          final mappedContext = ContentFeedbackContext(
            completionId: 'completion-$contentType',
            contentType: contentType,
            contentId: 'content-$contentType',
            contentLabel: contentType,
            scoreSummary: 'complete',
          );
          expect(
            missionFor(mappedContext)?.id,
            mission.id,
            reason: contentType,
          );
          expect(
            nextMission(const <String>{}, mappedContext)?.id,
            mission.id,
            reason: contentType,
          );
          expect(
            nextMission({mission.id}, mappedContext),
            isNull,
            reason: contentType,
          );
        }
      }
    });

    test('selects the first incomplete matching mission', () {
      final mission = nextMission({'beta_scenario'}, context);

      expect(mission, isNull);
      expect(nextMission(const <String>{}, context)?.id, 'beta_scenario');
    });
  });
}
