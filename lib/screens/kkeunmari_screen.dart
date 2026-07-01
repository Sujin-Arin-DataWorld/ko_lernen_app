import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../l10n/generated/app_localizations.dart';
import '../services/data_loader.dart';
import '../services/kkeunmari_engine.dart';
import '../services/storage_service.dart';
import '../services/tts_service.dart';
import '../widgets/sori/badge.dart';
import '../widgets/sori/button.dart';
import '../widgets/sori/card.dart';
import '../widgets/sori/celebration.dart';
import '../widgets/sori/chip.dart';
import '../widgets/sori/empty_state.dart';
import '../widgets/sori/hanok_header.dart';
import '../widgets/sori/mascot.dart';
import '../widgets/sori/pressable.dart';
import '../widgets/sori/progress.dart';
import '../widgets/sori/responsive.dart';
import '../widgets/sori/screen_coach.dart';
import '../widgets/sori/spotlight_coach.dart';
import '../widgets/sori/tokens.dart';

enum _Turn { user, tiger }

enum _End { none, tigerStuck, userStuck, deadEnd, timeUp }

/// 끝말잇기 화면 — 호랑이 ↔ 사용자 턴제 게임.
///
/// 시작: 호랑이가 안전한 단어 1개 제시.
/// 사용자 차례: 호랑이 단어의 last 음절로 시작하는 단어 입력 → 30s 카운트.
/// 호랑이 차례: 자동으로 다음 단어 선택 → 호랑이가 단어 없으면 사용자 승.
/// dead_end 단어가 나오면 그 차례 종료 (다음 차례 응답 못 함).
class KkeunmariScreen extends StatefulWidget {
  const KkeunmariScreen({super.key});

  @override
  State<KkeunmariScreen> createState() => _KkeunmariScreenState();
}

