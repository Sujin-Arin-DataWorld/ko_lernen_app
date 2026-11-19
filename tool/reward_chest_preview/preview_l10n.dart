import 'package:ko_lernen_app/l10n/generated/app_localizations.dart';

/// Copy used only by this standalone preview. It stays out of the app ARB
/// files so the shipped app gains no unused strings (ARB orphan ratchet).
extension RewardChestPreviewL10n on AppL10n {
  bool get _en => localeName.startsWith('en');

  /// Eyebrow above a newly unlocked decoration.
  String get rewardChestNewDecoration =>
      _en ? 'New decoration' : 'Neue Dekoration';

  /// Current learning XP total, not an additional reward from the chest.
  String get rewardChestLearningXp =>
      _en ? 'Your learning XP' : 'Deine Lern-XP';

  String get rewardChestCulturalStory =>
      _en ? 'The story behind it' : 'Die Geschichte dahinter';

  String get rewardChestPlaceSarangbang =>
      _en ? 'Place in Sarangbang' : 'Im Sarangbang platzieren';

  String get rewardChestPreviewTitle =>
      _en ? 'Mother-of-pearl chest · Preview' : 'Perlmutt-Truhe · Vorschau';

  String get rewardChestReplay => _en ? 'Watch again' : 'Noch einmal ansehen';

  String get rewardChestPreviewPlacement => _en
      ? 'Preview: In the app, you can place this piece in your Sarangbang.'
      : 'Vorschau: In der App platzierst du dieses Stück in deinem Sarangbang.';
}
