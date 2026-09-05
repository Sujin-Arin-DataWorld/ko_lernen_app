import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../l10n/generated/app_localizations.dart';
import '../../services/account/account_failure_diagnostics.dart';
import '../../services/account/account_failure_reason.dart';
import '../../services/account/account_switch_coordinator.dart';
import '../../services/account/account_transition_coordinator.dart';
import '../../services/account/account_ui_operations.dart';
import '../../services/account/cloud_backup_deletion.dart';
import '../../services/cloud_sync.dart';
import 'dialog.dart';
import 'tokens.dart';

class AccountNewLinkGuard extends StatefulWidget {
  const AccountNewLinkGuard({
    super.key,
    required this.operations,
    required this.builder,
  });

  final AccountUiOperations operations;
  final Widget Function(BuildContext context, bool available) builder;

  @override
  State<AccountNewLinkGuard> createState() => _AccountNewLinkGuardState();
}

class _AccountNewLinkGuardState extends State<AccountNewLinkGuard> {
  bool _initialRefreshComplete = false;
  int _refreshGeneration = 0;

  AccountUiPendingStateSource? get _source =>
      widget.operations is AccountUiPendingStateSource
      ? widget.operations as AccountUiPendingStateSource
      : null;

  @override
  void initState() {
    super.initState();
    _beginInitialRefresh();
  }

  @override
  void didUpdateWidget(covariant AccountNewLinkGuard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.operations != widget.operations) {
      _beginInitialRefresh();
    }
  }

  void _beginInitialRefresh() {
    final source = _source;
    if (source == null) return;
    _initialRefreshComplete = false;
    final generation = ++_refreshGeneration;
    // refreshPendingState() synchronously flips the shared static admission
    // notifier to `loading`. _beginInitialRefresh runs from initState and
    // didUpdateWidget — both build-phase — so notifying now would call setState
    // on sibling guards/panels mid-build. Defer to after the frame so the
    // shared notifier is only mutated between frames.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || generation != _refreshGeneration) return;
      unawaited(_completeInitialRefresh(source, generation));
    });
  }

  Future<void> _completeInitialRefresh(
    AccountUiPendingStateSource source,
    int generation,
  ) async {
    try {
      await source.refreshPendingState();
    } catch (_) {
      return;
    }
    if (!mounted || generation != _refreshGeneration) return;
    setState(() => _initialRefreshComplete = true);
  }

  @override
  Widget build(BuildContext context) {
    final source = _source;
    if (source == null) return widget.builder(context, true);
    return ValueListenableBuilder<AccountUiPendingState>(
      valueListenable: source.pendingState,
      builder: (context, state, _) {
        return widget.builder(
          context,
          _initialRefreshComplete && state == AccountUiPendingState.none,
        );
      },
    );
  }
}

class AccountPendingOperationPanel extends StatefulWidget {
  const AccountPendingOperationPanel({
    super.key,
    required this.operations,
    this.retryLocalDeletion,
    this.onCompleted,
    this.cloudDeletionState,
    this.resumeCloudDeletion,
    this.refreshOnMount = true,
  });

  final AccountUiOperations operations;
  final Future<void> Function()? retryLocalDeletion;
  final Future<void> Function()? onCompleted;

  /// When supplied, a `blocked` panel caused by a pending cloud-backup
  /// deletion journal names that journal and offers to resume it via
  /// [resumeCloudDeletion] instead of rendering a dead text card.
  final ValueListenable<CloudBackupDeletionJournalState>? cloudDeletionState;
  final Future<void> Function()? resumeCloudDeletion;

  /// Whether this panel owns the first persisted-state refresh.
  ///
  /// A parent that must refresh before this panel enters a lazy viewport can
  /// set this to false and perform the refresh from its own lifecycle.
  final bool refreshOnMount;

  @override
  State<AccountPendingOperationPanel> createState() =>
      _AccountPendingOperationPanelState();
}

