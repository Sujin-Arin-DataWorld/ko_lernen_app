import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;
import 'package:http/http.dart' as http;

import '../models/book_page.dart';

/// Phase 5 (stately-rising-jongga) — Cloud Function 클라이언트 + 로컬 fallback.
///
/// **흐름**:
///   1. POST → `BookAnalysisService.endpoint` (Cloud Function, Jin 배포)
///   2. 5초 timeout / 5xx 응답 시 → **로컬 stub** 으로 graceful degrade
///      (grammar pattern 만 작동, 번역은 placeholder)
///
/// **Endpoint 미설정**: 빈 문자열이면 즉시 로컬 stub.
/// Production: `BookAnalysisService.setEndpoint("https://us-central1-…")` 호출.
class BookAnalysisService {
  static String _endpoint = '';
  static const Duration _timeout = Duration(seconds: 12);

  /// Production endpoint. RemoteConfig 또는 Settings 화면에서 호출.
  static void setEndpoint(String url) {
    _endpoint = url.trim();
  }

  static String get endpoint => _endpoint;

  /// Hauptmethode — analysiert OCR-Text. Liefert immer ein Ergebnis,
  /// auch wenn die Cloud unerreichbar ist (degraded mode).
  static Future<BookAnalysisResult> analyze({
    required String text,
    String targetLang = 'de',
  }) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) {
      return BookAnalysisResult.empty();
    }

    // 1. Cloud Function — wenn konfiguriert
    if (_endpoint.isNotEmpty) {
      try {
        final res = await http
            .post(
              Uri.parse(_endpoint),
              headers: {'Content-Type': 'application/json'},
              body: jsonEncode({
                'text': trimmed,
                'lang': targetLang,
              }),
            )
            .timeout(_timeout);
        if (res.statusCode == 200) {
          final body = jsonDecode(res.body) as Map<String, dynamic>;
          return _parseCloudResponse(body);
        }
      } catch (_) {
        // fall through to local stub
      }
    }

    // 2. Lokaler Stub — Grammar-Patterns matchen, Wörter mit Placeholders.
    return _localStub(trimmed);
  }

  /// "나만의 단어장" 자동 채우기 — 단어 하나의 번역/뜻풀이를 가져온다 (VoCat 식).
  /// Cloud Function 이 배포돼 있어야 동작. 오프라인이거나 결과가 비면 null →
  /// UI 가 "직접 입력" 안내. 반환된 ExtractedWord 에는 번역(DE)·국어 뜻풀이·품사 포함.
  static Future<ExtractedWord?> autoFill(
    String korean, {
    String targetLang = 'de',
  }) async {
    final word = korean.trim();
    if (word.isEmpty) {
      return null;
    }
    final result = await analyze(text: word, targetLang: targetLang);
    if (result.words.isEmpty) {
      return null;
    }
    final match = result.words.firstWhere(
      (w) => w.korean == word,
      orElse: () => result.words.first,
    );
    if (match.translationDe.trim().isEmpty &&
        match.definitionKo.trim().isEmpty) {
      return null; // 오프라인/번역 없음 → 직접 입력 유도
    }
    return match;
  }

  // ── Cloud parsing ──────────────────────────────────────────────────

  static BookAnalysisResult _parseCloudResponse(Map<String, dynamic> body) {
    final warnings = <String>[];

    final wordsJson = (body['words'] as List?) ?? const [];
    final words = wordsJson
        .map((e) {
          final m = (e as Map).cast<String, dynamic>();
          return ExtractedWord(
            korean: m['korean'] as String? ?? '',
            romanization: m['romanization'] as String? ?? '',
            posDe: m['pos'] as String? ?? '',
            translationDe: (m['translation'] as String?) ?? '',
            translationEn: (m['translationEn'] as String?) ?? '',
            exampleKorean: m['example'] as String? ?? '',
            exampleDe: m['exampleTranslation'] as String? ?? '',
            definitionKo: m['definitionKo'] as String? ?? '',
            savedToPackId: null,
          );
        })
        .toList();

    final grammarJson = (body['grammar'] as List?) ?? const [];
    final grammar = grammarJson
        .map((e) {
          final m = (e as Map).cast<String, dynamic>();
          return GrammarHit(
            patternId: m['id'] as String? ?? '',
            nameDe: m['nameDe'] as String? ?? '',
            matchedText: m['matched'] as String? ?? '',
            level: m['level'] as String? ?? '',
            explanationDe: m['explanationDe'] as String? ?? '',
          );
        })
        .toList();

    final sentJson = (body['sentences'] as List?) ?? const [];
    final sentences = sentJson
        .map((e) {
          final m = (e as Map).cast<String, dynamic>();
          return TranslatedSentence(
            korean: m['korean'] as String? ?? '',
            translationDe: m['translation'] as String? ?? '',
          );
        })
        .toList();

    if ((body['warnings'] as List?)?.isNotEmpty ?? false) {
      warnings.addAll(
        (body['warnings'] as List).map((e) => e.toString()),
      );
    }

    return BookAnalysisResult(
      words: words,
      grammar: grammar,
      sentences: sentences,
      warnings: warnings,
    );
  }

  // ── Lokaler Fallback (Cloud nicht erreichbar) ────────────────────────

  static List<Map<String, dynamic>>? _grammarPatternsCache;

  static Future<List<Map<String, dynamic>>> _loadGrammarPatterns() async {
    if (_grammarPatternsCache != null) return _grammarPatternsCache!;
    try {
      final raw =
          await rootBundle.loadString('assets/data/grammar_patterns.json');
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

  static Future<BookAnalysisResult> _localStub(String text) async {
    final patterns = await _loadGrammarPatterns();
    final grammar = <GrammarHit>[];
    final usedPatternIds = <String>{};
    for (final p in patterns) {
      final id = p['id'] as String? ?? '';
      if (usedPatternIds.contains(id)) continue;
      final regex = p['regex'] as String? ?? '';
      if (regex.isEmpty) continue;
      try {
        final re = RegExp(regex);
        final m = re.firstMatch(text);
        if (m != null) {
          usedPatternIds.add(id);
          grammar.add(GrammarHit(
            patternId: id,
            nameDe: p['name_de'] as String? ?? id,
            matchedText: m.group(0) ?? '',
            level: p['level'] as String? ?? 'A2',
            explanationDe: p['explanation_de'] as String? ?? '',
          ));
        }
      } catch (_) {
        // bad regex — skip
      }
    }

    // Sätze auf '.', '!', '?' splitten (sehr einfach — Cloud Function nutzt
    // KSS für korrekte koreanische Satzgrenzen).
    final rawSentences = text
        .split(RegExp(r'(?<=[.!?。！？])\s+|\n+'))
        .where((s) => s.trim().isNotEmpty)
        .map((s) => TranslatedSentence(
              korean: s.trim(),
              translationDe: '', // 번역 미실행
            ))
        .toList();

    return BookAnalysisResult(
      words: const [],
      grammar: grammar,
      sentences: rawSentences,
      warnings: const ['offline_stub'],
    );
  }
}
