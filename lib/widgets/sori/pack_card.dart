import 'package:flutter/material.dart';

import '../../models/pack_progress.dart';
import 'dancheong_stamp.dart';
import 'pressable.dart';
import 'tokens.dart';

/// Pack-Karten Tile für die Pack-Marktplatz-Grid (Phase 2).
///
/// Drei Zustände:
///   - **locked**   — Schloss-Icon + erklärender Subtitle ("Vorheriger Pack
///                    zuerst klären"). Tap → Toast / SnackBar.
///   - **available / inProgress** — Topic-Icon + Progress-Dots + Tap-Action.
///   - **cleared**  — DancheongStamp Overlay rechts oben + tap nochmal.
///
/// Größe: ~160×180, passt in 2-Spalten-Grid auf typischen Geräten (360-440 dp
/// width).
class PackCard extends StatelessWidget {
  final String packId;
  final String title;
  final PackProgress progress;
  final VoidCallback? onTap;
  final VoidCallback? onLockedTap;

  const PackCard({
    super.key,
    required this.packId,
    required this.title,
    required this.progress,
    this.onTap,
    this.onLockedTap,
  });

  bool get _locked => progress.status == PackStatus.locked;
  bool get _cleared => progress.status == PackStatus.cleared;

  @override
  Widget build(BuildContext context) {
    final s = SoriSurfaces.of(context);
    final motif = motifForPackId(packId);

    final bg = _locked
        ? s.surface.withValues(alpha: 0.5)
        : (_cleared ? s.bg : s.surface);

    final border = _cleared
        ? SoriColors.success
        : (_locked ? s.text.withValues(alpha: 0.12) : SoriColors.info);

    return SoriPressable(
      onTap: _locked ? onLockedTap : onTap,
      haptic: _locked ? SoriHaptic.selection : SoriHaptic.light,
      child: Semantics(
        button: true,
        label: _semanticsLabel(),
        child: Container(
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(SoriRadius.md),
            border: Border.all(color: border, width: 1.2),
          ),
          padding: const EdgeInsets.all(Spacing.md),
          child: Stack(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Topic icon / lock
                  _TopRow(
                    motif: motif,
                    locked: _locked,
                    cleared: _cleared,
                    accent: _topIconColor(s),
                  ),
                  const SizedBox(height: Spacing.sm),
                  // Title
                  Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      height: 1.2,
                      color: _locked
                          ? s.text.withValues(alpha: 0.5)
                          : s.text,
                    ),
                  ),
                  const SizedBox(height: Spacing.sm),
                  // Bottom: progress dots or unlock hint
                  _BottomRow(
                    progress: progress,
                    locked: _locked,
                    accent: _bottomAccent(s),
                  ),
                ],
              ),
              // Cleared stamp overlay (top-right)
              if (_cleared)
                Positioned(
                  top: -4,
                  right: -4,
                  child: DancheongStamp(
                    motif: motif,
                    size: 44,
                    animate: false,
                    stamped: true,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Color _topIconColor(SoriSurfaces s) {
    if (_locked) return s.text.withValues(alpha: 0.4);
    if (_cleared) return SoriColors.success;
    return SoriColors.info;
  }

  Color _bottomAccent(SoriSurfaces s) {
    if (_locked) return s.text.withValues(alpha: 0.4);
    return SoriColors.info;
  }

  String _semanticsLabel() {
    final state = _cleared
        ? 'geklärt'
        : (_locked ? 'gesperrt' : 'verfügbar');
    final progressStr = '${progress.wordsLearned} von ${progress.wordsTotal} gelernt';
    return 'Pack $title, $state, $progressStr';
  }
}

class _TopRow extends StatelessWidget {
  final DancheongMotif motif;
  final bool locked;
  final bool cleared;
  final Color accent;
  const _TopRow({
    required this.motif,
    required this.locked,
    required this.cleared,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    if (locked) {
      return Icon(Icons.lock_rounded, size: 24, color: accent);
    }
    // Use a small static stamp as topic icon (cleared cards show big overlay)
    return Opacity(
      opacity: cleared ? 0.0 : 1.0, // cleared 카드는 오른쪽 위 큰 도장 사용
      child: SizedBox(
        width: 32,
        height: 32,
        child: DancheongStamp(motif: motif, size: 32),
      ),
    );
  }
}

class _BottomRow extends StatelessWidget {
  final PackProgress progress;
  final bool locked;
  final Color accent;
  const _BottomRow({
    required this.progress,
    required this.locked,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    final s = SoriSurfaces.of(context);
    if (locked) {
      return Text(
        '🔒 Vorher klären',
        style: TextStyle(fontSize: 11, color: accent),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
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
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: accent,
      ),
    );
  }
}
