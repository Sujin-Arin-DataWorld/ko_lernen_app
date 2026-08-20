import 'dart:async';

import 'package:flutter/material.dart';

import '../data/quest_catalog.dart';
import '../l10n/generated/app_localizations.dart';
import '../models/hanok_stage.dart';
import '../models/pack_progress.dart';
import '../models/vocab_pack.dart';
import '../models/course_mastery.dart';
import '../models/curriculum.dart';
import '../models/learner_level.dart';
import '../services/course_progress_service.dart';
import '../services/curriculum_catalog.dart';
import '../services/hanok_stage_service.dart';
import '../services/hanok_structure_projection_service.dart';
import '../services/pack_access.dart';
import '../services/pack_progress_service.dart';
import '../services/storage_service.dart';
import '../services/vocab_pack_service.dart';
import '../widgets/app_loading.dart';
import '../widgets/sori/decoration_layer.dart';
import '../widgets/sori/cultural_help.dart';
import '../widgets/sori/button.dart';
import '../widgets/sori/hanok_tokens.dart';
import '../widgets/sori/level_chip.dart';
import '../widgets/sori/card.dart';
import '../widgets/sori/course_progress_evidence_note.dart';
import '../widgets/sori/path_trail.dart';
import '../widgets/sori/progress.dart';
import '../widgets/sori/screen_coach.dart';
import '../widgets/sori/spotlight_coach.dart';
import '../widgets/sori/standard_page.dart';
import '../widgets/sori/tokens.dart';
import '../widgets/sori/window_class.dart';

/// 경로가 렌더할 단일 CEFR 레벨을 정한다. 학습자의 온보딩 선택
/// ([Storage.userLevelCode], 소문자 'a1'..'c2')이 진실의 출처이며, 온보딩 전
/// (null·빈값·알 수 없는 값)에는 A1으로 폴백해 경로가 절대 비지 않게 한다.
/// 반환은 팩/표시용 대문자 코드('A1'..'C2').
String pathVisibleLevel(String? userLevelCode) {
  return (LearnerLevel.fromCode(userLevelCode) ?? LearnerLevel.a1).display;
}

String pathLegacyBrowseVisibleLevel({
  required String? browseLevelCode,
  required String? placementLevelCode,
  required String? legacyUserLevelCode,
}) => pathVisibleLevel(
  browseLevelCode ?? placementLevelCode ?? legacyUserLevelCode,
);

/// The sequential course follows its canonical snapshot, while the legacy
/// pack browser may keep the learner's independently selected browse level.
String pathCourseVisibleLevel({
  required CourseMasterySnapshot snapshot,
  required Iterable<CourseUnit> courseUnits,
  required String fallbackBrowseLevel,
}) {
  final currentId = snapshot.currentCourseUnitId;
  if (currentId != null) {
    for (final unit in courseUnits) {
      if (unit.id == currentId) return pathVisibleLevel(unit.level);
    }
  }
  final placement = snapshot.placementLevel;
  if (placement != null && placement.trim().isNotEmpty) {
    return pathVisibleLevel(placement);
  }
  return pathVisibleLevel(fallbackBrowseLevel);
}

/// **Lernpfad (학습 경로)** — Duolingo식 진척 시각화.
///
/// "내가 어디 있고, 다음 한 걸음이 무엇인지"를 한 화면에 보여준다:
///   1. 상단: 한옥 12단계 (현재 단계 이미지 + 전체 클리어 진행률)
///   2. 본문: 레벨(A1~C2)별 단어팩 노드 — 완료(체크)/현재("Jetzt")/잠금(자물쇠).
///
/// 데이터: [HanokStageService.currentStage] + [PackProgressService.loadLevelView]
/// (둘 다 기존 서비스 — 새 저장소 없음). 노드 탭 → `/vocab/pack`.
///
/// **레벨 스코프**: 경로 본문(코스 미션 + 단어팩 노드)은 학습자가 온보딩에서
/// 고른 **한 레벨만** 보여준다([pathVisibleLevel]). 전체 A1~C2 나열은 초보자에게
/// 압도적이라 선택 레벨로 좁힌다. 상단 한옥 헤더의 진행도는 "집 전체"를 뜻하므로
/// 여전히 전 레벨 합산.
class LearningPathPreviewData {
  const LearningPathPreviewData({
    required this.courseUnits,
    required this.snapshot,
    this.selectedLevel = 'A1',
    this.stage = HanokStage.empty,
  });

