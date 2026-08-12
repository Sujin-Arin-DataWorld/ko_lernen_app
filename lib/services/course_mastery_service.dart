import 'dart:convert';

import '../models/course_mastery.dart';
import '../models/course_practice_context.dart';
import '../models/curriculum.dart';
import 'account/reconciliation_errors.dart';
import 'curriculum_catalog.dart';
import 'storage_service.dart';

/// A corrective activity for an answer that needs more than vocabulary SRS.
class RemediationRecommendation {
  const RemediationRecommendation({
    required this.conceptId,
    required this.errorReason,
    required this.contentLink,
  });

  final String conceptId;
  final MasteryErrorReason errorReason;
  final ContentLink? contentLink;
}

/// Result of writing one piece of course evidence.
class CourseUpdate {
  const CourseUpdate({
    required this.snapshot,
    required this.currentUnit,
    this.previousSnapshot,
    this.newlyUnlockedUnit,
    this.remediation,
  });

  final CourseMasterySnapshot snapshot;
  final CourseUnit? currentUnit;
  final CourseMasterySnapshot? previousSnapshot;
  final CourseUnit? newlyUnlockedUnit;
  final RemediationRecommendation? remediation;
}

/// Local, schema-checked progression graph for grammar, particles, speech
/// style and scenario checkpoints. It never writes vocabulary SRS or pack
/// progress; those systems retain their existing semantics.
class CourseMasteryService {
  CourseMasteryService(this.catalog, {this.snapshotPreferences});

  /// Retain enough detail for local remediation while preventing unbounded
  /// SharedPreferences growth. When trimming, unresolved corrections and
  /// active-mission unlock inputs take priority over ordinary history.
  static const int evidenceCap = 300;

  final CurriculumCatalog catalog;
  final PreferenceStringStore? snapshotPreferences;
  CourseMasterySnapshot _snapshot = const CourseMasterySnapshot.empty();
  bool _loaded = false;

  CourseMasterySnapshot get snapshot => _snapshot;
  CourseUnit? get currentUnit => _snapshot.currentCourseUnitId == null
      ? null
      : catalog.courseUnitFor(_snapshot.currentCourseUnitId!);

  /// Combines two catalog-compatible snapshots without favoring either side.
  /// Stable identity collisions and progression contradictions fail closed as
  /// sorted typed conflicts; a successful result is canonical and bounded.
  CourseMasteryMergeResult mergeForReconciliation({
    required CourseMasterySnapshot? local,
    required CourseMasterySnapshot? remote,
  }) {
    final conflicts = <CourseMasteryMergeConflict>[];
    if (catalog.validationIssues.isNotEmpty) {
      for (final issue in catalog.validationIssues) {
        conflicts.add(
          CourseMasteryMergeConflict(
            kind: CourseMasteryMergeConflictKind.progression,
            id: 'catalog:$issue',
          ),
        );
      }
      return CourseMasteryMergeResult.conflicted(_sortedConflicts(conflicts));
    }

    if (local != null) _collectSnapshotConflicts(local, conflicts);
    if (remote != null) _collectSnapshotConflicts(remote, conflicts);

    final localPlacement = _normalizedPlacement(local?.placementLevel);
    final remotePlacement = _normalizedPlacement(remote?.placementLevel);
    if (localPlacement != null &&
        remotePlacement != null &&
        localPlacement != remotePlacement) {
      conflicts.add(
        const CourseMasteryMergeConflict(
          kind: CourseMasteryMergeConflictKind.placement,
          id: 'placementLevel',
        ),
      );
    }

    final evidence = _mergeIdentityHistory<MasteryEvidence>(
      local?.evidence ?? const [],
      remote?.evidence ?? const [],
      kind: CourseMasteryMergeConflictKind.evidence,
      idOf: (entry) => entry.id,
      bodyOf: (entry) => jsonEncode(entry.toJson()),
      conflicts: conflicts,
    );
    final checkpoints = _mergeIdentityHistory<ScenarioCheckpointEvidence>(
      local?.scenarioCheckpoints ?? const [],
      remote?.scenarioCheckpoints ?? const [],
      kind: CourseMasteryMergeConflictKind.checkpoint,
      idOf: (entry) => entry.id,
      bodyOf: (entry) => jsonEncode(entry.toJson()),
      conflicts: conflicts,
    );

    final completed = <String>{
      ...?local?.completedUnitIds,
      ...?remote?.completedUnitIds,
    };
    final bypassed = <String>{
      ...?local?.bypassedPrerequisiteUnitIds,
      ...?remote?.bypassedPrerequisiteUnitIds,
    };
    for (final id in completed.intersection(bypassed)) {
      conflicts.add(
        CourseMasteryMergeConflict(
          kind: CourseMasteryMergeConflictKind.progression,
          id: id,
        ),
      );
    }
    if (conflicts.isNotEmpty) {
      return CourseMasteryMergeResult.conflicted(_sortedConflicts(conflicts));
    }

    final completedIds = completed.toList()..sort(_compareUnitIds);
    final bypassedIds = bypassed.toList()..sort(_compareUnitIds);
    final resolved = <String>{...completedIds, ...bypassedIds};
    final placement = localPlacement ?? remotePlacement;
    final courseStarted =
        _hasSequentialCourseState(local) || _hasSequentialCourseState(remote);
    final current = courseStarted
        ? _orderedUnits
              .where(
                (unit) =>
                    !resolved.contains(unit.id) &&
                    (placement == null ||
                        _levelRank(unit.level) >= _levelRank(placement)) &&
                    unit.prerequisiteUnitIds.every(resolved.contains),
              )
              .cast<CourseUnit?>()
              .firstWhere((unit) => unit != null, orElse: () => null)
        : null;

    evidence.sort(_compareEvidence);
    checkpoints.sort(_compareCheckpoints);
    var merged = CourseMasterySnapshot(
      placementLevel: placement,
      currentCourseUnitId: current?.id,
      completedUnitIds: completedIds,
      bypassedPrerequisiteUnitIds: bypassedIds,
      evidence: evidence,
      scenarioCheckpoints: checkpoints,
    );
    merged = merged.copyWith(
      evidence: _boundedEvidenceFor(merged.evidence, current),
      scenarioCheckpoints: _boundedCheckpointsFor(
        merged.scenarioCheckpoints,
        current,
      ),
    );
    try {
      _validateSnapshot(merged);
    } on FormatException {
      return const CourseMasteryMergeResult.conflicted([
        CourseMasteryMergeConflict(
          kind: CourseMasteryMergeConflictKind.progression,
          id: 'mergedSnapshot',
        ),
      ]);
    }
    return CourseMasteryMergeResult.merged(merged);
  }

