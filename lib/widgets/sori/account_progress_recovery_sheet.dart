import 'package:flutter/material.dart';

import '../../l10n/generated/app_localizations.dart';
import '../../models/learner_level.dart';
import '../../services/account/account_switch_resolution.dart';
import '../../services/account/account_ui_operations.dart';
import 'button.dart';
import 'card.dart';
import 'dialog.dart';
import 'sheet.dart';
import 'tokens.dart';

Future<AccountSwitchResolutionSide?> showAccountProgressRecoverySheet({
  required BuildContext context,
  required AccountSwitchResolutionPreview preview,
}) {
  return showSoriSheet<AccountSwitchResolutionSide>(
    context: context,
    presentation: const SoriSheetPresentation(
      backgroundColor: Colors.transparent,
      constraints: BoxConstraints(maxWidth: 560),
    ),
    builder: (_) => SoriSheetShell(
      maxTextScaleFactor: double.infinity,
      child: AccountProgressRecoverySheet(preview: preview),
    ),
  );
}

Future<AccountSwitchResolutionOutcome?> reviewPendingAccountProgress({
  required BuildContext context,
  required AccountUiOperations operations,
}) async {
  if (operations is! AccountUiSwitchResolutionOperations) {
    return AccountSwitchResolutionOutcome.unavailable;
  }
  final resolution = operations as AccountUiSwitchResolutionOperations;
  try {
    final result = await resolution.previewPendingSwitchResolution();
    if (!context.mounted) return null;
    if (result.status == AccountSwitchResolutionPreviewStatus.resumeRequired) {
      final t = AppL10n.of(context);
      final confirmed = await showSoriDialog<bool>(
        context: context,
        builder: (dialogContext) => SoriDialog(
          title: Text(t.accountRecoveryResumeTitle),
          content: Text(t.accountRecoveryResumeBody),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(t.btnCancel),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text(t.accountRecoveryResumeConfirm),
            ),
          ],
        ),
      );
      if (confirmed != true || !context.mounted) return null;
      return await resolution.resumePendingSwitchResolution();
    }
    final preview = result.preview;
    if (result.status != AccountSwitchResolutionPreviewStatus.ready ||
        preview == null) {
      return switch (result.status) {
        AccountSwitchResolutionPreviewStatus.blocked =>
          AccountSwitchResolutionOutcome.blocked,
        AccountSwitchResolutionPreviewStatus.stale =>
          AccountSwitchResolutionOutcome.stale,
        _ => AccountSwitchResolutionOutcome.unavailable,
      };
    }
    final side = await showAccountProgressRecoverySheet(
      context: context,
      preview: preview,
    );
    if (side == null || !context.mounted) return null;
    return await resolution.confirmPendingSwitchResolution(
      preview: preview,
      side: side,
    );
  } catch (_) {
    return AccountSwitchResolutionOutcome.unavailable;
  }
}

String accountProgressRecoveryMessage(
  AppL10n t,
  AccountSwitchResolutionOutcome result,
) => switch (result) {
  AccountSwitchResolutionOutcome.completed => t.accountRecoveryReady,
  AccountSwitchResolutionOutcome.blocked => t.accountRecoveryBlocked,
  AccountSwitchResolutionOutcome.stale => t.accountRecoveryStale,
  AccountSwitchResolutionOutcome.unavailable => t.accountRecoveryUnavailable,
};

class AccountProgressRecoverySheet extends StatefulWidget {
  const AccountProgressRecoverySheet({super.key, required this.preview});

  final AccountSwitchResolutionPreview preview;

  @override
  State<AccountProgressRecoverySheet> createState() =>
      _AccountProgressRecoverySheetState();
}

class _AccountProgressRecoverySheetState
    extends State<AccountProgressRecoverySheet> {
  AccountSwitchResolutionSide? _selected;
  bool _submitted = false;

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);
    final type = SoriTextTheme.of(context);
    final preview = widget.preview;
    return FocusTraversalGroup(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
            header: true,
            child: Text(t.accountRecoveryTitle, style: type.h2),
          ),
          const SizedBox(height: Spacing.sm),
          Text(t.accountRecoveryBody, style: type.body),
          const SizedBox(height: Spacing.lg),
          _choice(
            side: AccountSwitchResolutionSide.device,
            title: t.accountRecoveryDevice,
            level: preview.devicePlacementLevel,
            count: preview.deviceCompletedUnitCount,
            enabled: preview.canChooseDevice,
          ),
          const SizedBox(height: Spacing.sm),
          _choice(
            side: AccountSwitchResolutionSide.cloud,
            title: t.accountRecoveryCloud,
            level: preview.cloudPlacementLevel,
            count: preview.cloudCompletedUnitCount,
            enabled: preview.canChooseCloud,
          ),
          const SizedBox(height: Spacing.lg),
          SoriButton.filled(
            key: const Key('account-recovery-confirm'),
            label: t.accountRecoveryConfirm,
            fullWidth: true,
            feedbackOnTap: false,
            onTap: _selected == null || _submitted
                ? null
                : () {
                    if (_submitted) return;
                    setState(() => _submitted = true);
                    Navigator.of(context).pop(_selected);
                  },
          ),
          const SizedBox(height: Spacing.sm),
          SoriButton.outlined(
            key: const Key('account-recovery-cancel'),
            label: t.btnCancel,
            fullWidth: true,
            feedbackOnTap: false,
            onTap: _submitted ? null : () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  Widget _choice({
    required AccountSwitchResolutionSide side,
    required String title,
    required String level,
    required int count,
    required bool enabled,
  }) {
    final t = AppL10n.of(context);
    final type = SoriTextTheme.of(context);
    final displayLevel =
        LearnerLevel.fromCode(level)?.display ?? t.accountRecoveryUnknownLevel;
    final countLabel = count >= 0
        ? t.accountRecoveryCompletedUnits(count)
        : t.accountRecoveryCountUnavailable;
    final selected = _selected == side;
    return Semantics(
      selected: selected,
      enabled: enabled,
      inMutuallyExclusiveGroup: true,
      child: SoriCard(
        key: Key('account-recovery-${side.name}'),
        selectable: true,
        selected: selected,
        raised: enabled,
        onTap: enabled && !_submitted
            ? () => setState(() => _selected = side)
            : null,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ExcludeSemantics(
                  child: Icon(
                    selected
                        ? Icons.radio_button_checked
                        : Icons.radio_button_off,
                    color: enabled ? SoriColors.primaryOnLight : null,
                  ),
                ),
                const SizedBox(width: Spacing.sm),
                Expanded(
                  child: Text(
                    title,
                    style: type.body.copyWith(fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
            const SizedBox(height: Spacing.xs),
            Padding(
              padding: EdgeInsets.only(
                left: MediaQuery.textScalerOf(context).scale(16) > 24 ? 0 : 32,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(displayLevel, style: type.body),
                  const SizedBox(height: Spacing.xs),
                  Text(countLabel, style: type.body),
                  if (!enabled) ...[
                    const SizedBox(height: Spacing.sm),
                    Text(t.accountRecoveryUnavailableChoice, style: type.body),
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
