import 'learner_level.dart';
import 'personal_room.dart';
import 'room_layout.dart';

enum HanokGrowthEra {
  build,
  live,
  connect,
  share,
  care,
  transmit;

  String get code => name;

  static HanokGrowthEra? fromCode(String value) {
    for (final era in values) {
      if (era.code == value) {
        return era;
      }
    }
    return null;
  }

  static HanokGrowthEra fromLevel(LearnerLevel level) => switch (level) {
    LearnerLevel.a1 => HanokGrowthEra.build,
    LearnerLevel.a2 => HanokGrowthEra.live,
    LearnerLevel.b1 => HanokGrowthEra.connect,
    LearnerLevel.b2 => HanokGrowthEra.share,
    LearnerLevel.c1 => HanokGrowthEra.care,
    LearnerLevel.c2 => HanokGrowthEra.transmit,
  };
}

enum HanokGrantKind {
  constructionPiece,
  designOption,
  venue,
  ambience,
  credential;

  String get code => name;

  static HanokGrantKind? fromCode(String value) {
    for (final kind in values) {
      if (kind.code == value) {
        return kind;
      }
    }
    return null;
  }
}

enum HanokDesignSlot {
  roofMaterial,
  roofForm,
  changho,
  door,
  wallFinish,
  signboard,
  courtyard,
  ambience,
  regionClimate;

  String get code => name;

  static HanokDesignSlot? fromCode(String value) {
    for (final slot in values) {
      if (slot.code == value) {
        return slot;
      }
    }
    return null;
  }
}

enum HanokOptionProvenance {
  commonResidential,
  contextPlausible,
  ceremonialImaginative;

  String get code => name;

  static HanokOptionProvenance? fromCode(String value) {
    for (final provenance in values) {
      if (provenance.code == value) {
        return provenance;
      }
    }
    return null;
  }
}

enum HanokWeatheringTier {
  fresh,
  livedIn,
  patina;

  String get code => name;
}

/// One immutable visual reward projected from one learner-denominator slot.
///
/// It contains no writable completion flag. CourseMastery evidence remains the
/// only authority that can make this definition learner-owned.
final class HanokGrantDefinition {
  HanokGrantDefinition({
    required this.id,
    required this.canDoSegmentId,
    required this.level,
    required this.era,
    required this.order,
    required this.kind,
    required this.designSlot,
    required this.optionProvenance,
    required Iterable<String> revealAssetIds,
    required Iterable<String> prerequisiteGrantIds,
    required this.userDescriptionKey,
    required this.venueSurface,
  }) : revealAssetIds = List.unmodifiable(revealAssetIds),
       prerequisiteGrantIds = List.unmodifiable(prerequisiteGrantIds);

  final String id;
  final String canDoSegmentId;
  final LearnerLevel level;
  final HanokGrowthEra era;
  final int order;
  final HanokGrantKind kind;
  final HanokDesignSlot? designSlot;
  final HanokOptionProvenance? optionProvenance;
  final List<String> revealAssetIds;
  final List<String> prerequisiteGrantIds;
  final String userDescriptionKey;
  final PersonalRoomSurface? venueSurface;
}

/// Per-device Lamport clock. Actor ID is the deterministic tie-breaker when
/// two offline devices select different values at the same counter.
final class HanokLwwClock implements Comparable<HanokLwwClock> {
  static const int maxCounter = 9007199254740991;

  const HanokLwwClock({required this.counter, required this.actorId});

  factory HanokLwwClock.fromJson(Map<String, dynamic> json) {
    _requireExactKeys(json, required: const {'counter', 'actorId'});
    final counter = json['counter'];
    final actorId = json['actorId'];
    if (counter is! int ||
        counter < 0 ||
        counter > maxCounter ||
        actorId is! String ||
        !_validStableId(actorId)) {
      throw const FormatException('Invalid Hanok LWW clock.');
    }
    return HanokLwwClock(counter: counter, actorId: actorId);
  }

  final int counter;
  final String actorId;

