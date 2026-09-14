import 'package:flutter/material.dart';

import '../../l10n/generated/app_localizations.dart';
import '../../models/sarangchae_construction.dart';
import '../../models/sori_stage_progression.dart';
import '../../widgets/app_loading.dart';
import '../../widgets/sori/button.dart';
import '../../widgets/sori/hanok_v3_preview.dart';
import '../../widgets/sori/reward_icon.dart';
import '../../widgets/sori/sheet.dart';
import '../../widgets/sori/tokens.dart';
import 'sori_stage_common.dart';

class SoriStageRewardReceiptSheet extends StatefulWidget {
  const SoriStageRewardReceiptSheet({
    super.key,
    required this.receipt,
    this.loadConstruction,
  });

  final RewardReceipt receipt;
  final Future<SarangchaeConstruction> Function()? loadConstruction;

  @override
  State<SoriStageRewardReceiptSheet> createState() =>
      _SoriStageRewardReceiptSheetState();
}

class _SoriStageRewardReceiptSheetState
    extends State<SoriStageRewardReceiptSheet> {
  Future<SarangchaeConstruction>? _constructionFuture;

  @override
  void initState() {
    super.initState();
    if (widget.receipt.hasSarangchaeUpgrade) {
      _constructionFuture =
          (widget.loadConstruction ?? SarangchaeConstruction.load)();
    }
  }

  @override
  void didUpdateWidget(covariant SoriStageRewardReceiptSheet oldWidget) {
    super.didUpdateWidget(oldWidget);
    final receiptChanged =
        oldWidget.receipt.sarangchaeStageBefore !=
            widget.receipt.sarangchaeStageBefore ||
        oldWidget.receipt.sarangchaeStageAfter !=
            widget.receipt.sarangchaeStageAfter;
    if (widget.receipt.hasSarangchaeUpgrade &&
        (!oldWidget.receipt.hasSarangchaeUpgrade ||
            receiptChanged ||
            oldWidget.loadConstruction != widget.loadConstruction)) {
      _constructionFuture =
          (widget.loadConstruction ?? SarangchaeConstruction.load)();
    } else if (!widget.receipt.hasSarangchaeUpgrade) {
      _constructionFuture = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);
    final tt = SoriTextTheme.of(context);
    final receipt = widget.receipt;
    return Semantics(
      container: true,
      liveRegion: true,
      label: t.soriStageReceiptSemantics,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(Spacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      t.soriStageReceiptEyebrow,
                      style: const TextStyle(
                        color: SoriColors.accent,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.1,
                      ),
                    ),
                  ),
                  IconButton(
                    key: const Key('receipt-close'),
                    tooltip: t.btnClose,
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
              const SizedBox(height: Spacing.xs),
              Text(
                t.soriStageReceiptTitle,
                style: const TextStyle(
                  fontSize: 26,
                  height: 1.15,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: Spacing.lg),
              if (receipt.hasSarangchaeUpgrade) ...[
                Text(
                  t.sarangchaeNewStages(
                    receipt.sarangchaeStageAfter -
                        receipt.sarangchaeStageBefore,
                  ),
                  style: tt.h3,
                ),
                const SizedBox(height: Spacing.xs),
                Text(
                  t.sarangchaeStageTransition(
                    receipt.sarangchaeStageBefore,
                    receipt.sarangchaeStageAfter,
                  ),
                  style: tt.label,
                ),
                const SizedBox(height: Spacing.md),
                FutureBuilder<SarangchaeConstruction>(
                  future: _constructionFuture!,
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return snapshot.hasError
                          ? const SizedBox.shrink()
                          : const AppLoading();
                    }
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _SarangchaeBeforeAfter(
                          construction: snapshot.data!,
                          before: receipt.sarangchaeStageBefore,
                          after: receipt.sarangchaeStageAfter,
                        ),
                        const SizedBox(height: Spacing.lg),
                        SarangchaeConstructionExperience(
                          construction: snapshot.data!,
                          earnedStageCount: receipt.sarangchaeStageAfter,
                          minimumSelectableStage:
                              receipt.sarangchaeStageBefore + 1,
                          showLockedStages: false,
                          compact: true,
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: Spacing.lg),
              ],
              for (final item in receipt.items) _RewardLine(item: item),
              const SizedBox(height: Spacing.lg),
              SoriButton(
                label: t.soriStageReceiptContinue,
                onTap: () => Navigator.pop(context),
                fullWidth: true,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SarangchaeBeforeAfter extends StatelessWidget {
  const _SarangchaeBeforeAfter({
    required this.construction,
    required this.before,
    required this.after,
  });

  final SarangchaeConstruction construction;
  final int before;
  final int after;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: AspectRatio(
          aspectRatio: 4 / 3,
          child: KeyedSubtree(
            key: const ValueKey('sarangchae-before-artwork'),
            child: before == 0
                ? Semantics(
                    image: true,
                    label: AppL10n.of(context).sarangchaeStageLocked(0),
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: SoriSurfaces.of(context).surfaceAlt,
                        borderRadius: SoriRadius.brLg,
                      ),
                      child: const Center(
                        child: Icon(Icons.home_work_outlined, size: 28),
                      ),
                    ),
                  )
                : SarangchaeStageArtwork(
                    construction: construction,
                    earnedStageCount: before,
                    sequence: before,
                  ),
          ),
        ),
      ),
      const Padding(
        padding: EdgeInsets.symmetric(horizontal: Spacing.sm),
        child: Icon(Icons.arrow_forward_rounded),
      ),
      Expanded(
        child: AspectRatio(
          aspectRatio: 4 / 3,
          child: KeyedSubtree(
            key: const ValueKey('sarangchae-after-artwork'),
            child: SarangchaeStageArtwork(
              construction: construction,
              earnedStageCount: after,
              sequence: after,
            ),
          ),
        ),
      ),
    ],
  );
}

class _RewardLine extends StatelessWidget {
  const _RewardLine({required this.item});

  final RewardReceiptItem item;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: Spacing.sm),
    child: Row(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: SoriActivityColors.reward.withValues(alpha: .24),
            borderRadius: BorderRadius.circular(SoriRadius.sm),
          ),
          child: Icon(soriRewardIcon(item.kind), color: SoriColors.goldOnLight),
        ),
        const SizedBox(width: Spacing.md),
        Expanded(
          child: Text(
            '${item.amount == null ? '' : '+${item.amount} '}'
            '${localCopy(context, item.label)}',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
        ),
      ],
    ),
  );
}

Future<void> showSoriStageRewardReceipt(
  BuildContext context,
  RewardReceipt receipt,
) => showSoriSheet<void>(
  context: context,
  builder: (_) => SoriStageRewardReceiptSheet(receipt: receipt),
);
