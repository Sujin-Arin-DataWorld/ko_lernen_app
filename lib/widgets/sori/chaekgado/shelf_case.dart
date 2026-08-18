import 'package:flutter/material.dart';

import '../../../data/chaekgado_shelf.dart';
import '../tokens.dart';

/// 책가도 서재의 한 칸 — 듣기 카테고리 하나.
///
/// `slug` 는 `tools/content_factory/shelf_assignment.py` 의 `{level}_{slug}`
/// 뒷부분과 같다(예 `cafe`). 표시명은 ARB 가 정본이므로 이 위젯은 완성된
/// 문자열만 받는다 — 위젯이 l10n 을 알면 프리뷰가 못 돈다.
///
/// [count] 는 그 칸에 실제로 배정된 시나리오 개수다. **0 이면 재고 없는 칸**이고
/// 책등 대신 소품만 놓인다. C1(11편/12칸)·C2(11편/12칸)처럼 대부분이 빈 레벨을
/// 그림 없이 출시하기 위한 장치다.
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

/// 목재·소품 자산이 오기 전까지 쓰는 색면 팔레트.
///
/// 자산이 들어오면 [_ShelfPalette] 만 갈아끼운다 — 레이아웃 코드는 그대로다.
/// 값은 `docs/LISTENING_CARD_ART_SPEC.md` §공통 프롬프트 골격의 실측 팔레트에서
/// 목재 계열만 뽑은 것이다.
abstract final class _ShelfPalette {
  static const Color caseBack = Color(0xFF3E2B1B); // 책장 안쪽 그늘
  static const Color plank = Color(0xFF8E6646); // 널판 (실측 목재)
  static const Color plankLip = Color(0xFFA87F55); // 널판 앞면 하이라이트
  static const Color cellBack = Color(0xFFF4E8D0); // 한지 아이보리
  static const Color cellBackEmpty = Color(0xFFEADDC2); // 재고 0 칸
  static const Color cellEdge = Color(0xFF2A1C10);

  /// 책등 — 6색을 순환한다. 개수가 정보이므로 색은 의미를 갖지 않는다.
  static const List<Color> spines = [
    Color(0xFF5C4028),
    Color(0xFF7A5A3A),
    Color(0xFFB94B32),
    Color(0xFF4E6B63),
    Color(0xFF8E6646),
    Color(0xFF3F4A55),
  ];
}

/// 책가도 서재 — 세로로 스크롤하는 칸 그리드.
///
/// 칸 수를 고정하지 않는다. 레벨당 18칸이든 24칸이든 [compartments] 길이만큼
/// 행이 늘어난다([columns] 개씩 묶어 한 행). 행마다 아래에 널판이 깔린다.
class ChaekgadoShelfCase extends StatelessWidget {
  const ChaekgadoShelfCase({
    super.key,
    required this.compartments,
    required this.onOpen,
    this.emptyLabel,
    this.columns = 2,
    this.cellHeight = 132,
    this.padding = const EdgeInsets.symmetric(horizontal: Spacing.xs + 1),
  });

  final List<ChaekgadoCompartment> compartments;
  final ValueChanged<ChaekgadoCompartment> onOpen;

  /// 재고 0 칸에 적을 문구. null 이면 아무것도 적지 않는다.
  final String? emptyLabel;

  final int columns;
  final double cellHeight;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    final rows = <List<ChaekgadoCompartment>>[];
    for (var i = 0; i < compartments.length; i += columns) {
      rows.add(
        compartments.sublist(i, (i + columns).clamp(0, compartments.length)),
      );
    }

