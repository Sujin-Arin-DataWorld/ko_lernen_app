import '../../services/learning_journey.dart';
import '../../models/sori_stage_progression.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import '../../config/tester_feedback_feature.dart';
import '../../models/content_feedback.dart';
import '../../services/sound_service.dart';
import '../../services/storage_service.dart';
import '../../services/local_data_lifetime.dart';
import 'celebration.dart';
import 'character_clip.dart';
import 'content_feedback_card.dart';
import 'content_feedback_sheet.dart';
import 'mascot.dart';
import 'mascot_preference.dart';
import 'sori_icon.dart';
import 'tokens.dart';

/// 아이콘 + 라벨 한 줄 (🏆/🔥 이모지 대체 — 시맨틱 아이콘).
Widget _iconLine(IconData icon, String text, Color color) => Row(
  mainAxisSize: MainAxisSize.min,
  mainAxisAlignment: MainAxisAlignment.center,
  children: [
    Icon(icon, size: 16, color: color),
    const SizedBox(width: 5),
    Flexible(
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w800,
          color: color,
        ),
      ),
    ),
  ],
);

/// Records a persisted reward only once its exact row has been painted, fully
/// exposed in every enclosing viewport, and finished its presentation. Parent
/// fades can reuse a composited child, so their animations are observed too.
class LearningRewardPresentation extends StatefulWidget {
  const LearningRewardPresentation({
    super.key,
    required this.attempt,
    required this.kind,
    required this.amount,
    required this.child,
    this.identity,
    this.presentationComplete = true,
  });

  final LearningAttempt? attempt;
  final SoriRewardKind kind;
  final int amount;
  final String? identity;
  final bool presentationComplete;
  final Widget child;

  @override
  State<LearningRewardPresentation> createState() =>
      _LearningRewardPresentationState();
}

class _LearningRewardPresentationState
    extends State<LearningRewardPresentation> {
  final _paintKey = GlobalKey();
  final Set<Listenable> _fades = {};
  ScrollPosition? _scroll;
  bool _painted = false;
  bool _scheduled = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final scroll = Scrollable.maybeOf(context)?.position;
    if (!identical(scroll, _scroll)) {
      _scroll?.removeListener(_schedule);
      _scroll = scroll;
      _scroll?.addListener(_schedule);
    }
    _schedule();
  }

  @override
  void didUpdateWidget(covariant LearningRewardPresentation oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.attempt != widget.attempt ||
        oldWidget.amount != widget.amount ||
        oldWidget.identity != widget.identity) {
      _painted = false;
    }
    _schedule();
  }

  void _didPaint() {
    _painted = true;
    _schedule();
  }

  void _schedule() {
    if (_scheduled || !mounted) {
      return;
    }
    _scheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scheduled = false;
      if (mounted) {
        _check();
      }
    });
  }

  void _check() {
    final box = _paintKey.currentContext?.findRenderObject();
    if (box is! RenderBox || !box.attached || !box.hasSize) {
      return;
    }
    context.visitAncestorElements((element) {
      final ancestorWidget = element.widget;
      if (ancestorWidget is AnimatedWidget &&
          _fades.add(ancestorWidget.listenable)) {
        ancestorWidget.listenable.addListener(_schedule);
      }
      return true;
    });
    var exposed = true;
    final bounds = MatrixUtils.transformRect(
      box.getTransformTo(null),
      box.paintBounds,
    );
    if (bounds.isEmpty || !bounds.isFinite) {
      return;
    }
    bool contains(Rect viewport) =>
        viewport.inflate(0.01).contains(bounds.topLeft) &&
        viewport.inflate(0.01).contains(bounds.bottomRight);
    exposed = contains(Offset.zero & MediaQuery.sizeOf(context));
    RenderObject? ancestor = box.parent;
    while (ancestor != null) {
      if (ancestor is RenderOffstage && ancestor.offstage) {
        exposed = false;
      }
      if (ancestor is RenderOpacity && ancestor.opacity < 1) {
        exposed = false;
      }
      if (ancestor is RenderAnimatedOpacity) {
        if (_fades.add(ancestor.opacity)) {
          ancestor.opacity.addListener(_schedule);
        }
        if (ancestor.opacity.value < 1) {
          exposed = false;
        }
      }
      if (ancestor is RenderAbstractViewport) {
        exposed =
            exposed &&
            contains(
              MatrixUtils.transformRect(
                ancestor.getTransformTo(null),
                ancestor.paintBounds,
              ),
            );
      }
      ancestor = ancestor.parent;
    }
    if (_painted &&
        exposed &&
        widget.presentationComplete &&
        ModalRoute.of(context)?.isCurrent == true) {
      widget.attempt?.shown(
        widget.kind,
        widget.amount,
        identity: widget.identity,
      );
    }
  }

  @override
  void dispose() {
    _scroll?.removeListener(_schedule);
    for (final fade in _fades) {
      fade.removeListener(_schedule);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Register route visibility so a covered result can be acknowledged when
    // exposed again, without a synthetic rebuild or a new persistence result.
    ModalRoute.of(context);
    return _RewardPaintProbe(
      key: _paintKey,
      onPaint: _didPaint,
      child: widget.child,
    );
  }
}

