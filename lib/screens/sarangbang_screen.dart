import 'dart:async';

import 'package:flutter/material.dart';

import '../l10n/generated/app_localizations.dart';
import '../models/hanok_build_narrative.dart';
import '../models/personal_room.dart';
import '../services/decoration_reward_service.dart';
import '../services/hanok_build_narrative_service.dart';
import '../services/pack_access.dart';
import '../services/quest_tracker.dart';
import '../services/room_placement_service.dart';
import '../services/storage_service.dart';
import '../services/today_learning_navigation.dart';
import '../services/today_learning_snapshot.dart';
import '../widgets/app_error.dart';
import '../widgets/app_loading.dart';
import '../widgets/sori/button.dart';
import '../widgets/sori/card.dart';
import '../widgets/sori/mascot.dart';
import '../widgets/sori/pending_reward_card.dart';
import '../widgets/sori/personal_room_scene.dart';
import '../widgets/sori/responsive.dart';
import '../widgets/sori/screen_background.dart';
import '../widgets/sori/tokens.dart';

/// The Sarangbang is a deliberate return space: it shows what has arrived in
/// the room and how to arrange it. Home owns today's primary recommendation;
/// this screen only offers a quiet, optional route back to that same scene.
class SarangbangRoomState {
  final RoomPlacements placements;
  final Set<String> ownedDecor;
  final int openableBoxes;

  const SarangbangRoomState({
    this.placements = const {},
    this.ownedDecor = const {},
    this.openableBoxes = 0,
  });
}

class SarangbangStudyPreviewData {
  final TodayLearningSnapshot todaySnapshot;
  final HanokLearningReceipt receipt;
  final SarangbangRoomState room;

  const SarangbangStudyPreviewData({
    required this.todaySnapshot,
    required this.receipt,
    required this.room,
  });
}

class SarangbangStudyScreen extends StatefulWidget {
  final Future<TodayLearningSnapshot> Function()? loadTodaySnapshot;
  final Future<HanokLearningReceipt> Function()? loadLearningReceipt;
  final Future<SarangbangRoomState> Function()? loadRoomState;
  final Future<void> Function(TodayLearningSnapshot recommendation)?
  onOpenRecommendation;
  final SarangbangStudyPreviewData? preview;

  const SarangbangStudyScreen({
    super.key,
    this.loadTodaySnapshot,
    this.loadLearningReceipt,
    this.loadRoomState,
    this.onOpenRecommendation,
    this.preview,
  });

  /// Renders the production 03C screen from fixtures without reading or
  /// writing SharedPreferences, course state, rewards, or room placement.
  factory SarangbangStudyScreen.preview({
    Key? key,
    required TodayLearningSnapshot todaySnapshot,
    required HanokLearningReceipt receipt,
    SarangbangRoomState room = const SarangbangRoomState(),
    Future<void> Function(TodayLearningSnapshot recommendation)?
    onOpenRecommendation,
  }) => SarangbangStudyScreen(
    key: key,
    preview: SarangbangStudyPreviewData(
      todaySnapshot: todaySnapshot,
      receipt: receipt,
      room: room,
    ),
    onOpenRecommendation: onOpenRecommendation,
  );

  @override
  State<SarangbangStudyScreen> createState() => _SarangbangStudyScreenState();
}

class _SarangbangStudyScreenState extends State<SarangbangStudyScreen> {
  TodayLearningSnapshot? _snapshot;
  HanokLearningReceipt _receipt = const HanokLearningReceipt.empty();
  RoomPlacements _placements = const {};
  Set<String> _ownedDecor = const {};
  int _openableBoxes = 0; // 지금 열 수 있는 보자기 — 사랑방 발견 배너 게이트
  bool _loading = true;
  bool _loadFailed = false;

  @override
  void initState() {
    super.initState();
    final preview = widget.preview;
    if (preview == null) {
      _load();
      return;
    }
    _snapshot = preview.todaySnapshot;
    _receipt = preview.receipt;
    _placements = preview.room.placements;
    _ownedDecor = preview.room.ownedDecor;
    _openableBoxes = preview.room.openableBoxes;
    _loading = false;
  }

  SarangbangRoomState _readRoomSnapshot() {
    try {
      return SarangbangRoomState(
        placements: RoomPlacementService.sanitizeAll(Storage.roomPlacements),
        ownedDecor: Storage.ownedDecor.toSet(),
        openableBoxes: DecorationRewardService.openableBoxCount(),
      );
    } catch (_) {
      return const SarangbangRoomState();
    }
  }

