import 'package:flutter/material.dart';

import '../../l10n/generated/app_localizations.dart';
import '../../models/sori_stage_progression.dart';
import 'activity_illustration.dart';
import 'button.dart';
import 'catalog_card.dart';
import 'c_gallery/c_materials.dart';
import 'localized_copy.dart';
import 'reward_icon.dart';
import 'sheet.dart';
import 'tokens.dart';
import 'mascot.dart';

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
  bool conceptC = false,
}) {
  final isLocked = isActivityLocked(entry, progress);

  return showSoriSheet<void>(
    context: context,
    maxTextScaleFactor: conceptC ? 2 : 1.3,
    contentPadding: conceptC ? const EdgeInsets.fromLTRB(12, 12, 12, 16) : null,
    builder: (ctx) => conceptC
        ? _CActivitySheetContent(
            entry: entry,
            isLocked: isLocked,
            onStart: onStart,
          )
        : _ActivitySheetContent(
            entry: entry,
            progress: progress,
            isLocked: isLocked,
            onStart: onStart,
          ),
  );
}

/// The same start/lock contract on the approved C paper board. Artwork is
/// decorative; descriptions and reward expectations stay localized native text.
class _CActivitySheetContent extends StatelessWidget {
  const _CActivitySheetContent({
    required this.entry,
    required this.isLocked,
    required this.onStart,
  });

  final ActivityCatalogEntry entry;
  final bool isLocked;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);
    const body = TextStyle(
      fontFamily: 'Paperlogy',
      fontFamilyFallback: ['NotoSansKR'],
      fontSize: 16,
      height: 1.3,
      color: CPalette.ink,
    );
    return CPaperPanel(
      key: ValueKey('c-activity-sheet-${entry.id}'),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: AspectRatio(
              aspectRatio: entry.id == 'syllable_cross'
                  ? CGameReferenceArt.heroAspectRatio
                  : 2,
              child: cCatalogArt(entry),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            localCopy(context, entry.title),
            style: body.copyWith(fontSize: 24, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text(
            t.soriStageMinutes(entry.minutes),
            style: body.copyWith(color: CPalette.mutedInk),
          ),
          const SizedBox(height: 12),
          Text(localCopy(context, entry.description), style: body),
          if (entry.id == 'smalltalk' || entry.id == 'daily_game') ...[
            const SizedBox(height: 16),
            SoriCultureComment(
              conceptC: true,
              role: entry.id == 'smalltalk'
                  ? SoriCulturalRole.hahoeMask
                  : SoriCulturalRole.dokkaebi,
            ),
          ],
          if (isLocked && entry.unlock.explanation != null) ...[
            const SizedBox(height: 16),
            CPaperPanel(
              raised: false,
              child: Text(
                localCopy(context, entry.unlock.explanation!),
                style: body.copyWith(fontWeight: FontWeight.w600),
              ),
            ),
          ],
          if (entry.reward.items.isNotEmpty) ...[
            const SizedBox(height: 16),
            CPaperPanel(
              raised: false,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    localCopy(context, entry.reward.condition),
                    style: body.copyWith(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  for (final item in entry.reward.items)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Text(
                        '${item.amount == null ? '' : '+${item.amount} '}'
                        '${localCopy(context, item.label)}',
                        style: body,
                      ),
                    ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 18),
          CMaterialAction(
            key: ValueKey('c-activity-start-${entry.id}'),
            label: isLocked
                ? t.soriStageActivityLocked
                : t.soriStageActivityStart,
            gold: entry.tab != SoriStageTab.games,
            onTap: isLocked
                ? null
                : () {
                    Navigator.of(context).pop();
                    onStart();
                  },
          ),
        ],
      ),
    );
  }
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
                aspectRatio: 4 / 3,
                child: Image.asset(
                  activityIllustrationAsset(entry.id),
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => Container(
                    color: color.withValues(alpha: 0.08),
                    child: Center(
                      child: Text(t.catalogImageUnavailable, style: tt.body),
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

        // A small culture object accompanies the conversation-tone hint.
        if (entry.id == 'smalltalk') ...[
          const SizedBox(height: Spacing.md),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: Spacing.lg),
            child: SoriCultureComment(role: SoriCulturalRole.hahoeMask),
          ),
        ] else if (entry.id == 'daily_game' ||
            entry.id == 'syllable_cross') ...[
          const SizedBox(height: Spacing.md),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: Spacing.lg),
            child: SoriCultureComment(role: SoriCulturalRole.dokkaebi),
          ),
        ],
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
