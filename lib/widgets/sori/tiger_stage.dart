import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'mascot.dart';
import 'tokens.dart';

/// **TigerStage** — 살아있는 호랑이 프레임 애니메이션 (홈 상단 와이드 밴드용).
///
/// 상태머신:
///   REST → INTRO_GREETING(launch당 1회) → FRONT_IDLE(루프) ↔ PACING_L/R / SIT
///
/// 프레임 자산은 `assets/illustrations/tiger_anim/`의 35장 PNG. 전체 스펙은
/// `docs/TIGER_ANIMATION_SPEC.md` 참조.
///
/// 설계 요점:
///   - **토큰 가드 재귀 Future 시퀀서** — 새 행동이 시작되면 `_seqToken`이 증가해
///     이전 시퀀스가 다음 await에서 스스로 종료(setState-after-dispose 방지).
///   - **포즈 전환**은 150ms 크로스디졸브(`_xfade`), **걷기 프레임**은 하드컷(블러 방지).
///   - **pacing**은 항상 there-and-back(±span→0)이라 화면 밖 이탈/누적 드리프트 0.
///   - **reduce-motion**(`MediaQuery.disableAnimations`) 시 정지 프레임 1장 + 컨트롤러/타이머 0.
///   - **프레임 누락** 시 프레임별 errorBuilder → 즉시 `Mascot.tiger` + 전체 정적 밴드로 강등.
///   - 백그라운드 진입 시 타이머/컨트롤러 정지, 복귀 시 idle 재개(intro 아님).
class TigerStage extends StatefulWidget {
  /// 밴드 높이(px). 호랑이는 높이에 BoxFit.contain.
  final double height;

  /// 정지/누락 시 fallback `Mascot.tiger`에 쓸 표정.
  final MascotEmotion fallbackEmotion;

  const TigerStage({
    super.key,
    this.height = 168,
    this.fallbackEmotion = MascotEmotion.smile,
  });

  @override
  State<TigerStage> createState() => _TigerStageState();
}

enum _Phase { intro, frontIdle, pacingLeft, pacingRight, sitting, special }

