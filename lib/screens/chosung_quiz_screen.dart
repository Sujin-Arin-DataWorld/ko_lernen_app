import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/vocab.dart';
import '../models/feedback_completion.dart';
import '../services/data_loader.dart';
import '../services/sound_service.dart';
import '../services/storage_service.dart';
import '../widgets/sori/tokens.dart';
import '../widgets/sori/mascot_preference.dart';
import '../widgets/sori/responsive.dart';
import '../widgets/sori/card.dart';
import '../widgets/sori/button.dart';
import '../widgets/sori/celebration.dart';
import '../widgets/sori/content_feedback_card.dart';
import '../widgets/sori/chip.dart';
import '../widgets/sori/game_reward.dart';
import '../widgets/sori/sori_icon.dart';
import '../widgets/sori/score_pop.dart';
import '../widgets/sori/hanok_header.dart';
import '../widgets/sori/mascot.dart';
import '../widgets/sori/motion.dart';
import '../widgets/sori/progress.dart';
import '../widgets/sori/wordbook_add.dart';
import '../widgets/sori/screen_background.dart';
import '../widgets/sori/screen_coach.dart';
import '../widgets/sori/spotlight_coach.dart';
import '../l10n/generated/app_localizations.dart';
import '../widgets/app_loading.dart';

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

