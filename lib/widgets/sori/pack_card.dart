import 'package:flutter/material.dart';

import '../../l10n/generated/app_localizations.dart';
import '../../models/pack_progress.dart';
import 'dancheong_stamp.dart';
import 'illustrated_card.dart';
import 'sori_icon.dart';
import 'tokens.dart';

/// Pack-Karten Tile für die Pack-Marktplatz-Grid.
///
/// 2026-08-13 UI 개편 Phase 1: [SoriIllustratedCard] 규격으로 재구성 —
/// 상단에 motif 별 일러스트 슬롯(`assets/illustrations/packs/{motif}.webp`,
/// 규약 기반: 파일을 넣기만 하면 뜬다), 폴백은 기존 단청 도장.
///
/// Vier Zustände:
///   - **locked**   — 딤 처리 + 자물쇠 칩 + "Vorher klären" 힌트.
///   - **premium**  — §H 프리미엄 티저: 골드 왕관 칩 (탭 → 페이월 게이트).
///     선행 잠금(자물쇠)과 시각적으로 구분되는 별도 상태다.
///   - **available / inProgress** — 일러스트 + Progress-Dots + Tap-Action.
///   - **cleared**  — DancheongStamp Overlay rechts oben + tap nochmal.
class PackCard extends StatelessWidget {
  final String packId;
  final String title;
  final PackProgress progress;
  final VoidCallback? onTap;
  final VoidCallback? onLockedTap;

  /// §H: 이 팩이 프리미엄 구독 뒤에 있음을 카드에서 미리 보여준다
  /// (기존엔 탭 후 인터스티셜에서만 드러나 전환 기회를 잃었다).
  /// 선행 잠금이 있으면 자물쇠가 우선한다.
  final bool premium;

  const PackCard({
    super.key,
    required this.packId,
    required this.title,
    required this.progress,
    this.onTap,
    this.onLockedTap,
    this.premium = false,
  });

  bool get _locked => progress.status == PackStatus.locked;
  bool get _cleared => progress.status == PackStatus.cleared;

  @override
  Widget build(BuildContext context) {
    final motif = motifForPackId(packId);

    return SoriIllustratedCard(
      title: title,
      state: _locked
          ? SoriIllustratedCardState.locked
          : premium
          ? SoriIllustratedCardState.premium
          : _cleared
          ? SoriIllustratedCardState.cleared
          : SoriIllustratedCardState.normal,
      illustrationAsset: 'assets/illustrations/packs/${motif.name}.webp',
      fallback: DancheongStamp(motif: motif, size: 44, animate: false),
      overlay: _cleared
          ? DancheongStamp(
              motif: motif,
              size: 44,
              animate: false,
              stamped: true,
            )
          : null,
      footer: _BottomRow(progress: progress, locked: _locked),
      onTap: _locked ? onLockedTap : onTap,
      semanticsLabel: _semanticsLabel(context),
    );
  }

  /// 스크린리더에 그대로 읽히는 문구다 — 하드코딩 독일어를 두면 EN 사용자가
  /// 화면 전체를 독일어로 듣게 된다 (2026-08-18 l10n 스윕에서 발견).
  String _semanticsLabel(BuildContext context) {
    final t = AppL10n.of(context);
    final state = _locked
        ? t.packStateLocked
        : premium
        ? t.packStatePremium
        : _cleared
        ? t.packStateCleared
        : t.packStateAvailable;
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
  final bool locked;
  const _BottomRow({required this.progress, required this.locked});

  @override
  Widget build(BuildContext context) {
    final s = SoriSurfaces.of(context);
    final text = SoriTextTheme.of(context);
    final accent = locked ? s.text.withValues(alpha: 0.4) : SoriColors.info;
    if (locked) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(SoriGlyph.locked, size: 11, color: accent),
          const SizedBox(width: 3),
          Flexible(
            child: Text(
              AppL10n.of(context).packLockedHintShort,
              style: text.caption.copyWith(color: accent),
            ),
          ),
        ],
      );
    }

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
