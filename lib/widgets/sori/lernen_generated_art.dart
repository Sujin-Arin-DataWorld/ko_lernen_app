import 'package:flutter/material.dart';

/// Standalone artwork generated for the approved Lernen screens.
/// The bounds describe foreground placement. The full PNG is painted.
class LernenGeneratedArt extends StatelessWidget {
  const LernenGeneratedArt({
    super.key,
    required this.name,
    this.fit = BoxFit.contain,
  }) : assert(fit == BoxFit.contain || fit == BoxFit.fill);

  final String name;
  final BoxFit fit;

  static String assetPath(String name) =>
      'assets/illustrations/concept_c/lernen_20261110/$name.png';

  static const _geometry = <String, (Size, Rect)>{
    'topic-fan': (
      Size(640, 427),
      Rect.fromLTRB(53.75, 26.688, 596.25, 405.316),
    ),
    'topic-cup': (
      Size(640, 427),
      Rect.fromLTRB(66.667, 24.186, 571.25, 404.899),
    ),
    'topic-home': (
      Size(640, 427),
      Rect.fromLTRB(95.833, 45.869, 544.167, 366.536),
    ),
    'topic-transport': (
      Size(640, 320),
      Rect.fromLTRB(39.324, 35.716, 591.657, 287.892),
    ),
    'jade-book': (
      Size(640, 585),
      Rect.fromLTRB(34.634, 35.617, 594.634, 521.572),
    ),
    'hanji-refined': (Size(599, 1066), Rect.fromLTRB(0, 0, 599, 1066)),
    'jade': (Size(1254, 1254), Rect.fromLTRB(0, 0, 1254, 1254)),
    'brass-alignment': (Size(1280, 427), Rect.fromLTRB(21, 144, 1259, 283)),
    'brass-button': (
      Size(1280, 427),
      Rect.fromLTRB(28.877, 128.572, 1250.534, 281.914),
    ),
    'folio-card': (
      Size(1280, 853),
      Rect.fromLTRB(15.833, 33.32, 1245.833, 806.352),
    ),
    'folio-preview': (
      Size(1280, 427),
      Rect.fromLTRB(30.055, 56.619, 1232.855, 368.612),
    ),
    'review-tray': (
      Size(1280, 882),
      Rect.fromLTRB(59.338, 60.156, 1220.662, 784.565),
    ),
    'review-drawer': (
      Size(640, 585),
      Rect.fromLTRB(94.634, 75.626, 563.415, 493.761),
    ),
    'audio-puck': (
      Size(640, 640),
      Rect.fromLTRB(118.915, 108.708, 510.367, 511.898),
    ),
    'audio-puck-recording': (
      Size(640, 640),
      Rect.fromLTRB(75.534, 60.734, 557.831, 556.3),
    ),
    'audio-base': (
      Size(1280, 427),
      Rect.fromLTRB(29.466, 100.852, 1249.945, 322.609),
    ),
    'audio-base-compare': (
      Size(1280, 427),
      Rect.fromLTRB(15.912, 33.617, 1264.088, 380.407),
    ),
  };

  @override
  Widget build(BuildContext context) {
    final (sourceSize, artwork) = _geometry[name]!;
    return ExcludeSemantics(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final slot = constraints.biggest;
          if (!slot.isFinite || slot.isEmpty) {
            return Image.asset(assetPath(name), fit: BoxFit.contain);
          }
          final fitted = applyBoxFit(fit, artwork.size, slot).destination;
          final scaleX = fitted.width / artwork.width;
          final scaleY = fitted.height / artwork.height;
          final imageSize = Size(
            sourceSize.width * scaleX,
            sourceSize.height * scaleY,
          );
          final translation = Offset(
            (sourceSize.width / 2 - artwork.center.dx) * scaleX,
            (sourceSize.height / 2 - artwork.center.dy) * scaleY,
          );
          return OverflowBox(
            minWidth: imageSize.width,
            maxWidth: imageSize.width,
            minHeight: imageSize.height,
            maxHeight: imageSize.height,
            child: Transform.translate(
              offset: translation,
              child: Image.asset(
                assetPath(name),
                fit: BoxFit.fill,
                filterQuality: FilterQuality.medium,
              ),
            ),
          );
        },
      ),
    );
  }
}
