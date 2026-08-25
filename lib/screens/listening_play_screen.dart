import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../l10n/generated/app_localizations.dart';
import '../models/feedback_completion.dart';
import '../models/scenario.dart';
import '../services/analytics_service.dart';
import '../services/content_share_service.dart';
import '../widgets/sori/toast.dart';
import '../services/liked_content_service.dart';
import '../services/quest_abandon_tracker.dart';
import '../services/storage_service.dart';
import '../services/tts_service.dart';
import '../widgets/sori/badge.dart';
import '../widgets/sori/button.dart';
import '../widgets/sori/character_clip.dart';
import '../widgets/sori/chaekgado/scroll_sheet.dart';
import '../widgets/sori/content_feedback_card.dart';
import '../widgets/sori/content_feed.dart';
import '../widgets/sori/mascot.dart';
import '../widgets/sori/pressable.dart';
import '../widgets/sori/responsive.dart';
import '../widgets/sori/screen_coach.dart';
import '../widgets/sori/spotlight_coach.dart';
import '../widgets/sori/study_frame.dart';
import '../widgets/sori/tokens.dart';
import '../widgets/sori/tts_speed_control.dart';
import '../widgets/sori/wordbook_add.dart';

/// One-line listening player. The chaekgado shelf stays on `/listening`.
class ListeningPlayScreen extends StatefulWidget {
  const ListeningPlayScreen({super.key, required this.scenario});

  final Scenario scenario;

  static Widget fromRouteArgs(Object? arguments) {
    if (arguments is Scenario && arguments.dialog.isNotEmpty) {
      return ListeningPlayScreen(scenario: arguments);
    }
    return const SizedBox.shrink();
  }

  @override
  State<ListeningPlayScreen> createState() => _ListeningPlayScreenState();
}

