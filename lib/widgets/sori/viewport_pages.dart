import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

/// Splits full-size text at word boundaries, with a grapheme boundary for a
/// word that takes more than a page by itself. Width and height are the space
/// available to the text itself after padding and page controls.
List<String> soriViewportTextPages(
  BuildContext context,
  String text, {
  required TextStyle style,
  required double width,
  required double height,
}) {
  final effectiveStyle = DefaultTextStyle.of(context).style.merge(style);
  final painter = TextPainter(
    locale: Localizations.maybeLocaleOf(context),
    textDirection: Directionality.of(context),
    textScaler: MediaQuery.textScalerOf(context),
  );
  painter.text = TextSpan(text: '한', style: effectiveStyle);
  painter.layout();
  final availableHeight = math.max(height, painter.height);
  bool fits(String value) {
    painter.text = TextSpan(text: value, style: effectiveStyle);
    painter.layout(maxWidth: math.max(1, width));
    return painter.height <= availableHeight;
  }

  try {
    var remaining = text.trim();
    final pages = <String>[];
    while (remaining.isNotEmpty) {
      if (fits(remaining)) {
        pages.add(remaining);
        break;
      }
      final graphemes = remaining.characters.toList();
      var start = 1;
      var end = graphemes.length;
      while (start < end) {
        final middle = (start + end + 1) ~/ 2;
        if (fits(graphemes.take(middle).join().trimRight())) {
          start = middle;
        } else {
          end = middle - 1;
        }
      }
      final wordBoundary = graphemes.lastIndexWhere(
        (grapheme) => grapheme.trim().isEmpty,
        start < graphemes.length ? start : start - 1,
      );
      final split = wordBoundary > 0 ? wordBoundary : start;
      pages.add(graphemes.take(split).join().trimRight());
      remaining = graphemes.skip(split).join().trimLeft();
    }
    return pages;
  } finally {
    painter.dispose();
  }
}

/// Fits consecutive content sections into the measured body. Callers give
/// separate sections at meaningful reading or action boundaries. At unusually
/// large text sizes a single section can span multiple explicit pages.
class SoriViewportPages extends StatefulWidget {
  const SoriViewportPages({
    super.key,
    required this.sections,
    this.targetSectionKey,
    this.targetRevision = 0,
    this.centerContent = false,
  });

  static const controlsHeight = 48.0;

  final List<Widget> sections;
  final Key? targetSectionKey;
  final int targetRevision;
  final bool centerContent;

  @override
  State<SoriViewportPages> createState() => _SoriViewportPagesState();
}

class _SoriViewportPagesState extends State<SoriViewportPages> {
  int _page = 0;
  int _count = 1;
  int _firstSection = 0;
  int _endSection = 0;
  (int, int, int, int)? _pendingLayout;

