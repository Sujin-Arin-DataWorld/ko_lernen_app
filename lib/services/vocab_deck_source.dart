import '../models/book_page.dart';
import '../models/vocab.dart';
import 'custom_pack_corpus_resolver.dart';
import 'kkeunmari_engine.dart';

/// The learner's selected rows, captured when a notebook game is opened.
/// Keeps the pack identity without changing the stored pack or its progress.
class VocabDeckSource {
  VocabDeckSource({
    required this.packId,
    required Iterable<ExtractedWord> words,
  }) : words = List<ExtractedWord>.unmodifiable(words);

  final String packId;
  final List<ExtractedWord> words;

  late final List<Vocab> vocabulary = CustomPackCorpusResolver.notebookVocab(
    words,
  );
  late final List<Vocab> chosung = List<Vocab>.unmodifiable(
    CustomPackCorpusResolver.notebookChosung(words),
  );

  String meaningFor(String korean, String languageCode) {
    for (final word in words) {
      if (word.korean.trim() == korean) {
        return word.translationFor(languageCode);
      }
    }
    return '';
  }

  /// A saved/OCR row is not dictionary validation. Only exact matches in the
  /// curated word-chain dictionary can enter this offline game.
  List<KkeunmariWord> wordChainPool(Iterable<KkeunmariWord> dictionary) {
    final selected = words.map((word) => word.korean.trim()).toSet();
    final seen = <String>{};
    return List<KkeunmariWord>.unmodifiable(
      dictionary.where(
        (word) => selected.contains(word.word) && seen.add(word.word),
      ),
    );
  }
}