class _AccountPendingOperationPanelState
    extends State<AccountPendingOperationPanel> {
  AccountUiPendingStateSource? get _source =>
      widget.operations is AccountUiPendingStateSource
      ? widget.operations as AccountUiPendingStateSource
      : null;

  @override
  void initState() {
    super.initState();
    // This panel mounts inside the Settings screen's lazy ListView layout, so
    // calling refreshPendingState() here would synchronously flip the shared
    // static notifier and mark sibling ValueListenableBuilders dirty mid-build.
    // Defer to after the frame. (See _beginInitialRefresh above.)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !widget.refreshOnMount) return;
      _source?.refreshPendingState();
    });
  }

  @override
  Widget build(BuildContext context) {
    final source = _source;
    if (source == null) return const SizedBox.shrink();
    return ValueListenableBuilder<AccountUiPendingState>(
      valueListenable: source.pendingState,
      builder: (context, state, _) {
        final cloudListenable = widget.cloudDeletionState;
        if (cloudListenable == null) {
          return _buildPanel(context, source, state, cloudPending: false);
        }
        return ValueListenableBuilder<CloudBackupDeletionJournalState>(
          valueListenable: cloudListenable,
          builder: (context, cloudState, _) => _buildPanel(
            context,
            source,
            state,
            cloudPending: cloudState == CloudBackupDeletionJournalState.pending,
          ),
        );
      },
    );
  }

  Widget _buildPanel(
    BuildContext context,
    AccountUiPendingStateSource source,
    AccountUiPendingState state, {
    required bool cloudPending,
  }) {
    if (state == AccountUiPendingState.loading ||
        state == AccountUiPendingState.none) {
      return const SizedBox.shrink();
    }
    final t = AppL10n.of(context);
    final deletion =
        state == AccountUiPendingState.deletionRemotePending ||
        state == AccountUiPendingState.deletionLocalCleanup;
    final blocked = state == AccountUiPendingState.blocked;
    final cloudResumable =
        blocked && cloudPending && widget.resumeCloudDeletion != null;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(Spacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              deletion
                  ? t.accountDeletionPendingTitle
                  : cloudResumable
                  ? t.accountLockedCloudDeletionTitle
                  : t.accountOperationBlockedTitle,
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: Spacing.sm),
            Text(
              deletion
                  ? t.accountDeletionPendingBody
                  : cloudResumable
                  ? t.accountLockedCloudDeletionBody
                  : t.accountOperationBlockedBody,
            ),
            const SizedBox(height: Spacing.md),
            if (deletion && widget.retryLocalDeletion != null)
              FilledButton(
                onPressed: () async {
                  await widget.retryLocalDeletion!();
                  await source.refreshPendingState();
                },
                child: Text(t.btnRetry),
              )
            else
              // A blocked card must never be a dead end: resume the pending
              // cloud deletion when that journal is the blocker, otherwise
              // re-read the durable state so a fixed cause can unlock it.
              FilledButton(
                onPressed: () async {
                  if (cloudResumable) {
                    await widget.resumeCloudDeletion!();
                  }
                  await source.refreshPendingState();
                },
                child: Text(
                  cloudResumable
                      ? t.accountLockedResumeNow
                      : t.accountLockedRefresh,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

Future<void> runConfirmedAccountLink(
  BuildContext context, {
  required AccountUiOperations operations,
  required AccountLinkProvider provider,
  bool additionalProvider = false,
  Future<void> Function()? onCompleted,
}) async {
  final t = AppL10n.of(context);
  final confirmed = await showSoriDialog<bool>(
    context: context,
    builder: (dialogContext) => SoriDialog(
      title: Text(
        additionalProvider
            ? t.accountAdditionalProviderTitle
            : t.accountSafeConnectTitle,
      ),
      content: Text(
        additionalProvider
            ? t.accountAdditionalProviderConsent
            : t.accountSafeConnectExplain,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext, false),
          child: Text(t.btnCancel),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(dialogContext, true),
          child: Text(t.accountSafeConnectConfirm),
        ),
      ],
    ),
  );
  if (confirmed != true || !context.mounted) return;

  _showProgress(context, t.accountOperationInProgress);
  try {
    final link = await operations.link(provider);
    if (!context.mounted) return;
    Navigator.of(context, rootNavigator: true).pop();
    switch (link) {
      case AccountUiLinkCompleted():
        // Auto-backup the full root document right after a successful link —
        // the first-link backfill only covers bookshelf + pack progress, so
        // without this the user's game stats never reach the cloud until a
        // manual Settings → Backup. Fire-and-forget: the completed link must
        // not wait on (or fail with) the backup. Runs after the admission
        // lane released (link() has returned), so it cannot deadlock.
        if (!additionalProvider) {
          unawaited(
            CloudSync.backup().catchError((Object error) {
              AccountFailureDiagnostics.log('link.autoBackupFailed', error);
            }),
          );
        }
        await onCompleted?.call();
      case AccountUiLinkCancelled():
        // 사용자가 직접 닫았다 — 이 경우에만 조용히 돌아간다.
        return;
      case AccountUiLinkUnavailable():
        // ⚠️ 예전에는 이 경로가 Cancelled 로 뭉개져 **아무 메시지도 없었다**.
        await _showLinkProblem(
          context,
          title: t.accountLinkUnavailableTitle,
          body: t.accountLinkUnavailableBody,
        );
      case AccountUiProviderCollision():
        await _showLinkProblem(
          context,
          title: t.accountProviderCollisionTitle,
          body: t.accountProviderCollisionBody,
        );
      case AccountUiAppleConfigurationMissing():
        await _showLinkProblem(
          context,
          title: t.accountLinkUnavailableTitle,
          body: t.accountAppleConfigurationBody,
        );
      case AccountUiLinkFailed(:final reason):
        await _showLinkProblem(
          context,
          title: switch (reason) {
            AccountUiLinkFailureReason.offline => t.accountLinkOfflineTitle,
            _ => t.accountLinkFailedTitle,
          },
          body: switch (reason) {
            AccountUiLinkFailureReason.offline => t.accountLinkOfflineBody,
            _ => t.accountLinkFailedBody,
          },
          retry: () => runConfirmedAccountLink(
            context,
            operations: operations,
            provider: provider,
            additionalProvider: additionalProvider,
            onCompleted: onCompleted,
          ),
        );
      case AccountUiLinkBlocked():
        final source = operations is AccountUiPendingStateSource
            ? operations as AccountUiPendingStateSource
            : null;
        await _showLockedAction(
          context,
          title: t.accountOperationBlockedTitle,
          body:
              '${t.accountOperationBlockedBody}\n\n${t.accountOperationSupportBody}',
          actionLabel: t.accountLockedRefresh,
          action: () async {
            await source?.refreshPendingState();
          },
        );
      case AccountUiLinkConflict(:final conflict):
        if (additionalProvider) {
          await _showLinkProblem(
            context,
            title: t.accountProviderCollisionTitle,
            body: t.accountProviderCollisionBody,
          );
          return;
        }
        final confirmedSwitch = await showSoriDialog<bool>(
          context: context,
          builder: (dialogContext) => SoriDialog(
            title: Text(t.accountSwitchTitle),
            content: Text(t.accountSwitchBody),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: Text(t.btnCancel),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(dialogContext, true),
                child: Text(t.accountSwitchConfirm),
              ),
            ],
          ),
        );
        if (confirmedSwitch != true || !context.mounted) return;
        _showProgress(context, t.accountOperationInProgress);
        final switchResult = await operations.switchToExisting(conflict);
        if (!context.mounted) return;
        Navigator.of(context, rootNavigator: true).pop();
        switch (switchResult.status) {
          case AccountSwitchStatus.completed:
            // Same as the completed-link branch above: the first-link
            // backfill only covers bookshelf + pack progress.
            unawaited(
              CloudSync.backup().catchError((Object error) {
                AccountFailureDiagnostics.log('link.autoBackupFailed', error);
              }),
            );
            await onCompleted?.call();
          case AccountSwitchStatus.mergeDeferred:
            // No CloudSync.backup() here — it would overwrite the unmerged
            // cloud copy before the next-launch merge runs.
            await _showLinkProblem(
              context,
              title: t.accountSwitchDeferredTitle,
              body: t.accountSwitchDeferredBody,
            );
            await onCompleted?.call();
          case AccountSwitchStatus.failed:
            await showSafeAccountFailure(
              context,
              retry: () => runConfirmedAccountLink(
                context,
                operations: operations,
                provider: provider,
                additionalProvider: additionalProvider,
                onCompleted: onCompleted,
              ),
            );
        }
    }
  } catch (error) {
    // ⚠️ 예전엔 `catch (_)` 였다. Google 연동이 실패해도 오류 객체를 통째로
    // 버려서, 실기기에서는 로그인 화면이 뜬 뒤 조용히 sign-out 되는 것만 보이고
    // **원인을 알 수 없었다**(2026-08-07: App Check 통과 후에도 연동 실패).
    // 삭제 경로(`settings_screen._runAccountDeletion`)와 같은 처리 —
    // 코드만 로그에 남기고 사용자 화면은 안전한 고정 문구 그대로.
    AccountFailureDiagnostics.log('link.failed', error);
    if (!context.mounted) return;
    Navigator.of(context, rootNavigator: true).pop();
    await showSafeAccountFailure(
      context,
      retry: () => runConfirmedAccountLink(
        context,
        operations: operations,
        provider: provider,
        additionalProvider: additionalProvider,
        onCompleted: onCompleted,
      ),
    );
  }
}

