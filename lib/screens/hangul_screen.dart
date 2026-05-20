import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme.dart';
import '../data/hangul_data.dart';
import '../data/hangul_strokes.dart';
import '../widgets/flip_card.dart';
import '../widgets/stroke_canvas.dart';
import '../services/tts_service.dart';

class HangulScreen extends StatefulWidget {
  const HangulScreen({super.key});

  @override
  State<HangulScreen> createState() => _HangulScreenState();
}

class _HangulScreenState extends State<HangulScreen> with SingleTickerProviderStateMixin {
  late final TabController _tabs;
  int _tabIndex = 0;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
    _tabs.addListener(() {
      if (_tabs.index != _tabIndex) setState(() => _tabIndex = _tabs.index);
    });
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Hangul', style: TextStyle(fontWeight: FontWeight.w800)),
        bottom: TabBar(
          controller: _tabs,
          indicatorColor: AppColors.hangul,
          labelColor: AppColors.hangul,
          unselectedLabelColor: AppColors.textMuted,
          tabs: const [
            Tab(icon: Icon(Icons.grid_view_rounded), text: 'Übersicht'),
            Tab(icon: Icon(Icons.style_outlined),    text: 'Karten'),
            Tab(icon: Icon(Icons.gesture),           text: 'Schreiben'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabs,
        children: const [
          _OverviewTab(),
          _CardsTab(),
          _WriteTab(),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Tab 1 — Übersicht (Grid + Detail Bottom Sheet)
// ═══════════════════════════════════════════════════════════════════════════

class _OverviewTab extends StatelessWidget {
  const _OverviewTab();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
      children: [
        _SectionLabel('자음 · Konsonanten (19)'),
        _CharGrid(chars: consonants, color: AppColors.hangul),
        const SizedBox(height: 24),
        _SectionLabel('모음 · Vokale (15)'),
        _CharGrid(chars: vowels, color: AppColors.vocab),
        const SizedBox(height: 24),
        _SectionLabel('🧩 음절 구조 · Silbenaufbau'),
        const _SyllableDemo(),
      ],
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel(this.label);
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      child: Text(label, style: const TextStyle(
        fontSize: 13, fontWeight: FontWeight.w700,
        color: AppColors.textMuted, letterSpacing: 0.5,
      )),
    );
  }
}

class _CharGrid extends StatelessWidget {
  final List<HangulChar> chars;
  final Color color;
  const _CharGrid({required this.chars, required this.color});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 5,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        childAspectRatio: 0.95,
      ),
      itemCount: chars.length,
      itemBuilder: (ctx, i) {
        final c = chars[i];
        return _CharCell(char: c, color: color, onTap: () => _showDetail(ctx, c, color));
      },
    );
  }

  void _showDetail(BuildContext ctx, HangulChar c, Color color) {
    HapticFeedback.selectionClick();
    showModalBottomSheet(
      context: ctx,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _DetailSheet(char: c, color: color),
    );
  }
}

class _CharCell extends StatelessWidget {
  final HangulChar char;
  final Color color;
  final VoidCallback onTap;
  const _CharCell({required this.char, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        splashColor: color.withValues(alpha: 0.2),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.surfaceAlt, width: 1.2),
          ),
          padding: const EdgeInsets.all(6),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(char.letter, style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: color)),
              const SizedBox(height: 2),
              Text('[${char.romanization}]', style: const TextStyle(fontSize: 10, color: AppColors.textMuted, fontStyle: FontStyle.italic)),
            ],
          ),
        ),
      ),
    );
  }
}

class _DetailSheet extends StatelessWidget {
  final HangulChar char;
  final Color color;
  const _DetailSheet({required this.char, required this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(24, 18, 24, MediaQuery.of(context).padding.bottom + 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.surfaceAlt, borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 22),
          Text(char.letter, style: TextStyle(fontSize: 92, fontWeight: FontWeight.w800, color: color, height: 1)),
          const SizedBox(height: 6),
          Text('[${char.romanization}]', style: TextStyle(fontSize: 18, color: color.withValues(alpha: 0.85), fontStyle: FontStyle.italic, fontWeight: FontWeight.w600)),
          const SizedBox(height: 16),
          Text(char.descriptionDe, textAlign: TextAlign.center, style: const TextStyle(fontSize: 14, color: AppColors.text, height: 1.5)),
          const SizedBox(height: 24),
          FilledButton.icon(
            style: FilledButton.styleFrom(backgroundColor: color),
            onPressed: () => TtsService.speak(char.letter),
            icon: const Icon(Icons.volume_up),
            label: const Text('Aussprechen'),
          ),
        ],
      ),
    );
  }
}

