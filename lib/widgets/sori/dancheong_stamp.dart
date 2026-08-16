import 'dart:math' as math;

import 'package:flutter/material.dart';

// NOTE: tokens.dart absichtlich nicht importiert — die Stempel-Farben sind
// als const Color() hier inline gehalten, damit der Stempel ohne Theme-Lookup
// in jedem Kontext (CustomPainter, Hero-Animation, off-screen render) ohne
// MediaQuery funktioniert. Die Farbwerte spiegeln die Dancheong-Palette aus
// HANGUL_SORI_STYLE_GUIDE.md wider.

/// 단청 도장 — 팩 클리어 시 한지 위에 찍히는 도장.
///
/// Phase 2 (stately-rising-jongga): 정적 SVG-fallback (PNG 자산이 오기 전).
/// Jin이 `assets/illustrations/stamps/stamp_*.png` 작업 끝나면 [asset]
/// 파라미터로 PNG 사용. 그 전까지는 CustomPainter로 단청 lotus 모티프 그림.
///
/// 사용:
/// ```dart
/// DancheongStamp(
///   motif: DancheongMotif.lotus,       // 토픽군별 다른 모티프
///   size: 96,
///   animate: true,                     // 결과 화면에서 찍히는 애니메이션
/// )
/// ```
/// 팩 주제를 나타내는 단청 문양. **실루엣이 서로 겹치지 않도록** 고른다 —
/// 경로 노드는 62dp 라, 원본에서 구분되는 무늬도 그 크기에선 뭉개진다.
///
/// 2026-08-04: 8종 → 14종. 이유 두 가지.
///  1. `motifForPackId` 의 switch 에 13개 주제가 빠져 있어 86팩 중 36팩이
///     `_ => lotus` 로 떨어졌다. 매핑된 7개까지 합쳐 **절반이 연꽃**이었다.
///  2. lotus·chrysanthemum·octagon·plum 이 전부 "크림 바탕 금색 방사형 꽃"
///     이라 62dp 에선 한 개로 보였다. 그래서 신규 6종은 전부 실루엣 축을
///     달리 잡았다 — 가로 띠, S자 덩굴, 겹친 고리, 육각 격자, 삼각 소용돌이,
///     덩어리 꽃. lotus 는 측면 프로필로, octagon 은 순수 격자로 재작화.
enum DancheongMotif {
  lotus, // 인사·자기소개·가족 (a1 greetings/family/self_intro)
  chrysanthemum, // 시간·숫자 (a1 time/numbers)
  plum, // 감정·형용사 (a1/a2/b1 feelings·descriptions)
  bamboo, // 학교·직장 (a2/b1/b2 work/education)
  cloud, // 날씨·건강 (a2 weather, a2/b1 health)
  octagon, // 음식·쇼핑 (a1/a2 food/shopping)
  mountain, // 교통·여행 (a1/a2 transport)
  manja, // 신체·색·위치 (a1 body/colors/position)
  //  ── 2026-08-04 신설 ──
  vine, // 일상 (a1/a2/b1 daily) — 최대 그룹 13팩
  chilbo, // 사회·기술·소통 (b1 tech_society, b2 society/communication)
  gwigap, // 집·기타 (a2 home, a1/b2 misc)
  wave, // 환경 (b2 environment)
  taegeuk, // 사고·추상 (b2 thinking)
  peony, // 돈 (a2 money)
}

