import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:crypto/crypto.dart' as crypto;
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../../l10n/generated/app_localizations.dart';
import '../../widgets/sori/dancheong_stamp.dart';
import 'dancheong_catalog.dart';
import 'dancheong_models.dart';

final class DancheongTextFitFailure implements Exception {
  const DancheongTextFitFailure();
}

final class DancheongExportPackage {
  const DancheongExportPackage({
    required this.artworkId,
    required this.revision,
    required this.format,
    required this.png,
    required this.width,
    required this.height,
    required this.composition,
    required this.sha256,
  });
  final String artworkId;
  final int revision;
  final DancheongFormat format;
  final Uint8List png;
  final int width;
  final int height;
  final DancheongComposition composition;
  final String sha256;
}

/// Preview and export share one canvas and source bytes. Small source stamps
/// stay below their native size, including the focal motif.
final class DancheongRenderer {
  DancheongRenderer({AssetBundle? bundle}) : bundle = bundle ?? rootBundle;
  final AssetBundle bundle;
  Future<DancheongExportPackage> render(
    DancheongArtwork artwork, {
    required Set<String> ownedSlugs,
    void Function()? assertCurrent,
  }) async {
    final c = artwork.composition;
    void validate() {
      assertCurrent?.call();
      if (c.motifSlugs.isEmpty || !c.motifSlugs.every(ownedSlugs.contains)) {
        throw StateError('Missing owned artwork material');
      }
    }

    validate();
    final images = <ui.Image>[];
    ui.Image? borderImage;
    ui.Image? flowerOrnament;
    ui.Picture? picture;
    ui.Image? output;
    try {
      for (final slug in c.motifSlugs) {
        final bytes = await bundle.load(knownMotif(slug)!.spec.assetPath);
        validate();
        final codec = await ui.instantiateImageCodec(
          bytes.buffer.asUint8List(bytes.offsetInBytes, bytes.lengthInBytes),
        );
        try {
          images.add((await codec.getNextFrame()).image);
        } finally {
          codec.dispose();
        }
      }
      validate();
      if (c.border != DancheongBorder.none) {
        final data = await bundle.load(switch (c.border) {
          DancheongBorder.brocadeFlow => dancheongBrocadeFlowBorderAsset,
          DancheongBorder.colorRibbon => dancheongColorRibbonBorderAsset,
          DancheongBorder.lotusScroll => dancheongLotusBorderAsset,
          DancheongBorder.none => throw StateError('No border'),
        });
        final codec = await ui.instantiateImageCodec(
          data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
        );
        try {
          borderImage = (await codec.getNextFrame()).image;
        } finally {
          codec.dispose();
        }
        validate();
      }
      if (c.template == DancheongTemplate.flower && borderImage != null) {
        final data = await bundle.load(dancheongFlowerStudyAsset);
        final codec = await ui.instantiateImageCodec(
          data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
        );
        try {
          flowerOrnament = (await codec.getNextFrame()).image;
        } finally {
          codec.dispose();
        }
        validate();
      }
      final size = Size(1080, c.format == DancheongFormat.story ? 1920 : 1350);
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      try {
        _CompositionPainter(
          c,
          images,
          borderImage,
          flowerOrnament,
        ).paint(canvas, size);
      } finally {
        picture = recorder.endRecording();
      }
      output = await picture.toImage(size.width.toInt(), size.height.toInt());
      final data = await output.toByteData(format: ui.ImageByteFormat.png);
      validate();
      if (data == null) {
        throw StateError('PNG encoding failed');
      }
      final png = data.buffer.asUint8List(
        data.offsetInBytes,
        data.lengthInBytes,
      );
      return DancheongExportPackage(
        artworkId: artwork.id,
        revision: artwork.revision,
        format: c.format,
        png: png,
        width: size.width.toInt(),
        height: size.height.toInt(),
        composition: c,
        sha256: crypto.sha256.convert(png).toString(),
      );
    } finally {
      output?.dispose();
      borderImage?.dispose();
      flowerOrnament?.dispose();
      picture?.dispose();
      for (final image in images) {
        image.dispose();
      }
    }
  }
}

class _CompositionPainter {
  _CompositionPainter(
    this.c,
    this.images,
    this.borderImage,
    this.flowerOrnament,
  );
  final DancheongComposition c;
  final List<ui.Image> images;
  final ui.Image? borderImage;
  final ui.Image? flowerOrnament;
  void _stamp(Canvas canvas, int index, Offset center, double size) {
    final source = images[index % images.length];
    final side = math.min(
      size,
      math.min(source.width, source.height).toDouble(),
    );
    final target = Rect.fromCenter(center: center, width: side, height: side);
    final fitted = applyBoxFit(
      BoxFit.contain,
      Size(source.width.toDouble(), source.height.toDouble()),
      target.size,
    );
    canvas.drawImageRect(
      source,
      Offset.zero & Size(source.width.toDouble(), source.height.toDouble()),
      Alignment.center.inscribe(fitted.destination, target),
      Paint()..filterQuality = FilterQuality.high,
    );
  }

