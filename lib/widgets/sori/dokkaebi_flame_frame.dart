import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'tokens.dart';

/// Approved 16-phase blue fire. The carved frame is always sampled from A.
class DokkaebiFlameFrame extends StatefulWidget {
  const DokkaebiFlameFrame({
    super.key,
    required this.child,
    this.animate = true,
  });
  final Widget child;
  final bool animate;

  static const assets = [
    'assets/illustrations/dokkaebi_intro/frame_a.png',
    'assets/illustrations/dokkaebi_intro/frame_i.png',
    'assets/illustrations/dokkaebi_intro/frame_b.png',
    'assets/illustrations/dokkaebi_intro/frame_j.png',
    'assets/illustrations/dokkaebi_intro/frame_c.png',
    'assets/illustrations/dokkaebi_intro/frame_k.png',
    'assets/illustrations/dokkaebi_intro/frame_d.png',
    'assets/illustrations/dokkaebi_intro/frame_l.png',
    'assets/illustrations/dokkaebi_intro/frame_e.png',
    'assets/illustrations/dokkaebi_intro/frame_m.png',
    'assets/illustrations/dokkaebi_intro/frame_f.png',
    'assets/illustrations/dokkaebi_intro/frame_n.png',
    'assets/illustrations/dokkaebi_intro/frame_g.png',
    'assets/illustrations/dokkaebi_intro/frame_o.png',
    'assets/illustrations/dokkaebi_intro/frame_h.png',
    'assets/illustrations/dokkaebi_intro/frame_p.png',
  ];
  static const shaderAsset = 'shaders/dokkaebi_flame_frame.frag';
  static const durations = [
    .055,
    .055,
    .055,
    .055,
    .06,
    .06,
    .15,
    .15,
    .15,
    .15,
    .135,
    .135,
    .135,
    .135,
    .16,
    .16,
  ];
  static const cycle = 1.8;
  static const aperture = Rect.fromLTWH(.147, .148, .712, .687);

  static ({int first, int second, double blend}) sample(double seconds) {
    var phase = seconds % cycle;
    for (var i = 0; i < durations.length; i++) {
      if (phase < durations[i] || i == durations.length - 1) {
        final f = (phase / durations[i]).clamp(0.0, 1.0);
        return (first: i, second: (i + 1) % 16, blend: f * f * (3 - 2 * f));
      }
      phase -= durations[i];
    }
    return (first: 0, second: 1, blend: 0);
  }

  @override
  State<DokkaebiFlameFrame> createState() => _DokkaebiFlameFrameState();
}

