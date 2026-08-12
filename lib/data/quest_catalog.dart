import '../models/quest.dart';

/// Phase 4 (stately-rising-jongga) — 18 특별 퀘스트 카탈로그.
///
/// 출처: Plan §6.1 (10 상시) + §6.2 (4 계절) + §6.3 (사군자 4 sub)
/// + 2026-08-07 `q_dokkaebi_fire` 1 상시(고아 장식 배선).
///
/// **불변 규칙**:
///   - id 는 `q_` prefix + snake_case (Firestore key 안전).
///   - decorationSlug 는 `assets/illustrations/decorations/{slug}.png` 의
///     파일명 stem 과 정확히 일치.
///   - target 은 모두 양의 정수.
///   - layout (leftFrac, bottomFrac, widthFrac) 는 마당 캔버스 비율 — UI 에서
///     `Positioned(left: w * leftFrac, bottom: h * bottomFrac)` 로 배치.

const _seasonSeollal = SeasonWindow(
  startMonth: 1,
  startDay: 15,
  endMonth: 2,
  endDay: 20,
);
const _seasonChuseok = SeasonWindow(
  startMonth: 9,
  startDay: 1,
  endMonth: 10,
  endDay: 15,
);
const _seasonHangeulDay = SeasonWindow(
  startMonth: 10,
  startDay: 2,
  endMonth: 10,
  endDay: 16,
);
const _seasonChildrensDay = SeasonWindow(
  startMonth: 4,
  startDay: 28,
  endMonth: 5,
  endDay: 8,
);