class _ListeningPlayScreenState extends State<ListeningPlayScreen>
    with ScreenCoachMixin<ListeningPlayScreen> {
  int _step = 0;
  bool _completed = false;
  bool _showGloss = false;
  final ListeningFeedbackCompletionState _feedbackCompletion =
      ListeningFeedbackCompletionState();
  QuestAbandonTracker? _abandonTracker;
  final GlobalKey _speedKey = GlobalKey();
  final GlobalKey _lineKey = GlobalKey();

  Scenario get _scenario => widget.scenario;

  DialogLine get _line => _scenario.dialog[_step];

  /// 덱 공유 폰트 실측의 입력 — 시나리오 전체 대사를 어절로 쪼갠 목록.
  /// 줄마다 다시 만들면 값이 흔들릴 수 있어 한 번만 만든다.
  late final List<String> _deckWords = _scenario.dialog
      .expand((line) => line.ko.split(' '))
      .where((word) => word.trim().isNotEmpty)
      .toList(growable: false);

  @override
  String get coachId => 'listening_play';

  @override
  bool get coachReady => !_completed && _scenario.dialog.isNotEmpty;

  @override
  List<SpotlightStep> buildCoachSteps(BuildContext context) {
    final t = AppL10n.of(context);
    return [
      SpotlightStep(
        targetKey: _speedKey,
        title: t.coachListeningStep2Title,
        body: t.coachListeningStep2Body,
        icon: Icons.speed_rounded,
      ),
      SpotlightStep(
        targetKey: _lineKey,
        title: t.coachListeningStep3Title,
        body: t.coachListeningStep3Body,
        icon: Icons.headphones_rounded,
      ),
    ];
  }

  @override
  void initState() {
    super.initState();
    Analytics.lessonStarted(
      lessonType: 'listening',
      lessonId: _scenario.id,
      level: _scenario.level.display,
    );
    _abandonTracker = QuestAbandonTracker(
      questType: 'listening',
      questId: _scenario.id,
      lastStepReached: () => 'line_$_step',
    );
    scheduleCoach();
    _speakCurrent();
  }

  @override
  void dispose() {
    _abandonTracker?.dispose();
    TtsService.stop();
    super.dispose();
  }

  Future<void> _speakCurrent() async {
    if (_completed || _step >= _scenario.dialog.length) {
      return;
    }
    final line = _scenario.dialog[_step];
    if (line.speaker == 'narrator' || line.ko.isEmpty) {
      return;
    }
    await TtsService.speak(
      line.ko,
      voice: line.speaker == 'user' ? 'female' : 'male',
    );
  }

  void _goTo(int next) {
    if (next < 0 || next >= _scenario.dialog.length) {
      return;
    }
    HapticFeedback.selectionClick();
    setState(() {
      _step = next;
      _showGloss = false;
    });
    _speakCurrent();
  }

  void _next() {
    if (_step >= _scenario.dialog.length - 1) {
      _finish();
      return;
    }
    _goTo(_step + 1);
  }

  void _prev() {
    if (_step == 0) {
      return;
    }
    _goTo(_step - 1);
  }

  Future<void> _finish() async {
    if (_completed) {
      return;
    }
    Analytics.lessonCompleted(
      lessonType: 'listening',
      lessonId: _scenario.id,
      level: _scenario.level.display,
    );
    _abandonTracker?.markCompleted();
    final lang = Localizations.localeOf(context).languageCode;
    HapticFeedback.heavyImpact();
    final earned = (_scenario.dialog.length * 8).clamp(40, 120);
    final completion = await _feedbackCompletion.finish(
      persistXp: () async {
        await Storage.addXp(earned);
        await Storage.addCompletedScenario(_scenario.id);
      },
      create: () => FeedbackCompletion.listening(
        scenarioId: _scenario.id,
        contentLabel: _scenario.title.pick(lang),
        level: _scenario.level.display,
        lines: _scenario.dialog.length,
        rate: Storage.ttsSpeed,
      ),
    );
    if (!mounted || completion == null) {
      return;
    }
    setState(() => _completed = true);
  }

  void _restart() {
    HapticFeedback.selectionClick();
    setState(() {
      _step = 0;
      _completed = false;
      _showGloss = false;
      _feedbackCompletion.reset();
    });
    _speakCurrent();
  }

  Future<void> _likeCurrent() async {
    await LikedContentService.toggle(
      kind: LikedContentService.listening,
      id: '${_scenario.id}:$_step',
    );
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _bookmarkCurrent() async {
    final lang = Localizations.localeOf(context).languageCode;
    final gloss = _line.pick(lang);
    await addToWordbook(
      context,
      korean: _line.ko,
      translationDe: lang == 'en' ? _line.de : gloss,
      translationEn: _line.en,
      translationLanguage: lang,
      source: 'listening',
    );
  }

  Future<void> _shareCurrent() async {
    final t = AppL10n.of(context);
    final lang = Localizations.localeOf(context).languageCode;
    final outcome = await ContentShareService.shareStory(
      korean: _line.ko,
      gloss: _line.pick(lang),
    );
    if (outcome == ShareOutcome.failed && mounted) {
      soriToast(context, t.shareError);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);
    final lang = Localizations.localeOf(context).languageCode;
    final title = _scenario.title.pick(lang);
    return SoriStudyFrame(
      title: title.isEmpty ? t.listeningTitle : title,
      eyebrow: t.listeningProgress(
        _completed ? _scenario.dialog.length : _step + 1,
        _scenario.dialog.length,
      ),
      actions: [KeyedSubtree(key: _speedKey, child: const TtsSpeedAction())],
      particles: true,
      padding: const EdgeInsets.fromLTRB(
        Spacing.lg,
        Spacing.sm,
        Spacing.lg,
        Spacing.lg,
      ),
      child: SoriAdaptiveStudyBody(
        minHeight: 520,
        child: _completed ? _buildComplete(t) : _buildFeed(t, lang),
      ),
    );
  }

  Widget _buildFeed(AppL10n t, String lang) {
    final last = _step >= _scenario.dialog.length - 1;
    return SoriContentFeed(
      judgmentsEnabled: true,
      onNext: _next,
      onPrevious: _step > 0 ? _prev : null,
      onLike: _likeCurrent,
      onBookmark: _line.ko.isEmpty ? null : _bookmarkCurrent,
      bookmarkKey: _line.ko,
      onShare: _shareCurrent,
      onFlip: () => setState(() => _showGloss = !_showGloss),
      liked: LikedContentService.isLiked(
        kind: LikedContentService.listening,
        id: '${_scenario.id}:$_step',
      ),
      showBookmark: _line.ko.isNotEmpty,
      knowLabel: last ? t.listeningCompleteTitle : t.listeningNext,
      child: KeyedSubtree(
        key: _lineKey,
        child: _ListeningLinePage(
          line: _line,
          deckWords: _deckWords,
          showGloss: _showGloss,
          lang: lang,
          replayLabel: t.listeningReplay,
          onReplay: _speakCurrent,
        ),
      ),
    );
  }

  Widget _buildComplete(AppL10n t) {
    final surfaces = SoriSurfaces.of(context);
    final feedbackScope = ContentFeedbackControllerScope.maybeOf(context);
    final xp = (_scenario.dialog.length * 8).clamp(40, 120);
    return Column(
      children: [
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CharacterClipPlayer(
                asset: CharacterClips.magpieCelebrate,
                size: 104,
                blendColor: surfaces.bg,
                fallbackKind: MascotKind.magpie,
                fallbackEmotion: MascotEmotion.celebrate,
              ),
              const SizedBox(height: Spacing.md),
              Text(
                t.listeningCompleteTitle,
                style: SoriTextTheme.of(
                  context,
                ).h2.copyWith(color: SoriColors.contentCta),
              ),
              const SizedBox(height: Spacing.sm),
              Text(
                t.listeningCompleteBody(_scenario.dialog.length, xp),
                textAlign: TextAlign.center,
                style: SoriTextTheme.of(context).body,
              ),
              const SizedBox(height: Spacing.md),
              SoriBadge.xp(xp, size: 28),
              if (feedbackScope != null &&
                  feedbackScope.featureGate.isEnabled &&
                  _feedbackCompletion.current != null) ...[
                const SizedBox(height: Spacing.lg),
                ContentFeedbackCard(
                  feedbackContext: _feedbackCompletion.current!.context,
                  featureGate: feedbackScope.featureGate,
                  submitFeedback: feedbackScope.submitFeedback,
                  mascotKind: MascotKind.magpie,
                  completedMissionIds: feedbackScope.completedMissionIds,
                ),
              ],
            ],
          ),
        ),
        Row(
          children: [
            Expanded(
              child: SoriButton.outlined(
                label: t.listeningReplay,
                icon: Icons.replay_rounded,
                fullWidth: true,
                onTap: _restart,
              ),
            ),
            const SizedBox(width: Spacing.sm),
            Expanded(
              child: SoriButton.filled(
                label: t.listeningGotIt,
                accent: SoriColors.contentCta,
                fullWidth: true,
                onTap: () => Navigator.pop(context),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// 재생 꼬리표/한국어 줄이 쓰는 최소 탭 타깃. 실측(카드 높이 계산)과 렌더가
/// 같은 값을 봐야 안전망 FittedBox 가 개입하지 않는다.
const double _kReplayTapTarget = 48;

/// 한 줄짜리 두루마리 카드. **크기를 정하는 건 콘텐츠지 화면 비율이 아니다.**
///
/// 예전에는 `cardHeight = maxHeight * 0.34` 고정이라 짧은 줄에서는 카드 안이
/// 텅 비고 긴 줄에서는 글자가 축 띠 밖으로 밀려났다(2026-08-23 진단 B1/B2).
/// 지금은 ① 덱 전체가 공유하는 한 폰트 크기를 [soriUniformFitSize] 로 먼저 잡고,
/// ② 그 크기로 이 줄의 실제 콘텐츠 높이를 TextPainter 로 실측한 뒤,
/// ③ 종이 비율(위/아래 축 띠)을 되돌려 카드 높이를 만든다.
class _ListeningLinePage extends StatelessWidget {
  const _ListeningLinePage({
    required this.line,
    required this.deckWords,
    required this.showGloss,
    required this.lang,
    required this.replayLabel,
    required this.onReplay,
  });

  final DialogLine line;

  /// 시나리오 **전체 대사의 어절 목록**. [soriUniformFitSize] 는 `maxLines: 1`
  /// 실측이라 문장 통째가 아니라 최장 *어절*이 한 줄에 들어가는 크기를 잡는다 —
  /// 나머지 줄바꿈은 어절 단위 wrap 이 처리한다. 덱 내내 한 값이라 카드를
  /// 넘겨도 글자 크기가 요동치지 않는다.
  final List<String> deckWords;

  final bool showGloss;
  final String lang;
  final String replayLabel;
  final VoidCallback onReplay;

  double _measure(
    BuildContext context,
    String text,
    TextStyle style,
    double maxWidth,
  ) {
    final painter = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: Directionality.of(context),
      textAlign: TextAlign.center,
      textScaler: MediaQuery.textScalerOf(context),
    )..layout(maxWidth: maxWidth);
    final height = painter.height;
    painter.dispose();
    return height;
  }

  @override
  Widget build(BuildContext context) {
    final tt = SoriTextTheme.of(context);
    final gloss = line.pick(lang);
    return LayoutBuilder(
      builder: (context, constraints) {
        final cardWidth = (constraints.maxWidth * 0.9).toDouble();
        // 종이 내폭 — 축 띠/종이 여백은 에셋 비례 상수가 정본이다.
        final paperWidth = cardWidth * (1 - 2 * kScrollPaperSideFraction);
        final koStyle = tt.koDisplay.copyWith(
          fontSize: soriUniformFitSize(
            context,
            texts: deckWords,
            maxWidth: paperWidth,
            cap: 28,
            min: 22,
            letterSpacing: tt.koDisplay.letterSpacing ?? 0,
            lineHeight: tt.koDisplay.height ?? 1.0,
          ),
        );
        final glossStyle = tt.gloss;
        final metaStyle = tt.meta.copyWith(color: SoriColors.contentCta);
        final showsGloss = showGloss && gloss.isNotEmpty && gloss != line.ko;

        // 두 줄 다 `_ListeningReplayTarget` 안이라 48dp 탭 타깃이 바닥이다 —
        // 이걸 빼먹으면 실측이 모자라 FittedBox 가 주도해 버린다.
        var contentHeight = _measure(
          context,
          line.ko,
          koStyle,
          paperWidth,
        ).clamp(_kReplayTapTarget, double.infinity).toDouble();
        if (showsGloss) {
          contentHeight +=
              Spacing.md + _measure(context, gloss, glossStyle, paperWidth);
        }
        contentHeight +=
            Spacing.sm +
            _measure(
              context,
              replayLabel,
              metaStyle,
              paperWidth,
            ).clamp(_kReplayTapTarget, double.infinity).toDouble();

        final maxHeight = constraints.maxHeight.isFinite
            ? constraints.maxHeight
            : 520.0;
        final cardHeight =
            (contentHeight /
                    (1 - kScrollRodTopFraction - kScrollRodBottomFraction))
                .clamp(200.0, maxHeight * 0.72)
                .toDouble();

        return Center(
          child: SizedBox(
            width: cardWidth,
            height: cardHeight,
            child: SoriShortScrollCard(
              // FittedBox 는 **안전망으로만** 남는다 — 크기는 위의 균일값이
              // 정하고, 카드가 상한(0.72)에 걸린 극단에서만 미세 축소로 잘림을
              // 받아낸다. 폭은 종이 내폭 그대로라 어절 줄바꿈이 살아 있다.
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: SizedBox(
                  width: paperWidth,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _ListeningReplayTarget(
                        semanticsLabel: '$replayLabel: ${line.ko}',
                        onTap: onReplay,
                        child: Text(
                          line.ko,
                          textAlign: TextAlign.center,
                          style: koStyle,
                        ),
                      ),
                      if (showsGloss) ...[
                        const SizedBox(height: Spacing.md),
                        Text(
                          gloss,
                          textAlign: TextAlign.center,
                          style: glossStyle,
                        ),
                      ],
                      const SizedBox(height: Spacing.sm),
                      _ListeningReplayTarget(
                        semanticsLabel: replayLabel,
                        onTap: onReplay,
                        child: Text(replayLabel, style: metaStyle),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _ListeningReplayTarget extends StatelessWidget {
  const _ListeningReplayTarget({
    required this.semanticsLabel,
    required this.onTap,
    required this.child,
  });

  final String semanticsLabel;
  final VoidCallback onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      enabled: true,
      label: semanticsLabel,
      onTap: onTap,
      child: ExcludeSemantics(
        child: SoriPressable(
          onTap: onTap,
          haptic: SoriHaptic.selection,
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              minWidth: _kReplayTapTarget,
              minHeight: _kReplayTapTarget,
            ),
            child: Center(widthFactor: 1, heightFactor: 1, child: child),
          ),
        ),
      ),
    );
  }
}
