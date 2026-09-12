import 'hanok_growth.dart' show HanokWeatheringTier;

final class IlDuLwwClock implements Comparable<IlDuLwwClock> {
  static const int maxCounter = 9007199254740991;

  const IlDuLwwClock({required this.counter, required this.actorId});

  factory IlDuLwwClock.fromJson(Map<String, dynamic> json) {
    _requireExactKeys(json, required: const {'counter', 'actorId'});
    final counter = json['counter'];
    final actorId = json['actorId'];
    if (counter is! int ||
        counter < 0 ||
        counter > maxCounter ||
        actorId is! String ||
        !_validStableId(actorId)) {
      throw const FormatException('Invalid IlDu LWW clock.');
    }
    return IlDuLwwClock(counter: counter, actorId: actorId);
  }

  final int counter;
  final String actorId;

  IlDuLwwClock next(String nextActorId) {
    if (!_validStableId(nextActorId) || counter >= maxCounter) {
      throw const FormatException('Invalid next IlDu LWW clock.');
    }
    return IlDuLwwClock(counter: counter + 1, actorId: nextActorId);
  }

  @override
  int compareTo(IlDuLwwClock other) {
    final byCounter = counter.compareTo(other.counter);
    return byCounter != 0 ? byCounter : actorId.compareTo(other.actorId);
  }

  Map<String, dynamic> toJson() => {'counter': counter, 'actorId': actorId};
}

final class IlDuDesignSelection {
  IlDuDesignSelection({required this.grantId, required this.clock}) {
    if (!_validStableId(grantId)) {
      throw const FormatException('Invalid IlDu design grant ID.');
    }
  }

  factory IlDuDesignSelection.fromJson(Map<String, dynamic> json) {
    _requireExactKeys(json, required: const {'grantId', 'clock'});
    final grantId = json['grantId'];
    final rawClock = json['clock'];
    if (grantId is! String || rawClock is! Map) {
      throw const FormatException('Invalid IlDu design selection.');
    }
    return IlDuDesignSelection(
      grantId: grantId,
      clock: IlDuLwwClock.fromJson(_stringMap(rawClock)),
    );
  }

  final String grantId;
  final IlDuLwwClock clock;

  Map<String, dynamic> toJson() => {
    'grantId': grantId,
    'clock': clock.toJson(),
  };
}

final class IlDuCarePreferences {
  IlDuCarePreferences({
    required this.lastEligibleActivityAt,
    required this.vacationMode,
    required this.displayEnabled,
    required this.notificationsEnabled,
    required this.settingsClock,
    Iterable<String> notifiedTierIds = const [],
  }) : notifiedTierIds = Set.unmodifiable(_stableIdSet(notifiedTierIds)) {
    final activity = lastEligibleActivityAt;
    if (activity != null && (!_isStrictUtc(activity) || _isEpoch(activity))) {
      throw const FormatException('IlDu care activity must be strict UTC.');
    }
  }

  factory IlDuCarePreferences.fresh() => const IlDuCarePreferences._(
    lastEligibleActivityAt: null,
    vacationMode: false,
    displayEnabled: true,
    notificationsEnabled: false,
    settingsClock: IlDuLwwClock(counter: 0, actorId: 'bootstrap'),
    notifiedTierIds: <String>{},
  );

  const IlDuCarePreferences._({
    required this.lastEligibleActivityAt,
    required this.vacationMode,
    required this.displayEnabled,
    required this.notificationsEnabled,
    required this.settingsClock,
    required this.notifiedTierIds,
  });

