import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../l10n/generated/app_localizations.dart';
import '../../models/ildu_r16_layers.dart';

/// Approved scene foreground and separate contact shadow, without a studio mat.
/// Do not wrap this painter in an isolated Opacity/FadeTransition: multiply must
/// see the actual jade/paper surface. [opacity] applies to both paints directly.
class IlDuR16LayerArtwork extends StatefulWidget {
  const IlDuR16LayerArtwork({
    super.key,
    required this.processId,
    this.opacity = 1,
    this.fit = BoxFit.contain,
    this.semanticLabel,
    this.excludeFromSemantics = false,
  }) : assert(opacity >= 0 && opacity <= 1);

  final String processId;
  final double opacity;
  final BoxFit fit;
  final String? semanticLabel;
  final bool excludeFromSemantics;

  @override
  State<IlDuR16LayerArtwork> createState() => _IlDuR16LayerArtworkState();
}

class _IlDuR16LayerArtworkState extends State<IlDuR16LayerArtwork> {
  AssetBundle? _bundle;
  Future<IlDuR16LayerCatalog>? _catalog;
  int _generation = 0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final bundle = DefaultAssetBundle.of(context);
    if (_bundle != bundle) {
      _bundle = bundle;
      _catalog = IlDuR16LayerCatalog.load(bundle: bundle);
    }
  }

  @override
  Widget build(BuildContext context) => Semantics(
    image: true,
    label: widget.excludeFromSemantics ? null : widget.semanticLabel,
    excludeSemantics: widget.excludeFromSemantics,
    child: FutureBuilder<IlDuR16LayerCatalog>(
      future: _catalog,
      builder: (context, snapshot) {
        // The approved site stage contains zero architecture. Its studio GI
        // pass is noise, not an earned building or a ground shadow to display.
        if (widget.processId == 'ildu.sarangchae-site') {
          return const SizedBox.expand();
        }
        if (!snapshot.hasData && !snapshot.hasError) {
          return const SizedBox.expand();
        }
        final stage = snapshot.data?.stagesByProcessId[widget.processId];
        if (stage == null) return _error();
        return _LayerImages(
          key: ValueKey('${stage.processId}-$_generation'),
          stage: stage,
          opacity: widget.opacity,
          fit: widget.fit,
          errorBuilder: _error,
        );
      },
    ),
  );

  Widget _error() => Center(
    child: IconButton(
      tooltip: AppL10n.of(context).loadErrorTryAgain,
      icon: const Icon(Icons.refresh_rounded),
      onPressed: () => setState(() {
        _generation++;
        _catalog = IlDuR16LayerCatalog.load(bundle: _bundle);
      }),
    ),
  );
}

class _LayerImages extends StatefulWidget {
  const _LayerImages({
    super.key,
    required this.stage,
    required this.opacity,
    required this.fit,
    required this.errorBuilder,
  });
  final IlDuR16LayerStage stage;
  final double opacity;
  final BoxFit fit;
  final Widget Function() errorBuilder;

  @override
  State<_LayerImages> createState() => _LayerImagesState();
}

class _LayerImagesState extends State<_LayerImages> {
  final _streams = <ImageStream>[];
  final _listeners = <ImageStreamListener>[];
  final _images = <ImageInfo?>[null, null];
  AssetBundle? _bundle;
  bool _failed = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final bundle = DefaultAssetBundle.of(context);
    if (_bundle == bundle) return;
    _clear();
    _bundle = bundle;
    final configuration = createLocalImageConfiguration(context);
    for (final (index, layer) in [
      widget.stage.shadow,
      widget.stage.foreground,
    ].indexed) {
      final stream = AssetImage(
        layer.asset,
        bundle: bundle,
      ).resolve(configuration);
      final listener = ImageStreamListener(
        (info, synchronous) {
          _images[index]?.dispose();
          _images[index] = info;
          if (!synchronous && mounted) setState(() {});
        },
        onError: (Object error, StackTrace? stack) {
          if (mounted) setState(() => _failed = true);
        },
      );
      _streams.add(stream);
      _listeners.add(listener);
      stream.addListener(listener);
    }
  }

  void _clear() {
    for (var i = 0; i < _streams.length; i++) {
      _streams[i].removeListener(_listeners[i]);
    }
    _streams.clear();
    _listeners.clear();
    for (var i = 0; i < _images.length; i++) {
      _images[i]?.dispose();
      _images[i] = null;
    }
    _failed = false;
  }

  @override
  void dispose() {
    _clear();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_failed) return widget.errorBuilder();
    final shadow = _images[0]?.image;
    final foreground = _images[1]?.image;
    if (shadow == null || foreground == null) return const SizedBox.expand();
    return CustomPaint(
      painter: IlDuR16LayerPainter(
        shadow: shadow,
        foreground: foreground,
        opacity: widget.opacity,
        fit: widget.fit,
      ),
      child: const SizedBox.expand(),
    );
  }
}

/// Both passes use exactly the same full-canvas fit. The shadow PNG represents
/// Raw 0..1 attenuation; its >1 HDR indirect light remains in the source EXR.
class IlDuR16LayerPainter extends CustomPainter {
  const IlDuR16LayerPainter({
    required this.shadow,
    required this.foreground,
    this.opacity = 1,
    this.fit = BoxFit.contain,
  });

  final ui.Image shadow;
  final ui.Image foreground;
  final double opacity;
  final BoxFit fit;

  @override
  void paint(Canvas canvas, Size size) {
    if (opacity == 0 || size.isEmpty) return;
    final sourceSize = Size(
      foreground.width.toDouble(),
      foreground.height.toDouble(),
    );
    final fitted = applyBoxFit(fit, sourceSize, size);
    final source = Alignment.center.inscribe(
      fitted.source,
      Offset.zero & sourceSize,
    );
    final destination = Alignment.center.inscribe(
      fitted.destination,
      Offset.zero & size,
    );
    final paint = Paint()
      ..filterQuality = FilterQuality.high
      // Paint alpha interpolates each multiplier with neutral white:
      // M_effective = 1 + opacity * (M - 1), never RGB * opacity.
      ..color = Colors.white.withValues(alpha: opacity)
      ..blendMode = BlendMode.multiply;
    canvas.drawImageRect(shadow, source, destination, paint);
    paint.blendMode = BlendMode.srcOver;
    canvas.drawImageRect(foreground, source, destination, paint);
  }

  @override
  bool shouldRepaint(covariant IlDuR16LayerPainter oldDelegate) =>
      oldDelegate.shadow != shadow ||
      oldDelegate.foreground != foreground ||
      oldDelegate.opacity != opacity ||
      oldDelegate.fit != fit;
}
