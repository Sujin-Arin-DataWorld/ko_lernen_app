import '../data/quest_catalog.dart';
import '../models/quest.dart';
import '../models/gye.dart';
import 'data_loader.dart';
import 'gye_service.dart';
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
  static Future<List<QuestProgress>> computeAll({DateTime? now}) async {
    final today = now ?? DateTime.now();
    final completions = Storage.questCompletions;

    // CSV einmal pro Aufruf — Topic-Subsets aufbauen.
    final vocab = await DataLoader.loadVocab();
    final seen = Storage.vokSeenIds.toSet();

    int countSeenWithTopics(Set<String> topics) {
      return vocab
          .where((v) => topics.contains(v.topic) && seen.contains(v.korean))
          .length;
    }

    final foodCount =
        countSeenWithTopics({'Essen & Trinken'});
    final adjFeelCount =
        countSeenWithTopics({'Beschreibung', 'Gefühle'});
    final natureCount =
        countSeenWithTopics({'Wetter', 'Geographie', 'Umwelt'});
    final workEduCount =
        countSeenWithTopics({'Beruf', 'Bildung'});

    // Hanja-Proxy: koreanische Wörter mit ≥ 2 Silben sind häufig 한자어
    // (Approximation — Phase 5 책 한 컷 könnte präzisere POS-Daten liefern).
    final hanjaCount = vocab
        .where((v) =>
            v.korean.replaceAll(' ', '').length >= 2 &&
            seen.contains(v.korean))
        .length;

    // 송편 / Chuseok-Wörter — feste 12er-Liste aus dem Food-Set.
    final songpyeonCount = vocab.where(
      (v) =>
          _chuseokFoodWords.contains(v.korean) &&
          seen.contains(v.korean),
    ).length;

    // 한글 마스터리 — calligraphyTotalDays / 28 jamo × 100.
    // Wert ist clipped 0..100.
    final hangulPct =
        (Storage.calligraphyTotalDays * 100 / 28).clamp(0, 100).round();

    // 한글날 7-Tage-Challenge — Tage innerhalb Hangul-Day-Fenster.
    final hangeulChallenge = _calligraphyDaysInWindow(today, days: 14);

    // 어린이날 5-Tage-Streak — Streak innerhalb des Fensters.
    final childrensStreak = _calligraphyDaysInWindow(today, days: 11);

    return [
      for (final def in kQuestCatalog)
        _buildProgress(
          def,
          today: today,
          completions: completions,
          counters: {
            QuestSource.foodWordsMastered: foodCount,
            QuestSource.adjectiveFeelingWordsMastered: adjFeelCount,
            QuestSource.natureWordsMastered: natureCount,
            QuestSource.workEducationWordsMastered: workEduCount,
            QuestSource.hanjaWordsMastered: hanjaCount,
            QuestSource.scenariosCompleted: Storage.completedScenarios.length,
            QuestSource.pronunciationGood: 0, // Phase 5 ETA
            QuestSource.kkeunmariWins: Storage.kkeunmariWins,
            QuestSource.hangulMastery: hangulPct,
            QuestSource.streakDays: Storage.streakDays,
            QuestSource.friendsCount: 0, // Phase 6 ETA
            QuestSource.songpyeonWords: songpyeonCount,
            QuestSource.yutChosung: Storage.chosungCorrect,
            QuestSource.hangeulChallenge: hangeulChallenge,
            QuestSource.childrensDayCalligraphy: childrensStreak,
          },
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
        if (!Storage.pendingBoxes.contains(p.questId)) {
          await Storage.addPendingBox(p.questId);
        }
        await Storage.markQuestCompleted(p.questId);
        // 2픽: 방금 완료한 퀘스트를 계 피드에 broadcast (축하 유도)
        await GyeService.broadcastFeed(
          GyeFeedType.questCompleted,
          {'questId': p.questId},
        );
      }
    }
    // 2픽: 레벨업도 계 피드에 동기화 (순환 회피 — 여기서 pull)
    await GyeService.syncLevelUp();
  }

  // ── Helfer ──────────────────────────────────────────────────────────

  static QuestProgress _buildProgress(
    QuestDefinition def, {
    required DateTime today,
    required Map<String, String> completions,
    required Map<QuestSource, int> counters,
  }) {
    final active = def.isActiveOn(today);
    final cur = counters[def.source] ?? 0;
    final alreadyDone = completions.containsKey(def.id);
    final reached = cur >= def.target;
    return QuestProgress(
      questId: def.id,
      current: cur,
      target: def.target,
      active: active,
      completed: alreadyDone || reached,
      completedAtIso: completions[def.id],
    );
  }

  static int _calligraphyDaysInWindow(DateTime today, {required int days}) {
    final dates = Storage.calligraphyDates.toSet();
    final fromDay = today.subtract(Duration(days: days));
    int count = 0;
    for (final iso in dates) {
      final d = DateTime.tryParse(iso);
      if (d == null) continue;
      if (d.isAfter(fromDay.subtract(const Duration(seconds: 1))) &&
          d.isBefore(today.add(const Duration(days: 1)))) {
        count++;
      }
    }
    return count;
  }
}

/// Chuseok-Food-Wörter (Approximation — basiert auf scenarios.json/Vocab-Subset).
/// Phase 4 v1: hartkodiert. Konnte später in `assets/data/seasonal_keywords.json`
/// ausgelagert werden.
const Set<String> _chuseokFoodWords = {
  '송편', '추석', '떡', '한가위', '명절',
  '감', '곶감', '배', '사과', '밤',
  '식혜', '한과',
};
