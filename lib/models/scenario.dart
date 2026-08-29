/// Szenario-Modelle — wird aus `assets/data/scenarios_{level}.json` geladen.
///
/// Schema-Übersicht:
/// ```
/// Scenario
///   ├── id, emoji, level, register
///   ├── title  (ko/de/en)
///   ├── intro  (de/en — Hook in der Muttersprache)
///   ├── vocab[]      → VocabRef
///   ├── grammarIds[] → Strings, verweisen auf grammar.csv `id`
///   ├── dialog[]     → DialogLine
///   ├── quests[]     → QuestSpec
///   ├── culturalNote (optional)
///   └── xpReward
/// ```
library;

export 'learner_level.dart';

import 'curriculum.dart' show SpeechStyle, SpeechStyleX;
import 'learner_level.dart';
import 'scenario_character.dart';

/// Eine mehrsprachige Zeichenkette aus dem Scenario-JSON.
class LocalizedText {
  final String ko;
  final String de;
  final String en;

  const LocalizedText({required this.ko, required this.de, required this.en});

  /// Wählt die Variante anhand des Sprachcodes ('de'|'en'|fallback 'de').
  String pick(String langCode) {
    switch (langCode) {
      case 'en':
        return en.isNotEmpty ? en : de;
      case 'ko':
        return ko;
      default:
        return de.isNotEmpty ? de : en;
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
    aliases: ((j['aliases'] as List?) ?? const []).cast<String>(),
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
      case 'en':
        return en.isNotEmpty ? en : de;
      case 'ko':
        return ko;
      default:
        return de.isNotEmpty ? de : en;
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

  /// Satz aus Wort-Kacheln selbst zusammensetzen (produktiv).
  satzBauen,

  /// Diktat: gehörten Satz selbst tippen (produktiv, Hör+Schreib).
  diktat,

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
  /// Optional raw source ID. Pilot quests use this to make their concept
  /// mapping auditable without inventing an unstable index-based identifier.
  final String id;
  final QuestType type;
  final Map<String, dynamic> data;
  final List<String> conceptIds;

  const QuestSpec({
    this.id = '',
    required this.type,
    required this.data,
    this.conceptIds = const [],
  });

  factory QuestSpec.fromJson(Map<String, dynamic> j) => QuestSpec(
    id: (j['id'] as String?)?.trim() ?? '',
    type: QuestType.fromCode((j['type'] as String?) ?? 'hoerverstehen'),
    data: (j['data'] as Map<String, dynamic>?) ?? const {},
    conceptIds: ((j['conceptIds'] as List?) ?? const []).cast<String>(),
  );

  bool get hasExplicitId => id.isNotEmpty;

  /// Korean vocabulary keys this quest tests. Used for error-aware SRS:
  /// failing the quest marks these keys as "didn't get it" so they surface
  /// sooner. Empty for grammar-only quest types.
  List<String> targetVocabKeys() {
    switch (type) {
      case QuestType.hoerverstehen:
      case QuestType.luecken:
      case QuestType.uebersetzen:
        final opts = (data['options'] as List?) ?? const [];
        final idx = (data['correctIndex'] as num?)?.toInt() ?? 0;
        if (idx >= 0 && idx < opts.length) {
          final answer = opts[idx]?.toString() ?? '';
          if (answer.isNotEmpty) return [answer];
        }
        return const [];
      case QuestType.batchimDrop:
        final t = (data['targetWord'] as String?) ?? '';
        return t.isNotEmpty ? [t] : const [];
      case QuestType.satzBauen:
      case QuestType.diktat:
        final t = (data['targetKo'] as String?) ?? '';
        return t.isNotEmpty ? [t] : const [];
      case QuestType.particlePop:
      case QuestType.schreiben:
        return const [];
    }
  }
}

class CulturalNote {
  final LocalizedText title;
  final LocalizedText body;

  const CulturalNote({required this.title, required this.body});

  factory CulturalNote.fromJson(Map<String, dynamic> j) => CulturalNote(
    title: LocalizedText.fromJson(j['title'] as Map<String, dynamic>),
    body: LocalizedText.fromJson(j['body'] as Map<String, dynamic>),
  );

  /// Null-safe: gibt null zurück, wenn `culturalNote` kein Map ist oder
  /// title/body fehlen. So kann eine fehlerhafte Notiz NICHT das ganze
  /// Szenario (und via Loader die ganze Liste) beim Parsen werfen.
  static CulturalNote? fromJsonOrNull(dynamic j) {
    if (j is! Map<String, dynamic>) return null;
    final title = LocalizedText.fromJsonOrNull(j['title']);
    final body = LocalizedText.fromJsonOrNull(j['body']);
    if (title == null || body == null) return null;
    return CulturalNote(title: title, body: body);
  }
}

/// Inline Grammar-Block für Szenarien. Wenn ein Szenario einen spezifischen
/// Pattern lehrt, der nicht in `grammar.csv` ist, wird er hier eingebettet.
class GrammarBlock {
  final LocalizedText title; // z.B. "N(으)로 주세요"
  final LocalizedText explanation; // 2–4 Sätze Regel + Beispiele

  const GrammarBlock({required this.title, required this.explanation});

  factory GrammarBlock.fromJson(Map<String, dynamic> j) => GrammarBlock(
    title: LocalizedText.fromJson(j['title'] as Map<String, dynamic>),
    explanation: LocalizedText.fromJson(
      j['explanation'] as Map<String, dynamic>,
    ),
  );

  /// Null-safe (siehe [CulturalNote.fromJsonOrNull]).
  static GrammarBlock? fromJsonOrNull(dynamic j) {
    if (j is! Map<String, dynamic>) return null;
    final title = LocalizedText.fromJsonOrNull(j['title']);
    final explanation = LocalizedText.fromJsonOrNull(j['explanation']);
    if (title == null || explanation == null) return null;
    return GrammarBlock(title: title, explanation: explanation);
  }
}

/// Register / Formalitätsstufe — bestimmt Ton der Dialoge.
enum Register {
  polite, // ~요체 — Standard höflich (Café, Geschäft)
  casual, // 반말 — Freunde, Familie
  business, // 합쇼체 — Meeting, Vorstellung
  intimate; // 친밀한 반말 — Partner, enge Freunde

  static Register? tryFromCode(String? c) {
    // Legacy assets used `formal`; the product's canonical equivalent is the
    // business/official register rather than the polite fallback.
    final normalized = c?.trim().toLowerCase();
    if (normalized == 'formal') return Register.business;
    for (final r in values) {
      if (r.name == normalized) return r;
    }
    return null;
  }

  static Register fromCode(String c) {
    final parsed = tryFromCode(c);
    if (parsed != null) return parsed;
    return Register.polite;
  }
}

class Scenario {
  /// Scenarios are source-keyed; a blank ID is invalid for curriculum links.
  final String id;
  final LearnerLevel level;
  final String emoji;
  final Register register;
  final LocalizedText title;
  final LocalizedText intro;
  final List<VocabRef> vocab;
  final String courseUnitId;
  final SpeechStyle? speechStyle;
  final String relationshipContext;
  final String intent;
  final String playerCharacterId;
  final List<String> participantIds;

  /// 책가도 서재의 칸 — `{level}_{slug}` (예 `a1_eat`).  빈 문자열은 아직
  /// 배정되지 않은 시나리오다 (스펙 §5.1).
  final String shelf;

  /// 장면 배경 카테고리 — 12 열거값 중 하나.  `shelf` 와 **독립**이다:
  /// shelf 는 무엇을 배우나, backdrop 은 어디서 벌어지나다 (스펙 §5.1).
  final String backdrop;

  final List<String> conceptIds;
  final List<String> surfaceFormIds;
  final List<String> grammarIds;
  final GrammarBlock? grammarBlock; // inline grammar if not in grammar.csv
  final List<DialogLine> dialog;
  final List<QuestSpec> quests;
  final CulturalNote? culturalNote;
  final int xpReward;
  final String? sidekick; // 'minsu' | 'jieun' | null
  final String? preferredVoice; // hint für TTS voice picker (Phase 5b)

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
    this.courseUnitId = '',
    this.speechStyle,
    this.relationshipContext = '',
    this.intent = '',
    this.playerCharacterId = '',
    this.participantIds = const [],
    this.shelf = '',
    this.backdrop = '',
    this.conceptIds = const [],
    this.surfaceFormIds = const [],
    this.grammarBlock,
    this.culturalNote,
    this.xpReward = 100,
    this.sidekick,
    this.preferredVoice,
  });

