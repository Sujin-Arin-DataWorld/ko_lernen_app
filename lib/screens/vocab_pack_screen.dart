import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../l10n/generated/app_localizations.dart';
import '../models/feedback_completion.dart';
import '../models/vocab.dart';
import '../models/vocab_pack.dart';
import '../services/pack_progress_service.dart';
import '../services/sound_service.dart';
import '../services/storage_service.dart';
import '../services/tts_service.dart';
import '../services/vocab_pack_service.dart';
import '../widgets/app_error.dart';
import '../widgets/app_loading.dart';
import '../widgets/flip_card.dart';
import '../widgets/sori/button.dart';
import '../widgets/sori/card.dart';
import '../widgets/sori/celebration.dart';
import '../widgets/sori/chip.dart';
import '../widgets/sori/dancheong_stamp.dart';
import '../widgets/sori/feature_coach.dart';
import '../widgets/sori/quiz_choice.dart';
import '../widgets/sori/responsive.dart';
import '../widgets/sori/score_pop.dart';
import '../widgets/sori/screen_background.dart';
import '../widgets/sori/tokens.dart';
import '../widgets/sori/wordbook_add.dart';

/// **Vocab Pack Play Screen** — Phase 2 의 3-단계 학습 플로우.
///
/// 단계 진행:
///   1. **learn**   — 일반 단어 flip cards. "Gewusst" → SRS update + 다음.
///   2. **quiz**    — 일반 단어 4지선다 (한국어 → 독일어).
///   3. **boss**    — 보스 단어 4지선다 + TTS 재생 (한국어 발음 듣고 의미).
///
/// 모든 단계 끝나면 결과 화면(`/vocab/result`)으로 push & replace.
///
/// **Args (routes)**: `packId: String` (Navigator.pushNamed argument).
class VocabPackScreen extends StatefulWidget {
  final String packId;
  final Future<VocabPack?> Function(String packId)? packLoader;
  final Future<List<VocabPack>> Function(String level)? siblingPacksLoader;

  const VocabPackScreen({
    super.key,
    required this.packId,
    this.packLoader,
    this.siblingPacksLoader,
  });

  @override
  State<VocabPackScreen> createState() => _VocabPackScreenState();
}

enum _Stage { learn, quiz, boss }

Map<String, dynamic> vocabPackResultArguments({
  required String packId,
  required String packLevel,
  required double bossAccuracy,
  required int bossCorrect,
  required int bossTotal,
  required int quizCorrect,
  required int quizTotal,
  required bool justCleared,
  required String? nextUnlockedPackId,
  required FeedbackCompletion feedbackCompletion,
}) => <String, dynamic>{
  'packId': packId,
  'packLevel': packLevel,
  'bossAccuracy': bossAccuracy,
  'bossCorrect': bossCorrect,
  'bossTotal': bossTotal,
  'quizCorrect': quizCorrect,
  'quizTotal': quizTotal,
  'justCleared': justCleared,
  'nextUnlockedPackId': nextUnlockedPackId,
  'completionId': feedbackCompletion.context.completionId,
  'feedbackContext': feedbackCompletion.context,
};

class _VocabPackScreenState extends State<VocabPackScreen> {
  bool _loading = true;
  String? _error;
  VocabPack? _pack;
  List<VocabPack> _siblingPacks = [];

  _Stage _stage = _Stage.learn;

  // Stage 1 (learn) state
  int _learnIdx = 0;
  bool _flipped = false;

  // Stage 2 (quiz) + Stage 3 (boss) state
  int _qIdx = 0;
  int _quizCorrect = 0;
  int _bossCorrect = 0;
  int _selectedChoice = -1;
  bool _choiceLocked = false;
  int _combo = 0; // 연속 정답 (도파민 루프)
  List<String>? _choices; // per-question 4-option cache

  // 동일 pack 내에서 distractor 풀로 사용. pack이 너무 작으면 sibling pack 단어로 채움.
  List<Vocab> _distractorPool = [];

  final _rng = math.Random();

