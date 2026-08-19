import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../l10n/generated/app_localizations.dart';
import '../models/feedback_completion.dart';
import '../models/scenario.dart';
import '../services/analytics_service.dart';
import '../services/content_share_service.dart';
import '../services/liked_content_service.dart';
import '../services/quest_abandon_tracker.dart';
import '../services/storage_service.dart';
import '../services/tts_service.dart';
import '../widgets/sori/app_bar.dart';
import '../widgets/sori/badge.dart';
import '../widgets/sori/button.dart';
import '../widgets/sori/character_clip.dart';
import '../widgets/sori/content_feedback_card.dart';
import '../widgets/sori/content_feed.dart';
import '../widgets/sori/mascot.dart';
import '../widgets/sori/pressable.dart';
import '../widgets/sori/screen_background.dart';
import '../widgets/sori/screen_coach.dart';
import '../widgets/sori/spotlight_coach.dart';
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

  void _shareCurrent() {
    final t = AppL10n.of(context);
    final lang = Localizations.localeOf(context).languageCode;
    ContentShareService.shareStory(
      korean: _line.ko,
      gloss: _line.pick(lang),
      caption: t.contentShareBody(_line.ko, _line.pick(lang)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);
    final lang = Localizations.localeOf(context).languageCode;
    final title = _scenario.title.pick(lang);
    return Scaffold(
      appBar: SoriAppBar(
        title: title.isEmpty ? t.listeningTitle : title,
        eyebrow: t.listeningProgress(
          _completed ? _scenario.dialog.length : _step + 1,
          _scenario.dialog.length,
        ),
        actions: [
          KeyedSubtree(key: _speedKey, child: const TtsSpeedAction()),
        ],
      ),
      body: SoriScreenBackground(
        particles: true,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              Spacing.lg,
              Spacing.sm,
              Spacing.lg,
              Spacing.lg,
            ),
            child: _completed ? _buildComplete(t) : _buildFeed(t, lang),
          ),
        ),
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

class _ListeningLinePage extends StatelessWidget {
  const _ListeningLinePage({
    required this.line,
    required this.showGloss,
    required this.lang,
    required this.replayLabel,
    required this.onReplay,
  });

  final DialogLine line;
  final bool showGloss;
  final String lang;
  final String replayLabel;
  final VoidCallback onReplay;

  @override
  Widget build(BuildContext context) {
    final tt = SoriTextTheme.of(context);
    final gloss = line.pick(lang);
    final mascot = Mascot.forSpeaker(
      line.speaker,
      size: 56,
      emotion: MascotEmotion.smile,
      animate: false,
    );
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (mascot != null) ...[mascot, const SizedBox(height: Spacing.md)],
        SoriPressable(
          onTap: onReplay,
          haptic: SoriHaptic.selection,
          child: Text(
            line.ko,
            textAlign: TextAlign.center,
            style: tt.koDisplay,
          ),
        ),
        if (showGloss && gloss.isNotEmpty && gloss != line.ko) ...[
          const SizedBox(height: Spacing.md),
          Text(gloss, textAlign: TextAlign.center, style: tt.gloss),
        ],
        const SizedBox(height: Spacing.lg),
        SoriPressable(
          onTap: onReplay,
          haptic: SoriHaptic.selection,
          child: Text(
            replayLabel,
            style: tt.meta.copyWith(color: SoriColors.contentCta),
          ),
        ),
      ],
    );
  }
}
