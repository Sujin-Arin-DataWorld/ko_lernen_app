import '../models/personal_hanok.dart';

/// The only asset root the personal estate is allowed to use.
const kPersonalHanokAssetRoot = 'assets/illustrations/personal_hanok_v2/';

/// A fixed-canvas art layer. The renderer chooses it solely from the pure
/// [PersonalHanokProjection]; this metadata never owns progress or storage.
class PersonalHanokMapLayer {
  final String id;
  final String assetPath;
  final int zIndex;
  final PersonalHanokMilestone? milestone;
  final bool opaque;

  const PersonalHanokMapLayer({
    required this.id,
    required this.assetPath,
    required this.zIndex,
    this.milestone,
    this.opaque = false,
  });
}

/// Semantic interaction area, intentionally independent from paint bounds.
class PersonalHanokZoneDefinition {
  final PersonalHanokZone zone;
  final PersonalHanokRect bounds;
  final PersonalHanokMilestone? requires;
  final bool isInteractive;

  const PersonalHanokZoneDefinition({
    required this.zone,
    required this.bounds,
    this.requires,
    this.isInteractive = true,
  });
}

const kPersonalHanokLayers = <PersonalHanokMapLayer>[
  PersonalHanokMapLayer(
    id: 'site_base',
    assetPath: '${kPersonalHanokAssetRoot}map/site_base_light.png',
    zIndex: 0,
    opaque: true,
  ),
  PersonalHanokMapLayer(
    id: 'rear_garden',
    assetPath: '${kPersonalHanokAssetRoot}map/landscape/rear_garden.png',
    zIndex: 11,
    milestone: PersonalHanokMilestone.rearGarden,
  ),
  PersonalHanokMapLayer(
    id: 'sotdaeulmun',
    assetPath: '${kPersonalHanokAssetRoot}map/structures/sotdaeulmun.png',
    zIndex: 20,
    milestone: PersonalHanokMilestone.sotdaeulmun,
  ),
  PersonalHanokMapLayer(
    id: 'haengrangchae',
    assetPath: '${kPersonalHanokAssetRoot}map/structures/haengrangchae.png',
    zIndex: 21,
    milestone: PersonalHanokMilestone.haengrangchae,
  ),
  PersonalHanokMapLayer(
    id: 'sarangchae',
    assetPath: '${kPersonalHanokAssetRoot}map/structures/sarangchae.png',
    zIndex: 22,
    milestone: PersonalHanokMilestone.sarangchae,
  ),
  PersonalHanokMapLayer(
    id: 'anchae',
    assetPath: '${kPersonalHanokAssetRoot}map/structures/anchae.png',
    zIndex: 23,
    milestone: PersonalHanokMilestone.anchae,
  ),
  PersonalHanokMapLayer(
    id: 'daecheongmaru',
    assetPath: '${kPersonalHanokAssetRoot}map/structures/daecheongmaru.png',
    zIndex: 24,
    milestone: PersonalHanokMilestone.daecheongmaru,
  ),
  PersonalHanokMapLayer(
    id: 'sadang',
    assetPath: '${kPersonalHanokAssetRoot}map/structures/sadang.png',
    zIndex: 25,
    milestone: PersonalHanokMilestone.sadang,
  ),
];

const kPersonalHanokZones = <PersonalHanokZoneDefinition>[
  PersonalHanokZoneDefinition(
    zone: PersonalHanokZone.sarangbang,
    bounds: PersonalHanokRect(left: .14, top: .61, width: .52, height: .21),
    requires: PersonalHanokMilestone.sarangchae,
  ),
  PersonalHanokZoneDefinition(
    zone: PersonalHanokZone.daecheongmaru,
    bounds: PersonalHanokRect(left: .44, top: .27, width: .17, height: .14),
    requires: PersonalHanokMilestone.daecheongmaru,
  ),
  PersonalHanokZoneDefinition(
    zone: PersonalHanokZone.haengrangchae,
    bounds: PersonalHanokRect(left: .39, top: .81, width: .42, height: .12),
    requires: PersonalHanokMilestone.haengrangchae,
  ),
  PersonalHanokZoneDefinition(
    zone: PersonalHanokZone.anchae,
    bounds: PersonalHanokRect(left: .28, top: .24, width: .42, height: .33),
    requires: PersonalHanokMilestone.anchae,
  ),
  PersonalHanokZoneDefinition(
    zone: PersonalHanokZone.huwon,
    bounds: PersonalHanokRect(left: .07, top: .05, width: .55, height: .48),
    requires: PersonalHanokMilestone.rearGarden,
  ),
  PersonalHanokZoneDefinition(
    zone: PersonalHanokZone.sadang,
    bounds: PersonalHanokRect(left: .76, top: .29, width: .19, height: .31),
    requires: PersonalHanokMilestone.sadang,
  ),
  PersonalHanokZoneDefinition(
    zone: PersonalHanokZone.gyeRoad,
    bounds: PersonalHanokRect(left: .86, top: .70, width: .14, height: .25),
    isInteractive: false,
  ),
];

PersonalHanokMapLayer layerForMilestone(PersonalHanokMilestone milestone) {
  return kPersonalHanokLayers.firstWhere((layer) => layer.milestone == milestone);
}

PersonalHanokZoneDefinition zoneFor(PersonalHanokZone zone) {
  return kPersonalHanokZones.firstWhere((definition) => definition.zone == zone);
}
