import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../l10n/generated/app_localizations.dart';
import '../../models/learner_level.dart';
import '../../widgets/sori/tokens.dart';
import '../../widgets/trace_canvas.dart';
import 'onboarding_v3_demo_support.dart';

/// A hands-on, local demonstration. No assessment or progression services.
class OnboardingLearningDemo extends StatefulWidget {
  const OnboardingLearningDemo({
    super.key,
    required this.level,
    this.beginner = false,
  });
  final LearnerLevel level;
  final bool beginner;
  @override
  State<OnboardingLearningDemo> createState() => _OnboardingLearningDemoState();
}

class _OnboardingLearningDemoState
    extends OnboardingDemoSpeechState<OnboardingLearningDemo> {
  int _area = 0;
  int _skill = 0;
  bool _meaning = false;
  bool _reply = false;
  bool _ownTurn = false;
  bool _model = false;
  int _compactView = 0;

  void _choose({int? area, int? skill}) {
    demoStop();
    setState(() {
      _area = area ?? _area;
      _skill = skill ?? _skill;
      _reply = false;
      _ownTurn = false;
      _model = false;
      _meaning = false;
    });
  }

  @override
  void didUpdateWidget(covariant OnboardingLearningDemo oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.level != oldWidget.level ||
        widget.beginner != oldWidget.beginner) {
      _choose(area: 0, skill: 0);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.beginner) {
      return const _LetterDemo();
    }
    final t = AppL10n.of(context);
    final areas = [
      t.onboardingDemoCourse,
      t.onboardingDemoSmalltalk,
      t.onboardingDemoScenario,
    ];
    final skills = [
      t.onboardingDemoListen,
      t.onboardingDemoSpeak,
      t.onboardingDemoRead,
      t.onboardingDemoWrite,
    ];
    return LayoutBuilder(
      builder: (context, bounds) => OnboardingDemoContent(
        level: widget.level,
        builder: (data) {
          if (bounds.maxHeight < 340 ||
              MediaQuery.textScalerOf(context).scale(1) > 1.5) {
            return _compact(data, areas, skills);
          }
          final course = data['course'] as Map<String, dynamic>;
          final conversation =
              data[_area == 1 ? 'smalltalk' : 'scenario']
                  as Map<String, dynamic>;
          return Column(
            children: [
              DemoChoiceRow(
                children: [
                  for (var i = 0; i < 3; i++)
                    DemoChoice(
                      key: ValueKey('demo-area-$i'),
                      label: areas[i],
                      selected: _area == i,
                      onTap: () => _choose(area: i),
                    ),
                ],
              ),
              const SizedBox(height: 6),
              if (_area == 0) ...[
                DemoChoiceRow(
                  children: [
                    for (var i = 0; i < 4; i++)
                      DemoChoice(
                        key: ValueKey('demo-skill-$i'),
                        label: skills[i],
                        selected: _skill == i,
                        onTap: () => _choose(skill: i),
                      ),
                  ],
                ),
                const SizedBox(height: 6),
              ],
              Expanded(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: _area > 0
                        ? _conversation(conversation)
                        : _course(course),
                  ),
                ),
              ),
              if (demoAudioFailed)
                Text(
                  t.onboardingDemoAudioUnavailable,
                  style: const TextStyle(fontSize: 13),
                  textAlign: TextAlign.center,
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _compact(
    Map<String, dynamic> data,
    List<String> areas,
    List<String> skills,
  ) {
    final t = AppL10n.of(context);
    if (_compactView == 0) {
      return Column(
        children: [
          for (var i = 0; i < 3; i++)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: DemoChoice(
                  key: ValueKey('demo-area-$i'),
                  label: areas[i],
                  icon: [
                    Icons.route,
                    Icons.chat_bubble_outline,
                    Icons.forum_outlined,
                  ][i],
                  onTap: () {
                    _choose(area: i);
                    setState(() => _compactView = i == 0 ? 1 : 2);
                  },
                ),
              ),
            ),
        ],
      );
    }
    final isSkills = _compactView == 1;
    return Column(
      children: [
        SizedBox(
          height: 48,
          child: Row(
            children: [
              IconButton(
                key: const ValueKey('demo-learning-back'),
                tooltip: t.onboardingDemoPrevious,
                onPressed: () {
                  demoStop();
                  setState(() => _compactView = isSkills || _area > 0 ? 0 : 1);
                },
                icon: const Icon(Icons.arrow_back),
              ),
              Expanded(
                child: DemoPagedText(
                  text: isSkills
                      ? areas[0]
                      : _area == 0
                      ? skills[_skill]
                      : areas[_area],
                  korean: false,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: isSkills
              ? Column(
                  children: [
                    for (var row = 0; row < 2; row++)
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: DemoChoiceRow(
                            children: [
                              for (var col = 0; col < 2; col++)
                                DemoChoice(
                                  key: ValueKey('demo-skill-${row * 2 + col}'),
                                  label: skills[row * 2 + col],
                                  onTap: () {
                                    _choose(skill: row * 2 + col);
                                    setState(() => _compactView = 2);
                                  },
                                ),
                            ],
                          ),
                        ),
                      ),
                  ],
                )
              : _area == 0
              ? _course(data['course'] as Map<String, dynamic>, compact: true)
              : _compactConversation(
                  data[_area == 1 ? 'smalltalk' : 'scenario']
                      as Map<String, dynamic>,
                ),
        ),
      ],
    );
  }

  Widget _compactConversation(Map<String, dynamic> conversation) {
    final t = AppL10n.of(context);
    final value =
        conversation[_reply ? 'reply' : 'prompt'] as Map<String, dynamic>;
    return Column(
      children: [
        Expanded(
          child: Container(
            key: ValueKey(_reply ? 'demo-reply-bubble' : 'demo-partner-bubble'),
            margin: EdgeInsets.only(
              left: _reply ? 16 : 0,
              right: _reply ? 0 : 16,
            ),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: _reply
                  ? Theme.of(context).colorScheme.primaryContainer
                  : Theme.of(context).colorScheme.surfaceContainerLow,
            ),
            child: Column(
              children: [
                Text(
                  _reply ? t.onboardingDemoYourReply : t.onboardingDemoPartner,
                  style: const TextStyle(fontSize: 13),
                ),
                Expanded(
                  child: DemoPagedText(
                    text: _meaning
                        ? demoMeaning(context, value)
                        : value['ko'] as String,
                    korean: !_meaning,
                    fontSize: _meaning ? 18 : 26,
                  ),
                ),
              ],
            ),
          ),
        ),
        SizedBox(
          height: 48,
          child: Row(
            children: [
              IconButton(
                tooltip: t.onboardingDemoListen,
                icon: Icon(demoPlaying ? Icons.stop : Icons.volume_up_outlined),
                onPressed: () => demoSpeak(value['ko'] as String),
              ),
              IconButton(
                tooltip: t.onboardingDemoMeaning,
                icon: const Icon(Icons.translate),
                onPressed: () => setState(() => _meaning = !_meaning),
              ),
              IconButton(
                key: const ValueKey('demo-show-reply'),
                tooltip: _reply
                    ? t.onboardingDemoPartner
                    : t.onboardingDemoYourReply,
                icon: Icon(
                  _reply ? Icons.chevron_left : Icons.chat_bubble_outline,
                ),
                onPressed: () {
                  demoStop();
                  setState(() => _reply = !_reply);
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _course(Map<String, dynamic> example, {bool compact = false}) {
    final t = AppL10n.of(context);
    final ko = example['ko'] as String;
    if (_skill == 3) {
      return DemoSentenceTiles(
        key: ValueKey('demo-writing-${widget.level.code}'),
        sentence: ko,
      );
    }
    return Column(
      children: [
        if (_skill == 1 && !compact)
          Text(
            _ownTurn
                ? t.onboardingDemoYourTurn
                : t.onboardingDemoListenThenSpeak,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 13),
          ),
        Expanded(
          child: _skill == 1 && _ownTurn && !_model
              ? Column(
                  children: [
                    const Expanded(
                      child: Center(
                        child: Icon(
                          Icons.mic_none,
                          size: 64,
                          color: SoriColors.primary,
                        ),
                      ),
                    ),
                    DemoChoice(
                      key: const ValueKey('demo-speaking-model'),
                      label: t.onboardingDemoModel,
                      onTap: () => setState(() => _model = true),
                    ),
                  ],
                )
              : DemoPagedText(
                  text: _meaning ? demoMeaning(context, example) : ko,
                  korean: !_meaning,
                  fontSize: _meaning ? 18 : 28,
                  textKey: const ValueKey('demo-course-text'),
                ),
        ),
        if (_skill == 1) ...[
          Text(
            t.onboardingDemoNoRecording,
            style: const TextStyle(fontSize: 13),
            textAlign: TextAlign.center,
          ),
          DemoChoiceRow(
            children: [
              DemoChoice(
                key: const ValueKey('demo-course-audio'),
                label: demoPlaying
                    ? t.onboardingDemoStop
                    : t.onboardingDemoListen,
                icon: demoPlaying ? Icons.stop : Icons.volume_up_outlined,
                onTap: () => demoSpeak(ko),
              ),
              DemoChoice(
                key: const ValueKey('demo-own-turn'),
                label: _ownTurn
                    ? t.onboardingDemoAgain
                    : t.onboardingDemoYourTurn,
                selected: _ownTurn,
                onTap: () {
                  demoStop();
                  setState(() {
                    _ownTurn = !_ownTurn;
                    _model = false;
                    _meaning = false;
                  });
                },
              ),
            ],
          ),
        ] else
          DemoChoiceRow(
            children: [
              if (_skill == 0)
                DemoChoice(
                  key: const ValueKey('demo-course-audio'),
                  label: demoPlaying
                      ? t.onboardingDemoStop
                      : t.onboardingDemoListen,
                  icon: demoPlaying ? Icons.stop : Icons.volume_up_outlined,
                  onTap: () => demoSpeak(ko),
                ),
              DemoChoice(
                key: const ValueKey('demo-meaning'),
                label: _meaning
                    ? t.onboardingDemoKorean
                    : t.onboardingDemoMeaning,
                selected: _meaning,
                onTap: () => setState(() => _meaning = !_meaning),
              ),
            ],
          ),
      ],
    );
  }

  Widget _conversation(Map<String, dynamic> conversation) {
    final t = AppL10n.of(context);
    final prompt = conversation['prompt'] as Map<String, dynamic>;
    final reply = conversation['reply'] as Map<String, dynamic>;
    Widget bubble(Map<String, dynamic> value, bool own) => Expanded(
      child: Container(
        key: ValueKey(own ? 'demo-reply-bubble' : 'demo-partner-bubble'),
        margin: EdgeInsets.only(
          left: own ? 18 : 0,
          right: own ? 0 : 18,
          bottom: 4,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        decoration: BoxDecoration(
          color: own
              ? Theme.of(context).colorScheme.primaryContainer
              : Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          children: [
            Text(
              own ? t.onboardingDemoYourReply : t.onboardingDemoPartner,
              style: const TextStyle(fontSize: 13),
            ),
            Expanded(
              child: own && !_reply
                  ? Center(
                      child: DemoChoice(
                        key: const ValueKey('demo-show-reply'),
                        label: t.onboardingDemoYourReply,
                        onTap: () => setState(() => _reply = true),
                      ),
                    )
                  : DemoPagedText(
                      text: _meaning
                          ? demoMeaning(context, value)
                          : value['ko'] as String,
                      korean: !_meaning,
                      fontSize: _meaning ? 17 : 23,
                    ),
            ),
          ],
        ),
      ),
    );
    return Column(
      children: [
        bubble(prompt, false),
        bubble(reply, true),
        DemoChoiceRow(
          children: [
            DemoChoice(
              label: demoPlaying
                  ? t.onboardingDemoStop
                  : t.onboardingDemoListen,
              icon: demoPlaying ? Icons.stop : Icons.volume_up_outlined,
              onTap: () => demoSpeak((_reply ? reply : prompt)['ko'] as String),
            ),
            DemoChoice(
              label: _meaning
                  ? t.onboardingDemoKorean
                  : t.onboardingDemoMeaning,
              onTap: () => setState(() => _meaning = !_meaning),
            ),
          ],
        ),
      ],
    );
  }
}

// Letter forms, stroke order, sounds and examples: approved Sites app/begin/model.ts.
const _letters = ['ㄱ', 'ㄴ', 'ㅏ', 'ㅗ'];
const _sounds = ['그', '느', '아', '오'];
const _syllables = ['가', '나', '아', '오'];
const _words = ['가방', '나무', '아빠', '오리'];
const _strokes = [
  [
    [Offset(32, 50), Offset(180, 50), Offset(180, 182)],
  ],
  [
    [Offset(42, 28), Offset(42, 178), Offset(184, 178)],
  ],
  [
    [Offset(88, 25), Offset(88, 195)],
    [Offset(88, 108), Offset(163, 108)],
  ],
  [
    [Offset(110, 42), Offset(110, 118)],
    [Offset(25, 118), Offset(195, 118)],
  ],
];

class _LetterDemo extends StatefulWidget {
  const _LetterDemo();
  @override
  State<_LetterDemo> createState() => _LetterDemoState();
}

class _LetterDemoState extends OnboardingDemoSpeechState<_LetterDemo>
    with SingleTickerProviderStateMixin {
  final _trace = TraceCanvasController();
  late final _animation = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1600),
  );
  int _letter = 0;
  bool _showWord = false;
  @override
  void dispose() {
    _animation.dispose();
    _trace.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);
    final meanings = [
      t.onboardingDemoBag,
      t.onboardingDemoTree,
      t.onboardingDemoDad,
      t.onboardingDemoDuck,
    ];
    return LayoutBuilder(
      builder: (context, bounds) {
        if (bounds.maxHeight < 340 ||
            MediaQuery.textScalerOf(context).scale(1) > 1.5) {
          return _compactLetter(meanings);
        }
        return Column(
          children: [
            DemoChoiceRow(
              children: [
                for (var i = 0; i < _letters.length; i++)
                  DemoChoice(
                    key: ValueKey('demo-letter-$i'),
                    label: _letters[i],
                    korean: true,
                    selected: i == _letter,
                    onTap: () {
                      demoStop();
                      _animation.reset();
                      _trace.reset();
                      setState(() => _letter = i);
                    },
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Text(t.onboardingDemoTrace, style: const TextStyle(fontSize: 13)),
            Expanded(
              child: Center(
                child: AspectRatio(
                  aspectRatio: 1,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      AnimatedBuilder(
                        animation: _animation,
                        builder: (context, _) => CustomPaint(
                          painter: _StrokePainter(
                            _letter,
                            _animation.value,
                            Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ),
                      TraceCanvas(
                        controller: _trace,
                        ghost: '',
                        color: SoriColors.primary,
                        errorColor: SoriColors.accent,
                        enabled: true,
                        semanticLabel:
                            '${t.onboardingDemoTrace} ${_letters[_letter]}',
                        onStrokeEnd: (_, _) {
                          _animation.reset();
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
            DemoChoiceRow(
              children: [
                DemoChoice(
                  key: const ValueKey('demo-stroke-order'),
                  label: t.onboardingDemoShowMe,
                  icon: Icons.play_arrow,
                  onTap: () {
                    _trace.reset();
                    if (MediaQuery.disableAnimationsOf(context)) {
                      _animation.value = 1;
                    } else {
                      _animation.forward(from: 0);
                    }
                  },
                ),
                DemoChoice(
                  key: const ValueKey('demo-trace-reset'),
                  label: t.onboardingDemoReset,
                  icon: Icons.replay,
                  onTap: () {
                    _trace.reset();
                    _animation.reset();
                  },
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              '${_letters[_letter]} → ${_syllables[_letter]} · ${_words[_letter]}',
              locale: const Locale('ko'),
              style: const TextStyle(fontSize: 23, fontWeight: FontWeight.w600),
            ),
            Text(meanings[_letter], style: const TextStyle(fontSize: 13)),
            DemoChoiceRow(
              children: [
                DemoChoice(
                  key: const ValueKey('demo-letter-audio'),
                  label: t.onboardingDemoSound,
                  icon: Icons.volume_up_outlined,
                  onTap: () => demoSpeak(_sounds[_letter]),
                ),
                DemoChoice(
                  key: const ValueKey('demo-word-audio'),
                  label: t.onboardingDemoWord,
                  icon: Icons.volume_up_outlined,
                  onTap: () => demoSpeak(_words[_letter]),
                ),
              ],
            ),
            if (demoAudioFailed)
              Text(
                t.onboardingDemoAudioUnavailable,
                style: const TextStyle(fontSize: 13),
              ),
          ],
        );
      },
    );
  }

  Widget _compactLetter(List<String> meanings) {
    final t = AppL10n.of(context);
    return Column(
      children: [
        DemoChoiceRow(
          children: [
            for (var i = 0; i < _letters.length; i++)
              DemoChoice(
                key: ValueKey('demo-letter-$i'),
                label: _letters[i],
                korean: true,
                dense: true,
                selected: _letter == i,
                onTap: () {
                  demoStop();
                  _trace.reset();
                  _animation.reset();
                  setState(() => _letter = i);
                },
              ),
          ],
        ),
        Expanded(
          child: _showWord
              ? Column(
                  children: [
                    Expanded(
                      child: DemoPagedText(
                        text: '${_syllables[_letter]} · ${_words[_letter]}',
                        fontSize: 30,
                      ),
                    ),
                    Text(
                      meanings[_letter],
                      style: const TextStyle(fontSize: 15),
                    ),
                  ],
                )
              : Center(
                  child: AspectRatio(
                    aspectRatio: 1,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        AnimatedBuilder(
                          animation: _animation,
                          builder: (context, _) => CustomPaint(
                            painter: _StrokePainter(
                              _letter,
                              _animation.value,
                              Theme.of(context).colorScheme.primary,
                            ),
                          ),
                        ),
                        TraceCanvas(
                          controller: _trace,
                          ghost: '',
                          color: SoriColors.primary,
                          errorColor: SoriColors.accent,
                          enabled: true,
                          semanticLabel:
                              '${t.onboardingDemoTrace} ${_letters[_letter]}',
                          onStrokeEnd: (_, _) => _animation.reset(),
                        ),
                      ],
                    ),
                  ),
                ),
        ),
        SizedBox(
          height: 48,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              if (_showWord) ...[
                IconButton(
                  key: const ValueKey('demo-letter-audio'),
                  tooltip: t.onboardingDemoSound,
                  icon: const Icon(Icons.hearing),
                  onPressed: () => demoSpeak(_sounds[_letter]),
                ),
                IconButton(
                  key: const ValueKey('demo-word-audio'),
                  tooltip: t.onboardingDemoWord,
                  icon: const Icon(Icons.volume_up_outlined),
                  onPressed: () => demoSpeak(_words[_letter]),
                ),
              ] else ...[
                IconButton(
                  key: const ValueKey('demo-stroke-order'),
                  tooltip: t.onboardingDemoShowMe,
                  icon: const Icon(Icons.play_arrow),
                  onPressed: () {
                    _trace.reset();
                    if (MediaQuery.disableAnimationsOf(context)) {
                      _animation.value = 1;
                    } else {
                      _animation.forward(from: 0);
                    }
                  },
                ),
                IconButton(
                  key: const ValueKey('demo-trace-reset'),
                  tooltip: t.onboardingDemoReset,
                  icon: const Icon(Icons.replay),
                  onPressed: () {
                    _trace.reset();
                    _animation.reset();
                  },
                ),
              ],
              IconButton(
                key: const ValueKey('demo-letter-mode'),
                tooltip: _showWord
                    ? t.onboardingDemoTrace
                    : t.onboardingDemoWord,
                icon: Icon(
                  _showWord ? Icons.draw_outlined : Icons.menu_book_outlined,
                ),
                onPressed: () {
                  demoStop();
                  setState(() => _showWord = !_showWord);
                },
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _StrokePainter extends CustomPainter {
  _StrokePainter(this.letter, this.progress, this.color);
  final int letter;
  final double progress;
  final Color color;
  @override
  void paint(Canvas canvas, Size size) {
    final scale = math.min(size.width, size.height) / 220;
    canvas.save();
    canvas.scale(scale);
    final guide = Paint()
      ..color = color.withValues(alpha: 0.12)
      ..strokeWidth = 17
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;
    final ink = Paint()
      ..color = color
      ..strokeWidth = 9
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;
    final strokes = _strokes[letter];
    for (var i = 0; i < strokes.length; i++) {
      final points = strokes[i];
      final path = Path()..moveTo(points.first.dx, points.first.dy);
      for (final point in points.skip(1)) {
        path.lineTo(point.dx, point.dy);
      }
      canvas.drawPath(path, guide);
      final fraction = (progress * strokes.length - i).clamp(0.0, 1.0);
      for (final metric in path.computeMetrics()) {
        canvas.drawPath(metric.extractPath(0, metric.length * fraction), ink);
      }
      final label = TextPainter(
        text: TextSpan(
          text: '${i + 1}',
          style: TextStyle(
            color: color,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      label.paint(canvas, points.first - const Offset(17, 19));
      label.dispose();
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _StrokePainter oldDelegate) =>
      oldDelegate.letter != letter ||
      oldDelegate.progress != progress ||
      oldDelegate.color != color;
}
