import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/vocab.dart';
import '../services/data_loader.dart';
import '../services/storage_service.dart';
import '../theme.dart';

const List<String> _chosungTable = [
  'ㄱ','ㄲ','ㄴ','ㄷ','ㄸ','ㄹ','ㅁ','ㅂ','ㅃ',
  'ㅅ','ㅆ','ㅇ','ㅈ','ㅉ','ㅊ','ㅋ','ㅌ','ㅍ','ㅎ',
];

const List<String> _consonantPadKeys = [
  'ㄱ','ㄴ','ㄷ','ㄹ','ㅁ','ㅂ','ㅅ','ㅇ','ㅈ','ㅊ','ㅋ','ㅌ','ㅍ','ㅎ',
];

String extractChosung(String word) {
  final buf = StringBuffer();
  for (final r in word.runes) {
    if (r >= 0xAC00 && r <= 0xD7A3) {
      buf.write(_chosungTable[(r - 0xAC00) ~/ 588]);
    } else {
      buf.writeCharCode(r);
    }
  }
  return buf.toString();
}

enum _State { waiting, correct, wrong }

class ChosungQuizScreen extends StatefulWidget {
  const ChosungQuizScreen({super.key});

  @override
  State<ChosungQuizScreen> createState() => _ChosungQuizScreenState();
}

class _ChosungQuizScreenState extends State<ChosungQuizScreen> {
  List<Vocab> _deck   = [];
  int    _idx     = 0;
  int    _correct = 0;
  int    _wrong   = 0;
  bool   _hint    = false;
  _State _state   = _State.waiting;
  String _level   = 'A1';

  final _ctrl      = TextEditingController();
  final _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final all = await DataLoader.loadVocab();
    final filtered = all
        .where((v) =>
            v.level == _level &&
            v.korean.runes.every((c) => c >= 0xAC00 && c <= 0xD7A3))
        .toList()
      ..shuffle(Random());
    if (!mounted) return;
    setState(() {
      _deck    = filtered;
      _idx     = 0;
      _correct = 0;
      _wrong   = 0;
      _hint    = false;
      _state   = _State.waiting;
    });
    _ctrl.clear();
  }

  Vocab get _card => _deck[_idx % _deck.length];

  void _submit() {
    final ans = _ctrl.text.trim();
    if (ans.isEmpty) return;
    final ok = ans == _card.korean;
    setState(() {
      _state = ok ? _State.correct : _State.wrong;
      if (ok) { _correct++; } else { _wrong++; }
    });
    // Persistenz + Haptik
    if (ok) {
      HapticFeedback.lightImpact();
      Storage.incChosungCorrect();
    } else {
      HapticFeedback.mediumImpact();
      Storage.incChosungWrong();
    }
    Future.delayed(const Duration(milliseconds: 1400), _next);
  }

  void _skip() {
    HapticFeedback.selectionClick();
    setState(() { _wrong++; _state = _State.wrong; });
    Storage.incChosungWrong();
    Future.delayed(const Duration(milliseconds: 1000), _next);
  }

  void _next() {
    if (!mounted) return;
    setState(() {
      _idx++;
      _hint  = false;
      _state = _State.waiting;
      _ctrl.clear();
    });
    _focusNode.requestFocus();
  }

  void _appendConsonant(String c) {
    final text = _ctrl.text + c;
    _ctrl.value = TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_deck.isEmpty) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final card     = _card;
    final cs       = extractChosung(card.korean);
    final total    = _deck.length;
    final pos      = _idx % total + 1;
    final showPad  = _level == 'A1' || _level == 'A2';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Anlaut-Quiz', style: TextStyle(fontWeight: FontWeight.w800)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 8, 18, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── 레벨 선택 ──────────────────────────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: ['A1', 'A2', 'B1', 'B2'].map((lvl) {
                  final selected = _level == lvl;
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: ChoiceChip(
                      label: Text(lvl, style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: selected ? Colors.white : AppColors.textMuted,
                        fontSize: 13,
                      )),
                      selected: selected,
                      selectedColor: AppColors.primary,
                      backgroundColor: AppColors.surface,
                      side: BorderSide(color: selected ? AppColors.primary : AppColors.surfaceAlt),
                      onSelected: (_) {
                        if (!selected) {
                          setState(() => _level = lvl);
                          _load();
                        }
                      },
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 10),

              // ── 통계 칩 ────────────────────────────────────────────
              Row(children: [
                _chip('✅  $_correct', AppColors.success),
                const SizedBox(width: 8),
                _chip('❌  $_wrong', AppColors.danger),
                const SizedBox(width: 8),
                _chip('$pos / $total', AppColors.textMuted),
              ]),
              const SizedBox(height: 14),

              // ── 카드 ───────────────────────────────────────────────
              _QuizCard(
                chosung:     cs,
                german:      card.german,
                hint:        _hint,
                state:       _state,
                correctWord: card.korean,
                onHint:      () => setState(() => _hint = true),
              ),
              const SizedBox(height: 12),

              // ── 입력 ───────────────────────────────────────────────
              if (_state == _State.waiting) ...[
                TextField(
                  controller: _ctrl,
                  focusNode:  _focusNode,
                  autofocus:  true,
                  textAlign:  TextAlign.center,
                  style: const TextStyle(
                    fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.text,
                  ),
                  decoration: InputDecoration(
                    hintText:  'Koreanisch eingeben...',
                    hintStyle: const TextStyle(color: AppColors.textDim, fontSize: 16),
                    filled:    true,
                    fillColor: AppColors.surface,
                    border:        OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.surfaceAlt)),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.surfaceAlt)),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.primary, width: 2)),
                  ),
                  onSubmitted: (_) => _submit(),
                ),
                const SizedBox(height: 10),
                Row(children: [
                  Expanded(
                    flex: 3,
                    child: FilledButton(
                      onPressed: _submit,
                      style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
                      child: const Text('Bestätigen', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 2,
                    child: OutlinedButton(
                      onPressed: _skip,
                      child: const Text('Überspringen'),
                    ),
                  ),
                ]),
                if (showPad) ...[
                  const SizedBox(height: 12),
                  _ConsonantPad(onTap: _appendConsonant),
                ],
              ],

              const Spacer(),

              // ── 진행 바 ────────────────────────────────────────────
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value:           pos / total,
                  backgroundColor: AppColors.surfaceAlt,
                  valueColor:      const AlwaysStoppedAnimation(AppColors.primary),
                  minHeight:       5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _chip(String label, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(
      color:        color.withOpacity(0.15),
      borderRadius: BorderRadius.circular(100),
    ),
    child: Text(label, style: TextStyle(color: color, fontSize: 12.5, fontWeight: FontWeight.w700)),
  );
}

