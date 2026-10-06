/// Jin's October 4 canonical family. Selection and speech IDs stay unchanged.
/// Full body for introductions, inward-facing guides for explanations and
/// dedicated portraits for small slots. Source bytes are locked in the manifest.
abstract final class CompanionArt {
  static const root = 'assets/illustrations/companions/canonical';
  static const taego = '$root/taego.png';
  static const taegoGuide = '$root/taego_guide.png';
  static const taegoSeated = '$root/taego_seated.png';
  static const taegoPortrait = '$root/taego_portrait.png';
  static const joy = '$root/joy.png';
  static const joyGuide = '$root/joy_guide.png';
  static const joyCelebrate = '$root/joy_celebrate.png';
  static const joyPortrait = '$root/joy_portrait.png';
  static const dokkaebi = 'assets/illustrations/tactile/dokkaebi.png';
  static const scholar = 'assets/illustrations/tactile/hahoe_scholar.png';
  static const mintVideo = 'assets/video/rewards/making_money.mp4';
  static const mintPoster = '$root/making_money_poster.png';

  static String fullBody(String id) => id == 'magpie' ? joy : taego;
  static String portrait(String id) =>
      id == 'magpie' ? joyPortrait : taegoPortrait;
  static String guide(String id) => id == 'magpie' ? joyGuide : taegoGuide;

  /// Compatibility boundary for retired companion media. These legacy IDs
  /// never reach the video decoder; their callers retain navigation callbacks.
  static String? forRetiredClip(String asset, {required double size}) {
    if (!asset.startsWith('assets/video/character/') &&
        !asset.startsWith('assets/video/home_hero/')) {
      return null;
    }
    final magpie = asset.split('/').last.startsWith('magpie_');
    if (size <= 64) {
      return portrait(magpie ? 'magpie' : 'tiger');
    }
    if (magpie) {
      return asset.contains('celebrate') ? joyCelebrate : joy;
    }
    return asset.contains('sitting') || asset.contains('rest')
        ? taegoSeated
        : taego;
  }
}