class _KkeunmariScreenState extends State<KkeunmariScreen>
    with ScreenCoachMixin<KkeunmariScreen> {
  static const _turnSeconds = 30;

  bool _loading = true;
  List<KkeunmariWord> _chain = [];
  final Set<String> _used = {};
  Set<String> _vocabKeys = {}; // M1: nur diese Wörter speisen das SRS
  _Turn _turn = _Turn.user;
  _End _end = _End.none;
  bool _newBest = false; // diese Runde = längste Kette aller Zeiten?
  String _errorMsg = '';
  KkeunmariWord? _last; // 마지막으로 낸 단어 (chain 마지막)

  Timer? _timer;
  int _remaining = _turnSeconds;

  final _ctrl = TextEditingController();
  final _focusNode = FocusNode();

  // ── 코치마크 타겟 ──
  final GlobalKey _lastWordCardKey = GlobalKey();
  final GlobalKey _timerRowKey = GlobalKey();
  final GlobalKey _inputFieldKey = GlobalKey();

  @override
  String get coachId => 'kkeunmari';

  @override
  bool get coachReady => !_loading && _last != null;

  @override
  List<SpotlightStep> buildCoachSteps(BuildContext context) {
    final t = AppL10n.of(context);
    return [
      SpotlightStep(
        targetKey: _lastWordCardKey,
        title: t.coachKkeunmariStep1Title,
        body: t.coachKkeunmariStep1Body,
        icon: Icons.link_rounded,
      ),
      SpotlightStep(
        targetKey: _timerRowKey,
        title: t.coachKkeunmariStep2Title,
        body: t.coachKkeunmariStep2Body,
        icon: Icons.timer_outlined,
      ),
      SpotlightStep(
        targetKey: _inputFieldKey,
        title: t.coachKkeunmariStep3Title,
        body: t.coachKkeunmariStep3Body,
        icon: Icons.keyboard_rounded,
      ),
    ];
  }

  @override
  void initState() {
    super.initState();
    _start();
    scheduleCoach();
  }

  Future<void> _start() async {
    await KkeunmariEngine.load();
    if (!mounted) return;
    // M1: Vokabel-Keys laden → nur Kkeunmari-Wörter, die echte Vokabeln sind,
    // speisen das SRS (best-effort; Spiel läuft auch ohne).
    if (_vocabKeys.isEmpty) {
      try {
        final vocab = await DataLoader.loadVocab();
        if (!mounted) return;
        _vocabKeys = vocab.map((v) => v.korean).toSet();
      } catch (_) {
        /* SRS-Einspeisung optional */
      }
    }
    if (!mounted) return;
    if (KkeunmariEngine.pool.isEmpty) {
      // Pool leer (Asset fehlt/defekt) → Leer-Zustand zeigen statt pickStart-Crash.
      setState(() => _loading = false);
      return;
    }
    final start = KkeunmariEngine.pickStart();
    setState(() {
      _chain = [start];
      _used
        ..clear()
        ..add(start.word);
      _last = start;
      _turn = _Turn.user;
      _end = _End.none;
      _newBest = false;
      _errorMsg = '';
      _remaining = _turnSeconds;
      _loading = false;
    });
    _ctrl.clear();
    _startTimer();
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) TtsService.speak(start.word);
    });
  }

  void _startTimer() {
    _timer?.cancel();
    _remaining = _turnSeconds;
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      setState(() => _remaining--);
      if (_remaining <= 0) {
        t.cancel();
        _endGame(_End.timeUp);
      }
    });
  }

  void _stopTimer() {
    _timer?.cancel();
    _timer = null;
  }

  String get _required => _last?.last ?? '';

  void _submit() {
    if (_end != _End.none || _turn != _Turn.user) return;
    final input = _ctrl.text.trim();
    if (input.isEmpty) return;
    final (valid, reason, word) = KkeunmariEngine.validateUserWord(
      input,
      _required,
      _used,
    );
    if (!valid) {
      final t = AppL10n.of(context);
      HapticFeedback.mediumImpact();
      setState(() {
        _errorMsg = switch (reason) {
          'not_korean' => t.kkeunmariNotKorean,
          'not_in_pool' => t.kkeunmariNotInPool,
          'wrong_start' => t.kkeunmariWrongStart(_required),
          'already_used' => t.kkeunmariAlreadyUsed,
          _ => '',
        };
      });
      return;
    }
    final w = word!;
    HapticFeedback.lightImpact();
    setState(() {
      _chain.add(w);
      _used.add(w.word);
      _last = w;
      _errorMsg = '';
      _ctrl.clear();
    });
    TtsService.speak(w.word);

    // M1: nur echte Vokabeln ins SRS (Kkeunmari-Pool ≠ Vokabel-CSV → sonst
    // Geisterkarten, die in der Wiederholung nie auftauchen).
    if (_vocabKeys.contains(w.word)) {
      Storage.srsReview(w.word, gotIt: true);
    }

    // dead_end → 호랑이 응답 불가 → 사용자 승 직전, 한 박자 쉬고 종료.
    if (w.isDeadEnd) {
      _stopTimer();
      Future.delayed(const Duration(milliseconds: 800), () {
        if (mounted) _endGame(_End.deadEnd);
      });
      return;
    }

    // 호랑이 차례.
    _stopTimer();
    setState(() => _turn = _Turn.tiger);
    Future.delayed(const Duration(milliseconds: 1200), _tigerMove);
  }

  void _tigerMove() {
    if (!mounted || _end != _End.none) return;
    final next = KkeunmariEngine.pickTigerNext(_required, _used);
    if (next == null) {
      _endGame(_End.tigerStuck);
      return;
    }
    setState(() {
      _chain.add(next);
      _used.add(next.word);
      _last = next;
      _turn = _Turn.user;
    });
    TtsService.speak(next.word);
    _startTimer();
    _focusNode.requestFocus();
  }

  void _endGame(_End reason) {
    if (_end != _End.none) return;
    _stopTimer();
    HapticFeedback.heavyImpact();
    setState(() => _end = reason);
    // 사용자 승 (tigerStuck, deadEnd) → 셀러브레이션 + Phase 4 Quest-Tracking.
    final didWin = reason == _End.tigerStuck || reason == _End.deadEnd;
    if (didWin) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) SoriCelebration.burst(context);
      });
      // ignore: discarded_futures
      Storage.incKkeunmariWins();
    }
    // XP 보상 — chain length × 10. 최소 20.
    final earned = (_chain.length * 10).clamp(20, 500);
    // ignore: discarded_futures
    Storage.addXp(earned);
    // Persönliche Bestleistung = längste Kette (Selbst-Wettbewerb, keine Rangliste).
    // ignore: discarded_futures
    Storage.recordGameBest('kkeunmari', _chain.length).then((b) {
      if (mounted && b) setState(() => _newBest = true);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _ctrl.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);
    final s = SoriSurfaces.of(context);

    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (KkeunmariEngine.pool.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: Text(t.kkeunmariTitle)),
        body: SoriEmptyState(
          icon: Icons.link_off_rounded,
          title: t.kkeunmariTitle,
          body: KkeunmariEngine.lastError ?? 'Pool leer.',
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          t.kkeunmariTitle,
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            padding: soriClampPadding(
              constraints.maxWidth,
              base: const EdgeInsets.fromLTRB(16, 8, 16, 20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── hero ──
                HanokHeader(
                  asset: 'assets/illustrations/hanok/kkeunmari_hero.png',
                  fallbackIcon: Icons.link_rounded,
                  fallbackTint: SoriColors.accent,
                  aspectRatio: 10 / 3,
                ),
                const SizedBox(height: Spacing.md),

                // ── chain 시각화 ──
                _ChainStrip(chain: _chain),
                const SizedBox(height: Spacing.md),

                if (_end != _End.none)
                  _ResultCard(
                    end: _end,
                    chainLength: _chain.length,
                    xpEarned: (_chain.length * 10).clamp(20, 500),
                    isNewBest: _newBest,
                    onAgain: _start,
                    onHome: () => Navigator.pop(context),
                  )
                else ...[
                  // ── 현재 차례 + 타이머 ──
                  Row(
                    key: _timerRowKey,
                    children: [
                      _TurnIndicator(turn: _turn, t: t),
                      const Spacer(),
                      _Timer(remaining: _remaining, total: _turnSeconds),
                    ],
                  ),
                  const SizedBox(height: Spacing.md),

                  // ── 마지막 단어 카드 (last 음절 강조) ──
                  KeyedSubtree(
                    key: _lastWordCardKey,
                    child: _LastWordCard(word: _last!),
                  ),
                  const SizedBox(height: Spacing.md),

                  // ── 사용자 차례: 입력 ──
                  if (_turn == _Turn.user) ...[
                    Text(
                      t.kkeunmariStartHint(_required),
                      style: TextStyle(
                        color: s.textMuted,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: Spacing.sm),
                    TextField(
                      key: _inputFieldKey,
                      controller: _ctrl,
                      focusNode: _focusNode,
                      autofocus: true,
                      textAlign: TextAlign.center,
                      decoration: InputDecoration(
                        hintText: t.kkeunmariInputHint,
                      ),
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                      ),
                      onSubmitted: (_) => _submit(),
                    ),
                    if (_errorMsg.isNotEmpty) ...[
                      const SizedBox(height: Spacing.xs),
                      Text(
                        _errorMsg,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: SoriColors.danger,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                    const SizedBox(height: Spacing.md),
                    SoriButton.filled(
                      label: t.kkeunmariSubmit,
                      icon: Icons.send_rounded,
                      accent: SoriColors.accent,
                      fullWidth: true,
                      onTap: _submit,
                    ),
                  ] else
                    // 호랑이 차례: 짧은 "생각 중" 카드
                    SoriCard(
                      variant: SoriCardVariant.base,
                      accent: SoriColors.tiger,
                      tinted: true,
                      child: Row(
                        children: [
                          const Mascot(
                            kind: MascotKind.tiger,
                            emotion: MascotEmotion.thinking,
                            size: 56,
                            animate: false,
                          ),
                          const SizedBox(width: Spacing.md),
                          Expanded(
                            child: Text(
                              t.kkeunmariTigerTurn,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: SoriColors.tiger,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                  const SizedBox(height: Spacing.lg),

                  // ── chain length ──
                  Center(
                    child: SoriChip(
                      label: t.kkeunmariChainLength(_chain.length),
                      accent: SoriColors.accent,
                      variant: SoriChipVariant.soft,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Chain Strip ──────────────────────────────────────────────────────────────

class _ChainStrip extends StatelessWidget {
  final List<KkeunmariWord> chain;
  const _ChainStrip({required this.chain});

  @override
  Widget build(BuildContext context) {
    final s = SoriSurfaces.of(context);
    return SizedBox(
      height: 38,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        reverse: true,
        itemCount: chain.length,
        separatorBuilder: (_, __) => Center(
          child: Container(
            width: 10,
            height: 2,
            margin: const EdgeInsets.symmetric(horizontal: 4),
            color: SoriColors.accent.withValues(alpha: 0.35),
          ),
        ),
        itemBuilder: (_, i) {
          final w = chain[chain.length - 1 - i];
          final isLast = i == 0;
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: isLast
                  ? SoriColors.accent.withValues(alpha: 0.18)
                  : s.surfaceAlt,
              borderRadius: SoriRadius.brPill,
              border: Border.all(
                color: isLast ? SoriColors.accent : s.border,
                width: isLast ? 1.5 : 1,
              ),
            ),
            alignment: Alignment.center,
            child: Text(
              w.word,
              style: TextStyle(
                color: isLast ? SoriColors.accent : s.text,
                fontWeight: isLast ? FontWeight.w800 : FontWeight.w600,
                fontSize: 13.5,
              ),
            ),
          );
        },
      ),
    );
  }
}

// ─── Turn Indicator ───────────────────────────────────────────────────────────

class _TurnIndicator extends StatelessWidget {
  final _Turn turn;
  final AppL10n t;
  const _TurnIndicator({required this.turn, required this.t});

  @override
  Widget build(BuildContext context) {
    final isUser = turn == _Turn.user;
    final color = isUser ? SoriColors.accent : SoriColors.tiger;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          isUser ? Icons.person_rounded : Icons.pets_rounded,
          color: color,
          size: 16,
        ),
        const SizedBox(width: 4),
        Text(
          isUser ? t.kkeunmariYourTurn : t.kkeunmariTigerTurn,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.w800,
            fontSize: 13.5,
          ),
        ),
      ],
    );
  }
}

class _Timer extends StatelessWidget {
  final int remaining;
  final int total;
  const _Timer({required this.remaining, required this.total});

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);
    final urgent = remaining <= 10;
    final color = urgent ? SoriColors.danger : SoriColors.info;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 50,
          child: SoriProgressBar(
            value: (remaining / total).clamp(0.0, 1.0),
            thickness: 6,
            animated: false,
            color: color,
          ),
        ),
        const SizedBox(width: Spacing.xs),
        Text(
          t.kkeunmariTimerSeconds(remaining < 0 ? 0 : remaining),
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.w800,
            fontSize: 13,
          ),
        ),
      ],
    );
  }
}

// ─── Last Word Card ───────────────────────────────────────────────────────────

class _LastWordCard extends StatelessWidget {
  final KkeunmariWord word;
  const _LastWordCard({required this.word});

  @override
  Widget build(BuildContext context) {
    final s = SoriSurfaces.of(context);
    final chars = word.word.split('');
    return SoriCard(
      variant: SoriCardVariant.hero,
      accent: SoriColors.accent,
      tinted: true,
      width: double.infinity,
      child: Column(
        children: [
          LayoutBuilder(
            builder: (context, c) {
              final n = chars.length;
              final box = ((c.maxWidth - n * 4) / n).clamp(36.0, 56.0);
              final fontSize = (box * 0.5).clamp(18.0, 28.0);
              return Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(n, (i) {
                  final isLast = i == n - 1;
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    child: Container(
                      width: box,
                      height: box,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: isLast
                            ? SoriColors.accent
                            : SoriColors.accent.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(SoriRadius.sm),
                        border: Border.all(
                          color: SoriColors.accent.withValues(alpha: 0.6),
                          width: 1.5,
                        ),
                      ),
                      child: Text(
                        chars[i],
                        style: TextStyle(
                          color: isLast ? Colors.white : SoriColors.accent,
                          fontSize: fontSize,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  );
                }),
              );
            },
          ),
          const SizedBox(height: Spacing.sm),
          // Nur echte Übersetzungen zeigen — "TODO"/leer wird ausgeblendet
          // (der Pool ist fragment-lastig; siehe tools/content_factory/README).
          if (word.german.isNotEmpty && word.german != 'TODO')
            Text(
              word.german,
              style: TextStyle(
                color: s.textMuted,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          SoriPressable(
            onTap: () => TtsService.speak(word.word),
            haptic: SoriHaptic.selection,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Icon(
                Icons.volume_up_rounded,
                color: SoriColors.accent.withValues(alpha: 0.7),
                size: 22,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Result Card ──────────────────────────────────────────────────────────────

class _ResultCard extends StatelessWidget {
  final _End end;
  final int chainLength;
  final int xpEarned;
  final bool isNewBest;
  final VoidCallback onAgain;
  final VoidCallback onHome;

  const _ResultCard({
    required this.end,
    required this.chainLength,
    required this.xpEarned,
    required this.isNewBest,
    required this.onAgain,
    required this.onHome,
  });

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);
    final s = SoriSurfaces.of(context);
    final won = end == _End.tigerStuck || end == _End.deadEnd;
    final color = won ? SoriColors.success : SoriColors.warning;
    final reasonLabel = switch (end) {
      _End.tigerStuck => t.kkeunmariResultBody(chainLength),
      _End.deadEnd => t.kkeunmariDeadEnd,
      _End.timeUp => t.kkeunmariTimeUp,
      _End.userStuck => t.kkeunmariResultBody(chainLength),
      _End.none => '',
    };

    return SoriCard(
      variant: SoriCardVariant.hero,
      accent: color,
      tinted: true,
      width: double.infinity,
      child: Column(
        children: [
          Mascot(
            kind: won ? MascotKind.magpie : MascotKind.tiger,
            emotion: won ? MascotEmotion.celebrate : MascotEmotion.worry,
            size: 88,
            animate: true,
          ),
          const SizedBox(height: Spacing.md),
          Text(
            t.kkeunmariResultTitle,
            style: TextStyle(
              color: color,
              fontSize: 22,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: Spacing.xs),
          Text(
            reasonLabel,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: s.textMuted,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: Spacing.md),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SoriChip(
                label: t.kkeunmariChainLength(chainLength),
                accent: SoriColors.accent,
              ),
              const SizedBox(width: Spacing.sm),
              SoriBadge.xp(xpEarned, size: 24),
            ],
          ),
          if (isNewBest) ...[
            const SizedBox(height: Spacing.sm),
            Text(
              '🏆 ${t.gameNewBest}',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: SoriColors.gold,
              ),
            ),
          ],
          const SizedBox(height: Spacing.lg),
          Row(
            children: [
              Expanded(
                child: SoriButton.outlined(
                  label: t.kkeunmariBackHome,
                  fullWidth: true,
                  onTap: onHome,
                ),
              ),
              const SizedBox(width: Spacing.sm),
              Expanded(
                child: SoriButton.filled(
                  label: t.kkeunmariPlayAgain,
                  icon: Icons.refresh_rounded,
                  accent: color,
                  fullWidth: true,
                  onTap: onAgain,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