// ── 자음 버튼 패널 ──────────────────────────────────────────────────────────────
class _ConsonantPad extends StatelessWidget {
  final void Function(String) onTap;
  const _ConsonantPad({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      alignment: WrapAlignment.center,
      children: _consonantPadKeys.map((c) => SizedBox(
        width: 44,
        height: 44,
        child: OutlinedButton(
          onPressed: () => onTap(c),
          style: OutlinedButton.styleFrom(
            padding: EdgeInsets.zero,
            side: const BorderSide(color: AppColors.surfaceAlt),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          child: Text(c, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.text)),
        ),
      )).toList(),
    );
  }
}

// ── 퀴즈 카드 위젯 ─────────────────────────────────────────────────────────────
class _QuizCard extends StatelessWidget {
  final String chosung;
  final String german;
  final bool   hint;
  final _State state;
  final String correctWord;
  final VoidCallback onHint;

  const _QuizCard({
    required this.chosung,
    required this.german,
    required this.hint,
    required this.state,
    required this.correctWord,
    required this.onHint,
  });

  @override
  Widget build(BuildContext context) {
    final (Color accent, Color bgA, Color bgB) = switch (state) {
      _State.correct => (AppColors.success, AppColors.success.withOpacity(0.2), AppColors.success.withOpacity(0.04)),
      _State.wrong   => (AppColors.danger,  AppColors.danger.withOpacity(0.2),  AppColors.danger.withOpacity(0.04)),
      _State.waiting => (AppColors.primary, AppColors.primary.withOpacity(0.14), AppColors.surface),
    };

    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 170),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: accent, width: 2),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end:   Alignment.bottomRight,
          colors: [bgA, bgB],
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            chosung.split('').join('  '),
            style: TextStyle(fontSize: 46, fontWeight: FontWeight.w900, color: accent, letterSpacing: 6),
          ),
          const SizedBox(height: 14),
          switch (state) {
            _State.correct => Text(
                '✅  $correctWord',
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.success),
              ),
            _State.wrong => Column(children: [
                Text('Antwort: $correctWord',
                    style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w700, color: AppColors.danger)),
                const SizedBox(height: 4),
                Text(german,
                    style: const TextStyle(fontSize: 14, color: AppColors.textMuted)),
              ]),
            _State.waiting => hint
                ? Text(german,
                    style: const TextStyle(fontSize: 18, color: AppColors.textMuted, fontWeight: FontWeight.w600))
                : TextButton.icon(
                    onPressed: onHint,
                    icon:  const Icon(Icons.lightbulb_outline, size: 16, color: AppColors.warning),
                    label: const Text('Hinweis', style: TextStyle(color: AppColors.warning, fontSize: 13)),
                  ),
          },
        ],
      ),
    );
  }
}
