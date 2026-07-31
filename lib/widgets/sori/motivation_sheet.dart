import 'package:flutter/material.dart';

import '../../data/learner_motivation.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../services/storage_service.dart';
import 'card.dart';
import 'mascot.dart';
import 'sheet.dart';
import 'tokens.dart';

/// 첫 홈 진입 시 1회 — "왜 한국어를 배우나" 캡처(showSoriSheet 재사용).
///
/// 선택 시 [Storage.setMotivation] 저장, 닫든 선택하든 [Storage.setMotivationAsked]
/// 로 재노출 방지. 캡처된 이유는 홈 tiger bubble·프로필에서 개인화 격려에 쓰인다.
Future<LearnerMotivation?> showMotivationSheet(BuildContext context) async {
  final selected = await showSoriSheet<LearnerMotivation>(
    context: context,
    builder: (ctx) => const _MotivationSheetBody(),
  );
  await Storage.setMotivationAsked();
  if (selected != null) {
    await Storage.setMotivation(selected.id);
  }
  return selected;
}

class _MotivationSheetBody extends StatelessWidget {
  const _MotivationSheetBody();

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);
    final tt = SoriTextTheme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Center(
          child: Mascot.tiger(
            size: 68,
            emotion: MascotEmotion.smile,
            animate: false,
          ),
        ),
        const SizedBox(height: Spacing.sm),
        Text(t.motivationSheetTitle, style: tt.h2),
        const SizedBox(height: 4),
        Text(t.motivationSheetSubtitle, style: tt.bodySmall),
        const SizedBox(height: Spacing.lg),
        for (final m in LearnerMotivation.values) ...[
          _MotivationRow(m: m),
          const SizedBox(height: Spacing.sm),
        ],
        const SizedBox(height: Spacing.xs),
      ],
    );
  }
}

class _MotivationRow extends StatelessWidget {
  final LearnerMotivation m;

  const _MotivationRow({required this.m});

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);
    final s = SoriSurfaces.of(context);
    return SoriCard(
      variant: SoriCardVariant.base,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      onTap: () => Navigator.of(context).pop(m),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: m.accent.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(SoriRadius.sm),
            ),
            alignment: Alignment.center,
            child: Icon(m.icon, color: m.accent, size: 22),
          ),
          const SizedBox(width: Spacing.md),
          Expanded(
            child: Text(
              m.label(t),
              style: TextStyle(
                fontFamily: 'Pretendard',
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: s.text,
              ),
            ),
          ),
          Icon(Icons.chevron_right_rounded, color: s.textDim),
        ],
      ),
    );
  }
}