class _SyllableDemo extends StatelessWidget {
  const _SyllableDemo();

  @override
  Widget build(BuildContext context) {
    final examples = [
      ('한', ['ㅎ', 'ㅏ', 'ㄴ'], 'han'),
      ('국', ['ㄱ', 'ㅜ', 'ㄱ'], 'guk'),
      ('말', ['ㅁ', 'ㅏ', 'ㄹ'], 'mal'),
    ];
    return Column(
      children: examples.map((e) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: AppColors.surface,
            border: Border.all(color: AppColors.surfaceAlt),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Text(e.$1, style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w800, color: AppColors.vocab)),
              const SizedBox(width: 10),
              const Text('=', style: TextStyle(color: AppColors.textMuted)),
              const SizedBox(width: 6),
              for (var i = 0; i < e.$2.length; i++) ...[
                Text(e.$2[i], style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                if (i < e.$2.length - 1) const Text(' + ', style: TextStyle(color: AppColors.textDim)),
              ],
              const Spacer(),
              Text(e.$3, style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700, fontStyle: FontStyle.italic)),
            ],
          ),
        ),
      )).toList(),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Tab 2 — Karten (Flip + Aussprache)
// ═══════════════════════════════════════════════════════════════════════════

class _CardsTab extends StatefulWidget {
  const _CardsTab();
  @override
  State<_CardsTab> createState() => _CardsTabState();
}

class _CardsTabState extends State<_CardsTab> {
  int _mode = 0;  // 0=consonants, 1=vowels, 2=syllables
  int _idx  = 0;
  bool _flipped = false;

  List<HangulChar> get _pool {
    switch (_mode) {
      case 1: return vowels;
      case 2: return syllables.map((s) => HangulChar(s.letter, s.romanization, s.composition, s.composition)).toList();
      default: return consonants;
    }
  }

  void _next()   { HapticFeedback.selectionClick(); setState(() { _flipped = false; _idx = (_idx + 1) % _pool.length; }); }
  void _prev()   { HapticFeedback.selectionClick(); setState(() { _flipped = false; _idx = (_idx - 1 + _pool.length) % _pool.length; }); }
  void _random() { HapticFeedback.lightImpact();    setState(() { _flipped = false; _idx = math.Random().nextInt(_pool.length); }); }
  void _onFlip() { HapticFeedback.selectionClick(); setState(() => _flipped = !_flipped); }

  void _setMode(int m) {
    if (_mode == m) return;
    HapticFeedback.selectionClick();
    setState(() { _mode = m; _idx = 0; _flipped = false; });
  }

  @override
  Widget build(BuildContext context) {
    final c = _pool[_idx % _pool.length];
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          // Mode chips
          Wrap(
            spacing: 8,
            children: [
              _ModeChip(label: '자음', selected: _mode == 0, onTap: () => _setMode(0)),
              _ModeChip(label: '모음', selected: _mode == 1, onTap: () => _setMode(1)),
              _ModeChip(label: '음절', selected: _mode == 2, onTap: () => _setMode(2)),
            ],
          ),
          const SizedBox(height: 12),
          // Counter
          Text('${_idx + 1} / ${_pool.length}', style: const TextStyle(color: AppColors.textMuted, fontSize: 13)),
          const SizedBox(height: 8),

          Expanded(
            child: GestureDetector(
              onHorizontalDragEnd: (d) {
                if (d.primaryVelocity == null) return;
                if (d.primaryVelocity! < -250) _next();
                else if (d.primaryVelocity! > 250) _prev();
              },
              child: FlipCard(
                flipped: _flipped,
                onTap: _onFlip,
                front: _HangulCardFace(
                  gradient: const [Color(0xFF2A1525), Color(0xFF3A1A2C)],
                  borderColor: AppColors.hangul,
                  child: Text(c.letter, style: const TextStyle(fontSize: 110, fontWeight: FontWeight.w800, color: Color(0xFFFCC2D7))),
                ),
                back: _HangulCardFace(
                  gradient: const [Color(0xFF0F2942), Color(0xFF162E4D)],
                  borderColor: AppColors.vocab,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(c.letter, style: const TextStyle(fontSize: 60, fontWeight: FontWeight.w800, color: Color(0xFFA5D8FF))),
                      const SizedBox(height: 8),
                      Text('[${c.romanization}]', style: const TextStyle(fontSize: 20, color: Color(0xFF74C0FC), fontStyle: FontStyle.italic, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 12),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Text(c.descriptionDe, textAlign: TextAlign.center, style: const TextStyle(fontSize: 13, color: AppColors.text, height: 1.5)),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: OutlinedButton.icon(onPressed: _prev, icon: const Icon(Icons.arrow_back, size: 18), label: const Text('Zurück'))),
              const SizedBox(width: 8),
              Expanded(child: OutlinedButton.icon(onPressed: () => TtsService.speak(c.letter), icon: const Icon(Icons.volume_up, size: 18), label: const Text('Hören'))),
              const SizedBox(width: 8),
              Expanded(child: OutlinedButton.icon(onPressed: _next, icon: const Icon(Icons.arrow_forward, size: 18), label: const Text('Weiter'))),
            ],
          ),
          const SizedBox(height: 6),
          FilledButton.icon(
            onPressed: _random,
            style: FilledButton.styleFrom(backgroundColor: AppColors.hangul),
            icon: const Icon(Icons.shuffle),
            label: const Text('Zufällig'),
          ),
        ],
      ),
    );
  }
}

