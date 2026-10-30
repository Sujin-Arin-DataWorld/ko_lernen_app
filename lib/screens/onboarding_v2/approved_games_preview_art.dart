import 'package:flutter/material.dart';

import '../../widgets/sori/pressable.dart';
import '../../widgets/sori/tokens.dart';

const gamesPreviewArt = 'assets/illustrations/concept_c/spiele_preview/';
const gamesPreviewInk = Color(0xff123d35);

/// Exact approved source pixels form the material; text and actions are native.
class GamesPreviewSurface extends StatelessWidget {
  const GamesPreviewSurface({
    super.key,
    required this.child,
    this.art = 'paper_card.png',
    this.padding = const EdgeInsets.all(16),
  });
  final Widget child;
  final String art;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) => Stack(
    children: [
      Positioned.fill(
        child: ExcludeSemantics(
          child: Image.asset('$gamesPreviewArt$art', fit: BoxFit.fill),
        ),
      ),
      Padding(padding: padding, child: child),
    ],
  );
}

class GamesPreviewAction extends StatelessWidget {
  const GamesPreviewAction({
    super.key,
    required this.label,
    required this.onTap,
    this.selected = false,
    this.korean = false,
    this.art = 'silben_tile.png',
    this.illustration,
  });
  final String label;
  final VoidCallback? onTap;
  final bool selected;
  final bool korean;
  final String? art;
  final Widget? illustration;

  @override
  Widget build(BuildContext context) {
    final surfaceArt = art == 'silben_tile.png' && !korean
        ? 'paper_action.png'
        : art;
    final text = Padding(
      padding: EdgeInsets.symmetric(
        horizontal: art == null ? 4 : 10,
        vertical: art == null ? 4 : 12,
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (illustration != null) ...[
              ExcludeSemantics(child: illustration!),
              const SizedBox(height: 8),
            ],
            Text(
              label,
              textAlign: TextAlign.center,
              locale: korean ? const Locale('ko') : null,
              style: TextStyle(
                fontFamily: korean
                    ? SoriFonts.learningKorean
                    : SoriLocaleFonts.of(context).body,
                fontSize: korean ? 23 : 16,
                height: 1.2,
                fontWeight: FontWeight.w700,
                color: art == 'jade_action.png'
                    ? const Color(0xfffff0c9)
                    : gamesPreviewInk,
              ),
            ),
          ],
        ),
      ),
    );
    return Semantics(
      button: true,
      enabled: onTap != null,
      selected: selected,
      label: label,
      child: SoriPressable(
        onTap: onTap,
        haptic: null,
        pressScale: 1,
        pressOffsetY: 2,
        pressDuration: const Duration(milliseconds: 100),
        releaseDuration: const Duration(milliseconds: 180),
        releaseCurve: Curves.easeOutCubic,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: selected
                  ? Border.all(color: const Color(0xffaa6d16), width: 2)
                  : null,
            ),
            child: ExcludeSemantics(
              child: surfaceArt == null
                  ? text
                  : GamesPreviewSurface(
                      art: surfaceArt,
                      padding: EdgeInsets.zero,
                      child: text,
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
