import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'package:csv/csv.dart';

import '../models/vocab.dart';
import '../models/grammar.dart';
import '../models/media_phrase.dart';

class DataLoader {
  static const _vocabAsset = 'assets/data/korean_vocab.csv';
  static const _mediaPhrasesAsset = 'assets/data/media_phrases.json';

  static List<Vocab>? _vocabs;
  static List<Grammar>? _grammars;
  static List<MediaPhrase>? _mediaPhrases;
  static String? _vocabError;
  static String? _mediaPhrasesError;
  static String? lastError;

  static String? get vocabError => _vocabError;
  static String? get mediaPhrasesError => _mediaPhrasesError;

  static Future<List<Vocab>> loadVocab() async {
    if (_vocabs != null) {
      return _vocabs!;
    }
    try {
      final raw = await rootBundle.loadString(_vocabAsset);
      final rows = _parseCsv(raw);
      _vocabs = rows
          .skip(1)
          .where((r) => r.length >= 8)
          .map(Vocab.fromRow)
          .toList();
      _vocabError = null;
      lastError = null;
      return _vocabs!;
    } catch (e) {
      _vocabError = 'Vokabeln konnten nicht geladen werden.\n$e';
      lastError = _vocabError;
      _vocabs = [];
      return _vocabs!;
    }
  }

  static Future<List<Grammar>> loadGrammar() async {
    if (_grammars != null) {
      return _grammars!;
    }
    try {
      final raw = await rootBundle.loadString('assets/data/grammar.csv');
      final rows = _parseCsv(raw);
      _grammars = rows
          .skip(1)
          .where((r) => r.length >= 7)
          .map(Grammar.fromRow)
          .toList();
      lastError = null;
      return _grammars!;
    } catch (e) {
      lastError = 'Grammatik konnte nicht geladen werden.\n$e';
      _grammars = [];
      return _grammars!;
    }
  }

  /// Cache löschen — z.B. nach App-Reset.
  static void reset() {
    _vocabs = null;
    _grammars = null;
    _mediaPhrases = null;
    _vocabError = null;
    _mediaPhrasesError = null;
    lastError = null;
  }

  /// Invalidates only the vocabulary asset cache for an explicit retry.
  ///
  /// A failed load is cached as an empty list. Keep grammar and media caches
  /// intact while allowing a visible retry to perform a real second read.
  static void resetVocab() {
    final vocabError = _vocabError;
    _vocabs = null;
    _vocabError = null;
    if (lastError == vocabError) {
      lastError = null;
    }
    rootBundle.evict(_vocabAsset);
  }

  /// K-Pop / K-Drama / 힙합 영감 구절 로더.
  static Future<List<MediaPhrase>> loadMediaPhrases() async {
    if (_mediaPhrases != null) return _mediaPhrases!;
    try {
      final raw = await rootBundle.loadString(_mediaPhrasesAsset);
      final data = json.decode(raw) as Map<String, dynamic>;
      final list = data['phrases'] as List<dynamic>;
      _mediaPhrases = list
          .map((e) => MediaPhrase.fromJson(e as Map<String, dynamic>))
          .toList();
      _mediaPhrasesError = null;
      lastError = null;
      return _mediaPhrases!;
    } catch (e) {
      _mediaPhrasesError = 'Medieninhalte konnten nicht geladen werden.\n$e';
      lastError = _mediaPhrasesError;
      _mediaPhrases = [];
      return _mediaPhrases!;
    }
  }

  /// Invalidates only the media-phrase asset cache for an explicit retry.
  ///
  /// Failed loads are cached as an empty list. The asset bundle also caches
  /// its decoded string, so both layers must be evicted before a visible retry
  /// can perform a real second read.
  static void resetMediaPhrases() {
    final mediaError = _mediaPhrasesError;
    _mediaPhrases = null;
    _mediaPhrasesError = null;
    if (lastError == mediaError) {
      lastError = null;
    }
    rootBundle.evict(_mediaPhrasesAsset);
  }

  /// Invalidates only the grammar asset cache for an explicit retry.
  ///
  /// A failed grammar load is cached as an empty list so ordinary callers do
  /// not repeatedly parse a broken asset. A learner who taps the visible
  /// retry action, however, must get a real second read instead of the same
  /// cached failure state.
  static void resetGrammar() {
    _grammars = null;
    lastError = null;
  }

  static List<List<dynamic>> _parseCsv(String raw) {
    final normalized = raw.replaceAll('\r\n', '\n').replaceAll('\r', '\n');
    return const CsvToListConverter(
      eol: '\n',
      shouldParseNumbers: false,
    ).convert(normalized);
  }
}
