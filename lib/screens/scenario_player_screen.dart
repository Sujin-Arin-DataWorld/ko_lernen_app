import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../l10n/generated/app_localizations.dart';
import '../models/scenario.dart';
import '../services/premium_service.dart';
import '../services/scenario_loader.dart';
import '../services/storage_service.dart';
import '../services/tts_service.dart';
import '../widgets/sori/badge.dart';
import '../widgets/sori/button.dart';
import '../widgets/sori/card.dart';
import '../widgets/sori/celebration.dart';
import '../widgets/sori/mascot.dart';
import '../widgets/sori/progress.dart';
import '../widgets/sori/responsive.dart';
import '../widgets/sori/tokens.dart';
import '../widgets/sori/screen_coach.dart';
import '../widgets/sori/spotlight_coach.dart';
import '../widgets/sori/wordbook_add.dart';
import 'quest_engines/hoerverstehen_quest.dart';
import 'quest_engines/luecken_quest.dart';
import 'quest_engines/batchim_drop_quest.dart';
import 'quest_engines/diktat_quest.dart';
import 'quest_engines/particle_pop_quest.dart';
import 'quest_engines/quest_models.dart';
import 'quest_engines/satz_bauen_quest.dart';
import 'quest_engines/uebersetzen_quest.dart';

class ScenarioPlayerScreen extends StatefulWidget {
  final String scenarioId;

  const ScenarioPlayerScreen({super.key, required this.scenarioId});

  @override
  State<ScenarioPlayerScreen> createState() => _ScenarioPlayerScreenState();
}

