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
    final String overlay = switch (emotion) {
      MascotEmotion.celebrate  => '🎉',
      MascotEmotion.worry      => '😟',
      MascotEmotion.sleepy     => '😴',
      MascotEmotion.surprised  => '😲',
      _                        => '',
    };

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.bottomRight,
        children: [
          Image.asset(
            'assets/illustrations/hanok/tiger_magpie.png',
            width: size,
            height: size,
            fit: BoxFit.contain,
          ),
          if (overlay.isNotEmpty)
            Text(overlay, style: TextStyle(fontSize: size * 0.28)),
        ],
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

