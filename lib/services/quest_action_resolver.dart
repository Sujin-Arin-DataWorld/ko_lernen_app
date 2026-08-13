import '../data/quest_catalog.dart';
import '../models/quest.dart';

class QuestAction {
  const QuestAction({
    required this.questId,
    required this.label,
    this.route,
    this.arguments,
    this.seasonOpensAt,
  });
  final String questId;
  final ({String de, String en}) label;
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
        label: (de: 'Quests öffnen', en: 'Open quests'),
        route: '/quests',
      );
    }
    if (!definition.isActiveOn(now) && definition.season != null) {
      final opening = _nextOpening(definition.season!, now);
      return QuestAction(
        questId: questId,
        label: (
          de: 'Öffnet am ${_dateLabel(opening)}',
          en: 'Opens ${_dateLabel(opening)}',
        ),
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
        label: (de: 'Wortpakete öffnen', en: 'Open vocabulary packs'),
        route: '/vocab',
      ),
      QuestSource.scenariosCompleted => QuestAction(
        questId: questId,
        label: (de: 'Alltagsszenen öffnen', en: 'Open real-life scenarios'),
        route: '/scenarios',
      ),
      QuestSource.pronunciationGood => QuestAction(
        questId: questId,
        label: (de: 'Aussprache üben', en: 'Practice pronunciation'),
        route: '/pronunciation',
      ),
      QuestSource.kkeunmariWins => QuestAction(
        questId: questId,
        label: (de: 'Kkeunmari spielen', en: 'Play Kkeunmari'),
        route: '/kkeunmari',
      ),
      QuestSource.hangulMastery ||
      QuestSource.hangeulChallenge ||
      QuestSource.childrensDayCalligraphy => QuestAction(
        questId: questId,
        label: (de: 'Kalligrafie öffnen', en: 'Open calligraphy'),
        route: '/daily',
      ),
      QuestSource.streakDays => QuestAction(
        questId: questId,
        label: (de: 'Heutige Mission öffnen', en: 'Open today’s mission'),
        route: '/course/mission',
      ),
      QuestSource.friendsCount => QuestAction(
        questId: questId,
        label: (de: 'Gye öffnen', en: 'Open Gye'),
        route: '/gye/hub',
      ),
      QuestSource.yutChosung => QuestAction(
        questId: questId,
        label: (de: 'Chosung spielen', en: 'Play Chosung'),
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

  static String _dateLabel(DateTime date) =>
      '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';
}
