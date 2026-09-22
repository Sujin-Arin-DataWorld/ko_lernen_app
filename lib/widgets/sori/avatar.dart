import 'package:flutter/material.dart';

import '../../l10n/generated/app_localizations.dart';
import 'mascot.dart';
import 'mascot_preference.dart';
import 'pressable.dart';
import 'tokens.dart';

/// **SoriAvatar** — 40dp 원형 프로필 진입점 (§W-G G3/G5.2).
///
/// 프로필과 같은 선택 캐릭터를 표시하고 변경을 즉시 구독한다.
/// 캐릭터를 숨겼으면 일반 프로필 아이콘을 표시한다.
/// 모든 Sori Stage 루트 탭 헤더의 옛 프로필 `IconButton`
/// (`sori_stage_common.dart`의 `SoriStageRootHeader`)을 대체한다 — 두 곳
/// (구 아이콘 버튼·`SoriCollapsingHeader` trailing) 모두 같은 48dp 탭타깃 +
/// [AppL10n.soriStageProfileTooltip] 접근성 라벨 계약을 공유한다.
class SoriAvatar extends StatelessWidget {
  const SoriAvatar({super.key, this.onTap, this.semanticLabel, this.size = 40});

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
                child: SizedBox.square(
                  dimension: size,
                  child: ColoredBox(
                    color: SoriColors.primarySoft,
                    child: CompanionBuilder(
                      builder: (_, kind) => Mascot(
                        kind: kind,
                        emotion: MascotEmotion.neutral,
                        size: size,
                      ),
                      noneBuilder: (_) => Icon(
                        Icons.person_outline_rounded,
                        size: size * 0.65,
                        color: SoriColors.primaryOnLight,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
