import '../models/scenario.dart';

/// Converts the legacy stored level code into the canonical CEFR value used by
/// JSON bundles and level-picker UI.
///
/// Storage persists lower-case codes (`a1`…`b2`), while the content bundles
/// and the game-level controls use the display spelling (`A1`…`B2`). Keeping
/// this conversion here prevents a lower-case stored value from producing an
/// empty exact-match deck.
LearnerLevel learnerLevelForStoredCode(String? code) =>
    LearnerLevel.fromCode(code) ?? LearnerLevel.a1;

String learnerLevelDisplayForStoredCode(String? code) =>
    learnerLevelForStoredCode(code).display;
