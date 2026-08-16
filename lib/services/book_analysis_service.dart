import 'dart:convert';

import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:http/http.dart' as http;

import '../models/book_page.dart';
import 'book_analysis_text.dart';
import 'book_ocr_document.dart';

/// Phase 5 (stately-rising-jongga) — Cloud Function 클라이언트 + 로컬 fallback.
///
/// **흐름**:
///   1. POST → a fixed trusted Cloud Function URL with verified credentials
///   2. 5초 timeout / 5xx 응답 시 → **로컬 stub** 으로 graceful degrade
///      (grammar pattern 만 작동, 번역은 placeholder)
///
/// The production request target is intentionally fixed. This avoids sending
/// user text or Firebase credentials to a value that can be edited locally.
class BookAnalysisCredentials {
  const BookAnalysisCredentials({
    required this.idToken,
    required this.appCheckToken,
  });

  final String idToken;
  final String appCheckToken;
}

typedef BookAnalysisCredentialsProvider =
    Future<BookAnalysisCredentials?> Function();

class BookAnalysisService {
  static const Duration _timeout = Duration(seconds: 12);
  static final Uri trustedEndpoint = Uri.parse(
    'https://europe-west3-ko-lernen-app.cloudfunctions.net/'
    'analyze_korean_text',
  );

