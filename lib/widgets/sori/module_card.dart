import 'package:flutter/material.dart';

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
    final s = SoriSurfaces.of(context);
    return Stack(
      children: [
        SoriCard(
          variant: SoriCardVariant.base,
          onTap: onTap,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(SoriRadius.sm),
                ),
                alignment: Alignment.center,
                child: Icon(icon, size: 20, color: accent),
              ),
              const SizedBox(height: Spacing.sm),
              Text(
                title,
                style: TextStyle(
                  fontFamily: 'Pretendard',
                  color: s.text,
                  fontWeight: FontWeight.w800,
                  fontSize: 13.5,
                  letterSpacing: -0.2,
                  height: 1.2,
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 3),
                Text(
                  subtitle!,
                  style: TextStyle(
                    fontFamily: 'Pretendard',
                    color: s.textMuted,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w500,
                    height: 1.35,
                  ),
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
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
              decoration: BoxDecoration(
                color: ribbonType == 'new'
                    ? SoriColors.success
                    : SoriColors.warning,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                ribbonType == 'new'
                    ? 'NEU'
                    : ribbonValue != null
                        ? '$ribbonValue'
                        : 'DUE',
                style: const TextStyle(
                  fontFamily: 'Pretendard',
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  letterSpacing: -0.3,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
