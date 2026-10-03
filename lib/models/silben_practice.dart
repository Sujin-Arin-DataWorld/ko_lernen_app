import 'silben_puzzle.dart';
import 'practice_history.dart';

class SilbenReviewRequest {
  const SilbenReviewRequest({
    required this.level,
    required this.puzzleId,
    this.revision = 1,
  });
  final String level;
  final String puzzleId;
  final int revision;
}

String silbenWordOccurrence(SilbenWord word) =>
    '${word.dir}:${word.row}:${word.col}';
PracticeSource silbenPracticeSource(SilbenPuzzle puzzle, String level) =>
    PracticeSource(
      kind: PracticeKind.silben,
      id: puzzle.id,
      level: level.toLowerCase(),
      revision: 1,
    );

/// Observes help only. The learner's grid and tile pool remain screen-owned.
class SilbenHelpState {
  final Map<String, int> levels = {};
  (int, int)? revealedCell;
  int levelFor(SilbenWord word) => levels[silbenWordOccurrence(word)] ?? 0;
  List<(int, int)> crossingCells(SilbenPuzzle puzzle, SilbenWord word) => word
      .cells
      .where((c) => (puzzle.memberships[c]?.length ?? 0) > 1)
      .toList();
  void use(
    SilbenPuzzle puzzle,
    SilbenWord word,
    int level, {
    (int, int)? cell,
  }) {
    if (!puzzle.words.contains(word) || level < 1 || level > 3) {
      throw ArgumentError('Invalid selected word or help level.');
    }
    final affected = <SilbenWord>[word];
    if (level == 3) {
      if (cell == null || !word.cells.contains(cell)) {
        throw ArgumentError('Reveal must belong to the selected word.');
      }
      revealedCell = cell;
      affected.addAll(puzzle.memberships[cell] ?? const []);
    }
    for (final w in affected) {
      final key = silbenWordOccurrence(w);
      if (level > (levels[key] ?? 0)) {
        levels[key] = level;
      }
    }
  }
}
