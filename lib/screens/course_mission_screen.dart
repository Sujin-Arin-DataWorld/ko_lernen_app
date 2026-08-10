import 'package:flutter/material.dart';

import '../l10n/generated/app_localizations.dart';
import '../models/course_mission_step_plan.dart';
import '../models/course_mastery.dart';
import '../models/curriculum.dart';
import '../services/course_mastery_service.dart';
import '../services/course_mission_navigation.dart';
import '../services/onboarding_companion_service.dart';
import '../services/course_progress_service.dart';
import '../services/curriculum_catalog.dart';
import '../services/storage_service.dart';
import '../widgets/app_error.dart';
import '../widgets/app_loading.dart';
import '../widgets/sori/button.dart';
import '../widgets/sori/card.dart';
import '../widgets/sori/responsive.dart';
import '../widgets/sori/screen_background.dart';
import '../widgets/sori/tokens.dart';
import 'first_voice_success_screen.dart';
import 'course_mission_path_overview.dart';

/// The course-first entry point. Legacy libraries remain available, but every
/// action here is selected from the active mission's graph links.
class CourseMissionScreen extends StatefulWidget {
  const CourseMissionScreen({super.key, this.courseUnitId});

  final String? courseUnitId;

  @override
  State<CourseMissionScreen> createState() => _CourseMissionScreenState();
}

