class Vocab {
  final String korean;
  final String romanization;
  final String german;
  final String level;
  final String posDe;
  final String exampleKorean;
  final String exampleGerman;
  final String topic;

  // ── Phase 1 (stately-rising-jongga) ── Pack-Felder ─────────────────────
  // 알려진 단점: 구 8-컬럼 CSV / 테스트 fixture 와의 호환을 위해 모두
  // optional 기본값을 가진다.
  //   packId       — '' 면 팩 미할당 (마이그레이션 직후·테스트 fixture)
  //   packOrder    — 0 면 미할당
  //   isReviewBoss — 팩 끝 보스 단어 (클리어 조건). 기본 false.
  final String packId;
  final int packOrder;
  final bool isReviewBoss;

  const Vocab({
    required this.korean,
    required this.romanization,
    required this.german,
    required this.level,
    required this.posDe,
    required this.exampleKorean,
    required this.exampleGerman,
    required this.topic,
    this.packId = '',
    this.packOrder = 0,
    this.isReviewBoss = false,
  });

  /// 안정한 row → Vocab. 구 8-컬럼 / 신 11-컬럼 둘 다 처리.
  /// row 가 짧아도 IndexError 없이 빈 값/기본값으로 채운다.
  factory Vocab.fromRow(List<dynamic> row) {
    String s(int i) => i < row.length ? row[i].toString() : '';
    return Vocab(
      korean:        s(0),
      romanization:  s(1),
      german:        s(2),
      level:         s(3),
      posDe:         s(4),
      exampleKorean: s(5),
      exampleGerman: s(6),
      topic:         s(7),
      packId:        s(8),
      packOrder:     int.tryParse(s(9)) ?? 0,
      isReviewBoss:  s(10).toLowerCase() == 'true',
    );
  }
}