  void paint(Canvas canvas, Size size) {
    final h = size.height;
    canvas.drawColor(const Color(0xFFFAF6EC), BlendMode.src);
    // Restrained frames echo painted timber. Artwork colors come from the
    // actual collected motif images, rather than recoloring them.
    if (borderImage == null) {
      for (final (inset, color, width) in const [
        (48.0, Color(0xFF247567), 3.0),
        (58.0, Color(0xFFC99A2E), 1.0),
        (72.0, Color(0xFF247567), 1.0),
      ]) {
        canvas.drawRect(
          Rect.fromLTWH(inset, inset, 1080 - inset * 2, h - inset * 2),
          Paint()
            ..color = color
            ..strokeWidth = width
            ..style = PaintingStyle.stroke,
        );
      }
    }
    final hasText =
        c.koreanText.trim().isNotEmpty ||
        c.translation.trim().isNotEmpty ||
        c.signature.trim().isNotEmpty;
    Rect? frameRect;
    var work = Rect.fromLTRB(92, 92, 988, h - 92);
    final frame = borderImage;
    if (frame != null) {
      final source = Size(frame.width.toDouble(), frame.height.toDouble());
      frameRect = Alignment.center.inscribe(
        applyBoxFit(BoxFit.contain, source, size).destination,
        Offset.zero & size,
      );
      final scale = frameRect.width / source.width;
      final safe = switch (c.border) {
        DancheongBorder.brocadeFlow => const Rect.fromLTRB(
          320,
          300,
          1060,
          1060,
        ),
        DancheongBorder.colorRibbon => const Rect.fromLTWH(244, 304, 632, 778),
        _ => const Rect.fromLTWH(232, 256, 655, 886),
      };
      work = Rect.fromLTWH(
        frameRect.left + safe.left * scale,
        frameRect.top + safe.top * scale,
        safe.width * scale,
        safe.height * scale,
      ).deflate(8);
    }
    final richFlow =
        frame != null &&
        c.border == DancheongBorder.brocadeFlow &&
        c.template == DancheongTemplate.flower &&
        c.koreanText.characters.length +
                c.translation.characters.length +
                c.signature.characters.length <=
            100 &&
        !c.koreanText.contains('\n') &&
        !c.translation.contains('\n') &&
        !c.signature.contains('\n');
    Rect? flowText;
    if (richFlow) {
      final scale = frameRect!.width / frame.width;
      Rect fromSource(Rect r) => Rect.fromLTWH(
        frameRect!.left + r.left * scale,
        frameRect.top + r.top * scale,
        r.width * scale,
        r.height * scale,
      );
      work = fromSource(const Rect.fromLTRB(285, 270, 1060, 1000));
      flowText = fromSource(const Rect.fromLTRB(570, 1000, 1040, 1210));
      final green = Path()
        ..moveTo(frameRect.left, frameRect.top)
        ..lineTo(frameRect.right, frameRect.top)
        ..lineTo(frameRect.right, frameRect.top + 930 * scale)
        ..cubicTo(
          frameRect.left + 650 * scale,
          frameRect.top + 960 * scale,
          frameRect.left + 300 * scale,
          frameRect.top + 800 * scale,
          frameRect.left,
          frameRect.top + 780 * scale,
        )
        ..close();
      canvas.drawPath(green, Paint()..color = const Color(0xFF125844));
    }
    final artBottom = hasText && !richFlow
        ? work.top + work.height * .58
        : work.bottom;
    final artCenter = Offset(work.center.dx, (work.top + artBottom) / 2);
    canvas.save();
    canvas.clipRect(Rect.fromLTRB(work.left, work.top, work.right, artBottom));
    switch (c.template) {
      case DancheongTemplate.flower:
        final ornament = flowerOrnament;
        if (ornament != null) {
          // This fixed ornament belongs to the frame, not the reward inventory.
          // Only the separate medallions use the learner's earned materials.
          final side = math.min(work.width, artBottom - work.top - 64);
          canvas.drawImageRect(
            ornament,
            Offset.zero &
                Size(ornament.width.toDouble(), ornament.height.toDouble()),
            Rect.fromCenter(
              center: artCenter - const Offset(0, 28),
              width: side,
              height: side,
            ),
            Paint()..filterQuality = FilterQuality.high,
          );
          for (var i = 0; i < images.length; i++) {
            _stamp(
              canvas,
              i,
              Offset(
                work.center.dx + (i - (images.length - 1) / 2) * 90,
                artBottom - 35,
              ),
              70,
            );
          }
          break;
        }
        final radius = math.min(work.width * .36, (artBottom - work.top) * .34);
        for (var i = 0; i < 8; i++) {
          final angle = i * math.pi / 4;
          _stamp(
            canvas,
            i + 1,
            artCenter +
                Offset(math.cos(angle) * radius, math.sin(angle) * radius),
            math.min(164, radius * .48),
          );
        }
        _stamp(canvas, 0, artCenter, math.min(540, radius * 1.7));
      case DancheongTemplate.brocade:
        var row = 0;
        final cell = math.min(270.0, work.width / 3);
        for (
          var y = work.top + cell * .5;
          y < artBottom - cell * .4;
          y += cell
        ) {
          for (var col = 0; col < 3; col++) {
            _stamp(
              canvas,
              row + col,
              Offset(
                work.left +
                    cell * (col + .5) +
                    (row.isOdd ? cell * .08 : -cell * .08),
                y,
              ),
              cell * .84,
            );
          }
          row++;
        }
      case DancheongTemplate.letter:
        _stamp(
          canvas,
          0,
          artCenter,
          math.min(work.width * .82, (artBottom - work.top) * .82),
        );
        for (var i = 0; i < 3; i++) {
          _stamp(
            canvas,
            i + 1,
            Offset(work.center.dx + (i - 1) * work.width * .18, artBottom - 25),
            44,
          );
        }
    }
    canvas.restore();
    if (hasText) {
      _text(
        canvas,
        flowText ??
            Rect.fromLTRB(
              work.left + 8,
              artBottom + 16,
              work.right - 8,
              work.bottom - 12,
            ),
      );
    }
    if (frame != null) {
      canvas.drawImageRect(
        frame,
        Offset.zero & Size(frame.width.toDouble(), frame.height.toDouble()),
        frameRect!,
        Paint()..filterQuality = FilterQuality.high,
      );
    }
  }

