import 'dart:convert';

import '../models/course_mastery.dart';
import '../models/curriculum.dart';
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
    this.newlyUnlockedUnit,
    this.remediation,
  });

  final CourseMasterySnapshot snapshot;
  final CourseUnit? currentUnit;
  final CourseUnit? newlyUnlockedUnit;
  final RemediationRecommendation? remediation;
}

/// Local, schema-checked progression graph for grammar, particles, speech
/// style and scenario checkpoints. It never writes vocabulary SRS or pack
/// progress; those systems retain their existing semantics.
class CourseMasteryService {
  CourseMasteryService(this.catalog);

  /// Retain enough detail for local remediation while preventing unbounded
  /// SharedPreferences growth. When trimming, unresolved corrections and
  /// active-mission unlock inputs take priority over ordinary history.
  static const int evidenceCap = 300;

  final CurriculumCatalog catalog;
  CourseMasterySnapshot _snapshot = const CourseMasterySnapshot.empty();
  bool _loaded = false;

  CourseMasterySnapshot get snapshot => _snapshot;
  CourseUnit? get currentUnit => _snapshot.currentCourseUnitId == null
      ? null
      : catalog.courseUnitFor(_snapshot.currentCourseUnitId!);

  /// Starts the sequential path at the first unit of a chosen CEFR level.
  /// Earlier units are explicitly listed as bypassed prerequisites; they are
  /// never represented as completed work.
  Future<CourseMasterySnapshot> initializeForPlacement(String levelCode) async {
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

    _snapshot = CourseMasterySnapshot(
      placementLevel: level,
      currentCourseUnitId: startingUnit.id,
      bypassedPrerequisiteUnitIds: bypassed,
    );
    _loaded = true;
    await _persist();
    return _snapshot;
  }

