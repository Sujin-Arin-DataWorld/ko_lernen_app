import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../l10n/generated/app_localizations.dart';
import '../models/book_page.dart';
import '../models/custom_pack.dart';
import '../models/feedback_completion.dart';
import '../services/analytics_service.dart';
import '../services/quest_abandon_tracker.dart';
import '../services/custom_pack_service.dart';
import '../services/sound_service.dart';
import '../services/storage_service.dart';
import '../services/tts_service.dart';
import '../widgets/sori/button.dart';
import '../widgets/sori/empty_state.dart';
import '../widgets/sori/game_reward.dart';
import '../widgets/sori/mascot.dart';
import '../widgets/sori/screen_coach.dart';
import '../widgets/sori/spotlight_coach.dart';
import '../widgets/sori/study_frame.dart';
import '../widgets/sori/tokens.dart';
import '../widgets/sori/tts_speed_control.dart';

/// A3 — "짝 맞추기"(Matching). 한국어 ↔ 뜻 카드를 짝지어 없앤다.
/// 가벼운 인출 강화 게임. 한 라운드 최대 6쌍.
class CustomPackMatchingScreen extends StatefulWidget {
  final String packId;
  final List<ExtractedWord>? words;
  const CustomPackMatchingScreen({super.key, required this.packId, this.words});

  @override
  State<CustomPackMatchingScreen> createState() =>
      _CustomPackMatchingScreenState();
}