class _ModeChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _ModeChip({required this.label, required this.selected, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label, style: TextStyle(fontWeight: FontWeight.w700, color: selected ? Colors.white : AppColors.textMuted)),
      selected: selected,
      onSelected: (_) => onTap(),
      selectedColor: AppColors.hangul,
      backgroundColor: AppColors.surface,
      side: BorderSide(color: selected ? AppColors.hangul : AppColors.surfaceAlt),
    );
  }
}

class _HangulCardFace extends StatelessWidget {
  final List<Color> gradient;
  final Color borderColor;
  final Widget child;
  const _HangulCardFace({required this.gradient, required this.borderColor, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: gradient, begin: Alignment.topLeft, end: Alignment.bottomRight),
        border: Border.all(color: borderColor, width: 2),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: borderColor.withValues(alpha: 0.15), blurRadius: 18, offset: const Offset(0, 6))],
      ),
      child: Center(child: child),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Tab 3 — Schreiben (Stroke Order Animation + Practice)
// ═══════════════════════════════════════════════════════════════════════════

class _WriteTab extends StatefulWidget {
  const _WriteTab();
  @override
  State<_WriteTab> createState() => _WriteTabState();
}

class _WriteTabState extends State<_WriteTab> {
  int _mode = 0;  // 0=cons, 1=vowels
  int _idx = 0;
  final _practiceKey = GlobalKey<_PracticeCanvasState>();

  List<HangulChar> get _pool => _mode == 0 ? consonants : vowels;
  HangulChar get _current => _pool[_idx % _pool.length];

  void _next() {
    HapticFeedback.selectionClick();
    setState(() => _idx = (_idx + 1) % _pool.length);
    _practiceKey.currentState?.clear();
  }
  void _prev() {
    HapticFeedback.selectionClick();
    setState(() => _idx = (_idx - 1 + _pool.length) % _pool.length);
    _practiceKey.currentState?.clear();
  }
  void _setMode(int m) {
    if (_mode == m) return;
    HapticFeedback.selectionClick();
    setState(() { _mode = m; _idx = 0; });
    _practiceKey.currentState?.clear();
  }

