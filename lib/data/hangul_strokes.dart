import 'package:flutter/material.dart';

/// Ein einzelner Strich — entweder Linie (Polyline) oder Kreis (Circle).
sealed class Stroke {
  const Stroke();
}

class LineStroke extends Stroke {
  final List<Offset> points;
  const LineStroke(this.points);
}

class CircleStroke extends Stroke {
  final Offset center;
  final double radius;
  const CircleStroke(this.center, this.radius);
}

const Size strokeCanvas = Size(220, 220);

/// Strichreihenfolge pro Hangul-Buchstabe.
/// Koordinaten in 220×220 Bezugsfläche — werden im Canvas skaliert.
const Map<String, List<Stroke>> hangulStrokes = {
  // ── Konsonanten ──
  'ㄱ': [
    LineStroke([Offset(30, 55), Offset(172, 55), Offset(172, 178)]),
  ],
  'ㄴ': [
    LineStroke([Offset(42, 28), Offset(42, 170), Offset(178, 170)]),
  ],
  'ㄷ': [
    LineStroke([Offset(35, 42), Offset(175, 42)]),
    LineStroke([Offset(35, 42), Offset(35, 168), Offset(175, 168)]),
  ],
  'ㄹ': [
    LineStroke([Offset(35, 42), Offset(170, 42), Offset(170, 110)]),
    LineStroke([Offset(35, 110), Offset(170, 110)]),
    LineStroke([Offset(35, 112), Offset(35, 175), Offset(170, 175)]),
  ],
  'ㅁ': [
    LineStroke([Offset(42, 42), Offset(42, 175)]),
    LineStroke([Offset(42, 42), Offset(172, 42), Offset(172, 175)]),
    LineStroke([Offset(42, 175), Offset(172, 175)]),
  ],
  'ㅂ': [
    LineStroke([Offset(62, 38), Offset(62, 178)]),
    LineStroke([Offset(152, 38), Offset(152, 178)]),
    LineStroke([Offset(62, 108), Offset(152, 108)]),
    LineStroke([Offset(62, 178), Offset(152, 178)]),
  ],
  'ㅅ': [
    LineStroke([Offset(110, 40), Offset(42, 172)]),
    LineStroke([Offset(110, 40), Offset(178, 172)]),
  ],
  'ㅇ': [CircleStroke(Offset(110, 110), 68)],
  'ㅈ': [
    LineStroke([Offset(28, 60), Offset(192, 60)]),
    LineStroke([Offset(110, 60), Offset(45, 172)]),
    LineStroke([Offset(110, 60), Offset(175, 172)]),
  ],
  'ㅊ': [
    LineStroke([Offset(85, 26), Offset(135, 26)]),
    LineStroke([Offset(28, 60), Offset(192, 60)]),
    LineStroke([Offset(110, 60), Offset(45, 172)]),
    LineStroke([Offset(110, 60), Offset(175, 172)]),
  ],
  'ㅋ': [
    LineStroke([Offset(30, 55), Offset(172, 55), Offset(172, 178)]),
    LineStroke([Offset(30, 116), Offset(158, 116)]),
  ],
  'ㅌ': [
    LineStroke([Offset(30, 42), Offset(175, 42)]),
    LineStroke([Offset(30, 42), Offset(30, 172), Offset(175, 172)]),
    LineStroke([Offset(30, 107), Offset(175, 107)]),
  ],
  'ㅍ': [
    LineStroke([Offset(25, 65), Offset(192, 65)]),
    LineStroke([Offset(68, 65), Offset(68, 162)]),
    LineStroke([Offset(148, 65), Offset(148, 162)]),
    LineStroke([Offset(25, 162), Offset(192, 162)]),
  ],
  'ㅎ': [
    LineStroke([Offset(88, 22), Offset(130, 22)]),
    LineStroke([Offset(40, 55), Offset(178, 55)]),
    CircleStroke(Offset(110, 136), 52),
  ],
  'ㄲ': [
    LineStroke([Offset(18, 60), Offset(88, 60), Offset(88, 172)]),
    LineStroke([Offset(108, 60), Offset(178, 60), Offset(178, 172)]),
  ],
  'ㄸ': [
    LineStroke([Offset(12, 42), Offset(88, 42)]),
    LineStroke([Offset(12, 42), Offset(12, 165), Offset(88, 165)]),
    LineStroke([Offset(102, 42), Offset(178, 42)]),
    LineStroke([Offset(102, 42), Offset(102, 165), Offset(178, 165)]),
  ],
  'ㅃ': [
    LineStroke([Offset(15, 38), Offset(15, 178)]),
    LineStroke([Offset(100, 38), Offset(100, 178)]),
    LineStroke([Offset(15, 108), Offset(100, 108)]),
    LineStroke([Offset(15, 178), Offset(100, 178)]),
    LineStroke([Offset(120, 38), Offset(120, 178)]),
    LineStroke([Offset(205, 38), Offset(205, 178)]),
    LineStroke([Offset(120, 108), Offset(205, 108)]),
    LineStroke([Offset(120, 178), Offset(205, 178)]),
  ],
  'ㅆ': [
    LineStroke([Offset(70, 40), Offset(30, 165)]),
    LineStroke([Offset(70, 40), Offset(110, 165)]),
    LineStroke([Offset(148, 40), Offset(108, 165)]),
    LineStroke([Offset(148, 40), Offset(188, 165)]),
  ],
  'ㅉ': [
    LineStroke([Offset(15, 60), Offset(95, 60)]),
    LineStroke([Offset(55, 60), Offset(22, 165)]),
    LineStroke([Offset(55, 60), Offset(88, 165)]),
    LineStroke([Offset(105, 60), Offset(192, 60)]),
    LineStroke([Offset(148, 60), Offset(115, 165)]),
    LineStroke([Offset(148, 60), Offset(182, 165)]),
  ],

  // ── Vokale ──
  'ㅏ': [
    LineStroke([Offset(88, 25), Offset(88, 195)]),
    LineStroke([Offset(88, 110), Offset(158, 110)]),
  ],
  'ㅑ': [
    LineStroke([Offset(88, 25), Offset(88, 195)]),
    LineStroke([Offset(88, 78), Offset(158, 78)]),
    LineStroke([Offset(88, 138), Offset(158, 138)]),
  ],
  'ㅓ': [
    LineStroke([Offset(48, 110), Offset(118, 110)]),
    LineStroke([Offset(118, 25), Offset(118, 195)]),
  ],
  'ㅕ': [
    LineStroke([Offset(48, 78), Offset(118, 78)]),
    LineStroke([Offset(48, 138), Offset(118, 138)]),
    LineStroke([Offset(118, 25), Offset(118, 195)]),
  ],
  'ㅗ': [
    LineStroke([Offset(110, 42), Offset(110, 118)]),
    LineStroke([Offset(25, 118), Offset(195, 118)]),
  ],
  'ㅛ': [
    LineStroke([Offset(75, 42), Offset(75, 118)]),
    LineStroke([Offset(145, 42), Offset(145, 118)]),
    LineStroke([Offset(25, 118), Offset(195, 118)]),
  ],
  'ㅜ': [
    LineStroke([Offset(25, 95), Offset(195, 95)]),
    LineStroke([Offset(110, 95), Offset(110, 178)]),
  ],
  'ㅠ': [
    LineStroke([Offset(25, 95), Offset(195, 95)]),
    LineStroke([Offset(75, 95), Offset(75, 178)]),
    LineStroke([Offset(145, 95), Offset(145, 178)]),
  ],
  'ㅡ': [
    LineStroke([Offset(22, 110), Offset(195, 110)]),
  ],
  'ㅣ': [
    LineStroke([Offset(110, 22), Offset(110, 195)]),
  ],
  'ㅐ': [
    LineStroke([Offset(72, 25), Offset(72, 195)]),
    LineStroke([Offset(72, 110), Offset(145, 110)]),
    LineStroke([Offset(145, 25), Offset(145, 195)]),
  ],
  'ㅔ': [
    LineStroke([Offset(42, 110), Offset(115, 110)]),
    LineStroke([Offset(115, 25), Offset(115, 195)]),
    LineStroke([Offset(155, 25), Offset(155, 195)]),
  ],
  'ㅘ': [
    LineStroke([Offset(60, 42), Offset(60, 108)]),
    LineStroke([Offset(22, 108), Offset(125, 108)]),
    LineStroke([Offset(125, 25), Offset(125, 195)]),
    LineStroke([Offset(125, 110), Offset(188, 110)]),
  ],
  'ㅝ': [
    LineStroke([Offset(22, 92), Offset(120, 92)]),
    LineStroke([Offset(70, 92), Offset(70, 165)]),
    LineStroke([Offset(48, 118), Offset(120, 118)]),
    LineStroke([Offset(120, 25), Offset(120, 195)]),
  ],
  'ㅢ': [
    LineStroke([Offset(30, 110), Offset(160, 110)]),
    LineStroke([Offset(160, 25), Offset(160, 195)]),
  ],
};
