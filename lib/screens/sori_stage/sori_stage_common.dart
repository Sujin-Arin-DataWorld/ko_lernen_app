import 'package:flutter/material.dart';

import '../../widgets/sori/avatar.dart';
import '../../widgets/sori/page_header.dart';
import '../../widgets/sori/responsive.dart';

// §C-1-10: 정본은 widgets/sori/activity_illustration.dart 에 있다.
export '../../widgets/sori/activity_illustration.dart'
    show soriActivityColor, soriActivityIcon;

// §C-3c P0-1: 정본은 widgets/sori/localized_copy.dart.
export '../../widgets/sori/localized_copy.dart' show localCopy;

/// Sori Stage의 헤더·본문·하단 행동을 flex로 유지할 수 있는 최소 가용 높이.
///
/// 이 값은 전체 화면 높이가 아니라 [SafeArea] 안쪽의 실제 제약과 비교한다.
/// 일반 390×844 세로 화면은 기존 레이아웃을 유지하고, 짧은 분할 화면에서만
/// [SoriMinHeightScroll]이 하단 행동까지 도달 가능한 스크롤을 제공한다.
const double kSoriStageMinimumUsableHeight = 640;

double soriStageChromeMinHeight(BoxConstraints safeConstraints) {
  final available = safeConstraints.maxHeight;
  if (!available.isFinite || available < kSoriStageMinimumUsableHeight) {
    return kSoriStageMinimumUsableHeight;
  }
  return available;
}

/// [SafeArea] 내부 제약으로 Stage의 가용 높이를 계산하는 공용 프레임.
class SoriStageSafeViewport extends StatelessWidget {
  const SoriStageSafeViewport({
    super.key,
    required this.child,
    this.largeTextChildBuilder,
  });

  final Widget child;
  final Widget Function(BuildContext context, BoxConstraints safeConstraints)?
  largeTextChildBuilder;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final textScale = MediaQuery.textScalerOf(context).scale(1);
          final largeTextChild = largeTextChildBuilder;
          return SoriMinHeightScroll(
            minHeight: soriStageChromeMinHeight(constraints),
            child: textScale >= 1.6 && largeTextChild != null
                ? largeTextChild(context, constraints)
                : child,
          );
        },
      ),
    );
  }
}

/// SoriStage 루트 탭 공용 헤더 — 2026-08-13 부터 [SoriPageHeader] 에 위임.
/// (eyebrow/hero 위계는 토큰화된 공용판이 소유하고, 여기는 프로필 진입
/// 아이콘과 대문자화 정책만 담당한다.)
class SoriStageRootHeader extends StatelessWidget {
  const SoriStageRootHeader({
    super.key,
    required this.eyebrow,
    required this.title,
    this.body,
  });

  final String eyebrow;
  final String title;
  final String? body;

  @override
  Widget build(BuildContext context) {
    return SoriPageHeader(
      eyebrow: eyebrow.toUpperCase(),
      title: title,
      body: body,
      // §W-G G3: 프로필 진입 아이콘 → SoriAvatar (이니셜/마스코트 폴백).
      trailing: const SoriAvatar(),
    );
  }
}
