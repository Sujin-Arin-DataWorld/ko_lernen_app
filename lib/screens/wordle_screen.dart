import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/vocab.dart';
import '../services/data_loader.dart';
import '../services/storage_service.dart';
import '../widgets/sori/tokens.dart';
import '../widgets/sori/card.dart';
import '../widgets/sori/celebration.dart';
import '../widgets/sori/button.dart';
import '../widgets/sori/chip.dart';
import '../widgets/sori/hanok_tokens.dart';
import '../widgets/sori/mascot.dart';
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

class _WordleScreenState extends State<WordleScreen> {
  List<Vocab> _vocab = [];
  String _target = '';

  final List<(String, List<_LS>)> _guesses = [];
  bool _won = false;
  bool _lost = false;
  String _error = '';

  final _ctrl = TextEditingController();
  final _focusNode = FocusNode();

  static const _max = 6;

  @override
  void initState() {
    super.initState();
    _load();
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
      _error = '';
    });
    _ctrl.clear();
    _focusNode.requestFocus();
  }

  String? get _targetGerman =>
      _vocab.where((v) => v.korean == _target).map((v) => v.german).firstOrNull;

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
      SoriCelebration.burst(context);
    } else if (lost) {
      HapticFeedback.mediumImpact();
      Storage.incWordleLosses();
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
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(18, 6, 18, 24),
          child: Column(
            children: [
              // ── 마루 banner (한옥 처마 + 까치 + 풍경 + 매화) ──
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: Image.asset(
                  'assets/illustrations/hanok/porch.png',
                  width: double.infinity,
                  height: 80,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                t.wordleSyllableCount(n),
                style: TextStyle(
                  color: SoriSurfaces.of(context).textMuted,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: Spacing.sm),
              if (_targetGerman != null)
                SoriCard(
                  variant: SoriCardVariant.compact,
                  accent: SoriColors.warning,
                  tinted: true,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.lightbulb_outline,
                        color: SoriColors.warning,
                        size: 15,
                      ),
                      const SizedBox(width: Spacing.xs + 2),
                      Text(
                        t.wordleMeaning(_targetGerman!),
                        style: const TextStyle(
                          color: SoriColors.warning,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: Spacing.xs + 2),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SoriChip(
                    label: t.wordleLegendCorrect,
                    accent: SoriColors.success,
                  ),
                  const SizedBox(width: 12),
                  SoriChip(
                    label: t.wordleLegendPresent,
                    accent: SoriColors.warning,
                  ),
                  const SizedBox(width: 12),
                  SoriChip(label: t.wordleLegendAbsent),
                ],
              ),
              const SizedBox(height: 16),

              // ── 그리드 (단청 frame로 감싸기 — 한옥 처마 띠 느낌) ──
              Container(
                padding: const EdgeInsets.symmetric(
                  vertical: 10,
                  horizontal: 8,
                ),
                decoration: BoxDecoration(
                  color: SoriSurfaces.of(
                    context,
                  ).surface.withValues(alpha: 0.35),
                  borderRadius: BorderRadius.circular(SoriRadius.lg),
                  border: Border.all(
                    color: HanokColors.cheong.withValues(alpha: 0.55),
                    width: 2,
                  ),
                ),
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Column(
                      children: List.generate(_max, (row) {
                        if (row < _guesses.length) {
                          final (word, states) = _guesses[row];
                          return _Row(
                            syls: word.split(''),
                            states: states,
                            n: n,
                          );
                        }
                        return _Row(
                          syls: const [],
                          states: const [],
                          n: n,
                          isActive: row == _guesses.length && !_won && !_lost,
                        );
                      }),
                    ),
                    // 단청 4코너 점 — 적·황·녹 군집
                    const Positioned(
                      top: -4,
                      left: -4,
                      child: _CornerDot(color: HanokColors.jeok),
                    ),
                    const Positioned(
                      top: -4,
                      right: -4,
                      child: _CornerDot(color: HanokColors.hwang),
                    ),
                    const Positioned(
                      bottom: -4,
                      left: -4,
                      child: _CornerDot(color: HanokColors.hwang),
                    ),
                    const Positioned(
                      bottom: -4,
                      right: -4,
                      child: _CornerDot(color: HanokColors.jeok),
                    ),
                  ],
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
                    onNew: () => _load(random: true),
                  ),
                ),
              ] else ...[
                // ── 입력 ────────────────────────────────────────────
                TextField(
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

              const SizedBox(height: Spacing.lg),
              SoriButton.outlined(
                label: t.wordleNewWordBtn,
                icon: Icons.shuffle_rounded,
                fullWidth: true,
                onTap: () => _load(random: true),
              ),
            ],
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

  const _Row({
    required this.syls,
    required this.states,
    required this.n,
    this.isActive = false,
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
    return LayoutBuilder(
      builder: (context, constraints) {
        final cell = min(
          62.0,
          (constraints.maxWidth - (n * 8)) / n,
        ).clamp(44.0, 62.0);
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
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
        );
      },
    );
  }
}

// ── 결과 카드 ──────────────────────────────────────────────────────────────────
class _ResultCard extends StatelessWidget {
  final bool won;
  final String target;
  final String? german;
  final VoidCallback onNew;

  const _ResultCard({
    required this.won,
    required this.target,
    this.german,
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
          const SizedBox(height: Spacing.lg),
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
