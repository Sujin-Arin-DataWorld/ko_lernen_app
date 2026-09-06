/// Runtime paths for the approved Chaekgado visual system.
///
/// Keep this separate from the scenario shelf data: the card art, scroll rod,
/// and category vignettes are shared presentation assets, not
/// learning-content records.
///
/// W10 T-H4 (Jin 결정 D-2): the bookcase/book-cluster/scroll-body/
/// scroll-bottom constants that only the old shelf (`ChaekgadoShelfCase`) and
/// scroll sheet (`ChaekgadoScroll`) used were removed here when those widgets
/// moved to `assets_unused/retired_code/`.
///
/// W10 PR-C F3 (2026-09-06): `kHoerenScrollShortCard` had no remaining
/// caller in `lib/` or `test/` (T-H4's note that the category list screen
/// still called it was stale) — removed here, and its PNG moved to
/// `assets_unused/hangul_sori_chaekgado_asset_pack_v1/scroll/`.
library;

const String _chaekgadoAssetRoot = 'assets/hangul_sori_chaekgado_asset_pack_v1';

/// 듣기 카드 아트 — `assets/illustrations/listening/{imageKey}.webp`.
///
/// 칸 = 정물 한 점(08-19 §3-①). 같은 50여 장이 선반 칸과 두루마리 머리에
/// 같이 쓰인다. imageKey 정본은 `lib/data/chaekgado_shelf.dart` 의
/// `ChaekgadoSlot.imageKey` (= `docs/LISTENING_CARD_ART_SPEC.md` 의 키).
/// 파일이 없는 키는 부르는 쪽 `errorBuilder` 가 비네트→책더미로 내려간다.
const String kListeningCardArtDir = 'assets/illustrations/listening/';

String chaekgadoCardAsset(String imageKey) =>
    '$kListeningCardArtDir$imageKey.webp';

const String kHoerenScrollTop =
    '$_chaekgadoAssetRoot/scroll/hoeren_scroll_top.png';

const Map<String, String> _categoryVignettes = {
  'transit': 'vignette_01_transport.png',
  'taxi_stay': 'vignette_02_travel_lodging.png',
  'move': 'vignette_02_travel_lodging.png',
  'travel': 'vignette_02_travel_lodging.png',
  'delay': 'vignette_02_travel_lodging.png',
  'counter': 'vignette_03_shopping.png',
  'buy': 'vignette_03_shopping.png',
  'refund': 'vignette_03_shopping.png',
  'eat': 'vignette_04_cafe_food.png',
  'home': 'vignette_05_home_door.png',
  'apt': 'vignette_08_neighbors_housing.png',
  'neighbor': 'vignette_08_neighbors_housing.png',
  'greet': 'vignette_06_greeting_introduction.png',
  'body': 'vignette_07_health_sport.png',
  'health': 'vignette_07_health_sport.png',
  'insurance': 'vignette_07_health_sport.png',
  'partner': 'vignette_09_family_boundaries.png',
  'feel': 'vignette_09_family_boundaries.png',
  'meeting': 'vignette_10_evaluation_interview.png',
  'evidence': 'vignette_10_evaluation_interview.png',
  'form': 'vignette_10_evaluation_interview.png',
  'hiring': 'vignette_10_evaluation_interview.png',
  'authorities': 'vignette_11_authorities_permits.png',
  'enrolment': 'vignette_11_authorities_permits.png',
  'notice': 'vignette_11_authorities_permits.png',
  'public': 'vignette_11_authorities_permits.png',
  'privacy': 'vignette_12_data_consent.png',
  'friends': 'vignette_13_friends_gaming.png',
  'dating': 'vignette_14_dating_relationship.png',
  'fandom': 'vignette_15_fandom_video.png',
};

/// Returns null for C1/C2 concepts without a concrete supplied vignette.
/// Those compartments intentionally keep the book cluster only rather than
/// pretending that an unrelated object represents an abstract topic.
String? chaekgadoCategoryVignetteAsset(String slug) {
  final filename = _categoryVignettes[slug];
  return filename == null
      ? null
      : '$_chaekgadoAssetRoot/categories/transparent/$filename';
}
