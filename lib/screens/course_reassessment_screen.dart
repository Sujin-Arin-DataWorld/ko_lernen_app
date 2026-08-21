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
import '../widgets/sori/button.dart';
import '../widgets/sori/card.dart';
import '../widgets/sori/progress.dart';
import '../widgets/sori/standard_page.dart';
import '../widgets/sori/text_field.dart';
import '../widgets/sori/tokens.dart';
import '../widgets/sori/window_class.dart';

typedef ReassessmentSnapshotLoader = Future<CourseMasterySnapshot?> Function();

typedef ReassessmentEvidenceRecorder =
    Future<ProductiveCourseUpdate> Function({
      required ProductiveAssessmentResult result,
      required ProductiveAssessmentCatalog assessmentCatalog,
      required CourseSegmentCatalog segmentCatalog,
    });

typedef ReassessmentProjectStepRecorder =
    Future<ProductiveProjectStepUpdate> Function({
      required ProductiveProjectStepReviewResult result,
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
    this.projectStepRecorder,
    this.clock,
    this.allowUnreviewedContentForTesting = false,
  });

  const CourseReassessmentScreen.invalid({super.key})
    : arguments = null,
      bundleLoader = null,
      snapshotLoader = null,
      evidenceRecorder = null,
      projectStepRecorder = null,
      clock = null,
      allowUnreviewedContentForTesting = false;

  final CourseReassessmentRouteArguments? arguments;
  final Future<CanonicalCourseSegmentBundle> Function()? bundleLoader;
  final ReassessmentSnapshotLoader? snapshotLoader;
  final ReassessmentEvidenceRecorder? evidenceRecorder;
  final ReassessmentProjectStepRecorder? projectStepRecorder;
  final DateTime Function()? clock;
  final bool allowUnreviewedContentForTesting;

  @override
  State<CourseReassessmentScreen> createState() =>
      _CourseReassessmentScreenState();
}

class _CourseReassessmentScreenState extends State<CourseReassessmentScreen> {
  final TextEditingController _answerController = TextEditingController();
  final Map<String, TextEditingController> _slotControllers = {};
  final Map<String, String?> _slotSourceIds = {};
  final Map<String, Set<ProductiveEvidenceRole>> _evidenceRoles = {};
  final Set<String> _reviewedSourceIds = {};
  final Set<String> _openedProvenanceSourceIds = {};
  final Set<String> _expandedProvenanceSourceIds = {};
  CanonicalCourseSegmentBundle? _bundle;
  CourseMasterySnapshot? _snapshot;
  CanDoSegment? _segment;
  List<ProductiveAssessmentDefinition> _definitions = const [];
  int _definitionIndex = 0;
  Object? _loadError;
  bool _loading = true;
  bool _submitting = false;
  bool _segmentVerified = false;
  bool _projectReviewComplete = false;
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

  ProductiveProjectDefinition? get _project {
    final bundle = _bundle;
    final assessmentBundle = _assessmentBundle;
    if (bundle == null || assessmentBundle == null) {
      return null;
    }
    return bundle.productiveAssessments.projectsById[assessmentBundle
        .projectId];
  }

  ProductiveProjectStep? get _requiredReviewStep {
    final project = _project;
    final assessedStep = _projectStep;
    if (project == null || assessedStep == null) {
      return null;
    }
    for (final step in project.steps) {
      if (step.order == assessedStep.order - 1) {
        return step;
      }
    }
    return null;
  }

