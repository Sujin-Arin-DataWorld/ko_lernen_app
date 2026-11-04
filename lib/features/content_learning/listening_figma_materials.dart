import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../widgets/sori/c_learning_surface.dart';
import '../../widgets/sori/tokens.dart';
import '../../widgets/sori/pressable.dart';

/// Figma zhJY0ZY4gl4VNg8vaaNIXw, 5:5/5:6. Text remains native and scalable.
abstract final class ListeningFigma {
  static const font = 'Manrope';
  static const ink = Color(0xff242c26);
  static const jade = Color(0xff174d43);
  static const paper = Color(0xfff6edde);
  static const name = TextStyle(
    fontFamily: font,
    fontSize: 12,
    height: 1.5,
    letterSpacing: .42,
    fontWeight: FontWeight.w500,
    color: Color(0xff52634d),
  );
  static const translation = TextStyle(
    fontFamily: font,
    fontSize: 16,
    fontWeight: FontWeight.w500,
    height: 1.44,
    color: Color(0xff3c5145),
  );
  static TextStyle korean(bool long) => TextStyle(
    fontFamily: SoriFonts.learningKorean,
    fontSize: 18,
    height: long ? 1.42 : 1.3,
    letterSpacing: 0,
    fontWeight: long ? FontWeight.w500 : FontWeight.w700,
    color: ink,
  );
}

/// Exact paper crop and asymmetric edge from Figma 8:87, 8:95 and 8:148.
class ListeningDialogueSurface extends StatelessWidget {
  const ListeningDialogueSurface({
    super.key,
    required this.ownTurn,
    required this.active,
    required this.child,
  });
  final bool ownTurn, active;
  final Widget child;
  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.only(
      topLeft: const Radius.circular(18),
      topRight: const Radius.circular(18),
      bottomLeft: Radius.circular(ownTurn ? 18 : 6),
      bottomRight: Radius.circular(ownTurn ? 6 : 18),
    );
    return AnimatedContainer(
      duration: SoriMotion.respect(context, const Duration(milliseconds: 180)),
      decoration: BoxDecoration(
        borderRadius: radius,
        border: Border.all(
          color: active
              ? const Color(0xffc08b30)
              : ownTurn
              ? const Color(0xffb5c7a3)
              : const Color(0xffdfc9a2),
        ),
        boxShadow: [
          const BoxShadow(
            color: Color(0x45002b2b),
            offset: Offset(0, 5),
            blurRadius: 7,
          ),
          BoxShadow(
            color: ownTurn ? const Color(0xff61724e) : const Color(0xff816a48),
            offset: const Offset(0, 3),
          ),
          BoxShadow(
            color: ownTurn ? const Color(0xff8f9b73) : const Color(0xffbea070),
            offset: const Offset(0, 2),
          ),
          if (active)
            const BoxShadow(color: Color(0x6befcd80), spreadRadius: 2),
        ],
      ),
      child: SoriCMaterialSurface(
        raised: false,
        borderRadius: radius,
        tint: ownTurn ? const Color(0xb3bfdccb) : null,
        padding: const EdgeInsets.fromLTRB(11, 7, 11, 5),
        child: child,
      ),
    );
  }
}

/// Figma 8:144/146: 32dp face within a real 48dp interactive target.
class ListeningBubbleAction extends StatelessWidget {
  const ListeningBubbleAction({
    super.key,
    required this.label,
    required this.icon,
    required this.onPressed,
    this.brass = false,
    this.selected = false,
  });
  final String label;
  final IconData icon;
  final VoidCallback? onPressed;
  final bool brass, selected;
  @override
  Widget build(BuildContext context) {
    final large = MediaQuery.textScalerOf(context).scale(1) > 1.25;
    final face = Container(
      constraints: BoxConstraints(
        minHeight: 32,
        minWidth: large
            ? 48
            : brass
            ? 106
            : 146,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 5),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(9),
        gradient: brass
            ? LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: selected
                    ? const [Color(0xfff4dfad), Color(0xffd7ac59)]
                    : const [Color(0xfff2ddb0), Color(0xffe4c28a)],
              )
            : null,
        color: brass
            ? null
            : selected
            ? const Color(0x47aec7b4)
            : const Color(0x2bfffdf0),
        border: brass ? null : Border.all(color: const Color(0x3dae9e78)),
        boxShadow: brass
            ? const [
                BoxShadow(
                  color: Color(0x26624828),
                  offset: Offset(0, 2),
                  blurRadius: 2,
                ),
                BoxShadow(color: Color(0xffa98b58), offset: Offset(0, 1)),
              ]
            : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon == Icons.pause_rounded)
            const Icon(Icons.pause_rounded, size: 20)
          else
            SvgPicture.asset(
              'design_assets/hoeren/${brass ? 'speaker' : 'translate'}.svg',
              width: 20,
              height: 20,
              excludeFromSemantics: true,
            ),
          const SizedBox(width: 6),
          Flexible(child: Text(label)),
        ],
      ),
    );
    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        minimumSize: const Size(48, 48),
        padding: const EdgeInsets.symmetric(vertical: 8),
        tapTargetSize: MaterialTapTargetSize.padded,
        foregroundColor: ListeningFigma.jade,
        textStyle: const TextStyle(
          fontFamily: ListeningFigma.font,
          fontSize: 14,
          height: 22 / 14,
          fontWeight: FontWeight.w600,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9)),
      ),
      child: face,
    );
  }
}