class _RewardPaintProbe extends SingleChildRenderObjectWidget {
  const _RewardPaintProbe({
    super.key,
    required this.onPaint,
    required super.child,
  });
  final VoidCallback onPaint;
  @override
  RenderObject createRenderObject(BuildContext context) =>
      _RewardPaintBox(onPaint);
  @override
  void updateRenderObject(
    BuildContext context,
    covariant _RewardPaintBox renderObject,
  ) {
    renderObject.onPaint = onPaint;
    renderObject.markNeedsPaint();
  }
}

class _RewardPaintBox extends RenderProxyBox {
  _RewardPaintBox(this.onPaint);
  VoidCallback onPaint;
  @override
  void paint(PaintingContext context, Offset offset) {
    super.paint(context, offset);
    onPaint();
  }
}

/// Ergebnis einer Spielrunde — XP + persönliche Bestleistung.
class GameOutcome {
  final int xpGained;
  final LearningAttempt? attempt;
  final String? gameId;
  final int? best;
  final bool isNewBest;
  const GameOutcome({
    required this.xpGained,
    this.attempt,
    this.gameId,
    this.best,
    this.isNewBest = false,
  });
}

/// Reuse this attempt for the same completed round, including after failure.
/// A new round gets a new attempt. This does not resume a killed process.
class GameResultAttempt {
  GameResultAttempt({
    required String gameId,
    required int xp,
    int? score,
    bool higherIsBetter = true,
    int? dailyCompletionBonus,
    bool kkeunmariWin = false,
    LearningAttempt? learningAttempt,
  }) : _learningAttempt =
           learningAttempt ?? LearningJourneyObserver.beginAttempt(),
       _gameId = gameId,
       _xp = XpAwardAttempt(
         xp,
         dailyCompletionBonus: dailyCompletionBonus,
         kkeunmariWin: kkeunmariWin,
       ),
       _best = score == null
           ? null
           : GameBestAttempt(gameId, score, higherIsBetter: higherIsBetter);
  final LearningAttempt? _learningAttempt;
  final String _gameId;
  final XpAwardAttempt _xp;
  final GameBestAttempt? _best;
  final _lifetime = LocalDataLifetime.capture();
  bool _cancelled = false;
  GameOutcome? _outcome;
  Future<GameOutcome>? _pending;
  void cancel() {
    _cancelled = true;
  }

  void _assertCurrent() {
    _lifetime.assertCurrent();
    if (_cancelled) {
      throw const StaleLocalDataLifetimeException();
    }
  }

  Future<GameOutcome> save() {
    final pending = _pending;
    if (pending != null) {
      return pending;
    }
    final work = _save().whenComplete(() => _pending = null);
    final attempt = _learningAttempt;
    return _pending = attempt == null
        ? work
        : attempt.journey.track(work, attempt);
  }

  Future<GameOutcome> _save() async {
    _assertCurrent();
    if (_outcome != null) {
      return _outcome!;
    }
    await _xp.save();
    _assertCurrent();
    final best = _best;
    final isNewBest = best != null && await best.save();
    _assertCurrent();
    final outcome = GameOutcome(
      xpGained: _xp.earnedXp,
      attempt: _learningAttempt,
      gameId: _gameId,
      best: best?.best,
      isNewBest: isNewBest,
    );
    _outcome = outcome;
    _learningAttempt?.complete();
    SoundService.complete();
    return outcome;
  }
}

/// **Einheitliche Belohnung am Spielende.** XP gutschreiben, persönliche
/// Bestleistung aktualisieren, Abschluss-Sound spielen. Jedes Spiel ruft das
/// auf → ein konsistentes Dopamin-Loop statt zufälliger, halbfertiger
/// Belohnungen (genau das ließ die Spiele bisher "halbgar" wirken).
///
/// Selbst-Wettbewerb (persönliche Bestleistung) — **keine Ranglisten**
/// (Team-Regel: kompetitive Leaderboards = Dark-Pattern).
///
/// XP-Konvention (vom Aufrufer berechnet, hier dokumentiert für Konsistenz):
///   • Erkennen (Quiz/Matching): ×4 pro Treffer — Matching nur fehlerfrei voll.
///   • Abruf (Tippen/Cloze): ×5 pro Treffer (Abruf > Erkennen → kleine Prämie).
///   • Chosung: ×4 pro Runde-Treffer. Kkeunmari: Kettenlänge ×10 (20–500).
///   • Wordle: 10 + (übrige Versuche)×5 bei Sieg, 4 bei Niederlage.
Future<GameOutcome> recordGameResult({
  required String gameId,
  required int xp,
  int? score,
  bool higherIsBetter = true,
  LearningAttempt? learningAttempt,
}) => GameResultAttempt(
  gameId: gameId,
  xp: xp,
  score: score,
  higherIsBetter: higherIsBetter,
  learningAttempt: learningAttempt,
).save();

