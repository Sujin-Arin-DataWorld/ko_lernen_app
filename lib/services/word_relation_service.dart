import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;

import '../models/course_mastery.dart';
import '../models/curriculum.dart';
import '../models/learner_level.dart';
import '../models/vocab.dart';
import '../models/word_relation.dart';
import 'curriculum_catalog.dart';
import 'data_loader.dart';
import 'storage_service.dart';

/// Loads the word-web seed and builds learner-scoped study / quiz decks.
///
/// This is free practice. It does not write course evidence or Hanok grants.
class WordRelationService {
  WordRelationService._();

  static const String assetPath = 'assets/data/word_relations.json';
  static const int quizCap = 10;

  static List<WordRelationCluster>? _clusters;

  static Future<List<WordRelationCluster>> load({
    Future<String> Function(String path)? assetLoader,
  }) async {
    if (_clusters != null && assetLoader == null) {
      return _clusters!;
    }
    final raw = await (assetLoader ?? rootBundle.loadString)(assetPath);
    final parsed = parseClusters(raw);
    if (assetLoader == null) {
      _clusters = parsed;
    }
    return parsed;
  }

  static List<WordRelationCluster> parseClusters(String raw) {
    final decoded = json.decode(raw);
    if (decoded is! Map<String, dynamic>) {
      return const [];
    }
    final list = decoded['clusters'];
    if (list is! List) {
      return const [];
    }
    final seenIds = <String>{};
    final seenSources = <String>{};
    final out = <WordRelationCluster>[];
    for (final item in list) {
      if (item is! Map) {
        continue;
      }
      final cluster = WordRelationCluster.fromJson(
        Map<String, dynamic>.from(item),
      );
      if (cluster.id.isEmpty ||
          cluster.sourceKo.isEmpty ||
          !cluster.hasStudyContent) {
        continue;
      }
      if (!seenIds.add(cluster.id) || !seenSources.add(cluster.sourceKo)) {
        continue;
      }
      out.add(cluster);
    }
    return List<WordRelationCluster>.unmodifiable(out);
  }

  static List<WordRelationCluster> filterForLearner({
    required List<WordRelationCluster> clusters,
    required Set<String> seenKorean,
    required LearnerLevel level,
    required WordWebScope scope,
  }) {
    final seen = {for (final word in seenKorean) word.trim()}.difference({''});
    return [
      for (final cluster in clusters)
        if (_matchesScope(cluster, seen, level, scope)) cluster,
    ];
  }

  static bool _matchesScope(
    WordRelationCluster cluster,
    Set<String> seen,
    LearnerLevel level,
    WordWebScope scope,
  ) {
    if (scope == WordWebScope.learned) {
      return seen.contains(cluster.sourceKo);
    }
    final clusterLevel = LearnerLevel.fromCode(cluster.level);
    if (clusterLevel == null) {
      return false;
    }
    return clusterLevel.rank <= level.rank;
  }

  static List<WordRelationQuizItem> buildQuiz({
    required List<WordRelationCluster> clusters,
    List<WordRelationCluster>? distractorClusters,
    Random? random,
    int cap = quizCap,
  }) {
    final rng = random ?? Random();
    final candidates = <_QuizSeed>[];
    for (final cluster in clusters) {
      if (cluster.synonyms.isNotEmpty) {
        final answer = cluster.synonyms.first;
        candidates.add(
          _QuizSeed(
            kind: WordRelationKind.synonym,
            cluster: cluster,
            answerKo: answer.ko,
            promptDe: cluster.sourceKo,
            promptEn: cluster.sourceKo,
            blocked: {cluster.sourceKo, ...cluster.synonyms.map((n) => n.ko)},
          ),
        );
      }
      if (cluster.antonyms.isNotEmpty) {
        final answer = cluster.antonyms.first;
        candidates.add(
          _QuizSeed(
            kind: WordRelationKind.antonym,
            cluster: cluster,
            answerKo: answer.ko,
            promptDe: cluster.sourceKo,
            promptEn: cluster.sourceKo,
            blocked: {cluster.sourceKo, ...cluster.antonyms.map((n) => n.ko)},
          ),
        );
      }
      if (cluster.related.isNotEmpty) {
        final answer = cluster.related.first;
        candidates.add(
          _QuizSeed(
            kind: WordRelationKind.related,
            cluster: cluster,
            answerKo: answer.ko,
            promptDe: cluster.sourceKo,
            promptEn: cluster.sourceKo,
            blocked: {cluster.sourceKo, ...cluster.related.map((n) => n.ko)},
          ),
        );
      }
      if (cluster.expressions.isNotEmpty) {
        final answer = cluster.expressions.first;
        candidates.add(
          _QuizSeed(
            kind: WordRelationKind.expression,
            cluster: cluster,
            answerKo: answer.ko,
            promptDe: answer.de,
            promptEn: answer.en,
            blocked: {
              cluster.sourceKo,
              ...cluster.expressions.map((n) => n.ko),
            },
          ),
        );
      }
    }

    final poolByKind = <WordRelationKind, List<String>>{};
    for (final cluster in distractorClusters ?? clusters) {
      _addPool(poolByKind, WordRelationKind.synonym, [
        for (final item in cluster.synonyms) item.ko,
      ]);
      _addPool(poolByKind, WordRelationKind.antonym, [
        for (final item in cluster.antonyms) item.ko,
      ]);
      _addPool(poolByKind, WordRelationKind.related, [
        for (final item in cluster.related) item.ko,
      ]);
      _addPool(poolByKind, WordRelationKind.expression, [
        for (final item in cluster.expressions) item.ko,
      ]);
    }

    final items = <WordRelationQuizItem>[];
    candidates.shuffle(rng);
    for (final seed in candidates) {
      if (items.length >= cap) {
        break;
      }
      final options = _optionsFor(seed, poolByKind, rng);
      if (options.length < 4) {
        continue;
      }
      items.add(
        WordRelationQuizItem(
          kind: seed.kind,
          clusterId: seed.cluster.id,
          sourceKo: seed.cluster.sourceKo,
          promptDe: seed.promptDe,
          promptEn: seed.promptEn,
          answerKo: seed.answerKo,
          options: options,
        ),
      );
    }
    return items;
  }

