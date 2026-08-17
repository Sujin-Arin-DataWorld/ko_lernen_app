import '../models/book_page.dart';
import '../models/vocab.dart';
import '../services/cloze_loader.dart';
import '../services/data_loader.dart';
import '../services/satz_loader.dart';

/// Existing curated items that use the learner's chosen notebook headwords.
/// Missing matches stay empty — this never invents new sentences.
class CustomPackCorpusMatch {
  const CustomPackCorpusMatch({
    required this.cloze,
    required this.satz,
    required this.vocab,
  });

  static const empty = CustomPackCorpusMatch(
    cloze: <ClozeItem>[],
    satz: <SatzSentence>[],
    vocab: <Vocab>[],
  );

  final List<ClozeItem> cloze;
  final List<SatzSentence> satz;
  final List<Vocab> vocab;

  /// Chosung only accepts Hangul syllables (and spaces). Latin/Hanja
  /// notebook leftovers stay in [vocab] for Speed Match.
  List<Vocab> get chosung => vocab
      .where((item) => CustomPackCorpusResolver.isHangulOnly(item.korean))
      .toList(growable: false);

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

  static CustomPackCorpusMatch resolve({
    required Iterable<String> koreanHeadwords,
    required List<ClozeItem> cloze,
    required List<SatzSentence> satz,
    required List<Vocab> vocab,
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
    );
  }

  static Future<CustomPackCorpusMatch> forWords(
    Iterable<String> koreanHeadwords, {
    Iterable<ExtractedWord> fallbackWords = const <ExtractedWord>[],
  }) async {
    final cloze = await ClozeLoader.load();
    final satz = await SatzLoader.load();
    final vocab = await DataLoader.loadVocab();
    return resolve(
      koreanHeadwords: koreanHeadwords,
      cloze: cloze,
      satz: satz,
      vocab: vocab,
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
