import 'dart:math' as math;
import 'package:flutter/material.dart';

/// **Sori Mascot v3** — Korean cultural icons, 동글동글 cute.
///
/// 2 characters × 6 emotions:
/// - [Mascot.tiger]  호랑이 — 한국 상징, 88 Hodori 유산. 주연.
/// - [Mascot.magpie] 까치 + 갓 — 좋은 소식, 조선 민화 까치호랑이 풍속. 보조.
///
/// 사용:
/// ```dart
/// Mascot.tiger(emotion: MascotEmotion.celebrate, size: 96)
/// Mascot.magpie(emotion: MascotEmotion.smile, size: 64)
/// ```
///
/// **Legacy migration (v2 → v3)**: `Mascot.jieun` / `Mascot.minsu` 호출은
/// 자동으로 `Mascot.tiger`로 라우팅됨 (deprecated, 사용처 정리 후 제거 예정).
class Mascot extends StatelessWidget {
  final MascotKind kind;
  final MascotEmotion emotion;
  final double size;

  const Mascot({
    super.key,
    required this.kind,
    this.emotion = MascotEmotion.smile,
    this.size = 64,
  });

  // ── Primary constructors (v3) ─────────────────────────────────────────
  const Mascot.tiger({super.key, this.emotion = MascotEmotion.smile, this.size = 64})
      : kind = MascotKind.tiger;
  const Mascot.magpie({super.key, this.emotion = MascotEmotion.smile, this.size = 64})
      : kind = MascotKind.magpie;

  // ── Legacy constructors (deprecated — route to tiger) ─────────────────
  @Deprecated('Use Mascot.tiger — Jieun/Minsu painters retired in v3 design refresh')
  const Mascot.jieun({super.key, this.emotion = MascotEmotion.smile, this.size = 64})
      : kind = MascotKind.tiger;

  @Deprecated('Use Mascot.tiger — Jieun/Minsu painters retired in v3 design refresh')
  const Mascot.minsu({super.key, this.emotion = MascotEmotion.smile, this.size = 64})
      : kind = MascotKind.tiger;

  /// Speaker-code → Mascot. minsu/jieun (legacy) → tiger, kkachi/magpie → magpie.
  /// 알려지지 않은 speaker → null (caller가 emoji fallback 사용).
  static Widget? forSpeaker(String speaker,
      {MascotEmotion emotion = MascotEmotion.smile, double size = 56}) {
    switch (speaker) {
      case 'tiger':
      case 'horangi':
      case '호랑이':
      case 'jieun':   // legacy v2 → tiger
      case 'minsu':   // legacy v2 → tiger
        return Mascot.tiger(emotion: emotion, size: size);
      case 'kkachi':
      case 'magpie':
      case '까치':
        return Mascot.magpie(emotion: emotion, size: size);
      default:
        return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Route legacy kinds to tiger
    final effective = (kind == MascotKind.magpie) ? MascotKind.magpie : MascotKind.tiger;
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: effective == MascotKind.tiger
            ? _TigerPainter(emotion: emotion)
            : _MagpiePainter(emotion: emotion),
      ),
    );
  }
}

enum MascotKind {
  tiger,
  magpie,
  // Legacy aliases — code may still reference these. Painter ignores and uses tiger.
  @Deprecated('Use MascotKind.tiger') jieun,
  @Deprecated('Use MascotKind.tiger') minsu,
}

enum MascotEmotion { neutral, smile, worry, celebrate, sleepy, surprised }

// ═══════════════════════════════════════════════════════════════════════════
// Tiger Painter — Hodori 2026 (Kakao Friends roundness + 88 호돌이 친근함)
// ═══════════════════════════════════════════════════════════════════════════

class _TigerPainter extends CustomPainter {
  final MascotEmotion emotion;
  _TigerPainter({required this.emotion});