/// 연동이 취소가 **아닌** 이유로 끝났을 때 사용자에게 실제 원인을 알린다.
///
/// 새 UI 크롬(배지·필)을 만들지 않고 기존 AlertDialog 문법을 그대로 쓴다.
/// [retry] 가 있으면 재시도 버튼을 붙이고, 없으면(= 구조적으로 불가한 상태)
/// 확인만 제공한다 — 눌러도 같은 실패가 반복될 버튼을 주지 않는다.
Future<void> _showLinkProblem(
  BuildContext context, {
  required String title,
  required String body,
  Future<void> Function()? retry,
}) {
  final t = AppL10n.of(context);
  return showSoriDialog<void>(
    context: context,
    builder: (dialogContext) => SoriDialog(
      title: Text(title),
      content: Text(body),
      actions: [
        if (retry == null)
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(t.btnClose),
          )
        else ...[
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(t.btnCancel),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              retry();
            },
            child: Text(t.btnRetry),
          ),
        ],
      ],
    ),
  );
}

/// Explains why a locked account tile cannot act right now and offers the
/// matching escape instead of swallowing the tap.
///
/// Locked tiles keep a non-null onTap wired to this helper so the user always
/// learns which durable operation is pending and can resume/retry it here:
/// - pending cloud-backup deletion journal → resume that exact request
/// - pending account deletion → retry the same deletion
/// - replacement transition → existing resume/cancel dialog
/// - anything else (loading/blocked) → protected notice + status refresh
Future<void> showAccountActionLocked(
  BuildContext context, {
  required AccountUiOperations operations,
  required CloudBackupDeletionJournalState cloudDeletionState,
  Future<void> Function()? resumeCloudDeletion,
  Future<void> Function()? retryDeletion,
}) async {
  final t = AppL10n.of(context);
  final source = operations is AccountUiPendingStateSource
      ? operations as AccountUiPendingStateSource
      : null;
  final state = source?.pendingState.value ?? AccountUiPendingState.none;

  if (cloudDeletionState == CloudBackupDeletionJournalState.pending &&
      resumeCloudDeletion != null) {
    return _showLockedAction(
      context,
      title: t.accountLockedCloudDeletionTitle,
      body: t.accountLockedCloudDeletionBody,
      actionLabel: t.accountLockedResumeNow,
      action: resumeCloudDeletion,
    );
  }
  switch (state) {
    case AccountUiPendingState.deletionRemotePending:
    case AccountUiPendingState.deletionLocalCleanup:
      if (retryDeletion != null) {
        return _showLockedAction(
          context,
          title: t.accountDeletionPendingTitle,
          body: t.accountDeletionPendingBody,
          actionLabel: t.btnRetry,
          action: retryDeletion,
        );
      }
    case AccountUiPendingState.loading:
    case AccountUiPendingState.none:
    case AccountUiPendingState.blocked:
      break;
  }
  return _showLockedAction(
    context,
    title: t.accountOperationBlockedTitle,
    body:
        '${t.accountOperationBlockedBody}\n\n${t.accountOperationSupportBody}',
    actionLabel: t.accountLockedRefresh,
    action: () async {
      await source?.refreshPendingState();
    },
  );
}

