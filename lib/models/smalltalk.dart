/// Small-talk corpus models (assets/data/smalltalk.json).
class SmalltalkCategory {
  final String id;
  final String emoji;
  final Map<String, String> label; // ko / de / en

  const SmalltalkCategory({
    required this.id,
    required this.emoji,
    required this.label,
  });

  factory SmalltalkCategory.fromJson(Map<String, dynamic> j) =>
      SmalltalkCategory(
        id: j['id'] as String? ?? '',
        emoji: j['emoji'] as String? ?? '💬',
        label: ((j['label'] as Map?) ?? const {})
            .map((k, v) => MapEntry(k.toString(), v.toString())),
      );

  String labelFor(String lang) =>
      label[lang] ?? label['de'] ?? label['en'] ?? id;
}

class SmalltalkPhrase {
  final String category;
  final String level; // a1 / a2 / b1 / b2
  final String kind; // opener / question / reaction
  final String ko;
  final String de;
  final String en;

  /// Beispielantwort für die Catch-ball-Übung (Frage → Antwort). Nur bei
  /// Fragen gesetzt; sonst null.
  final SmalltalkReply? reply;

  const SmalltalkPhrase({
    required this.category,
    required this.level,
    required this.kind,
    required this.ko,
    required this.de,
    required this.en,
    this.reply,
  });

  factory SmalltalkPhrase.fromJson(Map<String, dynamic> j) => SmalltalkPhrase(
        category: j['category'] as String? ?? '',
        level: j['level'] as String? ?? 'a1',
        kind: j['kind'] as String? ?? 'opener',
        ko: j['ko'] as String? ?? '',
        de: j['de'] as String? ?? '',
        en: j['en'] as String? ?? '',
        reply: j['reply'] is Map<String, dynamic>
            ? SmalltalkReply.fromJson(j['reply'] as Map<String, dynamic>)
            : null,
      );

  /// Übersetzung je nach UI-Sprache ('de' → Deutsch, sonst Englisch).
  String translation(String lang) => lang == 'de' ? de : en;
}

/// Beispielantwort für die Catch-ball-Übung (Frage → Antwort).
class SmalltalkReply {
  final String ko;
  final String de;
  final String en;
  const SmalltalkReply({required this.ko, required this.de, required this.en});

  factory SmalltalkReply.fromJson(Map<String, dynamic> j) => SmalltalkReply(
        ko: j['ko'] as String? ?? '',
        de: j['de'] as String? ?? '',
        en: j['en'] as String? ?? '',
      );

  String translation(String lang) => lang == 'de' ? de : en;
}
