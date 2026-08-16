import '../models/can_do_segment.dart';
import '../models/hanok_growth.dart';
import '../models/learner_level.dart';
import '../models/personal_room.dart';
import 'course_segment_catalog.dart';

/// Strict immutable bridge from published can-do denominator slots to Hanok
/// presentation rewards.
final class HanokGrantCatalog {
  static const int supportedSchemaVersion = 1;

  HanokGrantCatalog._({
    required this.schemaVersion,
    required this.manifestVersion,
    required Iterable<HanokGrantDefinition> grants,
  }) : grants = List.unmodifiable(grants),
       grantsById = Map.unmodifiable({
         for (final grant in grants) grant.id: grant,
       }),
       grantsBySegmentId = Map.unmodifiable({
         for (final grant in grants) grant.canDoSegmentId: grant,
       });

  final int schemaVersion;
  final String manifestVersion;
  final List<HanokGrantDefinition> grants;
  final Map<String, HanokGrantDefinition> grantsById;
  final Map<String, HanokGrantDefinition> grantsBySegmentId;

  /// Rejects any rewrite of an already published reward identity while still
  /// allowing later additive tracks to append new grants.
  void validateEvolutionFrom(HanokGrantCatalog previous) {
    if (schemaVersion != previous.schemaVersion) {
      throw const FormatException('Hanok grant schema cannot change in place.');
    }
    for (final oldGrant in previous.grants) {
      final currentGrant = grantsById[oldGrant.id];
      if (currentGrant == null || !_sameGrant(currentGrant, oldGrant)) {
        throw FormatException(
          'Published Hanok grant ${oldGrant.id} changed or disappeared.',
        );
      }
    }
  }

  static HanokGrantCatalog fromJson(
    Map<String, dynamic> json, {
    required CourseSegmentCatalog segmentCatalog,
  }) {
    _requireKeys(
      json,
      required: const {'schemaVersion', 'manifestVersion', 'grants'},
      path: r'$',
    );
    final schemaVersion = json['schemaVersion'];
    final manifestVersion = json['manifestVersion'];
    final rows = json['grants'];
    if (schemaVersion != supportedSchemaVersion ||
        manifestVersion is! String ||
        !_validId(manifestVersion) ||
        rows is! List) {
      throw const FormatException('Invalid Hanok grant manifest.');
    }

    final expectedSegmentIds = _denominatorSegmentIds(segmentCatalog);
    final grants = <HanokGrantDefinition>[];
    final grantIds = <String>{};
    final segmentIds = <String>{};
    for (var index = 0; index < rows.length; index++) {
      final path =
          r'$.grants'
          '[$index]';
      final raw = rows[index];
      if (raw is! Map) {
        throw FormatException('$path must be an object.');
      }
      final row = raw.map((key, value) => MapEntry(key.toString(), value));
      final grant = _decodeGrant(row, path, segmentCatalog);
      if (!grantIds.add(grant.id) || !segmentIds.add(grant.canDoSegmentId)) {
        throw FormatException('$path duplicates a grant or segment ID.');
      }
      grants.add(grant);
    }
    if (!_sameSet(segmentIds, expectedSegmentIds)) {
      throw const FormatException(
        'Hanok grants must exactly cover published additive segment slots.',
      );
    }
    _requireCanonicalOrder(grants);
    _validatePrerequisites(grants);
    return HanokGrantCatalog._(
      schemaVersion: schemaVersion,
      manifestVersion: manifestVersion,
      grants: grants,
    );
  }
}

Set<String> _denominatorSegmentIds(CourseSegmentCatalog catalog) {
  final result = <String>{};
  for (final track in catalog.releaseTracks) {
    if (track.status == ReleaseTrackStatus.draft ||
        !track.kind.contributesToLearnerDenominator) {
      continue;
    }
    for (final editionId in track.editionIds) {
      final edition = catalog.findEdition(editionId)!;
      if (edition.status != TrackEditionStatus.draft) {
        result.addAll(edition.segmentIds);
      }
    }
  }
  return result;
}

