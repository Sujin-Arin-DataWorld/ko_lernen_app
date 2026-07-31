import 'package:flutter/material.dart';

import '../../l10n/generated/app_localizations.dart';
import '../../models/pack_progress.dart';
import 'pressable.dart';
import 'progress.dart';
import 'tokens.dart';

/// **PathNode** — 학습 경로의 단어팩 노드 위젯.
///
/// learning_path_screen.dart의 `_PathNode` 를 공유 위젯으로 추출.
/// 홈 임베드 + Lernpfad 화면 양쪽에서 사용.
///
/// 상태에 따른 외관:
/// - cleared : 녹청 링 + 체크 아이콘
/// - isNow   : 호랑이 주황 링 + 재생 아이콘 + "Jetzt" 배지
/// - locked  : 테두리색 링 + 자물쇠 아이콘 + opacity 0.62
/// - 기타     : 황금 링 + 재생 아이콘 + 진행 바
class PathNode extends StatelessWidget {
  const PathNode({
    super.key,
    required this.label,
    required this.status,
    required this.fraction,
    required this.isNow,
    required this.onTap,
  });

  final String label;
  final PackStatus status;
  final double fraction;
  final bool isNow;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);
    final s = SoriSurfaces.of(context);
    final cleared = status == PackStatus.cleared;
    final locked = status == PackStatus.locked;

    final Color ringColor = cleared
        ? SoriColors.primary
        : isNow
            ? SoriColors.tiger
            : locked
                ? s.border
                : SoriColors.gold;

    return Padding(
      padding: const EdgeInsets.only(bottom: Spacing.sm),
      child: SoriPressable(
        onTap: onTap,
        haptic: locked ? SoriHaptic.light : SoriHaptic.selection,
        child: Opacity(
          opacity: locked ? 0.62 : 1.0,
          child: Container(
            padding: const EdgeInsets.all(Spacing.md),
            decoration: BoxDecoration(
              color: isNow
                  ? SoriColors.tiger.withValues(alpha: 0.08)
                  : s.surface,
              borderRadius: SoriRadius.brMd,
              border: Border.all(
                color: isNow ? SoriColors.tiger : s.border,
                width: isNow ? 1.6 : 1,
              ),
            ),
            child: Row(
              children: [
                _buildIcon(ringColor, cleared, locked),
                const SizedBox(width: Spacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              label,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: s.text,
                              ),
                            ),
                          ),
                          if (isNow) ...[
                            const SizedBox(width: Spacing.sm),
                            _buildNowBadge(t),
                          ],
                        ],
                      ),
                      if (!locked && !cleared && fraction > 0) ...[
                        const SizedBox(height: 6),
                        SoriProgressBar(value: fraction, thickness: 5),
                      ],
                    ],
                  ),
                ),
                Icon(
                  locked ? Icons.lock_outline : Icons.chevron_right,
                  size: 20,
                  color: s.textDim,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildIcon(Color ring, bool cleared, bool locked) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: cleared ? SoriColors.primary : Colors.transparent,
        border: Border.all(color: ring, width: 2.4),
      ),
      alignment: Alignment.center,
      child: Icon(
        cleared
            ? Icons.check
            : locked
                ? Icons.lock_outline
                : Icons.play_arrow_rounded,
        size: 20,
        color: cleared ? Colors.white : ring,
      ),
    );
  }

  Widget _buildNowBadge(AppL10n t) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: SoriColors.tiger,
        borderRadius: SoriRadius.brPill,
      ),
      child: Text(
        t.pathNodeNow,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          // 흰 글씨 on tiger = 2.3:1 (AA 미달). 먹색이면 7.2:1.
          color: SoriColors.onTigerFill,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}