class _ScenarioPlayerScreenState extends State<ScenarioPlayerScreen>
    with ScreenCoachMixin<ScenarioPlayerScreen> {
  Scenario? _scenario;
  int _stage = 0;
  int _firstTryPassedCount = 0;
  int _passedCount = 0;
  bool _questReady = true; // false → Quest läuft noch, Next-Button deaktiviert
  final PageController _pageCtrl = PageController();
  // Quest-Indizes, die der Nutzer NICHT bestanden hat. Wird in _persistResult
  // konsumiert, um deren Ziel-Vokabeln SRS-mäßig herabzustufen (error-aware
  // review).
  final Set<int> _failedQuestIndices = <int>{};

  // ── 코치마크 타겟 ──
  final GlobalKey _stageAreaKey = GlobalKey();
  final GlobalKey _nextBtnKey = GlobalKey();

  @override
  String get coachId => 'scenario';

  /// 시나리오 로드됨 + 프리미엄 게이트 화면 아님(= 실제 콘텐츠 화면).
  @override
  bool get coachReady => _scenario != null;

  @override
  List<SpotlightStep> buildCoachSteps(BuildContext context) {
    final t = AppL10n.of(context);
    // 프리미엄 게이트를 통과한 시나리오만 코치 표시.
    if (_scenario == null) {
      return [];
    }
    return [
      SpotlightStep(
        targetKey: _stageAreaKey,
        title: t.coachScenarioStep1Title,
        body: t.coachScenarioStep1Body,
        icon: Icons.school_outlined,
      ),
      SpotlightStep(
        targetKey: _nextBtnKey,
        title: t.coachScenarioStep2Title,
        body: t.coachScenarioStep2Body,
        icon: Icons.arrow_forward_rounded,
      ),
    ];
  }

  // ─── Initialisierung ───────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _loadScenario();
    scheduleCoach();
  }

  @override
  void dispose() {
    _pageCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadScenario() async {
    await ScenarioLoader.load();
    final s = ScenarioLoader.byId(widget.scenarioId);
    if (s == null) {
      if (mounted) Navigator.pop(context);
      return;
    }
    // Premium-Gate (M4): A1-Szenarien frei, A2/B1/B2 erfordern ein Abo.
    // Deckt alle Einstiege ab (Home-CTA, Skill-Path, Szenarien-Liste).
    if (s.level != LearnerLevel.a1 && !PremiumService.isPremium) {
      if (!mounted) return;
      final ok = await PremiumService.gate(context);
      if (!ok) {
        if (mounted) Navigator.pop(context);
        return;
      }
    }
    if (mounted) setState(() => _scenario = s);
  }

  // ─── Backdrop-Map ──────────────────────────────────────────────────────────

  /// Scenario → scenes/ backdrop key. Delegates to
  /// `ScenarioBackdrop.backdropKey` so the scenarios list tile reuses the
  /// same mapping (single source of truth).
  String? get _backdropKey => _scenario?.backdropKey;

  // ─── Stage-Berechnung ──────────────────────────────────────────────────────

  /// Gesamtzahl der Stages:
  /// 0=Intro, 1=Vocab, 2=Dialog, [3=Grammar], 3/4..N=Quests, last=Result
  int get _totalStages {
    final s = _scenario;
    if (s == null) return 1;
    int count = 3; // Intro + Vocab + Dialog
    if (s.grammarBlock != null) count++;
    count += s.quests.length;
    count++; // Result
    return count;
  }

  bool get _hasGrammar => _scenario?.grammarBlock != null;

  /// Index des ersten Quest-Stages
  int get _questStartStage => _hasGrammar ? 4 : 3;

  /// Ist die aktuelle Stage die Ergebnis-Stage?
  bool get _isResultStage {
    final s = _scenario;
    if (s == null) return false;
    return _stage == _questStartStage + s.quests.length;
  }

  /// Quest-Index (0-basiert) der aktuellen Stage
  int get _currentQuestIndex => _stage - _questStartStage;

  double get _progress => _totalStages == 0 ? 0 : _stage / (_totalStages - 1);

  // ─── Navigation ────────────────────────────────────────────────────────────

  void _next() {
    if (!_questReady) return;
    final nextStage = _stage + 1;
    if (nextStage >= _totalStages) return;

    // Wenn nächste Stage Quest ist → questReady = false
    final nextIsQuest =
        nextStage >= _questStartStage &&
        nextStage < _questStartStage + (_scenario?.quests.length ?? 0);
    setState(() {
      _stage = nextStage;
      _questReady = !nextIsQuest;
    });
    _pageCtrl.animateToPage(
      nextStage,
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeInOut,
    );

    // 결과 스테이지 진입 + 별 1개 이상 → 축하 연출 (단청 별·다이아 burst)
    if (_isResultStage) {
      final s = _scenario;
      if (s != null &&
          _starsFor(_passedCount, _firstTryPassedCount, s.quests.length) >= 1) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) SoriCelebration.burst(context);
        });
      }
    }
  }

  void _onQuestComplete(QuestResult result) {
    if (result.passed) _passedCount++;
    if (result.firstTry && result.passed) _firstTryPassedCount++;
    if (!result.passed) _failedQuestIndices.add(_currentQuestIndex);
    setState(() => _questReady = true);
  }

  // ─── Stern-Berechnung ──────────────────────────────────────────────────────

  int _starsFor(int passed, int firstTryPassed, int total) {
    if (total == 0) return 0;
    if (passed == total && firstTryPassed == total) return 3;
    if (passed == total) return 2;
    if (passed >= (total * 0.6).ceil()) return 1;
    return 0;
  }

  // ─── Complete (Ergebnis speichern) ─────────────────────────────────────────

  Future<void> _persistResult(int stars, int earnedXp) async {
    final s = _scenario;
    if (s == null) return;

    HapticFeedback.heavyImpact();

    await Future.wait([
      Storage.addXp(earnedXp),
      Storage.setScenarioStars(s.id, stars),
      Storage.addCompletedScenario(s.id),
    ]);

    // Erster Abschluss → Badge
    if (!Storage.earnedBadges.contains('cafe_starter')) {
      await Storage.earnBadge('cafe_starter');
    }

    // Error-aware SRS: Ziel-Vokabeln gescheiterter Quests werden als
    // "nicht gewusst" gewertet (1-Tages-Intervall), alle anderen als
    // "gewusst". Wörter aus gescheiterten Quests, die nicht in der
    // Szenario-Vokabelliste stehen, werden ebenfalls heruntergestuft.
    final missedKeys = <String>{};
    for (final idx in _failedQuestIndices) {
      if (idx >= 0 && idx < s.quests.length) {
        missedKeys.addAll(s.quests[idx].targetVocabKeys());
      }
    }
    final scenarioKeys = s.vocab.map((v) => v.korean).toSet();
    for (final v in s.vocab) {
      await Storage.srsReview(v.korean, gotIt: !missedKeys.contains(v.korean));
    }
    for (final missed in missedKeys.difference(scenarioKeys)) {
      await Storage.srsReview(missed, gotIt: false);
    }
  }

  Future<void> _complete(int stars, int earnedXp) async {
    await _persistResult(stars, earnedXp);
    if (mounted) Navigator.pop(context);
  }

  Future<void> _openNext(int stars, int earnedXp, String nextId) async {
    await _persistResult(stars, earnedXp);
    if (mounted) {
      Navigator.of(
        context,
      ).pushReplacementNamed('/scenario', arguments: nextId);
    }
  }

  /// Nächstes empfohlenes Szenario im aktuellen Level.
  /// Priorität: 1) nicht abgeschlossen, 2) abgeschlossen aber < 3 Sterne.
  /// Aktuelles Szenario wird übersprungen.
  Scenario? _nextRecommended() {
    final cur = _scenario;
    if (cur == null) return null;
    final completed = Storage.completedScenarios.toSet();
    final stars = Storage.scenarioStars;
    final sameLevel = ScenarioLoader.byLevel(
      cur.level,
    ).where((s) => s.id != cur.id).toList();
    for (final s in sameLevel) {
      if (!completed.contains(s.id)) return s;
    }
    for (final s in sameLevel) {
      if ((stars[s.id] ?? 0) < 3) return s;
    }
    return null;
  }

  // ─── Sprecher-Emoji ────────────────────────────────────────────────────────

  String _speakerEmoji(String speaker) {
    switch (speaker) {
      case 'minsu':
        return '👨🏻‍💼';
      case 'jieun':
        return '👩🏻‍🎓';
      case 'user':
        return '🧑';
      case 'narrator':
        return '📝';
      case 'partner':
        return '💗';
      case 'officer':
        return '👮';
      default:
        return '💬';
    }
  }

  /// minsu/jieun이면 [Mascot] 위젯, 그 외엔 이모지 Text 반환.
  Widget _speakerAvatar(
    String speaker, {
    double size = 40,
    MascotEmotion emotion = MascotEmotion.smile,
  }) {
    final mascot = Mascot.forSpeaker(speaker, emotion: emotion, size: size);
    if (mascot != null) return mascot;
    return Text(_speakerEmoji(speaker), style: TextStyle(fontSize: size * 0.6));
  }

  // ─── Stage-Widgets ─────────────────────────────────────────────────────────

  Widget _buildIntro(AppL10n t, String lang) {
    final s = _scenario!;
    final ss = SoriSurfaces.of(context);
    return _StageScroll(
      child: Column(
        children: [
          _ScenarioIntroArt(
            backdropKey: _backdropKey,
            emoji: s.emoji,
            sidekick: s.sidekick,
          ),
          const SizedBox(height: Spacing.xl),
          Text(
            t.scenarioIntroTitle,
            style: SoriTextTheme.of(
              context,
            ).caption.copyWith(letterSpacing: 1.2, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: Spacing.xs),
          Text(
            s.title.pick(lang),
            style: SoriTextTheme.of(context).display,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: Spacing.lg),
          SoriCard(
            variant: SoriCardVariant.base,
            padding: const EdgeInsets.all(Spacing.lg),
            child: Text(
              s.intro.pick(lang),
              style: TextStyle(
                color: ss.textMuted,
                fontSize: 16,
                height: 1.7,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: Spacing.lg),
          SoriBadge.level(s.level.display, size: 28),
        ],
      ),
    );
  }

  Widget _buildVocab(AppL10n t, String lang) {
    final sc = _scenario!;
    final ss = SoriSurfaces.of(context);
    const vocabAccent = SoriColors.info;
    return _StageScroll(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _StageTitle(t.scenarioVocabTitle, vocabAccent),
          const SizedBox(height: Spacing.lg),
          ...sc.vocab.map(
            (v) => Padding(
              padding: const EdgeInsets.only(bottom: Spacing.md),
              child: SoriCard(
                variant: SoriCardVariant.base,
                accent: vocabAccent,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            v.korean,
                            style: const TextStyle(
                              color: vocabAccent,
                              fontSize: 26,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: () {
                            HapticFeedback.selectionClick();
                            TtsService.speak(v.korean);
                          },
                          icon: const Icon(
                            Icons.volume_up_rounded,
                            color: vocabAccent,
                            size: 22,
                          ),
                          style: IconButton.styleFrom(
                            backgroundColor: vocabAccent.withValues(
                              alpha: 0.12,
                            ),
                          ),
                        ),
                        // 시나리오 단어를 내 단어장에 담기.
                        AddToWordbookButton(
                          korean: v.korean,
                          translationDe: v.note?.de ?? '',
                          translationEn: v.note?.en ?? '',
                          compact: true,
                        ),
                      ],
                    ),
                    if (v.aliases.isNotEmpty) ...[
                      const SizedBox(height: Spacing.xs),
                      Wrap(
                        spacing: Spacing.xs,
                        runSpacing: Spacing.xs,
                        children: v.aliases
                            .map((a) => _MiniChip(a, vocabAccent))
                            .toList(),
                      ),
                    ],
                    if (v.variants.isNotEmpty) ...[
                      const SizedBox(height: Spacing.xs),
                      Wrap(
                        spacing: Spacing.xs,
                        runSpacing: Spacing.xs,
                        children: v.variants
                            .map((vt) => _MiniChip(vt, ss.textDim))
                            .toList(),
                      ),
                    ],
                    if (v.note != null) ...[
                      const SizedBox(height: Spacing.sm),
                      Text(
                        v.note!.pick(lang),
                        style: SoriTextTheme.of(context).bodySmall,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Speaker별 bubble accent 컬러
  Color _speakerAccent(String speaker) {
    switch (speaker) {
      case 'user':
        return SoriColors.primary;
      case 'narrator':
        return SoriColors.warning;
      case 'partner':
        return SoriColors.hangul;
      case 'officer':
        return SoriColors.danger;
      default:
        return SoriColors.success; // minsu, jieun, etc.
    }
  }

  Widget _buildDialog(AppL10n t, String lang) {
    final sc = _scenario!;
    final ss = SoriSurfaces.of(context);
    return _StageScroll(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _StageTitle(t.scenarioDialogTitle, SoriColors.success),
          const SizedBox(height: Spacing.lg),
          ...sc.dialog.map((line) {
            final isUser = line.speaker == 'user';
            final isNarrator = line.speaker == 'narrator';
            final bubbleAccent = _speakerAccent(line.speaker);

            return Padding(
              padding: const EdgeInsets.only(bottom: Spacing.md),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: isUser
                    ? MainAxisAlignment.end
                    : MainAxisAlignment.start,
                children: [
                  if (!isUser) ...[
                    _speakerAvatar(line.speaker, size: 40),
                    const SizedBox(width: Spacing.sm),
                  ],
                  Flexible(
                    child: isNarrator
                        ? Padding(
                            padding: const EdgeInsets.symmetric(
                              vertical: Spacing.xs,
                            ),
                            child: Text(
                              line.ko,
                              style: SoriTextTheme.of(
                                context,
                              ).bodySmall.copyWith(fontStyle: FontStyle.italic),
                            ),
                          )
                        : SoriCard(
                            variant: SoriCardVariant.compact,
                            accent: bubbleAccent,
                            tinted: isUser,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        line.ko,
                                        style: TextStyle(
                                          color: ss.text,
                                          fontSize: 17,
                                          fontWeight: FontWeight.w600,
                                          height: 1.4,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: Spacing.sm),
                                    GestureDetector(
                                      onTap: () {
                                        HapticFeedback.selectionClick();
                                        TtsService.speak(
                                          line.ko,
                                          voice: line.speaker == 'user'
                                              ? 'female'
                                              : 'male',
                                        );
                                      },
                                      child: Icon(
                                        Icons.volume_up_rounded,
                                        color: bubbleAccent.withValues(
                                          alpha: 0.7,
                                        ),
                                        size: 18,
                                      ),
                                    ),
                                  ],
                                ),
                                if (line.pick(lang).isNotEmpty) ...[
                                  const SizedBox(height: Spacing.xs),
                                  Text(
                                    line.pick(lang),
                                    style: SoriTextTheme.of(
                                      context,
                                    ).bodySmall.copyWith(color: ss.textDim),
                                  ),
                                ],
                              ],
                            ),
                          ),
                  ),
                  if (isUser) ...[
                    const SizedBox(width: Spacing.sm),
                    _speakerAvatar(line.speaker, size: 40),
                  ],
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildGrammar(AppL10n t, String lang) {
    final block = _scenario!.grammarBlock!;
    final ss = SoriSurfaces.of(context);
    const grammarAccent = SoriColors.warning;
    return _StageScroll(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _StageTitle(t.scenarioGrammarTitle, grammarAccent),
          const SizedBox(height: Spacing.lg),
          SoriCard(
            variant: SoriCardVariant.base,
            accent: grammarAccent,
            tinted: true,
            width: double.infinity,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  block.title.pick(lang),
                  style: SoriTextTheme.of(
                    context,
                  ).h2.copyWith(color: grammarAccent),
                ),
                const SizedBox(height: Spacing.md),
                Text(
                  block.explanation.pick(lang),
                  style: SoriTextTheme.of(
                    context,
                  ).body.copyWith(color: ss.textMuted, height: 1.6),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuest(QuestSpec spec, AppL10n t) {
    Widget questWidget;

    switch (spec.type) {
      case QuestType.hoerverstehen:
        questWidget = HoerverstehenQuest(
          data: spec.data,
          onComplete: (r) {
            _onQuestComplete(r);
          },
        );
      case QuestType.uebersetzen:
        questWidget = UebersetzenQuest(
          data: spec.data,
          onComplete: (r) {
            _onQuestComplete(r);
          },
        );
      case QuestType.luecken:
        questWidget = LueckenQuest(
          data: spec.data,
          onComplete: (r) {
            _onQuestComplete(r);
          },
        );
      case QuestType.particlePop:
        questWidget = ParticlePopQuest(
          data: spec.data,
          onComplete: (r) {
            _onQuestComplete(r);
          },
        );
      case QuestType.batchimDrop:
        questWidget = BatchimDropQuest(
          data: spec.data,
          onComplete: (r) {
            _onQuestComplete(r);
          },
        );
      case QuestType.satzBauen:
        questWidget = SatzBauenQuest(
          data: spec.data,
          onComplete: (r) {
            _onQuestComplete(r);
          },
        );
      case QuestType.diktat:
        questWidget = DiktatQuest(
          data: spec.data,
          onComplete: (r) {
            _onQuestComplete(r);
          },
        );
      default:
        questWidget = Center(
          child: Builder(
            builder: (ctx) {
              final ss = SoriSurfaces.of(ctx);
              return Text(
                'Quest type "${spec.type.name}" noch nicht implementiert.',
                style: TextStyle(color: ss.textMuted),
                textAlign: TextAlign.center,
              );
            },
          ),
        );
    }

    return _StageScroll(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _StageTitle(
            '${t.scenarioQuestsTitle} ${_currentQuestIndex + 1}/${_scenario!.quests.length}',
            SoriColors.primary,
          ),
          const SizedBox(height: Spacing.xl),
          questWidget,
        ],
      ),
    );
  }

  Widget _buildResult(AppL10n t, String lang) {
    final sc = _scenario!;
    final ss = SoriSurfaces.of(context);
    final stars = _starsFor(
      _passedCount,
      _firstTryPassedCount,
      sc.quests.length,
    );
    final xpFull = sc.xpReward;
    final earnedXp = stars == 3
        ? xpFull
        : stars == 2
        ? (xpFull * 2 ~/ 3)
        : stars == 1
        ? (xpFull ~/ 3)
        : 0;

    // Mascot emotion based on stars
    final mascotEmotion = stars == 3
        ? MascotEmotion.celebrate
        : stars >= 1
        ? MascotEmotion.smile
        : MascotEmotion.worry;
    // Mascot kind: 'kkachi'/'magpie' → magpie (좋은 소식 분위기), else tiger 기본
    final mascotKind = (sc.sidekick == 'kkachi' || sc.sidekick == 'magpie')
        ? MascotKind.magpie
        : MascotKind.tiger;

    return _StageScroll(
      child: Column(
        children: [
          const SizedBox(height: Spacing.xl),

          // Celebrating mascot
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: 1.0),
            duration: const Duration(milliseconds: 600),
            curve: SoriMotion.celebrate,
            builder: (_, v, child) => Transform.scale(scale: v, child: child),
            child: Mascot(
              kind: mascotKind,
              emotion: mascotEmotion,
              size: 120,
              animate: true,
            ),
          ),
          const SizedBox(height: Spacing.lg),

          // Sterne (SoriStars + AnimatedScale)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(3, (i) {
              final filled = i < stars;
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: Spacing.xs),
                child: TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.0, end: filled ? 1.0 : 0.8),
                  duration: Duration(milliseconds: 400 + i * 150),
                  curve: SoriMotion.celebrate,
                  builder: (_, v, child) =>
                      Transform.scale(scale: v, child: child),
                  child: Icon(
                    filled ? Icons.star_rounded : Icons.star_outline_rounded,
                    size: 48,
                    color: filled ? SoriColors.warning : ss.textDim,
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: Spacing.md),
          Text(
            t.scenarioStarsLabel(stars),
            style: SoriTextTheme.of(context).bodySmall,
          ),
          const SizedBox(height: Spacing.lg),

          // XP Badge (SoriBadge.xp)
          SoriCard(
            variant: SoriCardVariant.base,
            accent: SoriColors.primary,
            tinted: true,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SoriBadge.xp(earnedXp, size: 28),
                const SizedBox(width: Spacing.sm),
                Text(
                  t.scenarioXpEarned(earnedXp),
                  style: SoriTextTheme.of(context).h3.copyWith(
                    color: SoriColors.primary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: Spacing.xl),

          // Recap — was du in diesem Szenario gelernt hast
          SoriCard(
            variant: SoriCardVariant.base,
            accent: SoriColors.primary,
            width: double.infinity,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  t.scenarioRecapTitle,
                  style: SoriTextTheme.of(context).label.copyWith(
                    color: SoriColors.primary,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: Spacing.sm),
                _RecapLine(
                  icon: Icons.menu_book_rounded,
                  text: t.scenarioRecapWordsLine(sc.vocab.length),
                ),
                const SizedBox(height: Spacing.xs),
                _RecapLine(
                  icon: Icons.check_circle_outline_rounded,
                  text: t.scenarioRecapAccuracyLine(
                    _firstTryPassedCount,
                    sc.quests.length,
                  ),
                ),
                if (sc.grammarBlock != null) ...[
                  const SizedBox(height: Spacing.xs),
                  _RecapLine(
                    icon: Icons.translate_rounded,
                    text: t.scenarioRecapGrammarLine(
                      sc.grammarBlock!.title.pick(lang),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: Spacing.xl),

          // Cultural Note
          if (sc.culturalNote != null) ...[
            SoriCard(
              variant: SoriCardVariant.base,
              accent: SoriColors.warning,
              tinted: true,
              width: double.infinity,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text('🏮', style: TextStyle(fontSize: 18)),
                      const SizedBox(width: Spacing.sm),
                      Text(
                        t.scenarioCulturalNote,
                        style: SoriTextTheme.of(context).label.copyWith(
                          color: SoriColors.warning,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: Spacing.sm),
                  Text(
                    sc.culturalNote!.title.pick(lang),
                    style: SoriTextTheme.of(context).h3,
                  ),
                  const SizedBox(height: Spacing.xs),
                  Text(
                    sc.culturalNote!.body.pick(lang),
                    style: SoriTextTheme.of(
                      context,
                    ).bodySmall.copyWith(height: 1.5),
                  ),
                ],
              ),
            ),
            const SizedBox(height: Spacing.xl),
          ],

          // Next recommended — nächstes Szenario im gleichen Level
          Builder(
            builder: (_) {
              final next = _nextRecommended();
              if (next == null) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: Spacing.lg),
                  child: Text(
                    t.scenarioNextRecommendedAllDone(sc.level.display),
                    textAlign: TextAlign.center,
                    style: SoriTextTheme.of(context).bodySmall,
                  ),
                );
              }
              return Padding(
                padding: const EdgeInsets.only(bottom: Spacing.lg),
                child: SoriCard(
                  variant: SoriCardVariant.base,
                  accent: SoriColors.accent,
                  tinted: true,
                  width: double.infinity,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        t.scenarioNextRecommendedTitle,
                        style: SoriTextTheme.of(context).label.copyWith(
                          color: SoriColors.accent,
                          letterSpacing: 0.8,
                        ),
                      ),
                      const SizedBox(height: Spacing.sm),
                      Row(
                        children: [
                          SizedBox(
                            width: 36,
                            height: 36,
                            child:
                                Mascot.forSpeaker(
                                  next.sidekick ?? '',
                                  size: 36,
                                  emotion: MascotEmotion.smile,
                                ) ??
                                Mascot.tiger(
                                  emotion: MascotEmotion.smile,
                                  size: 36,
                                ),
                          ),
                          const SizedBox(width: Spacing.sm),
                          Expanded(
                            child: Text(
                              next.title.pick(lang),
                              style: SoriTextTheme.of(
                                context,
                              ).body.copyWith(fontWeight: FontWeight.w700),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: Spacing.sm),
                          SoriButton.outlined(
                            label: t.scenarioNextRecommendedCta,
                            onTap: () => _openNext(stars, earnedXp, next.id),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),

          // Complete-Button
          SoriButton.filled(
            label: t.scenarioCompleteBtn,
            accent: SoriColors.success,
            fullWidth: true,
            onTap: () => _complete(stars, earnedXp),
          ),
        ],
      ),
    );
  }

  // ─── Stage-Dispatcher ──────────────────────────────────────────────────────

  Widget _buildStage(int index, AppL10n t, String lang) {
    if (index == 0) return _buildIntro(t, lang);
    if (index == 1) return _buildVocab(t, lang);
    if (index == 2) return _buildDialog(t, lang);

    if (_hasGrammar) {
      if (index == 3) return _buildGrammar(t, lang);
    }

    if (index >= _questStartStage) {
      final questIdx = index - _questStartStage;
      final quests = _scenario!.quests;
      if (questIdx < quests.length) {
        return _buildQuest(quests[questIdx], t);
      }
      // Result stage
      return _buildResult(t, lang);
    }

    return const SizedBox.shrink();
  }

  // ─── Bottom Button ─────────────────────────────────────────────────────────

  Widget _buildBottomBar(AppL10n t) {
    if (_isResultStage) return const SizedBox.shrink();

    final isIntro = _stage == 0;
    final enabled = _questReady;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        Spacing.xl,
        0,
        Spacing.xl,
        Spacing.xxl,
      ),
      child: SoriButton.filled(
        key: _nextBtnKey,
        label: isIntro ? t.scenarioStartBtn : t.scenarioNextBtn,
        fullWidth: true,
        onTap: enabled ? _next : null,
      ),
    );
  }

  // ─── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);
    final lang = Localizations.localeOf(context).languageCode;

    if (_scenario == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          _scenario!.title.pick(lang),
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          overflow: TextOverflow.ellipsis,
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(6),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: Spacing.lg),
            child: SoriProgressBar(
              value: _progress,
              thickness: 6,
              animated: true,
            ),
          ),
        ),
      ),
      body: Stack(
        children: [
          if (_backdropKey != null)
            Positioned.fill(
              child: IgnorePointer(
                child: Opacity(
                  opacity: 0.08,
                  child: Image.asset(
                    'assets/illustrations/scenes/${_backdropKey!}.png',
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                  ),
                ),
              ),
            ),
          SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: PageView.builder(
                    key: _stageAreaKey,
                    controller: _pageCtrl,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _totalStages,
                    itemBuilder: (_, index) => _buildStage(index, t, lang),
                  ),
                ),
                _buildBottomBar(t),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Hilfs-Widgets ─────────────────────────────────────────────────────────

class _StageScroll extends StatelessWidget {
  final Widget child;

  const _StageScroll({required this.child});

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    return SingleChildScrollView(
      padding: soriClampPadding(
        width,
        base: const EdgeInsets.symmetric(
          horizontal: Spacing.lg,
          vertical: Spacing.xl,
        ),
      ),
      child: child,
    );
  }
}

class _ScenarioIntroArt extends StatelessWidget {
  final String? backdropKey;
  final String emoji;
  final String? sidekick;

  const _ScenarioIntroArt({
    required this.backdropKey,
    required this.emoji,
    required this.sidekick,
  });

  @override
  Widget build(BuildContext context) {
    final s = SoriSurfaces.of(context);
    final mascot =
        Mascot.forSpeaker(
          sidekick ?? '',
          size: 72,
          emotion: MascotEmotion.smile,
          animate: true,
        ) ??
        Mascot.tiger(emotion: MascotEmotion.smile, size: 72, animate: true);

    // Backdrop만 표시 (호랑이 없이 — 배경 자체가 시각적 focal point)
    if (backdropKey == null) {
      return Container(
        height: 140,
        width: double.infinity,
        decoration: BoxDecoration(
          color: SoriColors.primary.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(SoriRadius.lg),
          border: Border.all(color: SoriColors.primary.withValues(alpha: 0.25)),
        ),
        alignment: Alignment.center,
        child: mascot,
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(SoriRadius.lg),
      child: SizedBox(
        height: 140,
        width: double.infinity,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(
              'assets/illustrations/scenes/$backdropKey.png',
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                color: SoriColors.primary.withValues(alpha: 0.12),
                alignment: Alignment.center,
                child: mascot,
              ),
            ),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, s.bg.withValues(alpha: 0.5)],
                ),
              ),
            ),
            // 호랑이/까치를 오른쪽 하단에 배치 (배경과 구분)
            Positioned(right: Spacing.md, bottom: Spacing.xs, child: mascot),
          ],
        ),
      ),
    );
  }
}

class _StageTitle extends StatelessWidget {
  final String text;
  final Color color;

  const _StageTitle(this.text, this.color);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: SoriTextTheme.of(
        context,
      ).label.copyWith(color: color, letterSpacing: 1.2),
    );
  }
}

class _MiniChip extends StatelessWidget {
  final String label;
  final Color color;

  const _MiniChip(this.label, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(SoriRadius.xs),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Text(
        label,
        style: SoriTextTheme.of(
          context,
        ).caption.copyWith(color: color, fontWeight: FontWeight.w600),
      ),
    );
  }
}

class _RecapLine extends StatelessWidget {
  final IconData icon;
  final String text;

  const _RecapLine({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    final ss = SoriSurfaces.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: SoriColors.primary),
        const SizedBox(width: Spacing.sm),
        Expanded(
          child: Text(
            text,
            style: SoriTextTheme.of(context).bodySmall.copyWith(color: ss.text),
          ),
        ),
      ],
    );
  }
}