  HanokLwwClock next(String nextActorId) {
    if (!_validStableId(nextActorId) || counter >= maxCounter) {
      throw const FormatException('Invalid next Hanok LWW clock.');
    }
    return HanokLwwClock(counter: counter + 1, actorId: nextActorId);
  }

  @override
  int compareTo(HanokLwwClock other) {
    final byCounter = counter.compareTo(other.counter);
    if (byCounter != 0) {
      return byCounter;
    }
    return actorId.compareTo(other.actorId);
  }

  Map<String, dynamic> toJson() => {'counter': counter, 'actorId': actorId};
}

final class HanokLoadoutSelection {
  HanokLoadoutSelection({required this.grantId, required this.clock}) {
    if (!_validStableId(grantId)) {
      throw const FormatException('Invalid Hanok loadout grant ID.');
    }
  }

  factory HanokLoadoutSelection.fromJson(Map<String, dynamic> json) {
    _requireExactKeys(json, required: const {'grantId', 'clock'});
    final grantId = json['grantId'];
    final rawClock = json['clock'];
    if (grantId is! String || rawClock is! Map) {
      throw const FormatException('Invalid Hanok loadout selection.');
    }
    return HanokLoadoutSelection(
      grantId: grantId,
      clock: HanokLwwClock.fromJson(_stringMap(rawClock)),
    );
  }

  final String grantId;
  final HanokLwwClock clock;

  Map<String, dynamic> toJson() => {
    'grantId': grantId,
    'clock': clock.toJson(),
  };
}

final class HanokCareState {
  HanokCareState({
    required this.lastEligibleActivityAt,
    required this.vacationMode,
    required this.displayEnabled,
    required this.notificationsEnabled,
    required this.settingsClock,
    Iterable<String> notifiedTierIds = const [],
  }) : notifiedTierIds = Set.unmodifiable(_stableIdSet(notifiedTierIds)) {
    final activity = lastEligibleActivityAt;
    if (activity != null && (!_isStrictUtc(activity) || _isEpoch(activity))) {
      throw const FormatException('Hanok care activity must be strict UTC.');
    }
  }

  factory HanokCareState.fresh() => const HanokCareState._(
    lastEligibleActivityAt: null,
    vacationMode: false,
    displayEnabled: true,
    notificationsEnabled: false,
    settingsClock: HanokLwwClock(counter: 0, actorId: 'bootstrap'),
    notifiedTierIds: <String>{},
  );

  const HanokCareState._({
    required this.lastEligibleActivityAt,
    required this.vacationMode,
    required this.displayEnabled,
    required this.notificationsEnabled,
    required this.settingsClock,
    required this.notifiedTierIds,
  });

  factory HanokCareState.fromJson(Map<String, dynamic> json) {
    _requireExactKeys(
      json,
      required: const {
        'vacationMode',
        'displayEnabled',
        'notificationsEnabled',
        'settingsClock',
        'notifiedTierIds',
      },
      optional: const {'lastEligibleActivityAt'},
    );
    final rawActivity = json['lastEligibleActivityAt'];
    DateTime? activity;
    if (rawActivity != null) {
      if (rawActivity is! String || !rawActivity.endsWith('Z')) {
        throw const FormatException('Invalid Hanok care activity timestamp.');
      }
      activity = DateTime.tryParse(rawActivity);
      if (activity == null || !_isStrictUtc(activity) || _isEpoch(activity)) {
        throw const FormatException('Invalid Hanok care activity timestamp.');
      }
    }
    final vacationMode = json['vacationMode'];
    final displayEnabled = json['displayEnabled'];
    final notificationsEnabled = json['notificationsEnabled'];
    final rawClock = json['settingsClock'];
    final rawNotified = json['notifiedTierIds'] ?? const <Object>[];
    if (vacationMode is! bool ||
        displayEnabled is! bool ||
        notificationsEnabled is! bool ||
        rawClock is! Map ||
        rawNotified is! List) {
      throw const FormatException('Invalid Hanok care state.');
    }
    return HanokCareState(
      lastEligibleActivityAt: activity,
      vacationMode: vacationMode,
      displayEnabled: displayEnabled,
      notificationsEnabled: notificationsEnabled,
      settingsClock: HanokLwwClock.fromJson(_stringMap(rawClock)),
      notifiedTierIds: _stringIds(rawNotified, 'notifiedTierIds'),
    );
  }

