import 'package:flutter/material.dart';

import '../../l10n/generated/app_localizations.dart';
import '../../models/sori_stage_progression.dart';
import 'activity_illustration.dart';
import 'button.dart';
import 'localized_copy.dart';
import 'reward_icon.dart';
import 'sheet.dart';
import 'tokens.dart';

/// §C-2: 활동 카드 상세 시트 — 카드 규율(4기둥 ④)의 대가로 버린 정보를
/// 여기에 **강등**한다. 설명(entry.description) + 보상 계약(reward.condition
/// + items) + 시작 CTA.
///
/// 카탈로그에서:
/// - 일반 카드 **롱프레스** = 이 시트
/// - 잠긴 카드 **탭** = 이 시트(잠금 설명 전문 표시)
Future<void> showSoriActivitySheet(
  BuildContext context, {
  required ActivityCatalogEntry entry,
  required SoriActivityProgress? progress,
  required VoidCallback onStart,
}) {
  final isLocked = isActivityLocked(entry, progress);

  return showSoriSheet<void>(
    context: context,
    builder: (ctx) => _ActivitySheetContent(
      entry: entry,
      progress: progress,
      isLocked: isLocked,
      onStart: onStart,
    ),
  );
}

class _ActivitySheetContent extends StatelessWidget {
  const _ActivitySheetContent({
    required this.entry,
    required this.progress,
    required this.isLocked,
    required this.onStart,
  });

  final ActivityCatalogEntry entry;
  final SoriActivityProgress? progress;
  final bool isLocked;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);
    final tt = SoriTextTheme.of(context);
    final s = SoriSurfaces.of(context);
    final title = localCopy(context, entry.title);
    final description = localCopy(context, entry.description);
    final color = soriActivityColor(entry.colorRole);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 일러스트 배너
        Center(
          child: Padding(
            padding: const EdgeInsets.only(top: Spacing.md, bottom: Spacing.md),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(SoriRadius.lg),
              child: AspectRatio(
                aspectRatio: 16 / 10,
                child: Image.asset(
                  activityIllustrationAsset(entry.id),
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    color: color.withValues(alpha: 0.08),
                    child: Center(
                      child: ActivityIconFallback(
                        iconName: entry.iconName,
                        colorRole: entry.colorRole,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),

        // 제목 + 분
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: Spacing.lg),
          child: Text(title, style: tt.h2),
        ),
        const SizedBox(height: 4),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: Spacing.lg),
          child: Text(
            t.soriStageMinutes(entry.minutes),
            style: tt.cardSubtitle.copyWith(color: s.textMuted),
          ),
        ),

        const SizedBox(height: Spacing.md),

        // 설명 (ARB 문구 복원 — §C-1-5)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: Spacing.lg),
          child: Text(description, style: tt.body),
        ),

        // 잠금 설명 (잠긴 항목만)
        if (isLocked && entry.unlock.explanation != null) ...[
          const SizedBox(height: Spacing.md),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: Spacing.lg),
            child: Container(
              padding: const EdgeInsets.all(Spacing.sm),
              decoration: BoxDecoration(
                color: SoriColors.warning.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(SoriRadius.sm),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.lock_outline_rounded,
                    size: 18,
                    color: SoriColors.warning,
                  ),
                  const SizedBox(width: Spacing.sm),
                  Expanded(
                    child: Text(
                      localCopy(context, entry.unlock.explanation!),
                      style: tt.cardSubtitle.copyWith(
                        color: s.text,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],

        // 보상 계약 (§C-1-6 — "학습 전의 약속" 복원)
        if (entry.reward.items.isNotEmpty) ...[
          const SizedBox(height: Spacing.lg),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: Spacing.lg),
            child: Text(
              localCopy(context, entry.reward.condition),
              style: tt.label.copyWith(color: color),
            ),
          ),
          const SizedBox(height: Spacing.sm),
          ...entry.reward.items.map(
            (item) => Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: Spacing.lg,
                vertical: 2,
              ),
              child: Row(
                children: [
                  Icon(soriRewardIcon(item.kind), size: 16, color: color),
                  const SizedBox(width: Spacing.sm),
                  Expanded(
                    child: Text(
                      // 리시트와 동일한 '+N 라벨' 표기 — 약속과 이행이 같은
                      // 시각 언어를 쓴다 (§C-3c P1-⑦).
                      '${item.amount == null ? '' : '+${item.amount} '}'
                      '${localCopy(context, item.label)}',
                      style: tt.cardSubtitle.copyWith(color: s.text),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],

        const SizedBox(height: Spacing.xl),

        // CTA
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: Spacing.lg),
          child: SoriButton.filled(
            label: isLocked
                ? t.soriStageActivityLocked
                : t.soriStageActivityStart,
            fullWidth: true,
            onTap: isLocked
                ? null
                : () {
                    Navigator.of(context).pop();
                    onStart();
                  },
          ),
        ),
        const SizedBox(height: Spacing.lg),
      ],
    );
  }
}
