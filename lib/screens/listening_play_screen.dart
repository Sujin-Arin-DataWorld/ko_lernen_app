import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../controllers/listening_playback_controller.dart';
import '../l10n/generated/app_localizations.dart';
import '../models/feedback_completion.dart';
import '../models/scenario.dart';
import '../services/analytics_service.dart';
import '../services/liked_content_service.dart';
import '../services/quest_abandon_tracker.dart';
import '../services/scenario_loader.dart';
import '../services/storage_service.dart';
import '../services/tts_service.dart';
import '../widgets/sori/badge.dart';
import '../widgets/sori/button.dart';
import '../widgets/sori/card.dart';
import '../widgets/sori/character_clip.dart';
import '../widgets/sori/content_feedback_card.dart';
import '../widgets/sori/content_share_recovery.dart';
import '../widgets/sori/mascot.dart';
import '../widgets/sori/screen_coach.dart';
import '../widgets/sori/spotlight_coach.dart';
import '../widgets/sori/study_frame.dart';
import '../widgets/sori/tokens.dart';
import '../widgets/sori/tts_speed_control.dart';
import '../widgets/sori/wordbook_add.dart';

Future<bool> _speakWithTts(String text, {required String voice}) =>
    TtsService.speak(text, voice: voice);

Future<void> _stopTts() => TtsService.stop();

/// 책가도에서 고른 한 장면을 시작 전 소개·자동 대화극·줄별 복습으로 재생한다.
class ListeningPlayScreen extends StatefulWidget {
  const ListeningPlayScreen({
    super.key,
    required this.scenario,
    this.speechPlayer = _speakWithTts,
    this.stopPlayer = _stopTts,
  });