  final DateTime? lastEligibleActivityAt;
  final bool vacationMode;
  final bool displayEnabled;
  final bool notificationsEnabled;
  final HanokLwwClock settingsClock;
  final Set<String> notifiedTierIds;

  HanokCareState copyWith({
    DateTime? lastEligibleActivityAt,
    bool clearLastEligibleActivityAt = false,
    bool? vacationMode,
    bool? displayEnabled,
    bool? notificationsEnabled,
    HanokLwwClock? settingsClock,
    Iterable<String>? notifiedTierIds,
  }) {
    final nextActivity = clearLastEligibleActivityAt
        ? null
        : (lastEligibleActivityAt ?? this.lastEligibleActivityAt);
    final startsNewCycle = nextActivity != this.lastEligibleActivityAt;
    return HanokCareState(
      lastEligibleActivityAt: nextActivity,
      vacationMode: vacationMode ?? this.vacationMode,
      displayEnabled: displayEnabled ?? this.displayEnabled,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      settingsClock: settingsClock ?? this.settingsClock,
      notifiedTierIds:
          notifiedTierIds ??
          (startsNewCycle ? const <String>{} : this.notifiedTierIds),
    );
  }

  static HanokCareState merge(HanokCareState left, HanokCareState right) {
    final settings = _selectCareSettings(left, right);
    final latestActivity = _latestUtc(
      left.lastEligibleActivityAt,
      right.lastEligibleActivityAt,
    );
    final notified = <String>{};
    if (left.lastEligibleActivityAt == latestActivity) {
      notified.addAll(left.notifiedTierIds);
    }
    if (right.lastEligibleActivityAt == latestActivity) {
      notified.addAll(right.notifiedTierIds);
    }
    return HanokCareState(
      lastEligibleActivityAt: latestActivity,
      vacationMode: settings.vacationMode,
      displayEnabled: settings.displayEnabled,
      notificationsEnabled: settings.notificationsEnabled,
      settingsClock: settings.settingsClock,
      notifiedTierIds: notified,
    );
  }

  HanokWeatheringTier weatheringAt(DateTime asOf) {
    if (!_isStrictUtc(asOf)) {
      throw const FormatException('Hanok care projection requires UTC.');
    }
    if (!displayEnabled || vacationMode || lastEligibleActivityAt == null) {
      return HanokWeatheringTier.fresh;
    }
    final elapsed = asOf.difference(lastEligibleActivityAt!);
    if (elapsed.isNegative || elapsed.inDays < 7) {
      return HanokWeatheringTier.fresh;
    }
    if (elapsed.inDays < 14) {
      return HanokWeatheringTier.livedIn;
    }
    return HanokWeatheringTier.patina;
  }

  Map<String, dynamic> toJson() => {
    if (lastEligibleActivityAt != null)
      'lastEligibleActivityAt': lastEligibleActivityAt!
          .toUtc()
          .toIso8601String(),
    'vacationMode': vacationMode,
    'displayEnabled': displayEnabled,
    'notificationsEnabled': notificationsEnabled,
    'settingsClock': settingsClock.toJson(),
    'notifiedTierIds': notifiedTierIds.toList()..sort(),
  };
}

/// Learner-owned presentation state. Earned grant IDs are deliberately absent:
/// they are recomputed from CourseMastery every time.
final class HanokState {
  static const int currentSchemaVersion = 1;
  static const int currentCutoverVersion = 2;

