import '../models/learner_level.dart';
import '../models/smalltalk.dart';
import '../models/vocab.dart';
import 'storage_service.dart';

/// **PersonalizedLessonService (M5 — Runtime, Kosten 0)**
///
/// Stellt "Dein Tageskurs" rein LOKAL zusammen — KEIN Claude/Cloud-Aufruf zur
/// Laufzeit. Es wird nur aus bereits vorhandenem Content ausgewählt & sortiert:
///   1) heute fällige / neue SRS-Karten zuerst (Schwäche-getrieben),
///   2) dann Vokabeln, deren Thema zu den gewählten Interessen passt,
///   3) begrenzt auf das Userlevel (≤).
///
/// Die "Content-Fabrik" (offline Claude-Batch) vergrößert später den Pool und
/// liefert interessen-getaggte Szenarien/Drills — der Auswahl-Algorithmus hier
/// bleibt gleich und profitiert automatisch.
class PersonalizedLessonService {
  PersonalizedLessonService._();

  static const int maxVocab = 12;

  /// Interesse → bestehende CSV-Themen (deutsche Kategorien in `vocab.topic`).
  static const Map<String, Set<String>> interestTopics = {
    'everyday': {'Alltag', 'Zeit', 'Position', 'Bewegung', 'Menge', 'Zahlen'},
    'food_shopping': {'Essen & Trinken', 'Einkaufen'},
    'work_study': {
      'Beruf',
      'Bildung',
      'Technologie',
      'Gesellschaft',
      'Wissenschaft',
    },
    'travel': {'Reise', 'Verkehr', 'Wetter', 'Geographie', 'Umwelt'},
    'feelings_people': {
      'Gefühle',
      'Beziehungen',
      'Familie',
      'Person',
      'Denken',
      'Kommunikation',
    },
    'health_body': {'Gesundheit', 'Körper', 'Sport'},
  };

  /// Alle wählbaren Interessen-Keys (Reihenfolge = Anzeige-Reihenfolge).
  static const List<String> allInterests = [
    'everyday',
    'food_shopping',
    'work_study',
    'travel',
    'feelings_people',
    'health_body',
  ];

  static Set<String> _topicsFor(Iterable<String> interests) {
    final out = <String>{};
    for (final i in interests) {
      out.addAll(interestTopics[i] ?? const <String>{});
    }
    return out;
  }

  static int levelRank(String code) =>
      (LearnerLevel.fromCode(code) ?? LearnerLevel.a1).rank;

  /// Baut den personalisierten Vokabel-Deck (max [maxVocab]).
  /// Rein synchron/lokal — liest nur den SRS-Zustand aus [Storage].
  static List<Vocab> buildVocabDeck(
    List<Vocab> allVocab, {
    required String levelCode,
    required Set<String> interests,
  }) {
    final level = LearnerLevel.fromCode(levelCode) ?? LearnerLevel.a1;
    final rank = level.rank;
    final eligible = allVocab
        .where((v) => levelRank(v.level) <= rank)
        .toList(growable: false);
    if (eligible.isEmpty) return const [];

    final exact = eligible
        .where((word) => LearnerLevel.fromCode(word.level) == level)
        .toList(growable: false);
    // Old fixtures and imported decks may not have an exact-level row. Keep
    // the historical cumulative fallback only for that genuinely empty case.
    final newCandidates = exact.isEmpty ? eligible : exact;
    final todayIds = Storage.todayGoalIdsForNewPool(
      allIds: eligible.map((word) => word.korean),
      newCandidateIds: newCandidates.map((word) => word.korean),
    ).toSet();
    final pool = exact.isEmpty
        ? eligible
        : eligible
              .where(
                (word) =>
                    LearnerLevel.fromCode(word.level) == level ||
                    todayIds.contains(word.korean),
              )
              .toList(growable: false);

    final topics = _topicsFor(interests);

    // Stabiler Sort: kleinerer Score zuerst. Index als Tie-Breaker erhält die
    // (kuratierte) CSV-Reihenfolge → deterministisch ohne Zufall.
    final indexed = <MapEntry<int, Vocab>>[
      for (var i = 0; i < pool.length; i++) MapEntry(i, pool[i]),
    ];
    indexed.sort((a, b) {
      final sa = _score(a.value, todayIds, topics);
      final sb = _score(b.value, todayIds, topics);
      if (sa != sb) return sa.compareTo(sb);
      return a.key.compareTo(b.key);
    });
    return indexed.take(maxVocab).map((e) => e.value).toList();
  }

  /// Convenience: liest Level + Interessen aus [Storage].
  static List<Vocab> buildFromStorage(List<Vocab> allVocab) => buildVocabDeck(
    allVocab,
    levelCode: Storage.userLevelCode ?? 'A1',
    interests: Storage.interests.toSet(),
  );

  // ── M5: Interesse → Small-talk-Kategorien (smalltalk.json category-ids) ──
  static const Map<String, List<String>> interestSmalltalk = {
    'everyday': ['daily', 'weekend', 'weather', 'mood'],
    'food_shopping': ['food'],
    'work_study': ['work_study', 'interview'],
    'travel': ['travel'],
    'feelings_people': ['dating', 'family', 'partner_family', 'mood'],
    'health_body': ['health'],
  };

  /// Small-talk-Kategorien passend zu den Interessen (Reihenfolge = Priorität).
  /// Leere Interessen → leere Liste (= keine Priorisierung).
  static List<String> smalltalkCategoriesFor(Iterable<String> interests) {
    final out = <String>[];
    for (final i in interests) {
      for (final c in (interestSmalltalk[i] ?? const <String>[])) {
        if (!out.contains(c)) out.add(c);
      }
    }
    return out;
  }

  /// Wählt [count] Small-talk-Sätze: Interessen-Kategorien zuerst, auf Level
  /// (≤) begrenzt. Rein lokal, deterministisch (CSV-Reihenfolge als Tie-Break).
  static List<SmalltalkPhrase> pickSmalltalk(
    List<SmalltalkPhrase> all, {
    required String levelCode,
    required Set<String> interests,
    int count = 1,
  }) {
    final level = LearnerLevel.fromCode(levelCode) ?? LearnerLevel.a1;
    final eligible = <SmalltalkPhrase>[
      for (final p in all)
        if (levelRank(p.level) <= level.rank) p,
    ];
    final exact = eligible
        .where((phrase) => LearnerLevel.fromCode(phrase.level) == level)
        .toList(growable: false);
    final pool = exact.isEmpty ? eligible : exact;
    if (pool.isEmpty) return const [];
    final cats = smalltalkCategoriesFor(interests).toSet();
    final indexed = [
      for (var i = 0; i < pool.length; i++) MapEntry(i, pool[i]),
    ];
    indexed.sort((a, b) {
      final am = (cats.isEmpty || cats.contains(a.value.category)) ? 0 : 1;
      final bm = (cats.isEmpty || cats.contains(b.value.category)) ? 0 : 1;
      if (am != bm) return am.compareTo(bm);
      return a.key.compareTo(b.key);
    });
    return indexed.take(count).map((e) => e.value).toList();
  }

  static int _score(Vocab v, Set<String> dueIds, Set<String> topics) {
    var s = 0;
    if (!dueIds.contains(v.korean)) s += 100; // fällige/neue Karten zuerst
    if (topics.isNotEmpty && !topics.contains(v.topic)) {
      s += 10; // Interessen-Treffer nach vorne
    }
    return s;
  }
}
