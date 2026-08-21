import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import '../models/gye_dedication.dart';
import '../models/gye_weekly_promise.dart';
import '../l10n/gye_error_text.dart';
import '../l10n/generated/app_localizations.dart';
import '../models/gye.dart';
import '../services/account/cloud_write_session.dart';
import '../services/gye_dedication_service.dart';
import '../services/gye_service.dart';
import '../services/gye_weekly_promise_navigation.dart';
import '../services/pack_access.dart';
import '../services/storage_service.dart';
import '../services/today_learning_navigation.dart';
import '../services/today_learning_snapshot.dart';
import '../widgets/app_loading.dart';
import '../widgets/sori/app_bar.dart';
import '../widgets/sori/button.dart';
import '../widgets/sori/card.dart';
import '../widgets/sori/dure_board.dart';
import '../widgets/sori/dialog.dart';
import '../widgets/sori/empty_state.dart';
import '../widgets/sori/gye_dedication_action.dart';
import '../widgets/sori/gye_feed.dart';
import '../widgets/sori/gye_hanok.dart';
import '../widgets/sori/responsive.dart';
import '../widgets/sori/screen_background.dart';
import '../widgets/sori/screen_coach.dart';
import '../widgets/sori/sheet.dart';
import '../widgets/sori/spotlight_coach.dart';
import '../widgets/sori/standard_page.dart';
import '../widgets/sori/sticker_picker.dart';
import '../widgets/sori/toast.dart';
import '../widgets/sori/tokens.dart';
import '../widgets/sori/window_class.dart';

bool gyeActionsAvailable(CloudWriteSession? session) =>
    session != null && session.mode == CloudWriteMode.ready;

/// 계 마당 — 상단(이름·멤버수·주간 목표) / 중간(공동 한옥) / 하단(피드). plan §7.4.
/// (스티커 FAB·전송 = Tier 3d. 피드는 3e Cloud Function이 채움.)
class GyeScreen extends StatefulWidget {
  const GyeScreen({
    super.key,
    required this.gyeId,
    this.accountSessions,
    this.metaUpdates,
    this.memberUpdates,
    this.currentMemberUpdates,
    this.dedicationUpdates,
    this.blockedUidUpdates,
    this.feedUpdates,
    this.loadTodaySnapshot,
    this.resolvePromiseNavigation,
    this.ensureTodayPackAccess,
    this.openTodayRoute,
    this.onOpenMembers,
    this.onOpenSafeMessage,
    this.onOpenReaction,
    this.readOnlyPreview = false,
    this.enableCoach = true,
  });

  final String gyeId;
  final ValueListenable<CloudWriteSession?>? accountSessions;

  /// Read-only test seams. Production keeps every existing Gye stream.
  final Stream<GyeMeta?>? metaUpdates;
  final Stream<List<GyeMember>>? memberUpdates;
  final Stream<GyeMember?>? currentMemberUpdates;
  final Stream<List<GyeDedication>>? dedicationUpdates;
  final Stream<Set<String>>? blockedUidUpdates;
  final Stream<List<GyeFeedEvent>>? feedUpdates;

  /// Read-only seams used by widget tests and the integrated UX Gallery.
  /// Production keeps the shared Today loader and the catalog-backed resolver.
  final Future<TodayLearningSnapshot> Function()? loadTodaySnapshot;
  final Future<GyePromiseNavigationResolution> Function(
    GyeMeta meta,
    TodayLearningSnapshot today,
  )?
  resolvePromiseNavigation;
  final Future<bool> Function(String level)? ensureTodayPackAccess;
  final Future<void> Function(String route, Object? arguments)? openTodayRoute;
  final VoidCallback? onOpenMembers;

  /// Gallery-only action seams. They render the production controls while
  /// keeping every tap inside a deterministic, write-free preview boundary.
  final VoidCallback? onOpenSafeMessage;
  final ValueChanged<String>? onOpenReaction;
  final bool readOnlyPreview;
  final bool enableCoach;

  @override
  State<GyeScreen> createState() => _GyeScreenState();
}