/// 종성(받침) 28자 — index 0 = 받침 없음.
const List<String> _jongsungTable = [
  '',
  'ㄱ',
  'ㄲ',
  'ㄳ',
  'ㄴ',
  'ㄵ',
  'ㄶ',
  'ㄷ',
  'ㄹ',
  'ㄺ',
  'ㄻ',
  'ㄼ',
  'ㄽ',
  'ㄾ',
  'ㄿ',
  'ㅀ',
  'ㅁ',
  'ㅂ',
  'ㅄ',
  'ㅅ',
  'ㅆ',
  'ㅇ',
  'ㅈ',
  'ㅊ',
  'ㅋ',
  'ㅌ',
  'ㅍ',
  'ㅎ',
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

/// 받침이 하나도 없는 단어는 초성+모음 힌트가 곧 단어 전체다
/// (예: 모르다 → "ㅁㅗ ㄹㅡ ㄷㅏ" = 정답 노출). 2026-08-12 전수조사:
/// 930개 중 196개(A1 62/211)가 해당 — 쉬움 모드에서도 초성만 보여야 한다.
bool fullyRevealedByChosungVowel(String word) {
  var hasHangul = false;
  for (final r in word.runes) {
    if (r >= 0xAC00 && r <= 0xD7A3) {
      hasHangul = true;
      if ((r - 0xAC00) % 28 != 0) {
        return false; // 받침 있는 음절 → 힌트가 정답을 다 드러내지 않음
      }
    }
  }
  return hasHangul;
}

/// Build the displayed pattern based on hint mode.
String buildPattern(String word, HintMode mode) {
  // 쉬움 모드라도 정답이 통째로 노출되는 단어(전 음절 무받침)는 초성으로 강등.
  final effective =
      (mode == HintMode.chosungVowel && fullyRevealedByChosungVowel(word))
      ? HintMode.chosung
      : mode;
  final parts = <String>[];
  for (final r in word.runes) {
    if (r >= 0xAC00 && r <= 0xD7A3) {
      final idx = r - 0xAC00;
      final cho = _chosungTable[idx ~/ 588];
      final jung = _jungsungTable[(idx % 588) ~/ 28];
      switch (effective) {
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

class _ChosungQuizScreenState extends State<ChosungQuizScreen>
    with ScreenCoachMixin<ChosungQuizScreen> {
  static const int _roundSize = 10;

  // ── 코치마크 타겟 ──
  final GlobalKey _quizCardKey = GlobalKey();
  final GlobalKey _levelRowKey = GlobalKey();
  final GlobalKey _inputFieldKey = GlobalKey();

  @override
  String get coachId => 'chosung';

  @override
  bool get coachReady => _deck.isNotEmpty;

  @override
  List<SpotlightStep> buildCoachSteps(BuildContext context) {
    final t = AppL10n.of(context);
    return [
      SpotlightStep(
        targetKey: _quizCardKey,
        title: t.coachChosungStep1Title,
        body: t.coachChosungStep1Body,
        icon: Icons.grid_view_rounded,
      ),
      SpotlightStep(
        targetKey: _levelRowKey,
        title: t.coachChosungStep2Title,
        body: t.coachChosungStep2Body,
        icon: Icons.tune_rounded,
      ),
      SpotlightStep(
        targetKey: _inputFieldKey,
        title: t.coachChosungStep3Title,
        body: t.coachChosungStep3Body,
        icon: Icons.keyboard_rounded,
      ),
    ];
  }

  List<Vocab> _deck = [];
  int _idx = 0;
  int _correct = 0;
  int _wrong = 0;
  _State _state = _State.waiting;
  String _level = 'A1';
  // v2 (2026-05-29): 초성+모음 모드 추가 — 사용자가 너무 어렵다고 피드백.
  // 기본은 chosungVowel(쉬움) — 모음 보이면 추측 가능. 토글로 hard 모드 선택 가능.
  HintMode _mode = HintMode.chosungVowel;

  // Round tracking
  int _roundIndex = 0; // 0..roundSize-1
  int _roundCorrect = 0;
  int _combo = 0; // 연속 정답 (도파민 루프)
  final List<int> _roundDurationsMs = [];
  DateTime? _questionStart;
  bool _roundComplete = false;
  int _roundXp = 0;
  bool _roundNewBest = false;
  final FeedbackCompletionSlot _feedbackCompletion = FeedbackCompletionSlot();

  final _ctrl = TextEditingController();
  final _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _load();
    scheduleCoach();
  }

  Future<void> _load() async {
    _feedbackCompletion.reset();
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
      SoundService.correct();
      Storage.incChosungCorrect();
      _combo++;
      if (_combo >= 3) {
        SoundService.combo();
        ScorePop.show(
          context,
          AppL10n.of(context).comboPop(_combo),
          color: SoriColors.tiger,
        );
      }
    } else {
      HapticFeedback.mediumImpact();
      SoundService.wrong();
      Storage.incChosungWrong();
      _combo = 0;
    }
    // M1: Das Spiel speist das SRS — gewusst/nicht gewusst fließt in die
    // Wiederholungs-Planung (gleicher Key wie Vokabel-Packs: korean-String).
    Storage.srsReview(_card.korean, gotIt: ok);
    // 정답은 짧게(700ms) — 이미 맞은 걸 아는데 1.4s 대기는 체감상 "느리다".
    // 오답(1000ms)은 정답을 읽을 시간이 필요해 더 길게 유지한다.
    Future.delayed(Duration(milliseconds: ok ? 700 : 1000), _next);
  }

  void _skip() {
    HapticFeedback.selectionClick();
    _recordDuration();
    setState(() {
      _wrong++;
      _state = _State.wrong;
    });
    Storage.incChosungWrong();
    _combo = 0;
    Storage.srsReview(_card.korean, gotIt: false); // M1: Skip = nicht gewusst
    Future.delayed(const Duration(milliseconds: 1000), _next);
  }

  void _next() {
    if (!mounted) return;
    final completedRound = _roundIndex + 1 >= _roundSize;
    if (completedRound) {
      final averageDurationMs = _roundDurationsMs.isEmpty
          ? 0
          : _roundDurationsMs.reduce((a, b) => a + b) ~/
                _roundDurationsMs.length;
      _feedbackCompletion.complete(
        () => FeedbackCompletion.chosung(
          contentLabel: AppL10n.of(context).gameChosungTitle,
          level: _level,
          correct: _roundCorrect,
          total: _roundSize,
          averageDurationMs: averageDurationMs,
        ),
      );
      setState(() {
        _roundIndex = _roundSize;
        _state = _State.waiting;
        _roundComplete = true;
      });
      _ctrl.clear();
      // 라운드 종료 — XP 보상 + 개인 최고기록(정확도%).
      final accuracy = _roundCorrect / _roundSize;
      final xp = _roundCorrect * 4;
      _roundXp = xp;
      recordGameResult(
        gameId: 'chosung',
        xp: xp,
        score: (accuracy * 100).round(),
      ).then((o) {
        if (mounted) setState(() => _roundNewBest = o.isNewBest);
      });
      // 정확도 ≥80% 때만 단청 별 burst (과한 축하 자제).
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
      _state = _State.waiting;
      _ctrl.clear();
    });
    _questionStart = DateTime.now();
    _focusNode.requestFocus();
  }

  void _startNewRound() {
    HapticFeedback.selectionClick();
    _feedbackCompletion.reset();
    setState(() {
      _idx++;
      _roundIndex = 0;
      _roundCorrect = 0;
      _roundDurationsMs.clear();
      _roundComplete = false;
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
      return const Scaffold(body: AppLoading());
    }

    final card = _card;
    final showPad = _level == 'A1' || _level == 'A2';
    final roundPos =
        (_roundIndex.clamp(0, _roundSize)) + (_roundComplete ? 0 : 1);
    final roundProgress = _roundComplete
        ? 1.0
        : (_roundIndex / _roundSize).clamp(0.0, 1.0);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          AppL10n.of(context).gameChosungTitle,
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          // 현재 글자를 내 단어장에 담기.
          AddToWordbookButton(
            korean: card.korean,
            translationDe: card.german,
            romanization: card.romanization,
            posDe: card.posDe,
            exampleKorean: card.exampleKorean,
            exampleDe: card.exampleGerman,
            compact: true,
          ),
        ],
      ),
      body: SoriScreenBackground(
        child: SafeArea(
          child: SoriStudyClamp(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 8, 18, 16),
              child: Column(
                children: [
                  // 본문은 스크롤 가능 — autofocus 키보드 + 자음패드가 동시에 떠도
                  // 하단 오버플로 없이 스크롤된다. 진행 바는 아래 고정.
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // 모듈 헤더 — calligraphy 한지 화선지 톤(붓글씨)이 chosung 자음
                          // 학습과 가장 잘 어울림 (이전 porch.png는 generic 처마 풍경이었음).
                          const SoriEntrance(
                            child: HanokHeader(
                              asset:
                                  'assets/illustrations/hanok/calligraphy.png',
                              fallbackIcon: Icons.abc_rounded,
                            ),
                          ),
                          const SizedBox(height: Spacing.md),

                          // ── 레벨 선택 ──────────────────────────────────────────
                          Row(
                            key: _levelRowKey,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: ['A1', 'A2', 'B1', 'B2'].map((lvl) {
                              final selected = _level == lvl;
                              return Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: Spacing.xs,
                                ),
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
                                    : () => setState(
                                        () => _mode = HintMode.chosungVowel,
                                      ),
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
                                    : () => setState(
                                        () => _mode = HintMode.chosung,
                                      ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),

                          // ── 통계 칩 ────────────────────────────────────────────
                          // Wrap = textScale 1.3 × 308px에서 가로 오버플로 없이
                          // 다음 줄로 흐름. 이모지 → 시맨틱 아이콘(성공/실패 색).
                          Wrap(
                            spacing: Spacing.sm,
                            runSpacing: Spacing.xs,
                            children: [
                              SoriChip(
                                label: '$_correct',
                                icon: Icons.check_rounded,
                                accent: SoriColors.success,
                              ),
                              SoriChip(
                                label: '$_wrong',
                                icon: Icons.close_rounded,
                                accent: SoriColors.danger,
                              ),
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
                                  earnedXp: _roundXp,
                                  isNewBest: _roundNewBest,
                                  recommendation: _recommendation(t),
                                  feedbackCompletion:
                                      _feedbackCompletion.current,
                                  onContinue: _startNewRound,
                                );
                              },
                            ),
                          ] else ...[
                            // ── 카드 ─────────────────────────────────────────────
                            KeyedSubtree(
                              key: _quizCardKey,
                              child: _QuizCard(
                                word: card.korean,
                                mode: _mode,
                                german: card.german,
                                state: _state,
                              ),
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
                                      key: _inputFieldKey,
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
                        ],
                      ),
                    ),
                  ),

                  // ── 진행 바 (하단 고정) ────────────────────────────────
                  const SizedBox(height: 10),
                  SoriProgressBar(
                    value: roundProgress,
                    thickness: 6,
                    animated: true,
                  ),
                ],
              ),
            ),
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
  final int earnedXp;
  final bool isNewBest;
  final String? recommendation;
  final FeedbackCompletion? feedbackCompletion;
  final VoidCallback onContinue;

  const _RoundSummaryCard({
    required this.correct,
    required this.total,
    required this.durationsMs,
    required this.earnedXp,
    required this.isNewBest,
    required this.recommendation,
    required this.feedbackCompletion,
    required this.onContinue,
  });

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);
    final s = SoriSurfaces.of(context);
    final feedbackScope = ContentFeedbackControllerScope.maybeOf(context);
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
          CompanionBuilder(
            builder: (context, kind) => accuracy >= 80
                ? Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Mascot(
                        kind: kind,
                        emotion: MascotEmotion.celebrate,
                        size: 76,
                        animate: true,
                      ),
                      const SizedBox(width: 8),
                      const Mascot(
                        kind: MascotKind.magpie,
                        emotion: MascotEmotion.celebrate,
                        size: 76,
                        animate: true,
                      ),
                    ],
                  )
                : Mascot(
                    kind: kind,
                    emotion: mascotEmotion,
                    size: 88,
                    animate: true,
                  ),
            noneBuilder: (context) => Icon(
              accuracy >= 80
                  ? Icons.emoji_events_rounded
                  : Icons.insights_rounded,
              size: 82,
              color: accent,
            ),
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
          Wrap(
            alignment: WrapAlignment.center,
            spacing: Spacing.sm,
            runSpacing: Spacing.sm,
            children: [
              _Stat(label: t.chosungRoundAccuracy(accuracy), color: accent),
              _Stat(label: t.chosungRoundAvgTime(avgSec), color: s.text),
              _Stat(label: '+$earnedXp XP', color: SoriColors.gold),
            ],
          ),
          if (isNewBest) ...[
            const SizedBox(height: Spacing.sm),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(SoriGlyph.record, size: 15, color: SoriColors.gold),
                const SizedBox(width: 5),
                Text(
                  t.gameNewBest,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: SoriColors.gold,
                  ),
                ),
              ],
            ),
          ],
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
          if (feedbackCompletion != null &&
              feedbackScope != null &&
              feedbackScope.featureGate.isEnabled) ...[
            const SizedBox(height: Spacing.lg),
            ContentFeedbackCard(
              feedbackContext: feedbackCompletion!.context,
              featureGate: feedbackScope.featureGate,
              submitFeedback: feedbackScope.submitFeedback,
              completedMissionIds: feedbackScope.completedMissionIds,
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

// ── 퀴즈 카드 위젯 (v3, 2026-06-03) ───────────────────────────────────────────
// 재설계: 플랫 "ㅇㅏㅃㅏ" 텍스트 → 음절 스캐폴드(초성/중성/종성 슬롯). 채울 칸은
// 점선 박스 + 모음/받침 라벨. 뜻은 힌트 게이트 없이 항상 표시(= 단서).
class _QuizCard extends StatelessWidget {
  final String word; // 정답 한국어
  final HintMode mode;
  final String german;
  final _State state;

  const _QuizCard({
    required this.word,
    required this.mode,
    required this.german,
    required this.state,
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
          _SyllableScaffold(word: word, mode: mode, accent: accent),
          const SizedBox(height: 16),
          switch (state) {
            _State.correct => Text(
              word,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: SoriColors.success,
              ),
            ),
            _State.wrong => Column(
              children: [
                Text(
                  t.chosungAnswerLabel(word),
                  style: const TextStyle(
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
            // 뜻 항상 표시 — 글자를 떠올리는 핵심 단서.
            _State.waiting => Text(
              german,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 20,
                color: s.text,
                fontWeight: FontWeight.w700,
              ),
            ),
          },
        ],
      ),
    );
  }
}

// ── 음절 스캐폴드 ──────────────────────────────────────────────────────────────
// 각 음절 = 초성 / 중성 / (종성) 슬롯 박스. 채워진 슬롯 = 주어진 자모,
// 점선 슬롯 = 채워야 할 부분(모음/받침 라벨).
//   easy(초성+모음): 초성·중성 채움, 받침은 점선.
//   hard(초성 only): 초성 채움, 중성·받침 점선 → 받침 없는 단어(아빠)도 안 노출.
class _SyllableScaffold extends StatelessWidget {
  final String word;
  final HintMode mode;
  final Color accent;
  const _SyllableScaffold({
    required this.word,
    required this.mode,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    final showVowel = mode == HintMode.chosungVowel;
    final blocks = <Widget>[];
    for (final r in word.runes) {
      if (r >= 0xAC00 && r <= 0xD7A3) {
        final idx = r - 0xAC00;
        blocks.add(
          _box(
            _chosungTable[idx ~/ 588],
            _jungsungTable[(idx % 588) ~/ 28],
            _jongsungTable[idx % 28],
            showVowel,
          ),
        );
      } else {
        blocks.add(
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: Text(
              String.fromCharCode(r),
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w800,
                color: accent,
              ),
            ),
          ),
        );
      }
    }
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 8,
      runSpacing: 8,
      children: blocks,
    );
  }

  Widget _box(String cho, String jung, String jong, bool showVowel) {
    final slots = <Widget>[
      _Slot(text: cho, filled: true, accent: accent),
      _Slot(text: showVowel ? jung : '모음', filled: showVowel, accent: accent),
      if (jong.isNotEmpty) _Slot(text: '받침', filled: false, accent: accent),
    ];
    return Container(
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        border: Border.all(color: accent.withValues(alpha: 0.35), width: 1.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < slots.length; i++) ...[
            if (i > 0) const SizedBox(width: 4),
            slots[i],
          ],
        ],
      ),
    );
  }
}