  Future<SarangbangRoomState> _loadRoomState() async =>
      widget.loadRoomState == null
      ? _readRoomSnapshot()
      : widget.loadRoomState!();

  Future<void> _reloadRoomScene() async {
    final preview = widget.preview;
    final room = preview?.room ?? await _loadRoomState();
    if (!mounted) {
      return;
    }
    setState(() {
      _placements = room.placements;
      _ownedDecor = room.ownedDecor;
      _openableBoxes = room.openableBoxes;
    });
  }

  Future<void> _load() async {
    final preview = widget.preview;
    if (preview != null) {
      setState(() {
        _snapshot = preview.todaySnapshot;
        _receipt = preview.receipt;
        _placements = preview.room.placements;
        _ownedDecor = preview.room.ownedDecor;
        _openableBoxes = preview.room.openableBoxes;
        _loading = false;
        _loadFailed = false;
      });
      return;
    }
    setState(() {
      _loading = true;
      _loadFailed = false;
    });
    try {
      final load = widget.loadTodaySnapshot ?? TodayLearningSnapshotLoader.load;
      final receiptLoad =
          widget.loadLearningReceipt ?? HanokBuildNarrativeService.loadReceipt;
      final snapshotFuture = load();
      final receiptFuture = receiptLoad();
      final roomFuture = _loadRoomState();
      final snapshot = await snapshotFuture;
      final receipt = await receiptFuture;
      final room = await roomFuture;
      if (!mounted) {
        return;
      }
      setState(() {
        _snapshot = snapshot;
        _receipt = receipt;
        _placements = room.placements;
        _ownedDecor = room.ownedDecor;
        _openableBoxes = room.openableBoxes;
        _loading = false;
      });
      // 방금 학습 루트가 돌아왔다 — 그새 획득한 보자기를 생산한다(퀘스트 화면
      // 안 열어도). 렌더를 막지 않도록 fire-and-forget(best-effort 라 자체 오류를
      // 삼킨다). 동기화가 끝나면 새로 생긴 보자기가 배너에 바로 뜨도록 개수만 다시
      // 읽는다.
      if (widget.loadRoomState == null) {
        unawaited(
          QuestTracker.syncEarnedRewards().then((_) {
            if (!mounted) {
              return;
            }
            final boxes = DecorationRewardService.openableBoxCount();
            if (boxes != _openableBoxes) {
              setState(() => _openableBoxes = boxes);
            }
          }),
        );
      }
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _loading = false;
        _loadFailed = true;
      });
    }
  }

  Future<void> _openRecommendation() async {
    final snapshot = _snapshot;
    if (snapshot == null) {
      return;
    }
    final override = widget.onOpenRecommendation;
    if (override != null) {
      await override(snapshot);
      return;
    }

    if (!mounted) {
      return;
    }
    final opened = await TodayLearningNavigation.open(
      snapshot.destination,
      ensurePackAccess: (level) => ensurePackAccess(context, level: level),
      openRoute: (route, arguments) async {
        await Navigator.of(context).pushNamed(route, arguments: arguments);
      },
    );
    if (opened && mounted) {
      await _load();
    }
  }

  Future<void> _openFurnish() async {
    await Navigator.of(context).pushNamed('/sarangbang/furnish');
    if (mounted) {
      await _reloadRoomScene();
    }
  }

  Future<void> _openBojagi() async {
    await Navigator.of(context).pushNamed('/bojagi');
    if (!mounted) {
      return;
    }
    // 보자기를 열고 돌아왔다 — 방 장식과 남은 상자 수를 다시 읽는다.
    final room = widget.preview?.room ?? await _loadRoomState();
    if (!mounted) {
      return;
    }
    setState(() {
      _placements = room.placements;
      _ownedDecor = room.ownedDecor;
      _openableBoxes = room.openableBoxes;
    });
  }

  Future<void> _openCourtyard() async {
    await Navigator.of(context).pushNamed('/hanok');
  }

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);
    final s = SoriSurfaces.of(context);
    return Scaffold(
      backgroundColor: s.bg,
      appBar: AppBar(
        title: Text(t.sarangbangStudyTitle),
        actions: [
          IconButton(
            tooltip: t.hanokWorldTitle,
            icon: const Icon(Icons.account_balance_outlined),
            onPressed: () => Navigator.of(context).pushNamed('/hanok'),
          ),
          IconButton(
            tooltip: t.sarangbangStudyFurnish,
            icon: const Icon(Icons.chair_outlined),
            onPressed: _openFurnish,
          ),
        ],
      ),
      body: SoriScreenBackground(
        child: SafeArea(
          child: _loading
              ? const AppLoading()
              : _loadFailed
              ? AppError(message: t.courseMissionLoadError, onRetry: _load)
              : SoriContentClamp(
                  // A room scene and the learning CTA share a tablet row.
                  // This is deliberately wider than the default reading clamp;
                  // the decision below still uses the *actual* post-rail width.
                  maxWidth: 960,
                  base: const EdgeInsets.fromLTRB(
                    Spacing.lg,
                    Spacing.md,
                    Spacing.lg,
                    Spacing.xxxl,
                  ),
                  builder: (context, padding) => RefreshIndicator(
                    onRefresh: _load,
                    child: ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: padding,
                      children: [
                        const _SarangbangWelcome(),
                        const SizedBox(height: Spacing.lg),
                        // 발견 배너 — 열 수 있는 보자기가 있으면 학습하는 자리에서
                        // 바로 보인다(홈과 동일 카드). 없으면 렌더하지 않는다.
                        if (_openableBoxes > 0) ...[
                          PendingRewardCard(
                            count: _openableBoxes,
                            onOpen: _openBojagi,
                          ),
                          const SizedBox(height: Spacing.lg),
                        ],
                        LayoutBuilder(
                          builder: (context, constraints) {
                            final todayLink = KeyedSubtree(
                              key: const ValueKey('sarangbang-today-link'),
                              child: _SarangbangArrivalCard(receipt: _receipt),
                            );
                            final room = _SarangbangStudyScene(
                              placements: _placements,
                              owned: _ownedDecor,
                              expression: _receipt.latestSafeExpressionKo,
                            );
                            final furnishing = _SarangbangFurnishCard(
                              onFurnish: _openFurnish,
                            );

                            // This is an available-content threshold rather
                            // than a screen-width threshold: an AppShell rail
                            // consumes width on tablets.
                            if (constraints.maxWidth >= 640) {
                              return Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(flex: 11, child: room),
                                  const SizedBox(width: Spacing.lg),
                                  Expanded(
                                    flex: 9,
                                    child: Column(
                                      children: [
                                        todayLink,
                                        const SizedBox(height: Spacing.lg),
                                        furnishing,
                                      ],
                                    ),
                                  ),
                                ],
                              );
                            }
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                room,
                                const SizedBox(height: Spacing.lg),
                                todayLink,
                                const SizedBox(height: Spacing.lg),
                                furnishing,
                              ],
                            );
                          },
                        ),
                        const SizedBox(height: Spacing.lg),
                        _SarangbangReturnActions(
                          canOpenToday:
                              _snapshot?.pick != null ||
                              _snapshot?.destination != null,
                          onOpenToday: _openRecommendation,
                          onReturnToCourtyard: _openCourtyard,
                        ),
                      ],
                    ),
                  ),
                ),
        ),
      ),
    );
  }
}

