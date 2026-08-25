import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../dancheong_stamp.dart';
import '../hanok/hanji_texture.dart';
import '../hanok_tokens.dart';
import '../tokens.dart';
import 'chaekgado_assets.dart';
import 'scroll_palette.dart';

/// 책가도 목재 5색 — `docs/HANDOFF_HOEREN_REDESIGN_2026-08-19.md` §3-② 의
/// 승인 팔레트를 그대로 옮긴 것이다. **신규 안료가 아니다**: 널판 3톤·윗변
/// 석간주 어긋남선·장 안쪽이 그 표의 값이며, 값을 고칠 땐 그 문서가 먼저다.
/// 나무를 PNG 가 아니라 [CustomPainter] 로 그리는 이유도 같은 절(② 나무 =
/// 면 3톤 + 어긋남) — 프레임 PNG 는 기둥 위치와 투명 여백이 베이크돼 있어
/// dp 그리드에서는 재사용이 불가능하다.
abstract final class _ChaekgadoWood {
  /// 널판 위 밴드 30%.
  static const Color plankLight = Color(0xFFA87F55);

  /// 널판 중간 밴드 44%.
  static const Color plankMid = Color(0xFF8E6646);

  /// 널판 아래 밴드 26%.
  static const Color plankDark = Color(0xFF5C4028);

  /// 리소 2판 어긋남 — 널판 윗변 1px 석간주.
  static const Color misregister = Color(0xFFB94B32);

  /// 장 안쪽(칸 뒤) 먹갈색 면.
  static const Color carcass = Color(0xFF3E2B1B);
}

/// dp 그리드 — 레이아웃을 PNG 가 아니라 이 수치가 정한다.
abstract final class _Grid {
  static const double sidePillar = 12;
  static const double centerPillar = 10;
  static const double plank = 10;
  static const double crown = 24;
  static const double base = 14;
  static const double cellAspect = 0.6;
  static const double minCellHeight = 88;
  static const double maxCellHeight = 116;

  /// 행마다 홀짝으로 교차하는 어긋남 각(±0.5°).
  static const double skew = 0.5 * math.pi / 180;
}

/// 붓선(진행)과 완료 도장을 테스트가 집을 수 있게 하는 공개 키.
/// 칸마다 하나씩이라 같은 키가 여러 번 나오지만 형제가 아니므로 위젯 트리
/// 규칙상 충돌하지 않는다.
const Key kChaekgadoBrushStrokeKey = ValueKey('chaekgado_brush_stroke');

/// 완료 도장을 집는 공개 키.
const Key kChaekgadoStampKey = ValueKey('chaekgado_stamp');

/// 칸 하나의 좌표·크기를 재려는 테스트용 키.
Key chaekgadoCompartmentKey(String slug) => ValueKey('chaekgado_cell_$slug');

@immutable
class ChaekgadoCompartment {
  /// [shortLabel] 을 안 주면 [label] 을 그대로 쓴다 — 짧은 이름이 따로 없는
  /// 프리뷰·테스트 자리를 위해서다.
  const ChaekgadoCompartment({
    required this.slug,
    required this.label,
    String? shortLabel,
    this.imageKey,
    this.count = 0,
    this.progress = 0,
  }) : shortLabel = shortLabel ?? label;

  final String slug;

  /// 긴 이름 — 스크린리더와 두루마리 머리글이 쓴다.
  final String label;

  /// 칸 위에 실제로 찍히는 1~2 단어 이름 (눈 전용).
  final String shortLabel;

  /// `assets/illustrations/listening/{imageKey}.webp` 의 키.
  /// 없거나 파일이 없으면 비네트 → 책더미로 내려간다.
  final String? imageKey;

  final int count;
  final double progress;

  bool get isStocked => count > 0;
}

/// 책가도 서재 — **dp 그리드가 레이아웃을 정하고 나무는 페인터가 그린다.**
///
/// 2026-08-23 전면 재작성(계획 `cheerful-percolating-shore.md` P1). 이전 판은
/// 1254px 캔버스의 슬롯 좌표를 하드코딩해 칸이 103dp 폭·37dp 높이로 쪼그라들고
/// 가용폭의 27%가 PNG 속 투명 여백으로 사라졌다. 지금은:
///
/// - 기둥 12dp(중앙 10dp)를 빼고 남는 폭을 칸이 반씩 갖는다.
/// - 칸 높이 = `(칸폭 × 0.6).clamp(88, 116)` — 어느 폭에서도 48dp 탭 규정 위.
/// - **첫 칸은 전폭**이라 15칸(홀수)이 1 + 7×2 로 정확히 떨어진다. 죽은 빈
///   칸이 구조적으로 사라진다.
/// - 칸 내부는 듣기 카드 아트 한 장(규칙 ① 칸 = 정물 한 점).
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
        final cellHeight = (cellWidth * _Grid.cellAspect).clamp(
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
            const Positioned.fill(
              child: ColoredBox(color: _ChaekgadoWood.carcass),
            ),
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const _Plank(height: _Grid.crown, rowIndex: 0),
                ...band,
              ],
            ),
            // 그레인 1겹 — 08-19 §3-② "그레인 1겹 multiply(전체)".
            const Positioned.fill(child: IgnorePointer(child: _WoodGrain())),
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
    final children = <Widget>[const _Pillar(width: _Grid.sidePillar)];
    for (var i = 0; i < cells.length; i++) {
      if (i > 0) {
        children.add(const _Pillar(width: _Grid.centerPillar));
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
    children.add(const _Pillar(width: _Grid.sidePillar));
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: children,
    );
  }
}

