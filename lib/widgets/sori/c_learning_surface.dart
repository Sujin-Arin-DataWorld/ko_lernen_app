import 'package:flutter/material.dart';

import 'pressable.dart';
import 'c_material_assets.dart';
import 'tokens.dart';
import 'button.dart' show SoriLoadingIndicator;

/// Material colors and spacing from the approved 2026-10-10 Hangul snapshot.
/// Shared material reuse is separate from each screen's visual approval.
abstract final class SoriCLearningTokens {
  static const jade = Color(0xFF174D43);
  static const deep = Color(0xFF0E3931);
  static const paper = Color(0xFFF6EDDE);
  static const ink = Color(0xFF242C26);
  static const gold = Color(0xFFCFA15C);
  static const edge = Color(0xFFC7B18F);
  static const related = 4.0;
  static const control = 8.0;
  static const group = 12.0;
  static const section = 16.0;
  static const minTouch = 48.0;
}

enum SoriCMaterial { paper, jade, gold }

class SoriCLearningBackground extends StatelessWidget {
  const SoriCLearningBackground({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) => SoriCMaterialSurface(
    material: SoriCMaterial.jade,
    borderRadius: BorderRadius.zero,
    raised: false,
    child: child,
  );
}

/// Original texture bytes, clipped at paint time. No text is baked into art.
/// Padding is explicit so a surface does not introduce hidden nested spacing.
class SoriCMaterialSurface extends StatelessWidget {
  const SoriCMaterialSurface({
    super.key,
    required this.child,
    this.material = SoriCMaterial.paper,
    this.padding = EdgeInsets.zero,
    this.borderRadius = const BorderRadius.all(Radius.circular(16)),
    this.raised = true,
    this.tint,
  });

  final Widget child;
  final SoriCMaterial material;
  final EdgeInsetsGeometry padding;
  final BorderRadius borderRadius;
  final bool raised;
  final Color? tint;

  @override
  Widget build(BuildContext context) {
    final color = switch (material) {
      SoriCMaterial.paper => SoriCLearningTokens.paper,
      SoriCMaterial.jade => SoriCLearningTokens.jade,
      SoriCMaterial.gold => SoriCLearningTokens.gold,
    };
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: borderRadius,
        boxShadow: raised
            ? const [
                BoxShadow(color: Color(0xFFB39A73), offset: Offset(0, 2)),
                BoxShadow(
                  color: Color(0x14503919),
                  offset: Offset(0, 4),
                  blurRadius: 6,
                ),
              ]
            : null,
      ),
      child: ClipRRect(
        borderRadius: borderRadius,
        child: Stack(
          fit: StackFit.passthrough,
          children: [
            Positioned.fill(child: ColoredBox(color: color)),
            Positioned.fill(
              child: IgnorePointer(
                child: ExcludeSemantics(
                  child: material == SoriCMaterial.jade
                      ? Image.asset(
                          SoriCMaterialAssets.jade,
                          scale: 1254 / 420,
                          repeat: ImageRepeat.repeat,
                          fit: BoxFit.none,
                        )
                      : Opacity(
                          opacity: material == SoriCMaterial.paper ? .58 : .32,
                          child: LayoutBuilder(
                            builder: (context, bounds) => ClipRect(
                              child: OverflowBox(
                                alignment: material == SoriCMaterial.paper
                                    ? Alignment.topRight
                                    : Alignment.bottomRight,
                                minWidth: bounds.maxWidth * 2,
                                maxWidth: bounds.maxWidth * 2,
                                minHeight: bounds.maxHeight * 2,
                                maxHeight: bounds.maxHeight * 2,
                                child: Image.asset(
                                  SoriCMaterialAssets.paperAtlas,
                                  fit: BoxFit.fill,
                                ),
                              ),
                            ),
                          ),
                        ),
                ),
              ),
            ),
            Positioned.fill(
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: material == SoriCMaterial.jade
                        ? const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [Color(0x10FFFFFF), Color(0x40051C18)],
                          )
                        : null,
                  ),
                ),
              ),
            ),
            if (tint != null)
              Positioned.fill(
                child: IgnorePointer(child: ColoredBox(color: tint!)),
              ),
            Padding(
              padding: padding,
              child: material == SoriCMaterial.jade
                  ? child
                  : DefaultTextStyle.merge(
                      style: const TextStyle(color: SoriCLearningTokens.ink),
                      child: child,
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The book cover and paper are one content group, with no fixed page height.
class SoriCBookPanel extends StatelessWidget {
  const SoriCBookPanel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(SoriCLearningTokens.group),
  });
  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) => SoriCMaterialSurface(
    material: SoriCMaterial.jade,
    padding: const EdgeInsets.fromLTRB(6, 4, 4, 4),
    child: SoriCMaterialSurface(
      padding: padding,
      raised: false,
      borderRadius: SoriRadius.brSm,
      child: DefaultTextStyle.merge(
        style: const TextStyle(color: SoriCLearningTokens.ink),
        child: child,
      ),
    ),
  );
}

/// One pressure owner, minimum touch size, and unbounded readable labels.
/// The caller owns async saves and passes [loading] to prevent duplicate taps.
class SoriCPrimaryButton extends StatelessWidget {
  const SoriCPrimaryButton({
    super.key,
    required this.label,
    required this.onTap,
    this.loading = false,
    this.fullWidth = true,
    this.textStyle,
  });
  final String label;
  final VoidCallback? onTap;
  final bool loading;
  final bool fullWidth;
  final TextStyle? textStyle;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null && !loading;
    final face = SoriCMaterialSurface(
      material: SoriCMaterial.gold,
      raised: false,
      borderRadius: SoriRadius.brSm,
      child: Container(
        constraints: const BoxConstraints(minHeight: 48, minWidth: 48),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          border: Border.all(color: const Color(0xFFEDCE8F)),
          borderRadius: SoriRadius.brSm,
        ),
        alignment: Alignment.center,
        child: loading
            ? const SizedBox.square(
                dimension: 20,
                child: SoriLoadingIndicator(
                  strokeWidth: 2,
                  color: SoriCLearningTokens.ink,
                ),
              )
            : ExcludeSemantics(
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  style:
                      textStyle ??
                      TextStyle(
                        fontFamily: SoriLocaleFonts.of(context).body,
                        fontFamilyFallback: SoriLocaleFonts.fallback,
                        color: SoriCLearningTokens.ink,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        height: 1.25,
                      ),
                ),
              ),
      ),
    );
    return Semantics(
      button: true,
      enabled: enabled,
      label: label,
      child: Opacity(
        opacity: onTap == null ? .65 : 1,
        child: SoriPressable(
          onTap: enabled ? onTap : null,
          surfaceDepth: 3,
          surfaceRadius: 12,
          surfaceEdgeColor: const Color(0xFF765020),
          tactileTilt: true,
          pressScale: .99,
          child: fullWidth
              ? SizedBox(width: double.infinity, child: face)
              : face,
        ),
      ),
    );
  }
}