const List<QuestDefinition> kQuestCatalog = [
  // ── 상시 (10) ──────────────────────────────────────────────────────
  // 2026-08-07: target 50 → 15. `Essen & Trinken` 토픽은 31 개뿐이라 50 은
  // **도달 불가**였고, 이 퀘스트로만 열리는 `decoration_jangdokdae` 는 영원히
  // 뜨지 않았다. 15 는 31 의 48% — 정상 퀘스트(매화 45%·도깨비불 46%)와 같은 대역.
  QuestDefinition(
    id: 'q_jangdokdae',
    type: QuestType.standing,
    name: (de: 'Jangdokdae (Krugterrasse)', en: 'Jangdokdae (jar terrace)'),
    description: (
      de: 'Meistere 15 Wörter zu Essen und Trinken, dann entsteht eine Krug-Terrasse.',
      en: 'Master 15 food and drink words and a jar terrace appears.',
    ),
    target: 15,
    source: QuestSource.foodWordsMastered,
    decorationSlug: 'decoration_jangdokdae',
    layout: (leftFrac: 0.62, bottomFrac: 0.12, widthFrac: 0.30),
  ),

  QuestDefinition(
    id: 'q_maehwa',
    type: QuestType.standing,
    name: (de: 'Pflaumenbaum (매화)', en: 'Plum tree (매화)'),
    description: (
      de: 'Meistere 30 Adjektive und Gefühle.',
      en: 'Master 30 adjectives and emotion words.',
    ),
    target: 30,
    source: QuestSource.adjectiveFeelingWordsMastered,
    decorationSlug: 'decoration_maehwa',
    layout: (leftFrac: 0.05, bottomFrac: 0.18, widthFrac: 0.22),
  ),

  QuestDefinition(
    id: 'q_sonamu',
    type: QuestType.standing,
    name: (de: 'Alte Kiefer (노송)', en: 'Old pine (노송)'),
    description: (
      de: 'Schließe 10 Szenarien ab.',
      en: 'Complete 10 scenarios.',
    ),
    target: 10,
    source: QuestSource.scenariosCompleted,
    decorationSlug: 'decoration_sonamu',
    layout: (leftFrac: 0.72, bottomFrac: 0.20, widthFrac: 0.24),
  ),

  // 2026-08-07: target 20 → 10. Wetter 9 + Geographie 1 + Umwelt 13 = 23 이라
  // 20 은 코퍼스의 87% — 형식상 도달 가능해도 사실상 불가능했다. 10 은 43%.
  QuestDefinition(
    id: 'q_pond',
    type: QuestType.standing,
    name: (de: 'Teich & Karpfen (연못)', en: 'Pond & carp (연못)'),
    description: (
      de: 'Meistere 10 Natur- & Wetterwörter.',
      en: 'Master 10 nature & weather words.',
    ),
    target: 10,
    source: QuestSource.natureWordsMastered,
    decorationSlug: 'decoration_pond',
    layout: (leftFrac: 0.34, bottomFrac: 0.10, widthFrac: 0.30),
  ),

  QuestDefinition(
    id: 'q_seokdeung',
    type: QuestType.standing,
    name: (de: 'Steinlaterne (장명등)', en: 'Stone lantern (장명등)'),
    description: (
      de: '100× Aussprache ≥ 80% (Phase-5: Bewertung in Vorbereitung).',
      en: '100× pronunciation ≥ 80% (Phase-5: scoring upcoming).',
    ),
    target: 100,
    source: QuestSource.pronunciationGood,
    decorationSlug: 'decoration_seokdeung',
    layout: (leftFrac: 0.08, bottomFrac: 0.08, widthFrac: 0.10),
  ),

  QuestDefinition(
    id: 'q_punggyeong',
    type: QuestType.standing,
    name: (de: 'Windspiel (풍경)', en: 'Wind chime (풍경)'),
    description: (
      de: 'Gewinne 10 Runden Kkeunmari.',
      en: 'Win 10 rounds of Kkeunmari.',
    ),
    target: 10,
    source: QuestSource.kkeunmariWins,
    decorationSlug: 'decoration_punggyeong',
    layout: (leftFrac: 0.58, bottomFrac: 0.60, widthFrac: 0.08),
  ),

  QuestDefinition(
    id: 'q_pyeonaek',
    type: QuestType.standing,
    name: (de: 'Kalligraphie-Tafel (편액)', en: 'Calligraphy plaque (편액)'),
    description: (
      de: 'Meistere alle Hangul Jamo (100%).',
      en: 'Master all Hangul jamo (100%).',
    ),
    target: 100,
    source: QuestSource.hangulMastery,
    decorationSlug: 'decoration_pyeonaek',
    layout: (leftFrac: 0.42, bottomFrac: 0.66, widthFrac: 0.18),
  ),

  QuestDefinition(
    id: 'q_doldam',
    type: QuestType.standing,
    name: (de: 'Steinmauer (돌담)', en: 'Stone wall (돌담)'),
    description: (
      de: 'Sammle 5 Freunde / Gye-Mitglieder (Phase-6).',
      en: 'Collect 5 friends / gye members (Phase-6).',
    ),
    target: 5,
    source: QuestSource.friendsCount,
    decorationSlug: 'decoration_doldam',
    layout: (leftFrac: 0.00, bottomFrac: 0.04, widthFrac: 1.00),
  ),

  QuestDefinition(
    id: 'q_kkachi_nest',
    type: QuestType.standing,
    name: (de: 'Elsternnest (까치 둥지)', en: 'Magpie nest (까치 둥지)'),
    description: (de: '30 Tage Lern-Streak.', en: '30-day learning streak.'),
    target: 30,
    source: QuestSource.streakDays,
    decorationSlug: 'decoration_kkachi_nest',
    layout: (leftFrac: 0.72, bottomFrac: 0.62, widthFrac: 0.12),
  ),

  // 도깨비불 — 2026-08-07 신설. `QuestSource.workEducationWordsMastered` 는
  // QuestTracker 가 세고 있으면서도(quest_tracker.dart:77) 카탈로그에 소비처가
  // 없어 죽어 있던 유일한 소스였다. 어휘는 Beruf 32 + Bildung 22 = 54 개라
  // 25 는 도달 가능하다.
  QuestDefinition(
    id: 'q_dokkaebi_fire',
    type: QuestType.standing,
    name: (de: 'Irrlicht (도깨비불)', en: 'Goblin fire (도깨비불)'),
    description: (
      de: 'Meistere 25 Wörter aus Beruf und Bildung, dann wacht ein Irrlicht über die Nachtstunden.',
      en: 'Master 25 work and education words, and a goblin fire keeps watch over late study hours.',
    ),
    target: 25,
    source: QuestSource.workEducationWordsMastered,
    decorationSlug: 'decoration_dokkaebi_fire',
    layout: (leftFrac: 0.30, bottomFrac: 0.36, widthFrac: 0.09),
  ),

  // ── 사군자 4-Polyptychon (Plum-Orchid-Chrysanthemum-Bamboo) ────────
  // Plan §6.1 #9 — Hanja-style 단어 mastery as proxy (langer 단어 ≥ 2 글자).
  // Jeweils 1/4 des kumulativen Hanja-Counts.
  QuestDefinition(
    id: 'q_sagunja_maehwa',
    type: QuestType.standing,
    name: (de: 'Sagunja: Pflaume', en: 'Sagunja: Plum'),
    description: (
      de: 'Meistere 20 Hanja-Wörter (Frühling-Polyptychon).',
      en: 'Master 20 sino-Korean words (spring panel).',
    ),
    target: 20,
    source: QuestSource.hanjaWordsMastered,
    decorationSlug: 'decoration_sagunja_maehwa',
    layout: (leftFrac: 0.04, bottomFrac: 0.52, widthFrac: 0.10),
  ),
  QuestDefinition(
    id: 'q_sagunja_nan',
    type: QuestType.standing,
    name: (de: 'Sagunja: Orchidee', en: 'Sagunja: Orchid'),
    description: (
      de: 'Meistere 40 Hanja-Wörter (Sommer-Polyptychon).',
      en: 'Master 40 sino-Korean words (summer panel).',
    ),
    target: 40,
    source: QuestSource.hanjaWordsMastered,
    decorationSlug: 'decoration_sagunja_nan',
    layout: (leftFrac: 0.16, bottomFrac: 0.52, widthFrac: 0.10),
  ),
  QuestDefinition(
    id: 'q_sagunja_guk',
    type: QuestType.standing,
    name: (de: 'Sagunja: Chrysantheme', en: 'Sagunja: Chrysanthemum'),
    description: (
      de: 'Meistere 60 Hanja-Wörter (Herbst-Polyptychon).',
      en: 'Master 60 sino-Korean words (autumn panel).',
    ),
    target: 60,
    source: QuestSource.hanjaWordsMastered,
    decorationSlug: 'decoration_sagunja_guk',
    layout: (leftFrac: 0.28, bottomFrac: 0.52, widthFrac: 0.10),
  ),
  QuestDefinition(
    id: 'q_sagunja_juk',
    type: QuestType.standing,
    name: (de: 'Sagunja: Bambus', en: 'Sagunja: Bamboo'),
    description: (
      de: 'Meistere 80 Hanja-Wörter (Winter-Polyptychon).',
      en: 'Master 80 sino-Korean words (winter panel).',
    ),
    target: 80,
    source: QuestSource.hanjaWordsMastered,
    decorationSlug: 'decoration_sagunja_juk',
    layout: (leftFrac: 0.40, bottomFrac: 0.52, widthFrac: 0.10),
  ),

  // ── 계절 (4) ─────────────────────────────────────────────────────────
  QuestDefinition(
    id: 'q_seollal',
    type: QuestType.seasonal,
    name: (de: 'Seollal-Yutspiel (윷놀이)', en: 'Lunar New Year Yutnori'),
    description: (
      de: 'Spiele 5 Chosung-Quiz-Runden während Seollal.',
      en: 'Play 5 chosung quiz rounds during Lunar New Year.',
    ),
    target: 5,
    source: QuestSource.yutChosung,
    decorationSlug: 'decoration_seollal_flag',
    season: _seasonSeollal,
    layout: (leftFrac: 0.42, bottomFrac: 0.30, widthFrac: 0.20),
  ),

  // 2026-08-07: target 12 → 8. 옛 `_chuseokFoodWords` 12 개 중 코퍼스에 실재하는
  // 건 `사과` 하나뿐이라(`밤` 은 이 CSV 에서 "Nacht") 카운트 상한이 2 였다 —
  // 세 도달 불가 퀘스트 중 가장 심했다. 목록을 실재 단어 16 개로 다시 만들고
  // (quest_tracker.dart `kChuseokFoodWords`) target 은 그 50% 로 잡았다.
  QuestDefinition(
    id: 'q_chuseok',
    type: QuestType.seasonal,
    name: (de: 'Chuseok-Vollmond', en: 'Chuseok full moon'),
    description: (
      de: 'Meistere 8 Festtafel-Wörter während Chuseok.',
      en: 'Master 8 holiday-table words during Chuseok.',
    ),
    target: 8,
    source: QuestSource.songpyeonWords,
    decorationSlug: 'decoration_chuseok_moon',
    season: _seasonChuseok,
    layout: (leftFrac: 0.70, bottomFrac: 0.86, widthFrac: 0.15),
  ),

  QuestDefinition(
    id: 'q_hangeulday',
    type: QuestType.seasonal,
    name: (de: 'Hangul-Tag Sejong-Tafel', en: 'Hangul Day Sejong plaque'),
    description: (
      de: 'Schließe 7 Tage Kalligraphie während Hangul-Tag ab.',
      en: 'Complete 7 calligraphy days during Hangul Day.',
    ),
    target: 7,
    source: QuestSource.hangeulChallenge,
    decorationSlug: 'decoration_hangeulday_plaque',
    season: _seasonHangeulDay,
    layout: (leftFrac: 0.42, bottomFrac: 0.78, widthFrac: 0.16),
  ),

  QuestDefinition(
    id: 'q_kite',
    type: QuestType.seasonal,
    name: (de: 'Kinder-Tag Drachen (연)', en: 'Children\'s Day kite (연)'),
    description: (
      de: '5 Kalligraphie-Tage in Folge während Kindertag.',
      en: '5-day calligraphy streak during Children\'s Day.',
    ),
    target: 5,
    source: QuestSource.childrensDayCalligraphy,
    decorationSlug: 'decoration_kite',
    season: _seasonChildrensDay,
    layout: (leftFrac: 0.30, bottomFrac: 0.88, widthFrac: 0.18),
  ),
];

/// Convenience lookup. Wird sehr oft gerufen — Map einmalig bauen.
final Map<String, QuestDefinition> kQuestById = {
  for (final q in kQuestCatalog) q.id: q,
};
