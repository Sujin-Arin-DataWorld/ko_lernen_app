import '../models/can_do_segment.dart';
import '../models/curriculum.dart';
import '../models/learner_level.dart';

/// Strict, immutable catalog of assessable can-do segments.
///
/// The caller supplies the existing curriculum authorities so this catalog can
/// validate ownership without importing content loaders or reward systems.
class CourseSegmentCatalog {
  static const int supportedSchemaVersion = 1;
  static const double minimumPermanentMasteryScore = .7;

  final int schemaVersion;
  final List<ContentClusterDefinition> contentClusters;
  final List<CanDoSegment> segments;
  final List<TrackEdition> editions;
  final List<ReleaseTrackDefinition> releaseTracks;
  final List<CanDoSegment> publishedSegments;
  final Map<String, CanDoSegment> segmentsById;
  final Map<String, TrackEdition> editionsById;
  final Map<String, ReleaseTrackDefinition> releaseTracksById;
  final Map<String, ContentClusterDefinition> contentClustersById;

  CourseSegmentCatalog._({
    required this.schemaVersion,
    required Iterable<ContentClusterDefinition> contentClusters,
    required Iterable<CanDoSegment> segments,
    required Iterable<TrackEdition> editions,
    required Iterable<ReleaseTrackDefinition> releaseTracks,
  }) : contentClusters = List.unmodifiable(contentClusters),
       segments = List.unmodifiable(segments),
       editions = List.unmodifiable(editions),
       releaseTracks = List.unmodifiable(releaseTracks),
       publishedSegments = List.unmodifiable(
         segments.where(
           (segment) =>
               segment.lifecycle == CanDoSegmentLifecycle.published &&
               editions.any(
                 (edition) =>
                     edition.id == segment.trackEditionId &&
                     edition.status == TrackEditionStatus.published,
               ),
         ),
       ),
       segmentsById = Map.unmodifiable({
         for (final segment in segments) segment.id: segment,
       }),
       editionsById = Map.unmodifiable({
         for (final edition in editions) edition.id: edition,
       }),
       releaseTracksById = Map.unmodifiable({
         for (final track in releaseTracks) track.id: track,
       }),
       contentClustersById = Map.unmodifiable({
         for (final cluster in contentClusters) cluster.id: cluster,
       });

  factory CourseSegmentCatalog.fromJson(
    Map<String, dynamic> json, {
    required Iterable<CourseUnit> courseUnits,
    required Iterable<Concept> concepts,
    required Iterable<ContentSeedAuthority> seedAuthorities,
    required Iterable<ContentReferenceAuthority> contentAuthorities,
    required Iterable<SegmentAssessmentAuthority> assessmentAuthorities,
  }) {
    return _CourseSegmentCatalogDecoder(
      json: json,
      courseUnits: courseUnits,
      concepts: concepts,
      coreReleasePolicy: hanokV1CoreReleasePolicy,
      seedAuthorities: seedAuthorities,
      contentAuthorities: contentAuthorities,
      assessmentAuthorities: assessmentAuthorities,
    ).decode();
  }

  CanDoSegment? findSegment(String id) => segmentsById[id];

  TrackEdition? findEdition(String id) => editionsById[id];

  ReleaseTrackDefinition? findReleaseTrack(String id) => releaseTracksById[id];

  ContentClusterDefinition? findContentCluster(String id) =>
      contentClustersById[id];

  /// Stable denominator for a release track: the sum of its immutable slots.
  int denominatorForReleaseTrack(String releaseTrackId) {
    final track = releaseTracksById[releaseTrackId];
    if (track == null) {
      throw ArgumentError.value(
        releaseTrackId,
        'releaseTrackId',
        'unknown release track',
      );
    }
    return track.editionIds.fold<int>(
      0,
      (total, editionId) => total + editionsById[editionId]!.segmentIds.length,
    );
  }

  /// Segment evidence IDs that may satisfy one immutable edition slot.
  ///
  /// Old evidence remains valid after retirement. For an active edition, new
  /// learners may instead satisfy the slot through its published successor.
  List<String> satisfyingSegmentIdsForEditionSlot({
    required String editionId,
    required String segmentId,
  }) {
    final edition = editionsById[editionId];
    if (edition == null || !edition.segmentIds.contains(segmentId)) {
      throw ArgumentError('segment "$segmentId" is not a slot in "$editionId"');
    }
    final segment = segmentsById[segmentId]!;
    final satisfyingIds = <String>[segmentId];
    var cursor = segment;
    while (cursor.lifecycle == CanDoSegmentLifecycle.retired &&
        cursor.successorSegmentId != null) {
      final successorId = cursor.successorSegmentId!;
      satisfyingIds.add(successorId);
      cursor = segmentsById[successorId]!;
    }
    return List.unmodifiable(satisfyingIds);
  }

  /// Validates this catalog as the successor of [previous].
  ///
  /// Published denominators and stable mastery identities are append-only.
  /// Draft editions and segments remain authoring surfaces and may change or
  /// disappear before publication.
  void validateEvolutionFrom(CourseSegmentCatalog previous) {
    _CourseSegmentEvolutionValidator(
      previous: previous,
      current: this,
    ).validate();
  }
}

class _CourseSegmentCatalogDecoder {
  final Map<String, dynamic> json;
  final Iterable<CourseUnit> courseUnits;
  final Iterable<Concept> concepts;
  final CoreReleasePolicy coreReleasePolicy;
  final Iterable<ContentSeedAuthority> seedAuthorities;
  final Iterable<ContentReferenceAuthority> contentAuthorities;
  final Iterable<SegmentAssessmentAuthority> assessmentAuthorities;

  _CourseSegmentCatalogDecoder({
    required this.json,
    required this.courseUnits,
    required this.concepts,
    required this.coreReleasePolicy,
    required this.seedAuthorities,
    required this.contentAuthorities,
    required this.assessmentAuthorities,
  });

  CourseSegmentCatalog decode() {
    _requireKeys(
      json,
      required: const {
        'schemaVersion',
        'contentClusters',
        'segments',
        'trackEditions',
        'releaseTracks',
      },
      path: r'$',
    );
    final schemaVersion = _readInt(json['schemaVersion'], r'$.schemaVersion');
    if (schemaVersion != CourseSegmentCatalog.supportedSchemaVersion) {
      _fail(
        r'$.schemaVersion',
        'unsupported version $schemaVersion; expected '
            '${CourseSegmentCatalog.supportedSchemaVersion}',
      );
    }

    final unitsById = _indexCourseUnits(courseUnits);
    final conceptsById = _indexConcepts(concepts);
    final seedAuthoritiesById = _indexSeedAuthorities(seedAuthorities);
    final contentAuthoritiesByKey = _indexContentAuthorities(
      contentAuthorities,
    );
    final assessmentAuthoritiesById = _indexAssessmentAuthorities(
      assessmentAuthorities,
    );
    final contentClusters = _readContentClusters(json['contentClusters']);
    final segments = _readSegments(json['segments']);
    final editions = _readEditions(json['trackEditions']);
    final releaseTracks = _readReleaseTracks(json['releaseTracks']);
    final contentClustersById = _indexContentClusters(contentClusters);
    final segmentsById = _indexSegments(segments);
    final editionsById = _indexEditions(editions);
    final releaseTracksById = _indexReleaseTracks(releaseTracks);

    _validateContentClusters(
      contentClusters,
      seedAuthoritiesById: seedAuthoritiesById,
      authoritiesByKey: contentAuthoritiesByKey,
    );

    _validateSegments(
      segments,
      segmentsById: segmentsById,
      editionsById: editionsById,
      unitsById: unitsById,
      conceptsById: conceptsById,
      assessmentAuthoritiesById: assessmentAuthoritiesById,
      contentAuthoritiesByKey: contentAuthoritiesByKey,
      contentClustersById: contentClustersById,
      releaseTracksById: releaseTracksById,
    );
    _validateEditions(
      editions,
      segmentsById: segmentsById,
      editionsById: editionsById,
      releaseTracksById: releaseTracksById,
    );
    _validateReleaseTracks(
      releaseTracks,
      editionsById: editionsById,
      segmentsById: segmentsById,
      coreReleasePolicy: coreReleasePolicy,
    );
    _validateSuccessorGraph(
      segments,
      segmentsById: segmentsById,
      editionsById: editionsById,
      releaseTracksById: releaseTracksById,
    );
    _validateContentClusterOwnership(contentClusters, segments: segments);

    contentClusters.sort((left, right) {
      final levelOrder = left.level.rank.compareTo(right.level.rank);
      if (levelOrder != 0) {
        return levelOrder;
      }
      return left.id.compareTo(right.id);
    });
    segments.sort(_compareSegments);
    editions.sort((left, right) {
      final levelOrder = left.level.rank.compareTo(right.level.rank);
      if (levelOrder != 0) {
        return levelOrder;
      }
      return left.id.compareTo(right.id);
    });
    releaseTracks.sort((left, right) {
      final order = left.order.compareTo(right.order);
      return order != 0 ? order : left.id.compareTo(right.id);
    });
    return CourseSegmentCatalog._(
      schemaVersion: schemaVersion,
      contentClusters: contentClusters,
      segments: segments,
      editions: editions,
      releaseTracks: releaseTracks,
    );
  }

