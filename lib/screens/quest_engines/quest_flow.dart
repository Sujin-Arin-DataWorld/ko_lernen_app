import 'package:flutter/material.dart';

import '../../l10n/generated/app_localizations.dart';
import '../../widgets/sori/button.dart';
import '../../widgets/sori/pressable.dart';
import '../../widgets/sori/tokens.dart';

enum SoriAnswerState { idle, selected, correct, wrong }

enum SoriWordTileState { idle, selected, correct, wrong, disabled }

class SoriAnswerTray extends StatelessWidget {
  const SoriAnswerTray({
    super.key,
    this.child,
    this.tiles,
    this.slotCount,
    this.accent = SoriColors.primary,
    this.minHeight = 88,
  });

  final Widget? child;
  final List<Widget>? tiles;
  final int? slotCount;
  final Color accent;
  final double minHeight;

  @override
  Widget build(BuildContext context) {
    final surfaces = SoriSurfaces.of(context);
    final placed = tiles ?? const <Widget>[];
    final slots = slotCount;
    final Widget body;
    if (slots != null) {
      final empty = (slots - placed.length).clamp(0, slots);
      body = Wrap(
        spacing: 10,
        runSpacing: 10,
        children: [
          ...placed,
          for (var index = 0; index < empty; index++)
            SoriDottedAnswerSlot(
              key: ValueKey('answer-slot-${placed.length + index}'),
            ),
        ],
      );
    } else {
      body = child ?? const SizedBox.shrink();
    }
    return AnimatedContainer(
      duration: MediaQuery.disableAnimationsOf(context)
          ? Duration.zero
          : const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      constraints: BoxConstraints(minHeight: minHeight),
      width: double.infinity,
      padding: const EdgeInsets.all(Spacing.md),
      decoration: BoxDecoration(
        color: surfaces.surface,
        borderRadius: BorderRadius.circular(SoriRadius.lg),
        border: Border(bottom: BorderSide(color: accent, width: 2.5)),
      ),
      child: body,
    );
  }
}

/// Empty tray slot drawn with a dashed hanji-ink outline — no extra package.
class SoriDottedAnswerSlot extends StatelessWidget {
  const SoriDottedAnswerSlot({super.key, this.width = 56, this.height = 40});

  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    final surfaces = SoriSurfaces.of(context);
    return Semantics(
      label: AppL10n.of(context).questEmptyAnswerSlot,
      child: CustomPaint(
        painter: SoriDottedSlotPainter(color: surfaces.textDim),
        child: SizedBox(width: width, height: height),
      ),
    );
  }
}

class SoriDottedSlotPainter extends CustomPainter {
  const SoriDottedSlotPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    final rrect = RRect.fromRectAndRadius(
      Offset.zero & size,
      const Radius.circular(SoriRadius.sm),
    );
    final path = Path()..addRRect(rrect);
    const dash = 4.0;
    const gap = 3.0;
    for (final metric in path.computeMetrics()) {
      var dist = 0.0;
      while (dist < metric.length) {
        canvas.drawPath(metric.extractPath(dist, dist + dash), paint);
        dist += dash + gap;
      }
    }
  }

  @override
  bool shouldRepaint(covariant SoriDottedSlotPainter oldDelegate) =>
      oldDelegate.color != color;
}

/// Shared tile for productive word and jamo assembly tasks.
/// State is communicated by a corner icon and semantics as well as color.
class SoriWordTile extends StatelessWidget {
  const SoriWordTile({
    super.key,
    required this.label,
    required this.state,
    required this.onTap,
    this.scale = 1,
    this.compact = false,
    this.expand = false,
  });

