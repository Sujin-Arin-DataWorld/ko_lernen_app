import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/feedback_completion.dart';
import '../widgets/sori/tokens.dart';
import '../widgets/sori/card.dart';
import '../widgets/sori/chip.dart';
import '../widgets/sori/button.dart';
import '../widgets/sori/content_feedback_card.dart';
import '../widgets/sori/hanok_header.dart';
import '../widgets/sori/responsive.dart';
import '../widgets/sori/screen_coach.dart';
import '../widgets/sori/spotlight_coach.dart';
import '../widgets/sori/sheet.dart';
import '../data/hangul_data.dart';
import '../data/hangul_strokes.dart';
import '../widgets/flip_card.dart';
import '../widgets/stroke_canvas.dart';
import '../services/tts_service.dart';
import '../l10n/generated/app_localizations.dart';

class HangulScreen extends StatefulWidget {
  const HangulScreen({super.key, this.cardsRandom});
  final math.Random? cardsRandom;

  @override
  State<HangulScreen> createState() => _HangulScreenState();
}

class _HangulScreenState extends State<HangulScreen>
    with SingleTickerProviderStateMixin, ScreenCoachMixin<HangulScreen> {
  late final TabController _tabs;
  int _tabIndex = 0;
  final FeedbackCompletionSlot _cardsCompletion = FeedbackCompletionSlot();
  final FeedbackCompletionSlot _writingCompletion = FeedbackCompletionSlot();

  // ── 코치마크 타겟 ──
  final GlobalKey _tabBarKey = GlobalKey();

  @override
  String get coachId => 'hangul';

  @override
  List<SpotlightStep> buildCoachSteps(BuildContext context) {
    final t = AppL10n.of(context);
    return [
      SpotlightStep(
        targetKey: _tabBarKey,
        title: t.coachHangulTitle,
        body: t.coachHangulBody,
        icon: Icons.tab_rounded,
      ),
    ];
  }

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
    _tabs.addListener(() {
      if (_tabs.index != _tabIndex) setState(() => _tabIndex = _tabs.index);
    });
    scheduleCoach();
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  Future<void> _finishCards(int interactionCount) async {
    final t = AppL10n.of(context);
    final completion = _cardsCompletion.complete(
      () => FeedbackCompletion.hangulCards(
        contentLabel: t.hangulTabCards,
        interactionCount: interactionCount,
      ),
    );
    await _showCompletion(completion, t.testerFeedbackCompleteHangul);
    _cardsCompletion.reset();
  }

  Future<void> _finishWriting(int strokeCount) async {
    final t = AppL10n.of(context);
    final completion = _writingCompletion.complete(
      () => FeedbackCompletion.hangulWriting(
        contentLabel: t.hangulTabWrite,
        strokeCount: strokeCount,
      ),
    );
    await _showCompletion(completion, t.testerFeedbackCompleteHangul);
    _writingCompletion.reset();
  }

  Future<void> _showCompletion(
    FeedbackCompletion completion,
    String title,
  ) async {
    await showSoriSheet<void>(
      context: context,
      builder: (sheetContext) {
        final t = AppL10n.of(sheetContext);
        final feedbackScope = ContentFeedbackControllerScope.maybeOf(
          sheetContext,
        );
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              style: SoriTextTheme.of(sheetContext).h2,
              textAlign: TextAlign.center,
            ),
            if (feedbackScope != null &&
                feedbackScope.featureGate.isEnabled) ...[
              const SizedBox(height: Spacing.lg),
              ContentFeedbackCard(
                feedbackContext: completion.context,
                featureGate: feedbackScope.featureGate,
                submitFeedback: feedbackScope.submitFeedback,
                completedMissionIds: feedbackScope.completedMissionIds,
              ),
            ],
            const SizedBox(height: Spacing.lg),
            SoriButton.filled(
              label: t.btnClose,
              fullWidth: true,
              onTap: () => Navigator.pop(sheetContext),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(
          t.screenHangulTitle,
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        bottom: TabBar(
          key: _tabBarKey,
          controller: _tabs,
          indicatorColor: SoriColors.hangul,
          labelColor: SoriColors.hangul,
          unselectedLabelColor: SoriColors.darkTextMuted,
          tabs: [
            Tab(
              icon: const Icon(Icons.grid_view_rounded),
              text: t.hangulTabOverview,
            ),
            Tab(icon: const Icon(Icons.style_outlined), text: t.hangulTabCards),
            Tab(icon: const Icon(Icons.gesture), text: t.hangulTabWrite),
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
          children: [
            const _OverviewTab(),
            _CardsTab(
              onFinish: _finishCards,
              random: widget.cardsRandom ?? math.Random(),
            ),
            _WriteTab(onFinish: _finishWriting),
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
      padding: soriClampPadding(
        MediaQuery.sizeOf(context).width,
        base: const EdgeInsets.fromLTRB(12, 12, 12, 24),
      ),
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
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: SoriColors.darkTextMuted,
          letterSpacing: 0.5,
        ),
      ),
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
        return _CharCell(
          char: c,
          color: color,
          onTap: () => _showDetail(ctx, c, color),
        );
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
  const _CharCell({
    required this.char,
    required this.color,
    required this.onTap,
  });

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
              Text(
                char.letter,
                style: TextStyle(
                  fontSize: 92,
                  fontWeight: FontWeight.w800,
                  color: color,
                  height: 1,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '[${char.romanization}]',
                style: TextStyle(
                  fontSize: 18,
                  color: color.withValues(alpha: 0.85),
                  fontStyle: FontStyle.italic,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                char.descriptionDe,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  color: SoriColors.darkText,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                style: FilledButton.styleFrom(backgroundColor: color),
                onPressed: () => TtsService.speak(speakableJamo(char.letter)),
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
      children: examples
          .map(
            (e) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: SoriCard(
                variant: SoriCardVariant.base,
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                child: Row(
                  children: [
                    Text(
                      e.$1,
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w800,
                        color: SoriColors.info,
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Text(
                      '=',
                      style: TextStyle(color: SoriColors.darkTextMuted),
                    ),
                    const SizedBox(width: 6),
                    for (var i = 0; i < e.$2.length; i++) ...[
                      Text(
                        e.$2[i],
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (i < e.$2.length - 1)
                        const Text(
                          ' + ',
                          style: TextStyle(color: SoriColors.darkTextDim),
                        ),
                    ],
                    const Spacer(),
                    Text(
                      e.$3,
                      style: const TextStyle(
                        color: SoriColors.primary,
                        fontWeight: FontWeight.w700,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          )
          .toList(),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Tab 2 — Karten (Flip + Aussprache)
// ═══════════════════════════════════════════════════════════════════════════

class _CardsTab extends StatefulWidget {
  const _CardsTab({required this.onFinish, required this.random});
  final Future<void> Function(int interactionCount) onFinish;
  final math.Random random;
  @override
  State<_CardsTab> createState() => _CardsTabState();
}

class _CardsTabState extends State<_CardsTab> {
  int _mode = 0; // 0=consonants, 1=vowels, 2=syllables
  int _idx = 0;
  bool _flipped = false;
  int _sessionInteractions = 0;

  List<HangulChar> get _pool {
    switch (_mode) {
      case 1:
        return vowels;
      case 2:
        return syllables
            .map(
              (s) => HangulChar(
                s.letter,
                s.romanization,
                s.composition,
                s.composition,
                s.exampleWord,
                s.exampleDe,
                s.exampleEn,
              ),
            )
            .toList();
      default:
        return consonants;
    }
  }

  void _next() {
    HapticFeedback.selectionClick();
    setState(() {
      _sessionInteractions++;
      _flipped = false;
      _idx = (_idx + 1) % _pool.length;
    });
  }

  void _prev() {
    HapticFeedback.selectionClick();
    setState(() {
      _sessionInteractions++;
      _flipped = false;
      _idx = (_idx - 1 + _pool.length) % _pool.length;
    });
  }

  void _random() {
    final candidate = widget.random.nextInt(_pool.length);
    if (candidate == _idx) return;
    HapticFeedback.lightImpact();
    setState(() {
      _sessionInteractions++;
      _flipped = false;
      _idx = candidate;
    });
  }

  void _onFlip() {
    HapticFeedback.selectionClick();
    setState(() {
      _sessionInteractions++;
      _flipped = !_flipped;
    });
  }

  void _setMode(int m) {
    if (_mode == m) return;
    HapticFeedback.selectionClick();
    setState(() {
      _sessionInteractions++;
      _mode = m;
      _idx = 0;
      _flipped = false;
    });
  }

  Future<void> _finish() async {
    if (_sessionInteractions == 0) return;
    await widget.onFinish(_sessionInteractions);
    if (!mounted) return;
    setState(() => _sessionInteractions = 0);
  }

  // 카드 앞면 — 글자 하나가 카드를 채우는 대형 헤드라인. 짧은 단일 글자(음절은
  // 최대 두 글자)라 FittedBox(scaleDown) 으로 폭 넘침만 방지하고, 크기는 카드
  // 높이 [h] 에 비례시켜 기기 무관 충전율을 맞춘다.
  List<Widget> _frontFace(HangulChar c, double h) => [
    FittedBox(
      fit: BoxFit.scaleDown,
      child: Text(
        c.letter,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: soriFillSize(h, 0.40, 110, 200),
          fontWeight: FontWeight.w800,
          color: SoriColors.hangul,
        ),
      ),
    ),
  ];

  // 카드 뒷면 — 글자(헤드라인) + [로마자·설명] 묶음 + 예문 박스. spaceEvenly 가
  // 흩뜨리지 않도록 로마자와 설명은 한 Column 으로 묶는다. 폰트/아이콘 크기는
  // 카드 높이 [h] 에 비례(soriFillSize), 최소값은 기존 고정값이라 폰 축소 없음.
  List<Widget> _backFace(HangulChar c, SoriSurfaces s, double h) => [
    FittedBox(
      fit: BoxFit.scaleDown,
      child: Text(
        c.letter,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: soriFillSize(h, 0.16, 60, 110),
          fontWeight: FontWeight.w800,
          color: SoriColors.primary,
        ),
      ),
    ),
    Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '[${c.romanization}]',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: soriFillSize(h, 0.05, 20, 30),
            color: SoriColors.info,
            fontStyle: FontStyle.italic,
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: soriFillSize(h, 0.02, 6, 14)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Text(
            c.descriptionDe,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: soriFillSize(h, 0.045, 13, 22),
              color: s.text,
              height: 1.5,
            ),
          ),
        ),
      ],
    ),
    if (c.exampleWord.isNotEmpty)
      GestureDetector(
        onTap: () => TtsService.speak(c.exampleWord),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
          decoration: BoxDecoration(
            color: SoriColors.hangul.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: SoriColors.hangul.withValues(alpha: 0.30),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    c.exampleWord,
                    style: TextStyle(
                      fontSize: soriFillSize(h, 0.075, 22, 40),
                      fontWeight: FontWeight.w800,
                      color: SoriColors.hangul,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Icon(
                    Icons.volume_up_rounded,
                    size: soriFillSize(h, 0.05, 16, 28),
                    color: SoriColors.hangul,
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                c.exampleDe,
                style: TextStyle(
                  fontSize: soriFillSize(h, 0.05, 13, 26),
                  color: s.text,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
  ];

  @override
  Widget build(BuildContext context) {
    final c = _pool[_idx % _pool.length];
    final s = SoriSurfaces.of(context);
    return SoriStudyClamp(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            // Mode chips
            Wrap(
              spacing: 8,
              children: [
                SoriChip(
                  label: '자음',
                  accent: SoriColors.hangul,
                  selected: _mode == 0,
                  onTap: () => _setMode(0),
                ),
                SoriChip(
                  label: '모음',
                  accent: SoriColors.hangul,
                  selected: _mode == 1,
                  onTap: () => _setMode(1),
                ),
                SoriChip(
                  label: '음절',
                  accent: SoriColors.hangul,
                  selected: _mode == 2,
                  onTap: () => _setMode(2),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Counter
            Text(
              '${_idx + 1} / ${_pool.length}',
              style: TextStyle(color: s.textMuted, fontSize: 13),
            ),
            const SizedBox(height: 8),

            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  // 카드가 놓이는 세로 영역의 높이 — 카드 안 학습 텍스트를 이 높이에
                  // 비례해 키워(soriFillSize) 기기와 무관하게 균일한 세로 충전율을
                  // 만든다. FlipCard 가 이미 SingleChildScrollView + minHeight 로
                  // 감싸므로 콘텐츠가 넘칠 땐 스크롤로 받아낸다(오버플로 0, 기존
                  // 계약 유지). 이 LayoutBuilder 는 Expanded(경계 있음) 안이라 h 는
                  // 유한하다 — 카드 안쪽은 스크롤 컨텍스트라 무한이 되므로 여기서
                  // 잡아 아래로 넘긴다.
                  final h = constraints.maxHeight.isFinite
                      ? constraints.maxHeight
                      : 360.0;
                  return GestureDetector(
                    onHorizontalDragEnd: (d) {
                      if (d.primaryVelocity == null) {
                        return;
                      }
                      if (d.primaryVelocity! < -250) {
                        _next();
                      } else if (d.primaryVelocity! > 250) {
                        _prev();
                      }
                    },
                    child: SoriStudyScale(
                      child: FlipCard(
                        flipped: _flipped,
                        onTap: _onFlip,
                        front: _HangulCardFace(
                          gradient: const [
                            SoriColors.accent,
                            SoriColors.darkAccent,
                          ],
                          borderColor: SoriColors.hangul,
                          children: _frontFace(c, h),
                        ),
                        back: _HangulCardFace(
                          gradient: const [
                            SoriColors.highlight,
                            SoriColors.darkPrimary,
                          ],
                          borderColor: SoriColors.info,
                          children: _backFace(c, s, h),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
            // 독일어 "Zurück"/"Weiter" 는 영어보다 20~30% 길어 3버튼 균등 1/3
            // 에선 잘린다("Zurü…"). 좁은 폰(360dp)에선 아이콘+독일어 라벨 3개가
            // 한 줄에 물리적으로 안 들어간다 → 라벨을 온전히 보이려면 3개를 한
            // 줄에 두지 않는다: nav(prev/next)는 반폭 2버튼(라벨 여유), 핵심
            // 액션인 듣기는 아래 full-width 로 승격(발음 카드는 소리가 우선).
            Row(
              children: [
                Expanded(
                  child: SoriButton.outlined(
                    label: AppL10n.of(context).btnPrev,
                    icon: Icons.arrow_back,
                    onTap: _prev,
                    fullWidth: true,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: SoriButton.outlined(
                    label: AppL10n.of(context).btnNext,
                    icon: Icons.arrow_forward,
                    onTap: _next,
                    fullWidth: true,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            SoriButton.outlined(
              label: AppL10n.of(context).btnHoeren,
              icon: Icons.volume_up,
              onTap: () => TtsService.speak(speakableJamo(c.letter)),
              fullWidth: true,
            ),
            const SizedBox(height: 6),
            SoriButton.filled(
              label: AppL10n.of(context).btnRandom,
              icon: Icons.shuffle,
              accent: SoriColors.hangul,
              onTap: _random,
              fullWidth: true,
            ),
            const SizedBox(height: 8),
            SoriButton.filled(
              key: const Key('hangul-cards-finish'),
              label: AppL10n.of(context).testerFeedbackCompleteHangul,
              accent: SoriColors.hangul,
              onTap: _sessionInteractions == 0 ? null : _finish,
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
  final List<Widget> children;
  const _HangulCardFace({
    required this.gradient,
    required this.borderColor,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return SoriCard(
      variant: SoriCardVariant.hero,
      accent: borderColor,
      tinted: true,
      width: double.infinity,
      // spaceEvenly 로 카드 높이를 채운다(가운데 정렬 유지). FlipCard._fitFace 가
      // 이미 SingleChildScrollView + ConstrainedBox(minHeight: 뷰포트높이) 로
      // 감싸므로, 이 Column 은 그 minHeight(카드 padding 만큼만 줄어든 값)를 받아
      // 여백을 균등 분배하고, 콘텐츠가 더 크면 그 스크롤뷰가 받아낸다(오버플로 0).
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: children,
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Tab 3 — Schreiben (Stroke Order Animation + Practice)
// ═══════════════════════════════════════════════════════════════════════════

class _WriteTab extends StatefulWidget {
  const _WriteTab({required this.onFinish});
  final Future<void> Function(int strokeCount) onFinish;
  @override
  State<_WriteTab> createState() => _WriteTabState();
}

class _WriteTabState extends State<_WriteTab> {
  int _mode = 0; // 0=cons, 1=vowels
  int _idx = 0;
  int _strokeCount = 0;
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
    setState(() {
      _mode = m;
      _idx = 0;
    });
    _practiceKey.currentState?.clear();
  }

  void _onStrokeEnd() => setState(() => _strokeCount++);

  Future<void> _finish() async {
    if (_strokeCount == 0) return;
    await widget.onFinish(_strokeCount);
    if (!mounted) return;
    setState(() => _strokeCount = 0);
    _practiceKey.currentState?.clear();
  }

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);
    final c = _current;
    final strokes = hangulStrokes[c.letter] ?? [];

    return LayoutBuilder(
      builder: (context, viewport) => SingleChildScrollView(
        padding: soriClampPadding(
          MediaQuery.sizeOf(context).width,
          base: const EdgeInsets.all(14),
        ),
        // 태블릿 등 세로 여백이 남으면 내용을 세로 중앙 정렬(위 쏠림 해소).
        // 콘텐츠가 뷰포트보다 길면 스크롤(폰·큰 글자 안전).
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: viewport.maxHeight),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // 3 Regeln
              SoriCard(
                variant: SoriCardVariant.compact,
                accent: SoriColors.warning,
                tinted: true,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      t.hangulRulesTitle,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        color: SoriColors.warning,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      t.hangulRulesBody,
                      style: const TextStyle(
                        color: SoriColors.darkTextMuted,
                        fontSize: 11.5,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Mode
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SoriChip(
                    label: '자음',
                    accent: SoriColors.hangul,
                    selected: _mode == 0,
                    onTap: () => _setMode(0),
                  ),
                  const SizedBox(width: 8),
                  SoriChip(
                    label: '모음',
                    accent: SoriColors.hangul,
                    selected: _mode == 1,
                    onTap: () => _setMode(1),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // ── Demo (시범 stroke order) + Practice (사용자 따라쓰기) Side-by-Side ──
              // 비교 학습 효과 ↑. AspectRatio 1:1로 폰 너비에 적응 (iPhone SE 320pt도 OK).
              LayoutBuilder(
                builder: (ctx, constraints) {
                  // 양쪽 canvas 사이 gap 10, 각 Expanded → AspectRatio 1
                  // 한쪽 canvas 실제 size: (width - 10) / 2 - inner SoriCard padding(~12)
                  final canvasSize = ((constraints.maxWidth - 10) / 2 - 12)
                      .clamp(120.0, 220.0);

                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── 좌: 시범 stroke animation ──
                      Expanded(
                        child: Column(
                          children: [
                            Text(
                              t.hangulStrokeOrderTitle,
                              style: const TextStyle(
                                fontSize: 11.5,
                                color: SoriColors.darkTextMuted,
                                fontWeight: FontWeight.w700,
                              ),
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              overflow: TextOverflow.visible,
                            ),
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
                            Text(
                              t.hangulTraceTitle,
                              style: const TextStyle(
                                fontSize: 11.5,
                                color: SoriColors.success,
                                fontWeight: FontWeight.w700,
                              ),
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              overflow: TextOverflow.visible,
                            ),
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
                                  onStrokeEnd: _onStrokeEnd,
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
                  Expanded(
                    child: SoriButton.outlined(
                      label: t.btnPrev,
                      icon: Icons.arrow_back,
                      onTap: _prev,
                      fullWidth: true,
                    ),
                  ),
                  const SizedBox(width: 8),
                  SoriCard(
                    variant: SoriCardVariant.compact,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    child: Builder(
                      builder: (ctx) {
                        final s = SoriSurfaces.of(ctx);
                        return Text(
                          '${_idx + 1} / ${_pool.length}',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            color: s.text,
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: SoriButton.outlined(
                      label: t.btnNext,
                      icon: Icons.arrow_forward,
                      onTap: _next,
                      fullWidth: true,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              SoriButton.outlined(
                label: t.hangulPronounceLetter(c.letter),
                icon: Icons.volume_up,
                onTap: () => TtsService.speak(speakableJamo(c.letter)),
                fullWidth: true,
              ),
              const SizedBox(height: 8),
              SoriButton.filled(
                key: const Key('hangul-writing-finish'),
                label: t.testerFeedbackCompleteHangul,
                accent: SoriColors.hangul,
                onTap: _strokeCount == 0 ? null : _finish,
                fullWidth: true,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Frei-Hand Canvas zum Nachzeichnen.
class _PracticeCanvas extends StatefulWidget {
  final String ghost;
  final Color color;
  final VoidCallback onStrokeEnd;
  const _PracticeCanvas({
    super.key,
    required this.ghost,
    required this.color,
    required this.onStrokeEnd,
  });

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
        key: const Key('hangul-practice-canvas'),
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
          if (_current == null) return;
          HapticFeedback.lightImpact();
          setState(() => _current = null);
          widget.onStrokeEnd();
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

  _PracticePainter({
    required this.ghost,
    required this.strokes,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Ghost Buchstabe als Hintergrund
    final tp = TextPainter(
      text: TextSpan(
        text: ghost,
        style: TextStyle(
          fontSize: size.height * 0.85,
          fontWeight: FontWeight.w900,
          color: color.withValues(alpha: 0.08),
          height: 1,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(
      canvas,
      Offset((size.width - tp.width) / 2, (size.height - tp.height) / 2 - 8),
    );

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
      (old.strokes.isNotEmpty &&
          old.strokes.last.length != strokes.last.length) ||
      old.ghost != ghost;
}