  /// Starts the sequential path at the first unit of a chosen CEFR level.
  /// Earlier units are explicitly listed as bypassed prerequisites; they are
  /// never represented as completed work.
  Future<CourseMasterySnapshot> initializeForPlacement(
    String levelCode, {
    bool syncBrowseLevel = false,
  }) async {
    _ensureCatalogUsable();
    final level = _normalizeLevel(levelCode);
    final startingUnit = _orderedUnits
        .where((unit) => unit.level == level)
        .cast<CourseUnit?>()
        .firstWhere(
          (unit) => unit != null,
          orElse: () => throw FormatException(
            'Curriculum has no starting course unit for level $level.',
          ),
        )!;
    final targetRank = _levelRank(level);
    final bypassed = _orderedUnits
        .where((unit) => _levelRank(unit.level) < targetRank)
        .map((unit) => unit.id)
        .toList(growable: false);

    final nextSnapshot = CourseMasterySnapshot(
      placementLevel: level,
      currentCourseUnitId: startingUnit.id,
      bypassedPrerequisiteUnitIds: bypassed,
    );
    await _persistSnapshot(
      nextSnapshot,
      mirrorLegacyUserLevel: true,
      browseLevelCode: syncBrowseLevel ? level : null,
    );
    _snapshot = nextSnapshot;
    _loaded = true;
    return _snapshot;
  }

  /// Reloads and validates the durable local state. A bad catalog or malformed
  /// evidence is rejected before it can be aggregated into mastery/unlocks.
  Future<CourseMasterySnapshot> refresh() async {
    _ensureCatalogUsable();
    final canonicalRaw = Storage.courseMasterySnapshotRawJson.trim();
    final raw = canonicalRaw.isNotEmpty
        ? canonicalRaw
        : Storage.legacyCourseMasteryRawJson.trim();
    if (raw.isEmpty) {
      _snapshot = CourseMasterySnapshot(
        placementLevel: Storage.placementLevelCode,
        currentCourseUnitId: Storage.courseUnitId,
      );
      _validateSnapshot(_snapshot);
      _loaded = true;
      await _persist();
      return _snapshot;
    }
    final decoded = jsonDecode(raw);
    if (decoded is! Map) {
      throw const FormatException('Course mastery storage must be an object.');
    }
    final snapshotJson = decoded.map(
      (key, value) => MapEntry(key.toString(), value),
    );
    _snapshot = CourseMasterySnapshot.decodeAndMigrate(snapshotJson);
    _validateSnapshot(_snapshot);
    _loaded = true;
    if (canonicalRaw.isEmpty ||
        CourseMasterySnapshot.sourceVersionFor(snapshotJson) !=
            CourseMasterySnapshot.currentVersion) {
      await _persist();
    }
    return _snapshot;
  }

  /// Loads the durable course snapshot for read-only screens without creating
  /// or migrating storage. A path or historical mission view must never reset
  /// a completed course merely because its current unit is null.
  CourseMasterySnapshot? readForDisplay() {
    final snapshot = readForReconciliation();
    _snapshot = snapshot ?? const CourseMasterySnapshot.empty();
    _loaded = true;
    return snapshot;
  }

  /// Reads only durable state that belongs to the sequential course without
  /// migrating, synthesizing, or persisting a canonical snapshot. In
  /// particular, the unrelated legacy user-level fallback is not course state.
  CourseMasterySnapshot? readForReconciliation() {
    _ensureCatalogUsable();
    final canonicalRaw = Storage.courseMasterySnapshotRawJson.trim();
    final legacyRaw = Storage.legacyCourseMasteryRawJson.trim();
    final raw = canonicalRaw.isNotEmpty ? canonicalRaw : legacyRaw;
    if (raw.isNotEmpty) {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) {
        throw const FormatException(
          'Course mastery storage must be an object.',
        );
      }
      final snapshot = CourseMasterySnapshot.decodeAndMigrate(
        decoded.map((key, value) => MapEntry(key.toString(), value)),
      );
      _validateSnapshot(snapshot);
      return snapshot;
    }

