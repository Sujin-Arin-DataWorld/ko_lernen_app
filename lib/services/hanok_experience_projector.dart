import '../models/can_do_segment.dart';
import '../models/course_mastery.dart';
import '../models/hanok_growth.dart';
import '../models/learner_level.dart';
import '../models/personal_room.dart';
import '../models/room_layout.dart';
import 'course_segment_catalog.dart';
import 'hanok_grant_catalog.dart';
import 'productive_assessment_service.dart';

/// Pure Living Hanok V1 projection.
///
/// Permanent ownership comes only from trusted productive segment evidence.
/// CourseUnit completion opens reassessment but cannot earn a grant by itself.
final class HanokExperienceProjector {
  const HanokExperienceProjector();

  HanokExperienceProjection project({
    required CourseMasterySnapshot courseMastery,
    required CourseSegmentCatalog segmentCatalog,
    required ProductiveAssessmentCatalog assessmentCatalog,
    required HanokGrantCatalog grantCatalog,
    required HanokState state,
    required DateTime asOf,
    RoomLayouts roomLayouts = const {},
  }) {
    if (!asOf.isUtc) {
      throw const FormatException('Hanok projection requires UTC.');
    }
    final verified = verifiedCanDoSegmentIds(
      evidence: courseMastery.rewardProductiveEvidence,
      projectStepEvidence: courseMastery.rewardProductiveProjectStepEvidence,
      segmentCatalog: segmentCatalog,
      assessmentCatalog: assessmentCatalog,
    );
    final completedUnits = courseMastery.completedUnitIds.toSet()
      ..removeAll(courseMastery.bypassedPrerequisiteUnitIds);
    final reassessmentEligible = <String>{
      for (final segment in segmentCatalog.publishedSegments)
        if (completedUnits.contains(segment.parentCourseUnitId) &&
            !verified.contains(segment.id))
          segment.id,
    };

    final earned = <HanokGrantDefinition>[];
    final earnedIds = <String>{};
    for (final grant in grantCatalog.grants) {
      if (_slotIsVerified(grant, verified, segmentCatalog) &&
          grant.prerequisiteGrantIds.every(earnedIds.contains)) {
        earned.add(grant);
        earnedIds.add(grant.id);
      }
    }
    final a1 = grantCatalog.grants
        .where(
          (grant) =>
              grant.level == LearnerLevel.a1 &&
              grant.kind == HanokGrantKind.constructionPiece,
        )
        .toList(growable: false);
    var a1ConstructionStep = 0;
    for (final grant in a1) {
      if (!earnedIds.contains(grant.id)) {
        break;
      }
      a1ConstructionStep += 1;
    }

    final openedVenues = <PersonalRoomSurface>{
      for (final grant in earned)
        if (grant.venueSurface != null) grant.venueSurface!,
    };
    final options = <HanokDesignSlot, List<HanokGrantDefinition>>{};
    for (final grant in earned) {
      final slot = grant.designSlot;
      if (slot != null) {
        options.putIfAbsent(slot, () => <HanokGrantDefinition>[]).add(grant);
      }
    }
    final activeLoadout = <HanokDesignSlot, HanokGrantDefinition>{};
    for (final entry in state.activeLoadout.entries) {
      final slot = HanokDesignSlot.fromCode(entry.key);
      final grant = grantCatalog.grantsById[entry.value.grantId];
      if (slot != null &&
          grant != null &&
          grant.designSlot == slot &&
          earnedIds.contains(grant.id)) {
        activeLoadout[slot] = grant;
      }
    }

    final progress = <HanokTrackProgress>[];
    for (final track in segmentCatalog.releaseTracks) {
      if (track.status == ReleaseTrackStatus.draft ||
          !track.kind.contributesToLearnerDenominator) {
        continue;
      }
      var earnedSlots = 0;
      for (final editionId in track.editionIds) {
        final edition = segmentCatalog.findEdition(editionId)!;
        if (edition.status == TrackEditionStatus.draft) {
          continue;
        }
        for (final segmentId in edition.segmentIds) {
          final satisfying = segmentCatalog.satisfyingSegmentIdsForEditionSlot(
            editionId: editionId,
            segmentId: segmentId,
          );
          if (satisfying.any(verified.contains)) {
            earnedSlots += 1;
          }
        }
      }
      progress.add(
        HanokTrackProgress(
          releaseTrackId: track.id,
          earned: earnedSlots,
          total: segmentCatalog.denominatorForReleaseTrack(track.id),
        ),
      );
    }

    final currentEra = earned.isEmpty ? HanokGrowthEra.build : earned.last.era;
    final nextGrant = _firstAttainableGrant(
      grantCatalog.grants,
      earnedIds: earnedIds,
      bypassedCourseUnitIds: courseMastery.bypassedPrerequisiteUnitIds.toSet(),
      segmentCatalog: segmentCatalog,
    );
    return HanokExperienceProjection(
      verifiedCanDoSegmentIds: verified,
      reassessmentEligibleSegmentIds: reassessmentEligible,
      earnedGrants: earned,
      a1ConstructionStep: a1ConstructionStep,
      currentEra: currentEra,
      openedVenues: openedVenues,
      availableDesignOptions: options,
      activeLoadout: activeLoadout,
      weatheringTier: state.careState.weatheringAt(asOf),
      nextGrant: nextGrant,
      nextGrantProgress: nextGrant == null
          ? 0.0
          : _bestSatisfyingProgress(
              nextGrant,
              courseMastery: courseMastery,
              segmentCatalog: segmentCatalog,
              assessmentCatalog: assessmentCatalog,
            ),
      trackProgress: progress,
      roomLayouts: partitionRoomLayouts(
        roomLayouts: roomLayouts,
        openedVenues: openedVenues,
      ),
    );
  }

