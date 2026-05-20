import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../widgets/sori/tokens.dart';
import '../widgets/sori/card.dart';
import '../widgets/sori/chip.dart';
import '../widgets/sori/button.dart';
import '../data/hangul_data.dart';
import '../data/hangul_strokes.dart';
import '../widgets/flip_card.dart';
import '../widgets/stroke_canvas.dart';
import '../services/tts_service.dart';
import '../l10n/generated/app_localizations.dart';

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
    final t = AppL10n.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(t.screenHangulTitle, style: const TextStyle(fontWeight: FontWeight.w800)),
        bottom: TabBar(
          controller: _tabs,
          indicatorColor: SoriColors.hangul,
          labelColor: SoriColors.hangul,
          unselectedLabelColor: SoriColors.darkTextMuted,
          tabs: [
            Tab(icon: const Icon(Icons.grid_view_rounded), text: t.hangulTabOverview),
            Tab(icon: const Icon(Icons.style_outlined),    text: t.hangulTabCards),
            Tab(icon: const Icon(Icons.gesture),           text: t.hangulTabWrite),
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
    final t = AppL10n.of(context);
    return ListView(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
      children: [
        _SectionLabel('${t.hangulConsonantsLabel} (${consonants.length})'),
        _CharGrid(chars: consonants, color: SoriColors.hangul),
        const SizedBox(height: 24),
        _SectionLabel('${t.hangulVowelsLabel} (${vowels.length})'),
        _CharGrid(chars: vowels, color: SoriColors.info),
        const SizedBox(height: 24),
        _SectionLabel(t.hangulSyllableLabel),
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
        color: SoriColors.darkTextMuted, letterSpacing: 0.5,
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
      backgroundColor: SoriColors.darkSurface,
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
    return SoriCard(
      variant: SoriCardVariant.compact,
      accent: color,
      onTap: onTap,
      padding: const EdgeInsets.all(6),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(char.letter, style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: color)),
          const SizedBox(height: 2),
          Text('[${char.romanization}]', style: const TextStyle(fontSize: 10, color: SoriColors.darkTextMuted, fontStyle: FontStyle.italic)),
        ],
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
          Container(width: 40, height: 4, decoration: BoxDecoration(color: SoriColors.darkSurfaceAlt, borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 22),
          Text(char.letter, style: TextStyle(fontSize: 92, fontWeight: FontWeight.w800, color: color, height: 1)),
          const SizedBox(height: 6),
          Text('[${char.romanization}]', style: TextStyle(fontSize: 18, color: color.withValues(alpha: 0.85), fontStyle: FontStyle.italic, fontWeight: FontWeight.w600)),
          const SizedBox(height: 16),
          Text(char.descriptionDe, textAlign: TextAlign.center, style: const TextStyle(fontSize: 14, color: SoriColors.darkText, height: 1.5)),
          const SizedBox(height: 24),
          FilledButton.icon(
            style: FilledButton.styleFrom(backgroundColor: color),
            onPressed: () => TtsService.speak(char.letter),
            icon: const Icon(Icons.volume_up),
            label: Text(AppL10n.of(context).hangulPronounceBtn),
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
        child: SoriCard(
          variant: SoriCardVariant.base,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(
            children: [
              Text(e.$1, style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w800, color: SoriColors.info)),
              const SizedBox(width: 10),
              const Text('=', style: TextStyle(color: SoriColors.darkTextMuted)),
              const SizedBox(width: 6),
              for (var i = 0; i < e.$2.length; i++) ...[
                Text(e.$2[i], style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                if (i < e.$2.length - 1) const Text(' + ', style: TextStyle(color: SoriColors.darkTextDim)),
              ],
              const Spacer(),
              Text(e.$3, style: const TextStyle(color: SoriColors.primary, fontWeight: FontWeight.w700, fontStyle: FontStyle.italic)),
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
              SoriChip(label: '자음', accent: SoriColors.hangul, selected: _mode == 0, onTap: () => _setMode(0)),
              SoriChip(label: '모음', accent: SoriColors.hangul, selected: _mode == 1, onTap: () => _setMode(1)),
              SoriChip(label: '음절', accent: SoriColors.hangul, selected: _mode == 2, onTap: () => _setMode(2)),
            ],
          ),
          const SizedBox(height: 12),
          // Counter
          Text('${_idx + 1} / ${_pool.length}', style: const TextStyle(color: SoriColors.darkTextMuted, fontSize: 13)),
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
                  borderColor: SoriColors.hangul,
                  child: Text(c.letter, style: const TextStyle(fontSize: 110, fontWeight: FontWeight.w800, color: Color(0xFFFCC2D7))),
                ),
                back: _HangulCardFace(
                  gradient: const [Color(0xFF0F2942), Color(0xFF162E4D)],
                  borderColor: SoriColors.info,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(c.letter, style: const TextStyle(fontSize: 60, fontWeight: FontWeight.w800, color: Color(0xFFA5D8FF))),
                      const SizedBox(height: 8),
                      Text('[${c.romanization}]', style: const TextStyle(fontSize: 20, color: Color(0xFF74C0FC), fontStyle: FontStyle.italic, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 12),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Text(c.descriptionDe, textAlign: TextAlign.center, style: const TextStyle(fontSize: 13, color: SoriColors.darkText, height: 1.5)),
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
              Expanded(child: SoriButton.outlined(label: AppL10n.of(context).btnPrev, icon: Icons.arrow_back, onTap: _prev, fullWidth: true)),
              const SizedBox(width: 8),
              Expanded(child: SoriButton.outlined(label: AppL10n.of(context).btnHoeren, icon: Icons.volume_up, onTap: () => TtsService.speak(c.letter), fullWidth: true)),
              const SizedBox(width: 8),
              Expanded(child: SoriButton.outlined(label: AppL10n.of(context).btnNext, icon: Icons.arrow_forward, onTap: _next, fullWidth: true)),
            ],
          ),
          const SizedBox(height: 6),
          SoriButton.filled(
            label: AppL10n.of(context).btnRandom,
            icon: Icons.shuffle,
            accent: SoriColors.hangul,
            onTap: _random,
            fullWidth: true,
          ),
        ],
      ),
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
    return SoriCard(
      variant: SoriCardVariant.hero,
      accent: borderColor,
      tinted: true,
      width: double.infinity,
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
    final t = AppL10n.of(context);
    final c = _current;
    final strokes = hangulStrokes[c.letter] ?? [];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(14),
      child: Column(
        children: [
          // 3 Regeln
          SoriCard(
            variant: SoriCardVariant.compact,
            accent: SoriColors.warning,
            tinted: true,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(t.hangulRulesTitle, style: const TextStyle(fontWeight: FontWeight.w800, color: SoriColors.warning, fontSize: 13)),
                const SizedBox(height: 6),
                Text(t.hangulRulesBody,
                  style: const TextStyle(color: SoriColors.darkTextMuted, fontSize: 11.5, height: 1.5)),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Mode
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SoriChip(label: '자음', accent: SoriColors.hangul, selected: _mode == 0, onTap: () => _setMode(0)),
              const SizedBox(width: 8),
              SoriChip(label: '모음', accent: SoriColors.hangul, selected: _mode == 1, onTap: () => _setMode(1)),
            ],
          ),
          const SizedBox(height: 14),

          // Demo
          Column(
            children: [
              Text(t.hangulStrokeOrderTitle, style: const TextStyle(fontSize: 12, color: SoriColors.darkTextMuted)),
              const SizedBox(height: 6),
              SoriCard(
                variant: SoriCardVariant.base,
                accent: SoriColors.info,
                padding: const EdgeInsets.all(6),
                child: StrokeCanvas(
                  letter: c.letter,
                  strokes: strokes,
                  size: 220,
                  color: SoriColors.hangul,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Practice
          Column(
            children: [
              Text(t.hangulTraceTitle, style: const TextStyle(fontSize: 12, color: SoriColors.success)),
              const SizedBox(height: 6),
              _PracticeCanvas(key: _practiceKey, ghost: c.letter, color: SoriColors.success),
            ],
          ),
          const SizedBox(height: 10),
          SoriButton.outlined(
            label: t.hangulClearBtn,
            icon: Icons.delete_outline,
            onTap: () => _practiceKey.currentState?.clear(),
            destructive: true,
            fullWidth: true,
          ),
          const SizedBox(height: 12),

          // Nav
          Row(
            children: [
              Expanded(child: SoriButton.outlined(label: t.btnPrev, icon: Icons.arrow_back, onTap: _prev, fullWidth: true)),
              const SizedBox(width: 8),
              SoriCard(
                variant: SoriCardVariant.compact,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                child: Builder(builder: (ctx) {
                  final s = SoriSurfaces.of(ctx);
                  return Text('${_idx + 1} / ${_pool.length}', style: TextStyle(fontWeight: FontWeight.w800, color: s.text));
                }),
              ),
              const SizedBox(width: 8),
              Expanded(child: SoriButton.outlined(label: t.btnNext, icon: Icons.arrow_forward, onTap: _next, fullWidth: true)),
            ],
          ),
          const SizedBox(height: 14),
          SoriButton.outlined(
            label: t.hangulPronounceLetter(c.letter),
            icon: Icons.volume_up,
            onTap: () => TtsService.speak(c.letter),
            fullWidth: true,
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
    return SoriCard(
      variant: SoriCardVariant.base,
      accent: SoriColors.success,
      width: 220,
      height: 220,
      padding: EdgeInsets.zero,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(SoriRadius.md),
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