  factory Scenario.fromJson(Map<String, dynamic> j) => Scenario(
    id: (j['id'] as String?) ?? '',
    level: LearnerLevel.fromCode(j['level'] as String?) ?? LearnerLevel.a1,
    emoji: (j['emoji'] as String?) ?? '📖',
    register: Register.fromCode((j['register'] as String?) ?? 'polite'),
    title:
        LocalizedText.fromJsonOrNull(j['title']) ??
        const LocalizedText(ko: '', de: '', en: ''),
    intro:
        LocalizedText.fromJsonOrNull(j['intro']) ??
        const LocalizedText(ko: '', de: '', en: ''),
    vocab: ((j['vocab'] as List?) ?? const [])
        .map((e) => VocabRef.fromJson(e as Map<String, dynamic>))
        .toList(),
    courseUnitId: (j['courseUnitId'] as String?) ?? '',
    speechStyle: SpeechStyleX.tryFromCode(j['speechStyle']?.toString()),
    relationshipContext: (j['relationshipContext'] as String?) ?? '',
    intent: (j['intent'] as String?) ?? '',
    playerCharacterId: ((j['playerCharacterId'] as String?) ?? '').trim(),
    participantIds: ((j['participantIds'] as List?) ?? const [])
        .map((item) => item.toString().trim())
        .where((item) => item.isNotEmpty)
        .toList(growable: false),
    shelf: ((j['shelf'] as String?) ?? '').trim(),
    backdrop: ((j['backdrop'] as String?) ?? '').trim(),
    conceptIds: ((j['conceptIds'] as List?) ?? const []).cast<String>(),
    surfaceFormIds: ((j['surfaceFormIds'] as List?) ?? const []).cast<String>(),
    grammarIds: ((j['grammarIds'] as List?) ?? const []).cast<String>(),
    grammarBlock: GrammarBlock.fromJsonOrNull(j['grammarBlock']),
    dialog: ((j['dialog'] as List?) ?? const [])
        .map((e) => DialogLine.fromJson(e as Map<String, dynamic>))
        .toList(),
    quests: ((j['quests'] as List?) ?? const [])
        .map((e) => QuestSpec.fromJson(e as Map<String, dynamic>))
        .toList(),
    culturalNote: CulturalNote.fromJsonOrNull(j['culturalNote']),
    xpReward: (j['xpReward'] as num?)?.toInt() ?? 100,
    sidekick: j['sidekick'] as String?,
    preferredVoice: j['preferredVoice'] as String?,
  );

