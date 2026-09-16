import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'package:csv/csv.dart';

import '../models/vocab.dart';
import '../models/grammar.dart';
import '../models/media_phrase.dart';
import '../models/usage_note.dart';

class DataLoader {
  static final _vocabs = _BundledContentCache<Vocab>(
    asset: 'assets/data/korean_vocab.csv',
    failureMessage: 'Vokabeln konnten nicht geladen werden.',
    parse: (raw) => _parseCsv(
      raw,
    ).skip(1).where((row) => row.length >= 8).map(Vocab.fromRow).toList(),
  );
  static final _grammars = _BundledContentCache<Grammar>(
    asset: 'assets/data/grammar.csv',
    failureMessage: 'Grammatik konnte nicht geladen werden.',
    parse: (raw) => _parseCsv(
      raw,
    ).skip(1).where((row) => row.length >= 7).map(Grammar.fromRow).toList(),
  );
  static final _mediaPhrases = _BundledContentCache<MediaPhrase>(
    asset: 'assets/data/media_phrases.json',
    failureMessage: 'Medieninhalte konnten nicht geladen werden.',
    parse: (raw) {
      final data = json.decode(raw) as Map<String, dynamic>;
      return (data['phrases'] as List<dynamic>)
          .map((entry) => MediaPhrase.fromJson(entry as Map<String, dynamic>))
          .toList();
    },
  );
  // C9-T0: B1+ 단어 심화 노트. 파일이 없거나 비어 있어도(초기 배포 전/오프라인)
  // 빈 리스트로 안전하게 떨어진다 — `_BundledContentCache._read`의 공용
  // try/catch가 다른 소스와 동일하게 처리한다.
  static final _usageNotes = _BundledContentCache<UsageNote>(
    asset: 'assets/data/usage_notes.json',
    failureMessage: 'Verwendungsnotizen konnten nicht geladen werden.',
    parse: (raw) {
      final data = json.decode(raw) as Map<String, dynamic>;
      return (data['notes'] as List<dynamic>? ?? const [])
          .whereType<Map>()
          .map((entry) => UsageNote.fromJson(entry.cast<String, dynamic>()))
          .toList();
    },
  );
  static String? lastError;

  static String? get vocabError => _vocabs.error;
  static String? get grammarError => _grammars.error;
  static String? get mediaPhrasesError => _mediaPhrases.error;
  static String? get usageNotesError => _usageNotes.error;

  static Future<List<Vocab>> loadVocab() => _vocabs.load();

  /// B1+ 심화 노트 전체 목록(캐시됨). 자산이 없거나 파싱에 실패하면 빈 목록.
  static Future<List<UsageNote>> loadUsageNotes() => _usageNotes.load();

  /// 카드 뒷면이 바로 조회할 수 있도록 id 로 인덱싱한 편의 헬퍼.
  static Future<Map<String, UsageNote>> loadUsageNotesById() async {
    final notes = await loadUsageNotes();
    return {for (final note in notes) note.id: note};
  }

  /// Invalidates only the usage-notes asset cache for an explicit retry.
  static void resetUsageNotes() => _usageNotes.reset();

  /// Whether [value] is the result owned by the current vocabulary generation.
  ///
  /// This is read-only correlation for a higher-level cache. It prevents an
  /// older load from borrowing the success/error state of a newer retry.
  static bool isCurrentVocabResult(List<Vocab> value) =>
      _vocabs.isCurrentResult(value);

  static Future<List<Grammar>> loadGrammar() => _grammars.load();

  /// Cache löschen — z.B. nach App-Reset.
  static void reset() {
    _vocabs.reset();
    _grammars.reset();
    _mediaPhrases.reset();
    _usageNotes.reset();
    lastError = null;
  }

  /// Invalidates only the vocabulary asset cache for an explicit retry.
  ///
  /// A failed load is cached as an empty list. Keep grammar and media caches
  /// intact while allowing a visible retry to perform a real second read.
  static void resetVocab() {
    final vocabError = _vocabs.error;
    _vocabs.reset();
    if (lastError == vocabError) {
      lastError = null;
    }
  }

  /// K-Pop / K-Drama / 힙합 영감 구절 로더.
  static Future<List<MediaPhrase>> loadMediaPhrases() => _mediaPhrases.load();

  /// Invalidates only the media-phrase asset cache for an explicit retry.
  ///
  /// Failed loads are cached as an empty list. The asset bundle also caches
  /// its decoded string, so both layers must be evicted before a visible retry
  /// can perform a real second read.
  static void resetMediaPhrases() {
    final mediaError = _mediaPhrases.error;
    _mediaPhrases.reset();
    if (lastError == mediaError) {
      lastError = null;
    }
  }

  /// Invalidates only the grammar asset cache for an explicit retry.
  ///
  /// A failed grammar load is cached as an empty list so ordinary callers do
  /// not repeatedly parse a broken asset. A learner who taps the visible
  /// retry action, however, must get a real second read instead of the same
  /// cached failure state.
  static void resetGrammar() {
    _grammars.reset();
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

/// Shares decoding as well as the asset read between concurrent consumers.
/// A reset starts a new generation: older callers can finish, but cannot
/// publish stale data/errors or clear a newer in-flight request.
class _BundledContentCache<T> {
  _BundledContentCache({
    required this.asset,
    required this.failureMessage,
    required this.parse,
  });

  final String asset;
  final String failureMessage;
  final List<T> Function(String) parse;
  List<T>? _value;
  Future<List<T>>? _pending;
  int _generation = 0;
  String? error;

  Future<List<T>> load() {
    final cached = _value;
    if (cached != null) {
      return Future.value(cached);
    }
    return _pending ??= _read(_generation);
  }

  bool isCurrentResult(List<T> value) => identical(_value, value);

  Future<List<T>> _read(int generation) async {
    List<T> value;
    String? failure;
    try {
      final raw = await rootBundle.loadString(asset);
      value = parse(raw);
    } catch (error) {
      value = <T>[];
      failure = '$failureMessage\n$error';
    }
    if (generation == _generation) {
      _value = value;
      error = failure;
      DataLoader.lastError = failure;
      _pending = null;
    }
    return value;
  }

  void reset() {
    _generation++;
    _value = null;
    _pending = null;
    error = null;
    rootBundle.evict(asset);
  }
}
