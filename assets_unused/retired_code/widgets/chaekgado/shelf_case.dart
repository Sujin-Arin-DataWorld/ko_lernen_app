import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../data/chaekgado_shelf.dart' show ChaekgadoCompartment;
import '../dancheong_stamp.dart';
import '../tokens.dart';
import 'chaekgado_assets.dart';
import 'scroll_palette.dart';

/// The grid keeps readable targets while original artwork supplies the wood.
abstract final class _Grid {
  static const double sidePillar = 12;
  static const double centerPillar = 10;
  static const double plank = 20;
  static const double crown = 38;
  static const double base = 44;
  static const double cellAspect = 0.75;
  static const double minCellHeight = 144;
  static const double maxCellHeight = 196;
}

/// 붓선(진행)과 완료 도장을 테스트가 집을 수 있게 하는 공개 키.
/// 칸마다 하나씩이라 같은 키가 여러 번 나오지만 형제가 아니므로 위젯 트리
/// 규칙상 충돌하지 않는다.
const Key kChaekgadoBrushStrokeKey = ValueKey('chaekgado_brush_stroke');

/// 완료 도장을 집는 공개 키.
const Key kChaekgadoStampKey = ValueKey('chaekgado_stamp');

/// 칸 하나의 좌표·크기를 재려는 테스트용 키.
Key chaekgadoCompartmentKey(String slug) => ValueKey('chaekgado_cell_$slug');

/// The supplied faceted Chaekgado bookcase, assembled around responsive cells.
/// Original wood is cropped at runtime, so transparent source margins do not
/// shrink targets and category count does not stretch the whole cabinet.
class ChaekgadoShelfCase extends StatelessWidget {
  const ChaekgadoShelfCase({
    super.key,
    required this.compartments,
    required this.onOpen,
    this.emptyLabel,
  });

  final List<ChaekgadoCompartment> compartments;
  final ValueChanged<ChaekgadoCompartment> onOpen;

  /// 재고 0 칸에 붙는 꼬리표.
  final String? emptyLabel;

  /// 첫 칸 전폭 + 이후 2열. 마지막에 혼자 남는 칸도 전폭이라 빈 칸 위젯이
  /// 하나도 생기지 않는다.
  List<List<ChaekgadoCompartment>> _rows() {
    final rows = <List<ChaekgadoCompartment>>[];
    if (compartments.isEmpty) {
      return rows;
    }
    rows.add([compartments.first]);
    for (var i = 1; i < compartments.length; i += 2) {
      rows.add(compartments.sublist(i, math.min(i + 2, compartments.length)));
    }
    return rows;
  }

  @override
  Widget build(BuildContext context) {
    final rows = _rows();
    if (rows.isEmpty) {
      return const SizedBox.shrink();
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        if (!width.isFinite || width <= 0) {
          return const SizedBox.shrink();
        }
        final cellWidth = math.max(
          1.0,
          (width - _Grid.sidePillar * 2 - _Grid.centerPillar) / 2,
        );
        final cellHeight = (cellWidth * _Grid.cellAspect + 36).clamp(
          _Grid.minCellHeight,
          _Grid.maxCellHeight,
        );

        var index = 0;
        final band = <Widget>[];
        for (var row = 0; row < rows.length; row++) {
          band.add(
            SizedBox(
              height: cellHeight,
              child: _ShelfRow(
                cells: rows[row],
                firstIndex: index,
                emptyLabel: emptyLabel,
                onOpen: onOpen,
              ),
            ),
          );
          index += rows[row].length;
          band.add(
            _Plank(
              height: row == rows.length - 1 ? _Grid.base : _Grid.plank,
              rowIndex: row + 1,
            ),
          );
        }

        return Stack(
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const _Plank(height: _Grid.crown, rowIndex: 0),
                ...band,
              ],
            ),
          ],
        );
      },
    );
  }
}

class _ShelfRow extends StatelessWidget {
  const _ShelfRow({
    required this.cells,
    required this.firstIndex,
    required this.emptyLabel,
    required this.onOpen,
  });

  final List<ChaekgadoCompartment> cells;
  final int firstIndex;
  final String? emptyLabel;
  final ValueChanged<ChaekgadoCompartment> onOpen;

