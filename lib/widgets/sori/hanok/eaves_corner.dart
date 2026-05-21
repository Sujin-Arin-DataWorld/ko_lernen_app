import 'package:flutter/material.dart';

/// **EavesCorner** — 처마(eaves) 비대칭 BorderRadius helper.
///
/// 한옥 지붕 처마는 위쪽이 살짝 휘어 올라가는 곡선이 특징.
/// SoriCard의 BorderRadius를 비대칭으로 만들어 그 느낌을 모방:
/// - 상단 좌/우: 더 큰 radius (처마 끝 살짝 들어 올린 느낌)
/// - 하단 좌/우: 기본 radius (땅에 안정적으로 닿은 느낌)
///
/// 사용:
/// ```dart
/// Container(
///   decoration: BoxDecoration(
///     borderRadius: EavesCorner.borderRadius(base: 16, boost: 8),
///     // → top 24 / bottom 16
///   ),
/// )
/// ```
///
/// 또는 BorderRadius extension:
/// ```dart
/// BorderRadius.circular(16).eaves(boost: 6)
/// // → top 22 / bottom 16
/// ```
class EavesCorner {
  EavesCorner._();

  /// 처마 비대칭 BorderRadius 생성.
  /// [base] = 카드 기본 corner (예: SoriRadius.md = 16)
  /// [boost] = 상단 corner 추가 보정 (기본 8 — 너무 크면 부자연스러움)
  static BorderRadius borderRadius({required double base, double boost = 8}) {
    return BorderRadius.only(
      topLeft: Radius.circular(base + boost),
      topRight: Radius.circular(base + boost),
      bottomLeft: Radius.circular(base),
      bottomRight: Radius.circular(base),
    );
  }
}

/// BorderRadius extension — 기존 radius에 처마 boost 적용.
extension EavesCornerExt on BorderRadius {
  BorderRadius eaves({double boost = 8}) {
    return BorderRadius.only(
      topLeft: topLeft + Radius.circular(boost),
      topRight: topRight + Radius.circular(boost),
      bottomLeft: bottomLeft,
      bottomRight: bottomRight,
    );
  }
}
