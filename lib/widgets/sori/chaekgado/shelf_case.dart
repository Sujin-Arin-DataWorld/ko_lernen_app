import 'package:flutter/material.dart';

import '../tokens.dart';
import 'chaekgado_assets.dart';

@immutable
class ChaekgadoCompartment {
  const ChaekgadoCompartment({
    required this.slug,
    required this.label,
    this.count = 0,
    this.progress = 0,
  });

  final String slug;
  final String label;
  final int count;
  final double progress;

  bool get isStocked => count > 0;
}

/// A two-column, variable-height Chaekgado shelf.
///
/// The approved art pack supplies a fixed top and bottom plus a repeatable
/// middle row. This preserves the frame proportions for every learner level
/// instead of stretching the complete bookcase PNG when it has more than ten
/// categories.
class ChaekgadoShelfCase extends StatelessWidget {
  const ChaekgadoShelfCase({
    super.key,
    required this.compartments,
    required this.onOpen,
    this.emptyLabel,
    this.columns = 2,
    this.cellHeight = 132,
    this.padding = const EdgeInsets.symmetric(horizontal: Spacing.xs + 1),
  }) : assert(columns == 2, 'The Chaekgado asset has two columns.');

  final List<ChaekgadoCompartment> compartments;
  final ValueChanged<ChaekgadoCompartment> onOpen;
  final String? emptyLabel;

  /// Kept for source compatibility. The artwork, rather than an arbitrary
  /// dp value, determines the compartment height.
  final double cellHeight;

  /// Kept for source compatibility. The supplied foreground frame owns the
  /// shelf padding, so no extra inset is applied.
  final EdgeInsets padding;

  final int columns;

  static const double _canvasWidth = 1254;
  static const double _topHeight = 341;
  static const double _middleHeight = 199;
  static const double _bottomHeight = 266;

