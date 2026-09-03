import 'package:flutter/material.dart';

import '../../config/tester_feedback_feature.dart';
import '../../models/content_feedback.dart';
import '../../services/sound_service.dart';
import '../../services/storage_service.dart';
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

/// Ergebnis einer Spielrunde — XP + persönliche Bestleistung.
class GameOutcome {
  final int xpGained;
  final int? best;
  final bool isNewBest;
  const GameOutcome({
    required this.xpGained,
    this.best,
    this.isNewBest = false,
  });
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
}) async {
  if (xp > 0) {
    await Storage.addXp(xp);
  }
  var isNewBest = false;
  int? best;
  if (score != null) {
    isNewBest = await Storage.recordGameBest(
      gameId,
      score,
      higherIsBetter: higherIsBetter,
    );
    best = Storage.gameBest(gameId);
  }
  SoundService.complete();
  return GameOutcome(xpGained: xp, best: best, isNewBest: isNewBest);
}

/// **GameOverCard** — einheitlicher, erwachsen-eleganter Abschluss-Körper.
///
/// Maskottchen + Schlagzeile + (optional) Punktestand + XP-Hochzählen +
/// (optional) Rekord-Badge, dazu ein einmaliger Konfetti-Burst beim Erscheinen
/// (reduce-motion-sicher). Spiele behalten ihr eigenes Scaffold; sie geben die
/// Buttons als [actions] hinein (untereinander, mit Abstand gerendert).
class GameOverCard extends StatefulWidget {
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
                      const SizedBox(height: Spacing.lg),
                      AnimatedBuilder(
                        animation: _ctrl,
                        builder: (_, __) {
                          final shown = (widget.xpGained * _ctrl.value).round();
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
                            child: Text(
                              '+$shown XP',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                                color: SoriColors.gold,
                              ),
                            ),
                          );
                        },
                      ),
                      if (widget.isNewBest && widget.newBestLabel != null) ...[
                        const SizedBox(height: Spacing.md),
                        _iconLine(
                          SoriGlyph.record,
                          widget.newBestLabel!,
                          SoriColors.gold,
                        ),
                      ] else if (widget.bestLabel != null) ...[
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