  HanokState({
    this.schemaVersion = currentSchemaVersion,
    required this.manifestVersion,
    required this.cutoverVersion,
    Iterable<String> seenRevealIds = const [],
    Map<String, HanokLoadoutSelection> activeLoadout = const {},
    required this.careState,
  }) : seenRevealIds = Set.unmodifiable(_stableIdSet(seenRevealIds)),
       activeLoadout = Map.unmodifiable(_validateLoadout(activeLoadout)) {
    if (schemaVersion != currentSchemaVersion ||
        !_validStableId(manifestVersion) ||
        cutoverVersion < 0 ||
        cutoverVersion > currentCutoverVersion) {
      throw const FormatException('Invalid Hanok state header.');
    }
  }

  factory HanokState.fresh({required String manifestVersion}) => HanokState(
    manifestVersion: manifestVersion,
    cutoverVersion: currentCutoverVersion,
    careState: HanokCareState.fresh(),
  );

  factory HanokState.fromJson(Map<String, dynamic> json) {
    _requireExactKeys(
      json,
      required: const {
        'schemaVersion',
        'manifestVersion',
        'cutoverVersion',
        'seenRevealIds',
        'activeLoadout',
        'careState',
      },
    );
    final schemaVersion = json['schemaVersion'];
    final manifestVersion = json['manifestVersion'];
    final cutoverVersion = json['cutoverVersion'];
    final rawSeen = json['seenRevealIds'];
    final rawLoadout = json['activeLoadout'];
    final rawCare = json['careState'];
    if (schemaVersion is! int ||
        manifestVersion is! String ||
        cutoverVersion is! int ||
        rawSeen is! List ||
        rawLoadout is! Map ||
        rawCare is! Map) {
      throw const FormatException('Invalid Hanok state.');
    }
    final loadout = <String, HanokLoadoutSelection>{};
    for (final entry in rawLoadout.entries) {
      if (entry.key is! String || entry.value is! Map) {
        throw const FormatException('Invalid Hanok loadout map.');
      }
      loadout[entry.key as String] = HanokLoadoutSelection.fromJson(
        _stringMap(entry.value as Map),
      );
    }
    return HanokState(
      schemaVersion: schemaVersion,
      manifestVersion: manifestVersion,
      cutoverVersion: cutoverVersion,
      seenRevealIds: _stringIds(rawSeen, 'seenRevealIds'),
      activeLoadout: loadout,
      careState: HanokCareState.fromJson(_stringMap(rawCare)),
    );
  }

  final int schemaVersion;
  final String manifestVersion;
  final int cutoverVersion;
  final Set<String> seenRevealIds;

  /// String keys preserve future slot IDs during older-client sync. Known UI
  /// consumers resolve them through [HanokDesignSlot.fromCode].
  final Map<String, HanokLoadoutSelection> activeLoadout;
  final HanokCareState careState;

  HanokState copyWith({
    String? manifestVersion,
    int? cutoverVersion,
    Iterable<String>? seenRevealIds,
    Map<String, HanokLoadoutSelection>? activeLoadout,
    HanokCareState? careState,
  }) => HanokState(
    schemaVersion: schemaVersion,
    manifestVersion: manifestVersion ?? this.manifestVersion,
    cutoverVersion: cutoverVersion ?? this.cutoverVersion,
    seenRevealIds: seenRevealIds ?? this.seenRevealIds,
    activeLoadout: activeLoadout ?? this.activeLoadout,
    careState: careState ?? this.careState,
  );

  static HanokState merge(HanokState left, HanokState right) {
    if (left.schemaVersion != right.schemaVersion) {
      throw const FormatException('Cannot merge different Hanok schemas.');
    }
    final slots = {...left.activeLoadout.keys, ...right.activeLoadout.keys};
    final loadout = <String, HanokLoadoutSelection>{};
    for (final slot in slots) {
      final local = left.activeLoadout[slot];
      final remote = right.activeLoadout[slot];
      if (local == null) {
        loadout[slot] = remote!;
      } else if (remote == null) {
        loadout[slot] = local;
      } else {
        loadout[slot] = _selectLoadout(local, remote);
      }
    }
    return HanokState(
      schemaVersion: left.schemaVersion,
      manifestVersion:
          left.manifestVersion.compareTo(right.manifestVersion) >= 0
          ? left.manifestVersion
          : right.manifestVersion,
      cutoverVersion: left.cutoverVersion >= right.cutoverVersion
          ? left.cutoverVersion
          : right.cutoverVersion,
      seenRevealIds: {...left.seenRevealIds, ...right.seenRevealIds},
      activeLoadout: loadout,
      careState: HanokCareState.merge(left.careState, right.careState),
    );
  }

