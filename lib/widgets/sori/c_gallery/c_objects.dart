import 'package:flutter/material.dart';

import 'c_palette.dart';

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
    CObject.coin: 'assets/illustrations/concept_c/coin_v2.png',
    CObject.settings: 'assets/illustrations/concept_c/settings_v2.png',
    CObject.cloud: 'assets/illustrations/concept_c/cloud_v2.png',
    CObject.arrow: 'assets/illustrations/concept_c/arrow_v2.png',
    CObject.seal: 'assets/illustrations/concept_c/seal_v2.png',
    CObject.stampbook: 'assets/illustrations/concept_c/stampbook_v2.png',
    CObject.book: 'assets/illustrations/concept_c/book_v2.png',
    CObject.lantern: 'assets/illustrations/concept_c/lantern_v2.png',
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
  Widget build(BuildContext context) => const ExcludeSemantics(
    child: Text(
      'HANGUL SORI',
      style: TextStyle(
        fontFamily: 'Paperlogy',
        fontSize: 11.5,
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
    if (!reduced && !controller.isAnimating) controller.forward(from: 0);
  }

  void actionFocusChanged() {
    final focused = actionFocus?.hasPrimaryFocus ?? false;
    if (focused && !wasFocused) turn();
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
              fontFamily: 'Paperlogy',
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
    child: Center(
      child: SizedBox(
        width: 119 * 926 / 1698,
        height: 119,
        child: Stack(
          fit: StackFit.expand,
          children: [
            const CObjectArt(CObject.lantern),
            if (!lit)
              ClipPath(
                clipper: const _CLanternGlassClipper(),
                child: const ColorFiltered(
                  // Turn off the transmitted light without tinting the
                  // original brass, wood, frame, reflection or alpha edges.
                  colorFilter: ColorFilter.matrix([
                    .25,
                    .35,
                    .20,
                    0,
                    20,
                    .20,
                    .35,
                    .20,
                    0,
                    20,
                    .18,
                    .30,
                    .22,
                    0,
                    24,
                    0,
                    0,
                    0,
                    1,
                    0,
                  ]),
                  child: CObjectArt(CObject.lantern),
                ),
              ),
          ],
        ),
      ),
    ),
  );
}

/// Authored glass apertures in the unchanged 926x1698 lantern. Wooden muntins,
/// the square ornaments and their inner glass openings retain their geometry.
class _CLanternGlassClipper extends CustomClipper<Path> {
  const _CLanternGlassClipper();

  @override
  Path getClip(Size size) {
    final front = Path()
      ..moveTo(269, 798)
      ..quadraticBezierTo(269, 765, 303, 752)
      ..quadraticBezierTo(316, 729, 347, 734)
      ..lineTo(423, 733)
      ..quadraticBezierTo(459, 735, 466, 757)
      ..quadraticBezierTo(497, 766, 497, 798)
      ..lineTo(497, 1356)
      ..lineTo(307, 1356)
      ..quadraticBezierTo(268, 1356, 268, 1328)
      ..close();
    final side = Path()
      ..moveTo(575, 798)
      ..quadraticBezierTo(575, 766, 601, 754)
      ..quadraticBezierTo(613, 732, 640, 732)
      ..quadraticBezierTo(674, 732, 686, 758)
      ..quadraticBezierTo(709, 770, 709, 798)
      ..lineTo(709, 1322)
      ..quadraticBezierTo(709, 1345, 678, 1348)
      ..lineTo(575, 1355)
      ..close();
    final wood = Path()
      ..addRect(const Rect.fromLTWH(367, 725, 24, 635))
      ..addRect(const Rect.fromLTWH(633, 725, 19, 635))
      ..addRect(const Rect.fromLTWH(337, 975, 87, 118))
      ..addRect(const Rect.fromLTWH(613, 975, 58, 108));
    void rail(List<Offset> points) => wood.addPolygon(points, true);
    rail(const [
      Offset(264, 806),
      Offset(501, 822),
      Offset(501, 858),
      Offset(264, 840),
    ]);
    rail(const [
      Offset(264, 1219),
      Offset(501, 1244),
      Offset(501, 1280),
      Offset(264, 1260),
    ]);
    rail(const [
      Offset(573, 815),
      Offset(712, 798),
      Offset(712, 832),
      Offset(573, 850),
    ]);
    rail(const [
      Offset(573, 1236),
      Offset(712, 1218),
      Offset(712, 1252),
      Offset(573, 1270),
    ]);
    final glass =
        Path.combine(
            PathOperation.difference,
            Path()
              ..addPath(front, Offset.zero)
              ..addPath(side, Offset.zero),
            wood,
          )
          ..addRect(const Rect.fromLTWH(359, 1007, 40, 62))
          ..addRect(const Rect.fromLTWH(633, 1007, 20, 52));
    return glass.transform(
      Matrix4.diagonal3Values(size.width / 926, size.height / 1698, 1).storage,
    );
  }

  @override
  bool shouldReclip(_CLanternGlassClipper oldClipper) => false;
}