class _DokkaebiFlameFrameState extends State<DokkaebiFlameFrame>
    with SingleTickerProviderStateMixin {
  late final AnimationController _clock = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 3600),
  );
  final List<ui.Image> _images = [];
  ui.FragmentShader? _shader;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  Future<void> _load() async {
    try {
      for (final path in DokkaebiFlameFrame.assets) {
        final data = await rootBundle.load(path);
        final codec = await ui.instantiateImageCodec(
          data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
          targetWidth: 768,
        );
        final frame = await codec.getNextFrame();
        codec.dispose();
        if (!mounted) {
          frame.image.dispose();
          return;
        }
        _images.add(frame.image);
      }
      try {
        final program = await ui.FragmentProgram.fromAsset(
          DokkaebiFlameFrame.shaderAsset,
        );
        if (mounted) {
          _shader = program.fragmentShader();
        }
      } catch (_) {
        // Canvas fallback still animates 16 phases outside the fixed rim.
      }
      if (mounted) {
        setState(() {});
      }
    } catch (_) {
      // A stationary approved frame plus embers also works without shaders.
      for (final image in _images) {
        image.dispose();
      }
      _images.clear();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _sync();
  }

  @override
  void didUpdateWidget(covariant DokkaebiFlameFrame oldWidget) {
    super.didUpdateWidget(oldWidget);
    _sync();
  }

  void _sync() {
    if (widget.animate &&
        !MediaQuery.disableAnimationsOf(context) &&
        TickerMode.valuesOf(context).enabled) {
      if (!_clock.isAnimating) {
        _clock.repeat();
      }
    } else {
      _clock.stop();
    }
  }

  @override
  void dispose() {
    _clock.dispose();
    _shader?.dispose();
    for (final image in _images) {
      image.dispose();
    }
    _images.clear();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final animated = widget.animate && !MediaQuery.disableAnimationsOf(context);
    return RepaintBoundary(
      child: AspectRatio(
        aspectRatio: 2 / 3,
        child: Stack(
          fit: StackFit.expand,
          children: [
            FractionallySizedBox(
              widthFactor: DokkaebiFlameFrame.aperture.width,
              heightFactor: DokkaebiFlameFrame.aperture.height,
              alignment: const Alignment(.020833333333, -.0543130990415),
              child: ClipRRect(
                borderRadius: const BorderRadius.all(
                  Radius.circular(SoriRadius.xs),
                ),
                child: ColoredBox(color: Colors.black, child: widget.child),
              ),
            ),
            IgnorePointer(
              child: AnimatedBuilder(
                animation: _clock,
                builder: (context, _) => _images.length != 16
                    ? Image.asset(
                        DokkaebiFlameFrame.assets.first,
                        fit: BoxFit.fill,
                        cacheWidth: 768,
                      )
                    : CustomPaint(
                        painter: _FirePainter(
                          shader: _shader,
                          images: _images,
                          seconds: animated ? _clock.value * 3600 : 0,
                          animate: animated,
                        ),
                      ),
              ),
            ),
            if (animated)
              IgnorePointer(
                child: AnimatedBuilder(
                  animation: _clock,
                  builder: (context, _) =>
                      CustomPaint(painter: _EmberPainter(_clock.value * 3600)),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _FirePainter extends CustomPainter {
  _FirePainter({
    required this.shader,
    required this.images,
    required this.seconds,
    required this.animate,
  });
  final ui.FragmentShader? shader;
  final List<ui.Image> images;
  final double seconds;
  final bool animate;

  @override
  void paint(Canvas canvas, Size size) {
    final phase = DokkaebiFlameFrame.sample(seconds);
    final effect = shader;
    if (effect == null) {
      final bounds = Offset.zero & size;
      final rim = Path()
        ..fillType = PathFillType.evenOdd
        ..addRect(
          Rect.fromLTRB(
            size.width * .069,
            size.height * .105,
            size.width * .936,
            size.height * .898,
          ),
        )
        ..addRect(
          Rect.fromLTRB(
            size.width * .170,
            size.height * .157,
            size.width * .831,
            size.height * .823,
          ),
        );
      void draw(ui.Image image, Paint paint) => canvas.drawImageRect(
        image,
        Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()),
        bounds,
        paint,
      );
      canvas.save();
      canvas.clipPath(rim);
      draw(images.first, Paint());
      canvas.restore();
      canvas.save();
      canvas.clipPath(
        Path.combine(PathOperation.difference, Path()..addRect(bounds), rim),
      );
      canvas.saveLayer(bounds, Paint());
      draw(
        images[phase.first],
        Paint()..color = Color.fromRGBO(255, 255, 255, 1 - phase.blend),
      );
      draw(
        images[phase.second],
        Paint()
          ..blendMode = BlendMode.plus
          ..color = Color.fromRGBO(255, 255, 255, phase.blend),
      );
      canvas.restore();
      canvas.restore();
      return;
    }
    effect
      ..setFloat(0, size.width)
      ..setFloat(1, size.height)
      ..setFloat(2, seconds)
      ..setFloat(3, phase.blend)
      ..setFloat(4, animate ? 1 : 0)
      ..setImageSampler(0, images.first)
      ..setImageSampler(1, images[phase.first])
      ..setImageSampler(2, images[phase.second]);
    canvas.drawRect(Offset.zero & size, Paint()..shader = effect);
  }

  @override
  bool shouldRepaint(covariant _FirePainter oldDelegate) =>
      seconds != oldDelegate.seconds ||
      animate != oldDelegate.animate ||
      shader != oldDelegate.shader;
}

class _EmberPainter extends CustomPainter {
  _EmberPainter(this.seconds);
  final double seconds;
  @override
  void paint(Canvas canvas, Size size) {
    // Integer cycles close both particle trajectories and their opacity.
    for (var i = 0; i < 18; i++) {
      final p = (seconds / DokkaebiFlameFrame.cycle + i * .137) % 1;
      final x =
          (i.isEven ? .075 : .925) + math.sin(p * math.pi * 2 + i * 2.3) * .015;
      final center = Offset(x * size.width, (.91 - p * .79) * size.height);
      final alpha = math.sin(p * math.pi) * .65;
      final r = (1.1 + (i % 3) * .35) * size.width / 342;
      canvas.drawCircle(
        center,
        r,
        Paint()..color = const Color(0xFF7EE5FF).withValues(alpha: alpha),
      );
      canvas.drawCircle(
        center,
        r * .4,
        Paint()..color = const Color(0xFFE7FDFF).withValues(alpha: alpha),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _EmberPainter oldDelegate) =>
      seconds != oldDelegate.seconds;
}
