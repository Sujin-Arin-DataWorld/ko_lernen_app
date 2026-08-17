import '../models/book_page.dart';
import '../models/pronunciation_phrase.dart';
import '../models/scenario.dart';
import '../models/smalltalk.dart';
import '../models/vocab.dart';
import '../models/word_relation.dart';
import '../services/cloze_loader.dart';
import '../services/data_loader.dart';
import '../services/pronunciation_phrase_loader.dart';
import '../services/satz_loader.dart';
import '../services/scenario_loader.dart';
import '../services/smalltalk_loader.dart';
import '../services/word_relation_service.dart';

/// Existing curated items that use the learner's chosen notebook headwords.
/// Missing matches stay empty — this never invents new sentences.
class CustomPackCorpusMatch {
  const CustomPackCorpusMatch({
    required this.cloze,
    required this.satz,
    required this.vocab,
    this.smalltalk = const <SmalltalkPhrase>[],
    this.pronunciation = const <PronunciationPhrase>[],
    this.scenarios = const <Scenario>[],
    this.wordWeb = const <WordRelationCluster>[],
  });

  static const empty = CustomPackCorpusMatch(
    cloze: <ClozeItem>[],
    satz: <SatzSentence>[],
    vocab: <Vocab>[],
  );

  final List<ClozeItem> cloze;
  final List<SatzSentence> satz;
  final List<Vocab> vocab;
  final List<SmalltalkPhrase> smalltalk;
  final List<PronunciationPhrase> pronunciation;
  final List<Scenario> scenarios;
  final List<WordRelationCluster> wordWeb;

  /// Hangul-only slice of shipped CSV vocab. Notebook Speed/Chosung use
  /// [CustomPackCorpusResolver.notebookVocab] instead.
  List<Vocab> get chosung => vocab
      .where((item) => CustomPackCorpusResolver.isHangulOnly(item.korean))
      .toList(growable: false);

  bool get hasCuratedItems =>
      cloze.isNotEmpty ||
      satz.isNotEmpty ||
      smalltalk.isNotEmpty ||
      pronunciation.isNotEmpty ||
      scenarios.isNotEmpty ||
      wordWeb.isNotEmpty;

  CustomPackCorpusMatch restrictTo(Iterable<String> koreanHeadwords) {
    final selected = CustomPackCorpusResolver._normalized(koreanHeadwords);
    if (selected.isEmpty) {
      return empty;
    }
    return CustomPackCorpusMatch(
      cloze: cloze
          .where((item) => CustomPackCorpusResolver.matches(item.answer, selected))
          .toList(growable: false),
      satz: satz
          .where((item) => CustomPackCorpusResolver.matches(item.vocabKo, selected))
          .toList(growable: false),
      vocab: vocab
          .where((item) => CustomPackCorpusResolver.matches(item.korean, selected))
          .toList(growable: false),
      smalltalk: smalltalk
          .where((item) => CustomPackCorpusResolver.smalltalkMatches(item, selected))
          .toList(growable: false),
      pronunciation: pronunciation
          .where((item) => CustomPackCorpusResolver.occursIn(item.ko, selected))
          .toList(growable: false),
      scenarios: scenarios
          .where((item) => CustomPackCorpusResolver.scenarioMatches(item, selected))
          .toList(growable: false),
      wordWeb: wordWeb
          .where((item) => CustomPackCorpusResolver.wordWebMatches(item, selected))
          .toList(growable: false),
    );
  }
}

/// Result of loading the shipped catalogs for a notebook pack.
/// [failedSources] is why an empty match is not the same as "no sentences".
class CustomPackCorpusLoadResult {
  const CustomPackCorpusLoadResult({
    required this.match,
    this.failedSources = const <String>[],
  });

  final CustomPackCorpusMatch match;
  final List<String> failedSources;

  bool get loadFailed => failedSources.isNotEmpty;
}

class CustomPackCorpusResolver {
  const CustomPackCorpusResolver._();

  static const _verbSuffixes = <String>['하다', '되다', '이다'];

  static Set<String> stemsOf(String korean) {
    final trimmed = korean.trim();
    if (trimmed.isEmpty) {
      return <String>{};
    }
    final stems = <String>{trimmed};
    for (final suffix in _verbSuffixes) {
      if (trimmed.endsWith(suffix) && trimmed.length > suffix.length) {
        stems.add(trimmed.substring(0, trimmed.length - suffix.length));
      }
    }
    return stems;
  }

