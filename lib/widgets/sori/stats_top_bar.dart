import 'package:flutter/material.dart';

import '../../l10n/generated/app_localizations.dart';
import 'pressable.dart';
import 'tokens.dart';

/// **SoriStatsTopBar** — 워드마크 + 스트릭/레벨 칩 + 설정 진입.
///
/// 2026-08-14 Phase 2a: `home_screen.dart` 의 `_TopBar` 를 **본문 그대로**
/// 공용화 (홈 레이아웃 테스트 무변경이 추출 증명). SoriStage Today 가 두 번째
/// 소비자다 — 스트릭 칩=주간 시트, 레벨 칩=/stats 라는 §6.1 블록 1 계약 유지.
class SoriStatsTopBar extends StatelessWidget {
  final int streak;
  final int level;
  final int xp;
  final VoidCallback onStreakTap;
  final VoidCallback onStatsTap;

  /// 프로필 진입 아이콘(선택) — SoriStage Today 처럼 하단 탭에 프로필이 없는
  /// 셸에서만 켠다. 홈(레거시 셸)은 탭에 이미 있어 null(미표시) 유지.
  final VoidCallback? onProfileTap;

  /// [onProfileTap] 아이콘의 툴팁/시맨틱 라벨 (l10n 은 호출부 소관).
  final String? profileTooltip;

  const SoriStatsTopBar({
    super.key,
    required this.streak,
    required this.level,
    required this.xp,
    required this.onStreakTap,
    required this.onStatsTap,
    this.onProfileTap,
    this.profileTooltip,
  });

  @override
  Widget build(BuildContext context) {
    final s = SoriSurfaces.of(context);
    final t = AppL10n.of(context);

    // 헤더 크롬은 배율 1.4 에서 클램프 — 390dp + 200% 에서 칩·아이콘 행이
    // 폭을 넘친다(2026-08-14 실측 8px). 시트가 1.3 을 클램프하는 것과 같은
    // 계열의 결정: 칩은 숫자/짧은 라벨이라 1.4 로도 읽히고, 본문·인사말은
    // 이 위젯 밖이라 시스템 배율을 그대로 따른다.
    return MediaQuery.withClampedTextScaling(
      maxScaleFactor: 1.4,
      child: _bar(context, s, t),
    );
  }

  /// 프로필 버튼이 켜지면 예약해야 하는 추가 폭 (40dp 원판 48dp 타깃 + 간격).
  static const double _kProfileReserve = 56;

  /// 워드마크 **텍스트**를 그릴 최소 행 폭. 이보다 좁으면 로고만 남긴다 —
  /// "Hangul…" 식 말줄임 브랜드보다 로고 단독이 낫다. 홈(프로필 없음)은
  /// 예약폭 0 이라 기존 360dp 폰 표시가 그대로다. (창 분류가 아니라 이 행
  /// 전용 밀도 임계값 — 칩·48dp 타깃 실측 합에서 나온 값.)
  static const double _kWordmarkTextMinWidth = 320;

  /// 레벨 칩을 유지할 최소 행 폭 — 308dp 초협폭(분할 화면)에서는 스트릭
  /// 칩만 남긴다. 레벨/XP 상세는 어차피 /stats 가 정본.
  static const double _kLevelChipMinWidth = 240;