  // Palette
  static const _orange     = Color(0xFFFF8C42);  // body base
  static const _orangeDk   = Color(0xFFE66B1F);  // shadow (unused for now)
  static const _stripe     = Color(0xFF1A1A1A);  // stripes, eyes
  static const _faceLight  = Color(0xFFFFEED9);  // cream face center
  static const _white      = Color(0xFFFFFFFF);
  static const _pink       = Color(0xFFFF8E9E);  // nose, blush
  static const _pinkDeep   = Color(0xFFE85A75);  // inner ear
  static const _sparkle    = Color(0xFFFFC700);  // star eyes
  static const _highlight  = Color(0xFFFFFFFF);

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Order: ears → head → face center → forehead M-stripe → side stripes →
    //        blush → nose → eyes → mouth → (optional accessory)
    _drawEars(canvas, w, h);
    _drawHead(canvas, w, h);
    _drawFaceCenter(canvas, w, h);
    _drawStripes(canvas, w, h);
    _drawBlush(canvas, w, h);
    _drawNose(canvas, w, h);
    _drawEyes(canvas, w, h);
    _drawMouth(canvas, w, h);
  }

  // ── Ears (rounded triangles with pink inner) ─────────────────────────
  void _drawEars(Canvas canvas, double w, double h) {
    final orange = Paint()..color = _orange;
    final pink = Paint()..color = _pinkDeep;

    // Left ear
    final lEar = Path()
      ..moveTo(w * 0.18, h * 0.32)
      ..quadraticBezierTo(w * 0.20, h * 0.04, w * 0.36, h * 0.20)
      ..quadraticBezierTo(w * 0.30, h * 0.30, w * 0.18, h * 0.32)
      ..close();
    canvas.drawPath(lEar, orange);

    final lInner = Path()
      ..moveTo(w * 0.23, h * 0.26)
      ..quadraticBezierTo(w * 0.25, h * 0.13, w * 0.33, h * 0.22)
      ..quadraticBezierTo(w * 0.28, h * 0.27, w * 0.23, h * 0.26)
      ..close();
    canvas.drawPath(lInner, pink);

    // Right ear (mirror)
    final rEar = Path()
      ..moveTo(w * 0.82, h * 0.32)
      ..quadraticBezierTo(w * 0.80, h * 0.04, w * 0.64, h * 0.20)
      ..quadraticBezierTo(w * 0.70, h * 0.30, w * 0.82, h * 0.32)
      ..close();
    canvas.drawPath(rEar, orange);

    final rInner = Path()
      ..moveTo(w * 0.77, h * 0.26)
      ..quadraticBezierTo(w * 0.75, h * 0.13, w * 0.67, h * 0.22)
      ..quadraticBezierTo(w * 0.72, h * 0.27, w * 0.77, h * 0.26)
      ..close();
    canvas.drawPath(rInner, pink);
  }

  // ── Head (big orange circle) ─────────────────────────────────────────
  void _drawHead(Canvas canvas, double w, double h) {
    canvas.drawCircle(
      Offset(w * 0.5, h * 0.56),
      w * 0.40,
      Paint()..color = _orange,
    );
  }

  // ── Face center (cream oval for eye/nose area) ───────────────────────
  void _drawFaceCenter(Canvas canvas, double w, double h) {
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(w * 0.5, h * 0.66),
        width: w * 0.50,
        height: h * 0.42,
      ),
      Paint()..color = _faceLight,
    );
  }

  // ── Stripes — forehead M (Hodori) + 3 side stripes per cheek ─────────
  void _drawStripes(Canvas canvas, double w, double h) {
    final paint = Paint()
      ..color = _stripe
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.030
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    // Forehead M-stripe (Hodori signature)
    final m = Path()
      ..moveTo(w * 0.43, h * 0.30)
      ..lineTo(w * 0.46, h * 0.40)
      ..lineTo(w * 0.50, h * 0.32)
      ..lineTo(w * 0.54, h * 0.40)
      ..lineTo(w * 0.57, h * 0.30);
    canvas.drawPath(m, paint);

    // Left cheek stripes
    canvas.drawLine(Offset(w * 0.13, h * 0.52), Offset(w * 0.20, h * 0.56), paint);
    canvas.drawLine(Offset(w * 0.10, h * 0.60), Offset(w * 0.18, h * 0.64), paint);
    canvas.drawLine(Offset(w * 0.12, h * 0.68), Offset(w * 0.20, h * 0.71), paint);

    // Right cheek stripes
    canvas.drawLine(Offset(w * 0.87, h * 0.52), Offset(w * 0.80, h * 0.56), paint);
    canvas.drawLine(Offset(w * 0.90, h * 0.60), Offset(w * 0.82, h * 0.64), paint);
    canvas.drawLine(Offset(w * 0.88, h * 0.68), Offset(w * 0.80, h * 0.71), paint);
  }

  // ── Blush (cheeks) ───────────────────────────────────────────────────
  void _drawBlush(Canvas canvas, double w, double h) {
    final paint = Paint()..color = _pink.withValues(alpha: 0.42);
    canvas.drawCircle(Offset(w * 0.30, h * 0.71), w * 0.055, paint);
    canvas.drawCircle(Offset(w * 0.70, h * 0.71), w * 0.055, paint);
  }

  // ── Nose (rounded triangle pointing down) ────────────────────────────
  void _drawNose(Canvas canvas, double w, double h) {
    final paint = Paint()..color = _stripe;
    final nose = Path()
      ..moveTo(w * 0.45, h * 0.66)
      ..quadraticBezierTo(w * 0.50, h * 0.62, w * 0.55, h * 0.66)
      ..quadraticBezierTo(w * 0.52, h * 0.74, w * 0.50, h * 0.75)
      ..quadraticBezierTo(w * 0.48, h * 0.74, w * 0.45, h * 0.66)
      ..close();
    canvas.drawPath(nose, paint);
  }

  // ── Eyes (6 emotion variants) ────────────────────────────────────────
  void _drawEyes(Canvas canvas, double w, double h) {
    final eyeY = h * 0.57;
    final lx = w * 0.36;
    final rx = w * 0.64;

    switch (emotion) {
      case MascotEmotion.smile:
        // ^_^ curved arcs
        final stroke = Paint()
          ..color = _stripe
          ..style = PaintingStyle.stroke
          ..strokeWidth = w * 0.038
          ..strokeCap = StrokeCap.round;
        canvas.drawArc(
          Rect.fromCircle(center: Offset(lx, eyeY), radius: w * 0.055),
          math.pi + 0.3, math.pi - 0.6, false, stroke,
        );
        canvas.drawArc(
          Rect.fromCircle(center: Offset(rx, eyeY), radius: w * 0.055),
          math.pi + 0.3, math.pi - 0.6, false, stroke,
        );
        break;

      case MascotEmotion.neutral:
        // Round filled eyes with white highlight
        final dark = Paint()..color = _stripe;
        canvas.drawCircle(Offset(lx, eyeY), w * 0.045, dark);
        canvas.drawCircle(Offset(rx, eyeY), w * 0.045, dark);
        final hi = Paint()..color = _highlight;
        canvas.drawCircle(Offset(lx + w * 0.014, eyeY - h * 0.012), w * 0.014, hi);
        canvas.drawCircle(Offset(rx + w * 0.014, eyeY - h * 0.012), w * 0.014, hi);
        break;

      case MascotEmotion.celebrate:
        // Star sparkles
        _drawSparkle(canvas, Offset(lx, eyeY), w * 0.060);
        _drawSparkle(canvas, Offset(rx, eyeY), w * 0.060);
        break;

      case MascotEmotion.worry:
        // Small eyes + downward brows
        final dark = Paint()..color = _stripe;
        canvas.drawCircle(Offset(lx, eyeY), w * 0.034, dark);
        canvas.drawCircle(Offset(rx, eyeY), w * 0.034, dark);
        final brow = Paint()
          ..color = _stripe
          ..style = PaintingStyle.stroke
          ..strokeWidth = w * 0.034
          ..strokeCap = StrokeCap.round;
        canvas.drawLine(
          Offset(lx - w * 0.06, eyeY - h * 0.09),
          Offset(lx + w * 0.04, eyeY - h * 0.12),
          brow,
        );
        canvas.drawLine(
          Offset(rx + w * 0.06, eyeY - h * 0.09),
          Offset(rx - w * 0.04, eyeY - h * 0.12),
          brow,
        );
        break;

      case MascotEmotion.surprised:
        // Big round eyes with prominent highlight
        final dark = Paint()..color = _stripe;
        canvas.drawCircle(Offset(lx, eyeY), w * 0.055, dark);
        canvas.drawCircle(Offset(rx, eyeY), w * 0.055, dark);
        final hi = Paint()..color = _highlight;
        canvas.drawCircle(Offset(lx + w * 0.018, eyeY - h * 0.018), w * 0.020, hi);
        canvas.drawCircle(Offset(rx + w * 0.018, eyeY - h * 0.018), w * 0.020, hi);
        break;

      case MascotEmotion.sleepy:
        // Horizontal lines + z above ear
        final line = Paint()
          ..color = _stripe
          ..style = PaintingStyle.stroke
          ..strokeWidth = w * 0.038
          ..strokeCap = StrokeCap.round;
        canvas.drawLine(
          Offset(lx - w * 0.05, eyeY),
          Offset(lx + w * 0.05, eyeY),
          line,
        );
        canvas.drawLine(
          Offset(rx - w * 0.05, eyeY),
          Offset(rx + w * 0.05, eyeY),
          line,
        );
        _drawZ(canvas, w, h, w * 0.78, h * 0.12);
        break;
    }
  }

  // ── Mouth (6 emotion variants) ───────────────────────────────────────
  void _drawMouth(Canvas canvas, double w, double h) {
    final mouthY = h * 0.82;
    final stroke = Paint()
      ..color = _stripe
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.030
      ..strokeCap = StrokeCap.round;

    switch (emotion) {
      case MascotEmotion.neutral:
        canvas.drawLine(
          Offset(w * 0.46, mouthY),
          Offset(w * 0.54, mouthY),
          stroke,
        );
        break;

      case MascotEmotion.smile:
        // Two arcs (split smile under nose — 호랑이 입 특징)
        canvas.drawArc(
          Rect.fromCircle(center: Offset(w * 0.43, mouthY - h * 0.005), radius: w * 0.060),
          0.0, math.pi - 0.6, false, stroke,
        );
        canvas.drawArc(
          Rect.fromCircle(center: Offset(w * 0.57, mouthY - h * 0.005), radius: w * 0.060),
          0.6, math.pi - 0.6, false, stroke,
        );
        break;

      case MascotEmotion.celebrate:
        // Wide open with pink tongue
        final mouth = Path()
          ..moveTo(w * 0.40, mouthY - h * 0.01)
          ..quadraticBezierTo(w * 0.5, mouthY + h * 0.085, w * 0.60, mouthY - h * 0.01)
          ..close();
        canvas.drawPath(mouth, Paint()..color = _stripe);
        canvas.drawOval(
          Rect.fromCenter(
            center: Offset(w * 0.5, mouthY + h * 0.025),
            width: w * 0.115, height: h * 0.028,
          ),
          Paint()..color = _pink,
        );
        break;

      case MascotEmotion.worry:
        canvas.drawArc(
          Rect.fromCenter(
            center: Offset(w * 0.5, mouthY + h * 0.04),
            width: w * 0.16, height: h * 0.075,
          ),
          math.pi + 0.3, math.pi - 0.6, false, stroke,
        );
        break;

      case MascotEmotion.surprised:
        canvas.drawCircle(Offset(w * 0.5, mouthY), w * 0.030, Paint()..color = _stripe);
        break;

      case MascotEmotion.sleepy:
        canvas.drawOval(
          Rect.fromCenter(
            center: Offset(w * 0.5, mouthY),
            width: w * 0.07, height: h * 0.025,
          ),
          Paint()..color = _stripe,
        );
        break;
    }
  }

  // ── Helpers ──────────────────────────────────────────────────────────
  void _drawSparkle(Canvas canvas, Offset c, double r) {
    final paint = Paint()
      ..color = _sparkle
      ..style = PaintingStyle.stroke
      ..strokeWidth = r * 0.40
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(c.dx - r, c.dy), Offset(c.dx + r, c.dy), paint);
    canvas.drawLine(Offset(c.dx, c.dy - r), Offset(c.dx, c.dy + r), paint);
    final d = r * 0.6;
    canvas.drawLine(Offset(c.dx - d, c.dy - d), Offset(c.dx + d, c.dy + d), paint);
    canvas.drawLine(Offset(c.dx - d, c.dy + d), Offset(c.dx + d, c.dy - d), paint);
  }

  void _drawZ(Canvas canvas, double w, double h, double cx, double cy) {
    final tp = TextPainter(
      text: TextSpan(
        text: 'z',
        style: TextStyle(
          fontFamily: 'Pretendard',
          color: _stripe.withValues(alpha: 0.55),
          fontSize: w * 0.14,
          fontWeight: FontWeight.w900,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(cx - tp.width / 2, cy));
  }

  @override
  bool shouldRepaint(_TigerPainter old) => old.emotion != emotion;
}

// ═══════════════════════════════════════════════════════════════════════════
// Magpie + Gat Painter — 까치호랑이 풍속 보조 캐릭터
// 3/4 profile view (한쪽 눈 + 날개 살짝)
// ═══════════════════════════════════════════════════════════════════════════

class _MagpiePainter extends CustomPainter {
  final MascotEmotion emotion;
  _MagpiePainter({required this.emotion});

  // Palette
  static const _bodyDark  = Color(0xFF0D0D0D);   // 검정 몸 + 날개
  static const _bodyLight = Color(0xFFF4F4F4);   // 흰 배 + 볼
  static const _beak      = Color(0xFFE8A547);   // 부리 (오렌지-옐로)
  static const _gat       = Color(0xFF2A2A2A);   // 갓 회갈색
  static const _gatBand   = Color(0xFFFFD700);   // 갓 금띠
  static const _eye       = Color(0xFFFFFFFF);
  static const _pupil     = Color(0xFF000000);
  static const _sparkle   = Color(0xFFFFC700);
  static const _blush     = Color(0xFFFF8E9E);

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Render order: tail → wing → body → belly → head → beak → eye → blush → gat (top)
    _drawTail(canvas, w, h);
    _drawWing(canvas, w, h);
    _drawBody(canvas, w, h);
    _drawBelly(canvas, w, h);
    _drawHead(canvas, w, h);
    _drawBeak(canvas, w, h);
    _drawEye(canvas, w, h);
    _drawBlush(canvas, w, h);
    _drawGat(canvas, w, h);

    if (emotion == MascotEmotion.sleepy) _drawZ(canvas, w, h);
    if (emotion == MascotEmotion.celebrate) _drawCelebrateSparkles(canvas, w, h);
  }

  // ── Body (큰 검정 타원) ──────────────────────────────────────────────
  void _drawBody(Canvas canvas, double w, double h) {
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(w * 0.50, h * 0.65),
        width: w * 0.62,
        height: h * 0.46,
      ),
      Paint()..color = _bodyDark,
    );
  }

  // ── Belly (흰색 inverted U) ──────────────────────────────────────────
  void _drawBelly(Canvas canvas, double w, double h) {
    final belly = Path()
      ..moveTo(w * 0.32, h * 0.65)
      ..quadraticBezierTo(w * 0.50, h * 0.92, w * 0.68, h * 0.65)
      ..quadraticBezierTo(w * 0.50, h * 0.78, w * 0.32, h * 0.65)
      ..close();
    canvas.drawPath(belly, Paint()..color = _bodyLight);
  }

  // ── Head ─────────────────────────────────────────────────────────────
  void _drawHead(Canvas canvas, double w, double h) {
    canvas.drawCircle(
      Offset(w * 0.50, h * 0.42),
      w * 0.24,
      Paint()..color = _bodyDark,
    );
    // 흰 볼 (3/4 view — 오른쪽만 보임)
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(w * 0.58, h * 0.46),
        width: w * 0.16,
        height: h * 0.18,
      ),
      Paint()..color = _bodyLight,
    );
  }

  // ── Beak (작은 오렌지 삼각형, 정면 약간 오른쪽) ─────────────────────
  void _drawBeak(Canvas canvas, double w, double h) {
    final beakOpen = emotion == MascotEmotion.celebrate || emotion == MascotEmotion.surprised;
    final paint = Paint()..color = _beak;

    if (beakOpen) {
      // Open beak (큰 < 모양)
      final upper = Path()
        ..moveTo(w * 0.60, h * 0.46)
        ..lineTo(w * 0.78, h * 0.44)
        ..lineTo(w * 0.62, h * 0.50)
        ..close();
      canvas.drawPath(upper, paint);

      final lower = Path()
        ..moveTo(w * 0.62, h * 0.50)
        ..lineTo(w * 0.78, h * 0.55)
        ..lineTo(w * 0.60, h * 0.52)
        ..close();
      canvas.drawPath(lower, paint);
    } else {
      // Closed beak (작은 다이아몬드)
      final beak = Path()
        ..moveTo(w * 0.60, h * 0.47)
        ..lineTo(w * 0.74, h * 0.49)
        ..lineTo(w * 0.60, h * 0.51)
        ..close();
      canvas.drawPath(beak, paint);
    }
  }

  // ── Eye (3/4 view — 한쪽만, emotion 따라) ────────────────────────────
  void _drawEye(Canvas canvas, double w, double h) {
    final cx = w * 0.55;
    final cy = h * 0.40;

    switch (emotion) {
      case MascotEmotion.smile:
        // 호 모양 (^ )
        final stroke = Paint()
          ..color = _pupil
          ..style = PaintingStyle.stroke
          ..strokeWidth = w * 0.030
          ..strokeCap = StrokeCap.round;
        canvas.drawArc(
          Rect.fromCircle(center: Offset(cx, cy), radius: w * 0.048),
          math.pi + 0.3, math.pi - 0.6, false, stroke,
        );
        break;

      case MascotEmotion.neutral:
        canvas.drawCircle(Offset(cx, cy), w * 0.038, Paint()..color = _eye);
        canvas.drawCircle(Offset(cx, cy), w * 0.022, Paint()..color = _pupil);
        canvas.drawCircle(Offset(cx + w * 0.010, cy - h * 0.008), w * 0.009, Paint()..color = _eye);
        break;

      case MascotEmotion.celebrate:
        _drawSparkle(canvas, Offset(cx, cy), w * 0.05);
        break;

      case MascotEmotion.worry:
        canvas.drawCircle(Offset(cx, cy), w * 0.030, Paint()..color = _pupil);
        // 처진 눈썹
        final brow = Paint()
          ..color = _pupil
          ..style = PaintingStyle.stroke
          ..strokeWidth = w * 0.026
          ..strokeCap = StrokeCap.round;
        canvas.drawLine(
          Offset(cx - w * 0.06, cy - h * 0.08),
          Offset(cx + w * 0.05, cy - h * 0.11),
          brow,
        );
        break;

      case MascotEmotion.surprised:
        canvas.drawCircle(Offset(cx, cy), w * 0.050, Paint()..color = _eye);
        canvas.drawCircle(Offset(cx, cy), w * 0.030, Paint()..color = _pupil);
        canvas.drawCircle(Offset(cx + w * 0.015, cy - h * 0.012), w * 0.014, Paint()..color = _eye);
        break;

      case MascotEmotion.sleepy:
        final line = Paint()
          ..color = _pupil
          ..style = PaintingStyle.stroke
          ..strokeWidth = w * 0.030
          ..strokeCap = StrokeCap.round;
        canvas.drawLine(
          Offset(cx - w * 0.045, cy),
          Offset(cx + w * 0.045, cy),
          line,
        );
        break;
    }
  }

  // ── Blush (cheek) ────────────────────────────────────────────────────
  void _drawBlush(Canvas canvas, double w, double h) {
    canvas.drawCircle(
      Offset(w * 0.60, h * 0.52),
      w * 0.045,
      Paint()..color = _blush.withValues(alpha: 0.35),
    );
  }

  // ── Wing (검정 날개 살짝 보임, 흰 깃 끝) ─────────────────────────────
  void _drawWing(Canvas canvas, double w, double h) {
    final wing = Path()
      ..moveTo(w * 0.25, h * 0.60)
      ..quadraticBezierTo(w * 0.10, h * 0.70, w * 0.18, h * 0.82)
      ..quadraticBezierTo(w * 0.28, h * 0.78, w * 0.30, h * 0.72)
      ..lineTo(w * 0.32, h * 0.65)
      ..close();
    canvas.drawPath(wing, Paint()..color = _bodyDark);

    // 흰색 깃 끝 (까치 특징)
    final tip = Path()
      ..moveTo(w * 0.16, h * 0.80)
      ..lineTo(w * 0.21, h * 0.82)
      ..lineTo(w * 0.23, h * 0.78)
      ..close();
    canvas.drawPath(tip, Paint()..color = _bodyLight);
  }

  // ── Tail (긴 깃 뒤쪽) ────────────────────────────────────────────────
  void _drawTail(Canvas canvas, double w, double h) {
    final tail = Path()
      ..moveTo(w * 0.20, h * 0.65)
      ..lineTo(w * 0.02, h * 0.78)
      ..lineTo(w * 0.05, h * 0.85)
      ..lineTo(w * 0.22, h * 0.74)
      ..close();
    canvas.drawPath(tail, Paint()..color = _bodyDark);
    // 흰색 깃 stripe
    final stripe = Paint()
      ..color = _bodyLight
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.012;
    canvas.drawLine(Offset(w * 0.06, h * 0.82), Offset(w * 0.20, h * 0.71), stripe);
  }

  // ── Gat (전통 모자) — 회갈색 + 금띠 ──────────────────────────────────
  void _drawGat(Canvas canvas, double w, double h) {
    final gatFill = Paint()..color = _gat;
    final band = Paint()..color = _gatBand;

    // 챙 (brim, 넓은 ellipse)
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(w * 0.50, h * 0.20),
        width: w * 0.72,
        height: h * 0.07,
      ),
      gatFill,
    );

    // Crown (cylinder)
    final crown = Path()
      ..moveTo(w * 0.36, h * 0.20)
      ..lineTo(w * 0.36, h * 0.05)
      ..quadraticBezierTo(w * 0.50, h * 0.02, w * 0.64, h * 0.05)
      ..lineTo(w * 0.64, h * 0.20)
      ..close();
    canvas.drawPath(crown, gatFill);

    // 금색 띠 (얇은 가로 stripe at crown base)
    canvas.drawRect(
      Rect.fromCenter(
        center: Offset(w * 0.50, h * 0.19),
        width: w * 0.30,
        height: h * 0.015,
      ),
      band,
    );

    // 갓끈 (chin strap, 양옆)
    final strap = Paint()
      ..color = _gat
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.012;
    canvas.drawLine(Offset(w * 0.30, h * 0.22), Offset(w * 0.36, h * 0.40), strap);
    canvas.drawLine(Offset(w * 0.70, h * 0.22), Offset(w * 0.64, h * 0.40), strap);
  }

  // ── Helpers ──────────────────────────────────────────────────────────
  void _drawSparkle(Canvas canvas, Offset c, double r) {
    final paint = Paint()
      ..color = _sparkle
      ..style = PaintingStyle.stroke
      ..strokeWidth = r * 0.40
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(c.dx - r, c.dy), Offset(c.dx + r, c.dy), paint);
    canvas.drawLine(Offset(c.dx, c.dy - r), Offset(c.dx, c.dy + r), paint);
    final d = r * 0.6;
    canvas.drawLine(Offset(c.dx - d, c.dy - d), Offset(c.dx + d, c.dy + d), paint);
    canvas.drawLine(Offset(c.dx - d, c.dy + d), Offset(c.dx + d, c.dy - d), paint);
  }

  void _drawCelebrateSparkles(Canvas canvas, double w, double h) {
    // 작은 sparkles 주변에 (좋은 소식 분위기)
    _drawSparkle(canvas, Offset(w * 0.20, h * 0.30), w * 0.030);
    _drawSparkle(canvas, Offset(w * 0.85, h * 0.30), w * 0.030);
    _drawSparkle(canvas, Offset(w * 0.85, h * 0.60), w * 0.025);
  }

  void _drawZ(Canvas canvas, double w, double h) {
    final tp = TextPainter(
      text: TextSpan(
        text: 'z',
        style: TextStyle(
          fontFamily: 'Pretendard',
          color: _bodyDark.withValues(alpha: 0.6),
          fontSize: w * 0.14,
          fontWeight: FontWeight.w900,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(w * 0.78, h * 0.10));
  }

  @override
  bool shouldRepaint(_MagpiePainter old) => old.emotion != emotion;
}
