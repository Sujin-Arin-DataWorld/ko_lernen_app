import 'dart:math' as math;

import 'package:flutter/material.dart';
import '../../widgets/sori/button.dart';

import '../../l10n/generated/app_localizations.dart';
import '../../models/learner_level.dart';
import '../../services/hangul_composer.dart';
import '../../widgets/sori/tokens.dart';
import '../../widgets/sori/window_class.dart';
import 'approved_games_preview_art.dart';
import 'approved_games_preview_data.dart';
import 'onboarding_v3_demo_support.dart';

/// Real Spiele destinations behind a local preview boundary. Source models keep
/// their IDs; production game/result owners are never instantiated here.
class OnboardingGamesDemo extends StatefulWidget {
  const OnboardingGamesDemo({super.key, required this.level})
    : fullScreen = false;
  const OnboardingGamesDemo.fullScreen({super.key, required this.level})
    : fullScreen = true;
  final LearnerLevel level;
  final bool fullScreen;
  static const activityIds = [
    'chosung',
    'syllable_cross',
    'daily_game',
    'speed_match',
    'kkeunmari',
    'custom_practice',
  ];
  static const productionRoutes = [
    '/chosung',
    '/wordle',
    '/daily',
    '/speed_match',
    '/kkeunmari',
    '/custom_pack/play',
  ];
  @override
  State<OnboardingGamesDemo> createState() => _OnboardingGamesDemoState();
}