  @override
  Widget build(BuildContext context) {
    final children = <Widget>[
      const _Pillar(
        width: _Grid.sidePillar,
        source: Rect.fromLTRB(163, 352, 233, 502),
      ),
    ];
    for (var i = 0; i < cells.length; i++) {
      if (i > 0) {
        children.add(
          const _Pillar(
            width: _Grid.centerPillar,
            source: Rect.fromLTRB(594, 352, 650, 502),
          ),
        );
      }
      children.add(
        Expanded(
          child: _Compartment(
            key: chaekgadoCompartmentKey(cells[i].slug),
            data: cells[i],
            emptyLabel: emptyLabel,
            assetIndex: firstIndex + i,
            onTap: () => onOpen(cells[i]),
          ),
        ),
      );
    }
    children.add(
      const _Pillar(
        width: _Grid.sidePillar,
        source: Rect.fromLTRB(1007, 352, 1078, 502),
      ),
    );
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: children,
    );
  }
}

/// Source rectangles follow bookcase/layout.json; no image bytes are changed.
class _BookcaseCrop extends StatelessWidget {
  const _BookcaseCrop({
    this.asset = kChaekgadoBookcaseFrame,
    required this.source,
  });

  final String asset;
  final Rect source;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final scaleX = constraints.maxWidth / source.width;
      final scaleY = constraints.maxHeight / source.height;
      return ClipRect(
        child: Stack(
          fit: StackFit.expand,
          children: [
            Positioned(
              left: -source.left * scaleX,
              top: -source.top * scaleY,
              width: 1254 * scaleX,
              height: 1254 * scaleY,
              child: Image.asset(
                asset,
                fit: BoxFit.fill,
                excludeFromSemantics: true,
                filterQuality: FilterQuality.medium,
              ),
            ),
          ],
        ),
      );
    },
  );
}

class _Plank extends StatelessWidget {
  const _Plank({required this.height, required this.rowIndex});

  final double height;
  final int rowIndex;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: height,
    child: _BookcaseCrop(
      source: rowIndex == 0
          ? const Rect.fromLTRB(151, 47, 1091, 144)
          : height == _Grid.base
          ? const Rect.fromLTRB(151, 1081, 1091, 1205)
          : const Rect.fromLTRB(163, 300, 1078, 352),
    ),
  );
}

class _Pillar extends StatelessWidget {
  const _Pillar({required this.width, required this.source});

  final double width;
  final Rect source;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: width,
    child: _BookcaseCrop(source: source),
  );
}