  final List<CourseUnit> courseUnits;
  final CourseMasterySnapshot snapshot;
  final String selectedLevel;
  final HanokStage stage;
}

class LearningPathScreen extends StatefulWidget {
  const LearningPathScreen({super.key}) : previewData = null;

  /// Renders the production path from explicit fixture state without reading
  /// or initializing persisted course/pack progress.
  LearningPathScreen.preview({
    super.key,
    required List<CourseUnit> courseUnits,
    required CourseMasterySnapshot snapshot,
    String selectedLevel = 'A1',
    HanokStage stage = HanokStage.empty,
  }) : previewData = LearningPathPreviewData(
         courseUnits: courseUnits,
         snapshot: snapshot,
         selectedLevel: selectedLevel,
         stage: stage,
       );

  final LearningPathPreviewData? previewData;

  @override
  State<LearningPathScreen> createState() => _LearningPathScreenState();
}

class _LevelGroup {
  final String level;
  final List<({VocabPack pack, PackProgress progress})> packs;
  const _LevelGroup(this.level, this.packs);
}

class _LearningPathScreenState extends State<LearningPathScreen>
    with ScreenCoachMixin<LearningPathScreen> {
  bool _loading = true;
  HanokStage _stage = HanokStage.empty;
  final List<_LevelGroup> _groups = [];
  int _clearedTotal = 0;
  int _packTotal = 0;
  String? _nowPackId; // 첫 미완 + 잠금해제 팩 = "지금 할 것"
  String _selectedLevel = 'A1'; // 렌더할 단일 레벨 (온보딩 선택, 대문자)
  String _courseLevel = 'A1';
  List<CourseUnit> _courseUnits = const [];
  CourseMasterySnapshot? _courseSnapshot;
  bool _showLegacyPractice = false;

  static final List<String> _levels = List.unmodifiable(
    LearnerLevel.values.map((level) => level.display),
  );

  // ── 코치마크 타겟 ──
  final GlobalKey _nowNodeKey = GlobalKey();

  // ── §6.2-① 자동 스크롤 ──
  /// 홈 미리보기가 넘긴 스크롤 타깃 팩 id (`/path` route arguments).
  String? _focusPackId;
  final GlobalKey _focusNodeKey = GlobalKey();
  bool _autoScrolled = false;

  @override
  String get coachId => 'learningPath';

  @override
  bool get coachReady => !_loading && _groups.isNotEmpty;

  @override
  List<SpotlightStep> buildCoachSteps(BuildContext context) {
    final t = AppL10n.of(context);
    return [
      SpotlightStep(
        targetKey: _nowNodeKey,
        title: t.coachLearningPathTitle,
        body: t.coachLearningPathBody,
        icon: Icons.play_circle_outline_rounded,
      ),
    ];
  }

  @override
  void initState() {
    super.initState();
    final preview = widget.previewData;
    if (preview != null) {
      _applyPreview(preview);
    } else {
      _load();
      scheduleCoach();
    }
  }

  void _applyPreview(LearningPathPreviewData preview) {
    _stage = preview.stage;
    _selectedLevel = pathVisibleLevel(preview.selectedLevel);
    _courseUnits = List<CourseUnit>.unmodifiable(preview.courseUnits);
    _courseSnapshot = preview.snapshot;
    _courseLevel = pathCourseVisibleLevel(
      snapshot: preview.snapshot,
      courseUnits: preview.courseUnits,
      fallbackBrowseLevel: _selectedLevel,
    );
    _loading = false;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // 홈 미리보기(PathPreviewRow §10.2)가 넘긴 노드 id — 1회만 채택.
    final args = ModalRoute.of(context)?.settings.arguments;
    if (_focusPackId == null && args is String) {
      _focusPackId = args;
    }
  }

  /// §6.2-①: 진입(및 점프 버튼) 시 현재 — 또는 홈이 지정한 — 노드로 스크롤.
  /// ListView가 children 전량을 즉시 빌드하므로 ensureVisible이 안전하다.
  void _autoScrollToTarget({bool force = false}) {
    if (!mounted || (_autoScrolled && !force)) {
      return;
    }
    final focusCtx = _focusPackId != null && _focusPackId != _nowPackId
        ? _focusNodeKey.currentContext
        : null;
    final ctx = focusCtx ?? _nowNodeKey.currentContext;
    if (ctx == null) {
      return; // 타깃 없음(예: 전부 클리어) — 상단 유지.
    }
    _autoScrolled = true;
    final reduce = SoriMotion.reduceMotion(context);
    Scrollable.ensureVisible(
      ctx,
      alignment: 0.35,
      duration: reduce ? Duration.zero : const Duration(milliseconds: 450),
      curve: Curves.easeOutCubic,
    );
  }

  Future<void> _load() async {
    final preview = widget.previewData;
    if (preview != null) {
      if (mounted) {
        setState(() => _applyPreview(preview));
      }
      return;
    }
    final stage =
        (await HanokStructureProjectionService.loadCurrent()).structureStage;
    final selectedLevel = pathLegacyBrowseVisibleLevel(
      browseLevelCode: Storage.browseLevelCode,
      placementLevelCode: Storage.placementLevelCode,
      legacyUserLevelCode: Storage.userLevelCode,
    );
    final groups = <_LevelGroup>[];
    int cleared = 0;
    int total = 0;
    // 헤더의 "집 전체" 진행도는 전 레벨 합산 — 팩 뷰는 전부 로드한다.
    for (final lv in _levels) {
      final view = await PackProgressService.loadLevelView(lv);
      groups.add(_LevelGroup(lv, view));
      for (final e in view) {
        total++;
        if (e.progress.status == PackStatus.cleared) {
          cleared++;
        }
      }
    }
    // "Jetzt" 노드는 렌더되는(선택한) 레벨 안에서만 고른다 — 낮은 레벨의 미완
    // 팩이 선택 레벨 뷰에서 하이라이트/자동스크롤을 훔치지 않도록.
    String? now;
    for (final g in groups) {
      if (g.level != selectedLevel) {
        continue;
      }
      for (final e in g.packs) {
        if (e.progress.status != PackStatus.cleared &&
            e.progress.status != PackStatus.locked) {
          now = e.pack.id;
          break;
        }
      }
      break;
    }
    CurriculumCatalog? courseCatalog;
    CourseMasterySnapshot? courseSnapshot;
    try {
      courseCatalog = await CurriculumCatalog.load();
      courseSnapshot = await CourseProgressService.shared.readForDisplay();
    } catch (_) {
      // Existing pack path remains usable if a local curriculum asset is
      // invalid; the mission screen will surface the actionable error.
    }
    if (!mounted) {
      return;
    }
    final courseUnits = List<CourseUnit>.unmodifiable(
      courseCatalog?.courseUnits ?? const <CourseUnit>[],
    );
    final courseLevel = courseSnapshot == null
        ? selectedLevel
        : pathCourseVisibleLevel(
            snapshot: courseSnapshot,
            courseUnits: courseUnits,
            fallbackBrowseLevel: selectedLevel,
          );
    setState(() {
      _stage = stage;
      _groups
        ..clear()
        ..addAll(groups);
      _clearedTotal = cleared;
      _packTotal = total;
      _nowPackId = now;
      _selectedLevel = selectedLevel;
      _courseLevel = courseLevel;
      _courseUnits = courseUnits;
      _courseSnapshot = courseSnapshot;
      _loading = false;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => _autoScrollToTarget());
  }

  Future<void> _openPack(VocabPack pack, PackStatus status) async {
    final t = AppL10n.of(context);
    if (status == PackStatus.locked) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(t.pathLockedHint)));
      return;
    }
    // Premium-Gate 단일화 — ensurePackAccess (A1 frei, A2/B1/B2 Abo).
    final ok = await ensurePackAccess(context, level: pack.level);
    if (!ok || !mounted) return;
    await Navigator.pushNamed(context, '/vocab/pack', arguments: pack.id);
    if (mounted) {
      await _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);
    return SoriStandardFrame(
      appBarTitle: t.pathTitle,
      maxWidth: SoriMaxWidth.hub,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 48),
      actions: [
        // §6.2-①: 현재 노드로 점프 (자동 스크롤과 병행).
        IconButton(
          tooltip: t.pathJumpToNow,
          icon: const Icon(Icons.my_location_rounded),
          onPressed: () => _autoScrollToTarget(force: true),
        ),
        const SizedBox(width: Spacing.xs),
      ],
      builder: (context, resolvedPadding) => _loading
          ? const AppLoading()
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: resolvedPadding,
                children: [
                  if (_courseUnits.isNotEmpty && _courseSnapshot != null) ...[
                    _CourseMissionPath(
                      courseUnits: _courseUnits,
                      snapshot: _courseSnapshot!,
                      lang: Localizations.localeOf(context).languageCode,
                      filterLevel:
                          (LearnerLevel.fromCode(_courseLevel) ??
                                  LearnerLevel.a1)
                              .code,
                      onTapUnit: (unit) async {
                        await Navigator.pushNamed(
                          context,
                          '/course/mission',
                          arguments: unit.id,
                        );
                        if (mounted) await _load();
                      },
                    ),
                    const SizedBox(height: Spacing.xl),
                  ],
                  SoriButton.outlined(
                    key: const ValueKey('path-legacy-practice-toggle'),
                    label: _showLegacyPractice
                        ? t.pathHideMorePractice
                        : t.pathShowMorePractice,
                    trailingIcon: _showLegacyPractice
                        ? Icons.expand_less_rounded
                        : Icons.expand_more_rounded,
                    fullWidth: true,
                    onTap: () => setState(
                      () => _showLegacyPractice = !_showLegacyPractice,
                    ),
                  ),
                  if (_showLegacyPractice)
                    KeyedSubtree(
                      key: const ValueKey('path-legacy-practice-content'),
                      child: Column(
                        children: [
                          const SizedBox(height: Spacing.lg),
                          _HanokHeader(
                            stage: _stage,
                            cleared: _clearedTotal,
                            total: _packTotal,
                          ),
                          const SizedBox(height: Spacing.xl),
                          // 선택한 레벨만 렌더 — 전체 A1~C2 나열 대신.
                          for (final g in _groups)
                            if (g.level == _selectedLevel)
                              ..._levelSection(t, g),
                        ],
                      ),
                    ),
                ],
              ),
            ),
    );
  }

  List<Widget> _levelSection(AppL10n t, _LevelGroup g) {
    final s = SoriSurfaces.of(context);
    final lang = Localizations.localeOf(context).languageCode;
    final cleared = g.packs
        .where((e) => e.progress.status == PackStatus.cleared)
        .length;
    return [
      Padding(
        padding: const EdgeInsets.only(top: Spacing.sm, bottom: Spacing.sm),
        // §6.2-②: 레벨 챕터 헤더 — 사계 단청 팔레트로 장(章) 리듬.
        child: Row(
          children: [
            SoriLevelChip(code: g.level),
            const SizedBox(width: Spacing.sm),
            Expanded(
              child: Container(
                height: 1.5,
                decoration: BoxDecoration(
                  color: HanokLevelPalette.of(g.level).withValues(alpha: 0.28),
                  borderRadius: BorderRadius.circular(1),
                ),
              ),
            ),
            const SizedBox(width: Spacing.sm),
            Text(
              t.pathLevelPacks(cleared, g.packs.length),
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: s.textMuted,
              ),
            ),
          ],
        ),
      ),
      // 지그재그 경로 — 팩을 하나도 빠뜨리지 않고 전부 노드로 만든다.
      // (접거나 "+N개 더"로 숨기지 않음 → 모든 팩이 항상 탭 가능)
      SoriPathTrail(
        stops: [
          for (final e in g.packs)
            SoriPathStop(
              id: e.pack.id,
              label: VocabPackService.displayLabel(e.pack.id, lang: lang),
              status: e.progress.status,
              fraction: e.progress.progressFraction,
              isNow: e.pack.id == _nowPackId,
              nodeKey: e.pack.id == _nowPackId
                  ? _nowNodeKey
                  : (e.pack.id == _focusPackId ? _focusNodeKey : null),
              onTap: () => _openPack(e.pack, e.progress.status),
            ),
        ],
      ),
      const SizedBox(height: Spacing.lg),
    ];
  }
}