  /// Reloads and validates the durable local state. A bad catalog or malformed
  /// evidence is rejected before it can be aggregated into mastery/unlocks.
  Future<CourseMasterySnapshot> refresh() async {
    _ensureCatalogUsable();
    final raw = Storage.courseMasteryRawJson.trim();
    if (raw.isEmpty) {
      _snapshot = CourseMasterySnapshot(
        placementLevel: Storage.placementLevelCode,
        currentCourseUnitId: Storage.courseUnitId,
      );
      _validateSnapshot(_snapshot);
      _loaded = true;
      return _snapshot;
    }
    final decoded = jsonDecode(raw);
    if (decoded is! Map) {
      throw const FormatException('Course mastery storage must be an object.');
    }
    _snapshot = CourseMasterySnapshot.fromJson(
      decoded.map((key, value) => MapEntry(key.toString(), value)),
    );
    _validateSnapshot(_snapshot);
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
  Future<CourseUpdate> recordContentAttempt(
    CurriculumContentKind kind,
    String contentId,
    bool isCorrect, {
    String? conceptId,
    MasteryErrorReason? errorReason,
    DateTime? occurredAt,
    double? score,
  }) async {
    await _ensureLoaded();
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
    final requestedConceptId = conceptId?.trim();
    if (requestedConceptId != null && requestedConceptId.isEmpty) {
      throw const FormatException(
        'Content attempt conceptId must not be empty.',
      );
    }
    final conceptIds = requestedConceptId == null
        ? (allLinks.expand((link) => link.conceptIds).toSet().toList()..sort())
        : <String>[requestedConceptId];
    if (conceptIds.isEmpty) {
      throw const FormatException('Content attempt has no linked concept.');
    }

    final entries = <MasteryEvidence>[..._snapshot.evidence];
    for (final id in conceptIds) {
      _requireKnownConcept(id);
      final matchingLinks = allLinks
          .where((link) => link.conceptIds.contains(id))
          .toList(growable: false);
      if (matchingLinks.isEmpty) {
        throw FormatException(
          'Content ${kind.code}:$normalizedContentId is not linked to concept $id.',
        );
      }
      final activeLink = _activeLinkFor(matchingLinks);
      final sourceLink = activeLink ?? _preferredLink(matchingLinks);
      entries.add(
        MasteryEvidence(
          conceptId: id,
          contentKind: kind,
          contentId: normalizedContentId,
          courseUnitId: sourceLink.courseUnitId,
          isCorrect: isCorrect,
          occurredAt: timestamp,
          errorReason: errorReason,
          score: checkedScore,
          courseEligible: activeLink != null,
        ),
      );
    }
    _snapshot = _snapshot.copyWith(evidence: _boundedEvidence(entries));
    return _commitUpdate();
  }

  /// Records a scenario's aggregate checkpoint score. Only a score completed
  /// from the current mission's declared checkpoint can unlock that mission.
  Future<CourseUpdate> recordScenarioCheckpoint(
    String scenarioId,
    double score, {
    DateTime? occurredAt,
  }) async {
    await _ensureLoaded();
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
    final activeCheckpoint = activeUnit == null
        ? null
        : links
              .where(
                (link) =>
                    link.courseUnitId == activeUnit.id &&
                    activeUnit.checkpointContentIds.contains(link.contentKey),
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
          score: checkedScore,
          occurredAt: timestamp,
          courseEligible: activeCheckpoint != null,
        ),
      ]),
    );
    return _commitUpdate();
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
        .where((item) => item.courseEligible)
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
      if (eligible.length >= 3 && accuracy >= .85) {
        return CourseContentState.stableMastery;
      }
      return CourseContentState.checkpointPassed;
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

  Future<CourseUpdate> _commitUpdate() async {
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
    for (final conceptId in unit.requiredConceptIds) {
      final evidence = _snapshot.evidence
          .where(
            (item) =>
                item.courseEligible &&
                item.courseUnitId == unit.id &&
                item.conceptId == conceptId,
          )
          .toList(growable: false);
      if (evidence.isEmpty || _accuracy(evidence) < threshold) return false;
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
      if (matching.isEmpty) return false;
      if (_latestCheckpoint(matching).score < threshold) return false;
    }
    return true;
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

  ContentLink? _activeLinkFor(List<ContentLink> links) {
    final currentId = _snapshot.currentCourseUnitId;
    if (currentId == null) return null;
    for (final link in links) {
      if (link.courseUnitId == currentId) return link;
    }
    return null;
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
      if (!evidence.courseEligible) continue;
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
    final active = currentUnit;
    final unresolved = _pendingRemediationsFor(entries).values.toSet();
    return _boundedByPriority(
      entries,
      (entry) =>
          unresolved.contains(entry) ||
          (active != null &&
              entry.courseEligible &&
              entry.courseUnitId == active.id &&
              active.requiredConceptIds.contains(entry.conceptId)),
    );
  }

  List<ScenarioCheckpointEvidence> _boundedCheckpoints(
    List<ScenarioCheckpointEvidence> entries,
  ) {
    final active = currentUnit;
    if (active == null || active.checkpointContentIds.isEmpty) {
      return _boundedByPriority(entries, (_) => false);
    }
    final requiredScenarioIds = active.checkpointContentIds
        .map(_scenarioIdFromCheckpointKey)
        .whereType<String>()
        .toSet();
    final latestRequired = <String, ScenarioCheckpointEvidence>{};
    for (final entry in entries) {
      if (entry.courseEligible &&
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

  Future<void> _persist() async {
    _ensureCatalogUsable();
    _validateSnapshot(_snapshot);
    if (_snapshot.placementLevel != null) {
      await Storage.setPlacementLevelCode(_snapshot.placementLevel!);
    }
    if (_snapshot.currentCourseUnitId != null) {
      await Storage.setCourseUnitId(_snapshot.currentCourseUnitId!);
    }
    await Storage.setCourseMasteryRawJson(jsonEncode(_snapshot.toJson()));
  }

  void _ensureCatalogUsable() {
    if (catalog.validationIssues.isNotEmpty) {
      throw FormatException(
        'Course mastery requires a valid curriculum catalog: '
        '${catalog.validationIssues.join('; ')}',
      );
    }
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
    if (evidence.courseEligible && evidence.courseUnitId == null) {
      throw const FormatException('Eligible evidence requires a course unit.');
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
}