Future<void> _showLockedAction(
  BuildContext context, {
  required String title,
  required String body,
  required String actionLabel,
  required Future<void> Function() action,
}) {
  final t = AppL10n.of(context);
  return showSoriDialog<void>(
    context: context,
    builder: (dialogContext) => SoriDialog(
      title: Text(title),
      content: Text(body),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext),
          child: Text(t.btnClose),
        ),
        FilledButton(
          onPressed: () {
            Navigator.pop(dialogContext);
            action();
          },
          child: Text(actionLabel),
        ),
      ],
    ),
  );
}

Future<void> showSafeAccountFailure(
  BuildContext context, {
  required Future<void> Function() retry,
  bool deletion = false,
  bool showSupport = false,
  AccountFailureReason? reason,
}) {
  final t = AppL10n.of(context);
  final reasonHint = switch (reason) {
    AccountFailureReason.appCheck => t.accountFailureReasonAppCheck,
    AccountFailureReason.offline => t.accountFailureReasonOffline,
    AccountFailureReason.unauthenticated => t.accountFailureReasonAuth,
    AccountFailureReason.serverBusy => t.accountFailureReasonServer,
    AccountFailureReason.unknown || null => null,
  };
  return showSoriDialog<void>(
    context: context,
    builder: (dialogContext) => SoriDialog(
      title: Text(
        deletion ? t.accountDeletionPendingTitle : t.accountOperationRetryTitle,
      ),
      content: Text(
        [
          deletion ? t.accountDeletionPendingBody : t.accountOperationRetryBody,
          if (reasonHint != null) reasonHint,
          if (showSupport) t.accountOperationSupportBody,
        ].join('\n\n'),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext),
          child: Text(t.btnCancel),
        ),
        FilledButton(
          onPressed: () {
            Navigator.pop(dialogContext);
            retry();
          },
          child: Text(t.btnRetry),
        ),
      ],
    ),
  );
}

void _showProgress(BuildContext context, String label) {
  showSoriDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (_) => SoriDialogFrame(
      child: Padding(
        padding: const EdgeInsets.all(Spacing.xl),
        child: Row(
          children: [
            const CircularProgressIndicator(),
            const SizedBox(width: Spacing.lg),
            Expanded(child: Text(label)),
          ],
        ),
      ),
    ),
  );
}
