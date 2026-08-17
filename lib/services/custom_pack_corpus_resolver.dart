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

  /// Chosung only accepts Hangul syllables (and spaces). Latin/Hanja
  /// notebook leftovers stay in [vocab] for Speed Match.
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
        if (matches(key, selected) || occursIn(key, selected)) {
          return true;
        }
      }
    }
    for (final line in scenario.dialog) {
      if (occursIn(line.ko, selected)) {
        return true;
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
    Iterable<ExtractedWord> fallbackWords = const <ExtractedWord>[],
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
      found ??= _fallbackVocab(key, fallbackWords);
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

  static Future<CustomPackCorpusMatch> forWords(
    Iterable<String> koreanHeadwords, {
    Iterable<ExtractedWord> fallbackWords = const <ExtractedWord>[],
  }) async {
    final cloze = await ClozeLoader.load();
    final satz = await SatzLoader.load();
    final vocab = await DataLoader.loadVocab();
    await SmalltalkLoader.load();
    final pronunciation = await PronunciationPhraseLoader.load();
    final scenarios = await ScenarioLoader.load();
    final wordWeb = await WordRelationService.load();
    return resolve(
      koreanHeadwords: koreanHeadwords,
      cloze: cloze,
      satz: satz,
      vocab: vocab,
      smalltalk: SmalltalkLoader.phrases,
      pronunciation: pronunciation,
      scenarios: scenarios,
      wordWeb: wordWeb,
      fallbackWords: fallbackWords,
    );
  }

  static Vocab? _fallbackVocab(
    String korean,
    Iterable<ExtractedWord> fallbackWords,
  ) {
    for (final word in fallbackWords) {
      if (!matches(word.korean, <String>[korean])) {
        continue;
      }
      if (word.translationDe.trim().isEmpty && word.translationEn.trim().isEmpty) {
        return null;
      }
      return Vocab(
        korean: word.korean.trim(),
        romanization: '',
        german: word.translationDe,
        level: '',
        posDe: '',
        exampleKorean: word.exampleKorean,
        exampleGerman: '',
        topic: 'notebook',
        english: word.translationEn,
      );
    }
    return null;
  }

  static Set<String> _normalized(Iterable<String> koreanHeadwords) => <String>{
    for (final word in koreanHeadwords)
      if (word.trim().isNotEmpty) word.trim(),
  };
}
