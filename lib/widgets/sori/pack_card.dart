import 'package:flutter/material.dart';

import '../../data/pack_artwork_catalog.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../models/pack_progress.dart';
import 'dancheong_stamp.dart';
import 'illustrated_card.dart';
import 'tokens.dart';

/// Pack-Karten Tile für die Pack-Marktplatz-Grid.
///
/// 2026-08-13 UI 개편 Phase 1: [SoriIllustratedCard] 규격으로 재구성 —
/// 상단에 승인된 팩 전용 일러스트를 우선 표시하고, 아직 제작되지 않은 팩은
/// motif 일러스트(`assets/illustrations/packs/{motif}.webp`)를 유지한다.
/// 이미지 로드 실패 시 최종 폴백은 기존 단청 도장이다.
///
/// Zwei sichtbare Zustände:
///   - **available / inProgress** — 일러스트 + Progress-Dots + Tap-Action.
///   - **cleared**  — DancheongStamp Overlay rechts oben + tap nochmal.
/// 저장된 레거시 `locked` 값도 직접 열 수 있는 일반 카드로 표시한다.
class PackCard extends StatelessWidget {
  final String packId;
  final String title;
  final PackProgress progress;
  final VoidCallback? onTap;

  const PackCard({
    super.key,
    required this.packId,
    required this.title,
    required this.progress,
    this.onTap,
  });

  bool get _cleared => progress.status == PackStatus.cleared;

  @override
  Widget build(BuildContext context) {
    final motif = motifForPackId(packId);

    return SoriIllustratedCard(
      title: title,
      state: _cleared
          ? SoriIllustratedCardState.cleared
          : SoriIllustratedCardState.normal,
      illustrationAsset: PackArtworkCatalog.assetFor(packId, motif),
      fallback: DancheongStamp(motif: motif, size: 44, animate: false),
      overlay: _cleared
          ? DancheongStamp(
              motif: motif,
              size: 44,
              animate: false,
              stamped: true,
            )
          : null,
      footer: _BottomRow(progress: progress),
      onTap: onTap,
      semanticsLabel: _semanticsLabel(context),
    );
  }

  /// 스크린리더에 그대로 읽히는 문구다 — 하드코딩 독일어를 두면 EN 사용자가
  /// 화면 전체를 독일어로 듣게 된다 (2026-08-18 l10n 스윕에서 발견).
  String _semanticsLabel(BuildContext context) {
    final t = AppL10n.of(context);
    final state = _cleared ? t.packStateCleared : t.packStateAvailable;
    return t.packSemantics(
      title,
      state,
      progress.wordsLearned,
      progress.wordsTotal,
    );
  }
}

class _BottomRow extends StatelessWidget {
  final PackProgress progress;
  const _BottomRow({required this.progress});

  @override
  Widget build(BuildContext context) {
    final s = SoriSurfaces.of(context);
    const accent = SoriColors.info;

    final total = progress.wordsTotal;
    final learned = progress.wordsLearned.clamp(0, total);
    // Show up to 10 dots; if total > 10, fall back to "N/M" text
    if (total <= 10) {
      return Row(
        children: List.generate(total, (i) {
          final filled = i < learned;
          return Container(
            margin: const EdgeInsets.only(right: 3),
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: filled ? accent : s.text.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
          );
        }),
      );
    }
    return Text(
      '$learned / $total',
      style: TextStyle(
        fontSize: 13.5,
        fontWeight: FontWeight.w600,
        color: accent,
      ),
    );
  }
}
