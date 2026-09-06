import 'package:flutter/material.dart';

import 'responsive.dart';
import 'tokens.dart';

/// §W2-Task5: `_cellAspectRatio` 는 그리드 엔트리 전체 타이틀·풋터를
/// `TextPainter.layout()` 으로 실측한다 — 셀 폭·텍스트 스케일·로케일·문자열
/// 목록이 그대로면 매 build() 마다 다시 잴 필요가 없다. 이 키가 같으면
/// 이전 결과를 재사용한다.
///
/// (W10 T-H1: `sori_stage_catalog_screen.dart` 에서 동작 그대로 옮겨 왔다 —
/// 카탈로그와 듣기 허브 그리드가 같은 컬럼·비율 규칙을 공유하기 위함.)
String cellAspectRatioCacheKey({
  required double cellWidth,
  required double textScale,
  required String locale,
  required Iterable<String> titles,
  required Iterable<String> footerLabels,
}) {
  final buffer = StringBuffer()
    ..write(cellWidth.toStringAsFixed(2))
    ..write('|')
    ..write(textScale.toStringAsFixed(3))
    ..write('|')
    ..write(locale)
    ..write('|')
    ..writeAll(titles, '')
    ..write('|')
    ..writeAll(footerLabels, '');
  return buffer.toString();
}

// §정리#3: 이전엔 단일 엔트리(마지막 키 1개)였다 — Learn/Games 두 탭이 한
// 셸 패스 안에서 서로 다른 키로 번갈아 rebuild 되면 서로를 매번 몰아내
// 캐시가 무의미해졌다. 탭 개수만큼(여유 포함) 담을 수 있는 작은 맵으로
// 바꾸고, 꽉 차면 가장 먼저 넣은(오래된) 항목부터 버린다(삽입 순서 = Map
// 순회 순서라 별도 타임스탬프 없이 `keys.first` 로 충분). 동작(캐시 키
// 계산·반환값)은 그대로다.
const int _cellAspectRatioCacheCapacity = 4;
final Map<String, double> _cellAspectRatioCache = <String, double>{};

/// Grid ratio derived from the 4:3 image plus the measured localized title,
/// meta (분) subtitle line, and status footer. Every string remains available
/// while cards in a row keep the same height.
///
/// §E2 (L4): 이전엔 subtitle(분 메타 라인)이 이미지 우하단 필이라 카드
/// 본문 높이에 안 들어갔다. 이제 title 아래 텍스트 줄이 됐으니 실측에
/// 포함해야 한다 — 안 그러면 그리드 셀 바닥에 빈 공간이 남는다.
double _cellAspectRatio(
  BuildContext context,
  double cellWidth, {
  required Iterable<String> titles,
  required Iterable<String> subtitles,
  required Iterable<String> footerLabels,
}) {
  if (!cellWidth.isFinite || cellWidth <= 0) {
    return 0.78;
  }
  final scaler = MediaQuery.textScalerOf(context);
  final direction = Directionality.of(context);
  final locale = Localizations.localeOf(context);
  final textScale = scaler.scale(14) / 14;
  // subtitles 는 titles 와 1:1로 대응하는 파생값(같은 entry 집합)이라 titles가
  // 이미 캐시 키를 정확히 구분한다 — cellAspectRatioCacheKey 시그니처는 그대로
  // 둔다(다른 곳에서 직접 호출하는 계약을 안 건드린다).
  final cacheKey = cellAspectRatioCacheKey(
    cellWidth: cellWidth,
    textScale: textScale,
    locale: locale.toLanguageTag(),
    titles: titles,
    footerLabels: footerLabels,
  );
  final cached = _cellAspectRatioCache[cacheKey];
  if (cached != null) {
    return cached;
  }
  final tt = SoriTextTheme.of(context);
  final titleStyle = tt.cardTitle;
  final subtitleStyle = tt.cardSubtitle;
  // §LAYOUT-2(J12): must match the rendered style exactly —
  // _StateLabel renders w600, not the bare tt.cardSubtitle weight.
  final footerStyle = tt.cardSubtitle.copyWith(fontWeight: FontWeight.w600);
  const double bodyPadding = Spacing.sm + Spacing.md;
  // §W10 PR-B: `SoriIllustratedCard`의 바깥 `Container`가 쓰는
  // `Border.all(width: 1)`(illustrated_card.dart)은 `BoxDecoration.padding`
  // (== `border.dimensions`)을 통해 Flutter `Container`가 자식 폭을 좌우
  // 각 1px씩 자동으로 인셋한다 — 실측 `bodyWidth`가 이 2px을 빼지 않으면
  // 실제보다 넓은 폭으로 줄바꿈을 판정해, 그 경계에 걸린 타이틀(예:
  // "Eigene Wörter üben")이 측정상 1줄인데 실제 렌더는 2줄이 되어 카드
  // 본문이 오버플로할 수 있다(illustrated_card_overflow_guard_test).
  const double cardBorderInset = 1 * 2;
  final bodyWidth = (cellWidth - Spacing.md * 2 - cardBorderInset).clamp(
    1.0,
    double.infinity,
  );
  final title = _maxMeasuredTextHeight(
    texts: titles,
    style: titleStyle,
    maxWidth: bodyWidth,
    scaler: scaler,
    direction: direction,
    locale: locale,
  );
  final subtitle = _maxMeasuredTextHeight(
    texts: subtitles,
    style: subtitleStyle,
    maxWidth: bodyWidth,
    scaler: scaler,
    direction: direction,
    locale: locale,
  );
  // Footer text sits to the right of an 8dp dot + Spacing.xs(4) gap — 12 total.
  const double footerLeadWidth = 8 + Spacing.xs;
  final footer = _maxMeasuredTextHeight(
    texts: footerLabels,
    style: footerStyle,
    maxWidth: (bodyWidth - footerLeadWidth).clamp(1.0, double.infinity),
    scaler: scaler,
    direction: direction,
    locale: locale,
  );
  // Two physical border pixels plus a small rounding allowance keep the
  // fixed-height grid honest at tablet comfort scale and 200% OS text.
  const double layoutAllowance = 4;
  // §E2: subtitle 위 SizedBox(height: 2) — illustrated_card.dart의 제목→
  // 서브타이틀 간격과 정확히 맞춘다.
  const double subtitleGap = 2;
  final double height =
      cellWidth / (4 / 3) +
      bodyPadding +
      title +
      subtitleGap +
      subtitle +
      Spacing.xs +
      footer +
      layoutAllowance;
  final ratio = cellWidth / height;
  if (_cellAspectRatioCache.length >= _cellAspectRatioCacheCapacity) {
    _cellAspectRatioCache.remove(_cellAspectRatioCache.keys.first);
  }
  _cellAspectRatioCache[cacheKey] = ratio;
  return ratio;
}