/// 칸 하나 = 정물 한 점.
class _Compartment extends StatelessWidget {
  const _Compartment({
    super.key,
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
    final progress = data.progress.clamp(0.0, 1.0);
    final done = stocked && progress >= 1;

    return Semantics(
      button: true,
      // 짧은 이름은 눈, 스크린리더는 긴 이름 + 재고.
      label: stocked ? '${data.label}, ${data.count}' : data.label,
      excludeSemantics: true,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        // 칸 높이는 그리드가 정하므로 글자가 무한정 자랄 수 없다. 전체
        // 문자열은 위 Semantics 가 전달하고, 눈에 보이는 꼬리표만
        // stats_top_bar 와 같은 1.4 배 상한을 둔다(200% 대응).
        child: MediaQuery.withClampedTextScaling(
          maxScaleFactor: 1.4,
          child: Stack(
            fit: StackFit.expand,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: _CellGround(
                      slug: data.slug,
                      imageKey: data.imageKey,
                      assetIndex: assetIndex,
                    ),
                  ),
                  _CellTag(
                    data: data,
                    emptyLabel: emptyLabel,
                    progress: progress,
                    stamped: done,
                  ),
                ],
              ),
              if (done)
                Positioned(
                  left: 4,
                  bottom: 4,
                  child: _CompletionStamp(slug: data.slug),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 칸 바닥 — 듣기 카드 아트 한 장. 없으면 비네트, 그것도 없으면 책더미.
class _CellGround extends StatelessWidget {
  const _CellGround({
    required this.slug,
    required this.imageKey,
    required this.assetIndex,
  });

  final String slug;
  final String? imageKey;
  final int assetIndex;

  @override
  Widget build(BuildContext context) {
    final key = imageKey;
    if (key == null) {
      return _fallback(context);
    }
    // Preserve the full illustration, including the wide first compartment.
    // Captions occupy their own row and cannot cover a lower-positioned subject.
    return ColoredBox(
      color: SoriScrollPalette.paper,
      child: Image.asset(
        chaekgadoCardAsset(key),
        fit: BoxFit.contain,
        errorBuilder: (_, _, _) => _fallback(context),
      ),
    );
  }

  /// 아이보리 면 + 소품 하나. 재고 0 칸도 같은 바닥을 쓴다 — 자물쇠와
  /// 반투명(Opacity 0.62)은 폐기했다. 칸이 고장난 것처럼 보였다.
  Widget _fallback(BuildContext context) {
    final vignette = chaekgadoCategoryVignetteAsset(slug);
    final cluster = Image.asset(
      chaekgadoBookClusterAsset(assetIndex),
      fit: BoxFit.contain,
      alignment: Alignment.bottomCenter,
      errorBuilder: (_, _, _) => const SizedBox.shrink(),
    );
    return Stack(
      fit: StackFit.expand,
      children: [
        const ColoredBox(color: SoriScrollPalette.paper),
        const _BookcaseCrop(
          asset: kChaekgadoBookcaseBackplate,
          source: Rect.fromLTRB(234, 144, 594, 300),
        ),
        Padding(
          padding: const EdgeInsets.all(Spacing.sm),
          child: vignette == null
              ? cluster
              : Image.asset(
                  vignette,
                  fit: BoxFit.contain,
                  alignment: Alignment.bottomRight,
                  errorBuilder: (_, _, _) => cluster,
                ),
        ),
      ],
    );
  }
}

/// Progress and captions sit below the illustration so no subject is obscured.
class _CellTag extends StatelessWidget {
  const _CellTag({
    required this.data,
    required this.emptyLabel,
    required this.progress,
    required this.stamped,
  });

  final ChaekgadoCompartment data;
  final String? emptyLabel;
  final double progress;
  final bool stamped;

  @override
  Widget build(BuildContext context) {
    final tt = SoriTextTheme.of(context);
    final surfaces = SoriSurfaces.of(context);
    final empty = !data.isStocked && emptyLabel != null;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (progress > 0)
          SizedBox(
            height: 4,
            child: CustomPaint(
              key: kChaekgadoBrushStrokeKey,
              painter: _BrushStrokePainter(progress: progress),
            ),
          ),
        DecoratedBox(
          decoration: BoxDecoration(color: surfaces.surface),
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              // 완료 도장이 좌하단에 찍히는 칸은 글이 도장을 피한다.
              stamped ? 46 : Spacing.sm,
              Spacing.xs,
              Spacing.sm,
              Spacing.xs,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data.shortLabel,
                  maxLines: 2,
                  style: tt.meta.copyWith(
                    fontWeight: FontWeight.w700,
                    color: surfaces.text,
                  ),
                ),
                if (empty) Text(emptyLabel!, maxLines: 1, style: tt.meta),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// 진행 = 붓선 (규칙 ③). 길이는 진행률, 끝은 −0.4° 로 살짝 들린다.
/// 0% 면 아예 안 그린다 — 빈 트랙(회색 바)이 없어야 선반이 조용하다.
class _BrushStrokePainter extends CustomPainter {
  const _BrushStrokePainter({required this.progress});

  final double progress;

  static const double _flickRadians = 0.4 * math.pi / 180;

  @override
  void paint(Canvas canvas, Size size) {
    final length = size.width * progress;
    if (length <= 0 || size.height <= 0) {
      return;
    }
    final y = size.height / 2;
    final rise = length * math.tan(_flickRadians);
    canvas.drawPath(
      Path()
        ..moveTo(0, y)
        ..lineTo(length, y - rise),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4
        ..strokeCap = StrokeCap.round
        ..color = SoriColors.primary,
    );
  }

  @override
  bool shouldRepaint(covariant _BrushStrokePainter oldDelegate) =>
      oldDelegate.progress != progress;
}

/// 완료 도장 — 문양은 slug 해시로 고른다(같은 칸은 언제나 같은 문양).
/// 팝은 180ms scale 1.15→1, `disableAnimations` 면 정적이다.
/// 그림은 정본 [DancheongStamp] 재사용 — 19 장 PNG 와 페인터 폴백이 딸려온다.
class _CompletionStamp extends StatelessWidget {
  const _CompletionStamp({required this.slug});

  final String slug;

  static const double _size = 36;
  static const double _tiltRadians = -9 * math.pi / 180;
  static const Duration _pop = Duration(milliseconds: 180);

  @override
  Widget build(BuildContext context) {
    final motif = DancheongMotif
        .values[slug.hashCode.abs() % DancheongMotif.values.length];
    final stamp = Transform.rotate(
      angle: _tiltRadians,
      child: DancheongStamp(motif: motif, size: _size, stamped: true),
    );
    final instant = MediaQuery.disableAnimationsOf(context);
    return SizedBox(
      key: kChaekgadoStampKey,
      width: _size,
      height: _size,
      child: instant
          ? stamp
          : TweenAnimationBuilder<double>(
              tween: Tween(begin: 1.15, end: 1),
              duration: _pop,
              curve: Curves.easeOut,
              builder: (context, scale, child) =>
                  Transform.scale(scale: scale, child: child),
              child: stamp,
            ),
    );
  }
}
