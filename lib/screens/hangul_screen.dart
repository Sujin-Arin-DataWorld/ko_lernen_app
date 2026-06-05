import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../widgets/sori/tokens.dart';
import '../widgets/sori/card.dart';
import '../widgets/sori/chip.dart';
import '../widgets/sori/button.dart';
import '../widgets/sori/hanok_header.dart';
import '../widgets/sori/responsive.dart';
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
      body: SafeArea(
        child: TabBarView(
          controller: _tabs,
          // "그리기 박스에서만 스와이프 차단" — Schreiben 탭(index 2)에서만
          // 좌우 스와이프를 끈다. 손가락 그리기(pan)가 탭 넘김을 유발하지 않고,
          // Übersicht/Karten 탭은 정상 스와이프 유지. (탭 전환은 상단 탭 클릭)
          physics: _tabIndex == 2 ? const NeverScrollableScrollPhysics() : null,
          children: const [
            _OverviewTab(),
            _CardsTab(),
            _WriteTab(),
          ],
        ),
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
      padding: soriClampPadding(MediaQuery.sizeOf(context).width, base: const EdgeInsets.fromLTRB(12, 12, 12, 24)),
      children: [
        // 모듈 헤더 통일 (Phase 4) — HanokHeader 10:3 banner.
        const HanokHeader(
          asset: 'assets/illustrations/hanok/calligraphy.png',
          fallbackIcon: Icons.draw_outlined,
        ),
        const SizedBox(height: 16),
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
    // 5×N → 4×N: 셀이 커져 큰 한글(36) + romanization(12) 여유롭게 들어감.
    // 정사각형 셀(aspect 1.0) — 시각적 안정 + 안드로이드 그리드 표준.
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 1.0,
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
    // 바텀시트 대신 중앙 다이얼로그 — 화면 정중앙에 떠서 상단/하단 시스템바에
    // 구조적으로 안 걸림(기기 무관 동일). 내용은 스크롤 가능해 오버플로도 0.
    showDialog(
      context: ctx,
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
      padding: const EdgeInsets.all(4),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          // FittedBox로 셀 사이즈에 자동 적응 — 어떤 폰에서도 overflow 0
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              char.letter,
              style: TextStyle(
                fontFamily: 'Pretendard',
                fontSize: 36,
                fontWeight: FontWeight.w900,
                color: color,
                height: 1,
              ),
            ),
          ),
          const SizedBox(height: 3),
          Text(
            char.romanization,
            style: TextStyle(
              fontFamily: 'Pretendard',
              fontSize: 11,
              color: color.withValues(alpha: 0.75),
              fontStyle: FontStyle.italic,
              fontWeight: FontWeight.w600,
              height: 1,
            ),
          ),
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
    // 중앙 다이얼로그: 화면 정중앙 → 시스템바에 안 걸림(기기 무관 동일).
    // SingleChildScrollView → 설명이 길거나 글자배율이 커도 스크롤(오버플로 0).
    // insetPadding responsive — 좁은 폰(width < 360) 대비.
    final screenWidth = MediaQuery.sizeOf(context).width;
    return Dialog(
      backgroundColor: SoriColors.darkSurface,
      insetPadding: EdgeInsets.symmetric(
        horizontal: screenWidth < 360 ? 16 : 32,
        vertical: 24,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
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
        ),
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
      case 2: return syllables.map((s) => HangulChar(s.letter, s.romanization, s.composition, s.composition, s.exampleWord, s.exampleDe, s.exampleEn)).toList();
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
    final s = SoriSurfaces.of(context);
    return SoriCenterClamp(
      child: Padding(
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
          Text('${_idx + 1} / ${_pool.length}', style: TextStyle(color: s.textMuted, fontSize: 13)),
          const SizedBox(height: 8),

          Expanded(
            child: GestureDetector(
              onHorizontalDragEnd: (d) {
                if (d.primaryVelocity == null) return;
                if (d.primaryVelocity! < -250) {
                  _next();
                } else if (d.primaryVelocity! > 250) {
                  _prev();
                }
              },
              child: FlipCard(
                flipped: _flipped,
                onTap: _onFlip,
                front: _HangulCardFace(
                  gradient: const [SoriColors.accent, SoriColors.darkAccent],
                  borderColor: SoriColors.hangul,
                  child: Text(c.letter, style: const TextStyle(fontSize: 110, fontWeight: FontWeight.w800, color: SoriColors.hangul)),
                ),
                back: _HangulCardFace(
                  gradient: const [SoriColors.highlight, SoriColors.darkPrimary],
                  borderColor: SoriColors.info,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(c.letter, style: const TextStyle(fontSize: 60, fontWeight: FontWeight.w800, color: SoriColors.primary)),
                      const SizedBox(height: 8),
                      Text('[${c.romanization}]', style: const TextStyle(fontSize: 20, color: SoriColors.info, fontStyle: FontStyle.italic, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 12),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Text(c.descriptionDe, textAlign: TextAlign.center, style: TextStyle(fontSize: 13, color: s.text, height: 1.5)),
                      ),
                      if (c.exampleWord.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        GestureDetector(
                          onTap: () => TtsService.speak(c.exampleWord),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                            decoration: BoxDecoration(
                              color: SoriColors.hangul.withValues(alpha: 0.10),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: SoriColors.hangul.withValues(alpha: 0.30)),
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(c.exampleWord, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: SoriColors.hangul)),
                                    const SizedBox(width: 6),
                                    const Icon(Icons.volume_up_rounded, size: 16, color: SoriColors.hangul),
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Text(c.exampleDe, style: TextStyle(fontSize: 13, color: s.text, fontWeight: FontWeight.w600)),
                              ],
                            ),
                          ),
                        ),
                      ],
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
      padding: soriClampPadding(MediaQuery.sizeOf(context).width, base: const EdgeInsets.all(14)),
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

          // ── Demo (시범 stroke order) + Practice (사용자 따라쓰기) Side-by-Side ──
          // 비교 학습 효과 ↑. AspectRatio 1:1로 폰 너비에 적응 (iPhone SE 320pt도 OK).
          LayoutBuilder(
            builder: (ctx, constraints) {
              // 양쪽 canvas 사이 gap 10, 각 Expanded → AspectRatio 1
              // 한쪽 canvas 실제 size: (width - 10) / 2 - inner SoriCard padding(~12)
              final canvasSize = ((constraints.maxWidth - 10) / 2 - 12).clamp(120.0, 220.0);

              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── 좌: 시범 stroke animation ──
                  Expanded(
                    child: Column(
                      children: [
                        Text(t.hangulStrokeOrderTitle,
                            style: const TextStyle(fontSize: 11.5, color: SoriColors.darkTextMuted, fontWeight: FontWeight.w700),
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.visible),
                        const SizedBox(height: 6),
                        SoriCard(
                          variant: SoriCardVariant.base,
                          accent: SoriColors.info,
                          padding: const EdgeInsets.all(6),
                          child: AspectRatio(
                            aspectRatio: 1,
                            child: StrokeCanvas(
                              letter: c.letter,
                              strokes: strokes,
                              size: canvasSize,
                              color: SoriColors.hangul,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  // ── 우: Practice canvas (사용자 손가락) ──
                  Expanded(
                    child: Column(
                      children: [
                        Text(t.hangulTraceTitle,
                            style: const TextStyle(fontSize: 11.5, color: SoriColors.success, fontWeight: FontWeight.w700),
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.visible),
                        const SizedBox(height: 6),
                        SoriCard(
                          variant: SoriCardVariant.base,
                          accent: SoriColors.success,
                          padding: const EdgeInsets.all(6),
                          child: AspectRatio(
                            aspectRatio: 1,
                            child: _PracticeCanvas(
                              key: _practiceKey,
                              ghost: c.letter,
                              color: SoriColors.success,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
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
  /// 명시적 size. null → 부모 (Expanded/AspectRatio) 가 결정.
  final double? size;
  // ignore: unused_element_parameter
  const _PracticeCanvas({super.key, required this.ghost, required this.color, this.size});

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
    return ClipRRect(
      borderRadius: BorderRadius.circular(SoriRadius.md),
      child: GestureDetector(
        // Pan gesture for drawing strokes (handles all drags: horizontal, vertical, diagonal)
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
