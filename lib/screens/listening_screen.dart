import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../l10n/generated/app_localizations.dart';
import '../widgets/app_loading.dart';
import '../models/content_feedback.dart';
import '../models/feedback_completion.dart';
import '../models/scenario.dart';
import '../services/analytics_service.dart';
import '../services/learner_level_selection.dart';
import '../services/scenario_loader.dart';
import '../services/storage_service.dart';
import '../services/tts_service.dart';
import '../widgets/sori/badge.dart';
import '../widgets/sori/button.dart';
import '../widgets/sori/card.dart';
import '../widgets/sori/character_clip.dart';
import '../widgets/sori/chip.dart';
import '../widgets/sori/content_feedback_card.dart';
import '../widgets/sori/empty_state.dart';
import '../widgets/sori/hanok_header.dart';
import '../widgets/sori/mascot.dart';
import '../widgets/sori/pressable.dart';
import '../widgets/sori/tts_speed_control.dart';
import '../widgets/sori/progress.dart';
import '../widgets/sori/screen_background.dart';
import '../widgets/sori/screen_coach.dart';
import '../widgets/sori/spotlight_coach.dart';
import '../widgets/sori/tokens.dart';
import '../widgets/sori/responsive.dart';

enum _SubMode { both, koOnly, nativeOnly, off }

/// Chooses the initial listening scenario without dropping a higher-level
/// learner to the first (normally A1) asset when their exact level is sparse.
///
/// Exact-level material remains the first choice. If it is unavailable, the
/// closest lower available level is selected; only a completely non-cumulative
/// fixture falls back to the first playable scenario.
Scenario? selectInitialListeningScenario(
  Iterable<Scenario> scenarios,
  LearnerLevel userLevel,
) {
  final playable = scenarios.where((scenario) => scenario.dialog.isNotEmpty);
  final exact = playable.where((scenario) => scenario.level == userLevel);
  if (exact.isNotEmpty) {
    return exact.first;
  }

  for (var rank = userLevel.rank; rank >= LearnerLevel.a1.rank; rank--) {
    final level = LearnerLevel.values[rank];
    final closestLower = playable.where((scenario) => scenario.level == level);
    if (closestLower.isNotEmpty) {
      return closestLower.first;
    }
  }

  return playable.isEmpty ? null : playable.first;
}

/// Listening 모드 — 시나리오 dialog를 TTS로 step by step 재생한다.
///
/// v1.0 minimum: 시나리오 선택 → 발화 카드 한 줄씩 보기 → TTS 재생 →
/// 다음으로 진행. 완료 시 XP 보상 + Storage 누적.
class ListeningScreen extends StatefulWidget {
  final Future<List<Scenario>> Function()? scenariosLoader;

  const ListeningScreen({super.key, this.scenariosLoader});

  @override
  State<ListeningScreen> createState() => _ListeningScreenState();
}

