import 'package:flutter/material.dart';

import '../../l10n/generated/app_localizations.dart';
import 'button.dart';
import 'mascot.dart';
import 'tokens.dart';

/// 지원하는 코치마크 종류 (후속 세션에서 gye / wordbook 추가).
enum FeatureCoach {
  /// 책 한 컷 — 첫 진입 시 3스텝 안내.
  book,

  /// 단어팩 — 학습 3단계(learn→quiz→boss) 소개.
  vocabPack,
}

/// 마스코트 바텀시트 코치마크.
///
/// `account_nudge.dart` 구조를 일반화한 버전. 항상 비차단 — "알겠어요" 1버튼,
/// 또는 배경 탭으로 닫을 수 있다.
///
/// ```dart
/// // initState → addPostFrameCallback 안에서 호출
/// WidgetsBinding.instance.addPostFrameCallback((_) async {
///   if (!Storage.tutBookSeen) {
///     await showFeatureCoachSheet(context, FeatureCoach.book);
///     await Storage.setTutBookSeen();
///   }
/// });
/// ```
Future<void> showFeatureCoachSheet(
  BuildContext context,
  FeatureCoach coach,
) async {
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _FeatureCoachSheet(coach: coach),
  );
}

// ─────────────────────────────────────────────────────────────────────────────

class _FeatureCoachSheet extends StatelessWidget {
  final FeatureCoach coach;
  const _FeatureCoachSheet({required this.coach});

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);
    final s = SoriSurfaces.of(context);

    final title = _title(t);
    final steps = _steps(t);

    return Container(
      decoration: BoxDecoration(
        color: s.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(
        24,
        12,
        24,
        24 + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Grab handle
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: s.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // 마스코트
            const Mascot.tiger(
              size: 88,
              emotion: MascotEmotion.smile,
              animate: true,
            ),
            const SizedBox(height: 12),

            // 제목
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Pretendard',
                fontSize: 19,
                fontWeight: FontWeight.w900,
                color: s.text,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 16),

            // 번호 3스텝
            for (int i = 0; i < steps.length; i++) ...[
              _StepRow(index: i + 1, text: steps[i]),
              if (i < steps.length - 1) const SizedBox(height: 8),
            ],

            // 한도 노트 (책 한 컷 전용)
            if (coach == FeatureCoach.book) ...[
              const SizedBox(height: 8),
              Text(
                t.coachBookLimitNote,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Pretendard',
                  fontSize: 11.5,
                  color: s.textMuted,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],

            const SizedBox(height: 20),

            // CTA
            SoriButton.filled(
              label: t.coachBtnGotIt,
              fullWidth: true,
              onTap: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      ),
    );
  }

  String _title(AppL10n t) {
    switch (coach) {
      case FeatureCoach.book:
        return t.coachBookTitle;
      case FeatureCoach.vocabPack:
        return t.coachVocabPackTitle;
    }
  }

  List<String> _steps(AppL10n t) {
    switch (coach) {
      case FeatureCoach.book:
        return [t.coachBookStep1, t.coachBookStep2, t.coachBookStep3];
      case FeatureCoach.vocabPack:
        return [
          t.coachVocabPackStep1,
          t.coachVocabPackStep2,
          t.coachVocabPackStep3,
        ];
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _StepRow extends StatelessWidget {
  final int index;
  final String text;
  const _StepRow({required this.index, required this.text});

  @override
  Widget build(BuildContext context) {
    final s = SoriSurfaces.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 22,
          height: 22,
          decoration: BoxDecoration(
            color: SoriColors.primary.withValues(alpha: 0.16),
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: Text(
            '$index',
            style: const TextStyle(
              fontFamily: 'Pretendard',
              fontSize: 11,
              fontWeight: FontWeight.w900,
              color: SoriColors.primary,
              height: 1,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontFamily: 'Pretendard',
              fontSize: 13.5,
              height: 1.45,
              color: s.text,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}