    final body = Padding(
      padding: padding,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var r = 0; r < rows.length; r++)
            _ShelfRow(
              cells: rows[r],
              columns: columns,
              cellHeight: cellHeight,
              emptyLabel: emptyLabel,
              onOpen: onOpen,
              // 소품은 108칸 공용 4종을 순환 — 칸별 자산이 아니다.
              propOffset: r * columns,
            ),
        ],
      ),
    );

    return ColoredBox(
      color: _ShelfPalette.caseBack,
      // Column, not ListView — a level has at most ~6 rows (12 compartments
      // at 2 columns), far too few to need virtualization. A plain Column
      // composes inside ANY parent: the bounded Expanded of the standalone
      // preview, or the unbounded SingleChildScrollView of the real Hören
      // screen. ListView.builder needs a bounded-height parent and breaks
      // inside SingleChildScrollView without shrinkWrap/physics juggling.
      //
      // The pillar Row wants `stretch` — pillars as tall as the shelf body —
      // but `stretch` demands a bounded cross axis, and inside
      // SingleChildScrollView the vertical axis is unbounded, so a plain
      // Row+stretch here throws "BoxConstraints forces an infinite height".
      // IntrinsicHeight measures the body's own (finite) height first and
      // hands that down as a tight constraint instead.
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const _Pillar(),
            Expanded(child: body),
            const _Pillar(),
          ],
        ),
      ),
    );
  }
}

/// 서재 좌우 기둥 — 칸 내용과 무관, 폭 고정.
class _Pillar extends StatelessWidget {
  const _Pillar();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 11,
      child: Image.asset(
        kChaekgadoPillarAsset,
        fit: BoxFit.fill,
        errorBuilder: (_, _, _) => const ColoredBox(color: _ShelfPalette.plank),
      ),
    );
  }
}

class _ShelfRow extends StatelessWidget {
  const _ShelfRow({
    required this.cells,
    required this.columns,
    required this.cellHeight,
    required this.emptyLabel,
    required this.onOpen,
    required this.propOffset,
  });

  final List<ChaekgadoCompartment> cells;
  final int columns;
  final double cellHeight;
  final String? emptyLabel;
  final ValueChanged<ChaekgadoCompartment> onOpen;
  final int propOffset;