/// Sequential missions sit above the older pack path. Future missions are
/// intentionally previewable, but only the active one can collect progress.
class _CourseMissionPath extends StatelessWidget {
  const _CourseMissionPath({
    required this.courseUnits,
    required this.snapshot,
    required this.lang,
    required this.filterLevel,
    required this.onTapUnit,
  });

  final List<CourseUnit> courseUnits;
  final CourseMasterySnapshot snapshot;
  final String lang;

  /// 소문자 CEFR 코드('a1'..'c2') — 이 레벨의 미션만 렌더한다.
  final String filterLevel;
  final ValueChanged<CourseUnit> onTapUnit;

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);
    final grouped = <String, List<CourseUnit>>{
      for (final level in LearnerLevel.values) level.code: <CourseUnit>[],
    };
    for (final unit in courseUnits) {
      if (unit.level != filterLevel) {
        continue; // 선택 레벨만 — 나머지는 렌더하지 않음.
      }
      grouped.putIfAbsent(unit.level, () => <CourseUnit>[]).add(unit);
    }
    for (final units in grouped.values) {
      units.sort((left, right) => left.order.compareTo(right.order));
    }
    final ordered = grouped.values.expand((units) => units).toList();
    CourseUnit? current;
    for (final unit in ordered) {
      if (unit.id == snapshot.currentCourseUnitId) {
        current = unit;
        break;
      }
    }
    CourseUnit? latestCompleted;
    for (final unit in ordered) {
      if (snapshot.completedUnitIds.contains(unit.id)) {
        latestCompleted = unit;
      }
    }
    final currentIndex = current == null ? -1 : ordered.indexOf(current);
    CourseUnit? next;
    for (var i = currentIndex + 1; i < ordered.length; i++) {
      final candidate = ordered[i];
      if (!snapshot.completedUnitIds.contains(candidate.id) &&
          !snapshot.bypassedPrerequisiteUnitIds.contains(candidate.id) &&
          candidate.id != current?.id) {
        next = candidate;
        break;
      }
    }
    final visible = <CourseUnit>[];
    for (final unit in [latestCompleted, current, next]) {
      if (unit != null &&
          !visible.any((candidate) => candidate.id == unit.id)) {
        visible.add(unit);
      }
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          t.pathStoryEyebrow(
            (LearnerLevel.fromCode(filterLevel) ?? LearnerLevel.a1).display,
          ),
          style: SoriTextTheme.of(context).label,
        ),
        const SizedBox(height: Spacing.xs),
        Text(t.pathStoryTitle, style: SoriTextTheme.of(context).h1),
        const SizedBox(height: Spacing.xs),
        Text(t.pathStoryBody, style: SoriTextTheme.of(context).bodySmall),
        const SizedBox(height: Spacing.lg),
        for (final unit in visible)
          Padding(
            padding: const EdgeInsets.only(bottom: Spacing.sm),
            child: _CourseMissionNode(
              key: ValueKey('path-course-row-${unit.id}'),
              unit: unit,
              status: _statusFor(unit),
              lang: lang,
              onTap: () => onTapUnit(unit),
            ),
          ),
        const SizedBox(height: Spacing.xs),
        const CourseProgressEvidenceNote(),
        if (current case final currentUnit?) ...[
          const SizedBox(height: Spacing.md),
          SoriButton.filled(
            key: const ValueKey('path-current-mission'),
            label: t.pathOpenCurrentMission,
            fullWidth: true,
            onTap: () => onTapUnit(currentUnit),
          ),
        ],
      ],
    );
  }

  _MissionPathStatus _statusFor(CourseUnit unit) {
    if (snapshot.currentCourseUnitId == unit.id) {
      return _MissionPathStatus.current;
    }
    if (snapshot.completedUnitIds.contains(unit.id)) {
      return _MissionPathStatus.completed;
    }
    if (snapshot.bypassedPrerequisiteUnitIds.contains(unit.id)) {
      return _MissionPathStatus.bypassed;
    }
    return _MissionPathStatus.preview;
  }
}