  static void _addPool(
    Map<WordRelationKind, List<String>> pool,
    WordRelationKind kind,
    Iterable<String> words,
  ) {
    final list = pool.putIfAbsent(kind, () => <String>[]);
    for (final word in words) {
      final trimmed = word.trim();
      if (trimmed.isEmpty || list.contains(trimmed)) {
        continue;
      }
      list.add(trimmed);
    }
  }

  static List<String> _optionsFor(
    _QuizSeed seed,
    Map<WordRelationKind, List<String>> pool,
    Random rng,
  ) {
    final sameKind = [
      for (final word in pool[seed.kind] ?? const <String>[])
        if (!seed.blocked.contains(word) && word != seed.answerKo) word,
    ]..shuffle(rng);
    final distractors = [...sameKind];
    if (distractors.length < 3) {
      final extras = <String>[
        for (final words in pool.values)
          for (final word in words)
            if (!seed.blocked.contains(word) &&
                word != seed.answerKo &&
                !distractors.contains(word))
              word,
      ]..shuffle(rng);
      distractors.addAll(extras);
    }
    if (distractors.length < 3) {
      return const [];
    }
    final options = <String>[seed.answerKo, ...distractors.take(3)];
    options.shuffle(rng);
    return options;
  }

  /// Korean strings the learner has already met in packs or SRS reviews.
  ///
  /// Grammar pattern IDs stay out: they are not Korean headwords.
  static Set<String> learnedKorean() {
    return {
      for (final word in [...Storage.vokSeenIds, ...Storage.srsReviewedIds])
        if (word.trim().isNotEmpty) word.trim(),
    };
  }

  /// Pack/SRS Korean plus course vocab the learner already answered or finished.
  ///
  /// Snapshot or catalog failures keep the sync [learnedKorean] set. This
  /// method never writes course evidence or Hanok grants.
  static Future<Set<String>> learnedKoreanWithCourse({
    CourseMasterySnapshot? snapshot,
    Future<CurriculumCatalog> Function()? catalogLoader,
    Future<List<Vocab>> Function()? vocabLoader,
  }) async {
    final learned = learnedKorean();
    try {
      final mastery = snapshot ?? _snapshotFromStorage();
      CurriculumCatalog? catalog;
      try {
        catalog = await (catalogLoader ?? CurriculumCatalog.load)();
      } catch (_) {
        catalog = null;
      }
      final ids = courseVocabContentIds(
        snapshot: mastery,
        linksForCompletedUnit: catalog == null
            ? null
            : catalog.linksForCourseUnit,
      );
      if (ids.isEmpty) {
        return learned;
      }
      final rows = await (vocabLoader ?? DataLoader.loadVocab)();
      final byId = {for (final item in rows) item.id: item};
      return {
        ...learned,
        for (final id in ids)
          if (byId[id] != null && byId[id]!.korean.trim().isNotEmpty)
            byId[id]!.korean.trim(),
      };
    } catch (_) {
      return learned;
    }
  }

  @visibleForTesting
  static Set<String> courseVocabContentIds({
    required CourseMasterySnapshot snapshot,
    Iterable<ContentLink> Function(String unitId)? linksForCompletedUnit,
  }) {
    final ids = <String>{};
    for (final item in snapshot.evidence) {
      if (item.contentKind == CurriculumContentKind.vocab && item.isCorrect) {
        final id = item.contentId.trim();
        if (id.isNotEmpty) {
          ids.add(id);
        }
      }
    }
    final lookup = linksForCompletedUnit;
    if (lookup != null) {
      for (final unitId in snapshot.completedUnitIds) {
        for (final link in lookup(unitId)) {
          if (link.contentKind == CurriculumContentKind.vocab) {
            final id = link.contentId.trim();
            if (id.isNotEmpty) {
              ids.add(id);
            }
          }
        }
      }
    }
    return ids;
  }

  static CourseMasterySnapshot _snapshotFromStorage() {
    final raw = Storage.courseMasterySnapshotRawJson.trim();
    if (raw.isEmpty) {
      return const CourseMasterySnapshot.empty();
    }
    final decoded = jsonDecode(raw);
    if (decoded is! Map) {
      throw const FormatException('course mastery snapshot must be an object');
    }
    return CourseMasterySnapshot.decodeAndMigrate(
      Map<String, dynamic>.from(decoded),
    );
  }

  static void resetForTesting() => _clusters = null;
}

class _QuizSeed {
  const _QuizSeed({
    required this.kind,
    required this.cluster,
    required this.answerKo,
    required this.promptDe,
    required this.promptEn,
    required this.blocked,
  });

  final WordRelationKind kind;
  final WordRelationCluster cluster;
  final String answerKo;
  final String promptDe;
  final String promptEn;
  final Set<String> blocked;
}
