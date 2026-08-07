import 'dart:async';

import 'package:flutter/material.dart';

import '../../l10n/generated/app_localizations.dart';
import '../../services/account/account_failure_diagnostics.dart';
import '../../services/account/account_transition_coordinator.dart';
import '../../services/account/account_ui_operations.dart';
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
  });

  final AccountUiOperations operations;
  final Future<void> Function()? retryLocalDeletion;
  final Future<void> Function()? onCompleted;

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
      if (!mounted) return;
      _source?.refreshPendingState();
    });
  }

  Future<void> _cancelPersisted(AccountUiPendingStateSource source) async {
    var failed = false;
    try {
      failed = !await widget.operations.cancelReplacement();
    } catch (_) {
      failed = true;
    }
    try {
      await source.refreshPendingState();
    } catch (_) {
      failed = true;
    }
    if (failed && mounted) {
      await showSafeAccountFailure(
        context,
        showSupport: true,
        retry: () => _cancelPersisted(source),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final source = _source;
    if (source == null) return const SizedBox.shrink();
    return ValueListenableBuilder<AccountUiPendingState>(
      valueListenable: source.pendingState,
      builder: (context, state, _) {
        if (state == AccountUiPendingState.loading ||
            state == AccountUiPendingState.none) {
          return const SizedBox.shrink();
        }
        final t = AppL10n.of(context);
        final deletion =
            state == AccountUiPendingState.deletionRemotePending ||
            state == AccountUiPendingState.deletionLocalCleanup;
        final blocked = state == AccountUiPendingState.blocked;
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(Spacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  deletion
                      ? t.accountDeletionPendingTitle
                      : blocked
                      ? t.accountOperationBlockedTitle
                      : t.accountOperationResumeTitle,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: Spacing.sm),
                Text(
                  deletion
                      ? t.accountDeletionPendingBody
                      : blocked
                      ? t.accountOperationBlockedBody
                      : t.accountOperationResumeBody,
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
                else if (!blocked)
                  Wrap(
                    spacing: Spacing.sm,
                    children: [
                      if (state == AccountUiPendingState.replacementCancellable)
                        TextButton(
                          onPressed: () => _cancelPersisted(source),
                          child: Text(t.accountOperationCancel),
                        ),
                      FilledButton(
                        onPressed: () => _resume(
                          context,
                          widget.operations,
                          widget.onCompleted,
                        ),
                        child: Text(t.accountOperationResume),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

Future<void> runConfirmedAccountLink(
  BuildContext context, {
  required AccountUiOperations operations,
  required AccountLinkProvider provider,
  Future<void> Function()? onCompleted,
}) async {
  final t = AppL10n.of(context);
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(t.accountSafeConnectTitle),
      content: Text(t.accountSafeConnectExplain),
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
        await onCompleted?.call();
      case AccountUiLinkCancelled():
        return;
      case AccountUiLinkBlocked():
        await _showBlocked(context, operations);
      case AccountUiLinkConflict(:final conflict):
        _showProgress(context, t.accountOperationInProgress);
        final result = await operations.confirmReplacement(conflict);
        if (!context.mounted) return;
        Navigator.of(context, rootNavigator: true).pop();
        await _presentTransitionResult(
          context,
          operations: operations,
          result: result,
          onCompleted: onCompleted,
        );
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
        onCompleted: onCompleted,
      ),
    );
  }
}

Future<void> showSafeAccountFailure(
  BuildContext context, {
  required Future<void> Function() retry,
  bool deletion = false,
  bool showSupport = false,
}) {
  final t = AppL10n.of(context);
  return showDialog<void>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(
        deletion ? t.accountDeletionPendingTitle : t.accountOperationRetryTitle,
      ),
      content: Text(
        [
          deletion ? t.accountDeletionPendingBody : t.accountOperationRetryBody,
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

Future<void> _presentTransitionResult(
  BuildContext context, {
  required AccountUiOperations operations,
  required AccountTransitionResult result,
  Future<void> Function()? onCompleted,
}) async {
  switch (result.status) {
    case AccountTransitionStatus.completed:
      await onCompleted?.call();
    case AccountTransitionStatus.targetVerificationFailed:
      await showSafeAccountFailure(
        context,
        retry: () => _resume(context, operations, onCompleted),
      );
    case AccountTransitionStatus.reconciliationPending:
    case AccountTransitionStatus.cleanupPending:
    case AccountTransitionStatus.activationPending:
      await _showResume(
        context,
        operations: operations,
        canCancel:
            result.status == AccountTransitionStatus.reconciliationPending,
        onCompleted: onCompleted,
      );
    case AccountTransitionStatus.blocked:
      await _showBlocked(context, operations);
  }
}

Future<void> _resume(
  BuildContext context,
  AccountUiOperations operations,
  Future<void> Function()? onCompleted,
) async {
  final t = AppL10n.of(context);
  _showProgress(context, t.accountOperationInProgress);
  try {
    final result = await operations.resumeReplacement();
    if (!context.mounted) return;
    Navigator.of(context, rootNavigator: true).pop();
    await _presentTransitionResult(
      context,
      operations: operations,
      result: result,
      onCompleted: onCompleted,
    );
  } catch (_) {
    if (!context.mounted) return;
    Navigator.of(context, rootNavigator: true).pop();
    await showSafeAccountFailure(
      context,
      retry: () => _resume(context, operations, onCompleted),
    );
  }
}

Future<void> _showResume(
  BuildContext context, {
  required AccountUiOperations operations,
  required bool canCancel,
  Future<void> Function()? onCompleted,
}) {
  final t = AppL10n.of(context);
  return showDialog<void>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(t.accountOperationResumeTitle),
      content: Text(t.accountOperationResumeBody),
      actions: [
        if (canCancel)
          TextButton(
            onPressed: () async {
              final nav = Navigator.of(dialogContext);
              try {
                final cancelled = await operations.cancelReplacement();
                if (!dialogContext.mounted) return;
                nav.pop();
                if (!cancelled && context.mounted) {
                  await showSafeAccountFailure(
                    context,
                    retry: () => _retryCancel(context, operations),
                  );
                }
              } catch (_) {
                if (!dialogContext.mounted) return;
                nav.pop();
                if (context.mounted) {
                  await showSafeAccountFailure(
                    context,
                    retry: () => _retryCancel(context, operations),
                  );
                }
              }
            },
            child: Text(t.accountOperationCancel),
          ),
        FilledButton(
          onPressed: () {
            Navigator.pop(dialogContext);
            _resume(context, operations, onCompleted);
          },
          child: Text(t.accountOperationResume),
        ),
      ],
    ),
  );
}

Future<void> _retryCancel(
  BuildContext context,
  AccountUiOperations operations,
) async {
  try {
    final cancelled = await operations.cancelReplacement();
    if (!cancelled && context.mounted) {
      await showSafeAccountFailure(
        context,
        retry: () => _retryCancel(context, operations),
      );
    }
  } catch (_) {
    if (context.mounted) {
      await showSafeAccountFailure(
        context,
        retry: () => _retryCancel(context, operations),
      );
    }
  }
}

Future<void> _showBlocked(
  BuildContext context,
  AccountUiOperations operations,
) {
  final t = AppL10n.of(context);
  return showDialog<void>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(t.accountOperationBlockedTitle),
      content: Text(
        '${t.accountOperationBlockedBody}\n\n${t.accountOperationSupportBody}',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext),
          child: Text(t.btnClose),
        ),
        FilledButton(
          onPressed: () {
            Navigator.pop(dialogContext);
            _resume(context, operations, null);
          },
          child: Text(t.accountOperationResume),
        ),
      ],
    ),
  );
}

void _showProgress(BuildContext context, String label) {
  showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (_) => Dialog(
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
