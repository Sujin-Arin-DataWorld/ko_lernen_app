import '../services/cloze_loader.dart';

/// Stable, persistence-safe identifiers for the eight cloze learning domains.
enum ClozeTopicGroupId {
  everydayHome,
  peopleRelationships,
  travelServices,
  workEducation,
  languageMedia,
  societyInstitutions,
  technologyScience,
  healthNatureLeisure,
}

/// Exact canonical topic authority for `assets/data/cloze.json`.
///
/// Item IDs remain owned by the JSON corpus. This class only maps each exact
/// topic string to one stable group and derives group membership from the
/// canonical [ClozeItem] objects, so no second item-ID dataset can drift.
final class ClozeTopicGroups {
  ClozeTopicGroups._();

  static const List<ClozeTopicGroupId> _ordered = [
    ClozeTopicGroupId.everydayHome,
    ClozeTopicGroupId.peopleRelationships,
    ClozeTopicGroupId.travelServices,
    ClozeTopicGroupId.workEducation,
    ClozeTopicGroupId.languageMedia,
    ClozeTopicGroupId.societyInstitutions,
    ClozeTopicGroupId.technologyScience,
    ClozeTopicGroupId.healthNatureLeisure,
  ];

  static List<ClozeTopicGroupId> get ordered => _ordered;