/// Pack-ID → Motif Mapping. Konsistent über alle Phasen.
DancheongMotif motifForPackId(String packId) {
  final base = _baseOf(packId);
  return switch (base) {
    'a1_greetings' || 'a1_self_intro' || 'a1_family' => DancheongMotif.lotus,
    'a1_time' || 'a1_numbers' => DancheongMotif.chrysanthemum,
    'a1_descriptions' ||
    'a2_descriptions' ||
    'b1_descriptions' ||
    'a2_feelings' ||
    'b1_emotions_relations' ||
    'b1_character_feelings' ||
    'b1_descriptions_adj' => DancheongMotif.plum,
    'a2_work' ||
    'a2_education' ||
    'b1_work' ||
    'b2_work' ||
    'b2_education' ||
    'b1_work_career' ||
    'a2_people_jobs' ||
    'a2_school_uni' => DancheongMotif.bamboo,
    'a2_weather' ||
    'a2_health_misc' ||
    'b1_health_education' ||
    'b1_health_hospital' => DancheongMotif.cloud,
    'a1_food' ||
    'a2_food' ||
    'a2_shopping' ||
    'a2_clothing' ||
    'a2_wearing_verbs' ||
    'a2_restaurant' ||
    'a2_food_more' => DancheongMotif.octagon,
    'a1_transport' ||
    'a2_transport' ||
    'b1_travel_transport' ||
    'b1_city_places' => DancheongMotif.mountain,
    'a1_body' ||
    'a1_colors' ||
    'a1_position' ||
    'b2_safety_rules' => DancheongMotif.manja,
    // ── 2026-08-04: 여기부터가 예전에 통째로 fallback 으로 새던 주제들 ──
    'a1_daily' ||
    'a2_daily' ||
    'b1_daily' ||
    'b1_verbs_daily' ||
    'b2_thinking_verbs' ||
    'b2_modern_life' ||
    'a2_change_verbs' => DancheongMotif.vine,
    'b1_tech_society' ||
    'b2_society' ||
    'b2_communication' ||
    'b1_media_culture' ||
    'b1_communication_lang' ||
    'b2_language_grammar' => DancheongMotif.chilbo,
    'a2_home' ||
    'a1_misc' ||
    'b2_misc' ||
    'b2_household_practical' ||
    'a2_household' => DancheongMotif.gwigap,
    'b2_environment' || 'a2_nature' => DancheongMotif.wave,
    'b2_thinking' || 'b2_abstract_concepts' => DancheongMotif.taegeuk,
    'a2_money' || 'b1_money_bank' => DancheongMotif.peony,
    // ── 2026-08-11 확장 팩 (TOPIK-Kuratierung) ──
    'b1_social_events' ||
    'b2_relationships_people' ||
    'b2_manners_society' ||
    'b2_honorifics' => DancheongMotif.lotus,
    'b1_time_life' || 'b2_events_culture' => DancheongMotif.chrysanthemum,
    // fallback — 여기 걸리면 새 주제가 생긴 것이다. 위에 추가할 것.
    // `test/dancheong_stamp_test.dart` 의 전수 대조 테스트가 잡아준다.
    // Reviewed A1-C2 content packs using the existing motif pipeline.
    'b1_housing_contract' => DancheongMotif.gwigap,
    'b2_formal_agreement' => DancheongMotif.chilbo,
    'b1_work_coordination' => DancheongMotif.bamboo,
    'b2_formal_complaint' => DancheongMotif.manja,
    'b2_decisions_perspectives' => DancheongMotif.taegeuk,
    'b2_reading_response' => DancheongMotif.chrysanthemum,
    'b2_language_society' => DancheongMotif.chilbo,
    'b2_life_values' => DancheongMotif.taegeuk,
    'b2_literature_emotion' => DancheongMotif.chrysanthemum,
    'b2_language_change' => DancheongMotif.chilbo,
    // Reviewed A1-C2 content packs using the existing motif pipeline.
    'b2_collaborative_feedback' => DancheongMotif.bamboo,
    'b2_digital_judgment' => DancheongMotif.chilbo,
    'c1_accessible_participation' => DancheongMotif.gwigap,
    'c1_evidence_reasoning' => DancheongMotif.taegeuk,
    'c2_institutional_mediation' => DancheongMotif.manja,
    'c2_narrative_perspective' => DancheongMotif.chrysanthemum,
    'b2_shared_space_coordination' => DancheongMotif.gwigap,
    'b2_personal_boundaries' => DancheongMotif.plum,
    'c1_risk_communication' => DancheongMotif.manja,
    'c1_sustainable_tradeoffs' => DancheongMotif.wave,
    'c2_language_framing' => DancheongMotif.chilbo,
    'c2_technology_ethics' => DancheongMotif.taegeuk,
    _ => DancheongMotif.lotus,
  };
}

String _baseOf(String packId) {
  final parts = packId.split('_');
  if (parts.isNotEmpty && int.tryParse(parts.last) != null) {
    return parts.sublist(0, parts.length - 1).join('_');
  }
  return packId;
}

class DancheongStamp extends StatefulWidget {
  final DancheongMotif motif;
  final double size;

  /// `true`면 찍히는 애니메이션 (scale 1.4 → 0.95 → 1.0, ~700ms).
  /// `false`면 즉시 1.0 정적.
  final bool animate;

  /// `true`면 stamped 효과 (찍힌 후 약간 ink-smudge feel — opacity 살짝 ↓).
  final bool stamped;

  const DancheongStamp({
    super.key,
    this.motif = DancheongMotif.lotus,
    this.size = 96,
    this.animate = false,
    this.stamped = false,
  });