class _CustomPackMatchingScreenState extends State<CustomPackMatchingScreen>
    with ScreenCoachMixin<CustomPackMatchingScreen> {
  final math.Random _rng = math.Random();
  CustomPack? _pack;
  List<ExtractedWord> _pool = const [];
  String _languageCode = 'de';
  bool _roundInitialized = false;

  List<ExtractedWord> _round = const [];
  List<String> _leftKo = const []; // 한국어 열 (셔플)
  List<String> _rightMeanings = const []; // 뜻 열 (셔플)
  int? _selLeft; // 선택된 한국어 index
  final Set<String> _matched = {}; // 맞춘 한국어
  // 이번 라운드에서 한 번이라도 잘못 짝지은 단어. 이후 정답은 게임 보상은
  // 유지하지만 SRS 성공 증거로 올리지 않는다.
  final Set<String> _missedKorean = {};
  String? _wrongRight; // 방금 틀린 뜻 (빨강 플래시)
  String? _statusMessage;
  int _misses = 0; // 라운드 내 오답 탭 수 (XP 보상에 반영)

  // ── 코치마크 타겟 ──
  final GlobalKey _boardKey = GlobalKey();
  final FeedbackCompletionSlot _feedbackCompletion = FeedbackCompletionSlot();
  late final QuestAbandonTracker _abandonTracker;

  @override
  String get coachId => 'cpMatching';

  @override
  bool get coachReady => _pool.length >= 2 && _round.isNotEmpty;

  @override
  List<SpotlightStep> buildCoachSteps(BuildContext context) {
    final t = AppL10n.of(context);
    return [
      SpotlightStep(
        targetKey: _boardKey,
        title: t.coachCpMatchingTitle,
        body: t.coachCpMatchingBody,
        icon: Icons.grid_view_rounded,
      ),
    ];
  }

  @override
  void initState() {
    super.initState();
    Analytics.gameStarted(gameType: 'matching');
    _abandonTracker = QuestAbandonTracker(
      questType: 'matching',
      questId: widget.packId,
      lastStepReached: () => 'matched_${_matched.length}',
    );
    final loaded = CustomPackService.getById(widget.packId);
    final pack = loaded == null || widget.words == null
        ? loaded
        : loaded.copyWith(words: widget.words);
    _pack = pack;
    scheduleCoach();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_roundInitialized) {
      return;
    }
    _roundInitialized = true;
    _startRoundForLocale(Localizations.localeOf(context).languageCode);
  }

  void _startRoundForLocale(String languageCode) {
    _languageCode = languageCode;
    final pack = _pack;
    if (pack == null) {
      return;
    }
    _pool = pack.words
        .where((word) => word.translationFor(languageCode).trim().isNotEmpty)
        .toList();
    if (_pool.length >= 2) {
      _newRound();
    }
  }

  void _newRound() {
    final shuffled = [..._pool]..shuffle(_rng);
    // Preserve the existing rule: one tile per distinct meaning. Apply that
    // rule to the locale fixed for this round so the right column is clear.
    final seenMeanings = <String>{};
    final unique = <ExtractedWord>[];
    for (final word in shuffled) {
      final meaning = word.translationFor(_languageCode).trim();
      if (seenMeanings.contains(meaning)) {
        continue;
      }
      seenMeanings.add(meaning);
      unique.add(word);
      if (unique.length >= 6) {
        break;
      }
    }
    _round = unique;
    _leftKo = _round.map((w) => w.korean).toList()..shuffle(_rng);
    _rightMeanings =
        _round.map((word) => word.translationFor(_languageCode).trim()).toList()
          ..shuffle(_rng);
    _matched.clear();
    _missedKorean.clear();
    _selLeft = null;
    _wrongRight = null;
    _statusMessage = null;
    _misses = 0;
    _feedbackCompletion.reset();
  }

  void _tapLeft(int i) {
    final ko = _leftKo[i];
    if (_matched.contains(ko)) {
      return;
    }
    HapticFeedback.selectionClick();
    setState(() {
      _selLeft = i;
      _statusMessage = null;
    });
    TtsService.speak(ko);
  }

  void _tapRight(String meaning) {
    if (_selLeft == null) {
      return;
    }
    final ko = _leftKo[_selLeft!];
    final expected = _round
        .firstWhere((word) => word.korean == ko)
        .translationFor(_languageCode)
        .trim();
    // 정답/오답 무관 — 이 라운드에서 노출됐다는 사실 자체를 기록한다.
    Storage.addVokSeen(ko);
    if (meaning == expected) {
      HapticFeedback.lightImpact();
      SoundService.correct();
      // Eine spätere Korrektur darf XP und den Spielfortschritt abschließen,
      // aber keine positive SRS-Evidenz über den vorherigen Fehlversuch legen.
      if (!_missedKorean.contains(ko)) {
        unawaited(Storage.srsReview(ko, gotIt: true));
      }
      setState(() {
        _matched.add(ko);
        _selLeft = null;
        _wrongRight = null;
        _statusMessage = AppL10n.of(context).statsCorrect;
      });
      if (_roundDone) {
        _finish();
      }
    } else {
      HapticFeedback.mediumImpact();
      SoundService.wrong();
      _misses++;
      // Pro Wort/Runde genau ein negativer Lernnachweis. Wiederholte Taps auf
      // dieselbe falsche Zuordnung dürfen den Zähler nicht künstlich aufblasen.
      if (_missedKorean.add(ko)) {
        unawaited(Storage.srsReview(ko, gotIt: false));
        unawaited(Storage.incrementWrongCount(ko));
      }
      setState(() {
        _wrongRight = meaning;
        _statusMessage = AppL10n.of(context).statsWrong;
      });
      Future.delayed(const Duration(milliseconds: 450), () {
        if (mounted) {
          setState(() => _wrongRight = null);
        }
      });
    }
  }

  Future<void> _finish() async {
    _feedbackCompletion.complete(
      () => FeedbackCompletion.customPackMatching(
        packId: widget.packId,
        pairs: _matched.length,
        misses: _misses,
      ),
    );
    // Fehlerfreie Runde → voller XP, sonst kleiner Abschlag (Aufwand spiegeln).
    await recordGameResult(gameId: 'cp_matching', xp: _roundXp);
    await Analytics.gameCompleted(
      gameType: 'matching',
      result: 'win',
      score: _round.length,
    );
    _abandonTracker.markCompleted();
  }

  @override
  void dispose() {
    _abandonTracker.dispose();
    super.dispose();
  }

  bool get _roundDone => _round.isNotEmpty && _matched.length >= _round.length;

  int get _roundXp => _misses == 0 ? _round.length * 4 : _round.length * 3;

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);
    final pack = _pack;

    if (pack == null) {
      return SoriStudyFrame(
        title: t.wbMatching,
        child: Center(
          child: SoriEmptyState(
            asset: 'assets/illustrations/mascot/tiger_front.png',
            icon: Icons.help_outline,
            title: t.customPackNotFoundTitle,
            body: t.customPackNotFoundBody,
          ),
        ),
      );
    }
    if (_pool.length < 2 || _round.length < 2) {
      return SoriStudyFrame(
        title: t.wbMatching,
        child: Center(
          child: SoriEmptyState(
            asset: 'assets/illustrations/mascot/magpie_encourage.png',
            icon: Icons.grid_view_rounded,
            title: t.wbMatching,
            body: t.wbMatchingNeedMore,
          ),
        ),
      );
    }

    final s = SoriSurfaces.of(context);
    final tt = SoriTextTheme.of(context);

    return SoriStudyFrame(
      title: t.wbMatching,
      leading: IconButton(
        tooltip: t.btnClose,
        constraints: const BoxConstraints.tightFor(width: 48, height: 48),
        icon: const Icon(Icons.close),
        onPressed: () => Navigator.of(context).maybePop(),
      ),
      actions: const [TtsSpeedAction()],
      padding: EdgeInsets.zero,
      child: _roundDone
          ? _buildDone(t)
          : SoriAdaptiveStudyBody(
              minHeight: 560,
              child: Padding(
                padding: const EdgeInsets.all(Spacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      t.wbMatchingHint,
                      style: tt.caption.copyWith(color: s.textMuted),
                    ),
                    if (_statusMessage != null) ...[
                      const SizedBox(height: Spacing.sm),
                      Semantics(
                        key: const ValueKey('custom-matching-feedback'),
                        liveRegion: true,
                        label: _statusMessage,
                        child: Text(
                          _statusMessage!,
                          textAlign: TextAlign.center,
                          style: tt.h3.copyWith(
                            color: _statusMessage == t.statsCorrect
                                ? SoriColors.primaryOnLight
                                : SoriColors.danger,
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: Spacing.md),
                    Expanded(
                      child: KeyedSubtree(
                        key: _boardKey,
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // 한국어 열
                            Expanded(
                              child: Column(
                                children: [
                                  for (var i = 0; i < _leftKo.length; i++)
                                    _Tile(
                                      label: _leftKo[i],
                                      matched: _matched.contains(_leftKo[i]),
                                      selected: _selLeft == i,
                                      accent: SoriColors.primary,
                                      enabled: !_matched.contains(_leftKo[i]),
                                      onTap: () => _tapLeft(i),
                                    ),
                                ],
                              ),
                            ),
                            const SizedBox(width: Spacing.md),
                            // 뜻 열
                            Expanded(
                              child: Column(
                                children: [
                                  for (final meaning in _rightMeanings)
                                    _Tile(
                                      label: meaning,
                                      matched: _matched.any(
                                        (ko) =>
                                            _round
                                                .firstWhere(
                                                  (w) => w.korean == ko,
                                                )
                                                .translationFor(_languageCode)
                                                .trim() ==
                                            meaning,
                                      ),
                                      wrong: _wrongRight == meaning,
                                      accent: SoriColors.accent,
                                      enabled: _selLeft != null,
                                      onTap: () => _tapRight(meaning),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildDone(AppL10n t) {
    return Semantics(
      container: true,
      liveRegion: true,
      label: '${t.wbMatchingDone}. ${t.wbMatchingDoneBody}',
      child: GameOverCard(
        headline: t.wbMatchingDone,
        scoreLabel: t.wbMatchingDoneBody,
        feedbackContext: _feedbackCompletion.current?.context,
        xpGained: _roundXp,
        mascotKind: MascotKind.magpie,
        mascotEmotion: MascotEmotion.celebrate,
        actions: [
          SoriButton(
            label: t.quizAgain,
            icon: Icons.refresh_rounded,
            variant: SoriButtonVariant.filled,
            accent: SoriColors.primary,
            fullWidth: true,
            onTap: () => setState(
              () => _startRoundForLocale(
                Localizations.localeOf(context).languageCode,
              ),
            ),
          ),
          SoriButton(
            label: t.btnClose,
            variant: SoriButtonVariant.ghost,
            fullWidth: true,
            onTap: () => Navigator.of(context).maybePop(),
          ),
        ],
      ),
    );
  }
}

class _Tile extends StatelessWidget {
  final String label;
  final bool matched;
  final bool selected;
  final bool wrong;
  final bool enabled;
  final Color accent;
  final VoidCallback? onTap;
  const _Tile({
    required this.label,
    required this.accent,
    required this.onTap,
    this.enabled = true,
    this.matched = false,
    this.selected = false,
    this.wrong = false,
  });

  @override
  Widget build(BuildContext context) {
    final s = SoriSurfaces.of(context);
    Color border = enabled
        ? (s.brightness == Brightness.light
              ? SoriColors.lightBorderStrong
              : SoriColors.darkBorderStrong)
        : s.border;
    Color bg = s.surface;
    double opacity = 1;
    IconData? stateIcon;
    String? semanticValue;
    if (matched) {
      opacity = 0.25;
      border = SoriColors.success;
      stateIcon = Icons.check_circle_rounded;
      semanticValue = AppL10n.of(context).statsCorrect;
    } else if (wrong) {
      border = SoriColors.danger;
      bg = SoriColors.danger.withValues(alpha: 0.12);
      stateIcon = Icons.cancel_rounded;
      semanticValue = AppL10n.of(context).statsWrong;
    } else if (selected) {
      border = accent;
      bg = accent.withValues(alpha: 0.12);
      stateIcon = Icons.radio_button_checked_rounded;
      semanticValue = AppL10n.of(context).questAnswerSelected;
    }
    final canTap = enabled && !matched && onTap != null;
    return Semantics(
      button: true,
      enabled: canTap,
      selected: selected,
      label: label,
      value: semanticValue,
      onTap: canTap ? onTap : null,
      excludeSemantics: true,
      child: Opacity(
        opacity: opacity,
        child: Padding(
          padding: const EdgeInsets.only(bottom: Spacing.sm),
          child: Material(
            color: bg,
            borderRadius: BorderRadius.circular(SoriRadius.md),
            child: InkWell(
              borderRadius: BorderRadius.circular(SoriRadius.md),
              onTap: canTap ? onTap : null,
              child: Container(
                width: double.infinity,
                constraints: const BoxConstraints(minHeight: 56),
                alignment: Alignment.center,
                padding: const EdgeInsets.symmetric(
                  horizontal: Spacing.sm,
                  vertical: Spacing.sm,
                ),
                decoration: BoxDecoration(
                  border: Border.all(color: border, width: 1.5),
                  borderRadius: BorderRadius.circular(SoriRadius.md),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: Text(
                        label,
                        textAlign: TextAlign.center,
                        style: SoriTextTheme.of(context).label,
                      ),
                    ),
                    if (stateIcon != null) ...[
                      const SizedBox(width: Spacing.xs),
                      Icon(stateIcon, size: 20, color: border),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