class _GyeScreenState extends State<GyeScreen>
    with ScreenCoachMixin<GyeScreen> {
  // ── 코치마크 타겟 ──
  final GlobalKey _dureBoardKey = GlobalKey();
  final GlobalKey _fabKey = GlobalKey();

  // 계 데이터 로드 여부 — StreamBuilder가 첫 데이터를 받으면 true.
  bool _metaLoaded = false;
  bool _statsSynced = false;
  late final GyeDedicationService _dedicationService;
  String? _promiseNavigationKey;
  Future<GyePromiseNavigationResolution>? _promiseNavigation;

  @override
  String get coachId => 'gye';

  @override
  bool get coachReady => _metaLoaded;

  @override
  List<SpotlightStep> buildCoachSteps(BuildContext context) {
    final t = AppL10n.of(context);
    return [
      SpotlightStep(
        targetKey: _dureBoardKey,
        title: t.coachGyeStep1Title,
        body: t.coachGyeStep1Body,
        icon: Icons.groups_2_outlined,
      ),
      SpotlightStep(
        targetKey: _fabKey,
        title: t.coachGyeStep2Title,
        body: t.coachGyeStep2Body,
        icon: Icons.emoji_emotions_outlined,
      ),
    ];
  }

  @override
  void initState() {
    super.initState();
    _dedicationService = GyeDedicationService.production();
    if (widget.enableCoach) {
      scheduleCoach();
    }
    // 프로필 카드용 level/streak denormalize (best-effort, 진입 시 1회).
    // ignore: discarded_futures, unawaited_futures
  }

  Future<GyePromiseNavigationResolution> _navigationFor(GyeMeta meta) {
    final key = [
      meta.id,
      meta.weeklyPromiseSchemaVersion,
      meta.weeklyPromiseId,
      meta.weeklyPromiseTarget,
      meta.weeklyPromiseWeekKey,
    ].join(':');
    if (_promiseNavigationKey == key && _promiseNavigation != null) {
      return _promiseNavigation!;
    }
    _promiseNavigationKey = key;
    _promiseNavigation = _resolveNavigation(meta);
    return _promiseNavigation!;
  }

  Future<GyePromiseNavigationResolution> _resolveNavigation(
    GyeMeta meta,
  ) async {
    try {
      final loadToday =
          widget.loadTodaySnapshot ?? TodayLearningSnapshotLoader.load;
      final today = await loadToday();
      final resolve = widget.resolvePromiseNavigation;
      return resolve == null
          ? GyeWeeklyPromiseNavigation.load(meta: meta, today: today)
          : resolve(meta, today);
    } catch (_) {
      return const GyePromiseNavigationResolution(
        kind: GyePromiseNavigationKind.unavailable,
      );
    }
  }

  Future<void> _openPromiseNavigation(
    GyePromiseNavigationResolution resolution,
  ) async {
    final destination = resolution.destination;
    if (destination == null) {
      if (mounted) {
        soriNotice(context, AppL10n.of(context).gyeTodayUnavailable);
      }
      return;
    }
    final opened = await TodayLearningNavigation.open(
      destination,
      ensurePackAccess:
          widget.ensureTodayPackAccess ??
          (level) => ensurePackAccess(context, level: level),
      openRoute:
          widget.openTodayRoute ??
          (route, arguments) async {
            await Navigator.of(context).pushNamed(route, arguments: arguments);
          },
    );
    if (opened && mounted) {
      setState(() {
        _promiseNavigationKey = null;
        _promiseNavigation = null;
      });
    }
  }

  void _openMembers() {
    final override = widget.onOpenMembers;
    if (override != null) {
      override();
      return;
    }
    Navigator.of(context).pushNamed('/gye/members', arguments: widget.gyeId);
  }

  void _openSafeMessage(BuildContext context) {
    final previewAction = widget.onOpenSafeMessage;
    if (previewAction != null) {
      previewAction();
      return;
    }
    _openGyeStickerPicker(context, widget.gyeId);
  }

  void _openReaction(BuildContext context, String eventId) {
    final previewAction = widget.onOpenReaction;
    if (previewAction != null) {
      previewAction(eventId);
      return;
    }
    _openReactionPicker(context, widget.gyeId, eventId);
  }

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);
    final s = SoriSurfaces.of(context);
    return ValueListenableBuilder<CloudWriteSession?>(
      valueListenable:
          widget.accountSessions ?? cloudWriteSessionController.changes,
      builder: (context, accountSession, _) {
        final cloudActionsAvailable = gyeActionsAvailable(accountSession);
        final safeMessageAvailable =
            cloudActionsAvailable || widget.onOpenSafeMessage != null;
        final reactionAvailable =
            cloudActionsAvailable || widget.onOpenReaction != null;
        if (cloudActionsAvailable && !_statsSynced) {
          _statsSynced = true;
          // ignore: discarded_futures, unawaited_futures
          GyeService.syncMyMemberStats();
        }
        return StreamBuilder<GyeMeta?>(
          stream: widget.metaUpdates ?? GyeService.metaStream(widget.gyeId),
          builder: (context, snap) {
            if (snap.connectionState == ConnectionState.waiting &&
                !snap.hasData) {
              return SoriStandardFrame(
                appBarTitle: t.gyeTitle,
                maxWidth: SoriMaxWidth.hub,
                builder: (context, padding) =>
                    Padding(padding: padding, child: const AppLoading()),
              );
            }
            final meta = snap.data;
            if (meta == null) {
              return SoriStandardFrame(
                appBarTitle: t.gyeTitle,
                maxWidth: SoriMaxWidth.hub,
                builder: (context, padding) => Padding(
                  padding: padding,
                  child: Center(
                    child: SoriEmptyState(
                      asset: 'assets/illustrations/mascot/magpie_perched.png',
                      icon: Icons.groups_2_outlined,
                      title: t.gyeNotFoundTitle,
                      body: t.gyeNotFoundBody,
                    ),
                  ),
                ),
              );
            }
            // 첫 meta 수신 시 coachReady 게이트 열기
            if (!_metaLoaded) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted && !_metaLoaded) {
                  setState(() => _metaLoaded = true);
                }
              });
            }
            return Scaffold(
              appBar: SoriAppBar(
                title: meta.name,
                textScale: MediaQuery.textScalerOf(context).scale(1),
                viewportWidth: MediaQuery.sizeOf(context).width,
                adaptTitleAtNormalScale: true,
                actions: [
                  Center(
                    child: Text(
                      t.gyeMembersN(meta.memberCount),
                      style: SoriTextTheme.of(
                        context,
                      ).label.copyWith(color: s.textMuted),
                    ),
                  ),
                  PopupMenuButton<String>(
                    enabled: cloudActionsAvailable,
                    onSelected: (v) {
                      if (v == 'invite') {
                        _shareGyeCode(context, meta.code);
                      } else if (v == 'leave') {
                        confirmLeaveGye(context, widget.gyeId);
                      } else if (v == 'members') {
                        Navigator.of(
                          context,
                        ).pushNamed('/gye/members', arguments: widget.gyeId);
                      }
                    },
                    itemBuilder: (_) => [
                      PopupMenuItem(
                        value: 'invite',
                        child: Text(t.gyeShareCode),
                      ),
                      PopupMenuItem(
                        value: 'members',
                        child: Text(t.gyeMembersTitle),
                      ),
                      if (meta.ownerId != GyeService.currentUid)
                        PopupMenuItem(value: 'leave', child: Text(t.gyeLeave)),
                      if (meta.ownerId == GyeService.currentUid)
                        PopupMenuItem(
                          enabled: false,
                          child: Text(t.gyeOwnerLeaveUnavailable),
                        ),
                    ],
                  ),
                ],
              ),
              body: SoriScreenBackground(
                child: SafeArea(
                  top: false,
                  child: SoriCenterClamp(
                    maxWidth: SoriMaxWidth.hub,
                    child: CustomScrollView(
                      slivers: [
                        SliverToBoxAdapter(
                          child: Column(
                            children: [
                              if (!cloudActionsAvailable &&
                                  !widget.readOnlyPreview)
                                Padding(
                                  padding: const EdgeInsets.fromLTRB(
                                    Spacing.lg,
                                    Spacing.md,
                                    Spacing.lg,
                                    0,
                                  ),
                                  child: Semantics(
                                    liveRegion: true,
                                    child: Container(
                                      padding: const EdgeInsets.all(Spacing.md),
                                      decoration: BoxDecoration(
                                        color: SoriColors.gold.withValues(
                                          alpha: 0.12,
                                        ),
                                        borderRadius: SoriRadius.brMd,
                                      ),
                                      child: Row(
                                        children: [
                                          const Icon(
                                            Icons.sync_lock_rounded,
                                            color: SoriColors.gold,
                                          ),
                                          const SizedBox(width: Spacing.sm),
                                          Expanded(
                                            child: Text(
                                              t.gyeAccountTransitionPaused,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              // 솔로 계(멤버 1) → 초대 유도. 협력 기능은 멤버가 있어야 산다.
                              Padding(
                                padding: const EdgeInsets.all(Spacing.lg),
                                child: _GyeWeeklyPromise(
                                  meta: meta,
                                  navigation: _navigationFor(meta),
                                  onOpenNavigation: _openPromiseNavigation,
                                  board:
                                      meta.weeklyPromiseSchemaVersion == 1 &&
                                          meta.weeklyPromiseId.isNotEmpty
                                      ? _GyeAnonymousPromiseProgress(meta: meta)
                                      : KeyedSubtree(
                                          key: _dureBoardKey,
                                          child: DureBoard(
                                            gyeId: widget.gyeId,
                                            meta: meta,
                                            myUid: GyeService.currentUid,
                                            writesAvailable:
                                                cloudActionsAvailable,
                                            showPausedReason: false,
                                            memberUpdates: widget.memberUpdates,
                                          ),
                                        ),
                                ),
                              ),
                              // Keep the shared learning promise ahead of the
                              // optional invitation.  A new group should first
                              // explain what it is for, not ask for a member.
                              if (meta.memberCount <= 1)
                                Padding(
                                  padding: const EdgeInsets.fromLTRB(
                                    Spacing.lg,
                                    0,
                                    Spacing.lg,
                                    Spacing.lg,
                                  ),
                                  child: _SoloInviteCard(
                                    code: meta.code,
                                    enabled: cloudActionsAvailable,
                                  ),
                                ),
                              Padding(
                                padding: EdgeInsets.fromLTRB(
                                  Spacing.lg,
                                  0,
                                  Spacing.lg,
                                  Spacing.md,
                                ),
                                child: _GyeCourtyardContext(meta: meta),
                              ),
                              LayoutBuilder(
                                builder: (context, c) {
                                  final h = (c.maxWidth * 0.72).clamp(
                                    280.0,
                                    380.0,
                                  );
                                  return SizedBox(
                                    height: h,
                                    child: StreamBuilder<GyeMember?>(
                                      stream:
                                          widget.currentMemberUpdates ??
                                          GyeService.currentMemberStream(
                                            widget.gyeId,
                                          ),
                                      builder: (context, memberSnapshot) {
                                        final currentMember =
                                            memberSnapshot.data;
                                        final currentMembershipEpoch =
                                            currentMember?.joinedAtEpoch;
                                        return StreamBuilder<
                                          List<GyeDedication>
                                        >(
                                          stream:
                                              widget.dedicationUpdates ??
                                              GyeDedicationService.streamForGye(
                                                widget.gyeId,
                                              ),
                                          builder: (context, dedicationSnapshot) {
                                            final dedications =
                                                dedicationSnapshot.data ??
                                                const <GyeDedication>[];
                                            return Stack(
                                              children: [
                                                Positioned.fill(
                                                  child: GyeHanok(
                                                    meta: meta,
                                                    dedications: dedications,
                                                  ),
                                                ),
                                                if (currentMember != null &&
                                                    currentMembershipEpoch !=
                                                        null)
                                                  Positioned(
                                                    top: Spacing.sm,
                                                    right: Spacing.sm,
                                                    child: GyeDedicationAction(
                                                      gyeId: widget.gyeId,
                                                      ownedDecor:
                                                          Storage.ownedDecor,
                                                      current:
                                                          currentGyeDedicationFor(
                                                            dedications,
                                                            GyeService
                                                                .currentUid,
                                                            currentMember
                                                                .membershipId,
                                                            currentMembershipEpoch,
                                                          ),
                                                      expectedMembershipId:
                                                          currentMember
                                                              .membershipId,
                                                      expectedMembershipEpoch:
                                                          currentMembershipEpoch,
                                                      actionsAvailable:
                                                          cloudActionsAvailable,
                                                      onCommit: _dedicationService
                                                          .setForCurrentSession,
                                                    ),
                                                  ),
                                              ],
                                            );
                                          },
                                        );
                                      },
                                    ),
                                  );
                                },
                              ),
                              Padding(
                                padding: const EdgeInsets.fromLTRB(
                                  Spacing.lg,
                                  Spacing.md,
                                  Spacing.lg,
                                  0,
                                ),
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    SoriButton.filled(
                                      key: const ValueKey('gye-safe-message'),
                                      label: t.gyeSafeMessage,
                                      icon: Icons.emoji_emotions_outlined,
                                      accent: SoriColors.gold,
                                      fullWidth: true,
                                      onTap: safeMessageAvailable
                                          ? () => _openSafeMessage(context)
                                          : null,
                                    ),
                                    TextButton(
                                      key: const ValueKey('gye-rules-members'),
                                      onPressed: _openMembers,
                                      style: TextButton.styleFrom(
                                        minimumSize: const Size(48, 48),
                                      ),
                                      child: Text(t.gyeRulesAndMembers),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(
                              Spacing.lg,
                              Spacing.md,
                              Spacing.lg,
                              Spacing.xs,
                            ),
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                t.gyeFeedTitle,
                                style: SoriTextTheme.of(context).label,
                              ),
                            ),
                          ),
                        ),
                        SliverToBoxAdapter(
                          // 차단한 멤버의 이벤트는 숨김 (Play UGC — 사용자 주도).
                          child: StreamBuilder<Set<String>>(
                            stream:
                                widget.blockedUidUpdates ??
                                GyeService.blockedUidsStream(),
                            builder: (context, bsnap) =>
                                StreamBuilder<List<GyeFeedEvent>>(
                                  stream:
                                      widget.feedUpdates ??
                                      GyeService.feedStream(widget.gyeId),
                                  builder: (context, fsnap) => GyeFeed(
                                    events: GyeService.filterBlocked(
                                      fsnap.data ?? const [],
                                      bsnap.data ?? const {},
                                    ),
                                    onReact: reactionAvailable
                                        ? (eventId) =>
                                              _openReaction(context, eventId)
                                        : null,
                                    shrinkWrap: true,
                                  ),
                                ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              floatingActionButton: FloatingActionButton(
                key: _fabKey,
                onPressed: safeMessageAvailable
                    ? () => _openSafeMessage(context)
                    : null,
                backgroundColor: SoriColors.primary,
                tooltip: t.gyeSafeMessage,
                child: const Icon(Icons.emoji_emotions_outlined),
              ),
            );
          },
        );
      },
    );
  }
}

/// Returns the current user's active exhibit from an already validated stream.
///
/// The Gye screen does not infer ownership from this data: it is purely the
/// visible server snapshot used to form a compare-and-set request.
GyeDedication? currentGyeDedicationFor(
  Iterable<GyeDedication> dedications,
  String? uid,
  String? membershipId,
  GyeMembershipEpoch? joinedAtEpoch,
) {
  if (uid == null ||
      uid.isEmpty ||
      membershipId == null ||
      membershipId.isEmpty ||
      joinedAtEpoch == null) {
    return null;
  }
  for (final dedication in dedications) {
    if (dedication.uid == uid &&
        dedication.membershipId == membershipId &&
        dedication.joinedAtEpoch == joinedAtEpoch) {
      return dedication;
    }
  }
  return null;
}

/// 계 나가기 — 확인 후 탈퇴 + 홈 복귀. plan §7/9.
Future<void> confirmLeaveGye(
  BuildContext context,
  String gyeId, {
  Future<void> Function(String gyeId) leave = GyeService.leaveGye,
}) async {
  final t = AppL10n.of(context);
  final ok = await showSoriDialog<bool>(
    context: context,
    builder: (dctx) => SoriDialog(
      content: Text(t.gyeLeaveConfirm),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dctx, false),
          child: Text(t.btnCancel),
        ),
        TextButton(
          onPressed: () => Navigator.pop(dctx, true),
          child: Text(t.gyeLeave),
        ),
      ],
    ),
  );
  if (ok == true) {
    try {
      await leave(gyeId);
      if (context.mounted) {
        Navigator.of(context).pop();
      }
    } on GyeException catch (error) {
      if (context.mounted) {
        soriToast(context, gyeErrorMessage(t, error.error));
      }
    } catch (_) {
      if (context.mounted) {
        soriToast(context, t.gyeErrNetwork);
      }
    }
  }
}

/// 스티커 키보드 시트 → 선택 시 전송. 레이트 초과 시 스낵바. plan §8.2.
void _openGyeStickerPicker(BuildContext context, String gyeId) {
  final t = AppL10n.of(context);
  showSoriSheet<void>(
    context: context,
    // StickerPicker는 자체 TabBar+GridView 스크롤러 → 시트 스크롤 비활성.
    scrollable: false,
    builder: (sheetCtx) => StickerPicker(
      onPick: (code) async {
        Navigator.of(sheetCtx).pop();
        final ok = await GyeService.sendSticker(gyeId: gyeId, code: code);
        if (!ok && context.mounted) {
          soriToast(context, t.gyeStickerRateLimited);
        }
      },
    ),
  );
}

/// 피드 반응 스티커 시트 → 선택 시 특정 이벤트(targetEventId)에 반응 전송.
/// 일반 스티커 시트와 동일 UX, sendReaction으로 라우팅. plan §D-3.
void _openReactionPicker(
  BuildContext context,
  String gyeId,
  String targetEventId,
) {
  final t = AppL10n.of(context);
  showSoriSheet<void>(
    context: context,
    scrollable: false,
    builder: (sheetCtx) => StickerPicker(
      onPick: (code) async {
        Navigator.of(sheetCtx).pop();
        final ok = await GyeService.sendReaction(
          gyeId: gyeId,
          targetEventId: targetEventId,
          code: code,
        );
        if (!ok && context.mounted) {
          soriToast(context, t.gyeStickerRateLimited);
        }
      },
    ),
  );
}

/// 초대 코드 공유 — OS 공유 시트로 6자리 코드 전파. 계(契)는 멤버가 있어야 산다.
/// ⋮ 메뉴와 솔로 초대 카드 양쪽의 공통 진입점.
Future<void> _shareGyeCode(BuildContext context, String code) {
  return SharePlus.instance.share(
    ShareParams(text: AppL10n.of(context).gyeShareMessage(code)),
  );
}

/// 05B presents server-projected scene contributions anonymously. Legacy
/// groups retain their existing aggregate pack board until they are migrated.
class _GyeWeeklyPromise extends StatelessWidget {
  const _GyeWeeklyPromise({
    required this.meta,
    required this.board,
    required this.navigation,
    required this.onOpenNavigation,
  });

  final GyeMeta meta;
  final Widget board;
  final Future<GyePromiseNavigationResolution> navigation;
  final ValueChanged<GyePromiseNavigationResolution> onOpenNavigation;

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);
    final isLifePromise =
        meta.weeklyPromiseSchemaVersion == 1 && meta.weeklyPromiseId.isNotEmpty;
    return SoriCard(
      variant: SoriCardVariant.hero,
      accent: SoriColors.primary,
      tinted: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isLifePromise ? t.gyePromiseEyebrow : t.gyeWeeklyEyebrow,
            style: SoriTextTheme.of(context).label,
          ),
          const SizedBox(height: Spacing.xs),
          Text(
            isLifePromise
                ? _promiseTitle(t, meta.weeklyPromiseId)
                : t.gyeWeeklyTitle,
            style: SoriTextTheme.of(context).h3,
          ),
          const SizedBox(height: Spacing.xs),
          Text(
            isLifePromise ? t.gyePromiseBody : t.gyeWeeklyBody,
            style: SoriTextTheme.of(context).bodySmall,
          ),
          if (isLifePromise) ...[
            const SizedBox(height: Spacing.xs),
            Text(
              t.gyePromiseEligibility,
              style: SoriTextTheme.of(context).caption,
            ),
          ],
          const SizedBox(height: Spacing.md),
          board,
          const SizedBox(height: Spacing.md),
          FutureBuilder<GyePromiseNavigationResolution>(
            future: navigation,
            builder: (context, snapshot) {
              final resolution = snapshot.data;
              final eligible =
                  resolution?.kind == GyePromiseNavigationKind.eligibleScene;
              final unavailable =
                  resolution?.kind == GyePromiseNavigationKind.unavailable;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SoriButton.filled(
                    key: const ValueKey('gye-promise-primary'),
                    label: eligible
                        ? t.gyePromiseSceneCta
                        : t.gyeTodayFallbackCta,
                    fullWidth: true,
                    onTap: resolution == null || unavailable
                        ? null
                        : () => onOpenNavigation(resolution),
                  ),
                  if (unavailable) ...[
                    const SizedBox(height: Spacing.xs),
                    Text(
                      t.gyeTodayUnavailable,
                      textAlign: TextAlign.center,
                      style: SoriTextTheme.of(context).caption,
                    ),
                  ],
                ],
              );
            },
          ),
          TextButton(
            onPressed: () => _showPromiseIntention(context, meta),
            style: TextButton.styleFrom(minimumSize: const Size(48, 48)),
            child: Text(t.gyePromiseIntentionAction),
          ),
        ],
      ),
    );
  }

  String _promiseTitle(AppL10n t, String promiseId) => switch (promiseId) {
    GyeWeeklyPromises.cafeOrder => t.gyePromiseCafeOrderTitle,
    GyeWeeklyPromises.directions => t.gyePromiseDirectionsTitle,
    GyeWeeklyPromises.selfIntroduction => t.gyePromiseSelfIntroductionTitle,
    _ => t.gyeWeeklyTitle,
  };
}