  Map<String, CourseUnit> _indexCourseUnits(Iterable<CourseUnit> units) {
    final byId = <String, CourseUnit>{};
    for (final unit in units) {
      _validateExternalId(unit.id, 'course unit');
      final level = LearnerLevel.fromCode(unit.level);
      if (level == null || unit.level != level.code) {
        _fail('courseUnits.${unit.id}.level', 'must be a canonical CEFR code');
      }
      if (byId.containsKey(unit.id)) {
        _fail('courseUnits', 'duplicate course unit ID "${unit.id}"');
      }
      byId[unit.id] = unit;
    }
    return byId;
  }

  Map<String, Concept> _indexConcepts(Iterable<Concept> source) {
    final byId = <String, Concept>{};
    for (final concept in source) {
      _validateExternalId(concept.id, 'concept');
      final level = LearnerLevel.fromCode(concept.level);
      if (level == null || concept.level != level.code) {
        _fail('concepts.${concept.id}.level', 'must be a canonical CEFR code');
      }
      if (byId.containsKey(concept.id)) {
        _fail('concepts', 'duplicate concept ID "${concept.id}"');
      }
      byId[concept.id] = concept;
    }
    return byId;
  }

  Map<String, ContentReferenceAuthority> _indexContentAuthorities(
    Iterable<ContentReferenceAuthority> source,
  ) {
    final byKey = <String, ContentReferenceAuthority>{};
    for (final authority in source) {
      final reference = authority.reference;
      _validateExternalId(reference.id, 'content reference');
      _validateExternalId(authority.sourceSeedId, 'content source seed');
      _validateExternalId(authority.courseUnitId, 'content course unit');
      if (byKey.containsKey(reference.key)) {
        _fail(
          'contentAuthorities',
          'duplicate content reference "${reference.key}"',
        );
      }
      byKey[reference.key] = authority;
    }
    return byKey;
  }

  Map<String, ContentSeedAuthority> _indexSeedAuthorities(
    Iterable<ContentSeedAuthority> source,
  ) {
    final byId = <String, ContentSeedAuthority>{};
    for (final authority in source) {
      _validateExternalId(authority.id, 'content seed');
      if (byId.containsKey(authority.id)) {
        _fail('seedAuthorities', 'duplicate content seed ID "${authority.id}"');
      }
      byId[authority.id] = authority;
    }
    return byId;
  }

  Map<String, SegmentAssessmentAuthority> _indexAssessmentAuthorities(
    Iterable<SegmentAssessmentAuthority> source,
  ) {
    final byId = <String, SegmentAssessmentAuthority>{};
    for (final authority in source) {
      final id = authority.assessmentItemId;
      _validateExternalId(id, 'assessment item');
      _validateExternalId(
        authority.missionContentLinkId,
        'mission content link',
      );
      _validateExternalId(authority.courseUnitId, 'assessment course unit');
      final conceptIds = <String>{};
      for (final conceptId in authority.conceptIds) {
        _validateExternalId(conceptId, 'assessment concept');
        if (!conceptIds.add(conceptId)) {
          _fail(
            'assessment authority "$id"',
            'duplicate concept ID "$conceptId"',
          );
        }
      }
      if (authority.rubricVersion <= 0) {
        _fail('assessment authority "$id"', 'rubricVersion must be positive');
      }
      if (!authority.minimumScore.isFinite ||
          authority.minimumScore <
              CourseSegmentCatalog.minimumPermanentMasteryScore ||
          authority.minimumScore > 1) {
        _fail(
          'assessment authority "$id"',
          'minimumScore must be at least '
              '${CourseSegmentCatalog.minimumPermanentMasteryScore} and at '
              'most 1',
        );
      }
      if (byId.containsKey(id)) {
        _fail('assessmentAuthorities', 'duplicate assessment item ID "$id"');
      }
      byId[id] = authority;
    }
    return byId;
  }

  List<ContentClusterDefinition> _readContentClusters(Object? raw) {
    final entries = _readList(raw, r'$.contentClusters');
    return [
      for (var index = 0; index < entries.length; index++)
        _readContentCluster(entries[index], r'$.contentClusters[$index]'),
    ];
  }

  ContentClusterDefinition _readContentCluster(Object? raw, String path) {
    final map = _readMap(raw, path);
    _requireKeys(
      map,
      required: const {
        'id',
        'level',
        'revision',
        'sourceSeedIds',
        'contentReferences',
      },
      path: path,
    );
    final revision = _readInt(map['revision'], '$path.revision');
    if (revision <= 0) {
      _fail('$path.revision', 'must be positive');
    }
    final contentReferences = _readContentReferences(
      map['contentReferences'],
      '$path.contentReferences',
    );
    if (contentReferences.isEmpty) {
      _fail('$path.contentReferences', 'must not be empty');
    }
    return ContentClusterDefinition(
      id: _readId(map['id'], '$path.id'),
      level: _readLevel(map['level'], '$path.level'),
      revision: revision,
      sourceSeedIds: _readIdList(map['sourceSeedIds'], '$path.sourceSeedIds'),
      contentReferences: contentReferences,
    );
  }

  Map<String, ContentClusterDefinition> _indexContentClusters(
    Iterable<ContentClusterDefinition> clusters,
  ) {
    final byId = <String, ContentClusterDefinition>{};
    for (final cluster in clusters) {
      if (byId.containsKey(cluster.id)) {
        _fail(
          r'$.contentClusters',
          'duplicate content cluster ID "${cluster.id}"',
        );
      }
      byId[cluster.id] = cluster;
    }
    return byId;
  }

  void _validateContentClusters(
    Iterable<ContentClusterDefinition> clusters, {
    required Map<String, ContentSeedAuthority> seedAuthoritiesById,
    required Map<String, ContentReferenceAuthority> authoritiesByKey,
  }) {
    for (final cluster in clusters) {
      for (final seedId in cluster.sourceSeedIds) {
        final authority = seedAuthoritiesById[seedId];
        if (authority == null) {
          _fail(
            'content cluster "${cluster.id}"',
            'unknown source seed "$seedId"',
          );
        }
        if (authority.level != cluster.level) {
          _fail(
            'content cluster "${cluster.id}"',
            'source seed "$seedId" has level ${authority.level.code}, '
                'expected ${cluster.level.code}',
          );
        }
      }
      for (final reference in cluster.contentReferences) {
        final authority = authoritiesByKey[reference.key];
        if (authority == null) {
          _fail(
            'content cluster "${cluster.id}"',
            'unknown content reference "${reference.key}"',
          );
        }
        if (authority.level != cluster.level) {
          _fail(
            'content cluster "${cluster.id}"',
            'content reference "${reference.key}" has level '
                '${authority.level.code}, expected ${cluster.level.code}',
          );
        }
        if (!cluster.sourceSeedIds.contains(authority.sourceSeedId)) {
          _fail(
            'content cluster "${cluster.id}"',
            'content reference "${reference.key}" declares source seed '
                '"${authority.sourceSeedId}" outside sourceSeedIds',
          );
        }
      }
    }
  }

