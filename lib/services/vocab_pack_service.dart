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
  /// [lang] 에 기본값을 두지 않는다 — 'de' 기본값 때문에 호출부 4곳이 조용히
  /// 독일어를 쓰고 있었다 (2026-08-18 l10n 스윕). required 로 두면 새 호출부도
  /// 컴파일 단계에서 걸린다.
  static String displayLabel(String packId, {required String lang}) {
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
    'b1_work_coordination': (
      'Arbeitskoordination & Termine',
      'Work Coordination & Schedules',
    ),
    'b2_formal_complaint': (
      'Formelle Beschwerde & Abhilfe',
      'Formal Complaints & Remedies',
    ),
    'b2_decisions_perspectives': (
      'Entscheidungen & Perspektiven',
      'Decisions & Perspectives',
    ),
    'b2_reading_response': ('Lesen & Reaktionen', 'Reading & Responses'),
    'b2_language_society': ('Sprache & Gesellschaft', 'Language & Society'),
    'b2_collaborative_feedback': (
      'Zusammenarbeit & Feedback',
      'Collaboration & Feedback',
    ),
    'b2_digital_judgment': ('Digitale Urteilsfähigkeit', 'Digital Judgment'),
    'c1_accessible_participation': (
      'Barrierefreiheit & Teilhabe',
      'Accessibility & Participation',
    ),
    'c1_evidence_reasoning': ('Forschung & Evidenz', 'Research & Evidence'),
    'c2_institutional_mediation': (
      'Institutionen & Vermittlung',
      'Institutions & Mediation',
    ),
    'c2_narrative_perspective': (
      'Erinnerung & Erzählperspektive',
      'Memory & Narrative Perspective',
    ),
    'b2_shared_space_coordination': (
      'Gemeinsame Räume & Rücksicht',
      'Shared Spaces & Consideration',
    ),
    'b2_personal_boundaries': ('Rhythmus & Grenzen', 'Rhythm & Boundaries'),
    'c1_risk_communication': (
      'Risiko & öffentliche Information',
      'Risk & Public Information',
    ),
    'c1_sustainable_tradeoffs': (
      'Nachhaltige Entscheidungen vor Ort',
      'Sustainable Local Choices',
    ),
    'c2_language_framing': (
      'Sprache, Deutung & Macht',
      'Language, Framing & Power',
    ),
    'c2_technology_ethics': (
      'Technikethik & Verantwortung',
      'Technology Ethics & Accountability',
    ),
    'a1_partner_meet_names': (
      'Erste Begrüßung und Anrede',
      'First greeting and address terms',
    ),
    'a1_partner_first_gift': (
      'Das erste Besuchgeschenk',
      'The first visit gift',
    ),
    'a1_partner_house_entry': ('Ins Haus kommen', 'Coming into the house'),
    'a1_partner_table_basic': (
      'Der erste Familientisch',
      'The first family table',
    ),
    'a1_partner_seollal_basic': (
      'Erste Schritte an Seollal',
      'First steps at Seollal',
    ),
    'a1_partner_chuseok_basic': (
      'Erste Schritte an Chuseok',
      'First steps at Chuseok',
    ),
    'a1_partner_siblings_hello': (
      'Geschwister zum ersten Mal',
      'Meeting the siblings',
    ),
    'a1_partner_photo_thanks': ('Fotos und Dank', 'Photos and thanks'),
    'a2_partner_dinner_talk': (
      'Gespräch am Abendessen',
      'Talk at the family dinner',
    ),
    'a2_partner_seollal_day': ('Ein Seollal-Tag', 'A full Seollal day'),
    'a2_partner_chuseok_day': ('Ein Chuseok-Tag', 'A full Chuseok day'),
    'a2_partner_sibling_tease': (
      'Geschwisterscherze',
      'Sibling teasing and backup',
    ),
    'a2_partner_overnight': ('Über Nacht bleiben', 'Staying overnight'),
    'a2_partner_leftover_bags': ('Eingepackte Reste', 'Leftovers packed to go'),
    'a2_partner_hometown_trip': (
      'Fahrt ins Elternhaus',
      'Trip to the hometown house',
    ),
    'a2_partner_banmal_switch': (
      'Zwischen Banmal und Höflichkeit',
      'Between casual and honorific speech',
    ),
    'b1_partner_awkward_questions': (
      'Unangenehme Fragen parieren',
      'Deflecting awkward questions',
    ),
    'b1_partner_job_visa': (
      'Arbeit und Aufenthalt erklären',
      'Explaining work and stay',
    ),
    'b1_partner_translating': (
      'Das übersetzende Paar',
      'The partner who interprets',
    ),
    'b1_partner_drink_table': (
      'Manieren am Trinktisch',
      'Manners at the drinking table',
    ),
    'b1_partner_sleep_room': (
      'Schlafplatz und Zimmergrenze',
      'Sleeping place and room boundaries',
    ),
    'b1_partner_after_visit': (
      'Nach dem Besuch ordnen',
      'Debrief after the visit',
    ),
    'b1_partner_group_chat': (
      'Manieren im Familienchat',
      'Family group-chat manners',
    ),
    'b1_partner_holiday_plan': (
      'Feiertagspläne abstimmen',
      'Coordinating holiday plans',
    ),
    'b2_partner_inlaws': (
      'Zwischen Schwiegerfamilien',
      'Between the two in-law houses',
    ),
    'b2_partner_marriage_talk': (
      'Heiratsgespräche führen',
      'Handling marriage talk',
    ),
    'b2_partner_honorific_trap': (
      'Anredefallen meiden',
      'Avoiding address-term traps',
    ),
    'b2_partner_ancestral_rite': ('Am Ritualtisch', 'At the ancestral rite'),
    'b2_partner_family_money': (
      'Geld in der Familie',
      'Money talk in the family',
    ),
    'b2_partner_holiday_duty': (
      'Feiertagsarbeit und Fairness',
      'Holiday labor and fairness',
    ),
    'b2_partner_boundary': (
      'Grenzen setzen und Beziehung halten',
      'Setting boundaries while keeping the bond',
    ),
    'b2_partner_public_intro': (
      'Die Familie in der Öffentlichkeit vorstellen',
      'Introducing family in public',
    ),
    'c1_partner_family_framing': (
      'Rahmen der Familiensprache',
      'How family language frames us',
    ),
    'c1_partner_holiday_labor': (
      'Verteilung der Festarbeit',
      'How holiday labor is distributed',
    ),
    'c2_partner_inlaw_power': (
      'Macht und Sprache der Schwiegerfamilie',
      'Power and language among in-laws',
    ),
    'c2_partner_name_memory': (
      'Politik von Name und Erinnerung',
      'The politics of names and memory',
    ),
    'a1_post_office': ('Auf der Post', 'At the post office'),
    'a1_pharmacy_ask': ('In der Apotheke fragen', 'Asking at the pharmacy'),
    'a1_weekend_promise': ('Wochenendzusage', 'Weekend plans'),
    'a1_neighbors_hall': ('Nachbarn im Flur', 'Neighbors in the hall'),
    'a1_school_supplies': ('Sachen für den Kurs', 'Class supplies'),
    'a1_subway_card': ('U-Bahn-Karte', 'Subway card'),
    'a1_weather_layer': ('Der Witterung anziehen', 'Dressing for the weather'),
    'a1_sorry_thanks': ('Entschuldigung und Dank', 'Sorry and thanks'),
    'a2_phone_plan': ('Handytarif', 'Phone plan'),
    'a2_bank_counter': ('Am Bankschalter', 'Bank counter'),
    'a2_gym_class': ('Fitnesskurs', 'Gym class'),
    'a2_salon_visit': ('Friseurbesuch', 'Salon visit'),
    'a2_apt_rules': ('Hausordnung', 'Apartment rules'),
    'a2_part_time': ('Nebenjob', 'Part-time job'),
    'a2_lost_found': ('Fundsachen', 'Lost and found'),
    'a2_festival_booth': ('Feststand', 'Festival booth'),
    'b1_workplace_mail': ('Dienstmail', 'Workplace mail'),
    'b1_roommate_talk': ('WG-Gespräch', 'Roommate talk'),
    'b1_insurance_claim': ('Versicherungsfall', 'Insurance claim'),
    'b1_public_office': ('Gang zum Amt', 'Public office errand'),
    'b1_volunteer_shift': ('Ehrenamtsschicht', 'Volunteer shift'),
    'b1_parent_school': ('Elterngespräch', 'Parent-school talk'),
    'b1_repair_words': ('Reparaturwortschatz', 'Repair words'),
    'b1_travel_change': ('Reiseänderung', 'Travel change'),
    'b2_performance_review': ('Beurteilungsgespräch', 'Performance review'),
    'b2_housing_dispute': ('Wohnstreit', 'Housing dispute'),
    'b2_media_literacy': ('Medienkompetenz', 'Media literacy'),
    'b2_civic_meeting': ('Bürgerversammlung', 'Civic meeting'),
    'b2_team_negotiation': ('Teamverhandlung', 'Team negotiation'),
    'b2_policy_brief': ('Kurze Lage', 'Policy brief'),
    'b2_customer_escalation': ('Eskalation', 'Customer escalation'),
    'b2_research_summary': ('Kurzreferat', 'Research summary'),
    'c1_evidence_caveat': ('Evidenzvorbehalt', 'Evidence caveats'),
    'c1_public_briefing': ('Öffentliche Lage', 'Public briefing'),
    'c1_survey_design': ('Erhebungsdesign', 'Survey design'),
    'c1_risk_wording': ('Risikosprache', 'Risk wording'),
    'c1_access_cost': ('Zugang und Kosten', 'Access and cost'),
    'c1_participation_design': ('Beteiligungsdesign', 'Participation design'),
    'c1_local_tradeoff': ('Abwägung vor Ort', 'Local trade-offs'),
    'c1_maintenance_burden': ('Betriebslast', 'Maintenance burden'),
    'c2_framing_analysis': ('Framinganalyse', 'Framing analysis'),
    'c2_institutional_voice': ('Stimme der Institution', 'Institutional voice'),
    'c2_memory_narrative': ('Erinnerung und Erzählung', 'Memory and narrative'),
    'c2_authority_language': ('Autoritätssprache', 'Language of authority'),
    'c2_appeal_path': ('Einspruchsweg', 'Appeal path'),
    'c2_audit_trail': ('Prüfspur', 'Audit trail'),
    'c2_withdrawal_right': ('Widerrufsrecht', 'Withdrawal right'),
    'c2_automated_harm': ('Folgen der Automatik', 'Automated harm'),
    'c1_media_evidence': ('Evidenz in den Medien', 'Evidence in the media'),
    'c1_play_time_policy': (
      'Regulierung der Spielzeit',
      'Play-time regulation',
    ),
    'c1_fan_labor': ('Fanarbeit und Belastung', 'Fan work and load'),
    'c1_intimacy_safety': (
      'Sicherheit beim Kennenlernen',
      'Safety when meeting people',
    ),
    'c2_automation_redress': (
      'Automatisierung und Rechtsweg',
      'Automation and redress',
    ),
    'c2_sanction_accountability': (
      'Sanktion und Rechenschaft',
      'Sanctions and accountability',
    ),
    'c2_relationship_narratives': (
      'Narrativ und Perspektive',
      'Narrative and perspective',
    ),
    'c2_fandom_discourse': (
      'Fandom-Sprache und Macht',
      'Fandom language and power',
    ),
    'b2_2026_social_topics': (
      'Gesellschaft & Alltag 2026',
      'Society & Daily Life 2026',
    ),
    'c1_2026_social_topics': (
      'Gesellschaft im Wandel',
      'Society in Transition',
    ),
    'c2_2026_social_topics': (
      'Diskurs, Macht & Verantwortung',
      'Discourse, Power & Responsibility',
    ),
    'a1_city_services_2026': ('Stadtwege & Service', 'City Routes & Services'),
    'a2_housing_search_2026': (
      'Wohnungssuche & Vertrag',
      'Finding a Home & Contracts',
    ),
    'b1_work_entry_2026': (
      'Berufseinstieg & Arbeitsbedingungen',
      'Starting Work & Conditions',
    ),
    'b2_housing_migration_2026': (
      'Wohnkosten, Migration & Teilhabe',
      'Housing, Migration & Inclusion',
    ),
    'c1_ai_culture_labor_2026': (
      'KI-Transparenz & Kulturarbeit',
      'AI Transparency & Cultural Labor',
    ),
    'c2_demography_accountability_2026': (
      'Demografie, Diskurs & Verantwortung',
      'Demography, Discourse & Accountability',
    ),
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
    'b2_collaborative_feedback': 26,
    'b2_digital_judgment': 27,
    'c1_accessible_participation': 1,
    'c1_evidence_reasoning': 2,
    'c2_institutional_mediation': 1,
    'c2_narrative_perspective': 2,
    'b2_shared_space_coordination': 28,
    'b2_personal_boundaries': 29,
    'c1_risk_communication': 3,
    'c1_sustainable_tradeoffs': 4,
    'c2_language_framing': 3,
    'c2_technology_ethics': 4,
    'a1_partner_meet_names': 26,
    'a1_partner_first_gift': 27,
    'a1_partner_house_entry': 28,
    'a1_partner_table_basic': 29,
    'a1_partner_seollal_basic': 30,
    'a1_partner_chuseok_basic': 31,
    'a1_partner_siblings_hello': 32,
    'a1_partner_photo_thanks': 33,
    'a2_partner_dinner_talk': 33,
    'a2_partner_seollal_day': 34,
    'a2_partner_chuseok_day': 35,
    'a2_partner_sibling_tease': 36,
    'a2_partner_overnight': 37,
    'a2_partner_leftover_bags': 38,
    'a2_partner_hometown_trip': 39,
    'a2_partner_banmal_switch': 40,
    'b1_partner_awkward_questions': 21,
    'b1_partner_job_visa': 22,
    'b1_partner_translating': 23,
    'b1_partner_drink_table': 24,
    'b1_partner_sleep_room': 25,
    'b1_partner_after_visit': 26,
    'b1_partner_group_chat': 27,
    'b1_partner_holiday_plan': 28,
    'b2_partner_inlaws': 30,
    'b2_partner_marriage_talk': 31,
    'b2_partner_honorific_trap': 32,
    'b2_partner_ancestral_rite': 33,
    'b2_partner_family_money': 34,
    'b2_partner_holiday_duty': 35,
    'b2_partner_boundary': 36,
    'b2_partner_public_intro': 37,
    'c1_partner_family_framing': 5,
    'c1_partner_holiday_labor': 6,
    'c2_partner_inlaw_power': 5,
    'c2_partner_name_memory': 6,
    'a1_post_office': 34,
    'a1_pharmacy_ask': 35,
    'a1_weekend_promise': 36,
    'a1_neighbors_hall': 37,
    'a1_school_supplies': 38,
    'a1_subway_card': 39,
    'a1_weather_layer': 40,
    'a1_sorry_thanks': 41,
    'a2_phone_plan': 41,
    'a2_bank_counter': 42,
    'a2_gym_class': 43,
    'a2_salon_visit': 44,
    'a2_apt_rules': 45,
    'a2_part_time': 46,
    'a2_lost_found': 47,
    'a2_festival_booth': 48,
    'b1_workplace_mail': 29,
    'b1_roommate_talk': 30,
    'b1_insurance_claim': 31,
    'b1_public_office': 32,
    'b1_volunteer_shift': 33,
    'b1_parent_school': 34,
    'b1_repair_words': 35,
    'b1_travel_change': 36,
    'b2_performance_review': 38,
    'b2_housing_dispute': 39,
    'b2_media_literacy': 40,
    'b2_civic_meeting': 41,
    'b2_team_negotiation': 42,
    'b2_policy_brief': 43,
    'b2_customer_escalation': 44,
    'b2_research_summary': 45,
    'c1_evidence_caveat': 7,
    'c1_public_briefing': 8,
    'c1_survey_design': 9,
    'c1_risk_wording': 10,
    'c1_access_cost': 11,
    'c1_participation_design': 12,
    'c1_local_tradeoff': 13,
    'c1_maintenance_burden': 14,
    'c2_framing_analysis': 7,
    'c2_institutional_voice': 8,
    'c2_memory_narrative': 9,
    'c2_authority_language': 10,
    'c2_appeal_path': 11,
    'c2_audit_trail': 12,
    'c2_withdrawal_right': 13,
    'c2_automated_harm': 14,
    'c1_media_evidence': 15,
    'c1_play_time_policy': 16,
    'c1_fan_labor': 17,
    'c1_intimacy_safety': 18,
    'c2_automation_redress': 15,
    'c2_sanction_accountability': 16,
    'c2_relationship_narratives': 17,
    'c2_fandom_discourse': 18,
    'b2_2026_social_topics': 46,
    'c1_2026_social_topics': 19,
    'c2_2026_social_topics': 19,
    'a1_city_services_2026': 42,
    'a2_housing_search_2026': 49,
    'b1_work_entry_2026': 37,
    'b2_housing_migration_2026': 47,
    'c1_ai_culture_labor_2026': 20,
    'c2_demography_accountability_2026': 20,
  };
}
