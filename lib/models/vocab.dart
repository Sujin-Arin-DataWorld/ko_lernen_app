import 'content_id.dart';

class Vocab {
  /// Immutable source ID from the final `id` CSV column.
  final String _sourceId;
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

  // ── DE+EN 이중언어 (2026-06-09) ── 영어 열은 CSV 맨 뒤(11~13)에 추가됨.
  // 비어 있을 수 있으므로(구 fixture·미번역 행) 헬퍼가 독일어로 자동 폴백.
  final String english;
  final String posEn;
  final String exampleEnglish;

  const Vocab({
    String id = '',
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
    this.english = '',
    this.posEn = '',
    this.exampleEnglish = '',
  }) : _sourceId = id;

  /// Stable graph key from the source data. The current corpus must always
  /// use this explicit ID; the semantic fallback exists only for old fixtures.
  ///
  /// Legacy fallback intentionally excludes translated copy and pack ordering.
  String get id => hasExplicitId
      ? _sourceId.trim()
      : stableContentId('vocab_legacy', [
          korean,
          romanization,
          level,
          topic,
          packId,
        ]);

  bool get hasExplicitId => _sourceId.trim().isNotEmpty;

  /// 안정한 row → Vocab. 구 8-컬럼 / 신 11-컬럼 / 신 14-컬럼 모두 처리.
  /// row 가 짧아도 IndexError 없이 빈 값/기본값으로 채운다.
  factory Vocab.fromRow(List<dynamic> row) {
    String s(int i) => i < row.length ? row[i].toString() : '';
    return Vocab(
      korean: s(0),
      romanization: s(1),
      german: s(2),
      level: s(3),
      posDe: s(4),
      exampleKorean: s(5),
      exampleGerman: s(6),
      topic: s(7),
      packId: s(8),
      packOrder: int.tryParse(s(9)) ?? 0,
      isReviewBoss: s(10).toLowerCase() == 'true',
      english: s(11),
      posEn: s(12),
      exampleEnglish: s(13),
      id: s(14),
    );
  }

  // ── 언어별 표시 헬퍼 ── lang=='en' 이고 영어가 있으면 영어, 아니면 독일어.
  /// 뜻 (en 우선, 없으면 de).
  String translationFor(String lang) =>
      (lang == 'en' && english.trim().isNotEmpty) ? english : german;

  /// 품사 라벨.
  String posFor(String lang) =>
      (lang == 'en' && posEn.trim().isNotEmpty) ? posEn : posDe;

  /// 예문 번역.
  String exampleFor(String lang) =>
      (lang == 'en' && exampleEnglish.trim().isNotEmpty)
      ? exampleEnglish
      : exampleGerman;
}
