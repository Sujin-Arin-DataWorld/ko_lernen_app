import 'package:flutter/material.dart';

import '../../l10n/generated/app_localizations.dart';
import 'motion.dart';
import 'tokens.dart';

/// **4지선다 답안 버튼 — 즉시 누름 피드백 + 정답 공개**
///
/// 시각 전용 위젯이다. 햅틱·효과음·채점·SRS 갱신은 부모 화면이 [onSelected]
/// 안에서 처리한다 (관심사 분리 → 화면별 보상 로직 자유).
///
/// 상태:
/// - **idle**: 중립 surface + 옅은 primary 테두리. 누르면 scale-down(탄력)으로
///   "제출" 촉감 (reduce-motion 시 정지).
/// - **revealed** ([revealed] = true): 정답 옵션은 **항상** 초록으로 표시되어
///   학습자가 정답을 확인할 수 있고(오답을 골랐어도), 선택한 오답은 빨강으로
///   표시된다. 나머지는 흐려진다. Duolingo·Quizlet의 정답 공개 패턴.
class QuizChoice extends StatefulWidget {
  /// 표시 텍스트(보기).
  final String text;

  /// 이 보기가 정답인지.
  final bool isCorrect;

  /// 사용자가 이 보기를 골랐는지.
  final bool isSelected;

  /// 답이 잠겼는지(공개 단계) — 정답/오답 색을 보일지 결정.
  final bool revealed;

  /// null 이면 탭 비활성(잠금 후). 탭하면 즉시 호출(부모가 채점).
  final VoidCallback? onSelected;

  /// 선택 보조 설명(로마자·품사 등). 없으면 미표시.
  final String? subtitle;

  /// 최소 높이(dp). null이면 콘텐츠 높이. 넉넉한 화면을 채워야 하는 화면
  /// (단어팩 등)에서 보기 박스를 더 크게·탭하기 쉽게 만들 때만 지정.
  final double? minHeight;

  /// idle 상태의 경계색 override. null이면 기존의 옅은 primary 경계를 유지한다.
  final Color? idleBorderColor;

  /// 앱 소유 semantics에 탭 action을 노출할지 여부. 기존 소비 화면의 semantics
  /// 계약을 바꾸지 않고 접근성 경로를 단계적으로 잠글 때만 활성화한다.
  final bool semanticTapEnabled;

  /// 정답을 초록으로 **드러낼지**. 오답 재시도가 허용된 게임(Lückentext·
  /// Tages-Challenge)에서는 틀린 순간 정답이 보이면 재시도가 무의미해지므로
  /// `false` 로 넘겨 **고른 오답만 빨갛게** 표시한다.
  final bool revealCorrect;

  const QuizChoice({
    super.key,
    required this.text,
    required this.isCorrect,
    this.isSelected = false,
    this.revealed = false,
    this.onSelected,
    this.subtitle,
    this.minHeight,
    this.idleBorderColor,
    this.semanticTapEnabled = false,
    this.revealCorrect = true,
  });

  @override
  State<QuizChoice> createState() => _QuizChoiceState();
}

class _QuizChoiceState extends State<QuizChoice>
    with SingleTickerProviderStateMixin {
  late final AnimationController _press;

  @override
  void initState() {
    super.initState();
    _press = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
    );
  }

  @override
  void dispose() {
    _press.dispose();
    super.dispose();
  }

  void _handleTap() {
    final cb = widget.onSelected;
    if (cb == null || widget.revealed) {
      return;
    }
    // 즉시 누름 애니메이션(있으면) → 그 직후 부모 콜백(채점).
    if (!SoriMotion.reduceMotion(context)) {
      _press.forward().then((_) {
        if (mounted) {
          _press.reverse();
        }
      });
    }
    cb();
  }

  @override
  Widget build(BuildContext context) {
    final s = SoriSurfaces.of(context);
    final t = AppL10n.of(context);
    final reduce = SoriMotion.reduceMotion(context);

    // ── 색 결정 (revealed 단계가 우선) ──
    Color bg = s.surface;
    Color border =
        widget.idleBorderColor ?? SoriColors.primary.withValues(alpha: 0.25);
    final Color fg = s.text;
    double opacity = 1.0;
    IconData? trailing;
    Color? trailingColor;
    String? semanticValue;

    if (widget.revealed) {
      if (widget.isCorrect && widget.revealCorrect) {
        bg = SoriColors.success.withValues(alpha: 0.14);
        border = SoriColors.success;
        trailing = Icons.check_circle_rounded;
        trailingColor = SoriColors.success;
        semanticValue = t.statsCorrect;
      } else if (widget.isSelected && !widget.isCorrect) {
        bg = SoriColors.danger.withValues(alpha: 0.14);
        border = SoriColors.danger;
        trailing = Icons.cancel_rounded;
        trailingColor = SoriColors.danger;
        semanticValue = t.statsWrong;
      } else if (widget.revealCorrect) {
        // 선택 안 된 오답 — 흐리게.
        opacity = 0.55;
      }
    }

    final content = AnimatedContainer(
      duration: SoriMotion.respect(context, SoriAnimation.quick),
      curve: Curves.easeOut,
      width: double.infinity,
      constraints: widget.minHeight != null
          ? BoxConstraints(minHeight: widget.minHeight!)
          : null,
      decoration: BoxDecoration(
        color: bg,
        border: Border.all(color: border, width: 1.6),
        borderRadius: BorderRadius.circular(SoriRadius.md),
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: Spacing.lg,
        vertical: Spacing.md,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  widget.text,
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    color: fg,
                  ),
                ),
                if (widget.subtitle != null &&
                    widget.subtitle!.trim().isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    widget.subtitle!,
                    style: TextStyle(fontSize: 13, color: s.textMuted),
                  ),
                ],
              ],
            ),
          ),
          if (trailing != null) ...[
            const SizedBox(width: Spacing.sm),
            Icon(trailing, color: trailingColor, size: 24),
          ],
        ],
      ),
    );

    final tappable = Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: widget.onSelected == null || widget.revealed ? null : _handleTap,
        borderRadius: BorderRadius.circular(SoriRadius.md),
        child: content,
      ),
    );

    final reveal = AnimatedOpacity(
      duration: SoriMotion.respect(context, SoriAnimation.quick),
      opacity: opacity,
      child: tappable,
    );

    final enabled = widget.onSelected != null && !widget.revealed;
    if (reduce) {
      return Semantics(
        button: true,
        enabled: enabled,
        selected: widget.isSelected,
        label: widget.text,
        value: semanticValue,
        hint: widget.subtitle,
        onTap: widget.semanticTapEnabled && enabled ? _handleTap : null,
        excludeSemantics: true,
        child: reveal,
      );
    }

    return Semantics(
      button: true,
      enabled: enabled,
      selected: widget.isSelected,
      label: widget.text,
      value: semanticValue,
      hint: widget.subtitle,
      onTap: widget.semanticTapEnabled && enabled ? _handleTap : null,
      excludeSemantics: true,
      child: AnimatedBuilder(
        animation: _press,
        builder: (_, child) {
          final scale = 1.0 - 0.04 * _press.value;
          return Transform.scale(scale: scale, child: child);
        },
        child: reveal,
      ),
    );
  }
}
