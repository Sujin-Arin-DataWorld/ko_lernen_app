// Phase 5 (stately-rising-jongga) — "책 한 컷" 데이터 모델.
//
// 사용자가 한국어 교재 페이지를 사진 찍어서 분석한 결과를 표현.
// Local + Firestore 양쪽에 사용되는 plain DTO.

import '../services/book_analysis_text.dart';
import '../services/book_image_service.dart';

String _bookLanguage(Object? value) => value == 'en' ? 'en' : 'de';

String _safeSupportedText(Object? value) =>
    BookAnalysisTextPreprocessor.sanitizeUnexpectedScripts(
      value is String ? value : '',
    ).text;

String _safeKoreanText(Object? value) =>
    BookAnalysisTextPreprocessor.prepare(value is String ? value : '').text;

const int maxExtractedWordKoreanCharacters = 80;
const int maxExtractedWordMeaningCharacters = 240;
const int maxExtractedWordExampleCharacters = 500;
const int maxExtractedWordDefinitionCharacters = 500;

String _limitCodePoints(String value, int maximum) =>
    String.fromCharCodes(value.runes.take(maximum));

String _safeWordKorean(Object? value) => _limitCodePoints(
  _safeKoreanText(value).replaceAll(RegExp(r'\s+'), ' ').trim(),
  maxExtractedWordKoreanCharacters,
);

String _safeWordMeaning(Object? value) => _limitCodePoints(
  _safeSupportedText(value).replaceAll(RegExp(r'\s+'), ' ').trim(),
  maxExtractedWordMeaningCharacters,
);

String _safeWordExample(Object? value) =>
    _limitCodePoints(_safeKoreanText(value), maxExtractedWordExampleCharacters);

String _safeWordDefinition(Object? value) => _limitCodePoints(
  _safeSupportedText(value),
  maxExtractedWordDefinitionCharacters,
);

String? _managedRefFor(Object? value, ManagedMediaKind kind) {
  final reference = ManagedMediaRef.tryParse(value);
  return reference?.kind == kind ? reference?.encoded : null;
}

class ExtractedWord {
  final String korean;
  final String romanization;
  final String posDe; // 'Nomen' / 'Verb' / 'Adjektiv' / ...
  final String translationDe;
  final String translationEn;
  final String translationLanguage;
  final String exampleKorean; // 추출 텍스트 중 첫 등장 문장 (옵션)
  final String exampleDe;
  final String exampleEn;
  final String exampleLanguage;
  final String definitionKo; // 우리말샘 국어사전 뜻풀이 (옵션, 없으면 '')
  final String imagePath; // 첨부 사진 로컬 경로 (옵션, 없으면 ''). 앱 문서 폴더.
  final String? savedToPackId; // 저장한 custom pack id (null = 미저장)
  final String sourceUnitId;

  const ExtractedWord({
    required this.korean,
    required this.romanization,
    required this.posDe,
    required this.translationDe,
    required this.translationEn,
    required this.exampleKorean,
    required this.exampleDe,
    this.exampleEn = '',
    this.exampleLanguage = '',
    required this.savedToPackId,
    this.translationLanguage = 'de',
    this.definitionKo = '',
    this.imagePath = '',
    this.sourceUnitId = '',
  });

  /// Only return a meaning known to belong to the requested language.
  /// Old English OCR/import rows may still use the legacy German-named slot.
  String translationFor(String languageCode) {
    if (languageCode == 'en') {
      return translationEn.trim().isNotEmpty
          ? translationEn
          : (translationLanguage == 'en' ? translationDe : '');
    }
    if (translationLanguage == 'en' &&
        (translationEn.trim().isEmpty ||
            translationDe.trim() == translationEn.trim())) {
      return '';
    }
    return translationDe;
  }

  /// Retained original meaning for explicit editing, never a locale fallback.
  String get originalTranslation => translationLanguage == 'en'
      ? (translationEn.trim().isNotEmpty ? translationEn : translationDe)
      : translationDe;

  /// Old analysis responses store the requested language in exampleDe.
  /// Never present that German-only example as an English learning cue.
  String exampleFor(String languageCode) {
    if (languageCode == 'en') {
      return exampleEn.isNotEmpty
          ? exampleEn
          : (_resolvedExampleLanguage == 'en' ? exampleDe : '');
    }
    return _resolvedExampleLanguage == 'en' ? '' : exampleDe;
  }

  String get _resolvedExampleLanguage =>
      exampleLanguage.isEmpty ? translationLanguage : exampleLanguage;

