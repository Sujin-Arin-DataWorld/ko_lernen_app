import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/vocab.dart';
import '../services/data_loader.dart';
import '../services/storage_service.dart';
import '../theme.dart';

enum _LS { empty, correct, present, absent }

List<_LS> _check(String guess, String target) {
  final n      = target.length;
  final result = List.filled(n, _LS.absent);
  final used   = List.filled(n, false);

  for (int i = 0; i < n && i < guess.length; i++) {
    if (guess[i] == target[i]) { result[i] = _LS.correct; used[i] = true; }
  }
  for (int i = 0; i < guess.length; i++) {
    if (result[i] == _LS.correct) continue;
    for (int j = 0; j < n; j++) {
      if (!used[j] && guess[i] == target[j]) {
        result[i] = _LS.present; used[j] = true; break;
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
  List<String> _pool  = [];
  List<Vocab>  _vocab = [];
  String _target = '';

  final List<(String, List<_LS>)> _guesses = [];
  bool   _won   = false;
  bool   _lost  = false;
  String _error = '';

  final _ctrl      = TextEditingController();
  final _focusNode = FocusNode();

  static const _max = 6;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load({bool random = false}) async {
    final all = await DataLoader.loadVocab();
    final pool = all
        .where((v) =>
            v.korean.length >= 2 &&
            v.korean.length <= 3 &&
            v.korean.runes.every((c) => c >= 0xAC00 && c <= 0xD7A3))
        .map((v) => v.korean)
        .toSet()
        .toList()
      ..sort();

    String target;
    if (random) {
      target = pool[Random().nextInt(pool.length)];
    } else {
      final seed = DateTime.now().year * 10000 +
          DateTime.now().month * 100 +
          DateTime.now().day;
      target = pool[seed % pool.length];
    }

    if (!mounted) return;
    setState(() {
      _pool   = pool;
      _vocab  = all;
      _target = target;
      _guesses.clear();
      _won   = false;
      _lost  = false;
      _error = '';
    });
    _ctrl.clear();
    _focusNode.requestFocus();
  }

  String? get _targetGerman => _vocab
      .where((v) => v.korean == _target)
      .map((v) => v.german)
      .firstOrNull;

  void _showHelp() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('게임 방법', style: TextStyle(fontWeight: FontWeight.w800)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '오늘의 한국어 단어를 6번 안에 맞혀보세요.\n각 시도 후 색상이 단서를 줍니다.',
              style: TextStyle(color: AppColors.textMuted, fontSize: 13.5, height: 1.5),
            ),
            const SizedBox(height: 20),
            _helpRow(AppColors.success, '정확', '이 글자는 정확한 위치에 있어요'),
            const SizedBox(height: 10),
            _helpRow(AppColors.warning, '다른 위치', '이 글자는 단어에 있지만 위치가 달라요'),
            const SizedBox(height: 10),
            _helpRow(AppColors.surfaceAlt, '없음', '이 글자는 단어에 없어요'),
            const SizedBox(height: 20),
            const Text(
              '매일 새로운 단어가 출제됩니다.\n셔플 버튼으로 랜덤 단어도 즐길 수 있어요!',
              style: TextStyle(color: AppColors.textMuted, fontSize: 12.5, height: 1.5),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('확인', style: TextStyle(color: AppColors.vocab, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  Widget _helpRow(Color color, String label, String desc) => Row(
    crossAxisAlignment: CrossAxisAlignment.center,
    children: [
      Container(
        width: 36, height: 36,
        decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(8)),
        alignment: Alignment.center,
        child: Text('가', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16)),
      ),
      const SizedBox(width: 12),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 13)),
            Text(desc, style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
          ],
        ),
      ),
    ],
  );

  void _submit() {
    final input = _ctrl.text.trim();
    if (input.isEmpty) return;

    if (input.length != _target.length) {
      setState(() => _error = '${_target.length}글자로 입력해주세요!');
      return;
    }
    if (!input.runes.every((c) => c >= 0xAC00 && c <= 0xD7A3)) {
      setState(() => _error = '한국어로만 입력해주세요!');
      return;
    }

    final result = _check(input, _target);
    final won    = result.every((s) => s == _LS.correct);
    final lost   = !won && _guesses.length + 1 >= _max;

    setState(() {
      _error = '';
      _guesses.add((input, result));
      _won  = won;
      _lost = lost;
    });
    _ctrl.clear();

    if (won) {
      HapticFeedback.heavyImpact();
      Storage.incWordleWins();
    } else if (lost) {
      HapticFeedback.mediumImpact();
      Storage.incWordleLosses();
    } else {
      HapticFeedback.selectionClick();
      _focusNode.requestFocus();
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_target.isEmpty) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final n = _target.length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('한글 워들', style: TextStyle(fontWeight: FontWeight.w800)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon:    const Icon(Icons.help_outline_rounded),
            tooltip: '게임 방법',
            onPressed: _showHelp,
          ),
          IconButton(
            icon:    const Icon(Icons.shuffle_rounded),
            tooltip: '새 단어',
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
              Text(
                '${n}음절 단어 · 6번 안에 맞혀보세요',
                style: const TextStyle(color: AppColors.textMuted, fontSize: 13),
              ),
              const SizedBox(height: 8),
              if (_targetGerman != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.warning.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.warning.withOpacity(0.35)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.lightbulb_outline, color: AppColors.warning, size: 15),
                      const SizedBox(width: 6),
                      Text('Bedeutung: ${_targetGerman!}',
                          style: const TextStyle(color: AppColors.warning, fontSize: 13, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _legend(AppColors.success, '정확한 위치'),
                  const SizedBox(width: 12),
                  _legend(AppColors.warning, '다른 위치'),
                  const SizedBox(width: 12),
                  _legend(AppColors.surfaceAlt, '없음'),
                ],
              ),
              const SizedBox(height: 16),

              // ── 그리드 ──────────────────────────────────────────────
              ...List.generate(_max, (row) {
                if (row < _guesses.length) {
                  final (word, states) = _guesses[row];
                  return _Row(syls: word.split(''), states: states, n: n);
                }
                return _Row(
                  syls:     const [],
                  states:   const [],
                  n:        n,
                  isActive: row == _guesses.length && !_won && !_lost,
                );
              }),

              const SizedBox(height: 16),

              // ── 에러 ────────────────────────────────────────────────
              if (_error.isNotEmpty)
                Container(
                  padding:    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color:        AppColors.danger.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(_error,
                      style: const TextStyle(color: AppColors.danger, fontWeight: FontWeight.w600)),
                ),

              // ── 결과 ────────────────────────────────────────────────
              if (_won || _lost) ...[
                const SizedBox(height: 8),
                _ResultCard(
                  won:    _won,
                  target: _target,
                  german: _targetGerman,
                  onNew:  () => _load(random: true),
                ),
              ] else ...[
                // ── 입력 ────────────────────────────────────────────
                TextField(
                  controller: _ctrl,
                  focusNode:  _focusNode,
                  autofocus:  true,
                  textAlign:  TextAlign.center,
                  maxLength:  n,
                  style: const TextStyle(
                    fontSize: 24, fontWeight: FontWeight.w800,
                    color: AppColors.text, letterSpacing: 10,
                  ),
                  decoration: InputDecoration(
                    counterText: '',
                    hintText:    '$n글자 입력...',
                    hintStyle:   const TextStyle(color: AppColors.textDim, fontSize: 15, letterSpacing: 0),
                    filled:      true,
                    fillColor:   AppColors.surface,
                    border:        OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.surfaceAlt)),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.surfaceAlt)),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.vocab, width: 2)),
                  ),
                  onSubmitted: (_) => _submit(),
                ),
                const SizedBox(height: 10),
                FilledButton(
                  onPressed: _submit,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.vocab,
                    minimumSize:     const Size(double.infinity, 50),
                  ),
                  child: const Text('제출', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                ),
              ],

              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: () => _load(random: true),
                icon:  const Icon(Icons.shuffle_rounded, size: 16),
                label: const Text('새 단어'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _legend(Color color, String label) => Row(children: [
    Container(width: 14, height: 14, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3))),
    const SizedBox(width: 5),
    Text(label, style: const TextStyle(color: AppColors.textMuted, fontSize: 11.5)),
  ]);
}

