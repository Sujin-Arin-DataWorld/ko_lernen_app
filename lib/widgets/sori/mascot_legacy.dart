import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Sori 마스코트 — 2 캐릭터 × 6 감정.
///
/// [Mascot.jieun] 지은 — 동그란 안경, 긴 검정 머리 (Sujin 기반 추상화)
/// [Mascot.minsu] 민수 — 올리브 야구 모자, 짧은 머리 (남친 기반 추상화)
///
/// 사진 그대로의 초상이 아니라 핵심 특징(머리·안경·모자)만 추출한 카툰 아바타.
///
/// 사용:
/// ```dart
/// Mascot.jieun(emotion: MascotEmotion.smile, size: 64)
/// Mascot.minsu(emotion: MascotEmotion.celebrate, size: 96)
/// ```
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

  const Mascot.jieun({super.key, this.emotion = MascotEmotion.smile, this.size = 64})
      : kind = MascotKind.jieun;

  const Mascot.minsu({super.key, this.emotion = MascotEmotion.smile, this.size = 64})
      : kind = MascotKind.minsu;

  /// Speaker-code → Mascot. minsu/jieun 외엔 null (emoji fallback에 사용).
  static Widget? forSpeaker(String speaker, {MascotEmotion emotion = MascotEmotion.smile, double size = 56}) {
    switch (speaker) {
      case 'minsu': return Mascot.minsu(emotion: emotion, size: size);
      case 'jieun': return Mascot.jieun(emotion: emotion, size: size);
      default:      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _MascotPainter(kind: kind, emotion: emotion)),
    );
  }
}

enum MascotKind    { jieun, minsu }
enum MascotEmotion { neutral, smile, worry, celebrate, sleepy, surprised }

// ─────────────────────────────────────────────────────────────────────────
// Painter
// ─────────────────────────────────────────────────────────────────────────

class _MascotPainter extends CustomPainter {
  final MascotKind kind;
  final MascotEmotion emotion;

  _MascotPainter({required this.kind, required this.emotion});

