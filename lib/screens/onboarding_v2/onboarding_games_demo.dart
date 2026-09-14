import 'package:flutter/material.dart';

import '../../l10n/generated/app_localizations.dart';
import '../../models/learner_level.dart';
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
  int _choicesPage = 0;
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
      _choicesPage = 0;
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
          if (bounds.maxHeight < 340 ||
              MediaQuery.textScalerOf(context).scale(1) > 1.5) {
            return _compact(data, names);
          }
          return Column(
            children: [
              for (var row = 0; row < 2; row++) ...[
                DemoChoiceRow(
                  children: [
                    for (var col = 0; col < 3; col++)
                      DemoChoice(
                        key: ValueKey('demo-game-${row * 3 + col}'),
                        label: names[row * 3 + col],
                        selected: _game == row * 3 + col,
                        onTap: () => _reset(row * 3 + col),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
              ],
              Expanded(
                child: Container(
                  key: ValueKey('demo-board-$_game'),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: _board(data),
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
                  style: const TextStyle(fontSize: 13),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _compact(Map<String, dynamic> data, List<String> names) {
    final t = AppL10n.of(context);
    if (_picker) {
      return Column(
        children: [
          for (var row = 0; row < 3; row++)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: DemoChoiceRow(
                  children: [
                    for (var col = 0; col < 2; col++)
                      DemoChoice(
                        key: ValueKey('demo-game-${row * 2 + col}'),
                        label: names[row * 2 + col],
                        onTap: () {
                          _reset(row * 2 + col);
                          setState(() => _picker = false);
                        },
                      ),
                  ],
                ),
              ),
            ),
        ],
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

  Widget _choices(List<String> values, ValueChanged<String> choose) {
    final pageCount = (values.length / 2).ceil();
    final page = _choicesPage.clamp(0, pageCount - 1);
    return Row(
      children: [
        Expanded(
          child: DemoChoiceRow(
            children: [
              for (final value in values.skip(page * 2).take(2))
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
        ),
        if (pageCount > 1)
          SizedBox(
            height: 48,
            width: 48,
            child: IconButton(
              key: const ValueKey('demo-more-choices'),
              tooltip:
                  '${AppL10n.of(context).onboardingDemoWords} ${page + 1}/$pageCount',
              onPressed: () =>
                  setState(() => _choicesPage = (page + 1) % pageCount),
              icon: const Icon(Icons.chevron_right),
            ),
          ),
      ],
    );
  }

  Widget _compactCross(Map<String, dynamic> puzzle) {
    final solution = (puzzle['solution'] as List).cast<String>();
    final rows = puzzle['rows'] as int;
    final cols = puzzle['cols'] as int;
    final row = _gridRow % rows;
    final clues = (puzzle['clues'] as List).cast<Map<String, dynamic>>();
    return Column(
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
                          key: ValueKey('demo-cross-cell-${row * cols + col}'),
                          label: _example
                              ? solution[row * cols + col]
                              : _cross[row * cols + col] ?? '·',
                          korean: true,
                          dense: true,
                          selected: _cell == row * cols + col,
                          onTap: () => setState(() => _cell = row * cols + col),
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
        Expanded(
          child: DemoPagedText(
            text: clues
                .map(
                  (clue) => '${clue['dir'] == 'h' ? '→' : '↓'} ${clue['ko']}',
                )
                .join('\n'),
            fontSize: 18,
          ),
        ),
        _choices(
          solution.where((s) => s.isNotEmpty).toSet().toList(),
          (syllable) => setState(() {
            _cross[_cell] = syllable;
            _example = false;
          }),
        ),
      ],
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
