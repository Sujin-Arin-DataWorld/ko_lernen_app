import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../l10n/generated/app_localizations.dart';
import '../../services/content_share_service.dart';
import 'button.dart';
import 'sheet.dart';
import 'toast.dart';
import 'tokens.dart';

typedef ContentStorySharer =
    Future<ShareOutcome> Function({
      required String korean,
      required String gloss,
    });
typedef ContentTextCopier = Future<void> Function(String value);

enum _ContentShareRecoveryAction { retry, copyText }

/// Shares the generated image and exposes explicit recovery when that fails.
/// Text is copied only after the learner chooses it; it is never substituted
/// silently for an image attachment.
Future<void> shareContentStoryWithRecovery({
  required BuildContext context,
  required String korean,
  required String gloss,
  ContentStorySharer? shareStory,
  ContentTextCopier? copyText,
}) async {
  final share = shareStory ?? ContentShareService.shareStory;
  final copy =
      copyText ?? (value) => Clipboard.setData(ClipboardData(text: value));

  while (context.mounted) {
    final outcome = await share(korean: korean, gloss: gloss);
    if (!context.mounted || outcome == ShareOutcome.shared) {
      return;
    }

    final action = await _showContentShareRecoverySheet(context);
    if (!context.mounted || action == null) {
      return;
    }
    if (action == _ContentShareRecoveryAction.retry) {
      continue;
    }

    final t = AppL10n.of(context);
    try {
      await copy(t.contentShareBody(korean, gloss));
    } on Object {
      if (context.mounted) {
        soriToast(context, t.contentShareCopyFailed);
      }
      return;
    }
    if (context.mounted) {
      soriNotice(context, t.contentShareCopied);
    }
    return;
  }
}

Future<_ContentShareRecoveryAction?> _showContentShareRecoverySheet(
  BuildContext context,
) {
  final t = AppL10n.of(context);
  return showSoriSheet<_ContentShareRecoveryAction>(
    context: context,
    builder: (sheetContext) => Semantics(
      container: true,
      liveRegion: true,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Align(
            alignment: Alignment.centerLeft,
            child: Icon(
              Icons.image_not_supported_outlined,
              color: SoriColors.danger,
              size: 32,
            ),
          ),
          const SizedBox(height: Spacing.sm),
          Text(
            t.contentShareFailedTitle,
            style: SoriTextTheme.of(sheetContext).h3,
          ),
          const SizedBox(height: Spacing.xs),
          Text(
            t.contentShareFailedBody,
            style: SoriTextTheme.of(sheetContext).body,
          ),
          const SizedBox(height: Spacing.lg),
          SoriButton.filled(
            label: t.contentShareRetry,
            fullWidth: true,
            onTap: () =>
                Navigator.pop(sheetContext, _ContentShareRecoveryAction.retry),
          ),
          const SizedBox(height: Spacing.sm),
          SoriButton.outlined(
            label: t.contentShareCopyText,
            fullWidth: true,
            onTap: () => Navigator.pop(
              sheetContext,
              _ContentShareRecoveryAction.copyText,
            ),
          ),
        ],
      ),
    ),
  );
}