  void _validateContentClusterOwnership(
    Iterable<ContentClusterDefinition> clusters, {
    required Iterable<CanDoSegment> segments,
  }) {
    final referencedIds = <String>{
      for (final segment in segments) ...segment.contentClusterIds,
    };
    for (final cluster in clusters) {
      if (!referencedIds.contains(cluster.id)) {
        _fail(
          'content cluster "${cluster.id}"',
          'must be referenced by at least one segment',
        );
      }
      final usedByPublishedSegment = segments.any(
        (segment) =>
            segment.lifecycle != CanDoSegmentLifecycle.draft &&
            segment.contentClusterIds.contains(cluster.id),
      );
      if (usedByPublishedSegment && cluster.sourceSeedIds.isEmpty) {
        _fail(
          'content cluster "${cluster.id}"',
          'published or retired segment clusters require sourceSeedIds',
        );
      }
    }
  }

  List<CanDoSegment> _readSegments(Object? raw) {
    final entries = _readList(raw, r'$.segments');
    if (entries.isEmpty) {
      _fail(r'$.segments', 'must not be empty');
    }
    return [
      for (var index = 0; index < entries.length; index++)
        _readSegment(entries[index], r'$.segments[$index]'),
    ];
  }

  CanDoSegment _readSegment(Object? raw, String path) {
    final map = _readMap(raw, path);
    _requireKeys(
      map,
      required: const {
        'id',
        'constructLineageId',
        'parentCourseUnitId',
        'level',
        'order',
        'title',
        'canDo',
        'requiredConceptIds',
        'contentClusterIds',
        'proofRevision',
        'evidencePolicy',
        'assessmentRequirements',
        'ownedAssessmentItemIds',
        'releaseTrackId',
        'trackEditionId',
        'lifecycle',
      },
      optional: const {'successorSegmentId'},
      path: path,
    );

    final id = _readId(map['id'], '$path.id');
    final level = _readLevel(map['level'], '$path.level');
    final order = _readInt(map['order'], '$path.order');
    if (order <= 0) {
      _fail('$path.order', 'must be positive');
    }
    final proofRevision = _readInt(map['proofRevision'], '$path.proofRevision');
    if (proofRevision < 0) {
      _fail('$path.proofRevision', 'must not be negative');
    }

    final assessmentRequirements = _readAssessmentRequirements(
      map['assessmentRequirements'],
      '$path.assessmentRequirements',
    );
    final rawEvidencePolicy = _readString(
      map['evidencePolicy'],
      '$path.evidencePolicy',
    );
    final evidencePolicy = SegmentEvidencePolicyX.tryFromCode(
      rawEvidencePolicy,
    );
    if (evidencePolicy == null) {
      _fail(
        '$path.evidencePolicy',
        'unknown evidence policy "$rawEvidencePolicy"',
      );
    }
    final successorRaw = map['successorSegmentId'];
    final successorSegmentId = successorRaw == null
        ? null
        : _readId(successorRaw, '$path.successorSegmentId');

    return CanDoSegment(
      id: id,
      constructLineageId: _readId(
        map['constructLineageId'],
        '$path.constructLineageId',
      ),
      parentCourseUnitId: _readId(
        map['parentCourseUnitId'],
        '$path.parentCourseUnitId',
      ),
      level: level,
      order: order,
      title: _readText(map['title'], '$path.title'),
      canDo: _readText(map['canDo'], '$path.canDo'),
      requiredConceptIds: _readIdList(
        map['requiredConceptIds'],
        '$path.requiredConceptIds',
      ),
      contentClusterIds: _readIdList(
        map['contentClusterIds'],
        '$path.contentClusterIds',
      ),
      proofRevision: proofRevision,
      evidencePolicy: evidencePolicy,
      assessmentRequirements: assessmentRequirements,
      ownedAssessmentItemIds: _readIdList(
        map['ownedAssessmentItemIds'],
        '$path.ownedAssessmentItemIds',
      ),
      releaseTrackId: _readId(map['releaseTrackId'], '$path.releaseTrackId'),
      trackEditionId: _readId(map['trackEditionId'], '$path.trackEditionId'),
      lifecycle: _readLifecycle(map['lifecycle'], '$path.lifecycle'),
      successorSegmentId: successorSegmentId,
    );
  }

  List<ContentReference> _readContentReferences(Object? raw, String path) {
    final entries = _readList(raw, path);
    final references = <ContentReference>[];
    final keys = <String>{};
    for (var index = 0; index < entries.length; index++) {
      final entryPath = '$path[$index]';
      final map = _readMap(entries[index], entryPath);
      _requireKeys(map, required: const {'kind', 'id'}, path: entryPath);
      final rawKind = _readString(map['kind'], '$entryPath.kind');
      final kind = ContentReferenceKindX.tryFromCode(rawKind);
      if (kind == null) {
        _fail('$entryPath.kind', 'unknown content reference kind "$rawKind"');
      }
      final reference = ContentReference(
        kind: kind,
        id: _readId(map['id'], '$entryPath.id'),
      );
      if (!keys.add(reference.key)) {
        _fail(path, 'duplicate content reference "${reference.key}"');
      }
      references.add(reference);
    }
    return references;
  }

  List<SegmentAssessmentRequirement> _readAssessmentRequirements(
    Object? raw,
    String path,
  ) {
    final entries = _readList(raw, path);
    final requirements = <SegmentAssessmentRequirement>[];
    final assessmentItemIds = <String>{};
    for (var index = 0; index < entries.length; index++) {
      final entryPath = '$path[$index]';
      final map = _readMap(entries[index], entryPath);
      _requireKeys(
        map,
        required: const {
          'assessmentItemId',
          'missionContentLinkId',
          'evidenceMode',
          'rubricVersion',
          'minimumScore',
        },
        path: entryPath,
      );
      final assessmentItemId = _readId(
        map['assessmentItemId'],
        '$entryPath.assessmentItemId',
      );
      if (!assessmentItemIds.add(assessmentItemId)) {
        _fail(path, 'duplicate assessment item ID "$assessmentItemId"');
      }
      final rawMode = _readString(
        map['evidenceMode'],
        '$entryPath.evidenceMode',
      );
      final mode = SegmentEvidenceModeX.tryFromCode(rawMode);
      if (mode == null) {
        _fail('$entryPath.evidenceMode', 'unknown evidence mode "$rawMode"');
      }
      final rubricVersion = _readInt(
        map['rubricVersion'],
        '$entryPath.rubricVersion',
      );
      if (rubricVersion <= 0) {
        _fail('$entryPath.rubricVersion', 'must be positive');
      }
      final minimumScore = _readDouble(
        map['minimumScore'],
        '$entryPath.minimumScore',
      );
      if (!minimumScore.isFinite ||
          minimumScore < CourseSegmentCatalog.minimumPermanentMasteryScore ||
          minimumScore > 1) {
        _fail(
          '$entryPath.minimumScore',
          'must be at least '
              '${CourseSegmentCatalog.minimumPermanentMasteryScore} and at '
              'most 1',
        );
      }
      requirements.add(
        SegmentAssessmentRequirement(
          assessmentItemId: assessmentItemId,
          missionContentLinkId: _readId(
            map['missionContentLinkId'],
            '$entryPath.missionContentLinkId',
          ),
          evidenceMode: mode,
          rubricVersion: rubricVersion,
          minimumScore: minimumScore,
        ),
      );
    }
    return requirements;
  }

  List<TrackEdition> _readEditions(Object? raw) {
    final entries = _readList(raw, r'$.trackEditions');
    if (entries.isEmpty) {
      _fail(r'$.trackEditions', 'must not be empty');
    }
    return [
      for (var index = 0; index < entries.length; index++)
        _readEdition(entries[index], r'$.trackEditions[$index]'),
    ];
  }