    final placement = Storage.dedicatedCoursePlacementLevelCode;
    final currentUnit = Storage.courseUnitId;
    if (placement == null && currentUnit == null) return null;
    final snapshot = CourseMasterySnapshot(
      placementLevel: placement,
      currentCourseUnitId: currentUnit,
    );
    _validateSnapshot(snapshot);
    return snapshot;
  }

  /// Produces the only course state eligible to leave this device. Existing
  /// canonical v2 bytes are catalog-validated without mutation. When v2 is
  /// absent, a retained v1 record or dedicated course mirrors are migrated
  /// through canonical-first persistence before the caller can serialize
  /// them. Browse and legacy account-level state are never inputs here.
  Future<CourseMasterySnapshot?> migrateForCloudCapture() async {
    _ensureCatalogUsable();
    final canonicalRaw = Storage.courseMasterySnapshotRawJson.trim();
    if (canonicalRaw.isNotEmpty) {
      final snapshotJson = _decodeStoredSnapshotJson(canonicalRaw);
      if (CourseMasterySnapshot.sourceVersionFor(snapshotJson) !=
          CourseMasterySnapshot.currentVersion) {
        throw const FormatException(
          'Canonical course mastery storage must use schema version 2.',
        );
      }
      final snapshot = CourseMasterySnapshot.decodeAndMigrate(snapshotJson);
      _validateSnapshot(snapshot);
      return snapshot;
    }

    final legacyRaw = Storage.legacyCourseMasteryRawJson.trim();
    final CourseMasterySnapshot snapshot;
    if (legacyRaw.isNotEmpty) {
      snapshot = CourseMasterySnapshot.decodeAndMigrate(
        _decodeStoredSnapshotJson(legacyRaw),
      );
    } else {
      final placement = Storage.dedicatedCoursePlacementLevelCode;
      final currentUnit = Storage.courseUnitId;
      if (placement == null && currentUnit == null) return null;
      snapshot = CourseMasterySnapshot(
        placementLevel: placement,
        currentCourseUnitId: currentUnit,
      );
    }

    _validateSnapshot(snapshot);
    await _persistSnapshot(snapshot, mirrorLegacyUserLevel: false);
    _snapshot = snapshot;
    _loaded = true;
    return snapshot;
  }

  /// Installs a validated snapshot produced by a later reconciliation layer.
  /// The optional generation is an optimistic raw-snapshot fence: callers that
  /// supply one cannot replace a newer local canonical value accidentally.
  Future<CourseMasterySnapshot> applyReconciledSnapshot(
    CourseMasterySnapshot snapshot, {
    required String? expectedGeneration,
    void Function()? assertCurrentWrite,
  }) async {
    _ensureCatalogUsable();
    if (expectedGeneration != null &&
        Storage.courseMasterySnapshotRawJson != expectedGeneration) {
      throw const LocalReconciliationGenerationConflict();
    }
    _validateSnapshot(snapshot);
    await _persistSnapshot(
      snapshot,
      mirrorLegacyUserLevel: false,
      assertCurrentWrite: assertCurrentWrite,
    );
    _snapshot = snapshot;
    _loaded = true;
    return _snapshot;
  }

  /// Changes the active mission only when all declared prerequisites have been
  /// completed or explicitly bypassed. Completed missions stay reviewable in
  /// their own screens, so this method does not rewind the sequential pointer.
  Future<CourseMasterySnapshot> selectCourseUnit(String unitId) async {
    await _ensureLoaded();
    final target = catalog.courseUnitFor(unitId.trim());
    if (target == null) {
      throw FormatException('Unknown course unit: $unitId');
    }
    if (target.id == _snapshot.currentCourseUnitId) return _snapshot;
    if (!_canActivate(target)) {
      throw StateError('Course unit ${target.id} is not unlocked.');
    }
    _snapshot = _snapshot.copyWith(currentCourseUnitId: target.id);
    await _persist();
    return _snapshot;
  }

  /// Records a result from a game, grammar card, vocabulary card, small-talk
  /// activity, cloze, sentence builder, or scenario subtask. If [conceptId]
  /// is omitted, all concepts linked to this content receive the same result.
  /// Course-routed grammar and small-talk checkpoints are stricter: they
  /// require a declared `assess` graph link and exactly one explicit concept.
  Future<CourseUpdate> recordContentAttempt(
    CurriculumContentKind kind,
    String contentId,
    bool isCorrect, {
    CoursePracticeContext? courseContext,
    String? conceptId,
    MasteryErrorReason? errorReason,
    DateTime? occurredAt,
    double? score,
  }) async {
    await _ensureLoaded();
    final previousSnapshot = _snapshot;
    final timestamp = _validTimestamp(occurredAt ?? DateTime.now().toUtc());
    final checkedScore = _validOptionalScore(score);
    final normalizedContentId = contentId.trim();
    if (normalizedContentId.isEmpty) {
      throw const FormatException('Content attempt requires a content ID.');
    }
    final allLinks = catalog.linksForContent(kind, normalizedContentId);
    if (allLinks.isEmpty) {
      throw FormatException(
        'Unknown linked content: ${kind.code}:$normalizedContentId',
      );
    }
    final contextEntry = courseContext == null
        ? null
        : _contextEntryLink(courseContext, kind);
    final requiresExactAssessment =
        courseContext != null && _requiresTypedMissionContext(kind);
    final requiresSingleConceptAssessment =
        courseContext != null && _requiresSingleConceptAssessment(kind);
    final requestedConceptId = conceptId?.trim();
    if (requestedConceptId != null && requestedConceptId.isEmpty) {
      throw const FormatException(
        'Content attempt conceptId must not be empty.',
      );
    }
    if (requiresExactAssessment) {
      if (contextEntry!.role != ContentLinkRole.assess) {
        throw FormatException(
          'Course context ${contextEntry.id} is not an assessment link.',
        );
      }
      if (requestedConceptId == null) {
        throw FormatException(
          'Course checkpoint evidence requires an explicit concept ID.',
        );
      }
      if (kind == CurriculumContentKind.smalltalk &&
          catalog.conceptFor(requestedConceptId)?.kind !=
              ConceptKind.speechStyle) {
        throw FormatException(
          'Small-talk relationship checkpoints require a speech-style concept.',
        );
      }
    }
    // A typed route identifies one immutable graph edge. Browse callers never
    // inherit the active unit merely because their content happens to occur in
    // it; their answers remain useful history only.
    final eligibleLinks = contextEntry == null
        ? allLinks
        : allLinks
              .where(
                (link) =>
                    link.id == contextEntry.id &&
                    link.courseUnitId == contextEntry.courseUnitId &&
                    (!requiresExactAssessment ||
                        link.role == ContentLinkRole.assess),
              )
              .toList(growable: false);
    if (eligibleLinks.isEmpty) {
      throw FormatException(
        'Course context ${courseContext!.courseUnitId} does not link '
        '${kind.code}:$normalizedContentId.',
      );
    }
    if (requiresExactAssessment) {
      if (eligibleLinks.length != 1 ||
          !eligibleLinks.single.conceptIds.contains(requestedConceptId)) {
        throw FormatException(
          'Course checkpoint ${kind.code}:$normalizedContentId does not '
          'match concept $requestedConceptId for ${contextEntry!.courseUnitId}.',
        );
      }
    }
    if (requiresSingleConceptAssessment) {
      // A generic course card may move through other content in the same
      // mission, but each submitted answer still needs exactly one, explicit
      // assess edge. Otherwise a later data edit could make a caller choose
      // which of several concepts the same check should credit.
      if (eligibleLinks.single.conceptIds.length != 1) {
        throw FormatException(
          'Course checkpoint ${kind.code}:$normalizedContentId must have '
          'one exact assessment concept for ${contextEntry!.courseUnitId}.',
        );
      }
    }
    final conceptIds = requestedConceptId == null
        ? (eligibleLinks.expand((link) => link.conceptIds).toSet().toList()
            ..sort())
        : <String>[requestedConceptId];
    if (conceptIds.isEmpty) {
      throw const FormatException('Content attempt has no linked concept.');
    }

    final entries = <MasteryEvidence>[..._snapshot.evidence];
    for (final id in conceptIds) {
      _requireKnownConcept(id);
      final matchingLinks = eligibleLinks
          .where((link) => link.conceptIds.contains(id))
          .toList(growable: false);
      if (matchingLinks.isEmpty) {
        throw FormatException(
          'Content ${kind.code}:$normalizedContentId is not linked to concept $id.',
        );
      }
      final activeLink =
          contextEntry != null && currentUnit?.id == contextEntry.courseUnitId
          ? contextEntry
          : null;
      entries.add(
        MasteryEvidence(
          conceptId: id,
          contentKind: kind,
          contentId: normalizedContentId,
          courseUnitId: activeLink?.courseUnitId,
          missionContentLinkId: activeLink?.id,
          isCorrect: isCorrect,
          occurredAt: timestamp,
          errorReason: errorReason,
          score: checkedScore,
          // Only an exact assessment edge may change sequential mastery.
          // Typed practice still keeps its unit provenance so the mission
          // brief can advance without pretending that practice was a test.
          courseEligible:
              activeLink?.role == ContentLinkRole.assess &&
              _requiresTypedMissionContext(kind),
        ),
      );
    }
    _snapshot = _snapshot.copyWith(evidence: _boundedEvidence(entries));
    return _commitUpdate(previousSnapshot: previousSnapshot);
  }

  /// Records a scenario's aggregate checkpoint score. Only a score completed
  /// from the current mission's declared checkpoint can unlock that mission.
  Future<CourseUpdate> recordScenarioCheckpoint(
    String scenarioId,
    double score, {
    CoursePracticeContext? courseContext,
    DateTime? occurredAt,
  }) async {
    await _ensureLoaded();
    final previousSnapshot = _snapshot;
    final normalizedScenarioId = scenarioId.trim();
    if (normalizedScenarioId.isEmpty) {
      throw const FormatException(
        'Scenario checkpoint requires a scenario ID.',
      );
    }
    final checkedScore = _validScore(score);
    final timestamp = _validTimestamp(occurredAt ?? DateTime.now().toUtc());
    final links = catalog.linksForContent(
      CurriculumContentKind.scenario,
      normalizedScenarioId,
    );
    if (links.isEmpty) {
      throw FormatException('Unknown linked scenario: $normalizedScenarioId');
    }
    final activeUnit = currentUnit;
    final contextEntry =
        courseContext?.isFor(CurriculumContentKind.scenario) == true &&
            courseContext?.initialContentId == normalizedScenarioId
        ? courseContext
        : null;
    final activeCheckpoint =
        activeUnit == null ||
            contextEntry == null ||
            contextEntry.courseUnitId != activeUnit.id
        ? null
        : links
              .where(
                (link) =>
                    link.courseUnitId == activeUnit.id &&
                    link.id == contextEntry.contentLinkId &&
                    link.contentId == contextEntry.initialContentId &&
                    activeUnit.checkpointContentIds.contains(link.contentKey) &&
                    link.exactlyAssesses(activeUnit),
              )
              .cast<ContentLink?>()
              .firstWhere((link) => link != null, orElse: () => null);
    final sourceLink = activeCheckpoint ?? _preferredLink(links);
    _snapshot = _snapshot.copyWith(
      scenarioCheckpoints: _boundedCheckpoints([
        ..._snapshot.scenarioCheckpoints,
        ScenarioCheckpointEvidence(
          scenarioId: normalizedScenarioId,
          courseUnitId: sourceLink.courseUnitId,
          missionContentLinkId: activeCheckpoint?.id,
          score: checkedScore,
          occurredAt: timestamp,
          courseEligible: activeCheckpoint != null,
        ),
      ]),
    );
    return _commitUpdate(previousSnapshot: previousSnapshot);
  }

  /// Current learner-facing concept state, derived only after the catalog and
  /// persisted evidence have passed validation.
  CourseContentState stateForConcept(String conceptId) {
    _ensureCatalogUsable();
    _requireKnownConcept(conceptId);
    final evidence = _snapshot.evidence
        .where((item) => item.conceptId == conceptId)
        .toList(growable: false);
    final eligible = evidence
        .where(_isVerifiedCourseEligibleEvidence)
        .toList(growable: false);
    // Free browsing remains visible as history, but never changes sequential
    // course state or creates a retroactive mastery result.
    if (eligible.isEmpty) {
      return currentUnit?.requiredConceptIds.contains(conceptId) == true
          ? CourseContentState.introduced
          : CourseContentState.preview;
    }
    if (_pendingRemediations().containsKey(conceptId)) {
      return CourseContentState.reviewDue;
    }
    final accuracy = _accuracy(eligible);
    if (accuracy >= _passThresholdForConcept(conceptId)) {
      return eligible.length >= 3 && accuracy >= .85
          ? CourseContentState.stableMastery
          : CourseContentState.checkpointPassed;
    }
    return CourseContentState.practiceAvailable;
  }

  /// Targeted concept correction queue. It remains separate from word SRS and
  /// is cleared by a later correct linked answer for the same concept.
  List<RemediationRecommendation> get reviewQueue {
    _ensureCatalogUsable();
    return _pendingRemediations().entries
        .map(
          (entry) => _recommendationFor(
            entry.key,
            entry.value.errorReason ?? MasteryErrorReason.unknown,
          ),
        )
        .toList(growable: false);
  }

  Future<void> _ensureLoaded() async {
    if (!_loaded) await refresh();
  }

  Future<CourseUpdate> _commitUpdate({
    CourseMasterySnapshot? previousSnapshot,
  }) async {
    // Compact legacy oversized snapshots before the next durable write too,
    // not only when the corresponding list was appended in this call.
    _snapshot = _snapshot.copyWith(
      evidence: _boundedEvidence(_snapshot.evidence),
      scenarioCheckpoints: _boundedCheckpoints(_snapshot.scenarioCheckpoints),
    );
    final newlyUnlocked = _advanceIfPassed();
    await _persist();
    final queue = reviewQueue;
    return CourseUpdate(
      snapshot: _snapshot,
      currentUnit: currentUnit,
      previousSnapshot: previousSnapshot,
      newlyUnlockedUnit: newlyUnlocked,
      remediation: queue.isEmpty ? null : queue.first,
    );
  }

  CourseUnit? _advanceIfPassed() {
    final unit = currentUnit;
    if (unit == null || !_unitPassed(unit)) return null;
    final completed = <String>{..._snapshot.completedUnitIds, unit.id}.toList()
      ..sort(_compareUnitIds);
    final resolved = <String>{
      ...completed,
      ..._snapshot.bypassedPrerequisiteUnitIds,
    };
    CourseUnit? next;
    for (final candidate in _orderedUnits) {
      if (candidate.id != unit.id &&
          !resolved.contains(candidate.id) &&
          candidate.prerequisiteUnitIds.every(resolved.contains)) {
        next = candidate;
        break;
      }
    }
    _snapshot = _snapshot.copyWith(
      completedUnitIds: completed,
      currentCourseUnitId: next?.id,
      clearCurrentCourseUnitId: next == null,
    );
    return next;
  }

  bool _unitPassed(CourseUnit unit) {
    final threshold = unit.passThreshold;
    final latestScenarioEvidenceAt = <String, DateTime>{};
    for (final conceptId in unit.requiredConceptIds) {
      final evidence = _snapshot.evidence
          .where(
            (item) =>
                _isVerifiedCourseEligibleEvidence(item) &&
                item.courseUnitId == unit.id &&
                item.conceptId == conceptId &&
                _isVerifiedConceptEvidenceForUnit(item, unit),
          )
          .toList(growable: false);
      if (evidence.isEmpty || _accuracy(evidence) < threshold) return false;
      for (final item in evidence) {
        if (item.contentKind == CurriculumContentKind.scenario &&
            unit.checkpointContentIds.contains(item.contentKey)) {
          final previous = latestScenarioEvidenceAt[item.contentId];
          if (previous == null || item.occurredAt.isAfter(previous)) {
            latestScenarioEvidenceAt[item.contentId] = item.occurredAt;
          }
        }
      }
    }
    if (unit.checkpointContentIds.isEmpty) return true;
    for (final contentKey in unit.checkpointContentIds) {
      final pieces = contentKey.split(':');
      if (pieces.length != 2 ||
          pieces.first != CurriculumContentKind.scenario.code) {
        return false;
      }
      final matching = _snapshot.scenarioCheckpoints
          .where(
            (item) =>
                item.courseEligible &&
                item.courseUnitId == unit.id &&
                item.scenarioId == pieces.last,
          )
          .toList(growable: false);
      final verifiedMatching = matching
          .where(_isVerifiedCourseEligibleCheckpoint)
          .toList(growable: false);
      if (verifiedMatching.isEmpty) return false;
      final latestCheckpoint = _latestCheckpoint(verifiedMatching);
      if (latestCheckpoint.score < threshold) return false;
      final scenarioEvidenceAt = latestScenarioEvidenceAt[pieces.last];
      if (scenarioEvidenceAt != null &&
          latestCheckpoint.occurredAt.isBefore(scenarioEvidenceAt)) {
        return false;
      }
    }
    return true;
  }

  bool _isVerifiedConceptEvidenceForUnit(
    MasteryEvidence evidence,
    CourseUnit unit,
  ) =>
      _isVerifiedCourseEligibleEvidence(evidence) &&
      evidence.courseUnitId == unit.id;

  bool _isVerifiedCourseEligibleEvidence(MasteryEvidence evidence) {
    if (!evidence.courseEligible ||
        evidence.courseUnitId == null ||
        evidence.missionContentLinkId == null ||
        !_requiresTypedMissionContext(evidence.contentKind)) {
      return false;
    }
    return catalog
        .linksForContent(evidence.contentKind, evidence.contentId)
        .any(
          (link) =>
              link.courseUnitId == evidence.courseUnitId &&
              link.conceptIds.contains(evidence.conceptId) &&
              link.role == ContentLinkRole.assess &&
              evidence.missionContentLinkId == link.id,
        );
  }

  bool _isVerifiedCourseEligibleCheckpoint(
    ScenarioCheckpointEvidence checkpoint,
  ) {
    if (!checkpoint.courseEligible ||
        checkpoint.courseUnitId == null ||
        checkpoint.missionContentLinkId == null) {
      return false;
    }
    final unit = catalog.courseUnitFor(checkpoint.courseUnitId!);
    if (unit == null ||
        !unit.checkpointContentIds.contains(
          '${CurriculumContentKind.scenario.code}:${checkpoint.scenarioId}',
        )) {
      return false;
    }
    return catalog
        .linksForContent(CurriculumContentKind.scenario, checkpoint.scenarioId)
        .any(
          (link) =>
              link.id == checkpoint.missionContentLinkId &&
              link.courseUnitId == checkpoint.courseUnitId &&
              link.exactlyAssesses(unit),
        );
  }

  ScenarioCheckpointEvidence _latestCheckpoint(
    List<ScenarioCheckpointEvidence> entries,
  ) {
    return entries.reduce(
      (latest, candidate) =>
          candidate.occurredAt.isAfter(latest.occurredAt) ? candidate : latest,
    );
  }

  bool _canActivate(CourseUnit target) {
    if (_snapshot.completedUnitIds.contains(target.id) ||
        _snapshot.bypassedPrerequisiteUnitIds.contains(target.id)) {
      return false;
    }
    final resolved = <String>{
      ..._snapshot.completedUnitIds,
      ..._snapshot.bypassedPrerequisiteUnitIds,
    };
    return target.prerequisiteUnitIds.every(resolved.contains);
  }

  bool _requiresTypedMissionContext(CurriculumContentKind kind) =>
      kind == CurriculumContentKind.grammar ||
      kind == CurriculumContentKind.smalltalk ||
      kind == CurriculumContentKind.scenario;

  bool _requiresSingleConceptAssessment(CurriculumContentKind kind) =>
      kind == CurriculumContentKind.grammar ||
      kind == CurriculumContentKind.smalltalk;

  ContentLink _contextEntryLink(
    CoursePracticeContext context,
    CurriculumContentKind kind,
  ) {
    if (!context.isFor(kind)) {
      throw FormatException('Course context does not match ${kind.code}.');
    }
    final matches = catalog.contentLinks
        .where((link) => link.id == context.contentLinkId)
        .toList(growable: false);
    if (matches.length != 1) {
      throw FormatException(
        'Unknown course context link: ${context.contentLinkId}',
      );
    }
    final link = matches.single;
    if (link.courseUnitId != context.courseUnitId ||
        link.contentKind != context.contentKind ||
        link.contentId != context.initialContentId) {
      throw const FormatException(
        'Course context link does not match its source.',
      );
    }
    return link;
  }

  ContentLink _preferredLink(List<ContentLink> links) {
    final sorted = links.toList()
      ..sort((left, right) {
        final role = _rolePriority(
          left.role,
        ).compareTo(_rolePriority(right.role));
        if (role != 0) return role;
        return left.id.compareTo(right.id);
      });
    return sorted.first;
  }

  int _rolePriority(ContentLinkRole role) => switch (role) {
    ContentLinkRole.review => 0,
    ContentLinkRole.practice => 1,
    ContentLinkRole.introduce => 2,
    ContentLinkRole.assess => 3,
  };

  Map<String, MasteryEvidence> _pendingRemediations() {
    return _pendingRemediationsFor(_snapshot.evidence);
  }

  Map<String, MasteryEvidence> _pendingRemediationsFor(
    Iterable<MasteryEvidence> entries,
  ) {
    final pending = <String, MasteryEvidence>{};
    for (final evidence in entries) {
      // Future/free-browse answers must not create a sequential-course repair
      // item before the learner reaches that linked concept.
      if (!_isVerifiedCourseEligibleEvidence(evidence)) continue;
      if (evidence.isCorrect) {
        pending.remove(evidence.conceptId);
      } else if (_needsTargetedRemediation(evidence)) {
        pending[evidence.conceptId] = evidence;
      }
    }
    return pending;
  }

  bool _needsTargetedRemediation(MasteryEvidence evidence) {
    final reason = evidence.errorReason;
    if (reason == MasteryErrorReason.batchim ||
        reason == MasteryErrorReason.particleRole ||
        reason == MasteryErrorReason.wordOrder ||
        reason == MasteryErrorReason.speechStyle ||
        reason == MasteryErrorReason.spellingSpacing) {
      return true;
    }
    final kind = catalog.conceptFor(evidence.conceptId)?.kind;
    return kind == ConceptKind.particle ||
        kind == ConceptKind.conjugation ||
        kind == ConceptKind.speechStyle ||
        kind == ConceptKind.pronunciation;
  }

  RemediationRecommendation _recommendationFor(
    String conceptId,
    MasteryErrorReason errorReason,
  ) {
    final options = catalog
        .linksForConcept(conceptId)
        .where(
          (link) =>
              link.role == ContentLinkRole.review ||
              link.role == ContentLinkRole.practice,
        )
        .toList(growable: false);
    return RemediationRecommendation(
      conceptId: conceptId,
      errorReason: errorReason,
      contentLink: options.isEmpty ? null : _preferredLink(options),
    );
  }

  double _accuracy(List<MasteryEvidence> evidence) =>
      evidence.where((item) => item.isCorrect).length / evidence.length;

  double _passThresholdForConcept(String conceptId) {
    final unit = currentUnit;
    if (unit != null && unit.requiredConceptIds.contains(conceptId)) {
      return unit.passThreshold;
    }
    return .7;
  }

  List<MasteryEvidence> _boundedEvidence(List<MasteryEvidence> entries) {
    return _boundedEvidenceFor(entries, currentUnit);
  }

  List<MasteryEvidence> _boundedEvidenceFor(
    List<MasteryEvidence> entries,
    CourseUnit? active,
  ) {
    final unresolved = _pendingRemediationsFor(entries).values.toSet();
    return _boundedByPriority(
      entries,
      (entry) =>
          unresolved.contains(entry) ||
          (active != null &&
              _isVerifiedCourseEligibleEvidence(entry) &&
              entry.courseUnitId == active.id &&
              active.requiredConceptIds.contains(entry.conceptId)),
    );
  }

  List<ScenarioCheckpointEvidence> _boundedCheckpoints(
    List<ScenarioCheckpointEvidence> entries,
  ) {
    return _boundedCheckpointsFor(entries, currentUnit);
  }

  List<ScenarioCheckpointEvidence> _boundedCheckpointsFor(
    List<ScenarioCheckpointEvidence> entries,
    CourseUnit? active,
  ) {
    if (active == null || active.checkpointContentIds.isEmpty) {
      return _boundedByPriority(entries, (_) => false);
    }
    final requiredScenarioIds = active.checkpointContentIds
        .map(_scenarioIdFromCheckpointKey)
        .whereType<String>()
        .toSet();
    final latestRequired = <String, ScenarioCheckpointEvidence>{};
    for (final entry in entries) {
      if (_isVerifiedCourseEligibleCheckpoint(entry) &&
          entry.courseUnitId == active.id &&
          requiredScenarioIds.contains(entry.scenarioId)) {
        final previous = latestRequired[entry.scenarioId];
        if (previous == null || entry.occurredAt.isAfter(previous.occurredAt)) {
          latestRequired[entry.scenarioId] = entry;
        }
      }
    }
    final required = latestRequired.values.toSet();
    return _boundedByPriority(entries, required.contains);
  }

  /// Retention is deterministic and bounded: newest unresolved remediation
  /// and active-mission unlock inputs first, then the newest regular history.
  /// If the protected set itself exceeds [evidenceCap], its newest records win
  /// so [evidenceCap] remains a hard upper bound.
  List<T> _boundedByPriority<T>(
    List<T> entries,
    bool Function(T entry) isPriority,
  ) {
    if (entries.length <= evidenceCap) return List.unmodifiable(entries);
    final selected = <int>{};
    void select(bool Function(T entry) predicate) {
      for (
        var index = entries.length - 1;
        index >= 0 && selected.length < evidenceCap;
        index--
      ) {
        if (predicate(entries[index])) selected.add(index);
      }
    }

    select(isPriority);
    select((_) => true);
    final ordered = selected.toList()..sort();
    return List.unmodifiable([for (final index in ordered) entries[index]]);
  }

  Future<void> _persist({
    bool mirrorLegacyUserLevel = true,
    void Function()? assertCurrentWrite,
  }) => _persistSnapshot(
    _snapshot,
    mirrorLegacyUserLevel: mirrorLegacyUserLevel,
    assertCurrentWrite: assertCurrentWrite,
  );

  Future<void> _persistSnapshot(
    CourseMasterySnapshot snapshot, {
    required bool mirrorLegacyUserLevel,
    String? browseLevelCode,
    void Function()? assertCurrentWrite,
  }) async {
    _ensureCatalogUsable();
    _validateSnapshot(snapshot);
    await Storage.setCourseMasteryStateAtomically(
      canonicalSnapshotJson: jsonEncode(snapshot.toJson()),
      placementLevelCode: snapshot.placementLevel,
      browseLevelCode: browseLevelCode,
      currentCourseUnitId: snapshot.currentCourseUnitId,
      mirrorLegacyUserLevel: mirrorLegacyUserLevel,
      preferences: snapshotPreferences,
      assertCurrentWrite: assertCurrentWrite,
    );
  }

  void _ensureCatalogUsable() {
    if (catalog.validationIssues.isNotEmpty) {
      throw FormatException(
        'Course mastery requires a valid curriculum catalog: '
        '${catalog.validationIssues.join('; ')}',
      );
    }
  }

  Map<String, dynamic> _decodeStoredSnapshotJson(String raw) {
    final decoded = jsonDecode(raw);
    if (decoded is! Map) {
      throw const FormatException('Course mastery storage must be an object.');
    }
    return decoded.map((key, value) => MapEntry(key.toString(), value));
  }

  void _validateSnapshot(CourseMasterySnapshot snapshot) {
    if (snapshot.version != CourseMasterySnapshot.currentVersion) {
      throw FormatException(
        'Unsupported course mastery version ${snapshot.version}.',
      );
    }
    if (snapshot.placementLevel != null) {
      _normalizeLevel(snapshot.placementLevel!);
    }
    if (snapshot.currentCourseUnitId != null) {
      _requireKnownUnit(snapshot.currentCourseUnitId!);
    }
    _validateUnitIdList(snapshot.completedUnitIds, 'completed unit');
    _validateUnitIdList(
      snapshot.bypassedPrerequisiteUnitIds,
      'bypassed prerequisite unit',
    );
    final overlap = snapshot.completedUnitIds.toSet().intersection(
      snapshot.bypassedPrerequisiteUnitIds.toSet(),
    );
    if (overlap.isNotEmpty) {
      throw FormatException('Units cannot be completed and bypassed: $overlap');
    }
    _validateProgressionCoherence(snapshot);
    for (final evidence in snapshot.evidence) {
      _validateEvidence(evidence);
    }
    for (final checkpoint in snapshot.scenarioCheckpoints) {
      _validateCheckpoint(checkpoint);
    }
  }

  void _validateProgressionCoherence(CourseMasterySnapshot snapshot) {
    final completed = snapshot.completedUnitIds.toSet();
    final bypassed = snapshot.bypassedPrerequisiteUnitIds.toSet();
    final resolved = <String>{...completed, ...bypassed};
    final placement = snapshot.placementLevel == null
        ? null
        : _normalizeLevel(snapshot.placementLevel!);

    if (bypassed.isNotEmpty) {
      if (placement == null) {
        throw const FormatException(
          'Bypassed prerequisites require a placement level.',
        );
      }
      final expected = _orderedUnits
          .where((unit) => _levelRank(unit.level) < _levelRank(placement))
          .map((unit) => unit.id)
          .toSet();
      if (bypassed.length != expected.length ||
          !bypassed.containsAll(expected)) {
        throw const FormatException(
          'Bypassed prerequisites must be the pre-placement course prefix.',
        );
      }
    }

    for (final unitId in completed) {
      _validateResolvedPrerequisites(unitId, resolved, 'Completed course unit');
    }

    final currentId = snapshot.currentCourseUnitId;
    if (currentId == null) return;
    if (resolved.contains(currentId)) {
      throw FormatException(
        'Current course unit cannot be completed or bypassed: $currentId',
      );
    }
    final current = catalog.courseUnitFor(currentId)!;
    if (placement != null &&
        _levelRank(current.level) < _levelRank(placement)) {
      throw FormatException(
        'Current course unit precedes placement level: $currentId',
      );
    }
    _validateResolvedPrerequisites(currentId, resolved, 'Current course unit');
  }

  void _validateResolvedPrerequisites(
    String unitId,
    Set<String> resolved,
    String label,
  ) {
    final unit = catalog.courseUnitFor(unitId)!;
    final missing = unit.prerequisiteUnitIds
        .where((id) => !resolved.contains(id))
        .toList(growable: false);
    if (missing.isNotEmpty) {
      throw FormatException(
        '$label $unitId has unresolved prerequisites: $missing',
      );
    }
  }

  void _validateEvidence(MasteryEvidence evidence) {
    _requireKnownConcept(evidence.conceptId);
    _validTimestamp(evidence.occurredAt);
    _validOptionalScore(evidence.score);
    if (evidence.contentId.trim().isEmpty) {
      throw const FormatException('Mastery evidence has an empty content ID.');
    }
    final links = catalog.linksForContent(
      evidence.contentKind,
      evidence.contentId,
    );
    if (links.isEmpty ||
        !links.any((link) => link.conceptIds.contains(evidence.conceptId))) {
      throw FormatException(
        'Evidence references unknown linked content ${evidence.contentKey}.',
      );
    }
    if (evidence.courseUnitId != null) {
      _requireKnownUnit(evidence.courseUnitId!);
      if (!links.any((link) => link.courseUnitId == evidence.courseUnitId)) {
        throw FormatException(
          'Evidence course unit does not match ${evidence.contentKey}.',
        );
      }
    }
    if (evidence.missionContentLinkId != null) {
      final missionLinks = links
          .where(
            (link) =>
                link.id == evidence.missionContentLinkId &&
                link.courseUnitId == evidence.courseUnitId &&
                link.conceptIds.contains(evidence.conceptId),
          )
          .toList(growable: false);
      if (missionLinks.length != 1 ||
          (evidence.courseEligible &&
              missionLinks.single.role != ContentLinkRole.assess)) {
        throw const FormatException(
          'Mission evidence does not match one exact graph edge.',
        );
      }
    }
    if (evidence.courseEligible && evidence.courseUnitId == null) {
      throw const FormatException('Eligible evidence requires a course unit.');
    }
    if (evidence.courseEligible &&
        _requiresTypedMissionContext(evidence.contentKind)) {
      final eligibleAssessLinks = links
          .where(
            (link) =>
                link.courseUnitId == evidence.courseUnitId &&
                link.role == ContentLinkRole.assess &&
                link.conceptIds.contains(evidence.conceptId) &&
                (!_requiresSingleConceptAssessment(evidence.contentKind) ||
                    (link.conceptIds.length == 1 &&
                        link.conceptIds.single == evidence.conceptId)),
          )
          .toList(growable: false);
      final isSpeechStyle =
          evidence.contentKind != CurriculumContentKind.smalltalk ||
          catalog.conceptFor(evidence.conceptId)?.kind ==
              ConceptKind.speechStyle;
      final hasExactAssessment =
          _requiresSingleConceptAssessment(evidence.contentKind)
          ? eligibleAssessLinks.length == 1
          : eligibleAssessLinks.isNotEmpty;
      if (!hasExactAssessment || !isSpeechStyle) {
        throw FormatException(
          'Eligible ${evidence.contentKind.code} evidence must reference an '
          'exact assessment concept.',
        );
      }
    }
  }

  void _validateCheckpoint(ScenarioCheckpointEvidence checkpoint) {
    _validTimestamp(checkpoint.occurredAt);
    _validScore(checkpoint.score);
    final links = catalog.linksForContent(
      CurriculumContentKind.scenario,
      checkpoint.scenarioId,
    );
    if (links.isEmpty) {
      throw FormatException(
        'Unknown checkpoint scenario ${checkpoint.scenarioId}.',
      );
    }
    if (checkpoint.courseUnitId != null) {
      _requireKnownUnit(checkpoint.courseUnitId!);
      if (!links.any((link) => link.courseUnitId == checkpoint.courseUnitId)) {
        throw FormatException(
          'Checkpoint course unit does not match ${checkpoint.scenarioId}.',
        );
      }
    }
    if (checkpoint.courseEligible && checkpoint.courseUnitId == null) {
      throw const FormatException(
        'Eligible checkpoint requires a course unit.',
      );
    }
    if (checkpoint.courseEligible && checkpoint.missionContentLinkId != null) {
      final unit = catalog.courseUnitFor(checkpoint.courseUnitId!);
      final hasExactAssessment =
          unit != null &&
          unit.checkpointContentIds.contains(
            '${CurriculumContentKind.scenario.code}:${checkpoint.scenarioId}',
          ) &&
          links.any(
            (link) =>
                link.id == checkpoint.missionContentLinkId &&
                link.courseUnitId == unit.id &&
                link.exactlyAssesses(unit),
          );
      if (!hasExactAssessment) {
        throw FormatException(
          'Eligible checkpoint must reference its mission assessment link.',
        );
      }
    }
  }

  void _validateUnitIdList(List<String> ids, String label) {
    if (ids.length != ids.toSet().length) {
      throw FormatException('Duplicate $label IDs are not allowed.');
    }
    for (final id in ids) {
      _requireKnownUnit(id);
    }
  }

  void _requireKnownConcept(String id) {
    if (id.trim().isEmpty || catalog.conceptFor(id) == null) {
      throw FormatException('Unknown concept: $id');
    }
  }

  void _requireKnownUnit(String id) {
    if (id.trim().isEmpty || catalog.courseUnitFor(id) == null) {
      throw FormatException('Unknown course unit: $id');
    }
  }

  String? _scenarioIdFromCheckpointKey(String contentKey) {
    final pieces = contentKey.split(':');
    if (pieces.length != 2 ||
        pieces.first != CurriculumContentKind.scenario.code ||
        pieces.last.trim().isEmpty) {
      return null;
    }
    return pieces.last;
  }

  DateTime _validTimestamp(DateTime value) {
    final normalized = value.toUtc();
    if (normalized.millisecondsSinceEpoch == 0) {
      throw const FormatException(
        'Course evidence requires a non-epoch occurredAt timestamp.',
      );
    }
    return normalized;
  }

  double _validScore(double value) {
    if (!value.isFinite || value < 0 || value > 1) {
      throw const FormatException('Course score must be between 0 and 1.');
    }
    return value;
  }

  double? _validOptionalScore(double? value) =>
      value == null ? null : _validScore(value);

  String _normalizeLevel(String value) {
    final level = value.trim().toLowerCase();
    if (!const {'a1', 'a2', 'b1', 'b2'}.contains(level)) {
      throw FormatException('Unsupported placement level: $value');
    }
    return level;
  }

  int _levelRank(String level) => switch (level) {
    'a1' => 0,
    'a2' => 1,
    'b1' => 2,
    'b2' => 3,
    _ => throw FormatException('Unsupported curriculum level: $level'),
  };

  List<CourseUnit> get _orderedUnits {
    final units = catalog.courseUnits.toList();
    units.sort((left, right) {
      final level = _levelRank(left.level).compareTo(_levelRank(right.level));
      if (level != 0) return level;
      final order = left.order.compareTo(right.order);
      return order != 0 ? order : left.id.compareTo(right.id);
    });
    return units;
  }

  int _compareUnitIds(String left, String right) {
    final leftIndex = _orderedUnits.indexWhere((unit) => unit.id == left);
    final rightIndex = _orderedUnits.indexWhere((unit) => unit.id == right);
    return leftIndex.compareTo(rightIndex);
  }

  void _collectSnapshotConflicts(
    CourseMasterySnapshot snapshot,
    List<CourseMasteryMergeConflict> conflicts,
  ) {
    if (snapshot.version != CourseMasterySnapshot.currentVersion) {
      conflicts.add(
        CourseMasteryMergeConflict(
          kind: CourseMasteryMergeConflictKind.version,
          id: snapshot.version.toString(),
        ),
      );
    }

    var placementValid = true;
    if (snapshot.placementLevel != null) {
      try {
        _normalizeLevel(snapshot.placementLevel!);
      } on FormatException {
        placementValid = false;
        conflicts.add(
          CourseMasteryMergeConflict(
            kind: CourseMasteryMergeConflictKind.placement,
            id: snapshot.placementLevel!,
          ),
        );
      }
    }

    var progressionReferencesValid = true;
    final currentId = snapshot.currentCourseUnitId;
    if (currentId != null && catalog.courseUnitFor(currentId) == null) {
      progressionReferencesValid = false;
      conflicts.add(
        CourseMasteryMergeConflict(
          kind: CourseMasteryMergeConflictKind.progression,
          id: currentId,
        ),
      );
    }
    progressionReferencesValid =
        _collectUnitListConflicts(snapshot.completedUnitIds, conflicts) &&
        progressionReferencesValid;
    progressionReferencesValid =
        _collectUnitListConflicts(
          snapshot.bypassedPrerequisiteUnitIds,
          conflicts,
        ) &&
        progressionReferencesValid;
    final overlap = snapshot.completedUnitIds.toSet().intersection(
      snapshot.bypassedPrerequisiteUnitIds.toSet(),
    );
    for (final id in overlap) {
      conflicts.add(
        CourseMasteryMergeConflict(
          kind: CourseMasteryMergeConflictKind.progression,
          id: id,
        ),
      );
    }
    if (progressionReferencesValid && placementValid && overlap.isEmpty) {
      try {
        _validateProgressionCoherence(snapshot);
      } on FormatException {
        conflicts.add(
          const CourseMasteryMergeConflict(
            kind: CourseMasteryMergeConflictKind.progression,
            id: 'snapshot',
          ),
        );
      }
    }

    for (final entry in snapshot.evidence) {
      try {
        if (entry.id.trim().isEmpty) {
          throw const FormatException('Evidence ID must not be empty.');
        }
        _validateEvidence(entry);
      } on FormatException {
        conflicts.add(
          CourseMasteryMergeConflict(
            kind: CourseMasteryMergeConflictKind.evidence,
            id: entry.id,
          ),
        );
      }
    }
    for (final entry in snapshot.scenarioCheckpoints) {
      try {
        if (entry.id.trim().isEmpty) {
          throw const FormatException('Checkpoint ID must not be empty.');
        }
        _validateCheckpoint(entry);
      } on FormatException {
        conflicts.add(
          CourseMasteryMergeConflict(
            kind: CourseMasteryMergeConflictKind.checkpoint,
            id: entry.id,
          ),
        );
      }
    }
  }

  bool _collectUnitListConflicts(
    List<String> ids,
    List<CourseMasteryMergeConflict> conflicts,
  ) {
    var valid = true;
    final seen = <String>{};
    for (final id in ids) {
      if (!seen.add(id) || catalog.courseUnitFor(id) == null) {
        valid = false;
        conflicts.add(
          CourseMasteryMergeConflict(
            kind: CourseMasteryMergeConflictKind.progression,
            id: id,
          ),
        );
      }
    }
    return valid;
  }

  List<T> _mergeIdentityHistory<T>(
    List<T> local,
    List<T> remote, {
    required CourseMasteryMergeConflictKind kind,
    required String Function(T entry) idOf,
    required String Function(T entry) bodyOf,
    required List<CourseMasteryMergeConflict> conflicts,
  }) {
    final merged = <String, T>{};
    final bodies = <String, String>{};
    for (final entry in [...local, ...remote]) {
      final id = idOf(entry);
      final body = bodyOf(entry);
      final previous = bodies[id];
      if (previous != null && previous != body) {
        conflicts.add(CourseMasteryMergeConflict(kind: kind, id: id));
        continue;
      }
      bodies[id] = body;
      merged[id] = entry;
    }
    return merged.values.toList();
  }

  List<CourseMasteryMergeConflict> _sortedConflicts(
    Iterable<CourseMasteryMergeConflict> conflicts,
  ) {
    final sorted = conflicts.toSet().toList()
      ..sort((left, right) {
        final kind = left.kind.index.compareTo(right.kind.index);
        return kind != 0 ? kind : left.id.compareTo(right.id);
      });
    return List.unmodifiable(sorted);
  }

  String? _normalizedPlacement(String? value) => value?.trim().toLowerCase();

  bool _hasSequentialCourseState(CourseMasterySnapshot? snapshot) {
    if (snapshot == null) return false;
    return snapshot.placementLevel != null ||
        snapshot.currentCourseUnitId != null ||
        snapshot.completedUnitIds.isNotEmpty ||
        snapshot.bypassedPrerequisiteUnitIds.isNotEmpty;
  }

  int _compareEvidence(MasteryEvidence left, MasteryEvidence right) {
    final time = left.occurredAt.compareTo(right.occurredAt);
    return time != 0 ? time : left.id.compareTo(right.id);
  }

  int _compareCheckpoints(
    ScenarioCheckpointEvidence left,
    ScenarioCheckpointEvidence right,
  ) {
    final time = left.occurredAt.compareTo(right.occurredAt);
    return time != 0 ? time : left.id.compareTo(right.id);
  }
}
