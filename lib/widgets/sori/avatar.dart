import 'package:flutter/material.dart';

import '../../l10n/generated/app_localizations.dart';
import 'mascot.dart';
import 'pressable.dart';
import 'tokens.dart';

/// **SoriAvatar** — 40dp 원형 프로필 진입점 (§W-G G3/G5.2).
///
/// [initials]가 있으면 2글자까지 대문자로 표시하고, 없으면 `Mascot.tiger`
/// 폴백으로 채운다. 모든 Sori Stage 루트 탭 헤더의 옛 프로필 `IconButton`
/// (`sori_stage_common.dart`의 `SoriStageRootHeader`)을 대체한다 — 두 곳
/// (구 아이콘 버튼·`SoriCollapsingHeader` trailing) 모두 같은 48dp 탭타깃 +
/// [AppL10n.soriStageProfileTooltip] 접근성 라벨 계약을 공유한다.
class SoriAvatar extends StatelessWidget {
  const SoriAvatar({
    super.key,
    this.initials,
    this.onTap,
    this.semanticLabel,
    this.size = 40,
  });

  /// 표시할 이니셜(최대 2글자, 대문자 변환은 이 위젯이 담당). null/빈 값이면
  /// 마스코트 폴백을 그린다. 이 앱은 아직 사용자 표시 이름을 저장하지 않아
  /// 프로덕션 호출부는 항상 null을 넘긴다 — 이니셜은 향후 프로필 이름이
  /// 생기면 바로 쓸 수 있게 열어 둔 시임이다.
  final String? initials;

  /// 기본은 `/profile`로 이동 — 기존 프로필 아이콘 버튼과 동일한 목적지.
  final VoidCallback? onTap;

  /// 기본은 기존 프로필 툴팁 문구([AppL10n.soriStageProfileTooltip]).
  final String? semanticLabel;

  /// 원 지름. 탭 영역 자체는 항상 48dp(WCAG 터치 타깃) — [CulturalHelpButton]
  /// 과 같은 예약폭이라 `SoriCollapsingHeader.trailingSlots` 산식과 맞는다.
  final double size;

  static const double _tapTarget = 48;

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);
    final label = semanticLabel ?? t.soriStageProfileTooltip;
    final trimmed = initials?.trim();
    final hasInitials = trimmed != null && trimmed.isNotEmpty;

    Widget content;
    if (hasInitials) {
      final letters = trimmed.characters.take(2).toString().toUpperCase();
      content = ColoredBox(
        color: SoriColors.primarySoft,
        child: Center(
          child: Text(
            letters,
            style: SoriTextTheme.of(context).label.copyWith(
              color: SoriColors.primaryOnLight,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ),
      );
    } else {
      content = ColoredBox(
        color: SoriColors.primarySoft,
        child: FittedBox(
          fit: BoxFit.cover,
          child: Mascot.tiger(size: size * 1.6),
        ),
      );
    }

    // §17/§18 raw InkWell 금지 래칫 — SoriPressable(scale + haptic)이 이
    // 디자인 시스템의 정본 탭 반응이다.
    return Semantics(
      button: true,
      label: label,
      child: SoriPressable(
        onTap: onTap ?? () => Navigator.of(context).pushNamed('/profile'),
        child: SizedBox.square(
          dimension: _tapTarget,
          child: Center(
            child: ExcludeSemantics(
              child: ClipOval(
                child: SizedBox(width: size, height: size, child: content),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
