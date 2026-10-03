import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:ko_lernen_app/data/cloze_topic_groups.dart';
import 'package:ko_lernen_app/services/cloze_loader.dart';

const _expectedTopics = <ClozeTopicGroupId, Set<String>>{
  ClozeTopicGroupId.everydayHome: {
    '결제와 배달',
    '도시 생활',
    '생활 종합',
    '약속과 일정',
    '집 구하기',
    'Alltag',
    'Einkaufen',
    'Essen & Trinken',
    'Farben',
    'Feststand',
    'Geld',
    'Hausordnung',
    'Menge',
    'Nachbarschaft',
    'Reparaturwortschatz',
    'WG-Gespräch',
    'Wochenendzusage',
    'Wohnen',
    'Wohnen & Vertrag',
    'Zahlen',
    'Zeit',
    'Zuhause',
  },
  ClozeTopicGroupId.peopleRelationships: {
    '자기소개',
    '첫인사',
    'Begrüßung',
    'Beziehungen',
    'Entschuldigung',
    'Familie',
    'Freundschaft',
    'Gefühle',
    'Höflichkeit',
    'Kommunikation',
    'Motivation',
    'Partnerschaft & koreanische Familie',
    'Person',
    'Selbstvorstellung',
  },
  ClozeTopicGroupId.travelServices: {
    'Amtgang',
    'Bankschalter',
    'Friseursalon',
    'Fundsachen',
    'Handytarif',
    'Postamt',
    'Reise',
    'Reiseänderung',
    'U-Bahnkarte',
    'Verkehr',
    'Versicherungsfall',
  },
  ClozeTopicGroupId.workEducation: {
    '직장 소통',
    '첫 수업',
    '취업과 근무 조건',
    'Arbeitskoordination & Termine',
    'Beruf',
    'Menschen & Berufe',
    'Betriebslast',
    'Beurteilung',
    'Bildung',
    'Dienstmail',
    'Ehrenamtsschicht',
    'Elterngespräch',
    'Kurzreferat',
    'Nebenjob',
    'Schultasche',
    'Teamarbeit & Feedback',
    'Teamverhandlung',
  },
  ClozeTopicGroupId.languageMedia: {
    'Abstrakte Begriffe',
    '다시 묻기',
    '은는과 이가',
    'Autoritätssprache',
    'Beschreibung',
    'Denken',
    'Diskurs & Macht',
    'Ehrensprache',
    'Entscheidungen & Perspektiven',
    'Erinnerung & Erzählperspektive',
    'Erinnerungsnarrativ',
    'Framinganalyse',
    'Kurzlage',
    'Lesen & Reaktionen',
    'Medien & Evidenz',
    'Medienkompetenz',
    'Narrativ & Perspektive',
    'Position',
    'Sprache & Gesellschaft',
    'Sprache, Deutung & Macht',
  },
  ClozeTopicGroupId.societyInstitutions: {
    '인구 담론과 제도 책임',
    '주거비와 사회 통합',
    'Argumentation und Verfahrensgestaltung',
    'Beteiligungsdesign',
    'Bürgerversammlung',
    'Diskurs, Macht & Verantwortung',
    'Einspruchsweg',
    'Eskalation',
    'Formelle Beschwerde & Abhilfe',
    'Formelle Vereinbarungen',
    'Gemeinsame Räume & Rücksicht',
    'Gesellschaft',
    'Gesellschaft & Alltag 2026',
    'Gesellschaft im Wandel',
    'Institutionelle Vermittlung',
    'Institutionsstimme',
    'Öffentliche Lage',
    'Regulierung & Nebenwirkung',
    'Sanktion & Rechenschaft',
    'Widerrufsrecht',
    'Wohnstreit',
    'Zugänglichkeit & Teilhabe',
    'Zugangskosten',
  },
  ClozeTopicGroupId.technologyScience: {
    'AI 투명성과 문화 노동',
    'Automatenfolgen',
    'Automatisierung & Rechtsweg',
    'Digitale Aufmerksamkeit',
    'Erhebungsdesign',
    'Evidenzvorbehalt',
    'Forschung & Evidenz',
    'Geographie',
    'Nachhaltige Entscheidungen vor Ort',
    'Ortliche Abwägung',
    'Prüfspur',
    'Risiko & öffentliche Information',
    'Risikosprache',
    'Technikethik & Verantwortung',
    'Technologie',
    'Wissenschaft',
  },
  ClozeTopicGroupId.healthNatureLeisure: {
    'Apotheke',
    'Fanarbeit & Belastung',
    'Fitnesskurs',
    'Freizeit',
    'Gesundheit',
    'Körper',
    'Natur',
    'Natur & Draußen',
    'Rhythmus & Grenzen',
    'Sicherheit & Grenzen',
    'Sport',
    'Tiere',
    'Umwelt',
    'Wetter',
    'Wetterschicht',
  },
};