  @override
  State<DancheongStamp> createState() => _DancheongStampState();
}

class _DancheongStampState extends State<DancheongStamp>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;
  late final Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    // overshoot → settle
    _scale = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(
          begin: 1.4,
          end: 0.95,
        ).chain(CurveTween(curve: Curves.easeOut)),
        weight: 60,
      ),
      TweenSequenceItem(
        tween: Tween(
          begin: 0.95,
          end: 1.0,
        ).chain(CurveTween(curve: Curves.easeOutBack)),
        weight: 40,
      ),
    ]).animate(_ctrl);
    _opacity = CurvedAnimation(parent: _ctrl, curve: const Interval(0, 0.5));

    if (widget.animate) {
      _ctrl.forward();
    } else {
      _ctrl.value = 1.0;
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  /// Motif → `stamps/stamp_*.png` 파일 slug.
  ///
  /// 2026-08-04: enum 이름과 파일명을 1:1 로 맞추면서 switch 를 없앴다
  /// (`geometric_octagon` → `octagon` 이 마지막 예외였다). 덕분에
  /// `test/dancheong_stamp_test.dart` 가 "모든 문양에 PNG 가 있다" 를
  /// enum 전수로 검사할 수 있다 — 새 문양을 추가하고 그림을 빠뜨리면 터진다.
  static String _assetSlug(DancheongMotif m) => 'stamp_${m.name}';

  @override
  Widget build(BuildContext context) {
    // PNG 자산 우선; 없으면(로드 실패) 기존 절차적 CustomPainter로 fallback.
    final painter = CustomPaint(
      size: Size(widget.size, widget.size),
      painter: _StampPainter(
        motif: widget.motif,
        intensity: widget.stamped ? 0.85 : 1.0,
      ),
    );
    // 원본 PNG는 1254x1254 — 62dp 노드에 그대로 디코드하면 장당 6.3MB.
    // cacheWidth 로 표시 크기(x DPR)에 맞춰 디코드해 경로 화면처럼 도장이
    // 수십 개 깔리는 곳에서도 이미지 캐시가 터지지 않게 한다.
    final cachePx = (widget.size * MediaQuery.devicePixelRatioOf(context))
        .round()
        .clamp(1, 1254);
    Widget stamp = Image.asset(
      'assets/illustrations/stamps/${_assetSlug(widget.motif)}.png',
      width: widget.size,
      height: widget.size,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.medium,
      cacheWidth: cachePx,
      cacheHeight: cachePx,
      errorBuilder: (_, __, ___) => painter,
    );
    // stamped 도장은 약간 무광 (ink absorbed effect).
    if (widget.stamped) {
      stamp = Opacity(opacity: 0.92, child: stamp);
    }

    if (!widget.animate) return stamp;
    return AnimatedBuilder(
      animation: _ctrl,
      child: stamp,
      builder: (ctx, child) {
        return Opacity(
          opacity: _opacity.value.clamp(0.0, 1.0),
          child: Transform.scale(scale: _scale.value, child: child),
        );
      },
    );
  }
}

class _StampPainter extends CustomPainter {
  final DancheongMotif motif;
  final double intensity;
  _StampPainter({required this.motif, required this.intensity});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final radius = math.min(cx, cy);

    // Outer red ring — Dancheong red lifted
    final red = const Color(0xFFC44F40).withValues(alpha: intensity);
    final cream = const Color(0xFFFAF6EC);

    final ringPaint = Paint()..color = red;
    canvas.drawCircle(Offset(cx, cy), radius, ringPaint);

    // Inner cream circle (paper surface)
    final innerR = radius * 0.78;
    canvas.drawCircle(Offset(cx, cy), innerR, Paint()..color = cream);

    // Motif
    final motifPaint = Paint()..color = red.withValues(alpha: intensity * 0.95);
    final accentPaint = Paint()
      ..color = const Color(
        0xFFD4A22E,
      ).withValues(alpha: intensity); // 황 (gold)
    final tealPaint = Paint()
      ..color = const Color(0xFF1F7A6B).withValues(alpha: intensity); // 녹청

