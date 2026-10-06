import 'package:flutter/material.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../models/sori_stage_progression.dart';
import '../../services/storage_service.dart';
import '../../widgets/sori/button.dart';
import '../../widgets/sori/card.dart';
import '../../widgets/sori/tokens.dart';
import '../../widgets/sori/c_gallery/c_materials.dart';
import 'dancheong_catalog.dart';
import 'dancheong_models.dart';
import 'dancheong_renderer.dart';
import 'dancheong_screens.dart';
import 'dancheong_store.dart';

String? confirmedOwnedReceiptMotif(RewardReceipt receipt, Set<String> owned) {
  final identities = receipt.items
      .where((item) => item.kind == SoriRewardKind.stamp)
      .map((item) => item.identity)
      .whereType<String>()
      .where((slug) => knownMotif(slug) != null && owned.contains(slug))
      .toSet();
  return identities.length == 1 ? identities.single : null;
}

class DancheongEntryCard extends StatelessWidget {
  const DancheongEntryCard({
    super.key,
    required this.store,
    required this.onOpen,
    this.compact = false,
  });
  final DancheongStore store;
  final VoidCallback onOpen;
  final bool compact;
  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: store.changes,
    builder: (context, _) {
      final t = AppL10n.of(context);
      DancheongArtwork? newest;
      try {
        newest = store.currentOwner().artworks.lastOrNull;
      } catch (_) {
        return const SizedBox.shrink();
      }
      if (compact) {
        return SoriCard(
          key: const ValueKey('hanok-dancheong-entry'),
          padding: const EdgeInsets.all(Spacing.sm),
          onTap: onOpen,
          semanticLabel: '${t.dancheongEntry}. ${t.dancheongEntryAction}',
          child: Row(
            children: [
              SizedBox(
                width: 48,
                height: 60,
                child: newest == null
                    ? Image.asset(
                        dancheongExamplePatternAsset,
                        fit: BoxFit.contain,
                        semanticLabel: t.dancheongExamples,
                      )
                    : DancheongArtworkView(
                        composition: newest.composition,
                        ownedSlugs: knownOwnedMotifs(Storage.earnedStamps),
                      ),
              ),
              const SizedBox(width: Spacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(t.dancheongEntry, style: SoriTextTheme.of(context).h3),
                    Text(
                      t.dancheongEntryAction,
                      style: SoriTextTheme.of(context).meta,
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      }
      return SoriCard(
        key: const ValueKey('hanok-dancheong-entry'),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(t.dancheongEntry, style: SoriTextTheme.of(context).h3),
            const SizedBox(height: Spacing.sm),
            if (newest != null)
              SizedBox(
                height: 190,
                child: DancheongArtworkView(
                  composition: newest.composition,
                  ownedSlugs: knownOwnedMotifs(Storage.earnedStamps),
                ),
              )
            else
              SizedBox(
                height: 100,
                child: Image.asset(
                  dancheongExamplePatternAsset,
                  fit: BoxFit.contain,
                  semanticLabel: t.dancheongExamples,
                ),
              ),
            if (newest == null)
              Text(t.dancheongExamples, style: SoriTextTheme.of(context).meta),
            const SizedBox(height: Spacing.sm),
            Text(t.dancheongIntro),
            const SizedBox(height: Spacing.md),
            SoriButton.outlined(
              label: t.dancheongEntryAction,
              fullWidth: true,
              onTap: onOpen,
            ),
          ],
        ),
      );
    },
  );
}

class DancheongDraftResume extends StatelessWidget {
  const DancheongDraftResume({
    super.key,
    required this.store,
    required this.onOpen,
    this.conceptC = false,
  });
  final DancheongStore store;
  final ValueChanged<DancheongEditorArgs> onOpen;
  final bool conceptC;
  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: store.changes,
    builder: (context, _) {
      DancheongDraft? draft;
      try {
        final drafts = [...store.currentOwner().drafts]
          ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
        draft = drafts.firstOrNull;
      } catch (_) {
        return const SizedBox.shrink();
      }
      if (draft == null) {
        return const SizedBox.shrink();
      }
      final selected = draft;
      if (conceptC) {
        return Padding(
          padding: const EdgeInsets.only(top: 12),
          child: CMaterialAction(
            key: const ValueKey('today-dancheong-draft'),
            label: AppL10n.of(context).dancheongDraft,
            gold: false,
            onTap: () => onOpen(DancheongEditorArgs(draftId: selected.id)),
          ),
        );
      }
      return Padding(
        padding: const EdgeInsets.only(top: Spacing.md),
        child: SoriButton.outlined(
          key: const ValueKey('today-dancheong-draft'),
          label: AppL10n.of(context).dancheongDraft,
          fullWidth: true,
          onTap: () => onOpen(DancheongEditorArgs(draftId: selected.id)),
        ),
      );
    },
  );
}