HanokGrantDefinition _decodeGrant(
  Map<String, dynamic> row,
  String path,
  CourseSegmentCatalog segmentCatalog,
) {
  const required = {
    'id',
    'canDoSegmentId',
    'level',
    'era',
    'order',
    'kind',
    'revealAssetIds',
    'prerequisiteGrantIds',
    'userDescriptionKey',
  };
  const optional = {'designSlot', 'optionProvenance', 'venueSurface'};
  _requireKeys(row, required: required, optional: optional, path: path);
  final id = _id(row['id'], '$path.id');
  final segmentId = _id(row['canDoSegmentId'], '$path.canDoSegmentId');
  final segment = segmentCatalog.findSegment(segmentId);
  final level = LearnerLevel.fromCode(row['level'] as String?);
  final era = row['era'] is String
      ? HanokGrowthEra.fromCode(row['era'] as String)
      : null;
  final kind = row['kind'] is String
      ? HanokGrantKind.fromCode(row['kind'] as String)
      : null;
  final order = row['order'];
  if (segment == null ||
      level == null ||
      era == null ||
      kind == null ||
      order is! int ||
      order <= 0 ||
      segment.level != level ||
      segment.order != order ||
      era != HanokGrowthEra.fromLevel(level)) {
    throw FormatException('$path has inconsistent segment metadata.');
  }

  HanokDesignSlot? designSlot;
  HanokOptionProvenance? provenance;
  if (row['designSlot'] case final String raw) {
    designSlot = HanokDesignSlot.fromCode(raw);
  }
  if (row['optionProvenance'] case final String raw) {
    provenance = HanokOptionProvenance.fromCode(raw);
  }
  PersonalRoomSurface? venue;
  if (row['venueSurface'] case final String raw) {
    venue = PersonalRoomSurface.fromStorageKey(raw);
  }
  if (kind == HanokGrantKind.designOption) {
    if (designSlot == null || provenance == null || venue != null) {
      throw FormatException('$path has an invalid design option contract.');
    }
  } else if (designSlot != null || provenance != null) {
    throw FormatException('$path has design metadata on a non-design grant.');
  }
  if ((kind == HanokGrantKind.venue) != (venue != null)) {
    throw FormatException('$path has an invalid venue contract.');
  }

  final revealAssetIds = _idList(row['revealAssetIds'], '$path.revealAssetIds');
  final prerequisiteGrantIds = _idList(
    row['prerequisiteGrantIds'],
    '$path.prerequisiteGrantIds',
  );
  if (revealAssetIds.isEmpty) {
    throw FormatException('$path.revealAssetIds must not be empty.');
  }
  return HanokGrantDefinition(
    id: id,
    canDoSegmentId: segmentId,
    level: level,
    era: era,
    order: order,
    kind: kind,
    designSlot: designSlot,
    optionProvenance: provenance,
    revealAssetIds: revealAssetIds,
    prerequisiteGrantIds: prerequisiteGrantIds,
    userDescriptionKey: _id(
      row['userDescriptionKey'],
      '$path.userDescriptionKey',
    ),
    venueSurface: venue,
  );
}

void _requireCanonicalOrder(List<HanokGrantDefinition> grants) {
  final sorted = List<HanokGrantDefinition>.from(grants)
    ..sort((left, right) {
      final level = left.level.rank.compareTo(right.level.rank);
      if (level != 0) {
        return level;
      }
      final order = left.order.compareTo(right.order);
      return order != 0 ? order : left.id.compareTo(right.id);
    });
  for (var index = 0; index < grants.length; index++) {
    if (grants[index].id != sorted[index].id) {
      throw const FormatException('Hanok grants are not canonically ordered.');
    }
  }
}

void _validatePrerequisites(List<HanokGrantDefinition> grants) {
  final orderById = <String, int>{};
  for (var index = 0; index < grants.length; index++) {
    orderById[grants[index].id] = index;
  }
  for (var index = 0; index < grants.length; index++) {
    for (final prerequisiteId in grants[index].prerequisiteGrantIds) {
      final prerequisiteOrder = orderById[prerequisiteId];
      if (prerequisiteOrder == null || prerequisiteOrder >= index) {
        throw const FormatException(
          'Hanok grant prerequisite must be an earlier known grant.',
        );
      }
    }
  }
}

List<String> _idList(Object? value, String path) {
  if (value is! List) {
    throw FormatException('$path must be a list.');
  }
  final result = <String>[];
  final seen = <String>{};
  for (var index = 0; index < value.length; index++) {
    final id = _id(value[index], '$path[$index]');
    if (!seen.add(id)) {
      throw FormatException('$path contains a duplicate ID.');
    }
    result.add(id);
  }
  return result;
}

String _id(Object? value, String path) {
  if (value is! String || !_validId(value)) {
    throw FormatException('$path must be a stable ID.');
  }
  return value;
}

bool _validId(String value) =>
    value.isNotEmpty &&
    value.length <= 160 &&
    RegExp(r'^[A-Za-z0-9_.:-]+$').hasMatch(value);

void _requireKeys(
  Map<String, dynamic> value, {
  required Set<String> required,
  Set<String> optional = const {},
  required String path,
}) {
  final keys = value.keys.toSet();
  final missing = required.difference(keys);
  final unknown = keys.difference({...required, ...optional});
  if (missing.isNotEmpty || unknown.isNotEmpty) {
    throw FormatException('$path has missing or unknown fields.');
  }
}

bool _sameSet(Set<String> left, Set<String> right) =>
    left.length == right.length && left.containsAll(right);

bool _sameGrant(HanokGrantDefinition left, HanokGrantDefinition right) =>
    left.id == right.id &&
    left.canDoSegmentId == right.canDoSegmentId &&
    left.level == right.level &&
    left.era == right.era &&
    left.order == right.order &&
    left.kind == right.kind &&
    left.designSlot == right.designSlot &&
    left.optionProvenance == right.optionProvenance &&
    _sameList(left.revealAssetIds, right.revealAssetIds) &&
    _sameList(left.prerequisiteGrantIds, right.prerequisiteGrantIds) &&
    left.userDescriptionKey == right.userDescriptionKey &&
    left.venueSurface == right.venueSurface;

bool _sameList(List<String> left, List<String> right) {
  if (left.length != right.length) {
    return false;
  }
  for (var index = 0; index < left.length; index++) {
    if (left[index] != right[index]) {
      return false;
    }
  }
  return true;
}
