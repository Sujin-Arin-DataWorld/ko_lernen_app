import 'package:flutter/material.dart';

import '../../l10n/generated/app_localizations.dart';
import '../../models/pack_progress.dart';
import 'path_trail.dart';
import 'pressable.dart';
import 'tokens.dart';

/// **PathPreviewRow** — 홈 블록 4 "이어지는 길" 미리보기 (계획 §6.1·§10.2).
///
/// Lernpfad 현재 노드 ±1 = 3노드 가로 스트립 + "Ganzer Pfad →". 노드 시각은
/// `path_trail.dart` 문법([SoriPathNodeDisc] — 도장·황금 링·잠금 회색조)을
/// 재사용하고, 클립은 재생하지 않는다(홈 히어로가 클립 — 디코더 ≤1 계약).
/// 전량 경로와 100% 트리거는 `/path` 전용 화면 몫(§6.2).
class PathPreviewRow extends StatelessWidget {
  /// 정확히 현재 ±1 슬라이스 (호출측이 계산). 3개 미만이면 있는 만큼.
  final List<SoriPathStop> stops;
  final VoidCallback onSeeAll;

  const PathPreviewRow({
    super.key,
    required this.stops,
    required this.onSeeAll,
  });

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final stop in stops) Expanded(child: _PreviewNode(stop: stop)),
        Padding(
          // 디스크 중심선 근처로 시각 정렬.
          padding: const EdgeInsets.only(top: 20),
          child: TextButton(
            onPressed: onSeeAll,
            style: TextButton.styleFrom(
              foregroundColor: SoriColors.primary,
              padding: const EdgeInsets.symmetric(horizontal: Spacing.sm),
              minimumSize: const Size(48, 48),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  t.pathSeeAll,
                  style: SoriTextTheme.of(
                    context,
                  ).label.copyWith(color: SoriColors.primary),
                ),
                const SizedBox(width: 2),
                const Icon(Icons.chevron_right, size: 14),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _PreviewNode extends StatelessWidget {
  final SoriPathStop stop;
  const _PreviewNode({required this.stop});

  @override
  Widget build(BuildContext context) {
    final s = SoriSurfaces.of(context);
    final locked = stop.status == PackStatus.locked;
    return Semantics(
      button: true,
      // 미리보기 노드는 전부 탭 가능(비현재 노드도 /path로 이동) —
      // SoriPathStop.onTap은 비-nullable이라 null 검사 불필요.
      enabled: true,
      label: stop.label,
      child: SoriPressable(
        onTap: stop.onTap,
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: SoriPathTrail.discBox,
              child: Center(child: SoriPathNodeDisc(stop: stop)),
            ),
            const SizedBox(height: 4),
            Text(
              stop.label,
              textAlign: TextAlign.center,
              // §4.3: 1줄 ellipsis 금지 — 2줄 허용.
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12,
                height: 1.3,
                fontWeight: locked ? FontWeight.w600 : FontWeight.w700,
                // 잠금도 본문 대비 유지 — opacity로 뭉개지 않는다(§4.4-3).
                color: locked ? s.textMuted : s.text,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
