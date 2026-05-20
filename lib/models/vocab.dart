class Vocab {
  final String korean;
  final String romanization;
  final String german;
  final String level;
  final String posDe;
  final String exampleKorean;
  final String exampleGerman;
  final String topic;

  const Vocab({
    required this.korean,
    required this.romanization,
    required this.german,
    required this.level,
    required this.posDe,
    required this.exampleKorean,
    required this.exampleGerman,
    required this.topic,
  });

  factory Vocab.fromRow(List<dynamic> row) => Vocab(
        korean:        row[0].toString(),
        romanization:  row[1].toString(),
        german:        row[2].toString(),
        level:         row[3].toString(),
        posDe:         row[4].toString(),
        exampleKorean: row[5].toString(),
        exampleGerman: row[6].toString(),
        topic:         row[7].toString(),
      );
}
