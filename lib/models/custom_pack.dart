import 'book_page.dart';

/// Phase 5.1 (stately-rising-jongga) — "책 한 컷" 에서 만들어진 사용자 정의 팩.
///
/// 일반 `VocabPack` (CSV 기반) 과는 별도 — 단어가 사용자 사진에서 추출됐고,
/// 글로벌 vocab CSV 와 별개로 관리. Closed Testing 의 핵심 사용자 흐름:
///   1. 사용자가 책 페이지를 사진 찍어 분석
///   2. "이 페이지로 팩 만들기" 탭 → 이름 입력 → CustomPack 생성
///   3. /custom_pack/play → flip card 학습
class CustomPack {
  final String id;

  /// 사용자가 정한 이름 — 예: "Schritte 1 — Lektion 5".
  /// 비어있으면 sourcePage 의 capturedAt 으로 fallback.
  final String name;

  /// 원본 `BookPage.id`. 책장에서 다시 참조 가능.
  final String sourcePageId;

  /// 팩에 포함된 단어들 (BookPage 에서 복사 — denormalized 라 BookPage 가
  /// 삭제돼도 팩은 작동).
  final List<ExtractedWord> words;

  /// ISO UTC 생성 시각.
  final String createdAtIso;

  const CustomPack({
    required this.id,
    required this.name,
    required this.sourcePageId,
    required this.words,
    required this.createdAtIso,
  });

  /// `BookPage` 에서 직접 생성. id 는 호출자가 부여.
  factory CustomPack.fromBookPage({
    required String id,
    required String name,
    required BookPage page,
    DateTime? createdAt,
  }) {
    return CustomPack(
      id: id,
      name: name,
      sourcePageId: page.id,
      words: List<ExtractedWord>.from(page.words),
      createdAtIso: (createdAt ?? DateTime.now().toUtc()).toIso8601String(),
    );
  }

  /// 사용자가 직접 만드는 빈 단어장 ("나만의 단어장"). 사진 출처 없음.
  factory CustomPack.manual({
    required String id,
    required String name,
    List<ExtractedWord> words = const [],
    DateTime? createdAt,
  }) {
    return CustomPack(
      id: id,
      name: name,
      sourcePageId: '', // 빈 값 = 수동 생성 단어장
      words: List<ExtractedWord>.from(words),
      createdAtIso: (createdAt ?? DateTime.now().toUtc()).toIso8601String(),
    );
  }

  /// 사진이 아니라 사용자가 손으로 만든 단어장인지.
  bool get isManual => sourcePageId.isEmpty;

  CustomPack copyWith({String? name, List<ExtractedWord>? words}) => CustomPack(
        id: id,
        name: name ?? this.name,
        sourcePageId: sourcePageId,
        words: words ?? this.words,
        createdAtIso: createdAtIso,
      );

  Map<String, dynamic> toJson() => {
        'name': name,
        'sourcePageId': sourcePageId,
        'words': words.map((w) => w.toJson()).toList(),
        'createdAt': createdAtIso,
      };

  factory CustomPack.fromJson(String id, Map<String, dynamic> j) => CustomPack(
        id: id,
        name: j['name'] as String? ?? '',
        sourcePageId: j['sourcePageId'] as String? ?? '',
        words: ((j['words'] as List?) ?? const [])
            .map((e) => ExtractedWord.fromJson(
                (e as Map).cast<String, dynamic>()))
            .toList(),
        createdAtIso: j['createdAt'] as String? ?? '',
      );

  int get totalWords => words.length;

  /// UI 표시 라벨 — name 비어있으면 short date.
  String displayName() {
    if (name.trim().isNotEmpty) return name;
    if (createdAtIso.length >= 10) return createdAtIso.substring(0, 10);
    return 'Custom Pack';
  }
}