  @override
  Widget build(BuildContext context) {
    final c = _current;
    final strokes = hangulStrokes[c.letter] ?? [];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(14),
      child: Column(
        children: [
          // 3 Regeln
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.grammar.withValues(alpha: 0.12),
              border: Border.all(color: AppColors.grammar.withValues(alpha: 0.6)),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('✏️ 한글 쓰기 3원칙', style: TextStyle(fontWeight: FontWeight.w800, color: Color(0xFFFFD43B), fontSize: 13)),
                SizedBox(height: 6),
                Text('① Oben → Unten   ② Horizontal → Vertikal   ③ Links → Rechts',
                  style: TextStyle(color: AppColors.textMuted, fontSize: 11.5, height: 1.5)),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Mode
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _ModeChip(label: '자음', selected: _mode == 0, onTap: () => _setMode(0)),
              const SizedBox(width: 8),
              _ModeChip(label: '모음', selected: _mode == 1, onTap: () => _setMode(1)),
            ],
          ),
          const SizedBox(height: 14),

          // Demo
          Column(
            children: [
              const Text('📽 Strichreihenfolge (tippe für neu)', style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
              const SizedBox(height: 6),
              Container(
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  border: Border.all(color: AppColors.vocab.withValues(alpha: 0.4), width: 2),
                  borderRadius: BorderRadius.circular(16),
                ),
                padding: const EdgeInsets.all(6),
                child: StrokeCanvas(
                  letter: c.letter,
                  strokes: strokes,
                  size: 220,
                  color: AppColors.hangul,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Practice
          Column(
            children: [
              const Text('✍️ mit dem Finger nachzeichnen', style: TextStyle(fontSize: 12, color: AppColors.success)),
              const SizedBox(height: 6),
              _PracticeCanvas(key: _practiceKey, ghost: c.letter, color: AppColors.success),
            ],
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: () => _practiceKey.currentState?.clear(),
            icon: const Icon(Icons.delete_outline, color: AppColors.danger),
            label: const Text('Löschen', style: TextStyle(color: AppColors.danger)),
            style: OutlinedButton.styleFrom(side: const BorderSide(color: AppColors.danger), minimumSize: const Size(double.infinity, 44)),
          ),
          const SizedBox(height: 12),

          // Nav
          Row(
            children: [
              Expanded(child: OutlinedButton.icon(onPressed: _prev, icon: const Icon(Icons.arrow_back, size: 18), label: const Text('Zurück'))),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(12)),
                child: Text('${_idx + 1} / ${_pool.length}', style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.text)),
              ),
              const SizedBox(width: 8),
              Expanded(child: OutlinedButton.icon(onPressed: _next, icon: const Icon(Icons.arrow_forward, size: 18), label: const Text('Weiter'))),
            ],
          ),
          const SizedBox(height: 14),
          OutlinedButton.icon(
            onPressed: () => TtsService.speak(c.letter),
            icon: const Icon(Icons.volume_up, size: 18),
            label: Text('${c.letter} aussprechen'),
            style: OutlinedButton.styleFrom(minimumSize: const Size(double.infinity, 44)),
          ),
        ],
      ),
    );
  }
}

/// Frei-Hand Canvas zum Nachzeichnen.
class _PracticeCanvas extends StatefulWidget {
  final String ghost;
  final Color color;
  const _PracticeCanvas({super.key, required this.ghost, required this.color});

  @override
  State<_PracticeCanvas> createState() => _PracticeCanvasState();
}

class _PracticeCanvasState extends State<_PracticeCanvas> {
  final List<List<Offset>> _strokes = [];
  List<Offset>? _current;

  void clear() {
    setState(() {
      _strokes.clear();
      _current = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 220, height: 220,
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.success.withValues(alpha: 0.5), width: 2),
        borderRadius: BorderRadius.circular(16),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: GestureDetector(
          onPanStart: (d) {
            setState(() {
              _current = [d.localPosition];
              _strokes.add(_current!);
            });
          },
          onPanUpdate: (d) {
            setState(() => _current?.add(d.localPosition));
          },
          onPanEnd: (_) {
            HapticFeedback.lightImpact();
            _current = null;
          },
          child: CustomPaint(
            painter: _PracticePainter(
              ghost: widget.ghost,
              strokes: _strokes,
              color: widget.color,
            ),
            child: const SizedBox.expand(),
          ),
        ),
      ),
    );
  }
}

class _PracticePainter extends CustomPainter {
  final String ghost;
  final List<List<Offset>> strokes;
  final Color color;

  _PracticePainter({required this.ghost, required this.strokes, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    // Ghost Buchstabe als Hintergrund
    final tp = TextPainter(
      text: TextSpan(text: ghost, style: TextStyle(
        fontSize: size.height * 0.85,
        fontWeight: FontWeight.w900,
        color: color.withValues(alpha: 0.08),
        height: 1,
      )),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset((size.width - tp.width) / 2, (size.height - tp.height) / 2 - 8));

    // Striche
    final p = Paint()
      ..color = color
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = 6
      ..style = PaintingStyle.stroke;

    for (final stroke in strokes) {
      if (stroke.length < 2) continue;
      final path = Path()..moveTo(stroke.first.dx, stroke.first.dy);
      for (var i = 1; i < stroke.length; i++) {
        path.lineTo(stroke[i].dx, stroke[i].dy);
      }
      canvas.drawPath(path, p);
    }
  }

  @override
  bool shouldRepaint(covariant _PracticePainter old) =>
      old.strokes.length != strokes.length ||
      (old.strokes.isNotEmpty && old.strokes.last.length != strokes.last.length) ||
      old.ghost != ghost;
}
