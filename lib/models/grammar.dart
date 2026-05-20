class Grammar {
  final String pattern;
  final String level;
  final String typeDe;
  final String explanationDe;
  final String exampleKorean;
  final String exampleGerman;
  final String note;

  const Grammar({
    required this.pattern,
    required this.level,
    required this.typeDe,
    required this.explanationDe,
    required this.exampleKorean,
    required this.exampleGerman,
    required this.note,
  });

  factory Grammar.fromRow(List<dynamic> row) => Grammar(
        pattern:       row[0].toString(),
        level:         row[1].toString(),
        typeDe:        row[2].toString(),
        explanationDe: row[3].toString(),
        exampleKorean: row[4].toString(),
        exampleGerman: row[5].toString(),
        note:          row[6].toString(),
      );
}