/// Figma component 8:24; the caller retains playback/progress ownership.
class ListeningFigmaPrimary extends StatelessWidget {
  const ListeningFigmaPrimary({
    super.key,
    required this.label,
    required this.onTap,
  });
  final String label;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    enabled: onTap != null,
    child: SoriPressable(
      onTap: onTap,
      // Keep lettering stable; the raised face moves into its lower edge.
      pressScale: 1,
      pressDuration: SoriMotion.fast,
      releaseDuration: SoriMotion.medium,
      releaseCurve: SoriMotion.gentle,
      surfaceDepth: 3,
      surfaceEdgeColor: const Color(0xff9d763c),
      surfaceRadius: 20,
      child: Container(
        constraints: const BoxConstraints(minHeight: 56),
        width: double.infinity,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xffac8243)),
          boxShadow: const [
            BoxShadow(
              color: Color(0x213e2a1a),
              offset: Offset(0, 6),
              blurRadius: 6,
            ),
            BoxShadow(color: Color(0xff675335), offset: Offset(0, 5)),
            BoxShadow(color: Color(0xff9d763c), offset: Offset(0, 3)),
          ],
        ),
        child: SizedBox(
          width: double.infinity,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(19),
            child: Stack(
              alignment: Alignment.center,
              children: [
                const Positioned.fill(
                  child: ListeningPaperTexture(bottom: true),
                ),
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          const Color(0xfff2d398).withValues(alpha: .85),
                          const Color(0xffd6a957).withValues(alpha: .85),
                        ],
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 16,
                  ),
                  child: Text(
                    label,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontFamily: ListeningFigma.font,
                      fontSize: 20,
                      height: 1.1,
                      fontWeight: FontWeight.w600,
                      color: ListeningFigma.ink,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

class ListeningPaperTexture extends StatelessWidget {
  const ListeningPaperTexture({super.key, this.bottom = false});
  final bool bottom;
  @override
  Widget build(BuildContext context) => IgnorePointer(
    child: ExcludeSemantics(
      child: LayoutBuilder(
        builder: (context, bounds) => ClipRect(
          child: OverflowBox(
            alignment: bottom ? Alignment.bottomRight : Alignment.topRight,
            minWidth: bounds.maxWidth * 2,
            maxWidth: bounds.maxWidth * 2,
            minHeight: bounds.maxHeight * 2,
            maxHeight: bounds.maxHeight * 2,
            child: Image.asset(
              'assets/illustrations/concept_c/material_atlas.png',
              fit: BoxFit.fill,
            ),
          ),
        ),
      ),
    ),
  );
}

class ListeningHeaderIcon extends StatelessWidget {
  const ListeningHeaderIcon(this.name, {super.key});
  final String name;
  @override
  Widget build(BuildContext context) => name == 'home'
      ? Center(
          child: Image.asset(
            'design_assets/hoeren/home-c-v1.png',
            width: 40,
            height: 40,
            cacheWidth: 160,
            fit: BoxFit.contain,
            excludeFromSemantics: true,
          ),
        )
      : Center(
          child: SizedBox(
            width: 22,
            height: 22,
            child: SvgPicture.asset(
              'design_assets/hoeren/$name.svg',
              width: 22,
              height: 22,
              excludeFromSemantics: true,
            ),
          ),
        );
}

class ListeningSpeakerSignal extends StatelessWidget {
  const ListeningSpeakerSignal({
    super.key,
    required this.active,
    required this.ownTurn,
  });
  final bool active, ownTurn;
  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: AnimatedContainer(
      duration: SoriMotion.respect(context, const Duration(milliseconds: 180)),
      width: 5,
      height: 5,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: active
            ? const Color(0xffc89a43)
            : ownTurn
            ? const Color(0xff337a67)
            : const Color(0xffbc9558),
        boxShadow: active
            ? const [BoxShadow(color: Color(0x66e9ce8a), spreadRadius: 3)]
            : null,
      ),
    ),
  );
}

class ListeningTranslationReveal extends StatelessWidget {
  const ListeningTranslationReveal({super.key, required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) => SoriMotion.reduceMotion(context)
      ? child
      : AnimatedSize(
          duration: const Duration(milliseconds: 220),
          alignment: Alignment.topCenter,
          curve: Curves.easeOutCubic,
          child: child,
        );
}
