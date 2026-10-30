import 'dart:convert';

import '../models/grammar.dart';
import '../models/grammar_study_plan.dart';

/// Grammatik 마스터플랜의 순수 슬라이스 로직. IO/Storage 는 다루지 않는다 —
/// 화면이 Storage.grammarPlanRawJson 을 읽고 [decodePlans]/[encodePlans] 로
/// 오간다.
abstract final class GrammarPlanService {
  static const List<int> itemsPerDayOptions = [3, 5, 7, 10];
  static const int defaultItemsPerDay = 5;

  /// grammar.csv 큐레이션 순서(=DataLoader.loadGrammar() 반환 순서, 파일
  /// 등장 순)를 유지한 채 [level] 행만 골라낸다. 정렬하지 않는다 — 정렬하면
  /// CSV 편집마다 슬라이스 경계가 흔들린다.
  static List<Grammar> curatedRowsForLevel(
    List<Grammar> source,
    String level,
  ) => source
      .where((g) => g.level.toUpperCase() == level.toUpperCase())
      .toList(growable: false);

  /// Next unserved IDs in current CSV order. Historical days retain their
  /// actual IDs, so changing pace cannot skip unseen rows or replay old ones.
  /// The screen still owns today's completed-day gate and cached quiz slice.
  static List<Grammar> todaysSlice({
    required List<Grammar> curatedRows,
    required GrammarStudyPlan plan,
  }) {
    if (plan.itemsPerDay <= 0) {
      return const <Grammar>[];
    }
    return _unservedRows(
      curatedRows,
      plan,
    ).take(plan.itemsPerDay).toList(growable: false);
  }

  static int totalDays(List<Grammar> curatedRows, int itemsPerDay) =>
      itemsPerDay <= 0 ? 0 : (curatedRows.length / itemsPerDay).ceil();

  static int totalDaysForPlan({
    required List<Grammar> curatedRows,
    required GrammarStudyPlan plan,
  }) {
    if (plan.itemsPerDay <= 0) {
      return 0;
    }
    final remaining = _unservedRows(curatedRows, plan).length;
    return plan.completedDays + (remaining / plan.itemsPerDay).ceil();
  }

  static Iterable<Grammar> _unservedRows(
    List<Grammar> curatedRows,
    GrammarStudyPlan plan,
  ) {
    final servedIds = {for (final day in plan.servedIdsByDate.values) ...day};
    return curatedRows.where((row) => !servedIds.contains(row.id));
  }

  /// dateIso 하루치 서빙 기록을 추가한 새 플랜(불변). 같은 날짜 재호출은
  /// 멱등 — 그 날짜 키를 그대로 덮어쓴다(호출측이 이미 오늘 슬라이스를
  /// 확정해 넘기므로 값은 항상 동일해야 한다).
  static GrammarStudyPlan recordServedDay(
    GrammarStudyPlan plan, {
    required String dateIso,
    required List<String> servedIds,
  }) {
    final next = Map<String, List<String>>.of(plan.servedIdsByDate);
    next[dateIso] = List<String>.unmodifiable(servedIds);
    return plan.copyWith(servedIdsByDate: next);
  }

  /// 레벨→플랜 맵 직렬화(Storage.grammarPlanRawJson 저장용).
  static String encodePlans(Map<String, GrammarStudyPlan> plans) => jsonEncode({
    for (final entry in plans.entries) entry.key: entry.value.toJson(),
  });

  /// 손상/빈 원본은 조용히 빈 맵으로 떨어진다.
  static Map<String, GrammarStudyPlan> decodePlans(String raw) {
    if (raw.trim().isEmpty) return const {};
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return const {};

      final plans = <String, GrammarStudyPlan>{};
      for (final entry in decoded.entries) {
        if (entry.value is! Map) return const {};
        final planJson = <String, dynamic>{
          for (final value in (entry.value as Map).entries)
            value.key.toString(): value.value,
        };
        plans[entry.key.toString()] = GrammarStudyPlan.fromJson(planJson);
      }
      return plans;
    } catch (_) {
      return const {};
    }
  }
}