  List<ReleaseTrackDefinition> _readReleaseTracks(Object? raw) {
    final entries = _readList(raw, r'$.releaseTracks');
    if (entries.isEmpty) {
      _fail(r'$.releaseTracks', 'must not be empty');
    }
    return [
      for (var index = 0; index < entries.length; index++)
        _readReleaseTrack(entries[index], r'$.releaseTracks[$index]'),
    ];
  }

  ReleaseTrackDefinition _readReleaseTrack(Object? raw, String path) {
    final map = _readMap(raw, path);
    _requireKeys(
      map,
      required: const {'id', 'kind', 'order', 'title', 'editionIds', 'status'},
      optional: const {'publishedAt'},
      path: path,
    );
    final rawKind = _readString(map['kind'], '$path.kind');
    final kind = ReleaseTrackKindX.tryFromCode(rawKind);
    if (kind == null) {
      _fail('$path.kind', 'unknown release track kind "$rawKind"');
    }
    final rawStatus = _readString(map['status'], '$path.status');
    final status = ReleaseTrackStatusX.tryFromCode(rawStatus);
    if (status == null) {
      _fail('$path.status', 'unknown release track status "$rawStatus"');
    }
    final order = _readInt(map['order'], '$path.order');
    if (order <= 0) {
      _fail('$path.order', 'must be positive');
    }
    final editionIds = _readIdList(map['editionIds'], '$path.editionIds');
    if (editionIds.isEmpty) {
      _fail('$path.editionIds', 'must not be empty');
    }
    final publishedAt = _readPublicationTime(
      map,
      path: path,
      isDraft: status == ReleaseTrackStatus.draft,
      ownerLabel: 'release track',
    );
    return ReleaseTrackDefinition(
      id: _readId(map['id'], '$path.id'),
      kind: kind,
      order: order,
      title: _readText(map['title'], '$path.title'),
      editionIds: editionIds,
      publishedAt: publishedAt,
      status: status,
    );
  }

  TrackEdition _readEdition(Object? raw, String path) {
    final map = _readMap(raw, path);
    _requireKeys(
      map,
      required: const {'id', 'releaseTrackId', 'level', 'segmentIds', 'status'},
      optional: const {'publishedAt'},
      path: path,
    );
    final rawStatus = _readString(map['status'], '$path.status');
    final status = TrackEditionStatusX.tryFromCode(rawStatus);
    if (status == null) {
      _fail('$path.status', 'unknown track edition status "$rawStatus"');
    }
    final publishedAt = _readPublicationTime(
      map,
      path: path,
      isDraft: status == TrackEditionStatus.draft,
      ownerLabel: 'edition',
    );
    final segmentIds = _readIdList(map['segmentIds'], '$path.segmentIds');
    if (segmentIds.isEmpty) {
      _fail('$path.segmentIds', 'must not be empty');
    }
    return TrackEdition(
      id: _readId(map['id'], '$path.id'),
      releaseTrackId: _readId(map['releaseTrackId'], '$path.releaseTrackId'),
      level: _readLevel(map['level'], '$path.level'),
      segmentIds: segmentIds,
      publishedAt: publishedAt,
      status: status,
    );
  }

  Map<String, CanDoSegment> _indexSegments(Iterable<CanDoSegment> segments) {
    final byId = <String, CanDoSegment>{};
    for (final segment in segments) {
      if (byId.containsKey(segment.id)) {
        _fail(r'$.segments', 'duplicate segment ID "${segment.id}"');
      }
      byId[segment.id] = segment;
    }
    return byId;
  }

  Map<String, TrackEdition> _indexEditions(Iterable<TrackEdition> editions) {
    final byId = <String, TrackEdition>{};
    for (final edition in editions) {
      if (byId.containsKey(edition.id)) {
        _fail(r'$.trackEditions', 'duplicate track edition ID "${edition.id}"');
      }
      byId[edition.id] = edition;
    }
    return byId;
  }

  Map<String, ReleaseTrackDefinition> _indexReleaseTracks(
    Iterable<ReleaseTrackDefinition> tracks,
  ) {
    final byId = <String, ReleaseTrackDefinition>{};
    final orders = <int>{};
    for (final track in tracks) {
      if (byId.containsKey(track.id)) {
        _fail(r'$.releaseTracks', 'duplicate release track ID "${track.id}"');
      }
      if (!orders.add(track.order)) {
        _fail(
          r'$.releaseTracks',
          'duplicate release track order ${track.order}',
        );
      }
      byId[track.id] = track;
    }
    return byId;
  }

