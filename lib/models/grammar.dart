import 'content_id.dart';

class Grammar {
  /// Immutable graph identity, independent from the learner-facing pattern.
  /// New corpus rows provide this in the dedicated `id` CSV column. Legacy
  /// test fixtures without it retain a deterministic semantic fallback.
  final String _sourceId;
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

  /// Reviewed learner-language phrase that expresses this grammar pattern in
  /// [exampleGerman]. It is intentionally stored separately from the rendered
  /// example: the study card stays natural, while the choice practice can
  /// highlight one precise semantic cue without trying to infer an inflected
  /// Korean surface form from [pattern].
  final String exampleGermanFocus;

  /// English counterpart of [exampleGermanFocus] for the same choice prompt.
  final String exampleEnFocus;

  /// Whether this row has a manually reviewed four-choice grammar prompt.
  ///
  /// This is intentionally explicit rather than inferred from translated
  /// examples: a missing or malformed future row must fail closed and remain
  /// available only in the normal grammar study library.
  final bool quizEnabled;

  /// Exactly three authored, same-level grammar IDs for the optional choice
  /// exercise. Their CSV order is canonical; only presentation order is
  /// shuffled at runtime.
  final List<String> quizDistractorIds;

  const Grammar({
    String id = '',
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
    this.exampleGermanFocus = '',
    this.exampleEnFocus = '',
    this.quizEnabled = false,
    this.quizDistractorIds = const <String>[],
  }) : _sourceId = id;

  /// A durable ID for graph links. [pattern] is presentation/source text and
  /// can change without invalidating the explicit CSV identity.
  String get id => _sourceId.trim().isNotEmpty
      ? _sourceId.trim()
      : stableContentId('grammar_legacy', [level, typeDe, pattern]);

  bool get hasExplicitId => _sourceId.trim().isNotEmpty;

  /// Rows may be short in legacy fixtures, so missing values stay empty
  /// rather than throwing. The current CSV has 16 columns: the original
  /// seven study fields, four EN fields, durable ID, two reviewed prompt
  /// focus markers, and two choice-practice metadata fields.
  factory Grammar.fromRow(List<dynamic> row) {
    String s(int i) => i < row.length ? row[i].toString() : '';
    final distractorIds = s(15)
        .split('|')
        .map((id) => id.trim())
        .where((id) => id.isNotEmpty)
        .toList(growable: false);
    return Grammar(
      pattern: s(0),
      level: s(1),
      typeDe: s(2),
      explanationDe: s(3),
      exampleKorean: s(4),
      exampleGerman: s(5),
      note: s(6),
      typeEn: s(7),
      explanationEn: s(8),
      exampleEn: s(9),
      noteEn: s(10),
      id: s(11),
      exampleGermanFocus: s(12),
      exampleEnFocus: s(13),
      quizEnabled: s(14).trim().toLowerCase() == 'true',
      quizDistractorIds: List<String>.unmodifiable(distractorIds),
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

  /// The reviewed phrase to emphasize in the learner-language example for
  /// the standalone four-choice grammar practice. A missing or ambiguous
  /// phrase leaves the row study-only rather than guessing a cue.
  String exampleFocusFor(String lang) =>
      lang == 'en' ? exampleEnFocus : exampleGermanFocus;

  /// A prompt is usable only when its authored focus occurs exactly once in
  /// the displayed sentence. This guards against a copied or stale marker
  /// silently emphasizing the wrong part of an otherwise valid example.
  bool hasSingleExampleFocusFor(String lang) {
    final focus = exampleFocusFor(lang).trim();
    final example = exampleFor(lang);
    if (focus.isEmpty || example.isEmpty) {
      return false;
    }
    final first = example.indexOf(focus);
    if (first < 0) {
      return false;
    }
    return example.indexOf(focus, first + focus.length) < 0;
  }
}
