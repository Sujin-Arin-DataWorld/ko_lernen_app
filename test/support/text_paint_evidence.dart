import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

/// Keeps Flutter's guideline as the first check. Its modal color histogram can
/// select two shades of textured paper instead of the sparse foreground ink.
/// Every reported failure must then have independent paint proof at the same
/// WCAG threshold; unknown failures and unsupported paint remain failures.
class PaintedTextContrastGuideline extends AccessibilityGuideline {
  const PaintedTextContrastGuideline({
    this.framework = textContrastGuideline,
    this.evidenceName = 'contrast',
  });

  final AccessibilityGuideline framework;
  final String evidenceName;

  @override
  String get description => 'Painted text follows WCAG AA contrast guidelines';

  @override
  Future<Evaluation> evaluate(WidgetTester tester) async {
    final native = await framework.evaluate(tester);
    if (native.passed) {
      return native;
    }
    Evaluation fail(String reason) =>
        Evaluation.fail('${native.reason}\nPaint verification: $reason');
    final reason = native.reason ?? '';
    final matches = RegExp(
      r'SemanticsNode#(\d+)\(',
    ).allMatches(reason).toList();
    if (matches.isEmpty ||
        matches.length !=
            'Expected contrast ratio of at least'.allMatches(reason).length) {
      return fail('Unmapped framework failure; original failure retained.');
    }
    final reportedRequired = <int, double>{};
    for (var i = 0; i < matches.length; i++) {
      final block = reason.substring(
        matches[i].end,
        i + 1 < matches.length ? matches[i + 1].start : reason.length,
      );
      final thresholds = RegExp(
        r'Expected contrast ratio of at least\s+(\d+(?:\.\d+)?)(?=\s|$)',
      ).allMatches(block).toList();
      if (thresholds.length != 1) {
        return fail('Unmapped framework contrast threshold.');
      }
      final required = double.tryParse(thresholds.single.group(1)!);
      if (required == null || !required.isFinite || required <= 0) {
        return fail('Unsupported framework contrast threshold.');
      }
      final node = int.parse(matches[i].group(1)!);
      reportedRequired[node] = math.max(reportedRequired[node] ?? 0, required);
    }
    if (tester.binding.renderViews.length != 1) {
      return fail('Multiple render views are unsupported.');
    }
    final view = tester.binding.renderViews.single;
    final nodeIds = reportedRequired.keys.toSet();
    final nodes = <int, SemanticsNode>{};
    void visit(SemanticsNode node) {
      if (nodeIds.contains(node.id)) {
        nodes[node.id] = node;
      }
      node.visitChildren((child) {
        visit(child);
        return true;
      });
    }

    visit(view.owner!.semanticsOwner!.rootSemanticsNode!);
    if (nodes.length != nodeIds.length) {
      return fail('A reported semantics node is missing.');
    }
    final candidates = <_PaintCandidate>[];
    for (final node in nodes.values) {
      final data = node.getSemanticsData();
      final text = data.label.isEmpty ? data.value : data.label;
      var mapped = 0;
      var nodeBounds = node.rect;
      SemanticsNode? ancestor = node;
      while (ancestor != null) {
        if (ancestor.transform case final transform?) {
          nodeBounds = MatrixUtils.transformRect(transform, nodeBounds);
        }
        ancestor = ancestor.parent;
      }
      for (final element in find.text(text).hitTestable().evaluate()) {
        final paragraph = element.renderObject;
        if (paragraph is! RenderParagraph) {
          return fail('Unsupported render object for node ${node.id}.');
        }
        final transform = paragraph.getTransformTo(null);
        final bounds = MatrixUtils.transformRect(
          transform,
          paragraph.paintBounds,
        );
        if (nodeBounds.intersect(bounds).isEmpty) {
          continue;
        }
        final style = _homogeneousStyle(paragraph.text);
        final ink = style?.foreground?.color ?? style?.color;
        if (style == null ||
            ink == null ||
            ink.a != 1 ||
            style.fontSize == null ||
            style.foreground != null ||
            (style.shadows?.isNotEmpty ?? false)) {
          return fail(
            'Unsupported, mixed or translucent text for node ${node.id}.',
          );
        }
        final boxes = paragraph.getBoxesForSelection(
          TextSelection(
            baseOffset: 0,
            extentOffset: paragraph.text.toPlainText().length,
          ),
        );
        if (boxes.isEmpty) {
          return fail('No glyph boxes for node ${node.id}.');
        }
        candidates.add(
          _PaintCandidate(
            paragraph,
            node.id,
            text,
            ink,
            reportedRequired[node.id]!,
            const MinimumTextContrastGuideline().targetContrastRatio(
              style.fontSize,
              bold: style.fontWeight == FontWeight.bold,
            ),
            boxes
                .map(
                  (box) => MatrixUtils.transformRect(transform, box.toRect()),
                )
                .toList(),
          ),
        );
        mapped++;
      }
      if (mapped == 0) {
        return fail('No painted paragraph mapped to node ${node.id}.');
      }
    }

    final originals = {
      for (final candidate in candidates)
        candidate.paragraph: candidate.paragraph.text,
    };
    final erased = {
      for (final entry in originals.entries)
        entry.key: _withoutInk(entry.value),
    };
    for (final entry in originals.entries) {
      if (entry.value.compareTo(erased[entry.key]!).index >
          RenderComparison.paint.index) {
        return fail('Erasing this text would require layout.');
      }
    }
    final foreground = await _captureFrame(tester);
    final owners = originals.keys.map((paragraph) => paragraph.owner!).toSet();
    late _PaintFrame background;
    try {
      for (final entry in erased.entries) {
        entry.key.text = entry.value;
        entry.key.markNeedsPaint();
      }
      // Text paint changes do not change glyph metrics or advance the clock.
      for (final owner in owners) {
        owner.flushPaint();
      }
      background = await _captureFrame(tester);
    } finally {
      for (final entry in originals.entries) {
        entry.key.text = entry.value;
        entry.key.markNeedsPaint();
      }
      for (final owner in owners) {
        owner.flushPaint();
      }
    }
    final restored = await _captureFrame(tester);
    if (!listEquals(foreground.rgba, restored.rgba)) {
      const output = String.fromEnvironment('TEXT_PAINT_EVIDENCE_DIR');
      if (output.isNotEmpty) {
        await tester.runAsync(() async {
          final name = evidenceName.replaceAll(' ', '-');
          await Directory(output).create(recursive: true);
          await File('$output/$name-original.png').writeAsBytes(foreground.png);
          await File(
            '$output/$name-background.png',
          ).writeAsBytes(background.png);
          await File('$output/$name-restored.png').writeAsBytes(restored.png);
        });
      }
      return fail('Restored frame differs from the original admitted frame.');
    }
    final reports = <Map<String, Object>>[];
    for (final candidate in candidates) {
      var core = 0;
      var glyphPixels = 0;
      var minimum = double.infinity;
      final pixels = <int>{};
      for (final box in candidate.boxes) {
        for (
          var y = math.max(0, box.top.floor());
          y < math.min(foreground.height, box.bottom.ceil());
          y++
        ) {
          for (
            var x = math.max(0, box.left.floor());
            x < math.min(foreground.width, box.right.ceil());
            x++
          ) {
            pixels.add(y * foreground.width + x);
          }
        }
      }
      for (final pixel in pixels) {
        final actual = foreground.color(pixel);
        final underneath = background.color(pixel);
        if (actual == underneath) {
          continue;
        }
        glyphPixels++;
        if (actual == candidate.ink) {
          core++;
        }
        final a = candidate.ink.computeLuminance();
        final b = underneath.computeLuminance();
        final ratio = (math.max(a, b) + .05) / (math.min(a, b) + .05);
        minimum = math.min(minimum, ratio);
      }
      reports.add({
        'node': candidate.node,
        'text': candidate.text,
        'ink': candidate.ink.toARGB32().toRadixString(16),
        'corePixels': core,
        'glyphPixels': glyphPixels,
        'minimumContrast': minimum.isFinite ? minimum : 0,
        'nativeRequiredContrast': candidate.reportedRequired,
        'styleRequiredContrast': candidate.styleRequired,
        'requiredContrast': candidate.required,
      });
    }
    const output = String.fromEnvironment('TEXT_PAINT_EVIDENCE_DIR');
    if (output.isNotEmpty) {
      final name = evidenceName.replaceAll(' ', '-');
      await tester.runAsync(() async {
        final file = File('$output/$name-background.png');
        await file.parent.create(recursive: true);
        await file.writeAsBytes(background.png);
        await File('$output/$name-paint-proof.json').writeAsString(
          const JsonEncoder.withIndent('  ').convert({
            'nativeFailure': reason,
            'restoredRgbaIdentical': true,
            'paragraphs': reports,
          }),
        );
      });
    }
    for (final report in reports) {
      if ((report['corePixels']! as int) == 0) {
        return fail('No actual opaque ink core pixels: ${report['text']}');
      }
      if ((report['minimumContrast']! as double) <
          (report['requiredContrast']! as double)) {
        return fail('Insufficient actual glyph/background contrast: $report');
      }
    }
    return const Evaluation.pass();
  }
}

