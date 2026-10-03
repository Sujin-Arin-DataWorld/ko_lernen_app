import 'package:flutter_test/flutter_test.dart';
import 'package:ko_lernen_app/models/silben_puzzle.dart';
import 'package:ko_lernen_app/models/silben_practice.dart';

void main() {
  const h = SilbenWord(
    dir: 'h',
    row: 1,
    col: 0,
    answer: '가나다',
    german: 'across',
    exampleKo: '',
    exampleDe: '',
  );
  const v = SilbenWord(
    dir: 'v',
    row: 0,
    col: 1,
    answer: '차나마',
    german: 'down',
    exampleKo: '',
    exampleDe: '',
  );
  const p = SilbenPuzzle(
    id: 'test',
    rows: 3,
    cols: 3,
    words: [h, v],
    pool: ['가', '나', '다', '차', '마'],
  );
  test(
    'help marks selected occurrence and shared reveal without mutating solution or pool',
    () {
      final help = SilbenHelpState();
      final solution = p.solution;
      help.use(p, h, 1);
      expect(help.levelFor(v), 0);
      expect(help.crossingCells(p, h), [(1, 1)]);
      help.use(p, h, 2);
      expect(help.levelFor(h), 2);
      help.use(p, h, 3, cell: (1, 1));
      expect(help.levelFor(v), 3);
      expect(help.revealedCell, (1, 1));
      expect(p.solution, solution);
      expect(p.pool.length, 5);
      expect(() => help.use(p, h, 3, cell: (0, 1)), throwsArgumentError);
      expect(silbenWordOccurrence(h), 'h:1:0');
    },
  );
}
