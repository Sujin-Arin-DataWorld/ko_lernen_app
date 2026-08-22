import 'package:flutter/material.dart';

import 'hanok/eaves_corner.dart';
import 'hanok/hanji_texture.dart';
import 'pressable.dart';
import 'tokens.dart';

/// SoriCard variant. (크기·스킨 축 — 표면 문법과는 독립)
enum SoriCardVariant {
  /// 큰 hero card (24 padding, radius 20).
  hero,

  /// 기본 카드 (16 padding, radius 16).
  base,

  /// 작은 compact 카드 (12 padding, radius 12).
  compact,

  /// 한지 텍스처 배경 카드 (v4 한옥 skin). hero급 padding, hanji bg, eaves corner 자동.
  hanji,
}

/// **SoriCard** — 통합 카드 컴포넌트. **표면 v2** (2026-08-03,
/// `docs/DESIGN_OVERHAUL_PLAN_2026-08-02.md` §4.1 "한지 위 백자" · §4.2 · §10.3).
///
/// 표면 규칙:
/// - 라이트 기본 = `lightSurfaceRaised` + `SoriElevation.low`, **테두리 없음**.
///   탭 가능 카드는 눌림 동안 `SoriElevation.medium`. 구 문법(전면 1.5px
///   hairline)은 §3 진단 1원인(크림-온-크림 + 만능 테두리)으로 폐지.
/// - [selectable] = 경계 자체가 정보인 선택형 UI(라디오·레벨 카드·선택지)만
///   `lightBorderStrong` 1.5px 테두리, [selected]면 `primary` 2px.
/// - [accent] 색 코딩은 전면 테두리 → **좌측 4px 액센트 바**로 이전
///   (기존 API 불변, 시각만 이동 — v2 §0b-2 "카드별 색 코딩 소실" 회피).
/// - 다크 = 그림자 무효 환경이라 `darkBorderStrong` 1.5px 유지 (§4.5).
/// - 처마 곡선(`EavesCorner`)은 표면 v2에서도 **존치** — 그림자 문법과 독립,
///   variant 자동 규칙(hanji + eaves 옵션) 현행 유지 (§10.3 명시 결정).
class SoriCard extends StatefulWidget {
  final Widget child;
  final SoriCardVariant variant;

  /// 색 코딩 액센트 — 좌측 4px 바 + (tinted면) 옅은 채움. null이면 brand-neutral.
  final Color? accent;

  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final EdgeInsetsGeometry? padding;
  final double? width;
  final double? height;

  /// surface 배경 대신 accent 채움(아주 옅게). hero 카드에 권장.
  final bool tinted;

  /// v4 한옥 skin — 카드 상단 모서리를 처마(eaves)처럼 살짝 더 큰 곡선으로.
  /// hero/hanji variant에 자연스러움. base/compact엔 보통 false.
  final bool eaves;

  /// 선택형 UI(경계 자체가 정보 — 라디오·레벨 카드·선택지)만 true.
  /// 표면 v2에서 테두리가 남는 유일한 라이트 케이스 (§4.1 3행).
  final bool selectable;

  /// [selectable] 카드의 선택 상태 — `primary` 2px 테두리 (§10.3).
  final bool selected;

  /// 접근성 라벨 — null이면 child의 Semantics를 그대로 사용.
  /// tappable card는 button 역할로 트리에 등록된다.
  final String? semanticLabel;

  const SoriCard({
    super.key,
    required this.child,
    this.variant = SoriCardVariant.base,
    this.accent,
    this.onTap,
    this.onLongPress,
    this.padding,
    this.width,
    this.height,
    this.tinted = false,
    this.eaves = false,
    this.selectable = false,
    this.selected = false,
    this.semanticLabel,
  }) : assert(selectable || !selected, 'selected는 selectable 카드 전용');

  /// 카드가 실제로 칠하는 배경색 — build 와 **같은 계산**을 외부에 노출한다.
  /// `CharacterClipPlayer.blendColor`(multiply 합성)처럼 카드 배경과 정확히
  /// 일치해야 하는 소비자는 반드시 이걸 쓸 것 — 수식을 복제하면 어긋난 순간
  /// 흰 영상 배경이 사각형으로 비친다(핑크 사각형 계열 재발 방지).
  /// ⚠️ hanji variant 는 HanjiTexture 가 배경을 그리므로 이 값과 다르다 —
  /// hanji 카드 위 multiply 합성에는 쓰지 말 것.
  static Color resolvedBackground(
    BuildContext context, {
    Color? accent,
    bool tinted = false,
  }) {
    final s = SoriSurfaces.of(context);
    final isLight = s.brightness == Brightness.light;
    final accentColor = accent ?? SoriColors.primary;

    // 라이트에서는 배경보다 한 톤 밝은 흰 한지로 카드를 띄운다.
    // s.surface(#F1ECDC)는 s.bg(#FAF6EC) 대비 1.09:1 이라 카드로 안 읽힌다.
    final baseSurface = isLight ? SoriColors.lightSurfaceRaised : s.surface;
    if (!tinted) {
      return baseSurface;
    }
    return Color.alphaBlend(
      accentColor.withValues(alpha: isLight ? 0.08 : 0.14),
      baseSurface,
    );
  }

  @override
  State<SoriCard> createState() => _SoriCardState();
}

class _SoriCardState extends State<SoriCard> {
  /// 눌림 동안 그림자 low→medium (§10.3 pressed 스펙, 라이트 전용).
  bool _pressed = false;

  double get _radius => switch (widget.variant) {
    SoriCardVariant.hero => SoriRadius.lg,
    SoriCardVariant.base => SoriRadius.md,
    SoriCardVariant.compact => SoriRadius.sm,
    SoriCardVariant.hanji => SoriRadius.lg,
  };