  @override
  Widget build(BuildContext context) {
    final rows = <List<ChaekgadoCompartment>>[];
    for (var i = 0; i < compartments.length; i += columns) {
      rows.add(
        compartments.sublist(i, (i + columns).clamp(0, compartments.length)),
      );
    }

    if (rows.isEmpty) {
      return const SizedBox.shrink();
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        if (!width.isFinite || width <= 0) {
          return const SizedBox.shrink();
        }
        final sourceHeight = _sourceHeightForRows(rows.length);
        final scale = width / _canvasWidth;

        return SizedBox(
          width: width,
          height: sourceHeight * scale,
          child: Stack(
            children: [
              Positioned.fill(
                child: _BookcaseLayer(
                  top: kChaekgadoBackplateTop,
                  middle: kChaekgadoBackplateMiddle,
                  bottom: kChaekgadoBackplateBottom,
                  rows: rows.length,
                ),
              ),
              for (var row = 0; row < rows.length; row++)
                for (var column = 0; column < rows[row].length; column++)
                  _positionedCompartment(
                    rows[row][column],
                    row: row,
                    column: column,
                    rowCount: rows.length,
                    index: row * columns + column,
                    scale: scale,
                  ),
              Positioned.fill(
                child: IgnorePointer(
                  child: _BookcaseLayer(
                    top: kChaekgadoFrameTop,
                    middle: kChaekgadoFrameMiddle,
                    bottom: kChaekgadoFrameBottom,
                    rows: rows.length,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  double _sourceHeightForRows(int rows) =>
      _topHeight +
      (rows - 2).clamp(0, 99).toDouble() * _middleHeight +
      _bottomHeight;

  Widget _positionedCompartment(
    ChaekgadoCompartment compartment, {
    required int row,
    required int column,
    required int rowCount,
    required int index,
    required double scale,
  }) {
    final bounds = _slotBounds(row, column, rowCount);
    return Positioned(
      left: bounds.left * scale,
      top: bounds.top * scale,
      width: bounds.width * scale,
      height: bounds.height * scale,
      child: _Compartment(
        data: compartment,
        emptyLabel: emptyLabel,
        assetIndex: index,
        onTap: () => onOpen(compartment),
      ),
    );
  }

  _SlotBounds _slotBounds(int row, int column, int rowCount) {
    final left = column == 0 ? 234.0 : 650.0;
    final width = column == 0 ? 360.0 : 355.0;
    if (row == 0) {
      return _SlotBounds(left: left, top: 144, width: width, height: 156);
    }
    if (row == rowCount - 1) {
      return _SlotBounds(
        left: left,
        top: _topHeight + (rowCount - 2) * _middleHeight + 13,
        width: width,
        height: 127,
      );
    }
    return _SlotBounds(
      left: left,
      top: _topHeight + (row - 1) * _middleHeight + 11,
      width: width,
      height: 150,
    );
  }
}

class _BookcaseLayer extends StatelessWidget {
  const _BookcaseLayer({
    required this.top,
    required this.middle,
    required this.bottom,
    required this.rows,
  });

  final String top;
  final String middle;
  final String bottom;
  final int rows;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(flex: 341, child: _slice(top)),
        for (var i = 0; i < (rows - 2).clamp(0, 99); i++)
          Expanded(flex: 199, child: _slice(middle)),
        Expanded(flex: 266, child: _slice(bottom)),
      ],
    );
  }

  Widget _slice(String asset) => Image.asset(asset, fit: BoxFit.fill);
}

class _SlotBounds {
  const _SlotBounds({
    required this.left,
    required this.top,
    required this.width,
    required this.height,
  });

  final double left;
  final double top;
  final double width;
  final double height;
}

class _Compartment extends StatelessWidget {
  const _Compartment({
    required this.data,
    required this.emptyLabel,
    required this.assetIndex,
    required this.onTap,
  });

  final ChaekgadoCompartment data;
  final String? emptyLabel;
  final int assetIndex;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final stocked = data.isStocked;
    return Semantics(
      button: true,
      label: stocked ? '${data.label}, ${data.count}' : data.label,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(5, 4, 5, 3),
          child: Opacity(
            opacity: stocked ? 1 : 0.62,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  data.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 7,
                    height: 1.1,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF312116),
                  ),
                ),
                if (stocked) ...[
                  const SizedBox(height: 2),
                  ClipRRect(
                    borderRadius: const BorderRadius.all(Radius.circular(2)),
                    child: SizedBox(
                      height: 2,
                      child: LinearProgressIndicator(
                        value: data.progress.clamp(0, 1),
                        backgroundColor: const Color(0x55FFF3D0),
                        valueColor: const AlwaysStoppedAnimation(
                          SoriColors.primary,
                        ),
                      ),
                    ),
                  ),
                ],
                Expanded(
                  child: _CellInterior(
                    slug: data.slug,
                    assetIndex: assetIndex,
                    locked: !stocked,
                  ),
                ),
                if (!stocked && emptyLabel != null)
                  Text(
                    emptyLabel!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 6,
                      color: Color(0xFF624A35),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CellInterior extends StatelessWidget {
  const _CellInterior({
    required this.slug,
    required this.assetIndex,
    required this.locked,
  });

  final String slug;
  final int assetIndex;
  final bool locked;

  @override
  Widget build(BuildContext context) {
    final vignette = chaekgadoCategoryVignetteAsset(slug);
    return LayoutBuilder(
      builder: (context, constraints) {
        return Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned(
              left: 0,
              bottom: -2,
              width: constraints.maxWidth * 0.56,
              height: constraints.maxHeight * 0.9,
              child: Image.asset(
                chaekgadoBookClusterAsset(assetIndex),
                fit: BoxFit.contain,
                alignment: Alignment.bottomLeft,
              ),
            ),
            if (vignette != null)
              Positioned(
                right: -2,
                bottom: -1,
                width: constraints.maxWidth * 0.5,
                height: constraints.maxHeight * 0.82,
                child: Image.asset(
                  vignette,
                  fit: BoxFit.contain,
                  alignment: Alignment.bottomRight,
                ),
              ),
            if (locked)
              const Align(
                alignment: Alignment.center,
                child: Icon(Icons.lock_outline_rounded, size: 14),
              ),
          ],
        );
      },
    );
  }
}
