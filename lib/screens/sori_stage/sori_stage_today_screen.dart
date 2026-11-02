import '../../widgets/sori/top_chrome.dart';
import '../../widgets/sori/yeopjeon_wallet_card.dart';
import 'dart:async' show unawaited;
import '../../features/dancheong/dancheong_connections.dart';
import '../../features/dancheong/dancheong_store.dart';
import '../../features/content_learning/content_learning_widgets.dart';
import '../../widgets/sori/learning_focus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../data/canonical_companion_art.dart';
import '../../data/milestone.dart';
import '../../data/quest_catalog.dart';
import '../../data/sori_activity_catalog.dart';
import '../../features/guide/today_guide_section.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../models/feedback_completion.dart';
import '../../models/quest.dart';
import '../../models/sarangchae_construction.dart';
import '../../models/sori_stage_progression.dart';
import '../../services/decoration_reward_service.dart';
import '../../services/sori_stage_progression_service.dart';
import '../../services/sori_stage_reward_receipt_service.dart';
import '../../services/storage_service.dart';
import '../../services/today_learning_snapshot.dart';
import '../../services/today_learning_navigation.dart';
import '../../widgets/app_loading.dart';
import '../../widgets/sori/activity_illustration.dart';
import '../../widgets/sori/button.dart';
import '../../widgets/sori/bojagi_reveal.dart' show kNajeonChestClosed;
import '../../widgets/sori/app_bar.dart';
import '../../widgets/sori/card.dart';
import '../../widgets/sori/cultural_help.dart';
import '../../widgets/sori/hanok_v3_preview.dart';
import '../../widgets/sori/c_gallery/c_materials.dart';
import '../../widgets/sori/mascot_preference.dart';
import '../../widgets/sori/milestone_celebration.dart';
import '../../widgets/sori/motion.dart';
import '../../widgets/sori/placed_decoration.dart' show decorName, decorTerm;
import '../../widgets/sori/progress_meter.dart';
import '../../widgets/sori/responsive.dart';
import '../../widgets/sori/reward_icon.dart';
import '../../widgets/sori/reward_thumb.dart';
import '../../widgets/sori/section_header.dart';
import '../../widgets/sori/sheet.dart';
import '../../widgets/sori/sori_term.dart';
import '../../widgets/sori/spotlight_coach.dart';
import '../../widgets/sori/approved_chrome_assets.dart';
import '../../widgets/sori/pressable.dart';
import '../../widgets/sori/settings_button.dart';
import '../../widgets/sori/today_learning_card.dart';
import '../../widgets/sori/today_subject_art.dart';
import '../../widgets/sori/c_gallery/c_objects.dart';
import '../../widgets/sori/tokens.dart';
import '../../widgets/sori/week_sheet.dart';
import '../../widgets/sori/window_class.dart';
import 'sori_stage_common.dart';
import 'c_stage_chrome.dart';
import 'sori_stage_reward_receipt_sheet.dart';

/// Today: compact greeting and companion grounded to the shared learning goal.
/// The compact brand and live wallet retain profile and settings access.
///
/// Approved C5 jade carries the native chrome and transparent canonical hero;
/// the shared learning goal owns the main paper card below it.
class SoriStageTodayScreen extends StatefulWidget {
  const SoriStageTodayScreen({
    super.key,
    this.loadSnapshot,
    this.refreshGeneration = 0,
    this.replayHomeTour,
    this.now,
    this.onHomeTourStarted,
    this.enableMilestoneCelebrations,
    this.active = true,
    this.forceStaticHero = false,
    this.onOpenGames,
  });

  final Future<SoriStageProgressionSnapshot> Function()? loadSnapshot;
  final int refreshGeneration;
  final ValueListenable<int>? replayHomeTour;

  /// 테스트/골든용 시계 주입 — 인사말(시간대)이 실제 시각에 묶이지 않게.
  final DateTime Function()? now;

  /// Test seam for availability-sensitive home-tour admission.
  final VoidCallback? onHomeTourStarted;

  /// Defaults to production-only (`loadSnapshot == null`) so preview and
  /// golden fixtures remain read-only. Milestone ownership tests can opt in.
  final bool? enableMilestoneCelebrations;

  /// The shell keeps Today mounted in an IndexedStack. Presentation side
  /// effects (tour and milestone sheet) are admitted only while this tab is
  /// visible.
  final bool active;

  /// Keeps the mascot frame deterministic in pixel tests.
  final bool forceStaticHero;

  /// Switches the existing shell tab without creating another game owner.
  final VoidCallback? onOpenGames;

  @override
  State<SoriStageTodayScreen> createState() => _SoriStageTodayScreenState();
}

class _SoriStageTodayScreenState extends State<SoriStageTodayScreen> {
  late Future<SoriStageProgressionSnapshot> _future;
  final GlobalKey _missionTourKey = GlobalKey();
  int _snapshotGeneration = 0;
  bool? _todayUnavailable;
  bool _homeTourScheduled = false;
  bool _celebrating = false;
  bool _milestoneHandledThisVisit = false;
  int _presentationGeneration = 0;

  bool get _milestoneCelebrationsEnabled =>
      widget.enableMilestoneCelebrations ?? widget.loadSnapshot == null;

  @override
  void initState() {
    super.initState();
    _future = _loadSnapshot(startHomeTourWhenReady: true);
    widget.replayHomeTour?.addListener(_onReplayRequested);
  }