    switch (motif) {
      case DancheongMotif.lotus:
        _drawLotus(canvas, cx, cy, innerR, motifPaint, accentPaint);
        break;
      case DancheongMotif.chrysanthemum:
        _drawChrysanthemum(canvas, cx, cy, innerR, motifPaint, accentPaint);
        break;
      case DancheongMotif.plum:
        _drawPlum(canvas, cx, cy, innerR, motifPaint, accentPaint);
        break;
      case DancheongMotif.bamboo:
        _drawBamboo(canvas, cx, cy, innerR, tealPaint, motifPaint);
        break;
      case DancheongMotif.cloud:
        _drawCloud(canvas, cx, cy, innerR, motifPaint);
        break;
      case DancheongMotif.octagon:
        _drawOctagon(canvas, cx, cy, innerR, motifPaint, accentPaint);
        break;
      case DancheongMotif.mountain:
        _drawMountain(canvas, cx, cy, innerR, motifPaint, tealPaint);
        break;
      case DancheongMotif.manja:
      // 신규 6종은 PNG 가 정본이고 이 painter 는 로드 실패 시 fallback 일 뿐이라,
      // 실루엣이 가장 가까운 기존 도형을 재사용한다. 전용 painter 를 6개 더
      // 쓰는 건 여기서 얻는 값에 비해 유지비가 크다.
      case DancheongMotif.taegeuk: // 삼태극 ≈ 바람개비
        _drawManja(canvas, cx, cy, innerR, motifPaint);
        break;
      case DancheongMotif.wave:
      case DancheongMotif.vine: // 물결·덩굴 ≈ 소용돌이
        _drawCloud(canvas, cx, cy, innerR, motifPaint);
        break;
      case DancheongMotif.chilbo:
      case DancheongMotif.gwigap: // 칠보·귀갑 ≈ 기하 격자
        _drawOctagon(canvas, cx, cy, innerR, motifPaint, accentPaint);
        break;
      case DancheongMotif.peony: // 모란 ≈ 겹꽃
        _drawLotus(canvas, cx, cy, innerR, motifPaint, accentPaint);
        break;
    }
  }

  // 8-petal lotus (radial)
  void _drawLotus(
    Canvas c,
    double cx,
    double cy,
    double r,
    Paint p,
    Paint accent,
  ) {
    const petals = 8;
    final petalLen = r * 0.55;
    final petalWidth = r * 0.18;
    for (int i = 0; i < petals; i++) {
      final angle = (i * 2 * math.pi / petals);
      c.save();
      c.translate(cx, cy);
      c.rotate(angle);
      final path = Path()
        ..moveTo(0, -r * 0.15)
        ..quadraticBezierTo(petalWidth, -r * 0.35, 0, -petalLen)
        ..quadraticBezierTo(-petalWidth, -r * 0.35, 0, -r * 0.15)
        ..close();
      c.drawPath(path, p);
      c.restore();
    }
    c.drawCircle(Offset(cx, cy), r * 0.16, accent);
  }

  void _drawChrysanthemum(
    Canvas c,
    double cx,
    double cy,
    double r,
    Paint p,
    Paint accent,
  ) {
    // double layer lotus, 12 petals each
    for (int layer = 0; layer < 2; layer++) {
      final petals = 12;
      final petalLen = layer == 0 ? r * 0.65 : r * 0.40;
      for (int i = 0; i < petals; i++) {
        final angle =
            (i * 2 * math.pi / petals) + (layer == 1 ? math.pi / petals : 0);
        c.save();
        c.translate(cx, cy);
        c.rotate(angle);
        final path = Path()
          ..moveTo(0, 0)
          ..quadraticBezierTo(r * 0.05, -r * 0.25, 0, -petalLen)
          ..quadraticBezierTo(-r * 0.05, -r * 0.25, 0, 0)
          ..close();
        c.drawPath(path, layer == 0 ? p : accent);
        c.restore();
      }
    }
    c.drawCircle(Offset(cx, cy), r * 0.12, p);
  }

  void _drawPlum(
    Canvas c,
    double cx,
    double cy,
    double r,
    Paint p,
    Paint accent,
  ) {
    // 5 round petals
    const petals = 5;
    final petalR = r * 0.28;
    final dist = r * 0.45;
    for (int i = 0; i < petals; i++) {
      final angle = (i * 2 * math.pi / petals) - math.pi / 2;
      final px = cx + math.cos(angle) * dist;
      final py = cy + math.sin(angle) * dist;
      c.drawCircle(Offset(px, py), petalR, p);
    }
    c.drawCircle(Offset(cx, cy), r * 0.18, accent);
  }

  void _drawBamboo(
    Canvas c,
    double cx,
    double cy,
    double r,
    Paint p,
    Paint dark,
  ) {
    // 3 vertical stalks
    final stalkW = r * 0.15;
    final stalkH = r * 1.4;
    final spacing = r * 0.4;
    for (int i = -1; i <= 1; i++) {
      final left = cx + i * spacing - stalkW / 2;
      final top = cy - stalkH / 2;
      c.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(left, top, stalkW, stalkH),
          const Radius.circular(4),
        ),
        p,
      );
      // segment lines
      for (int seg = 1; seg < 4; seg++) {
        final y = top + (stalkH / 4) * seg;
        c.drawLine(
          Offset(left, y),
          Offset(left + stalkW, y),
          Paint()
            ..color = dark.color
            ..strokeWidth = 1.5,
        );
      }
    }
  }

  void _drawCloud(Canvas c, double cx, double cy, double r, Paint p) {
    // 3-bump cloud scroll
    final base = cy + r * 0.2;
    c.drawCircle(Offset(cx - r * 0.4, base), r * 0.3, p);
    c.drawCircle(Offset(cx, base - r * 0.1), r * 0.4, p);
    c.drawCircle(Offset(cx + r * 0.4, base), r * 0.3, p);
    // bottom curl
    final path = Path()
      ..moveTo(cx - r * 0.6, base + r * 0.1)
      ..quadraticBezierTo(cx, base + r * 0.4, cx + r * 0.6, base + r * 0.1);
    c.drawPath(
      path,
      Paint()
        ..color = p.color
        ..strokeWidth = 3
        ..style = PaintingStyle.stroke,
    );
  }

  void _drawOctagon(
    Canvas c,
    double cx,
    double cy,
    double r,
    Paint p,
    Paint accent,
  ) {
    final sides = 8;
    final outer = r * 0.75;
    final inner = r * 0.5;
    final path = Path();
    for (int i = 0; i < sides; i++) {
      final angle = (i * 2 * math.pi / sides) - math.pi / 8;
      final x = cx + math.cos(angle) * outer;
      final y = cy + math.sin(angle) * outer;
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    c.drawPath(path, p);

    final innerPath = Path();
    for (int i = 0; i < sides; i++) {
      final angle = (i * 2 * math.pi / sides) - math.pi / 8;
      final x = cx + math.cos(angle) * inner;
      final y = cy + math.sin(angle) * inner;
      if (i == 0) {
        innerPath.moveTo(x, y);
      } else {
        innerPath.lineTo(x, y);
      }
    }
    innerPath.close();
    c.drawPath(innerPath, accent);
  }

  void _drawMountain(
    Canvas c,
    double cx,
    double cy,
    double r,
    Paint p,
    Paint accent,
  ) {
    // 3 triangular peaks (irworobongdo simplified)
    final base = cy + r * 0.5;
    // back peak
    final back = Path()
      ..moveTo(cx - r * 0.6, base)
      ..lineTo(cx, cy - r * 0.5)
      ..lineTo(cx + r * 0.6, base)
      ..close();
    c.drawPath(back, accent);
    // front peaks
    final left = Path()
      ..moveTo(cx - r * 0.7, base)
      ..lineTo(cx - r * 0.3, cy - r * 0.1)
      ..lineTo(cx + r * 0.1, base)
      ..close();
    c.drawPath(left, p);
    final right = Path()
      ..moveTo(cx - r * 0.1, base)
      ..lineTo(cx + r * 0.3, cy - r * 0.2)
      ..lineTo(cx + r * 0.7, base)
      ..close();
    c.drawPath(right, p);
  }

  void _drawManja(Canvas c, double cx, double cy, double r, Paint p) {
    // Korean traditional 卍 (manja) — geometric grid, NOT to be confused
    // with German nazi symbol (mirrored direction + 4 dots). For neutrality,
    // we draw a 4-petal pinwheel instead of the full manja fret.
    final arm = r * 0.55;
    final w = r * 0.2;
    for (int i = 0; i < 4; i++) {
      final angle = i * math.pi / 2;
      c.save();
      c.translate(cx, cy);
      c.rotate(angle);
      final path = Path()
        ..moveTo(0, -w / 2)
        ..lineTo(arm, -w / 2)
        ..lineTo(arm, -w * 1.5)
        ..lineTo(arm + w, 0)
        ..lineTo(arm, w * 1.5)
        ..lineTo(arm, w / 2)
        ..lineTo(0, w / 2)
        ..close();
      c.drawPath(path, p);
      c.restore();
    }
  }

  @override
  bool shouldRepaint(_StampPainter old) =>
      old.motif != motif || old.intensity != intensity;
}

// Convenience helper for theme-aware accent if needed in future.
@visibleForTesting
Color dancheongRed() => const Color(0xFFC44F40);
