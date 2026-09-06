import '../models/sori_stage_progression.dart';

const _firstClear = SoriLocalizedCopy(
  de: 'Beim ersten Abschluss',
  en: 'On first completion',
  key: SoriCopyKey.firstCompletion,
);
const _finishSession = SoriLocalizedCopy(
  de: 'Wenn du die Runde abschließt',
  en: 'When you finish the session',
  key: SoriCopyKey.finishSession,
);
const _verifiedLearning = SoriLocalizedCopy(
  de: 'Nach einem bestätigten Lernerfolg',
  en: 'After verified learning',
  key: SoriCopyKey.verifiedLearning,
);

RewardContract _contract(
  String id,
  SoriLocalizedCopy condition,
  List<RewardContractItem> items,
) => RewardContract(activityId: id, condition: condition, items: items);

const _xp = RewardContractItem(
  kind: SoriRewardKind.xp,
  label: SoriLocalizedCopy(
    de: 'Lern-XP',
    en: 'XP',
    key: SoriCopyKey.rewardXp,
  ),
);

const _quest = RewardContractItem(
  kind: SoriRewardKind.questProgress,
  label: SoriLocalizedCopy(
    de: 'Quest',
    en: 'Quest',
    key: SoriCopyKey.rewardQuest,
  ),
);
const _hanok = RewardContractItem(
  kind: SoriRewardKind.hanokProgress,
  permanent: true,
  label: SoriLocalizedCopy(
    de: 'Hanok-Bauteil',
    en: 'Hanok piece',
    key: SoriCopyKey.rewardHanok,
  ),
);
const _stamp = RewardContractItem(
  kind: SoriRewardKind.stamp,
  permanent: true,
  label: SoriLocalizedCopy(
    de: 'Dojang-Stempel',
    en: 'Dojang stamp',
    key: SoriCopyKey.rewardStamp,
  ),
);
const _best = RewardContractItem(
  kind: SoriRewardKind.personalBest,
  label: SoriLocalizedCopy(
    de: 'Persönliche Bestleistung',
    en: 'Personal best',
    key: SoriCopyKey.rewardBest,
  ),
);
const _noDirectReward = RewardContractItem(
  kind: SoriRewardKind.none,
  label: SoriLocalizedCopy(
    de: 'Keine direkte Belohnung',
    en: 'No direct reward',
    key: SoriCopyKey.rewardNone,
  ),
);

ActivityCatalogEntry _entry({
  required String id,
  required SoriStageTab tab,
  required String de,
  required String en,
  required String descriptionDe,
  required String descriptionEn,
  required String route,
  required int minutes,
  required SoriActivityColorRole color,
  required String icon,
  required RewardContract reward,
  bool ownsRoute = true,
  Object? arguments,
  List<String> detailRouteAliases = const <String>[],
  ActivityUnlockCondition unlock = const ActivityUnlockCondition.unlocked(),
  SoriLearnSection? learnSection,
}) => ActivityCatalogEntry(
  id: id,
  tab: tab,
  title: SoriLocalizedCopy(de: de, en: en, activityId: id),
  description: SoriLocalizedCopy(
    de: descriptionDe,
    en: descriptionEn,
    activityId: id,
    isActivityDescription: true,
  ),
  route: route,
  arguments: arguments,
  minutes: minutes,
  colorRole: color,
  iconName: icon,
  reward: reward,
  ownsRoute: ownsRoute,
  detailRouteAliases: detailRouteAliases,
  unlock: unlock,
  learnSection: learnSection,
);

