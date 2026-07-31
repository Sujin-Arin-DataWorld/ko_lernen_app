import '../models/content_feedback.dart';

const int betaMissionCatalogVersion = 1;

class BetaMission {
  const BetaMission({
    required this.id,
    required this.labelKey,
    required this.allowedContentTypes,
  });

  final String id;
  final String labelKey;
  final Set<String> allowedContentTypes;

  bool matches(ContentFeedbackContext context) =>
      allowedContentTypes.contains(context.contentType);
}

const List<BetaMission> betaMissionCatalog = [
  BetaMission(
    id: 'beta_scenario',
    labelKey: 'testerFeedbackMissionScenario',
    allowedContentTypes: {'scenario'},
  ),
  BetaMission(
    id: 'beta_word_work',
    labelKey: 'testerFeedbackMissionWordWork',
    allowedContentTypes: {
      'vocab_pack',
      'review',
      'custom_wordbook',
      'custom_wordbook_game',
      'legacy_vocab',
    },
  ),
  BetaMission(
    id: 'beta_listening',
    labelKey: 'testerFeedbackMissionListening',
    allowedContentTypes: {'listening'},
  ),
  BetaMission(
    id: 'beta_games',
    labelKey: 'testerFeedbackMissionGames',
    allowedContentTypes: {'game'},
  ),
  BetaMission(
    id: 'beta_language_form',
    labelKey: 'testerFeedbackMissionLanguageForm',
    allowedContentTypes: {
      'grammar_session',
      'hangul_cards',
      'hangul_writing',
      'daily_hangul',
    },
  ),
];

BetaMission? missionFor(ContentFeedbackContext context) {
  for (final mission in betaMissionCatalog) {
    if (mission.matches(context)) return mission;
  }
  return null;
}

BetaMission? nextMission(
  Iterable<String> completedMissionIds,
  ContentFeedbackContext context,
) {
  final completed = completedMissionIds.toSet();
  for (final mission in betaMissionCatalog) {
    if (!completed.contains(mission.id) && mission.matches(context)) {
      return mission;
    }
  }
  return null;
}