  static bool isHangulOnly(String korean) {
    final trimmed = korean.trim();
    if (trimmed.isEmpty) {
      return false;
    }
    return trimmed.runes.every(
      (rune) => (rune >= 0xAC00 && rune <= 0xD7A3) || rune == 0x20,
    );
  }

  static int hangulSyllableCount(String korean) {
    var count = 0;
    for (final rune in korean.runes) {
      if (rune >= 0xAC00 && rune <= 0xD7A3) {
        count++;
      }
    }
    return count;
  }

  /// Exact headword / stem equality. Used when the corpus already stores
  /// a vocabulary key (`ClozeItem.answer`, `SatzSentence.vocabKo`,
  /// `Vocab.korean`, scenario `vocab[]`, word-web `sourceKo`).
  static bool matches(String contentKorean, Iterable<String> selected) {
    final contentStems = stemsOf(contentKorean);
    if (contentStems.isEmpty) {
      return false;
    }
    for (final word in selected) {
      if (stemsOf(word).any(contentStems.contains)) {
        return true;
      }
    }
    return false;
  }

  /// Finds a 2+ syllable notebook stem inside an already-authored sentence.
  /// One-syllable stems are skipped so 이/가/은 do not light up every line.
  static bool occursIn(String sentence, Iterable<String> selected) {
    final text = sentence.trim();
    if (text.isEmpty) {
      return false;
    }
    for (final word in selected) {
      for (final stem in stemsOf(word)) {
        if (hangulSyllableCount(stem) < 2) {
          continue;
        }
        if (text.contains(stem)) {
          return true;
        }
      }
    }
    return false;
  }

  static bool smalltalkMatches(
    SmalltalkPhrase phrase,
    Iterable<String> selected,
  ) {
    if (occursIn(phrase.ko, selected)) {
      return true;
    }
    final reply = phrase.reply;
    if (reply != null && occursIn(reply.ko, selected)) {
      return true;
    }
    if (occursIn(phrase.followUp.ko, selected)) {
      return true;
    }
    for (final turn in phrase.safeAlternativeQuestions) {
      if (occursIn(turn.ko, selected)) {
        return true;
      }
    }
    return false;
  }

  static bool scenarioMatches(Scenario scenario, Iterable<String> selected) {
    for (final ref in scenario.vocab) {
      if (matches(ref.korean, selected)) {
        return true;
      }
      for (final alias in ref.aliases) {
        if (matches(alias, selected)) {
          return true;
        }
      }
    }
    for (final quest in scenario.quests) {
      for (final key in quest.targetVocabKeys()) {
        if (matches(key, selected)) {
          return true;
        }
      }
    }
    return false;
  }

  static bool wordWebMatches(
    WordRelationCluster cluster,
    Iterable<String> selected,
  ) {
    if (matches(cluster.sourceKo, selected)) {
      return true;
    }
    for (final neighbor in <WordNeighbor>[
      ...cluster.synonyms,
      ...cluster.antonyms,
      ...cluster.related,
    ]) {
      if (matches(neighbor.ko, selected)) {
        return true;
      }
    }
    for (final expression in cluster.expressions) {
      if (matches(expression.ko, selected) || occursIn(expression.ko, selected)) {
        return true;
      }
    }
    return false;
  }

  static CustomPackCorpusMatch resolve({
    required Iterable<String> koreanHeadwords,
    required List<ClozeItem> cloze,
    required List<SatzSentence> satz,
    required List<Vocab> vocab,
    List<SmalltalkPhrase> smalltalk = const <SmalltalkPhrase>[],
    List<PronunciationPhrase> pronunciation = const <PronunciationPhrase>[],
    List<Scenario> scenarios = const <Scenario>[],
    List<WordRelationCluster> wordWeb = const <WordRelationCluster>[],
  }) {
    final selected = _normalized(koreanHeadwords);
    if (selected.isEmpty) {
      return CustomPackCorpusMatch.empty;
    }
    final matchedCloze = cloze
        .where((item) => matches(item.answer, selected))
        .toList(growable: false);
    final matchedSatz = satz
        .where((item) => matches(item.vocabKo, selected))
        .toList(growable: false);
    final vocabByKo = <String, Vocab>{
      for (final item in vocab) item.korean.trim(): item,
    };
    final matchedVocab = <Vocab>[];
    final seen = <String>{};
    for (final key in selected) {
      Vocab? found;
      for (final stem in stemsOf(key)) {
        found = vocabByKo[stem];
        if (found != null) {
          break;
        }
      }
      if (found == null || !seen.add(found.korean.trim())) {
        continue;
      }
      matchedVocab.add(found);
    }
    return CustomPackCorpusMatch(
      cloze: matchedCloze,
      satz: matchedSatz,
      vocab: List<Vocab>.unmodifiable(matchedVocab),
      smalltalk: smalltalk
          .where((item) => smalltalkMatches(item, selected))
          .toList(growable: false),
      pronunciation: pronunciation
          .where((item) => occursIn(item.ko, selected))
          .toList(growable: false),
      scenarios: scenarios
          .where((item) => scenarioMatches(item, selected))
          .toList(growable: false),
      wordWeb: wordWeb
          .where((item) => wordWebMatches(item, selected))
          .toList(growable: false),
    );
  }