class _ListeningScreenState extends State<ListeningScreen>
    with ScreenCoachMixin<ListeningScreen> {
  List<Scenario> _scenarios = const [];
  Scenario? _selected;
  int _step = 0;
  bool _loading = true;
  _SubMode _subs = _SubMode.both;
  bool _completed = false;
  final ListeningFeedbackCompletionState _feedbackCompletion =
      ListeningFeedbackCompletionState();

  // ── 코치마크 타겟 ──
  final GlobalKey _scenarioChipKey = GlobalKey();
  final GlobalKey _controlsBarKey = GlobalKey();
  final GlobalKey _lineCardKey = GlobalKey();

  @override
  String get coachId => 'listening';

  @override
  bool get coachReady => !_loading && _selected != null;

  @override
  List<SpotlightStep> buildCoachSteps(BuildContext context) {
    final t = AppL10n.of(context);
    return [
      SpotlightStep(
        targetKey: _scenarioChipKey,
        title: t.coachListeningStep1Title,
        body: t.coachListeningStep1Body,
        icon: Icons.playlist_play_rounded,
      ),
      SpotlightStep(
        targetKey: _controlsBarKey,
        title: t.coachListeningStep2Title,
        body: t.coachListeningStep2Body,
        icon: Icons.tune_rounded,
      ),
      SpotlightStep(
        targetKey: _lineCardKey,
        title: t.coachListeningStep3Title,
        body: t.coachListeningStep3Body,
        icon: Icons.headphones_rounded,
      ),
    ];
  }

  @override
  void initState() {
    super.initState();
    _load();
    scheduleCoach();
  }

  Future<void> _load() async {
    final providedLoader = widget.scenariosLoader;
    final list = providedLoader != null
        ? await providedLoader()
        : await ScenarioLoader.load();
    if (!mounted) return;
    final userLevel = learnerLevelForStoredCode(Storage.userLevelCode);
    final playable = list
        .where((scenario) => scenario.dialog.isNotEmpty)
        .toList();
    setState(() {
      _scenarios = playable;
      _selected = selectInitialListeningScenario(playable, userLevel);
      _loading = false;
    });
    final started = _selected;
    if (started != null) {
      Analytics.lessonStarted(
        lessonType: 'listening',
        lessonId: started.id,
        level: started.level.display,
      );
    }
    // 첫 대사를 바로 들려준다.
    //
    // _pickScenario 는 예전부터 _speakCurrent() 를 불렀는데 **처음 들어와서
    // 자동 선택되는 이 경로**에만 그게 없었다. 그래서 화면에 들어오면 대사만
    // 떠 있고 소리가 안 나서, 들으려면 반복 버튼을 눌러야 했다("이거 좀
    // 오류같아서 고쳐야할것같아" — Jin, 2026-08-12). 듣기 연습 화면이 조용히
    // 시작하는 건 확실히 오작동처럼 보인다.
    _speakCurrent();
  }

  @override
  void dispose() {
    TtsService.stop();
    super.dispose();
  }

  void _pickScenario(Scenario s) {
    HapticFeedback.selectionClick();
    TtsService.stop();
    setState(() {
      _selected = s;
      _step = 0;
      _completed = false;
      _feedbackCompletion.reset();
    });
    _speakCurrent();
  }

  Future<void> _speakCurrent() async {
    final sc = _selected;
    if (sc == null || _step >= sc.dialog.length) {
      return;
    }
    final line = sc.dialog[_step];
    // 'narrator' 라인은 무성 (분위기 텍스트) — 그냥 표시만.
    if (line.speaker == 'narrator' || line.ko.isEmpty) {
      return;
    }
    // 속도는 전역 배수(`Storage.ttsSpeed`) 하나만 쓴다 — 화면 로컬 배수는
    // 화면을 떠나면 사라져 혼란만 줬다 (2026-08-13 전역 속도 바로 통합).
    // 화자→voice 는 scenario_player 와 동일 규칙 — NPC 대사는 male 사전생성
    // 캐시(tts/v3)에 적중해야 재합성·화자 불일치가 없다.
    await TtsService.speak(
      line.ko,
      voice: line.speaker == 'user' ? 'female' : 'male',
    );
  }

  void _next() {
    final sc = _selected;
    if (sc == null) return;
    HapticFeedback.selectionClick();
    if (_step >= sc.dialog.length - 1) {
      _finish();
      return;
    }
    setState(() => _step++);
    _speakCurrent();
  }

  void _prev() {
    if (_step == 0) return;
    HapticFeedback.selectionClick();
    setState(() => _step--);
    _speakCurrent();
  }

  Future<void> _finish() async {
    final sc = _selected;
    if (sc == null) return;
    Analytics.lessonCompleted(
      lessonType: 'listening',
      lessonId: sc.id,
      level: sc.level.display,
    );
    final lang = Localizations.localeOf(context).languageCode;
    HapticFeedback.heavyImpact();
    final earned = (sc.dialog.length * 8).clamp(40, 120);
    final completion = await _feedbackCompletion.finish(
      persistXp: () => Storage.addXp(earned),
      create: () => FeedbackCompletion.listening(
        scenarioId: sc.id,
        contentLabel: sc.title.pick(lang),
        level: sc.level.display,
        lines: sc.dialog.length,
        rate: Storage.ttsSpeed,
      ),
    );
    if (!mounted || completion == null) return;
    setState(() => _completed = true);
  }

  void _restart() {
    HapticFeedback.selectionClick();
    setState(() {
      _step = 0;
      _completed = false;
      _feedbackCompletion.reset();
    });
    _speakCurrent();
  }

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);

    if (_loading) {
      return const Scaffold(body: AppLoading());
    }
    if (_scenarios.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: Text(t.listeningTitle)),
        body: SoriEmptyState(
          asset: 'assets/illustrations/mascot/magpie_encourage.png',
          icon: Icons.headphones_outlined,
          title: t.listeningEmptyTitle,
          body: t.listeningEmptyBody,
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          t.listeningTitle,
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SoriScreenBackground(
        particles: true,
        child: SafeArea(
          child: SingleChildScrollView(
            padding: soriClampPadding(
              MediaQuery.sizeOf(context).width,
              base: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── 풍경(風磬) hero header — 자산 없으면 fallback ──
                HanokHeader(
                  asset: 'assets/illustrations/hanok/listening_hero.png',
                  fallbackIcon: Icons.headphones_outlined,
                  fallbackTint: SoriColors.info,
                  aspectRatio: 10 / 3,
                ),
                const SizedBox(height: Spacing.md),

                Text(
                  t.listeningSubtitle,
                  style: SoriTextTheme.of(context).bodySmall,
                ),
                const SizedBox(height: Spacing.md),

                // ── 시나리오 선택 chips ──
                Text(
                  t.listeningSelectScenario,
                  style: SoriTextTheme.of(context).cardSubtitle.copyWith(
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.4,
                  ),
                ),
                const SizedBox(height: Spacing.sm),
                SizedBox(
                  key: _scenarioChipKey,
                  height: 38,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: _scenarios.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(width: Spacing.xs + 2),
                    itemBuilder: (_, i) {
                      final sc = _scenarios[i];
                      final selected = sc.id == _selected?.id;
                      final lang = Localizations.localeOf(context).languageCode;
                      return SoriChip(
                        label: '${sc.emoji}  ${sc.title.pick(lang)}',
                        accent: SoriColors.info,
                        selected: selected,
                        variant: SoriChipVariant.filled,
                        onTap: () => _pickScenario(sc),
                      );
                    },
                  ),
                ),
                const SizedBox(height: Spacing.lg),

                // ── 컨트롤 + 자막 토글 ──
                if (_selected != null) ...[
                  KeyedSubtree(
                    key: _controlsBarKey,
                    child: _ControlsBar(
                      subs: _subs,
                      onSubs: (m) => setState(() => _subs = m),
                      t: t,
                    ),
                  ),
                  const SizedBox(height: Spacing.md),

                  // ── 발화 카드 또는 완료 카드 ──
                  if (_completed)
                    _CompleteCard(
                      lines: _selected!.dialog.length,
                      xpEarned: (_selected!.dialog.length * 8).clamp(40, 120),
                      feedbackContext: _feedbackCompletion.current?.context,
                      onReplay: _restart,
                      onClose: () => Navigator.pop(context),
                    )
                  else
                    KeyedSubtree(
                      key: _lineCardKey,
                      child: _LineCard(
                        line: _selected!.dialog[_step],
                        subs: _subs,
                        onReplay: _speakCurrent,
                      ),
                    ),

                  const SizedBox(height: Spacing.lg),

                  if (!_completed) ...[
                    // 진행 바
                    SoriProgressBar(
                      value: (_step + 1) / _selected!.dialog.length,
                      thickness: 6,
                      animated: true,
                    ),
                    const SizedBox(height: Spacing.sm),
                    Center(
                      child: Text(
                        t.listeningProgress(
                          _step + 1,
                          _selected!.dialog.length,
                        ),
                        style: SoriTextTheme.of(
                          context,
                        ).caption.copyWith(fontWeight: FontWeight.w600),
                      ),
                    ),
                    const SizedBox(height: Spacing.md),

                    // 다음/이전 버튼
                    Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: SoriButton.outlined(
                            label: t.listeningPrev,
                            icon: Icons.skip_previous_rounded,
                            fullWidth: true,
                            onTap: _step > 0 ? _prev : null,
                          ),
                        ),
                        const SizedBox(width: Spacing.sm),
                        Expanded(
                          flex: 3,
                          child: SoriButton.filled(
                            label: _step >= _selected!.dialog.length - 1
                                ? t.listeningCompleteTitle
                                : t.listeningNext,
                            icon: _step >= _selected!.dialog.length - 1
                                ? Icons.check_rounded
                                : Icons.skip_next_rounded,
                            accent: SoriColors.info,
                            fullWidth: true,
                            onTap: _next,
                          ),
                        ),
                      ],
                    ),
                  ],
                ] else
                  SoriCard(
                    variant: SoriCardVariant.base,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: Spacing.lg),
                      child: Center(
                        child: Text(
                          t.listeningPickFirst,
                          textAlign: TextAlign.center,
                          style: SoriTextTheme.of(context).bodySmall,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Controls Bar ─────────────────────────────────────────────────────────────

class _ControlsBar extends StatelessWidget {
  final _SubMode subs;
  final ValueChanged<_SubMode> onSubs;
  final AppL10n t;

  const _ControlsBar({
    required this.subs,
    required this.onSubs,
    required this.t,
  });

  @override
  Widget build(BuildContext context) {
    final s = SoriSurfaces.of(context);
    return SoriCard(
      variant: SoriCardVariant.compact,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Speed row — 전역 속도 배수 (모든 화면과 공유·영속).
          const TtsSpeedControl(mode: TtsSpeedControlMode.row),
          const SizedBox(height: Spacing.sm),
          // Subtitle row
          Row(
            children: [
              Icon(Icons.subtitles_outlined, size: 16, color: s.textMuted),
              const SizedBox(width: Spacing.xs),
              Text(
                t.listeningSubtitleLabel,
                style: SoriTextTheme.of(
                  context,
                ).caption.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(width: Spacing.md),
              Expanded(
                child: Wrap(
                  spacing: Spacing.xs,
                  runSpacing: Spacing.xs,
                  children: [
                    _subChip(t.listeningSubtitleBoth, _SubMode.both),
                    _subChip(t.listeningSubtitleKo, _SubMode.koOnly),
                    _subChip(t.listeningSubtitleNative, _SubMode.nativeOnly),
                    _subChip(t.listeningSubtitleOff, _SubMode.off),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _subChip(String label, _SubMode mode) {
    return SoriChip(
      label: label,
      accent: SoriColors.info,
      selected: subs == mode,
      variant: SoriChipVariant.soft,
      onTap: () => onSubs(mode),
      fontSize: 11.5,
      minInteractiveHeight: 44,
    );
  }
}

// ─── Line Card ────────────────────────────────────────────────────────────────

class _LineCard extends StatelessWidget {
  final DialogLine line;
  final _SubMode subs;
  final VoidCallback onReplay;

  const _LineCard({
    required this.line,
    required this.subs,
    required this.onReplay,
  });

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);
    final s = SoriSurfaces.of(context);
    final lang = Localizations.localeOf(context).languageCode;
    final isUser = line.speaker == 'user';
    final isNarrator = line.speaker == 'narrator';
    final showKo = subs == _SubMode.both || subs == _SubMode.koOnly;
    final showNative = subs == _SubMode.both || subs == _SubMode.nativeOnly;

    final accent = isUser
        ? SoriColors.primary
        : isNarrator
        ? SoriColors.warning
        : SoriColors.info;

    final mascot = Mascot.forSpeaker(
      line.speaker,
      size: 56,
      emotion: MascotEmotion.smile,
      animate: false,
    );

    return SoriCard(
      variant: SoriCardVariant.hero,
      accent: accent,
      tinted: true,
      width: double.infinity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (mascot != null) ...[mascot, const SizedBox(height: Spacing.md)],
          if (showKo) ...[
            Text(
              line.ko,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: s.text,
                fontSize: 22,
                fontWeight: FontWeight.w800,
                height: 1.4,
              ),
            ),
            const SizedBox(height: Spacing.sm),
          ],
          if (showNative && line.pick(lang) != line.ko) ...[
            Text(
              line.pick(lang),
              textAlign: TextAlign.center,
              style: TextStyle(color: s.textMuted, fontSize: 14, height: 1.5),
            ),
            const SizedBox(height: Spacing.md),
          ],
          SoriPressable(
            onTap: onReplay,
            haptic: SoriHaptic.selection,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.14),
                borderRadius: SoriRadius.brPill,
                border: Border.all(color: accent.withValues(alpha: 0.4)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.replay_rounded, size: 16, color: accent),
                  const SizedBox(width: Spacing.xs),
                  Text(
                    t.listeningReplay,
                    style: TextStyle(
                      color: accent,
                      fontWeight: FontWeight.w700,
                      fontSize: 12.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Complete Card ────────────────────────────────────────────────────────────

class _CompleteCard extends StatelessWidget {
  final int lines;
  final int xpEarned;
  final ContentFeedbackContext? feedbackContext;
  final VoidCallback onReplay;
  final VoidCallback onClose;

  const _CompleteCard({
    required this.lines,
    required this.xpEarned,
    required this.feedbackContext,
    required this.onReplay,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);
    final feedbackScope = ContentFeedbackControllerScope.maybeOf(context);
    return SoriCard(
      variant: SoriCardVariant.hero,
      accent: SoriColors.success,
      tinted: true,
      width: double.infinity,
      child: Column(
        children: [
          // 완료 축하 — 까치 축하 클립(영상 게이트 통과 시), 아니면 정적 마스코트.
          // tinted 카드(success 8%) 실배경과 같은 함수로 blendColor를 맞춰
          // multiply 사각 이음매를 막는다.
          CharacterClipPlayer(
            asset: CharacterClips.magpieCelebrate,
            size: 104,
            blendColor: SoriCard.resolvedBackground(
              context,
              accent: SoriColors.success,
              tinted: true,
            ),
            fallbackKind: MascotKind.magpie,
            fallbackEmotion: MascotEmotion.celebrate,
          ),
          const SizedBox(height: Spacing.md),
          Text(
            t.listeningCompleteTitle,
            style: SoriTextTheme.of(context).h2.copyWith(
              color: SoriColors.success,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: Spacing.sm),
          Text(
            t.listeningCompleteBody(lines, xpEarned),
            textAlign: TextAlign.center,
            style: SoriTextTheme.of(
              context,
            ).bodySmall.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: Spacing.md),
          SoriBadge.xp(xpEarned, size: 28),
          if (feedbackContext != null &&
              feedbackScope != null &&
              feedbackScope.featureGate.isEnabled) ...[
            const SizedBox(height: Spacing.lg),
            ContentFeedbackCard(
              feedbackContext: feedbackContext!,
              featureGate: feedbackScope.featureGate,
              submitFeedback: feedbackScope.submitFeedback,
              mascotKind: MascotKind.magpie,
              completedMissionIds: feedbackScope.completedMissionIds,
            ),
          ],
          const SizedBox(height: Spacing.lg),
          Row(
            children: [
              Expanded(
                child: SoriButton.outlined(
                  label: t.listeningReplay,
                  icon: Icons.replay_rounded,
                  fullWidth: true,
                  onTap: onReplay,
                ),
              ),
              const SizedBox(width: Spacing.sm),
              Expanded(
                child: SoriButton.filled(
                  label: t.listeningGotIt,
                  accent: SoriColors.success,
                  fullWidth: true,
                  onTap: onClose,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
