import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'sori/tokens.dart';

/// 오류 상태 — 부드럽게 등장하고, 아이콘이 잔잔히 호흡한다.
class AppError extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;
  final IconData icon;
  final String? retryLabel;

  const AppError({
    super.key,
    required this.message,
    this.onRetry,
    this.icon = Icons.error_outline,
    this.retryLabel,
  });

  @override
  Widget build(BuildContext context) {
    final s = SoriSurfaces.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 56, color: SoriColors.danger)
                .animate(onPlay: (c) => c.repeat(reverse: true))
                .scaleXY(
                  begin: 1.0,
                  end: 1.07,
                  duration: 900.ms,
                  curve: Curves.easeInOut,
                ),
            const SizedBox(height: 14),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(color: s.text, fontSize: 15, height: 1.5),
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 18),
              FilledButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: Text(retryLabel ?? 'Erneut versuchen'),
              ),
            ],
          ],
        )
            .animate()
            .fadeIn(duration: 280.ms)
            .slideY(
              begin: 0.07,
              end: 0,
              duration: 340.ms,
              curve: Curves.easeOutCubic,
            ),
      ),
    );
  }
}

/// 빈 상태 — 부드럽게 등장하고, 아이콘이 천천히 떠다닌다.
class AppEmpty extends StatelessWidget {
  final String message;
  final IconData icon;
  final VoidCallback? onAction;
  final String? actionLabel;

  const AppEmpty({
    super.key,
    required this.message,
    this.icon = Icons.inbox_outlined,
    this.onAction,
    this.actionLabel,
  });

  @override
  Widget build(BuildContext context) {
    final s = SoriSurfaces.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 56, color: s.textDim)
                .animate(onPlay: (c) => c.repeat(reverse: true))
                .moveY(
                  begin: 0,
                  end: -7,
                  duration: 1700.ms,
                  curve: Curves.easeInOut,
                ),
            const SizedBox(height: 14),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(color: s.textMuted, fontSize: 14, height: 1.5),
            ),
            if (onAction != null) ...[
              const SizedBox(height: 18),
              OutlinedButton(
                onPressed: onAction,
                child: Text(actionLabel ?? 'Anpassen'),
              ),
            ],
          ],
        )
            .animate()
            .fadeIn(duration: 280.ms)
            .slideY(
              begin: 0.07,
              end: 0,
              duration: 340.ms,
              curve: Curves.easeOutCubic,
            ),
      ),
    );
  }
}
