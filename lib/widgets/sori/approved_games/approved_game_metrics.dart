/// Measurements taken from the approved game reference art.
///
/// These values sit off the 4-pt spacing grid on purpose: the painted game
/// assets were drawn at these offsets and sizes, so rounding them to the grid
/// would visibly misalign art, text and touch surfaces. Values that match an
/// existing house token use `Spacing` or `SoriRadius` instead.
abstract final class ApprovedGameMetrics {
  /// Settings gear artwork in the approved game header.
  static const double gearArt = 28;

  /// Back chevron artwork in the shared approved game frame.
  static const double frameBackArtWidth = 12;
  static const double frameBackArtHeight = 19;

  /// Back chevron artwork in the word-chain header.
  static const double chainBackArtWidth = 18;
  static const double chainBackArtHeight = 28;

  /// Corner radius of the soft shadow plate under approved material panels.
  static const double materialShadowRadius = 15;

  /// Corner radius of approved art buttons and their focus ring.
  static const double artButtonRadius = 13;

  /// Corner radius of the Silben card back face.
  static const double silbenBackFaceRadius = 14;

  /// Corner radius of Silben board cells and pool tiles.
  static const double silbenCellRadius = 10;

  /// Top margin that seats the Silben action pill on its wooden rail.
  static const double silbenPillTop = 13;

  /// Horizontal inset of the Silben clue list.
  static const double silbenClueInset = 17;

  /// Leading space that keeps the hint label clear of the lamp artwork.
  static const double silbenHintLead = 22;

  /// Hairline gap between the clue list and the Silben board.
  static const double silbenBoardGap = 1;

  /// Gap between a clue's direction icon and its text.
  static const double silbenClueIconGap = 9;
}
