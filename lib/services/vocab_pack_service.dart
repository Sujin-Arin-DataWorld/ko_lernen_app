import '../models/vocab.dart';
import '../models/vocab_pack.dart';
import 'data_loader.dart';

/// VocabPack 로더 + 진행도 헬퍼.
///
/// Phase 1 (stately-rising-jongga): 단순한 in-memory 그룹화.
/// Phase 2 부터: 화면 (VocabPacksScreen, VocabPackScreen) 에서 사용.
class VocabPackService {
  /// 메모리 캐시 — 한 세션 내 재호출 시 즉시 반환.
  static List<VocabPack>? _cache;

  /// 모든 팩 (level → pack_order → sub_index 순).
  ///
  /// 첫 호출 시 `DataLoader.loadVocab()` 가 CSV 를 한 번 읽고,
  /// 결과를 그룹화한다. 재호출은 캐시 hit.
  static Future<List<VocabPack>> loadAll() async {
    if (_cache != null) return _cache!;

    final all = await DataLoader.loadVocab();
    final grouped = <String, List<Vocab>>{};
    for (final v in all) {
      if (v.packId.isEmpty) continue; // 팩 미할당 → 무시 (방어적)
      grouped.putIfAbsent(v.packId, () => []).add(v);
    }

    final packs = grouped.entries.map((e) {
      final words = List<Vocab>.from(e.value)
        ..sort((a, b) => a.packOrder.compareTo(b.packOrder));
      return VocabPack(
        id: e.key,
        level: words.isEmpty ? '' : words.first.level,
        words: words,
      );
    }).toList();

    packs.sort(_packComparator);
    _cache = packs;
    return packs;
  }

  /// 특정 레벨의 팩 (a1_…).
  static Future<List<VocabPack>> packsForLevel(String level) async {
    final all = await loadAll();
    return all.where((p) => p.level == level).toList();
  }

  /// pack_id 로 단일 팩 lookup. null 이면 미존재.
  static Future<VocabPack?> findById(String packId) async {
    final all = await loadAll();
    for (final p in all) {
      if (p.id == packId) return p;
    }
    return null;
  }

  /// 표시용 라벨 (DE / EN). 폴백: pack_id.
  ///
  /// 정의는 [packDisplayMap] 참조. ARB 키와 다르게 빌드 타임 상수로 유지 —
  /// 팩 이름은 잘 안 바뀌고, l10n 키가 폭증하면 ARB 관리가 어려워짐.
  /// UI 에 다국어 노출이 필요해지면 향후 `pack_{id}_name` 키로 이전.
  static String displayLabel(String packId, {String lang = 'de'}) {
    final base = _baseId(packId);
    final pair = packDisplayMap[base];
    if (pair == null) return packId;
    final label = lang == 'en' ? pair.$2 : pair.$1;
    final sub = _subIndex(packId);
    return sub == null ? label : '$label ($sub)';
  }

  /// 캐시 무효화 (테스트 / 핫리로드 후).
  static void reset() {
    _cache = null;
  }

  // ── 정렬 ─────────────────────────────────────────────────────────────
  static int _packComparator(VocabPack a, VocabPack b) {
    final lvlCmp = a.level.compareTo(b.level);
    if (lvlCmp != 0) return lvlCmp;
    final aBase = _baseId(a.id);
    final bBase = _baseId(b.id);
    final aOrd = packOrderInLevel[aBase] ?? 99;
    final bOrd = packOrderInLevel[bBase] ?? 99;
    if (aOrd != bOrd) return aOrd.compareTo(bOrd);
    final aSub = _subIndex(a.id) ?? 0;
    final bSub = _subIndex(b.id) ?? 0;
    return aSub.compareTo(bSub);
  }

  static String _baseId(String packId) {
    final parts = packId.split('_');
    if (parts.isNotEmpty && int.tryParse(parts.last) != null) {
      return parts.sublist(0, parts.length - 1).join('_');
    }
    return packId;
  }

  static int? _subIndex(String packId) {
    final parts = packId.split('_');
    if (parts.isNotEmpty) {
      return int.tryParse(parts.last);
    }
    return null;
  }