enum _MissionPathStatus { current, completed, bypassed, preview }

class _CourseMissionNode extends StatelessWidget {
  const _CourseMissionNode({
    super.key,
    required this.unit,
    required this.status,
    required this.lang,
    required this.onTap,
  });

  final CourseUnit unit;
  final _MissionPathStatus status;
  final String lang;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);
    final canDo = _conciseCanDo(unit.canDo.pick(lang), lang);
    final (icon, color, statusText) = switch (status) {
      _MissionPathStatus.current => (
        Icons.play_circle_outline_rounded,
        SoriColors.primary,
        t.pathStatusCurrent,
      ),
      _MissionPathStatus.completed => (
        Icons.check_circle_outline_rounded,
        SoriColors.success,
        t.pathStatusCompleted,
      ),
      _MissionPathStatus.bypassed => (
        Icons.fast_forward_rounded,
        SoriColors.info,
        t.pathStatusBypassed,
      ),
      _MissionPathStatus.preview => (
        Icons.visibility_outlined,
        SoriColors.warning,
        t.pathStatusNext,
      ),
    };
    final body = switch (status) {
      _MissionPathStatus.completed => t.pathCompletedCanDo(canDo),
      _MissionPathStatus.current => t.pathCurrentCanDo(canDo),
      _MissionPathStatus.preview => t.pathNextAfterEvidence,
      _MissionPathStatus.bypassed => canDo,
    };
    final stackStatus = MediaQuery.textScalerOf(context).scale(1) >= 1.6;
    final details = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(unit.title.pick(lang), style: SoriTextTheme.of(context).label),
        const SizedBox(height: 2),
        Text(body, style: SoriTextTheme.of(context).bodySmall),
        if (stackStatus) ...[
          const SizedBox(height: Spacing.sm),
          Text(
            statusText,
            style: SoriTextTheme.of(context).caption.copyWith(color: color),
          ),
        ],
      ],
    );
    return SoriCard(
      variant: SoriCardVariant.compact,
      accent: color,
      onTap: onTap,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _MissionStatusBadge(
            order: unit.order,
            status: status,
            icon: icon,
            color: color,
            semanticLabel: statusText,
          ),
          const SizedBox(width: Spacing.md),
          Expanded(child: details),
          if (!stackStatus) ...[
            const SizedBox(width: Spacing.sm),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 96),
              child: Text(
                statusText,
                textAlign: TextAlign.end,
                style: SoriTextTheme.of(context).caption.copyWith(color: color),
              ),
            ),
          ],
        ],
      ),
    );
  }

  static String _conciseCanDo(String value, String lang) {
    final prefix = lang == 'de' ? 'Ich kann ' : 'I can ';
    return value.startsWith(prefix) ? value.substring(prefix.length) : value;
  }
}

