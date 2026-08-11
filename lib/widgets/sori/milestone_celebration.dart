import 'package:flutter/material.dart';

import '../../data/milestone.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../models/content_feedback.dart';
import '../../services/storage_service.dart';
import 'button.dart';
import 'celebration.dart';
import 'character_clip.dart';
import 'content_feedback_card.dart';
import 'mascot.dart';
import 'mascot_preference.dart';
import 'sheet.dart';
import 'tokens.dart';

/// 마일스톤 달성 축하 — 축하 버스트 + 마스코트 + 메시지(showSoriSheet 재사용).
///
/// 호출 전 [Storage.markMilestonesCelebrated]로 1회 가드 마킹(중복 방지)은 호출부 책임.
Future<void> showMilestoneCelebration(
  BuildContext context,
  Milestone milestone, {
  required ContentFeedbackContext feedbackContext,
}) async {
  SoriCelebration.burst(context);
  await showSoriSheet<void>(
    context: context,
    builder: (ctx) =>
        _MilestoneBody(milestone: milestone, feedbackContext: feedbackContext),
  );
}

class _MilestoneBody extends StatelessWidget {
  final Milestone milestone;
  final ContentFeedbackContext feedbackContext;

  const _MilestoneBody({
    required this.milestone,
    required this.feedbackContext,
  });

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);
    final s = SoriSurfaces.of(context);
    final tt = SoriTextTheme.of(context);
    final feedbackScope = ContentFeedbackControllerScope.maybeOf(context);
    // 선택 캐릭터 인식 축하 클립 — 호랑이: 포효 / 까치: 비행(2026-07-30 배선).
    // 시트 배경(s.surface)에 multiply로 흡수. 폴백은 기존 정적 celebrate.
    final kind = MascotPreference.selectedKind;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (kind != null) ...[
          CharacterClipPlayer(
            asset: kind == MascotKind.magpie
                ? CharacterClips.magpieFlight
                : CharacterClips.tigerRoar,
            // Jin 실기기 피드백: 포효 영상이 너무 작다 → 히어로급으로 키운다.
            // 시트는 88% maxHeight 클램프 + 자동 스크롤이라 커져도 안전.
            size: 160,
            blendColor: s.surface,
            fallbackKind: kind,
            fallbackEmotion: MascotEmotion.celebrate,
          ),
          const SizedBox(height: Spacing.md),
        ] else ...[
          const Icon(
            Icons.workspace_premium_rounded,
            size: 104,
            color: SoriColors.gold,
          ),
          const SizedBox(height: Spacing.md),
        ],
        Text(milestone.title(t), style: tt.h1, textAlign: TextAlign.center),
        const SizedBox(height: 6),
        Text(
          milestone.body(t),
          style: tt.body.copyWith(color: s.textMuted),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: Spacing.lg),
        if (feedbackScope != null && feedbackScope.featureGate.isEnabled) ...[
          ContentFeedbackCard(
            feedbackContext: feedbackContext,
            featureGate: feedbackScope.featureGate,
            submitFeedback: feedbackScope.submitFeedback,
          ),
          const SizedBox(height: Spacing.lg),
        ],
        SoriButton.filled(
          key: const Key('milestone-celebration-continue'),
          label: t.feedbackCompletionContinue,
          icon: Icons.arrow_forward_rounded,
          fullWidth: true,
          onTap: () => Navigator.of(context).pop(),
        ),
        const SizedBox(height: Spacing.xs),
      ],
    );
  }
}