// ── 그리드 행 ──────────────────────────────────────────────────────────────────
class _Row extends StatelessWidget {
  final List<String> syls;
  final List<_LS>    states;
  final int  n;
  final bool isActive;

  const _Row({required this.syls, required this.states, required this.n, this.isActive = false});

  static Color _bg(   _LS s, bool active) => switch (s) {
    _LS.correct => AppColors.success,
    _LS.present => AppColors.warning,
    _LS.absent  => AppColors.surfaceAlt,
    _LS.empty   => Colors.transparent,
  };
  static Color _border(_LS s, bool active) => switch (s) {
    _LS.correct => AppColors.success,
    _LS.present => AppColors.warning,
    _LS.absent  => AppColors.surfaceAlt,
    _LS.empty   => active ? AppColors.vocab : AppColors.surfaceAlt,
  };
  static Color _fg(_LS s) => switch (s) {
    _LS.correct || _LS.present || _LS.absent => Colors.white,
    _LS.empty => AppColors.text,
  };

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(n, (i) {
          final s   = i < states.length ? states[i] : _LS.empty;
          final syl = i < syls.length   ? syls[i]   : '';
          return AnimatedContainer(
            duration:    const Duration(milliseconds: 200),
            width:  62, height: 62,
            margin: const EdgeInsets.symmetric(horizontal: 4),
            decoration: BoxDecoration(
              color:        _bg(s, isActive),
              borderRadius: BorderRadius.circular(12),
              border:       Border.all(color: _border(s, isActive), width: 2),
            ),
            alignment: Alignment.center,
            child: Text(syl,
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: _fg(s))),
          );
        }),
      ),
    );
  }
}

// ── 결과 카드 ──────────────────────────────────────────────────────────────────
class _ResultCard extends StatelessWidget {
  final bool    won;
  final String  target;
  final String? german;
  final VoidCallback onNew;

  const _ResultCard({required this.won, required this.target, this.german, required this.onNew});

  @override
  Widget build(BuildContext context) {
    final color = won ? AppColors.success : AppColors.danger;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color:        color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(18),
        border:       Border.all(color: color.withOpacity(0.45)),
      ),
      child: Column(children: [
        Text(won ? '🎉 정답!' : '😅 아쉬워요!',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: color)),
        if (!won && german != null) ...[
          const SizedBox(height: 8),
          Text('정답: $target',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.text)),
          const SizedBox(height: 2),
          Text(german!,
              style: const TextStyle(fontSize: 14, color: AppColors.textMuted)),
        ],
        const SizedBox(height: 16),
        FilledButton.icon(
          onPressed: onNew,
          icon:  const Icon(Icons.shuffle_rounded, size: 18),
          label: const Text('새 단어', style: TextStyle(fontWeight: FontWeight.w700)),
          style: FilledButton.styleFrom(backgroundColor: color),
        ),
      ]),
    );
  }
}