TextStyle? _homogeneousStyle(InlineSpan span) {
  TextStyle? result;
  var supported = true;
  void visit(InlineSpan span, TextStyle inherited) {
    if (span is! TextSpan) {
      supported = false;
      return;
    }
    final effective = inherited.merge(span.style);
    if (span.text?.trim().isNotEmpty ?? false) {
      if (result != null && result != effective) {
        supported = false;
      }
      result = effective;
    }
    for (final child in span.children ?? const <InlineSpan>[]) {
      visit(child, effective);
    }
  }

  visit(span, const TextStyle());
  return supported ? result : null;
}

InlineSpan _withoutInk(InlineSpan span) {
  if (span is! TextSpan) {
    return span;
  }
  return TextSpan(
    text: span.text,
    style: (span.style ?? const TextStyle()).copyWith(
      color: Colors.transparent,
      decoration: TextDecoration.none,
    ),
    locale: span.locale,
    children: span.children?.map(_withoutInk).toList(),
  );
}

class _PaintCandidate {
  const _PaintCandidate(
    this.paragraph,
    this.node,
    this.text,
    this.ink,
    this.reportedRequired,
    this.styleRequired,
    this.boxes,
  );
  final RenderParagraph paragraph;
  final int node;
  final String text;
  final Color ink;
  final double reportedRequired, styleRequired;
  double get required => math.max(reportedRequired, styleRequired);
  final List<Rect> boxes;
}