  final String label;
  final SoriWordTileState state;
  final VoidCallback? onTap;
  final double scale;
  final bool compact;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);
    final surfaces = SoriSurfaces.of(context);
    final (border, background, foreground, icon, status) = switch (state) {
      SoriWordTileState.idle => (
        SoriColors.primary,
        surfaces.surface,
        surfaces.text,
        null,
        '',
      ),
      SoriWordTileState.selected => (
        SoriColors.primary,
        SoriColors.primarySoft,
        surfaces.text,
        Icons.check_circle_outline_rounded,
        t.questAnswerSelected,
      ),
      SoriWordTileState.correct => (
        SoriColors.success,
        SoriColors.success.withAlpha(32),
        surfaces.brightness == Brightness.light
            ? SoriColors.primaryOnLight
            : SoriColors.primaryOnDark,
        Icons.check_circle_rounded,
        t.questCorrect,
      ),
      SoriWordTileState.wrong => (
        SoriColors.danger,
        SoriColors.danger.withAlpha(32),
        surfaces.brightness == Brightness.light
            ? SoriColors.accent
            : SoriColors.danger,
        Icons.cancel_rounded,
        t.questWrong,
      ),
      SoriWordTileState.disabled => (
        surfaces.surfaceAlt,
        surfaces.surface,
        surfaces.textDim,
        null,
        '',
      ),
    };
    final duration = MediaQuery.disableAnimationsOf(context)
        ? Duration.zero
        : const Duration(milliseconds: 180);
    final radius = BorderRadius.circular(SoriRadius.sm);
    final tile = Semantics(
      button: true,
      enabled: onTap != null,
      selected: state == SoriWordTileState.selected,
      label: status.isEmpty ? label : '$label, $status',
      excludeSemantics: true,
      onTap: onTap,
      child: SoriPressable(
        onTap: onTap,
        haptic: null,
        pressScale: 0.97,
        child: ExcludeSemantics(
          child: Material(
            color: background,
            borderRadius: radius,
            child: AnimatedContainer(
              duration: duration,
              curve: Curves.easeOut,
              constraints: expand
                  ? const BoxConstraints.expand()
                  : BoxConstraints(minHeight: 48 * scale),
              padding: EdgeInsets.symmetric(
                horizontal: (compact ? 8 : 12) * scale,
                vertical: (compact ? 8 : 10) * scale,
              ),
              decoration: BoxDecoration(
                borderRadius: radius,
                border: Border.all(color: border, width: 1.5),
                boxShadow: state == SoriWordTileState.idle
                    ? null
                    : [
                        BoxShadow(
                          color: border.withValues(alpha: 0.12),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Padding(
                    padding: icon == null
                        ? EdgeInsets.zero
                        : const EdgeInsets.only(top: 2, right: 2),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        label,
                        maxLines: 1,
                        textAlign: TextAlign.center,
                        style: SoriTextTheme.of(context).body.copyWith(
                          color: foreground,
                          fontSize: (compact ? 16 : 18) * scale,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  if (icon != null)
                    Positioned(
                      top: 0,
                      right: 0,
                      child: Icon(icon, color: border, size: 14 * scale),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    return expand ? SizedBox.expand(child: tile) : tile;
  }
}

/// Cinematic prompt card: sentence, speaker, replay link, whole-card tap.
class SoriPromptCard extends StatelessWidget {
  const SoriPromptCard({
    super.key,
    required this.sentence,
    this.onReplay,
    this.replaySemanticLabel,
    this.compact = false,
  });

  final String sentence;
  final VoidCallback? onReplay;
  final String? replaySemanticLabel;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);
    final surfaces = SoriSurfaces.of(context);
    final replayable = onReplay != null;
    final label = replayable
        ? (replaySemanticLabel ?? '$sentence, ${t.questReplayAudio}')
        : sentence;
    final fontSize = compact ? 20.0 : 22.0;

    return Semantics(
      button: replayable,
      enabled: replayable ? true : null,
      label: label,
      excludeSemantics: true,
      onTap: onReplay,
      child: SoriPressable(
        onTap: onReplay,
        haptic: null,
        pressScale: replayable ? 0.99 : 1,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: surfaces.surface,
            borderRadius: BorderRadius.circular(SoriRadius.md),
            border: Border.all(color: SoriColors.primary, width: 1.5),
          ),
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              Spacing.md,
              compact ? Spacing.sm : Spacing.md,
              Spacing.md,
              compact ? Spacing.sm : Spacing.md,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (replayable) ...[
                  Container(
                    width: compact ? 40 : 44,
                    height: compact ? 40 : 44,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: SoriColors.primarySoft,
                    ),
                    child: const Icon(
                      Icons.volume_up_rounded,
                      color: SoriColors.primary,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: Spacing.sm),
                ],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        sentence,
                        style: SoriTextTheme.of(context).body.copyWith(
                          color: surfaces.text,
                          fontSize: fontSize,
                          fontWeight: FontWeight.w700,
                          height: 1.3,
                        ),
                      ),
                      if (replayable) ...[
                        const SizedBox(height: Spacing.xs),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                t.questReplayAudio,
                                style: SoriTextTheme.of(context).caption
                                    .copyWith(
                                      color: SoriColors.primary,
                                      fontWeight: FontWeight.w700,
                                    ),
                              ),
                            ),
                            const Icon(
                              Icons.touch_app_rounded,
                              color: SoriColors.primary,
                              size: 18,
                            ),
                          ],
                        ),
                      ],
                    ],
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

/// Shared, accessible answer row used by scenario choice engines.
/// State is communicated by icon and semantics as well as color.
class SoriAnswerTile extends StatelessWidget {
  const SoriAnswerTile({
    super.key,
    required this.label,
    required this.index,
    required this.state,
    required this.onTap,
    this.compact = false,
  });

  final String label;
  final int index;
  final SoriAnswerState state;
  final VoidCallback? onTap;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);
    final surfaces = SoriSurfaces.of(context);
    final idleBorder = surfaces.brightness == Brightness.light
        ? SoriColors.lightBorderStrong
        : SoriColors.darkBorderStrong;
    final duration = MediaQuery.disableAnimationsOf(context)
        ? Duration.zero
        : const Duration(milliseconds: 200);
    final (accent, icon, status) = switch (state) {
      SoriAnswerState.idle => (idleBorder, null, ''),
      SoriAnswerState.selected => (
        SoriColors.primary,
        Icons.check_circle_outline_rounded,
        t.questAnswerSelected,
      ),
      SoriAnswerState.correct => (
        SoriColors.success,
        Icons.check_circle_rounded,
        t.questCorrect,
      ),
      SoriAnswerState.wrong => (
        SoriColors.danger,
        Icons.cancel_rounded,
        t.questWrong,
      ),
    };
    final selected = state != SoriAnswerState.idle;

    return Semantics(
      button: true,
      selected: selected,
      enabled: onTap != null,
      label: status.isEmpty ? label : '$label, $status',
      excludeSemantics: true,
      onTap: onTap,
      child: SoriPressable(
        onTap: onTap,
        haptic: null,
        pressScale: 0.98,
        child: AnimatedScale(
          scale: selected ? 0.99 : 1,
          duration: duration,
          child: AnimatedContainer(
            duration: duration,
            decoration: BoxDecoration(
              color: selected ? accent.withAlpha(24) : surfaces.surface,
              borderRadius: BorderRadius.circular(SoriRadius.md),
              border: Border.all(color: accent, width: selected ? 2 : 1.5),
              boxShadow: selected
                  ? [
                      BoxShadow(
                        color: accent.withValues(alpha: 0.1),
                        blurRadius: 9,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : null,
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 52),
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: Spacing.md,
                  vertical: compact ? Spacing.sm : 12,
                ),
                child: Row(
                  children: [
                    SizedBox.square(
                      dimension: 28,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: accent.withAlpha(selected ? 36 : 18),
                        ),
                        child: Center(
                          child: Text(
                            String.fromCharCode(65 + index),
                            style: SoriTextTheme.of(context).caption.copyWith(
                              color: selected ? accent : surfaces.textMuted,
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: Spacing.sm),
                    Expanded(
                      child: Text(
                        label,
                        style: SoriTextTheme.of(context).body.copyWith(
                          color: surfaces.text,
                          fontWeight: selected
                              ? FontWeight.w700
                              : FontWeight.w500,
                        ),
                      ),
                    ),
                    if (icon != null) ...[
                      const SizedBox(width: Spacing.sm),
                      Icon(icon, color: accent, size: 22),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The single action area for scenario quests.
class ScenarioQuestAction extends StatelessWidget {
  const ScenarioQuestAction({
    super.key,
    required this.canSubmit,
    required this.onSubmit,
    this.resolved,
    this.onContinue,
    this.isLast = false,
    this.hint,
    this.pendingHint,
    this.onDontKnow,
  });

  final bool canSubmit;
  final VoidCallback? onSubmit;
  final bool? resolved;
  final VoidCallback? onContinue;
  final bool isLast;
  final String? hint;
  final String? pendingHint;
  final VoidCallback? onDontKnow;

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);
    final result = resolved;
    if (result == null) {
      final warningForeground =
          SoriSurfaces.of(context).brightness == Brightness.light
          ? SoriColors.goldOnLight
          : SoriColors.warning;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (pendingHint?.trim().isNotEmpty == true) ...[
            Semantics(
              liveRegion: true,
              label: pendingHint,
              excludeSemantics: true,
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline_rounded,
                    color: warningForeground,
                    size: 20,
                  ),
                  const SizedBox(width: Spacing.xs),
                  Expanded(
                    child: Text(
                      pendingHint!,
                      style: SoriTextTheme.of(
                        context,
                      ).bodySmall.copyWith(color: warningForeground),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: Spacing.sm),
          ],
          SoriButton.filled(
            key: const ValueKey('quest-submit'),
            label: t.questCheckAnswer,
            fullWidth: true,
            onTap: canSubmit ? onSubmit : null,
          ),
          if (onDontKnow != null) ...[
            const SizedBox(height: Spacing.xs),
            SoriButton.ghost(
              key: const ValueKey('quest-dont-know'),
              label: t.questDontKnowYet,
              fullWidth: true,
              onTap: onDontKnow,
            ),
          ],
        ],
      );
    }

    // `resolved == false` 는 "틀린 채로 끝났다"가 아니라 **정답이 공개됐다**는
    // 뜻이다 — 2회 오답이나 "모르겠어요" 뒤 엔진이 정답을 채워 넣고 해설을 연다.
    // 이 배너를 오답 빨강으로 칠하면 학습자가 방금 공개된 정답을 틀린 답으로
    // 읽는다(2026-08-17 Jin: "틀렸다는거야 뭐야"). 오답 순간의 피드백은 각 엔진의
    // 200ms 빨간 플래시와 `SoundService.wrong()` 이 이미 전달하므로, 여기서는
    // 중립적인 황색을 쓴다. 채점 결과(`passed`, XP·SRS)는 그대로다.
    final surfaces = SoriSurfaces.of(context);
    final accent = result
        ? (surfaces.brightness == Brightness.light
              ? SoriColors.primaryOnLight
              : SoriColors.primaryOnDark)
        : (surfaces.brightness == Brightness.light
              ? SoriColors.goldOnLight
              : SoriColors.warning);
    final resolvedMessage = hint?.trim().isNotEmpty == true
        ? hint!
        : (result ? t.questCorrect : t.questAnswerRevealed);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          liveRegion: true,
          label: resolvedMessage,
          excludeSemantics: true,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                result
                    ? Icons.check_circle_rounded
                    : Icons.info_outline_rounded,
                color: accent,
              ),
              const SizedBox(width: Spacing.sm),
              Expanded(
                child: Text(
                  resolvedMessage,
                  style: SoriTextTheme.of(
                    context,
                  ).bodySmall.copyWith(color: accent),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: Spacing.sm),
        SoriButton.filled(
          key: const ValueKey('quest-continue'),
          label: isLast ? t.questViewResult : t.questNext,
          fullWidth: true,
          onTap: onContinue,
        ),
      ],
    );
  }
}