/// Unlike Home's mission hero, this card does not restate a competing next
/// action. It is only an arrival record; navigation stays after the room and
/// furnishing surfaces so this revisit does not duplicate the Home mission.
class _SarangbangArrivalCard extends StatelessWidget {
  const _SarangbangArrivalCard({required this.receipt});

  final HanokLearningReceipt receipt;

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);
    final text = SoriTextTheme.of(context);
    final expression = receipt.latestSafeExpressionKo;
    return SoriCard(
      variant: SoriCardVariant.base,
      child: expression == null || expression.trim().isEmpty
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(t.sarangbangStoredTitle, style: text.cardTitle),
                const SizedBox(height: Spacing.xs),
                Text(t.sarangbangStoredEmpty, style: text.cardSubtitle),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(t.sarangbangStoredTitle, style: text.cardTitle),
                const SizedBox(height: Spacing.xs),
                Text(
                  t.sarangbangStoredRecord(
                    receipt.earnedExpressionCount,
                    receipt.safeSceneCount,
                    receipt.plannedBeamCount,
                  ),
                  style: text.cardSubtitle,
                ),
              ],
            ),
    );
  }
}

class _SarangbangStudyScene extends StatelessWidget {
  final RoomPlacements placements;
  final Set<String> owned;
  final String? expression;

