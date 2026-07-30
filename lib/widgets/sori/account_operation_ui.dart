import 'package:flutter/material.dart';

import '../../l10n/generated/app_localizations.dart';
import '../../services/account/account_transition_coordinator.dart';
import '../../services/account/account_ui_operations.dart';
import 'tokens.dart';

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
  } catch (_) {
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
}) {
  final t = AppL10n.of(context);
  return showDialog<void>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(
        deletion ? t.accountDeletionPendingTitle : t.accountOperationRetryTitle,
      ),
      content: Text(
        deletion ? t.accountDeletionPendingBody : t.accountOperationRetryBody,
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