  void _validateSegments(
    Iterable<CanDoSegment> segments, {
    required Map<String, CanDoSegment> segmentsById,
    required Map<String, TrackEdition> editionsById,
    required Map<String, CourseUnit> unitsById,
    required Map<String, Concept> conceptsById,
    required Map<String, SegmentAssessmentAuthority> assessmentAuthoritiesById,
    required Map<String, ContentReferenceAuthority> contentAuthoritiesByKey,
    required Map<String, ContentClusterDefinition> contentClustersById,
    required Map<String, ReleaseTrackDefinition> releaseTracksById,
  }) {
    final assessmentOwners = <String, String>{};
    for (final segment in segments) {
      final path = 'segment "${segment.id}"';
      final unit = unitsById[segment.parentCourseUnitId];
      if (unit == null) {
        _fail(
          path,
          'unknown parent course unit "${segment.parentCourseUnitId}"',
        );
      }
      final unitLevel = LearnerLevel.fromCode(unit.level)!;
      if (segment.level != unitLevel) {
        _fail(
          path,
          'level ${segment.level.code} does not match parent course unit '
          '${unitLevel.code}',
        );
      }

      final ownedConceptIds = unit.requiredConceptIds.toSet();
      for (final conceptId in segment.requiredConceptIds) {
        final concept = conceptsById[conceptId];
        if (concept == null) {
          _fail(path, 'unknown required concept "$conceptId"');
        }
        if (!ownedConceptIds.contains(conceptId)) {
          _fail(
            path,
            'required concept "$conceptId" is not owned by parent course unit '
            '"${unit.id}"',
          );
        }
        final conceptLevel = LearnerLevel.fromCode(concept.level)!;
        if (conceptLevel != segment.level) {
          _fail(
            path,
            'required concept "$conceptId" has level ${conceptLevel.code}, '
            'expected ${segment.level.code}',
          );
        }
      }

      for (final clusterId in segment.contentClusterIds) {
        final cluster = contentClustersById[clusterId];
        if (cluster == null) {
          _fail(path, 'unknown content cluster "$clusterId"');
        }
        if (cluster.level != segment.level) {
          _fail(
            path,
            'content cluster "$clusterId" has level ${cluster.level.code}, '
            'expected ${segment.level.code}',
          );
        }
        for (final reference in cluster.contentReferences) {
          final authority = contentAuthoritiesByKey[reference.key]!;
          if (authority.courseUnitId != segment.parentCourseUnitId) {
            _fail(
              path,
              'content reference "${reference.key}" belongs to course unit '
              '"${authority.courseUnitId}", expected '
              '"${segment.parentCourseUnitId}"',
            );
          }
        }
      }

      final currentAssessmentIds = <String>{};
      for (final requirement in segment.assessmentRequirements) {
        final assessmentItemId = requirement.assessmentItemId;
        currentAssessmentIds.add(assessmentItemId);
        final authority = assessmentAuthoritiesById[assessmentItemId];
        if (authority == null) {
          _fail(path, 'unknown assessment item "$assessmentItemId"');
        }
        _validateAssessmentRequirement(
          segment,
          requirement,
          authority: authority,
          path: path,
        );
      }
      for (final assessmentItemId in segment.ownedAssessmentItemIds) {
        final existingOwner = assessmentOwners[assessmentItemId];
        if (existingOwner != null) {
          _fail(
            path,
            'assessment item "$assessmentItemId" is already owned by '
            'segment "$existingOwner"',
          );
        }
        assessmentOwners[assessmentItemId] = segment.id;
      }
      final missingOwned = currentAssessmentIds.difference(
        segment.ownedAssessmentItemIds.toSet(),
      );
      if (missingOwned.isNotEmpty) {
        _fail(
          path,
          'ownedAssessmentItemIds must include current requirements: '
          '${missingOwned.toList()..sort()}',
        );
      }

      if (segment.lifecycle != CanDoSegmentLifecycle.draft) {
        if (segment.requiredConceptIds.isEmpty) {
          _fail(path, 'published or retired segments require a concept');
        }
        if (segment.proofRevision <= 0) {
          _fail(
            path,
            'published or retired segments require proofRevision > 0',
          );
        }
        if (segment.assessmentRequirements.isEmpty) {
          _fail(
            path,
            'published or retired segments require assessment requirements',
          );
        }
        if (segment.ownedAssessmentItemIds.isEmpty) {
          _fail(
            path,
            'published or retired segments require owned assessment IDs',
          );
        }
        if (segment.contentClusterIds.isEmpty) {
          _fail(
            path,
            'published or retired segments require a content cluster',
          );
        }
      }

      final edition = editionsById[segment.trackEditionId];
      if (edition == null) {
        _fail(path, 'unknown track edition "${segment.trackEditionId}"');
      }
      if (edition.releaseTrackId != segment.releaseTrackId) {
        _fail(path, 'release track does not match its track edition');
      }
      if (edition.level != segment.level) {
        _fail(path, 'level does not match its track edition');
      }
      final lifecycleMatches = switch (segment.lifecycle) {
        CanDoSegmentLifecycle.draft =>
          edition.status == TrackEditionStatus.draft,
        CanDoSegmentLifecycle.published =>
          edition.status == TrackEditionStatus.published,
        CanDoSegmentLifecycle.retired =>
          edition.status == TrackEditionStatus.published ||
              edition.status == TrackEditionStatus.retired,
      };
      if (!lifecycleMatches) {
        _fail(
          path,
          '${segment.lifecycle.code} segment is incompatible with '
          '${edition.status.code} edition',
        );
      }

      final releaseTrack = releaseTracksById[segment.releaseTrackId];
      if (releaseTrack == null) {
        _fail(path, 'unknown release track "${segment.releaseTrackId}"');
      }

      final successorId = segment.successorSegmentId;
      if (successorId != null) {
        if (segment.lifecycle != CanDoSegmentLifecycle.retired) {
          _fail(path, 'only retired segments may declare a successor');
        }
        final successor = segmentsById[successorId];
        if (successor == null) {
          _fail(path, 'unknown successor segment "$successorId"');
        }
        if (successor.id == segment.id) {
          _fail(path, 'a segment cannot succeed itself');
        }
        if (successor.lifecycle == CanDoSegmentLifecycle.draft) {
          _fail(path, 'successor must be published or retired, never draft');
        }
        if (successor.level != segment.level) {
          _fail(path, 'successor must remain in the same level');
        }
        if (successor.constructLineageId != segment.constructLineageId) {
          _fail(path, 'successor must preserve the same construct lineage');
        }
        if (successor.trackEditionId == segment.trackEditionId) {
          _fail(path, 'successor must use a different additive edition');
        }
      }
    }
  }

  void _validateAssessmentRequirement(
    CanDoSegment segment,
    SegmentAssessmentRequirement requirement, {
    required SegmentAssessmentAuthority authority,
    required String path,
  }) {
    if (!authority.isAssessEdge || !authority.courseEligible) {
      _fail(
        path,
        'assessment item "${requirement.assessmentItemId}" is not an '
        'eligible assess edge',
      );
    }
    final exactConcepts = _sameStringSets(
      authority.conceptIds,
      segment.requiredConceptIds,
    );
    if (authority.missionContentLinkId != requirement.missionContentLinkId ||
        authority.level != segment.level ||
        authority.courseUnitId != segment.parentCourseUnitId ||
        !exactConcepts ||
        authority.evidenceMode != requirement.evidenceMode ||
        authority.rubricVersion != requirement.rubricVersion ||
        authority.minimumScore != requirement.minimumScore) {
      _fail(
        path,
        'assessment item "${requirement.assessmentItemId}" does not exactly '
        'match its trusted authority',
      );
    }
  }

  void _validateEditions(
    Iterable<TrackEdition> editions, {
    required Map<String, CanDoSegment> segmentsById,
    required Map<String, TrackEdition> editionsById,
    required Map<String, ReleaseTrackDefinition> releaseTracksById,
  }) {
    final membershipCounts = <String, int>{};
    for (final edition in editions) {
      final path = 'track edition "${edition.id}"';
      final releaseTrack = releaseTracksById[edition.releaseTrackId];
      if (releaseTrack == null) {
        _fail(path, 'unknown release track "${edition.releaseTrackId}"');
      }
      final statusMatches = switch (edition.status) {
        TrackEditionStatus.draft =>
          releaseTrack.status == ReleaseTrackStatus.draft,
        TrackEditionStatus.published =>
          releaseTrack.status == ReleaseTrackStatus.published,
        TrackEditionStatus.retired =>
          releaseTrack.status == ReleaseTrackStatus.published ||
              releaseTrack.status == ReleaseTrackStatus.retired,
      };
      if (!statusMatches) {
        _fail(
          path,
          '${edition.status.code} edition is incompatible with '
          '${releaseTrack.status.code} release track',
        );
      }
      final members = <CanDoSegment>[];
      for (final segmentId in edition.segmentIds) {
        final segment = segmentsById[segmentId];
        if (segment == null) {
          _fail(path, 'unknown segment "$segmentId"');
        }
        if (segment.trackEditionId != edition.id) {
          _fail(path, 'segment "$segmentId" belongs to another edition');
        }
        if (segment.releaseTrackId != edition.releaseTrackId ||
            segment.level != edition.level) {
          _fail(path, 'segment "$segmentId" has incompatible track metadata');
        }
        membershipCounts.update(
          segmentId,
          (count) => count + 1,
          ifAbsent: () => 1,
        );
        members.add(segment);
      }

      final sortedMemberIds = [...members]..sort(_compareSegments);
      final expectedIds = [for (final segment in sortedMemberIds) segment.id];
      if (!_sameStrings(edition.segmentIds, expectedIds)) {
        _fail(path, 'segmentIds must be ordered by level, order, then ID');
      }
    }

    for (final segment in segmentsById.values) {
      final count = membershipCounts[segment.id] ?? 0;
      if (count != 1) {
        _fail(
          'segment "${segment.id}"',
          'must appear exactly once in its declared track edition; found $count',
        );
      }
      if (!editionsById.containsKey(segment.trackEditionId)) {
        _fail('segment "${segment.id}"', 'declares an unknown track edition');
      }
    }
  }

  void _validateReleaseTracks(
    Iterable<ReleaseTrackDefinition> releaseTracks, {
    required Map<String, TrackEdition> editionsById,
    required Map<String, CanDoSegment> segmentsById,
    required CoreReleasePolicy coreReleasePolicy,
  }) {
    final coreTracks = releaseTracks
        .where((track) => track.kind == ReleaseTrackKind.core)
        .toList(growable: false);
    if (coreTracks.length != 1) {
      _fail(r'$.releaseTracks', 'must contain exactly one core track');
    }
    _validateCoreReleasePolicy(
      coreTracks.single,
      editionsById: editionsById,
      policy: coreReleasePolicy,
    );

    final membershipCounts = <String, int>{};
    for (final track in releaseTracks) {
      final path = 'release track "${track.id}"';
      for (final editionId in track.editionIds) {
        final edition = editionsById[editionId];
        if (edition == null) {
          _fail(path, 'unknown edition "$editionId"');
        }
        if (edition.releaseTrackId != track.id) {
          _fail(path, 'edition "$editionId" belongs to another release track');
        }
        membershipCounts.update(
          editionId,
          (count) => count + 1,
          ifAbsent: () => 1,
        );
      }
    }
    for (final edition in editionsById.values) {
      final count = membershipCounts[edition.id] ?? 0;
      if (count != 1) {
        _fail(
          'track edition "${edition.id}"',
          'must appear exactly once in releaseTracks; found $count',
        );
      }
    }

    // Ensure every segment's redundant track ID agrees with both authorities.
    for (final segment in segmentsById.values) {
      final edition = editionsById[segment.trackEditionId]!;
      if (edition.releaseTrackId != segment.releaseTrackId) {
        _fail(
          'segment "${segment.id}"',
          'release track does not match its edition',
        );
      }
    }
  }