  List<ProductiveSourceSnippet> get _reviewSourceSnippets {
    final bundle = _bundle;
    final project = _project;
    final step = _requiredReviewStep;
    if (bundle == null || project == null || step == null) {
      return const [];
    }
    final ids = bundle.productiveAssessments.introducedSourceIdsForStep(
      project.id,
      step.id,
    );
    return List.unmodifiable([
      for (final id in ids)
        if (bundle.productiveAssessments.snippetsById[id] case final snippet?)
          snippet,
    ]);
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
      if (!ProductiveAssessmentCatalog.runtimeContentApproved &&
          !widget.allowUnreviewedContentForTesting) {
        throw StateError('Productive assessment content review is pending.');
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
      final assessmentBundle = bundle.productiveAssessments.bundleForSegment(
        segment.id,
      );
      var projectReviewComplete = true;
      if (assessmentBundle != null) {
        final project = bundle
            .productiveAssessments
            .projectsById[assessmentBundle.projectId]!;
        final assessedStep = project.steps.singleWhere(
          (step) => step.id == assessmentBundle.stepId,
        );
        final reviewStep = project.steps.singleWhere(
          (step) => step.order == assessedStep.order - 1,
        );
        final trustedSteps = trustedProductiveProjectStepEvidence(
          evidence: snapshot.productiveProjectStepEvidence,
          assessmentCatalog: bundle.productiveAssessments,
        );
        projectReviewComplete = trustedSteps.any(
          (entry) =>
              entry.projectId == project.id && entry.stepId == reviewStep.id,
        );
      }
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
        _projectReviewComplete = projectReviewComplete;
        _reviewedSourceIds.clear();
        _openedProvenanceSourceIds.clear();
        _expandedProvenanceSourceIds.clear();
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
    await Navigator.of(context).pushNamed(
      courseReassessmentRoute,
      arguments: CourseReassessmentRouteArguments(
        courseUnitId: prerequisite.courseUnitId,
        canDoSegmentId: prerequisite.canDoSegmentId,
        assessmentItemId: prerequisite.assessmentItemId,
      ),
    );
    if (mounted) {
      await _load();
    }
  }

  Future<void> _submitProjectReview() async {
    final bundle = _bundle;
    final project = _project;
    final reviewStep = _requiredReviewStep;
    if (bundle == null ||
        project == null ||
        reviewStep == null ||
        _submitting) {
      return;
    }
    setState(() {
      _submitting = true;
      _notice = null;
    });
    try {
      final result = const ProductiveProjectStepReviewEngine().evaluate(
        catalog: bundle.productiveAssessments,
        projectId: project.id,
        stepId: reviewStep.id,
        reviewedSourceSnippetIds: _reviewedSourceIds,
        openedProvenanceSnippetIds: _openedProvenanceSourceIds,
      );
      if (!result.passed) {
        if (mounted) {
          setState(
            () => _notice = AppL10n.of(
              context,
            ).courseReassessmentProjectReviewIncomplete,
          );
        }
        return;
      }
      final record =
          widget.projectStepRecorder ??
          ({
            required ProductiveProjectStepReviewResult result,
            required ProductiveAssessmentCatalog assessmentCatalog,
            required CourseSegmentCatalog segmentCatalog,
          }) => CourseProgressService.shared.recordProductiveProjectStep(
            result: result,
            assessmentCatalog: assessmentCatalog,
            segmentCatalog: segmentCatalog,
          );
      final update = await record(
        result: result,
        assessmentCatalog: bundle.productiveAssessments,
        segmentCatalog: bundle.segments,
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _snapshot = update.snapshot;
        _projectReviewComplete = true;
      });
      _resetInputsForDefinition();
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
      _finishSegment();
      return;
    }
    if (_definitionIndex + 1 >= _definitions.length) {
      setState(() => _notice = AppL10n.of(context).courseReassessmentError);
      return;
    }
    setState(() => _definitionIndex += 1);
    _resetInputsForDefinition();
  }

  void _finishSegment() {
    final catalog = _bundle?.productiveAssessments;
    final segment = _segment;
    if (catalog == null || segment == null) {
      Navigator.of(context).pop(true);
      return;
    }
    final nextBundle = catalog.nextBundleInProject(segment.id);
    if (nextBundle == null) {
      Navigator.of(context).pop(true);
      return;
    }
    final nextDefinition = catalog.definitionFor(
      nextBundle.assessmentItemIds.first,
    );
    if (nextDefinition == null) {
      setState(() => _notice = AppL10n.of(context).courseReassessmentError);
      return;
    }
    Navigator.of(context).pushReplacementNamed(
      courseReassessmentRoute,
      arguments: CourseReassessmentRouteArguments(
        courseUnitId: nextDefinition.courseUnitId,
        canDoSegmentId: nextDefinition.canDoSegmentId,
        assessmentItemId: nextDefinition.assessmentItemId,
      ),
    );
  }

  void _retry() {
    setState(() {
      _latestResult = null;
      _notice = null;
    });
  }

