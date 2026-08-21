import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../l10n/generated/app_localizations.dart';
import '../widgets/app_loading.dart';
import '../models/feedback_completion.dart';
import '../models/vocab.dart';
import '../services/cloze_loader.dart';
import '../services/data_loader.dart';
import '../services/sound_service.dart';
import '../services/storage_service.dart';
import '../widgets/sori/button.dart';
import '../widgets/sori/card.dart';
import '../widgets/sori/cloze_prompt.dart';
import '../widgets/sori/empty_state.dart';
import '../widgets/sori/game_reward.dart';
import '../widgets/sori/mascot.dart';
import '../widgets/sori/responsive.dart';
import '../widgets/sori/study_frame.dart';
import '../widgets/sori/tokens.dart';
import '../widgets/sori/tts_speed_control.dart';

/// **Tages-Challenge (오늘의 도전)** — ein datums-gesetztes Lückentext-Puzzle.
///
/// Alle Nutzer:innen bekommen dasselbe Tagesset (Seed = Tag). Tägliche Gewohnheit
/// schlägt jede Einzel-Funktion (Forschung); Belohnung = Bonus-XP + persönlicher
/// Tages-Streak. **Keine Rangliste** (Selbst-Wettbewerb, kein Dark-Pattern).
class DailyChallengeScreen extends StatefulWidget {
  /// Optional test fixture; production uses the curated daily selection.
  final List<ClozeItem>? items;

  const DailyChallengeScreen({super.key, this.items});

  /// Tages-Seed: lokale Tage seit Epoche → deterministisch. Lokal (nicht UTC),
  /// damit Puzzle-Tag und Streak-Tag (Storage nutzt lokales Datum) niemals
  /// um Mitternacht auseinanderlaufen.
  static int dailySeed(DateTime now) => DateTime(
    now.year,
    now.month,
    now.day,
  ).difference(DateTime(2020, 1, 1)).inDays;

  /// Deterministische Tagesauswahl (rein, testbar).
  static List<ClozeItem> pickDaily(List<ClozeItem> all, int seed, int count) {
    final copy = [...all]..shuffle(Random(seed));
    return copy.take(count).toList();
  }

  /// 사용자의 현재 레벨 문항만 남긴 풀 (rein, testbar).
  ///
  /// 데일리는 전 레벨 풀에서 뽑혀 A2 학습자에게 B2 문항('양극화' 등)이,
  /// 반대로 C1/C2 학습자에게 A1 문항이 일반 카드처럼 노출됐다. 레벨은
  /// "이 수준까지"가 아니라 이 화면에서 연습할 현재 난이도다. 따라서
  /// [levelCode]가 있으면 정확히 같은 레벨만 쓴다. 열 문항보다 적더라도
  /// 상위 또는 하위 레벨을 섞지 않고, 가능한 만큼의 짧은 라운드를 낸다.
  /// 온보딩 전([levelCode] == null)에만 전체 풀을 사용한다.
  static List<ClozeItem> capToLevel(
    List<ClozeItem> all,
    String? levelCode,
    int count,
  ) {
    if (levelCode == null) return all;
    return all.where((item) => item.level == levelCode).toList();
  }

  @override
  State<DailyChallengeScreen> createState() => _DailyChallengeScreenState();
}

class _DailyChallengeScreenState extends State<DailyChallengeScreen> {
  static const _count = 10;
  static const _completionBonus = 20;

  List<ClozeItem> _round = const [];
  Map<String, Vocab> _vocabByKo = const {};
  bool _loading = true;
  bool _alreadyDone = false; // heute schon erledigt → Übungsmodus, kein Bonus
  int _idx = 0;
  int _score = 0;
  String? _picked;

