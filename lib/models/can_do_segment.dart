import 'curriculum.dart';
import 'learner_level.dart';

/// A typed reference to practice content used by a revisioned content cluster.
///
/// This is intentionally independent of [CurriculumContentKind]. A vocabulary
/// pack and a project are segment-level learning resources rather than legacy
/// curriculum graph nodes.
enum ContentReferenceKind {
  vocabPack,
  grammar,
  smalltalk,
  cloze,
  satz,
  scenario,
  project,
}

extension ContentReferenceKindX on ContentReferenceKind {
  String get code => name;

  static ContentReferenceKind? tryFromCode(String? value) {
    for (final kind in ContentReferenceKind.values) {
      if (kind.code == value) {
        return kind;
      }
    }
    return null;
  }
}

/// Productive proof modes that can contribute to verified segment mastery.
enum SegmentEvidenceMode {
  guidedProduction,
  dictation,
  connectedProduction,
  openWriting,
  oralProduction,
  connectedEvidence,
}

/// How multiple assessment requirements combine for one segment.
///
/// V1 intentionally supports only an all-of contract: every declared
/// requirement must have eligible evidence before the segment is verified.
enum SegmentEvidencePolicy { allOf }

extension SegmentEvidencePolicyX on SegmentEvidencePolicy {
  String get code => name;

  static SegmentEvidencePolicy? tryFromCode(String? value) {
    for (final policy in SegmentEvidencePolicy.values) {
      if (policy.code == value) {
        return policy;
      }
    }
    return null;
  }
}

extension SegmentEvidenceModeX on SegmentEvidenceMode {
  String get code => name;

  static SegmentEvidenceMode? tryFromCode(String? value) {
    for (final mode in SegmentEvidenceMode.values) {
      if (mode.code == value) {
        return mode;
      }
    }
    return null;
  }
}

enum CanDoSegmentLifecycle { draft, published, retired }

extension CanDoSegmentLifecycleX on CanDoSegmentLifecycle {
  String get code => name;

  static CanDoSegmentLifecycle? tryFromCode(String? value) {
    for (final lifecycle in CanDoSegmentLifecycle.values) {
      if (lifecycle.code == value) {
        return lifecycle;
      }
    }
    return null;
  }
}

enum TrackEditionStatus { draft, published, retired }

extension TrackEditionStatusX on TrackEditionStatus {
  String get code => name;

  static TrackEditionStatus? tryFromCode(String? value) {
    for (final status in TrackEditionStatus.values) {
      if (status.code == value) {
        return status;
      }
    }
    return null;
  }
}

enum ReleaseTrackKind { core, extension }

extension ReleaseTrackKindX on ReleaseTrackKind {
  String get code => name;

  static ReleaseTrackKind? tryFromCode(String? value) {
    for (final kind in ReleaseTrackKind.values) {
      if (kind.code == value) {
        return kind;
      }
    }
    return null;
  }
}

enum ReleaseTrackStatus { draft, published, retired }

extension ReleaseTrackStatusX on ReleaseTrackStatus {
  String get code => name;

  static ReleaseTrackStatus? tryFromCode(String? value) {
    for (final status in ReleaseTrackStatus.values) {
      if (status.code == value) {
        return status;
      }
    }
    return null;
  }
}

class ContentReference {
  final ContentReferenceKind kind;
  final String id;

  const ContentReference({required this.kind, required this.id});

  String get key => '${kind.code}:$id';

  Map<String, String> toJson() => {'kind': kind.code, 'id': id};
}

/// Trusted metadata for a bundled practice-content reference.
///
/// The catalog decoder receives these authorities from the content loaders so
/// a cluster cannot silently route learners across levels, source seeds, or
/// owning course units.
class ContentReferenceAuthority {
  final ContentReference reference;
  final LearnerLevel level;
  final String sourceSeedId;
  final String courseUnitId;

  const ContentReferenceAuthority({
    required this.reference,
    required this.level,
    required this.sourceSeedId,
    required this.courseUnitId,
  });
}

/// Trusted provenance for one independently authored situation seed.
///
/// A seed may produce multiple practice modalities, but it never owns mastery
/// or a reward denominator. Its level is checked before a cluster can cite it.
class ContentSeedAuthority {
  final String id;
  final LearnerLevel level;

  const ContentSeedAuthority({required this.id, required this.level});
}

