import 'dart:convert';
import 'dart:math';

import 'package:flutter/services.dart' show rootBundle;

import '../models/content_id.dart';

/// Ein Lückentext-Item (Cloze): ein echter Beispielsatz mit einer Lücke.
/// Quelle: `assets/data/cloze.json` (von tools/content_factory/build_cloze.py
/// aus muttersprachlich geprüften Sätzen erzeugt — keine neue Übersetzung).
class ClozeItem {
  /// Immutable source identity from `assets/data/cloze.json`.
  final String _sourceId;
  final String level; // a1 / a2 / b1 / b2
  final String sentenceKo; // mit ＿＿＿ als Lücke
  final String answer; // das fehlende Wort
  final String fullKo; // vollständiger Satz (für TTS)
  final String de;
  final String en;
  final List<String> distractors;
  final String topic;

  const ClozeItem({
    String id = '',
    required this.level,
    required this.sentenceKo,
    required this.answer,
    required this.fullKo,
    required this.de,
    required this.en,
    required this.distractors,
    this.topic = '',
  }) : _sourceId = id;

  /// The shipped corpus uses the raw `id`. The hash is exclusively a legacy
  /// compatibility fallback for fixtures that predate explicit IDs.
  String get id => hasExplicitId
      ? _sourceId.trim()
      : stableContentId('cloze_legacy', [
          level,
          sentenceKo,
          answer,
          fullKo,
          topic,
        ]);

  bool get hasExplicitId => _sourceId.trim().isNotEmpty;

  factory ClozeItem.fromJson(Map<String, dynamic> j) => ClozeItem(
    id: j['id']?.toString() ?? '',
    level: (j['level'] as String? ?? '').toLowerCase(),
    sentenceKo: j['sentenceKo'] as String? ?? '',
    answer: j['answer'] as String? ?? '',
    fullKo: j['fullKo'] as String? ?? '',
    de: j['de'] as String? ?? '',
    en: j['en'] as String? ?? '',
    distractors:
        (j['distractors'] as List?)?.map((e) => e.toString()).toList() ??
        const [],
    topic: j['topic'] as String? ?? '',
  );

  /// Bedeutung in der UI-Sprache (Fallback Deutsch).
  String meaning(String lang) => lang == 'en' && en.isNotEmpty ? en : de;

  /// Antwort + Distraktoren, gemischt (deterministisch über [seed]).
  List<String> options(int seed) {
    final o = <String>[answer, ...distractors];
    o.shuffle(Random(seed));
    return o;
  }
}

class ClozeLoader {
  ClozeLoader._();

  static List<ClozeItem>? _cache;

  static Future<List<ClozeItem>> load() async {
    if (_cache != null) {
      return _cache!;
    }
    final raw = await rootBundle.loadString('assets/data/cloze.json');
    final data = jsonDecode(raw) as Map<String, dynamic>;
    final items = (data['items'] as List)
        .map((e) => ClozeItem.fromJson(e as Map<String, dynamic>))
        .toList();
    _cache = items;
    return items;
  }

  /// Items eines Levels (oder alle, wenn [level] null/leer). Gemischt.
  static List<ClozeItem> filter(List<ClozeItem> all, String? level) {
    if (level == null || level.isEmpty) {
      return all;
    }
    return all.where((c) => c.level == level.toLowerCase()).toList();
  }
}
