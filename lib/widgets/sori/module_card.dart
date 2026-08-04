import 'package:flutter/material.dart';

import '../../l10n/generated/app_localizations.dart';
import 'card.dart';
import 'tokens.dart';

/// **ModuleCard** — 모듈/게임 진입 미니 카드.
///
/// `home_screen.dart`의 private `_MiniModuleCard`를 public 컴포넌트로 추출.
/// 허브 3종(learn / practice / wordbook)과 홈에서 공유한다.
///
/// ```dart
/// ModuleCard(
///   icon: Icons.text_fields_rounded,
///   title: t.moduleHangulTitle,
///   subtitle: t.moduleHangulDesc,
///   accent: SoriColors.hangul,
///   onTap: () => Navigator.pushNamed(context, '/hangul'),
/// )
/// ```
class ModuleCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Color accent;
  final VoidCallback onTap;

  /// mini ribbon 상태 (null=없음, 'new'=신규, 'due'=복습대기)
  final String? ribbonType;
  final int? ribbonValue;

  const ModuleCard({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    required this.accent,
    required this.onTap,
    this.ribbonType,
    this.ribbonValue,
  });

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);
    final tt = SoriTextTheme.of(context);
    final comfortScale = soriComfortScale(MediaQuery.sizeOf(context).width);
    // passthrough: wenn die Karte im Grid eine feste (gestretchte) Höhe bekommt
    // (IntrinsicHeight + CrossAxisAlignment.stretch), füllt die SoriCard sie aus
    // → gleich hohe Karten pro Reihe. Ohne feste Höhe = Inhaltshöhe wie bisher.
    return Stack(
      fit: StackFit.passthrough,
      children: [
        SoriCard(
          variant: SoriCardVariant.base,
          onTap: onTap,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36 * comfortScale,
                height: 36 * comfortScale,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(
                    SoriRadius.sm * comfortScale,
                  ),
                ),
                alignment: Alignment.center,
                child: Icon(icon, size: 20 * comfortScale, color: accent),
              ),
              SizedBox(height: Spacing.sm * comfortScale),
              Text(title, style: tt.cardTitle),
              if (subtitle != null) ...[
                const SizedBox(height: 3),
                Text(
                  subtitle!,
                  style: tt.cardSubtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
        if (ribbonType != null)
          Positioned(
            top: 8,
            right: 8,
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: 6 * comfortScale,
                vertical: 3 * comfortScale,
              ),
              decoration: BoxDecoration(
                color: ribbonType == 'new'
                    ? SoriColors.success
                    : SoriColors.warning,
                borderRadius: BorderRadius.circular(4 * comfortScale),
              ),
              child: Text(
                ribbonType == 'new'
                    ? t.moduleBadgeNew
                    : ribbonValue != null
                    ? '$ribbonValue'
                    : t.moduleBadgeDue,
                style: tt.label.copyWith(
                  fontSize: 11 * comfortScale,
                  color: Colors.white,
                  letterSpacing: -0.1,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// **FeaturedModuleCard** — 섹션의 대표 진입(전폭 가로 카드).
///
/// 균일 2×N 그리드를 깨는 에디토리얼 위계용. 한지 텍스처 + 처마 모서리
/// (기존 hanji variant 활용) + 큰 아이콘 + 명조 제목 + chevron.
class FeaturedModuleCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Color accent;
  final VoidCallback onTap;
  final String? ribbonType; // 'new' → NEU 배지 (featured여도 유지)

  const FeaturedModuleCard({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    required this.accent,
    required this.onTap,
    this.ribbonType,
  });

  @override
  Widget build(BuildContext context) {
    final s = SoriSurfaces.of(context);
    final tt = SoriTextTheme.of(context);
    final t = AppL10n.of(context);
    final comfortScale = soriComfortScale(MediaQuery.sizeOf(context).width);
    final card = SoriCard(
      variant: SoriCardVariant.hanji,
      accent: accent,
      onTap: onTap,
      child: Row(
        children: [
          Container(
            width: 52 * comfortScale,
            height: 52 * comfortScale,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(SoriRadius.md * comfortScale),
            ),
            alignment: Alignment.center,
            child: Icon(icon, size: 28 * comfortScale, color: accent),
          ),
          SizedBox(width: Spacing.md * comfortScale),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // 명조 h2 (에디토리얼 히어로 제목).
                Text(
                  title,
                  style: tt.h2,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 3),
                  Text(
                    subtitle!,
                    style: tt.bodySmall,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          SizedBox(width: Spacing.sm * comfortScale),
          Icon(Icons.chevron_right_rounded, color: s.textDim),
        ],
      ),
    );
    if (ribbonType == null) return card;
    return Stack(
      children: [
        card,
        Positioned(
          top: 8,
          right: 8,
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: 6 * comfortScale,
              vertical: 3 * comfortScale,
            ),
            decoration: BoxDecoration(
              color: ribbonType == 'new'
                  ? SoriColors.success
                  : SoriColors.warning,
              borderRadius: BorderRadius.circular(4 * comfortScale),
            ),
            child: Text(
              ribbonType == 'new' ? t.moduleBadgeNew : t.moduleBadgeDue,
              style: tt.label.copyWith(
                fontSize: 11 * comfortScale,
                color: Colors.white,
                letterSpacing: -0.1,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