class _PaintFrame {
  const _PaintFrame(this.width, this.height, this.rgba, this.png);
  final int width, height;
  final Uint8List rgba, png;

  Color color(int pixel) {
    final offset = pixel * 4;
    return Color.fromARGB(
      rgba[offset + 3],
      rgba[offset],
      rgba[offset + 1],
      rgba[offset + 2],
    );
  }
}

Future<_PaintFrame> _captureFrame(WidgetTester tester) async {
  final view = tester.binding.renderViews.single;
  final layer = view.debugLayer! as OffsetLayer;
  return (await tester.runAsync(() async {
    final image = await layer.toImage(
      view.paintBounds,
      pixelRatio: 1 / view.flutterView.devicePixelRatio,
    );
    final rgba = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
    final png = await image.toByteData(format: ui.ImageByteFormat.png);
    final result = _PaintFrame(
      image.width,
      image.height,
      Uint8List.fromList(rgba!.buffer.asUint8List()),
      Uint8List.fromList(png!.buffer.asUint8List()),
    );
    image.dispose();
    return result;
  }))!;
}

/// Captures the same admitted frame used by Flutter's contrast guideline.
/// It neither pumps another frame nor changes any widget or text style.
Future<void> captureTextPaintEvidence(WidgetTester tester, String name) async {
  const output = String.fromEnvironment('TEXT_PAINT_EVIDENCE_DIR');
  if (output.isEmpty) {
    return;
  }
  final paragraphs = <Map<String, Object?>>[];
  for (final element in find.byType(RichText).evaluate()) {
    final paragraph = element.renderObject;
    if (paragraph is! RenderParagraph || !paragraph.hasSize) {
      continue;
    }
    final bounds = MatrixUtils.transformRect(
      paragraph.getTransformTo(null),
      paragraph.paintBounds,
    );
    final spans = <Map<String, Object?>>[];
    void record(InlineSpan span, TextStyle inherited) {
      if (span is! TextSpan) {
        return;
      }
      final style = inherited.merge(span.style);
      if (span.text case final text? when text.isNotEmpty) {
        final color = style.foreground?.color ?? style.color;
        spans.add({
          'text': text,
          'ink': color?.toARGB32().toRadixString(16).padLeft(8, '0'),
          'fontFamily': style.fontFamily,
          'fontFamilyFallback': style.fontFamilyFallback,
          'fontSize': style.fontSize,
          'fontWeight': style.fontWeight?.value,
          'height': style.height,
        });
      }
      for (final child in span.children ?? const <InlineSpan>[]) {
        record(child, style);
      }
    }

    record(paragraph.text, const TextStyle());
    paragraphs.add({
      'text': paragraph.text.toPlainText(),
      'bounds': [bounds.left, bounds.top, bounds.right, bounds.bottom],
      'textScale16': paragraph.textScaler.scale(16),
      'spans': spans,
    });
  }
  final safeName = name.replaceAll(' ', '-');
  final view = tester.binding.renderViews.single;
  final layer = view.debugLayer! as OffsetLayer;
  await tester.runAsync(() async {
    final image = await layer.toImage(
      view.paintBounds,
      pixelRatio: 1 / view.flutterView.devicePixelRatio,
    );
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    final file = File('$output/$safeName.png');
    await file.parent.create(recursive: true);
    await file.writeAsBytes(bytes!.buffer.asUint8List());
    await File('$output/$safeName.json').writeAsString(
      const JsonEncoder.withIndent('  ').convert({
        'width': image.width,
        'height': image.height,
        'paragraphs': paragraphs,
      }),
    );
    image.dispose();
  });
}
