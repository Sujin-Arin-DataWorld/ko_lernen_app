/// Runtime paths for the approved Chaekgado visual system.
///
/// Keep this separate from the scenario shelf data: the same bookcase,
/// scroll, book clusters, and category vignettes are shared presentation
/// assets, not learning-content records.
library;

const String _chaekgadoAssetRoot = 'assets/hangul_sori_chaekgado_asset_pack_v1';

const String kChaekgadoBackplateTop =
    '$_chaekgadoAssetRoot/bookcase/slices/backplate/chaekgado_backplate_top.png';
const String kChaekgadoBackplateMiddle =
    '$_chaekgadoAssetRoot/bookcase/slices/backplate/chaekgado_backplate_middle.png';
const String kChaekgadoBackplateBottom =
    '$_chaekgadoAssetRoot/bookcase/slices/backplate/chaekgado_backplate_bottom.png';
const String kChaekgadoFrameTop =
    '$_chaekgadoAssetRoot/bookcase/slices/frame/chaekgado_frame_top.png';
const String kChaekgadoFrameMiddle =
    '$_chaekgadoAssetRoot/bookcase/slices/frame/chaekgado_frame_middle.png';
const String kChaekgadoFrameBottom =
    '$_chaekgadoAssetRoot/bookcase/slices/frame/chaekgado_frame_bottom.png';

const String kHoerenScrollTop =
    '$_chaekgadoAssetRoot/scroll/hoeren_scroll_top.png';
const String kHoerenScrollBody =
    '$_chaekgadoAssetRoot/scroll/hoeren_scroll_body_tile.png';
const String kHoerenScrollBottom =
    '$_chaekgadoAssetRoot/scroll/hoeren_scroll_bottom.png';
const String kHoerenScrollShortCard =
    '$_chaekgadoAssetRoot/scroll/hoeren_scroll_short_card.png';

const List<String> kChaekgadoBookClusters = [
  '$_chaekgadoAssetRoot/books/transparent/books_cluster_01.png',
  '$_chaekgadoAssetRoot/books/transparent/books_cluster_02.png',
  '$_chaekgadoAssetRoot/books/transparent/books_cluster_03.png',
  '$_chaekgadoAssetRoot/books/transparent/books_cluster_04.png',
  '$_chaekgadoAssetRoot/books/transparent/books_cluster_05.png',
  '$_chaekgadoAssetRoot/books/transparent/books_cluster_06.png',
];

String chaekgadoBookClusterAsset(int index) =>
    kChaekgadoBookClusters[index % kChaekgadoBookClusters.length];

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
