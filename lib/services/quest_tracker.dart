import '../data/quest_catalog.dart';
import '../models/quest.dart';
import '../models/gye.dart';
import 'data_loader.dart';
import 'decoration_reward_service.dart';
import 'gye_service.dart';
import 'gye_member_quest_service.dart';
import 'storage_service.dart';

/// Phase 4 (stately-rising-jongga) — Quest-Progress Computation.
///
/// **Passive pull**: 호출 시점에 모든 source 를 읽고 카운트한다.
/// 별도 이벤트 시스템 없음 (단순). UI 가 setState 후 다시 부르면 fresh.
///
/// 완료 시점은 `Storage.markQuestCompleted` 로 persist —
/// 그 후 카운터가 떨어져도 decoration 은 유지된다.
class QuestTracker {
  /// Alle Quests + aktueller Stand. `now` für Tests injizierbar.
  static Future<List<QuestProgress>> computeAll({
    DateTime? now,
    Future<GyeMemberQuestResult> Function()? loadGyeMembers,
  }) async {
    final today = now ?? DateTime.now();
    final completions = Storage.questCompletions;

    // CSV einmal pro Aufruf — Topic-Subsets aufbauen.
    final vocab = await DataLoader.loadVocab();
    bool isStrong(String word) =>
        Storage.vocabMastery(word) == MasteryState.strong;

    int countSeenWithTopics(Set<String> topics) {
      return vocab
          .where((v) => topics.contains(v.topic) && isStrong(v.korean))
          .length;
    }

    // Hanja-Proxy: koreanische Wörter mit ≥ 2 Silben sind häufig 한자어
    // (Approximation — Phase 5 책 한 컷 könnte präzisere POS-Daten liefern).
    final hanjaCount = vocab
        .where((v) => isHanjaProxyWord(v.korean) && isStrong(v.korean))
        .length;

    // 명절 상차림 단어 — Essen & Trinken 의 고정 부분집합.
    final songpyeonCount = vocab
        .where(
          (v) => kChuseokFoodWords.contains(v.korean) && isStrong(v.korean),
        )
        .length;

    // 한글 마스터리 — calligraphyTotalDays / 28 jamo × 100.
    // Wert ist clipped 0..100.
    final hangulPct = (Storage.calligraphyTotalDays * 100 / 28)
        .clamp(0, 100)
        .round();

    // 한글날 7-Tage-Challenge — Tage innerhalb Hangul-Day-Fenster.
    final hangeulChallenge = _calligraphyDaysInWindow(today, days: 14);

    // 어린이날 5-Tage-Streak — Streak innerhalb des Fensters.
    final childrensStreak = _calligraphyDaysInWindow(today, days: 11);

    // 카탈로그 루프 **밖**에서 한 번만 만든다 — 안에 두면 topic 카운트가
    // 퀘스트 수만큼 반복 스캔된다.
    final memberResult =
        await (loadGyeMembers ?? GyeMemberQuestService.refreshOrCached)();
    final counters = <QuestSource, int>{
      // Topic 기반 소스는 [kQuestTopicSets] 가 단일 정의다 — 여기에 항목을
      // 더하면 계산과 도달 가능성 가드가 함께 따라온다.
      for (final entry in kQuestTopicSets.entries)
        entry.key: countSeenWithTopics(entry.value),
      QuestSource.hanjaWordsMastered: hanjaCount,
      QuestSource.scenariosCompleted: Storage.completedScenarios.length,
      QuestSource.pronunciationGood: Storage.pronunciationPassCount,
      QuestSource.kkeunmariWins: Storage.kkeunmariWins,
      QuestSource.hangulMastery: hangulPct,
      QuestSource.streakDays: Storage.streakDays,
      QuestSource.friendsCount: memberResult.count,
      QuestSource.songpyeonWords: songpyeonCount,
      QuestSource.yutChosung: Storage.chosungCorrect,
      QuestSource.hangeulChallenge: hangeulChallenge,
      QuestSource.childrensDayCalligraphy: childrensStreak,
    };

    return [
      for (final def in kQuestCatalog)
        _buildProgress(
          def,
          today: today,
          completions: completions,
          counters: counters,
          gyeMembersVerifiedOnline: memberResult.verifiedOnline,
        ),
    ];
  }

  /// 사후 한 번 실행 — 처음 target 도달한 quest 들을 persist.
  /// UI 가 progress 를 표시한 뒤 호출하면 idempotent.
  static Future<void> persistNewCompletions(
    List<QuestProgress> progresses,
  ) async {
    for (final p in progresses) {
      if (p.completed && p.completedAtIso == null) {
        // p.completedAtIso == null 은 "방금 도달" 의미 (computeAll 의 mark 참고)
        // 완료 marker 보다 보상 상자를 먼저 기록한다. 두 저장 사이에 앱이 꺼져도
        // 다음 실행에서 아직 완료되지 않은 퀘스트가 다시 계산되고, 이미 저장된
        // 상자를 확인한 뒤 marker 만 마무리한다. 같은 퀘스트의 보상 중복도 막는다.
        await DecorationRewardService.ensurePendingBoxForQuest(p.questId);
        await Storage.markQuestCompleted(p.questId);
        // 2픽: 방금 완료한 퀘스트를 계 피드에 broadcast (축하 유도) — best-effort.
        // 보상 상자·완료 마커는 위에서 이미 로컬에 기록됐으므로, 소셜 계층이
        // 없거나(오프라인·미로그인) 실패해도 학습 보상은 유실되지 않는다.
        try {
          await GyeService.broadcastFeed(GyeFeedType.questCompleted, {
            'questId': p.questId,
          });
        } catch (_) {
          // 보상은 이미 지급됨 — 소셜 broadcast 실패는 무시.
        }
      }
    }
    // 2픽: 레벨업도 계 피드에 동기화 (순환 회피 — 여기서 pull) — best-effort.
    try {
      await GyeService.syncLevelUp();
    } catch (_) {
      // 소셜 동기화는 로컬 보상 루프에 필수가 아님.
    }
  }