class _Slot extends StatelessWidget {
  final String text;
  final bool filled;
  final Color accent;
  const _Slot({required this.text, required this.filled, required this.accent});

  @override
  Widget build(BuildContext context) {
    if (filled) {
      return Container(
        width: 30,
        height: 40,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: accent.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(7),
        ),
        child: Text(
          text,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w900,
            color: accent,
          ),
        ),
      );
    }
    // 채울 칸 — 점선 박스 + 무엇을 넣을지 라벨(모음/받침).
    return CustomPaint(
      painter: _DashedBoxPainter(color: accent.withValues(alpha: 0.65)),
      child: SizedBox(
        width: 30,
        height: 40,
        child: Center(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              color: accent.withValues(alpha: 0.75),
            ),
          ),
        ),
      ),
    );
  }
}

class _DashedBoxPainter extends CustomPainter {
  final Color color;
  _DashedBoxPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    final rrect = RRect.fromRectAndRadius(
      Offset.zero & size,
      const Radius.circular(7),
    );
    final path = Path()..addRRect(rrect);
    const dash = 4.0, gap = 3.0;
    for (final metric in path.computeMetrics()) {
      var dist = 0.0;
      while (dist < metric.length) {
        canvas.drawPath(metric.extractPath(dist, dist + dash), paint);
        dist += dash + gap;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedBoxPainter old) => old.color != color;
}
