/// Szenario-Modelle — wird aus `assets/data/scenarios.json` geladen.
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
}

/// Scenario ID -> category scene key (cafe/office/home/directions/station/
/// taxi/airport/convenience/market/pharmacy/restaurant/hotel). This is the **fallback** backdrop used when a scenario has no
/// dedicated per-scenario asset; `SceneAssetResolver` overrides it automatically
/// when `scenes/{id}.png` / `video/loops/scene_{id}.mp4` are present.
///
/// Exact-id keys (not substring) so ids like `mart_grocery` map correctly and
/// order no longer matters. **All 39 scenarios are listed** → every scenario
/// always resolves to an existing category backdrop. Add new scenarios here.
///
/// 2026-08-03: 6개 시나리오가 미등록이라 `backdropKey`가 null → `posterAsset()`이
/// null을 반환해 배경 없이 마스코트로 떨어지고 있었다. 전수 등록하면서 `home`
/// 카테고리를 신설해 cafe 과부하(33개 중 13개)를 10개로 낮췄다 — 통화·메신저·
/// 사적 대화는 카페가 아니라 집이 맞다.
///
/// ⚠️ 카테고리를 새로 추가할 땐 `assets/illustrations/scenes/{key}.png`가
/// **번들에 실제로 있어야** 한다. 없으면 그 카테고리의 시나리오가 전부 깨진다.
/// 현재 실재(12): airport · cafe · convenience · directions · home · hotel ·
/// market · office · pharmacy · restaurant · station · taxi. 전부 단청 회화체 포스터.
///
/// 2026-08-04: 포스터 11종이 모두 실재하게 되어 하중을 재분배했다 —
/// directions 8→2(station 3·taxi 2·airport 1 분리), cafe 10→7(office 3 분리),
/// market 9→8(convenience 1 분리). clinic 은 아직 없어 market 유지.
///
/// 2026-08-07: `scenes/pharmacy.png` 는 번들에 들어가면서도 이 맵에 카테고리가
/// 없어 **한 번도 렌더된 적이 없는 고아**였다(1.6MB). `pharmacy_headache` 를
/// 여기로 옮겨 market 8→7. 약국 장면이 시장 배경을 쓰던 것도 함께 고쳐진다.
/// 대신 `loops/scene_pharmacy.mp4` 는 없어 이 카테고리는 정지 포스터만 나온다 —
/// 틀린 배경이 움직이는 것보다 맞는 배경이 정지한 편이 낫다는 판단.
/// clinic 계열(`doctor_consultation`·`clinic_safety`)은 배경이 없어 market 유지.
extension ScenarioBackdrop on Scenario {
  static const _categoryById = <String, String>{
    // Reviewed C1 Batch 04 scenarios. Existing backdrop pipeline only.
    'b1_leak_report': 'home',
    'b1_move_in_handover': 'office',
    'b1_contract_appointment': 'office',
    'b1_heating_safety_call': 'home',
    'b1_team_meeting_coordination': 'office',
    'b1_attendance_followup': 'office',
    'b1_covering_absence': 'office',
    'b1_reschedule_request': 'office',
    'b2_contract_clause_inquiry': 'office',
    'b2_deadline_deferral_request': 'office',
    'b2_signature_scope_confirmation': 'office',
    'b2_remedy_plan_request': 'office',
    'b2_objection_status_request': 'office',
    'b2_decision_criteria_workshop': 'office',
    'b2_reading_circle_response': 'cafe',
    'b2_public_wording_feedback': 'cafe',
    // Reviewed scenario Batch 06. Existing backdrop pipeline only.
    'b1_repair_visit_followup': 'home',
    'b2_device_failure_escalation': 'office',
    'c1_survey_limits_briefing': 'office',
    'c2_automated_decision_appeal': 'office',
    // Reviewed scenario Batch 08. Existing backdrop pipeline only.
    'a1_partner_first_door': 'home',
    'a1_partner_seollal_bow': 'home',
    'a1_partner_songpyeon_too_big': 'home',
    'a1_partner_more_side_dishes': 'restaurant',
    'a2_partner_leftover_bags': 'home',
    'a2_partner_holiday_train': 'station',
    'a2_partner_banmal_slip': 'home',
    'b1_partner_marriage_question': 'home',
    'b1_partner_drink_table': 'restaurant',
    'b1_partner_overnight_door': 'home',
    'b2_partner_inlaw_rotation': 'home',
    'b2_partner_public_intro': 'cafe',
    'c1_partner_invisible_labor': 'home',
    'c2_partner_name_and_memory': 'office',
    'a1_partner_gift_too_big': 'home',
    'a1_partner_wrong_seat': 'home',
    'a1_partner_new_year_money': 'home',
    'a2_partner_morning_greeting': 'home',
    'a2_partner_group_chat_join': 'home',
    'a2_partner_hanbok_rental': 'market',
    'b1_partner_salary_deflect': 'home',
    'b1_partner_interpret_skip': 'home',
    'b1_partner_heavy_bags_home': 'taxi',
    'b2_partner_dowry_joke': 'home',
    'b2_partner_holiday_labor_chart': 'home',
    'b2_partner_photo_permission': 'cafe',
    'c1_partner_guest_or_family': 'home',
    'c2_partner_document_the_place': 'home',
    // cafe — 카페 · 캐주얼한 만남 (2026-08-04: 10→7, 업무 3건은 office 로)
    'cafe_starbucks_basic': 'cafe',
    'introduce_yourself': 'cafe',
    'cafe_study': 'cafe',
    'love_confession': 'cafe',
    'friend_birthday': 'cafe',
    'first_class_meeting': 'cafe', // 첫 수업 — 교실 배경이 생기면 이동
    'titles_relationship_distance': 'cafe', // 처음 만난 사람 호칭
    // office — 업무 · 격식 있는 실내 (2026-08-04 신설)
    'business_meeting_intro': 'office',
    'bank_account': 'office',
    'job_interview': 'office',
    'rent_bank_transfer': 'office',
    // home — 통화 / 메신저 / 사적인 대화 (2026-08-03 신설)
    'warm_encouragement': 'home',
    'couple_argument': 'home',
    'plans_with_friend': 'home',
    'postpone_plans': 'home',
    'cancel_plans': 'home',
    'phone_messenger_reply': 'home',
    'delivery_address_confirmation': 'home',
    'clarify_repeat': 'home',
    'home_morning_routine': 'home',
    // directions — 길 위 (2026-08-04: 8→2, 역·공항·택시로 분리)
    'running_late': 'directions',
    'lost_phone': 'directions',
    'survival_day_capstone': 'directions',
    // station — 지하철 · 기차 (2026-08-04 신설)
    'subway_transfer': 'station',
    'subway_directions': 'station',
    'ktx_ticket': 'station',
    // taxi (2026-08-04 신설)
    'taxi_kakao': 'taxi',
    'taxi_street': 'taxi',
    // airport (2026-08-04 신설)
    'airport_arrival': 'airport',
    // convenience (2026-08-04 신설)
    'convenience_store': 'convenience',
    // pharmacy — 약국 창구 (2026-08-07 신설: 번들에만 있던 포스터를 배선)
    'pharmacy_headache': 'pharmacy',
    // market — 상점 · 심부름 · 건강 창구 (2026-08-04: 9→8, 2026-08-07: 8→7)
    'myeongdong_shopping': 'market',
    'mart_grocery': 'market',
    'complaint_delivery': 'market',
    'doctor_consultation': 'market', // 진료 상담 — clinic 배경이 생기면 이동
    'feeling_sick': 'market',
    'gym_signup': 'market',
    'clinic_safety': 'market', // 병원 접수 — clinic 배경이 생기면 이동
    // restaurant — 식사
    'bunshik_tteokbokki': 'restaurant',
    'company_dinner_hoeshik': 'restaurant',
    'food_delivery': 'restaurant',
    // hotel
    'hotel_checkin': 'hotel',
  };

  /// Category scene key for this scenario, or null if the id is unregistered.
  String? get backdropKey => _categoryById[id];
}
