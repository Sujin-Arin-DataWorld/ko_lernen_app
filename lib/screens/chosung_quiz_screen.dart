import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/vocab.dart';
import '../models/feedback_completion.dart';
import '../models/learner_level.dart';
import '../services/data_loader.dart';
import '../services/analytics_service.dart';
import '../services/learner_level_selection.dart';
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
import '../widgets/sori/chosung_hint.dart';
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
import '../services/hangul_composer.dart';
import '../widgets/app_loading.dart';

// 화면 자판 배열. 자음 + 모음.
//
// 2026-08-12: 모음이 없어서 정답을 만들 수가 없었다("모음 클릭하는게 없어" —
// Jin). 자음만 있던 시절엔 ㅅ·ㅈ 을 눌러도 "ㅅㅈ" 이 될 뿐이라 채점
// (`답 == _card.korean`)을 통과할 방법이 아예 없었다. 모음 추가와
// HangulComposer 조합이 **함께** 있어야 ㅅ→ㅏ→ㅈ→ㅏ→ㅇ = "사장" 이 된다.
//
// 쌍자음(ㄲ·ㄸ·ㅃ·ㅆ·ㅉ)은 넣지 않았다 — 키가 5개 늘면 좁은 폰에서 줄이 밀리고,
// 초성이 쌍자음인 단어는 소수라 시스템 키보드로 입력할 수 있다. 필요해지면
// 여기만 늘리면 된다(조합기는 이미 쌍자음을 처리한다).
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

const List<String> _vowelPadKeys = [
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

enum _State { waiting, correct, wrong }

class ChosungQuizScreen extends StatefulWidget {
  const ChosungQuizScreen({super.key, this.deck});

  /// Optional notebook / pack subset. Production library play leaves this null.
  final List<Vocab>? deck;

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
    _level = learnerLevelDisplayForStoredCode(Storage.userLevelCode);
    _load();
    scheduleCoach();
    Analytics.gameStarted(gameType: 'chosung', level: _level);
  }

  Future<void> _load() async {
    _feedbackCompletion.reset();
    final source = widget.deck ?? await DataLoader.loadVocab();
    final filtered =
        source
            .where(
              (v) =>
                  (widget.deck != null || v.level == _level) &&
                  // C1/C2 vocabulary is intentionally phrase-based. Spaces
                  // are rendered as literal hint separators and remain
                  // typeable with the system keyboard used above A2.
                  v.korean.runes.every(
                    (c) => (c >= 0xAC00 && c <= 0xD7A3) || c == 0x20,
                  ),
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
      Analytics.gameCompleted(
        gameType: 'chosung',
        result: accuracy >= 0.8 ? 'win' : 'lose',
        score: (accuracy * 100).round(),
      );
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
    final levels = LearnerLevel.values.map((level) => level.display).toList();
    final idx = levels.indexOf(_level);
    if (accuracy >= 0.9 && idx < levels.length - 1) {
      return t.chosungRoundLevelUp(levels[idx + 1]);
    }
    if (accuracy < 0.5) {
      return t.chosungRoundReview(_level);
    }
    return t.chosungRoundKeepLevel(_level);
  }

  /// 화면 자판 전용 조합기. 시스템 키보드 입력은 [_syncComposer] 로 흡수한다.
  final _composer = HangulComposer();

  /// 사용자가 시스템 키보드로 직접 고쳤거나 다음 문항으로 넘어가며 _ctrl 이
  /// 비워졌으면, 조합 상태를 현재 텍스트에 맞춘다.
  ///
  /// 이 한 줄 덕분에 `_ctrl.clear()` 를 부르는 4곳(다음 문항·건너뛰기·라운드
  /// 초기화)을 따로 손보지 않아도 된다 — 어긋난 순간 다음 자판 입력에서 저절로
  /// 맞춰진다.
  void _syncComposer() {
    if (_composer.text != _ctrl.text) {
      _composer.resetTo(_ctrl.text);
    }
  }

  void _writeComposer() {
    final text = _composer.text;
    _ctrl.value = TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }

  void _appendJamo(String jamo) {
    _syncComposer();
    _composer.addJamo(jamo);
    _writeComposer();
  }

  void _backspaceJamo() {
    _syncComposer();
    _composer.backspace();
    _writeComposer();
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
                          Wrap(
                            key: _levelRowKey,
                            alignment: WrapAlignment.center,
                            spacing: Spacing.sm,
                            runSpacing: Spacing.xs,
                            children: LearnerLevel.values.map((level) {
                              final lvl = level.display;
                              final selected = _level == lvl;
                              return SoriChip(
                                key: ValueKey('chosung-level-$lvl'),
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
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 8),

                          // ── 난이도 토글 (초성 only / 초성+모음) ────────────────
                          Wrap(
                            alignment: WrapAlignment.center,
                            spacing: Spacing.sm,
                            runSpacing: Spacing.xs,
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
                              _JamoPad(
                                onJamo: _appendJamo,
                                onBackspace: _backspaceJamo,
                              ),
                            ] else ...[
                              // 자판이 사라지는 게 고장처럼 보인다는 피드백
                              // ("B부터는 없다고 설명해줘야될것같아. 오류같잖아"
                              // — Jin, 2026-08-12). 의도된 난이도 설계라는 걸
                              // 한 줄로 알린다.
                              const SizedBox(height: 12),
                              Text(
                                AppL10n.of(context).chosungPadHiddenNote,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 12.5,
                                  color: SoriColors.darkTextMuted,
                                ),
                              ),
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
/// 자음·모음 자판 + 지우기.
///
/// 모음 줄은 [SoriColors.info] 로 물들여 자음과 구분한다 — 초성 퀴즈라 자음이
/// 주역이고 모음은 음절을 완성하는 보조라는 걸 색으로 보여주는 편이 낫다.
class _JamoPad extends StatelessWidget {
  final void Function(String) onJamo;
  final VoidCallback onBackspace;
  const _JamoPad({required this.onJamo, required this.onBackspace});

  Widget _row(List<String> keys, {Color? accent}) => Wrap(
    spacing: Spacing.xs + 2,
    runSpacing: Spacing.xs + 2,
    alignment: WrapAlignment.center,
    children: keys
        .map(
          (c) => SoriChip(
            label: c,
            variant: SoriChipVariant.outlined,
            accent: accent,
            fontSize: 16,
            onTap: () => onJamo(c),
          ),
        )
        .toList(),
  );

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _row(_consonantPadKeys),
        const SizedBox(height: Spacing.xs + 2),
        _row(_vowelPadKeys, accent: SoriColors.info),
        const SizedBox(height: Spacing.xs + 2),
        SoriChip(
          label: '⌫',
          variant: SoriChipVariant.outlined,
          accent: SoriColors.warning,
          fontSize: 16,
          onTap: onBackspace,
        ),
      ],
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
          ChosungHint(word: word, mode: mode, accent: accent),
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
