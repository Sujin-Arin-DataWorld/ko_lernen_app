import '../services/learning_journey.dart';
import '../services/course_attempt_companion.dart';
import 'package:flutter/material.dart';

import '../l10n/generated/app_localizations.dart';
import '../models/course_mission_brief.dart';
import '../models/course_mastery.dart';
import '../models/curriculum.dart';
import '../models/scenario.dart';
import '../services/course_mission_navigation.dart';
import '../services/course_progress_service.dart';
import '../services/curriculum_catalog.dart';
import '../services/scenario_loader.dart';
import '../widgets/app_error.dart';
import '../widgets/app_loading.dart';
import '../widgets/sori/course_mission_brief.dart';
import '../widgets/sori/c_gallery/c_materials.dart';
import '../widgets/sori/c_gallery/c_objects.dart';
import '../widgets/sori/sheet.dart';
import 'sori_stage/c_stage_chrome.dart';
import '../widgets/sori/toast.dart';
import '../widgets/sori/tokens.dart';

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
    final journey = LearningJourneyObserver.forContext(context)?.active;
    if (journey != null) {
      journey.afterReturn.putIfAbsent(
        unit.id,
        () =>
            (originContext) => CourseAttemptCompanion.offer(
              originContext,
              unit: unit,
              evidenceIdsBefore: evidenceIdsBefore,
            ),
      );
    }
    await Navigator.of(
      context,
    ).pushNamed(destination.route, arguments: destination.arguments);
    if (!mounted) return;
    await _load();
    if (!mounted) return;

    if (journey != null) {
      return;
    }
    await CourseAttemptCompanion.offer(
      context,
      unit: unit,
      evidenceIdsBefore: evidenceIdsBefore,
      after: _snapshot,
      links: _catalog?.contentLinks,
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);
    if (widget.previewBrief case final preview?) {
      return _buildBriefFrame(t, preview, widget.previewOpenLink!);
    }
    if (_loading) {
      return _cFrame(t, const Center(child: AppLoading()), scrollable: false);
    }
    if (_error != null || _unit == null) {
      return _cFrame(
        t,
        AppError(message: t.courseMissionLoadError, onRetry: _load),
        scrollable: false,
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
    return _cFrame(
      t,
      CourseMissionBriefView(
        brief: brief,
        openLink: _openLink,
        onExplain: () => _showWhy(unit),
      ),
      onRefresh: _load,
    );
  }

  Widget _cFrame(
    AppL10n t,
    Widget child, {
    Future<void> Function()? onRefresh,
    bool scrollable = true,
  }) {
    final body = Padding(
      padding: EdgeInsets.fromLTRB(
        12,
        0,
        12,
        24 + MediaQuery.paddingOf(context).bottom,
      ),
      child: CPaperPanel(
        key: const ValueKey('c-course-mission-panel'),
        radius: 16,
        padding: const EdgeInsets.all(16),
        child: child,
      ),
    );
    Widget content = scrollable
        ? ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.zero,
            children: [body],
          )
        : Center(child: body);
    if (onRefresh != null) {
      content = RefreshIndicator(onRefresh: onRefresh, child: content);
    }
    return Scaffold(
      backgroundColor: CPalette.jade,
      body: CStageBackground(
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 4),
                child: CStageHeader(
                  title: t.courseMissionTitle,
                  artwork: const CObjectArt(CObject.book),
                ),
              ),
              Expanded(child: content),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBriefFrame(
    AppL10n t,
    CourseMissionBrief brief,
    CourseMissionBriefOpener openLink,
  ) {
    return _cFrame(
      t,
      CourseMissionBriefView(
        brief: brief,
        openLink: openLink,
        onExplain: () => _showWhy(brief.unit),
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
