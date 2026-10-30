import 'package:flutter/material.dart';

import 'c_palette.dart';
import '../approved_chrome_assets.dart';
import '../tokens.dart';

/// Independent alpha assets. No icon or wordmark is cropped from the board.
enum CObject { coin, settings, cloud, arrow, seal, stampbook, book, lantern }

class CObjectArt extends StatelessWidget {
  const CObjectArt(
    this.object, {
    super.key,
    this.size,
    this.fit = BoxFit.contain,
  });
  final CObject object;
  final double? size;
  final BoxFit fit;

  static const paths = {
    CObject.coin: ApprovedChromeAssets.coinFront,
    CObject.settings: ApprovedChromeAssets.settings,
    CObject.cloud: ApprovedChromeAssets.cloud,
    CObject.arrow: 'assets/illustrations/concept_c/arrow_v2.png',
    CObject.seal: 'assets/illustrations/concept_c/seal_v2.png',
    CObject.stampbook: 'assets/illustrations/concept_c/stampbook_v2.png',
    CObject.book: ApprovedChromeAssets.learn,
    CObject.lantern: 'assets/illustrations/gye/weekly_lantern/lit.png',
  };
  static String path(CObject object) => paths[object]!;

  @override
  Widget build(BuildContext context) => Image.asset(
    path(object),
    width: size,
    height: size,
    fit: fit,
    excludeFromSemantics: true,
    filterQuality: FilterQuality.high,
    cacheWidth: size == null
        ? null
        : (size! * MediaQuery.devicePixelRatioOf(context)).ceil(),
  );
}

class CBrandWordmark extends StatelessWidget {
  const CBrandWordmark({super.key});
  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: Text(
      'HANGUL SORI',
      style: TextStyle(
        fontFamily: SoriLocaleFonts.of(context).body,
        fontFamilyFallback: SoriLocaleFonts.fallback,
        fontSize: 13,
        fontWeight: FontWeight.w600,
        letterSpacing: 2,
        color: Color(0xffe9c98a),
        shadows: [Shadow(color: Color(0x88061912), offset: Offset(0, 1))],
      ),
    ),
  );
}

class CArrow extends StatelessWidget {
  const CArrow({
    super.key,
    this.down = false,
    this.dark = false,
    this.size = 18,
  });
  final bool down;
  final bool dark;
  final double size;
  @override
  Widget build(BuildContext context) {
    Widget arrow = CObjectArt(CObject.arrow, size: size);
    if (dark) {
      arrow = ColorFiltered(
        colorFilter: const ColorFilter.mode(CPalette.ink, BlendMode.modulate),
        child: arrow,
      );
    }
    // Transparent authoring margins remain in the source; optical sizing is
    // a UI transform, so the solid chevron reads clearly in a small CTA slot.
    return RotatedBox(
      quarterTurns: down ? 1 : 0,
      child: Transform.scale(scale: 1.8, child: arrow),
    );
  }
}

/// Hover/focus drives one turn; tap is owned by the surrounding action.
class CSettingsCog extends StatefulWidget {
  const CSettingsCog({super.key});
  @override
  State<CSettingsCog> createState() => _CSettingsCogState();
}

class _CSettingsCogState extends State<CSettingsCog>
    with SingleTickerProviderStateMixin {
  late final controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 700),
  );
  late final turns = controller.drive(CurveTween(curve: Curves.easeOutCubic));
  bool reduced = false;
  bool wasFocused = false;
  FocusNode? actionFocus;

  void turn() {
    if (!reduced && !controller.isAnimating) {
      controller.forward(from: 0);
    }
  }

  void actionFocusChanged() {
    final focused = actionFocus?.hasPrimaryFocus ?? false;
    if (focused && !wasFocused) {
      turn();
    }
    wasFocused = focused;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    reduced =
        MediaQuery.disableAnimationsOf(context) ||
        MediaQuery.of(context).accessibleNavigation;
    if (reduced) {
      controller.stop();
      controller.value = 0;
    }
    // The surrounding SoriPressable owns the keyboard stop and activation.
    // Observe its node directly: rebuilding an inherited Focus is insufficient
    // to distinguish every primary-focus transition.
    final node = Focus.maybeOf(context, createDependency: false);
    if (node != actionFocus) {
      actionFocus?.removeListener(actionFocusChanged);
      actionFocus = node;
      actionFocus?.addListener(actionFocusChanged);
      actionFocusChanged();
    }
  }

  @override
  void dispose() {
    actionFocus?.removeListener(actionFocusChanged);
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => MouseRegion(
    onEnter: (_) => turn(),
    child: RotationTransition(
      turns: turns,
      child: const CObjectArt(CObject.settings, size: 34),
    ),
  );
}

class CWaxSeal extends StatelessWidget {
  const CWaxSeal({super.key, this.number, this.active = true, this.size = 43});
  final int? number;
  final bool active;
  final double size;

  @override
  Widget build(BuildContext context) => SizedBox.square(
    dimension: size,
    child: Stack(
      alignment: Alignment.center,
      children: [
        Opacity(
          opacity: active ? 1 : .48,
          child: CObjectArt(CObject.seal, size: size),
        ),
        if (number != null)
          Text(
            '$number',
            style: TextStyle(
              fontFamily: SoriLocaleFonts.of(context).body,
              fontFamilyFallback: SoriLocaleFonts.fallback,
              fontSize: size * .43,
              fontWeight: FontWeight.w700,
              color: active ? CPalette.ink : CPalette.mutedInk,
              shadows: const [
                Shadow(color: Color(0x88fff3d1), offset: Offset(0, 1)),
              ],
            ),
          ),
      ],
    ),
  );
}

class CLantern extends StatelessWidget {
  const CLantern({super.key, required this.lit});
  final bool lit;
  @override
  Widget build(BuildContext context) => SizedBox(
    height: 119,
    child: Image.asset(
      lit
          ? 'assets/illustrations/gye/weekly_lantern/lit.png'
          : 'assets/illustrations/gye/weekly_lantern/off.png',
      fit: BoxFit.contain,
      excludeFromSemantics: true,
      cacheHeight: (119 * MediaQuery.devicePixelRatioOf(context)).ceil(),
    ),
  );
}
