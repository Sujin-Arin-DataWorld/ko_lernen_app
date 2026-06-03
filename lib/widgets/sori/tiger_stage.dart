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

  // 걷기 프레임 1장당 체류(ms). pace 컨트롤러 길이도 이 값으로 계산해 동기.
  static const int _walkMs = 116;
  // 걷기 프레임 간 크로스페이드(ms). 짧게 — 하드컷 스냅만 완화(과하면 다리 잔상).
  static const int _walkFade = 46;

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
    const seq = <(String, int, int)>[
      ('stand_greet', 1300, 280),
      ('bob_a', 640, 280),
      ('bob_b', 640, 280),
      ('bob_a', 640, 280),
    ];
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
  Future<void> _doPace(bool startLeft) async {
    final token = ++_seqToken;
    _phase = startLeft ? _Phase.pacingLeft : _Phase.pacingRight;
    final dir = startLeft ? -1.0 : 1.0;

    Future<void> tf(String n, int fade, int dwell) async {
      await _crossTo(n, fadeMs: fade);
      if (_disposed || token != _seqToken) {
        return;
      }
      await Future<void>.delayed(Duration(milliseconds: dwell));
    }

    // 나가기: 정면→측면 전환 후 walk out (0 → dir)
    await tf(startLeft ? 'turn_left_3q' : 'turn_right_3q', 150, 240);
    if (_disposed || token != _seqToken) {
      return;
    }
    await tf(startLeft ? 'step_out_left' : 'step_out_right', 120, 170);
    if (_disposed || token != _seqToken) {
      return;
    }
    if (!startLeft) {
      // 우측만 측면 walk_start 추가 lead-in 보유
      await tf('walk_start_right', 60, 120);
      if (_disposed || token != _seqToken) {
        return;
      }
    }
    await _walkSegment(token, startLeft, 0.0, dir);
    if (_disposed || token != _seqToken) {
      return;
    }
    // 돌아오기: 반대로 돌아 walk back (dir → 0)
    await tf(startLeft ? 'turn_right_3q' : 'turn_left_3q', 150, 220);
    if (_disposed || token != _seqToken) {
      return;
    }
    await _walkSegment(token, !startLeft, dir, 0.0);
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
  Future<void> _walkSegment(
    int token,
    bool faceLeft,
    double dxFrom,
    double dxTo, {
    int loops = 2,
  }) async {
    final frames = faceLeft ? _walkLeft : _walkRight;
    if (mounted) {
      setState(() {
        _dxFrom = dxFrom;
        _dxTo = dxTo;
      });
    }
    _paceCtrl.duration =
        Duration(milliseconds: loops * frames.length * _walkMs);
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
          const Duration(milliseconds: _walkMs - _walkFade),
        );
      }
    }
    try {
      await paceFut;
    } catch (_) {}
  }

  Future<void> _doSit() async {
    final token = ++_seqToken;
    _phase = _Phase.sitting;
    await _crossTo('sit_idle_a', fadeMs: 220);
    if (_disposed || token != _seqToken) {
      return;
    }
    await Future<void>.delayed(const Duration(milliseconds: 900));
    if (_disposed || token != _seqToken) {
      return;
    }
    await _crossTo('sit_idle_b', fadeMs: 320);
    if (_disposed || token != _seqToken) {
      return;
    }
    await Future<void>.delayed(const Duration(milliseconds: 950));
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
    if (r < 0.45) {
      _scheduleAmbient(); // 그대로 idle
      return;
    }
    if (r < 0.68) {
      _doPace(_rng.nextBool()); // 완료 시 _enterFrontIdle이 재무장
      return;
    }
    if (r < 0.80) {
      _doSit();
      return;
    }
    if (r < 0.91) {
      _doStretch(); // 기지개
      return;
    }
    _doRoar(); // 포효
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
                // 걷는 동안만 미세 상하 bob → 미끄러지듯(ice-skating) 보임 방지.
                final dy = _paceCtrl.isAnimating
                    ? -3.0 * math.sin(math.pi * _paceCtrl.value * 4).abs()
                    : 0.0;
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
