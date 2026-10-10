import 'dart:ui' as ui;

import 'package:flutter/material.dart';

/// Viewports into unchanged source PNGs; original files and alpha are retained.
class YeopjeonAssetSlice extends StatelessWidget {
  const YeopjeonAssetSlice({
    super.key,
    required this.asset,
    required this.source,
  });
  final String asset;
  final Rect source;

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: ClipRect(
      child: LayoutBuilder(
        builder: (_, bounds) {
          final sx = bounds.maxWidth / source.width;
          final sy = bounds.maxHeight / source.height;
          return Stack(
            children: [
              Positioned(
                left: -source.left * sx,
                top: -source.top * sy,
                width: 1254 * sx,
                height: 1254 * sy,
                child: Image.asset(
                  asset,
                  fit: BoxFit.fill,
                  filterQuality: FilterQuality.medium,
                ),
              ),
            ],
          );
        },
      ),
    ),
  );
}

class YeopjeonCoinImage extends StatelessWidget {
  const YeopjeonCoinImage({super.key, required this.size});
  final double size;
  @override
  Widget build(BuildContext context) => SizedBox.square(
    dimension: size,
    child: const YeopjeonAssetSlice(
      asset: 'assets/animations/rewards/coin_face.png',
      source: Rect.fromLTWH(168, 156, 914, 938),
    ),
  );
}

/// One clipped canvas. Expanded labels get one continuous face; the frame and
/// cloud retain their normal size instead of stretching an eight-pixel bevel.
class YeopjeonCtaMaterial extends StatefulWidget {
  const YeopjeonCtaMaterial({super.key, required this.primary});
  final bool primary;
  @override
  State<YeopjeonCtaMaterial> createState() => _YeopjeonCtaMaterialState();
}

class _YeopjeonCtaMaterialState extends State<YeopjeonCtaMaterial> {
  ImageStream? _stream;
  ImageInfo? _info;
  late final _listener = ImageStreamListener((info, _) {
    final old = _info;
    setState(() => _info = info);
    old?.dispose();
  });
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final next = const AssetImage(
      'assets/animations/rewards/cta_atlas.png',
    ).resolve(createLocalImageConfiguration(context));
    if (next.key == _stream?.key) return;
    _stream?.removeListener(_listener);
    _stream = next..addListener(_listener);
  }

  @override
  void dispose() {
    _stream?.removeListener(_listener);
    _info?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => IgnorePointer(
    child: RepaintBoundary(
      child: CustomPaint(
        painter: _CtaPainter(_info?.image, widget.primary),
        size: Size.infinite,
      ),
    ),
  );
}

class _CtaPainter extends CustomPainter {
  const _CtaPainter(this.image, this.primary);
  final ui.Image? image;
  final bool primary;

  @override
  void paint(Canvas canvas, Size size) {
    final atlas = image;
    if (atlas == null || size.isEmpty) return;
    final base = primary ? 54.0 : 48.0, unit = base / 232;
    final top = primary ? 101.0 : 397.0;
    const sx = [14.0, 244.0, 1101.0, 1241.0];
    final sy = [top, top + 64, top + 80, top + 232];
    final dx = [0.0, 230 * unit, size.width - 140 * unit, size.width];
    final dy = [0.0, 64 * unit, size.height - 152 * unit, size.height];
    final paint = Paint()..filterQuality = FilterQuality.medium;
    final outer = RRect.fromRectAndRadius(
      Offset.zero & size,
      const Radius.circular(12),
    );
    canvas.save();
    canvas.clipRRect(outer);
    // A continuous face for every height removes cap seams on held contact.
    canvas.drawImageRect(
      atlas,
      Rect.fromLTRB(254, top + 44, 1090, top + 188),
      Offset.zero & size,
      paint,
    );
    final ring = Path()
      ..fillType = PathFillType.evenOdd
      ..addRRect(outer)
      ..addRRect(outer.deflate(26 * unit));
    final cloud = Path()
      ..moveTo(24, 209)
      ..lineTo(24, 161)
      ..cubicTo(15, 149, 22, 127, 41, 127)
      ..cubicTo(36, 108, 52, 94, 73, 96)
      ..cubicTo(89, 91, 104, 103, 111, 115)
      ..cubicTo(129, 113, 145, 126, 143, 140)
      ..cubicTo(160, 138, 177, 145, 180, 162)
      ..cubicTo(195, 171, 192, 192, 170, 199)
      ..lineTo(195, 209)
      ..close();
    final transform = Matrix4.identity()
      ..translateByDouble(0, size.height - base, 0, 1)
      ..scaleByDouble(unit, unit, 1, 1);
    // Separate clips keep the ring hole consistent on the browser backend.
    for (final mask in [ring, cloud.transform(transform.storage)]) {
      canvas.save();
      canvas.clipPath(mask);
      for (var row = 0; row < 3; row++) {
        for (var col = 0; col < 3; col++) {
          if (row == 1 && col == 1) continue;
          canvas.drawImageRect(
            atlas,
            Rect.fromLTRB(sx[col], sy[row], sx[col + 1], sy[row + 1]),
            Rect.fromLTRB(dx[col], dy[row], dx[col + 1], dy[row + 1]),
            paint,
          );
        }
      }
      canvas.restore();
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_CtaPainter old) =>
      old.image != image || old.primary != primary;
}

class YeopjeonCtaMedallion extends StatelessWidget {
  const YeopjeonCtaMedallion({super.key});
  @override
  Widget build(BuildContext context) => Container(
    width: 29,
    height: 29,
    alignment: Alignment.center,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      border: Border.all(color: const Color(0xffa2743f)),
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xfffff4d9), Color(0xffdac392)],
      ),
      boxShadow: const [
        BoxShadow(
          color: Color(0x60654622),
          offset: Offset(0, 1),
          blurRadius: 2,
        ),
      ],
    ),
    child: const SizedBox(
      width: 14,
      height: 22,
      child: YeopjeonAssetSlice(
        asset: 'assets/animations/rewards/arrow.png',
        source: Rect.fromLTWH(390, 238, 506, 790),
      ),
    ),
  );
}