/// One stable, testable inventory for every learner-facing Sori Stage entry.
/// Detail routes remain owned by the existing Navigator.
final List<ActivityCatalogEntry> soriActivityCatalog = List.unmodifiable([
  _entry(
    id: 'course',
    tab: SoriStageTab.learn,
    de: 'Kurs',
    en: 'Course',
    descriptionDe: 'Dein geführter Weg durch echte Situationen.',
    descriptionEn: 'Your guided path through real situations.',
    route: '/path',
    detailRouteAliases: const ['/course/mission'],
    minutes: 8,
    color: SoriActivityColorRole.completion,
    icon: 'route',
    reward: _contract('course', _verifiedLearning, [_xp, _hanok, _quest]),
    learnSection: SoriLearnSection.today,
  ),
  _entry(
    id: 'hangul',
    tab: SoriStageTab.learn,
    de: 'Hangul',
    en: 'Hangul',
    descriptionDe: 'Silben bauen und sicher lesen.',
    descriptionEn: 'Build syllables and read with confidence.',
    route: '/hangul',
    minutes: 6,
    color: SoriActivityColorRole.review,
    icon: 'hangul',
    reward: _contract('hangul', _finishSession, [_quest]),
    learnSection: SoriLearnSection.explore,
  ),
  _entry(
    id: 'calligraphy',
    tab: SoriStageTab.learn,
    de: 'Buchstabe des Tages',
    en: 'Character of the day',
    descriptionDe: 'Jeden Tag ein Schriftzeichen entdecken.',
    descriptionEn: 'Discover one character every day.',
    route: '/calligraphy',
    minutes: 3,
    color: SoriActivityColorRole.review,
    icon: 'brush',
    reward: _contract('calligraphy', _finishSession, [_quest]),
    learnSection: SoriLearnSection.explore,
  ),
  _entry(
    id: 'pronunciation',
    tab: SoriStageTab.learn,
    de: 'Aussprache',
    en: 'Pronunciation',
    descriptionDe: 'Hören, nachsprechen und auf Wunsch bewerten.',
    descriptionEn: 'Listen, repeat, and optionally assess.',
    route: '/pronunciation',
    minutes: 4,
    color: SoriActivityColorRole.speaking,
    icon: 'mic',
    reward: _contract('pronunciation', _verifiedLearning, [_quest]),
    learnSection: SoriLearnSection.explore,
  ),
  _entry(
    id: 'vocab_packs',
    tab: SoriStageTab.learn,
    de: 'Wortpakete',
    en: 'Vocabulary packs',
    descriptionDe: 'Wörter nach Alltagsthema lernen.',
    descriptionEn: 'Learn words by everyday topic.',
    route: '/vocab',
    detailRouteAliases: const ['/vocab/pack'],
    minutes: 7,
    color: SoriActivityColorRole.listening,
    icon: 'cards',
    reward: _contract('vocab_packs', _firstClear, [_xp, _stamp, _quest]),
    learnSection: SoriLearnSection.today,
  ),
  _entry(
    id: 'srs',
    tab: SoriStageTab.learn,
    de: 'Wiederholen',
    en: 'Review',
    descriptionDe: 'Wörter genau im richtigen Moment auffrischen.',
    descriptionEn: 'Refresh words at just the right moment.',
    route: '/review/hub',
    detailRouteAliases: const ['/review'],
    minutes: 5,
    color: SoriActivityColorRole.review,
    icon: 'repeat',
    reward: _contract('srs', _finishSession, [_xp, _quest]),
    learnSection: SoriLearnSection.review,
  ),
  _entry(
    id: 'my_words',
    tab: SoriStageTab.learn,
    de: 'Meine Wörter',
    en: 'My words',
    descriptionDe: 'Suchen, Regal und schwierige Wörter an einem Ort.',
    descriptionEn: 'Search, shelf, and difficult words in one place.',
    route: '/my_words',
    detailRouteAliases: const <String>[
      '/wordbook/search',
      '/bookshelf',
      '/hard_words',
      '/book',
    ],
    minutes: 5,
    color: SoriActivityColorRole.review,
    icon: 'bookshelf',
    reward: _contract('my_words', _finishSession, [_noDirectReward]),
    learnSection: SoriLearnSection.review,
  ),
  _entry(
    id: 'grammar',
    tab: SoriStageTab.learn,
    de: 'Grammatik',
    en: 'Grammar',
    descriptionDe: 'Muster verstehen und direkt anwenden.',
    descriptionEn: 'Understand patterns and use them right away.',
    route: '/grammar',
    minutes: 7,
    color: SoriActivityColorRole.completion,
    icon: 'grammar',
    reward: _contract('grammar', _finishSession, [_noDirectReward]),
    learnSection: SoriLearnSection.today,
  ),
  _entry(
    id: 'listening',
    tab: SoriStageTab.learn,
    de: 'Hören',
    en: 'Listening',
    descriptionDe: 'Kurze natürliche Sätze sicher erkennen.',
    descriptionEn: 'Recognize short natural phrases.',
    route: '/listening',
    minutes: 5,
    color: SoriActivityColorRole.listening,
    icon: 'headphones',
    reward: _contract('listening', _finishSession, [_xp]),
    learnSection: SoriLearnSection.explore,
  ),
  _entry(
    id: 'scenarios',
    tab: SoriStageTab.learn,
    de: 'Alltagsszenen',
    en: 'Real-life scenarios',
    descriptionDe: 'Café, Verkehr und Gespräche üben.',
    descriptionEn: 'Practice cafés, transport, and conversations.',
    route: '/scenarios',
    detailRouteAliases: const ['/scenario'],
    minutes: 8,
    color: SoriActivityColorRole.speaking,
    icon: 'dialogue',
    reward: _contract('scenarios', _verifiedLearning, [_xp, _hanok, _quest]),
    learnSection: SoriLearnSection.explore,
  ),
  _entry(
    id: 'smalltalk',
    tab: SoriStageTab.learn,
    de: 'Small Talk',
    en: 'Small Talk',
    descriptionDe: 'Kurze Gespräche flüssig verbinden.',
    descriptionEn: 'Connect short conversations naturally.',
    route: '/smalltalk',
    minutes: 6,
    color: SoriActivityColorRole.speaking,
    icon: 'chat',
    reward: _contract('smalltalk', _finishSession, [_noDirectReward]),
    learnSection: SoriLearnSection.explore,
  ),
  _entry(
    id: 'word_web',
    tab: SoriStageTab.learn,
    de: 'Nuancen & Gegenteile',
    en: 'Nuances & opposites',
    descriptionDe: 'Synonyme, Gegenteile und Wendungen zu deinen Wörtern.',
    descriptionEn: 'Synonyms, opposites and expressions for your words.',
    route: '/word_web',
    minutes: 6,
    color: SoriActivityColorRole.review,
    icon: 'hub',
    reward: _contract('word_web', _finishSession, [_noDirectReward]),
    learnSection: SoriLearnSection.explore,
  ),
  // W10 T-L2: 'vocab_notebook' 타일 제거 — Vokabelheft는 이제 카탈로그 타일이
  // 아니라 Meine Wörter("my_words") 화면의 "+" 시트에서만 들어간다. 라우트
  // ('/vocab_notebook' 및 그 별칭들)와 화면은 그대로 살아 있다 — 여기서
  // 지우는 것은 Lernen 탭 카드뿐이다.
  _entry(
    id: 'daily_game',
    tab: SoriStageTab.games,
    de: 'Tageschallenge',
    en: 'Daily challenge',
    descriptionDe: 'Ein kurzer Mix für heute.',
    descriptionEn: 'A short mix for today.',
    route: '/daily',
    minutes: 4,
    color: SoriActivityColorRole.reward,
    icon: 'sun',
    reward: _contract('daily_game', _finishSession, [_xp, _best]),
  ),
  _entry(
    id: 'chosung',
    tab: SoriStageTab.games,
    de: 'Anlaut-Quiz',
    en: 'First-sound quiz',
    descriptionDe: 'Wörter an ihren Anfangslauten erkennen.',
    descriptionEn: 'Recognize words from their first sounds.',
    route: '/chosung',
    minutes: 4,
    color: SoriActivityColorRole.listening,
    icon: 'chosung',
    reward: _contract('chosung', _finishSession, [_xp, _best, _quest]),
  ),
  _entry(
    id: 'syllable_cross',
    tab: SoriStageTab.games,
    de: 'Silben-Rätsel',
    en: 'Syllable puzzle',
    descriptionDe: 'Silben kombinieren und Wörter finden.',
    descriptionEn: 'Combine syllables and find words.',
    route: '/wordle',
    minutes: 5,
    color: SoriActivityColorRole.completion,
    icon: 'grid',
    reward: _contract('syllable_cross', _finishSession, [_xp, _best]),
  ),
  _entry(
    id: 'cloze',
    tab: SoriStageTab.games,
    de: 'Lückentext',
    en: 'Fill the gap',
    descriptionDe: 'Das passende Wort im Satz abrufen.',
    descriptionEn: 'Recall the right word in a sentence.',
    route: '/cloze',
    minutes: 5,
    color: SoriActivityColorRole.review,
    icon: 'cloze',
    reward: _contract('cloze', _finishSession, [_xp, _best]),
  ),
  _entry(
    id: 'speed_match',
    tab: SoriStageTab.games,
    de: 'Blitz-Paare',
    en: 'Speed pairs',
    descriptionDe: 'Bedeutungen schnell und sicher verbinden.',
    descriptionEn: 'Match meanings quickly and accurately.',
    route: '/speed_match',
    minutes: 3,
    color: SoriActivityColorRole.speaking,
    icon: 'bolt',
    reward: _contract('speed_match', _finishSession, [_xp, _best]),
  ),
  _entry(
    id: 'sentence_arcade',
    tab: SoriStageTab.games,
    de: 'Satz-Arcade',
    en: 'Sentence arcade',
    descriptionDe: 'Sätze unter Zeitdruck richtig bauen.',
    descriptionEn: 'Build sentences under time pressure.',
    route: '/satz_arcade',
    minutes: 5,
    color: SoriActivityColorRole.speaking,
    icon: 'arcade',
    reward: _contract('sentence_arcade', _finishSession, [_xp, _best]),
  ),
  _entry(
    id: 'kkeunmari',
    tab: SoriStageTab.games,
    de: 'Kkeunmari',
    en: 'Kkeunmari',
    descriptionDe: 'Eine Wortkette gegen den Tiger spielen.',
    descriptionEn: 'Play a word chain against the tiger.',
    route: '/kkeunmari',
    minutes: 6,
    color: SoriActivityColorRole.speaking,
    icon: 'chain',
    reward: _contract('kkeunmari', _finishSession, [_xp, _best, _quest]),
  ),
  // W10 T-L3: 'custom_quiz' + 'custom_matching' + 'custom_typing' 세 타일을
  // 하나로 합친다 — 셋 다 '/my_words'(Meine Wörter)로 들어가 그 안에서
  // 퀴즈/매칭/타이핑을 고르므로 카탈로그 레벨의 세 타일은 중복이었다.
  // minutes 는 셋 중 최댓값(5), 일러스트는 custom_quiz 것을 재사용한다
  // (activities/custom_practice.webp — 기존 custom_quiz.webp 를 git mv).
  _entry(
    id: 'custom_practice',
    tab: SoriStageTab.games,
    de: 'Eigene Wörter üben',
    en: 'Practice my words',
    descriptionDe:
        'Quiz, Matching und Tippen mit deinen gespeicherten Wörtern.',
    descriptionEn: 'Quiz, matching and typing with your saved words.',
    route: '/my_words',
    ownsRoute: false,
    minutes: 5,
    color: SoriActivityColorRole.listening,
    icon: 'quiz',
    reward: _contract('custom_practice', _finishSession, [_xp, _best]),
  ),
]);

ActivityCatalogEntry? activityForRoute(String? route) {
  if (route == null) {
    return null;
  }
  for (final activity in soriActivityCatalog) {
    if (activity.ownsRoute &&
        (activity.route == route ||
            activity.detailRouteAliases.contains(route))) {
      return activity;
    }
  }
  return null;
}
