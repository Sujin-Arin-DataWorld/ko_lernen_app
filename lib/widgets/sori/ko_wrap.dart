import 'package:flutter/material.dart';

/// Wraps Korean (and mixed) phrases on spaces only.
///
/// Flutter's default breaker splits Hangul by syllable, so `포기하지` becomes
/// `포기하` / `지`. Each whitespace token stays on one line.
class SoriPhraseWrap extends StatelessWidget {
  const SoriPhraseWrap(
    this.text, {
    super.key,
    this.style,
    this.textAlign = TextAlign.center,
  });

  final String text;
  final TextStyle? style;
  final TextAlign textAlign;

  @override
  Widget build(BuildContext context) {
    final parts = text
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .toList(growable: false);
    if (parts.length <= 1) {
      return Text(
        text,
        textAlign: textAlign,
        style: style,
        softWrap: false,
        overflow: TextOverflow.fade,
      );
    }
    final alignment = switch (textAlign) {
      TextAlign.center || TextAlign.justify => WrapAlignment.center,
      TextAlign.right || TextAlign.end => WrapAlignment.end,
      _ => WrapAlignment.start,
    };
    return Wrap(
      alignment: alignment,
      spacing: 6,
      runSpacing: 2,
      children: [
        for (final part in parts)
          Text(part, style: style, softWrap: false),
      ],
    );
  }
}