  String posFor(String languageCode) {
    if (languageCode != 'en') {
      return posDe;
    }
    return const {
          'Nomen': 'Noun',
          'Substantiv': 'Noun',
          'Verb': 'Verb',
          'Adjektiv': 'Adjective',
          'Adverb': 'Adverb',
          'Pronomen': 'Pronoun',
          'Partikel': 'Particle',
          'Interjektion': 'Interjection',
          'Ausdruck': 'Expression',
          'Phrase': 'Phrase',
          'Zahlwort': 'Numeral',
          'Konjunktion': 'Conjunction',
          'Verbphrase': 'Verb phrase',
        }[posDe] ??
        (const {
              'Noun',
              'Adjective',
              'Pronoun',
              'Particle',
              'Interjection',
              'Expression',
              'Numeral',
              'Conjunction',
              'Verb phrase',
            }.contains(posDe)
            ? posDe
            : '');
  }

  /// 사용자가 손으로 입력하는 단어 ("나만의 단어장"). 옵션 필드는 기본 빈 값.
  factory ExtractedWord.manual({
    required String korean,
    required String translationDe,
    String translationEn = '',
    String translationLanguage = 'de',
    String romanization = '',
    String posDe = '',
    String exampleKorean = '',
    String exampleDe = '',
    String exampleEn = '',
    String exampleLanguage = '',
    String definitionKo = '',
    String imagePath = '',
  }) => ExtractedWord(
    korean: _safeWordKorean(korean),
    romanization: _safeWordMeaning(romanization),
    posDe: _safeWordMeaning(posDe),
    translationDe: _safeWordMeaning(translationDe),
    translationEn: _safeWordMeaning(translationEn),
    translationLanguage: _bookLanguage(translationLanguage),
    exampleKorean: _safeWordExample(exampleKorean),
    exampleDe: _safeWordMeaning(exampleDe),
    exampleEn: _safeWordMeaning(exampleEn),
    exampleLanguage: exampleLanguage.isEmpty
        ? _bookLanguage(translationLanguage)
        : _bookLanguage(exampleLanguage),
    definitionKo: _safeWordDefinition(definitionKo),
    imagePath: imagePath,
    savedToPackId: null,
  );

  Map<String, dynamic> toLocalJson() => {
    'korean': korean,
    'romanization': romanization,
    'posDe': posDe,
    'translationDe': translationDe,
    'translationEn': translationEn,
    'translationLanguage': translationLanguage,
    'exampleKorean': exampleKorean,
    'exampleDe': exampleDe,
    'exampleEn': exampleEn,
    'exampleLanguage': _resolvedExampleLanguage,
    'definitionKo': definitionKo,
    'imagePath': _managedRefFor(imagePath, ManagedMediaKind.word) ?? '',
    'savedToPackId': savedToPackId,
    if (sourceUnitId.isNotEmpty) 'sourceUnitId': sourceUnitId,
  };

  Map<String, dynamic> toPortableJson() => {
    'korean': korean,
    'romanization': romanization,
    'posDe': posDe,
    'translationDe': translationDe,
    'translationEn': translationEn,
    'translationLanguage': translationLanguage,
    'exampleKorean': exampleKorean,
    'exampleDe': exampleDe,
    'exampleEn': exampleEn,
    'exampleLanguage': _resolvedExampleLanguage,
    'definitionKo': definitionKo,
    'savedToPackId': savedToPackId,
    if (sourceUnitId.isNotEmpty) 'sourceUnitId': sourceUnitId,
  };

  Map<String, dynamic> toJson() => toLocalJson();

  factory ExtractedWord.fromLocalJson(Map<String, dynamic> j) => ExtractedWord(
    korean: _safeWordKorean(j['korean']),
    romanization: _safeWordMeaning(j['romanization']),
    posDe: _safeWordMeaning(j['posDe']),
    translationDe: _safeWordMeaning(j['translationDe']),
    translationEn: _safeWordMeaning(j['translationEn']),
    translationLanguage: _bookLanguage(j['translationLanguage']),
    exampleKorean: _safeWordExample(j['exampleKorean']),
    exampleDe: _safeWordMeaning(j['exampleDe']),
    exampleEn: _safeWordMeaning(j['exampleEn']),
    exampleLanguage: _bookLanguage(
      j['exampleLanguage'] ?? j['translationLanguage'],
    ),
    definitionKo: _safeWordDefinition(j['definitionKo']),
    imagePath: _managedRefFor(j['imagePath'], ManagedMediaKind.word) ?? '',
    savedToPackId: j['savedToPackId'] as String?,
    sourceUnitId: _safeSupportedText(j['sourceUnitId']),
  );

