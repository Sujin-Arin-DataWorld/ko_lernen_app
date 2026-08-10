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
import '../services/storage_service.dart';
import '../widgets/app_loading.dart';
import '../widgets/sori/button.dart';
import '../widgets/sori/card.dart';
import '../widgets/sori/dure_board.dart';
import '../widgets/sori/empty_state.dart';
import '../widgets/sori/gye_dedication_action.dart';
import '../widgets/sori/gye_feed.dart';
import '../widgets/sori/gye_hanok.dart';
import '../widgets/sori/responsive.dart';
import '../widgets/sori/screen_coach.dart';
import '../widgets/sori/sheet.dart';
import '../widgets/sori/spotlight_coach.dart';
import '../widgets/sori/sticker_picker.dart';
import '../widgets/sori/tokens.dart';

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
    scheduleCoach();
    // 프로필 카드용 level/streak denormalize (best-effort, 진입 시 1회).
    // ignore: discarded_futures, unawaited_futures
  }

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);
    final s = SoriSurfaces.of(context);
    return ValueListenableBuilder<CloudWriteSession?>(
      valueListenable:
          widget.accountSessions ?? cloudWriteSessionController.changes,
      builder: (context, accountSession, _) {
        final actionsAvailable = gyeActionsAvailable(accountSession);
        if (actionsAvailable && !_statsSynced) {
          _statsSynced = true;
          // ignore: discarded_futures, unawaited_futures
          GyeService.syncMyMemberStats();
        }
        return StreamBuilder<GyeMeta?>(
          stream: widget.metaUpdates ?? GyeService.metaStream(widget.gyeId),
          builder: (context, snap) {
            if (snap.connectionState == ConnectionState.waiting &&
                !snap.hasData) {
              return Scaffold(
                appBar: AppBar(title: Text(t.gyeTitle)),
                body: const AppLoading(),
              );
            }
            final meta = snap.data;
            if (meta == null) {
              return Scaffold(
                appBar: AppBar(title: Text(t.gyeTitle)),
                body: Center(
                  child: SoriEmptyState(
                    asset: 'assets/illustrations/mascot/magpie_perched.png',
                    icon: Icons.groups_2_outlined,
                    title: t.gyeNotFoundTitle,
                    body: t.gyeNotFoundBody,
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
              appBar: AppBar(
                title: Text(
                  meta.name,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                actions: [
                  Center(
                    child: Text(
                      t.gyeMembersN(meta.memberCount),
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: s.textMuted,
                      ),
                    ),
                  ),
                  PopupMenuButton<String>(
                    enabled: actionsAvailable,
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
              body: SafeArea(
                child: SoriCenterClamp(
                  child: CustomScrollView(
                    slivers: [
                      SliverToBoxAdapter(
                        child: Column(
                          children: [
                            if (!actionsAvailable)
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
                            if (meta.memberCount <= 1)
                              Padding(
                                padding: const EdgeInsets.fromLTRB(
                                  Spacing.lg,
                                  Spacing.lg,
                                  Spacing.lg,
                                  0,
                                ),
                                child: _SoloInviteCard(
                                  code: meta.code,
                                  enabled: actionsAvailable,
                                ),
                              ),
                            Padding(
                              padding: const EdgeInsets.all(Spacing.lg),
                              child: _GyeWeeklyPromise(
                                meta: meta,
                                onOpenToday: () => Navigator.of(context)
                                    .pushNamedAndRemoveUntil(
                                      '/',
                                      (route) => false,
                                    ),
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
                                          writesAvailable: actionsAvailable,
                                          showPausedReason: false,
                                          memberUpdates: widget.memberUpdates,
                                        ),
                                      ),
                              ),
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
                                      final currentMember = memberSnapshot.data;
                                      final currentMembershipEpoch =
                                          currentMember?.joinedAtEpoch;
                                      return StreamBuilder<List<GyeDedication>>(
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
                                                          GyeService.currentUid,
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
                                                        actionsAvailable,
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
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  const _GyeCourtyardContext(),
                                  const SizedBox(height: Spacing.md),
                                  SoriButton.outlined(
                                    key: const ValueKey('gye-safe-message'),
                                    label: t.gyeSafeMessage,
                                    icon: Icons.emoji_emotions_outlined,
                                    fullWidth: true,
                                    onTap: actionsAvailable
                                        ? () => _openGyeStickerPicker(
                                            context,
                                            widget.gyeId,
                                          )
                                        : null,
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
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                              ),
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
                                  onReact: actionsAvailable
                                      ? (eventId) => _openReactionPicker(
                                          context,
                                          widget.gyeId,
                                          eventId,
                                        )
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
              floatingActionButton: FloatingActionButton(
                key: _fabKey,
                onPressed: actionsAvailable
                    ? () => _openGyeStickerPicker(context, widget.gyeId)
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
  final ok = await showDialog<bool>(
    context: context,
    builder: (dctx) => AlertDialog(
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(gyeErrorMessage(t, error.error))),
        );
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(t.gyeErrNetwork)));
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
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(t.gyeStickerRateLimited)));
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
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(t.gyeStickerRateLimited)));
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
    required this.onOpenToday,
  });

  final GyeMeta meta;
  final Widget board;
  final VoidCallback onOpenToday;

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
          const SizedBox(height: Spacing.md),
          board,
          const SizedBox(height: Spacing.md),
          SoriButton.outlined(
            label: t.gyeOpenToday,
            fullWidth: true,
            onTap: onOpenToday,
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

/// Intentionally reveals aggregate lantern state only: never a member list,
/// individual tally, answer, score, or ordering of participants.
class _GyeAnonymousPromiseProgress extends StatelessWidget {
  const _GyeAnonymousPromiseProgress({required this.meta});

  final GyeMeta meta;

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);
    final s = SoriSurfaces.of(context);
    final target = meta.weeklyPromiseTarget;
    final progress = meta.weeklyPromiseProgress.clamp(0, target);
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
        ],
      ),
    );
  }
}

/// 05C heading; existing feed, stickers, reports and moderation stay below.
class _GyeCourtyardContext extends StatelessWidget {
  const _GyeCourtyardContext();

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);
    final text = SoriTextTheme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(t.gyeCourtyardEyebrow, style: text.label),
        const SizedBox(height: Spacing.xs),
        Text(t.gyeCourtyardTitle, style: text.h3),
        const SizedBox(height: Spacing.xs),
        Text(t.gyeCourtyardBody, style: text.bodySmall),
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
    final s = SoriSurfaces.of(context);
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
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  t.gyeInviteTitle,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            t.gyeInviteBody,
            style: TextStyle(fontSize: 13, height: 1.45, color: s.textMuted),
          ),
          const SizedBox(height: Spacing.md),
          Row(
            children: [
              Expanded(
                child: Text(
                  '${t.gyeCodeLabel}:',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 12, color: s.textMuted),
                ),
              ),
              const SizedBox(width: Spacing.xs),
              Text(
                code,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 3,
                ),
              ),
            ],
          ),
          const SizedBox(height: Spacing.md),
          SoriButton(
            label: t.gyeShareCode,
            icon: Icons.ios_share,
            accent: SoriColors.primary,
            fullWidth: true,
            onTap: enabled ? () => _shareGyeCode(context, code) : null,
          ),
        ],
      ),
    );
  }
}
