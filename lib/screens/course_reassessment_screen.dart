import 'package:flutter/material.dart';

import '../l10n/generated/app_localizations.dart';
import '../models/can_do_segment.dart';
import '../models/course_mastery.dart';
import '../models/productive_mastery.dart';
import '../services/canonical_course_segment_loader.dart';
import '../services/course_mastery_service.dart';
import '../services/course_mission_navigation.dart';
import '../services/course_progress_service.dart';
import '../services/course_segment_catalog.dart';
import '../services/productive_assessment_service.dart';
import '../widgets/app_error.dart';
import '../widgets/app_loading.dart';
import '../widgets/sori/app_bar.dart';
import '../widgets/sori/button.dart';
import '../widgets/sori/card.dart';
import '../widgets/sori/responsive.dart';
import '../widgets/sori/screen_background.dart';
import '../widgets/sori/tokens.dart';

typedef ReassessmentSnapshotLoader = Future<CourseMasterySnapshot?> Function();

typedef ReassessmentEvidenceRecorder =
    Future<ProductiveCourseUpdate> Function({
      required ProductiveAssessmentResult result,
      required ProductiveAssessmentCatalog assessmentCatalog,
      required CourseSegmentCatalog segmentCatalog,
    });

/// Executes one exact productive assessment without rewinding the course.
///
/// Free writing and source notes remain in this widget's memory. Only the
/// scored [ProductiveMasteryEvidence] returned by
/// [ReassessmentEvidenceRecorder] can leave the screen. Oral production stays
/// unavailable until its separate privacy-reviewed authority is installed.
class CourseReassessmentScreen extends StatefulWidget {
  const CourseReassessmentScreen({
    super.key,
    required this.arguments,
    this.bundleLoader,
    this.snapshotLoader,
    this.evidenceRecorder,
    this.clock,
  });

  const CourseReassessmentScreen.invalid({super.key})
    : arguments = null,
      bundleLoader = null,
      snapshotLoader = null,
      evidenceRecorder = null,
      clock = null;

  final CourseReassessmentRouteArguments? arguments;
  final Future<CanonicalCourseSegmentBundle> Function()? bundleLoader;
  final ReassessmentSnapshotLoader? snapshotLoader;
  final ReassessmentEvidenceRecorder? evidenceRecorder;
  final DateTime Function()? clock;

  @override
  State<CourseReassessmentScreen> createState() =>
      _CourseReassessmentScreenState();
}

class _CourseReassessmentScreenState extends State<CourseReassessmentScreen> {
  final TextEditingController _answerController = TextEditingController();
  final Map<String, TextEditingController> _slotControllers = {};
  final Map<String, String?> _slotSourceIds = {};
  final Map<String, Set<ProductiveEvidenceRole>> _evidenceRoles = {};
  CanonicalCourseSegmentBundle? _bundle;
  CourseMasterySnapshot? _snapshot;
  CanDoSegment? _segment;
  List<ProductiveAssessmentDefinition> _definitions = const [];
  int _definitionIndex = 0;
  Object? _loadError;
  bool _loading = true;
  bool _submitting = false;
  bool _segmentVerified = false;
  ProductiveAssessmentResult? _latestResult;
  String? _notice;

  ProductiveAssessmentDefinition? get _definition {
    if (_definitions.isEmpty || _definitionIndex >= _definitions.length) {
      return null;
    }
    return _definitions[_definitionIndex];
  }

  ProductiveAssessmentBundle? get _assessmentBundle {
    final bundle = _bundle;
    final segment = _segment;
    if (bundle == null || segment == null) {
      return null;
    }
    return bundle.productiveAssessments.bundleForSegment(segment.id);
  }

  ProductiveProjectStep? get _projectStep {
    final bundle = _bundle;
    final assessmentBundle = _assessmentBundle;
    if (bundle == null || assessmentBundle == null) {
      return null;
    }
    final project =
        bundle.productiveAssessments.projectsById[assessmentBundle.projectId];
    if (project == null) {
      return null;
    }
    for (final step in project.steps) {
      if (step.id == assessmentBundle.stepId) {
        return step;
      }
    }
    return null;
  }

