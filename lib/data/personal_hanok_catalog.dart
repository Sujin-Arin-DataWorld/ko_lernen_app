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

  /// Painted alpha bounds on the fixed 1536 × 1152 master canvas.
  ///
  /// These are intentionally independent from a place's tap target. They
  /// make the art-coordinate contract explicit for focus/reveal work while
  /// allowing accessibility targets to remain a comfortable 44dp minimum.
  final PersonalHanokRect? visualBounds;
  final bool opaque;

  const PersonalHanokMapLayer({
    required this.id,
    required this.assetPath,
    required this.zIndex,
    this.milestone,
    this.visualBounds,
    this.opaque = false,
  });
}

/// Semantic interaction area, intentionally independent from paint bounds.
class PersonalHanokZoneDefinition {
  final PersonalHanokZone zone;

  /// Broad visual bounds used by a future selected-place viewport.
  final PersonalHanokRect bounds;

  /// One or more precise, non-overlapping hit regions on the fixed map.
  ///
  /// A Hanok can have separated wings, so a single large rectangular target
  /// would make one place intercept another. These regions intentionally
  /// follow the physical building/landscape pieces instead.
  final List<PersonalHanokRect> hitRegions;
  final PersonalHanokMilestone? requires;
  final bool isInteractive;

  const PersonalHanokZoneDefinition({
    required this.zone,
    required this.bounds,
    required this.hitRegions,
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
    visualBounds: PersonalHanokRect(
      left: .013,
      top: .091,
      width: .973,
      height: .454,
    ),
  ),
  PersonalHanokMapLayer(
    id: 'sotdaeulmun',
    assetPath: '${kPersonalHanokAssetRoot}map/structures/sotdaeulmun.png',
    zIndex: 20,
    milestone: PersonalHanokMilestone.sotdaeulmun,
    visualBounds: PersonalHanokRect(
      left: .389,
      top: .759,
      width: .223,
      height: .180,
    ),
  ),
  PersonalHanokMapLayer(
    id: 'haengrangchae',
    assetPath: '${kPersonalHanokAssetRoot}map/structures/haengrangchae.png',
    zIndex: 21,
    milestone: PersonalHanokMilestone.haengrangchae,
    visualBounds: PersonalHanokRect(
      left: .163,
      top: .743,
      width: .278,
      height: .155,
    ),
  ),
  PersonalHanokMapLayer(
    id: 'sarangchae',
    assetPath: '${kPersonalHanokAssetRoot}map/structures/sarangchae.png',
    zIndex: 22,
    milestone: PersonalHanokMilestone.sarangchae,
    visualBounds: PersonalHanokRect(
      left: .104,
      top: .533,
      width: .556,
      height: .268,
    ),
  ),
  PersonalHanokMapLayer(
    id: 'anchae',
    assetPath: '${kPersonalHanokAssetRoot}map/structures/anchae.png',
    zIndex: 23,
    milestone: PersonalHanokMilestone.anchae,
    visualBounds: PersonalHanokRect(
      left: .262,
      top: .258,
      width: .455,
      height: .294,
    ),
  ),
  PersonalHanokMapLayer(
    id: 'daecheongmaru',
    assetPath: '${kPersonalHanokAssetRoot}map/structures/daecheongmaru.png',
    zIndex: 24,
    milestone: PersonalHanokMilestone.daecheongmaru,
    visualBounds: PersonalHanokRect(
      left: .449,
      top: .303,
      width: .113,
      height: .125,
    ),
  ),
  PersonalHanokMapLayer(
    id: 'sadang',
    assetPath: '${kPersonalHanokAssetRoot}map/structures/sadang.png',
    zIndex: 25,
    milestone: PersonalHanokMilestone.sadang,
    visualBounds: PersonalHanokRect(
      left: .779,
      top: .298,
      width: .131,
      height: .203,
    ),
  ),
];

const kPersonalHanokZones = <PersonalHanokZoneDefinition>[
  PersonalHanokZoneDefinition(
    zone: PersonalHanokZone.sarangbang,
    bounds: PersonalHanokRect(left: .10, top: .53, width: .56, height: .27),
    hitRegions: <PersonalHanokRect>[
      // Leave room for the 44dp haengrang target at compact map heights.
      PersonalHanokRect(left: .15, top: .60, width: .49, height: .14),
    ],
    requires: PersonalHanokMilestone.sarangchae,
  ),
  PersonalHanokZoneDefinition(
    zone: PersonalHanokZone.daecheongmaru,
    bounds: PersonalHanokRect(left: .44, top: .30, width: .13, height: .13),
    hitRegions: <PersonalHanokRect>[
      PersonalHanokRect(left: .43, top: .31, width: .14, height: .11),
    ],
    requires: PersonalHanokMilestone.daecheongmaru,
  ),
  PersonalHanokZoneDefinition(
    zone: PersonalHanokZone.haengrangchae,
    bounds: PersonalHanokRect(left: .16, top: .74, width: .28, height: .16),
    hitRegions: <PersonalHanokRect>[
      // The building begins directly below the Sarangchae facade. This keeps
      // its compact 44dp target below that facade instead of intercepting a
      // Sarangbang tap near the center of the map.
      PersonalHanokRect(left: .17, top: .80, width: .26, height: .09),
    ],
    requires: PersonalHanokMilestone.haengrangchae,
  ),
  PersonalHanokZoneDefinition(
    zone: PersonalHanokZone.anchae,
    bounds: PersonalHanokRect(left: .26, top: .25, width: .46, height: .30),
    hitRegions: <PersonalHanokRect>[
      PersonalHanokRect(left: .26, top: .32, width: .13, height: .20),
      PersonalHanokRect(left: .64, top: .32, width: .09, height: .20),
    ],
    requires: PersonalHanokMilestone.anchae,
  ),
  PersonalHanokZoneDefinition(
    zone: PersonalHanokZone.huwon,
    bounds: PersonalHanokRect(left: .01, top: .09, width: .98, height: .46),
    hitRegions: <PersonalHanokRect>[
      PersonalHanokRect(left: .20, top: .12, width: .21, height: .16),
      PersonalHanokRect(left: .08, top: .31, width: .17, height: .20),
    ],
    requires: PersonalHanokMilestone.rearGarden,
  ),
  PersonalHanokZoneDefinition(
    zone: PersonalHanokZone.sadang,
    bounds: PersonalHanokRect(left: .78, top: .30, width: .13, height: .20),
    hitRegions: <PersonalHanokRect>[
      PersonalHanokRect(left: .79, top: .32, width: .12, height: .18),
    ],
    requires: PersonalHanokMilestone.sadang,
  ),
  PersonalHanokZoneDefinition(
    zone: PersonalHanokZone.gyeRoad,
    bounds: PersonalHanokRect(left: .86, top: .70, width: .14, height: .25),
    hitRegions: <PersonalHanokRect>[
      PersonalHanokRect(left: .86, top: .70, width: .14, height: .25),
    ],
    isInteractive: false,
  ),
];

/// Returns only the personal places that are built and can be opened now.
///
/// The map, accessible place list, and future focused viewport share this
/// predicate so their affordances cannot drift apart.
Iterable<PersonalHanokZoneDefinition> visiblePersonalHanokZones(
  PersonalHanokProjection projection,
) => kPersonalHanokZones.where((definition) {
  final required = definition.requires;
  return definition.isInteractive &&
      required != null &&
      projection.isUnlocked(required);
});

PersonalHanokMapLayer layerForMilestone(PersonalHanokMilestone milestone) {
  return kPersonalHanokLayers.firstWhere(
    (layer) => layer.milestone == milestone,
  );
}

PersonalHanokZoneDefinition zoneFor(PersonalHanokZone zone) {
  return kPersonalHanokZones.firstWhere(
    (definition) => definition.zone == zone,
  );
}