  @override
  Widget build(BuildContext context) {
    final children = <Widget>[];
    for (var i = 0; i < columns; i++) {
      if (i > 0) children.add(const SizedBox(width: Spacing.xs + 1));
      children.add(
        Expanded(
          // 마지막 행이 덜 찼으면 빈 자리를 남긴다 — 칸을 늘려 채우면
          // 폭이 다른 칸이 생겨 선반이 어긋나 보인다.
          child: i < cells.length
              ? _Compartment(
                  data: cells[i],
                  height: cellHeight,
                  emptyLabel: emptyLabel,
                  propIndex: propOffset + i,
                  onTap: () => onOpen(cells[i]),
                )
              : SizedBox(height: cellHeight),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(top: Spacing.xs + 1),
      child: Column(
        children: [
          Row(crossAxisAlignment: CrossAxisAlignment.end, children: children),
          // 널판 — 실제 목재 텍스처. 앞면 하이라이트 1px 는 자산이 없을 때
          // 폴백에서만 필요하므로 errorBuilder 쪽에 남긴다.
          SizedBox(
            height: 14,
            child: Image.asset(
              kChaekgadoPlankAsset,
              fit: BoxFit.fill,
              errorBuilder: (_, _, _) => const DecoratedBox(
                decoration: BoxDecoration(
                  color: _ShelfPalette.plank,
                  border: Border(
                    top: BorderSide(color: _ShelfPalette.plankLip, width: 1),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Compartment extends StatelessWidget {
  const _Compartment({
    required this.data,
    required this.height,
    required this.emptyLabel,
    required this.propIndex,
    required this.onTap,
  });

  final ChaekgadoCompartment data;
  final double height;
  final String? emptyLabel;
  final int propIndex;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final stocked = data.isStocked;
    return Semantics(
      button: true,
      label: stocked ? '${data.label} · ${data.count}' : data.label,
      child: ExcludeSemantics(
        child: GestureDetector(
          onTap: onTap,
          behavior: HitTestBehavior.opaque,
          child: Container(
            height: height,
            padding: const EdgeInsets.fromLTRB(
              Spacing.xs + 1,
              Spacing.xs + 1,
              Spacing.xs + 1,
              0,
            ),
            decoration: BoxDecoration(
              color: stocked
                  ? _ShelfPalette.cellBack
                  : _ShelfPalette.cellBackEmpty,
              border: Border.all(color: _ShelfPalette.cellEdge, width: 1),
              borderRadius: const BorderRadius.all(Radius.circular(2)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _NamePlate(
                  label: data.label,
                  progress: stocked ? data.progress : null,
                  emptyLabel: stocked ? null : emptyLabel,
                ),
                Expanded(
                  child: _CellInterior(count: data.count, propIndex: propIndex),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// 이름표 — 카테고리를 **식별하는 것은 이 문자열**이다.
///
/// 책등의 한국어는 실기기에서 8px 안팎이라 판독되지 않는다. 그래서 책등은
/// 분위기와 개수만 나르고, 식별은 여기가 한다.
class _NamePlate extends StatelessWidget {
  const _NamePlate({
    required this.label,
    required this.progress,
    required this.emptyLabel,
  });

  final String label;
  final double? progress;
  final String? emptyLabel;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(5, 3, 5, 4),
      decoration: BoxDecoration(
        color: SoriColors.lightBg,
        border: Border.all(color: const Color(0xFFC9B694), width: 0.5),
        borderRadius: const BorderRadius.all(Radius.circular(3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 9,
              height: 1.25,
              fontWeight: FontWeight.w600,
              color: SoriColors.lightText,
            ),
          ),
          if (progress != null) ...[
            const SizedBox(height: 3),
            ClipRRect(
              borderRadius: const BorderRadius.all(Radius.circular(2)),
              child: SizedBox(
                height: 2,
                child: LinearProgressIndicator(
                  value: progress!.clamp(0, 1),
                  backgroundColor: const Color(0xFFDDCDAE),
                  valueColor: const AlwaysStoppedAnimation(
                    SoriColors.primary,
                  ),
                ),
              ),
            ),
          ] else if (emptyLabel != null) ...[
            const SizedBox(height: 2),
            Text(
              emptyLabel!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 8,
                color: Color(0xFF9C8B70),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// 칸 내부 — 책등 [count] 개 + 소품 하나.
///
/// 책등 개수는 **실제 시나리오 개수**다. 4개 고정이 아니다. 3권과 화병 하나는
/// 책가도의 정상 구도라 듬성듬성해도 비어 보이지 않는다.
class _CellInterior extends StatelessWidget {
  const _CellInterior({required this.count, required this.propIndex});

  final int count;
  final int propIndex;

  @override
  Widget build(BuildContext context) {
    final spines = <Widget>[];
    // 한 칸에 다 안 들어가는 개수는 잘라 그린다 — 넘치면 폭이 깨진다.
    for (var i = 0; i < count.clamp(0, 5); i++) {
      if (i > 0) spines.add(const SizedBox(width: 3));
      spines.add(
        Container(
          width: 15,
          // 높이를 조금씩 다르게 — 프리뷰에서 전부 같은 높이로 세우니
          // 책이 아니라 색 막대로 보였다. 3종을 순환시킨다.
          height: switch (i % 3) {
            0 => 84.0,
            1 => 76.0,
            _ => 88.0,
          },
          decoration: BoxDecoration(
            color: _ShelfPalette.spines[i % _ShelfPalette.spines.length],
            borderRadius: const BorderRadius.vertical(top: Radius.circular(1)),
          ),
          // 인장 — 책등 아래 붉은 점.
          child: const Align(
            alignment: Alignment(0, 0.78),
            child: SizedBox(
              width: 5,
              height: 5,
              child: ColoredBox(color: Color(0xFFB94B32)),
            ),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          ...spines,
          const Spacer(),
          // 소품 — 108칸 공용 4종(청자·붓통·사발·두루마리)을 칸 위치로 순환.
          _Prop(index: propIndex),
        ],
      ),
    );
  }
}

class _Prop extends StatelessWidget {
  const _Prop({required this.index});

  final int index;

  @override
  Widget build(BuildContext context) {
    final asset = kChaekgadoProps[index % kChaekgadoProps.length];
    return SizedBox(
      width: 26,
      height: 40,
      child: Image.asset(
        asset,
        fit: BoxFit.contain,
        alignment: Alignment.bottomCenter,
        errorBuilder: (_, _, _) => const _PlaceholderProp(),
      ),
    );
  }
}

class _PlaceholderProp extends StatelessWidget {
  const _PlaceholderProp();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 17,
      height: 40,
      decoration: BoxDecoration(
        color: const Color(0xFF9FBDB2),
        border: Border.all(color: const Color(0xFF7FA096), width: 1),
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(8),
          bottom: Radius.circular(5),
        ),
      ),
    );
  }
}