  List<HanokGrantReceipt> receiptsBetween({
    required CourseMasterySnapshot before,
    required CourseMasterySnapshot after,
    required CourseSegmentCatalog segmentCatalog,
    required ProductiveAssessmentCatalog assessmentCatalog,
    required HanokGrantCatalog grantCatalog,
    required HanokState state,
    required DateTime asOf,
  }) {
    final beforeProjection = project(
      courseMastery: before,
      segmentCatalog: segmentCatalog,
      assessmentCatalog: assessmentCatalog,
      grantCatalog: grantCatalog,
      state: state,
      asOf: asOf,
    );
    final afterProjection = project(
      courseMastery: after,
      segmentCatalog: segmentCatalog,
      assessmentCatalog: assessmentCatalog,
      grantCatalog: grantCatalog,
      state: state,
      asOf: asOf,
    );
    final beforeIds = beforeProjection.earnedGrantIds;
    final trustedEvidence = trustedProductiveMasteryEvidence(
      evidence: after.rewardProductiveEvidence,
      assessmentCatalog: assessmentCatalog,
    );
    final receipts = <HanokGrantReceipt>[];
    for (final grant in afterProjection.earnedGrants) {
      if (beforeIds.contains(grant.id)) {
        continue;
      }
      final slot = segmentCatalog.findSegment(grant.canDoSegmentId)!;
      final satisfyingIds = segmentCatalog.satisfyingSegmentIdsForEditionSlot(
        editionId: slot.trackEditionId,
        segmentId: slot.id,
      );
      final candidates =
          trustedEvidence
              .where((item) => satisfyingIds.contains(item.canDoSegmentId))
              .toList(growable: false)
            ..sort((left, right) {
              final time = right.occurredAt.compareTo(left.occurredAt);
              return time != 0 ? time : left.id.compareTo(right.id);
            });
      if (candidates.isEmpty) {
        throw const FormatException('Earned Hanok grant has no trusted proof.');
      }
      final evidence = candidates.first;
      receipts.add(
        HanokGrantReceipt(
          sourceCourseUnitId: evidence.courseUnitId,
          sourceCanDoSegmentId: evidence.canDoSegmentId,
          newGrantIds: [grant.id],
          revealAssetIds: grant.revealAssetIds,
          earnedExpressionKey: evidence.assessmentItemId,
          evidenceId: evidence.id,
        ),
      );
    }
    return List.unmodifiable(receipts);
  }

  HanokRoomLayoutProjection partitionRoomLayouts({
    required RoomLayouts roomLayouts,
    required Set<PersonalRoomSurface> openedVenues,
  }) {
    final active = <PersonalRoomSurface, RoomLayout>{};
    final dormant = <PersonalRoomSurface, RoomLayout>{};
    for (final entry in roomLayouts.entries) {
      final target = openedVenues.contains(entry.key) ? active : dormant;
      target[entry.key] = List<RoomLayoutItem>.from(entry.value);
    }
    return HanokRoomLayoutProjection(active: active, dormant: dormant);
  }
}

HanokGrantDefinition? _firstAttainableGrant(
  Iterable<HanokGrantDefinition> grants, {
  required Set<String> earnedIds,
  required Set<String> bypassedCourseUnitIds,
  required CourseSegmentCatalog segmentCatalog,
}) {
  for (final grant in grants) {
    if (earnedIds.contains(grant.id) ||
        !grant.prerequisiteGrantIds.every(earnedIds.contains)) {
      continue;
    }
    final segment = segmentCatalog.findSegment(grant.canDoSegmentId)!;
    final attainable = segmentCatalog
        .satisfyingSegmentIdsForEditionSlot(
          editionId: segment.trackEditionId,
          segmentId: segment.id,
        )
        .map(segmentCatalog.findSegment)
        .whereType<CanDoSegment>()
        .any(
          (candidate) =>
              !bypassedCourseUnitIds.contains(candidate.parentCourseUnitId),
        );
    if (attainable) {
      return grant;
    }
  }
  return null;
}

bool _slotIsVerified(
  HanokGrantDefinition grant,
  Set<String> verified,
  CourseSegmentCatalog segmentCatalog,
) {
  final segment = segmentCatalog.findSegment(grant.canDoSegmentId)!;
  return segmentCatalog
      .satisfyingSegmentIdsForEditionSlot(
        editionId: segment.trackEditionId,
        segmentId: segment.id,
      )
      .any(verified.contains);
}

/// The furthest-along evidence progress across every segment id that could
/// satisfy [grant]'s slot — mirrors [_slotIsVerified]'s "any satisfying
/// segment" semantics, so this reaches exactly 1.0 whenever [_slotIsVerified]
/// would first become true.
double _bestSatisfyingProgress(
  HanokGrantDefinition grant, {
  required CourseMasterySnapshot courseMastery,
  required CourseSegmentCatalog segmentCatalog,
  required ProductiveAssessmentCatalog assessmentCatalog,
}) {
  final segment = segmentCatalog.findSegment(grant.canDoSegmentId)!;
  final candidateIds = segmentCatalog.satisfyingSegmentIdsForEditionSlot(
    editionId: segment.trackEditionId,
    segmentId: segment.id,
  );
  var best = 0.0;
  for (final candidateId in candidateIds) {
    final progress = canDoSegmentEvidenceProgress(
      segmentId: candidateId,
      evidence: courseMastery.rewardProductiveEvidence,
      projectStepEvidence: courseMastery.rewardProductiveProjectStepEvidence,
      segmentCatalog: segmentCatalog,
      assessmentCatalog: assessmentCatalog,
    ).fraction;
    if (progress > best) {
      best = progress;
    }
  }
  return best;
}
