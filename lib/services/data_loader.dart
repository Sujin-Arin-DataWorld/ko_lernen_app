import 'package:flutter/services.dart' show rootBundle;
import 'package:csv/csv.dart';

import '../models/vocab.dart';
import '../models/grammar.dart';

class DataLoader {
  static List<Vocab>?   _vocabs;
  static List<Grammar>? _grammars;
  static String? lastError;

  static Future<List<Vocab>> loadVocab() async {
    if (_vocabs != null) return _vocabs!;
    try {
      final raw = await rootBundle.loadString('assets/data/korean_vocab.csv');
      final rows = const CsvToListConverter(
        eol: '\n',
        shouldParseNumbers: false,
      ).convert(raw);
      _vocabs = rows.skip(1).where((r) => r.length >= 8).map(Vocab.fromRow).toList();
      lastError = null;
      return _vocabs!;
    } catch (e) {
      lastError = 'Vokabeln konnten nicht geladen werden.\n$e';
      _vocabs = [];
      return _vocabs!;
    }
  }

  static Future<List<Grammar>> loadGrammar() async {
    if (_grammars != null) return _grammars!;
    try {
      final raw = await rootBundle.loadString('assets/data/grammar.csv');
      final rows = const CsvToListConverter(
        eol: '\n',
        shouldParseNumbers: false,
      ).convert(raw);
      _grammars = rows.skip(1).where((r) => r.length >= 7).map(Grammar.fromRow).toList();
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
    lastError = null;
  }
}
