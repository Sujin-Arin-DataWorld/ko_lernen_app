import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';

import '../models/feedback_completion.dart';
import '../widgets/sori/tokens.dart';
import '../widgets/sori/card.dart';
import '../widgets/sori/chip.dart';
import '../widgets/sori/button.dart';
import '../widgets/sori/content_feedback_card.dart';
import '../widgets/sori/content_feed.dart';
import '../services/content_share_service.dart';
import '../widgets/sori/toast.dart';
import '../services/liked_content_service.dart';
import '../widgets/sori/hanok_header.dart';
import '../widgets/sori/responsive.dart';
import '../widgets/sori/screen_coach.dart';
import '../widgets/sori/spotlight_coach.dart';
import '../widgets/sori/sheet.dart';
import '../widgets/sori/tts_speed_control.dart';
import '../data/hangul_data.dart';
import '../data/hangul_strokes.dart';
import '../services/sound_service.dart';
import '../services/storage_service.dart';
import '../services/stroke_matcher.dart';
import '../widgets/flip_card.dart';
import '../widgets/stroke_canvas.dart';
import '../services/analytics_service.dart';
import '../services/quest_abandon_tracker.dart';
import '../services/tts_service.dart';
import '../l10n/generated/app_localizations.dart';

class HangulScreen extends StatefulWidget {
  const HangulScreen({
    super.key,
    this.cardsRandom,
    this.speechPlayer,
    this.textPrefetcher,
  });
  final math.Random? cardsRandom;
  final Future<bool> Function(String text)? speechPlayer;

  /// 음성 미리받기 주입구(테스트용). 미지정이면 [TtsService.prefetch].
  final Future<void> Function(String text)? textPrefetcher;

  @override
  State<HangulScreen> createState() => _HangulScreenState();
}

