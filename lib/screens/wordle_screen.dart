import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/vocab.dart';
import '../services/data_loader.dart';
import '../services/sound_service.dart';
import '../services/storage_service.dart';
import '../widgets/sori/tokens.dart';
import '../widgets/sori/card.dart';
import '../widgets/sori/celebration.dart';
import '../widgets/sori/button.dart';
import '../widgets/sori/game_reward.dart';
import '../widgets/sori/hanok_header.dart';
import '../widgets/sori/hanok_tokens.dart';
import '../widgets/sori/mascot.dart';
import '../widgets/sori/motion.dart';
import '../widgets/sori/wordbook_add.dart';
import '../widgets/sori/screen_background.dart';
import '../widgets/sori/screen_coach.dart';
import '../widgets/sori/spotlight_coach.dart';
import '../l10n/generated/app_localizations.dart';

enum _LS { empty, correct, present, absent }

List<_LS> _check(String guess, String target) {
  final n = target.length;
  final result = List.filled(n, _LS.absent);
  final used = List.filled(n, false);

  for (int i = 0; i < n && i < guess.length; i++) {
    if (guess[i] == target[i]) {
      result[i] = _LS.correct;
      used[i] = true;
    }
  }
  for (int i = 0; i < guess.length; i++) {
    if (result[i] == _LS.correct) continue;
    for (int j = 0; j < n; j++) {
      if (!used[j] && guess[i] == target[j]) {
        result[i] = _LS.present;
        used[j] = true;
        break;
      }
    }
  }
  return result;
}

class WordleScreen extends StatefulWidget {
  const WordleScreen({super.key});

  @override
  State<WordleScreen> createState() => _WordleScreenState();
}

