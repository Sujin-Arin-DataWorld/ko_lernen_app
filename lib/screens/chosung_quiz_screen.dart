import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/vocab.dart';
import '../services/data_loader.dart';
import '../services/storage_service.dart';
import '../widgets/sori/tokens.dart';
import '../widgets/sori/card.dart';
import '../widgets/sori/button.dart';
import '../widgets/sori/celebration.dart';
import '../widgets/sori/chip.dart';
import '../widgets/sori/hanok_header.dart';
import '../widgets/sori/mascot.dart';
import '../widgets/sori/progress.dart';
import '../l10n/generated/app_localizations.dart';

const List<String> _chosungTable = [
  'ㄱ',
  'ㄲ',
  'ㄴ',
  'ㄷ',
  'ㄸ',
  'ㄹ',
  'ㅁ',
  'ㅂ',
  'ㅃ',
  'ㅅ',
  'ㅆ',
  'ㅇ',
  'ㅈ',
  'ㅉ',
  'ㅊ',
  'ㅋ',
  'ㅌ',
  'ㅍ',
  'ㅎ',
];

const List<String> _consonantPadKeys = [
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
];

/// 중성(모음) 21자 — 한글 syllable decomposition.
const List<String> _jungsungTable = [
  'ㅏ',
  'ㅐ',
  'ㅑ',
  'ㅒ',
  'ㅓ',
  'ㅔ',
  'ㅕ',
  'ㅖ',
  'ㅗ',
  'ㅘ',
  'ㅙ',
  'ㅚ',
  'ㅛ',
  'ㅜ',
  'ㅝ',
  'ㅞ',
  'ㅟ',
  'ㅠ',
  'ㅡ',
  'ㅢ',
  'ㅣ',
];

String extractChosung(String word) {
  final buf = StringBuffer();
  for (final r in word.runes) {
    if (r >= 0xAC00 && r <= 0xD7A3) {
      buf.write(_chosungTable[(r - 0xAC00) ~/ 588]);
    } else {
      buf.writeCharCode(r);
    }
  }
  return buf.toString();
}

/// Hint mode for the quiz card display.
/// - [chosung]: just initial consonants (hard, e.g. "ㄱㅇㄷ" for 귀엽다)
/// - [chosungVowel]: initial consonant + medial vowel pairs (easier,
///   e.g. "ㄱㅟ ㅇㅕ ㄷㅏ") — keeps user guessing the final but reveals vowels.
enum HintMode { chosung, chosungVowel }

/// Build the displayed pattern based on hint mode.
String buildPattern(String word, HintMode mode) {
  final parts = <String>[];
  for (final r in word.runes) {
    if (r >= 0xAC00 && r <= 0xD7A3) {
      final idx = r - 0xAC00;
      final cho = _chosungTable[idx ~/ 588];
      final jung = _jungsungTable[(idx % 588) ~/ 28];
      switch (mode) {
        case HintMode.chosung:
          parts.add(cho);
        case HintMode.chosungVowel:
          parts.add('$cho$jung');
      }
    } else {
      parts.add(String.fromCharCode(r));
    }
  }
  return parts.join(' ');
}

enum _State { waiting, correct, wrong }

class ChosungQuizScreen extends StatefulWidget {
  const ChosungQuizScreen({super.key});

  @override
  State<ChosungQuizScreen> createState() => _ChosungQuizScreenState();
}

class _ChosungQuizScreenState extends State<ChosungQuizScreen> {
  static const int _roundSize = 10;

  List<Vocab> _deck = [];
  int _idx = 0;
  int _correct = 0;
  int _wrong = 0;
  bool _hint = false;
  _State _state = _State.waiting;
  String _level = 'A1';
  // v2 (2026-05-29): 초성+모음 모드 추가 — 사용자가 너무 어렵다고 피드백.
  // 기본은 chosungVowel(쉬움) — 모음 보이면 추측 가능. 토글로 hard 모드 선택 가능.
  HintMode _mode = HintMode.chosungVowel;

  // Round tracking
  int _roundIndex = 0; // 0..roundSize-1
  int _roundCorrect = 0;
  final List<int> _roundDurationsMs = [];
  DateTime? _questionStart;
  bool _roundComplete = false;