  void _updateLayout(int page, int count, int first, int end) {
    final pending = _pendingLayout;
    _pendingLayout = (page, count, first, end);
    if (pending != null) {
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final layout = _pendingLayout!;
      _pendingLayout = null;
      if (mounted && layout != (_page, _count, _firstSection, _endSection)) {
        setState(() {
          _page = layout.$1;
          _count = layout.$2;
          _firstSection = layout.$3;
          _endSection = layout.$4;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final labels = MaterialLocalizations.of(context);
    final target = widget.targetSectionKey;
    final targetIndex = target == null
        ? -1
        : widget.sections.indexWhere((section) => section.key == target);
    return Stack(
      fit: StackFit.expand,
      children: [
        _PageContent(
          page: _page,
          anchor: (target, widget.targetRevision, targetIndex),
          onLayout: _updateLayout,
          centerContent: widget.centerContent,
          children: [
            for (final (index, section) in widget.sections.indexed)
              ExcludeFocus(
                key: section.key == null ? null : ValueKey<Key>(section.key!),
                excluding: index < _firstSection || index >= _endSection,
                child: TickerMode(
                  enabled: index >= _firstSection && index < _endSection,
                  child: section,
                ),
              ),
          ],
        ),
        if (_count > 1)
          Align(
            alignment: Alignment.bottomCenter,
            child: SizedBox(
              height: SoriViewportPages.controlsHeight,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    key: const ValueKey('sori-viewport-previous'),
                    tooltip: labels.previousPageTooltip,
                    constraints: const BoxConstraints.tightFor(
                      width: 48,
                      height: 48,
                    ),
                    onPressed: _page == 0
                        ? null
                        : () => setState(() => _page--),
                    icon: const BackButtonIcon(),
                  ),
                  Flexible(
                    child: Semantics(
                      liveRegion: true,
                      child: Text(
                        '${labels.formatDecimal(_page + 1)} / ${labels.formatDecimal(_count)}',
                        key: const ValueKey('sori-viewport-page'),
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 14, height: 1.1),
                      ),
                    ),
                  ),
                  IconButton(
                    key: const ValueKey('sori-viewport-next'),
                    tooltip: labels.nextPageTooltip,
                    constraints: const BoxConstraints.tightFor(
                      width: 48,
                      height: 48,
                    ),
                    onPressed: _page + 1 >= _count
                        ? null
                        : () => setState(() => _page++),
                    icon: const Icon(Icons.navigate_next_rounded),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _PageContent extends MultiChildRenderObjectWidget {
  const _PageContent({
    required this.page,
    required this.anchor,
    required this.onLayout,
    required this.centerContent,
    required super.children,
  });

  final int page;
  final (Key?, int, int) anchor;
  final void Function(int page, int count, int first, int end) onLayout;
  final bool centerContent;

  @override
  _RenderPageContent createRenderObject(BuildContext context) =>
      _RenderPageContent(page, anchor, onLayout, centerContent);

  @override
  void updateRenderObject(
    BuildContext context,
    _RenderPageContent renderObject,
  ) {
    renderObject
      ..onLayout = onLayout
      ..centerContent = centerContent
      ..anchor = anchor
      ..page = page;
  }
}

class _SectionData extends ContainerBoxParentData<RenderBox> {
  int firstPage = 0;
  int lastPage = 0;
  double top = 0;
}

class _RenderPageContent extends RenderBox
    with
        ContainerRenderObjectMixin<RenderBox, _SectionData>,
        RenderBoxContainerDefaultsMixin<RenderBox, _SectionData> {
  _RenderPageContent(
    this._page,
    this._anchor,
    this.onLayout,
    this._centerContent,
  );

  void Function(int page, int count, int first, int end) onLayout;
  int _page;
  (Key?, int, int) _anchor;
  bool _anchorPending = true;
  int _visiblePage = 0;
  double _bodyHeight = 0;
  bool _centerContent;

  set centerContent(bool value) {
    if (value != _centerContent) {
      _centerContent = value;
      markNeedsLayout();
    }
  }

  set anchor((Key?, int, int) value) {
    if (value != _anchor) {
      _anchor = value;
      _anchorPending = true;
      markNeedsLayout();
    }
  }

  set page(int value) {
    if (value != _page) {
      _page = value;
      markNeedsLayout();
      markNeedsSemanticsUpdate();
    }
  }

  @override
  void setupParentData(RenderBox child) {
    if (child.parentData is! _SectionData) {
      child.parentData = _SectionData();
    }
  }

  @override
  void performLayout() {
    size = constraints.biggest;
    final children = getChildrenAsList();
    final sectionConstraints = BoxConstraints.tightFor(width: size.width);
    var total = 0.0;
    for (final child in children) {
      child.layout(sectionConstraints, parentUsesSize: true);
      total += child.size.height;
    }

    _bodyHeight = total <= size.height
        ? size.height
        : math.max(0, size.height - SoriViewportPages.controlsHeight);
    var pageIndex = 0;
    var top = 0.0;
    // A little overlap keeps the last text line available on both pages.
    final stride = math.max(1.0, _bodyHeight - 24);
    for (final child in children) {
      if (top > 0 && top + child.size.height > _bodyHeight) {
        pageIndex++;
        top = 0;
      }
      final data = child.parentData! as _SectionData;
      data
        ..firstPage = pageIndex
        ..top = top;
      if (_bodyHeight > 0 && child.size.height > _bodyHeight) {
        pageIndex += ((child.size.height - _bodyHeight) / stride).ceil();
        top = _bodyHeight;
      } else {
        top += child.size.height;
      }
      data.lastPage = pageIndex;
    }
    _visiblePage = math.min(_page, pageIndex);
    final targetIndex = _anchor.$3;
    if (_anchorPending && targetIndex >= 0 && targetIndex < children.length) {
      _visiblePage =
          (children[targetIndex].parentData! as _SectionData).firstPage;
    }
    for (final child in children) {
      final data = child.parentData! as _SectionData;
      final distance = math.max(0, _visiblePage - data.firstPage) * stride;
      final maxDistance = math.max(0.0, child.size.height - _bodyHeight);
      data.offset = Offset(0, data.top - math.min(distance, maxDistance));
    }
    _anchorPending = false;
    final first = children.indexWhere(_isVisible);
    final end = children.lastIndexWhere(_isVisible) + 1;
    // Centring applies only to a page whose sections all fit; a section that
    // spans pages at large text sizes keeps its scrolled offset.
    if (_centerContent && end > 0 && first >= 0) {
      final last = children[end - 1];
      final lastData = last.parentData! as _SectionData;
      if (lastData.firstPage == lastData.lastPage) {
        final space = math.max(
          0.0,
          _bodyHeight - lastData.offset.dy - last.size.height,
        );
        for (var index = first; index < end; index++) {
          final data = children[index].parentData! as _SectionData;
          data.offset += Offset(0, space / 2);
        }
      }
    }
    onLayout(_visiblePage, pageIndex + 1, math.max(first, 0), end);
    markNeedsSemanticsUpdate();
  }

  bool _isVisible(RenderBox child) {
    final data = child.parentData! as _SectionData;
    return data.firstPage <= _visiblePage && _visiblePage <= data.lastPage;
  }

  @override
  Rect describeApproximatePaintClip(RenderObject child) =>
      Rect.fromLTWH(0, 0, size.width, _bodyHeight);

  Iterable<RenderBox> get _visibleChildren =>
      getChildrenAsList().where(_isVisible);

  @override
  void paint(PaintingContext context, Offset offset) {
    context.pushClipRect(
      needsCompositing,
      offset,
      Rect.fromLTWH(0, 0, size.width, _bodyHeight),
      (context, offset) {
        for (final child in _visibleChildren) {
          final data = child.parentData! as _SectionData;
          context.paintChild(child, offset + data.offset);
        }
      },
    );
  }

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) {
    if (position.dy >= _bodyHeight) {
      return false;
    }
    for (final child in _visibleChildren.toList().reversed) {
      final data = child.parentData! as _SectionData;
      if (result.addWithPaintOffset(
        offset: data.offset,
        position: position,
        hitTest: (result, position) =>
            child.hitTest(result, position: position),
      )) {
        return true;
      }
    }
    return false;
  }

  @override
  void visitChildrenForSemantics(RenderObjectVisitor visitor) {
    for (final child in _visibleChildren) {
      visitor(child);
    }
  }
}
