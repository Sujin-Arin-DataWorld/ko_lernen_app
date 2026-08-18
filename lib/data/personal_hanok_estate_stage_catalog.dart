/// Reveal-asset lookup for the B1–C2 estate `constructionPiece` grants
/// (Phase 1 PR-A, `tools/content_factory/drafts/hanok_grants.json`).
///
/// The 86-grant system is still dark (`publishedGrants: []` — see
/// AGENTS.md's Hanok section); nothing in `lib/` renders through this table
/// yet. It exists now for two reasons:
///
/// 1. The 14 promoted stage PNGs
///    (`assets/illustrations/personal_hanok_v2/map/stages/`, declared in
///    `pubspec.yaml`) need a literal reference somewhere in `lib/` or
///    `test/asset_orphan_guard_test.dart` flags them as dead weight in the
///    bundle.
/// 2. Phase 1 PR-C's renderer needs a `revealAssetId -> asset path` resolver
///    for the alpha-ramp mechanism. This is that resolver, built once instead
///    of twice.
///
/// Scope: only the 6 buildings whose stage art already exists (sotdaeulmun,
/// haengrangchae, anchae, daecheongmaru, sadang, rear_garden). 우물·별당·서고
/// (Phase 3, unbuilt) are deliberately absent — listing them before the art
/// exists would be a dead reference to a file that doesn't exist yet.
///
/// Each building's `*_final` entry aliases the existing
/// `map/structures/*.png` / `map/landscape/rear_garden.png` file byte-for-byte
/// (see `docs/assets/hanok_estate_kit/*_stages_ledger.json`) — it is not a
/// new asset, which is why it was intentionally excluded from the
/// `map/stages/` promotion (see the comment on that pubspec.yaml line).
const kPersonalHanokEstateStageAssets = <String, String>{
  'hanok_estate_sotdaeulmun_s1_platform':
      'assets/illustrations/personal_hanok_v2/map/stages/sotdaeulmun_s1_platform.png',
  'hanok_estate_sotdaeulmun_s2_frame_roof':
      'assets/illustrations/personal_hanok_v2/map/stages/sotdaeulmun_s2_frame_roof.png',
  'hanok_estate_sotdaeulmun_s3_final':
      'assets/illustrations/personal_hanok_v2/map/structures/sotdaeulmun.png',

  'hanok_estate_haengrangchae_s1_foundation':
      'assets/illustrations/personal_hanok_v2/map/stages/haengrangchae_s1_foundation.png',
  'hanok_estate_haengrangchae_s2_frame':
      'assets/illustrations/personal_hanok_v2/map/stages/haengrangchae_s2_frame.png',
  'hanok_estate_haengrangchae_s3_roof':
      'assets/illustrations/personal_hanok_v2/map/stages/haengrangchae_s3_roof.png',
  'hanok_estate_haengrangchae_s4_final':
      'assets/illustrations/personal_hanok_v2/map/structures/haengrangchae.png',

  'hanok_estate_anchae_s1_platform':
      'assets/illustrations/personal_hanok_v2/map/stages/anchae_s1_platform.png',
  'hanok_estate_anchae_s2_frame':
      'assets/illustrations/personal_hanok_v2/map/stages/anchae_s2_frame.png',
  'hanok_estate_anchae_s3_roof':
      'assets/illustrations/personal_hanok_v2/map/stages/anchae_s3_roof.png',
  'hanok_estate_anchae_s4_final':
      'assets/illustrations/personal_hanok_v2/map/structures/anchae.png',

  'hanok_estate_daecheongmaru_s1_platform':
      'assets/illustrations/personal_hanok_v2/map/stages/daecheongmaru_s1_platform.png',
  'hanok_estate_daecheongmaru_s2_frame':
      'assets/illustrations/personal_hanok_v2/map/stages/daecheongmaru_s2_frame.png',
  'hanok_estate_daecheongmaru_s3_final':
      'assets/illustrations/personal_hanok_v2/map/structures/daecheongmaru.png',

  'hanok_estate_sadang_s1_platform':
      'assets/illustrations/personal_hanok_v2/map/stages/sadang_s1_platform.png',
  'hanok_estate_sadang_s2_frame_roof':
      'assets/illustrations/personal_hanok_v2/map/stages/sadang_s2_frame_roof.png',
  'hanok_estate_sadang_s3_final':
      'assets/illustrations/personal_hanok_v2/map/structures/sadang.png',

  'hanok_estate_rear_garden_s1_hardscape':
      'assets/illustrations/personal_hanok_v2/map/stages/rear_garden_s1_hardscape.png',
  'hanok_estate_rear_garden_s2_bridge':
      'assets/illustrations/personal_hanok_v2/map/stages/rear_garden_s2_bridge.png',
  'hanok_estate_rear_garden_s3_final':
      'assets/illustrations/personal_hanok_v2/map/landscape/rear_garden.png',
};