  const _SarangbangStudyScene({
    required this.placements,
    required this.owned,
    required this.expression,
  });

  @override
  Widget build(BuildContext context) {
    final text = SoriTextTheme.of(context);
    return Column(
      key: const ValueKey('sarangbang-study-room'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AspectRatio(
          aspectRatio: 1.06,
          child: Stack(
            fit: StackFit.expand,
            children: [
              PersonalRoomScene(
                surface: PersonalRoomSurface.sarangbang,
                placements: placements,
                owned: owned,
                interactive: false,
              ),
              if (expression case final value?)
                if (value.trim().isNotEmpty)
                  Positioned(
                    left: Spacing.md,
                    right: Spacing.md,
                    bottom: Spacing.md,
                    child: Align(
                      alignment: Alignment.bottomLeft,
                      child: Container(
                        key: const ValueKey('sarangbang-earned-expression'),
                        padding: const EdgeInsets.symmetric(
                          horizontal: Spacing.sm,
                          vertical: Spacing.xs,
                        ),
                        decoration: BoxDecoration(
                          color: SoriSurfaces.of(
                            context,
                          ).surface.withValues(alpha: .94),
                          borderRadius: SoriRadius.brSm,
                          border: Border.all(
                            color: SoriColors.gold.withValues(alpha: .55),
                          ),
                        ),
                        child: Text(
                          value.trim(),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: text.label,
                        ),
                      ),
                    ),
                  ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SarangbangReturnActions extends StatelessWidget {
  const _SarangbangReturnActions({
    required this.canOpenToday,
    required this.onOpenToday,
    required this.onReturnToCourtyard,
  });

  final bool canOpenToday;
  final VoidCallback onOpenToday;
  final VoidCallback onReturnToCourtyard;

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);
    return Column(
      key: const ValueKey('sarangbang-return-actions'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (canOpenToday) ...[
          SoriButton.outlined(
            key: const ValueKey('sarangbang-open-today'),
            label: t.sarangbangOpenToday,
            fullWidth: true,
            onTap: onOpenToday,
          ),
          const SizedBox(height: Spacing.xs),
        ],
        SoriButton.ghost(
          key: const ValueKey('sarangbang-return-courtyard'),
          label: t.sarangbangReturnCourtyard,
          fullWidth: true,
          onTap: onReturnToCourtyard,
        ),
      ],
    );
  }
}

/// Furnishing is an optional return activity.  Keeping it in a separate card
/// prevents the room itself from being mistaken for a competing daily mission
/// while retaining the established room-editor route.
class _SarangbangFurnishCard extends StatelessWidget {
  const _SarangbangFurnishCard({required this.onFurnish});

  final VoidCallback onFurnish;

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);
    final text = SoriTextTheme.of(context);
    final s = SoriSurfaces.of(context);
    return SoriCard(
      key: const ValueKey('sarangbang-furnish-card'),
      variant: SoriCardVariant.compact,
      accent: SoriColors.gold,
      tinted: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(t.sarangbangFurnishTitle, style: text.cardTitle),
          const SizedBox(height: Spacing.xs),
          Text(
            t.sarangbangFurnishBody,
            style: text.bodySmall.copyWith(color: s.textMuted),
          ),
          const SizedBox(height: Spacing.md),
          SoriButton.outlined(
            key: const ValueKey('sarangbang-furnish-action'),
            label: t.sarangbangStudyFurnish,
            accent: SoriColors.gold,
            fullWidth: true,
            onTap: onFurnish,
          ),
        ],
      ),
    );
  }
}

class _SarangbangWelcome extends StatelessWidget {
  const _SarangbangWelcome();

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);
    final text = SoriTextTheme.of(context);
    return SoriCard(
      key: const ValueKey('sarangbang-welcome'),
      variant: SoriCardVariant.hanji,
      accent: SoriColors.primary,
      tinted: true,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  t.sarangbangStudySceneLabel,
                  style: text.label.copyWith(color: SoriColors.primary),
                ),
                const SizedBox(height: Spacing.xs),
                Text(t.sarangbangStudyIntroTitle, style: text.h3),
                const SizedBox(height: Spacing.xs),
                Text(t.sarangbangStudyIntroBody, style: text.bodySmall),
              ],
            ),
          ),
          const SizedBox(width: Spacing.md),
          const Mascot.tiger(
            emotion: MascotEmotion.thinking,
            size: 76,
            animate: false,
          ),
        ],
      ),
    );
  }
}
