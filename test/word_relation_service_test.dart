import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ko_lernen_app/models/learner_level.dart';
import 'package:ko_lernen_app/models/word_relation.dart';
import 'package:ko_lernen_app/services/data_loader.dart';
import 'package:ko_lernen_app/services/storage_service.dart';
import 'package:ko_lernen_app/services/word_relation_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(WordRelationService.resetForTesting);

  tearDown(() {
    WordRelationService.resetForTesting();
    DataLoader.reset();
  });

  test('live seed links every source to an existing vocab row', () async {
    final clusters = await WordRelationService.load();
    final vocab = await DataLoader.loadVocab();
    final byId = {for (final item in vocab) item.id: item};
    final byKorean = {for (final item in vocab) item.korean: item};

    expect(clusters, isNotEmpty);
    expect(clusters.length, 66);
    expect(clusters.where((c) => c.level == 'B1'), hasLength(8));
    expect(clusters.where((c) => c.level == 'B2'), hasLength(8));
    expect(clusters.where((c) => c.synonyms.isEmpty), isEmpty);
    for (final cluster in clusters) {
      expect(cluster.hasStudyContent, isTrue, reason: cluster.id);
      expect(cluster.sourceDe, isNotEmpty, reason: cluster.id);
      expect(cluster.sourceEn, isNotEmpty, reason: cluster.id);
      expect(
        byId.containsKey(cluster.sourceVocabId),
        isTrue,
        reason: cluster.id,
      );
      expect(byId[cluster.sourceVocabId]!.korean, cluster.sourceKo);
      expect(byId[cluster.sourceVocabId]!.german, cluster.sourceDe);
      expect(byId[cluster.sourceVocabId]!.english, cluster.sourceEn);
      expect(
        byKorean.containsKey(cluster.sourceKo),
        isTrue,
        reason: cluster.id,
      );
      expect(cluster.expressions, isNotEmpty, reason: cluster.id);
    }
  });

  test('learnedKorean unions pack seen and SRS Korean keys', () async {
    Storage.resetForTesting();
    SharedPreferences.setMockInitialValues({});
    await Storage.init();
    await Storage.addVokSeen('크다');
    await Storage.srsReview('감사합니다', gotIt: true);

    expect(
      WordRelationService.learnedKorean(),
      containsAll(<String>{'크다', '감사합니다'}),
    );
    expect(WordRelationService.learnedKorean(), isNot(contains('')));
  });

  test('learned scope keeps only seen source words', () {
    final clusters = WordRelationService.parseClusters(_fixture);
    final learned = WordRelationService.filterForLearner(
      clusters: clusters,
      seenKorean: {'크다'},
      level: LearnerLevel.a2,
      scope: WordWebScope.learned,
    );
    final level = WordRelationService.filterForLearner(
      clusters: clusters,
      seenKorean: const {},
      level: LearnerLevel.a1,
      scope: WordWebScope.level,
    );

    expect(learned.map((c) => c.sourceKo), ['크다']);
    expect(level.map((c) => c.sourceKo), ['크다', '작다']);
    expect(
      WordRelationService.filterForLearner(
        clusters: clusters,
        seenKorean: const {},
        level: LearnerLevel.a1,
        scope: WordWebScope.learned,
      ),
      isEmpty,
    );
  });

  test(
    'quiz options include the answer and never leak same-cluster neighbors',
    () {
      final clusters = WordRelationService.parseClusters(_fixture);
      final items = WordRelationService.buildQuiz(
        clusters: clusters,
        random: Random(4),
        cap: 8,
      );

      expect(items, isNotEmpty);
      for (final item in items) {
        expect(item.options, hasLength(4));
        expect(item.options.toSet(), hasLength(4));
        expect(item.options, contains(item.answerKo));
        expect(item.options, isNot(contains(item.sourceKo)));
      }
      expect(
        items.any((item) => item.kind == WordRelationKind.antonym),
        isTrue,
      );
      expect(
        items.any((item) => item.kind == WordRelationKind.expression),
        isTrue,
      );
    },
  );

  test(
    'thin learned singleton uses the full seed only for distractors',
    () async {
      final all = await WordRelationService.load();
      final thin = all.firstWhere((cluster) => cluster.sourceKo == '감사합니다');
      final blocked = {
        thin.sourceKo,
        ...thin.synonyms.map((item) => item.ko),
        ...thin.antonyms.map((item) => item.ko),
        ...thin.related.map((item) => item.ko),
        ...thin.expressions.map((item) => item.ko),
      };

      expect(WordRelationService.buildQuiz(clusters: [thin]), isEmpty);

      final items = WordRelationService.buildQuiz(
        clusters: [thin],
        distractorClusters: all,
        random: Random(2),
      );
      expect(items, isNotEmpty);
      for (final item in items) {
        expect(item.sourceKo, thin.sourceKo);
        expect(item.options, hasLength(4));
        expect(item.options.toSet(), hasLength(4));
        expect(item.options, contains(item.answerKo));
        expect(item.options, isNot(contains(item.sourceKo)));
        expect(
          item.options.where((option) => option != item.answerKo),
          isNot(contains(thin.sourceKo)),
        );
      }
      expect(blocked, contains(thin.sourceKo));
    },
  );
}

