import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../models/course_mastery.dart';
import '../../models/gye.dart';
import '../../models/home_navigation_art.dart';
import '../../models/sori_stage_progression.dart';
import '../../services/account/cloud_write_session.dart';
import '../../services/catalog_history_lease.dart';
import '../../services/course_attempt_companion.dart';
import '../../services/course_progress_service.dart';
import '../../services/learning_focus.dart';
import '../../services/learning_journey.dart';
import '../../services/sori_stage_progression_service.dart';
import '../../services/sori_stage_reward_receipt_service.dart';
import '../../services/storage_service.dart';
import '../../services/today_learning_snapshot.dart';
import '../../widgets/sori/adaptive_navigation.dart';
import '../../widgets/sori/learning_focus.dart';
import '../../widgets/sori/route_observer.dart';
import '../../widgets/sori/tab_reselect.dart';
import '../../widgets/sori/toast.dart';
import 'sori_stage_catalog_screen.dart';
import 'sori_stage_gye_screen.dart';
import 'sori_stage_hanok_screen.dart';
import 'sori_stage_reward_receipt_sheet.dart';
import 'sori_stage_today_screen.dart';

class SoriStageShell extends StatefulWidget {
  const SoriStageShell({
    super.key,
    required this.replayHomeTour,
    this.requestedTab,
    this.loadTodaySnapshot,
    this.loadProgressionSnapshot,
    this.loadGyeMetas,
    this.loadLearningFocus,
    this.loadReceiptNetworkBefore,
    this.loadCompanionBefore,
  });

  final ValueListenable<int> replayHomeTour;
  final ValueNotifier<int>? requestedTab;

  /// Test seam for the Today tab's snapshot loader — see
  /// [SoriStageTodayScreen.loadSnapshot]. Production leaves this null (the
  /// tab loads via its own default `compute()`-backed loader).
  final Future<SoriStageProgressionSnapshot> Function()? loadTodaySnapshot;

  /// Optional aggregate loader for the other learning and Hanok tabs.
  /// Production keeps each tab's ordinary loader.
  final Future<SoriStageProgressionSnapshot> Function()?
  loadProgressionSnapshot;
  final Future<List<GyeMeta>> Function()? loadGyeMetas;

  /// Test seam for one already-assembled focus. Production uses the same
  /// [LearningFocus.load] path as Today and Learn.
  final Future<LearningFocus> Function()? loadLearningFocus;

  /// Optional receipt baseline loader; it never gates activity entry.
  final Future<SoriStageNetworkBeforeFields> Function()?
  loadReceiptNetworkBefore;

  /// Optional pre-attempt evidence capture; it never gates activity entry.
  final Future<CourseMasterySnapshot?> Function()? loadCompanionBefore;

  @override
  State<SoriStageShell> createState() => _SoriStageShellState();
}