  void _validateCoreReleasePolicy(
    ReleaseTrackDefinition coreTrack, {
    required Map<String, TrackEdition> editionsById,
    required CoreReleasePolicy policy,
  }) {
    _validateExternalId(policy.releaseTrackId, 'core release policy track');
    if (policy.segmentCountsByLevel.isEmpty) {
      _fail('core release policy', 'must declare at least one level');
    }
    for (final entry in policy.segmentCountsByLevel.entries) {
      if (entry.value <= 0) {
        _fail(
          'core release policy',
          '${entry.key.code} segment count must be positive',
        );
      }
    }
    if (coreTrack.id != policy.releaseTrackId || coreTrack.order != 1) {
      _fail(
        'release track "${coreTrack.id}"',
        'core must be ${policy.releaseTrackId} at order 1',
      );
    }

    final editionsByLevel = <LearnerLevel, TrackEdition>{};
    for (final editionId in coreTrack.editionIds) {
      final edition = editionsById[editionId];
      if (edition == null) {
        continue;
      }
      if (editionsByLevel.containsKey(edition.level)) {
        _fail(
          'release track "${coreTrack.id}"',
          'core must contain exactly one edition for ${edition.level.code}',
        );
      }
      editionsByLevel[edition.level] = edition;
    }

    final isPublished = coreTrack.status != ReleaseTrackStatus.draft;
    if (isPublished &&
        !_sameLevelSets(
          editionsByLevel.keys,
          policy.segmentCountsByLevel.keys,
        )) {
      _fail(
        'release track "${coreTrack.id}"',
        'published core levels must exactly match the product policy',
      );
    }
    for (final entry in editionsByLevel.entries) {
      final expectedCount = policy.segmentCountsByLevel[entry.key];
      if (expectedCount == null) {
        _fail(
          'release track "${coreTrack.id}"',
          'unexpected core level ${entry.key.code}',
        );
      }
      final actualCount = entry.value.segmentIds.length;
      final invalidCount = isPublished
          ? actualCount != expectedCount
          : actualCount > expectedCount;
      if (invalidCount) {
        _fail(
          'track edition "${entry.value.id}"',
          '${entry.key.code} core count is $actualCount; expected '
              '${isPublished ? expectedCount : 'at most $expectedCount'}',
        );
      }
    }
  }

  void _validateSuccessorGraph(
    Iterable<CanDoSegment> segments, {
    required Map<String, CanDoSegment> segmentsById,
    required Map<String, TrackEdition> editionsById,
    required Map<String, ReleaseTrackDefinition> releaseTracksById,
  }) {
    final predecessorBySuccessorId = <String, String>{};
    final segmentsByLineageId = <String, List<CanDoSegment>>{};
    for (final segment in segments) {
      segmentsByLineageId
          .putIfAbsent(segment.constructLineageId, () => <CanDoSegment>[])
          .add(segment);
      final edition = editionsById[segment.trackEditionId]!;
      final successorId = segment.successorSegmentId;
      if (segment.lifecycle == CanDoSegmentLifecycle.retired &&
          edition.status == TrackEditionStatus.published &&
          successorId == null) {
        _fail(
          'segment "${segment.id}"',
          'retired segment in an active edition requires a successor',
        );
      }
      if (successorId == null) {
        continue;
      }
      final existingPredecessor = predecessorBySuccessorId[successorId];
      if (existingPredecessor != null) {
        _fail(
          'segment "$successorId"',
          'cannot succeed both "$existingPredecessor" and "${segment.id}"',
        );
      }
      predecessorBySuccessorId[successorId] = segment.id;
      final successor = segmentsById[successorId]!;
      final successorEdition = editionsById[successor.trackEditionId]!;
      final sourceTrack = releaseTracksById[segment.releaseTrackId]!;
      final successorTrack = releaseTracksById[successor.releaseTrackId]!;
      if (successorEdition.status == TrackEditionStatus.draft ||
          successorTrack.status == ReleaseTrackStatus.draft ||
          successorTrack.kind != ReleaseTrackKind.extension ||
          successorTrack.order <= sourceTrack.order) {
        _fail(
          'segment "${segment.id}"',
          'successor must be in a newer non-draft additive track',
        );
      }

      final chainIds = <String>{segment.id};
      var terminal = successor;
      while (terminal.successorSegmentId != null) {
        if (!chainIds.add(terminal.id)) {
          _fail('segment "${segment.id}"', 'successor graph contains a cycle');
        }
        terminal = segmentsById[terminal.successorSegmentId!]!;
      }
      if (!chainIds.add(terminal.id)) {
        _fail('segment "${segment.id}"', 'successor graph contains a cycle');
      }
      if (terminal.lifecycle != CanDoSegmentLifecycle.published) {
        _fail(
          'segment "${segment.id}"',
          'successor chain must end in a published segment',
        );
      }
    }

    for (final entry in segmentsByLineageId.entries) {
      if (entry.value.length == 1) {
        continue;
      }
      final roots = entry.value
          .where((segment) => !predecessorBySuccessorId.containsKey(segment.id))
          .toList(growable: false);
      if (roots.length != 1) {
        _fail(
          'construct lineage "${entry.key}"',
          'must form one linear successor chain',
        );
      }
      var visitedCount = 1;
      var cursor = roots.single;
      while (cursor.successorSegmentId != null) {
        cursor = segmentsById[cursor.successorSegmentId!]!;
        visitedCount += 1;
      }
      if (visitedCount != entry.value.length) {
        _fail(
          'construct lineage "${entry.key}"',
          'contains disconnected successor records',
        );
      }
    }
  }
}

class _CourseSegmentEvolutionValidator {
  final CourseSegmentCatalog previous;
  final CourseSegmentCatalog current;

  const _CourseSegmentEvolutionValidator({
    required this.previous,
    required this.current,
  });

  void validate() {
    _validateNewContentUsesAdditiveTracks();
    _validateClusters();
    _validateLockedSegments();
    _validateLockedEditions();
    _validateLockedReleaseTracks();
  }

  void _validateNewContentUsesAdditiveTracks() {
    final previousNonDraftTracks = previous.releaseTracks
        .where((track) => track.status != ReleaseTrackStatus.draft)
        .toList(growable: false);
    final previousMaxNonDraftOrder = previousNonDraftTracks.fold<int>(
      0,
      (maximum, track) => track.order > maximum ? track.order : maximum,
    );
    final previouslyLockedTrackIds = {
      for (final track in previousNonDraftTracks) track.id,
    };
    for (final track in current.releaseTracks) {
      final previousTrack = previous.releaseTracksById[track.id];
      final becameNonDraftExtension =
          track.kind == ReleaseTrackKind.extension &&
          track.status != ReleaseTrackStatus.draft &&
          (previousTrack == null ||
              previousTrack.status == ReleaseTrackStatus.draft);
      if (becameNonDraftExtension && track.order <= previousMaxNonDraftOrder) {
        _evolutionFail(
          'new non-draft extension track "${track.id}" order ${track.order} '
          'must be strictly after previous non-draft maximum order '
          '$previousMaxNonDraftOrder',
        );
      }
    }
    for (final edition in current.editions) {
      if (previous.editionsById.containsKey(edition.id)) {
        continue;
      }
      if (previouslyLockedTrackIds.contains(edition.releaseTrackId)) {
        _evolutionFail(
          'new edition "${edition.id}" cannot attach to locked release track '
          '"${edition.releaseTrackId}"',
        );
      }
    }
    for (final segment in current.segments) {
      if (previous.segmentsById.containsKey(segment.id)) {
        continue;
      }
      final track = current.releaseTracksById[segment.releaseTrackId]!;
      final previousTrack = previous.releaseTracksById[track.id];
      if (previousTrack != null &&
          previousTrack.status != ReleaseTrackStatus.draft) {
        _evolutionFail(
          'new segment "${segment.id}" must use a new or previously draft '
          'extension release track',
        );
      }
    }
  }

