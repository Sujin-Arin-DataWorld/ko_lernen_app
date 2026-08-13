// Phase 4 (stately-rising-jongga) — 특별 퀘스트 모델.
//
// Quest = 한국 학습 행위들이 누적되면 마당에 영구 장식이 추가되는 single-shot
// 달성 목표. **상시 (standing)** 와 **계절 (seasonal)** 두 종류.
//
// 진행도는 **passive** 로 계산 — `QuestTracker` 가 호출 시점에 Storage /
// 다른 서비스를 읽고 즉시 count. 별도 이벤트 hook 없음 (단순).

enum QuestType {
  /// 상시 — 언제든 도전 가능, 영구 표시.
  standing,

  /// 계절 — 특정 날짜 범위에서만 활성, 해당 시즌에 클리어 시 영구 표시.
  seasonal,
}

/// 계절 윈도우 — 그레고리안 달력 기준 단순화.
/// 실제 음력 (설날·추석) 은 매년 변동 — Phase 4 v1 은 가장 흔한 범위 사용.
class SeasonWindow {
  /// 월 (1-12), 양 끝 포함.
  final int startMonth;
  final int startDay;
  final int endMonth;
  final int endDay;
  const SeasonWindow({
    required this.startMonth,
    required this.startDay,
    required this.endMonth,
    required this.endDay,
  });

  /// 윈도우가 [date] 를 포함하는지. 연도-경계 (12→1) 도 지원.
  bool contains(DateTime date) {
    final m = date.month;
    final d = date.day;
    final cur = m * 100 + d;
    final start = startMonth * 100 + startDay;
    final end = endMonth * 100 + endDay;
    if (start <= end) return cur >= start && cur <= end;
    // wraps around year boundary
    return cur >= start || cur <= end;
  }
}

/// 정적 퀘스트 정의. 카탈로그 (`quest_catalog.dart`) 에 const 로 선언.
class QuestDefinition {
  final String id;
  final QuestType type;

  /// 사람-읽기 라벨 (DE/EN) — l10n 키 사용 가능하지만 한 줄이라 inline.
  final ({String de, String en}) name;
  final ({String de, String en}) description;

  /// 달성 목표 수치 (예: 50 단어 마스터, 30 일 streak, 10 시나리오).
  final int target;

  /// 진행도 계산 슬롯 — QuestTracker 가 mapping 으로 실제 함수 부른다.
  final QuestSource source;

  /// 영구 장식 자산 슬러그 — `assets/illustrations/decorations/{slug}.png`.
  final String decorationSlug;

  /// 계절 윈도우 (seasonal 만 의미).
  final SeasonWindow? season;

  /// 단순 마당 좌표 (0..1) — 데코 layer 에서 stack 위치.
  final ({double leftFrac, double bottomFrac, double widthFrac}) layout;

  const QuestDefinition({
    required this.id,
    required this.type,
    required this.name,
    required this.description,
    required this.target,
    required this.source,
    required this.decorationSlug,
    required this.layout,
    this.season,
  });

  bool isActiveOn(DateTime now) {
    if (type == QuestType.standing) return true;
    return season?.contains(now) ?? false;
  }
}

/// 카운팅 소스 — QuestTracker 의 switch 에서 라우팅.
enum QuestSource {
  /// 음식 토픽 단어 마스터 수 (Essen & Trinken).
  foodWordsMastered,

  /// 형용사 + 감정 단어 마스터 수 (Beschreibung + Gefühle).
  adjectiveFeelingWordsMastered,

  /// 자연·날씨 토픽 단어 마스터 수 (Wetter + Geographie + Umwelt).
  natureWordsMastered,

  /// 학교·직장 토픽 단어 마스터 수 (Beruf + Bildung).
  workEducationWordsMastered,

  /// 한자어 (sino-Korean) 단어 추정 마스터 수 — Phase 4 v1 은 단순 length≥2 비율로 추정.
  hanjaWordsMastered,

  /// 시나리오 완료 수.
  scenariosCompleted,

  /// 발음 평가 80%+ 횟수. **미구현** (발음 평가 시스템 부재) → 항상 0.
  /// Phase 5 대기 — 어휘 도달 가능성 가드에서 의도적으로 제외된다
  /// (`quest_catalog_test.dart` 의 `_intentionallyUnimplementedSources`).
  pronunciationGood,

  /// 끝말잇기 누적 승수.
  kkeunmariWins,

  /// 한글 자모 학습률 (calligraphy days). 100% = 자모 완성.
  hangulMastery,

  /// Streak 일수.
  streakDays,

  /// 친구/계원 수. **미구현** (Phase 6 의 계 도입 전) → 항상 0.
  /// Phase 6 대기 — 어휘 도달 가능성 가드에서 의도적으로 제외된다
  /// (`quest_catalog_test.dart` 의 `_intentionallyUnimplementedSources`).
  friendsCount,

  /// 한글날 챌린지 — calligraphy 일 수 (시즌 중).
  hangeulChallenge,

  /// 명절 상차림 단어 — `Essen & Trinken` 의 고정 부분집합
  /// (`quest_tracker.dart` 의 `kChuseokFoodWords`, 16 단어).
  /// 이름은 남았지만 실제 송편/추석 어휘는 아직 코퍼스에 없다 — 2026-08-07 참고.
  songpyeonWords,

  /// 윷놀이 — chosung quiz 정답 5회 (시즌 중).
  yutChosung,

  /// 어린이날 — daily char 5 일 연속 (시즌 중).
  childrensDayCalligraphy,
}

/// 단일 퀘스트의 현재 진행 상태 — QuestTracker.computeAll() 출력.
class QuestProgress {
  final String questId;
  final int current;
  final int target;
  final bool active; // seasonal 이고 윈도우 밖이면 false
  final bool completed; // current >= target (history 에 저장됨)
  final bool completionVerified;
  final String? completedAtIso;

  const QuestProgress({
    required this.questId,
    required this.current,
    required this.target,
    required this.active,
    required this.completed,
    required this.completedAtIso,
    this.completionVerified = true,
  });

  double get fraction => target == 0 ? 0.0 : (current / target).clamp(0.0, 1.0);
}
