/// Szenario-Modelle — wird aus `assets/data/scenarios.json` geladen.
///
/// Schema-Übersicht:
/// ```
/// Scenario
///   ├── id, emoji, level, register
///   ├── title  (ko/de/en)
///   ├── intro  (de/en — Hook in der Muttersprache)
///   ├── vocab[]      → VocabRef
///   ├── grammarIds[] → Strings, verweisen auf grammar.csv `pattern`
///   ├── dialog[]     → DialogLine
///   ├── quests[]     → QuestSpec
///   ├── culturalNote (optional)
///   └── xpReward
/// ```

/// CEFR-Stufe — auch Storage-Schlüssel via [code].
enum LearnerLevel {
  a1, a2, b1, b2;

  /// Lower-case Code für Persistenz: 'a1', 'a2', 'b1', 'b2'.
  String get code => name;

  /// Anzeige-Variante: 'A1', 'A2', 'B1', 'B2'.
  String get display => name.toUpperCase();

  /// 0..3 — für Vergleichsoperationen (Lock/Unlock).
  int get rank => index;

  static LearnerLevel? fromCode(String? c) {
    if (c == null || c.isEmpty) return null;
    final norm = c.toLowerCase();
    for (final lv in values) {
      if (lv.code == norm) return lv;
    }
    return null;
  }
}

/// Eine mehrsprachige Zeichenkette aus dem Scenario-JSON.
class LocalizedText {
  final String ko;
  final String de;
  final String en;

  const LocalizedText({required this.ko, required this.de, required this.en});

  /// Wählt die Variante anhand des Sprachcodes ('de'|'en'|fallback 'de').
  String pick(String langCode) {
    switch (langCode) {
      case 'en': return en.isNotEmpty ? en : de;
      case 'ko': return ko;
      default:   return de.isNotEmpty ? de : en;
    }
  }

  factory LocalizedText.fromJson(Map<String, dynamic> j) => LocalizedText(
    ko: (j['ko'] as String?) ?? '',
    de: (j['de'] as String?) ?? '',
    en: (j['en'] as String?) ?? '',
  );

  static LocalizedText? fromJsonOrNull(dynamic j) =>
      j is Map<String, dynamic> ? LocalizedText.fromJson(j) : null;
}

/// Referenz auf ein Vokabel-Element.
/// Wenn `korean` in `korean_vocab.csv` existiert, wird die CSV-Karte verlinkt.
/// `aliases` (z.B. 아아 → 아이스 아메리카노) und `variants` (z.B. 숏/톨/그란데/벤티)
/// werden als zusätzliche Lern-Tags angezeigt.
class VocabRef {
  final String korean;
  final List<String> aliases;
  final List<String> variants;
  final LocalizedText? note;

  const VocabRef({
    required this.korean,
    this.aliases = const [],
    this.variants = const [],
    this.note,
  });

  factory VocabRef.fromJson(Map<String, dynamic> j) => VocabRef(
    korean: (j['korean'] as String?) ?? '',
    aliases:  ((j['aliases']  as List?) ?? const []).cast<String>(),
    variants: ((j['variants'] as List?) ?? const []).cast<String>(),
    note: LocalizedText.fromJsonOrNull(j['note']),
  );
}

/// Eine Dialog-Zeile. `speaker` ist ein Kürzel: 'minsu', 'jieun', 'user', 'narrator'.
class DialogLine {
  final String speaker;
  final String ko;
  final String de;
  final String en;

  const DialogLine({
    required this.speaker,
    required this.ko,
    required this.de,
    required this.en,
  });

  factory DialogLine.fromJson(Map<String, dynamic> j) => DialogLine(
    speaker: (j['speaker'] as String?) ?? 'narrator',
    ko: (j['ko'] as String?) ?? '',
    de: (j['de'] as String?) ?? '',
    en: (j['en'] as String?) ?? '',
  );

  String pick(String langCode) {
    switch (langCode) {
      case 'en': return en.isNotEmpty ? en : de;
      case 'ko': return ko;
      default:   return de.isNotEmpty ? de : en;
    }
  }
}

/// Mini-game type für Quests innerhalb eines Szenarios.
enum QuestType {
  /// TTS-Hörverstehen → 4 Auswahlmöglichkeiten.
  hoerverstehen,
  /// Lückentext, ein Wort fehlt.
  luecken,
  /// DE/EN → KO Übersetzung (Multiple Choice).
  uebersetzen,
  /// Partikel-Spiel: 은/는, 이/가, 을/를, (으)로 ziehen.
  particlePop,
  /// Receiver-Konsonant (받침) wählen nach gehörtem Wort.
  batchimDrop,
  /// Hangul-Buchstabe nachzeichnen.
  schreiben;

  static QuestType fromCode(String c) {
    for (final t in values) {
      if (t.name == c) return t;
    }
    return QuestType.hoerverstehen;
  }
}

