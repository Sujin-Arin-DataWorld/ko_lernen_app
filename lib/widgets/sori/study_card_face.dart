import 'package:flutter/material.dart';

import 'card.dart';
import 'tokens.dart';

/// **StudyCardFace** — 학습 카드(플래시카드)용 hero 카드 표면.
///
/// 플래시카드 화면들이 공통으로 쓰던 잘못된 패턴
/// (`SoriCard > SingleChildScrollView > Center > Column(min)`)을 대체한다.
/// 그 패턴은 `SingleChildScrollView`가 자식에게 무한 높이를 줘 `Center`를
/// 무력화 → 콘텐츠가 카드 상단에 쏠리고 아래가 텅 비었다(void 버그).
///
/// 여기서는 **LayoutBuilder + ConstrainedBox(minHeight) + IntrinsicHeight +
/// Column(center)** 레시피로 콘텐츠를 카드 높이에 맞춰 **수직 중앙 정렬**하고,
/// 콘텐츠가 카드보다 길 때만 스크롤한다(텍스트 스케일 1.3·작은 화면 안전).
///
/// ⚠️ `IntrinsicHeight` 안에서는 `Spacer`/`Flexible`/`Expanded`·중첩
/// `LayoutBuilder`를 직접 자식으로 두면 안 된다. 간격은 [alignment]와
/// `SizedBox`로 준다.
///
/// 사용:
/// ```dart
/// StudyCardFace(
///   accent: SoriColors.warning,
///   children: [
///     SoriChip(label: g.level),
///     const SizedBox(height: 14),
///     Text(g.pattern, ...),
///   ],
/// )
/// ```
class StudyCardFace extends StatelessWidget {
  final List<Widget> children;

  /// 카드 border + tap 모션 강조색.
  final Color accent;

  /// 콘텐츠 블록의 수직 정렬. 기본 center → void 제거.
  final MainAxisAlignment alignment;

  final CrossAxisAlignment crossAxisAlignment;

  final EdgeInsetsGeometry? padding;

  /// 부모(Expanded 등)가 준 높이 중 카드가 차지할 비율. 1.0이면 가득 채운다.
  /// <1.0이면 글자 수와 무관하게 그 비율 높이로 **고정**하고 상하 여백을 남긴다
  /// (예: 0.82 — 단어가 짧아도 쪼그라들지 않고, 코치마크·버튼 공간을 확보).
  final double heightFactor;

  const StudyCardFace({
    super.key,
    required this.children,
    this.accent = SoriColors.primary,
    this.alignment = MainAxisAlignment.center,
    this.crossAxisAlignment = CrossAxisAlignment.center,
    this.padding,
    this.heightFactor = 1.0,
  });

  @override
  Widget build(BuildContext context) {
    final card = SoriCard(
      variant: SoriCardVariant.hero,
      accent: accent,
      width: double.infinity,
      padding: padding,
      child: LayoutBuilder(
        builder: (context, constraints) {
          // FlipCard/Expanded가 tight height를 주면 maxHeight는 유한.
          // 혹시 무한(unbounded)이면 0으로 떨어뜨려 콘텐츠 높이에 맞춤.
          final minH = constraints.maxHeight.isFinite
              ? constraints.maxHeight
              : 0.0;
          return SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: minH),
              child: IntrinsicHeight(
                child: Column(
                  mainAxisAlignment: alignment,
                  crossAxisAlignment: crossAxisAlignment,
                  children: children,
                ),
              ),
            ),
          );
        },
      ),
    );
    if (heightFactor >= 1.0) {
      return card;
    }
    // 글자 수와 무관하게 고정 비율 높이 + 상하 여백(중앙 정렬).
    return Center(
      child: FractionallySizedBox(heightFactor: heightFactor, child: card),
    );
  }
}
