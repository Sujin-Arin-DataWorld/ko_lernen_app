/// Silben-Kreuz(음절 크로스워드) 모델 — assets/data/silben_puzzles.json 스키마.
/// 번들은 tool/gen_silben_puzzles.py 가 생성한다(직접 편집 금지).
library;

/// 퍼즐 속 단어 1개 (가로/세로 배치 + 힌트).
class SilbenWord {
  final String dir; // 'h' | 'v'
  final int row;
  final int col;
  final String answer;
  final String german;
  final String exampleKo; // 정답이 ◯로 가려진 한국어 예문
  final String exampleDe;

  const SilbenWord({
    required this.dir,
    required this.row,
    required this.col,
    required this.answer,
    required this.german,
    required this.exampleKo,
    required this.exampleDe,
  });

  bool get isHorizontal => dir == 'h';

  /// 이 단어가 차지하는 칸 좌표들 (배치 순서).
  List<(int, int)> get cells => [
    for (var j = 0; j < answer.length; j++)
      isHorizontal ? (row, col + j) : (row + j, col),
  ];

  factory SilbenWord.fromJson(Map<String, dynamic> json) => SilbenWord(
    dir: json['dir'] as String,
    row: json['row'] as int,
    col: json['col'] as int,
    answer: json['answer'] as String,
    german: json['german'] as String,
    exampleKo: json['exampleKo'] as String? ?? '',
    exampleDe: json['exampleDe'] as String? ?? '',
  );
}

/// 크로스워드 퍼즐 1개.
class SilbenPuzzle {
  final String id;
  final int rows;
  final int cols;
  final List<SilbenWord> words;
  final List<String> pool; // 해답 음절 + 방해 음절 (셔플됨)

  const SilbenPuzzle({
    required this.id,
    required this.rows,
    required this.cols,
    required this.words,
    required this.pool,
  });

  /// (row,col) → 정답 음절. 교차 칸은 단어들끼리 같은 음절임이 생성기에서 보장됨.
  Map<(int, int), String> get solution {
    final map = <(int, int), String>{};
    for (final w in words) {
      final cs = w.cells;
      for (var j = 0; j < cs.length; j++) {
        map[cs[j]] = w.answer[j];
      }
    }
    return map;
  }

  factory SilbenPuzzle.fromJson(Map<String, dynamic> json) => SilbenPuzzle(
    id: json['id'] as String,
    rows: json['rows'] as int,
    cols: json['cols'] as int,
    words: [
      for (final w in json['words'] as List)
        SilbenWord.fromJson(w as Map<String, dynamic>),
    ],
    pool: [for (final s in json['pool'] as List) s as String],
  );
}
