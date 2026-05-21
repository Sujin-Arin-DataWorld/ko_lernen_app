import 'package:flutter/material.dart';

/// **Sori Mascot v5** — 호랑이 + 갓 쓴 까치 일러스트 기반 마스코트.
///
/// **v4 버그 수정**: v4는 존재하지 않는 `tiger_magpie.png`를 참조해 홈·시나리오·
/// 퀘스트·데일리 등 앱 전역에서 마스코트가 *깨진 이미지 아이콘*으로 표시됐다.
/// v5는 실제로 번들된 일러스트 `welcome-hero.png` (1024², 직접 제작한 호랑이+까치)
/// 를 사용한다.
///
/// API는 v4와 동일 — 호출부 변경 불필요:
/// - [Mascot.tiger] / [Mascot.magpie] / [Mascot.new]
/// - [Mascot.forSpeaker] — 시나리오 speaker 코드 → 마스코트
/// - [MascotKind] / [MascotEmotion]
///
/// **신규**: [animate] = true → 부드러운 호흡(breathing) 스케일로 "살아있는" 느낌.
/// 결과 화면·홈 hero 등 큰 컨텍스트에만 권장. dialog 작은 아바타는 false 유지.
///
/// 사용:
/// ```dart
/// Mascot.tiger(emotion: MascotEmotion.celebrate, size: 120, animate: true)
/// Mascot.magpie(emotion: MascotEmotion.smile, size: 56)
/// ```
class Mascot extends StatefulWidget {
  final MascotKind kind;
  final MascotEmotion emotion;
  final double size;

  /// 부드러운 호흡 스케일 애니메이션 — hero 컨텍스트(결과/홈)에만 권장.
  final bool animate;

  const Mascot({
    super.key,
    required this.kind,
    this.emotion = MascotEmotion.smile,
    this.size = 64,
    this.animate = false,
  });

  // ── Primary constructors ──────────────────────────────────────────────
  const Mascot.tiger({
    super.key,
    this.emotion = MascotEmotion.smile,
    this.size = 64,
    this.animate = false,
  }) : kind = MascotKind.tiger;

  const Mascot.magpie({
    super.key,
    this.emotion = MascotEmotion.smile,
    this.size = 64,
    this.animate = false,
  }) : kind = MascotKind.magpie;

  // ── Legacy constructors (deprecated — route to tiger) ─────────────────
  @Deprecated('Use Mascot.tiger — Jieun/Minsu painters retired in v3 design refresh')
  const Mascot.jieun({
    super.key,
    this.emotion = MascotEmotion.smile,
    this.size = 64,
    this.animate = false,
  }) : kind = MascotKind.tiger;

  @Deprecated('Use Mascot.tiger — Jieun/Minsu painters retired in v3 design refresh')
  const Mascot.minsu({
    super.key,
    this.emotion = MascotEmotion.smile,
    this.size = 64,
    this.animate = false,
  }) : kind = MascotKind.tiger;

  /// Speaker-code → Mascot. minsu/jieun (legacy) → tiger, kkachi/magpie → magpie.
  /// 알 수 없는 speaker → null (caller가 emoji fallback 사용).
  static Widget? forSpeaker(
    String speaker, {
    MascotEmotion emotion = MascotEmotion.smile,
    double size = 56,
    bool animate = false,
  }) {
    switch (speaker) {
      case 'tiger':
      case 'horangi':
      case '호랑이':
      case 'jieun': // legacy v2 → tiger
      case 'minsu': // legacy v2 → tiger
        return Mascot.tiger(emotion: emotion, size: size, animate: animate);
      case 'kkachi':
      case 'magpie':
      case '까치':
        return Mascot.magpie(emotion: emotion, size: size, animate: animate);
      default:
        return null;
    }
  }

  @override
  State<Mascot> createState() => _MascotState();
}

class _MascotState extends State<Mascot> with SingleTickerProviderStateMixin {
  /// 직접 제작한 호랑이+까치 일러스트. pubspec의 `assets/illustrations/hanok/`
  /// 디렉토리로 번들됨.
  static const String _asset = 'assets/illustrations/hanok/welcome-hero.png';

  AnimationController? _breath;

  @override
  void initState() {
    super.initState();
    if (widget.animate) _startBreath();
  }

  void _startBreath() {
    _breath = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2600),
    )..repeat(reverse: true);
  }

  @override
  void didUpdateWidget(covariant Mascot old) {
    super.didUpdateWidget(old);
    if (widget.animate && _breath == null) {
      _startBreath();
    } else if (!widget.animate && _breath != null) {
      _breath!.dispose();
      _breath = null;
    }
  }

  @override
  void dispose() {
    _breath?.dispose();
    super.dispose();
  }

  /// 감정 → 우측 하단 이모지 오버레이. smile/neutral은 오버레이 없음.
  String get _overlay {
    switch (widget.emotion) {
      case MascotEmotion.celebrate:
        return '🎉';
      case MascotEmotion.worry:
        return '😟';
      case MascotEmotion.sleepy:
        return '😴';
      case MascotEmotion.surprised:
        return '😲';
      case MascotEmotion.neutral:
      case MascotEmotion.smile:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget image = Image.asset(
      _asset,
      width: widget.size,
      height: widget.size,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.medium,
      errorBuilder: (_, __, ___) => _Fallback(kind: widget.kind, size: widget.size),
    );

    // hero 컨텍스트: 부드러운 호흡 스케일.
    final breath = _breath;
    if (breath != null) {
      image = AnimatedBuilder(
        animation: breath,
        builder: (_, child) {
          final t = Curves.easeInOut.transform(breath.value);
          return Transform.scale(scale: 1.0 + t * 0.045, child: child);
        },
        child: image,
      );
    }

    final overlay = _overlay;

    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: Stack(
        alignment: Alignment.bottomRight,
        children: [
          image,
          if (overlay.isNotEmpty)
            Text(overlay, style: TextStyle(fontSize: widget.size * 0.30, height: 1)),
        ],
      ),
    );
  }
}

/// 에셋 로드 실패 시 (이론상 발생하지 않음 — 번들됨) *깨진 아이콘* 대신
/// 부드러운 색상 원 + 이모지 fallback.
class _Fallback extends StatelessWidget {
  final MascotKind kind;
  final double size;
  const _Fallback({required this.kind, required this.size});

  @override
  Widget build(BuildContext context) {
    final isMagpie = kind == MascotKind.magpie;
    // SoriColors와 독립 — 위젯 자체로 안전하게 동작하도록 const 색상 사용.
    final color = isMagpie ? const Color(0xFF5A7BA0) : const Color(0xFFFF8C42);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.18),
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Text(
        isMagpie ? '🐦' : '🐯',
        style: TextStyle(fontSize: size * 0.5, height: 1),
      ),
    );
  }
}

enum MascotKind {
  tiger,
  magpie,
  // Legacy aliases — 코드가 여전히 참조할 수 있음. v5는 둘 다 일러스트로 표시.
  @Deprecated('Use MascotKind.tiger') jieun,
  @Deprecated('Use MascotKind.tiger') minsu,
}

enum MascotEmotion { neutral, smile, worry, celebrate, sleepy, surprised }
