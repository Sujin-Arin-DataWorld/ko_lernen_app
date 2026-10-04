import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:ko_lernen_app/l10n/generated/app_localizations.dart';
import 'package:ko_lernen_app/widgets/sori/tokens.dart';

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

/// Native counterpart of the approved light paper / gold-action study. Only
/// the comparison flag selects it; v8's receipt and scroll policy are intact.
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
  final String itemName;
  final String? itemTerm;
  final String rewardTypeLabel;
  final String? description;
  final int? totalXp;
  final int? level;
  final int? xpToNext;
  final String storyLabel;
  final VoidCallback? onStory;
  final String actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, box) {
      final t = AppL10n.of(context);
      final text = SoriTextTheme.of(context);
      final surfaces = SoriSurfaces.of(context);
      final compact = box.maxHeight < 420;
      final lean = box.maxHeight < 340;
      final titleStyle = text.h1.copyWith(
        fontSize: lean ? 22 : 28,
        height: lean ? 1.20 : 1.25,
        fontWeight: FontWeight.w500,
        letterSpacing: -0.4,
      );
      final header = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (!lean) ...[
            Text(
              rewardTypeLabel,
              style: text.eyebrow.copyWith(color: SoriColors.goldOnLight),
            ),
            const SizedBox(height: 6),
          ],
          Semantics(
            header: true,
            liveRegion: true,
            child: Text(
              itemName,
              key: const Key('reward-guide-title'),
              style: titleStyle,
            ),
          ),
          if (!lean && itemTerm != null) ...[
            const SizedBox(height: 6),
            Text(
              itemTerm!,
              style: text.meta.copyWith(color: surfaces.textMuted),
            ),
          ],
        ],
      );
      final showXp = totalXp != null && level != null && xpToNext != null;
      final content = Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _GuideArrival(second: second, start: 2.18, child: header),
          SizedBox(height: lean ? 10 : 16),
          _GuideArrival(
            second: second,
            start: 2.30,
            child: Container(
              key: const Key('reward-guide-description'),
              padding: EdgeInsets.symmetric(
                horizontal: 16,
                vertical: lean ? 8 : 14,
              ),
              decoration: BoxDecoration(
                color: SoriColors.lightSurfaceRaised,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: SoriColors.lightBorder.withValues(alpha: 0.60),
                ),
                boxShadow: [
                  const BoxShadow(
                    color: Color(0xFFE1D9C9),
                    offset: Offset(0, 3),
                  ),
                  BoxShadow(
                    color: SoriColors.lightText.withValues(alpha: 0.045),
                    offset: const Offset(0, 10),
                    blurRadius: 18,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (!compact && description != null) ...[
                    Text(
                      description!,
                      style: text.bodySmall.copyWith(
                        fontSize: 16,
                        height: 1.45,
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                  if (onStory != null)
                    TextButton(
                      key: const Key('reward-guide-story'),
                      onPressed: onStory,
                      style: TextButton.styleFrom(
                        textStyle:
                            (Theme.of(context).textTheme.labelLarge ??
                                    const TextStyle(inherit: false))
                                .merge(text.label),
                        minimumSize: const Size(48, 48),
                        foregroundColor: SoriColors.primaryDark,
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 22),
                            child: Text(
                              storyLabel,
                              textAlign: TextAlign.center,
                              style: text.label,
                            ),
                          ),
                          const Positioned(
                            right: 0,
                            child: Icon(Icons.chevron_right_rounded, size: 18),
                          ),
                        ],
                      ),
                    ),
                  if (showXp) ...[
                    Divider(
                      height: lean ? 10 : 18,
                      color: SoriColors.lightBorder,
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            t.rewardChestLearningXp,
                            style: text.meta,
                          ),
                        ),
                        Text(
                          '${NumberFormat.decimalPattern(t.localeName).format(totalXp)} ${t.statsXp}',
                          style: text.h3.copyWith(
                            fontSize: 18,
                            color: SoriColors.goldOnLight,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: ((100 - xpToNext!) / 100).clamp(0.0, 1.0),
                        minHeight: 6,
                        color: SoriColors.gold,
                        backgroundColor: SoriColors.lightSurfaceAlt,
                        semanticsLabel: t.rewardChestLearningXp,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Text(t.statsLevelLabel(level!), style: text.meta),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            t.statsToNextLevel(xpToNext!, level! + 1),
                            textAlign: TextAlign.end,
                            style: text.meta,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
          SizedBox(height: lean ? 12 : 20),
          _GuideArrival(
            second: second,
            start: 2.56,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                boxShadow: const [
                  BoxShadow(color: Color(0xFFBD9844), offset: Offset(0, 3)),
                ],
              ),
              child: TextButton(
                key: const Key('reward-guide-action'),
                onPressed: onAction,
                style: TextButton.styleFrom(
                  textStyle:
                      (Theme.of(context).textTheme.labelLarge ??
                              const TextStyle(inherit: false))
                          .merge(text.label),
                  minimumSize: Size(48, lean ? 48 : 56),
                  backgroundColor: const Color(0xFFF5CF78),
                  foregroundColor: SoriColors.lightText,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        actionLabel,
                        style: text.label.copyWith(color: SoriColors.lightText),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Icon(Icons.arrow_forward_rounded, size: 20),
                  ],
                ),
              ),
            ),
          ),
        ],
      );
      // Normal mobile/landscape sizes fit a single page. At extreme system text
      // sizes retain an accessible scroll fallback instead of clipping words.
      return Align(
        alignment: Alignment.topCenter,
        child: SingleChildScrollView(
          key: const Key('reward-guide-viewport'),
          clipBehavior: Clip.none,
          child: content,
        ),
      );
    },
  );
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