void main() {
  final raw =
      jsonDecode(File('assets/data/cloze.json').readAsStringSync())
          as Map<String, dynamic>;
  final sourceRows = (raw['items'] as List).cast<Map<String, dynamic>>();
  final items = sourceRows.map(ClozeItem.fromJson).toList(growable: false);
  final canonicalTopics = items.map((item) => item.topic).toSet();

  test('accepted canonical baseline is exactly 2,365 items and 138 topics', () {
    // C3-T5 (2026-09-16): Batch 30 A1 reinforcement adds 62 cloze items and
    // 2 new exact topic strings (Selbstvorstellung, Tiere). 2215 + 62 =
    // 2277; 132 + 2 = 134. Batch 31 A2 reinforcement (first A2 batch) adds
    // 64 more cloze items and 2 more new topic strings (Menschen &
    // Berufe, Natur & Draußen). 2277 + 64 = 2341; 134 + 2 = 136.
    // C2 batches 35 and 37 add 24 items with two new exact topics.
    expect(items, hasLength(2365));
    expect(canonicalTopics, hasLength(138));
    expect(items.every((item) => item.topic.trim().isNotEmpty), isTrue);
    expect(items.every((item) => item.hasExplicitId), isTrue);
    expect(items.map((item) => item.id).toSet(), hasLength(items.length));
  });

  test('the stable authority exposes exactly eight ordered ASCII IDs', () {
    expect(ClozeTopicGroups.ordered, const [
      ClozeTopicGroupId.everydayHome,
      ClozeTopicGroupId.peopleRelationships,
      ClozeTopicGroupId.travelServices,
      ClozeTopicGroupId.workEducation,
      ClozeTopicGroupId.languageMedia,
      ClozeTopicGroupId.societyInstitutions,
      ClozeTopicGroupId.technologyScience,
      ClozeTopicGroupId.healthNatureLeisure,
    ]);
    expect(ClozeTopicGroups.ordered.toSet(), hasLength(8));
    expect(
      ClozeTopicGroups.ordered.every(
        (group) => RegExp(r'^[a-z][A-Za-z0-9]*$').hasMatch(group.name),
      ),
      isTrue,
    );
  });

  test('all 138 exact topics map once with no missing or dangling key', () {
    expect(_expectedTopics.keys.toList(), ClozeTopicGroups.ordered);
    final expectedUnion = <String>{};
    for (final entry in _expectedTopics.entries) {
      for (final topic in entry.value) {
        expect(
          expectedUnion.add(topic),
          isTrue,
          reason: 'topic appears in more than one group: $topic',
        );
        expect(ClozeTopicGroups.groupForTopic(topic), entry.key, reason: topic);
      }
    }
    expect(expectedUnion, hasLength(138));
    expect(expectedUnion, canonicalTopics);
    expect(ClozeTopicGroups.groupForTopic('not-a-canonical-topic'), isNull);
  });

  test('partition assigns every canonical item ID exactly once', () {
    final partition = ClozeTopicGroups.partition(items);
    expect(partition.keys.toList(), ClozeTopicGroups.ordered);

    final flattened = <ClozeItem>[];
    for (final group in ClozeTopicGroups.ordered) {
      final grouped = partition[group]!;
      expect(grouped, isNotEmpty, reason: group.name);
      expect(
        grouped.every(
          (item) => ClozeTopicGroups.groupForTopic(item.topic) == group,
        ),
        isTrue,
        reason: group.name,
      );
      flattened.addAll(grouped);
    }

    expect(flattened, hasLength(items.length));
    expect(flattened.map((item) => item.id).toSet(), hasLength(items.length));
    expect(
      flattened.map((item) => item.id).toSet(),
      items.map((item) => item.id).toSet(),
    );
  });

  test(
    'the two new C2 topics retain all twelve items in their exact groups',
    () {
      const additions = {
        'Ehrensprache': ClozeTopicGroupId.languageMedia,
        'Argumentation und Verfahrensgestaltung':
            ClozeTopicGroupId.societyInstitutions,
      };
      final counts = ClozeTopicGroups.countsForLevel(items, level: 'c2');
      expect(
        counts.values.fold<int>(0, (total, count) => total + count),
        items.where((item) => item.level == 'c2').length,
      );
      for (final entry in additions.entries) {
        final topicItems = items
            .where((item) => item.topic == entry.key)
            .toList();
        expect(topicItems, hasLength(12), reason: entry.key);
        expect(topicItems.every((item) => item.level == 'c2'), isTrue);
        final groupItems = ClozeTopicGroups.filterItems(
          items,
          level: 'c2',
          group: entry.value,
        );
        expect(groupItems, hasLength(counts[entry.value]!));
        expect(
          groupItems
              .where((item) => item.topic == entry.key)
              .map((item) => item.id),
          unorderedEquals(topicItems.map((item) => item.id)),
        );
      }
    },
  );

  test('partition fails closed for an unknown topic or duplicate item ID', () {
    final canonical = items.first;
    final unknown = ClozeItem(
      id: 'unknown-topic-fixture',
      level: canonical.level,
      sentenceKo: canonical.sentenceKo,
      answer: canonical.answer,
      fullKo: canonical.fullKo,
      de: canonical.de,
      en: canonical.en,
      distractors: canonical.distractors,
      topic: 'not-a-canonical-topic',
    );

    expect(
      () => ClozeTopicGroups.partition([unknown]),
      throwsA(isA<StateError>()),
    );
    expect(
      () => ClozeTopicGroups.partition([canonical, canonical]),
      throwsA(isA<StateError>()),
    );
  });
}
