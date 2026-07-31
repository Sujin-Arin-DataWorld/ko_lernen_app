import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../l10n/generated/app_localizations.dart';
import '../models/scenario.dart';
import '../services/scenario_loader.dart';
import '../services/storage_service.dart';
import '../services/tts_service.dart';
import '../widgets/sori/badge.dart';
import '../widgets/sori/button.dart';
import '../widgets/sori/card.dart';
import '../widgets/sori/character_clip.dart';
import '../widgets/sori/chip.dart';
import '../widgets/sori/empty_state.dart';
import '../widgets/sori/hanok_header.dart';
import '../widgets/sori/mascot.dart';
import '../widgets/sori/pressable.dart';
import '../widgets/sori/progress.dart';
import '../widgets/sori/screen_background.dart';
import '../widgets/sori/screen_coach.dart';
import '../widgets/sori/spotlight_coach.dart';
import '../widgets/sori/tokens.dart';
import '../widgets/sori/responsive.dart';

enum _SubMode { both, koOnly, nativeOnly, off }

/// Listening 모드 — 시나리오 dialog를 TTS로 step by step 재생한다.
///
/// v1.0 minimum: 시나리오 선택 → 발화 카드 한 줄씩 보기 → TTS 재생 →
/// 다음으로 진행. 완료 시 XP 보상 + Storage 누적.
class ListeningScreen extends StatefulWidget {
  const ListeningScreen({super.key});

  @override
  State<ListeningScreen> createState() => _ListeningScreenState();
}

class _ListeningScreenState extends State<ListeningScreen>
    with ScreenCoachMixin<ListeningScreen> {
  List<Scenario> _scenarios = const [];
  Scenario? _selected;
  int _step = 0;
  bool _loading = true;
  double _rate = 1.0; // 0.75 / 1.0 / 1.25 — TTS speech rate multiplier
  _SubMode _subs = _SubMode.both;
  bool _completed = false;

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
    final list = await ScenarioLoader.load();
    if (!mounted) return;
    final userLevel =
        LearnerLevel.fromCode(Storage.userLevelCode) ?? LearnerLevel.a1;
    final preferred = list
        .where((s) => s.level == userLevel && s.dialog.isNotEmpty)
        .toList();
    setState(() {
      _scenarios = list.where((s) => s.dialog.isNotEmpty).toList();
      _selected = preferred.isNotEmpty
          ? preferred.first
          : (_scenarios.isNotEmpty ? _scenarios.first : null);
      _loading = false;
    });
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
    // 화면 속도는 요청에만 적용되며 사용자의 전역 TTS 설정은 보존한다.
    await TtsService.speak(line.ko, rateMultiplier: _rate);
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
    HapticFeedback.heavyImpact();
    final earned = (sc.dialog.length * 8).clamp(40, 120);
    await Storage.addXp(earned);
    if (!mounted) return;
    setState(() => _completed = true);
  }

  void _restart() {
    HapticFeedback.selectionClick();
    setState(() {
      _step = 0;
      _completed = false;
    });
    _speakCurrent();
  }

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);

    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_scenarios.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: Text(t.listeningTitle)),
        body: SoriEmptyState(
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
                      rate: _rate,
                      subs: _subs,
                      onRate: (r) => setState(() => _rate = r),
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
  final double rate;
  final _SubMode subs;
  final ValueChanged<double> onRate;
  final ValueChanged<_SubMode> onSubs;
  final AppL10n t;

  const _ControlsBar({
    required this.rate,
    required this.subs,
    required this.onRate,
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
          // Speed row
          Row(
            children: [
              Icon(Icons.speed_rounded, size: 16, color: s.textMuted),
              const SizedBox(width: Spacing.xs),
              Text(
                t.listeningSpeedLabel,
                style: SoriTextTheme.of(
                  context,
                ).caption.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(width: Spacing.md),
              ...[0.75, 1.0, 1.25].map((r) {
                final selected = (rate - r).abs() < 0.01;
                return Padding(
                  padding: const EdgeInsets.only(right: Spacing.xs),
                  child: SoriChip(
                    label: '${r}x',
                    accent: SoriColors.info,
                    selected: selected,
                    variant: SoriChipVariant.soft,
                    onTap: () => onRate(r),
                    fontSize: 12,
                  ),
                );
              }),
            ],
          ),
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
  final VoidCallback onReplay;
  final VoidCallback onClose;

  const _CompleteCard({
    required this.lines,
    required this.xpEarned,
    required this.onReplay,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);
    return SoriCard(
      variant: SoriCardVariant.hero,
      accent: SoriColors.success,
      tinted: true,
      width: double.infinity,
      child: Column(
        children: [
          // 완료 축하 — 까치 축하 클립(영상 게이트 통과 시), 아니면 정적 마스코트.
          const CharacterClipPlayer(
            asset: CharacterClips.magpieCelebrate,
            size: 104,
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
