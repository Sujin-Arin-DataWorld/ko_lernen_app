import 'package:flutter/material.dart';

import '../../../l10n/generated/app_localizations.dart';
import '../../../models/cultural_glossary.dart';
import '../button.dart';
import '../external_link.dart';
import '../tokens.dart';
import 'reward_art.dart';

/// The cultural popup is display-only; it never acknowledges or claims a box.
Future<void> showRewardCulturalStory(
  BuildContext context, {
  required CulturalGlossaryEntry entry,
  required String itemAsset,
  required String itemName,
}) async {
  await showDialog<void>(
    context: context,
    builder: (context) {
      final t = AppL10n.of(context);
      final text = SoriTextTheme.of(context);
      final copy = entry.localized(
        Localizations.localeOf(context).languageCode,
      );
      return Dialog(
        backgroundColor: const Color(0xfffffdf8),
        insetPadding: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: Color(0xffd2b878)),
        ),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: 480,
            maxHeight: MediaQuery.sizeOf(context).height * .86,
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Semantics(
                        header: true,
                        child: Text(
                          t.rewardChestCulturalStory,
                          textAlign: TextAlign.center,
                          style: text.h3,
                        ),
                      ),
                    ),
                    IconButton(
                      autofocus: true,
                      tooltip: t.btnClose,
                      constraints: const BoxConstraints(
                        minWidth: 48,
                        minHeight: 48,
                      ),
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 180,
                  child: Semantics(
                    image: true,
                    label: itemName,
                    child: RewardArt(itemAsset),
                  ),
                ),
                const SizedBox(height: 16),
                Text(itemName, textAlign: TextAlign.center, style: text.h2),
                Text(
                  '${entry.korean} · ${entry.romanization}',
                  textAlign: TextAlign.center,
                  style: text.bodySmall.copyWith(fontFamily: 'NotoSansKR'),
                ),
                const SizedBox(height: 16),
                Text(copy.story, style: text.body.copyWith(height: 1.5)),
                const SizedBox(height: 16),
                for (final source in entry.sources)
                  SoriButton.ghost(
                    label: source.title,
                    fullWidth: true,
                    onTap: () => openExternalUrl(context, source.url),
                  ),
                SoriButton.outlined(
                  label: t.btnClose,
                  fullWidth: true,
                  onTap: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}