/// **GameOverCard** — einheitlicher, erwachsen-eleganter Abschluss-Körper.
///
/// Maskottchen + Schlagzeile + (optional) Punktestand + XP-Hochzählen +
/// (optional) Rekord-Badge, dazu ein einmaliger Konfetti-Burst beim Erscheinen
/// (reduce-motion-sicher). Spiele behalten ihr eigenes Scaffold; sie geben die
/// Buttons als [actions] hinein (untereinander, mit Abstand gerendert).
class GameOverCard extends StatefulWidget {
  final GameOutcome? outcome;

  /// False while an outcome-backed reward is unknown. Legacy callers can still
  /// display an explicitly known zero-XP result with the default true value.
  final bool rewardReady;
  final String headline;
  final String? scoreLabel;
  final int xpGained;

  /// Bereits formatierter Bestleistungs-Text, z. B. "Beste Genauigkeit: 90%".
  final String? bestLabel;
  final bool isNewBest;
  final String? newBestLabel; // z. B. "Neuer Rekord!"

  /// Optionaler Streak-Hinweis (🔥), getrennt vom Rekord-Trophäen-Slot.
  /// Für Konsistenz = "du warst dran" (nicht "gewonnen") → auch bei schwachem
  /// Score tonal stimmig.
  final String? streakLabel;

  /// `null`이면 [MascotPreference] 의 선택 캐릭터. 승패로 캐릭터를 바꾸는
  /// 게임들은 명시적으로 넘긴다(까치=승리, 호랑이=위로 — 의도된 연출).
  final MascotKind? mascotKind;
  final MascotEmotion mascotEmotion;
  final bool celebrate; // Burst beim Erscheinen
  final List<Widget> actions;
  final ContentFeedbackContext? feedbackContext;
  final TesterFeedbackFeatureGate? feedbackFeatureGate;
  final ContentFeedbackSubmitter? feedbackSubmitter;
  final Iterable<String>? feedbackCompletedMissionIds;

  const GameOverCard({
    super.key,
    required this.headline,
    this.outcome,
    this.rewardReady = true,
    required this.xpGained,
    this.scoreLabel,
    this.bestLabel,
    this.isNewBest = false,
    this.newBestLabel,
    this.streakLabel,
    this.mascotKind,
    this.mascotEmotion = MascotEmotion.celebrate,
    this.celebrate = true,
    this.actions = const [],
    this.feedbackContext,
    this.feedbackFeatureGate,
    this.feedbackSubmitter,
    this.feedbackCompletedMissionIds,
  });

  @override
  State<GameOverCard> createState() => _GameOverCardState();
}