  static const Map<String, ClozeTopicGroupId> _topicToGroup = {
    '결제와 배달': ClozeTopicGroupId.everydayHome,
    '도시 생활': ClozeTopicGroupId.everydayHome,
    '생활 종합': ClozeTopicGroupId.everydayHome,
    '약속과 일정': ClozeTopicGroupId.everydayHome,
    '집 구하기': ClozeTopicGroupId.everydayHome,
    'Alltag': ClozeTopicGroupId.everydayHome,
    'Einkaufen': ClozeTopicGroupId.everydayHome,
    'Essen & Trinken': ClozeTopicGroupId.everydayHome,
    'Farben': ClozeTopicGroupId.everydayHome,
    'Feststand': ClozeTopicGroupId.everydayHome,
    'Geld': ClozeTopicGroupId.everydayHome,
    'Hausordnung': ClozeTopicGroupId.everydayHome,
    'Menge': ClozeTopicGroupId.everydayHome,
    'Nachbarschaft': ClozeTopicGroupId.everydayHome,
    'Reparaturwortschatz': ClozeTopicGroupId.everydayHome,
    'WG-Gespräch': ClozeTopicGroupId.everydayHome,
    'Wochenendzusage': ClozeTopicGroupId.everydayHome,
    'Wohnen': ClozeTopicGroupId.everydayHome,
    'Wohnen & Vertrag': ClozeTopicGroupId.everydayHome,
    'Zahlen': ClozeTopicGroupId.everydayHome,
    'Zeit': ClozeTopicGroupId.everydayHome,
    '자기소개': ClozeTopicGroupId.peopleRelationships,
    '첫인사': ClozeTopicGroupId.peopleRelationships,
    'Begrüßung': ClozeTopicGroupId.peopleRelationships,
    'Beziehungen': ClozeTopicGroupId.peopleRelationships,
    'Entschuldigung': ClozeTopicGroupId.peopleRelationships,
    'Familie': ClozeTopicGroupId.peopleRelationships,
    'Gefühle': ClozeTopicGroupId.peopleRelationships,
    'Höflichkeit': ClozeTopicGroupId.peopleRelationships,
    'Kommunikation': ClozeTopicGroupId.peopleRelationships,
    'Motivation': ClozeTopicGroupId.peopleRelationships,
    'Partnerschaft & koreanische Familie':
        ClozeTopicGroupId.peopleRelationships,
    'Person': ClozeTopicGroupId.peopleRelationships,
    'Amtgang': ClozeTopicGroupId.travelServices,
    'Bankschalter': ClozeTopicGroupId.travelServices,
    'Friseursalon': ClozeTopicGroupId.travelServices,
    'Fundsachen': ClozeTopicGroupId.travelServices,
    'Handytarif': ClozeTopicGroupId.travelServices,
    'Postamt': ClozeTopicGroupId.travelServices,
    'Reise': ClozeTopicGroupId.travelServices,
    'Reiseänderung': ClozeTopicGroupId.travelServices,
    'U-Bahnkarte': ClozeTopicGroupId.travelServices,
    'Verkehr': ClozeTopicGroupId.travelServices,
    'Versicherungsfall': ClozeTopicGroupId.travelServices,
    '취업과 근무 조건': ClozeTopicGroupId.workEducation,
    'Arbeitskoordination & Termine': ClozeTopicGroupId.workEducation,
    'Beruf': ClozeTopicGroupId.workEducation,
    'Betriebslast': ClozeTopicGroupId.workEducation,
    'Beurteilung': ClozeTopicGroupId.workEducation,
    'Bildung': ClozeTopicGroupId.workEducation,
    'Dienstmail': ClozeTopicGroupId.workEducation,
    'Ehrenamtsschicht': ClozeTopicGroupId.workEducation,
    'Elterngespräch': ClozeTopicGroupId.workEducation,
    'Kurzreferat': ClozeTopicGroupId.workEducation,
    'Nebenjob': ClozeTopicGroupId.workEducation,
    'Schultasche': ClozeTopicGroupId.workEducation,
    'Teamarbeit & Feedback': ClozeTopicGroupId.workEducation,
    'Teamverhandlung': ClozeTopicGroupId.workEducation,
    '다시 묻기': ClozeTopicGroupId.languageMedia,
    '은는과 이가': ClozeTopicGroupId.languageMedia,
    'Autoritätssprache': ClozeTopicGroupId.languageMedia,
    'Beschreibung': ClozeTopicGroupId.languageMedia,
    'Denken': ClozeTopicGroupId.languageMedia,
    'Diskurs & Macht': ClozeTopicGroupId.languageMedia,
    'Entscheidungen & Perspektiven': ClozeTopicGroupId.languageMedia,
    'Erinnerung & Erzählperspektive': ClozeTopicGroupId.languageMedia,
    'Erinnerungsnarrativ': ClozeTopicGroupId.languageMedia,
    'Framinganalyse': ClozeTopicGroupId.languageMedia,
    'Kurzlage': ClozeTopicGroupId.languageMedia,
    'Lesen & Reaktionen': ClozeTopicGroupId.languageMedia,
    'Medien & Evidenz': ClozeTopicGroupId.languageMedia,
    'Medienkompetenz': ClozeTopicGroupId.languageMedia,
    'Narrativ & Perspektive': ClozeTopicGroupId.languageMedia,
    'Position': ClozeTopicGroupId.languageMedia,
    'Sprache & Gesellschaft': ClozeTopicGroupId.languageMedia,
    'Sprache, Deutung & Macht': ClozeTopicGroupId.languageMedia,
    '인구 담론과 제도 책임': ClozeTopicGroupId.societyInstitutions,
    '주거비와 사회 통합': ClozeTopicGroupId.societyInstitutions,
    'Beteiligungsdesign': ClozeTopicGroupId.societyInstitutions,
    'Bürgerversammlung': ClozeTopicGroupId.societyInstitutions,
    'Diskurs, Macht & Verantwortung': ClozeTopicGroupId.societyInstitutions,
    'Einspruchsweg': ClozeTopicGroupId.societyInstitutions,
    'Eskalation': ClozeTopicGroupId.societyInstitutions,
    'Formelle Beschwerde & Abhilfe': ClozeTopicGroupId.societyInstitutions,
    'Formelle Vereinbarungen': ClozeTopicGroupId.societyInstitutions,
    'Gemeinsame Räume & Rücksicht': ClozeTopicGroupId.societyInstitutions,
    'Gesellschaft': ClozeTopicGroupId.societyInstitutions,
    'Gesellschaft & Alltag 2026': ClozeTopicGroupId.societyInstitutions,
    'Gesellschaft im Wandel': ClozeTopicGroupId.societyInstitutions,
    'Institutionelle Vermittlung': ClozeTopicGroupId.societyInstitutions,
    'Institutionsstimme': ClozeTopicGroupId.societyInstitutions,
    'Öffentliche Lage': ClozeTopicGroupId.societyInstitutions,
    'Regulierung & Nebenwirkung': ClozeTopicGroupId.societyInstitutions,
    'Sanktion & Rechenschaft': ClozeTopicGroupId.societyInstitutions,
    'Widerrufsrecht': ClozeTopicGroupId.societyInstitutions,
    'Wohnstreit': ClozeTopicGroupId.societyInstitutions,
    'Zugänglichkeit & Teilhabe': ClozeTopicGroupId.societyInstitutions,
    'Zugangskosten': ClozeTopicGroupId.societyInstitutions,
    'AI 투명성과 문화 노동': ClozeTopicGroupId.technologyScience,
    'Automatenfolgen': ClozeTopicGroupId.technologyScience,
    'Automatisierung & Rechtsweg': ClozeTopicGroupId.technologyScience,
    'Digitale Aufmerksamkeit': ClozeTopicGroupId.technologyScience,
    'Erhebungsdesign': ClozeTopicGroupId.technologyScience,
    'Evidenzvorbehalt': ClozeTopicGroupId.technologyScience,
    'Forschung & Evidenz': ClozeTopicGroupId.technologyScience,
    'Geographie': ClozeTopicGroupId.technologyScience,
    'Nachhaltige Entscheidungen vor Ort': ClozeTopicGroupId.technologyScience,
    'Ortliche Abwägung': ClozeTopicGroupId.technologyScience,
    'Prüfspur': ClozeTopicGroupId.technologyScience,
    'Risiko & öffentliche Information': ClozeTopicGroupId.technologyScience,
    'Risikosprache': ClozeTopicGroupId.technologyScience,
    'Technikethik & Verantwortung': ClozeTopicGroupId.technologyScience,
    'Technologie': ClozeTopicGroupId.technologyScience,
    'Wissenschaft': ClozeTopicGroupId.technologyScience,
    'Apotheke': ClozeTopicGroupId.healthNatureLeisure,
    'Fanarbeit & Belastung': ClozeTopicGroupId.healthNatureLeisure,
    'Fitnesskurs': ClozeTopicGroupId.healthNatureLeisure,
    'Freizeit': ClozeTopicGroupId.healthNatureLeisure,
    'Gesundheit': ClozeTopicGroupId.healthNatureLeisure,
    'Körper': ClozeTopicGroupId.healthNatureLeisure,
    'Rhythmus & Grenzen': ClozeTopicGroupId.healthNatureLeisure,
    'Sicherheit & Grenzen': ClozeTopicGroupId.healthNatureLeisure,
    'Umwelt': ClozeTopicGroupId.healthNatureLeisure,
    'Wetter': ClozeTopicGroupId.healthNatureLeisure,
    'Wetterschicht': ClozeTopicGroupId.healthNatureLeisure,
  };

  static ClozeTopicGroupId? groupForTopic(String topic) => _topicToGroup[topic];

  static Map<ClozeTopicGroupId, List<ClozeItem>> partition(
    Iterable<ClozeItem> items,
  ) {
    final grouped = <ClozeTopicGroupId, List<ClozeItem>>{
      for (final group in _ordered) group: <ClozeItem>[],
    };
    final seenIds = <String>{};

    for (final item in items) {
      if (!seenIds.add(item.id)) {
        throw StateError('Duplicate cloze item ID: ${item.id}');
      }
      final group = groupForTopic(item.topic);
      if (group == null) {
        throw StateError('Unmapped cloze topic: ${item.topic}');
      }
      grouped[group]!.add(item);
    }

    return Map.unmodifiable({
      for (final group in _ordered)
        group: List<ClozeItem>.unmodifiable(grouped[group]!),
    });
  }
}
