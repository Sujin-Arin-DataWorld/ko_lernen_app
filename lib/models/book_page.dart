// Phase 5 (stately-rising-jongga) — "책 한 컷" 데이터 모델.
//
// 사용자가 한국어 교재 페이지를 사진 찍어서 분석한 결과를 표현.
// Local + Firestore 양쪽에 사용되는 plain DTO.

class ExtractedWord {
  final String korean;
  final String romanization;
  final String posDe; // 'Nomen' / 'Verb' / 'Adjektiv' / ...
  final String translationDe;
  final String translationEn;
  final String exampleKorean; // 추출 텍스트 중 첫 등장 문장 (옵션)
  final String exampleDe;
  final String? savedToPackId; // 저장한 custom pack id (null = 미저장)

  const ExtractedWord({
    required this.korean,
    required this.romanization,
    required this.posDe,
    required this.translationDe,
    required this.translationEn,
    required this.exampleKorean,
    required this.exampleDe,
    required this.savedToPackId,
  });

  Map<String, dynamic> toJson() => {
    'korean': korean,
    'romanization': romanization,
    'posDe': posDe,
    'translationDe': translationDe,
    'translationEn': translationEn,
    'exampleKorean': exampleKorean,
    'exampleDe': exampleDe,
    'savedToPackId': savedToPackId,
  };

  factory ExtractedWord.fromJson(Map<String, dynamic> j) => ExtractedWord(
    korean: j['korean'] as String? ?? '',
    romanization: j['romanization'] as String? ?? '',
    posDe: j['posDe'] as String? ?? '',
    translationDe: j['translationDe'] as String? ?? '',
    translationEn: j['translationEn'] as String? ?? '',
    exampleKorean: j['exampleKorean'] as String? ?? '',
    exampleDe: j['exampleDe'] as String? ?? '',
    savedToPackId: j['savedToPackId'] as String?,
  );

  ExtractedWord copyWith({String? savedToPackId, bool clearSaved = false}) =>
      ExtractedWord(
        korean: korean,
        romanization: romanization,
        posDe: posDe,
        translationDe: translationDe,
        translationEn: translationEn,
        exampleKorean: exampleKorean,
        exampleDe: exampleDe,
        savedToPackId: clearSaved
            ? null
            : (savedToPackId ?? this.savedToPackId),
      );
}

/// 문법 패턴 hit — `grammar_patterns.json` 의 한 entry 가 텍스트에 매치된 것.
class GrammarHit {
  /// 패턴 ID (예: `g_progressive`).
  final String patternId;

  /// 패턴 사람-읽기 이름 (DE).
  final String nameDe;

  /// 매치된 텍스트 조각 (예: `'먹고 있어요'`).
  final String matchedText;

  /// CEFR 레벨 추정 (`A1` / `A2` / `B1` / `B2`).
  final String level;

  /// 짧은 사용법 설명.
  final String explanationDe;

  const GrammarHit({
    required this.patternId,
    required this.nameDe,
    required this.matchedText,
    required this.level,
    required this.explanationDe,
  });

  Map<String, dynamic> toJson() => {
    'patternId': patternId,
    'nameDe': nameDe,
    'matchedText': matchedText,
    'level': level,
    'explanationDe': explanationDe,
  };

  factory GrammarHit.fromJson(Map<String, dynamic> j) => GrammarHit(
    patternId: j['patternId'] as String? ?? '',
    nameDe: j['nameDe'] as String? ?? '',
    matchedText: j['matchedText'] as String? ?? '',
    level: j['level'] as String? ?? '',
    explanationDe: j['explanationDe'] as String? ?? '',
  );
}

/// 분석된 한 문장.
class TranslatedSentence {
  final String korean;
  final String translationDe;

  const TranslatedSentence({required this.korean, required this.translationDe});

  Map<String, dynamic> toJson() => {
    'korean': korean,
    'translationDe': translationDe,
  };

  factory TranslatedSentence.fromJson(Map<String, dynamic> j) =>
      TranslatedSentence(
        korean: j['korean'] as String? ?? '',
        translationDe: j['translationDe'] as String? ?? '',
      );
}

/// 책 페이지 한 장 — bookshelf 의 entry.
class BookPage {
  /// Firestore document ID — 시간 기반 짧은 ULID-like.
  final String id;

  /// 기기 로컬 이미지 경로 (path_provider 의 application support dir 안).
  /// Firestore 에는 저장되지 않음. 기기 변경 시 사라짐.
  final String? localThumbnailPath;

  /// OCR 결과 원본 텍스트.
  final String extractedText;

  /// 사용자 메모 (max 200자 권장).
  final String note;

  /// 분석된 단어 목록 (max 30).
  final List<ExtractedWord> words;

  /// 검출된 문법 hit (중복 패턴은 첫 매치만 보관).
  final List<GrammarHit> grammar;

  /// 분석된 문장 (max ~10).
  final List<TranslatedSentence> sentences;

  /// 캡쳐 시각 (ISO UTC).
  final String capturedAtIso;

  /// 이 페이지에서 만든 커스텀 팩 ID (선택).
  final String? customPackId;

  const BookPage({
    required this.id,
    required this.localThumbnailPath,
    required this.extractedText,
    required this.note,
    required this.words,
    required this.grammar,
    required this.sentences,
    required this.capturedAtIso,
    required this.customPackId,
  });

  Map<String, dynamic> toFirestoreJson() => {
    // localThumbnailPath 는 의도적으로 제외 — 기기 로컬 경로는 다른 기기에서 의미 없음.
    'extractedText': extractedText,
    'note': note,
    'words': words.map((w) => w.toJson()).toList(),
    'grammar': grammar.map((g) => g.toJson()).toList(),
    'sentences': sentences.map((s) => s.toJson()).toList(),
    'capturedAt': capturedAtIso,
    'customPackId': customPackId,
  };

  Map<String, dynamic> toLocalJson() => {
    'id': id,
    'localThumbnailPath': localThumbnailPath,
    ...toFirestoreJson(),
  };

  factory BookPage.fromJson(String id, Map<String, dynamic> j) => BookPage(
    id: id,
    localThumbnailPath: j['localThumbnailPath'] as String?,
    extractedText: j['extractedText'] as String? ?? '',
    note: j['note'] as String? ?? '',
    words: ((j['words'] as List?) ?? const [])
        .map((e) => ExtractedWord.fromJson((e as Map).cast<String, dynamic>()))
        .toList(),
    grammar: ((j['grammar'] as List?) ?? const [])
        .map((e) => GrammarHit.fromJson((e as Map).cast<String, dynamic>()))
        .toList(),
    sentences: ((j['sentences'] as List?) ?? const [])
        .map(
          (e) =>
              TranslatedSentence.fromJson((e as Map).cast<String, dynamic>()),
        )
        .toList(),
    capturedAtIso: j['capturedAt'] as String? ?? '',
    customPackId: j['customPackId'] as String?,
  );
}

/// 분석 결과 (Cloud Function 응답에서 직접 변환).
class BookAnalysisResult {
  final List<ExtractedWord> words;
  final List<GrammarHit> grammar;
  final List<TranslatedSentence> sentences;
  final List<String> warnings; // 예: "DeepL rate limit, 18 단어 번역 안 됨"

  const BookAnalysisResult({
    required this.words,
    required this.grammar,
    required this.sentences,
    required this.warnings,
  });

  factory BookAnalysisResult.empty() => const BookAnalysisResult(
    words: [],
    grammar: [],
    sentences: [],
    warnings: ['analysis_unavailable'],
  );
}