  final Scenario scenario;
  final ListeningSpeak speechPlayer;
  final ListeningStop stopPlayer;

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
    with WidgetsBindingObserver, ScreenCoachMixin<ListeningPlayScreen> {
  late final ListeningPlaybackController _playback;
  final ListeningFeedbackCompletionState _feedbackCompletion =
      ListeningFeedbackCompletionState();
  final ScrollController _scrollController = ScrollController();
  QuestAbandonTracker? _abandonTracker;
  bool _completionPersisted = false;
  int _completionXp = 0;
  final GlobalKey _speedKey = GlobalKey();
  final GlobalKey _conversationKey = GlobalKey();

  Scenario get _scenario => widget.scenario;

  @override
  String get coachId => 'listening_play';

  @override
  bool get coachReady =>
      _playback.phase != ListeningPlaybackPhase.intro &&
      _playback.phase != ListeningPlaybackPhase.complete;

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
        targetKey: _conversationKey,
        title: t.coachListeningStep3Title,
        body: t.coachListeningStep3Body,
        icon: Icons.headphones_rounded,
      ),
    ];
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _playback = ListeningPlaybackController(
      lines: _scenario.dialog,
      speak: widget.speechPlayer,
      stop: widget.stopPlayer,
      onCompleted: _finish,
    )..addListener(_onPlaybackChanged);
    Analytics.lessonStarted(
      lessonType: 'listening',
      lessonId: _scenario.id,
      level: _scenario.level.display,
    );
    _abandonTracker = QuestAbandonTracker(
      questType: 'listening',
      questId: _scenario.id,
      lastStepReached: () => 'line_${_playback.currentIndex}',
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) {
      unawaited(_playback.stopForLifecycle());
    }
  }

  void _onPlaybackChanged() {
    if (!mounted) {
      return;
    }
    setState(() {});
    if (_playback.phase == ListeningPlaybackPhase.autoplay) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToLatest());
    }
  }

  void _scrollToLatest() {
    if (!mounted || !_scrollController.hasClients) {
      return;
    }
    final target = _scrollController.position.maxScrollExtent;
    if (MediaQuery.maybeOf(context)?.disableAnimations ?? false) {
      _scrollController.jumpTo(target);
    } else {
      _scrollController.animateTo(
        target,
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _playback.removeListener(_onPlaybackChanged);
    _playback.dispose();
    _scrollController.dispose();
    _abandonTracker?.dispose();
    super.dispose();
  }

  Future<void> _finish() async {
    if (_completionPersisted) {
      return;
    }
    Analytics.lessonCompleted(
      lessonType: 'listening',
      lessonId: _scenario.id,
      level: _scenario.level.display,
    );
    _abandonTracker?.markCompleted();
    final lang = Localizations.localeOf(context).languageCode;
    final earned = (_scenario.dialog.length * 8).clamp(40, 120);
    final completion = await _feedbackCompletion.finish(
      persistXp: () async {
        final claim = await Storage.claimListeningCompletionReward(
          scenarioId: _scenario.id,
          earnedXp: earned,
        );
        _completionXp = claim == ListeningRewardClaimResult.awarded
            ? earned
            : 0;
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
    _completionPersisted = true;
    HapticFeedback.heavyImpact();
    setState(() {});
  }

  Future<void> _likeLine(int index) async {
    await LikedContentService.toggle(
      kind: LikedContentService.listening,
      id: '${_scenario.id}:$index',
    );
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _shareLine(int index) async {
    final line = _scenario.dialog[index];
    final lang = Localizations.localeOf(context).languageCode;
    await shareContentStoryWithRecovery(
      context: context,
      korean: line.ko,
      gloss: line.pick(lang),
    );
  }

  Future<void> _openNextStory() async {
    final scenarios = (await ScenarioLoader.load())
        .where((item) => item.dialog.isNotEmpty)
        .toList(growable: false);
    if (!mounted || scenarios.isEmpty) {
      return;
    }
    final sameShelf = scenarios
        .where((item) => item.shelf == _scenario.shelf)
        .toList(growable: false);
    final candidates = sameShelf.length > 1 ? sameShelf : scenarios;
    final current = candidates.indexWhere((item) => item.id == _scenario.id);
    final next = candidates[(current + 1) % candidates.length];
    await Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        settings: const RouteSettings(name: '/listening/play'),
        builder: (_) => ListeningPlayScreen(scenario: next),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);
    final lang = Localizations.localeOf(context).languageCode;
    final title = _scenario.title.pick(lang);
    final progress = _playback.phase == ListeningPlaybackPhase.intro
        ? t.listeningLineCount(_scenario.dialog.length)
        : t.listeningProgress(_playback.revealedCount, _scenario.dialog.length);
    return SoriStudyFrame(
      title: title.isEmpty ? t.listeningTitle : title,
      eyebrow: progress,
      actions: [KeyedSubtree(key: _speedKey, child: const TtsSpeedAction())],
      particles: _playback.phase == ListeningPlaybackPhase.complete,
      padding: const EdgeInsets.fromLTRB(
        Spacing.lg,
        Spacing.sm,
        Spacing.lg,
        Spacing.lg,
      ),
      child: SoriAdaptiveStudyBody(
        minHeight: 520,
        child: switch (_playback.phase) {
          ListeningPlaybackPhase.intro => _buildIntro(t, lang),
          ListeningPlaybackPhase.complete => _buildComplete(t),
          _ => _buildConversation(t, lang),
        },
      ),
    );
  }

  Widget _buildIntro(AppL10n t, String lang) {
    final intro = _scenario.intro.pick(lang);
    final speakers = <String>{
      for (final line in _scenario.dialog)
        if (line.speaker != 'narrator') _speakerName(t, line.speaker),
    }.join(', ');
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            child: SoriCard(
              variant: SoriCardVariant.base,
              child: Column(
                children: [
                  const Mascot(
                    kind: MascotKind.tiger,
                    emotion: MascotEmotion.smile,
                    size: 88,
                  ),
                  const SizedBox(height: Spacing.md),
                  Text(
                    t.listeningSceneIntro,
                    style: SoriTextTheme.of(
                      context,
                    ).meta.copyWith(color: SoriColors.contentCta),
                  ),
                  const SizedBox(height: Spacing.xs),
                  if (intro.isNotEmpty)
                    Text(
                      intro,
                      textAlign: TextAlign.center,
                      style: SoriTextTheme.of(context).body,
                    ),
                  const SizedBox(height: Spacing.lg),
                  _IntroFact(
                    icon: Icons.people_outline_rounded,
                    label: t.listeningParticipants,
                    value: speakers,
                  ),
                  const SizedBox(height: Spacing.sm),
                  _IntroFact(
                    icon: Icons.format_list_numbered_rounded,
                    label: t.listeningTitle,
                    value: t.listeningLineCount(_scenario.dialog.length),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: Spacing.md),
        SoriButton.filled(
          key: const ValueKey('listening-dialogue-start'),
          label: t.listeningDialogueStart,
          icon: Icons.play_arrow_rounded,
          accent: SoriColors.contentCta,
          fullWidth: true,
          onTap: () {
            _playback.start();
            scheduleCoach();
          },
        ),
      ],
    );
  }

  Widget _buildConversation(AppL10n t, String lang) {
    final review = _playback.phase == ListeningPlaybackPhase.review;
    return Column(
      key: _conversationKey,
      children: [
        Expanded(
          child: ListView(
            controller: _scrollController,
            padding: const EdgeInsets.symmetric(vertical: Spacing.sm),
            children: [
              if (review) ...[
                Text(
                  t.listeningReviewTitle,
                  textAlign: TextAlign.center,
                  style: SoriTextTheme.of(context).h3,
                ),
                const SizedBox(height: Spacing.xs),
                Text(
                  t.listeningReviewBody,
                  textAlign: TextAlign.center,
                  style: SoriTextTheme.of(context).bodySmall,
                ),
                const SizedBox(height: Spacing.md),
              ],
              if (_playback.ttsFailed) ...[
                _TtsFailureCard(
                  title: t.listeningTtsFailedTitle,
                  body: t.listeningTtsFailedBody,
                  retryLabel: t.listeningRetry,
                  onRetry: _playback.retryCurrent,
                ),
                const SizedBox(height: Spacing.sm),
              ],
              for (var index = 0; index < _playback.revealedCount; index++)
                _DialogueBubble(
                  line: _scenario.dialog[index],
                  speakerName: _speakerName(t, _scenario.dialog[index].speaker),
                  gloss: _scenario.dialog[index].pick(lang),
                  current: index == _playback.currentIndex,
                  review: review,
                  translationExpanded: _playback.expandedTranslations.contains(
                    index,
                  ),
                  showTranslationLabel: t.listeningShowTranslation,
                  hideTranslationLabel: t.listeningHideTranslation,
                  translationLanguage: lang,
                  replayLabel: t.listeningReplay,
                  likeLabel: t.contentActionLike,
                  shareLabel: t.shareTooltip,
                  liked: LikedContentService.isLiked(
                    kind: LikedContentService.listening,
                    id: '${_scenario.id}:$index',
                  ),
                  onTranslation: () => _playback.toggleTranslation(index),
                  onReplay: () => _playback.replayLine(index),
                  onLike: () => _likeLine(index),
                  onShare: () => _shareLine(index),
                ),
            ],
          ),
        ),
        const SizedBox(height: Spacing.sm),
        if (_playback.phase == ListeningPlaybackPhase.autoplay)
          SoriButton.outlined(
            label: t.listeningPause,
            icon: Icons.pause_rounded,
            fullWidth: true,
            onTap: _playback.pause,
          )
        else if (_playback.phase == ListeningPlaybackPhase.paused)
          SoriButton.filled(
            label: t.listeningResume,
            icon: Icons.play_arrow_rounded,
            accent: SoriColors.contentCta,
            fullWidth: true,
            onTap: _playback.resume,
          )
        else
          SoriButton.outlined(
            label: t.listeningBackToScroll,
            fullWidth: true,
            onTap: () => Navigator.of(context).pop(),
          ),
      ],
    );
  }

  Widget _buildComplete(AppL10n t) {
    final surfaces = SoriSurfaces.of(context);
    final feedbackScope = ContentFeedbackControllerScope.maybeOf(context);
    final xp = _completionXp;
    return SingleChildScrollView(
      child: Column(
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
            xp > 0
                ? t.listeningCompleteBody(_scenario.dialog.length, xp)
                : t.listeningCompleteReplayBody(_scenario.dialog.length),
            textAlign: TextAlign.center,
            style: SoriTextTheme.of(context).body,
          ),
          const SizedBox(height: Spacing.md),
          if (xp > 0) SoriBadge.xp(xp, size: 28),
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
          const SizedBox(height: Spacing.xl),
          SoriButton.filled(
            label: t.listeningReviewCta,
            accent: SoriColors.contentCta,
            fullWidth: true,
            onTap: _playback.enterReview,
          ),
          const SizedBox(height: Spacing.sm),
          Row(
            children: [
              Expanded(
                child: SoriButton.outlined(
                  label: t.listeningNextStory,
                  fullWidth: true,
                  onTap: _openNextStory,
                ),
              ),
              const SizedBox(width: Spacing.sm),
              Expanded(
                child: SoriButton.outlined(
                  label: t.listeningBackToScroll,
                  fullWidth: true,
                  onTap: () => Navigator.of(context).pop(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _speakerName(AppL10n t, String speaker) {
    if (speaker == 'user') {
      return t.listeningSpeakerYou;
    }
    if (speaker == 'narrator') {
      return t.listeningNarrator;
    }
    final trimmed = speaker.trim();
    if (trimmed.isEmpty) {
      return t.listeningNarrator;
    }
    return '${trimmed[0].toUpperCase()}${trimmed.substring(1)}';
  }
}

class _IntroFact extends StatelessWidget {
  const _IntroFact({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: SoriColors.contentCta),
        const SizedBox(width: Spacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: SoriTextTheme.of(context).meta),
              Text(value, style: SoriTextTheme.of(context).body),
            ],
          ),
        ),
      ],
    );
  }
}

class _DialogueBubble extends StatelessWidget {
  const _DialogueBubble({
    required this.line,
    required this.speakerName,
    required this.gloss,
    required this.current,
    required this.review,
    required this.translationExpanded,
    required this.showTranslationLabel,
    required this.hideTranslationLabel,
    required this.translationLanguage,
    required this.replayLabel,
    required this.likeLabel,
    required this.shareLabel,
    required this.liked,
    required this.onTranslation,
    required this.onReplay,
    required this.onLike,
    required this.onShare,
  });

  final DialogLine line;
  final String speakerName;
  final String gloss;
  final bool current;
  final bool review;
  final bool translationExpanded;
  final String showTranslationLabel;
  final String hideTranslationLabel;
  final String translationLanguage;
  final String replayLabel;
  final String likeLabel;
  final String shareLabel;
  final bool liked;
  final Future<void> Function() onTranslation;
  final Future<void> Function() onReplay;
  final Future<void> Function() onLike;
  final Future<void> Function() onShare;

  @override
  Widget build(BuildContext context) {
    final narrator = line.speaker == 'narrator';
    final user = line.speaker == 'user';
    final surfaces = SoriSurfaces.of(context);
    final bubbleRadius = BorderRadius.circular(narrator ? 12 : 20);
    final bubbleSurface = Container(
      constraints: BoxConstraints(
        maxWidth: narrator
            ? MediaQuery.sizeOf(context).width * 0.84
            : MediaQuery.sizeOf(context).width * 0.78,
      ),
      padding: const EdgeInsets.all(Spacing.md),
      decoration: BoxDecoration(
        color: narrator ? surfaces.surfaceAlt : surfaces.surface,
        borderRadius: bubbleRadius,
        border: Border.all(
          color: current
              ? SoriColors.listeningCurrentInnerOutline
              : surfaces.border,
          width: current ? 1.5 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: narrator
            ? CrossAxisAlignment.center
            : CrossAxisAlignment.start,
        children: [
          if (!narrator)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _NeutralAvatar(name: speakerName),
                const SizedBox(width: Spacing.xs),
                Flexible(
                  child: Text(
                    speakerName,
                    style: SoriTextTheme.of(
                      context,
                    ).meta.copyWith(color: SoriColors.contentCta),
                  ),
                ),
              ],
            )
          else
            Text(
              speakerName,
              style: SoriTextTheme.of(
                context,
              ).meta.copyWith(color: surfaces.textMuted),
            ),
          const SizedBox(height: Spacing.xs),
          Text(
            line.ko,
            textAlign: narrator ? TextAlign.center : TextAlign.start,
            style: SoriTextTheme.of(
              context,
            ).koDisplay.copyWith(fontSize: 20, fontWeight: FontWeight.w600),
          ),
          if (translationExpanded && gloss.isNotEmpty && gloss != line.ko) ...[
            const SizedBox(height: Spacing.sm),
            Text(gloss, style: SoriTextTheme.of(context).gloss),
          ],
          const SizedBox(height: Spacing.xs),
          Wrap(
            spacing: Spacing.xs,
            runSpacing: Spacing.xs,
            children: [
              TextButton.icon(
                onPressed: onReplay,
                icon: const Icon(Icons.volume_up_outlined),
                label: Text(replayLabel),
              ),
              TextButton.icon(
                onPressed: onTranslation,
                icon: Icon(
                  translationExpanded
                      ? Icons.translate_rounded
                      : Icons.translate_outlined,
                ),
                label: Text(
                  translationExpanded
                      ? hideTranslationLabel
                      : showTranslationLabel,
                ),
              ),
              if (review)
                IconButton(
                  tooltip: likeLabel,
                  onPressed: onLike,
                  icon: Icon(liked ? Icons.favorite : Icons.favorite_border),
                ),
              if (review && line.ko.isNotEmpty)
                AddToWordbookButton(
                  korean: line.ko,
                  translationDe: line.de,
                  translationEn: line.en,
                  translationLanguage: translationLanguage,
                  compact: true,
                  coachEnabled: false,
                ),
              if (review)
                IconButton(
                  tooltip: shareLabel,
                  onPressed: onShare,
                  icon: const Icon(Icons.share_outlined),
                ),
            ],
          ),
        ],
      ),
    );
    final framedBubble = current
        ? Container(
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(narrator ? 14 : 22),
              border: Border.all(
                color: SoriColors.listeningCurrentOutline,
                width: 2,
              ),
            ),
            child: bubbleSurface,
          )
        : bubbleSurface;
    final bubble = Semantics(
      container: true,
      liveRegion: current,
      label: '$speakerName: ${line.ko}',
      child: framedBubble,
    );
    return Padding(
      padding: const EdgeInsets.only(bottom: Spacing.md),
      child: Align(
        alignment: narrator
            ? Alignment.center
            : user
            ? Alignment.centerRight
            : Alignment.centerLeft,
        child: bubble,
      ),
    );
  }
}

class _NeutralAvatar extends StatelessWidget {
  const _NeutralAvatar({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    final initial = name.trim().isEmpty ? '?' : name.trim()[0].toUpperCase();
    return Semantics(
      excludeSemantics: true,
      child: Container(
        width: 32,
        height: 32,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: SoriColors.contentCta.withValues(alpha: 0.12),
        ),
        child: Text(
          initial,
          style: SoriTextTheme.of(
            context,
          ).meta.copyWith(color: SoriColors.contentCta),
        ),
      ),
    );
  }
}

class _TtsFailureCard extends StatelessWidget {
  const _TtsFailureCard({
    required this.title,
    required this.body,
    required this.retryLabel,
    required this.onRetry,
  });

  final String title;
  final String body;
  final String retryLabel;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      liveRegion: true,
      child: SoriCard(
        variant: SoriCardVariant.base,
        accent: SoriColors.danger,
        tinted: true,
        child: Row(
          children: [
            const Icon(Icons.volume_off_outlined, color: SoriColors.danger),
            const SizedBox(width: Spacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: SoriTextTheme.of(
                      context,
                    ).body.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: Spacing.xs),
                  Text(body, style: SoriTextTheme.of(context).bodySmall),
                ],
              ),
            ),
            TextButton(onPressed: onRetry, child: Text(retryLabel)),
          ],
        ),
      ),
    );
  }
}