  Widget _buildScrollableState(EdgeInsets resolvedPadding, Widget child) =>
      LayoutBuilder(
        builder: (context, constraints) {
          final minHeight = (constraints.maxHeight - resolvedPadding.vertical)
              .clamp(0.0, double.infinity)
              .toDouble();
          return SingleChildScrollView(
            padding: resolvedPadding,
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: minHeight),
              child: child,
            ),
          );
        },
      );

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);
    if (_loading) {
      return SoriStandardFrame(
        appBarTitle: t.courseReassessmentTitle,
        maxWidth: SoriMaxWidth.form,
        builder: (context, resolvedPadding) => _buildScrollableState(
          resolvedPadding,
          AppLoading(message: t.courseReassessmentLoading),
        ),
      );
    }
    if (_loadError != null || _segment == null || _definition == null) {
      return SoriStandardFrame(
        appBarTitle: t.courseReassessmentTitle,
        maxWidth: SoriMaxWidth.form,
        builder: (context, resolvedPadding) => _buildScrollableState(
          resolvedPadding,
          AppError(message: t.courseReassessmentLoadError, onRetry: _load),
        ),
      );
    }
    final locale = Localizations.localeOf(context).languageCode;
    final segment = _segment!;
    return SoriStandardPage(
      appBarTitle: t.courseReassessmentTitle,
      maxWidth: SoriMaxWidth.form,
      eyebrow: t.courseReassessmentEyebrow,
      headline: segment.title.pick(locale),
      description: segment.canDo.pick(locale),
      children: [
        _buildProgress(t),
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
              child: Text(_notice!, style: SoriTextTheme.of(context).body),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildProgress(AppL10n t) {
    final projectStage = !_projectReviewComplete
        ? _requiredReviewStep?.order
        : _projectStep?.order;
    final progressLabel = projectStage == null
        ? t.courseReassessmentStep(_definitionIndex + 1, _definitions.length)
        : t.courseReassessmentProjectStep(projectStage, 4);
    final progressValue = projectStage == null
        ? (_definitionIndex + 1) / _definitions.length
        : projectStage / 4;
    return Semantics(
      label: progressLabel,
      child: ExcludeSemantics(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(progressLabel, style: SoriTextTheme.of(context).meta),
            const SizedBox(height: Spacing.xs),
            SoriProgressBar(
              value: progressValue,
              color: SoriActivityColors.speaking,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAssessment(AppL10n t) {
    final definition = _definition!;
    final missing = _missingPrerequisite(definition);
    if (missing != null) {
      return _buildPrerequisite(t, missing);
    }
    if (!_projectReviewComplete && _requiredReviewStep != null) {
      return _buildProjectReview(t);
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
          style: SoriTextTheme.of(context).bodySmall,
        ),
      ],
    );
  }

  Widget _buildProjectReview(AppL10n t) {
    final locale = Localizations.localeOf(context).languageCode;
    final sources = _reviewSourceSnippets;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SoriCard(
          variant: SoriCardVariant.hero,
          accent: SoriActivityColors.review,
          tinted: true,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                t.courseReassessmentProjectReviewTitle,
                style: SoriTextTheme.of(context).h2,
              ),
              const SizedBox(height: Spacing.sm),
              Text(
                t.courseReassessmentProjectReviewBody,
                style: SoriTextTheme.of(context).body,
              ),
            ],
          ),
        ),
        const SizedBox(height: Spacing.lg),
        for (var index = 0; index < sources.length; index++) ...[
          SoriCard(
            key: ValueKey('course-reassessment-review-${sources[index].id}'),
            variant: SoriCardVariant.base,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  t.courseReassessmentSource(index + 1),
                  style: SoriTextTheme.of(context).label,
                ),
                const SizedBox(height: Spacing.xs),
                Text(
                  sources[index].text.pick(locale),
                  style: SoriTextTheme.of(context).body,
                ),
                const SizedBox(height: Spacing.sm),
                Material(
                  type: MaterialType.transparency,
                  child: CheckboxListTile(
                    key: ValueKey(
                      'course-reassessment-reviewed-${sources[index].id}',
                    ),
                    contentPadding: EdgeInsets.zero,
                    controlAffinity: ListTileControlAffinity.leading,
                    title: Text(t.courseReassessmentProjectMarkReviewed),
                    value: _reviewedSourceIds.contains(sources[index].id),
                    onChanged: _submitting
                        ? null
                        : (selected) {
                            setState(() {
                              if (selected == true) {
                                _reviewedSourceIds.add(sources[index].id);
                              } else {
                                _reviewedSourceIds.remove(sources[index].id);
                              }
                            });
                          },
                  ),
                ),
                TextButton(
                  key: ValueKey(
                    'course-reassessment-provenance-${sources[index].id}',
                  ),
                  onPressed: _submitting
                      ? null
                      : () {
                          setState(() {
                            _openedProvenanceSourceIds.add(sources[index].id);
                            if (!_expandedProvenanceSourceIds.add(
                              sources[index].id,
                            )) {
                              _expandedProvenanceSourceIds.remove(
                                sources[index].id,
                              );
                            }
                          });
                        },
                  child: Text(
                    _expandedProvenanceSourceIds.contains(sources[index].id)
                        ? t.courseReassessmentProjectHideProvenance
                        : t.courseReassessmentProjectShowProvenance,
                  ),
                ),
                if (_expandedProvenanceSourceIds.contains(sources[index].id))
                  Text(
                    sources[index].provenance.pick(locale),
                    style: SoriTextTheme.of(context).bodySmall,
                  ),
              ],
            ),
          ),
          if (index + 1 < sources.length) const SizedBox(height: Spacing.md),
        ],
        const SizedBox(height: Spacing.lg),
        SoriButton.filled(
          key: const ValueKey('course-reassessment-submit-project-review'),
          label: _submitting
              ? t.courseReassessmentProjectReviewing
              : t.courseReassessmentProjectCompleteReview,
          fullWidth: true,
          accent: SoriActivityColors.review,
          onTap: _submitting ? null : _submitProjectReview,
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
            style: SoriTextTheme.of(context).label,
          ),
          const SizedBox(height: Spacing.md),
          Text(
            definition.prompt.pick(locale),
            style: SoriTextTheme.of(context).h2,
          ),
          const SizedBox(height: Spacing.md),
          Text(
            t.courseReassessmentRole,
            style: SoriTextTheme.of(context).label,
          ),
          const SizedBox(height: Spacing.xs),
          Text(
            definition.roleInstruction.pick(locale),
            style: SoriTextTheme.of(context).body,
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
        SoriTextField(
          fieldKey: const ValueKey('course-reassessment-answer'),
          controller: _answerController,
          minLines: rubric.requiresStructuredSubmission ? 6 : 3,
          maxLines: 12,
          maxLength: rubric.maxInputCodePoints,
          enabled: !_submitting,
          labelText: t.courseReassessmentAnswer,
          hintText: t.courseReassessmentAnswerHint,
          alignLabelWithHint: true,
          helperText: t.courseReassessmentLength(
            rubric.minInputCodePoints,
            rubric.maxInputCodePoints,
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
            style: SoriTextTheme.of(context).cardTitle,
          ),
          const SizedBox(height: Spacing.sm),
          SoriTextField(
            fieldKey: ValueKey('course-reassessment-slot-$slotId'),
            controller: _slotControllers[slotId],
            minLines: 2,
            maxLines: 4,
            enabled: !_submitting,
            hintText: t.courseReassessmentEvidencePointHint,
          ),
          const SizedBox(height: Spacing.md),
          DropdownButtonFormField<String>(
            key: ValueKey('course-reassessment-source-$slotId'),
            initialValue: _slotSourceIds[slotId],
            isExpanded: true,
            itemHeight: null,
            decoration: InputDecoration(
              labelText: t.courseReassessmentSourceForPoint,
            ),
            items: [
              for (
                var sourceIndex = 0;
                sourceIndex < sources.length;
                sourceIndex++
              )
                DropdownMenuItem(
                  value: sources[sourceIndex].id,
                  child: Text(t.courseReassessmentSource(sourceIndex + 1)),
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
        Text(t.courseReassessmentSources, style: SoriTextTheme.of(context).h3),
        const SizedBox(height: Spacing.sm),
        for (var index = 0; index < sources.length; index++) ...[
          SoriCard(
            variant: SoriCardVariant.compact,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  t.courseReassessmentSource(index + 1),
                  style: SoriTextTheme.of(context).label,
                ),
                const SizedBox(height: Spacing.xs),
                Text(
                  sources[index].text.pick(locale),
                  style: SoriTextTheme.of(context).body,
                ),
                const SizedBox(height: Spacing.xs),
                Text(
                  sources[index].provenance.pick(locale),
                  style: SoriTextTheme.of(context).bodySmall,
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
          style: SoriTextTheme.of(context).h3,
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
                  style: SoriTextTheme.of(context).label,
                ),
                const SizedBox(height: Spacing.xs),
                Text(
                  sources[index].text.pick(locale),
                  style: SoriTextTheme.of(context).body,
                ),
                const SizedBox(height: Spacing.sm),
                Text(
                  t.courseReassessmentRelationship,
                  style: SoriTextTheme.of(context).label,
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
            style: SoriTextTheme.of(context).h3,
          ),
          const SizedBox(height: Spacing.sm),
          Text(
            t.courseReassessmentOralUnavailableBody,
            style: SoriTextTheme.of(context).body,
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
            style: SoriTextTheme.of(context).h3,
          ),
          const SizedBox(height: Spacing.sm),
          Text(
            t.courseReassessmentPrerequisiteBody,
            style: SoriTextTheme.of(context).body,
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
              style: SoriTextTheme.of(context).h1,
            ),
            const SizedBox(height: Spacing.sm),
            Text(
              passed
                  ? t.courseReassessmentPassedBody((result.score * 100).round())
                  : t.courseReassessmentTryAgainBody(
                      (result.score * 100).round(),
                    ),
              textAlign: TextAlign.center,
              style: SoriTextTheme.of(context).body,
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
            style: SoriTextTheme.of(context).h1,
          ),
          const SizedBox(height: Spacing.sm),
          Text(
            t.courseReassessmentCompleteBody,
            textAlign: TextAlign.center,
            style: SoriTextTheme.of(context).body,
          ),
          const SizedBox(height: Spacing.lg),
          SoriButton.filled(
            label: t.courseReassessmentFinish,
            fullWidth: true,
            accent: SoriActivityColors.completion,
            onTap: _finishSegment,
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
