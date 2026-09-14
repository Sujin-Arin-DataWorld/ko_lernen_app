// Fixtures for the O1 OCR gloss resolver (BookWordGlossResolver).
//
// Each fixture builds a [BookOcrDocument] the same way the real OCR pipeline
// does — through [BookOcrDocumentBuilder.build] on a flat stream of
// [BookOcrLine]s — so the resolver sees exactly the unit/region shape it
// would see from a photographed textbook page.
import 'dart:ui' show Rect;

import 'package:ko_lernen_app/services/book_ocr_document.dart';

BookOcrLine _line({
  required String text,
  required int blockIndex,
  required int lineIndex,
  required double top,
}) => BookOcrLine(
  text: text,
  bounds: Rect.fromLTWH(20, top, 260, 24),
  sourceLineId: 'block:$blockIndex:line:$lineIndex',
  blockIndex: blockIndex,
  lineIndex: lineIndex,
  confidence: 0.95,
  recognizedLanguages: const <String>['ko', 'de'],
);

/// F1 — a mixed A1 textbook page: ten Korean sentences, each immediately
/// followed (same OCR block) by its printed German translation line. The
/// German lines never contain Hangul, so `BookOcrDocumentBuilder` already
/// drops them before they can become analysis units — the resolver only ever
/// sees the Korean side. One sentence (S2) uses the copula `이에요`, which is
/// intentionally outside this PR's particle/verb-ending coverage (tracked as
/// a known miss for O1-T2) and keeps the fixture's resolution rate below
/// 100% while remaining above the 95% floor asserted by the test.
///
/// Sentence -> German gloss pairs, and the Hangul tokens each sentence
/// contributes (used by the test to compute the expected resolution ratio):
///   S1  안녕하세요.                -> Hallo.                          [안녕하세요]
///   S2  저는 학생이에요.           -> Ich bin Student.                [저는, 학생이에요]*
///   S3  오늘 학교에 가요.          -> Ich gehe heute zur Schule.      [오늘, 학교에, 가요]
///   S4  내일 친구를 만나요.        -> Ich treffe morgen einen Freund. [내일, 친구를, 만나요]
///   S5  책을 읽어요.               -> Ich lese ein Buch.              [책을, 읽어요]
///   S6  감사합니다.                -> Vielen Dank.                    [감사합니다]
///   S7  방이 작아요.               -> Das Zimmer ist klein.           [방이, 작아요]
///   S8  저는 집에 있어요.          -> Ich bin zu Hause.               [저는, 집에, 있어요]
///   S9  친구가 옷을 사요.          -> Ich kaufe Kleidung.             [친구가, 옷을, 사요]
///   S10 친구가 집에 와요.          -> Ich komme nach Hause.           [친구가, 집에, 와요]
/// (* = the one expected miss: 학생이에요)
BookOcrDocument buildF1TextbookPageDocument() {
  const pairs = <(String korean, String german)>[
    ('안녕하세요.', 'Hallo.'),
    ('저는 학생이에요.', 'Ich bin Student.'),
    ('오늘 학교에 가요.', 'Ich gehe heute zur Schule.'),
    ('내일 친구를 만나요.', 'Ich treffe morgen einen Freund.'),
    ('책을 읽어요.', 'Ich lese ein Buch.'),
    ('감사합니다.', 'Vielen Dank.'),
    ('방이 작아요.', 'Das Zimmer ist klein.'),
    ('저는 집에 있어요.', 'Ich bin zu Hause.'),
    ('친구가 옷을 사요.', 'Ich kaufe Kleidung.'),
    ('친구가 집에 와요.', 'Ich komme nach Hause.'),
  ];

  final lines = <BookOcrLine>[];
  for (var block = 0; block < pairs.length; block++) {
    final (korean, german) = pairs[block];
    final top = block * 80.0;
    lines.add(
      _line(text: korean, blockIndex: block, lineIndex: 0, top: top),
    );
    lines.add(
      _line(text: german, blockIndex: block, lineIndex: 1, top: top + 28),
    );
  }
  return BookOcrDocumentBuilder.build(lines);
}

/// Total Hangul tokens across [buildF1TextbookPageDocument] (see the table
/// above), and the one token the bundled/page-hint tiers cannot resolve in
/// this PR (an irregular copula form).
const int kF1TotalHangulTokens = 23;
const Set<String> kF1KnownMissTokens = {'학생이에요'};

/// F2 — particle-stripping and verb-ending cases named in the design:
///   학교에서 -> 학교, 친구를 -> 친구, 책은 -> 책 (noun + particle)
///   먹어요 -> 먹다, 가요 -> 가다, 봐요 -> 보다 (verb conjugation, incl.
///   the 봐 -> 보다 vowel-contraction fallback)
/// Each token is its own OCR line/block — deliberately minimal, no foreign
/// hints anywhere, so every resolution must come from the bundled tier.
BookOcrDocument buildF2ParticleAndVerbDocument() {
  const tokens = <String>['학교에서', '친구를', '책은', '먹어요', '가요', '봐요'];
  final lines = <BookOcrLine>[
    for (final (index, token) in tokens.indexed)
      _line(text: token, blockIndex: index, lineIndex: 0, top: index * 40.0),
  ];
  return BookOcrDocumentBuilder.build(lines);
}

/// F3 — page-hint tier behaviour.
///
/// Block 0: a made-up word absent from the bundled CSV (`콜라`) is
/// immediately followed, in the same OCR block, by a Latin-only line
/// (`Cola`) — this must resolve via `source: pageHint`.
///
/// Block 1: another CSV-absent word (`피자`) is followed by an unrelated
/// Korean sentence and only *then* a Latin line (`Pizza`) two lines away —
/// not the immediate next line — so it must NOT pick up a page hint.
BookOcrDocument buildF3PageHintDocument() {
  final lines = <BookOcrLine>[
    _line(text: '콜라', blockIndex: 0, lineIndex: 0, top: 0),
    _line(text: 'Cola', blockIndex: 0, lineIndex: 1, top: 28),
    _line(text: '피자', blockIndex: 1, lineIndex: 0, top: 120),
    _line(text: '맛있어요.', blockIndex: 1, lineIndex: 1, top: 148),
    _line(text: 'Pizza', blockIndex: 1, lineIndex: 2, top: 176),
  ];
  return BookOcrDocumentBuilder.build(lines);
}
