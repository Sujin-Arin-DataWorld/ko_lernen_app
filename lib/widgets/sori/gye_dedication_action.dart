import 'package:flutter/material.dart';

import '../../data/gye_dedication_catalog.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../models/gye_dedication.dart';
import '../../services/gye_dedication_service.dart';
import 'button.dart';
import 'gye_dedication_picker.dart';
import 'placed_decoration.dart';
import 'sheet.dart';
import 'tokens.dart';

/// The one callable-only mutation seam used by the shared exhibition UI.
///
/// The Gye screen supplies the cloud-session-gated production callback, while
/// tests can supply a deterministic fake. This widget never writes personal
/// decor, placement, rewards, or any Firestore document directly.
typedef GyeDedicationCommit =
    Future<GyeDedicationMutation> Function({
      required String gyeId,
      required String? decorationSlug,
      required int expectedRevision,
      required String operationId,
    });

/// Compact action over the shared courtyard map.
///
/// It deliberately keeps its own state pessimistic: success only ends the
/// pending state. The parent stream remains the sole source of exhibit data.
class GyeDedicationAction extends StatefulWidget {
  const GyeDedicationAction({
    super.key,
    required this.gyeId,
    required this.ownedDecor,
    required this.current,
    required this.actionsAvailable,
    required this.onCommit,
  });

  final String gyeId;
  final Iterable<String> ownedDecor;
  final GyeDedication? current;
  final bool actionsAvailable;
  final GyeDedicationCommit onCommit;

  @override
  State<GyeDedicationAction> createState() => _GyeDedicationActionState();
}

class _GyeDedicationActionState extends State<GyeDedicationAction> {
  bool _submitting = false;

  Future<void> _openPicker() async {
    if (_submitting || !widget.actionsAvailable) {
      return;
    }
    final candidates = eligibleGyeDedicationSlugs(widget.ownedDecor).toList()
      ..sort();
    final picked = await showSoriSheet<String>(
      context: context,
      builder: (_) => GyeDedicationPickerSheet(
        candidates: candidates,
        current: widget.current,
      ),
    );
    if (!mounted || picked == null) {
      return;
    }
    final decorationSlug = picked == kGyeDedicationWithdraw ? null : picked;
    if (decorationSlug == widget.current?.decorationSlug) {
      return;
    }
    final change = GyeDedicationChange.fromCurrent(
      current: widget.current,
      decorationSlug: decorationSlug,
    );
    final confirmed = await _confirm(change.decorationSlug);
    if (!mounted || !confirmed) {
      return;
    }
    await _submit(
      _GyeDedicationRequest(
        change: change,
        operationId: GyeDedicationService.newOperationId(),
      ),
    );
  }

  Future<bool> _confirm(String? decorationSlug) async {
    final t = AppL10n.of(context);
    final german = Localizations.localeOf(context).languageCode != 'en';
    final body = decorationSlug == null
        ? t.gyeDedicationWithdrawConfirmBody
        : t.gyeDedicationConfirmBody(decorName(decorationSlug, german: german));
    return (await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: Text(
              decorationSlug == null
                  ? t.gyeDedicationWithdraw
                  : t.gyeDedicationConfirmTitle,
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(body),
                const SizedBox(height: Spacing.md),
                Text(
                  t.gyeDedicationKeepOwned,
                  style: SoriTextTheme.of(dialogContext).bodySmall,
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(false),
                child: Text(t.btnCancel),
              ),
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(true),
                child: Text(
                  decorationSlug == null
                      ? t.gyeDedicationWithdraw
                      : t.gyeDedicationConfirm,
                ),
              ),
            ],
          ),
        )) ??
        false;
  }

  Future<void> _submit(_GyeDedicationRequest request) async {
    if (_submitting || !widget.actionsAvailable) {
      return;
    }
    setState(() => _submitting = true);
    GyeDedicationClientFailure? failure;
    try {
      await widget.onCommit(
        gyeId: widget.gyeId,
        decorationSlug: request.change.decorationSlug,
        expectedRevision: request.change.expectedRevision,
        operationId: request.operationId,
      );
    } on GyeDedicationClientFailure catch (error) {
      failure = error;
    } catch (_) {
      failure = const GyeDedicationClientFailure(
        GyeDedicationFailureCategory.unknown,
        retryable: true,
      );
    } finally {
      if (mounted) {
        setState(() => _submitting = false);
      }
    }
    if (!mounted || failure == null) {
      return;
    }
    _showFailure(failure, request);
  }

  void _showFailure(
    GyeDedicationClientFailure failure,
    _GyeDedicationRequest request,
  ) {
    final t = AppL10n.of(context);
    final message = failure.category == GyeDedicationFailureCategory.conflict
        ? t.gyeDedicationConflict
        : t.gyeDedicationUpdateFailed;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          // A revision conflict must be resolved by the live stream. Retrying
          // the same compare-and-set request would only repeat the stale
          // revision and makes a blind overwrite look possible.
          action:
              failure.retryable &&
                  failure.category != GyeDedicationFailureCategory.conflict
              ? SnackBarAction(
                  label: t.gyeDedicationRetry,
                  onPressed: () {
                    _submit(request);
                  },
                )
              : null,
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);
    return Semantics(
      label: t.gyeDedicationTitle,
      child: SoriButton.outlined(
        label: t.gyeDedicationAction,
        size: SoriButtonSize.md,
        onTap: widget.actionsAvailable && !_submitting ? _openPicker : null,
      ),
    );
  }
}

class _GyeDedicationRequest {
  const _GyeDedicationRequest({
    required this.change,
    required this.operationId,
  });

  final GyeDedicationChange change;
  final String operationId;
}