  void _validateClusters() {
    final lockedClusterIds = <String>{
      for (final segment in previous.segments)
        if (segment.lifecycle != CanDoSegmentLifecycle.draft)
          ...segment.contentClusterIds,
    };
    for (final oldCluster in previous.contentClusters) {
      if (!lockedClusterIds.contains(oldCluster.id)) {
        continue;
      }
      final nextCluster = current.contentClustersById[oldCluster.id];
      if (nextCluster == null) {
        _evolutionFail('content cluster "${oldCluster.id}" cannot be deleted');
      }
      if (nextCluster.level != oldCluster.level) {
        _evolutionFail(
          'content cluster "${oldCluster.id}" cannot change level',
        );
      }
      if (nextCluster.revision < oldCluster.revision) {
        _evolutionFail(
          'content cluster "${oldCluster.id}" revision cannot decrease',
        );
      }
      if (!_startsWithStrings(
        nextCluster.sourceSeedIds,
        oldCluster.sourceSeedIds,
      )) {
        _evolutionFail(
          'content cluster "${oldCluster.id}" cannot remove or reorder '
          'source seed provenance',
        );
      }
      final sourceSeedsChanged = !_sameStrings(
        oldCluster.sourceSeedIds,
        nextCluster.sourceSeedIds,
      );
      final referencesChanged = !_sameContentReferences(
        oldCluster.contentReferences,
        nextCluster.contentReferences,
      );
      if ((sourceSeedsChanged || referencesChanged) &&
          nextCluster.revision <= oldCluster.revision) {
        _evolutionFail(
          'content cluster "${oldCluster.id}" provenance or reference '
          'changes require a revision increase',
        );
      }
    }
  }

  void _validateLockedSegments() {
    for (final oldSegment in previous.segments) {
      if (oldSegment.lifecycle == CanDoSegmentLifecycle.draft) {
        continue;
      }
      final nextSegment = current.segmentsById[oldSegment.id];
      if (nextSegment == null) {
        _evolutionFail('segment "${oldSegment.id}" cannot be deleted');
      }
      if (nextSegment.constructLineageId != oldSegment.constructLineageId ||
          nextSegment.parentCourseUnitId != oldSegment.parentCourseUnitId ||
          nextSegment.level != oldSegment.level ||
          nextSegment.order != oldSegment.order ||
          !_sameStrings(
            nextSegment.requiredConceptIds,
            oldSegment.requiredConceptIds,
          ) ||
          !_sameStrings(
            nextSegment.contentClusterIds,
            oldSegment.contentClusterIds,
          ) ||
          nextSegment.releaseTrackId != oldSegment.releaseTrackId ||
          nextSegment.trackEditionId != oldSegment.trackEditionId) {
        _evolutionFail(
          'segment "${oldSegment.id}" changed immutable identity fields',
        );
      }
      if (nextSegment.canDo.ko != oldSegment.canDo.ko) {
        _evolutionFail(
          'segment "${oldSegment.id}" changed immutable Korean can-do',
        );
      }
      final nextOwned = nextSegment.ownedAssessmentItemIds.toSet();
      final removedOwned = oldSegment.ownedAssessmentItemIds
          .where((id) => !nextOwned.contains(id))
          .toList(growable: false);
      if (removedOwned.isNotEmpty) {
        _evolutionFail(
          'segment "${oldSegment.id}" cannot remove owned assessment IDs: '
          '$removedOwned',
        );
      }
      if (nextSegment.proofRevision < oldSegment.proofRevision) {
        _evolutionFail(
          'segment "${oldSegment.id}" proofRevision cannot decrease',
        );
      }
      final assessmentChanged = !_sameAssessmentRequirements(
        oldSegment.assessmentRequirements,
        nextSegment.assessmentRequirements,
      );
      final oldRequirementsById = {
        for (final requirement in oldSegment.assessmentRequirements)
          requirement.assessmentItemId: requirement,
      };
      for (final requirement in nextSegment.assessmentRequirements) {
        final oldRequirement =
            oldRequirementsById[requirement.assessmentItemId];
        if (oldRequirement == null) {
          continue;
        }
        if (requirement.rubricVersion < oldRequirement.rubricVersion ||
            requirement.minimumScore < oldRequirement.minimumScore) {
          _evolutionFail(
            'segment "${oldSegment.id}" cannot weaken rubric or minimumScore '
            'for assessment "${requirement.assessmentItemId}"',
          );
        }
      }
      if (assessmentChanged &&
          nextSegment.proofRevision <= oldSegment.proofRevision) {
        _evolutionFail(
          'segment "${oldSegment.id}" assessment changes require a '
          'proofRevision increase',
        );
      }
      if (!_allowedSegmentTransition(
        oldSegment.lifecycle,
        nextSegment.lifecycle,
      )) {
        _evolutionFail(
          'segment "${oldSegment.id}" cannot transition from '
          '${oldSegment.lifecycle.code} to ${nextSegment.lifecycle.code}',
        );
      }
      if (oldSegment.successorSegmentId != null &&
          nextSegment.successorSegmentId != oldSegment.successorSegmentId) {
        _evolutionFail(
          'segment "${oldSegment.id}" successor cannot change once assigned',
        );
      }
    }
  }

  void _validateLockedEditions() {
    for (final oldEdition in previous.editions) {
      if (oldEdition.status == TrackEditionStatus.draft) {
        continue;
      }
      final nextEdition = current.editionsById[oldEdition.id];
      if (nextEdition == null) {
        _evolutionFail('track edition "${oldEdition.id}" cannot be deleted');
      }
      if (nextEdition.releaseTrackId != oldEdition.releaseTrackId ||
          nextEdition.level != oldEdition.level ||
          !_sameStrings(nextEdition.segmentIds, oldEdition.segmentIds) ||
          nextEdition.publishedAt != oldEdition.publishedAt) {
        _evolutionFail(
          'track edition "${oldEdition.id}" changed immutable publication '
          'fields',
        );
      }
      if (!_allowedEditionTransition(oldEdition.status, nextEdition.status)) {
        _evolutionFail(
          'track edition "${oldEdition.id}" cannot transition from '
          '${oldEdition.status.code} to ${nextEdition.status.code}',
        );
      }
    }
  }

  void _validateLockedReleaseTracks() {
    for (final oldTrack in previous.releaseTracks) {
      if (oldTrack.status == ReleaseTrackStatus.draft) {
        continue;
      }
      final nextTrack = current.releaseTracksById[oldTrack.id];
      if (nextTrack == null) {
        _evolutionFail('release track "${oldTrack.id}" cannot be deleted');
      }
      if (nextTrack.kind != oldTrack.kind ||
          nextTrack.order != oldTrack.order ||
          !_sameStrings(nextTrack.editionIds, oldTrack.editionIds) ||
          nextTrack.publishedAt != oldTrack.publishedAt) {
        _evolutionFail(
          'release track "${oldTrack.id}" changed immutable publication '
          'fields',
        );
      }
      if (!_allowedReleaseTrackTransition(oldTrack.status, nextTrack.status)) {
        _evolutionFail(
          'release track "${oldTrack.id}" cannot transition from '
          '${oldTrack.status.code} to ${nextTrack.status.code}',
        );
      }
    }
  }
}