class _MissionStatusBadge extends StatelessWidget {
  const _MissionStatusBadge({
    required this.order,
    required this.status,
    required this.icon,
    required this.color,
    required this.semanticLabel,
  });

  final int order;
  final _MissionPathStatus status;
  final IconData icon;
  final Color color;
  final String semanticLabel;

  @override
  Widget build(BuildContext context) => Semantics(
    label: semanticLabel,
    child: ExcludeSemantics(
      child: Container(
        width: 40,
        height: 40,
        alignment: Alignment.center,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        child:
            status == _MissionPathStatus.completed ||
                status == _MissionPathStatus.bypassed
            ? Icon(icon, size: 22, color: Colors.white)
            : Text(
                '$order',
                style: SoriTextTheme.of(
                  context,
                ).label.copyWith(color: Colors.white),
              ),
      ),
    ),
  );
}

// ─── 한옥 단계 헤더 ──────────────────────────────────────────────────────────

class _HanokHeader extends StatelessWidget {
  const _HanokHeader({
    required this.stage,
    required this.cleared,
    required this.total,
  });

  final HanokStage stage;
  final int cleared;
  final int total;

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);
    final s = SoriSurfaces.of(context);
    final frac = total == 0 ? 0.0 : cleared / total;
    return Container(
      decoration: BoxDecoration(
        color: s.surface,
        borderRadius: SoriRadius.brLg,
        border: Border.all(color: s.border),
        boxShadow: SoriElevation.low,
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AspectRatio(
            aspectRatio: 16 / 9,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.asset(
                  'assets/illustrations/hanok_stages/stage_${stage.assetSlug}_light.png',
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          SoriColors.primarySoft,
                          SoriColors.lightSurfaceAlt,
                        ],
                      ),
                    ),
                    alignment: Alignment.center,
                    child: const Icon(
                      Icons.temple_buddhist_outlined,
                      size: 56,
                      color: SoriColors.primary,
                    ),
                  ),
                ),
                // 완료한 특별 퀘스트의 장식을 한옥 위에 합성 — "내 학습이
                // 마당을 꾸민다" 원설계 부활(2026-07-30, Jin 승인). 완료 0개면
                // SizedBox.shrink. 좌표는 마당 시안값 — 실기기 육안 튜닝 대상.
                CulturalGlossaryBuilder(
                  builder: (context, glossary) {
                    final inspectableSlugs =
                        glossary?.decorationSlugs ?? const {};
                    final completedSlugs = Storage.questCompletions.keys
                        .map((id) => kQuestById[id]?.decorationSlug)
                        .whereType<String>()
                        .toSet();
                    final hasInspectableObject = completedSlugs.any(
                      inspectableSlugs.contains,
                    );
                    return Stack(
                      fit: StackFit.expand,
                      children: [
                        DecorationLayer(
                          inspectableDecorationSlugs: inspectableSlugs,
                          onInspectDecoration: (slug) {
                            unawaited(markCulturalObjectHintSeen());
                            unawaited(
                              showCulturalDecorationSheet(context, slug),
                            );
                          },
                        ),
                        if (hasInspectableObject)
                          const PositionedDirectional(
                            start: Spacing.sm,
                            end: Spacing.sm,
                            top: Spacing.sm,
                            child: Align(
                              alignment: AlignmentDirectional.topCenter,
                              child: CulturalObjectHint(enabled: true),
                            ),
                          ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(Spacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  t.pathHanokStage(stage.ordinal + 1),
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: s.text,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  t.pathHanokSub,
                  style: TextStyle(
                    fontSize: 13,
                    color: s.textMuted,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: Spacing.md),
                SoriProgressBar(value: frac, animated: true),
                const SizedBox(height: 6),
                Text(
                  t.pathLevelPacks(cleared, total),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: s.textMuted,
                  ),
                ),
                const SizedBox(height: Spacing.md),
                SoriButton.outlined(
                  label: t.hanokWorldTitle,
                  fullWidth: true,
                  onTap: () => Navigator.of(context).pushNamed('/hanok'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
