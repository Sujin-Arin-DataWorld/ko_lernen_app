/// One neighbor in a word-web cluster: synonym, antonym, or related word.
class WordNeighbor {
  final String ko;
  final String de;
  final String en;
  final String nuanceDe;
  final String nuanceEn;
  final String vocabId;

  const WordNeighbor({
    required this.ko,
    required this.de,
    required this.en,
    this.nuanceDe = '',
    this.nuanceEn = '',
    this.vocabId = '',
  });

  factory WordNeighbor.fromJson(Map<String, dynamic> json) {
    String read(String key) => (json[key] as String? ?? '').trim();
    return WordNeighbor(
      ko: read('ko'),
      de: read('de'),
      en: read('en'),
      nuanceDe: read('nuanceDe'),
      nuanceEn: read('nuanceEn'),
      vocabId: read('vocabId'),
    );
  }

  String gloss(String lang) => (lang == 'en' && en.isNotEmpty) ? en : de;

  String nuance(String lang) =>
      (lang == 'en' && nuanceEn.isNotEmpty) ? nuanceEn : nuanceDe;

  bool get isComplete => ko.isNotEmpty && de.isNotEmpty && en.isNotEmpty;
}

/// A set phrase or collocation attached to a learned source word.
class WordExpression {
  final String ko;
  final String de;
  final String en;
  final String exampleKo;
  final String exampleDe;
  final String exampleEn;

  const WordExpression({
    required this.ko,
    required this.de,
    required this.en,
    this.exampleKo = '',
    this.exampleDe = '',
    this.exampleEn = '',
  });

  factory WordExpression.fromJson(Map<String, dynamic> json) {
    String read(String key) => (json[key] as String? ?? '').trim();
    return WordExpression(
      ko: read('ko'),
      de: read('de'),
      en: read('en'),
      exampleKo: read('exampleKo'),
      exampleDe: read('exampleDe'),
      exampleEn: read('exampleEn'),
    );
  }

  String gloss(String lang) => (lang == 'en' && en.isNotEmpty) ? en : de;

  String example(String lang) =>
      (lang == 'en' && exampleEn.isNotEmpty) ? exampleEn : exampleDe;

  bool get isComplete => ko.isNotEmpty && de.isNotEmpty && en.isNotEmpty;
}

/// Synonyms, antonyms, related words, and expressions for one learned word.
class WordRelationCluster {
  final String id;
  final String sourceKo;
  final String sourceVocabId;
  final String sourceDe;
  final String sourceEn;
  final String level;
  final List<WordNeighbor> synonyms;
  final List<WordNeighbor> antonyms;
  final List<WordNeighbor> related;
  final List<WordExpression> expressions;

  const WordRelationCluster({
    required this.id,
    required this.sourceKo,
    required this.sourceVocabId,
    this.sourceDe = '',
    this.sourceEn = '',
    required this.level,
    this.synonyms = const [],
    this.antonyms = const [],
    this.related = const [],
    this.expressions = const [],
  });

  factory WordRelationCluster.fromJson(Map<String, dynamic> json) {
    String read(String key) => (json[key] as String? ?? '').trim();
    List<WordNeighbor> neighbors(String key) {
      final raw = json[key];
      if (raw is! List) {
        return const [];
      }
      return raw
          .whereType<Map>()
          .map((item) => WordNeighbor.fromJson(Map<String, dynamic>.from(item)))
          .where((item) => item.isComplete)
          .toList(growable: false);
    }

    List<WordExpression> phrases(String key) {
      final raw = json[key];
      if (raw is! List) {
        return const [];
      }
      return raw
          .whereType<Map>()
          .map(
            (item) => WordExpression.fromJson(Map<String, dynamic>.from(item)),
          )
          .where((item) => item.isComplete)
          .toList(growable: false);
    }

    return WordRelationCluster(
      id: read('id'),
      sourceKo: read('sourceKo'),
      sourceVocabId: read('sourceVocabId'),
      sourceDe: read('sourceDe'),
      sourceEn: read('sourceEn'),
      level: read('level'),
      synonyms: neighbors('synonyms'),
      antonyms: neighbors('antonyms'),
      related: neighbors('related'),
      expressions: phrases('expressions'),
    );
  }

  bool get hasStudyContent =>
      synonyms.isNotEmpty ||
      antonyms.isNotEmpty ||
      related.isNotEmpty ||
      expressions.isNotEmpty;

  String sourceGloss(String lang) =>
      (lang == 'en' && sourceEn.isNotEmpty) ? sourceEn : sourceDe;
}

enum WordWebScope { learned, level }

enum WordRelationKind { synonym, antonym, related, expression }

class WordRelationQuizItem {
  final WordRelationKind kind;
  final String clusterId;
  final String sourceKo;
  final String promptDe;
  final String promptEn;
  final String answerKo;
  final List<String> options;

  const WordRelationQuizItem({
    required this.kind,
    required this.clusterId,
    required this.sourceKo,
    required this.promptDe,
    required this.promptEn,
    required this.answerKo,
    required this.options,
  });

  String promptGloss(String lang) =>
      (lang == 'en' && promptEn.isNotEmpty) ? promptEn : promptDe;
}
