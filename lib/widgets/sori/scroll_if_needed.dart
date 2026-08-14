import 'package:flutter/material.dart';

/// 학습 카드 안쪽의 세로 스크롤은 **짧은 뷰포트용 안전망**이지 주된 상호작용이
/// 아니다. 그런데 `Scrollable` 은 스크롤할 게 하나도 없어도 세로 드래그를
/// 제스처 아레나에서 가져간다 — 카드가 `SoriSwipeCard` 안에 있으면 더 깊은
/// 쪽(스크롤뷰)이 이겨서 **위/아래 스와이프가 통째로 먹힌다**.
///
/// 이 물리는 실제로 넘칠 때만 드래그를 받는다:
/// - 내용이 카드에 들어가면 → `Scrollable` 이 드래그를 아예 시작하지 않아
///   덱의 위/아래 스와이프(저장·스킵)가 정상 동작한다.
/// - 내용이 넘치면 → 평소처럼 스크롤된다. 넘치는 카드를 읽어야 하는 사용자가
///   우선이므로 그때는 스크롤이 스와이프를 이기는 게 맞다.
class ScrollOnlyIfOverflowing extends ScrollPhysics {
  const ScrollOnlyIfOverflowing({super.parent});

  @override
  ScrollOnlyIfOverflowing applyTo(ScrollPhysics? ancestor) =>
      ScrollOnlyIfOverflowing(parent: buildParent(ancestor));

  @override
  bool shouldAcceptUserOffset(ScrollMetrics position) {
    if (position.maxScrollExtent <= 0 && position.minScrollExtent >= 0) {
      return false;
    }
    return super.shouldAcceptUserOffset(position);
  }
}

/// 학습 카드 면(front/back)의 표준 스크롤 물리.
const ScrollPhysics kSoriCardFacePhysics = ScrollOnlyIfOverflowing(
  parent: ClampingScrollPhysics(),
);