  // Palette
  static const _skin       = Color(0xFFFBD9B8);
  static const _blush      = Color(0xFFFFB3B3);
  static const _hairDark   = Color(0xFF1F1A17);
  static const _hairLight  = Color(0xFFB89373);
  static const _capOlive   = Color(0xFF93A26A);
  static const _capOliveDk = Color(0xFF7A8956);
  static const _glasses    = Color(0xFF1A1A1A);
  static const _mouth      = Color(0xFF5C3D2E);
  static const _sparkle    = Color(0xFFFFC700);
  static const _highlight  = Color(0xFFFFFFFF);

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Render order: hair (back) → face → blush → accessory → eyes → mouth
    _drawHair(canvas, w, h);
    _drawFace(canvas, w, h);
    _drawBlush(canvas, w, h);
    if (kind == MascotKind.jieun) {
      _drawGlasses(canvas, w, h);
    } else {
      _drawCap(canvas, w, h);
    }
    _drawEyes(canvas, w, h);
    _drawMouth(canvas, w, h);
  }

  // ── Hair (Jieun: long parted black · Minsu: under-cap tuft) ──────────
  void _drawHair(Canvas canvas, double w, double h) {
    final paint = Paint();

    if (kind == MascotKind.jieun) {
      paint.color = _hairDark;
      // 긴 머리 (가운데 가르마, 양쪽 폭포)
      final hair = Path()
        ..moveTo(w * 0.14, h * 0.48)
        ..quadraticBezierTo(w * 0.5, h * 0.04, w * 0.86, h * 0.48)
        ..lineTo(w * 0.86, h * 0.96)
        ..lineTo(w * 0.72, h * 0.98)
        ..lineTo(w * 0.72, h * 0.56)
        ..lineTo(w * 0.28, h * 0.56)
        ..lineTo(w * 0.28, h * 0.98)
        ..lineTo(w * 0.14, h * 0.96)
        ..close();
      canvas.drawPath(hair, paint);

      // 가르마 (살짝 살색 보이게)
      paint.color = _skin;
      final part = Path()
        ..moveTo(w * 0.485, h * 0.18)
        ..lineTo(w * 0.515, h * 0.18)
        ..lineTo(w * 0.51, h * 0.36)
        ..lineTo(w * 0.49, h * 0.36)
        ..close();
      canvas.drawPath(part, paint);
    } else {
      paint.color = _hairLight;
      // 모자 밑으로 살짝 보이는 옆머리·뒷머리
      final hair = Path()
        ..moveTo(w * 0.18, h * 0.48)
        ..lineTo(w * 0.18, h * 0.62)
        ..quadraticBezierTo(w * 0.16, h * 0.55, w * 0.20, h * 0.48)
        ..close();
      canvas.drawPath(hair, paint);

      final hair2 = Path()
        ..moveTo(w * 0.82, h * 0.48)
        ..lineTo(w * 0.82, h * 0.62)
        ..quadraticBezierTo(w * 0.84, h * 0.55, w * 0.80, h * 0.48)
        ..close();
      canvas.drawPath(hair2, paint);
    }
  }

  // ── Face oval ────────────────────────────────────────────────────────
  void _drawFace(Canvas canvas, double w, double h) {
    final paint = Paint()..color = _skin;
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(w * 0.5, h * 0.55),
        width: w * 0.60,
        height: h * 0.70,
      ),
      paint,
    );
  }

  void _drawBlush(Canvas canvas, double w, double h) {
    final paint = Paint()..color = _blush.withValues(alpha: 0.35);
    canvas.drawCircle(Offset(w * 0.30, h * 0.66), w * 0.055, paint);
    canvas.drawCircle(Offset(w * 0.70, h * 0.66), w * 0.055, paint);
  }

  // ── Glasses (Jieun) ──────────────────────────────────────────────────
  void _drawGlasses(Canvas canvas, double w, double h) {
    final frame = Paint()
      ..color = _glasses
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.035
      ..strokeCap = StrokeCap.round;

    final eyeY = h * 0.58;
    final r = w * 0.115;

    canvas.drawCircle(Offset(w * 0.36, eyeY), r, frame);
    canvas.drawCircle(Offset(w * 0.64, eyeY), r, frame);
    canvas.drawLine(
      Offset(w * 0.36 + r, eyeY),
      Offset(w * 0.64 - r, eyeY),
      frame,
    );
  }

  // ── Cap (Minsu, olive Yankees-ish) ───────────────────────────────────
  void _drawCap(Canvas canvas, double w, double h) {
    final cap = Paint()..color = _capOlive;
    final shadow = Paint()..color = _capOliveDk;

    // 모자 돔
    final dome = Path()
      ..moveTo(w * 0.14, h * 0.50)
      ..quadraticBezierTo(w * 0.5, h * 0.08, w * 0.86, h * 0.50)
      ..lineTo(w * 0.84, h * 0.54)
      ..quadraticBezierTo(w * 0.5, h * 0.20, w * 0.16, h * 0.54)
      ..close();
    canvas.drawPath(dome, cap);

    // 모자 챙 (앞으로)
    final brim = Path()
      ..moveTo(w * 0.46, h * 0.52)
      ..quadraticBezierTo(w * 0.75, h * 0.56, w * 0.94, h * 0.58)
      ..lineTo(w * 0.94, h * 0.62)
      ..quadraticBezierTo(w * 0.75, h * 0.60, w * 0.46, h * 0.56)
      ..close();
    canvas.drawPath(brim, shadow);

    // NY 로고 (간단 원)
    final logo = Paint()..color = _highlight;
    canvas.drawCircle(Offset(w * 0.46, h * 0.32), w * 0.045, logo);
    final logoDark = Paint()..color = _capOliveDk;
    final logoFont = TextPainter(
      text: const TextSpan(text: 'N', style: TextStyle(
        color: _capOliveDk, fontSize: 8, fontWeight: FontWeight.w900,
      )),
      textDirection: TextDirection.ltr,
    )..layout();
    logoFont.paint(canvas, Offset(w * 0.46 - logoFont.width / 2, h * 0.32 - logoFont.height / 2));
    // (logoDark unused — keep paint var to avoid lint; safe noop)
    canvas.drawCircle(Offset(w * 0.46, h * 0.32), 0, logoDark);
  }

  // ── Eyes ─────────────────────────────────────────────────────────────
  void _drawEyes(Canvas canvas, double w, double h) {
    final dark = Paint()..color = _hairDark;
    final eyeY = h * 0.58;
    final lx = w * 0.36;
    final rx = w * 0.64;

    switch (emotion) {
      case MascotEmotion.neutral:
        canvas.drawCircle(Offset(lx, eyeY), w * 0.025, dark);
        canvas.drawCircle(Offset(rx, eyeY), w * 0.025, dark);
        break;

      case MascotEmotion.smile:
        final stroke = Paint()
          ..color = _hairDark
          ..style = PaintingStyle.stroke
          ..strokeWidth = w * 0.030
          ..strokeCap = StrokeCap.round;
        canvas.drawArc(
          Rect.fromCircle(center: Offset(lx, eyeY), radius: w * 0.045),
          math.pi + 0.4, math.pi - 0.8, false, stroke,
        );
        canvas.drawArc(
          Rect.fromCircle(center: Offset(rx, eyeY), radius: w * 0.045),
          math.pi + 0.4, math.pi - 0.8, false, stroke,
        );
        break;

      case MascotEmotion.worry:
        canvas.drawCircle(Offset(lx, eyeY), w * 0.028, dark);
        canvas.drawCircle(Offset(rx, eyeY), w * 0.028, dark);
        final brow = Paint()
          ..color = _hairDark
          ..style = PaintingStyle.stroke
          ..strokeWidth = w * 0.025
          ..strokeCap = StrokeCap.round;
        canvas.drawLine(
          Offset(lx - w * 0.05, eyeY - h * 0.07),
          Offset(lx + w * 0.04, eyeY - h * 0.10),
          brow,
        );
        canvas.drawLine(
          Offset(rx + w * 0.05, eyeY - h * 0.07),
          Offset(rx - w * 0.04, eyeY - h * 0.10),
          brow,
        );
        break;

      case MascotEmotion.celebrate:
        _drawSparkle(canvas, Offset(lx, eyeY), w * 0.055);
        _drawSparkle(canvas, Offset(rx, eyeY), w * 0.055);
        break;

      case MascotEmotion.sleepy:
        final line = Paint()
          ..color = _hairDark
          ..style = PaintingStyle.stroke
          ..strokeWidth = w * 0.030
          ..strokeCap = StrokeCap.round;
        canvas.drawLine(Offset(lx - w * 0.05, eyeY), Offset(lx + w * 0.05, eyeY), line);
        canvas.drawLine(Offset(rx - w * 0.05, eyeY), Offset(rx + w * 0.05, eyeY), line);
        break;

      case MascotEmotion.surprised:
        canvas.drawCircle(Offset(lx, eyeY), w * 0.040, dark);
        canvas.drawCircle(Offset(rx, eyeY), w * 0.040, dark);
        final hi = Paint()..color = _highlight;
        canvas.drawCircle(Offset(lx + w * 0.012, eyeY - h * 0.012), w * 0.014, hi);
        canvas.drawCircle(Offset(rx + w * 0.012, eyeY - h * 0.012), w * 0.014, hi);
        break;
    }
  }

  void _drawSparkle(Canvas canvas, Offset c, double r) {
    final paint = Paint()
      ..color = _sparkle
      ..style = PaintingStyle.stroke
      ..strokeWidth = r * 0.45
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(c.dx - r, c.dy), Offset(c.dx + r, c.dy), paint);
    canvas.drawLine(Offset(c.dx, c.dy - r), Offset(c.dx, c.dy + r), paint);
    // diagonal small
    final diag = r * 0.6;
    canvas.drawLine(Offset(c.dx - diag, c.dy - diag), Offset(c.dx + diag, c.dy + diag), paint);
    canvas.drawLine(Offset(c.dx - diag, c.dy + diag), Offset(c.dx + diag, c.dy - diag), paint);
  }

  // ── Mouth ────────────────────────────────────────────────────────────
  void _drawMouth(Canvas canvas, double w, double h) {
    final mouthY = h * 0.80;

    switch (emotion) {
      case MascotEmotion.neutral:
        final line = Paint()
          ..color = _mouth
          ..style = PaintingStyle.stroke
          ..strokeWidth = w * 0.022
          ..strokeCap = StrokeCap.round;
        canvas.drawLine(Offset(w * 0.45, mouthY), Offset(w * 0.55, mouthY), line);
        break;

      case MascotEmotion.smile:
        final stroke = Paint()
          ..color = _mouth
          ..style = PaintingStyle.stroke
          ..strokeWidth = w * 0.030
          ..strokeCap = StrokeCap.round;
        canvas.drawArc(
          Rect.fromCenter(
            center: Offset(w * 0.5, mouthY - h * 0.012),
            width: w * 0.22, height: h * 0.10,
          ),
          0.25, math.pi - 0.5, false, stroke,
        );
        break;

      case MascotEmotion.celebrate:
        final fill = Paint()..color = _mouth;
        final pink = Paint()..color = const Color(0xFFFF8E9E);

        final mouth = Path()
          ..moveTo(w * 0.39, mouthY - h * 0.012)
          ..quadraticBezierTo(w * 0.5, mouthY + h * 0.075, w * 0.61, mouthY - h * 0.012)
          ..close();
        canvas.drawPath(mouth, fill);

        canvas.drawOval(
          Rect.fromCenter(
            center: Offset(w * 0.5, mouthY + h * 0.022),
            width: w * 0.12, height: h * 0.028,
          ),
          pink,
        );
        break;

      case MascotEmotion.worry:
        final stroke = Paint()
          ..color = _mouth
          ..style = PaintingStyle.stroke
          ..strokeWidth = w * 0.028
          ..strokeCap = StrokeCap.round;
        canvas.drawArc(
          Rect.fromCenter(
            center: Offset(w * 0.5, mouthY + h * 0.05),
            width: w * 0.18, height: h * 0.08,
          ),
          math.pi + 0.3, math.pi - 0.6, false, stroke,
        );
        break;

      case MascotEmotion.sleepy:
        final fill = Paint()..color = _mouth;
        canvas.drawOval(
          Rect.fromCenter(
            center: Offset(w * 0.5, mouthY),
            width: w * 0.07, height: h * 0.028,
          ),
          fill,
        );
        // Z above (sleepy zzz)
        final z = TextPainter(
          text: TextSpan(text: 'z', style: TextStyle(
            fontFamily: 'Pretendard',
            color: _hairDark.withValues(alpha: 0.6),
            fontSize: w * 0.12,
            fontWeight: FontWeight.w800,
          )),
          textDirection: TextDirection.ltr,
        )..layout();
        z.paint(canvas, Offset(w * 0.78, h * 0.25));
        break;

      case MascotEmotion.surprised:
        final fill = Paint()..color = _mouth;
        canvas.drawCircle(Offset(w * 0.5, mouthY), w * 0.035, fill);
        break;
    }
  }

  @override
  bool shouldRepaint(_MascotPainter old) =>
      old.kind != kind || old.emotion != emotion;
}