  EdgeInsetsGeometry get _defaultPadding => switch (widget.variant) {
    SoriCardVariant.hero => const EdgeInsets.all(Spacing.xl),
    SoriCardVariant.base => const EdgeInsets.all(Spacing.lg),
    SoriCardVariant.compact => const EdgeInsets.all(Spacing.md),
    SoriCardVariant.hanji => const EdgeInsets.all(Spacing.lg),
  };

  /// hanji variant + 처마 옵션은 자동 eaves 처리.
  bool get _useEaves => widget.eaves || widget.variant == SoriCardVariant.hanji;

  /// hanji variant는 항상 HanjiTexture wrapping.
  bool get _useHanji => widget.variant == SoriCardVariant.hanji;

  BorderRadius get _borderRadius => _useEaves
      ? EavesCorner.borderRadius(base: _radius, boost: 6)
      : BorderRadius.circular(_radius);

  bool get _interactive => widget.onTap != null || widget.onLongPress != null;

  @override
  Widget build(BuildContext context) {
    final s = SoriSurfaces.of(context);
    final isLight = s.brightness == Brightness.light;
    final bgColor = SoriCard.resolvedBackground(
      context,
      accent: widget.accent,
      tinted: widget.tinted,
    );

    // 표면 v2 테두리 규칙 (§4.1·§10.3): 라이트 기본은 무테두리.
    // selectable(경계=정보)과 다크(그림자 무효)만 테두리를 가진다.
    final Border? border;
    if (widget.selectable && widget.selected) {
      border = Border.all(color: SoriColors.primary, width: 2);
    } else if (widget.selectable) {
      border = Border.all(
        color: isLight
            ? SoriColors.lightBorderStrong
            : SoriColors.darkBorderStrong,
        width: 1.5,
      );
    } else if (!isLight) {
      border = Border.all(color: SoriColors.darkBorderStrong, width: 1.5);
    } else {
      border = null;
    }

    // 라이트 전용 그림자 — 흰 한지 카드가 크림(lightBg) 위에 "떠 있는" 문법.
    final List<BoxShadow>? shadows = isLight
        ? (_pressed && _interactive ? SoriElevation.medium : SoriElevation.low)
        : null;

    Widget content = Padding(
      padding: widget.padding ?? _defaultPadding,
      child: widget.child,
    );

    // accent 색 코딩: 좌측 4px 바 (콘텐츠 아래 레이어, 라운드 코너는 클리핑).
    // ⚠️ selectable+accent 동시 사용 시 바가 좌측 테두리 위에 얹힌다 — 조합 지양.
    //
    // ⚠️ `fit: StackFit.passthrough` 필수. 기본값 `StackFit.loose` 는 non-positioned
    // 콘텐츠의 min 제약(높이·너비)을 0 으로 풀어 버린다 → 콘텐츠가 카드 높이를
    // 채우지 못하고 `topStart` 로 쏠린다. hero 플립카드(`Center`/가운데정렬 Column)가
    // 카드 상단·좌측으로 붕 뜨던 회귀의 실제 원인. passthrough 는 카드의 실제 제약을
    // 그대로 넘겨 Center/가운데정렬이 정상 동작하게 한다(높이 여유 시 동일, 부족 시
    // 스크롤 폴백 유지). start 정렬 카드는 좌측 정렬이라 시각 변화 없음.
    if (widget.accent != null) {
      content = Stack(
        fit: StackFit.passthrough,
        children: [
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            width: 4,
            child: ColoredBox(color: widget.accent!),
          ),
          content,
        ],
      );
    }

    Widget body;
    if (_useHanji) {
      // hanji 는 HanjiTexture 가 배경을 그린다 — 그림자는 바깥, 테두리는
      // 전경(foreground)으로 올려 텍스처가 테두리를 덮지 않게 한다.
      body = Container(
        decoration: BoxDecoration(
          borderRadius: _borderRadius,
          boxShadow: shadows,
        ),
        foregroundDecoration: BoxDecoration(
          borderRadius: _borderRadius,
          border: border,
        ),
        child: HanjiTexture(borderRadius: _borderRadius, child: content),
      );
    } else {
      final decoration = BoxDecoration(
        color: bgColor,
        borderRadius: _borderRadius,
        border: border,
        boxShadow: shadows,
      );
      // 내용 클리핑: 구 문법의 탭 분기 ClipRRect 는 그림자까지 잘라내므로 제거,
      // Container.clipBehavior 가 승계 (accent 바·탭 카드만 클립).
      final clip = (widget.accent != null || _interactive)
          ? Clip.antiAlias
          : Clip.none;
      body = _interactive
          ? AnimatedContainer(
              duration: SoriMotion.fast,
              curve: Curves.easeOut,
              clipBehavior: clip,
              decoration: decoration,
              child: content,
            )
          : Container(
              clipBehavior: clip,
              decoration: decoration,
              child: content,
            );
    }

    final card = SizedBox(
      width: widget.width,
      height: widget.height,
      child: body,
    );

    if (!_interactive) {
      return widget.semanticLabel == null
          ? card
          : Semantics(
              label: widget.semanticLabel,
              container: true,
              child: card,
            );
    }

    return Semantics(
      button: true,
      enabled: true,
      label: widget.semanticLabel,
      selected: widget.selectable ? widget.selected : null,
      child: SoriPressable(
        onTap: widget.onTap,
        onLongPress: widget.onLongPress,
        pressScale:
            (widget.variant == SoriCardVariant.hero ||
                widget.variant == SoriCardVariant.hanji)
            ? 0.97
            : 0.96,
        onPressedChanged: (pressed) {
          if (!mounted) {
            return;
          }
          setState(() => _pressed = pressed);
        },
        child: card,
      ),
    );
  }
}
