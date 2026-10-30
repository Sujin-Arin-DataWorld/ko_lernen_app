import 'package:flutter/material.dart';

import '../../l10n/generated/app_localizations.dart';
import 'tokens.dart';

/// The weekly title yields a separate count row when either translation or
/// accessibility text needs it. Nothing is clipped under the amount.
class DureWeeklyHeading extends StatelessWidget {
  const DureWeeklyHeading({
    super.key,
    required this.total,
    required this.goal,
    required this.done,
  });
  final int total;
  final int goal;
  final bool done;

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);
    final s = SoriSurfaces.of(context);
    final titleStyle = SoriTextTheme.of(
      context,
    ).label.copyWith(fontSize: 13, color: s.text);
    final amountSpan = TextSpan(
      children: [
        TextSpan(
          text: '$total',
          style: titleStyle.copyWith(
            fontSize: 16,
            color: done ? SoriColors.gold : SoriColors.primary,
          ),
        ),
        TextSpan(
          text: goal > 0 ? ' / $goal' : '',
          style: titleStyle.copyWith(color: s.textMuted),
        ),
      ],
    );
    return LayoutBuilder(
      builder: (context, bounds) {
        final painter = TextPainter(
          textDirection: Directionality.of(context),
          textScaler: MediaQuery.textScalerOf(context),
        );
        painter.text = TextSpan(text: t.gyeDureTitle, style: titleStyle);
        painter.layout();
        final titleWidth = painter.width;
        painter.text = amountSpan;
        painter.layout();
        final amountWidth = painter.width;
        painter.dispose();
        final title = Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 1),
              child: Icon(
                done ? Icons.local_florist_rounded : Icons.grass_rounded,
                size: 16,
                color: done ? SoriColors.gold : SoriColors.primary,
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                t.gyeDureTitle,
                key: const ValueKey('gye-dure-week-heading'),
                style: titleStyle,
              ),
            ),
          ],
        );
        final amount = Text.rich(
          amountSpan,
          key: const ValueKey('gye-dure-week-amount'),
        );
        if (titleWidth + amountWidth + 34 <= bounds.maxWidth) {
          return Row(
            children: [
              Expanded(child: title),
              const SizedBox(width: 12),
              amount,
            ],
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [title, const SizedBox(height: 4), amount],
        );
      },
    );
  }
}