  Widget _bar(BuildContext context, SoriSurfaces s, AppL10n t) {
    return Column(
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            final double w = constraints.maxWidth;
            final double reserve = onProfileTap != null ? _kProfileReserve : 0;
            final bool showWordmarkText = w >= _kWordmarkTextMinWidth + reserve;
            final bool showLevelChip = w >= _kLevelChipMinWidth + reserve;
            return Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.asset(
                    'assets/icons/icon-192.png',
                    width: 36,
                    height: 36,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(width: Spacing.sm),
                Expanded(
                  child: showWordmarkText
                      ? Text(
                          'Hangul Sori',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontFamily: SoriFonts.sans,
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            color: s.text,
                            letterSpacing: -0.3,
                          ),
                        )
                      : const SizedBox.shrink(),
                ),
                // §6.1 블록 1: 스탯을 헤더 칩 1줄로 — 🔥는 아이콘으로만(이모지
                // 글리프 금지). 스트릭 칩 탭 = 주간 시트, 레벨 칩 탭 = /stats.
                _HeaderChip(
                  icon: Icons.local_fire_department_rounded,
                  color: SoriColors.warning,
                  label: '$streak',
                  semanticLabel: '$streak ${t.statsDays}',
                  onTap: onStreakTap,
                ),
                const SizedBox(width: Spacing.sm),
                if (showLevelChip) ...[
                  _HeaderChip(
                    icon: Icons.stars_rounded,
                    color: SoriColors.primary,
                    label: 'Lv $level',
                    semanticLabel: 'Lv $level · $xp XP',
                    onTap: onStatsTap,
                  ),
                  const SizedBox(width: Spacing.sm),
                ],
                if (onProfileTap != null)
                  Tooltip(
                    message: profileTooltip ?? '',
                    child: _RoundIconButton(
                      icon: Icons.person_outline_rounded,
                      semanticLabel: profileTooltip,
                      onTap: onProfileTap!,
                    ),
                  ),
                // 2026-07-31: 아이콘 4개 → 1개.
                // 학습그룹·프로필은 하단 탭에 이미 있어 중복 진입점이었고
                // (SC 3.2.3), 통계는 프로필 안에서 갈 수 있다. 설정만 남긴다 —
                // 하단 탭에 없는 유일한 목적지.
                _RoundIconButton(
                  icon: Icons.settings_outlined,
                  semanticLabel: t.settingsTitle,
                  onTap: () => Navigator.pushNamed(context, '/settings'),
                ),
              ],
            );
          },
        ),
        const SizedBox(height: Spacing.lg),
      ],
    );
  }
}

/// 헤더 스탯 칩 — 표면 v2(라이트 무테두리 + low 그림자 / 다크 테두리),
/// 시각 32dp + 상하 패딩으로 48dp 터치 타깃 확보.
class _HeaderChip extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final String semanticLabel;
  final VoidCallback onTap;

  const _HeaderChip({
    required this.icon,
    required this.color,
    required this.label,
    required this.semanticLabel,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final s = SoriSurfaces.of(context);
    final isLight = s.brightness == Brightness.light;
    return Semantics(
      button: true,
      label: semanticLabel,
      child: SoriPressable(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: Spacing.sm),
          child: Container(
            height: 32,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              color: isLight ? SoriColors.lightSurfaceRaised : s.surface,
              borderRadius: SoriRadius.brPill,
              boxShadow: isLight ? SoriElevation.low : null,
              border: isLight
                  ? null
                  : Border.all(color: SoriColors.darkBorderStrong, width: 1.5),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 14, color: color),
                const SizedBox(width: 4),
                Text(
                  label,
                  style: SoriTextTheme.of(context).label.copyWith(
                    fontSize: 12.5,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RoundIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final String? semanticLabel;
  const _RoundIconButton({
    required this.icon,
    required this.onTap,
    this.semanticLabel,
  });

  @override
  Widget build(BuildContext context) {
    final s = SoriSurfaces.of(context);
    // 눌리는 영역은 48dp(Material 최소 권고), 보이는 원판은 40dp.
    // 이전엔 36dp 원판이 곧 터치 타깃이라 손가락으로 놓치기 쉬웠다.
    return Semantics(
      button: true,
      label: semanticLabel,
      child: SoriPressable(
        onTap: onTap,
        haptic: SoriHaptic.selection,
        child: SizedBox(
          width: 48,
          height: 48,
          child: Center(
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: s.surface.withValues(alpha: 0.62),
                shape: BoxShape.circle,
                border: Border.all(color: SoriColors.lightBorderStrong),
              ),
              child: Icon(icon, size: 20, color: s.textMuted),
            ),
          ),
        ),
      ),
    );
  }
}