  final _ctrl = TextEditingController();
  final _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final all = await DataLoader.loadVocab();
    final filtered =
        all
            .where(
              (v) =>
                  v.level == _level &&
                  v.korean.runes.every((c) => c >= 0xAC00 && c <= 0xD7A3),
            )
            .toList()
          ..shuffle(Random());
    if (!mounted) return;
    setState(() {
      _deck = filtered;
      _idx = 0;
      _correct = 0;
      _wrong = 0;
      _hint = false;
      _state = _State.waiting;
      _roundIndex = 0;
      _roundCorrect = 0;
      _roundDurationsMs.clear();
      _roundComplete = false;
    });
    _ctrl.clear();
    _questionStart = DateTime.now();
  }

  Vocab get _card => _deck[_idx % _deck.length];

  void _recordDuration() {
    final start = _questionStart;
    if (start != null) {
      _roundDurationsMs.add(DateTime.now().difference(start).inMilliseconds);
    }
  }

  void _submit() {
    final ans = _ctrl.text.trim();
    if (ans.isEmpty) return;
    final ok = ans == _card.korean;
    _recordDuration();
    setState(() {
      _state = ok ? _State.correct : _State.wrong;
      if (ok) {
        _correct++;
        _roundCorrect++;
      } else {
        _wrong++;
      }
    });
    // Persistenz + Haptik
    if (ok) {
      HapticFeedback.lightImpact();
      Storage.incChosungCorrect();
    } else {
      HapticFeedback.mediumImpact();
      Storage.incChosungWrong();
    }
    // M1: Das Spiel speist das SRS — gewusst/nicht gewusst fließt in die
    // Wiederholungs-Planung (gleicher Key wie Vokabel-Packs: korean-String).
    Storage.srsReview(_card.korean, gotIt: ok);
    Future.delayed(const Duration(milliseconds: 1400), _next);
  }

  void _skip() {
    HapticFeedback.selectionClick();
    _recordDuration();
    setState(() {
      _wrong++;
      _state = _State.wrong;
    });
    Storage.incChosungWrong();
    Storage.srsReview(_card.korean, gotIt: false); // M1: Skip = nicht gewusst
    Future.delayed(const Duration(milliseconds: 1000), _next);
  }

  void _next() {
    if (!mounted) return;
    final completedRound = _roundIndex + 1 >= _roundSize;
    if (completedRound) {
      setState(() {
        _roundIndex = _roundSize;
        _state = _State.waiting;
        _roundComplete = true;
        _hint = false;
      });
      _ctrl.clear();
      // 라운드 종료 — 정확도 ≥80% 때만 단청 별 burst (과한 축하 자제).
      final accuracy = _roundCorrect / _roundSize;
      if (accuracy >= 0.8) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) SoriCelebration.burst(context);
        });
      }
      return;
    }
    setState(() {
      _idx++;
      _roundIndex++;
      _hint = false;
      _state = _State.waiting;
      _ctrl.clear();
    });
    _questionStart = DateTime.now();
    _focusNode.requestFocus();
  }

  void _startNewRound() {
    HapticFeedback.selectionClick();
    setState(() {
      _idx++;
      _roundIndex = 0;
      _roundCorrect = 0;
      _roundDurationsMs.clear();
      _roundComplete = false;
      _hint = false;
      _state = _State.waiting;
    });
    _ctrl.clear();
    _questionStart = DateTime.now();
    _focusNode.requestFocus();
  }

  String? _recommendation(AppL10n t) {
    if (_roundDurationsMs.isEmpty) return null;
    final accuracy = _roundCorrect / _roundSize;
    final levels = ['A1', 'A2', 'B1', 'B2'];
    final idx = levels.indexOf(_level);
    if (accuracy >= 0.9 && idx < levels.length - 1) {
      return t.chosungRoundLevelUp(levels[idx + 1]);
    }
    if (accuracy < 0.5) {
      return t.chosungRoundReview(_level);
    }
    return t.chosungRoundKeepLevel(_level);
  }

  void _appendConsonant(String c) {
    final text = _ctrl.text + c;
    _ctrl.value = TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_deck.isEmpty) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final card = _card;
    final cs = buildPattern(card.korean, _mode);
    final showPad = _level == 'A1' || _level == 'A2';
    final roundPos =
        (_roundIndex.clamp(0, _roundSize)) + (_roundComplete ? 0 : 1);
    final roundProgress = _roundComplete
        ? 1.0
        : (_roundIndex / _roundSize).clamp(0.0, 1.0);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Anlaut-Quiz',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 8, 18, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 모듈 헤더 — calligraphy 한지 화선지 톤(붓글씨)이 chosung 자음
              // 학습과 가장 잘 어울림 (이전 porch.png는 generic 처마 풍경이었음).
              const HanokHeader(
                asset: 'assets/illustrations/hanok/calligraphy.png',
                fallbackIcon: Icons.abc_rounded,
              ),
              const SizedBox(height: Spacing.md),

              // ── 레벨 선택 ──────────────────────────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: ['A1', 'A2', 'B1', 'B2'].map((lvl) {
                  final selected = _level == lvl;
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: Spacing.xs),
                    child: SoriChip(
                      label: lvl,
                      accent: SoriColors.primary,
                      selected: selected,
                      variant: SoriChipVariant.soft,
                      fontSize: 13,
                      onTap: selected
                          ? null
                          : () {
                              setState(() => _level = lvl);
                              _load();
                            },
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 8),

              // ── 난이도 토글 (초성 only / 초성+모음) ────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SoriChip(
                    label: '초성 + 모음',
                    icon: Icons.lightbulb_outline,
                    accent: SoriColors.warning,
                    selected: _mode == HintMode.chosungVowel,
                    variant: SoriChipVariant.soft,
                    fontSize: 12,
                    onTap: _mode == HintMode.chosungVowel
                        ? null
                        : () => setState(() => _mode = HintMode.chosungVowel),
                  ),
                  const SizedBox(width: Spacing.sm),
                  SoriChip(
                    label: '초성 only',
                    icon: Icons.flash_on_rounded,
                    accent: SoriColors.danger,
                    selected: _mode == HintMode.chosung,
                    variant: SoriChipVariant.soft,
                    fontSize: 12,
                    onTap: _mode == HintMode.chosung
                        ? null
                        : () => setState(() => _mode = HintMode.chosung),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // ── 통계 칩 ────────────────────────────────────────────
              Row(
                children: [
                  SoriChip(label: '✅  $_correct', accent: SoriColors.success),
                  const SizedBox(width: Spacing.sm),
                  SoriChip(label: '❌  $_wrong', accent: SoriColors.danger),
                  const SizedBox(width: Spacing.sm),
                  SoriChip(label: '$roundPos / $_roundSize'),
                ],
              ),
              const SizedBox(height: 14),

              if (_roundComplete) ...[
                Builder(
                  builder: (context) {
                    final t = AppL10n.of(context);
                    return _RoundSummaryCard(
                      correct: _roundCorrect,
                      total: _roundSize,
                      durationsMs: _roundDurationsMs,
                      recommendation: _recommendation(t),
                      onContinue: _startNewRound,
                    );
                  },
                ),
              ] else ...[
                // ── 카드 ─────────────────────────────────────────────
                _QuizCard(
                  chosung: cs,
                  german: card.german,
                  hint: _hint,
                  state: _state,
                  correctWord: card.korean,
                  onHint: () => setState(() => _hint = true),
                ),
                const SizedBox(height: 12),
              ],

              // ── 입력 ───────────────────────────────────────────────
              if (!_roundComplete && _state == _State.waiting) ...[
                Builder(
                  builder: (context) {
                    final t = AppL10n.of(context);
                    return Column(
                      children: [
                        TextField(
                          controller: _ctrl,
                          focusNode: _focusNode,
                          autofocus: true,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                          ),
                          onSubmitted: (_) => _submit(),
                        ),
                        const SizedBox(height: Spacing.sm + 2),
                        Row(
                          children: [
                            Expanded(
                              flex: 3,
                              child: SoriButton.filled(
                                label: t.chosungSubmitBtn,
                                fullWidth: true,
                                onTap: _submit,
                              ),
                            ),
                            const SizedBox(width: Spacing.sm + 2),
                            Expanded(
                              flex: 2,
                              child: SoriButton.outlined(
                                label: t.btnSkip,
                                fullWidth: true,
                                onTap: _skip,
                              ),
                            ),
                          ],
                        ),
                      ],
                    );
                  },
                ),
                if (showPad) ...[
                  const SizedBox(height: 12),
                  _ConsonantPad(onTap: _appendConsonant),
                ],
              ],

              const Spacer(),

              // ── 진행 바 ────────────────────────────────────────────
              SoriProgressBar(
                value: roundProgress,
                thickness: 6,
                animated: true,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── 라운드 요약 카드 ──────────────────────────────────────────────────────────
class _RoundSummaryCard extends StatelessWidget {
  final int correct;
  final int total;
  final List<int> durationsMs;
  final String? recommendation;
  final VoidCallback onContinue;

  const _RoundSummaryCard({
    required this.correct,
    required this.total,
    required this.durationsMs,
    required this.recommendation,
    required this.onContinue,
  });

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);
    final s = SoriSurfaces.of(context);
    final accuracy = total == 0 ? 0 : ((correct / total) * 100).round();
    final avgSec = durationsMs.isEmpty
        ? '0.0'
        : (durationsMs.reduce((a, b) => a + b) / durationsMs.length / 1000)
              .toStringAsFixed(1);
    final accent = accuracy >= 80
        ? SoriColors.success
        : accuracy >= 50
        ? SoriColors.warning
        : SoriColors.danger;

    // 정확도에 따른 mascot emotion — 모두 PNG가 존재하는 4가지로만 매핑.
    final mascotEmotion = accuracy >= 80
        ? MascotEmotion.celebrate
        : accuracy >= 50
        ? MascotEmotion.surprised
        : MascotEmotion.worry;

    return SoriCard(
      variant: SoriCardVariant.hero,
      accent: accent,
      tinted: true,
      width: double.infinity,
      padding: const EdgeInsets.all(Spacing.xl),
      child: Column(
        children: [
          // 호랑이가 정확도에 맞춰 축하·격려·아쉬움 표정으로 등장.
          Mascot(
            kind: MascotKind.tiger,
            emotion: mascotEmotion,
            size: 88,
            animate: true,
          ),
          const SizedBox(height: Spacing.sm),
          Text(
            t.chosungRoundDoneTitle,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: accent,
            ),
          ),
          const SizedBox(height: Spacing.md),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _Stat(label: t.chosungRoundAccuracy(accuracy), color: accent),
              const SizedBox(width: Spacing.md),
              _Stat(label: t.chosungRoundAvgTime(avgSec), color: s.text),
            ],
          ),
          if (recommendation != null) ...[
            const SizedBox(height: Spacing.md),
            Text(
              recommendation!,
              style: TextStyle(
                fontSize: 14,
                color: s.textMuted,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
          const SizedBox(height: Spacing.lg),
          SoriButton.filled(
            label: t.chosungRoundContinue,
            accent: accent,
            fullWidth: true,
            onTap: onContinue,
          ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final String label;
  final Color color;
  const _Stat({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(SoriRadius.sm),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w700,
          fontSize: 13,
        ),
      ),
    );
  }
}

// ── 자음 버튼 패널 ──────────────────────────────────────────────────────────────
class _ConsonantPad extends StatelessWidget {
  final void Function(String) onTap;
  const _ConsonantPad({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: Spacing.xs + 2,
      runSpacing: Spacing.xs + 2,
      alignment: WrapAlignment.center,
      children: _consonantPadKeys
          .map(
            (c) => SoriChip(
              label: c,
              variant: SoriChipVariant.outlined,
              fontSize: 16,
              onTap: () => onTap(c),
            ),
          )
          .toList(),
    );
  }
}

// ── 퀴즈 카드 위젯 ─────────────────────────────────────────────────────────────
class _QuizCard extends StatelessWidget {
  final String chosung;
  final String german;
  final bool hint;
  final _State state;
  final String correctWord;
  final VoidCallback onHint;

  const _QuizCard({
    required this.chosung,
    required this.german,
    required this.hint,
    required this.state,
    required this.correctWord,
    required this.onHint,
  });

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);
    final s = SoriSurfaces.of(context);
    final accent = switch (state) {
      _State.correct => SoriColors.success,
      _State.wrong => SoriColors.danger,
      _State.waiting => SoriColors.primary,
    };

    return SoriCard(
      variant: SoriCardVariant.hero,
      accent: accent,
      tinted: true,
      width: double.infinity,
      padding: const EdgeInsets.all(Spacing.xl),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // v2: buildPattern이 이미 공백 포함된 display 문자열 반환.
          // 단순 chosung: "ㄱ ㅇ ㄷ"  / chosungVowel: "ㄱㅟ ㅇㅕ ㄷㅏ"
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              chosung,
              maxLines: 1,
              style: TextStyle(
                fontSize: 42,
                fontWeight: FontWeight.w900,
                color: accent,
                letterSpacing: 2,
              ),
            ),
          ),
          const SizedBox(height: 14),
          switch (state) {
            _State.correct => Text(
              '✅  $correctWord',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: SoriColors.success,
              ),
            ),
            _State.wrong => Column(
              children: [
                Text(
                  t.chosungAnswerLabel(correctWord),
                  style: TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w700,
                    color: SoriColors.danger,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  german,
                  style: TextStyle(fontSize: 14, color: s.textMuted),
                ),
              ],
            ),
            _State.waiting =>
              hint
                  ? Text(
                      german,
                      style: TextStyle(
                        fontSize: 18,
                        color: s.textMuted,
                        fontWeight: FontWeight.w600,
                      ),
                    )
                  : SoriChip(
                      label: t.chosungHintBtn,
                      icon: Icons.lightbulb_outline,
                      accent: SoriColors.warning,
                      onTap: onHint,
                    ),
          },
        ],
      ),
    );
  }
}
