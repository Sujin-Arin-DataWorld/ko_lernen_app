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
  // ⛔ scripts/build_vocab_packs.py 는 11열 시대의 레거시 도구라 절대 실행하지
  // 않는다. 실행하면 현재 15열 CSV의 EN 열·stable id가 손상된다.
  // 새 팩은 tools/content_factory/plan_pack_assignments.py 의 read-only 검증과
  // Jin 검수 뒤에 이 map·순서·curriculum companion을 함께 명시적으로 갱신한다.
  //
  // 형식: base_pack_id → (DE, EN)
  static const Map<String, (String, String)> packDisplayMap = {
    // A1
    'a1_greetings': ('Begrüßung & Höflichkeit', 'Greetings & Politeness'),
    'a1_self_intro': ('Sich vorstellen', 'Self-introduction'),
    'a1_family': ('Familie & Beziehungen', 'Family & Relationships'),
    'a1_numbers': ('Zahlen & Menge', 'Numbers & Quantity'),
    'a1_time': ('Zeit', 'Time'),
    'a1_food': ('Essen & Trinken', 'Food & Drinks'),
    'a1_body': ('Körper', 'Body'),
    'a1_colors': ('Farben', 'Colors'),
    'a1_descriptions': ('Beschreibung', 'Descriptions'),
    'a1_position': ('Räumliche Position', 'Spatial Position'),
    'a1_daily': ('Tägliche Aktivitäten', 'Daily Activities'),
    'a1_transport': ('Verkehr & Bewegung', 'Transport & Movement'),
    'a1_misc': ('Sonstiges', 'Miscellaneous'),
    // A1 신규 2026-08 (콘텐츠 확장)
    'a1_reactions': ('Reaktionen', 'Reactions'),
    'a1_cafe_order': ('Café-Bestellung', 'Café Order'),
    'a1_convenience': ('Im Convenience Store', 'Convenience Store'),
    'a1_directions': ('Wegfragen', 'Asking Directions'),
    'a1_phone_sns': ('KakaoTalk & SNS', 'KakaoTalk & SNS'),
    'a1_classroom': ('Im Unterricht', 'In Class'),
    'a1_home_items': ('Zu Hause', 'At Home'),
    'a1_taste_food': ('Geschmack', 'Taste'),
    'a1_emotions_basic': ('Gefühle (Basis)', 'Basic Feelings'),
    'a1_seasons': ('Jahreszeiten & Wetter', 'Seasons & Weather'),
    'a1_shopping_basic': ('Einkaufen (Basis)', 'Basic Shopping'),
    'a1_exclamations': ('Ausrufe', 'Exclamations'),
    // A2
    'a2_daily': ('Alltag (A2)', 'Daily Life (A2)'),
    'a2_feelings': ('Gefühle', 'Feelings'),
    'a2_food': ('Essen & Trinken (A2)', 'Food & Drinks (A2)'),
    'a2_shopping': ('Einkaufen', 'Shopping'),
    'a2_work': ('Beruf (A2)', 'Work (A2)'),
    'a2_transport': ('Verkehr (A2)', 'Transport (A2)'),
    'a2_descriptions': (
      'Beschreibung & Farben (A2)',
      'Descriptions & Colors (A2)',
    ),
    'a2_weather': ('Wetter', 'Weather'),
    'a2_education': ('Bildung (A2)', 'Education (A2)'),
    'a2_health_misc': ('Gesundheit & Sonstiges', 'Health & Misc'),
    'a2_home': ('Wohnen & Haushalt', 'Home & Household'),
    'a2_money': ('Geld & Bank', 'Money & Banking'),
    // A2 확장 2026-08 (tools/content_factory/add_a2_expansion_packs.py)
    'a2_clothing': ('Kleidung', 'Clothing'),
    'a2_wearing_verbs': ('Anziehen & Accessoires', 'Wearing & Accessories'),
    'a2_restaurant': ('Im Restaurant', 'At the Restaurant'),
    'a2_household': ('Haushalt & Zimmer', 'Household & Room'),
    'a2_food_more': ('Essen & Zutaten', 'Food & Ingredients'),
    'a2_nature': ('Natur & Draußen', 'Nature & Outdoors'),
    'a2_people_jobs': ('Menschen & Berufe', 'People & Jobs'),
    'a2_school_uni': ('Schule & Uni', 'School & University'),
    'a2_change_verbs': ('Zustandsverben', 'State-change Verbs'),
    // A2 신규 2026-08 (콘텐츠 확장)
    'a2_delivery_app': ('Lieferapp', 'Delivery App'),
    'a2_korean_food': ('Koreanisches Essen', 'Korean Food'),
    'a2_banmal_intro': ('Informelle Sprache', 'Informal Speech'),
    'a2_culture_words': ('K-Kultur-Wörter', 'K-Culture Words'),
    'a2_dating_sns': ('Dating & SNS', 'Dating & SNS'),
    'a2_holidays': ('Feiertage & Feste', 'Holidays & Festivals'),
    'a2_hospital': ('Beim Arzt', 'At the Doctor'),
    'a2_moving_house': ('Umzug & Wohnung', 'Moving & Housing'),
    'a2_hobby': ('Hobbys & Freizeit', 'Hobbies & Free Time'),
    'a2_natural_spoken': ('Umgangssprache', 'Spoken Korean'),
    'a2_bbq_culture': ('BBQ-Kultur', 'BBQ Culture'),
    // B1
    'b1_daily': ('Alltag (B1)', 'Daily Life (B1)'),
    'b1_descriptions': ('Beschreibung (B1)', 'Descriptions (B1)'),
    'b1_work': ('Beruf (B1)', 'Work (B1)'),
    'b1_tech_society': ('Technologie & Gesellschaft', 'Technology & Society'),
    'b1_emotions_relations': ('Gefühle & Beziehungen', 'Emotions & Relations'),
    'b1_health_education': (
      'Gesundheit, Bildung & Umwelt',
      'Health, Education & Environment',
    ),
    // B1 확장 2026-08 (TOPIK-Kuratierung — tools/content_factory/add_b1_expansion_packs.py)
    'b1_media_culture': ('Medien & Kultur', 'Media & Culture'),
    'b1_city_places': ('Stadt & Orte', 'City & Places'),
    'b1_money_bank': ('Geld & Gebühren (B1)', 'Money & Fees (B1)'),
    'b1_travel_transport': ('Reise & Verkehr (B1)', 'Travel & Transport (B1)'),
    'b1_health_hospital': ('Krankenhaus & Apotheke', 'Hospital & Pharmacy'),
    'b1_work_career': ('Karriere & Büro', 'Career & Office'),
    'b1_social_events': ('Feste & Einladungen', 'Celebrations & Invitations'),
    'b1_communication_lang': ('Sprache & Ausdruck', 'Language & Expression'),
    'b1_character_feelings': (
      'Charakter & Gefühle (B1)',
      'Character & Feelings (B1)',
    ),
    'b1_verbs_daily': ('Nützliche Verben (B1)', 'Useful Verbs (B1)'),
    'b1_descriptions_adj': ('Eigenschaften (B1)', 'Qualities (B1)'),
    'b1_time_life': ('Zeit & Lebenslauf', 'Time & Life Stages'),
    // B2
    'b2_society': ('Gesellschaft (B2)', 'Society (B2)'),
    'b2_thinking': ('Denken & Abstraktion', 'Thinking & Abstraction'),
    'b2_communication': ('Kommunikation (B2)', 'Communication (B2)'),
    'b2_work': ('Beruf (B2)', 'Work (B2)'),
    'b2_education': ('Bildung (B2)', 'Education (B2)'),
    'b2_misc': ('Sonstiges (B2)', 'Misc (B2)'),
    'b2_environment': ('Umwelt & Klima', 'Environment & Climate'),
    // B2 확장 2026-08 (TOPIK-Kuratierung — tools/content_factory/add_b2_expansion_packs.py)
    'b2_modern_life': ('Modernes Leben', 'Modern Life'),
    'b2_manners_society': ('Umgangsformen', 'Manners & Conduct'),
    'b2_abstract_concepts': (
      'Abstrakte Begriffe (B2)',
      'Abstract Concepts (B2)',
    ),
    'b2_language_grammar': ('Sprache & Grammatik', 'Language & Grammar'),
    'b2_household_practical': (
      'Haushalt & Praktisches',
      'Household & Practical',
    ),
    'b2_relationships_people': (
      'Menschen & Beziehungen (B2)',
      'People & Relationships (B2)',
    ),
    'b2_safety_rules': ('Sicherheit & Regeln', 'Safety & Rules'),
    'b2_events_culture': ('Feste & Traditionen', 'Festivals & Traditions'),
    'b2_thinking_verbs': ('Handeln & Verändern (B2)', 'Action & Change (B2)'),
    'b2_honorifics': ('Ehrensprache (높임말)', 'Honorific Speech'),
    // B2 확장 (2026-08-15)
    'b2_life_values': ('Lebensphilosophie', 'Life Philosophy'),
    'b2_literature_emotion': ('Literatur & Gefühle', 'Literature & Emotions'),
    'b2_language_change': ('Sprache & Wandel', 'Language & Change'),
    'b1_housing_contract': ('Wohnen & Vertrag', 'Housing & Contracts'),
    'b2_formal_agreement': ('Formelle Vereinbarungen', 'Formal Agreements'),
    'b1_work_coordination': ('Arbeitskoordination & Termine', 'Work Coordination & Schedules'),
    'b2_formal_complaint': ('Formelle Beschwerde & Abhilfe', 'Formal Complaints & Remedies'),
    'b2_decisions_perspectives': ('Entscheidungen & Perspektiven', 'Decisions & Perspectives'),
    'b2_reading_response': ('Lesen & Reaktionen', 'Reading & Responses'),
    'b2_language_society': ('Sprache & Gesellschaft', 'Language & Society'),
  };

  /// 레벨 내 팩 학습 순서 (위→아래). 디스플레이·잠금 순서.
  /// 새 팩은 legacy build_vocab_packs.py와 동기화하지 않는다. Jin 검수 뒤
  /// plan_pack_assignments.py의 preflight와 companion curriculum mapping을
  /// 통과한 명시적 변경으로만 이 순서를 늘린다.
  static const Map<String, int> packOrderInLevel = {
    // A1
    'a1_greetings': 1,
    'a1_self_intro': 2,
    'a1_family': 3,
    'a1_numbers': 4,
    'a1_time': 5,
    'a1_body': 6,
    'a1_colors': 7,
    'a1_food': 8,
    'a1_position': 9,
    'a1_daily': 10,
    'a1_descriptions': 11,
    'a1_transport': 12,
    'a1_misc': 13,
    'a1_reactions': 14,
    'a1_cafe_order': 15,
    'a1_convenience': 16,
    'a1_directions': 17,
    'a1_phone_sns': 18,
    'a1_classroom': 19,
    'a1_home_items': 20,
    'a1_taste_food': 21,
    'a1_emotions_basic': 22,
    'a1_seasons': 23,
    'a1_shopping_basic': 24,
    'a1_exclamations': 25,
    // A2
    'a2_daily': 1,
    'a2_food': 2,
    'a2_shopping': 3,
    'a2_descriptions': 4,
    'a2_feelings': 5,
    'a2_weather': 6,
    'a2_transport': 7,
    'a2_work': 8,
    'a2_education': 9,
    'a2_health_misc': 10,
    'a2_home': 11,
    'a2_money': 12,
    'a2_clothing': 13,
    'a2_wearing_verbs': 14,
    'a2_restaurant': 15,
    'a2_food_more': 16,
    'a2_household': 17,
    'a2_nature': 18,
    'a2_people_jobs': 19,
    'a2_school_uni': 20,
    'a2_change_verbs': 21,
    'a2_delivery_app': 22,
    'a2_korean_food': 23,
    'a2_banmal_intro': 24,
    'a2_culture_words': 25,
    'a2_dating_sns': 26,
    'a2_holidays': 27,
    'a2_hospital': 28,
    'a2_moving_house': 29,
    'a2_hobby': 30,
    'a2_natural_spoken': 31,
    'a2_bbq_culture': 32,
    // B1
    'b1_daily': 1,
    'b1_descriptions': 2,
    'b1_emotions_relations': 3,
    'b1_work': 4,
    'b1_tech_society': 5,
    'b1_health_education': 6,
    'b1_media_culture': 7,
    'b1_city_places': 8,
    'b1_travel_transport': 9,
    'b1_money_bank': 10,
    'b1_health_hospital': 11,
    'b1_work_career': 12,
    'b1_social_events': 13,
    'b1_communication_lang': 14,
    'b1_character_feelings': 15,
    'b1_verbs_daily': 16,
    'b1_descriptions_adj': 17,
    'b1_time_life': 18,
    // B2
    'b2_society': 1,
    'b2_thinking': 2,
    'b2_communication': 3,
    'b2_work': 4,
    'b2_education': 5,
    'b2_misc': 6,
    'b2_environment': 7,
    'b2_modern_life': 8,
    'b2_manners_society': 9,
    'b2_abstract_concepts': 10,
    'b2_language_grammar': 11,
    'b2_household_practical': 12,
    'b2_relationships_people': 13,
    'b2_safety_rules': 14,
    'b2_events_culture': 15,
    'b2_thinking_verbs': 16,
    'b2_honorifics': 17,
    // B2 확장 (2026-08-15)
    'b2_life_values': 18,
    'b2_literature_emotion': 19,
    'b2_language_change': 20,
    'b1_housing_contract': 19,
    'b2_formal_agreement': 21,
    'b1_work_coordination': 20,
    'b2_formal_complaint': 22,
    'b2_decisions_perspectives': 23,
    'b2_reading_response': 24,
    'b2_language_society': 25,
  };
}
