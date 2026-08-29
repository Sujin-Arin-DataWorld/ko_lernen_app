/// 한 CEFR 레벨의 CSV 큐레이션 순서(=grammar.csv 파일 등장 순, 재정렬 없음)를
/// 사용자 페이스대로 걷는 진행 상태. 레벨별로 저장돼, 레벨을 전환해도 다른
/// 레벨의 플랜은 지워지지 않고 "일시정지"된다(kl_gram_plan_v1, 레벨→플랜 맵).
class GrammarStudyPlan {
  const GrammarStudyPlan({
    required this.level,
    required this.itemsPerDay,
    required this.servedIdsByDate,
  });

  /// CEFR 레벨 코드(소문자, 예: 'a1').
  final String level;

  /// 하루 분량 — {3,5,7,10} 중 하나, 기본 5.
  final int itemsPerDay;

  /// dateIso → 그 날 실제로 서빙된 grammar row id 목록(서빙 순서 보존).
  /// **일자별 서빙 id 목록**이지 일차 카운트가 아니다 — grammar.csv 행이
  /// 재배치돼도 이미 서빙된 id 는 그대로 식별 가능하다(검수#24).
  final Map<String, List<String>> servedIdsByDate;

  /// "오늘 분량" 산정 기준 — 달력이 아니라 지금까지 완료한 날 수.
  int get completedDays => servedIdsByDate.length;

  factory GrammarStudyPlan.fromJson(Map<String, dynamic> json) {
    final rawServed = json['servedIdsByDate'];
    return GrammarStudyPlan(
      level: json['level']?.toString() ?? '',
      itemsPerDay: (json['itemsPerDay'] as num?)?.toInt() ?? 5,
      servedIdsByDate: rawServed is Map
          ? {
              for (final entry in rawServed.entries)
                entry.key.toString(): entry.value is List
                    ? [for (final id in entry.value as List) id.toString()]
                    : const <String>[],
            }
          : const {},
    );
  }

  Map<String, dynamic> toJson() => {
        'level': level,
        'itemsPerDay': itemsPerDay,
        'servedIdsByDate': servedIdsByDate,
      };

  GrammarStudyPlan copyWith({
    String? level,
    int? itemsPerDay,
    Map<String, List<String>>? servedIdsByDate,
  }) =>
      GrammarStudyPlan(
        level: level ?? this.level,
        itemsPerDay: itemsPerDay ?? this.itemsPerDay,
        servedIdsByDate: servedIdsByDate ?? this.servedIdsByDate,
      );
}