  factory ExtractedWord.fromPortableJson(Map<String, dynamic> j) =>
      ExtractedWord(
        korean: _safeWordKorean(j['korean']),
        romanization: _safeWordMeaning(j['romanization']),
        posDe: _safeWordMeaning(j['posDe']),
        translationDe: _safeWordMeaning(j['translationDe']),
        translationEn: _safeWordMeaning(j['translationEn']),
        translationLanguage: _bookLanguage(j['translationLanguage']),
        exampleKorean: _safeWordExample(j['exampleKorean']),
        exampleDe: _safeWordMeaning(j['exampleDe']),
        exampleEn: _safeWordMeaning(j['exampleEn']),
        exampleLanguage: _bookLanguage(
          j['exampleLanguage'] ?? j['translationLanguage'],
        ),
        definitionKo: _safeWordDefinition(j['definitionKo']),
        imagePath: '',
        savedToPackId: j['savedToPackId'] as String?,
        sourceUnitId: _safeSupportedText(j['sourceUnitId']),
      );

  factory ExtractedWord.fromJson(Map<String, dynamic> j) =>
      ExtractedWord.fromLocalJson(j);

  ExtractedWord copyWith({String? savedToPackId, bool clearSaved = false}) =>
      ExtractedWord(
        korean: korean,
        romanization: romanization,
        posDe: posDe,
        translationDe: translationDe,
        translationEn: translationEn,
        translationLanguage: translationLanguage,
        exampleKorean: exampleKorean,
        exampleDe: exampleDe,
        exampleEn: exampleEn,
        exampleLanguage: _resolvedExampleLanguage,
        definitionKo: definitionKo,
        imagePath: imagePath,
        sourceUnitId: sourceUnitId,
        savedToPackId: clearSaved
            ? null
            : (savedToPackId ?? this.savedToPackId),
      );

  ExtractedWord copyWithEditable({
    String? korean,
    String? translationDe,
    String? translationEn,
    String? translationLanguage,
    String? exampleKorean,
    String? exampleDe,
    String? exampleEn,
    String? exampleLanguage,
    String? definitionKo,
    String? imagePath,
    bool clearImage = false,
  }) => ExtractedWord(
    korean: _safeWordKorean(korean ?? this.korean),
    romanization: romanization,
    posDe: posDe,
    translationDe: _safeWordMeaning(translationDe ?? this.translationDe),
    translationEn: _safeWordMeaning(translationEn ?? this.translationEn),
    translationLanguage: _bookLanguage(
      translationLanguage ?? this.translationLanguage,
    ),
    exampleKorean: _safeWordExample(exampleKorean ?? this.exampleKorean),
    exampleDe: _safeWordMeaning(exampleDe ?? this.exampleDe),
    exampleEn: _safeWordMeaning(exampleEn ?? this.exampleEn),
    exampleLanguage: exampleLanguage ?? _resolvedExampleLanguage,
    definitionKo: _safeWordDefinition(definitionKo ?? this.definitionKo),
    imagePath: clearImage ? '' : (imagePath ?? this.imagePath),
    sourceUnitId: sourceUnitId,
    savedToPackId: savedToPackId,
  );
}

/// A multi-word learning expression extracted from a source OCR unit.
class ExtractedExpression {
  const ExtractedExpression({
    required this.korean,
    required this.translationDe,
    required this.translationEn,
    required this.translationLanguage,
    required this.sourceUnitId,
  });

  final String korean;
  final String translationDe;
  final String translationEn;
  final String translationLanguage;
  final String sourceUnitId;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'korean': korean,
    'translationDe': translationDe,
    'translationEn': translationEn,
    'translationLanguage': translationLanguage,
    'sourceUnitId': sourceUnitId,
  };

  factory ExtractedExpression.fromJson(Map<String, dynamic> json) =>
      ExtractedExpression(
        korean: _safeWordExample(json['korean']),
        translationDe: _safeWordMeaning(json['translationDe']),
        translationEn: _safeWordMeaning(json['translationEn']),
        translationLanguage: _bookLanguage(json['translationLanguage']),
        sourceUnitId: _safeSupportedText(json['sourceUnitId']),
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
  final String sourceUnitId;

  const GrammarHit({
    required this.patternId,
    required this.nameDe,
    required this.matchedText,
    required this.level,
    required this.explanationDe,
    this.sourceUnitId = '',
  });

  Map<String, dynamic> toJson() => {
    'patternId': patternId,
    'nameDe': nameDe,
    'matchedText': matchedText,
    'level': level,
    'explanationDe': explanationDe,
    'sourceUnitId': sourceUnitId,
  };

  factory GrammarHit.fromJson(Map<String, dynamic> j) => GrammarHit(
    patternId: _safeSupportedText(j['patternId']),
    nameDe: _safeSupportedText(j['nameDe']),
    matchedText: _safeKoreanText(j['matchedText']),
    level: _safeSupportedText(j['level']),
    explanationDe: _safeSupportedText(j['explanationDe']),
    sourceUnitId: _safeSupportedText(j['sourceUnitId']),
  );
}

