import 'package:flutter/material.dart';

import '../../l10n/generated/app_localizations.dart';
import '../../models/sori_stage_progression.dart';
import '../../widgets/sori/tokens.dart';

class SoriStageRootHeader extends StatelessWidget {
  const SoriStageRootHeader({
    super.key,
    required this.eyebrow,
    required this.title,
    this.body,
  });

  final String eyebrow;
  final String title;
  final String? body;

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                eyebrow.toUpperCase(),
                style: const TextStyle(
                  color: SoriColors.accent,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.1,
                ),
              ),
              const SizedBox(height: Spacing.xs),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 30,
                  height: 1.08,
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (body != null) ...[
                const SizedBox(height: Spacing.sm),
                Text(body!, style: const TextStyle(fontSize: 16, height: 1.45)),
              ],
            ],
          ),
        ),
        const SizedBox(width: Spacing.sm),
        SizedBox.square(
          dimension: 48,
          child: IconButton(
            tooltip: t.soriStageProfileTooltip,
            onPressed: () => Navigator.of(context).pushNamed('/profile'),
            icon: const Icon(Icons.person_outline_rounded),
          ),
        ),
      ],
    );
  }
}

Color soriActivityColor(SoriActivityColorRole role) => switch (role) {
  SoriActivityColorRole.listening => SoriActivityColors.listening,
  SoriActivityColorRole.speaking => SoriActivityColors.speaking,
  SoriActivityColorRole.review => SoriActivityColors.review,
  SoriActivityColorRole.completion => SoriActivityColors.completion,
  SoriActivityColorRole.reward => SoriActivityColors.reward,
  SoriActivityColorRole.collaboration => SoriActivityColors.collaboration,
  SoriActivityColorRole.hanok => SoriActivityColors.hanokStage,
};

IconData soriActivityIcon(String name) => switch (name) {
  'headphones' => Icons.headphones_rounded,
  'mic' => Icons.mic_rounded,
  'brush' => Icons.brush_rounded,
  'cards' => Icons.style_rounded,
  'repeat' => Icons.replay_rounded,
  'target' => Icons.track_changes_rounded,
  'grammar' => Icons.account_tree_outlined,
  'dialogue' || 'chat' => Icons.forum_outlined,
  'camera' => Icons.document_scanner_outlined,
  'bookshelf' => Icons.auto_stories_outlined,
  'search' => Icons.search_rounded,
  'sun' => Icons.wb_sunny_outlined,
  'chosung' => Icons.text_fields_rounded,
  'grid' => Icons.grid_view_rounded,
  'cloze' => Icons.space_bar_rounded,
  'bolt' => Icons.bolt_rounded,
  'arcade' => Icons.sports_esports_outlined,
  'chain' => Icons.link_rounded,
  'keyboard' => Icons.keyboard_alt_outlined,
  'matching' => Icons.compare_arrows_rounded,
  'quiz' => Icons.quiz_outlined,
  'hangul' => Icons.translate_rounded,
  _ => Icons.route_rounded,
};

String localCopy(BuildContext context, SoriLocalizedCopy copy) {
  final t = AppL10n.of(context);
  final activityId = copy.activityId;
  if (activityId != null) {
    return copy.isActivityDescription
        ? t.soriStageActivityDescription(activityId)
        : t.soriStageActivityTitle(activityId);
  }
  final key = copy.key;
  if (key != null) {
    return t.soriStageCatalogCopy(key.name);
  }
  // Non-production fixtures may still provide literal bilingual copy. All
  // catalog and receipt surfaces carry an ARB-backed activity ID or copy key.
  return copy.resolve(Localizations.localeOf(context).languageCode);
}