  // ── 디스플레이 정의 ──────────────────────────────────────────────────
  //
  // 출처: scripts/build_vocab_packs.py 의 PACK_DISPLAY. 두 곳을 동기화 유지!
  // 변경 시 둘 다 수정 + 단위 테스트 (build_vocab_packs 출력 vs displayLabel)
  // 으로 확인.
  //
  // 형식: base_pack_id → (DE, EN)
  static const Map<String, (String, String)> packDisplayMap = {
    // A1
    'a1_greetings':    ('Begrüßung & Höflichkeit', 'Greetings & Politeness'),
    'a1_self_intro':   ('Sich vorstellen', 'Self-introduction'),
    'a1_family':       ('Familie & Beziehungen', 'Family & Relationships'),
    'a1_numbers':      ('Zahlen & Menge', 'Numbers & Quantity'),
    'a1_time':         ('Zeit', 'Time'),
    'a1_food':         ('Essen & Trinken', 'Food & Drinks'),
    'a1_body':         ('Körper', 'Body'),
    'a1_colors':       ('Farben', 'Colors'),
    'a1_descriptions': ('Beschreibung', 'Descriptions'),
    'a1_position':     ('Räumliche Position', 'Spatial Position'),
    'a1_daily':        ('Tägliche Aktivitäten', 'Daily Activities'),
    'a1_transport':    ('Verkehr & Bewegung', 'Transport & Movement'),
    'a1_misc':         ('Sonstiges', 'Miscellaneous'),
    // A2
    'a2_daily':        ('Alltag (A2)', 'Daily Life (A2)'),
    'a2_feelings':     ('Gefühle', 'Feelings'),
    'a2_food':         ('Essen & Trinken (A2)', 'Food & Drinks (A2)'),
    'a2_shopping':     ('Einkaufen', 'Shopping'),
    'a2_work':         ('Beruf (A2)', 'Work (A2)'),
    'a2_transport':    ('Verkehr (A2)', 'Transport (A2)'),
    'a2_descriptions': ('Beschreibung & Farben (A2)', 'Descriptions & Colors (A2)'),
    'a2_weather':      ('Wetter', 'Weather'),
    'a2_education':    ('Bildung (A2)', 'Education (A2)'),
    'a2_health_misc':  ('Gesundheit & Sonstiges', 'Health & Misc'),
    'a2_home':         ('Wohnen & Haushalt', 'Home & Household'),
    'a2_money':        ('Geld & Bank', 'Money & Banking'),
    // B1
    'b1_daily':                ('Alltag (B1)', 'Daily Life (B1)'),
    'b1_descriptions':         ('Beschreibung (B1)', 'Descriptions (B1)'),
    'b1_work':                 ('Beruf (B1)', 'Work (B1)'),
    'b1_tech_society':         ('Technologie & Gesellschaft', 'Technology & Society'),
    'b1_emotions_relations':   ('Gefühle & Beziehungen', 'Emotions & Relations'),
    'b1_health_education':     ('Gesundheit, Bildung & Umwelt', 'Health, Education & Environment'),
    // B1 확장 2026-08 (TOPIK-Kuratierung — tools/content_factory/add_b1_expansion_packs.py)
    'b1_media_culture':        ('Medien & Kultur', 'Media & Culture'),
    'b1_city_places':          ('Stadt & Orte', 'City & Places'),
    'b1_money_bank':           ('Geld & Gebühren (B1)', 'Money & Fees (B1)'),
    'b1_travel_transport':     ('Reise & Verkehr (B1)', 'Travel & Transport (B1)'),
    'b1_health_hospital':      ('Krankenhaus & Apotheke', 'Hospital & Pharmacy'),
    'b1_work_career':          ('Karriere & Büro', 'Career & Office'),
    'b1_social_events':        ('Feste & Einladungen', 'Celebrations & Invitations'),
    'b1_communication_lang':   ('Sprache & Ausdruck', 'Language & Expression'),
    'b1_character_feelings':   ('Charakter & Gefühle (B1)', 'Character & Feelings (B1)'),
    'b1_verbs_daily':          ('Nützliche Verben (B1)', 'Useful Verbs (B1)'),
    'b1_descriptions_adj':     ('Eigenschaften (B1)', 'Qualities (B1)'),
    'b1_time_life':            ('Zeit & Lebenslauf', 'Time & Life Stages'),
    // B2
    'b2_society':       ('Gesellschaft (B2)', 'Society (B2)'),
    'b2_thinking':      ('Denken & Abstraktion', 'Thinking & Abstraction'),
    'b2_communication': ('Kommunikation (B2)', 'Communication (B2)'),
    'b2_work':          ('Beruf (B2)', 'Work (B2)'),
    'b2_education':     ('Bildung (B2)', 'Education (B2)'),
    'b2_misc':          ('Sonstiges (B2)', 'Misc (B2)'),
    'b2_environment':   ('Umwelt & Klima', 'Environment & Climate'),
    // B2 확장 2026-08 (TOPIK-Kuratierung — tools/content_factory/add_b2_expansion_packs.py)
    'b2_modern_life':          ('Modernes Leben', 'Modern Life'),
    'b2_manners_society':      ('Umgangsformen', 'Manners & Conduct'),
    'b2_abstract_concepts':    ('Abstrakte Begriffe (B2)', 'Abstract Concepts (B2)'),
    'b2_language_grammar':     ('Sprache & Grammatik', 'Language & Grammar'),
    'b2_household_practical':  ('Haushalt & Praktisches', 'Household & Practical'),
    'b2_relationships_people': ('Menschen & Beziehungen (B2)', 'People & Relationships (B2)'),
    'b2_safety_rules':         ('Sicherheit & Regeln', 'Safety & Rules'),
    'b2_events_culture':       ('Feste & Traditionen', 'Festivals & Traditions'),
    'b2_thinking_verbs':       ('Handeln & Verändern (B2)', 'Action & Change (B2)'),
    'b2_honorifics':           ('Ehrensprache (높임말)', 'Honorific Speech'),
  };