class _TigerStageState extends State<TigerStage>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  static const String _dir = 'assets/illustrations/tiger_anim/';

  /// 인트로는 앱 launch당 1회. (영속 X — `Storage.introSeen`은 게이트 화면 전용)
  static bool _introPlayedThisLaunch = false;

  // 걷기 프레임 1장당 체류(ms). 더 빠를수록 더 부드러워 보임(frame interpolation 효과).
  // 100ms = 10fps = 자연스러운 수준. 느릴수록 어색(8fps 이하는 stutter 눈에 띔).
  static const int _walkMs = 100;
  // 걷기 프레임은 하드컷(0) — 다리 움직임이 명확하고 선명함.
  static const int _walkFade = 0;

  static const List<String> _allFrames = [
    'rest_idle', 'notice_turn', 'notice_front', 'smile_front', 'rise_prep',
    'rise_half', 'stand_greet', 'bob_a', 'bob_b',
    'stand_idle_a', 'stand_idle_b', 'sit_idle_a', 'sit_idle_b',
    'turn_left_3q', 'step_out_left',
    'walk_left_a', 'walk_left_b', 'walk_left_c', 'walk_left_d', 'walk_left_e',
    'walk_left_f', 'walk_stop_left', 'turn_left_front',
    'turn_right_3q', 'step_out_right', 'walk_start_right',
    'walk_right_a', 'walk_right_b', 'walk_right_c', 'walk_right_d', 'walk_right_e',
    'walk_right_f', 'walk_stop_right', 'turn_right_front',
    // ambient specials (3/4 right): 기지개 + 포효
    'stretch_prep', 'stretch_full', 'stretch_release',
    'roar_prep', 'roar_open', 'roar_open2', 'roar_full', 'roar_close',
    'roar_recover',
  ];
  static const List<String> _walkLeft = [
    'walk_left_a', 'walk_left_b', 'walk_left_c', 'walk_left_d', 'walk_left_e',
    'walk_left_f',
  ];
  static const List<String> _walkRight = [
    'walk_right_a', 'walk_right_b', 'walk_right_c', 'walk_right_d', 'walk_right_e',
    'walk_right_f',
  ];

  late final AnimationController _xfade; // 프레임 크로스디졸브
  late final AnimationController _paceCtrl; // pacing x-translation
  late final CurvedAnimation _paceCurve;
  late final AnimationController _breath; // 상시 미세 호흡(정지 프레임 방지)

  String _frontName = 'stand_greet';
  String _backName = 'stand_greet';

  _Phase _phase = _Phase.frontIdle;
  int _seqToken = 0;
  bool _disposed = false;
  bool _precached = false;
  bool _assetsOk = true;
  bool _lifeStarted = false;
  bool _paused = false;
  bool _reduceMotion = false;

  Timer? _ambient;
  final math.Random _rng = math.Random();

  // pacing 좌표(fraction −1..1) — build에서 _span(px)와 곱해 dx.
  double _dxFrom = 0;
  double _dxTo = 0;
  double _span = 56;

  String _resolve(String name) => '$_dir$name.png';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _xfade = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
      value: 1,
    );
    _paceCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _paceCurve = CurvedAnimation(parent: _paceCtrl, curve: Curves.easeInOut);
    _breath = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2600),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reduceMotion = SoriMotion.reduceMotion(context);
    _precache();
    if (_reduceMotion) {
      _stopLife();
    } else {
      _maybeStartLife();
    }
  }

  void _precache() {
    if (_precached) {
      return;
    }
    _precached = true;
    for (final n in _allFrames) {
      precacheImage(AssetImage(_resolve(n)), context).catchError((_) {});
    }
  }

  void _maybeStartLife() {
    if (_lifeStarted || _disposed) {
      return;
    }
    _lifeStarted = true;
    if (!_breath.isAnimating) {
      _breath.repeat(reverse: true);
    }
    if (!_introPlayedThisLaunch) {
      _introPlayedThisLaunch = true;
      _runIntro();
    } else {
      _enterFrontIdle();
    }
  }

  void _stopLife() {
    _ambient?.cancel();
    _seqToken++; // 진행 중 시퀀스 무효화
    _lifeStarted = false;
    _paceCtrl.stop();
    _breath.stop();
    if (mounted) {
      setState(() {
        _frontName = 'stand_greet';
        _backName = 'stand_greet';
        _dxFrom = 0;
        _dxTo = 0;
      });
    }
    _xfade.value = 1;
  }

  // ── 프레임 전환 ──────────────────────────────────────────────────────
  /// [fadeMs] <= 0 → 즉시 스왑(걷기용 하드컷). 그 외 → 크로스디졸브.
  Future<void> _crossTo(String name, {int fadeMs = 150}) async {
    if (_disposed) {
      return;
    }
    if (name == _frontName && _xfade.value == 1) {
      return;
    }
    if (fadeMs <= 0) {
      if (!mounted) {
        return;
      }
      setState(() {
        _backName = name;
        _frontName = name;
      });
      _xfade.value = 1;
      return;
    }
    if (!mounted) {
      return;
    }
    setState(() {
      _backName = _frontName;
      _frontName = name;
    });
    _xfade.duration = Duration(milliseconds: fadeMs);
    try {
      await _xfade.forward(from: 0);
    } catch (_) {
      // TickerCanceled (dispose 중) — 무시
    }
  }

  // ── 시퀀스 ──────────────────────────────────────────────────────────
  Future<void> _runIntro() async {
    final token = ++_seqToken;
    _phase = _Phase.intro;
    // (name, dwell ms, fade ms). 첫 프레임은 즉시 노출.
    const seq = <(String, int, int)>[
      ('rest_idle', 650, 0),
      ('notice_turn', 300, 200),
      ('notice_front', 300, 180),
      ('smile_front', 460, 200),
      ('rise_prep', 300, 160),
      ('rise_half', 360, 170),
      ('stand_greet', 650, 220),
    ];
    for (final (name, ms, fade) in seq) {
      if (_disposed || token != _seqToken) {
        return;
      }
      await _crossTo(name, fadeMs: fade);
      if (_disposed || token != _seqToken) {
        return;
      }
      await Future<void>.delayed(Duration(milliseconds: ms));
    }
    _enterFrontIdle();
  }

  void _enterFrontIdle() {
    if (_disposed || _reduceMotion || _paused) {
      return;
    }
    _phase = _Phase.frontIdle;
    _scheduleAmbient();
    _loopFrontIdle();
  }

  Future<void> _loopFrontIdle() async {
    final token = ++_seqToken;
    // 다양한 idle 포즈로 "살아있는" 느낌 연출.
    // stand_idle_a/b도 활용해서 호흡 다양성 증가.
    const seq = <(String, int, int)>[
      ('stand_greet', 1200, 260),      // 인사 포즈
      ('bob_a', 720, 240),               // 호흡 A
      ('bob_b', 720, 240),               // 호흡 B
      ('stand_idle_a', 800, 240),        // 다른 정지 포즈 A
      ('bob_a', 720, 240),               // 호흡 다시
      ('stand_idle_b', 800, 240),        // 다른 정지 포즈 B
      ('bob_b', 720, 240),               // 호흡 B
    ];
    // 총 루프 시간 ≈ 6.5초 (충분히 길어서 사용자가 완전히 분석하지 못함)
    while (!_disposed && token == _seqToken) {
      for (final (name, ms, fade) in seq) {
        if (_disposed || token != _seqToken) {
          return;
        }
        await _crossTo(name, fadeMs: fade);
        if (_disposed || token != _seqToken) {
          return;
        }
        await Future<void>.delayed(Duration(milliseconds: ms));
      }
    }
  }

  // ── pacing (there-and-back: 0 → ±span → 0, 항상 중앙 복귀) ──────────────
  // 호랑이가 가끔 짧게(2회), 보통(3회), 가끔 길게(4회) 걸음 → 예측 불가능 → 살아있는 느낌
  Future<void> _doPace(bool startLeft) async {
    final token = ++_seqToken;
    _phase = startLeft ? _Phase.pacingLeft : _Phase.pacingRight;
    final dir = startLeft ? -1.0 : 1.0;
    // walk loop 확률: 2회(25%) / 3회(50%) / 4회(25%)
    final loopCount = _rng.nextDouble() < 0.25 ? 2 : (_rng.nextDouble() < 0.666 ? 3 : 4);

    Future<void> tf(String n, int fade, int dwell) async {
      await _crossTo(n, fadeMs: fade);
      if (_disposed || token != _seqToken) {
        return;
      }
      await Future<void>.delayed(Duration(milliseconds: dwell));
    }

    // 나가기: 정면→측면 전환 후 walk out (0 → dir)
    // turn (포즈 전환) — smooth 200ms fade로 자연스럽게
    await tf(startLeft ? 'turn_left_3q' : 'turn_right_3q', 200, 240);
    if (_disposed || token != _seqToken) {
      return;
    }
    // step_out (발 내딛기) — turn 후 즉시, smooth 180ms fade
    await tf(startLeft ? 'step_out_left' : 'step_out_right', 180, 160);
    if (_disposed || token != _seqToken) {
      return;
    }
    // step_out → walk 간 아주 짧은 settling (walk_stop이 이제 transition을 담당하므로 거의 필요 없음)
    await Future<void>.delayed(const Duration(milliseconds: 20));
    if (_disposed || token != _seqToken) {
      return;
    }
    await _walkSegment(token, startLeft, 0.0, dir, loops: loopCount);
    if (_disposed || token != _seqToken) {
      return;
    }
    // 돌아오기: 반대로 돌아 walk back (dir → 0)
    await tf(startLeft ? 'turn_right_3q' : 'turn_left_3q', 150, 220);
    if (_disposed || token != _seqToken) {
      return;
    }
    // 돌아올 때도 같은 loop count (대칭성)
    await _walkSegment(token, !startLeft, dir, 0.0, loops: loopCount);
    if (_disposed || token != _seqToken) {
      return;
    }
    await tf(startLeft ? 'turn_right_front' : 'turn_left_front', 150, 300);
    if (_disposed || token != _seqToken) {
      return;
    }
    _enterFrontIdle();
  }

  /// 걷기 한 구간: [faceLeft] 방향 프레임을 [loops]회 하드컷 재생하면서
  /// dx fraction을 [dxFrom]→[dxTo]로 _paceCtrl과 동기 이동.
  /// 걷기 끝에 walk_stop_left/right를 추가 → turn으로 부드럽게 연결.
  Future<void> _walkSegment(
    int token,
    bool faceLeft,
    double dxFrom,
    double dxTo, {
    int loops = 3,
  }) async {
    final frames = faceLeft ? _walkLeft : _walkRight;
    final stopFrame = faceLeft ? 'walk_stop_left' : 'walk_stop_right';

    if (mounted) {
      setState(() {
        _dxFrom = dxFrom;
        _dxTo = dxTo;
      });
    }
    // 계산: walk loop의 시간 + walk_stop(100ms)
    _paceCtrl.duration =
        Duration(milliseconds: loops * frames.length * _walkMs + 100);
    final paceFut = _paceCtrl.forward(from: 0);

    for (var i = 0; i < loops; i++) {
      for (final n in frames) {
        if (_disposed || token != _seqToken) {
          _paceCtrl.stop();
          return;
        }
        await _crossTo(n, fadeMs: _walkFade);
        if (_disposed || token != _seqToken) {
          _paceCtrl.stop();
          return;
        }
        await Future<void>.delayed(
          Duration(milliseconds: _walkMs - _walkFade),
        );
      }
    }

    // 걷기 끝: walk_stop 프레임으로 발 착지 강조 (100ms)
    if (!_disposed && token == _seqToken) {
      await _crossTo(stopFrame, fadeMs: 0);
      if (!_disposed && token == _seqToken) {
        await Future<void>.delayed(const Duration(milliseconds: 100));
      }
    }

    try {
      await paceFut;
    } catch (_) {}
  }

  Future<void> _doSit() async {
    final token = ++_seqToken;
    _phase = _Phase.sitting;
    // 호랑이가 가끔 짧게(1.5초), 보통(2초), 가끔 길게(3초) 앉음 → 자연스러움
    final sitDuration = _rng.nextDouble() < 0.3 ? 1500 : (_rng.nextDouble() < 0.666 ? 2000 : 3000);

    await _crossTo('sit_idle_a', fadeMs: 220);
    if (_disposed || token != _seqToken) {
      return;
    }
    await Future<void>.delayed(Duration(milliseconds: (sitDuration * 0.45).toInt()));
    if (_disposed || token != _seqToken) {
      return;
    }
    await _crossTo('sit_idle_b', fadeMs: 320);
    if (_disposed || token != _seqToken) {
      return;
    }
    await Future<void>.delayed(Duration(milliseconds: (sitDuration * 0.55).toInt()));
    if (_disposed || token != _seqToken) {
      return;
    }
    await _crossTo('stand_greet', fadeMs: 260);
    if (_disposed || token != _seqToken) {
      return;
    }
    _enterFrontIdle();
  }

  // 토큰 가드 스텝 시퀀스(전환 프레임용). (name, fadeMs, dwellMs).
  Future<void> _playSteps(int token, List<(String, int, int)> steps) async {
    for (final (n, fade, dwell) in steps) {
      await _crossTo(n, fadeMs: fade);
      if (_disposed || token != _seqToken) {
        return;
      }
      await Future<void>.delayed(Duration(milliseconds: dwell));
      if (_disposed || token != _seqToken) {
        return;
      }
    }
  }

  // 기지개 — 정면→3/4 우로 돌아 쭉 폈다가 정면 복귀 (ambient special).
  Future<void> _doStretch() async {
    final token = ++_seqToken;
    _phase = _Phase.special;
    await _playSteps(token, const [
      ('turn_right_3q', 150, 160),
      ('stretch_prep', 200, 260),
      ('stretch_full', 260, 720),
      ('stretch_release', 200, 240),
      ('turn_right_front', 160, 200),
    ]);
    if (_disposed || token != _seqToken) {
      return;
    }
    _enterFrontIdle();
  }

  // 포효 — 정면→3/4 우로 돌아 으르렁 후 정면 복귀 (ambient special).
  Future<void> _doRoar() async {
    final token = ++_seqToken;
    _phase = _Phase.special;
    await _playSteps(token, const [
      ('turn_right_3q', 150, 140),
      ('roar_prep', 160, 220),
      ('roar_open', 110, 130),
      ('roar_open2', 90, 120),
      ('roar_full', 110, 440),
      ('roar_close', 120, 160),
      ('roar_recover', 160, 220),
      ('turn_right_front', 160, 200),
    ]);
    if (_disposed || token != _seqToken) {
      return;
    }
    _enterFrontIdle();
  }

  // ── ambient 스케줄러 (frontIdle에서만 행동, 항상 재무장) ────────────────
  void _scheduleAmbient() {
    _ambient?.cancel();
    if (_disposed || _reduceMotion || _paused) {
      return;
    }
    _ambient = Timer(
      Duration(milliseconds: 5000 + _rng.nextInt(5000)),
      _onAmbientTick,
    );
  }

  void _onAmbientTick() {
    if (_disposed || _paused || _phase != _Phase.frontIdle) {
      _scheduleAmbient();
      return;
    }
    final r = _rng.nextDouble();
    // 확률 재조정: idle을 줄이고 다양한 행동을 늘림
    // → 사용자가 호랑이를 완전히 분석할 시간 부족
    // → 더 "살아있는" 느낌 (자주 변하므로 부자연스러움이 눈에 띄지 않음)
    if (r < 0.32) {
      _scheduleAmbient(); // idle 유지 (32%)
      return;
    }
    if (r < 0.57) {
      _doPace(_rng.nextBool()); // pacing 25%
      return;
    }
    if (r < 0.72) {
      _doSit(); // sitting 15%
      return;
    }
    if (r < 0.86) {
      _doStretch(); // stretch 14%
      return;
    }
    _doRoar(); // roar 14%
    // 총합: 32 + 25 + 15 + 14 + 14 = 100%
  }

  // ── lifecycle ───────────────────────────────────────────────────────
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _paused = false;
      if (_lifeStarted && !_reduceMotion) {
        if (!_breath.isAnimating) {
          _breath.repeat(reverse: true);
        }
        _enterFrontIdle();
      }
    } else {
      _paused = true;
      _ambient?.cancel();
      _seqToken++;
      _paceCtrl.stop();
      _breath.stop();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    WidgetsBinding.instance.removeObserver(this);
    _ambient?.cancel();
    _paceCurve.dispose();
    _breath.dispose();
    _xfade.dispose();
    _paceCtrl.dispose();
    super.dispose();
  }

  void _onImageError() {
    if (!_assetsOk || _disposed) {
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_disposed || !mounted) {
        return;
      }
      setState(() => _assetsOk = false);
    });
  }

  // ── build ───────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    if (_reduceMotion || !_assetsOk) {
      return _staticBand();
    }
    return RepaintBoundary(
      child: SizedBox(
        height: widget.height,
        width: double.infinity,
        child: LayoutBuilder(
          builder: (context, c) {
            _span = (c.maxWidth * 0.17).clamp(28.0, 80.0);
            return AnimatedBuilder(
              animation: Listenable.merge([_xfade, _paceCtrl, _breath]),
              builder: (context, _) {
                final dx =
                    (_dxFrom + (_dxTo - _dxFrom) * _paceCurve.value) * _span;
                // ⚠️ bob 제거됨: 프레임이 이미 상하 움직임(stride의 자연스러운 리듬)을 포함.
                // 추가 bob은 이중 움직임 → 어색함. 프레임의 자연스러운 gait만 신뢰.
                const dy = 0.0;
                // 상시 미세 호흡 스케일 → 정지 프레임도 죽지 않게.
                final breath =
                    1.0 + 0.016 * Curves.easeInOut.transform(_breath.value);
                return Stack(
                  alignment: Alignment.bottomCenter,
                  clipBehavior: Clip.hardEdge,
                  children: [
                    Transform.translate(
                      offset: Offset(dx, 0),
                      child: _shadow(),
                    ),
                    Transform.translate(
                      offset: Offset(dx, dy),
                      child: Transform.scale(
                        scale: breath,
                        alignment: Alignment.bottomCenter,
                        child: _frameStack(),
                      ),
                    ),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _frameStack() {
    // easeInOut으로 디졸브 양끝을 부드럽게(선형 크로스페이드의 딱딱함 완화).
    final f = Curves.easeInOut.transform(_xfade.value.clamp(0.0, 1.0));
    return SizedBox(
      height: widget.height,
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          _frameImg(_backName, 1 - f),
          _frameImg(_frontName, f),
        ],
      ),
    );
  }

  Widget _frameImg(String name, double opacity) {
    return Opacity(
      opacity: opacity.clamp(0.0, 1.0),
      child: Image.asset(
        _resolve(name),
        height: widget.height * 0.94,
        fit: BoxFit.contain,
        gaplessPlayback: true,
        filterQuality: FilterQuality.medium,
        errorBuilder: (_, __, ___) {
          _onImageError();
          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _shadow() {
    final w = widget.height * 0.46;
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Container(
        width: w,
        height: w * 0.22,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.all(Radius.elliptical(w, w * 0.22)),
          gradient: RadialGradient(
            colors: [
              Colors.black.withValues(alpha: 0.18),
              Colors.black.withValues(alpha: 0.0),
            ],
          ),
        ),
      ),
    );
  }

  Widget _staticBand() {
    return SizedBox(
      height: widget.height,
      width: double.infinity,
      child: Center(
        child: Image.asset(
          _resolve('stand_greet'),
          height: widget.height * 0.94,
          fit: BoxFit.contain,
          filterQuality: FilterQuality.medium,
          errorBuilder: (_, __, ___) => Mascot.tiger(
            size: widget.height * 0.82,
            emotion: widget.fallbackEmotion,
          ),
        ),
      ),
    );
  }
}