/// 분석된 한 문장.
class TranslatedSentence {
  final String korean;
  final String translationDe;
  final String translationLanguage;
  final String sourceUnitId;

  const TranslatedSentence({
    required this.korean,
    required this.translationDe,
    this.translationLanguage = 'de',
    this.sourceUnitId = '',
  });

  Map<String, dynamic> toJson() => {
    'korean': korean,
    'translationDe': translationDe,
    'translationLanguage': translationLanguage,
    'sourceUnitId': sourceUnitId,
  };

  factory TranslatedSentence.fromJson(Map<String, dynamic> j) =>
      TranslatedSentence(
        korean: _safeKoreanText(j['korean']),
        translationDe: _safeSupportedText(j['translationDe']),
        translationLanguage: _bookLanguage(j['translationLanguage']),
        sourceUnitId: _safeSupportedText(j['sourceUnitId']),
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

  /// Multi-word learning expressions preserved separately from word lemmas.
  final List<ExtractedExpression> expressions;

  /// 캡쳐 시각 (ISO UTC).
  final String capturedAtIso;

  /// 이 페이지에서 만든 커스텀 팩 ID (선택).
  final String? customPackId;
  final String analysisLanguage;

  const BookPage({
    required this.id,
    required this.localThumbnailPath,
    required this.extractedText,
    required this.note,
    required this.words,
    required this.grammar,
    required this.sentences,
    this.expressions = const <ExtractedExpression>[],
    required this.capturedAtIso,
    required this.customPackId,
    this.analysisLanguage = 'de',
  });

  Map<String, dynamic> toFirestoreJson() => {
    // localThumbnailPath 는 의도적으로 제외 — 기기 로컬 경로는 다른 기기에서 의미 없음.
    'extractedText': extractedText,
    'note': note,
    'words': words.map((w) => w.toPortableJson()).toList(),
    'grammar': grammar.map((g) => g.toJson()).toList(),
    'sentences': sentences.map((s) => s.toJson()).toList(),
    'expressions': expressions.map((e) => e.toJson()).toList(),
    'capturedAt': capturedAtIso,
    'customPackId': customPackId,
    'analysisLanguage': analysisLanguage,
  };

  Map<String, dynamic> toLocalJson() => {
    'id': id,
    'localThumbnailPath': _managedRefFor(
      localThumbnailPath,
      ManagedMediaKind.book,
    ),
    'extractedText': extractedText,
    'note': note,
    'words': words.map((w) => w.toLocalJson()).toList(),
    'grammar': grammar.map((g) => g.toJson()).toList(),
    'sentences': sentences.map((s) => s.toJson()).toList(),
    'expressions': expressions.map((e) => e.toJson()).toList(),
    'capturedAt': capturedAtIso,
    'customPackId': customPackId,
    'analysisLanguage': analysisLanguage,
  };

  factory BookPage.fromJson(String id, Map<String, dynamic> j) => BookPage(
    id: id,
    localThumbnailPath: _managedRefFor(
      j['localThumbnailPath'],
      ManagedMediaKind.book,
    ),
    extractedText: _safeKoreanText(j['extractedText']),
    note: j['note'] as String? ?? '',
    words: ((j['words'] as List?) ?? const [])
        .map(
          (entry) => ExtractedWord.fromLocalJson(
            (entry as Map).cast<String, dynamic>(),
          ),
        )
        .where(_isSafeLegacyWord)
        .toList(),
    grammar: ((j['grammar'] as List?) ?? const [])
        .map(
          (entry) =>
              GrammarHit.fromJson((entry as Map).cast<String, dynamic>()),
        )
        .where(_isSafeLegacyGrammar)
        .toList(),
    sentences: ((j['sentences'] as List?) ?? const [])
        .map(
          (entry) => TranslatedSentence.fromJson(
            (entry as Map).cast<String, dynamic>(),
          ),
        )
        .where(_isSafeLegacySentence)
        .toList(),
    expressions: ((j['expressions'] as List?) ?? const [])
        .map(
          (entry) => ExtractedExpression.fromJson(
            (entry as Map).cast<String, dynamic>(),
          ),
        )
        .where(_isSafeLegacyExpression)
        .toList(),
    capturedAtIso: j['capturedAt'] as String? ?? '',
    customPackId: j['customPackId'] as String?,
    analysisLanguage: _bookLanguage(j['analysisLanguage']),
  );

  factory BookPage.fromPortableJson(String id, Map<String, dynamic> j) =>
      BookPage(
        id: id,
        localThumbnailPath: null,
        extractedText: _safeKoreanText(j['extractedText']),
        note: j['note'] as String? ?? '',
        words: ((j['words'] as List?) ?? const [])
            .map(
              (entry) => ExtractedWord.fromPortableJson(
                (entry as Map).cast<String, dynamic>(),
              ),
            )
            .where(_isSafeLegacyWord)
            .toList(),
        grammar: ((j['grammar'] as List?) ?? const [])
            .map(
              (entry) =>
                  GrammarHit.fromJson((entry as Map).cast<String, dynamic>()),
            )
            .where(_isSafeLegacyGrammar)
            .toList(),
        sentences: ((j['sentences'] as List?) ?? const [])
            .map(
              (entry) => TranslatedSentence.fromJson(
                (entry as Map).cast<String, dynamic>(),
              ),
            )
            .where(_isSafeLegacySentence)
            .toList(),
        expressions: ((j['expressions'] as List?) ?? const [])
            .map(
              (entry) => ExtractedExpression.fromJson(
                (entry as Map).cast<String, dynamic>(),
              ),
            )
            .where(_isSafeLegacyExpression)
            .toList(),
        capturedAtIso: j['capturedAt'] as String? ?? '',
        customPackId: j['customPackId'] as String?,
        analysisLanguage: _bookLanguage(j['analysisLanguage']),
      );

  BookPage copyWith({String? localThumbnailPath}) => BookPage(
    id: id,
    localThumbnailPath: localThumbnailPath ?? this.localThumbnailPath,
    extractedText: extractedText,
    note: note,
    words: words,
    grammar: grammar,
    sentences: sentences,
    expressions: expressions,
    capturedAtIso: capturedAtIso,
    customPackId: customPackId,
    analysisLanguage: analysisLanguage,
  );
}

bool _isSafeLegacyWord(ExtractedWord word) {
  if (!BookAnalysisTextPreprocessor.containsHangulSyllable(word.korean)) {
    return false;
  }
  final selectedMeaning = word.translationLanguage == 'en'
      ? (word.translationEn.isNotEmpty
            ? word.translationEn
            : word.translationDe)
      : word.translationDe;
  return selectedMeaning.trim().isNotEmpty;
}

bool _isSafeLegacyGrammar(GrammarHit grammar) =>
    BookAnalysisTextPreprocessor.containsHangulSyllable(grammar.matchedText);

bool _isSafeLegacySentence(TranslatedSentence sentence) =>
    BookAnalysisTextPreprocessor.containsHangulSyllable(sentence.korean);

bool _isSafeLegacyExpression(ExtractedExpression expression) =>
    BookAnalysisTextPreprocessor.containsHangulSyllable(expression.korean) &&
    (expression.translationLanguage == 'en'
        ? (expression.translationEn.isNotEmpty ||
              expression.translationDe.isNotEmpty)
        : expression.translationDe.isNotEmpty);

/// 분석 결과 (Cloud Function 응답에서 직접 변환).
class BookAnalysisResult {
  static const Set<String> blockingWarnings = {
    'no_korean_text',
    'invalid_response_schema',
    'wrong_analysis_language',
    'empty_analysis_result',
    'invalid_response_filtered',
  };

  final List<ExtractedWord> words;
  final List<GrammarHit> grammar;
  final List<TranslatedSentence> sentences;
  final List<ExtractedExpression> expressions;
  final List<String> warnings; // 예: "DeepL rate limit, 18 단어 번역 안 됨"
  final String analysisLanguage;

  const BookAnalysisResult({
    required this.words,
    required this.grammar,
    required this.sentences,
    this.expressions = const <ExtractedExpression>[],
    required this.warnings,
    this.analysisLanguage = 'de',
  });

  bool get hasMeaningfulResult =>
      words.isNotEmpty ||
      grammar.isNotEmpty ||
      sentences.isNotEmpty ||
      expressions.isNotEmpty;

  /// Only results whose server contract and content passed every safety gate
  /// may reach TTS, the bookshelf, or a custom pack.
  bool get isSaveable =>
      hasMeaningfulResult && !warnings.any(blockingWarnings.contains);

  factory BookAnalysisResult.empty() => const BookAnalysisResult(
    words: [],
    grammar: [],
    sentences: [],
    expressions: [],
    warnings: ['analysis_unavailable'],
    analysisLanguage: 'de',
  );
}
