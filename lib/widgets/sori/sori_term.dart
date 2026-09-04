import 'dart:async';

import 'package:flutter/material.dart';

import '../../l10n/generated/app_localizations.dart';
import '../../services/analytics_service.dart';
import 'cultural_help.dart';
import 'pressable.dart';
import 'tokens.dart';

/// A dotted-underline inline term that opens the cultural glossary sheet
/// for [termId] when tapped — the lightweight counterpart to
/// [CulturalHelpButton]/[CulturalDecorationHelpButton] for a name that is
/// already visible on screen (e.g. "Jangdokdae · 장독대" under a decoration
/// name), rather than a separate "?" affordance.
///
/// Every occurrence logs `cultural_term_open` with the term and the calling
/// [surface] so Fable can see which surfaces actually get tapped.
class SoriTerm extends StatelessWidget {
  const SoriTerm({
    super.key,
    required this.termId,
    required this.text,
    this.style,
    this.surface = 'unknown',
  });

  /// [CulturalGlossary] entry id opened on tap.
  final String termId;

  /// Visible text, e.g. "Jangdokdae · 장독대".
  final String text;

  final TextStyle? style;

  /// Analytics tag for which screen/list this term appeared in.
  final String surface;

  void _open(BuildContext context) {
    unawaited(
      Analytics.logEvent(
        'cultural_term_open',
        parameters: {'term_id': termId, 'surface': surface},
      ),
    );
    unawaited(showCulturalTermSheetForId(context, termId));
  }

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);
    final baseStyle = style ?? DefaultTextStyle.of(context).style;
    final resolvedStyle = baseStyle.copyWith(
      decoration: TextDecoration.underline,
      decorationStyle: TextDecorationStyle.dotted,
      decorationColor: SoriColors.primary.withValues(alpha: 0.6),
      decorationThickness: 1.5,
    );
    return Semantics(
      button: true,
      label: t.culturalHelpSemantics(text),
      onTap: () => _open(context),
      excludeSemantics: true,
      child: SoriPressable(
        onTap: () => _open(context),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 44),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: Align(
              alignment: AlignmentDirectional.centerStart,
              widthFactor: 1,
              child: Text(text, style: resolvedStyle),
            ),
          ),
        ),
      ),
    );
  }

  /// Inline variant for use inside a [Text.rich]/[TextSpan] sentence.
  ///
  /// Wraps the same interactive [SoriTerm] in a [WidgetSpan] instead of a
  /// `TextSpan(recognizer: TapGestureRecognizer())`, which would need a
  /// manual `dispose()` the surrounding widget has no natural place for and
  /// otherwise leaks.
  static InlineSpan span({
    required String termId,
    required String text,
    TextStyle? style,
    String surface = 'unknown',
  }) {
    return WidgetSpan(
      alignment: PlaceholderAlignment.baseline,
      baseline: TextBaseline.alphabetic,
      child: SoriTerm(
        termId: termId,
        text: text,
        style: style,
        surface: surface,
      ),
    );
  }
}