  /// 화면-비의존 보상 동기화: 퀘스트를 재계산하고 처음 target 도달한 완료만
  /// persist 한다. 공부만으로도(퀘스트 화면 안 열어도) 학습자가 획득한 보자기가
  /// 생산된다. best-effort — 자체 오류를 삼켜 UI 호출자(홈·사랑방)가 무조건
  /// await 할 수 있다. 멱등: [persistNewCompletions] 는 처음 도달한 퀘스트만
  /// 처리하고 [DecorationRewardService.ensurePendingBoxForQuest] 는 중복을
  /// 거부하므로 여러 화면에서 불러도 이중 지급 없음.
  static Future<void> syncEarnedRewards() async {
    try {
      final progresses = await computeAll();
      await persistNewCompletions(progresses);
    } catch (_) {
      // 비차단: 보상 동기화 실패는 절대 UI 로 전파하지 않는다.
    }
  }

  // ── Helfer ──────────────────────────────────────────────────────────

  static QuestProgress _buildProgress(
    QuestDefinition def, {
    required DateTime today,
    required Map<String, String> completions,
    required Map<QuestSource, int> counters,
    required bool gyeMembersVerifiedOnline,
  }) {
    final active = def.isActiveOn(today);
    final cur = counters[def.source] ?? 0;
    final alreadyDone = completions.containsKey(def.id);
    final requiresOnlineVerification = def.source == QuestSource.friendsCount;
    final completionVerified =
        !requiresOnlineVerification || gyeMembersVerifiedOnline || alreadyDone;
    final reached = cur >= def.target && completionVerified;
    return QuestProgress(
      questId: def.id,
      current: cur,
      target: def.target,
      active: active,
      completed: alreadyDone || reached,
      completedAtIso: completions[def.id],
      completionVerified: completionVerified,
    );
  }

  static int _calligraphyDaysInWindow(DateTime today, {required int days}) {
    final dates = Storage.calligraphyDates.toSet();
    final fromDay = today.subtract(Duration(days: days));
    int count = 0;
    for (final iso in dates) {
      final d = DateTime.tryParse(iso);
      if (d == null) {
        continue;
      }
      if (d.isAfter(fromDay.subtract(const Duration(seconds: 1))) &&
          d.isBefore(today.add(const Duration(days: 1)))) {
        count++;
      }
    }
    return count;
  }
}

// ── 어휘-바운드 소스의 공유 정의 ──────────────────────────────────────
//
// 아래 세 정의는 [QuestTracker.computeAll] 의 카운트와
// `test/quest_catalog_test.dart` 의 **도달 가능성 가드가 함께 읽는 단일 정의**다.
// 한쪽에만 있으면 둘이 조용히 어긋나 target 이 어휘 수를 넘어서는 사고가 다시
// 난다 (2026-08-07 에 실제로 3건 발견 — 아래 참고).

/// Topic 기반 어휘 마스터리 소스 → `korean_vocab.csv` 의 `topic` 집합.
///
/// 각 집합의 행 수가 그 소스를 쓰는 퀘스트의 **도달 가능한 상한**이다.
/// 2026-08-11 실측 (총 930 행): 음식 31 · 형용사+감정 66 · 자연 23 · 직업+교육 54.
const Map<QuestSource, Set<String>> kQuestTopicSets = {
  QuestSource.foodWordsMastered: {'Essen & Trinken'},
  QuestSource.adjectiveFeelingWordsMastered: {'Beschreibung', 'Gefühle'},
  QuestSource.natureWordsMastered: {'Wetter', 'Geographie', 'Umwelt'},
  QuestSource.workEducationWordsMastered: {'Beruf', 'Bildung'},
};

/// 한자어 proxy — 공백을 뺀 길이가 2 이상이면 한자어로 추정한다.
/// (Phase 5 책 한 컷의 POS 데이터가 들어오면 정밀해질 자리.)
bool isHanjaProxyWord(String korean) => korean.replaceAll(' ', '').length >= 2;

/// 명절 상차림 단어 — `Essen & Trinken` 토픽의 고정 부분집합 (16 개).
///
/// **2026-08-07 재작성.** 옛 목록은 송편·추석·떡·한가위·명절·감·곶감·배·식혜·
/// 한과 12 개였는데 그 중 `korean_vocab.csv` 에 실재하는 건 `사과` 하나뿐이었다
/// (`밤` 은 매칭됐지만 이 코퍼스에서는 `Zeit` 토픽의 "Nacht" — 음식이 아니다).
/// 그래서 `q_chuseok` 의 카운트는 상한이 2 인데 target 이 12 이라 영원히 완료될
/// 수 없었고 `decoration_chuseok_moon` 도 뜨지 않았다.
/// 지금은 **코퍼스에 실재하는 단어만** 담는다 — 이 파일을 고칠 때 그 불변식을
/// 깨면 `quest_catalog_test` 의 가드가 잡는다.
///
/// 명절 어휘(송편·추석·한가위…)를 CSV 에 추가하면 여기로 되돌리는 게 맞다.
const Set<String> kChuseokFoodWords = {
  '밥',
  '고기',
  '생선',
  '채소',
  '과일',
  '사과',
  '계란',
  '김치',
  '차',
  '물',
  '먹다',
  '마시다',
  '맛있다',
  '요리하다',
  '맛',
  '달다',
};
