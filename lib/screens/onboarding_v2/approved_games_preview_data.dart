import '../../models/learner_level.dart';
import '../../models/silben_puzzle.dart';
import '../../models/vocab.dart';
import '../../services/cloze_loader.dart';
import '../../services/data_loader.dart';
import '../../services/kkeunmari_engine.dart';
import '../../services/silben_puzzle_loader.dart';

/// Read-only samples from the same shipped bundles as the production games.
/// Source IDs stay on their models. No account, result, SRS or reward owner is
/// instantiated by the preview.
class ApprovedGamesPreviewData {
  const ApprovedGamesPreviewData({
    required this.words,
    required this.daily,
    required this.puzzle,
    required this.chain,
  });

  final List<Vocab> words;
  final ClozeItem daily;
  final SilbenPuzzle puzzle;
  final List<KkeunmariWord> chain;

  static Future<ApprovedGamesPreviewData> load(LearnerLevel level) async {
    final values = await Future.wait<Object>([
      DataLoader.loadVocab(),
      ClozeLoader.load(),
      SilbenPuzzleLoader.load(),
      KkeunmariEngine.load(),
    ]);
    final allWords = values[0] as List<Vocab>;
    final words = allWords
        .where((word) => word.level.toLowerCase() == level.code)
        .where(
          (word) => word.korean.runes.every((c) => c >= 0xac00 && c <= 0xd7a3),
        )
        .toList(growable: false);
    final daily = (values[1] as List<ClozeItem>).firstWhere(
      (item) => level == LearnerLevel.a1 && item.id == 'cloze_a1_0012',
      orElse: () => (values[1] as List<ClozeItem>).firstWhere(
        (item) => item.level == level.code,
      ),
    );
    final puzzle =
        (values[2] as Map<String, List<SilbenPuzzle>>)[level.display]!.first;
    if (words.length < 3) {
      throw StateError('Preview vocabulary unavailable for ${level.code}');
    }
    // The actual noun-verified offline pool owns these word identities. This
    // sample neither invokes the online dictionary nor starts a timed round.
    final pool = values[3] as List<KkeunmariWord>;
    List<KkeunmariWord> chain = const [];
    for (final first in pool.where(
      (w) =>
          w.level.toLowerCase() == level.code &&
          w.word.length >= 2 &&
          w.word.length <= 4 &&
          !w.isDeadEnd,
    )) {
      final next = pool.where(
        (w) =>
            w.word != first.word &&
            w.word.length <= 4 &&
            w.first == first.last &&
            (_langAvailable(w)),
      );
      if (next.isNotEmpty) {
        chain = [first, next.first];
        break;
      }
    }
    if (chain.isEmpty) {
      throw StateError('Preview word chain unavailable');
    }
    return ApprovedGamesPreviewData(
      words: words.take(3).toList(growable: false),
      daily: daily,
      puzzle: puzzle,
      chain: chain,
    );
  }

  static bool _langAvailable(KkeunmariWord word) => word.german.isNotEmpty;
}