  Map<String, dynamic> toJson() => {
    'schemaVersion': schemaVersion,
    'manifestVersion': manifestVersion,
    'cutoverVersion': cutoverVersion,
    'seenRevealIds': seenRevealIds.toList()..sort(),
    'activeLoadout': {
      for (final key in activeLoadout.keys.toList()..sort())
        key: activeLoadout[key]!.toJson(),
    },
    'careState': careState.toJson(),
  };
}

HanokLoadoutSelection _selectLoadout(
  HanokLoadoutSelection left,
  HanokLoadoutSelection right,
) {
  final clock = left.clock.compareTo(right.clock);
  if (clock != 0) {
    return clock > 0 ? left : right;
  }
  return left.grantId.compareTo(right.grantId) >= 0 ? left : right;
}

HanokCareState _selectCareSettings(HanokCareState left, HanokCareState right) {
  final clock = left.settingsClock.compareTo(right.settingsClock);
  if (clock != 0) {
    return clock > 0 ? left : right;
  }
  return _careSettingsKey(left).compareTo(_careSettingsKey(right)) >= 0
      ? left
      : right;
}

String _careSettingsKey(HanokCareState state) =>
    '${state.vacationMode ? 1 : 0}'
    '${state.displayEnabled ? 1 : 0}'
    '${state.notificationsEnabled ? 1 : 0}';

final class HanokTrackProgress {
  const HanokTrackProgress({
    required this.releaseTrackId,
    required this.earned,
    required this.total,
  });

  final String releaseTrackId;
  final int earned;
  final int total;
}

/// Non-mutating room-v3 partition for the current Hanok venue grants.
///
/// Locked-room items stay byte-for-byte present in [dormant]. Once the venue
/// is earned, the same item instances and z-order move to [active].
final class HanokRoomLayoutProjection {
  HanokRoomLayoutProjection({
    required RoomLayouts active,
    required RoomLayouts dormant,
  }) : active = _freezeRoomLayouts(active),
       dormant = _freezeRoomLayouts(dormant);

  final RoomLayouts active;
  final RoomLayouts dormant;
}

final class HanokExperienceProjection {
  HanokExperienceProjection({
    required Iterable<String> verifiedCanDoSegmentIds,
    required Iterable<String> reassessmentEligibleSegmentIds,
    required Iterable<HanokGrantDefinition> earnedGrants,
    required this.a1ConstructionStep,
    required this.currentEra,
    required Iterable<PersonalRoomSurface> openedVenues,
    required Map<HanokDesignSlot, List<HanokGrantDefinition>>
    availableDesignOptions,
    required Map<HanokDesignSlot, HanokGrantDefinition> activeLoadout,
    required this.weatheringTier,
    required this.nextGrant,
    required Iterable<HanokTrackProgress> trackProgress,
    required this.roomLayouts,
  }) : verifiedCanDoSegmentIds = Set.unmodifiable(verifiedCanDoSegmentIds),
       reassessmentEligibleSegmentIds = Set.unmodifiable(
         reassessmentEligibleSegmentIds,
       ),
       earnedGrants = List.unmodifiable(earnedGrants),
       openedVenues = Set.unmodifiable(openedVenues),
       availableDesignOptions = Map.unmodifiable({
         for (final entry in availableDesignOptions.entries)
           entry.key: List<HanokGrantDefinition>.unmodifiable(entry.value),
       }),
       activeLoadout = Map.unmodifiable(activeLoadout),
       trackProgress = List.unmodifiable(trackProgress);

