/// 미디어 영감 구절 (K-Pop/K-Drama/힙합 스타일 자체 예문).
class MediaPhrase {
  final String id;
  final String level;
  final String korean;
  final String romanization;
  final String german;
  final String english;

  /// "song" | "drama"
  final String sourceType;

  /// 예: "K-Pop 위로 발라드", "힙합 동기부여", "K-Drama 연애"
  final String sourceStyle;

  final List<String> grammarIds;
  final List<String> vocabIds;
  final String courseUnitId;
  final List<String> conceptIds;
  final String contextDe;
  final String contextEn;

  const MediaPhrase({
    required this.id,
    required this.level,
    required this.korean,
    required this.romanization,
    required this.german,
    required this.english,
    required this.sourceType,
    required this.sourceStyle,
    this.grammarIds = const [],
    this.vocabIds = const [],
    this.courseUnitId = '',
    this.conceptIds = const [],
    this.contextDe = '',
    this.contextEn = '',
  });

  factory MediaPhrase.fromJson(Map<String, dynamic> j) {
    return MediaPhrase(
      id: j['id'] as String? ?? '',
      level: j['level'] as String? ?? '',
      korean: j['korean'] as String? ?? '',
      romanization: j['romanization'] as String? ?? '',
      german: j['german'] as String? ?? '',
      english: j['english'] as String? ?? '',
      sourceType: j['source_type'] as String? ?? '',
      sourceStyle: j['source_style'] as String? ?? '',
      grammarIds: _strings(j['grammar_ids']),
      vocabIds: _strings(j['vocab_ids']),
      courseUnitId: j['courseUnitId'] as String? ?? '',
      conceptIds: _strings(j['conceptIds']),
      contextDe: j['context_de'] as String? ?? '',
      contextEn: j['context_en'] as String? ?? '',
    );
  }

  static List<String> _strings(dynamic v) {
    if (v is List) return v.cast<String>();
    return const [];
  }

  /// 현재 UI 언어에 맞는 의미 반환.
  String meaning(String lang) => lang == 'en' ? english : german;

  /// 현재 UI 언어에 맞는 맥락 반환.
  String context(String lang) => lang == 'en' ? contextEn : contextDe;
}