/// Revisioned practice routing for one or more stable can-do segments.
///
/// Adding practice for the same ability increments [revision] without changing
/// segment or edition identity. A genuinely new can-do receives a new segment
/// in a new additive edition, so previously published denominators stay fixed.
class ContentClusterDefinition {
  final String id;
  final LearnerLevel level;
  final int revision;
  final List<String> sourceSeedIds;
  final List<ContentReference> contentReferences;

  ContentClusterDefinition({
    required this.id,
    required this.level,
    required this.revision,
    required Iterable<String> sourceSeedIds,
    required Iterable<ContentReference> contentReferences,
  }) : sourceSeedIds = List.unmodifiable(sourceSeedIds),
       contentReferences = List.unmodifiable(contentReferences);

  Map<String, dynamic> toJson() => {
    'id': id,
    'level': level.code,
    'revision': revision,
    'sourceSeedIds': sourceSeedIds,
    'contentReferences': [
      for (final reference in contentReferences) reference.toJson(),
    ],
  };
}

/// The exact assessment contract that can verify one segment.
class SegmentAssessmentRequirement {
  final String assessmentItemId;
  final String missionContentLinkId;
  final SegmentEvidenceMode evidenceMode;
  final int rubricVersion;
  final double minimumScore;

  const SegmentAssessmentRequirement({
    required this.assessmentItemId,
    required this.missionContentLinkId,
    required this.evidenceMode,
    required this.rubricVersion,
    required this.minimumScore,
  });

  Map<String, dynamic> toJson() => {
    'assessmentItemId': assessmentItemId,
    'missionContentLinkId': missionContentLinkId,
    'evidenceMode': evidenceMode.code,
    'rubricVersion': rubricVersion,
    'minimumScore': minimumScore,
  };
}

/// Trusted assessment metadata supplied by the mission/assessment catalog.
///
/// A segment declaration must exactly match this authority. This prevents a
/// recognition item from being relabelled as productive evidence in JSON.
class SegmentAssessmentAuthority {
  final String assessmentItemId;
  final String missionContentLinkId;
  final LearnerLevel level;
  final String courseUnitId;
  final List<String> conceptIds;
  final SegmentEvidenceMode evidenceMode;
  final int rubricVersion;
  final double minimumScore;
  final bool isAssessEdge;
  final bool courseEligible;

  SegmentAssessmentAuthority({
    required this.assessmentItemId,
    required this.missionContentLinkId,
    required this.level,
    required this.courseUnitId,
    required Iterable<String> conceptIds,
    required this.evidenceMode,
    required this.rubricVersion,
    required this.minimumScore,
    required this.isAssessEdge,
    required this.courseEligible,
  }) : conceptIds = List.unmodifiable(conceptIds);
}

/// A stable, assessable ability inside a broader [CourseUnit].
///
/// Course units remain the navigation and prerequisite boundary. Segment IDs
/// are the immutable mastery boundary that may later drive durable rewards.
class CanDoSegment {
  final String id;
  final String constructLineageId;
  final String parentCourseUnitId;
  final LearnerLevel level;
  final int order;
  final CurriculumText title;
  final CurriculumText canDo;
  final List<String> requiredConceptIds;
  final List<String> contentClusterIds;
  final int proofRevision;
  final SegmentEvidencePolicy evidencePolicy;
  final List<SegmentAssessmentRequirement> assessmentRequirements;
  final List<String> ownedAssessmentItemIds;
  final String releaseTrackId;
  final String trackEditionId;
  final CanDoSegmentLifecycle lifecycle;
  final String? successorSegmentId;

  CanDoSegment({
    required this.id,
    required this.constructLineageId,
    required this.parentCourseUnitId,
    required this.level,
    required this.order,
    required this.title,
    required this.canDo,
    required Iterable<String> requiredConceptIds,
    required Iterable<String> contentClusterIds,
    required this.proofRevision,
    required this.evidencePolicy,
    required Iterable<SegmentAssessmentRequirement> assessmentRequirements,
    required Iterable<String> ownedAssessmentItemIds,
    required this.releaseTrackId,
    required this.trackEditionId,
    required this.lifecycle,
    this.successorSegmentId,
  }) : requiredConceptIds = List.unmodifiable(requiredConceptIds),
       contentClusterIds = List.unmodifiable(contentClusterIds),
       assessmentRequirements = List.unmodifiable(assessmentRequirements),
       ownedAssessmentItemIds = List.unmodifiable(ownedAssessmentItemIds);