  List<ProductiveSourceSnippet> get _sourceSnippets {
    final bundle = _bundle;
    final step = _projectStep;
    if (bundle == null || step == null) {
      return const [];
    }
    return List.unmodifiable([
      for (final id in step.snippetIds)
        if (bundle.productiveAssessments.snippetsById[id] case final snippet?)
          snippet,
    ]);
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _answerController.clear();
    _answerController.dispose();
    for (final controller in _slotControllers.values) {
      controller.clear();
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _loadError = null;
      _notice = null;
    });
    try {
      final arguments = widget.arguments;
      if (arguments == null) {
        throw const FormatException('Missing reassessment route arguments.');
      }
      final loadBundle =
          widget.bundleLoader ?? CanonicalCourseSegmentLoader.load;
      final loadSnapshot =
          widget.snapshotLoader ?? CourseProgressService.shared.readForDisplay;
      final results = await Future.wait<Object?>([
        loadBundle(),
        loadSnapshot(),
      ]);
      final bundle = results[0]! as CanonicalCourseSegmentBundle;
      final snapshot = results[1] as CourseMasterySnapshot?;
      final segment = bundle.segments.findSegment(arguments.canDoSegmentId);
      if (segment == null ||
          segment.parentCourseUnitId != arguments.courseUnitId) {
        throw const FormatException('Unknown reassessment segment.');
      }
      if (snapshot == null ||
          snapshot.bypassedPrerequisiteUnitIds.contains(
            segment.parentCourseUnitId,
          ) ||
          (!snapshot.completedUnitIds.contains(segment.parentCourseUnitId) &&
              snapshot.currentCourseUnitId != segment.parentCourseUnitId)) {
        throw StateError('Course unit is not eligible for reassessment.');
      }
      final definitions = <ProductiveAssessmentDefinition>[];
      for (final requirement in segment.assessmentRequirements) {
        final definition = bundle.productiveAssessments.definitionFor(
          requirement.assessmentItemId,
        );
        if (definition == null) {
          throw const FormatException(
            'Segment assessment has no executable definition.',
          );
        }
        definitions.add(definition);
      }
      final initialIndex = definitions.indexWhere(
        (definition) =>
            definition.assessmentItemId == arguments.assessmentItemId,
      );
      if (initialIndex < 0) {
        throw const FormatException(
          'Requested assessment does not belong to the segment.',
        );
      }
      final verified = verifiedCanDoSegmentIds(
        evidence: snapshot.productiveEvidence,
        projectStepEvidence: snapshot.productiveProjectStepEvidence,
        segmentCatalog: bundle.segments,
        assessmentCatalog: bundle.productiveAssessments,
      ).contains(segment.id);
      if (!mounted) {
        return;
      }
      setState(() {
        _bundle = bundle;
        _snapshot = snapshot;
        _segment = segment;
        _definitions = List.unmodifiable(definitions);
        _definitionIndex = initialIndex;
        _segmentVerified = verified;
        _loading = false;
      });
      _resetInputsForDefinition();
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _loadError = error;
        _loading = false;
      });
    }
  }

  void _resetInputsForDefinition() {
    _answerController.clear();
    for (final controller in _slotControllers.values) {
      controller.clear();
      controller.dispose();
    }
    _slotControllers.clear();
    _slotSourceIds.clear();
    _evidenceRoles.clear();
    final definition = _definition;
    final rubric = definition?.textRubric;
    if (rubric != null) {
      for (final slotId in rubric.requiredStructuredSlotIds) {
        _slotControllers[slotId] = TextEditingController();
        _slotSourceIds[slotId] = null;
      }
    }
    for (final snippet in _sourceSnippets) {
      _evidenceRoles[snippet.id] = <ProductiveEvidenceRole>{};
    }
    if (mounted) {
      setState(() {
        _latestResult = null;
        _notice = null;
      });
    }
  }

  ProductiveAssessmentDefinition? _missingPrerequisite(
    ProductiveAssessmentDefinition definition,
  ) {
    final snapshot = _snapshot;
    final catalog = _bundle?.productiveAssessments;
    if (snapshot == null || catalog == null) {
      return null;
    }
    List<ProductiveMasteryEvidence> trustedEvidence;
    try {
      trustedEvidence = trustedProductiveMasteryEvidence(
        evidence: snapshot.productiveEvidence,
        assessmentCatalog: catalog,
      );
    } on FormatException {
      trustedEvidence = const [];
    }
    for (final prerequisiteId in definition.prerequisiteAssessmentItemIds) {
      final prerequisite = catalog.definitionFor(prerequisiteId);
      if (prerequisite == null) {
        continue;
      }
      final complete = prerequisite.conceptIds.every(
        (conceptId) => trustedEvidence.any(
          (entry) =>
              entry.assessmentItemId == prerequisiteId &&
              entry.conceptId == conceptId &&
              entry.score >= prerequisite.minimumScore,
        ),
      );
      if (!complete) {
        return prerequisite;
      }
    }
    return null;
  }

  Future<void> _openMissingPrerequisite(
    ProductiveAssessmentDefinition prerequisite,
  ) async {
    await Navigator.of(context).pushReplacementNamed(
      courseReassessmentRoute,
      arguments: CourseReassessmentRouteArguments(
        courseUnitId: prerequisite.courseUnitId,
        canDoSegmentId: prerequisite.canDoSegmentId,
        assessmentItemId: prerequisite.assessmentItemId,
      ),
    );
  }

  Future<void> _submitText() async {
    final bundle = _bundle;
    final definition = _definition;
    if (bundle == null || definition == null || _submitting) {
      return;
    }
    setState(() {
      _submitting = true;
      _notice = null;
    });
    try {
      final rubric = definition.textRubric;
      if (rubric == null) {
        throw const FormatException('Assessment is not writable.');
      }
      final occurredAt = (widget.clock ?? DateTime.now)();
      final ProductiveAssessmentResult result;
      if (rubric.requiresStructuredSubmission) {
        result = const ProductiveTextAssessmentEngine().evaluateStructured(
          catalog: bundle.productiveAssessments,
          definition: definition,
          submission: ProductiveStructuredWritingSubmission(
            text: _answerController.text,
            slotValues: {
              for (final entry in _slotControllers.entries)
                entry.key: entry.value.text,
            },
            linkedSourceSpanIds: {
              for (final entry in _slotSourceIds.entries)
                entry.key: [if (entry.value != null) entry.value!],
            },
          ),
          occurredAt: occurredAt,
        );
      } else {
        result = const ProductiveTextAssessmentEngine().evaluate(
          definition: definition,
          input: _answerController.text,
          occurredAt: occurredAt,
        );
      }
      await _acceptResult(result);
    } catch (_) {
      if (mounted) {
        setState(() => _notice = AppL10n.of(context).courseReassessmentError);
      }
    } finally {
      if (mounted) {
        setState(() => _submitting = false);
      }
    }
  }

  Future<void> _submitConnectedEvidence() async {
    final bundle = _bundle;
    final definition = _definition;
    if (bundle == null || definition == null || _submitting) {
      return;
    }
    setState(() {
      _submitting = true;
      _notice = null;
    });
    try {
      final result = const ProductiveConnectedEvidenceEngine().evaluate(
        catalog: bundle.productiveAssessments,
        definition: definition,
        nodes: [
          for (final entry in _evidenceRoles.entries)
            if (entry.value.isNotEmpty)
              ProductiveEvidenceNode(
                sourceSnippetId: entry.key,
                roles: entry.value,
              ),
        ],
        occurredAt: (widget.clock ?? DateTime.now)(),
      );
      await _acceptResult(result);
    } catch (_) {
      if (mounted) {
        setState(() => _notice = AppL10n.of(context).courseReassessmentError);
      }
    } finally {
      if (mounted) {
        setState(() => _submitting = false);
      }
    }
  }

  Future<void> _acceptResult(ProductiveAssessmentResult result) async {
    if (!result.passed) {
      setState(() => _latestResult = result);
      return;
    }
    final bundle = _bundle!;
    final record =
        widget.evidenceRecorder ??
        ({
          required ProductiveAssessmentResult result,
          required ProductiveAssessmentCatalog assessmentCatalog,
          required CourseSegmentCatalog segmentCatalog,
        }) => CourseProgressService.shared.recordProductiveAssessment(
          result: result,
          assessmentCatalog: assessmentCatalog,
          segmentCatalog: segmentCatalog,
        );
    final update = await record(
      result: result,
      assessmentCatalog: bundle.productiveAssessments,
      segmentCatalog: bundle.segments,
    );
    if (update.acceptedEvidence.isEmpty) {
      throw StateError('Successful assessment returned no evidence.');
    }
    final verified = verifiedCanDoSegmentIds(
      evidence: update.snapshot.productiveEvidence,
      projectStepEvidence: update.snapshot.productiveProjectStepEvidence,
      segmentCatalog: bundle.segments,
      assessmentCatalog: bundle.productiveAssessments,
    ).contains(_segment!.id);
    if (!mounted) {
      return;
    }
    setState(() {
      _snapshot = update.snapshot;
      _latestResult = result;
      _segmentVerified = verified;
    });
  }

  void _continue() {
    if (_segmentVerified) {
      Navigator.of(context).pop(true);
      return;
    }
    if (_definitionIndex + 1 >= _definitions.length) {
      setState(() => _notice = AppL10n.of(context).courseReassessmentError);
      return;
    }
    setState(() => _definitionIndex += 1);
    _resetInputsForDefinition();
  }

  void _retry() {
    setState(() {
      _latestResult = null;
      _notice = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);
    if (_loading) {
      return Scaffold(
        appBar: SoriAppBar(title: t.courseReassessmentTitle),
        body: AppLoading(message: t.courseReassessmentLoading),
      );
    }
    if (_loadError != null || _segment == null || _definition == null) {
      return Scaffold(
        appBar: SoriAppBar(title: t.courseReassessmentTitle),
        body: AppError(message: t.courseReassessmentLoadError, onRetry: _load),
      );
    }
    return Scaffold(
      appBar: SoriAppBar(title: t.courseReassessmentTitle),
      body: SoriScreenBackground(
        child: SoriContentClamp(
          maxWidth: 820,
          base: const EdgeInsets.fromLTRB(16, 12, 16, 48),
          builder: (context, padding) => ListView(
            padding: padding,
            children: [
              _buildHeader(t),
              const SizedBox(height: Spacing.lg),
              if (_latestResult case final result?)
                _buildResult(t, result)
              else if (_segmentVerified)
                _buildComplete(t)
              else
                _buildAssessment(t),
              if (_notice != null) ...[
                const SizedBox(height: Spacing.lg),
                Semantics(
                  liveRegion: true,
                  child: SoriCard(
                    accent: SoriActivityColors.review,
                    tinted: true,
                    child: Text(_notice!, style: const TextStyle(height: 1.45)),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(AppL10n t) {
    final locale = Localizations.localeOf(context).languageCode;
    final segment = _segment!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          t.courseReassessmentEyebrow,
          style: const TextStyle(
            color: SoriColors.accent,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.05,
          ),
        ),
        const SizedBox(height: Spacing.sm),
        Text(
          segment.title.pick(locale),
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: Spacing.sm),
        Text(segment.canDo.pick(locale), style: const TextStyle(height: 1.45)),
        const SizedBox(height: Spacing.md),
        Text(
          t.courseReassessmentStep(_definitionIndex + 1, _definitions.length),
          style: TextStyle(
            color: SoriSurfaces.of(context).textDim,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: Spacing.xs),
        LinearProgressIndicator(
          value: (_definitionIndex + 1) / _definitions.length,
          color: SoriActivityColors.speaking,
        ),
      ],
    );
  }

  Widget _buildAssessment(AppL10n t) {
    final definition = _definition!;
    final missing = _missingPrerequisite(definition);
    if (missing != null) {
      return _buildPrerequisite(t, missing);
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildPrompt(t, definition),
        const SizedBox(height: Spacing.lg),
        switch (definition.evidenceMode) {
          SegmentEvidenceMode.guidedProduction ||
          SegmentEvidenceMode.dictation ||
          SegmentEvidenceMode.connectedProduction ||
          SegmentEvidenceMode.openWriting => _buildWriting(t, definition),
          SegmentEvidenceMode.connectedEvidence => _buildConnectedEvidence(
            t,
            definition,
          ),
          SegmentEvidenceMode.oralProduction => _buildOral(t, definition),
        },
        const SizedBox(height: Spacing.md),
        Text(
          t.courseReassessmentPrivacy,
          style: TextStyle(
            color: SoriSurfaces.of(context).textDim,
            fontSize: 13,
            height: 1.4,
          ),
        ),
      ],
    );
  }

  Widget _buildPrompt(AppL10n t, ProductiveAssessmentDefinition definition) {
    final locale = Localizations.localeOf(context).languageCode;
    return SoriCard(
      variant: SoriCardVariant.hero,
      accent: SoriActivityColors.speaking,
      tinted: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _modeLabel(t, definition.evidenceMode),
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: Spacing.md),
          Text(
            definition.prompt.pick(locale),
            style: const TextStyle(fontSize: 19, height: 1.45),
          ),
          const SizedBox(height: Spacing.md),
          Text(
            t.courseReassessmentRole,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: Spacing.xs),
          Text(
            definition.roleInstruction.pick(locale),
            style: const TextStyle(height: 1.45),
          ),
        ],
      ),
    );
  }

  Widget _buildWriting(AppL10n t, ProductiveAssessmentDefinition definition) {
    final rubric = definition.textRubric!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (rubric.requiresStructuredSubmission) ...[
          _buildSources(t),
          const SizedBox(height: Spacing.lg),
          for (
            var index = 0;
            index < rubric.requiredStructuredSlotIds.length;
            index++
          ) ...[
            _buildStructuredSlot(
              t,
              rubric.requiredStructuredSlotIds[index],
              index + 1,
            ),
            const SizedBox(height: Spacing.md),
          ],
        ],
        TextField(
          key: const ValueKey('course-reassessment-answer'),
          controller: _answerController,
          minLines: rubric.requiresStructuredSubmission ? 6 : 3,
          maxLines: 12,
          maxLength: rubric.maxInputCodePoints,
          enabled: !_submitting,
          decoration: InputDecoration(
            labelText: t.courseReassessmentAnswer,
            hintText: t.courseReassessmentAnswerHint,
            alignLabelWithHint: true,
            border: const OutlineInputBorder(),
            helperText: t.courseReassessmentLength(
              rubric.minInputCodePoints,
              rubric.maxInputCodePoints,
            ),
          ),
        ),
        const SizedBox(height: Spacing.md),
        SoriButton.filled(
          key: const ValueKey('course-reassessment-submit-writing'),
          label: _submitting
              ? t.courseReassessmentChecking
              : t.courseReassessmentSubmit,
          fullWidth: true,
          accent: SoriActivityColors.speaking,
          onTap: _submitting ? null : _submitText,
        ),
      ],
    );
  }

  Widget _buildStructuredSlot(AppL10n t, String slotId, int index) {
    final sources = _sourceSnippets;
    return SoriCard(
      variant: SoriCardVariant.base,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            t.courseReassessmentEvidencePoint(index),
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: Spacing.sm),
          TextField(
            key: ValueKey('course-reassessment-slot-$slotId'),
            controller: _slotControllers[slotId],
            minLines: 2,
            maxLines: 4,
            enabled: !_submitting,
            decoration: InputDecoration(
              hintText: t.courseReassessmentEvidencePointHint,
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: Spacing.md),
          DropdownButtonFormField<String>(
            key: ValueKey('course-reassessment-source-$slotId'),
            initialValue: _slotSourceIds[slotId],
            isExpanded: true,
            decoration: InputDecoration(
              labelText: t.courseReassessmentSourceForPoint,
              border: const OutlineInputBorder(),
            ),
            items: [
              for (
                var sourceIndex = 0;
                sourceIndex < sources.length;
                sourceIndex++
              )
                DropdownMenuItem(
                  value: sources[sourceIndex].id,
                  child: Text(
                    t.courseReassessmentSource(sourceIndex + 1),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
            ],
            onChanged: _submitting
                ? null
                : (value) => setState(() => _slotSourceIds[slotId] = value),
          ),
        ],
      ),
    );
  }

  Widget _buildSources(AppL10n t) {
    final locale = Localizations.localeOf(context).languageCode;
    final sources = _sourceSnippets;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          t.courseReassessmentSources,
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: Spacing.sm),
        for (var index = 0; index < sources.length; index++) ...[
          SoriCard(
            variant: SoriCardVariant.compact,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  t.courseReassessmentSource(index + 1),
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: Spacing.xs),
                Text(
                  sources[index].text.pick(locale),
                  style: const TextStyle(height: 1.45),
                ),
                const SizedBox(height: Spacing.xs),
                Text(
                  sources[index].provenance.pick(locale),
                  style: TextStyle(
                    color: SoriSurfaces.of(context).textDim,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          if (index + 1 < sources.length) const SizedBox(height: Spacing.sm),
        ],
      ],
    );
  }

  Widget _buildConnectedEvidence(
    AppL10n t,
    ProductiveAssessmentDefinition definition,
  ) {
    final locale = Localizations.localeOf(context).languageCode;
    final sources = _sourceSnippets;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          t.courseReassessmentConnectSources,
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: Spacing.sm),
        for (var index = 0; index < sources.length; index++) ...[
          SoriCard(
            variant: SoriCardVariant.base,
            selectable: true,
            selected: _evidenceRoles[sources[index].id]!.isNotEmpty,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  t.courseReassessmentSource(index + 1),
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: Spacing.xs),
                Text(
                  sources[index].text.pick(locale),
                  style: const TextStyle(height: 1.45),
                ),
                const SizedBox(height: Spacing.sm),
                Text(
                  t.courseReassessmentRelationship,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                for (final role in sources[index].supportedRoles)
                  CheckboxListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    controlAffinity: ListTileControlAffinity.leading,
                    title: Text(_roleLabel(t, role)),
                    value: _evidenceRoles[sources[index].id]!.contains(role),
                    onChanged: _submitting
                        ? null
                        : (selected) {
                            setState(() {
                              final roles = _evidenceRoles[sources[index].id]!;
                              if (selected == true) {
                                roles.add(role);
                              } else {
                                roles.remove(role);
                              }
                            });
                          },
                  ),
              ],
            ),
          ),
          if (index + 1 < sources.length) const SizedBox(height: Spacing.sm),
        ],
        const SizedBox(height: Spacing.md),
        SoriButton.filled(
          key: const ValueKey('course-reassessment-submit-evidence'),
          label: _submitting
              ? t.courseReassessmentChecking
              : t.courseReassessmentSubmitEvidence,
          fullWidth: true,
          accent: SoriActivityColors.speaking,
          onTap: _submitting ? null : _submitConnectedEvidence,
        ),
      ],
    );
  }

  Widget _buildOral(AppL10n t, ProductiveAssessmentDefinition definition) {
    return SoriCard(
      key: const ValueKey('course-reassessment-oral-unavailable'),
      accent: SoriActivityColors.review,
      tinted: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            t.courseReassessmentOralUnavailableTitle,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: Spacing.sm),
          Text(
            t.courseReassessmentOralUnavailableBody,
            style: const TextStyle(height: 1.45),
          ),
        ],
      ),
    );
  }

  Widget _buildPrerequisite(
    AppL10n t,
    ProductiveAssessmentDefinition prerequisite,
  ) {
    return SoriCard(
      accent: SoriActivityColors.review,
      tinted: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            t.courseReassessmentPrerequisiteTitle,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: Spacing.sm),
          Text(
            t.courseReassessmentPrerequisiteBody,
            style: const TextStyle(height: 1.45),
          ),
          const SizedBox(height: Spacing.md),
          SoriButton.outlined(
            label: t.courseReassessmentOpenPrerequisite,
            fullWidth: true,
            onTap: () => _openMissingPrerequisite(prerequisite),
          ),
        ],
      ),
    );
  }

  Widget _buildResult(AppL10n t, ProductiveAssessmentResult result) {
    final passed = result.passed;
    return Semantics(
      liveRegion: true,
      child: SoriCard(
        variant: SoriCardVariant.hero,
        accent: passed
            ? SoriActivityColors.completion
            : SoriActivityColors.review,
        tinted: true,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Icon(
              passed ? Icons.check_circle_outline : Icons.refresh_rounded,
              size: 52,
              color: passed
                  ? SoriActivityColors.completion
                  : SoriActivityColors.review,
            ),
            const SizedBox(height: Spacing.md),
            Text(
              passed
                  ? t.courseReassessmentPassedTitle
                  : t.courseReassessmentTryAgainTitle,
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: Spacing.sm),
            Text(
              passed
                  ? t.courseReassessmentPassedBody((result.score * 100).round())
                  : t.courseReassessmentTryAgainBody(
                      (result.score * 100).round(),
                    ),
              textAlign: TextAlign.center,
              style: const TextStyle(height: 1.45),
            ),
            const SizedBox(height: Spacing.lg),
            if (passed)
              SoriButton.filled(
                key: const ValueKey('course-reassessment-continue'),
                label: _segmentVerified
                    ? t.courseReassessmentFinish
                    : t.courseReassessmentContinue,
                trailingIcon: Icons.arrow_forward_rounded,
                fullWidth: true,
                accent: SoriActivityColors.completion,
                onTap: _continue,
              )
            else
              SoriButton.outlined(
                key: const ValueKey('course-reassessment-retry'),
                label: t.courseReassessmentRetry,
                fullWidth: true,
                onTap: _retry,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildComplete(AppL10n t) {
    return SoriCard(
      variant: SoriCardVariant.hero,
      accent: SoriActivityColors.completion,
      tinted: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Icon(
            Icons.verified_outlined,
            size: 56,
            color: SoriActivityColors.completion,
          ),
          const SizedBox(height: Spacing.md),
          Text(
            t.courseReassessmentCompleteTitle,
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: Spacing.sm),
          Text(
            t.courseReassessmentCompleteBody,
            textAlign: TextAlign.center,
            style: const TextStyle(height: 1.45),
          ),
          const SizedBox(height: Spacing.lg),
          SoriButton.filled(
            label: t.courseReassessmentFinish,
            fullWidth: true,
            accent: SoriActivityColors.completion,
            onTap: () => Navigator.of(context).pop(true),
          ),
        ],
      ),
    );
  }

  String _modeLabel(AppL10n t, SegmentEvidenceMode mode) => switch (mode) {
    SegmentEvidenceMode.guidedProduction =>
      t.courseReassessmentModeGuidedProduction,
    SegmentEvidenceMode.dictation => t.courseReassessmentModeDictation,
    SegmentEvidenceMode.connectedProduction =>
      t.courseReassessmentModeConnectedProduction,
    SegmentEvidenceMode.openWriting => t.courseReassessmentModeOpenWriting,
    SegmentEvidenceMode.oralProduction => t.courseReassessmentModeOral,
    SegmentEvidenceMode.connectedEvidence =>
      t.courseReassessmentModeConnectedEvidence,
  };

  String _roleLabel(AppL10n t, ProductiveEvidenceRole role) => switch (role) {
    ProductiveEvidenceRole.support => t.courseReassessmentRoleSupport,
    ProductiveEvidenceRole.contrast => t.courseReassessmentRoleContrast,
    ProductiveEvidenceRole.limitation => t.courseReassessmentRoleLimitation,
    ProductiveEvidenceRole.complement => t.courseReassessmentRoleComplement,
    ProductiveEvidenceRole.context => t.courseReassessmentRoleContext,
    ProductiveEvidenceRole.stakeholderPerspective =>
      t.courseReassessmentRoleStakeholder,
    ProductiveEvidenceRole.counterexample =>
      t.courseReassessmentRoleCounterexample,
  };
}
