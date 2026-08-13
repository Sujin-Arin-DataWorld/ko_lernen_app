import '../data/quest_catalog.dart';
import '../models/quest.dart';

enum QuestActionLabelKey {
  openQuests,
  openVocabulary,
  openScenarios,
  practicePronunciation,
  playKkeunmari,
  openHangul,
  openCalligraphy,
  openToday,
  openGye,
  playChosung,
  seasonOpens,
}

class QuestAction {
  const QuestAction({
    required this.questId,
    required this.labelKey,
    this.route,
    this.arguments,
    this.seasonOpensAt,
  });
  final String questId;
  final QuestActionLabelKey labelKey;
  final String? route;
  final Object? arguments;
  final DateTime? seasonOpensAt;
}

abstract final class QuestActionResolver {
  static List<QuestAction> all({DateTime? now}) => [
    for (final definition in kQuestCatalog)
      resolve(definition.id, now: now ?? DateTime.now()),
  ];

  static QuestAction resolve(String questId, {required DateTime now}) {
    final definition = kQuestById[questId];
    if (definition == null) {
      return QuestAction(
        questId: questId,
        labelKey: QuestActionLabelKey.openQuests,
        route: '/quests',
      );
    }
    if (!definition.isActiveOn(now) && definition.season != null) {
      final opening = _nextOpening(definition.season!, now);
      return QuestAction(
        questId: questId,
        labelKey: QuestActionLabelKey.seasonOpens,
        seasonOpensAt: opening,
      );
    }
    return switch (definition.source) {
      QuestSource.foodWordsMastered ||
      QuestSource.adjectiveFeelingWordsMastered ||
      QuestSource.natureWordsMastered ||
      QuestSource.workEducationWordsMastered ||
      QuestSource.hanjaWordsMastered ||
      QuestSource.songpyeonWords => QuestAction(
        questId: questId,
        labelKey: QuestActionLabelKey.openVocabulary,
        route: '/vocab',
      ),
      QuestSource.scenariosCompleted => QuestAction(
        questId: questId,
        labelKey: QuestActionLabelKey.openScenarios,
        route: '/scenarios',
      ),
      QuestSource.pronunciationGood => QuestAction(
        questId: questId,
        labelKey: QuestActionLabelKey.practicePronunciation,
        route: '/pronunciation',
      ),
      QuestSource.kkeunmariWins => QuestAction(
        questId: questId,
        labelKey: QuestActionLabelKey.playKkeunmari,
        route: '/kkeunmari',
      ),
      QuestSource.hangulMastery => QuestAction(
        questId: questId,
        labelKey: QuestActionLabelKey.openHangul,
        route: '/hangul',
      ),
      QuestSource.hangeulChallenge ||
      QuestSource.childrensDayCalligraphy => QuestAction(
        questId: questId,
        labelKey: QuestActionLabelKey.openCalligraphy,
        route: '/calligraphy',
      ),
      QuestSource.streakDays => QuestAction(
        questId: questId,
        labelKey: QuestActionLabelKey.openToday,
        route: '/course/mission',
      ),
      QuestSource.friendsCount => QuestAction(
        questId: questId,
        labelKey: QuestActionLabelKey.openGye,
        route: '/gye/hub',
      ),
      QuestSource.yutChosung => QuestAction(
        questId: questId,
        labelKey: QuestActionLabelKey.playChosung,
        route: '/chosung',
      ),
    };
  }

  static DateTime _nextOpening(SeasonWindow season, DateTime now) {
    var opening = DateTime(now.year, season.startMonth, season.startDay);
    if (!opening.isAfter(now)) {
      opening = DateTime(now.year + 1, season.startMonth, season.startDay);
    }
    return opening;
  }

  static String dateLabel(DateTime date) =>
      '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';
}