Future<void> _showPromiseIntention(BuildContext context, GyeMeta meta) {
  final t = AppL10n.of(context);
  final title = switch (meta.weeklyPromiseId) {
    GyeWeeklyPromises.cafeOrder => t.gyePromiseCafeOrderTitle,
    GyeWeeklyPromises.directions => t.gyePromiseDirectionsTitle,
    GyeWeeklyPromises.selfIntroduction => t.gyePromiseSelfIntroductionTitle,
    _ => t.gyeWeeklyTitle,
  };
  return showSoriDialog<void>(
    context: context,
    builder: (dialogContext) => SoriDialog(
      title: Text(title),
      content: Text('${t.gyePromiseBody}\n\n${t.gyePromisePrivacyRule}'),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(),
          child: Text(t.btnClose),
        ),
      ],
    ),
  );
}

/// Intentionally reveals aggregate lantern state only: never a member list,
/// individual tally, answer, score, or ordering of participants.
class _GyeAnonymousPromiseProgress extends StatelessWidget {
  const _GyeAnonymousPromiseProgress({required this.meta});

  final GyeMeta meta;

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);
    final s = SoriSurfaces.of(context);
    // Remote group metadata is untrusted. The supported weekly promises use
    // three lights; keep a malformed payload from creating an unbounded list.
    final target = meta.weeklyPromiseTarget.clamp(1, 5).toInt();
    final progress = meta.weeklyPromiseProgress.clamp(0, target).toInt();
    final fraction = target > 0 ? progress / target : 0.0;
    return Semantics(
      label: t.gyePromiseProgress(progress, target),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            t.gyePromiseProgress(progress, target),
            style: SoriTextTheme.of(context).cardTitle,
          ),
          const SizedBox(height: Spacing.sm),
          ClipRRect(
            borderRadius: BorderRadius.circular(SoriRadius.pill),
            child: SizedBox(
              height: 12,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  ColoredBox(color: s.border),
                  FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: fraction,
                    child: const ColoredBox(color: SoriColors.gold),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: Spacing.sm),
          Text(
            t.gyePromiseRemaining((target - progress).clamp(0, target)),
            style: SoriTextTheme.of(context).bodySmall,
          ),
          const SizedBox(height: Spacing.md),
          for (var index = 0; index < target; index++) ...[
            _AnonymousContributionRow(complete: index < progress),
            if (index < target - 1) const SizedBox(height: Spacing.sm),
          ],
          const SizedBox(height: Spacing.md),
          Semantics(
            container: true,
            child: Container(
              padding: const EdgeInsets.all(Spacing.sm),
              decoration: BoxDecoration(
                color: SoriColors.primary.withValues(alpha: 0.08),
                borderRadius: SoriRadius.brSm,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.shield_outlined,
                    size: 20,
                    color: SoriColors.primary,
                  ),
                  const SizedBox(width: Spacing.sm),
                  Expanded(
                    child: Text(
                      t.gyePromisePrivacyRule,
                      style: SoriTextTheme.of(context).bodySmall,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AnonymousContributionRow extends StatelessWidget {
  const _AnonymousContributionRow({required this.complete});

  final bool complete;

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);
    final s = SoriSurfaces.of(context);
    final title = complete
        ? t.gyePromiseContributionCompleteTitle
        : t.gyePromiseContributionPendingTitle;
    final body = complete
        ? t.gyePromiseContributionCompleteBody
        : t.gyePromiseContributionPendingBody;
    return Semantics(
      container: true,
      label: '$title. $body',
      child: ExcludeSemantics(
        child: Container(
          padding: const EdgeInsets.all(Spacing.sm),
          decoration: BoxDecoration(
            color: complete
                ? SoriColors.gold.withValues(alpha: 0.12)
                : s.surfaceAlt,
            borderRadius: SoriRadius.brSm,
            border: Border.all(color: s.border),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                complete ? Icons.light_mode_rounded : Icons.circle_outlined,
                size: 22,
                color: complete ? SoriColors.gold : s.textDim,
              ),
              const SizedBox(width: Spacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: SoriTextTheme.of(context).label),
                    const SizedBox(height: Spacing.xs),
                    Text(body, style: SoriTextTheme.of(context).caption),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 05C heading; existing feed, stickers, reports and moderation stay below.
class _GyeCourtyardContext extends StatelessWidget {
  const _GyeCourtyardContext({required this.meta});

  final GyeMeta meta;

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);
    final text = SoriTextTheme.of(context);
    final lanterns =
        (meta.weeklyPromiseSchemaVersion == 1
                ? meta.weeklyPromiseProgress
                : meta.weeklyGoalProgress)
            .clamp(0, 5)
            .toInt();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(t.gyeCourtyardEyebrow, style: text.label),
        const SizedBox(height: Spacing.xs),
        Text(
          lanterns == 3
              ? t.gyeCourtyardLightsThree
              : t.gyeCourtyardLightsToday(lanterns),
          style: text.h3,
        ),
        const SizedBox(height: Spacing.xs),
        Text(t.gyeCourtyardTitle, style: text.bodySmall),
        const SizedBox(height: Spacing.xs),
        Text(t.gyeCourtyardBody, style: text.caption),
      ],
    );
  }
}

/// 솔로 계(멤버 1명) 초대 카드 — 빈 두레판을 "행동 가능한" 상태로 전환.
/// 비경쟁 협력 기능은 멤버가 있어야 의미가 있으므로, 가장 먼저 초대를 유도.

class _SoloInviteCard extends StatelessWidget {
  final String code;
  final bool enabled;
  const _SoloInviteCard({required this.code, required this.enabled});

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);
    final text = SoriTextTheme.of(context);
    return SoriCard(
      variant: SoriCardVariant.hero,
      accent: SoriColors.primary,
      tinted: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.group_add_outlined,
                size: 20,
                color: SoriColors.primary,
              ),
              const SizedBox(width: Spacing.sm),
              Expanded(child: Text(t.gyeInviteTitle, style: text.h3)),
            ],
          ),
          const SizedBox(height: Spacing.xs),
          Text(t.gyeInviteBody, style: text.bodySmall),
          const SizedBox(height: Spacing.md),
          LayoutBuilder(
            builder: (context, constraints) {
              final textScale = MediaQuery.textScalerOf(context).scale(1);
              final stackCode =
                  constraints.maxWidth < SoriAdaptiveWidth.criticalActionRow ||
                  textScale >= 1.6;
              final label = Text('${t.gyeCodeLabel}:', style: text.caption);
              final value = Text(
                code,
                style: text.h2.copyWith(letterSpacing: 3),
              );
              if (stackCode) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    label,
                    const SizedBox(height: Spacing.xs),
                    value,
                  ],
                );
              }
              return Row(
                children: [
                  Expanded(child: label),
                  const SizedBox(width: Spacing.xs),
                  value,
                ],
              );
            },
          ),
          const SizedBox(height: Spacing.md),
          SoriButton(
            label: t.gyeShareCode,
            accent: SoriColors.primary,
            fullWidth: true,
            onTap: enabled ? () => _shareGyeCode(context, code) : null,
          ),
        ],
      ),
    );
  }
}