  factory IlDuCarePreferences.fromJson(Map<String, dynamic> json) {
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
        throw const FormatException('Invalid IlDu care activity timestamp.');
      }
      activity = DateTime.tryParse(rawActivity);
      if (activity == null || !_isStrictUtc(activity) || _isEpoch(activity)) {
        throw const FormatException('Invalid IlDu care activity timestamp.');
      }
    }
    final vacationMode = json['vacationMode'];
    final displayEnabled = json['displayEnabled'];
    final notificationsEnabled = json['notificationsEnabled'];
    final rawClock = json['settingsClock'];
    final rawNotified = json['notifiedTierIds'];
    if (vacationMode is! bool ||
        displayEnabled is! bool ||
        notificationsEnabled is! bool ||
        rawClock is! Map ||
        rawNotified is! List) {
      throw const FormatException('Invalid IlDu care preferences.');
    }
    return IlDuCarePreferences(
      lastEligibleActivityAt: activity,
      vacationMode: vacationMode,
      displayEnabled: displayEnabled,
      notificationsEnabled: notificationsEnabled,
      settingsClock: IlDuLwwClock.fromJson(_stringMap(rawClock)),
      notifiedTierIds: _stringIds(rawNotified, 'notifiedTierIds'),
    );
  }

  final DateTime? lastEligibleActivityAt;
  final bool vacationMode;
  final bool displayEnabled;
  final bool notificationsEnabled;
  final IlDuLwwClock settingsClock;
  final Set<String> notifiedTierIds;

  IlDuCarePreferences copyWith({
    DateTime? lastEligibleActivityAt,
    bool clearLastEligibleActivityAt = false,
    bool? vacationMode,
    bool? displayEnabled,
    bool? notificationsEnabled,
    IlDuLwwClock? settingsClock,
    Iterable<String>? notifiedTierIds,
  }) {
    final nextActivity = clearLastEligibleActivityAt
        ? null
        : (lastEligibleActivityAt ?? this.lastEligibleActivityAt);
    final startsNewCycle = nextActivity != this.lastEligibleActivityAt;
    return IlDuCarePreferences(
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

  static IlDuCarePreferences merge(
    IlDuCarePreferences left,
    IlDuCarePreferences right,
  ) {
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
    return IlDuCarePreferences(
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
      throw const FormatException('IlDu care projection requires UTC.');
    }
    if (!displayEnabled || vacationMode || lastEligibleActivityAt == null) {
      return HanokWeatheringTier.fresh;
    }
    final elapsed = asOf.difference(lastEligibleActivityAt!);
    if (elapsed.isNegative || elapsed.inDays < 7) {
      return HanokWeatheringTier.fresh;
    }
    return elapsed.inDays < 14
        ? HanokWeatheringTier.livedIn
        : HanokWeatheringTier.patina;
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

final class IlDuWorldState {
  static const int currentSchemaVersion = 1;
  static const int currentMigrationVersion = 1;

  IlDuWorldState({
    this.schemaVersion = currentSchemaVersion,
    this.migrationVersion = currentMigrationVersion,
    required this.sourceManifestVersion,
    Map<String, IlDuDesignSelection> activeDesignSelections = const {},
    required this.carePreferences,
  }) : activeDesignSelections = Map.unmodifiable(
         _validateSelections(activeDesignSelections),
       ) {
    if (schemaVersion != currentSchemaVersion ||
        migrationVersion != currentMigrationVersion ||
        !_validStableId(sourceManifestVersion)) {
      throw const FormatException('Invalid IlDu world state header.');
    }
  }

  factory IlDuWorldState.fresh({required String sourceManifestVersion}) =>
      IlDuWorldState(
        sourceManifestVersion: sourceManifestVersion,
        carePreferences: IlDuCarePreferences.fresh(),
      );

  factory IlDuWorldState.fromJson(Map<String, dynamic> json) {
    _requireExactKeys(
      json,
      required: const {
        'schemaVersion',
        'migrationVersion',
        'sourceManifestVersion',
        'activeDesignSelections',
        'carePreferences',
      },
    );
    final schemaVersion = json['schemaVersion'];
    final migrationVersion = json['migrationVersion'];
    final sourceManifestVersion = json['sourceManifestVersion'];
    final rawSelections = json['activeDesignSelections'];
    final rawCare = json['carePreferences'];
    if (schemaVersion is! int ||
        migrationVersion is! int ||
        sourceManifestVersion is! String ||
        rawSelections is! Map ||
        rawCare is! Map) {
      throw const FormatException('Invalid IlDu world state.');
    }
    final selections = <String, IlDuDesignSelection>{};
    for (final entry in rawSelections.entries) {
      if (entry.key is! String || entry.value is! Map) {
        throw const FormatException('Invalid IlDu design selection map.');
      }
      selections[entry.key as String] = IlDuDesignSelection.fromJson(
        _stringMap(entry.value as Map),
      );
    }
    return IlDuWorldState(
      schemaVersion: schemaVersion,
      migrationVersion: migrationVersion,
      sourceManifestVersion: sourceManifestVersion,
      activeDesignSelections: selections,
      carePreferences: IlDuCarePreferences.fromJson(_stringMap(rawCare)),
    );
  }

  final int schemaVersion;
  final int migrationVersion;
  final String sourceManifestVersion;
  final Map<String, IlDuDesignSelection> activeDesignSelections;
  final IlDuCarePreferences carePreferences;

  IlDuWorldState copyWith({
    String? sourceManifestVersion,
    Map<String, IlDuDesignSelection>? activeDesignSelections,
    IlDuCarePreferences? carePreferences,
  }) => IlDuWorldState(
    schemaVersion: schemaVersion,
    migrationVersion: migrationVersion,
    sourceManifestVersion: sourceManifestVersion ?? this.sourceManifestVersion,
    activeDesignSelections:
        activeDesignSelections ?? this.activeDesignSelections,
    carePreferences: carePreferences ?? this.carePreferences,
  );

  static IlDuWorldState merge(IlDuWorldState left, IlDuWorldState right) {
    if (left.schemaVersion != right.schemaVersion ||
        left.migrationVersion != right.migrationVersion) {
      throw const FormatException('Cannot merge different IlDu schemas.');
    }
    final slots = {
      ...left.activeDesignSelections.keys,
      ...right.activeDesignSelections.keys,
    };
    final selections = <String, IlDuDesignSelection>{};
    for (final slot in slots) {
      final local = left.activeDesignSelections[slot];
      final remote = right.activeDesignSelections[slot];
      if (local == null) {
        selections[slot] = remote!;
      } else if (remote == null) {
        selections[slot] = local;
      } else {
        selections[slot] = _selectDesign(local, remote);
      }
    }
    return IlDuWorldState(
      sourceManifestVersion:
          left.sourceManifestVersion.compareTo(right.sourceManifestVersion) >= 0
          ? left.sourceManifestVersion
          : right.sourceManifestVersion,
      activeDesignSelections: selections,
      carePreferences: IlDuCarePreferences.merge(
        left.carePreferences,
        right.carePreferences,
      ),
    );
  }

  Map<String, dynamic> toJson() => {
    'schemaVersion': schemaVersion,
    'migrationVersion': migrationVersion,
    'sourceManifestVersion': sourceManifestVersion,
    'activeDesignSelections': {
      for (final key in activeDesignSelections.keys.toList()..sort())
        key: activeDesignSelections[key]!.toJson(),
    },
    'carePreferences': carePreferences.toJson(),
  };
}

IlDuDesignSelection _selectDesign(
  IlDuDesignSelection left,
  IlDuDesignSelection right,
) {
  final clock = left.clock.compareTo(right.clock);
  if (clock != 0) {
    return clock > 0 ? left : right;
  }
  return left.grantId.compareTo(right.grantId) >= 0 ? left : right;
}

IlDuCarePreferences _selectCareSettings(
  IlDuCarePreferences left,
  IlDuCarePreferences right,
) {
  final clock = left.settingsClock.compareTo(right.settingsClock);
  if (clock != 0) {
    return clock > 0 ? left : right;
  }
  return _careSettingsKey(left).compareTo(_careSettingsKey(right)) >= 0
      ? left
      : right;
}

String _careSettingsKey(IlDuCarePreferences state) =>
    '${state.vacationMode ? 1 : 0}'
    '${state.displayEnabled ? 1 : 0}'
    '${state.notificationsEnabled ? 1 : 0}';

Map<String, IlDuDesignSelection> _validateSelections(
  Map<String, IlDuDesignSelection> source,
) {
  final result = <String, IlDuDesignSelection>{};
  for (final entry in source.entries) {
    if (!_validStableId(entry.key)) {
      throw const FormatException('Invalid IlDu design slot ID.');
    }
    result[entry.key] = entry.value;
  }
  return result;
}

Set<String> _stableIdSet(Iterable<String> values) {
  final result = <String>{};
  for (final value in values) {
    if (!_validStableId(value) || !result.add(value)) {
      throw const FormatException('Invalid or duplicate IlDu ID.');
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
      throw const FormatException('IlDu JSON keys must be unique strings.');
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
    throw const FormatException('IlDu JSON has missing or unknown fields.');
  }
}

bool _isStrictUtc(DateTime value) => value.isUtc;

bool _isEpoch(DateTime value) => value.millisecondsSinceEpoch == 0;

DateTime? _latestUtc(DateTime? left, DateTime? right) {
  if (left == null) return right;
  if (right == null) return left;
  return left.isAfter(right) ? left : right;
}