class _GameOverCardState extends State<GameOverCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      if (widget.celebrate) {
        SoriCelebration.burst(context);
      }
      if (SoriMotion.reduceMotion(context)) {
        _ctrl.value = 1.0;
      } else {
        _ctrl.forward();
      }
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  /// 배치 계획 2026-07-29 §2: 감정에 맞는 캐릭터 클립(흰배경 mp4).
  /// 없으면 null → 기존 정적 마스코트 유지.
  String? get _feedbackClip {
    final kind = kindOrPreferred;
    if (kind == null) {
      return null;
    }
    return CharacterClips.feedbackFor(
      kind,
      widget.mascotEmotion,
      newBest: widget.isNewBest,
    );
  }

  /// Explicit kinds are authored game feedback. A missing kind represents the
  /// learner's personal companion and therefore remains nullable for `none`.
  MascotKind? get kindOrPreferred =>
      widget.mascotKind ?? MascotPreference.selectedKind;

  @override
  Widget build(BuildContext context) {
    final s = SoriSurfaces.of(context);
    final feedbackScope = ContentFeedbackControllerScope.maybeOf(context);
    final feedbackFeatureGate =
        widget.feedbackFeatureGate ??
        feedbackScope?.featureGate ??
        const TesterFeedbackFeatureGate();
    final feedbackSubmitter =
        widget.feedbackSubmitter ?? feedbackScope?.submitFeedback;
    final feedbackCompletedMissionIds =
        widget.feedbackCompletedMissionIds ??
        feedbackScope?.completedMissionIds ??
        const <String>{};
    final kind = kindOrPreferred;
    // ⚠️ 결과 화면 전체를 **평면 스캐폴드 색**으로 덮는다.
    // 이 카드를 띄우는 게임 4종(cloze·daily_challenge·satz_arcade·speed_match)은
    // `SoriScreenBackground` 를 쓰는데, 거기 `_HanjiPainter` 가 반지름 48~163px
    // 짜리 구름 얼룩(#D4C496 @0.075)을 뿌려 배경을 얼룩덜룩하게 만든다
    // (실측 #FAF6EC → #F7F2E6). 아래 축하 클립은 흰 매트를 multiply 로 지운
    // **완전 평면** 사각형이라, blendColor 가 맞아도 "매끈한 밝은 사각형"으로
    // 읽힌다 — Jin 이 반복 지적한 "호랑이 흰 배경"의 실제 정체.
    // 바탕을 평면으로 만들면 클립 사각형이 배경과 완전히 같은 값이 된다.
    return ColoredBox(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: Padding(
        padding: const EdgeInsets.all(Spacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Center(
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (kind != null) ...[
                        if (_feedbackClip == null)
                          Mascot(
                            kind: kind,
                            emotion: widget.mascotEmotion,
                            size: 104,
                            animate: true,
                          )
                        else
                          CharacterClipPlayer(
                            asset: _feedbackClip!,
                            size: 116,
                            blendColor: Theme.of(
                              context,
                            ).scaffoldBackgroundColor,
                            fallbackKind: kind,
                            fallbackEmotion: widget.mascotEmotion,
                          ),
                        const SizedBox(height: Spacing.md),
                      ],
                      Text(
                        widget.headline,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (widget.scoreLabel != null) ...[
                        const SizedBox(height: Spacing.xs),
                        Text(
                          widget.scoreLabel!,
                          style: TextStyle(fontSize: 15, color: s.textMuted),
                        ),
                      ],
                      if (widget.rewardReady) ...[
                        const SizedBox(height: Spacing.lg),
                        AnimatedBuilder(
                          animation: _ctrl,
                          builder: (rewardContext, __) {
                            final shown = (widget.xpGained * _ctrl.value)
                                .round();
                            return Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 18,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: SoriColors.gold.withValues(alpha: 0.14),
                                borderRadius: BorderRadius.circular(
                                  SoriRadius.pill,
                                ),
                                border: Border.all(
                                  color: SoriColors.gold.withValues(alpha: 0.5),
                                ),
                              ),
                              child: LearningRewardPresentation(
                                attempt: widget.outcome?.attempt,
                                kind: SoriRewardKind.xp,
                                amount: widget.outcome?.xpGained ?? 0,
                                presentationComplete: _ctrl.isCompleted,
                                child: Text(
                                  '+$shown XP',
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w700,
                                    color: SoriColors.gold,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                      if (widget.rewardReady &&
                          widget.isNewBest &&
                          widget.newBestLabel != null) ...[
                        const SizedBox(height: Spacing.md),
                        LearningRewardPresentation(
                          attempt: widget.outcome?.attempt,
                          kind: SoriRewardKind.personalBest,
                          amount: widget.outcome?.isNewBest == true ? 1 : 0,
                          identity: widget.outcome?.gameId,
                          child: _iconLine(
                            SoriGlyph.record,
                            widget.newBestLabel!,
                            SoriColors.gold,
                          ),
                        ),
                      ] else if (widget.rewardReady &&
                          widget.bestLabel != null) ...[
                        const SizedBox(height: Spacing.md),
                        Text(
                          widget.bestLabel!,
                          style: TextStyle(fontSize: 13, color: s.textMuted),
                        ),
                      ],
                      if (widget.streakLabel != null) ...[
                        const SizedBox(height: Spacing.sm),
                        _iconLine(
                          SoriGlyph.streak,
                          widget.streakLabel!,
                          SoriColors.tiger,
                        ),
                      ],
                      if (widget.feedbackContext != null &&
                          feedbackSubmitter != null &&
                          feedbackFeatureGate.isEnabled) ...[
                        const SizedBox(height: Spacing.lg),
                        ContentFeedbackCard(
                          feedbackContext: widget.feedbackContext!,
                          featureGate: feedbackFeatureGate,
                          submitFeedback: feedbackSubmitter,
                          mascotKind: kindOrPreferred,
                          completedMissionIds: feedbackCompletedMissionIds,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
            for (var i = 0; i < widget.actions.length; i++) ...[
              if (i > 0) const SizedBox(height: Spacing.sm),
              widget.actions[i],
            ],
          ],
        ),
      ),
    );
  }
}