  void _text(Canvas canvas, Rect area) {
    TextPainter layout(double font) {
      return TextPainter(
        text: TextSpan(
          style: TextStyle(
            fontFamily: 'NotoSansKR',
            fontSize: font,
            height: 1.35,
            color: const Color(0xFF243B33),
          ),
          children: [
            if (c.koreanText.isNotEmpty)
              TextSpan(
                text: '${c.koreanText}\n',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            if (c.translation.isNotEmpty)
              TextSpan(
                text: '${c.translation}\n',
                style: TextStyle(fontSize: font * .72),
              ),
            if (c.signature.isNotEmpty)
              TextSpan(
                text: '\n${c.signature}',
                style: TextStyle(fontSize: font * .56),
              ),
          ],
        ),
        textAlign: TextAlign.center,
        textDirection: TextDirection.ltr,
      )..layout(maxWidth: area.width);
    }

    var font = 64.0;
    var painter = layout(font);
    while (painter.height > area.height && font > 24) {
      painter.dispose();
      font -= 2;
      painter = layout(font);
    }
    if (painter.height > area.height) {
      painter.dispose();
      throw const DancheongTextFitFailure();
    }
    painter.paint(
      canvas,
      Offset(area.left, area.top + (area.height - painter.height) / 2),
    );
    painter.dispose();
  }
}

class DancheongArtworkView extends StatefulWidget {
  const DancheongArtworkView({
    super.key,
    required this.composition,
    required this.ownedSlugs,
  });
  final DancheongComposition composition;
  final Set<String> ownedSlugs;
  @override
  State<DancheongArtworkView> createState() => _DancheongArtworkViewState();
}

class _DancheongArtworkViewState extends State<DancheongArtworkView> {
  Future<DancheongExportPackage>? _future;
  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant DancheongArtworkView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.composition != widget.composition ||
        !setEquals(oldWidget.ownedSlugs, widget.ownedSlugs)) {
      _load();
    }
  }

  void _load() {
    _future = widget.composition.motifSlugs.isEmpty
        ? null
        : DancheongRenderer().render(
            DancheongArtwork(
              id: '00000000-0000-4000-8000-000000000000',
              revision: 1,
              composition: widget.composition,
              completedAt: DateTime.utc(2026),
            ),
            ownedSlugs: widget.ownedSlugs,
          );
  }

  @override
  Widget build(BuildContext context) => AspectRatio(
    aspectRatio:
        1080 /
        (widget.composition.format == DancheongFormat.story ? 1920 : 1350),
    child: FutureBuilder<DancheongExportPackage>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.hasData &&
            snapshot.connectionState == ConnectionState.done) {
          return Image.memory(
            snapshot.data!.png,
            fit: BoxFit.contain,
            gaplessPlayback: false,
            semanticLabel: AppL10n.of(context).dancheongPreview,
          );
        }
        if (snapshot.hasError) {
          if (snapshot.error is DancheongTextFitFailure) {
            return Center(child: Text(AppL10n.of(context).dancheongTextFit));
          }
          return Center(
            child: TextButton(
              onPressed: () => setState(_load),
              child: Text(AppL10n.of(context).btnRetry),
            ),
          );
        }
        return Center(
          child: _future == null
              ? const Icon(Icons.palette_outlined, size: 48)
              : const CircularProgressIndicator(),
        );
      },
    ),
  );
}