  /// 현재 문제에서 이미 한 번 틀렸는가 — 재시도로 맞혀도 첫 시도 결과가
  /// 점수·SRS 에 반영되도록 [_pick] 이 읽는다.
  bool _retried = false;
  GameOutcome? _outcome;
  int _streak = 0;
  final FeedbackCompletionSlot _feedbackCompletion = FeedbackCompletionSlot();

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final all = widget.items ?? await ClozeLoader.load();
    // Keep injected item fixtures independent from the vocabulary asset. The
    // production path still loads it to enrich the translation gloss.
    final vocab = widget.items == null
        ? await DataLoader.loadVocab()
        : const <Vocab>[];
    if (!mounted) return;
    final round = DailyChallengeScreen.pickDaily(
      DailyChallengeScreen.capToLevel(all, Storage.placementLevelCode, _count),
      DailyChallengeScreen.dailySeed(DateTime.now()),
      _count,
    );
    setState(() {
      _round = round;
      _vocabByKo = {for (final v in vocab) v.korean: v};
      _alreadyDone = Storage.dailyChallengeDoneToday();
      _loading = false;
    });
  }

  void _pick(ClozeItem item, String option) {
    if (_picked != null) return;
    final ok = option == item.answer;
    // 첫 시도 여부를 기록 전에 잡는다 — 재시도로 맞혀도 점수·SRS 는 첫 시도
    // 결과를 따른다. 안 그러면 재시도 허용이 곧 전원 만점이 되어
    // `n / 10 richtig` 카운터가 의미를 잃는다.
    final firstTry = !_retried;
    setState(() => _picked = option);

    if (firstTry) {
      Storage.srsReview(item.answer, gotIt: ok);
      if (ok) _score++;
    }

    if (ok) {
      HapticFeedback.lightImpact();
      SoundService.correct();
      Future.delayed(const Duration(milliseconds: 1100), () {
        if (!mounted) return;
        setState(() {
          _idx++;
          _picked = null;
          _retried = false;
        });
        if (_idx >= _round.length) _finish();
      });
      return;
    }

    // 오답 — 빈칸에 빨갛게 들어갔다가 되돌아오고 계속 고를 수 있다
    // (Jin 2026-08-07 지시: 재시도 허용).
    HapticFeedback.mediumImpact();
    SoundService.wrong();
    Future.delayed(const Duration(milliseconds: 700), () {
      if (!mounted) return;
      setState(() {
        _picked = null;
        _retried = true;
      });
    });
  }

  Future<void> _finish() async {
    _feedbackCompletion.complete(
      () => FeedbackCompletion.dailyChallenge(
        contentLabel: AppL10n.of(context).dailyTitle,
        finishedAt: DateTime.now(),
        correct: _score,
        total: _round.length,
      ),
    );
    final pct = _round.isEmpty ? 0 : ((_score / _round.length) * 100).round();
    // Bonus nur beim ERSTEN Abschluss heute (kein Doppel-Bonus beim Üben).
    final firstToday = !Storage.dailyChallengeDoneToday();
    final bonus = firstToday ? _completionBonus : 0;
    if (firstToday) {
      await Storage.markDailyChallengeDone();
    }
    final outcome = await recordGameResult(
      gameId: 'daily',
      xp: _score * 5 + bonus,
      score: pct,
    );
    if (mounted) {
      setState(() {
        _outcome = outcome;
        _streak = Storage.dailyChallengeStreak;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);
    if (_loading) {
      return SoriStudyFrame(
        title: t.dailyTitle,
        padding: EdgeInsets.zero,
        child: const AppLoading(),
      );
    }
    if (_round.isEmpty) {
      // Defensive: cloze.json leer/fehlend → gemeinsamer leerer Zustand statt
      // eines irreführenden 0/0-Ergebnisses.
      return SoriStudyFrame(
        title: t.dailyTitle,
        padding: EdgeInsets.zero,
        child: Center(
          child: SoriEmptyState(
            asset: 'assets/illustrations/mascot/magpie_encourage.png',
            icon: Icons.today_outlined,
            title: t.dailyTitle,
            body: t.clozeEmptyBody,
          ),
        ),
      );
    }
    // Index-only Guard (wie cloze/satz_arcade): _outcome wird erst nach den
    // async SharedPreferences-Writes gesetzt — ohne diese Reihenfolge gäbe es
    // im Fenster _idx==length && _outcome==null einen RangeError auf _round[_idx].
    // _buildDone liest _outcome defensiv (?.), rendert also auch während des
    // kurzen Fensters korrekt.
    if (_idx >= _round.length) {
      return _buildDone(t);
    }

    final s = SoriSurfaces.of(context);
    final lang = Localizations.localeOf(context).languageCode;
    final item = _round[_idx];
    final options = item.options(
      DailyChallengeScreen.dailySeed(DateTime.now()) + _idx,
    );
    final revealed = _picked != null;

    return SoriStudyFrame(
      title: t.dailyTitle,
      eyebrow:
          '${_idx + 1} / ${_round.length} · ${t.quizScore(_score, _round.length)}',
      leading: IconButton(
        icon: const Icon(Icons.close),
        tooltip: t.btnClose,
        constraints: const BoxConstraints.tightFor(width: 48, height: 48),
        onPressed: () => Navigator.of(context).maybePop(),
      ),
      actions: const [TtsSpeedAction()],
      child: SoriAdaptiveStudyBody(
        minHeight: 520,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_alreadyDone) ...[
              Semantics(
                container: true,
                label: t.dailyAlreadyDone,
                child: ExcludeSemantics(
                  child: SoriCard(
                    key: const Key('daily-practice-note'),
                    variant: SoriCardVariant.compact,
                    accent: SoriColors.gold,
                    tinted: true,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.check_circle_rounded,
                          size: 20,
                          color: SoriColors.gold,
                        ),
                        const SizedBox(width: Spacing.sm),
                        Expanded(
                          child: Text(
                            t.dailyAlreadyDone,
                            style: SoriTextTheme.of(
                              context,
                            ).bodySmall.copyWith(color: s.text),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: Spacing.md),
            ],
            Text(
              t.clozeInstruction,
              style: SoriTextTheme.of(
                context,
              ).meta.copyWith(color: s.textMuted),
            ),
            const SizedBox(height: Spacing.md),
            Flexible(
              flex: 3,
              child: SingleChildScrollView(
                child: ClozePromptCard(
                  item: item,
                  lang: lang,
                  gloss: _vocabByKo[item.answer]?.translationFor(lang),
                  picked: _picked,
                  pickedWrong: _picked != null && _picked != item.answer,
                ),
              ),
            ),
            const SizedBox(height: Spacing.xl),
            Expanded(
              flex: 4,
              child: ClozeOptionsList(
                options: options,
                answer: item.answer,
                picked: _picked,
                revealed: revealed,
                onPick: (opt) => _pick(item, opt),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDone(AppL10n t) {
    final pct = _round.isEmpty ? 0 : ((_score / _round.length) * 100).round();
    return SoriStudyFrame(
      title: t.dailyTitle,
      automaticallyImplyLeading: false,
      padding: EdgeInsets.zero,
      child: SoriCenterClamp(
        child: GameOverCard(
          headline: t.quizResultTitle,
          scoreLabel: t.quizScore(_score, _round.length),
          feedbackContext: _feedbackCompletion.current?.context,
          // tatsächlich gutgeschriebener Wert (eine Quelle der Wahrheit).
          xpGained: _outcome?.xpGained ?? (_score * 5),
          // echter Genauigkeits-Rekord (vom recordGameResult), nicht der Streak.
          isNewBest: _outcome?.isNewBest ?? false,
          newBestLabel: t.gameNewBest,
          // Streak nur, wenn HEUTE neu abgeschlossen (nicht im Übungsmodus).
          streakLabel: _alreadyDone ? null : t.dailyStreak(_streak),
          mascotKind: pct >= 50 ? MascotKind.magpie : MascotKind.tiger,
          mascotEmotion: pct >= 50
              ? MascotEmotion.celebrate
              : MascotEmotion.worry,
          celebrate: pct >= 50,
          actions: [
            SoriButton(
              label: t.btnClose,
              icon: Icons.check_rounded,
              variant: SoriButtonVariant.filled,
              accent: SoriColors.gold,
              fullWidth: true,
              onTap: () => Navigator.of(context).maybePop(),
            ),
          ],
        ),
      ),
    );
  }
}