class _CourseMissionScreenState extends State<CourseMissionScreen> {
  CurriculumCatalog? _catalog;
  CourseMasterySnapshot? _snapshot;
  Map<String, CourseContentState> _conceptStates = const {};
  List<RemediationRecommendation> _reviewQueue = const [];
  Object? _error;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final catalog = await CurriculumCatalog.load();
      var snapshot = await CourseProgressService.shared.refresh();
      if (snapshot.currentCourseUnitId == null) {
        final level =
            snapshot.placementLevel ?? Storage.placementLevelCode ?? 'a1';
        snapshot = await CourseProgressService.shared.initializeForPlacement(
          level,
        );
      }
      final requested = widget.courseUnitId?.trim();
      final unit =
          catalog.courseUnitFor(requested ?? '') ??
          catalog.courseUnitFor(snapshot.currentCourseUnitId!);
      if (unit == null) {
        throw const FormatException('No current course mission exists.');
      }
      final states = await CourseProgressService.shared.conceptStates(
        unit.requiredConceptIds,
      );
      final queue = await CourseProgressService.shared.reviewQueue();
      if (!mounted) return;
      setState(() {
        _catalog = catalog;
        _snapshot = snapshot;
        _conceptStates = states;
        _reviewQueue = queue;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error;
        _loading = false;
      });
    }
  }

  CourseUnit? get _unit {
    final catalog = _catalog;
    if (catalog == null) return null;
    return catalog.courseUnitFor(widget.courseUnitId?.trim() ?? '') ??
        catalog.courseUnitFor(_snapshot?.currentCourseUnitId ?? '');
  }

  bool get _isCurrent => _unit?.id == _snapshot?.currentCourseUnitId;

  Future<void> _openLink(ContentLink link) async {
    final unit = _unit;
    final destination = destinationForCourseLink(link);
    if (unit == null || destination == null) return;
    await Storage.setBrowseLevelCode(unit.level);
    if (!mounted) return;
    await Navigator.of(
      context,
    ).pushNamed(destination.route, arguments: destination.arguments);
    if (!mounted) return;
    await _load();
    if (!mounted) return;

    final snapshot = _snapshot;
    if (snapshot == null ||
        !OnboardingCompanionService.shouldOffer(
          introPreviewSeen: Storage.introPreviewSeen,
          activeCourseUnitId: unit.id,
          activeCourseLevel: unit.level,
          evidence: snapshot.evidence,
        )) {
      return;
    }

    final languageCode = Localizations.localeOf(context).languageCode;
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) =>
            FirstVoiceSuccessScreen(canDo: unit.canDo.pick(languageCode)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);
    if (_loading) {
      return Scaffold(
        appBar: AppBar(title: Text(t.courseMissionTitle)),
        body: const AppLoading(),
      );
    }
    if (_error != null || _unit == null) {
      return Scaffold(
        appBar: AppBar(title: Text(t.courseMissionTitleShort)),
        body: AppError(message: t.courseMissionLoadError, onRetry: _load),
      );
    }

    final unit = _unit!;
    final catalog = _catalog!;
    final lang = Localizations.localeOf(context).languageCode;
    final links = catalog.linksForCourseUnit(unit.id);
    final missionPlan = CourseMissionStepPlan.fromLinks(links);
    final actions = _actionsFor(links);
    final families = catalog.formFamilies
        .where(
          (family) => family.conceptIds.any(unit.requiredConceptIds.contains),
        )
        .toList(growable: false);
    final surfaceIds = <String>{
      for (final family in families) ...family.surfaceFormIds,
      for (final surface in catalog.surfaceForms)
        if (surface.conceptIds.any(unit.requiredConceptIds.contains))
          surface.id,
    };
    final surfaces = surfaceIds
        .map(catalog.surfaceFormFor)
        .whereType<SurfaceForm>()
        .toList(growable: false);

    return Scaffold(
      appBar: AppBar(title: Text(t.courseMissionTitle)),
      body: SoriScreenBackground(
        child: RefreshIndicator(
          onRefresh: _load,
          child: ListView(
            padding: soriClampPadding(
              MediaQuery.sizeOf(context).width,
              base: const EdgeInsets.fromLTRB(16, 12, 16, 48),
            ),
            children: [
              SoriCard(
                variant: SoriCardVariant.hero,
                accent: SoriColors.primary,
                tinted: true,
                eaves: true,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${unit.level.toUpperCase()} · ${_isCurrent ? t.courseMissionNow : t.courseMissionPreviewTag}',
                      style: SoriTextTheme.of(context).label.copyWith(
                        color: SoriColors.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: Spacing.sm),
                    Text(
                      unit.title.pick(lang),
                      style: SoriTextTheme.of(context).display,
                    ),
                    const SizedBox(height: Spacing.sm),
                    Text(
                      unit.canDo.pick(lang),
                      style: SoriTextTheme.of(
                        context,
                      ).body.copyWith(height: 1.5),
                    ),
                    const SizedBox(height: Spacing.lg),
                    if (_isCurrent && actions.isNotEmpty)
                      SoriButton.filled(
                        label: t.courseMissionStartPractice,
                        fullWidth: true,
                        onTap: () => _openLink(actions.first),
                      )
                    else if (!_isCurrent)
                      Text(
                        t.courseMissionPreviewNotice,
                        style: SoriTextTheme.of(context).bodySmall,
                      ),
                  ],
                ),
              ),
              const SizedBox(height: Spacing.xl),
              CourseMissionPathOverview(steps: missionPlan.steps),
              const SizedBox(height: Spacing.lg),
              SoriCard(
                variant: SoriCardVariant.base,
                child: ExpansionTile(
                  title: Text(
                    t.courseMissionDetails,
                    style: SoriTextTheme.of(context).h3,
                  ),
                  tilePadding: EdgeInsets.zero,
                  childrenPadding: const EdgeInsets.only(top: Spacing.sm),
                  children: [
                    _SectionTitle(t.courseSectionToday),
                    const SizedBox(height: Spacing.sm),
                    ...unit.requiredConceptIds.map(
                      (conceptId) => _ConceptRow(
                        concept: catalog.conceptFor(conceptId)!,
                        state:
                            _conceptStates[conceptId] ??
                            CourseContentState.preview,
                        lang: lang,
                      ),
                    ),
                    if (families.isNotEmpty) ...[
                      const SizedBox(height: Spacing.xl),
                      _SectionTitle(t.courseSectionFamilies),
                      const SizedBox(height: Spacing.sm),
                      ...families.map(
                        (family) => _FormFamilyCard(family: family, lang: lang),
                      ),
                    ],
                    if (surfaces.isNotEmpty) ...[
                      const SizedBox(height: Spacing.xl),
                      _SectionTitle(t.courseSectionSurfaces),
                      const SizedBox(height: Spacing.sm),
                      ...surfaces.map(
                        (surface) =>
                            _SurfaceFormCard(surface: surface, lang: lang),
                      ),
                    ],
                    if (_reviewQueue.isNotEmpty) ...[
                      const SizedBox(height: Spacing.xl),
                      _SectionTitle(t.courseSectionRepair),
                      const SizedBox(height: Spacing.sm),
                      ..._reviewQueue.map(
                        (item) => _ReviewCard(
                          item: item,
                          catalog: catalog,
                          lang: lang,
                          onTap: item.contentLink == null
                              ? null
                              : () => _openLink(item.contentLink!),
                        ),
                      ),
                    ],
                    if (actions.isNotEmpty) ...[
                      const SizedBox(height: Spacing.xl),
                      _SectionTitle(t.courseSectionPractice),
                      const SizedBox(height: Spacing.sm),
                      ...actions.map(
                        (link) => _PracticeCard(
                          link: link,
                          onTap: () => _openLink(link),
                          label: _practiceLabel(link.contentKind, t),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<ContentLink> _actionsFor(List<ContentLink> links) {
    final byKind = <CurriculumContentKind, ContentLink>{};
    final scenarios = <String, ContentLink>{};
    final sorted = links.toList()
      ..sort((left, right) {
        final role = _roleWeight(left.role).compareTo(_roleWeight(right.role));
        return role != 0 ? role : left.id.compareTo(right.id);
      });
    for (final link in sorted) {
      if (link.contentKind == CurriculumContentKind.scenario) {
        scenarios.putIfAbsent(link.contentId, () => link);
        continue;
      }
      byKind.putIfAbsent(link.contentKind, () => link);
    }
    final values = <ContentLink>[...byKind.values, ...scenarios.values]
      ..sort(
        (left, right) => _actionWeight(
          left.contentKind,
        ).compareTo(_actionWeight(right.contentKind)),
      );
    return values;
  }

  int _roleWeight(ContentLinkRole role) => switch (role) {
    ContentLinkRole.assess => 0,
    ContentLinkRole.practice => 1,
    ContentLinkRole.introduce => 2,
    ContentLinkRole.review => 3,
  };

  int _actionWeight(CurriculumContentKind kind) => switch (kind) {
    CurriculumContentKind.vocab => 0,
    CurriculumContentKind.grammar => 1,
    CurriculumContentKind.cloze => 2,
    CurriculumContentKind.satz => 3,
    CurriculumContentKind.scenario => 4,
    CurriculumContentKind.smalltalk => 5,
  };

  String _practiceLabel(CurriculumContentKind kind, AppL10n t) =>
      switch (kind) {
        CurriculumContentKind.vocab => t.coursePracticeVocab,
        CurriculumContentKind.grammar => t.coursePracticeGrammar,
        CurriculumContentKind.cloze => t.coursePracticeCloze,
        CurriculumContentKind.satz => t.coursePracticeSatz,
        CurriculumContentKind.scenario => t.coursePracticeScenario,
        CurriculumContentKind.smalltalk => t.coursePracticeSmalltalk,
      };
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);
  final String text;

  @override
  Widget build(BuildContext context) =>
      Text(text, style: SoriTextTheme.of(context).h3);
}

class _ConceptRow extends StatelessWidget {
  const _ConceptRow({
    required this.concept,
    required this.state,
    required this.lang,
  });

  final Concept concept;
  final CourseContentState state;
  final String lang;

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);
    final (icon, color, status) = switch (state) {
      CourseContentState.preview => (
        Icons.visibility_outlined,
        SoriColors.info,
        t.courseStatePreview,
      ),
      CourseContentState.introduced => (
        Icons.menu_book_outlined,
        SoriColors.primary,
        t.courseStateIntroduced,
      ),
      CourseContentState.practiceAvailable => (
        Icons.edit_outlined,
        SoriColors.warning,
        t.courseStatePractice,
      ),
      CourseContentState.checkpointPassed => (
        Icons.check_circle_outline,
        SoriColors.success,
        t.courseStateCheckpointPassed,
      ),
      CourseContentState.reviewDue => (
        Icons.refresh_rounded,
        SoriColors.danger,
        t.courseStateReviewDue,
      ),
      CourseContentState.stableMastery => (
        Icons.workspace_premium_outlined,
        SoriColors.primary,
        t.courseStateStable,
      ),
    };
    return Padding(
      padding: const EdgeInsets.only(bottom: Spacing.sm),
      child: SoriCard(
        variant: SoriCardVariant.compact,
        accent: color,
        child: Row(
          children: [
            Icon(icon, color: color),
            const SizedBox(width: Spacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    concept.title.pick(lang),
                    style: SoriTextTheme.of(context).label,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    concept.explanation.pick(lang),
                    style: SoriTextTheme.of(context).bodySmall,
                  ),
                ],
              ),
            ),
            const SizedBox(width: Spacing.sm),
            Text(
              status,
              style: SoriTextTheme.of(context).caption.copyWith(color: color),
            ),
          ],
        ),
      ),
    );
  }
}

class _FormFamilyCard extends StatelessWidget {
  const _FormFamilyCard({required this.family, required this.lang});
  final FormFamily family;
  final String lang;

  String _axisLabel(AppL10n t, String axis) => switch (axis) {
    'batchim' => t.courseAxisBatchim,
    'sentence_role' => t.courseAxisSentenceRole,
    'relationship_context' => t.courseAxisRelationship,
    'setting' => t.courseAxisSetting,
    _ => axis,
  };

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: Spacing.sm),
      child: SoriCard(
        variant: SoriCardVariant.base,
        accent: SoriColors.hangul,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(family.title.pick(lang), style: SoriTextTheme.of(context).h3),
            if (family.changeAxes.isNotEmpty) ...[
              const SizedBox(height: Spacing.xs),
              Text(
                family.changeAxes
                    .map((axis) => _axisLabel(t, axis))
                    .join(' · '),
                style: SoriTextTheme.of(context).bodySmall,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _SurfaceFormCard extends StatelessWidget {
  const _SurfaceFormCard({required this.surface, required this.lang});
  final SurfaceForm surface;
  final String lang;

  String _usageLabel(AppL10n t, String usage) => switch (usage) {
    'official' => t.courseUsageOfficial,
    'polite' => t.courseUsageEverydayPolite,
    'close_relationship_only' => t.courseUsageCloseOnly,
    'official_or_service' => t.courseUsageOfficialOrService,
    'everyday_polite' => t.courseUsageEverydayPolite,
    'friendly_polite' => t.courseUsageFriendlyPolite,
    'sentence_role' => t.courseAxisSentenceRole,
    'service_request' => t.courseUsageServiceRequest,
    'payment_notice' => t.courseUsagePaymentNotice,
    _ => usage,
  };

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: Spacing.sm),
      child: SoriCard(
        variant: SoriCardVariant.compact,
        accent: SoriColors.primary,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(surface.ko, style: SoriTextTheme.of(context).h3),
            const SizedBox(height: Spacing.xs),
            Text(
              surface.meaning.pick(lang),
              style: SoriTextTheme.of(context).body,
            ),
            if (surface.usageContext.trim().isNotEmpty) ...[
              const SizedBox(height: 2),
              Text(
                _usageLabel(t, surface.usageContext),
                style: SoriTextTheme.of(context).bodySmall,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ReviewCard extends StatelessWidget {
  const _ReviewCard({
    required this.item,
    required this.catalog,
    required this.lang,
    required this.onTap,
  });
  final RemediationRecommendation item;
  final CurriculumCatalog catalog;
  final String lang;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final concept = catalog.conceptFor(item.conceptId);
    return Padding(
      padding: const EdgeInsets.only(bottom: Spacing.sm),
      child: SoriCard(
        variant: SoriCardVariant.compact,
        accent: SoriColors.danger,
        onTap: onTap,
        child: Row(
          children: [
            const Icon(Icons.refresh_rounded, color: SoriColors.danger),
            const SizedBox(width: Spacing.md),
            Expanded(
              child: Text(
                concept?.title.pick(lang) ?? item.conceptId,
                style: SoriTextTheme.of(context).label,
              ),
            ),
            if (onTap != null) const Icon(Icons.arrow_forward_rounded),
          ],
        ),
      ),
    );
  }
}

class _PracticeCard extends StatelessWidget {
  const _PracticeCard({
    required this.link,
    required this.onTap,
    required this.label,
  });
  final ContentLink link;
  final VoidCallback onTap;
  final String label;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: Spacing.sm),
    child: SoriCard(
      variant: SoriCardVariant.compact,
      accent: link.role == ContentLinkRole.assess
          ? SoriColors.success
          : SoriColors.primary,
      onTap: onTap,
      child: Row(
        children: [
          Icon(_iconFor(link.contentKind), color: SoriColors.primary),
          const SizedBox(width: Spacing.md),
          Expanded(child: Text(label, style: SoriTextTheme.of(context).label)),
          const Icon(Icons.arrow_forward_rounded),
        ],
      ),
    ),
  );

  IconData _iconFor(CurriculumContentKind kind) => switch (kind) {
    CurriculumContentKind.vocab => Icons.style_outlined,
    CurriculumContentKind.grammar => Icons.account_tree_outlined,
    CurriculumContentKind.smalltalk => Icons.forum_outlined,
    CurriculumContentKind.cloze => Icons.short_text_rounded,
    CurriculumContentKind.satz => Icons.reorder_rounded,
    CurriculumContentKind.scenario => Icons.record_voice_over_outlined,
  };
}