class _SoriStageShellState extends State<SoriStageShell> with RouteAware {
  int _index = 0;
  late final LearningFocusController _focus;
  int _refreshGeneration = 0;
  int _accountGeneration = 0;
  ModalRoute<dynamic>? _route;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (route != _route) {
      soriRouteObserver.unsubscribe(this);
      _route = route;
      if (route != null) {
        soriRouteObserver.subscribe(this, route);
      }
    }
  }

  @override
  void didPopNext() {
    // Only a return to the shell invalidates outside-owner learning/settings.
    // Owned result sheets and companion routes are settled by _open itself.
    if (!mounted || _focus.launching) {
      return;
    }
    setState(() => _refreshGeneration++);
    unawaited(_focus.refresh(force: true));
  }

  void _refreshFocusForTab(int index) {
    if ((index == 0 || index == 1) && !_focus.launching) {
      unawaited(_focus.refresh());
    }
  }

  void _accountChanged() {
    if (!mounted) {
      return;
    }
    LearningJourneyObserver.forContext(context)?.cancel();
    _focus.lastJourneyResult = null;
    // A new account must not inherit a tab's completed FutureBuilder snapshot,
    // cached group list, selected construction history, or pending async read.
    setState(() {
      _accountGeneration++;
      _refreshGeneration++;
    });
    unawaited(_focus.refresh(force: true));
  }

  Future<void> _open(
    BuildContext callerContext,
    TodayLearningDestination destination, {
    LearningFocus? focus,
    String? activityId,
  }) async {
    if (!_focus.claimLaunch()) {
      return;
    }
    // Today's aggregate may replace the originating focus subtree while away.
    // The shell owns this journey and remains the presentation anchor.
    final context = this.context;
    final origin = ModalRoute.of(context);
    final observer = LearningJourneyObserver.forContext(context);
    final account = cloudWriteSessionController.current;
    final historyLease = CatalogHistoryLease.capture();
    final journey = origin == null ? null : observer?.begin(origin);
    try {
      final unit = focus?.brief?.unit;
      Set<String>? evidenceIdsBefore;
      if (unit != null) {
        // Enqueue the read before navigation and therefore before this
        // activity's serialized course writes. A missing/failed/pending
        // capture must not turn historical evidence into a new success.
        unawaited(
          Future<CourseMasterySnapshot?>.sync(
            widget.loadCompanionBefore ??
                CourseProgressService.shared.readForDisplay,
          ).then<void>((snapshot) {
            if (snapshot != null) {
              evidenceIdsBefore = snapshot.evidence
                  .map((item) => item.id)
                  .toSet();
            }
          }, onError: (Object _, StackTrace __) {}),
        );
      }
      if (!context.mounted || account != cloudWriteSessionController.current) {
        observer?.cancel();
        return;
      }
      final receipt = await SoriStageRewardReceiptService.capture(
        activityId: activityId ?? 'today',
        confirmedRewardMoments: () => journey?.rewardMoments ?? const [],
        pendingRewardMoments: () => journey?.pendingRewards ?? const [],
        loadNetworkBefore: widget.loadReceiptNetworkBefore,
        loadSnapshot: () => SoriStageProgressionService.load().timeout(
          const Duration(seconds: 5),
        ),
        openActivity: () async {
          final firstReturn = Navigator.of(
            context,
            rootNavigator: true,
          ).pushNamed(destination.route, arguments: destination.arguments);
          if (activityId != null) {
            unawaited(
              Storage.recordCatalogActivity(activityId, lease: historyLease),
            );
          }
          if (journey == null) {
            await firstReturn;
          } else {
            await journey.returned;
            if (!journey.cancelled) {
              await journey.settle();
            }
          }
          if (mounted &&
              journey?.cancelled != true &&
              account == cloudWriteSessionController.current) {
            if (journey != null) {
              _focus.recordReturn(journey.result);
            }
            setState(() => _refreshGeneration++);
            unawaited(_focus.refresh(force: true));
          }
        },
      );
      if (!mounted ||
          !context.mounted ||
          origin?.isCurrent != true ||
          journey?.cancelled == true ||
          account != cloudWriteSessionController.current) {
        return;
      }
      final remaining = receipt == null
          ? null
          : journey?.unshown(receipt) ?? receipt;
      if (remaining != null && !remaining.isEmpty) {
        await showSoriStageRewardReceipt(context, remaining);
      }
      final focusedUnitOfferAlreadyQueued =
          unit != null && journey?.afterReturn.containsKey(unit.id) == true;
      if (journey != null) {
        for (final offer in journey.afterReturn.values) {
          if (!mounted ||
              !context.mounted ||
              account != cloudWriteSessionController.current ||
              origin?.isCurrent != true) {
            return;
          }
          await offer(context);
        }
      }
      final capturedEvidence = evidenceIdsBefore;
      if (unit != null &&
          !focusedUnitOfferAlreadyQueued &&
          capturedEvidence != null &&
          mounted &&
          context.mounted &&
          account == cloudWriteSessionController.current &&
          origin?.isCurrent == true) {
        await CourseAttemptCompanion.offer(
          context,
          unit: unit,
          evidenceIdsBefore: capturedEvidence,
        );
      }
    } catch (_) {
      if (context.mounted) {
        soriToast(context, AppL10n.of(context).loadErrorTryAgain);
      }
    } finally {
      if (identical(observer?.active, journey)) {
        observer?.cancel();
      }
      _focus.releaseLaunch();
    }
  }

  final _scrollControllers = List.generate(5, (_) => ScrollController());

  @override
  void initState() {
    super.initState();
    _focus = LearningFocusController(
      loader:
          widget.loadLearningFocus ??
          (widget.loadTodaySnapshot == null
              ? null
              : () async => LearningFocus.load(
                  loadToday: () async =>
                      (await widget.loadTodaySnapshot!()).today,
                )),
    );
    unawaited(_focus.refresh());
    cloudWriteSessionController.changes.addListener(_accountChanged);
    widget.replayHomeTour.addListener(_onReplayRequested);
    widget.requestedTab?.addListener(_onTabRequested);
    WidgetsBinding.instance.addPostFrameCallback((_) => _onTabRequested());
  }

  @override
  void didUpdateWidget(covariant SoriStageShell oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.loadTodaySnapshot != widget.loadTodaySnapshot ||
        oldWidget.loadLearningFocus != widget.loadLearningFocus) {
      unawaited(_focus.refresh(force: true));
    }
    if (oldWidget.replayHomeTour != widget.replayHomeTour) {
      oldWidget.replayHomeTour.removeListener(_onReplayRequested);
      widget.replayHomeTour.addListener(_onReplayRequested);
    }
    if (oldWidget.requestedTab != widget.requestedTab) {
      oldWidget.requestedTab?.removeListener(_onTabRequested);
      widget.requestedTab?.addListener(_onTabRequested);
    }
  }

  @override
  void dispose() {
    soriRouteObserver.unsubscribe(this);
    cloudWriteSessionController.changes.removeListener(_accountChanged);
    _focus.dispose();
    widget.replayHomeTour.removeListener(_onReplayRequested);
    widget.requestedTab?.removeListener(_onTabRequested);
    for (final controller in _scrollControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _onReplayRequested() {
    if (!mounted) {
      return;
    }
    setState(() => _index = 0);
    _refreshFocusForTab(0);
  }

  void _onTabRequested() {
    final notifier = widget.requestedTab;
    if (!mounted || notifier == null) {
      return;
    }
    final requested = notifier.value;
    if (requested < 0 || requested >= _scrollControllers.length) {
      return;
    }
    final changed = _index != requested;
    setState(() => _index = requested);
    if (changed) {
      _refreshFocusForTab(requested);
    }
    notifier.value = -1;
  }

  void _select(int index) {
    if (_index == index) {
      reselectTabScroll(
        _scrollControllers[index],
        reduceMotion: MediaQuery.maybeOf(context)?.disableAnimations ?? false,
      );
      return;
    }
    setState(() => _index = index);
    _refreshFocusForTab(index);
  }

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);
    final width = MediaQuery.sizeOf(context).width;
    final textScale = MediaQuery.textScalerOf(context).scale(14) / 14;
    final usesRail = SoriAdaptiveNavigation.usesRailForWidth(width);
    final navigation = SoriAdaptiveNavigation(
      imageOnly: true,
      selectedIndex: _index,
      onDestinationSelected: _select,
      items: [
        SoriAdaptiveNavigationItem(
          icon: Icons.today_outlined,
          selectedIcon: Icons.today_rounded,
          artworkAsset: HomeNavigationArt.today,
          label: t.soriStageNavToday,
        ),
        SoriAdaptiveNavigationItem(
          icon: Icons.school_outlined,
          selectedIcon: Icons.school_rounded,
          artworkAsset: HomeNavigationArt.learn,
          label: t.soriStageNavLearn,
        ),
        SoriAdaptiveNavigationItem(
          icon: Icons.sports_esports_outlined,
          selectedIcon: Icons.sports_esports_rounded,
          artworkAsset: HomeNavigationArt.games,
          label: t.soriStageNavGames,
        ),
        SoriAdaptiveNavigationItem(
          icon: Icons.home_work_outlined,
          selectedIcon: Icons.home_work_rounded,
          artworkAsset: HomeNavigationArt.hanok,
          label: t.soriStageNavHanok,
        ),
        SoriAdaptiveNavigationItem(
          icon: Icons.groups_2_outlined,
          selectedIcon: Icons.groups_2_rounded,
          artworkAsset: HomeNavigationArt.gye,
          label: t.soriStageNavGye,
        ),
      ],
    );
    final screens = [
      SoriStageTodayScreen(
        replayHomeTour: widget.replayHomeTour,
        active: _index == 0,
        refreshGeneration: _refreshGeneration,
        loadSnapshot: widget.loadTodaySnapshot,
      ),
      SoriStageCatalogScreen(
        tab: SoriStageTab.learn,
        active: _index == 1,
        refreshGeneration: _refreshGeneration,
        loadSnapshot: widget.loadProgressionSnapshot,
      ),
      SoriStageCatalogScreen(
        tab: SoriStageTab.games,
        active: _index == 2,
        refreshGeneration: _refreshGeneration,
        loadSnapshot: widget.loadProgressionSnapshot,
      ),
      SoriStageHanokScreen(
        active: _index == 3,
        refreshGeneration: _refreshGeneration,
        loadSnapshot: widget.loadProgressionSnapshot,
      ),
      SoriStageGyeScreen(
        onContinueSolo: () => _select(0),
        active: _index == 4,
        refreshGeneration: _refreshGeneration,
        loadGyeMetas: widget.loadGyeMetas,
      ),
    ];

    return LearningFocusScope(
      controller: _focus,
      open: _open,
      child: Scaffold(
        body: Row(
          children: [
            if (usesRail)
              SafeArea(
                child: SizedBox(
                  width: SoriAdaptiveNavigation.railWidthForWidth(
                    width,
                    textScale: textScale,
                    imageOnly: true,
                  ),
                  child: navigation,
                ),
              ),
            Expanded(
              child: IndexedStack(
                index: _index,
                children: [
                  for (var index = 0; index < screens.length; index++)
                    PrimaryScrollController(
                      controller: _scrollControllers[index],
                      child: TickerMode(
                        enabled: _index == index,
                        child: KeyedSubtree(
                          key: ValueKey(
                            'c-account-$_accountGeneration-tab-$index',
                          ),
                          child: screens[index],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
        bottomNavigationBar: usesRail ? null : navigation,
      ),
    );
  }
}