class _OnboardingGamesDemoState
    extends OnboardingDemoSpeechState<OnboardingGamesDemo> {
  late Future<ApprovedGamesPreviewData> _data;
  final _input = TextEditingController();
  final _composer = HangulComposer();
  int? _game;
  int _pair = -1;
  final Set<int> _matched = {};
  (int, int)? _cell;
  final Map<(int, int), String> _cross = {};
  String? _picked;
  bool _revealed = false;
  bool? _correct;
  int _chain = 0;

  @override
  void initState() {
    super.initState();
    _data = ApprovedGamesPreviewData.load(widget.level);
  }

  @override
  void didUpdateWidget(covariant OnboardingGamesDemo oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.level != widget.level) {
      _data = ApprovedGamesPreviewData.load(widget.level);
      _reset();
    }
  }

  @override
  void dispose() {
    _input.dispose();
    super.dispose();
  }

  void _reset([int? game]) {
    demoStop();
    FocusManager.instance.primaryFocus?.unfocus();
    _input.clear();
    _composer.clear();
    setState(() {
      _game = game ?? _game;
      _pair = -1;
      _matched.clear();
      _cross.clear();
      _cell = null;
      _picked = null;
      _revealed = false;
      _correct = null;
      _chain = 0;
    });
  }

  void _back() {
    demoStop();
    FocusManager.instance.primaryFocus?.unfocus();
    if (_game != null) {
      setState(() => _game = null);
    } else if (widget.fullScreen) {
      Navigator.of(context).pop();
    }
  }

  String get _lang => Localizations.localeOf(context).languageCode;

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);
    final content = DecoratedBox(
      decoration: const BoxDecoration(
        color: Color(0xfff6e9cf),
        image: DecorationImage(
          image: AssetImage('${gamesPreviewArt}paper.png'),
          fit: BoxFit.cover,
        ),
      ),
      child: Column(
        children: [
          _header(t),
          Expanded(
            child: FutureBuilder<ApprovedGamesPreviewData>(
              future: _data,
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(t.onboardingDemoUnavailable),
                          TextButton(
                            onPressed: () => setState(
                              () => _data = ApprovedGamesPreviewData.load(
                                widget.level,
                              ),
                            ),
                            child: Text(t.btnRetry),
                          ),
                        ],
                      ),
                    ),
                  );
                }
                if (!snapshot.hasData) {
                  return const Center(
                    child: SoriLoadingIndicator(color: SoriColors.primary),
                  );
                }
                return _game == null
                    ? _picker(t, snapshot.data!)
                    : _board(snapshot.data!, t);
              },
            ),
          ),
        ],
      ),
    );
    if (!widget.fullScreen) {
      return content;
    }
    return PopScope(
      canPop: _game == null,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          _back();
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xff075347),
        body: SafeArea(child: content),
      ),
    );
  }

  Widget _header(AppL10n t) {
    final game = _game;
    final title = game == null
        ? t.onboardingCtaGames
        : t.soriStageActivityTitle(OnboardingGamesDemo.activityIds[game]);
    return DecoratedBox(
      decoration: const BoxDecoration(
        image: DecorationImage(
          image: AssetImage('${gamesPreviewArt}jade.png'),
          fit: BoxFit.cover,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(4, 4, 8, 8),
        child: Row(
          children: [
            if (game != null || widget.fullScreen)
              IconButton(
                key: ValueKey(
                  game == null ? 'demo-games-close' : 'demo-games-back',
                ),
                tooltip: game == null ? t.btnClose : t.onboardingDemoPrevious,
                onPressed: _back,
                color: const Color(0xfff9ebcf),
                icon: const Icon(Icons.chevron_left_rounded),
              ),
            Expanded(
              child: Semantics(
                header: true,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontFamily: SoriLocaleFonts.of(context).heading,
                        color: Color(0xfffff7e7),
                        fontSize: 23,
                        fontWeight: SoriLocaleFonts.of(context).headingWeight,
                        height: 1.1,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${t.guideAvailabilityPreview} · ${widget.level.display}',
                      style: const TextStyle(
                        color: Color(0xfff2d9a3),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (game != null)
              IconButton(
                key: const ValueKey('demo-game-reset'),
                tooltip: t.onboardingDemoReset,
                onPressed: _reset,
                color: const Color(0xfff9ebcf),
                icon: const Icon(Icons.replay_rounded),
              ),
          ],
        ),
      ),
    );
  }

  Widget _picker(AppL10n t, ApprovedGamesPreviewData data) => LayoutBuilder(
    builder: (context, bounds) {
      final columns =
          MediaQuery.textScalerOf(context).scale(1) > 1.4 ||
              bounds.maxWidth < SoriAdaptiveWidth.onboardingDemoCompact
          ? 1
          : bounds.maxWidth >= SoriAdaptiveWidth.onboardingDemoExpanded
          ? 3
          : 2;
      return SingleChildScrollView(
        padding: const EdgeInsets.all(12),
        child: Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (var i = 0; i < 6; i++)
              SizedBox(
                width: (bounds.maxWidth - 24 - 8 * (columns - 1)) / columns,
                child: GamesPreviewAction(
                  key: ValueKey('demo-game-$i'),
                  label: t.soriStageActivityTitle(
                    OnboardingGamesDemo.activityIds[i],
                  ),
                  onTap: () => _reset(i),
                  art: 'paper_card.png',
                  illustration: MediaQuery.textScalerOf(context).scale(1) > 1.4
                      ? null
                      : SizedBox(
                          height: 110,
                          child: switch (i) {
                            1 => Image.asset(
                              '${gamesPreviewArt}silben_board.png',
                              fit: BoxFit.contain,
                            ),
                            2 => Image.asset(
                              '${gamesPreviewArt}daily_header.png',
                              fit: BoxFit.contain,
                            ),
                            4 => Image.asset(
                              '${gamesPreviewArt}chain_board.png',
                              fit: BoxFit.contain,
                            ),
                            3 => Center(
                              child: _text(
                                '${data.words.first.korean}\n↔\n${data.words.first.translationFor(_lang)}',
                                size: 17,
                                korean: true,
                              ),
                            ),
                            _ => Center(
                              child: _text(
                                i == 0 ? 'ㄱ · ㄴ · ㄷ' : data.words.first.korean,
                                size: 30,
                                korean: true,
                              ),
                            ),
                          },
                        ),
                ),
              ),
          ],
        ),
      );
    },
  );

  Widget _board(ApprovedGamesPreviewData data, AppL10n t) =>
      SingleChildScrollView(
        key: ValueKey('demo-board-$_game'),
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 620),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                switch (_game) {
                  0 => _initials(data, t),
                  1 => _syllables(data, t),
                  2 => _daily(data, t),
                  3 => _pairs(data, t),
                  4 => _wordChain(data, t),
                  _ => _cards(data, t),
                },
                if (_correct != null) ...[
                  const SizedBox(height: 8),
                  Semantics(
                    liveRegion: true,
                    child: Text(
                      _correct! ? t.btnGewusst : t.vocabPackRecallIncorrect,
                      key: const ValueKey('demo-game-feedback'),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: _correct!
                            ? gamesPreviewInk
                            : const Color(0xff8c3425),
                      ),
                    ),
                  ),
                ],
                if (demoAudioFailed) ...[
                  const SizedBox(height: 8),
                  Text(
                    t.onboardingDemoAudioUnavailable,
                    textAlign: TextAlign.center,
                  ),
                ],
              ],
            ),
          ),
        ),
      );

  Widget _text(String value, {double size = 22, bool korean = false}) => Text(
    value,
    textAlign: TextAlign.center,
    locale: korean ? const Locale('ko') : null,
    style: TextStyle(
      fontSize: size,
      height: 1.35,
      color: gamesPreviewInk,
      fontWeight: FontWeight.w600,
      fontFamily: korean
          ? SoriFonts.learningKorean
          : SoriLocaleFonts.of(context).body,
    ),
  );
  Widget _row(List<Widget> children) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      for (var i = 0; i < children.length; i++) ...[
        if (i > 0) const SizedBox(width: 8),
        Expanded(child: children[i]),
      ],
    ],
  );
  Widget _audio(String text, AppL10n t) => TextButton.icon(
    key: const ValueKey('demo-game-audio'),
    onPressed: () => demoSpeak(text),
    icon: Icon(demoPlaying ? Icons.stop_rounded : Icons.volume_up_rounded),
    label: Text(demoPlaying ? t.onboardingDemoStop : t.btnHoeren),
    style: TextButton.styleFrom(minimumSize: const Size(48, 48)),
  );

  Widget _initials(ApprovedGamesPreviewData data, AppL10n t) {
    final word = data.words.first;
    final initials = word.korean.runes
        .map((c) => 'ㄱㄲㄴㄷㄸㄹㅁㅂㅃㅅㅆㅇㅈㅉㅊㅋㅌㅍㅎ'[(c - 0xac00) ~/ 588])
        .join(' ');
    const keys = [
      'ㄱ',
      'ㄴ',
      'ㄷ',
      'ㄹ',
      'ㅁ',
      'ㅂ',
      'ㅅ',
      'ㅇ',
      'ㅈ',
      'ㅊ',
      'ㅋ',
      'ㅌ',
      'ㅍ',
      'ㅎ',
      'ㅏ',
      'ㅑ',
      'ㅓ',
      'ㅕ',
      'ㅗ',
      'ㅛ',
      'ㅜ',
      'ㅠ',
      'ㅡ',
      'ㅣ',
      'ㅐ',
      'ㅔ',
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        GamesPreviewSurface(
          child: Column(
            children: [
              _text(initials, size: 32, korean: true),
              const SizedBox(height: 8),
              _text(word.translationFor(_lang), size: 17),
              if (_revealed) _text(word.korean, korean: true),
            ],
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          key: const ValueKey('demo-initial-input'),
          controller: _input,
          onChanged: _composer.resetTo,
          autocorrect: false,
          decoration: InputDecoration(
            labelText: t.onboardingDemoYourReply,
            border: const OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 8),
        LayoutBuilder(
          builder: (context, bounds) {
            final columns = math.max(1, (bounds.maxWidth / 56).floor());
            return Wrap(
              spacing: 4,
              runSpacing: 4,
              children: [
                for (final jamo in keys)
                  SizedBox(
                    width: (bounds.maxWidth - 4 * (columns - 1)) / columns,
                    child: GamesPreviewAction(
                      key: ValueKey('demo-jamo-$jamo'),
                      label: jamo,
                      korean: true,
                      onTap: () {
                        _composer.addJamo(jamo);
                        _input.text = _composer.text;
                      },
                    ),
                  ),
              ],
            );
          },
        ),
        const SizedBox(height: 8),
        _row([
          GamesPreviewAction(
            key: const ValueKey('demo-game-example'),
            label: t.chosungHintBtn,
            onTap: () => setState(() => _revealed = !_revealed),
          ),
          GamesPreviewAction(
            key: const ValueKey('demo-game-submit'),
            label: t.btnSubmit,
            art: 'jade_action.png',
            onTap: () =>
                setState(() => _correct = _input.text.trim() == word.korean),
          ),
        ]),
      ],
    );
  }

  Widget _syllables(ApprovedGamesPreviewData data, AppL10n t) {
    final puzzle = data.puzzle;
    final solution = puzzle.solution;
    final selected = _cell ?? solution.keys.first;
    final a1Art =
        puzzle.rows == 3 &&
        puzzle.cols == 2 &&
        MediaQuery.textScalerOf(context).scale(1) <= 1.4;
    Widget cell((int, int) at, {bool onArt = false}) => GamesPreviewAction(
      key: ValueKey('demo-cross-cell-${at.$1 * puzzle.cols + at.$2}'),
      label: _cross[at] ?? '·',
      korean: true,
      selected: selected == at,
      art: onArt ? null : 'silben_tile.png',
      onTap: () => setState(() => _cell = at),
    );
    final grid = a1Art
        ? LayoutBuilder(
            builder: (context, bounds) {
              final factor = bounds.maxWidth / 799;
              const positions = <(int, int), Rect>{
                (0, 0): Rect.fromLTWH(400, 115, 168, 140),
                (0, 1): Rect.fromLTWH(586, 115, 165, 140),
                (1, 0): Rect.fromLTWH(400, 278, 168, 140),
                (2, 0): Rect.fromLTWH(400, 433, 168, 140),
                (2, 1): Rect.fromLTWH(586, 433, 165, 140),
              };
              return SizedBox(
                height: 650 * factor,
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: Image.asset(
                        '${gamesPreviewArt}silben_board.png',
                        fit: BoxFit.fill,
                        excludeFromSemantics: true,
                      ),
                    ),
                    Positioned(
                      left: 390 * factor,
                      top: 48 * factor,
                      width: 390 * factor,
                      height: 50 * factor,
                      child: Center(
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Text(
                            (puzzle.memberships[selected]!.first).meaningFor(
                              _lang,
                            ),
                            maxLines: 1,
                            style: TextStyle(
                              fontFamily: SoriLocaleFonts.of(context).body,
                              color: const Color(0xffffedce),
                              fontSize: 14,
                              height: 1,
                            ),
                          ),
                        ),
                      ),
                    ),
                    for (final at in solution.keys)
                      if (positions[at] case final Rect rect)
                        Positioned(
                          left: rect.left * factor,
                          top: rect.top * factor,
                          width: rect.width * factor,
                          height: rect.height * factor,
                          child: cell(at, onArt: true),
                        ),
                  ],
                ),
              );
            },
          )
        : LayoutBuilder(
            builder: (context, bounds) {
              final tileWidth = math.max(
                48.0,
                MediaQuery.textScalerOf(context).scale(23) + 24,
              );
              final gridWidth = math.max(
                bounds.maxWidth - 24,
                puzzle.cols * tileWidth + (puzzle.cols - 1) * 8,
              );
              return GamesPreviewSurface(
                art: 'wood_tray.png',
                padding: const EdgeInsets.all(12),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: SizedBox(
                    width: gridWidth,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        for (var row = 0; row < puzzle.rows; row++) ...[
                          if (row > 0) const SizedBox(height: 4),
                          _row([
                            for (var col = 0; col < puzzle.cols; col++)
                              solution.containsKey((row, col))
                                  ? cell((row, col))
                                  : const SizedBox(height: 48),
                          ]),
                        ],
                      ],
                    ),
                  ),
                ),
              );
            },
          );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < puzzle.words.length; i++) ...[
          if (i > 0) const SizedBox(height: 4),
          GamesPreviewSurface(
            art: 'silben_clue.png',
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
            child: Row(
              children: [
                SizedBox(
                  width: 28,
                  child: Text(
                    '${i + 1}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: Color(0xfffff0cf),
                    ),
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Text(
                    puzzle.words[i].meaningFor(_lang),
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: gamesPreviewInk,
                    ),
                  ),
                ),
                Text(
                  puzzle.words[i].isHorizontal ? '→' : '↓',
                  style: const TextStyle(fontSize: 22, color: gamesPreviewInk),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 8),
        grid,
        const SizedBox(height: 8),
        _text(t.onboardingDemoWords, size: 17),
        const SizedBox(height: 4),
        LayoutBuilder(
          builder: (context, bounds) {
            final columns = MediaQuery.textScalerOf(context).scale(1) > 1.4
                ? 3
                : 4;
            return Wrap(
              spacing: 4,
              runSpacing: 4,
              children: [
                for (final syllable in puzzle.pool)
                  SizedBox(
                    width: (bounds.maxWidth - 4 * (columns - 1)) / columns,
                    child: GamesPreviewAction(
                      key: ValueKey('demo-choice-$syllable'),
                      label: syllable,
                      korean: true,
                      onTap: () => setState(() {
                        _correct = solution[selected] == syllable;
                        if (_correct!) {
                          _cross[selected] = syllable;
                        }
                      }),
                    ),
                  ),
              ],
            );
          },
        ),
        const SizedBox(height: 8),
        GamesPreviewAction(
          key: const ValueKey('demo-game-example'),
          label: t.chosungHintBtn,
          art: 'jade_action.png',
          onTap: () => setState(() => _cross[selected] = solution[selected]!),
        ),
      ],
    );
  }

  Widget _daily(ApprovedGamesPreviewData data, AppL10n t) {
    final item = data.daily;
    final options = [
      item.distractors.first,
      item.answer,
      ...item.distractors.skip(1),
    ].take(4).toList();
    final sentence = item.sentenceKo.replaceAll(
      '＿＿＿',
      _correct == true ? _picked ?? '＿＿＿' : '＿＿＿',
    );
    Widget choice(String value, {bool onArt = false}) => GamesPreviewAction(
      key: ValueKey('demo-choice-$value'),
      label: value,
      korean: true,
      art: onArt ? null : 'paper_action.png',
      selected: _picked == value,
      onTap: () => setState(() {
        _picked = value;
        _correct = item.accepts(value);
      }),
    );
    final availableWidth = MediaQuery.sizeOf(context).width - 56;
    final painter = TextPainter(
      textDirection: Directionality.of(context),
      textScaler: MediaQuery.textScalerOf(context),
    );
    Size measure(String text, double size, bool korean, double width) {
      painter.text = TextSpan(
        text: text,
        style: TextStyle(
          fontSize: size,
          height: 1.35,
          fontWeight: FontWeight.w600,
          fontFamily: korean
              ? SoriFonts.learningKorean
              : SoriLocaleFonts.of(context).body,
        ),
      );
      painter.layout(maxWidth: width);
      return painter.size;
    }

    final widestOption = options
        .map((value) => measure(value, 23, true, double.infinity).width)
        .reduce(math.max);
    final optionsNeedMoreWidth = widestOption + 8 > availableWidth * 335 / 850;
    final textWidth = availableWidth * 666 / 850;
    final textHeight =
        measure(sentence, 25, true, textWidth).height +
        8 +
        measure(item.meaning(_lang), 16, false, textWidth).height;
    final textNeedsMoreHeight = textHeight > availableWidth * 300 / 850;
    painter.dispose();
    if (MediaQuery.textScalerOf(context).scale(1) > 1.4 ||
        optionsNeedMoreWidth ||
        textNeedsMoreHeight) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Image.asset('${gamesPreviewArt}daily_header.png'),
          GamesPreviewSurface(
            child: Column(
              children: [
                _text(sentence, korean: true),
                const SizedBox(height: 8),
                _text(item.meaning(_lang), size: 17),
              ],
            ),
          ),
          const SizedBox(height: 8),
          for (final option in options) ...[
            choice(option),
            const SizedBox(height: 8),
          ],
          _audio(item.fullKo, t),
        ],
      );
    }
    return Column(
      children: [
        LayoutBuilder(
          builder: (context, bounds) {
            final unit = bounds.maxWidth / 850;
            const rects = [
              Rect.fromLTWH(76, 777, 335, 173),
              Rect.fromLTWH(438, 777, 335, 173),
              Rect.fromLTWH(76, 974, 335, 174),
              Rect.fromLTWH(438, 974, 335, 174),
            ];
            return SizedBox(
              height: 1580 * unit,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: Image.asset(
                      '${gamesPreviewArt}daily_board.png',
                      fit: BoxFit.fill,
                    ),
                  ),
                  Positioned(
                    left: 90 * unit,
                    top: 420 * unit,
                    width: 666 * unit,
                    height: 300 * unit,
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _text(sentence, size: 25, korean: true),
                          const SizedBox(height: 8),
                          _text(item.meaning(_lang), size: 16),
                        ],
                      ),
                    ),
                  ),
                  for (var i = 0; i < options.length; i++)
                    Positioned(
                      left: rects[i].left * unit,
                      top: rects[i].top * unit,
                      width: rects[i].width * unit,
                      height: rects[i].height * unit,
                      child: choice(options[i], onArt: true),
                    ),
                ],
              ),
            );
          },
        ),
        _audio(item.fullKo, t),
      ],
    );
  }

  Widget _pairs(ApprovedGamesPreviewData data, AppL10n t) => Column(
    children: [
      for (var row = 0; row < data.words.length; row++) ...[
        if (row > 0) const SizedBox(height: 12),
        _row([
          GamesPreviewAction(
            key: ValueKey('demo-pair-ko-$row'),
            art: 'paper_card.png',
            label:
                '${data.words[row].korean}${_matched.contains(row) ? ' ✓' : ''}',
            korean: true,
            selected: _pair == row || _matched.contains(row),
            onTap: () => setState(() => _pair = row),
          ),
          GamesPreviewAction(
            key: ValueKey('demo-pair-meaning-${2 - row}'),
            art: 'paper_card.png',
            label:
                '${data.words[2 - row].translationFor(_lang)}${_matched.contains(2 - row) ? ' ✓' : ''}',
            selected: _matched.contains(2 - row),
            onTap: _pair < 0
                ? null
                : () => setState(() {
                    _correct = _pair == 2 - row;
                    if (_correct!) {
                      _matched.add(_pair);
                      _pair = -1;
                    }
                  }),
          ),
        ]),
      ],
    ],
  );

  Widget _wordChain(ApprovedGamesPreviewData data, AppL10n t) {
    final word = data.chain[_chain];
    final largeText = MediaQuery.textScalerOf(context).scale(1) > 1.4;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (largeText) ...[
          Image.asset(
            '${gamesPreviewArt}chain_board.png',
            height: 180,
            fit: BoxFit.contain,
          ),
          Text(
            word.word,
            key: const ValueKey('demo-chain-word'),
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: SoriFonts.learningKorean,
              fontSize: 28,
              color: gamesPreviewInk,
              fontWeight: FontWeight.w800,
            ),
          ),
        ] else
          LayoutBuilder(
            builder: (context, bounds) {
              final unit = bounds.maxWidth / 850;
              return SizedBox(
                height: 848 * unit,
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: Image.asset(
                        '${gamesPreviewArt}chain_board.png',
                        fit: BoxFit.fill,
                      ),
                    ),
                    for (var i = 0; i <= _chain; i++)
                      Positioned(
                        left: (175 + 185 * i) * unit,
                        top: 150 * unit,
                        width: 130 * unit,
                        height: 160 * unit,
                        child: Center(
                          child: _text(
                            data.chain[i].word,
                            size: 18,
                            korean: true,
                          ),
                        ),
                      ),
                    Positioned(
                      left: 115 * unit,
                      top: 480 * unit,
                      width: 380 * unit,
                      height: 150 * unit,
                      child: Center(
                        child: Text(
                          word.word,
                          key: const ValueKey('demo-chain-word'),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: SoriFonts.learningKorean,
                            fontSize: 32,
                            color: gamesPreviewInk,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        _text(word.meaning(_lang), size: 17),
        _audio(word.word, t),
        if (_chain + 1 < data.chain.length) ...[
          _text(
            t.kkeunmariStartHint(word.word[word.word.length - 1]),
            size: 17,
          ),
          const SizedBox(height: 8),
          TextField(
            key: const ValueKey('demo-chain-input'),
            controller: _input,
            decoration: InputDecoration(
              hintText: t.kkeunmariInputHint,
              border: const OutlineInputBorder(),
            ),
            autocorrect: false,
          ),
          const SizedBox(height: 8),
          GamesPreviewAction(
            key: const ValueKey('demo-chain-next'),
            art: 'paper_action.png',
            label: data.chain[_chain + 1].word,
            korean: true,
            onTap: () {
              _input.text = data.chain[_chain + 1].word;
            },
          ),
          const SizedBox(height: 8),
          GamesPreviewAction(
            key: const ValueKey('demo-game-submit'),
            label: t.kkeunmariSubmit,
            art: 'chain_submit.png',
            onTap: () => setState(() {
              _correct = _input.text.trim() == data.chain[_chain + 1].word;
              if (_correct!) {
                _chain++;
                _input.clear();
              }
            }),
          ),
        ] else
          GamesPreviewAction(label: t.onboardingDemoAgain, onTap: _reset),
      ],
    );
  }

  Widget _cards(ApprovedGamesPreviewData data, AppL10n t) {
    final word = data.words.first;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _text(t.customPackPlayTitle, size: 17),
        const SizedBox(height: 12),
        SizedBox(
          height: 240,
          child: GamesPreviewAction(
            key: const ValueKey('demo-card-flip'),
            label: _revealed ? word.translationFor(_lang) : word.korean,
            korean: !_revealed,
            art: 'paper_card.png',
            onTap: () => setState(() => _revealed = !_revealed),
          ),
        ),
        const SizedBox(height: 8),
        _text(t.hintTapToFlip, size: 16),
        _audio(word.korean, t),
      ],
    );
  }
}