  @override
  void initState() {
    super.initState();
    _load();
    // 첫 진입 시 3단계 코치마크 1회 표시.
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) {
        return;
      }
      if (!Storage.tutVocabPackSeen) {
        await showFeatureCoachSheet(context, FeatureCoach.vocabPack);
        await Storage.setTutVocabPackSeen();
      }
    });
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final providedPackLoader = widget.packLoader;
      final pack = providedPackLoader != null
          ? await providedPackLoader(widget.packId)
          : await VocabPackService.findById(widget.packId);
      if (!mounted) return;
      if (pack == null) {
        setState(() {
          _loading = false;
          _error = AppL10n.of(context).loadErrorTryAgain;
        });
        return;
      }
      // Sibling packs — Distractor 풀 보강용 (같은 level).
      final providedSiblingLoader = widget.siblingPacksLoader;
      final siblings = providedSiblingLoader != null
          ? await providedSiblingLoader(pack.level)
          : await VocabPackService.packsForLevel(pack.level);
      if (!mounted) return;
      final pool = <Vocab>[
        ...pack.words,
        for (final p in siblings)
          if (p.id != pack.id) ...p.words,
      ];
      setState(() {
        _pack = pack;
        _siblingPacks = siblings;
        _distractorPool = pool;
        _loading = false;
      });
      _prepareNextQuestion(); // pre-warm choice cache for stage 1 → 2 transition
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = AppL10n.of(context).loadErrorTryAgain;
      });
    }
  }

  List<Vocab> get _normalWords => _pack?.normalWords.toList() ?? const [];

  List<Vocab> get _bossWords => _pack?.bossWords.toList() ?? const [];

  Vocab? get _currentLearn =>
      _learnIdx < _normalWords.length ? _normalWords[_learnIdx] : null;

  Vocab? get _currentQuiz {
    switch (_stage) {
      case _Stage.learn:
        return null;
      case _Stage.quiz:
        return _qIdx < _normalWords.length ? _normalWords[_qIdx] : null;
      case _Stage.boss:
        return _qIdx < _bossWords.length ? _bossWords[_qIdx] : null;
    }
  }

  // ── Stage 1 (Learn) ────────────────────────────────────────────────

  void _learnGotIt() {
    final cur = _currentLearn;
    if (cur == null) return;
    HapticFeedback.lightImpact();
    Storage.addVokSeen(cur.korean);
    // ignore: discarded_futures
    Storage.srsReview(cur.korean, gotIt: true);
    _advanceLearn();
  }

  void _learnDontKnow() {
    final cur = _currentLearn;
    if (cur == null) return;
    HapticFeedback.mediumImpact();
    Storage.addVokSeen(cur.korean);
    // ignore: discarded_futures
    Storage.srsReview(cur.korean, gotIt: false);
    _advanceLearn();
  }

  void _advanceLearn() {
    final pack = _pack;
    if (pack == null) return;
    setState(() {
      _flipped = false;
      _learnIdx++;
    });
    if (_learnIdx >= _normalWords.length) {
      // Stage 1 끝 — wordsLearned 기록 후 stage 2 진입
      // ignore: discarded_futures
      PackProgressService.recordWordLearned(pack);
      _enterQuiz();
    }
  }

  // ── Stage 2 / 3 (Quiz / Boss) ──────────────────────────────────────

  void _enterQuiz() {
    if (_normalWords.isEmpty) {
      // 일반 단어 없으면 바로 boss
      _enterBoss();
      return;
    }
    setState(() {
      _stage = _Stage.quiz;
      _qIdx = 0;
      _selectedChoice = -1;
      _choiceLocked = false;
      _choices = null;
    });
    _prepareNextQuestion();
    // 스테이지 전환 인라인 배너 — 최초 1회만 (모달보다 학습 흐름 덜 끊음).
    if (!Storage.tutPackQuizSeen && mounted) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (!mounted) {
          return;
        }
        await ScaffoldMessenger.of(context)
            .showSnackBar(
              SnackBar(
                content: Text(AppL10n.of(context).coachPackStageQuiz),
                duration: const Duration(seconds: 3),
              ),
            )
            .closed;
        await Storage.setTutPackQuizSeen();
      });
    }
  }

  void _enterBoss() {
    if (_bossWords.isEmpty) {
      // 보스 없으면 perfect로 간주 (edge case — 작은 팩)
      _finish(bossAccuracy: 1.0, bossCorrect: 0, bossTotal: 0);
      return;
    }
    setState(() {
      _stage = _Stage.boss;
      _qIdx = 0;
      _selectedChoice = -1;
      _choiceLocked = false;
      _choices = null;
    });
    _prepareNextQuestion();
    // Boss 첫 단어 자동 TTS
    final cur = _currentQuiz;
    if (cur != null) {
      // ignore: discarded_futures
      TtsService.speak(cur.korean);
    }
    // 스테이지 전환 인라인 배너 — 최초 1회만.
    if (!Storage.tutPackBossSeen && mounted) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (!mounted) {
          return;
        }
        await ScaffoldMessenger.of(context)
            .showSnackBar(
              SnackBar(
                content: Text(AppL10n.of(context).coachPackStageBoss),
                duration: const Duration(seconds: 3),
              ),
            )
            .closed;
        await Storage.setTutPackBossSeen();
      });
    }
  }

  /// 4지선다 옵션 생성 — 정답 + 같은 level pool 에서 3 distractor.
  void _prepareNextQuestion() {
    final cur = _currentQuiz;
    if (cur == null) return;
    final lang = Localizations.localeOf(context).languageCode;
    final correct = cur.translationFor(lang);
    final pool = _distractorPool
        .where(
          (v) => v.korean != cur.korean && v.translationFor(lang) != correct,
        )
        .map((v) => v.translationFor(lang))
        .toSet()
        .toList();
    pool.shuffle(_rng);
    final distractors = pool.take(3).toList();
    final all = <String>[correct, ...distractors];
    all.shuffle(_rng);
    setState(() {
      _choices = all;
      _selectedChoice = -1;
      _choiceLocked = false;
    });
  }

  void _selectChoice(int i) {
    if (_choiceLocked) return;
    final cur = _currentQuiz;
    final choices = _choices;
    if (cur == null || choices == null) return;
    final lang = Localizations.localeOf(context).languageCode;
    final isCorrect = choices[i] == cur.translationFor(lang);
    setState(() {
      _selectedChoice = i;
      _choiceLocked = true;
    });
    if (isCorrect) {
      // 정답 순간 보상 — 햅틱 + 효과음 + 색종이 burst + 콤보.
      HapticFeedback.lightImpact();
      SoundService.correct();
      SoriCelebration.burst(context);
      _combo++;
      if (_combo >= 3) {
        SoundService.combo();
        ScorePop.show(
          context,
          AppL10n.of(context).comboPop(_combo),
          color: SoriColors.tiger,
        );
      }
      if (_stage == _Stage.quiz) {
        _quizCorrect++;
        Storage.addVokSeen(cur.korean);
        // ignore: discarded_futures
        Storage.srsReview(cur.korean, gotIt: true);
      } else {
        _bossCorrect++;
        Storage.addVokSeen(cur.korean);
        // ignore: discarded_futures
        Storage.srsReview(cur.korean, gotIt: true);
      }
    } else {
      // 오답 — 더 강한 햅틱 + 부드러운 효과음, 콤보 리셋.
      HapticFeedback.mediumImpact();
      SoundService.wrong();
      _combo = 0;
      // ignore: discarded_futures
      Storage.srsReview(cur.korean, gotIt: false);
    }
    // 짧은 피드백 후 다음 질문
    Future.delayed(const Duration(milliseconds: 850), _advanceQuiz);
  }

  void _advanceQuiz() {
    if (!mounted) return;
    final isQuiz = _stage == _Stage.quiz;
    final total = isQuiz ? _normalWords.length : _bossWords.length;
    if (_qIdx + 1 >= total) {
      if (isQuiz) {
        _enterBoss();
      } else {
        _finish(
          bossAccuracy: _bossWords.isEmpty
              ? 1.0
              : _bossCorrect / _bossWords.length,
          bossCorrect: _bossCorrect,
          bossTotal: _bossWords.length,
        );
      }
      return;
    }
    setState(() {
      _qIdx++;
      _selectedChoice = -1;
      _choiceLocked = false;
      _choices = null;
    });
    _prepareNextQuestion();
    if (_stage == _Stage.boss) {
      final cur = _currentQuiz;
      if (cur != null) {
        // ignore: discarded_futures
        TtsService.speak(cur.korean);
      }
    }
  }

  // ── Finish ─────────────────────────────────────────────────────────

  Future<void> _finish({
    required double bossAccuracy,
    required int bossCorrect,
    required int bossTotal,
  }) async {
    final pack = _pack;
    if (pack == null) return;
    final lang = Localizations.localeOf(context).languageCode;
    final feedbackCompletion = FeedbackCompletion.vocabPack(
      packId: pack.id,
      contentLabel: VocabPackService.displayLabel(pack.id, lang: lang),
      level: pack.level,
      bossCorrect: bossCorrect,
      bossTotal: bossTotal,
      quizCorrect: _quizCorrect,
      quizTotal: _normalWords.length,
    );
    // SiblingPacks 같은 level (이미 _siblingPacks). 정렬된 pack list.
    final result = await PackProgressService.recordBossAttempt(
      pack,
      _siblingPacks,
      bossAccuracy: bossAccuracy,
    );
    // XP 보상 (Plan §4.4) — wordsTotal*5 + bossCorrect*10
    await Storage.addXp(pack.total * 5 + bossCorrect * 10);
    // 도장 획득 — 첫 클리어 시 토픽군 motif 도장을 도장첩에 추가.
    if (result.justCleared) {
      await Storage.addEarnedStamp(motifForPackId(pack.id).name);
    }

    if (!mounted) return;
    Navigator.of(context).pushReplacementNamed(
      '/vocab/result',
      arguments: vocabPackResultArguments(
        packId: pack.id,
        packLevel: pack.level,
        bossAccuracy: bossAccuracy,
        bossCorrect: bossCorrect,
        bossTotal: bossTotal,
        quizCorrect: _quizCorrect,
        quizTotal: _normalWords.length,
        justCleared: result.justCleared,
        nextUnlockedPackId: result.nextUnlocked?.id,
        feedbackCompletion: feedbackCompletion,
      ),
    );
  }

  // ── Build ──────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);

    if (_loading) {
      return Scaffold(
        appBar: AppBar(title: Text(t.vocabPackPlayTitle)),
        body: const AppLoading(),
      );
    }
    if (_error != null || _pack == null) {
      return Scaffold(
        appBar: AppBar(title: Text(t.vocabPackPlayTitle)),
        body: AppError(message: _error ?? 'unknown error', onRetry: _load),
      );
    }

    final pack = _pack!;
    final title = VocabPackService.displayLabel(pack.id);
    // 현재 보고 있는 단어(학습/퀴즈/보스)를 바로 내 단어장에 담기.
    final Vocab? addable = _stage == _Stage.learn
        ? _currentLearn
        : _currentQuiz;

    return Scaffold(
      appBar: AppBar(
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        actions: [
          if (addable != null)
            AddToWordbookButton(
              korean: addable.korean,
              translationDe: addable.german,
              romanization: addable.romanization,
              posDe: addable.posDe,
              exampleKorean: addable.exampleKorean,
              exampleDe: addable.exampleGerman,
              compact: true,
            ),
        ],
      ),
      body: SoriScreenBackground(
        child: SafeArea(
          child: SoriCenterClamp(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: Column(
                children: [
                  _StageBar(stage: _stage),
                  const SizedBox(height: Spacing.md),
                  Expanded(child: _buildStageBody(t)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStageBody(AppL10n t) {
    switch (_stage) {
      case _Stage.learn:
        return _buildLearn(t);
      case _Stage.quiz:
      case _Stage.boss:
        return _buildQuiz(t);
    }
  }

  Widget _buildLearn(AppL10n t) {
    final cur = _currentLearn;
    if (cur == null) {
      // 일반 단어 0개인 edge case (보스만 있는 팩) → 바로 quiz/boss
      WidgetsBinding.instance.addPostFrameCallback((_) => _enterQuiz());
      return const SizedBox.shrink();
    }
    return Column(
      children: [
        Row(
          children: [
            SoriChip(
              label: '${_learnIdx + 1} / ${_normalWords.length}',
              accent: SoriColors.info,
            ),
            const SizedBox(width: Spacing.sm),
            Text(
              t.vocabPackLearnHint,
              style: TextStyle(
                fontSize: 12,
                color: SoriSurfaces.of(context).textMuted,
              ),
            ),
          ],
        ),
        const SizedBox(height: Spacing.md),
        Expanded(
          child: FlipCard(
            flipped: _flipped,
            onTap: () {
              HapticFeedback.selectionClick();
              setState(() => _flipped = !_flipped);
            },
            front: _FlipFront(v: cur),
            back: _FlipBack(v: cur),
          ),
        ),
        const SizedBox(height: Spacing.md),
        Row(
          children: [
            Expanded(
              child: SoriButton(
                label: t.vocabPackDontKnow,
                variant: SoriButtonVariant.outlined,
                accent: SoriColors.danger,
                onTap: _learnDontKnow,
              ),
            ),
            const SizedBox(width: Spacing.md),
            Expanded(
              child: SoriButton(
                label: t.vocabPackGotIt,
                variant: SoriButtonVariant.filled,
                accent: SoriColors.success,
                onTap: _learnGotIt,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildQuiz(AppL10n t) {
    final cur = _currentQuiz;
    final choices = _choices;
    if (cur == null || choices == null) {
      return const Center(child: CircularProgressIndicator());
    }
    final total = _stage == _Stage.quiz
        ? _normalWords.length
        : _bossWords.length;
    final s = SoriSurfaces.of(context);

    return Column(
      children: [
        Row(
          children: [
            SoriChip(label: '${_qIdx + 1} / $total', accent: SoriColors.info),
            const SizedBox(width: Spacing.sm),
            Text(
              _stage == _Stage.boss ? t.vocabPackBossHint : t.vocabPackQuizHint,
              style: TextStyle(fontSize: 12, color: s.textMuted),
            ),
          ],
        ),
        const SizedBox(height: Spacing.md),
        // Korean prompt + (boss only) TTS replay button
        SoriCard(
          variant: SoriCardVariant.hero,
          accent: _stage == _Stage.boss ? SoriColors.warning : SoriColors.info,
          tinted: true,
          child: Column(
            children: [
              Text(
                cur.korean,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: Spacing.xs),
              Text(
                '[${cur.romanization}]',
                style: TextStyle(
                  fontSize: 14,
                  color: s.textMuted,
                  fontStyle: FontStyle.italic,
                ),
              ),
              if (_stage == _Stage.boss) ...[
                const SizedBox(height: Spacing.md),
                SoriButton(
                  label: t.vocabPackBossReplayAudio,
                  icon: Icons.volume_up_rounded,
                  variant: SoriButtonVariant.outlined,
                  accent: SoriColors.warning,
                  onTap: () {
                    // ignore: discarded_futures
                    TtsService.speak(cur.korean);
                  },
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: Spacing.lg),
        // 4 choices — 중앙 정렬 + 스크롤 안전
        Expanded(
          child: Center(
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(choices.length, (i) {
                  final text = choices[i];
                  final isCorrect =
                      text ==
                      cur.translationFor(
                        Localizations.localeOf(context).languageCode,
                      );

                  return Padding(
                    padding: const EdgeInsets.only(bottom: Spacing.sm),
                    child: QuizChoice(
                      text: text,
                      isCorrect: isCorrect,
                      isSelected: i == _selectedChoice,
                      revealed: _choiceLocked,
                      onSelected: _choiceLocked ? null : () => _selectChoice(i),
                    ),
                  );
                }),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _StageBar extends StatelessWidget {
  final _Stage stage;
  const _StageBar({required this.stage});

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);
    final stages = [
      ('learn', t.vocabPackStageLearn, _Stage.learn),
      ('quiz', t.vocabPackStageQuiz, _Stage.quiz),
      ('boss', t.vocabPackStageBoss, _Stage.boss),
    ];
    return Row(
      children: stages.map((triple) {
        final active = triple.$3 == stage;
        final done = stage.index > triple.$3.index;
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: Container(
              height: 6,
              decoration: BoxDecoration(
                color: done
                    ? SoriColors.success
                    : (active
                          ? SoriColors.info
                          : SoriColors.info.withValues(alpha: 0.15)),
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _FlipFront extends StatelessWidget {
  final Vocab v;
  const _FlipFront({required this.v});

  @override
  Widget build(BuildContext context) {
    final s = SoriSurfaces.of(context);
    return SoriCard(
      variant: SoriCardVariant.hero,
      accent: SoriColors.info,
      tinted: true,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              v.korean,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: Spacing.sm),
            Text(
              '[${v.romanization}]',
              style: TextStyle(
                fontSize: 16,
                color: s.textMuted,
                fontStyle: FontStyle.italic,
              ),
            ),
            const SizedBox(height: Spacing.md),
            IconButton(
              icon: const Icon(Icons.volume_up_rounded, size: 28),
              onPressed: () {
                // ignore: discarded_futures
                TtsService.speak(v.korean);
              },
            ),
            const SizedBox(height: Spacing.md),
            // 인라인 아이콘 + 힌트 — Text.rich라 좁은 폭에서 자연스럽게 줄바꿈.
            Text.rich(
              TextSpan(
                children: [
                  WidgetSpan(
                    alignment: PlaceholderAlignment.middle,
                    child: Icon(
                      Icons.touch_app_outlined,
                      size: 14,
                      color: s.textDim,
                    ),
                  ),
                  const WidgetSpan(child: SizedBox(width: 4)),
                  TextSpan(text: AppL10n.of(context).vocabPackTapToFlip),
                ],
              ),
              style: TextStyle(fontSize: 12, color: s.textDim),
            ),
          ],
        ),
      ),
    );
  }
}

class _FlipBack extends StatelessWidget {
  final Vocab v;
  const _FlipBack({required this.v});

  @override
  Widget build(BuildContext context) {
    final lang = Localizations.localeOf(context).languageCode;
    final s = SoriSurfaces.of(context);
    return SoriCard(
      variant: SoriCardVariant.hero,
      accent: SoriColors.success,
      tinted: true,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              v.translationFor(lang),
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: Spacing.sm),
            Text(
              v.posFor(lang),
              style: TextStyle(fontSize: 14, color: s.textMuted),
            ),
            if (v.exampleKorean.isNotEmpty) ...[
              const SizedBox(height: Spacing.lg),
              Text(
                v.exampleKorean,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                v.exampleFor(lang),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: s.textMuted,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
