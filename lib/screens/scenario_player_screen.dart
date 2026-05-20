import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../l10n/generated/app_localizations.dart';
import '../models/scenario.dart';
import '../services/scenario_loader.dart';
import '../services/storage_service.dart';
import '../services/tts_service.dart';
import '../theme.dart';
import 'quest_engines/hoerverstehen_quest.dart';
import 'quest_engines/luecken_quest.dart';
import 'quest_engines/particle_pop_quest.dart';
import 'quest_engines/quest_models.dart';
import 'quest_engines/uebersetzen_quest.dart';

class ScenarioPlayerScreen extends StatefulWidget {
  final String scenarioId;

  const ScenarioPlayerScreen({super.key, required this.scenarioId});

  @override
  State<ScenarioPlayerScreen> createState() => _ScenarioPlayerScreenState();
}

class _ScenarioPlayerScreenState extends State<ScenarioPlayerScreen> {
  Scenario? _scenario;
  int _stage = 0;
  int _firstTryPassedCount = 0;
  int _passedCount = 0;
  bool _questReady = true; // false → Quest läuft noch, Next-Button deaktiviert
  final PageController _pageCtrl = PageController();

  // ─── Initialisierung ───────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _loadScenario();
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
    if (mounted) setState(() => _scenario = s);
  }

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
    final nextIsQuest = nextStage >= _questStartStage &&
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
  }

  void _onQuestComplete(QuestResult result) {
    if (result.passed) _passedCount++;
    if (result.firstTry && result.passed) _firstTryPassedCount++;
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

  Future<void> _complete(int stars, int earnedXp) async {
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

    // SRS für alle Vocab
    for (final v in s.vocab) {
      await Storage.srsReview(v.korean, gotIt: stars >= 1);
    }

    if (mounted) Navigator.pop(context);
  }

  // ─── Sprecher-Emoji ────────────────────────────────────────────────────────

  String _speakerEmoji(String speaker) {
    switch (speaker) {
      case 'minsu':    return '👨🏻‍💼';
      case 'jieun':   return '👩🏻‍🎓';
      case 'user':     return '🧑';
      case 'narrator': return '📝';
      default:         return '💬';
    }
  }

  // ─── Stage-Widgets ─────────────────────────────────────────────────────────

  Widget _buildIntro(AppL10n t, String lang) {
    final s = _scenario!;
    return _StageScroll(
      child: Column(
        children: [
          const SizedBox(height: 20),
          Text(s.emoji, style: const TextStyle(fontSize: 72)),
          const SizedBox(height: 20),
          Text(
            t.scenarioIntroTitle,
            style: const TextStyle(
              color: AppColors.textMuted,
              fontSize: 13,
              letterSpacing: 1.2,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            s.title.pick(lang),
            style: const TextStyle(
              color: AppColors.text,
              fontSize: 26,
              fontWeight: FontWeight.w700,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.surfaceAlt, width: 1.5),
            ),
            child: Text(
              s.intro.pick(lang),
              style: const TextStyle(
                color: AppColors.textMuted,
                fontSize: 15,
                height: 1.6,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 8),
          // Level badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.primary.withAlpha(30),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.primary.withAlpha(80)),
            ),
            child: Text(
              s.level.display,
              style: const TextStyle(
                color: AppColors.primary,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVocab(AppL10n t, String lang) {
    final s = _scenario!;
    return _StageScroll(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _StageTitle(t.scenarioVocabTitle, AppColors.vocab),
          const SizedBox(height: 16),
          ...s.vocab.map((v) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.vocab.withAlpha(60), width: 1.5),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          v.korean,
                          style: const TextStyle(
                            color: AppColors.vocab,
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
                        icon: const Icon(Icons.volume_up_rounded, color: AppColors.vocab, size: 22),
                        style: IconButton.styleFrom(
                          backgroundColor: AppColors.vocab.withAlpha(26),
                        ),
                      ),
                    ],
                  ),
                  if (v.aliases.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: v.aliases.map((a) => _MiniChip(a, AppColors.vocab)).toList(),
                    ),
                  ],
                  if (v.variants.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: v.variants.map((vt) => _MiniChip(vt, AppColors.textDim)).toList(),
                    ),
                  ],
                  if (v.note != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      v.note!.pick(lang),
                      style: const TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 13,
                        height: 1.4,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildDialog(AppL10n t, String lang) {
    final s = _scenario!;
    return _StageScroll(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _StageTitle(t.scenarioDialogTitle, AppColors.listen),
          const SizedBox(height: 16),
          ...s.dialog.map((line) {
            final isUser = line.speaker == 'user';
            final isNarrator = line.speaker == 'narrator';
            return Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment:
                    isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
                children: [
                  if (!isUser) ...[
                    Text(
                      _speakerEmoji(line.speaker),
                      style: const TextStyle(fontSize: 24),
                    ),
                    const SizedBox(width: 10),
                  ],
                  Flexible(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: isNarrator
                            ? Colors.transparent
                            : isUser
                                ? AppColors.primary.withAlpha(38)
                                : AppColors.surface,
                        borderRadius: BorderRadius.circular(14),
                        border: isNarrator
                            ? null
                            : Border.all(
                                color: isUser
                                    ? AppColors.primary.withAlpha(80)
                                    : AppColors.surfaceAlt,
                                width: 1.5,
                              ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (!isNarrator)
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  line.ko,
                                  style: const TextStyle(
                                    color: AppColors.text,
                                    fontSize: 17,
                                    fontWeight: FontWeight.w600,
                                    height: 1.4,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                GestureDetector(
                                  onTap: () {
                                    HapticFeedback.selectionClick();
                                    TtsService.speak(line.ko);
                                  },
                                  child: const Icon(
                                    Icons.volume_up_rounded,
                                    color: AppColors.textMuted,
                                    size: 18,
                                  ),
                                ),
                              ],
                            )
                          else
                            Text(
                              line.ko,
                              style: const TextStyle(
                                color: AppColors.textMuted,
                                fontSize: 14,
                                fontStyle: FontStyle.italic,
                                height: 1.4,
                              ),
                            ),
                          if (line.pick(lang).isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              line.pick(lang),
                              style: const TextStyle(
                                color: AppColors.textDim,
                                fontSize: 13,
                                height: 1.3,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  if (isUser) ...[
                    const SizedBox(width: 10),
                    Text(
                      _speakerEmoji(line.speaker),
                      style: const TextStyle(fontSize: 24),
                    ),
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
    return _StageScroll(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _StageTitle(t.scenarioGrammarTitle, AppColors.grammar),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.grammar.withAlpha(18),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.grammar.withAlpha(80), width: 1.5),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  block.title.pick(lang),
                  style: const TextStyle(
                    color: AppColors.grammar,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  block.explanation.pick(lang),
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 15,
                    height: 1.6,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuest(QuestSpec spec, AppL10n t) {
    final langCode = Localizations.localeOf(context).languageCode;
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
      default:
        questWidget = Center(
          child: Text(
            'Quest type "${spec.type.name}" noch nicht implementiert.',
            style: const TextStyle(color: AppColors.textMuted),
            textAlign: TextAlign.center,
          ),
        );
    }

    return _StageScroll(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _StageTitle(
            '${t.scenarioQuestsTitle} ${_currentQuestIndex + 1}/${_scenario!.quests.length}',
            AppColors.primary,
          ),
          const SizedBox(height: 20),
          questWidget,
        ],
      ),
    );
  }

  Widget _buildResult(AppL10n t, String lang) {
    final s = _scenario!;
    final stars = _starsFor(_passedCount, _firstTryPassedCount, s.quests.length);
    final xpFull = s.xpReward;
    final earnedXp = stars == 3
        ? xpFull
        : stars == 2
            ? (xpFull * 2 ~/ 3)
            : stars == 1
                ? (xpFull ~/ 3)
                : 0;

    return _StageScroll(
      child: Column(
        children: [
          const SizedBox(height: 20),
          // Sterne
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(3, (i) {
              final filled = i < stars;
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: AnimatedScale(
                  scale: filled ? 1.0 : 0.8,
                  duration: const Duration(milliseconds: 400),
                  curve: Curves.elasticOut,
                  child: Text(
                    filled ? '⭐' : '☆',
                    style: TextStyle(
                      fontSize: 44,
                      color: filled ? AppColors.warning : AppColors.textDim,
                    ),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 12),
          Text(
            t.scenarioStarsLabel(stars),
            style: const TextStyle(
              color: AppColors.textMuted,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 16),

          // XP Card
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            decoration: BoxDecoration(
              color: AppColors.primary.withAlpha(26),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.primary.withAlpha(80), width: 1.5),
            ),
            child: Text(
              t.scenarioXpEarned(earnedXp),
              style: const TextStyle(
                color: AppColors.primary,
                fontSize: 22,
                fontWeight: FontWeight.w800,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 24),

          // Cultural Note
          if (s.culturalNote != null) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.warning.withAlpha(20),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.warning.withAlpha(80), width: 1.5),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text('🏮', style: TextStyle(fontSize: 18)),
                      const SizedBox(width: 8),
                      Text(
                        t.scenarioCulturalNote,
                        style: const TextStyle(
                          color: AppColors.warning,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    s.culturalNote!.title.pick(lang),
                    style: const TextStyle(
                      color: AppColors.text,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    s.culturalNote!.body.pick(lang),
                    style: const TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 14,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],

          // Complete-Button
          FilledButton(
            onPressed: () => _complete(stars, earnedXp),
            style: FilledButton.styleFrom(
              minimumSize: const Size(double.infinity, 52),
              backgroundColor: AppColors.success,
            ),
            child: Text(
              t.scenarioCompleteBtn,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
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
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
      child: FilledButton(
        onPressed: enabled ? _next : null,
        style: FilledButton.styleFrom(
          minimumSize: const Size(double.infinity, 52),
        ),
        child: Text(
          isIntro ? t.scenarioStartBtn : t.scenarioNextBtn,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }

  // ─── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);
    final lang = Localizations.localeOf(context).languageCode;

    if (_scenario == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
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
          preferredSize: const Size.fromHeight(4),
          child: LinearProgressIndicator(
            value: _progress,
            backgroundColor: AppColors.surfaceAlt,
            valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
            minHeight: 4,
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: PageView.builder(
              controller: _pageCtrl,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _totalStages,
              itemBuilder: (_, index) => _buildStage(index, t, lang),
            ),
          ),
          _buildBottomBar(t),
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
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
      child: child,
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
      style: TextStyle(
        color: color,
        fontSize: 13,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.2,
      ),
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
        color: color.withAlpha(26),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withAlpha(60)),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600),
      ),
    );
  }
}