/// Eine konkrete Quest-Instanz. `data` ist typ-spezifisch und wird vom
/// jeweiligen Quest-Widget interpretiert (siehe lib/screens/quest_engines/).
class QuestSpec {
  final QuestType type;
  final Map<String, dynamic> data;

  const QuestSpec({required this.type, required this.data});

  factory QuestSpec.fromJson(Map<String, dynamic> j) => QuestSpec(
    type: QuestType.fromCode((j['type'] as String?) ?? 'hoerverstehen'),
    data: (j['data'] as Map<String, dynamic>?) ?? const {},
  );
}

class CulturalNote {
  final LocalizedText title;
  final LocalizedText body;

  const CulturalNote({required this.title, required this.body});

  factory CulturalNote.fromJson(Map<String, dynamic> j) => CulturalNote(
    title: LocalizedText.fromJson(j['title'] as Map<String, dynamic>),
    body:  LocalizedText.fromJson(j['body']  as Map<String, dynamic>),
  );
}

/// Inline Grammar-Block für Szenarien. Wenn ein Szenario einen spezifischen
/// Pattern lehrt, der nicht in `grammar.csv` ist, wird er hier eingebettet.
class GrammarBlock {
  final LocalizedText title;        // z.B. "N(으)로 주세요"
  final LocalizedText explanation;  // 2–4 Sätze Regel + Beispiele

  const GrammarBlock({required this.title, required this.explanation});

  factory GrammarBlock.fromJson(Map<String, dynamic> j) => GrammarBlock(
    title:       LocalizedText.fromJson(j['title']       as Map<String, dynamic>),
    explanation: LocalizedText.fromJson(j['explanation'] as Map<String, dynamic>),
  );
}

/// Register / Formalitätsstufe — bestimmt Ton der Dialoge.
enum Register {
  polite,     // ~요체 — Standard höflich (Café, Geschäft)
  casual,     // 반말 — Freunde, Familie
  business,   // 합쇼체 — Meeting, Vorstellung
  intimate;   // 친밀한 반말 — Partner, enge Freunde

  static Register fromCode(String c) {
    for (final r in values) {
      if (r.name == c) return r;
    }
    return Register.polite;
  }
}

class Scenario {
  final String id;
  final LearnerLevel level;
  final String emoji;
  final Register register;
  final LocalizedText title;
  final LocalizedText intro;
  final List<VocabRef> vocab;
  final List<String> grammarIds;
  final GrammarBlock? grammarBlock;  // inline grammar if not in grammar.csv
  final List<DialogLine> dialog;
  final List<QuestSpec> quests;
  final CulturalNote? culturalNote;
  final int xpReward;
  final String? sidekick;        // 'minsu' | 'jieun' | null
  final String? preferredVoice;  // hint für TTS voice picker (Phase 5b)

  const Scenario({
    required this.id,
    required this.level,
    required this.emoji,
    required this.register,
    required this.title,
    required this.intro,
    required this.vocab,
    required this.grammarIds,
    required this.dialog,
    required this.quests,
    this.grammarBlock,
    this.culturalNote,
    this.xpReward = 100,
    this.sidekick,
    this.preferredVoice,
  });

  factory Scenario.fromJson(Map<String, dynamic> j) => Scenario(
    id:    (j['id'] as String?) ?? '',
    level: LearnerLevel.fromCode(j['level'] as String?) ?? LearnerLevel.a1,
    emoji: (j['emoji'] as String?) ?? '📖',
    register: Register.fromCode((j['register'] as String?) ?? 'polite'),
    title: LocalizedText.fromJson(j['title'] as Map<String, dynamic>),
    intro: LocalizedText.fromJson(j['intro'] as Map<String, dynamic>),
    vocab: ((j['vocab'] as List?) ?? const [])
        .map((e) => VocabRef.fromJson(e as Map<String, dynamic>))
        .toList(),
    grammarIds: ((j['grammarIds'] as List?) ?? const []).cast<String>(),
    grammarBlock: j['grammarBlock'] is Map<String, dynamic>
        ? GrammarBlock.fromJson(j['grammarBlock'] as Map<String, dynamic>)
        : null,
    dialog: ((j['dialog'] as List?) ?? const [])
        .map((e) => DialogLine.fromJson(e as Map<String, dynamic>))
        .toList(),
    quests: ((j['quests'] as List?) ?? const [])
        .map((e) => QuestSpec.fromJson(e as Map<String, dynamic>))
        .toList(),
    culturalNote: j['culturalNote'] is Map<String, dynamic>
        ? CulturalNote.fromJson(j['culturalNote'] as Map<String, dynamic>)
        : null,
    xpReward: (j['xpReward'] as num?)?.toInt() ?? 100,
    sidekick: j['sidekick'] as String?,
    preferredVoice: j['preferredVoice'] as String?,
  );
}