  /// Hauptmethode — analysiert OCR-Text. Liefert immer ein Ergebnis,
  /// auch wenn die Cloud unerreichbar ist (degraded mode).
  static Future<BookAnalysisResult> analyze({
    required String text,
    String? targetLang = 'de',
    http.Client? client,
    BookAnalysisCredentialsProvider? credentialsProvider,
    BookOcrDocument? document,
  }) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) {
      return BookAnalysisResult.empty();
    }
    final language = normalizeTargetLanguage(targetLang);
    final prepared = BookAnalysisTextPreprocessor.prepare(trimmed);
    if (!prepared.hasKoreanText) {
      return BookAnalysisResult(
        words: const [],
        grammar: const [],
        sentences: const [],
        warnings: prepared.warnings,
        analysisLanguage: language,
      );
    }

    final credentials = await (credentialsProvider ?? firebaseCredentials)();
    if (credentials == null) {
      return _localStub(
        prepared.text,
        language,
        document: document,
        warnings: prepared.warnings,
        warning: 'remote_credentials_unavailable',
      );
    }

    try {
      final response = await _requestAnalysis(
        text: prepared.text,
        language: language,
        credentials: credentials,
        client: client,
        document: document,
      );
      if (response.statusCode == 200) {
        Object? decoded;
        try {
          decoded = jsonDecode(response.body);
        } on FormatException {
          return _blockedResult(
            language,
            warnings: {...prepared.warnings, 'invalid_response_schema'},
          );
        }
        if (decoded is! Map || decoded.keys.any((key) => key is! String)) {
          return _blockedResult(
            language,
            warnings: {...prepared.warnings, 'invalid_response_schema'},
          );
        }
        return _parseCloudResponse(
          decoded.cast<String, dynamic>(),
          language: language,
          clientWarnings: prepared.warnings,
        );
      }
      if (response.statusCode == 429) {
        return _localStub(
          prepared.text,
          language,
          document: document,
          warnings: prepared.warnings,
          warning: 'server_rate_limited',
        );
      }
      if (response.statusCode == 401 || response.statusCode == 403) {
        return _localStub(
          prepared.text,
          language,
          document: document,
          warnings: prepared.warnings,
          warning: 'remote_credentials_unavailable',
        );
      }
      if (response.statusCode == 422) {
        return BookAnalysisResult(
          words: const [],
          grammar: const [],
          sentences: const [],
          warnings: {...prepared.warnings, 'no_korean_text'}.toList(),
          analysisLanguage: language,
        );
      }
    } catch (_) {
      // A remote failure must never expose backend details in the app.
    }

    // Local fallback — Grammar-Patterns matchen, Wörter mit Placeholders.
    return _localStub(
      prepared.text,
      language,
      document: document,
      warnings: prepared.warnings,
      warning: 'remote_analysis_failed',
    );
  }

  /// Shared credential source for protected learning endpoints.
  ///
  /// Keeping this here ensures book analysis and word validation use the same
  /// Firebase Auth plus App Check contract; neither endpoint receives a key
  /// from the installed app.
  static Future<BookAnalysisCredentials?> firebaseCredentials() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return null;
      final tokens = await Future.wait<String?>([
        user.getIdToken(),
        FirebaseAppCheck.instance.getToken(),
      ]);
      final idToken = tokens[0]?.trim() ?? '';
      final appCheckToken = tokens[1]?.trim() ?? '';
      if (idToken.isEmpty || appCheckToken.isEmpty) return null;
      return BookAnalysisCredentials(
        idToken: idToken,
        appCheckToken: appCheckToken,
      );
    } catch (_) {
      return null;
    }
  }

  static Future<http.Response> _requestAnalysis({
    required String text,
    required String language,
    required BookAnalysisCredentials credentials,
    http.Client? client,
    BookOcrDocument? document,
  }) async {
    final ownsClient = client == null;
    final effectiveClient = client ?? http.Client();
    try {
      final request = http.Request('POST', trustedEndpoint)
        ..followRedirects = false
        ..headers.addAll({
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${credentials.idToken}',
          'X-Firebase-AppCheck': credentials.appCheckToken,
        })
        ..body = jsonEncode(<String, dynamic>{
          'text': text,
          'lang': language,
          'analysisLanguage': language,
          if (document != null) ...<String, dynamic>{
            'schemaVersion': BookOcrDocument.schemaVersion,
            'units': document.toAnalysisRequestUnits(),
          },
        });
      final streamed = await effectiveClient.send(request).timeout(_timeout);
      return http.Response.fromStream(streamed);
    } finally {
      if (ownsClient) effectiveClient.close();
    }
  }

  static String normalizeTargetLanguage(String? value) {
    final normalized = value?.trim().toLowerCase().replaceAll('_', '-') ?? '';
    if (normalized == 'en' || normalized.startsWith('en-')) {
      return 'en';
    }
    if (normalized == 'de' || normalized.startsWith('de-')) {
      return 'de';
    }
    return 'de';
  }

  /// "나만의 단어장" 자동 채우기 — 단어 하나의 번역/뜻풀이를 가져온다 (VoCat 식).
  /// Cloud Function 이 배포돼 있어야 동작. 오프라인이거나 결과가 비면 null →
  /// UI 가 "직접 입력" 안내. 반환된 ExtractedWord 에는 번역(DE)·국어 뜻풀이·품사 포함.
  static Future<ExtractedWord?> autoFill(
    String korean, {
    String targetLang = 'de',
    http.Client? client,
    BookAnalysisCredentialsProvider? credentialsProvider,
  }) async {
    final word = korean.trim();
    if (word.isEmpty) {
      return null;
    }
    final result = await analyze(
      text: word,
      targetLang: targetLang,
      client: client,
      credentialsProvider: credentialsProvider,
    );
    if (!result.isSaveable || result.words.isEmpty) {
      return null;
    }
    final match = result.words.firstWhere(
      (w) => w.korean == word,
      orElse: () => result.words.first,
    );
    if (match.translationDe.trim().isEmpty &&
        match.translationEn.trim().isEmpty &&
        match.definitionKo.trim().isEmpty) {
      return null; // 오프라인/번역 없음 → 직접 입력 유도
    }
    return match;
  }

  // ── Cloud parsing ──────────────────────────────────────────────────

  static BookAnalysisResult _blockedResult(
    String language, {
    required Iterable<String> warnings,
  }) => BookAnalysisResult(
    words: const [],
    grammar: const [],
    sentences: const [],
    warnings: warnings.toSet().toList(growable: false),
    analysisLanguage: language,
  );

  static BookAnalysisResult _parseCloudResponse(
    Map<String, dynamic> body, {
    required String language,
    Iterable<String> clientWarnings = const [],
  }) {
    final warnings = <String>{...clientWarnings};
    var invalidResponse = false;

    const requiredListFields = {
      'words',
      'expressions',
      'grammar',
      'sentences',
      'warnings',
    };
    if (requiredListFields.any((field) => body[field] is! List) ||
        body['analysisLanguage'] is! String ||
        !const {'de', 'en'}.contains(body['analysisLanguage'])) {
      return _blockedResult(
        language,
        warnings: {...warnings, 'invalid_response_schema'},
      );
    }
    if (body['analysisLanguage'] != language) {
      return _blockedResult(
        language,
        warnings: {...warnings, 'wrong_analysis_language'},
      );
    }

    String clean(Object? value, int maxLength) {
      if (value == null) return '';
      if (value is! String) {
        invalidResponse = true;
        return '';
      }
      final sanitized = BookAnalysisTextPreprocessor.sanitizeUnexpectedScripts(
        value,
      );
      if (sanitized.removedCharacterCount > 0 ||
          sanitized.removedFormatControlCount > 0) {
        invalidResponse = true;
      }
      var text = sanitized.text.trim();
      if (text.length > maxLength) {
        text = text.substring(0, maxLength).trimRight();
        invalidResponse = true;
      }
      return text;
    }

    String cleanSourceUnitId(Object? value) {
      final sourceUnitId = clean(value, 80);
      if (sourceUnitId.isNotEmpty &&
          !RegExp(r'^unit:\d{1,4}$').hasMatch(sourceUnitId)) {
        invalidResponse = true;
        return '';
      }
      return sourceUnitId;
    }

    List<dynamic> list(Object? value, int maxItems) {
      if (value is! List) {
        invalidResponse = true;
        return const [];
      }
      if (value.length > maxItems) {
        invalidResponse = true;
      }
      return value.take(maxItems).toList(growable: false);
    }

    for (final warning in list(body['warnings'], 20)) {
      if (warning is String &&
          RegExp(r'^[a-z0-9_:-]{1,80}$').hasMatch(warning)) {
        warnings.add(warning);
      } else {
        invalidResponse = true;
      }
    }
    final translationUnavailable = warnings.contains('translation_unavailable');

    final words = <ExtractedWord>[];
    for (final entry in list(body['words'], 30)) {
      if (entry is! Map) {
        invalidResponse = true;
        continue;
      }
      final item = entry.cast<Object?, Object?>();
      final korean = clean(item['korean'], 40);
      if (!RegExp(r'^[\uAC00-\uD7A3]{1,20}$').hasMatch(korean)) {
        invalidResponse = true;
        continue;
      }
      final translation = clean(item['translation'], 240);
      if (!RegExp(r'[A-Za-z\u00C0-\u024F]').hasMatch(translation)) {
        if (!translationUnavailable) {
          invalidResponse = true;
        }
        continue;
      }
      final explicitEnglish = clean(item['translationEn'], 240);
      final example = clean(item['example'], 500);
      final sourceUnitId = cleanSourceUnitId(item['sourceUnitId']);
      words.add(
        ExtractedWord(
          korean: korean,
          romanization: clean(item['romanization'], 120),
          posDe: clean(item['pos'], 80),
          // translationDe remains the legacy primary-meaning slot used by
          // custom-pack games. translationLanguage records its real language.
          translationDe: translation,
          translationEn: language == 'en' ? translation : explicitEnglish,
          translationLanguage: language,
          exampleKorean:
              BookAnalysisTextPreprocessor.containsHangulSyllable(example)
              ? example
              : '',
          exampleDe: clean(item['exampleTranslation'], 500),
          definitionKo: clean(item['definitionKo'], 500),
          sourceUnitId: sourceUnitId,
          savedToPackId: null,
        ),
      );
    }

    final expressions = <ExtractedExpression>[];
    for (final entry in list(body['expressions'], 30)) {
      if (entry is! Map) {
        invalidResponse = true;
        continue;
      }
      final item = entry.cast<Object?, Object?>();
      final korean = clean(item['korean'], 160);
      final translation = clean(item['translation'], 240);
      final sourceUnitId = clean(item['sourceUnitId'], 80);
      if (!BookAnalysisTextPreprocessor.containsHangulSyllable(korean) ||
          !RegExp(r'^unit:\d{1,4}$').hasMatch(sourceUnitId)) {
        invalidResponse = true;
        continue;
      }
      if (!RegExp(r'[A-Za-z\u00C0-\u024F]').hasMatch(translation)) {
        if (!translationUnavailable) {
          invalidResponse = true;
        }
        continue;
      }
      expressions.add(
        ExtractedExpression(
          korean: korean,
          translationDe: translation,
          translationEn: language == 'en' ? translation : '',
          translationLanguage: language,
          sourceUnitId: sourceUnitId,
        ),
      );
    }

    final grammar = <GrammarHit>[];
    final seenGrammar = <String>{};
    for (final entry in list(body['grammar'], 40)) {
      if (entry is! Map) {
        invalidResponse = true;
        continue;
      }
      final item = entry.cast<Object?, Object?>();
      final id = clean(item['id'], 64);
      final matched = clean(item['matched'], 160);
      if (!RegExp(r'^[a-zA-Z0-9_-]{1,64}$').hasMatch(id) ||
          !BookAnalysisTextPreprocessor.containsHangulSyllable(matched) ||
          !seenGrammar.add(id)) {
        invalidResponse = true;
        continue;
      }
      final level = clean(item['level'], 8);
      final name = clean(item['nameDe'], 160);
      final explanation = clean(item['explanationDe'], 600);
      if (!RegExp(r'[A-Za-z\u00C0-\u024F]').hasMatch(name) ||
          !RegExp(r'[A-Za-z\u00C0-\u024F]').hasMatch(explanation)) {
        invalidResponse = true;
        continue;
      }
      if (!const {'A1', 'A2', 'B1', 'B2', 'C1', 'C2'}.contains(level)) {
        invalidResponse = true;
      }
      grammar.add(
        GrammarHit(
          patternId: id,
          nameDe: name,
          matchedText: matched,
          level: const {'A1', 'A2', 'B1', 'B2', 'C1', 'C2'}.contains(level)
              ? level
              : '',
          explanationDe: explanation,
          sourceUnitId: cleanSourceUnitId(item['sourceUnitId']),
        ),
      );
    }

    final sentences = <TranslatedSentence>[];
    for (final entry in list(body['sentences'], 20)) {
      if (entry is! Map) {
        invalidResponse = true;
        continue;
      }
      final item = entry.cast<Object?, Object?>();
      final korean = clean(item['korean'], 600);
      final translation = clean(item['translation'], 800);
      if (!BookAnalysisTextPreprocessor.containsHangulSyllable(korean)) {
        invalidResponse = true;
        continue;
      }
      if (!RegExp(r'[A-Za-z\u00C0-\u024F]').hasMatch(translation) &&
          !translationUnavailable) {
        invalidResponse = true;
        continue;
      }
      sentences.add(
        TranslatedSentence(
          korean: korean,
          translationDe: translation,
          translationLanguage: language,
          sourceUnitId: cleanSourceUnitId(item['sourceUnitId']),
        ),
      );
    }

    if (invalidResponse) {
      warnings.add('invalid_response_filtered');
    }
    if (words.isEmpty &&
        expressions.isEmpty &&
        grammar.isEmpty &&
        sentences.isEmpty) {
      warnings.add('empty_analysis_result');
    }

    return BookAnalysisResult(
      words: words,
      grammar: grammar,
      sentences: sentences,
      expressions: expressions,
      warnings: warnings.toList(growable: false),
      analysisLanguage: language,
    );
  }

  // ── Lokaler Fallback (Cloud nicht erreichbar) ────────────────────────

  static List<Map<String, dynamic>>? _grammarPatternsCache;

  static Future<List<Map<String, dynamic>>> _loadGrammarPatterns() async {
    if (_grammarPatternsCache != null) return _grammarPatternsCache!;
    try {
      final raw = await rootBundle.loadString(
        'assets/data/grammar_patterns.json',
      );
      final decoded = jsonDecode(raw);
      final list = (decoded is List)
          ? decoded.cast<Map<String, dynamic>>()
          : <Map<String, dynamic>>[];
      _grammarPatternsCache = list;
      return list;
    } catch (_) {
      _grammarPatternsCache = const [];
      return const [];
    }
  }

  static Future<BookAnalysisResult> _localStub(
    String text,
    String targetLang, {
    BookOcrDocument? document,
    Iterable<String> warnings = const [],
    String? warning,
  }) async {
    final patterns = await _loadGrammarPatterns();
    final grammar = <GrammarHit>[];
    final usedPatternIds = <String>{};
    final analysisSources = document == null
        ? <({String text, String sourceUnitId})>[(text: text, sourceUnitId: '')]
        : document.analysisUnits
              .map((unit) => (text: unit.korean, sourceUnitId: unit.id))
              .toList(growable: false);
    for (final source in analysisSources) {
      for (final p in patterns) {
        final id = p['id'] as String? ?? '';
        if (usedPatternIds.contains(id)) {
          continue;
        }
        if (p['detector'] != null && p['detector'] != 'regex') {
          continue;
        }
        final regex = p['regex'] as String? ?? '';
        if (regex.isEmpty) {
          continue;
        }
        try {
          final re = RegExp(regex);
          final m = re.firstMatch(source.text);
          if (m != null) {
            usedPatternIds.add(id);
            final isEnglish = targetLang == 'en';
            grammar.add(
              GrammarHit(
                patternId: id,
                nameDe: isEnglish
                    ? p['name_en'] as String? ?? 'Korean grammar ($id)'
                    : p['name_de'] as String? ?? id,
                matchedText: m.group(0) ?? '',
                level: p['level'] as String? ?? 'A2',
                explanationDe: isEnglish
                    ? p['explanation_en'] as String? ??
                          'This Korean grammar pattern was detected in the '
                              'selected text.'
                    : p['explanation_de'] as String? ?? '',
                sourceUnitId: source.sourceUnitId,
              ),
            );
          }
        } catch (_) {
          // bad regex — skip
        }
      }
    }

    // Sätze auf '.', '!', '?' splitten (sehr einfach — Cloud Function nutzt
    // KSS für korrekte koreanische Satzgrenzen).
    // ⚠️ 개행은 문장 경계가 아니다. OCR 은 **책·화면의 줄 폭**에 맞춰 줄을
    // 바꾸므로 `\n` 에서 자르면 문장이 한복판에서 끊긴다. 2026-08-12 실기기가
    // 그랬다 — "…CEFR에 입각하여 설계된 A1~C1 전체에", "프로그램을 인터넷
    // 강의와 오프라인 교육으로 제공하고 및 이민을 준비하는" 같은 조각이
    // 나열됐다(Jin). 문장부호로 끝나지 않는 줄은 다음 줄과 먼저 이어 붙이고,
    // 그다음에 문장부호로만 나눈다.
    List<TranslatedSentence> sentencesFor(
      String sourceText,
      String sourceUnitId,
    ) {
      final buffer = StringBuffer();
      for (final line in sourceText.split(RegExp(r'\r?\n'))) {
        final trimmed = line.trim();
        if (trimmed.isEmpty) {
          continue;
        }
        if (buffer.isNotEmpty) {
          final previous = buffer.toString();
          buffer.write(RegExp(r'[.!?。！？]$').hasMatch(previous) ? '\n' : ' ');
        }
        buffer.write(trimmed);
      }
      return buffer
          .toString()
          .split(RegExp(r'(?<=[.!?。！？])\s+'))
          .where((sentence) => sentence.trim().isNotEmpty)
          .map(
            (sentence) => TranslatedSentence(
              korean: sentence.trim(),
              translationDe: '',
              translationLanguage: targetLang,
              sourceUnitId: sourceUnitId,
            ),
          )
          .toList(growable: false);
    }

    final rawSentences = <TranslatedSentence>[];
    if (document != null) {
      for (final unit in document.analysisUnits) {
        if (unit.role == BookOcrUnitRole.sentence) {
          rawSentences.addAll(sentencesFor(unit.korean, unit.id));
        }
      }
    } else {
      rawSentences.addAll(sentencesFor(text, ''));
    }

    return BookAnalysisResult(
      words: const [],
      grammar: grammar,
      sentences: rawSentences,
      warnings: {
        'offline_stub',
        'offline_grammar_reduced',
        ...warnings,
        if (warning != null) warning,
      }.toList(growable: false),
      analysisLanguage: targetLang,
    );
  }
}
