import 'package:flutter/material.dart';

import '../../models/ildu_r16_art.dart';
import '../hanok_asset_image.dart';
import 'ildu_r16_layer_artwork.dart';

/// Switches artwork by an exact existing process ID, never by a guessed index.
/// The caller continues to own visibility, eligibility and purchases. Gates and
/// unavailable R16 assets retain their existing approved image.
class IlDuR16ProcessImage extends StatefulWidget {
  const IlDuR16ProcessImage({
    super.key,
    required this.processId,
    required this.fallbackAsset,
    this.fit = BoxFit.contain,
    this.cacheHeight,
    this.cacheWidth,
    this.semanticLabel,
    this.excludeFromSemantics = false,
    this.loader,
    this.prefetchPack = true,
    this.errorBuilder,
  });

  final String processId;
  final String fallbackAsset;
  final BoxFit fit;
  final int? cacheHeight;
  final int? cacheWidth;
  final String? semanticLabel;
  final bool excludeFromSemantics;
  final Future<IlDuR16ArtCatalog> Function()? loader;
  final bool prefetchPack;
  final ImageErrorWidgetBuilder? errorBuilder;

  @override
  State<IlDuR16ProcessImage> createState() => _IlDuR16ProcessImageState();
}

class _IlDuR16ProcessImageState extends State<IlDuR16ProcessImage> {
  AssetBundle? _bundle;
  Future<IlDuR16ArtCatalog>? _future;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final bundle = DefaultAssetBundle.of(context);
    if (_bundle != bundle || _future == null) {
      _bundle = bundle;
      _future = widget.loader?.call() ?? IlDuR16ArtCatalog.load(bundle: bundle);
    }
  }

  @override
  void didUpdateWidget(covariant IlDuR16ProcessImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.loader != widget.loader) {
      _future =
          widget.loader?.call() ?? IlDuR16ArtCatalog.load(bundle: _bundle);
    }
  }

  Widget _fallback() => HanokAssetImage(
    widget.fallbackAsset,
    fit: widget.fit,
    cacheHeight: widget.cacheHeight,
    cacheWidth: widget.cacheWidth,
    semanticLabel: widget.semanticLabel,
    excludeFromSemantics: widget.excludeFromSemantics,
    prefetchPack: widget.prefetchPack,
    errorBuilder: widget.errorBuilder,
  );

  @override
  Widget build(BuildContext context) => FutureBuilder<IlDuR16ArtCatalog>(
    future: _future,
    builder: (context, snapshot) {
      // Sarangchae has a complete foreground/shadow catalog. Fail closed in
      // that renderer even if metadata fails; never flash the old studio mat.
      if (widget.processId.startsWith('ildu.sarangchae-')) {
        return IlDuR16LayerArtwork(
          key: ValueKey('r16-${widget.processId}'),
          processId: widget.processId,
          fit: widget.fit,
          semanticLabel: widget.semanticLabel,
          excludeFromSemantics: widget.excludeFromSemantics,
        );
      }
      if (!snapshot.hasData &&
          !snapshot.hasError &&
          snapshot.connectionState != ConnectionState.done) {
        // The surrounding artwork frame retains its dimensions while local
        // metadata resolves. Static artwork does not need a repeating timer.
        return const SizedBox.shrink();
      }
      final stage = snapshot.data?.stagesByProcessId[widget.processId];
      if (stage == null) {
        return _fallback();
      }
      return Image.asset(
        stage.image.asset,
        key: ValueKey('r16-${widget.processId}'),
        fit: widget.fit,
        cacheHeight: widget.cacheHeight,
        cacheWidth: widget.cacheWidth,
        semanticLabel: widget.semanticLabel,
        excludeFromSemantics: widget.excludeFromSemantics,
        errorBuilder: (_, _, _) => _fallback(),
      );
    },
  );
}