const _fixture = '''
{
  "version": 1,
  "clusters": [
    {
      "id": "rel_test_big",
      "sourceKo": "크다",
      "sourceVocabId": "vocab_a1_0116",
      "sourceDe": "groß",
      "sourceEn": "big",
      "level": "A1",
      "synonyms": [
        {"ko": "커다랗다", "de": "sehr groß", "en": "huge"}
      ],
      "antonyms": [
        {"ko": "작다", "de": "klein", "en": "small"}
      ],
      "related": [
        {"ko": "사이즈", "de": "Größe", "en": "size"}
      ],
      "expressions": [
        {
          "ko": "큰일 나다",
          "de": "in Schwierigkeiten geraten",
          "en": "to get into trouble",
          "exampleKo": "열쇠를 두고 와서 큰일 났어요.",
          "exampleDe": "Ich habe den Schlüssel vergessen.",
          "exampleEn": "I left my keys and now I am in trouble."
        }
      ]
    },
    {
      "id": "rel_test_small",
      "sourceKo": "작다",
      "sourceVocabId": "vocab_a1_0117",
      "level": "A1",
      "synonyms": [
        {"ko": "조그맣다", "de": "winzig", "en": "tiny"}
      ],
      "antonyms": [
        {"ko": "크다", "de": "groß", "en": "big"}
      ],
      "related": [
        {"ko": "조금", "de": "ein bisschen", "en": "a little"}
      ],
      "expressions": [
        {
          "ko": "작은 가게",
          "de": "ein kleiner Laden",
          "en": "a small shop",
          "exampleKo": "집 앞에 작은 가게가 있어요.",
          "exampleDe": "Vor dem Haus gibt es einen kleinen Laden.",
          "exampleEn": "There is a small shop in front of the house."
        }
      ]
    },
    {
      "id": "rel_test_hot",
      "sourceKo": "덥다",
      "sourceVocabId": "vocab_a2_0059",
      "level": "A2",
      "synonyms": [
        {"ko": "뜨겁다", "de": "heiß", "en": "hot"}
      ],
      "antonyms": [
        {"ko": "춥다", "de": "kalt", "en": "cold"}
      ],
      "related": [
        {"ko": "여름", "de": "Sommer", "en": "summer"}
      ],
      "expressions": [
        {
          "ko": "오늘 너무 더워요",
          "de": "Heute ist es sehr heiß",
          "en": "It is very hot today",
          "exampleKo": "창문을 열어도 오늘 너무 더워요.",
          "exampleDe": "Selbst mit offenem Fenster ist es heute sehr heiß.",
          "exampleEn": "Even with the window open, it is very hot today."
        }
      ]
    },
    {
      "id": "rel_test_cold",
      "sourceKo": "춥다",
      "sourceVocabId": "vocab_a2_0060",
      "level": "A2",
      "synonyms": [
        {"ko": "차갑다", "de": "kühl", "en": "chilly"}
      ],
      "antonyms": [
        {"ko": "덥다", "de": "heiß", "en": "hot"}
      ],
      "related": [
        {"ko": "겨울", "de": "Winter", "en": "winter"}
      ],
      "expressions": [
        {
          "ko": "밖에 추워요",
          "de": "Draußen ist es kalt",
          "en": "It is cold outside",
          "exampleKo": "코트 입어요. 밖에 추워요.",
          "exampleDe": "Zieh einen Mantel an. Draußen ist es kalt.",
          "exampleEn": "Put on a coat. It is cold outside."
        }
      ]
    }
  ]
}
''';