bool _allowedSegmentTransition(
  CanDoSegmentLifecycle previous,
  CanDoSegmentLifecycle current,
) {
  return switch (previous) {
    CanDoSegmentLifecycle.draft => true,
    CanDoSegmentLifecycle.published =>
      current == CanDoSegmentLifecycle.published ||
          current == CanDoSegmentLifecycle.retired,
    CanDoSegmentLifecycle.retired => current == CanDoSegmentLifecycle.retired,
  };
}

bool _allowedEditionTransition(
  TrackEditionStatus previous,
  TrackEditionStatus current,
) {
  return switch (previous) {
    TrackEditionStatus.draft => true,
    TrackEditionStatus.published =>
      current == TrackEditionStatus.published ||
          current == TrackEditionStatus.retired,
    TrackEditionStatus.retired => current == TrackEditionStatus.retired,
  };
}

bool _allowedReleaseTrackTransition(
  ReleaseTrackStatus previous,
  ReleaseTrackStatus current,
) {
  return switch (previous) {
    ReleaseTrackStatus.draft => true,
    ReleaseTrackStatus.published =>
      current == ReleaseTrackStatus.published ||
          current == ReleaseTrackStatus.retired,
    ReleaseTrackStatus.retired => current == ReleaseTrackStatus.retired,
  };
}

bool _sameAssessmentRequirements(
  List<SegmentAssessmentRequirement> left,
  List<SegmentAssessmentRequirement> right,
) {
  if (left.length != right.length) {
    return false;
  }
  for (var index = 0; index < left.length; index++) {
    final leftRequirement = left[index];
    final rightRequirement = right[index];
    if (leftRequirement.assessmentItemId != rightRequirement.assessmentItemId ||
        leftRequirement.missionContentLinkId !=
            rightRequirement.missionContentLinkId ||
        leftRequirement.evidenceMode != rightRequirement.evidenceMode ||
        leftRequirement.rubricVersion != rightRequirement.rubricVersion ||
        leftRequirement.minimumScore != rightRequirement.minimumScore) {
      return false;
    }
  }
  return true;
}

bool _sameContentReferences(
  List<ContentReference> left,
  List<ContentReference> right,
) {
  if (left.length != right.length) {
    return false;
  }
  for (var index = 0; index < left.length; index++) {
    if (left[index].kind != right[index].kind ||
        left[index].id != right[index].id) {
      return false;
    }
  }
  return true;
}

Never _evolutionFail(String message) {
  throw FormatException('catalog evolution: $message');
}

int _compareSegments(CanDoSegment left, CanDoSegment right) {
  final levelOrder = left.level.rank.compareTo(right.level.rank);
  if (levelOrder != 0) {
    return levelOrder;
  }
  final order = left.order.compareTo(right.order);
  if (order != 0) {
    return order;
  }
  return left.id.compareTo(right.id);
}

CurriculumText _readText(Object? raw, String path) {
  final map = _readMap(raw, path);
  _requireKeys(map, required: const {'ko', 'de', 'en'}, path: path);
  return CurriculumText(
    ko: _readString(map['ko'], '$path.ko'),
    de: _readString(map['de'], '$path.de'),
    en: _readString(map['en'], '$path.en'),
  );
}

LearnerLevel _readLevel(Object? raw, String path) {
  final code = _readString(raw, path);
  final level = LearnerLevel.fromCode(code);
  if (level == null || level.code != code) {
    _fail(path, 'unknown or non-canonical learner level "$code"');
  }
  return level;
}

CanDoSegmentLifecycle _readLifecycle(Object? raw, String path) {
  final code = _readString(raw, path);
  final lifecycle = CanDoSegmentLifecycleX.tryFromCode(code);
  if (lifecycle == null) {
    _fail(path, 'unknown segment lifecycle "$code"');
  }
  return lifecycle;
}

List<String> _readIdList(Object? raw, String path) {
  final values = _readList(raw, path);
  final result = <String>[];
  final seen = <String>{};
  for (var index = 0; index < values.length; index++) {
    final id = _readId(values[index], '$path[$index]');
    if (!seen.add(id)) {
      _fail(path, 'duplicate ID "$id"');
    }
    result.add(id);
  }
  return result;
}

Map<String, dynamic> _readMap(Object? raw, String path) {
  if (raw is! Map) {
    _fail(path, 'must be an object');
  }
  final result = <String, dynamic>{};
  for (final entry in raw.entries) {
    if (entry.key is! String) {
      _fail(path, 'must use string keys');
    }
    result[entry.key as String] = entry.value;
  }
  return result;
}

List<Object?> _readList(Object? raw, String path) {
  if (raw is! List) {
    _fail(path, 'must be an array');
  }
  return List<Object?>.from(raw);
}

final RegExp _stableIdPattern = RegExp(r'^[a-z0-9][a-z0-9_.-]*$');

String _readId(Object? raw, String path) {
  final id = _readString(raw, path);
  if (!_stableIdPattern.hasMatch(id)) {
    _fail(path, r'must match [a-z0-9][a-z0-9_.-]*');
  }
  return id;
}

String _readString(Object? raw, String path) {
  if (raw is! String || raw.isEmpty || raw.trim() != raw) {
    _fail(path, 'must be a nonempty, trimmed string');
  }
  return raw;
}

int _readInt(Object? raw, String path) {
  if (raw is! int) {
    _fail(path, 'must be an integer');
  }
  return raw;
}

double _readDouble(Object? raw, String path) {
  if (raw is! num) {
    _fail(path, 'must be a number');
  }
  return raw.toDouble();
}

DateTime? _readPublicationTime(
  Map<String, dynamic> map, {
  required String path,
  required bool isDraft,
  required String ownerLabel,
}) {
  if (isDraft) {
    if (map.containsKey('publishedAt')) {
      _fail('$path.publishedAt', 'is forbidden for a draft $ownerLabel');
    }
    return null;
  }
  if (!map.containsKey('publishedAt')) {
    _fail(
      '$path.publishedAt',
      'is required for a published or retired $ownerLabel',
    );
  }
  final rawPublishedAt = _readString(map['publishedAt'], '$path.publishedAt');
  final publishedAt = DateTime.tryParse(rawPublishedAt);
  if (publishedAt == null ||
      !publishedAt.isUtc ||
      rawPublishedAt != publishedAt.toUtc().toIso8601String()) {
    _fail('$path.publishedAt', 'must be a canonical UTC timestamp');
  }
  return publishedAt;
}

void _requireKeys(
  Map<String, dynamic> map, {
  required Set<String> required,
  Set<String> optional = const {},
  required String path,
}) {
  final missing = required.difference(map.keys.toSet()).toList()..sort();
  if (missing.isNotEmpty) {
    _fail(path, 'missing keys: ${missing.join(', ')}');
  }
  final allowed = {...required, ...optional};
  final unknown = map.keys.toSet().difference(allowed).toList()..sort();
  if (unknown.isNotEmpty) {
    _fail(path, 'unknown keys: ${unknown.join(', ')}');
  }
}

void _validateExternalId(String id, String label) {
  if (!_stableIdPattern.hasMatch(id)) {
    _fail(label, r'ID must match [a-z0-9][a-z0-9_.-]*');
  }
}

bool _sameStrings(List<String> left, List<String> right) {
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

bool _startsWithStrings(List<String> values, List<String> prefix) {
  if (values.length < prefix.length) {
    return false;
  }
  for (var index = 0; index < prefix.length; index++) {
    if (values[index] != prefix[index]) {
      return false;
    }
  }
  return true;
}

bool _sameStringSets(Iterable<String> left, Iterable<String> right) {
  final leftSet = left.toSet();
  final rightSet = right.toSet();
  return leftSet.length == rightSet.length && leftSet.containsAll(rightSet);
}

bool _sameLevelSets(Iterable<LearnerLevel> left, Iterable<LearnerLevel> right) {
  final leftSet = left.toSet();
  final rightSet = right.toSet();
  return leftSet.length == rightSet.length && leftSet.containsAll(rightSet);
}

Never _fail(String path, String message) {
  throw FormatException('$path: $message');
}