double _maxMeasuredTextHeight({
  required Iterable<String> texts,
  required TextStyle style,
  required double maxWidth,
  required TextScaler scaler,
  required TextDirection direction,
  required Locale locale,
}) {
  var height = scaler.scale(style.fontSize ?? 14) * (style.height ?? 1);
  for (final text in texts) {
    final painter = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: direction,
      textScaler: scaler,
      locale: locale,
    )..layout(maxWidth: maxWidth);
    height = height < painter.height ? painter.height : height;
    painter.dispose();
  }
  return height;
}

/// **SoriIllustratedCardGrid** (W10 T-H1) — [SoriIllustratedCard] 그리드의
/// 공유 슬리버. `sori_stage_catalog_screen.dart` 의 컬럼 산출·측정
/// `childAspectRatio` 규칙을 그대로 옮긴 것 — 카탈로그와 듣기 허브가 같은
/// 규칙(같은 `target`/`min`/`max`/간격)을 쓰면 시각적으로 동일한 그리드가
/// 나온다.
///
/// 가용 폭은 이 슬리버를 감싼 `SliverPadding`(또는 그 밖의 크로스축을 줄이는
/// 조상)이 이미 반영한 값이다 — 별도 `outerPadding` 인자를 받지 않는다.
class SoriIllustratedCardGrid extends StatelessWidget {
  const SoriIllustratedCardGrid({
    super.key,
    required this.itemCount,
    required this.itemBuilder,
    required this.titles,
    required this.subtitles,
    required this.footerLabels,
    this.target = 160,
    this.min = 2,
    this.max = 6,
    this.mainAxisSpacing = Spacing.md,
    this.crossAxisSpacing = Spacing.md,
  });

  final int itemCount;
  final Widget Function(BuildContext context, int index) itemBuilder;

  /// 그리드에 실제로 그려질 카드들의 타이틀/서브타이틀/풋터 문자열 —
  /// `childAspectRatio` 를 재는 데만 쓰인다(실제 렌더는 [itemBuilder] 몫).
  final Iterable<String> titles;
  final Iterable<String> subtitles;
  final Iterable<String> footerLabels;

  final double target;
  final int min;
  final int max;
  final double mainAxisSpacing;
  final double crossAxisSpacing;

  @override
  Widget build(BuildContext context) {
    return SliverLayoutBuilder(
      builder: (context, constraints) {
        final double available = constraints.crossAxisExtent;
        final baseColumns = soriGridColumns(
          available,
          target: target,
          min: min,
          max: max,
          outerPadding: 0,
          spacing: crossAxisSpacing,
        );
        final textScale = MediaQuery.textScalerOf(context).scale(14) / 14;
        final columns = textScale >= 1.6 && available < SoriBreakpoints.grid
            ? 1
            : baseColumns;
        final double cellWidth =
            (available - crossAxisSpacing * (columns - 1)) / columns;
        return SliverGrid(
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            mainAxisSpacing: mainAxisSpacing,
            crossAxisSpacing: crossAxisSpacing,
            childAspectRatio: _cellAspectRatio(
              context,
              cellWidth,
              titles: titles,
              subtitles: subtitles,
              footerLabels: footerLabels,
            ),
          ),
          delegate: SliverChildBuilderDelegate(
            itemBuilder,
            childCount: itemCount,
          ),
        );
      },
    );
  }
}
