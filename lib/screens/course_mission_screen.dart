import 'package:flutter/material.dart';

import '../l10n/generated/app_localizations.dart';
import '../models/course_mission_brief.dart';
import '../models/course_mastery.dart';
import '../models/curriculum.dart';
import '../models/scenario.dart';
import '../motion/transitions.dart';
import '../services/analytics_service.dart';
import '../services/course_mission_navigation.dart';
import '../services/onboarding_companion_service.dart';
import '../services/course_progress_service.dart';
import '../services/curriculum_catalog.dart';
import '../services/scenario_loader.dart';
import '../services/storage_service.dart';
import '../widgets/app_error.dart';
import '../widgets/app_loading.dart';
import '../widgets/sori/course_mission_brief.dart';
import '../widgets/sori/sheet.dart';
import '../widgets/sori/standard_page.dart';
import '../widgets/sori/toast.dart';
import '../widgets/sori/tokens.dart';
import '../widgets/sori/window_class.dart';
import 'first_voice_success_screen.dart';

/// The course-first entry point. Legacy libraries remain available, but every
/// action here is selected from the active mission's graph links.
class CourseMissionScreen extends StatefulWidget {
  const CourseMissionScreen({
    super.key,
    this.courseUnitId,
    this.destinationResolver,
  }) : previewBrief = null,
       previewOpenLink = null;

  const CourseMissionScreen.preview({
    super.key,
    required CourseMissionBrief brief,
    required CourseMissionBriefOpener openLink,
  }) : courseUnitId = null,
       destinationResolver = null,
       previewBrief = brief,
       previewOpenLink = openLink;

  final String? courseUnitId;
  final Future<CourseMissionDestination?> Function(ContentLink link)?
  destinationResolver;
  final CourseMissionBrief? previewBrief;
  final CourseMissionBriefOpener? previewOpenLink;

  @override
  State<CourseMissionScreen> createState() => _CourseMissionScreenState();
}

class _CourseMissionScreenState extends State<CourseMissionScreen> {
  CurriculumCatalog? _catalog;
  CourseMasterySnapshot? _snapshot;
  List<Scenario> _scenarios = const [];
  Object? _error;
  bool _loading = true;
  bool _learningStartRecorded = false;

  @override
  void initState() {
    super.initState();
    if (widget.previewBrief == null) {
      _load();
    } else {
      _loading = false;
    }
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final catalog = await CurriculumCatalog.load();
      final scenarios = await ScenarioLoader.load();
      final snapshot = await CourseProgressService.shared.readForDisplay();
      final requested = widget.courseUnitId?.trim();
      final unit =
          catalog.courseUnitFor(requested ?? '') ??
          catalog.courseUnitFor(snapshot?.currentCourseUnitId ?? '');
      if (unit == null) {
        throw const FormatException('No current course mission exists.');
      }
      if (!mounted) return;
      if (!_learningStartRecorded) {
        _learningStartRecorded = true;
        Analytics.lessonStarted(
          lessonType: 'course',
          lessonId: unit.id,
          level: unit.level,
        );
      }
      setState(() {
        _catalog = catalog;
        _snapshot = snapshot ?? const CourseMasterySnapshot.empty();
        _scenarios = scenarios;
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
    if (unit == null) {
      return;
    }
    CourseMissionDestination? destination;
    try {
      destination =
          await (widget.destinationResolver ?? directDestinationForCourseLink)(
            link,
          );
    } catch (_) {
      destination = null;
    }
    if (!mounted) return;
    if (destination == null) {
      soriToast(context, AppL10n.of(context).loadErrorTryAgain);
      return;
    }
    final evidenceIdsBefore =
        _snapshot?.evidence.map((item) => item.id).toSet() ?? const <String>{};
    if (!mounted) return;
    await Navigator.of(
      context,
    ).pushNamed(destination.route, arguments: destination.arguments);
    if (!mounted) return;
    await _load();
    if (!mounted) return;

    final snapshot = _snapshot;
    if (snapshot == null ||
        !OnboardingCompanionService.shouldOfferAfterAttempt(
          introPreviewSeen: Storage.introPreviewSeen,
          activeCourseUnitId: unit.id,
          activeCourseLevel: unit.level,
          evidenceIdsBefore: evidenceIdsBefore,
          evidenceAfter: snapshot.evidence,
          contentLinks: _catalog?.contentLinks ?? const <ContentLink>[],
        )) {
      return;
    }

    final languageCode = Localizations.localeOf(context).languageCode;
    await Navigator.of(context).push<void>(
      SoriTransitions.page<void>(
        (_) => FirstVoiceSuccessScreen(canDo: unit.canDo.pick(languageCode)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);
    if (widget.previewBrief case final preview?) {
      return _buildBriefFrame(t, preview, widget.previewOpenLink!);
    }
    if (_loading) {
      return SoriStandardFrame(
        appBarTitle: t.courseMissionTitle,
        maxWidth: SoriMaxWidth.prose,
        builder: (context, resolvedPadding) => const AppLoading(),
      );
    }
    if (_error != null || _unit == null) {
      return SoriStandardFrame(
        appBarTitle: t.courseMissionTitleShort,
        maxWidth: SoriMaxWidth.prose,
        builder: (context, resolvedPadding) =>
            AppError(message: t.courseMissionLoadError, onRetry: _load),
      );
    }

    final unit = _unit!;
    final catalog = _catalog!;
    final links = catalog.linksForCourseUnit(unit.id);
    final brief = CourseMissionBrief.from(
      unit: unit,
      links: links,
      scenarios: _scenarios,
      isCurrent: _isCurrent,
      snapshot: _snapshot ?? const CourseMasterySnapshot.empty(),
    );
    return SoriStandardFrame(
      appBarTitle: t.courseMissionTitle,
      maxWidth: SoriMaxWidth.prose,
      padding: const EdgeInsets.fromLTRB(
        Spacing.lg,
        Spacing.md,
        Spacing.lg,
        Spacing.xxxl,
      ),
      builder: (context, resolvedPadding) => RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: resolvedPadding,
          children: [
            CourseMissionBriefView(
              brief: brief,
              openLink: _openLink,
              onExplain: () => _showWhy(unit),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBriefFrame(
    AppL10n t,
    CourseMissionBrief brief,
    CourseMissionBriefOpener openLink,
  ) {
    return SoriStandardFrame(
      appBarTitle: t.courseMissionTitle,
      maxWidth: SoriMaxWidth.prose,
      padding: const EdgeInsets.fromLTRB(
        Spacing.lg,
        Spacing.md,
        Spacing.lg,
        Spacing.xxxl,
      ),
      builder: (context, resolvedPadding) => ListView(
        padding: resolvedPadding,
        children: [
          CourseMissionBriefView(
            brief: brief,
            openLink: openLink,
            onExplain: () => _showWhy(brief.unit),
          ),
        ],
      ),
    );
  }

  void _showWhy(CourseUnit unit) {
    final lang = Localizations.localeOf(context).languageCode;
    showSoriSheet<void>(
      context: context,
      builder: (sheetContext) => Text(
        unit.canDo.pick(lang),
        style: SoriTextTheme.of(sheetContext).body,
      ),
    );
  }
}
