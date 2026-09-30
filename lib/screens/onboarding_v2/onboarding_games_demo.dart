import 'package:flutter/material.dart';

import '../../l10n/generated/app_localizations.dart';
import '../../models/learner_level.dart';
import '../../widgets/sori/tokens.dart';
import '../../widgets/sori/window_class.dart';
import 'onboarding_v3_demo_support.dart';

/// Six distinct sample boards. All selections disappear when the demo closes.
class OnboardingGamesDemo extends StatefulWidget {
  const OnboardingGamesDemo({super.key, required this.level});
  final LearnerLevel level;
  @override
  State<OnboardingGamesDemo> createState() => _OnboardingGamesDemoState();
}

class _OnboardingGamesDemoState
    extends OnboardingDemoSpeechState<OnboardingGamesDemo> {
  int _game = 0;
  int _chain = 0;
  int _cell = 0;
  int _pair = -1;
  int _resetId = 0;
  String _word = '';
  final Set<int> _matched = {};
  final Map<int, String> _cross = {};
  bool _example = false;
  bool _picker = true;
  int _gridRow = 0;

  void _reset([int? game]) {
    demoStop();
    setState(() {
      _game = game ?? _game;
      _chain = 0;
      _cell = 0;
      _gridRow = 0;
      _pair = -1;
      _word = '';
      _matched.clear();
      _cross.clear();
      _example = false;
      _resetId++;
    });
  }

  @override
  void didUpdateWidget(covariant OnboardingGamesDemo oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.level != oldWidget.level) {
      _reset();
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);
    final names = [
      t.onboardingDemoInitials,
      t.onboardingDemoCross,
      t.onboardingDemoCloze,
      t.onboardingDemoPairs,
      t.onboardingDemoSentence,
      t.onboardingDemoChain,
    ];
    return LayoutBuilder(
      builder: (context, bounds) => OnboardingDemoContent(
        level: widget.level,
        builder: (data) {
          final selectorColumns = _selectorColumns(
            context,
            bounds.maxWidth,
            names,
          );
          final selectorFontSize =
              bounds.maxWidth >= SoriAdaptiveWidth.demoWideSelector
              ? 17.0
              : 15.0;
          if (bounds.maxHeight < 500 ||
              MediaQuery.textScalerOf(context).scale(1) > 1.5 ||
              selectorColumns < 3) {
            return _compact(data, names, selectorColumns, selectorFontSize);
          }
          return Column(
            children: [
              for (
                var row = 0;
                row < names.length ~/ selectorColumns;
                row++
              ) ...[
                SizedBox(
                  height: selectorFontSize >= 17 ? 64 : 48,
                  child: DemoChoiceRow(
                    children: [
                      for (var col = 0; col < selectorColumns; col++)
                        DemoChoice(
                          key: ValueKey(
                            'demo-game-${row * selectorColumns + col}',
                          ),
                          label: names[row * selectorColumns + col],
                          fontSize: selectorFontSize,
                          selected: _game == row * selectorColumns + col,
                          onTap: () => _reset(row * selectorColumns + col),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
              ],
              Expanded(
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      maxWidth: 640,
                      maxHeight: SoriAdaptiveHeight.onboardingDemoBoard,
                    ),
                    child: Container(
                      key: ValueKey('demo-board-$_game'),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Theme.of(
                          context,
                        ).colorScheme.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(SoriRadius.md),
                      ),
                      child: _board(data),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 4),
              if (_game != 4)
                DemoChoiceRow(
                  children: [
                    DemoChoice(
                      key: const ValueKey('demo-game-example'),
                      label: t.onboardingDemoExample,
                      onTap: () => setState(() => _example = !_example),
                      selected: _example,
                    ),
                    DemoChoice(
                      key: const ValueKey('demo-game-reset'),
                      label: t.onboardingDemoReset,
                      icon: Icons.replay,
                      onTap: _reset,
                    ),
                  ],
                ),
              if (demoAudioFailed)
                Text(
                  t.onboardingDemoAudioUnavailable,
                  style: SoriTextTheme.of(context).caption,
                ),
            ],
          );
        },
      ),
    );
  }

  int _selectorColumns(BuildContext context, double width, List<String> names) {
    final fontSize = width >= SoriAdaptiveWidth.demoWideSelector ? 17.0 : 15.0;
    final painter = TextPainter(
      textDirection: Directionality.of(context),
      textScaler: MediaQuery.textScalerOf(context),
      maxLines: 1,
    );
    var widestLabel = 0.0;
    for (final name in names) {
      for (final word in name.split(RegExp(r'[\s-]+'))) {
        painter.text = TextSpan(
          text: word,
          style: SoriTextTheme.of(
            context,
          ).label.copyWith(fontSize: fontSize, height: 1.15),
        );
        painter.layout();
        if (painter.width > widestLabel) {
          widestLabel = painter.width;
        }
      }
    }
    painter.dispose();
    // Include button padding and a font-rendering margin. Large text also needs
    // a comfortable card width, even when this font paints narrow words.
    final minTileWidth = MediaQuery.textScalerOf(context).scale(1) > 1.5
        ? 200.0
        : 0.0;
    for (final columns in [3, 2]) {
      final tileWidth = (width - 4 * (columns - 1)) / columns;
      if (tileWidth >= widestLabel + 24 && tileWidth >= minTileWidth) {
        return columns;
      }
    }
    return 1;
  }

  Widget _compact(
    Map<String, dynamic> data,
    List<String> names,
    int columns,
    double selectorFontSize,
  ) {
    final t = AppL10n.of(context);
    if (_picker) {
      final rowCount = (names.length / columns).ceil();
      final fontSize = selectorFontSize;
      final measuredHeight =
          MediaQuery.textScalerOf(context).scale(fontSize) * 1.15 + 16;
      final rowHeight = measuredHeight > (fontSize >= 17 ? 64 : 48)
          ? measuredHeight
          : (fontSize >= 17 ? 64.0 : 48.0);
      final grid = Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var row = 0; row < rowCount; row++)
            Padding(
              padding: EdgeInsets.only(bottom: row == rowCount - 1 ? 0 : 4),
              child: SizedBox(
                height: rowHeight,
                child: DemoChoiceRow(
                  children: [
                    for (var col = 0; col < columns; col++)
                      if (row * columns + col < names.length)
                        DemoChoice(
                          key: ValueKey('demo-game-${row * columns + col}'),
                          label: names[row * columns + col],
                          fontSize: fontSize,
                          onTap: () {
                            _reset(row * columns + col);
                            setState(() => _picker = false);
                          },
                        ),
                  ],
                ),
              ),
            ),
        ],
      );
      return LayoutBuilder(
        builder: (context, bounds) {
          final content = Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 900),
              child: grid,
            ),
          );
          if (bounds.maxHeight >=
              rowCount * rowHeight + (rowCount - 1) * 4 + 64) {
            return content;
          }
          return SingleChildScrollView(child: grid);
        },
      );
    }
    return Column(
      children: [
        SizedBox(
          height: 48,
          child: Row(
            children: [
              IconButton(
                key: const ValueKey('demo-games-back'),
                tooltip: t.onboardingDemoPrevious,
                icon: const Icon(Icons.arrow_back),
                onPressed: () {
                  demoStop();
                  setState(() => _picker = true);
                },
              ),
              Expanded(
                child: DemoPagedText(
                  text: names[_game],
                  korean: false,
                  fontSize: 15,
                ),
              ),
              if (_game != 4)
                IconButton(
                  key: const ValueKey('demo-game-example'),
                  tooltip: t.onboardingDemoExample,
                  icon: const Icon(Icons.visibility_outlined),
                  onPressed: () => setState(() => _example = !_example),
                ),
              IconButton(
                key: const ValueKey('demo-game-reset'),
                tooltip: t.onboardingDemoReset,
                icon: const Icon(Icons.replay),
                onPressed: _reset,
              ),
            ],
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(4),
            child: _board(data, compact: true),
          ),
        ),
      ],
    );
  }

  Widget _board(Map<String, dynamic> data, {bool compact = false}) {
    final t = AppL10n.of(context);
    final words = (data['words'] as List).cast<Map<String, dynamic>>();
    switch (_game) {
      case 0:
        final answer = words.first['ko'] as String;
        final initials = answer.runes
            .map((code) {
              if (code < 0xac00 || code > 0xd7a3) {
                return String.fromCharCode(code);
              }
              return 'ㄱㄲㄴㄷㄸㄹㅁㅂㅃㅅㅆㅇㅈㅉㅊㅋㅌㅍㅎ'[(code - 0xac00) ~/ 588];
            })
            .join(' ');
        return Column(
          children: [
            Expanded(
              child: DemoPagedText(
                text: _example
                    ? answer
                    : compact && _word.isNotEmpty
                    ? _word
                    : initials,
                fontSize: 36,
              ),
            ),
            Flexible(
              child: DemoPagedText(
                text: demoMeaning(context, words.first),
                korean: false,
                fontSize: 16,
              ),
            ),
            if (_word.isNotEmpty && !_example && !compact)
              Text(
                _word,
                key: const ValueKey('demo-initial-answer'),
                locale: const Locale('ko'),
                style: const TextStyle(fontSize: 24),
              ),
            _choices(
              words.map((v) => v['ko'] as String).toList(),
              (word) => setState(() => _word = word),
            ),
          ],
        );
      case 1:
        return compact
            ? _compactCross(data['cross'] as Map<String, dynamic>)
            : _crossword(data['cross'] as Map<String, dynamic>);
      case 2:
        final cloze = data['cloze'] as Map<String, dynamic>;
        final choices = [
          (cloze['distractors'] as List).first as String,
          cloze['answer'] as String,
          (cloze['distractors'] as List)[1] as String,
        ];
        return Column(
          children: [
            Expanded(
              child: DemoPagedText(
                text: (cloze['sentenceKo'] as String).replaceAll(
                  '＿＿＿',
                  _example
                      ? cloze['answer'] as String
                      : _word.isEmpty
                      ? '＿＿＿'
                      : _word,
                ),
                textKey: const ValueKey('demo-cloze-sentence'),
              ),
            ),
            _choices(choices, (word) => setState(() => _word = word)),
          ],
        );
      case 3:
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (var row = 0; row < 2; row++) ...[
              DemoChoiceRow(
                children: [
                  DemoChoice(
                    key: ValueKey('demo-pair-ko-$row'),
                    label:
                        '${words[row]['ko']}${_matched.contains(row) || _example ? ' ↔' : ''}',
                    korean: true,
                    selected: _pair == row || _matched.contains(row),
                    onTap: () => setState(() => _pair = row),
                  ),
                  DemoChoice(
                    key: ValueKey('demo-pair-meaning-${1 - row}'),
                    label: demoMeaning(context, words[1 - row]),
                    selected: _matched.contains(1 - row) || _example,
                    onTap: () => setState(() {
                      if (_pair == 1 - row) {
                        _matched.add(_pair);
                        _pair = -1;
                      }
                    }),
                  ),
                ],
              ),
              const SizedBox(height: 6),
            ],
          ],
        );
      case 4:
        return DemoSentenceTiles(
          key: ValueKey('demo-game-sentence-${widget.level.code}-$_resetId'),
          sentence: (data['course'] as Map<String, dynamic>)['ko'] as String,
        );
      case 5:
        final chain = (data['chain'] as List).cast<Map<String, dynamic>>();
        final index = _example ? chain.length - 1 : _chain;
        final current = chain[index]['ko'] as String;
        return Column(
          children: [
            Expanded(
              child: DemoPagedText(
                text: current,
                fontSize: 36,
                textKey: const ValueKey('demo-chain-word'),
              ),
            ),
            Flexible(
              child: DemoPagedText(
                text: demoMeaning(context, chain[index]),
                korean: false,
                fontSize: 16,
              ),
            ),
            if (index + 1 < chain.length)
              DemoChoice(
                key: const ValueKey('demo-chain-next'),
                label: '${current.characters.last} → ${chain[index + 1]['ko']}',
                korean: true,
                onTap: () => setState(() => _chain++),
              )
            else
              DemoChoice(label: t.onboardingDemoAgain, onTap: () => _reset()),
          ],
        );
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _choices(
    List<String> values,
    ValueChanged<String> choose, {
    int columns = 2,
  }) {
    // Keep every choice in the board's flow. The compact crossword scrolls
    // as a whole when there is not enough height for the grid and options.
    final choices = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var row = 0; row < values.length; row += columns) ...[
          if (row > 0) const SizedBox(height: 4),
          DemoChoiceRow(
            children: [
              for (final value in values.skip(row).take(columns))
                DemoChoice(
                  key: ValueKey('demo-choice-$value'),
                  label: value,
                  korean: true,
                  dense: MediaQuery.textScalerOf(context).scale(1) > 1.5,
                  selected: _word == value,
                  onTap: () => choose(value),
                ),
            ],
          ),
        ],
      ],
    );
    return choices;
  }

  Widget _compactCross(Map<String, dynamic> puzzle) {
    final solution = (puzzle['solution'] as List).cast<String>();
    final rows = puzzle['rows'] as int;
    final cols = puzzle['cols'] as int;
    final row = _gridRow % rows;
    final clues = (puzzle['clues'] as List).cast<Map<String, dynamic>>();
    return SingleChildScrollView(
      child: Column(
        children: [
          SizedBox(
            height: 48,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var col = 0; col < cols; col++)
                  SizedBox(
                    width: 48,
                    height: 48,
                    child: solution[row * cols + col].isEmpty
                        ? const SizedBox.shrink()
                        : DemoChoice(
                            key: ValueKey(
                              'demo-cross-cell-${row * cols + col}',
                            ),
                            label: _example
                                ? solution[row * cols + col]
                                : _cross[row * cols + col] ?? '·',
                            korean: true,
                            dense: true,
                            selected: _cell == row * cols + col,
                            onTap: () =>
                                setState(() => _cell = row * cols + col),
                          ),
                  ),
                IconButton(
                  key: const ValueKey('demo-cross-row'),
                  tooltip:
                      '${AppL10n.of(context).onboardingDemoNext} ${row + 1}/$rows',
                  icon: const Icon(Icons.keyboard_arrow_down),
                  onPressed: () => setState(() {
                    _gridRow = (row + 1) % rows;
                    _cell = _gridRow * cols;
                  }),
                ),
              ],
            ),
          ),
          _choices(
            solution.where((s) => s.isNotEmpty).toSet().toList(),
            (syllable) => setState(() {
              _cross[_cell] = syllable;
              _example = false;
            }),
            columns: 3,
          ),
          const SizedBox(height: Spacing.xs),
          SizedBox(
            height: 80,
            child: DemoPagedText(
              text: clues
                  .map(
                    (clue) => '${clue['dir'] == 'h' ? '→' : '↓'} ${clue['ko']}',
                  )
                  .join('\n'),
              fontSize: 18,
            ),
          ),
        ],
      ),
    );
  }

  Widget _crossword(Map<String, dynamic> puzzle) {
    final solution = (puzzle['solution'] as List).cast<String>();
    final rows = puzzle['rows'] as int;
    final cols = puzzle['cols'] as int;
    final first = solution.indexWhere((s) => s.isNotEmpty);
    final selectedCell = _cell == first
        ? solution.indexWhere((s) => s.isNotEmpty, first + 1)
        : _cell;
    final clues = (puzzle['clues'] as List).cast<Map<String, dynamic>>();
    return Column(
      children: [
        Expanded(
          child: Row(
            children: [
              SizedBox(
                width: cols * 48.0,
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      for (var row = 0; row < rows; row++)
                        Row(
                          children: [
                            for (var col = 0; col < cols; col++)
                              SizedBox(
                                width: 48,
                                height: 48,
                                child: solution[row * cols + col].isEmpty
                                    ? const SizedBox.shrink()
                                    : DemoChoice(
                                        key: ValueKey(
                                          'demo-cross-cell-${row * cols + col}',
                                        ),
                                        label:
                                            _example ||
                                                row * cols + col == first
                                            ? solution[row * cols + col]
                                            : _cross[row * cols + col] ?? '·',
                                        korean: true,
                                        selected:
                                            selectedCell == row * cols + col,
                                        onTap: row * cols + col == first
                                            ? null
                                            : () => setState(
                                                () => _cell = row * cols + col,
                                              ),
                                      ),
                              ),
                          ],
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: DemoPagedText(
                  text: clues
                      .map(
                        (clue) =>
                            '${clue['dir'] == 'h' ? '→' : '↓'} ${clue['ko']}',
                      )
                      .join('\n'),
                  fontSize: 18,
                ),
              ),
            ],
          ),
        ),
        _choices(
          solution.where((s) => s.isNotEmpty).toSet().toList(),
          (syllable) => setState(() {
            _cross[selectedCell] = syllable;
            _example = false;
          }),
        ),
      ],
    );
  }
}
