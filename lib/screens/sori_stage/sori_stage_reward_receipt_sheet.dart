import 'package:flutter/material.dart';

import '../../l10n/generated/app_localizations.dart';
import '../../models/sori_stage_progression.dart';
import '../../widgets/sori/button.dart';
import '../../widgets/sori/reward_icon.dart';
import '../../widgets/sori/sheet.dart';
import '../../widgets/sori/tokens.dart';
import 'sori_stage_common.dart';

class SoriStageRewardReceiptSheet extends StatelessWidget {
  const SoriStageRewardReceiptSheet({super.key, required this.receipt});

  final RewardReceipt receipt;

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);
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
              Text(
                t.soriStageReceiptEyebrow,
                style: const TextStyle(
                  color: SoriColors.accent,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.1,
                ),
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
