import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:ko_lernen_app/l10n/generated/app_localizations.dart';
import 'package:ko_lernen_app/widgets/sori/tokens.dart';
import '../button.dart';

double _phase(double s, double a, double b, [Curve curve = Curves.linear]) =>
    curve.transform(((s - a) / (b - a)).clamp(0.0, 1.0));

/// A brief, asymmetric blue accent. The existing pearl/gold opening stays
/// intact, and the original chest is composited above this painter.
class RewardChestBlueLightPainter extends CustomPainter {
  const RewardChestBlueLightPainter({
    required this.second,
    required this.origin,
    required this.chestWidth,
  });

  final double second;
  final Offset origin;
  final double chestWidth;

  double get opacity =>
      _phase(second, 0.42, 0.80, Curves.easeInOutCubic) *
      (1 - _phase(second, 1.04, 1.46, Curves.easeInOutCubic));

  double get warmth => _phase(second, 0.88, 1.34, Curves.easeInOutCubic);

  @override
  void paint(Canvas canvas, Size size) {
    if (opacity <= 0 || chestWidth <= 0) {
      return;
    }
    final blue = Color.lerp(
      const Color(0xFF83C8E5),
      const Color(0xFFE6C788),
      warmth,
    )!;
    canvas.save();
    canvas.translate(origin.dx, origin.dy);
    canvas.scale(chestWidth);
    // Unequal curved tongues, not a perfect ring, seam, or laser beam.
    for (var i = 0; i < 3; i++) {
      final side = i == 1 ? 1.0 : -1.0;
      final rise = _phase(second, 0.42 + i * 0.035, 1.08, Curves.easeOutCubic);
      final drift = math.sin(second * math.pi * 1.6 + i) * 0.025;
      canvas.save();
      canvas.translate(i == 2 ? 0.10 : side * 0.38, i == 2 ? -0.24 : 0.06);
      canvas.scale(side, 1);
      final tip = -0.22 - rise * (i == 2 ? 0.35 : 0.47);
      final path = Path()
        ..moveTo(-0.10, 0.24)
        ..cubicTo(0.10, 0.15, 0.30, -0.12, 0.19 + drift, -0.26)
        ..cubicTo(0.08, -0.40, 0.16, tip + 0.06, 0.30, tip)
        ..cubicTo(0.09, tip + 0.07, 0.02, -0.31, 0.05, -0.20)
        ..cubicTo(0.12, -0.07, 0.04, 0.12, -0.10, 0.24)
        ..close();
      canvas.drawPath(
        path,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.bottomLeft,
            end: Alignment.topRight,
            colors: [
              blue.withValues(alpha: 0),
              blue.withValues(alpha: opacity * 0.20),
              const Color(0xFFD6EAF2).withValues(alpha: opacity * 0.34),
              blue.withValues(alpha: 0),
            ],
            stops: const [0, 0.28, 0.58, 1],
          ).createShader(Rect.fromLTRB(-0.12, tip, 0.34, 0.25)),
      );
      canvas.restore();
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant RewardChestBlueLightPainter oldDelegate) =>
      oldDelegate.second != second ||
      oldDelegate.origin != origin ||
      oldDelegate.chestWidth != chestWidth;
}

/// Native receipt follows the approved light paper explanation and gold CTA.
/// All financial values are confirmed snapshots supplied by the reward receipt.
class RewardGuideReceipt extends StatelessWidget {
  const RewardGuideReceipt({
    super.key,
    required this.second,
    required this.itemName,
    required this.itemTerm,
    required this.rewardTypeLabel,
    required this.description,
    required this.totalXp,
    required this.level,
    required this.xpToNext,
    required this.storyLabel,
    required this.onStory,
    required this.actionLabel,
    required this.onAction,
  });
  final double second;
  final String itemName, rewardTypeLabel, storyLabel, actionLabel;
  final String? itemTerm, description;
  final int? totalXp, level, xpToNext;
  final VoidCallback? onStory, onAction;

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);
    final text = SoriTextTheme.of(context);
    final showXp = totalXp != null && level != null && xpToNext != null;
    return SingleChildScrollView(
      key: const Key('reward-guide-viewport'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _GuideArrival(
            second: second,
            start: 2.18,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  rewardTypeLabel,
                  style: text.eyebrow.copyWith(color: SoriColors.goldOnLight),
                ),
                const SizedBox(height: 6),
                Semantics(
                  header: true,
                  liveRegion: true,
                  child: Text(
                    itemName,
                    key: const Key('reward-guide-title'),
                    style: text.h1.copyWith(fontSize: 28, height: 1.25),
                  ),
                ),
                if (itemTerm != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    itemTerm!,
                    style: text.bodySmall.copyWith(fontFamily: 'NotoSansKR'),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),
          _GuideArrival(
            second: second,
            start: 2.30,
            child: Container(
              key: const Key('reward-guide-description'),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xfffffdf8),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xffe5dccb)),
                boxShadow: const [
                  BoxShadow(color: Color(0xffe1d9c9), offset: Offset(0, 3)),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (description != null)
                    Text(
                      description!,
                      style: text.bodySmall.copyWith(
                        fontSize: 16,
                        height: 1.45,
                      ),
                    ),
                  if (onStory != null)
                    SoriButton.ghost(
                      key: const Key('reward-guide-story'),
                      label: storyLabel,
                      onTap: onStory,
                      fullWidth: true,
                    ),
                  if (showXp) ...[
                    const Divider(height: 18, color: Color(0xffe5dccb)),
                    LayoutBuilder(
                      builder: (context, bounds) {
                        final label = Text(
                          t.rewardChestLearningXp,
                          style: text.meta,
                        );
                        final value = Text(
                          '${NumberFormat.decimalPattern(t.localeName).format(totalXp)} ${t.statsXp}',
                          style: text.h3.copyWith(
                            fontSize: 18,
                            color: SoriColors.goldOnLight,
                          ),
                        );
                        return MediaQuery.textScalerOf(context).scale(16) >
                                    24 ||
                                bounds.maxWidth < 280
                            ? Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [label, value],
                              )
                            : Row(
                                children: [
                                  Expanded(child: label),
                                  value,
                                ],
                              );
                      },
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(3),
                      child: LinearProgressIndicator(
                        value: ((100 - xpToNext!) / 100).clamp(0, 1),
                        minHeight: 6,
                        color: const Color(0xffcda24d),
                        backgroundColor: const Color(0xffeee5d1),
                        semanticsLabel: t.rewardChestLearningXp,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      alignment: WrapAlignment.spaceBetween,
                      spacing: 12,
                      runSpacing: 6,
                      children: [
                        Text(t.statsLevelLabel(level!), style: text.meta),
                        Text(
                          t.statsToNextLevel(xpToNext!, level! + 1),
                          style: text.meta,
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          _GuideArrival(
            second: second,
            start: 2.56,
            child: SoriButton.filled(
              key: const Key('reward-guide-action'),
              label: actionLabel,
              onTap: onAction,
              accent: const Color(0xfff5cf78),
              sculpted: true,
              fullWidth: true,
            ),
          ),
        ],
      ),
    );
  }
}

class _GuideArrival extends StatelessWidget {
  const _GuideArrival({
    required this.second,
    required this.start,
    required this.child,
  });
  final double second;
  final double start;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final progress = _phase(second, start, start + 0.30, Curves.easeOutCubic);
    return ExcludeSemantics(
      excluding: progress < 1,
      child: Opacity(
        opacity: progress,
        child: Transform.translate(
          offset: Offset(0, 8 * (1 - progress)),
          child: child,
        ),
      ),
    );
  }
}