class _WordleScreenState extends State<WordleScreen>
    with ScreenCoachMixin<WordleScreen> {
  List<Vocab> _vocab = [];
  String _target = '';

  final List<(String, List<_LS>)> _guesses = [];
  bool _won = false;
  bool _lost = false;
  int _earnedXp = 0;
  String _error = '';

  final _ctrl = TextEditingController();
  final _focusNode = FocusNode();

  // ── 코치마크 타겟 ──
  final GlobalKey _gridKey = GlobalKey();
  final GlobalKey _clueKey = GlobalKey();
  final GlobalKey _inputKey = GlobalKey();

  @override
  String get coachId => 'wordle';

  @override
  bool get coachReady => _target.isNotEmpty;

  @override
  List<SpotlightStep> buildCoachSteps(BuildContext context) {
    final t = AppL10n.of(context);
    return [
      SpotlightStep(
        targetKey: _gridKey,
        title: t.coachWordleStep1Title,
        body: t.coachWordleStep1Body,
        icon: Icons.grid_on_rounded,
      ),
      SpotlightStep(
        targetKey: _clueKey,
        title: t.coachWordleStep2Title,
        body: t.coachWordleStep2Body,
        icon: Icons.lightbulb_outline_rounded,
      ),
      SpotlightStep(
        targetKey: _inputKey,
        title: t.coachWordleStep3Title,
        body: t.coachWordleStep3Body,
        icon: Icons.keyboard_rounded,
      ),
    ];
  }

  static const _max = 6;

  @override
  void initState() {
    super.initState();
    _load();
    scheduleCoach();
  }

  Future<void> _load({bool random = false}) async {
    final all = await DataLoader.loadVocab();
    final pool =
        all
            .where(
              (v) =>
                  v.korean.length >= 2 &&
                  v.korean.length <= 3 &&
                  v.korean.runes.every((c) => c >= 0xAC00 && c <= 0xD7A3),
            )
            .map((v) => v.korean)
            .toSet()
            .toList()
          ..sort();

    String target;
    if (random) {
      target = pool[Random().nextInt(pool.length)];
    } else {
      final seed =
          DateTime.now().year * 10000 +
          DateTime.now().month * 100 +
          DateTime.now().day;
      target = pool[seed % pool.length];
    }

    if (!mounted) return;
    setState(() {
      _vocab = all;
      _target = target;
      _guesses.clear();
      _won = false;
      _lost = false;
      _earnedXp = 0;
      _error = '';
    });
    _ctrl.clear();
    _focusNode.requestFocus();
  }

  String? get _targetGerman =>
      _vocab.where((v) => v.korean == _target).map((v) => v.german).firstOrNull;

  /// Volle Vokabel zum Zielwort — für reichere Hinweise (Wortart + Beispiel).
  Vocab? get _targetVocab =>
      _vocab.where((v) => v.korean == _target).firstOrNull;

  void _showHelp() {
    final t = AppL10n.of(context);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: SoriSurfaces.of(ctx).surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          t.wordleHowTitle,
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              t.wordleHowIntro,
              style: TextStyle(
                color: SoriSurfaces.of(ctx).textMuted,
                fontSize: 13.5,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 20),
            _helpRow(
              SoriColors.success,
              t.wordleHowExact,
              t.wordleHowExactDesc,
            ),
            const SizedBox(height: 10),
            _helpRow(
              SoriColors.warning,
              t.wordleHowWrong,
              t.wordleHowWrongDesc,
            ),
            const SizedBox(height: 10),
            _helpRow(
              SoriSurfaces.of(ctx).surfaceAlt,
              t.wordleHowAbsent,
              t.wordleHowAbsentDesc,
            ),
            const SizedBox(height: 20),
            Text(
              t.wordleHowOutro,
              style: TextStyle(
                color: SoriSurfaces.of(ctx).textMuted,
                fontSize: 12.5,
                height: 1.5,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              t.btnConfirm,
              style: const TextStyle(
                color: SoriColors.info,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _helpRow(Color color, String label, String desc) {
    final s = SoriSurfaces.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(8),
          ),
          alignment: Alignment.center,
          child: const Text(
            '가',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 16,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
              Text(desc, style: TextStyle(color: s.textMuted, fontSize: 12)),
            ],
          ),
        ),
      ],
    );
  }

  void _submit() {
    final input = _ctrl.text.trim();
    if (input.isEmpty) return;

    if (input.length != _target.length) {
      setState(
        () => _error = AppL10n.of(context).wordleErrorLength(_target.length),
      );
      return;
    }
    if (!input.runes.every((c) => c >= 0xAC00 && c <= 0xD7A3)) {
      setState(() => _error = AppL10n.of(context).wordleErrorHangul);
      return;
    }

    final result = _check(input, _target);
    final won = result.every((s) => s == _LS.correct);
    final lost = !won && _guesses.length + 1 >= _max;

    setState(() {
      _error = '';
      _guesses.add((input, result));
      _won = won;
      _lost = lost;
    });
    _ctrl.clear();

    if (won) {
      HapticFeedback.heavyImpact();
      Storage.incWordleWins();
      Storage.srsReview(_target, gotIt: true); // M1: Spiel speist das SRS
      // Weniger Versuche → mehr XP. Bestleistung = wenigste Versuche.
      final xp = 10 + (_max - _guesses.length) * 5;
      _earnedXp = xp;
      recordGameResult(
        gameId: 'wordle',
        xp: xp,
        score: _guesses.length,
        higherIsBetter: false,
      ); // spielt den Abschluss-Sound
      SoriCelebration.burst(context);
    } else if (lost) {
      HapticFeedback.mediumImpact();
      SoundService.wrong();
      Storage.incWordleLosses();
      Storage.srsReview(_target, gotIt: false); // M1: Spiel speist das SRS
      _earnedXp = 4;
      Storage.addXp(4);
    } else {
      HapticFeedback.selectionClick();
    }
    // 항상 입력 필드에 다시 포커스 (결과 시에는 _ResultCard가 가려 자동 해제됨)
    if (!won && !lost) {
      _focusNode.requestFocus();
    }
  }

  KeyEventResult _onResultKey(KeyEvent event) {
    if (!(_won || _lost)) return KeyEventResult.ignored;
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    if (event.logicalKey == LogicalKeyboardKey.enter ||
        event.logicalKey == LogicalKeyboardKey.numpadEnter ||
        event.logicalKey == LogicalKeyboardKey.space) {
      _load(random: true);
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);
    if (_target.isEmpty) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final n = _target.length;
    // 작은 화면(compact)에선 배너·예문·중복 버튼을 생략해 게임판 세로 공간을
    // 확보 → 게임판 Expanded가 남는 공간에 정확히 맞춤(스크롤 없이 한 화면).
    // ⚠️ autofocus로 키보드가 올라오면 가용 높이가 줄어든다 — viewInsets를 빼서
    // 키보드 상태에서도 헤더·예문을 접어 하단 오버플로를 막는다.
    final compact =
        (MediaQuery.sizeOf(context).height -
            MediaQuery.viewInsetsOf(context).bottom) <
        720;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          t.screenWordleTitle,
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline_rounded),
            tooltip: t.wordleHelpTooltip,
            onPressed: _showHelp,
          ),
          IconButton(
            icon: const Icon(Icons.shuffle_rounded),
            tooltip: t.wordleShuffleTooltip,
            onPressed: () => _load(random: true),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SoriScreenBackground(
        child: SafeArea(
          child: Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: SoriBreakpoints.content,
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(18, 6, 18, 12),
                child: Column(
                  children: [
                    // 모듈 헤더 통일 (Phase 4) — HanokHeader 10:3 banner.
                    // 작은 화면(compact)에선 게임판 세로 공간 확보를 위해 배너 생략
                    // (AppBar 타이틀로 정체성 유지).
                    if (!compact) ...[
                      const SoriEntrance(
                        child: HanokHeader(
                          asset: 'assets/illustrations/hanok/porch.png',
                          fallbackIcon: Icons.grid_4x4_rounded,
                        ),
                      ),
                      const SizedBox(height: 14),
                    ],

                    // ── 단서: 음절 수 · 품사 · 뜻 · 예문 ──
                    // v4 (2026-06-03): Wordle이 너무 어렵다는 피드백 → 힌트 강화.
                    // 품사(명사/동사/형용사) + 뜻 + 독일어 예문을 보여줘 단어를
                    // 떠올리기 쉽게. (동의어/반의어는 데이터 확보 후 추가 예정.)
                    KeyedSubtree(
                      key: _clueKey,
                      child: Builder(
                        builder: (context) {
                          final ss = SoriSurfaces.of(context);
                          final tv = _targetVocab;
                          final pos = tv?.posDe.trim() ?? '';
                          final example = tv?.exampleGerman.trim() ?? '';
                          return Column(
                            children: [
                              Wrap(
                                alignment: WrapAlignment.center,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                spacing: 8,
                                runSpacing: 4,
                                children: [
                                  Text(
                                    t.wordleSyllableCount(n),
                                    style: TextStyle(
                                      fontFamily: 'Pretendard',
                                      color: ss.textMuted,
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  if (pos.isNotEmpty)
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: SoriColors.info.withValues(
                                          alpha: 0.12,
                                        ),
                                        borderRadius: BorderRadius.circular(
                                          SoriRadius.pill,
                                        ),
                                      ),
                                      child: Text(
                                        pos,
                                        style: const TextStyle(
                                          fontFamily: 'Pretendard',
                                          color: SoriColors.info,
                                          fontSize: 11,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              if (_targetGerman != null) ...[
                                const SizedBox(height: 6),
                                Text(
                                  _targetGerman!,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontFamily: 'Pretendard',
                                    color: ss.text,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                    height: 1.3,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                              if (!compact && example.isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Text(
                                  '„$example"',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontFamily: 'Pretendard',
                                    color: ss.textMuted,
                                    fontSize: 12.5,
                                    fontStyle: FontStyle.italic,
                                    height: 1.35,
                                  ),
                                  maxLines: 3,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ],
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 14),

                    // ── 그리드 (clean, no dancheong overlay) ──
                    // v2 (2026-05-29): dancheong_frame.png 오버레이를 제거 — 입력칸과
                    // 겹치며 그리드를 가려서 게임이 안 보였음. 외곽선 + 4 코너 점만
                    // 유지해 한옥 단청 정체성은 살리고 가독성은 회복.
                    Expanded(
                      child: Container(
                        key: _gridKey,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: SoriSurfaces.of(
                            context,
                          ).surface.withValues(alpha: 0.45),
                          borderRadius: BorderRadius.circular(SoriRadius.lg),
                          border: Border.all(
                            color: HanokColors.cheong.withValues(alpha: 0.45),
                            width: 1.5,
                          ),
                        ),
                        child: LayoutBuilder(
                          builder: (context, c) {
                            // 셀 = min(가로 허용, 세로 허용, 62) → 남는 공간에 정확히 맞춤.
                            final byW = (c.maxWidth - n * 8) / n;
                            final byH = (c.maxHeight - _max * 8) / _max;
                            final cell = [
                              byW,
                              byH,
                              62.0,
                            ].reduce((a, b) => a < b ? a : b).clamp(16.0, 62.0);
                            return Stack(
                              clipBehavior: Clip.none,
                              children: [
                                Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: List.generate(_max, (row) {
                                    if (row < _guesses.length) {
                                      final (word, states) = _guesses[row];
                                      return _Row(
                                        syls: word.split(''),
                                        states: states,
                                        n: n,
                                        maxCell: cell,
                                      );
                                    }
                                    return _Row(
                                      syls: const [],
                                      states: const [],
                                      n: n,
                                      isActive:
                                          row == _guesses.length &&
                                          !_won &&
                                          !_lost,
                                      maxCell: cell,
                                    );
                                  }),
                                ),
                                // 4 코너 단청 점 — 그리드를 가리지 않고 액센트만.
                                const Positioned(
                                  top: -6,
                                  left: -6,
                                  child: _CornerDot(color: HanokColors.jeok),
                                ),
                                const Positioned(
                                  top: -6,
                                  right: -6,
                                  child: _CornerDot(color: HanokColors.hwang),
                                ),
                                const Positioned(
                                  bottom: -6,
                                  left: -6,
                                  child: _CornerDot(color: HanokColors.hwang),
                                ),
                                const Positioned(
                                  bottom: -6,
                                  right: -6,
                                  child: _CornerDot(color: HanokColors.jeok),
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // ── 에러 ────────────────────────────────────────────────
                    if (_error.isNotEmpty)
                      SoriCard(
                        variant: SoriCardVariant.compact,
                        accent: SoriColors.danger,
                        tinted: true,
                        child: Text(
                          _error,
                          style: const TextStyle(
                            color: SoriColors.danger,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),

                    // ── 결과 ────────────────────────────────────────────────
                    if (_won || _lost) ...[
                      const SizedBox(height: 8),
                      Focus(
                        autofocus: true,
                        onKeyEvent: (_, e) => _onResultKey(e),
                        child: _ResultCard(
                          won: _won,
                          target: _target,
                          german: _targetGerman,
                          earnedXp: _earnedXp,
                          bestTries: _won ? Storage.gameBest('wordle') : 0,
                          onNew: () => _load(random: true),
                        ),
                      ),
                    ] else ...[
                      // ── 입력 ────────────────────────────────────────────
                      TextField(
                        key: _inputKey,
                        controller: _ctrl,
                        focusNode: _focusNode,
                        autofocus: true,
                        textAlign: TextAlign.center,
                        maxLength: n,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 10,
                        ),
                        decoration: InputDecoration(
                          counterText: '',
                          hintText: t.wordleInputHint(n),
                        ),
                        onSubmitted: (_) => _submit(),
                      ),
                      const SizedBox(height: Spacing.sm + 2),
                      SoriButton.filled(
                        label: t.wordleSubmitBtn,
                        accent: SoriColors.info,
                        fullWidth: true,
                        onTap: _submit,
                      ),
                    ],

                    // 새 단어 버튼은 AppBar shuffle 아이콘과 중복 → compact에선 생략.
                    if (!compact) ...[
                      const SizedBox(height: Spacing.lg),
                      SoriButton.outlined(
                        label: t.wordleNewWordBtn,
                        icon: Icons.shuffle_rounded,
                        fullWidth: true,
                        onTap: () => _load(random: true),
                      ),
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

// ── 그리드 행 ──────────────────────────────────────────────────────────────────
class _Row extends StatelessWidget {
  final List<String> syls;
  final List<_LS> states;
  final int n;
  final bool isActive;
  final double maxCell;

  const _Row({
    required this.syls,
    required this.states,
    required this.n,
    this.isActive = false,
    this.maxCell = 62.0,
  });

  static Color _bg(_LS s, bool active) => switch (s) {
    _LS.correct => SoriColors.success,
    _LS.present => SoriColors.warning,
    _LS.absent => SoriColors.darkSurfaceAlt,
    _LS.empty => Colors.transparent,
  };
  static Color _border(_LS s, bool active) => switch (s) {
    _LS.correct => SoriColors.success,
    _LS.present => SoriColors.warning,
    _LS.absent => SoriColors.darkSurfaceAlt,
    _LS.empty => active ? SoriColors.info : SoriColors.darkSurfaceAlt,
  };
  static Color _fg(_LS s) => switch (s) {
    _LS.correct || _LS.present || _LS.absent => Colors.white,
    _LS.empty => SoriColors.darkText,
  };

  @override
  Widget build(BuildContext context) {
    // 셀 = maxCell(화면 높이 기반 상한 → 게임판이 한 화면에 맞도록) + FittedBox로
    // 가로(좁은 폭·긴 단어)도 비례 축소 → 어떤 화면에서도 세로·가로 오버플로 0.
    final cell = maxCell;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(n, (i) {
            final s = i < states.length ? states[i] : _LS.empty;
            final syl = i < syls.length ? syls[i] : '';
            return AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: cell,
              height: cell,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                color: _bg(s, isActive),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _border(s, isActive), width: 2),
              ),
              alignment: Alignment.center,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  syl,
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    color: _fg(s),
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}

// ── 결과 카드 ──────────────────────────────────────────────────────────────────
class _ResultCard extends StatelessWidget {
  final bool won;
  final String target;
  final String? german;
  final int earnedXp;
  final int bestTries;
  final VoidCallback onNew;

  const _ResultCard({
    required this.won,
    required this.target,
    this.german,
    this.earnedXp = 0,
    this.bestTries = 0,
    required this.onNew,
  });

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);
    final s = SoriSurfaces.of(context);
    final color = won ? SoriColors.success : SoriColors.danger;
    return SoriCard(
      variant: SoriCardVariant.hero,
      accent: color,
      tinted: true,
      width: double.infinity,
      child: Column(
        children: [
          // 정답 시 까치 축하 / 패배 시 호랑이 worry — 결과 카드의 캐릭터.
          Mascot(
            kind: won ? MascotKind.magpie : MascotKind.tiger,
            emotion: won ? MascotEmotion.celebrate : MascotEmotion.worry,
            size: 80,
            animate: true,
          ),
          const SizedBox(height: Spacing.sm),
          Text(
            won ? t.wordleResultWin : t.wordleResultLose,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w900,
              color: color,
            ),
          ),
          if (earnedXp > 0) ...[
            const SizedBox(height: Spacing.sm),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: SoriColors.gold.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(SoriRadius.pill),
                border: Border.all(
                  color: SoriColors.gold.withValues(alpha: 0.5),
                ),
              ),
              child: Text(
                '+$earnedXp XP',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: SoriColors.gold,
                ),
              ),
            ),
          ],
          if (bestTries > 0) ...[
            const SizedBox(height: 6),
            Text(
              t.gameBestTries(bestTries),
              style: TextStyle(
                fontSize: 12.5,
                color: s.textMuted,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
          if (!won && german != null) ...[
            const SizedBox(height: Spacing.sm),
            Text(
              t.wordleAnswerLabel(target),
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: s.text,
              ),
            ),
            const SizedBox(height: 2),
            Text(german!, style: TextStyle(fontSize: 14, color: s.textMuted)),
          ],
          // 방금 배운 단어를 내 단어장에 담기.
          AddToWordbookButton(korean: target, translationDe: german ?? ''),
          const SizedBox(height: Spacing.sm),
          SoriButton.filled(
            label: t.wordleNewWordBtn,
            icon: Icons.shuffle_rounded,
            accent: color,
            fullWidth: true,
            onTap: onNew,
          ),
        ],
      ),
    );
  }
}

// ─── Dancheong corner dot ─────────────────────────────────────────────────────
class _CornerDot extends StatelessWidget {
  final Color color;
  const _CornerDot({required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: HanokColors.hanjiCream, width: 1.5),
      ),
    );
  }
}