  /// 레벨 내 팩 학습 순서 (위→아래). 디스플레이·잠금 순서.
  /// 변경 시 build_vocab_packs.py 의 PACK_ORDER_IN_LEVEL 와 동기화.
  static const Map<String, int> packOrderInLevel = {
    // A1
    'a1_greetings':    1,
    'a1_self_intro':   2,
    'a1_family':       3,
    'a1_numbers':      4,
    'a1_time':         5,
    'a1_body':         6,
    'a1_colors':       7,
    'a1_food':         8,
    'a1_position':     9,
    'a1_daily':        10,
    'a1_descriptions': 11,
    'a1_transport':    12,
    'a1_misc':         13,
    // A2
    'a2_daily':        1,
    'a2_food':         2,
    'a2_shopping':     3,
    'a2_descriptions': 4,
    'a2_feelings':     5,
    'a2_weather':      6,
    'a2_transport':    7,
    'a2_work':         8,
    'a2_education':    9,
    'a2_health_misc':  10,
    'a2_home':         11,
    'a2_money':        12,
    // B1
    'b1_daily':                1,
    'b1_descriptions':         2,
    'b1_emotions_relations':   3,
    'b1_work':                 4,
    'b1_tech_society':         5,
    'b1_health_education':     6,
    'b1_media_culture':        7,
    'b1_city_places':          8,
    'b1_travel_transport':     9,
    'b1_money_bank':           10,
    'b1_health_hospital':      11,
    'b1_work_career':          12,
    'b1_social_events':        13,
    'b1_communication_lang':   14,
    'b1_character_feelings':   15,
    'b1_verbs_daily':          16,
    'b1_descriptions_adj':     17,
    'b1_time_life':            18,
    // B2
    'b2_society':       1,
    'b2_thinking':      2,
    'b2_communication': 3,
    'b2_work':          4,
    'b2_education':     5,
    'b2_misc':          6,
    'b2_environment':   7,
    'b2_modern_life':          8,
    'b2_manners_society':      9,
    'b2_abstract_concepts':    10,
    'b2_language_grammar':     11,
    'b2_household_practical':  12,
    'b2_relationships_people': 13,
    'b2_safety_rules':         14,
    'b2_events_culture':       15,
    'b2_thinking_verbs':       16,
    'b2_honorifics':           17,
  };
}