  /// Notebook glosses for own-meaning games (Speed Match, Chosung).
  /// These are the learner's cards, not shipped example sentences.
  static List<Vocab> notebookVocab(Iterable<ExtractedWord> words) {
    final out = <Vocab>[];
    for (final word in words) {
      final korean = word.korean.trim();
      if (korean.isEmpty) {
        continue;
      }
      if (word.translationDe.trim().isEmpty &&
          word.translationEn.trim().isEmpty) {
        continue;
      }
      out.add(
        Vocab(
          korean: korean,
          romanization: '',
          german: word.translationDe,
          level: '',
          posDe: '',
          exampleKorean: word.exampleKorean,
          exampleGerman: '',
          topic: 'notebook',
          english: word.translationEn,
        ),
      );
    }
    return List<Vocab>.unmodifiable(out);
  }

  static List<Vocab> notebookChosung(Iterable<ExtractedWord> words) {
    return notebookVocab(words)
        .where((item) => isHangulOnly(item.korean))
        .toList(growable: false);
  }

  static Future<CustomPackCorpusLoadResult> forWords(
    Iterable<String> koreanHeadwords,
  ) async {
    final failed = <String>[];
    final cloze = await _loadCatalog<List<ClozeItem>>(
      'cloze',
      failed,
      ClozeLoader.load,
      empty: const <ClozeItem>[],
    );
    final satz = await _loadCatalog<List<SatzSentence>>(
      'satz',
      failed,
      SatzLoader.load,
      empty: const <SatzSentence>[],
    );
    final vocab = await _loadCatalog<List<Vocab>>(
      'vocab',
      failed,
      DataLoader.loadVocab,
      empty: const <Vocab>[],
      errorOf: () => DataLoader.lastError,
    );
    try {
      await SmalltalkLoader.load();
      if (SmalltalkLoader.lastError != null) {
        failed.add('smalltalk');
      }
    } catch (_) {
      failed.add('smalltalk');
    }
    final pronunciation = await _loadCatalog<List<PronunciationPhrase>>(
      'pronunciation',
      failed,
      PronunciationPhraseLoader.load,
      empty: const <PronunciationPhrase>[],
      errorOf: () => PronunciationPhraseLoader.lastError,
    );
    final scenarios = await _loadCatalog<List<Scenario>>(
      'scenarios',
      failed,
      ScenarioLoader.load,
      empty: const <Scenario>[],
      errorOf: () => ScenarioLoader.lastError,
    );
    final wordWeb = await _loadCatalog<List<WordRelationCluster>>(
      'wordWeb',
      failed,
      WordRelationService.load,
      empty: const <WordRelationCluster>[],
    );
    return CustomPackCorpusLoadResult(
      match: resolve(
        koreanHeadwords: koreanHeadwords,
        cloze: cloze,
        satz: satz,
        vocab: vocab,
        smalltalk: SmalltalkLoader.phrases,
        pronunciation: pronunciation,
        scenarios: scenarios,
        wordWeb: wordWeb,
      ),
      failedSources: List<String>.unmodifiable(failed),
    );
  }

  static Future<T> _loadCatalog<T>(
    String name,
    List<String> failed,
    Future<T> Function() load, {
    required T empty,
    String? Function()? errorOf,
  }) async {
    try {
      final value = await load();
      if (errorOf != null && errorOf() != null) {
        failed.add(name);
      }
      return value;
    } catch (_) {
      failed.add(name);
      return empty;
    }
  }

  static Set<String> _normalized(Iterable<String> koreanHeadwords) => <String>{
    for (final word in koreanHeadwords)
      if (word.trim().isNotEmpty) word.trim(),
  };
}