class _HangulScreenState extends State<HangulScreen>
    with SingleTickerProviderStateMixin, ScreenCoachMixin<HangulScreen> {
  late final TabController _tabs;
  int _tabIndex = 0;
  final FeedbackCompletionSlot _cardsCompletion = FeedbackCompletionSlot();
  final FeedbackCompletionSlot _writingCompletion = FeedbackCompletionSlot();
  late final QuestAbandonTracker _abandonTracker;

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
    Analytics.lessonStarted(lessonType: 'hangul');
    _abandonTracker = QuestAbandonTracker(
      questType: 'hangul',
      lastStepReached: () => switch (_tabIndex) {
        0 => 'overview',
        1 => 'cards',
        2 => 'write',
        _ => 'unknown',
      },
    );
    _warmJamoAudio();
  }

  @override
  void dispose() {
    _abandonTracker.dispose();
    _tabs.dispose();
    super.dispose();
  }

  /// 프리페치는 **어떤 경우에도 화면을 깨뜨리지 않는다**.
  ///
  /// 구현이 삼키는 것과 별개로 호출 지점에서도 막는다 — 주입된 구현이
  /// 던지면 `unawaited` 된 Future 가 미처리 예외로 새어나온다.
  Future<void> _prefetch(String text) async {
    try {
      await (widget.textPrefetcher?.call(text) ?? TtsService.prefetch(text));
    } catch (_) {
      // 못 받아도 누르면 평소 경로로 재생된다.
    }
  }

  /// 화면에 들어온 순간 낱자 34개 음성을 미리 받아둔다.
  ///
  /// 2026-08-17 테스터(Amor): "카드 음성이 너무 늦게 나온다." 첫 재생은
  /// Storage 다운로드를 기다린 뒤에야 소리가 났다. 고정된 34개짜리 작은
  /// 집합이라 미리 받아두면 이후 탭은 전부 로컬 디스크에서 즉시 난다.
  /// 실패는 무시한다 — 못 받아도 누르면 평소 경로로 재생된다.
  void _warmJamoAudio() {
    final texts = [
      for (final c in [...consonants, ...vowels]) speakableJamo(c.letter),
    ];
    if (widget.textPrefetcher != null) {
      unawaited(Future.wait([for (final t in texts) _prefetch(t)]));
      return;
    }
    unawaited(TtsService.prefetchAll(texts));
  }

  Future<void> _finishCards(int interactionCount) async {
    final t = AppL10n.of(context);
    Analytics.lessonCompleted(lessonType: 'hangul', lessonId: 'cards');
    _abandonTracker.markCompleted();
    final completion = _cardsCompletion.complete(
      () => FeedbackCompletion.hangulCards(
        contentLabel: t.hangulTabCards,
        interactionCount: interactionCount,
      ),
    );
    await _showCompletion(completion, t.testerFeedbackCompleteHangul);
    _cardsCompletion.reset();
  }

  Future<void> _finishWriting(HangulWritingResult result) async {
    final t = AppL10n.of(context);
    Analytics.lessonCompleted(lessonType: 'hangul', lessonId: 'writing');
    _abandonTracker.markCompleted();
    final completion = _writingCompletion.complete(
      () => FeedbackCompletion.hangulWriting(
        contentLabel: t.hangulTabWrite,
        letterCount: result.letters,
        strokeCount: result.strokes,
        strict: result.strict,
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

  Future<bool> _speakJamo(String letter) {
    final text = speakableJamo(letter);
    return widget.speechPlayer?.call(text) ?? TtsService.speak(text);
  }

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(
          t.screenHangulTitle,
          style: SoriTextTheme.of(context).h2,
        ),
        actions: const [TtsSpeedAction()],
        bottom: TabBar(
          key: _tabBarKey,
          controller: _tabs,
          indicatorColor: SoriColors.primary,
          labelColor: SoriColors.primary,
          unselectedLabelColor: SoriSurfaces.of(context).textMuted,
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
          // 탭 넘김 스와이프는 **개요 탭에서만** 켠다.
          //
          // 카드 탭과 쓰기 탭은 둘 다 가로 드래그를 스스로 쓴다 — 카드는
          // 카드 탭은 세로 피드(이전/다음 글자), 쓰기는 손가락 그리기와 좌우 이동.
          // TabBarView 의 가로 드래그 인식기는 제스처 아레나에서 카드의
          // Pan 인식기를 이겨버리기 때문에, 켜두면 카드를 미는 대신 탭이
          // 넘어간다(2026-08-18 실측). 탭 전환은 상단 TabBar 로 한다.
          physics: _tabIndex == 0 ? null : const NeverScrollableScrollPhysics(),
          children: [
            _OverviewTab(speak: _speakJamo),
            _CardsTab(
              onFinish: _finishCards,
              random: widget.cardsRandom ?? math.Random(),
              speak: _speakJamo,
              prefetch: _prefetch,
            ),
            _WriteTab(onFinish: _finishWriting, speak: _speakJamo),
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
  const _OverviewTab({required this.speak});
  final Future<bool> Function(String letter) speak;

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
        _CharGrid(chars: consonants, color: SoriColors.primary, speak: speak),
        const SizedBox(height: 24),
        _SectionLabel('${t.hangulVowelsLabel} (${vowels.length})'),
        _CharGrid(chars: vowels, color: SoriColors.info, speak: speak),
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
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: SoriSurfaces.of(context).textMuted,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

class _CharGrid extends StatelessWidget {
  final List<HangulChar> chars;
  final Color color;
  final Future<bool> Function(String letter) speak;
  const _CharGrid({
    required this.chars,
    required this.color,
    required this.speak,
  });

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
          key: ValueKey('hangul-overview-${c.letter}'),
          char: c,
          color: color,
          onTap: () => _showDetail(ctx, c, color),
        );
      },
    );
  }

  void _showDetail(BuildContext ctx, HangulChar c, Color color) {
    HapticFeedback.selectionClick();
    // 낱자를 누르는 행위 자체가 발음 학습이다. 상세 창 안의 스피커를 다시
    // 눌러야만 들리는 구조로 만들지 않는다.
    unawaited(speak(c.letter));
    // 바텀시트 대신 중앙 다이얼로그 — 화면 정중앙에 떠서 상단/하단 시스템바에
    // 구조적으로 안 걸림(기기 무관 동일). 내용은 스크롤 가능해 오버플로도 0.
    showDialog(
      context: ctx,
      builder: (_) => _DetailSheet(char: c, color: color, speak: speak),
    );
  }
}

class _CharCell extends StatelessWidget {
  final HangulChar char;
  final Color color;
  final VoidCallback onTap;
  const _CharCell({
    super.key,
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
                fontFamily: SoriFonts.sans,
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
              fontFamily: SoriFonts.sans,
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
  final Future<bool> Function(String letter) speak;
  const _DetailSheet({
    required this.char,
    required this.color,
    required this.speak,
  });

  @override
  Widget build(BuildContext context) {
    // 중앙 다이얼로그: 화면 정중앙 → 시스템바에 안 걸림(기기 무관 동일).
    // SingleChildScrollView → 설명이 길거나 글자배율이 커도 스크롤(오버플로 0).
    // insetPadding responsive — 좁은 폰(width < 360) 대비.
    final screenWidth = MediaQuery.sizeOf(context).width;
    return Dialog(
      backgroundColor: SoriSurfaces.of(context).surface,
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
                // 2026-08-17 테스터(Amor): EN UI 인데 연상 힌트가 독일어였다.
                // descriptionEn 은 처음부터 채워져 있었고 읽히지만 않았다.
                char.descriptionFor(
                  Localizations.localeOf(context).languageCode,
                ),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: SoriSurfaces.of(context).text,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                style: FilledButton.styleFrom(backgroundColor: color),
                onPressed: () => unawaited(speak(char.letter)),
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
                    Text(
                      '=',
                      style: TextStyle(
                        color: SoriSurfaces.of(context).textMuted,
                      ),
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
                        Text(
                          ' + ',
                          style: TextStyle(
                            color: SoriSurfaces.of(context).textDim,
                          ),
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
  const _CardsTab({
    required this.onFinish,
    required this.random,
    required this.speak,
    required this.prefetch,
  });
  final Future<void> Function(int interactionCount) onFinish;
  final math.Random random;
  final Future<bool> Function(String letter) speak;
  final Future<void> Function(String text) prefetch;
  @override
  State<_CardsTab> createState() => _CardsTabState();
}

class _CardsTabState extends State<_CardsTab> {
  int _mode = 0; // 0=consonants, 1=vowels, 2=syllables
  int _idx = 0;
  bool _flipped = false;
  int _sessionInteractions = 0;

  /// 플립 전 판정 시도 → 힌트 칩 펄스 (deck_coach.dart 계약).
  final ValueNotifier<int> _flipHint = ValueNotifier<int>(0);

  /// "다시 볼 글자만" 필터. 좌(모름) 판정이 모은 `Storage.hangulHard` 를
  /// **읽는 유일한 경로**다 — 이게 없으면 좌/우 판정이 write-only 라 아무
  /// 효과가 없다(grammar 의 Schwer 필터와 같은 모양, `grammar_screen.dart:215`).
  bool _hardOnly = false;

  @override
  void initState() {
    super.initState();
    _prefetchAround();
  }

  @override
  void dispose() {
    _flipHint.dispose();
    super.dispose();
  }

  /// 지금 카드와 좌우 이웃의 음성을 미리 받아둔다. 스와이프가 빨라질수록
  /// 다음 카드에 도착하는 시점이 앞당겨지므로 이게 더 중요해진다.
  void _prefetchAround() {
    final pool = _pool;
    if (pool.isEmpty) {
      return;
    }
    for (final offset in const [0, 1, -1]) {
      final c = pool[(_idx + offset + pool.length) % pool.length];
      unawaited(widget.prefetch(speakableJamo(c.letter)));
      if (c.exampleWord.isNotEmpty) {
        unawaited(widget.prefetch(c.exampleWord));
      }
    }
  }

  List<HangulChar> get _basePool {
    switch (_mode) {
      case 1:
        return vowels;
      case 2:
        return [for (final s in syllables) s.toHangulChar()];
      default:
        return consonants;
    }
  }

  List<HangulChar> get _pool {
    final base = _basePool;
    if (!_hardOnly) {
      return base;
    }
    final hard = Storage.hangulHard.toSet();
    final filtered = base.where((c) => hard.contains(c.letter)).toList();
    // 마지막 어려운 글자를 "앎"으로 지우면 덱이 비어 `_pool[_idx % 0]` 이
    // 터진다. 빈 결과는 필터를 없는 셈 치고 전체를 돌려준다 — 다음 build 에서
    // 칩도 자동으로 꺼진 것처럼 보인다.
    return filtered.isEmpty ? base : filtered;
  }

  void _toggleHardOnly() {
    HapticFeedback.selectionClick();
    setState(() {
      _hardOnly = !_hardOnly;
      _idx = 0;
      _flipped = false;
    });
    _prefetchAround();
  }

  /// 우 = 앎. 앱 공용 계약(좌=모름 · 우=앎 · 위=저장 · 아래=넘어가기)의 판정.
  ///
  /// 자모는 어휘가 아니라 **SRS 를 건드리지 않는다** — 문법의 `grammarHard` 와
  /// 같은 SRS 밖 집합(`Storage.hangulHard`)만 쓴다.
  void _known() {
    final letter = _pool[_idx % _pool.length].letter;
    unawaited(Storage.markHangulEasy(letter));
    _advance();
  }

  /// 좌 = 모름. 다시 볼 낱자로 표시하고 넘어간다.
  void _dontKnow() {
    final letter = _pool[_idx % _pool.length].letter;
    unawaited(Storage.markHangulHard(letter));
    _advance();
  }

  /// 판정 후 전진 — 햅틱은 커밋 순간 `SoriSwipeCard` 가 방향별로 이미 쳤다.
  void _advance() {
    setState(() {
      _sessionInteractions++;
      _flipped = false;
      _idx = (_idx + 1) % _pool.length;
    });
    _prefetchAround();
  }

  void _next() {
    HapticFeedback.selectionClick();
    setState(() {
      _sessionInteractions++;
      _flipped = false;
      _idx = (_idx + 1) % _pool.length;
    });
    _prefetchAround();
  }

  void _prev() {
    HapticFeedback.selectionClick();
    setState(() {
      _sessionInteractions++;
      _flipped = false;
      _idx = (_idx - 1 + _pool.length) % _pool.length;
    });
    _prefetchAround();
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
    _prefetchAround();
  }

  void _onFlip() {
    HapticFeedback.selectionClick();
    setState(() {
      _sessionInteractions++;
      _flipped = !_flipped;
    });
  }

  Future<void> _likeCurrent() async {
    final letter = _pool[_idx % _pool.length].letter;
    await LikedContentService.toggle(
      kind: LikedContentService.hangul,
      id: letter,
    );
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _shareCurrent() async {
    final c = _pool[_idx % _pool.length];
    final t = AppL10n.of(context);
    final outcome = await ContentShareService.shareStory(
      korean: c.letter,
      gloss: c.romanization,
    );
    if (outcome == ShareOutcome.failed && mounted) {
      soriToast(context, t.shareError);
    }
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
    _prefetchAround();
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
          color: SoriColors.primary,
        ),
      ),
    ),
  ];

  // 카드 뒷면 — 글자(헤드라인) + [로마자·설명] 묶음 + 예문 박스. spaceEvenly 가
  // 흩뜨리지 않도록 로마자와 설명은 한 Column 으로 묶는다. 폰트/아이콘 크기는
  // 카드 높이 [h] 에 비례(soriFillSize), 최소값은 기존 고정값이라 폰 축소 없음.
  List<Widget> _backFace(
    BuildContext context,
    HangulChar c,
    SoriSurfaces s,
    double h,
  ) {
    final t = AppL10n.of(context);
    final lang = Localizations.localeOf(context).languageCode;
    return [
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
              c.descriptionFor(lang),
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
        Container(
          padding: const EdgeInsets.fromLTRB(18, 6, 10, 6),
          decoration: BoxDecoration(
            color: SoriColors.primary.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: SoriColors.primary.withValues(alpha: 0.30),
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
                      color: SoriColors.primary,
                    ),
                  ),
                  const SizedBox(width: 6),
                  // 2026-08-17 테스터(Amor): "카드를 누르면 예시어가 나온다."
                  // 예전엔 이 칩 **전체**가 GestureDetector 라 카드 탭을 가로챘다.
                  // 예시어는 이 스피커 버튼으로만 재생한다 — 카드 아무 데나
                  // 누르면 언제나 낱자 음가다.
                  IconButton(
                    key: ValueKey('hangul-example-speak-${c.letter}'),
                    onPressed: () => unawaited(TtsService.speak(c.exampleWord)),
                    icon: Icon(
                      Icons.volume_up_rounded,
                      size: soriFillSize(h, 0.05, 16, 28),
                      color: SoriColors.primary,
                    ),
                    tooltip: t.hangulPronounceLetter(c.exampleWord),
                    padding: const EdgeInsets.all(6),
                    visualDensity: VisualDensity.compact,
                    constraints: const BoxConstraints(
                      minWidth: 40,
                      minHeight: 40,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                c.exampleFor(lang),
                style: TextStyle(
                  fontSize: soriFillSize(h, 0.05, 13, 26),
                  color: s.text,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
    ];
  }

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
                  label: AppL10n.of(context).hangulChipConsonants,
                  accent: SoriColors.primary,
                  selected: _mode == 0,
                  onTap: () => _setMode(0),
                ),
                SoriChip(
                  label: AppL10n.of(context).hangulChipVowels,
                  accent: SoriColors.primary,
                  selected: _mode == 1,
                  onTap: () => _setMode(1),
                ),
                // 좌(모름)로 모은 글자만 다시 돌아본다 — `Storage.hangulHard`
                // 를 읽는 유일한 경로다. 모은 게 없으면 띄우지 않는다(빈 필터).
                if (Storage.hangulHard.isNotEmpty)
                  SoriChip(
                    key: const Key('hangul-cards-hard-only'),
                    label: AppL10n.of(context).hangulHardOnly,
                    accent: SoriColors.danger,
                    selected: _hardOnly,
                    onTap: _toggleHardOnly,
                  ),
                SoriChip(
                  label: AppL10n.of(context).hangulChipSyllables,
                  accent: SoriColors.primary,
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
                  // 덱 미리보기는 **다음 카드 앞면만** — swipe_card.dart 계약.
                  // (한글 카드엔 유출될 정답이 없지만 관례를 깨지 않는다.)
                  final next = _pool[(_idx + 1) % _pool.length];
                  final t = AppL10n.of(context);
                  return SoriContentFeed(
                    judgmentsEnabled: _flipped,
                    onBlockedJudgment: () => _flipHint.value++,
                    flipHintTrigger: _flipHint,
                    onNext: _known,
                    onHard: _dontKnow,
                    onSkip: _next,
                    onPrevious: _prev,
                    onLike: _likeCurrent,
                    onShare: _shareCurrent,
                    onFlip: () {
                      unawaited(widget.speak(c.letter));
                      _onFlip();
                    },
                    showBookmark: false,
                    liked: LikedContentService.isLiked(
                      kind: LikedContentService.hangul,
                      id: c.letter,
                    ),
                    underlay: _HangulCardFace(
                      borderColor: SoriColors.primary,
                      children: _frontFace(next, h),
                    ),
                    knowLabel: t.btnGewusst,
                    hardLabel: t.btnNichtGewusst,
                    skipLabel: t.btnSkip,
                    child: SoriStudyScale(
                      child: FlipCard(
                        key: ValueKey('hangul-card-${c.letter}'),
                        flipped: _flipped,
                        onTap: () {
                          unawaited(widget.speak(c.letter));
                          _onFlip();
                        },
                        front: _HangulCardFace(
                          borderColor: SoriColors.primary,
                          children: _frontFace(c, h),
                        ),
                        back: _HangulCardFace(
                          borderColor: SoriColors.info,
                          children: _backFace(context, c, s, h),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 10),
            // 보조 동작(이전·듣기·무작위)은 판정이 아니므로 44dp 아이콘 행으로
            // 내린다 — legacy_vocab 의 보조 행과 같은 계층 규칙.
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  key: const Key('hangul-cards-prev'),
                  onPressed: _prev,
                  icon: const Icon(Icons.arrow_back_rounded),
                  tooltip: AppL10n.of(context).btnPrev,
                  constraints: const BoxConstraints(
                    minWidth: 44,
                    minHeight: 44,
                  ),
                ),
                const SizedBox(width: Spacing.md),
                IconButton(
                  key: const Key('hangul-cards-speak'),
                  onPressed: () => unawaited(widget.speak(c.letter)),
                  icon: const Icon(Icons.volume_up_rounded),
                  color: SoriColors.primary,
                  tooltip: AppL10n.of(context).btnHoeren,
                  constraints: const BoxConstraints(
                    minWidth: 44,
                    minHeight: 44,
                  ),
                ),
                const SizedBox(width: Spacing.md),
                IconButton(
                  key: const Key('hangul-cards-random'),
                  onPressed: _random,
                  icon: const Icon(Icons.shuffle_rounded),
                  tooltip: AppL10n.of(context).btnRandom,
                  constraints: const BoxConstraints(
                    minWidth: 44,
                    minHeight: 44,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            SoriButton.filled(
              key: const Key('hangul-cards-finish'),
              label: AppL10n.of(context).testerFeedbackCompleteHangul,
              accent: SoriColors.primary,
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
  final Color borderColor;
  final List<Widget> children;
  const _HangulCardFace({
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

/// Schreiben 탭 한 세션의 결과.
///
/// [letters] 는 **획순까지 맞게 완성한 글자 수**다. 예전엔 획 수만 세서 아무
/// 낙서 1획으로도 완료가 됐다 (2026-08-17 테스터 지적).
typedef HangulWritingResult = ({int letters, int strokes, bool strict});

class _WriteTab extends StatefulWidget {
  const _WriteTab({required this.onFinish, required this.speak});
  final Future<void> Function(HangulWritingResult result) onFinish;
  final Future<bool> Function(String letter) speak;
  @override
  State<_WriteTab> createState() => _WriteTabState();
}

class _WriteTabState extends State<_WriteTab> {
  int _mode = 0; // 0=cons, 1=vowels
  int _idx = 0;

  /// 세션 총 획 수 — 완료 payload 용. **Finish 게이트가 아니다.**
  int _strokeCount = 0;

  /// 현재 글자에서 통과한 획 수 = 다음에 기대하는 획 index.
  int _acceptedStrokes = 0;

  /// 획순까지 맞게 끝낸 글자 수 — 이것만이 Finish 를 연다.
  int _completedLetters = 0;

  /// 마지막 판정. 힌트 문구용. 맞으면 null.
  StrokeAttempt? _lastAttempt;

  /// 완성 연출 중 — 입력·판정을 정지시킨다.
  bool _letterDone = false;

  late bool _strict;

  Timer? _errorTimer;
  Timer? _advanceTimer;

  static const Duration _errorFlash = Duration(milliseconds: 450);
  static const Duration _advanceDelay = Duration(milliseconds: 650);

  final _practiceKey = GlobalKey<_PracticeCanvasState>();

  @override
  void initState() {
    super.initState();
    _strict = Storage.hangulStrictStrokes;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      unawaited(widget.speak(_current.letter));
      if (Storage.tutSeen('hangulWriteRules')) {
        return;
      }
      unawaited(_showRules());
    });
  }

  void _speakCurrent() {
    unawaited(widget.speak(_current.letter));
  }

  Future<void> _showRules() async {
    if (!mounted) {
      return;
    }
    final t = AppL10n.of(context);
    await showSoriSheet<void>(
      context: context,
      builder: (sheetContext) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              t.hangulRulesTitle,
              style: SoriTextTheme.of(sheetContext).h2,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: Spacing.md),
            Text(
              t.hangulRulesBody,
              style: SoriTextTheme.of(sheetContext).gloss,
            ),
            const SizedBox(height: Spacing.lg),
            SoriButton.filled(
              label: t.btnClose,
              accent: SoriColors.contentCta,
              fullWidth: true,
              onTap: () => Navigator.pop(sheetContext),
            ),
          ],
        );
      },
    );
    await Storage.setTutSeen('hangulWriteRules');
  }

  Future<void> _showWriteSettings() async {
    final t = AppL10n.of(context);
    await showSoriSheet<void>(
      context: context,
      builder: (sheetContext) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 8,
              runSpacing: 8,
              children: [
                SoriChip(
                  label: t.hangulChipConsonants,
                  accent: SoriColors.contentCta,
                  selected: _mode == 0,
                  onTap: () {
                    _setMode(0);
                    Navigator.pop(sheetContext);
                  },
                ),
                SoriChip(
                  label: t.hangulChipVowels,
                  accent: SoriColors.contentCta,
                  selected: _mode == 1,
                  onTap: () {
                    _setMode(1);
                    Navigator.pop(sheetContext);
                  },
                ),
                SoriChip(
                  key: const Key('hangul-check-strict'),
                  label: t.hangulCheckModeExam,
                  accent: SoriColors.contentCta,
                  selected: _strict,
                  onTap: () {
                    _setStrict(true);
                    Navigator.pop(sheetContext);
                  },
                ),
                SoriChip(
                  key: const Key('hangul-check-practice'),
                  label: t.hangulCheckModePractice,
                  accent: SoriColors.contentCta,
                  selected: !_strict,
                  onTap: () {
                    _setStrict(false);
                    Navigator.pop(sheetContext);
                  },
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    // Future.delayed 는 취소할 수 없어 Timer 로 바꿨다. dispose 후 _next 가
    // 튀는 것과, 완성 직후 Weiter 를 눌러 글자를 건너뛰는 것을 둘 다 막는다.
    _errorTimer?.cancel();
    _advanceTimer?.cancel();
    super.dispose();
  }

  List<HangulChar> get _pool => _mode == 0 ? consonants : vowels;
  HangulChar get _current => _pool[_idx % _pool.length];
  List<Stroke> get _targetStrokes =>
      hangulStrokes[_current.letter] ?? const <Stroke>[];

  /// 현재 글자 진행 상태를 처음으로 되돌린다.
  ///
  /// 예전엔 Löschen 이 캔버스만 지우고 획 카운터를 남겨, **지운 뒤로는 그
  /// 글자가 두 번 다시 판정되지 않았다** — 테스터가 본 "성공음이 일관되지
  /// 않다" 의 정체다. 되돌리기는 한 군데(여기)로 모은다.
  void _resetLetter() {
    _errorTimer?.cancel();
    _advanceTimer?.cancel();
    setState(() {
      _acceptedStrokes = 0;
      _lastAttempt = null;
      _letterDone = false;
    });
    _practiceKey.currentState?.clear();
  }

  void _next() {
    HapticFeedback.selectionClick();
    setState(() => _idx = (_idx + 1) % _pool.length);
    _resetLetter();
    _speakCurrent();
  }

  void _prev() {
    HapticFeedback.selectionClick();
    setState(() => _idx = (_idx - 1 + _pool.length) % _pool.length);
    _resetLetter();
    _speakCurrent();
  }

  void _setMode(int m) {
    if (_mode == m) {
      return;
    }
    HapticFeedback.selectionClick();
    setState(() {
      _mode = m;
      _idx = 0;
    });
    _resetLetter();
    _speakCurrent();
  }

  void _setStrict(bool strict) {
    if (_strict == strict) {
      return;
    }
    HapticFeedback.selectionClick();
    setState(() => _strict = strict);
    // 판정 규칙이 바뀌면 진행 중인 글자는 무효다.
    _resetLetter();
    unawaited(Storage.setHangulStrictStrokes(strict));
  }

  void _clearPractice() {
    HapticFeedback.selectionClick();
    _resetLetter();
  }

  void _onStrokeEnd() {
    setState(() => _strokeCount++);
    _judgeLastStroke();
  }

  /// 획을 뗄 때마다 **그 획 하나만** 기대 획과 대조한다.
  ///
  /// 예전에는 그은 획 수가 정답 획 수와 같아지는 순간 한 번만 봤고, 틀리면
  /// 아무 말도 하지 않았다 — 테스터(Amor)가 "일부러 틀려도 인식하지 못하고
  /// 그냥 진행된다" 고 본 그대로다.
  void _judgeLastStroke() {
    if (_letterDone) {
      return;
    }
    final canvas = _practiceKey.currentState;
    final target = _targetStrokes;
    if (canvas == null || target.isEmpty || canvas.strokes.isEmpty) {
      return;
    }
    final size = canvas.canvasSize;
    if (size == null || size.isEmpty) {
      return;
    }
    final attempt = evaluateStroke(
      target: target,
      expectedIndex: _acceptedStrokes,
      drawn: canvas.strokes.last,
      canvasSize: size,
      // 방향은 획순 검사 모드에서만 본다. ㅡ 를 거꾸로 그어도 남는 모양은
      // 같아서, 연습 모드에서까지 막으면 학습이 아니라 시험이 된다.
      checkDirection: _strict,
    );
    if (attempt.ok) {
      _acceptStroke(target.length);
      return;
    }
    _rejectStroke(attempt);
  }

  void _acceptStroke(int total) {
    _errorTimer?.cancel();
    _practiceKey.currentState?.clearErrorGhost();
    setState(() {
      _acceptedStrokes++;
      _lastAttempt = null;
    });
    if (_acceptedStrokes < total) {
      // 중간 획은 햅틱만 — ㅃ(8획)마다 효과음이 나면 소리가 의미를 잃는다.
      HapticFeedback.selectionClick();
      return;
    }
    _completeLetter();
  }

  void _completeLetter() {
    setState(() {
      _letterDone = true;
      _completedLetters++;
    });
    SoundService.correct();
    HapticFeedback.mediumImpact();
    _advanceTimer?.cancel();
    // 방금 그린 게 맞았는지 눈으로 볼 틈을 준 뒤 넘어간다.
    _advanceTimer = Timer(_advanceDelay, () {
      if (!mounted) {
        return;
      }
      _next();
    });
  }

  void _rejectStroke(StrokeAttempt attempt) {
    setState(() => _lastAttempt = attempt);
    if (!_strict) {
      // 연습 모드: 무엇이 틀렸는지 말해주되 지우거나 막지 않는다.
      return;
    }
    SoundService.wrong();
    HapticFeedback.heavyImpact();
    // 틀린 획은 **동기적으로** 판정 대상에서 빼고 잔상만 잠깐 남긴다.
    // 타이머가 _strokes 를 건드리지 않으므로, 잔상이 남은 동안 빠르게 다시
    // 그려도 엉뚱한 획이 지워지지 않는다.
    _practiceKey.currentState?.rejectLastStroke();
    _errorTimer?.cancel();
    _errorTimer = Timer(_errorFlash, () {
      if (!mounted) {
        return;
      }
      _practiceKey.currentState?.clearErrorGhost();
    });
  }

  Future<void> _finish() async {
    if (_completedLetters == 0) {
      return;
    }
    _errorTimer?.cancel();
    _advanceTimer?.cancel();
    await widget.onFinish((
      letters: _completedLetters,
      strokes: _strokeCount,
      strict: _strict,
    ));
    if (!mounted) {
      return;
    }
    setState(() {
      _completedLetters = 0;
      _strokeCount = 0;
    });
    _resetLetter();
  }

  /// 힌트 줄은 **절대 비우지 않는다** — 줄 수가 들쭉날쭉하면 캔버스가 위아래로
  /// 튄다. 픽셀 높이를 고정하는 대신 항상 한 줄을 채우는 쪽을 택했다(글자
  /// 배율이 커져도 안 깨진다).
  String _hintText(AppL10n t) {
    if (_targetStrokes.isEmpty) {
      return '';
    }
    if (_letterDone) {
      return t.hangulStrokeLetterDone(_current.letter);
    }
    final attempt = _lastAttempt;
    if (attempt == null) {
      return t.hangulStrokeNextHint(_acceptedStrokes + 1);
    }
    return switch (attempt.verdict) {
      StrokeVerdict.wrongOrder => t.hangulStrokeWrongOrder(
        (attempt.matchedIndex ?? 0) + 1,
        attempt.expectedIndex + 1,
      ),
      StrokeVerdict.wrongDirection => t.hangulStrokeWrongDirection(
        attempt.expectedIndex + 1,
      ),
      StrokeVerdict.tooShort => t.hangulStrokeTooShort,
      StrokeVerdict.offShape => t.hangulStrokeWrongShape(
        attempt.expectedIndex + 1,
      ),
      StrokeVerdict.ok => t.hangulStrokeNextHint(_acceptedStrokes + 1),
    };
  }

  Color _hintColor() {
    if (_letterDone) {
      return SoriColors.success;
    }
    if (_lastAttempt != null) {
      return SoriColors.danger;
    }
    return SoriSurfaces.of(context).textMuted;
  }

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);
    final c = _current;
    final strokes = _targetStrokes;
    final total = strokes.length;
    final shown = _letterDone ? total : math.min(_acceptedStrokes + 1, total);

    return LayoutBuilder(
      builder: (context, viewport) {
        final tt = SoriTextTheme.of(context);
        final chrome = 48.0;
        final nav = 56.0;
        final hintH = strokes.isNotEmpty ? 52.0 : 0.0;
        final finishH = _completedLetters > 0 ? 92.0 : 0.0;
        final canvasSize = math.min(
          viewport.maxWidth - 28,
          math.max(220.0, viewport.maxHeight - chrome - nav - hintH - finishH - 16),
        );
        return Semantics(
          container: true,
          customSemanticsActions: <CustomSemanticsAction, VoidCallback>{
            CustomSemanticsAction(label: t.btnPrev): _prev,
            CustomSemanticsAction(label: t.btnNext): _next,
          },
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 4, 14, 8),
            child: Column(
              children: [
                SizedBox(
                  height: chrome,
                  child: Row(
                    children: [
                      IconButton(
                        key: const Key('hangul-write-rules'),
                        onPressed: () => unawaited(_showRules()),
                        tooltip: t.hangulRulesTitle,
                        icon: Text('?', style: tt.h2),
                      ),
                      if (strokes.isNotEmpty)
                        Flexible(
                          child: SoriChip(
                            key: const Key('hangul-stroke-progress'),
                            label: t.hangulStrokeProgress(shown, total),
                            accent: _letterDone
                                ? SoriColors.success
                                : SoriColors.contentCta,
                            selected: _letterDone,
                          ),
                        ),
                      const Spacer(),
                      IconButton(
                        key: const Key('hangul-write-speak'),
                        onPressed: () => unawaited(widget.speak(c.letter)),
                        icon: const Icon(Icons.volume_up_rounded),
                        tooltip: t.hangulPronounceLetter(c.letter),
                      ),
                      IconButton(
                        key: const Key('hangul-write-overflow'),
                        onPressed: () => unawaited(_showWriteSettings()),
                        tooltip: t.hangulCheckModeLabel,
                        icon: const Icon(Icons.more_horiz_rounded),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Center(
                    child: SizedBox(
                      width: canvasSize,
                      height: canvasSize,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          IgnorePointer(
                            child: StrokeCanvas(
                              letter: c.letter,
                              strokes: strokes,
                              size: canvasSize,
                              color: SoriColors.contentCta,
                              highlightIndex: _letterDone || strokes.isEmpty
                                  ? null
                                  : _acceptedStrokes,
                            ),
                          ),
                          _PracticeCanvas(
                            key: _practiceKey,
                            ghost: c.letter,
                            color: SoriColors.primary,
                            errorColor: SoriColors.danger,
                            enabled: !_letterDone,
                            onStrokeEnd: _onStrokeEnd,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                if (strokes.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    key: const Key('hangul-stroke-hint'),
                    _hintText(t),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    style: tt.meta.copyWith(color: _hintColor()),
                  ),
                ],
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      key: const Key('hangul-write-prev'),
                      onPressed: _prev,
                      icon: const Icon(Icons.chevron_left_rounded),
                      tooltip: t.btnPrev,
                    ),
                    Text(
                      '${_idx + 1} / ${_pool.length}',
                      style: tt.meta,
                    ),
                    IconButton(
                      key: const Key('hangul-write-next'),
                      onPressed: _next,
                      icon: const Icon(Icons.chevron_right_rounded),
                      tooltip: t.btnNext,
                    ),
                    IconButton(
                      key: const Key('hangul-write-clear'),
                      onPressed: _clearPractice,
                      icon: const Icon(Icons.delete_outline_rounded),
                      color: SoriColors.danger,
                      tooltip: t.hangulClearBtn,
                    ),
                  ],
                ),
                if (_completedLetters > 0) ...[
                  Text(
                    t.hangulLettersDone(_completedLetters),
                    style: tt.meta.copyWith(color: SoriColors.success),
                  ),
                  const SizedBox(height: 6),
                  SoriButton.filled(
                    key: const Key('hangul-writing-finish'),
                    label: t.testerFeedbackCompleteHangul,
                    accent: SoriColors.contentCta,
                    onTap: _finish,
                    fullWidth: true,
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Frei-Hand Canvas zum Nachzeichnen.
class _PracticeCanvas extends StatefulWidget {
  final String ghost;
  final Color color;
  final Color errorColor;
  final bool enabled;
  final VoidCallback onStrokeEnd;
  const _PracticeCanvas({
    super.key,
    required this.ghost,
    required this.color,
    required this.errorColor,
    required this.onStrokeEnd,
    this.enabled = true,
  });

  @override
  State<_PracticeCanvas> createState() => _PracticeCanvasState();
}

class _PracticeCanvasState extends State<_PracticeCanvas> {
  final List<List<Offset>> _strokes = [];
  List<Offset>? _current;

  /// 방금 퇴짜맞은 획. **[_strokes] 바깥에 둔다** — 판정 대상 목록은 즉시
  /// 정리되고 여기 남는 건 잔상뿐이라, 잔상이 사라지기 전에 다시 그려도
  /// 타이머가 엉뚱한 획을 지울 수 없다.
  List<Offset>? _errorGhost;

  int _paintRevision = 0;

  /// 지금까지 통과 판정을 기다리는 획들. 획순 판정에 넘긴다.
  List<List<Offset>> get strokes => _strokes;

  /// 실제로 그린 영역의 크기. 판정은 220×220 기준으로 정규화하므로 필요하다.
  /// 레이아웃 전이면 null.
  Size? get canvasSize {
    final box = context.findRenderObject();
    return box is RenderBox && box.hasSize ? box.size : null;
  }

  void clear() {
    setState(() {
      _strokes.clear();
      _current = null;
      _errorGhost = null;
      _paintRevision++;
    });
  }

  /// 마지막 획을 판정 대상에서 빼고 잔상으로 옮긴다.
  void rejectLastStroke() {
    if (_strokes.isEmpty) {
      return;
    }
    setState(() {
      _errorGhost = _strokes.removeLast();
      _paintRevision++;
    });
  }

  /// 잔상을 지운다. 두 번 불러도 안전하다(타이머 콜백이 겹쳐도 무해).
  void clearErrorGhost() {
    if (_errorGhost == null) {
      return;
    }
    setState(() {
      _errorGhost = null;
      _paintRevision++;
    });
  }

  void _startStroke(PointerDownEvent event) {
    if (!widget.enabled) {
      return;
    }
    setState(() {
      // 새로 긋기 시작하면 잔상은 바로 걷는다.
      _errorGhost = null;
      _current = [event.localPosition];
      _strokes.add(_current!);
      _paintRevision++;
    });
  }

  void _updateStroke(PointerMoveEvent event) {
    if (_current == null) {
      return;
    }
    setState(() {
      _current!.add(event.localPosition);
      _paintRevision++;
    });
  }

  void _endStroke() {
    final current = _current;
    if (current == null) {
      return;
    }
    if (current.length < 2) {
      setState(() {
        _strokes.removeLast();
        _current = null;
        _paintRevision++;
      });
      return;
    }
    setState(() {
      _current = null;
      _paintRevision++;
    });
    // 햅틱은 부모가 판정 결과에 맞춰 준다 — 여기서 미리 울리면 오답 햅틱과 겹친다.
    widget.onStrokeEnd();
  }

  void _cancelStroke() {
    if (_current == null) {
      return;
    }
    setState(() {
      _strokes.removeLast();
      _current = null;
      _paintRevision++;
    });
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(SoriRadius.md),
      child: RawGestureDetector(
        key: const Key('hangul-practice-canvas'),
        behavior: HitTestBehavior.opaque,
        gestures: <Type, GestureRecognizerFactory>{
          EagerGestureRecognizer:
              GestureRecognizerFactoryWithHandlers<EagerGestureRecognizer>(
                EagerGestureRecognizer.new,
                (_) {},
              ),
        },
        child: Listener(
          behavior: HitTestBehavior.opaque,
          onPointerDown: _startStroke,
          onPointerMove: _updateStroke,
          onPointerUp: (_) => _endStroke(),
          onPointerCancel: (_) => _cancelStroke(),
          child: CustomPaint(
            key: ValueKey('hangul-practice-ghost-${widget.ghost}'),
            painter: _PracticePainter(
              ghost: widget.ghost,
              strokes: _strokes,
              errorGhost: _errorGhost,
              color: widget.color,
              errorColor: widget.errorColor,
              revision: _paintRevision,
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
  final List<Offset>? errorGhost;
  final Color color;
  final Color errorColor;
  final int revision;

  _PracticePainter({
    required this.ghost,
    required this.strokes,
    required this.errorGhost,
    required this.color,
    required this.errorColor,
    required this.revision,
  });

  void _drawPolyline(Canvas canvas, List<Offset> stroke, Paint paint) {
    if (stroke.length < 2) {
      return;
    }
    final path = Path()..moveTo(stroke.first.dx, stroke.first.dy);
    for (var i = 1; i < stroke.length; i++) {
      path.lineTo(stroke[i].dx, stroke[i].dy);
    }
    canvas.drawPath(path, paint);
  }

  @override
  void paint(Canvas canvas, Size size) {
    // Guide form is the StrokeCanvas underneath — same paths, same box.
    final p = Paint()
      ..color = color
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = size.height / 220 * 11
      ..style = PaintingStyle.stroke;

    for (final stroke in strokes) {
      _drawPolyline(canvas, stroke, p);
    }

    // 퇴짜맞은 획은 위에 더 굵게 — "이건 틀렸고 곧 사라진다" 가 읽히게.
    // 소리·햅틱은 웹/무음 설정에서 안 나므로 색이 유일한 신호일 수 있다.
    final ghostStroke = errorGhost;
    if (ghostStroke != null) {
      _drawPolyline(
        canvas,
        ghostStroke,
        Paint()
          ..color = errorColor
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round
          ..strokeWidth = 7
          ..style = PaintingStyle.stroke,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _PracticePainter old) =>
      old.revision != revision || old.ghost != ghost;
}