  @override
  void didUpdateWidget(covariant SoriStageTodayScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.replayHomeTour != widget.replayHomeTour) {
      oldWidget.replayHomeTour?.removeListener(_onReplayRequested);
      widget.replayHomeTour?.addListener(_onReplayRequested);
    }
    final becameActive = !oldWidget.active && widget.active;
    final loaderChanged =
        oldWidget.loadSnapshot != widget.loadSnapshot ||
        oldWidget.refreshGeneration != widget.refreshGeneration;
    if (oldWidget.active != widget.active) {
      _presentationGeneration++;
    }
    if (widget.active && (becameActive || loaderChanged)) {
      // Re-entering Today is also its freshness boundary. This both avoids a
      // hidden-tab presentation and reflects rewards/progress earned elsewhere.
      _todayUnavailable = null;
      _future = _loadSnapshot(startHomeTourWhenReady: true);
    }
  }

  @override
  void dispose() {
    widget.replayHomeTour?.removeListener(_onReplayRequested);
    super.dispose();
  }

  void _onReplayRequested() {
    if (!widget.active) {
      return;
    }
    // Await the active snapshot rather than trusting a stale availability
    // flag. This covers replay requests while Today is still loading and
    // prevents an unavailable mission card from ever receiving the tour.
    final activeFuture = _future;
    activeFuture
        .then<void>((snapshot) {
          if (!mounted ||
              !identical(activeFuture, _future) ||
              snapshot.today.isUnavailable) {
            return;
          }
          _todayUnavailable = false;
          _scheduleHomeTour();
        })
        .onError((_, _) {});
  }

  Future<SoriStageProgressionSnapshot> _loadSnapshot({
    bool startHomeTourWhenReady = false,
    bool checkMilestones = true,
  }) {
    final generation = ++_snapshotGeneration;
    final future = (widget.loadSnapshot ?? SoriStageProgressionService.load)();
    future
        .then<void>((snapshot) {
          if (!mounted || generation != _snapshotGeneration) {
            return;
          }
          _todayUnavailable = snapshot.today.isUnavailable;
          if (startHomeTourWhenReady &&
              widget.active &&
              widget.replayHomeTour != null &&
              !snapshot.today.isUnavailable &&
              !Storage.tutHomeTourSeen) {
            _scheduleHomeTour(requireUnseen: true);
          }
          if (widget.active &&
              checkMilestones &&
              !snapshot.today.isUnavailable &&
              _milestoneCelebrationsEnabled &&
              !_milestoneHandledThisVisit) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (_canPresent(generation: generation)) {
                // ignore: discarded_futures
                _maybeCelebrateMilestone(generation: generation);
              }
            });
            WidgetsBinding.instance.scheduleFrame();
          }
        })
        .onError((_, _) {
          if (mounted && generation == _snapshotGeneration) {
            _todayUnavailable = null;
          }
        });
    return future;
  }

  void _scheduleHomeTour({bool requireUnseen = false}) {
    if (!widget.active || _homeTourScheduled || _todayUnavailable != false) {
      return;
    }

    // A replay normally arrives after Today has built, so starting directly
    // avoids depending on an unrelated future frame. Initial loading has no
    // target context yet and falls through to the post-frame path below.
    if (_missionTourKey.currentContext != null) {
      _startHomeTourIfAdmitted(requireUnseen: requireUnseen);
      return;
    }

    _homeTourScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _homeTourScheduled = false;
      _startHomeTourIfAdmitted(requireUnseen: requireUnseen);
    });
    // The snapshot callback can run after the current frame has completed.
    // Request one explicitly so the admission check does not wait for a
    // later, unrelated rebuild.
    WidgetsBinding.instance.scheduleFrame();
  }

  void _startHomeTourIfAdmitted({required bool requireUnseen}) {
    if (!mounted ||
        !widget.active ||
        _todayUnavailable != false ||
        _missionTourKey.currentContext == null ||
        (requireUnseen && Storage.tutHomeTourSeen)) {
      return;
    }
    _startHomeTour();
  }

  void _startHomeTour() {
    widget.onHomeTourStarted?.call();
    final t = AppL10n.of(context);
    SpotlightCoach.show(
      context,
      steps: [
        SpotlightStep(
          targetKey: _missionTourKey,
          title: t.coachHomeMissionTitle,
          body: t.coachHomeMissionBody,
          icon: Icons.play_circle_outline,
          cutoutPadding: const EdgeInsets.all(6),
          cutoutRadius: SoriRadius.xl,
        ),
      ],
      onComplete: () => Storage.setTutHomeTourSeen(),
    );
  }

  void _reload({bool checkMilestones = true}) {
    // Manual refresh uses the same shell-owned recommendation as Lernen.
    // ignore: discarded_futures
    LearningFocusScope.maybeOf(context)?.notifier?.refresh(force: true);
    setState(() {
      _todayUnavailable = null;
      _future = _loadSnapshot(checkMilestones: checkMilestones);
    });
  }

  bool _canPresent({required int generation, int? presentationGeneration}) =>
      mounted &&
      widget.active &&
      generation == _snapshotGeneration &&
      (presentationGeneration == null ||
          presentationGeneration == _presentationGeneration);

  /// Sori Stage Today owns milestone presentation after the legacy Home
  /// surface was removed. Only the highest-priority newly reached milestone
  /// is shown per visit; reward creation remains source-idempotent.
  Future<void> _maybeCelebrateMilestone({required int generation}) async {
    if (!_canPresent(generation: generation) ||
        _celebrating ||
        _milestoneHandledThisVisit ||
        !Storage.tutHomeTourSeen ||
        _todayUnavailable != false) {
      return;
    }
    final newly = newlyReachedMilestones(
      streak: Storage.streakDays,
      level: Storage.xpLevel,
      vocab: Storage.vokSeenIds.length,
      celebrated: Storage.celebratedMilestones.toSet(),
    );
    if (newly.isEmpty) {
      return;
    }
    const priority = <MilestoneType, int>{
      MilestoneType.streak: 3,
      MilestoneType.level: 2,
      MilestoneType.vocab: 1,
    };
    final top = newly.reduce((a, b) {
      final pa = priority[a.type]!;
      final pb = priority[b.type]!;
      if (pa != pb) {
        return pa > pb ? a : b;
      }
      return a.value >= b.value ? a : b;
    });

    _celebrating = true;
    final presentationGeneration = _presentationGeneration;
    try {
      if (!_canPresent(
        generation: generation,
        presentationGeneration: presentationGeneration,
      )) {
        return;
      }
      await DecorationRewardService.ensurePendingBox(
        '${DecorationRewardService.kMilestoneSourcePrefix}${top.id}',
      );
      if (!_canPresent(
        generation: generation,
        presentationGeneration: presentationGeneration,
      )) {
        return;
      }
      if (!mounted) {
        return;
      }
      final feedbackContext = FeedbackCompletion.milestone(
        milestoneId: top.id,
        milestoneType: top.type.name,
        value: top.value,
      ).context;
      _milestoneHandledThisVisit = true;
      // Opening the modal is synchronous up to route insertion. Persist only
      // after a visible presentation exists, then await its dismissal. This
      // prevents a hidden tab from consuming the milestone while preserving
      // the invariant that a currently displayed celebration is recorded.
      final presentation = showMilestoneCelebration(
        context,
        top,
        feedbackContext: feedbackContext,
      );
      await Storage.markMilestonesCelebrated([top.id]);
      await presentation;
      if (mounted) {
        // The pending Bojagi was created after the displayed snapshot. Refresh
        // once without admitting the next milestone in the same visit.
        _reload(checkMilestones: false);
      }
    } finally {
      _celebrating = false;
    }
  }

  Future<void> _showWeekSheet() async {
    await showSoriWeekSheet(context);
    if (mounted) {
      setState(() {}); // 시트에서 돌아온 뒤 스트릭/XP 칩 최신화.
    }
  }

  Widget _header(BuildContext context, AppL10n t) => LayoutBuilder(
    builder: (context, bounds) => Row(
      key: const ValueKey('today-top-chrome'),
      children: [
        Expanded(
          child: Tooltip(
            message: t.soriStageProfileTooltip,
            child: SoriPressable(
              onTap: () => Navigator.pushNamed(context, '/profile'),
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 48),
                child: Row(
                  children: [
                    const ApprovedChromeImage(
                      asset: ApprovedChromeAssets.cloud,
                      size: 32,
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        'HANGUL SORI',
                        style: SoriTextTheme.of(context).taskLabel.copyWith(
                          fontSize: 13,
                          letterSpacing: 1,
                          fontWeight: FontWeight.w600,
                          color: CPalette.paper,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        ConstrainedBox(
          constraints: BoxConstraints(maxWidth: bounds.maxWidth * .34),
          child: SoriWalletBadge(
            compact: true,
            jadeSurface: true,
            quiet: true,
            onReturned: _reload,
          ),
        ),
        const SizedBox(width: 4),
        const SoriSettingsButton(iconSize: 33),
      ],
    ),
  );

  Future<void> _showDetails(SoriStageProgressionSnapshot snapshot) =>
      showSoriSheet<void>(
        context: context,
        maxHeightFactor: .9,
        presentation: const SoriSheetPresentation(
          backgroundColor: Colors.transparent,
        ),
        builder: (context) => Scaffold(
          appBar: SoriAppBar(
            title: AppL10n.of(context).todayDetails,
            textScale: MediaQuery.textScalerOf(context).scale(1),
            viewportWidth: MediaQuery.sizeOf(context).width,
            locale: Localizations.localeOf(context),
          ),
          body: _TodayDetailsContent(
            snapshot: snapshot,
            onRefresh: _reload,
            missionTourKey: GlobalKey(),
            header: Wrap(
              children: [
                SoriTextAction(
                  onPressed: _showWeekSheet,
                  label: AppL10n.of(context).statsThisWeek,
                ),
                SoriTextAction(
                  onPressed: () => Navigator.pushNamed(context, '/stats'),
                  label: AppL10n.of(context).todayProgress,
                ),
              ],
            ),
            companion: const SizedBox.shrink(),
          ),
        ),
      );

  Widget _companion(BuildContext context, AppL10n t) {
    return ValueListenableBuilder<CompanionPreference>(
      valueListenable: MascotPreference.preference,
      builder: (context, preference, _) => LayoutBuilder(
        builder: (context, bounds) {
          final kind = MascotPreference.mascotKindFor(preference);
          final small = bounds.maxWidth < 336;
          final large = MediaQuery.textScalerOf(context).scale(16) >= 20.8;
          final heroHeight = bounds.hasBoundedHeight
              ? bounds.maxHeight
              : (small ? 76.0 : 106.0);
          final tight = heroHeight <= 66;
          final type = SoriTextTheme.of(context);
          final words = Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Semantics(
                header: true,
                child: Text(
                  t.soriStageNavToday,
                  style: cStageTitle(context).copyWith(
                    fontSize: tight
                        ? 28
                        : small
                        ? 31
                        : 38,
                    height: 46 / 38,
                  ),
                ),
              ),
              SizedBox(height: tight ? 2 : 4),
              Text(
                t.todayCompanionSubtitle,
                key: const ValueKey('today-companion-greeting'),
                style: type.body.copyWith(
                  fontSize: tight ? 14 : 15,
                  height: 20 / 15,
                  color: CPalette.paper,
                ),
              ),
            ],
          );
          Widget portrait(double size) => SizedBox(
            key: const ValueKey('learning-companion-ground'),
            width: size,
            height: size,
            child: _TodayCompanionArt(
              path: kind?.name == 'tiger'
                  ? CanonicalCompanionArt.baekhoExpressions
                  : CanonicalCompanionArt.magpieExpressions,
            ),
          );
          if (large) {
            return Column(
              key: kind == null
                  ? const ValueKey('sori-today-companion-hidden')
                  : null,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                words,
                if (kind != null)
                  Align(
                    alignment: Alignment.bottomRight,
                    child: Transform.translate(
                      offset: const Offset(0, 8),
                      child: portrait(112),
                    ),
                  ),
              ],
            );
          }
          return SizedBox(
            key: kind == null
                ? const ValueKey('sori-today-companion-hidden')
                : null,
            height: heroHeight,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                if (kind != null)
                  Positioned(
                    right: 0,
                    top: 0,
                    width: tight
                        ? 104
                        : small
                        ? 132
                        : 152,
                    height: tight
                        ? 72
                        : small
                        ? 132
                        : 152,
                    child: portrait(
                      tight
                          ? 72
                          : small
                          ? 132
                          : 152,
                    ),
                  ),
                Padding(
                  padding: EdgeInsets.only(
                    left: 12,
                    top: tight
                        ? 4
                        : small
                        ? 8
                        : 20,
                  ),
                  child: SizedBox(width: bounds.maxWidth * .62, child: words),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);
    return Scaffold(
      body: CStageBackground(
        key: const ValueKey('sori-today-bg'),
        backdrop: Align(
          alignment: Alignment.topCenter,
          child: SizedBox(
            height: 240 + MediaQuery.paddingOf(context).top,
            width: double.infinity,
            child: ShaderMask(
              blendMode: BlendMode.dstIn,
              shaderCallback: (rect) => const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                // Keep navigation quiet; the floral scene belongs beside the
                // companion rather than behind the wallet and settings.
                colors: [
                  Colors.transparent,
                  Colors.transparent,
                  Colors.white,
                  Colors.white,
                  Colors.transparent,
                ],
                stops: [0, .32, .52, .8, 1],
              ).createShader(rect),
              child: ShaderMask(
                blendMode: BlendMode.dstIn,
                shaderCallback: (rect) => const LinearGradient(
                  colors: [
                    Colors.transparent,
                    Colors.transparent,
                    Colors.white,
                    Colors.white,
                  ],
                  stops: [0, .55, .7, 1],
                ).createShader(rect),
                child: const CAtlasArt(
                  path: TodaySubjectArt.environments,
                  region: Rect.fromLTWH(.5, .5, .5, .5),
                ),
              ),
            ),
          ),
        ),
        child: SafeArea(
          child: FutureBuilder<SoriStageProgressionSnapshot>(
            future: _future,
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                return _TodayContent(
                  snapshot: snapshot.requireData,
                  onRefresh: () {
                    final wallet = SoriWalletScope.maybeOf(context);
                    if (wallet != null) {
                      unawaited(wallet.refresh());
                    }
                    _reload();
                  },
                  missionTourKey: _missionTourKey,
                  header: _header(context, t),
                  companion: _companion(context, t),
                  onDetails: () => _showDetails(snapshot.requireData),
                  onOpenGames: widget.onOpenGames,
                );
              }
              // 로딩/오류에도 헤더(톱바+히어로)는 즉시 보인다 — 홈과 같은
              // "캐릭터가 먼저 맞이하는" 진입이자, 셸 테스트의 Profile 툴팁
              // 계약(스냅샷 로드와 무관)이기도 하다. ListView 인 이유:
              // 낮은 높이(가로 폰·분할 화면 360dp)에서 헤더+스피너가 화면을
              // 넘칠 수 있어 스크롤로 받는다.
              final bool waiting =
                  snapshot.connectionState == ConnectionState.waiting;
              return SoriContentClamp(
                maxWidth: SoriMaxWidth.hub,
                base: Spacing.page,
                builder: (context, padding) => ListView(
                  padding: padding,
                  children: [
                    _header(context, t),
                    _companion(context, t),
                    if (LearningFocusScope.maybeOf(context) != null)
                      const CPaperPanel(
                        child: SoriLearningFocus(
                          conceptC: true,
                          conceptCompactSummary: true,
                        ),
                      ),
                    const SizedBox(height: Spacing.xl),
                    if (waiting)
                      const AppLoading()
                    else
                      _TodayError(onRetry: _reload),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

/// Native, state-backed reconstruction of the approved three Today mockups.
class _TodayContent extends StatelessWidget {
  const _TodayContent({
    required this.snapshot,
    required this.onRefresh,
    required this.missionTourKey,
    required this.header,
    required this.companion,
    required this.onDetails,
    this.onOpenGames,
  });
  final SoriStageProgressionSnapshot snapshot;
  final VoidCallback onRefresh;
  final GlobalKey missionTourKey;
  final Widget header;
  final Widget companion;
  final VoidCallback onDetails;
  final VoidCallback? onOpenGames;

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);
    final scale = MediaQuery.textScalerOf(context).scale(16) / 16;
    return SoriContentClamp(
      maxWidth: SoriMaxWidth.hub,
      base: const EdgeInsets.fromLTRB(10, 16, 10, 10),
      builder: (context, padding) => LayoutBuilder(
        builder: (context, bounds) {
          final large = scale >= 1.3;
          final small = bounds.maxWidth - padding.horizontal < 336;
          final tight = !large && bounds.maxHeight < 650;
          final insets = tight ? padding.copyWith(top: 8, bottom: 6) : padding;
          final heroHeight = tight
              ? 64.0
              : small
              ? 76.0
              : 106.0;
          final rewardHeight = large
              ? 110 * scale
              : tight
              ? 88.0
              : 110.0;
          final discoveryHeight = large
              ? 118 * scale
              : tight
              ? 84.0
              : (small ? 112.0 : 134.0);
          final reserved =
              8 +
              insets.vertical +
              48 +
              heroHeight +
              20 +
              rewardHeight +
              discoveryHeight;
          final missionHeight = (bounds.maxHeight - reserved).clamp(
            tight ? 190.0 : 220.0,
            440.0,
          );
          Future<void> open(String route) async {
            await Navigator.pushNamed(context, route);
            if (context.mounted) onRefresh();
          }

          return RefreshIndicator(
            onRefresh: () async => onRefresh(),
            child: ListView(
              key: const ValueKey('today-dashboard-scroll'),
              physics: const AlwaysScrollableScrollPhysics(),
              padding: insets,
              children: [
                header,
                Semantics(
                  button: true,
                  label: t.todayDetails,
                  child: InkWell(
                    key: const ValueKey('today-details'),
                    onTap: onDetails,
                    child: large
                        ? companion
                        : SizedBox(height: heroHeight, child: companion),
                  ),
                ),
                if (LearningFocusScope.maybeOf(context) != null)
                  TodayLearningCard(
                    key: missionTourKey,
                    availableHeight: missionHeight,
                    compactArt: tight,
                  )
                else
                  CPaperPanel(
                    child: _TodayMissionStage(
                      key: missionTourKey,
                      snapshot: snapshot,
                      onActivityReturned: onRefresh,
                    ),
                  ),
                if (!snapshot.today.isUnavailable) ...[
                  const SizedBox(height: 10),
                  _TodayTreasureCard(
                    count: snapshot.pendingBojagiCount,
                    height: rewardHeight,
                    compact: tight,
                    onTap: () => open(
                      snapshot.pendingBojagiCount > 0
                          ? '/bojagi'
                          : '/sarangbang/furnish',
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: _TodayHanokEntrance(
                          owned: snapshot.ownedSarangchaeStage,
                          unavailable: snapshot.walletUnavailable,
                          height: discoveryHeight,
                          onTap: () => open('/hanok'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _TodayDiscovery(
                          key: const ValueKey('today-quick-play'),
                          title: t.todayExploreGames,
                          asset: ApprovedChromeAssets.games,
                          scene: const CSceneArt(CScene.syllables, height: 220),
                          height: discoveryHeight,
                          onTap: onOpenGames,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}

/// Contact changes the approved sprite frame, never the character identity.
class _TodayCompanionArt extends StatefulWidget {
  const _TodayCompanionArt({required this.path});
  final String path;
  @override
  State<_TodayCompanionArt> createState() => _TodayCompanionArtState();
}

class _TodayCompanionArtState extends State<_TodayCompanionArt> {
  bool contact = false;
  @override
  Widget build(BuildContext context) => Listener(
    onPointerDown: (_) => setState(() => contact = true),
    onPointerUp: (_) => setState(() => contact = false),
    onPointerCancel: (_) => setState(() => contact = false),
    child: CAtlasArt(
      path: widget.path,
      region: Rect.fromLTWH(contact ? .25 : 0, 0, .25, .5),
      fit: BoxFit.contain,
    ),
  );
}

/// A real pending offer opens the reward owner; an empty queue opens collection.
class _TodayTreasureCard extends StatelessWidget {
  const _TodayTreasureCard({
    required this.count,
    required this.height,
    required this.onTap,
    this.compact = false,
  });
  final int count;
  final double height;
  final VoidCallback onTap;
  final bool compact;
  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);
    final type = SoriTextTheme.of(context);
    final status = count > 0
        ? t.todayTreasureReady(count)
        : t.najeonChestEmptyTitle;
    final action = count > 0 ? t.todayTreasureOpen : t.todayTreasureCollection;
    return Semantics(
      button: true,
      label: '${t.todayTreasureTitle}. $status. $action',
      onTap: onTap,
      excludeSemantics: true,
      child: SoriPressable(
        key: const ValueKey('today-finds'),
        pressScale: .99,
        pressOffsetY: 1,
        releaseCurve: SoriMotion.gentle,
        onTap: onTap,
        child: Container(
          constraints: BoxConstraints(minHeight: height),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            boxShadow: const [
              BoxShadow(
                color: Color(0x52071f18),
                offset: Offset(0, 4),
                blurRadius: 5,
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: Stack(
              children: [
                const Positioned.fill(child: CTexture(CMaterial.oak)),
                Padding(
                  padding: const EdgeInsets.all(5),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: CPalette.brass, width: 1.4),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(13),
                      child: Stack(
                        children: [
                          const Positioned.fill(
                            child: CTexture(CMaterial.jade),
                          ),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(6, 4, 8, 4),
                            child: Row(
                              children: [
                                SizedBox(
                                  width: compact
                                      ? 70
                                      : height <= 110
                                      ? 100
                                      : 110,
                                  height: compact ? 64 : 96,
                                  child: Image.asset(
                                    kNajeonChestClosed,
                                    fit: BoxFit.contain,
                                    excludeFromSemantics: true,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        t.todayTreasureTitle,
                                        style: type.h3.copyWith(
                                          fontSize: 17,
                                          height: 22 / 17,
                                          color: CPalette.paper,
                                        ),
                                      ),
                                      Text(
                                        status,
                                        style: type.body.copyWith(
                                          fontSize: 14,
                                          height: 18 / 14,
                                          color: CPalette.paper,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      if (!compact)
                                        Container(
                                          constraints: const BoxConstraints(
                                            minHeight: 48,
                                          ),
                                          width: 152,
                                          alignment: Alignment.center,
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 8,
                                          ),
                                          decoration: BoxDecoration(
                                            color: CPalette.jade,
                                            border: Border.all(
                                              color: CPalette.brass,
                                              width: 1.5,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              22,
                                            ),
                                          ),
                                          child: Text(
                                            action,
                                            textAlign: TextAlign.center,
                                            style: type.label.copyWith(
                                              fontSize: 17,
                                              height: 22 / 17,
                                              color: CPalette.paper,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Uses the same physical card as Quick play, with an entrance illustration
/// rather than unearned finished architecture. The owned count stays native.
class _TodayHanokEntrance extends StatelessWidget {
  const _TodayHanokEntrance({
    required this.owned,
    required this.unavailable,
    required this.height,
    required this.onTap,
  });
  static const illustration =
      'assets/illustrations/concept_c/today/hanok-entrance.png';
  final int owned;
  final bool unavailable;
  final double height;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);
    final progress = unavailable
        ? t.soriStageHanokProgressUnavailable
        : t.sarangchaeConstructionProgress(
            owned,
            SarangchaeConstruction.stageCount,
          );
    return Semantics(
      key: const ValueKey('today-hanok-entrance'),
      button: true,
      label: '${t.todayYourHanok}. $progress',
      onTap: onTap,
      excludeSemantics: true,
      child: _TodayDiscovery(
        title: t.todayYourHanok,
        asset: illustration,
        height: height,
        progress: unavailable
            ? '—'
            : '$owned / ${SarangchaeConstruction.stageCount}',
        onTap: onTap,
      ),
    );
  }
}

class _TodayDiscovery extends StatelessWidget {
  const _TodayDiscovery({
    super.key,
    required this.title,
    required this.asset,
    required this.height,
    required this.onTap,
    this.progress,
    this.scene,
  });
  final String title;
  final String? progress;
  final Widget? scene;
  final String asset;
  final double height;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) {
    final type = SoriTextTheme.of(context);
    final large = MediaQuery.textScalerOf(context).scale(16) > 20.8;
    return Semantics(
      button: true,
      label: title,
      onTap: onTap,
      child: SoriPressable(
        pressScale: .99,
        pressOffsetY: 1,
        releaseCurve: SoriMotion.gentle,
        onTap: onTap,
        child: CPaperPanel(
          radius: 18,
          raised: false,
          surfaceTexture: const CTexture(CMaterial.paper),
          padding: const EdgeInsets.fromLTRB(10, 5, 10, 8),
          child: SizedBox(
            height: height - 15,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Center(
                    child:
                        scene ??
                        Image.asset(
                          asset,
                          fit: BoxFit.contain,
                          excludeFromSemantics: true,
                        ),
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: type.label.copyWith(
                          fontSize: 16,
                          height: 1.25,
                          color: CPalette.ink,
                        ),
                      ),
                    ),
                    const SizedBox(width: 2),
                    const CArrow(size: 14),
                  ],
                ),
                const SizedBox(height: 2),
                if (progress != null)
                  Text(
                    progress!,
                    key: const ValueKey('today-hanok-entrance-progress'),
                    style: type.caption.copyWith(
                      fontSize: 13,
                      height: 16 / 13,
                      color: CPalette.mutedInk,
                    ),
                  )
                else
                  SizedBox(
                    height: large
                        ? 16 * MediaQuery.textScalerOf(context).scale(1)
                        : 16,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TodayDetailsContent extends StatelessWidget {
  const _TodayDetailsContent({
    required this.snapshot,
    required this.onRefresh,
    required this.missionTourKey,
    required this.header,
    required this.companion,
  });
  final SoriStageProgressionSnapshot snapshot;
  final VoidCallback onRefresh;
  final GlobalKey missionTourKey;
  final Widget header;
  final Widget companion;

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);
    final todayUnavailable = snapshot.today.isUnavailable;
    // §W-D D6: 미션·보자기·한옥·섹션 2개 — 실제로 그려지는 블록 순서대로
    // 40ms 씩 늘려 stagger 한다(최대 6블록, 이 화면은 그 안에 든다).
    // reduce-motion 은 SoriEntrance 자체가 처리한다(§ 재확인 필요 없음).
    var entranceIndex = 0;
    Widget stagger(Widget child) {
      final delay = Duration(milliseconds: 40 * entranceIndex.clamp(0, 5));
      entranceIndex++;
      return SoriEntrance(delay: delay, child: child);
    }

    // §W-D D3: "Fast geschafft"(≥60%)·"Als Nächstes"(<60%) — 둘 다 이미
    // closestQuests 가 상위 3개로 자른 같은 리스트를 fraction 으로 나눌 뿐,
    // 모델에 새 조회를 추가하지 않는다.
    final closestQuests = snapshot.closestQuests;
    final nearlyComplete = closestQuests
        .where((quest) => quest.fraction >= 0.6)
        .take(3)
        .toList(growable: false);
    final upNext = closestQuests
        .where((quest) => quest.fraction < 0.6)
        .take(3)
        .toList(growable: false);

    return SoriContentClamp(
      maxWidth: SoriMaxWidth.hub,
      base: EdgeInsets.fromLTRB(
        12,
        MediaQuery.sizeOf(context).height < 750 ? 8 : 12,
        12,
        24,
      ),
      builder: (context, padding) => RefreshIndicator(
        onRefresh: () async => onRefresh(),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: padding,
          children: [
            header,
            if (SoriWalletScope.maybeOf(context) == null &&
                !todayUnavailable &&
                !snapshot.walletUnavailable &&
                snapshot.wallet != null)
              Align(
                alignment: Alignment.centerRight,
                child: SoriWalletBadge(
                  fallback: snapshot.wallet,
                  onReturned: onRefresh,
                ),
              ),
            companion,
            CPaperPanel(
              key: const ValueKey('c-today-board'),
              radius: 18,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  stagger(
                    LearningFocusScope.maybeOf(context) != null
                        ? SoriLearningFocus(
                            key: missionTourKey,
                            conceptC: true,
                            conceptCompactSummary: true,
                          )
                        : Column(
                            children: [
                              _TodayMissionStage(
                                key: missionTourKey,
                                snapshot: snapshot,
                                onActivityReturned: onRefresh,
                              ),
                            ],
                          ),
                  ),
                  const TodayGuideChecklistSection(topSpacing: Spacing.md),
                  const ContentDailyGoals(),
                  // A partial Today snapshot must not look like a complete daily
                  // dashboard. In particular, neither reward collection nor
                  // unrelated activity CTAs may accompany its safe retry path.
                  if (!todayUnavailable) ...[
                    if (snapshot.pendingBojagiCount > 0) ...[
                      const SizedBox(height: Spacing.md),
                      stagger(
                        _PendingBojagi(count: snapshot.pendingBojagiCount),
                      ),
                    ],
                    DancheongDraftResume(
                      store: DancheongStore(),
                      onOpen: (arguments) => Navigator.of(context).pushNamed(
                        '/dancheong-studio/edit',
                        arguments: arguments,
                      ),
                    ),
                    const SizedBox(height: Spacing.lg),
                    stagger(_HanokProgress(snapshot: snapshot)),
                    const SizedBox(height: Spacing.md),
                    YeopjeonWalletCard(key: ObjectKey(snapshot), compact: true),
                    if (nearlyComplete.isNotEmpty) ...[
                      const SizedBox(height: Spacing.lg),
                      stagger(
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // §D: 섹션 제목은 SoriSectionHeader(골드 hairline)
                            // 규격 — 자체 하단 여백(Spacing.sm)을 갖는다.
                            SoriSectionHeader(t.soriStageClosestQuests),
                            for (final quest in nearlyComplete)
                              _QuestProgressRow(progress: quest),
                          ],
                        ),
                      ),
                    ],
                    if (upNext.isNotEmpty) ...[
                      const SizedBox(height: Spacing.lg),
                      stagger(
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SoriSectionHeader(t.soriStageNextQuests),
                            for (final quest in upNext)
                              _QuestProgressRow(progress: quest),
                          ],
                        ),
                      ),
                    ],
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TodayMissionStage extends StatelessWidget {
  const _TodayMissionStage({
    super.key,
    required this.snapshot,
    required this.onActivityReturned,
  });
  final SoriStageProgressionSnapshot snapshot;
  final VoidCallback onActivityReturned;

  @override
  Widget build(BuildContext context) {
    // [TodayLearningSnapshotLoader] returns a partial snapshot when one of
    // its sources fails. It is useful for diagnostics, but it must never
    // become a fresh-looking mission or enter the reward-capture flow.
    if (snapshot.today.isUnavailable) {
      return _TodayUnavailableMissionStage(
        key: const ValueKey('sori-today-unavailable-mission'),
        today: snapshot.today,
        onRetry: onActivityReturned,
      );
    }

    final t = AppL10n.of(context);
    final tt = SoriTextTheme.of(context);
    final destination = snapshot.today.destination;
    final contract = snapshot.todayReward;
    // §P3-1: 활동 entry 는 기존 activityForRoute 로 얻는다 (신규 조회 함수
    // 발명 금지). 가능한 라우트 4종은 전부 activities/{id}.webp 를 보유 —
    // entry == null 강등 분기는 현재 도달 불가지만 가드로 필수.
    final entry = activityForRoute(destination?.route);
    // 3중 반복("Heutige Mission starten" ×2 + brand eyebrow) 해체 —
    // 제목은 오늘 활동의 로컬라이즈드 타이틀이 말한다.
    final String title = destination == null
        ? t.soriStageTodayEmpty
        : (entry == null
              ? t.soriStageMissionAction
              : localCopy(context, entry.title));
    final compact = MediaQuery.sizeOf(context).height < 750;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (entry != null && destination != null)
          // errorBuilder 는 2차 가드일 뿐: AspectRatio 는 자식이 아니라
          // 제약으로 크기가 잡히므로 errorBuilder 만으론 빈 다크 밴드가
          // 남는다. 1차 강등은 위 entry null 게이트다.
          ClipRRect(
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(SoriRadius.xl),
            ),
            child: SizedBox(
              height: compact ? 48 : 96,
              child: Image.asset(
                activityIllustrationAsset(entry.id),
                fit: BoxFit.contain,
                errorBuilder: (_, _, _) => const SizedBox.shrink(),
              ),
            ),
          ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                t.soriStageTodayMissionEyebrow,
                // eyebrow 토큰 — 짙은 한옥 스테이지 위라 석간주 대신 골드.
                style: tt.body.copyWith(fontSize: 16, color: CPalette.ink),
              ),
              const SizedBox(height: Spacing.sm),
              Text(
                title,
                // §D: 카드 내부 헤드라인은 h1 상한 — hero(38)는 페이지
                // 헤더 전용.
                style: tt.h1.copyWith(fontSize: 22, color: CPalette.ink),
              ),
              if (contract != null && contract.items.isNotEmpty) ...[
                const SizedBox(height: Spacing.lg),
                // §W-D D5.2: "Mögliche Belohnung:" 은 골드 라벨보다
                // 낮은 위계 — meta(13.5) + white@0.8.
                Text(
                  '${t.soriStagePossibleReward}:',
                  style: tt.meta.copyWith(color: CPalette.ink, fontSize: 16),
                ),
                const SizedBox(height: Spacing.sm),
                // §W-D D5.1: 세로 3열(아이콘 위·라벨 아래) — items 는 kind 가
                // 아이템마다 다르다(단일 roofing 아이콘 금지 원칙 유지).
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (final item in contract.items)
                      Expanded(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              soriRewardIcon(item.kind),
                              size: 20,
                              color: SoriColors.gold,
                            ),
                            const SizedBox(height: Spacing.xs),
                            Text(
                              localCopy(context, item.label),
                              textAlign: TextAlign.center,
                              style: tt.label.copyWith(
                                fontSize: 16,
                                color: CPalette.ink,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ],
              const SizedBox(height: 8),
              CMaterialAction(
                compact: compact,
                // 제목이 이미 무엇인지 말한다 — CTA 는 "Starten" 한 단어.
                // 미션이 없을 때는 기존 안내형 라벨 유지.
                label: destination == null || entry == null
                    ? t.soriStageMissionAction
                    : t.soriStageMissionStart,
                onTap: () async {
                  final activityId =
                      contract?.activityId ?? destination?.route ?? 'today';
                  final receipt = await SoriStageRewardReceiptService.capture(
                    activityId: activityId,
                    loadSnapshot: SoriStageProgressionService.load,
                    openActivity: () async {
                      if (destination == null) {
                        await Navigator.of(context).pushNamed('/path');
                        return;
                      }
                      await TodayLearningNavigation.open(
                        destination,
                        openRoute: (route, arguments) async {
                          await Navigator.of(
                            context,
                          ).pushNamed(route, arguments: arguments);
                        },
                      );
                    },
                  );
                  if (!context.mounted) {
                    return;
                  }
                  onActivityReturned();
                  if (receipt != null) {
                    await showSoriStageRewardReceipt(context, receipt);
                  }
                },
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Conservative presentation for a partial Today snapshot.
///
/// This preserves the shared loader's availability contract: users may retry
/// or open an already-saved review, but no stale recommendation is presented
/// as today's fresh mission and no Stage reward receipt is captured.
class _TodayUnavailableMissionStage extends StatelessWidget {
  const _TodayUnavailableMissionStage({
    super.key,
    required this.today,
    required this.onRetry,
  });

  final TodayLearningSnapshot today;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);
    final tt = SoriTextTheme.of(context);
    final hasSavedReview = today.dueCount > 0;
    final copy = _TodayUnavailableCopy.from(
      t,
      today.unavailableReason,
      hasSavedReview: hasSavedReview,
    );

    return Container(
      padding: const EdgeInsets.all(Spacing.xl),
      decoration: BoxDecoration(
        color: SoriActivityColors.hanokStage,
        borderRadius: BorderRadius.circular(SoriRadius.xl),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(copy.icon, color: SoriColors.gold),
              const SizedBox(width: Spacing.sm),
              Expanded(
                child: Text(
                  copy.eyebrow,
                  style: tt.eyebrow.copyWith(color: SoriColors.gold),
                ),
              ),
            ],
          ),
          const SizedBox(height: Spacing.md),
          Text(copy.title, style: tt.h1.copyWith(color: Colors.white)),
          const SizedBox(height: Spacing.sm),
          Text(
            copy.body,
            style: tt.body.copyWith(color: SoriActivityColors.onHanokStage),
          ),
          if (hasSavedReview) ...[
            const SizedBox(height: Spacing.xl),
            Text(
              t.homeUnavailableSafeTitle,
              style: tt.label.copyWith(color: SoriColors.gold),
            ),
            const SizedBox(height: Spacing.xs),
            Text(
              t.homeUnavailableSafeBody,
              style: tt.bodySmall.copyWith(
                color: SoriActivityColors.onHanokStage,
              ),
            ),
          ],
          const SizedBox(height: Spacing.xl),
          if (hasSavedReview) ...[
            SoriButton(
              key: const ValueKey('sori-today-saved-review'),
              label: t.homeUnavailableCta,
              onTap: () => Navigator.of(context).pushNamed('/review'),
            ),
            const SizedBox(height: Spacing.sm),
            TextButton(
              key: const ValueKey('sori-today-unavailable-retry'),
              onPressed: onRetry,
              style: TextButton.styleFrom(
                foregroundColor: SoriActivityColors.onHanokStage,
              ),
              child: Text(copy.retryLabel),
            ),
          ] else
            SoriButton(
              key: const ValueKey('sori-today-unavailable-retry'),
              label: copy.retryLabel,
              onTap: onRetry,
            ),
        ],
      ),
    );
  }
}

class _TodayUnavailableCopy {
  const _TodayUnavailableCopy({
    required this.icon,
    required this.eyebrow,
    required this.title,
    required this.body,
    required this.retryLabel,
  });

  final IconData icon;
  final String eyebrow;
  final String title;
  final String body;
  final String retryLabel;

  factory _TodayUnavailableCopy.from(
    AppL10n t,
    TodayLearningUnavailableReason? reason, {
    required bool hasSavedReview,
  }) {
    return switch (reason ?? TodayLearningUnavailableReason.localData) {
      TodayLearningUnavailableReason.offline => _TodayUnavailableCopy(
        icon: Icons.cloud_off_outlined,
        eyebrow: t.homeUnavailableEyebrow,
        title: t.homeUnavailableTitle,
        body: hasSavedReview
            ? t.homeUnavailableDescription
            : t.homeUnavailableDescriptionNoReview,
        retryLabel: t.homeUnavailableRetry,
      ),
      TodayLearningUnavailableReason.remoteService => _TodayUnavailableCopy(
        icon: Icons.cloud_sync_outlined,
        eyebrow: t.homeRemoteUnavailableEyebrow,
        title: t.homeRemoteUnavailableTitle,
        body: hasSavedReview
            ? t.homeRemoteUnavailableDescription
            : t.homeRemoteUnavailableDescriptionNoReview,
        retryLabel: t.homeUnavailableRetryGeneric,
      ),
      TodayLearningUnavailableReason.localData => _TodayUnavailableCopy(
        icon: Icons.refresh_rounded,
        eyebrow: t.homeLocalUnavailableEyebrow,
        title: t.homeLocalUnavailableTitle,
        body: hasSavedReview
            ? t.homeLocalUnavailableDescription
            : t.homeLocalUnavailableDescriptionNoReview,
        retryLabel: t.homeUnavailableRetryGeneric,
      ),
    };
  }
}

class _PendingBojagi extends StatelessWidget {
  const _PendingBojagi({required this.count});
  final int count;
  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);
    final tt = SoriTextTheme.of(context);
    final semanticsLabel = [
      t.soriStageBojagiTitle,
      '$count',
      t.soriStageBojagiBody,
      t.soriStageOpenBojagi,
    ].join('. ');
    void openBojagi() => Navigator.of(context).pushNamed('/bojagi');
    return Semantics(
      button: true,
      label: semanticsLabel,
      onTap: openBojagi,
      child: ExcludeSemantics(
        child: InkWell(
          onTap: openBojagi,
          borderRadius: BorderRadius.circular(SoriRadius.md),
          child: Container(
            constraints: const BoxConstraints(minHeight: 88),
            padding: const EdgeInsets.all(Spacing.md),
            decoration: BoxDecoration(
              color: SoriColors.gold.withValues(alpha: .18),
              border: Border.all(color: SoriColors.gold),
              borderRadius: BorderRadius.circular(SoriRadius.md),
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final textScale = MediaQuery.textScalerOf(context).scale(1);
                final stacked =
                    constraints.maxWidth < SoriAdaptiveWidth.footerActionRow ||
                    textScale >= 1.6;
                final details = Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${t.soriStageBojagiTitle} · $count',
                      key: const ValueKey('pending-bojagi-title'),
                      style: tt.h3,
                    ),
                    Text(
                      t.soriStageBojagiBody,
                      key: const ValueKey('pending-bojagi-body'),
                      style: tt.bodySmall,
                    ),
                  ],
                );
                final action = Text(
                  t.soriStageOpenBojagi,
                  key: const ValueKey('pending-bojagi-action'),
                  style: tt.label,
                );
                const icon = Icon(
                  Icons.redeem_rounded,
                  size: 36,
                  color: SoriColors.goldOnLight,
                );

                if (stacked) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          icon,
                          const SizedBox(width: Spacing.md),
                          Expanded(child: details),
                        ],
                      ),
                      const SizedBox(height: Spacing.md),
                      Align(
                        alignment: AlignmentDirectional.centerEnd,
                        child: action,
                      ),
                    ],
                  );
                }

                return Row(
                  children: [
                    icon,
                    const SizedBox(width: Spacing.md),
                    Expanded(child: details),
                    const SizedBox(width: Spacing.md),
                    action,
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _HanokProgress extends StatefulWidget {
  const _HanokProgress({required this.snapshot});
  final SoriStageProgressionSnapshot snapshot;

  @override
  State<_HanokProgress> createState() => _HanokProgressState();
}

class _HanokProgressState extends State<_HanokProgress> {
  late final Future<SarangchaeConstruction> _construction =
      SarangchaeConstruction.load();

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);
    final text = SoriTextTheme.of(context);
    final snapshot = widget.snapshot;
    final owned = snapshot.ownedSarangchaeStage;
    final unavailable = snapshot.walletUnavailable;
    final details = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          t.soriStageHanokNow,
          style: text.cardTitle.copyWith(color: CPalette.paper),
        ),
        const SizedBox(height: 4),
        Text(
          unavailable
              ? t.soriStageHanokProgressUnavailable
              : t.sarangchaeConstructionProgress(
                  owned,
                  SarangchaeConstruction.stageCount,
                ),
          key: const ValueKey('today-hanok-owned-stages'),
          style: text.bodySmall.copyWith(color: CPalette.paper),
        ),
        const SizedBox(height: 8),
        Text(
          snapshot.hanokCompetence.totalUnitCount == 0
              ? t.soriStageHanokNoUnits
              : t.soriStageConfirmedUnits(
                  snapshot.hanokCompetence.completedUnitCount,
                  snapshot.hanokCompetence.totalUnitCount,
                ),
          key: const ValueKey('today-hanok-confirmed-units'),
          style: text.bodySmall.copyWith(color: CPalette.paper),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            if (!unavailable && owned == 0) ...[
              const Icon(
                Icons.lock_outline_rounded,
                size: 18,
                color: CPalette.paper,
              ),
              const SizedBox(width: 4),
            ],
            Expanded(
              child: Text(
                t.soriStageOpenHanok,
                style: text.label.copyWith(color: CPalette.paper),
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              size: 20,
              color: CPalette.paper,
            ),
          ],
        ),
      ],
    );
    return SoriCard(
      key: const ValueKey('today-hanok-summary'),
      variant: SoriCardVariant.compact,
      backgroundColor: CPalette.deepJade,
      onTap: () => Navigator.of(context).pushNamed('/hanok'),
      child: LayoutBuilder(
        builder: (context, bounds) {
          if (unavailable || owned <= 1) return details;
          final stacked =
              bounds.maxWidth < SoriBreakpoints.hanokSummaryStack ||
              MediaQuery.textScalerOf(context).scale(1) >= 1.6;
          final art = SizedBox(
            key: const ValueKey('today-owned-sarangchae-artwork'),
            width: stacked ? double.infinity : 128,
            height: stacked ? 160 : 112,
            child: FutureBuilder<SarangchaeConstruction>(
              future: _construction,
              builder: (context, catalog) {
                if (catalog.hasError) {
                  return Center(
                    child: Text(
                      t.loadErrorTryAgain,
                      style: text.bodySmall.copyWith(color: CPalette.paper),
                    ),
                  );
                }
                if (!catalog.hasData) {
                  return Semantics(
                    label: t.speechIndicatorResolving,
                    child: const Center(
                      child: Icon(
                        Icons.hourglass_empty_rounded,
                        color: CPalette.paper,
                      ),
                    ),
                  );
                }
                return SarangchaeStageArtwork(
                  construction: catalog.data!,
                  earnedStageCount: owned,
                );
              },
            ),
          );
          return stacked
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [art, const SizedBox(height: 8), details],
                )
              : Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    art,
                    const SizedBox(width: 12),
                    Expanded(child: details),
                  ],
                );
        },
      ),
    );
  }
}

/// Secondary "Romanization · Hangul" line under a quest reward's name —
/// only when the glossary actually links [decorationSlug] to a term (most
/// slugs do not) and the term adds something [decorName] does not already
/// say (§W-C C3).
Widget _questCulturalTerm(BuildContext context, String decorationSlug) {
  return CulturalGlossaryBuilder(
    builder: (context, glossary) {
      final termId = glossary?.termIdForDecoration(decorationSlug);
      if (termId == null) {
        return const SizedBox.shrink();
      }
      final t = AppL10n.of(context);
      final term = decorTerm(t, decorationSlug);
      if (term == decorName(t, decorationSlug)) {
        return const SizedBox.shrink();
      }
      return Padding(
        padding: const EdgeInsets.only(top: 2),
        child: SoriTerm(
          termId: termId,
          text: term,
          style: SoriTextTheme.of(context).meta,
          surface: 'today_quest_row',
        ),
      );
    },
  );
}

class _QuestProgressRow extends StatelessWidget {
  const _QuestProgressRow({required this.progress});
  final QuestProgress progress;

  /// §W-D D4: 56dp 한지 원형 매트(`s.surfaceAlt` 원) + 보상 썸네일.
  Widget _thumbMat(SoriSurfaces s, String slug, bool earned) {
    const size = 56.0;
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: s.surfaceAlt, shape: BoxShape.circle),
      child: SoriRewardThumb(
        slug: slug,
        earned: earned,
        size: size,
        semantic: '',
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final definition = kQuestCatalog.firstWhere(
      (quest) => quest.id == progress.questId,
    );
    final language = Localizations.localeOf(context).languageCode;
    final tt = SoriTextTheme.of(context);
    final s = SoriSurfaces.of(context);
    // §P3-3b: 맨 ListTile → SoriCard(compact) 규율 + 보상 썸네일(퀘스트가
    // 언락하는 마당 장식 — quests 화면과 같은 SoriRewardThumb 공용 위젯).
    return Padding(
      padding: const EdgeInsets.only(bottom: Spacing.sm),
      child: SoriCard(
        variant: SoriCardVariant.compact,
        onTap: () => Navigator.of(context).pushNamed('/quests'),
        child: Row(
          children: [
            _thumbMat(s, definition.decorationSlug, progress.completed),
            const SizedBox(width: Spacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    language == 'de' ? definition.name.de : definition.name.en,
                    style: tt.cardTitle,
                  ),
                  _questCulturalTerm(context, definition.decorationSlug),
                  const SizedBox(height: Spacing.xs),
                  SoriProgressMeter.bar(
                    value: progress.fraction,
                    label: '${progress.current} / ${progress.target}',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TodayError extends StatelessWidget {
  const _TodayError({required this.onRetry});
  final VoidCallback onRetry;
  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);
    final text = SoriTextTheme.of(context);
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(Spacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.refresh_rounded, size: 48),
            const SizedBox(height: Spacing.md),
            Text(
              t.homeLocalUnavailableTitle,
              style: text.h3,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: Spacing.sm),
            Text(
              t.homeLocalUnavailableDescriptionNoReview,
              style: text.body,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: Spacing.lg),
            SoriButton.outlined(
              label: t.homeUnavailableRetryGeneric,
              onTap: onRetry,
            ),
          ],
        ),
      ),
    );
  }
}