  final Set<String> verifiedCanDoSegmentIds;
  final Set<String> reassessmentEligibleSegmentIds;
  final List<HanokGrantDefinition> earnedGrants;
  final int a1ConstructionStep;
  final HanokGrowthEra currentEra;
  final Set<PersonalRoomSurface> openedVenues;
  final Map<HanokDesignSlot, List<HanokGrantDefinition>> availableDesignOptions;
  final Map<HanokDesignSlot, HanokGrantDefinition> activeLoadout;
  final HanokWeatheringTier weatheringTier;
  final HanokGrantDefinition? nextGrant;
  final List<HanokTrackProgress> trackProgress;
  final HanokRoomLayoutProjection roomLayouts;

  Set<String> get earnedGrantIds =>
      Set.unmodifiable(earnedGrants.map((grant) => grant.id));
}

RoomLayouts _freezeRoomLayouts(RoomLayouts source) => Map.unmodifiable({
  for (final entry in source.entries)
    entry.key: List<RoomLayoutItem>.unmodifiable(entry.value),
});

final class HanokGrantReceipt {
  HanokGrantReceipt({
    required this.sourceCourseUnitId,
    required this.sourceCanDoSegmentId,
    required Iterable<String> newGrantIds,
    required Iterable<String> revealAssetIds,
    required this.earnedExpressionKey,
    required this.evidenceId,
  }) : newGrantIds = List.unmodifiable(newGrantIds),
       revealAssetIds = List.unmodifiable(revealAssetIds);

  final String sourceCourseUnitId;
  final String sourceCanDoSegmentId;
  final List<String> newGrantIds;
  final List<String> revealAssetIds;
  final String earnedExpressionKey;
  final String evidenceId;
}

Map<String, HanokLoadoutSelection> _validateLoadout(
  Map<String, HanokLoadoutSelection> source,
) {
  final result = <String, HanokLoadoutSelection>{};
  for (final entry in source.entries) {
    if (!_validStableId(entry.key)) {
      throw const FormatException('Invalid Hanok loadout slot ID.');
    }
    result[entry.key] = entry.value;
  }
  return result;
}

Set<String> _stableIdSet(Iterable<String> values) {
  final result = <String>{};
  for (final value in values) {
    if (!_validStableId(value) || !result.add(value)) {
      throw const FormatException('Invalid or duplicate Hanok ID.');
    }
  }
  return result;
}

List<String> _stringIds(List values, String field) {
  final result = <String>[];
  for (final value in values) {
    if (value is! String || !_validStableId(value) || result.contains(value)) {
      throw FormatException('Invalid $field.');
    }
    result.add(value);
  }
  return result;
}

bool _validStableId(String value) =>
    value.isNotEmpty &&
    value.length <= 160 &&
    RegExp(r'^[A-Za-z0-9_.:-]+$').hasMatch(value);

Map<String, dynamic> _stringMap(Map source) {
  final result = <String, dynamic>{};
  for (final entry in source.entries) {
    final key = entry.key;
    if (key is! String || result.containsKey(key)) {
      throw const FormatException('Hanok JSON keys must be unique strings.');
    }
    result[key] = entry.value;
  }
  return result;
}

void _requireExactKeys(
  Map<String, dynamic> value, {
  required Set<String> required,
  Set<String> optional = const {},
}) {
  final keys = value.keys.toSet();
  if (!keys.containsAll(required) ||
      keys.any((key) => !required.contains(key) && !optional.contains(key))) {
    throw const FormatException('Hanok JSON has missing or unknown fields.');
  }
}

bool _isStrictUtc(DateTime value) => value.isUtc;

bool _isEpoch(DateTime value) => value.millisecondsSinceEpoch == 0;

DateTime? _latestUtc(DateTime? left, DateTime? right) {
  if (left == null) {
    return right;
  }
  if (right == null) {
    return left;
  }
  return left.isAfter(right) ? left : right;
}