  bool get hasExplicitId => id.trim().isNotEmpty;

  /// Resolves the stable `speaker == user` quest contract to the character
  /// who actually performs the learner turns in this scene.
  String resolvedCharacterIdForSpeaker(String speaker) {
    final normalized = speaker.trim().toLowerCase();
    if (normalized == 'user' && playerCharacterId.isNotEmpty) {
      return playerCharacterId.trim().toLowerCase();
    }
    return normalized;
  }

  /// Character profiles are authoritative for canonical scenes. The legacy
  /// fallback preserves the old 413-scene behaviour until each level has Jin
  /// approval and is promoted.
  String voiceForSpeaker(String speaker) {
    final resolved = resolvedCharacterIdForSpeaker(speaker);
    final profile = ScenarioCharacterCatalog.profileFor(resolved);
    if (profile != null) {
      return profile.voice;
    }
    return speaker.trim().toLowerCase() == 'user' ? 'female' : 'male';
  }

  String speakerDisplayName(
    String speaker, {
    required String languageCode,
    required String fallbackYou,
    required String fallbackNarrator,
    required String playerSelfSuffix,
  }) {
    final normalized = speaker.trim().toLowerCase();
    if (normalized == 'narrator' || normalized.isEmpty) {
      return fallbackNarrator;
    }
    final resolved = resolvedCharacterIdForSpeaker(normalized);
    final profile = ScenarioCharacterCatalog.profileFor(resolved);
    if (profile != null) {
      // Character names are Korean learning-world labels even when the app
      // chrome is German or English. This also prevents honorifics such as
      // `수진 씨` from becoming a fixed UI identity.
      final name = profile.nameKo;
      return normalized == 'user' ? '$name $playerSelfSuffix' : name;
    }
    if (normalized == 'user') {
      return fallbackYou;
    }
    return '${resolved[0].toUpperCase()}${resolved.substring(1)}';
  }
}

/// 장면 배경은 이제 JSON `backdrop` 필드가 정본이다.  2026-08-17 이전에는 여기
/// 264 엔트리 const map 이 있었고, 시나리오를 추가할 때마다 Dart 를 고쳐야 했다
/// (스펙 §5.2).  값은 `test/fixtures/backdrop_baseline.json` 으로 그대로 옮겨졌고
/// 무회귀는 `test/scenario_shelf_contract_test.dart` 가 지킨다.
///
/// ⚠️ 카테고리는 `assets/illustrations/scenes/{key}.png` 가 **번들에 실제로 있는**
/// 14 종뿐이다: airport · bank · cafe · convenience · directions · home ·
/// hotel · market · office · pharmacy · restaurant · salon · station · taxi.
/// `SceneAssetResolver` 의 per-scenario 오버라이드 동작은 바뀌지 않았다.
extension ScenarioBackdrop on Scenario {
  /// Category scene key for this scenario, or null if the data has none.
  String? get backdropKey => backdrop.isEmpty ? null : backdrop;
}