class _Plank extends StatelessWidget {
  const _Plank({required this.height, required this.rowIndex});

  final double height;
  final int rowIndex;

  @override
  Widget build(BuildContext context) {
    return Transform(
      transform: Matrix4.skewY(rowIndex.isEven ? _Grid.skew : -_Grid.skew),
      alignment: Alignment.center,
      child: SizedBox(
        height: height,
        child: const CustomPaint(painter: _PlankPainter()),
      ),
    );
  }
}

class _Pillar extends StatelessWidget {
  const _Pillar({required this.width});

  final double width;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: width,
    child: const CustomPaint(painter: _PillarPainter()),
  );
}

/// 널판 — 가로 3톤 하드엣지(30/44/26) + 윗변 1px 석간주 어긋남.
class _PlankPainter extends CustomPainter {
  const _PlankPainter();

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) {
      return;
    }
    const bands = <(double, Color)>[
      (0.30, _ChaekgadoWood.plankLight),
      (0.44, _ChaekgadoWood.plankMid),
      (0.26, _ChaekgadoWood.plankDark),
    ];
    final paint = Paint();
    var y = 0.0;
    for (final (fraction, color) in bands) {
      final bandHeight = size.height * fraction;
      paint.color = color;
      // +0.5 는 하드엣지 사이에 반투명 이음매가 생기지 않게 하는 겹침이다.
      canvas.drawRect(Rect.fromLTWH(0, y, size.width, bandHeight + 0.5), paint);
      y += bandHeight;
    }
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, 1),
      Paint()..color = _ChaekgadoWood.misregister.withValues(alpha: 0.28),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// 기둥 — 세로 3면. 빛은 왼쪽 위에서 온다(F-A camera 규약).
class _PillarPainter extends CustomPainter {
  const _PillarPainter();

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) {
      return;
    }
    const faces = <(double, Color)>[
      (0.28, _ChaekgadoWood.plankLight),
      (0.46, _ChaekgadoWood.plankMid),
      (0.26, _ChaekgadoWood.plankDark),
    ];
    final paint = Paint();
    var x = 0.0;
    for (final (fraction, color) in faces) {
      final faceWidth = size.width * fraction;
      paint.color = color;
      canvas.drawRect(Rect.fromLTWH(x, 0, faceWidth + 0.5, size.height), paint);
      x += faceWidth;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// 나무 위 결 한 겹. 새 텍스처를 만들지 않고 정본 [HanjiTexture] 를 그대로
/// 쓴다 — 베이스 워시를 알파 0 으로 넘기면 사각형은 안 보이고 섬유·티끌만
/// 남는다(RGB 는 크림이라 페인터가 "밝은 종이" 쪽 결 색을 고른다).
class _WoodGrain extends StatelessWidget {
  const _WoodGrain();

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: 0.5,
      child: HanjiTexture(
        color: HanokColors.hanjiCream.withValues(alpha: 0),
        noiseAlpha: 0.05,
        child: const SizedBox.expand(),
      ),
    );
  }
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
              _CellGround(
                slug: data.slug,
                imageKey: data.imageKey,
                assetIndex: assetIndex,
                stocked: stocked,
              ),
              if (done)
                Positioned(
                  left: 4,
                  bottom: 4,
                  child: _CompletionStamp(slug: data.slug),
                ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: _CellTag(
                  data: data,
                  emptyLabel: emptyLabel,
                  progress: progress,
                  stamped: done,
                ),
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
    required this.stocked,
  });

  final String slug;
  final String? imageKey;
  final int assetIndex;
  final bool stocked;

  @override
  Widget build(BuildContext context) {
    final key = imageKey;
    if (!stocked || key == null) {
      return _fallback(context);
    }
    return Image.asset(
      chaekgadoCardAsset(key),
      fit: BoxFit.cover,
      // 아트 세이프가 12~88% 라 세로 중앙보다 살짝 위를 본다.
      alignment: const Alignment(0, -0.1),
      errorBuilder: (_, _, _) => _fallback(context),
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

/// 붓선(진행) + 이름표. 이름표는 아트 위에 앉으므로 표면색 띠를 깔아 대비를
/// 지킨다(꼬리표 대비 ≥ 7:1, 08-19 §3 접근성).
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
        ColoredBox(
          color: surfaces.surface.withValues(alpha: 0.92),
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
