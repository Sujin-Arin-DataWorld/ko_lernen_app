class Grammar {
  final String pattern;
  final String level;
  final String typeDe;
  final String explanationDe;
  final String exampleKorean;
  final String exampleGerman;
  final String note;

  // ── DE+EN 이중언어 (2026-06-09) ── 영어 열은 CSV 맨 뒤(7~10)에 추가됨.
  // 비어 있을 수 있으므로 헬퍼가 독일어로 자동 폴백.
  final String typeEn;
  final String explanationEn;
  final String exampleEn;
  final String noteEn;

  const Grammar({
    required this.pattern,
    required this.level,
    required this.typeDe,
    required this.explanationDe,
    required this.exampleKorean,
    required this.exampleGerman,
    required this.note,
    this.typeEn = '',
    this.explanationEn = '',
    this.exampleEn = '',
    this.noteEn = '',
  });

  /// row 가 짧아도 IndexError 없이 빈 값으로 채운다. (구 7-컬럼 / 신 11-컬럼 호환)
  factory Grammar.fromRow(List<dynamic> row) {
    String s(int i) => i < row.length ? row[i].toString() : '';
    return Grammar(
      pattern:       s(0),
      level:         s(1),
      typeDe:        s(2),
      explanationDe: s(3),
      exampleKorean: s(4),
      exampleGerman: s(5),
      note:          s(6),
      typeEn:        s(7),
      explanationEn: s(8),
      exampleEn:     s(9),
      noteEn:        s(10),
    );
  }

  // ── 언어별 표시 헬퍼 ── lang=='en' 이고 영어가 있으면 영어, 아니면 독일어.
  String typeFor(String lang) =>
      (lang == 'en' && typeEn.trim().isNotEmpty) ? typeEn : typeDe;

  String explanationFor(String lang) =>
      (lang == 'en' && explanationEn.trim().isNotEmpty)
          ? explanationEn
          : explanationDe;

  String exampleFor(String lang) =>
      (lang == 'en' && exampleEn.trim().isNotEmpty) ? exampleEn : exampleGerman;

  String noteFor(String lang) =>
      (lang == 'en' && noteEn.trim().isNotEmpty) ? noteEn : note;
}
