import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

/// Ein Satzbau-Item: ein echter Beispielsatz + Distraktor-Kacheln.
/// Quelle: `assets/data/satz_sentences.json` (build_satzbauen.py, aus
/// muttersprachlich geprüften Beispielsätzen — keine neue Übersetzung).
class SatzSentence {
  final String level;
  final String targetKo;
  final String promptDe;
  final String promptEn;
  final List<String> distractors;

  /// Headword, zu dem der Beispielsatz gehört → echtes SRS-Futter
  /// (nicht der ganze Satz → keine Geisterkarten).
  final String vocabKo;

  const SatzSentence({
    required this.level,
    required this.targetKo,
    required this.promptDe,
    required this.promptEn,
    required this.distractors,
    this.vocabKo = '',
  });

  factory SatzSentence.fromJson(Map<String, dynamic> j) => SatzSentence(
    level: (j['level'] as String? ?? '').toLowerCase(),
    targetKo: j['targetKo'] as String? ?? '',
    promptDe: j['promptDe'] as String? ?? '',
    promptEn: j['promptEn'] as String? ?? '',
    distractors:
        (j['distractors'] as List?)?.map((e) => e.toString()).toList() ??
        const [],
    vocabKo: j['vocabKo'] as String? ?? '',
  );

  /// Datenformat für [SatzBauenQuest]. audioKo = der Zielsatz (TTS).
  Map<String, dynamic> toQuestData() => {
    'targetKo': targetKo,
    'promptDe': promptDe,
    'promptEn': promptEn,
    'audioKo': targetKo,
    'distractors': distractors,
  };
}

class SatzLoader {
  SatzLoader._();

  static List<SatzSentence>? _cache;

  static Future<List<SatzSentence>> load() async {
    if (_cache != null) {
      return _cache!;
    }
    final raw = await rootBundle.loadString('assets/data/satz_sentences.json');
    final data = jsonDecode(raw) as Map<String, dynamic>;
    final items = (data['items'] as List)
        .map((e) => SatzSentence.fromJson(e as Map<String, dynamic>))
        .toList();
    _cache = items;
    return items;
  }

  static List<SatzSentence> filter(List<SatzSentence> all, String? level) {
    if (level == null || level.isEmpty) {
      return all;
    }
    return all.where((c) => c.level == level.toLowerCase()).toList();
  }
}