  /// Unique proof modes in declaration order, derived from exact requirements.
  List<SegmentEvidenceMode> get requiredEvidenceModes {
    final seen = <SegmentEvidenceMode>{};
    return List.unmodifiable([
      for (final requirement in assessmentRequirements)
        if (seen.add(requirement.evidenceMode)) requirement.evidenceMode,
    ]);
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'constructLineageId': constructLineageId,
    'parentCourseUnitId': parentCourseUnitId,
    'level': level.code,
    'order': order,
    'title': title.toJson(),
    'canDo': canDo.toJson(),
    'requiredConceptIds': requiredConceptIds,
    'contentClusterIds': contentClusterIds,
    'proofRevision': proofRevision,
    'evidencePolicy': evidencePolicy.code,
    'assessmentRequirements': [
      for (final requirement in assessmentRequirements) requirement.toJson(),
    ],
    'ownedAssessmentItemIds': ownedAssessmentItemIds,
    'releaseTrackId': releaseTrackId,
    'trackEditionId': trackEditionId,
    'lifecycle': lifecycle.code,
    if (successorSegmentId != null) 'successorSegmentId': successorSegmentId,
  };
}

/// Product policy for the one immutable core release track.
///
/// The catalog validator always uses [hanokV1CoreReleasePolicy].
class CoreReleasePolicy {
  final String releaseTrackId;
  final Map<LearnerLevel, int> segmentCountsByLevel;

  CoreReleasePolicy({
    required this.releaseTrackId,
    required Map<LearnerLevel, int> segmentCountsByLevel,
  }) : segmentCountsByLevel = Map.unmodifiable(segmentCountsByLevel);

  int get totalSegments => segmentCountsByLevel.values.fold(0, (a, b) => a + b);
}

/// Living Hanok V1's published core denominator. Later abilities must use a
/// separate extension track and cannot mutate these six edition slots.
final CoreReleasePolicy hanokV1CoreReleasePolicy = CoreReleasePolicy(
  releaseTrackId: 'core_2026_v1',
  segmentCountsByLevel: const {
    LearnerLevel.a1: 16,
    LearnerLevel.a2: 16,
    LearnerLevel.b1: 18,
    LearnerLevel.b2: 20,
    LearnerLevel.c1: 8,
    LearnerLevel.c2: 8,
  },
);

/// A release-level immutable progress denominator spanning per-level editions.
///
/// The initial core track owns six editions. Later abilities are published in
/// a separate extension track so the original core total never grows.
class ReleaseTrackDefinition {
  final String id;
  final ReleaseTrackKind kind;
  final int order;
  final CurriculumText title;
  final List<String> editionIds;
  final DateTime? publishedAt;
  final ReleaseTrackStatus status;

  ReleaseTrackDefinition({
    required this.id,
    required this.kind,
    required this.order,
    required this.title,
    required Iterable<String> editionIds,
    required this.publishedAt,
    required this.status,
  }) : editionIds = List.unmodifiable(editionIds);

  Map<String, dynamic> toJson() => {
    'id': id,
    'kind': kind.code,
    'order': order,
    'title': title.toJson(),
    'editionIds': editionIds,
    if (publishedAt != null)
      'publishedAt': publishedAt!.toUtc().toIso8601String(),
    'status': status.code,
  };
}

/// An immutable denominator for one level of a release track.
///
/// Published editions never absorb later segment IDs. New can-do abilities use
/// a new additive edition, while old editions retain their original denominator.
class TrackEdition {
  final String id;
  final String releaseTrackId;
  final LearnerLevel level;
  final List<String> segmentIds;
  final DateTime? publishedAt;
  final TrackEditionStatus status;

  TrackEdition({
    required this.id,
    required this.releaseTrackId,
    required this.level,
    required Iterable<String> segmentIds,
    required this.publishedAt,
    required this.status,
  }) : segmentIds = List.unmodifiable(segmentIds);

  Map<String, dynamic> toJson() => {
    'id': id,
    'releaseTrackId': releaseTrackId,
    'level': level.code,
    'segmentIds': segmentIds,
    if (publishedAt != null)
      'publishedAt': publishedAt!.toUtc().toIso8601String(),
    'status': status.code,
  };
}
