import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../l10n/generated/app_localizations.dart';
import '../models/custom_pack.dart';
import '../models/feedback_completion.dart';
import '../services/custom_pack_service.dart';
import '../services/storage_service.dart';
import '../services/tts_service.dart';
import '../widgets/flip_card.dart';
import '../widgets/managed_media_image.dart';
import '../widgets/sori/button.dart';
import '../widgets/sori/mascot_preference.dart';
import '../widgets/sori/card.dart';
import '../widgets/sori/chip.dart';
import '../widgets/sori/deck_action_bar.dart';
import '../widgets/sori/swipe_card.dart';
import '../widgets/sori/content_feedback_card.dart';
import '../widgets/sori/empty_state.dart';
import '../widgets/sori/mascot.dart';
import '../widgets/sori/pressable.dart';
import '../widgets/sori/responsive.dart';
import '../widgets/sori/screen_coach.dart';
import '../widgets/sori/spotlight_coach.dart';
import '../widgets/sori/tokens.dart';
import '../widgets/sori/tts_speed_control.dart';

/// Phase 5.1 (stately-rising-jongga) — CustomPack 학습 화면.
///
/// 단순 FlipCard 흐름:
///   - 앞면: 한국어 + 로마자 + TTS
///   - 뒷면: 독일어 + 예문 + 예문 번역
///   - "Gewusst" → addVokSeen + 다음. "다시" → 다음.
///   - 마지막 카드 끝나면 결과 카드.
///
/// 일반 vocab pack 의 3단계 (learn/quiz/boss) 와는 의도적으로 다름 —
/// 사용자 정의 단어는 양이 작고, 어휘 마스터 보다는 "이 페이지의 단어가 뭐였지?"
/// 빠르게 훑는 용도.
class CustomPackPlayScreen extends StatefulWidget {
  final String packId;
  const CustomPackPlayScreen({super.key, required this.packId});

  @override
  State<CustomPackPlayScreen> createState() => _CustomPackPlayScreenState();
}

class _CustomPackPlayScreenState extends State<CustomPackPlayScreen>
    with ScreenCoachMixin<CustomPackPlayScreen> {
  CustomPack? _pack;
  int _idx = 0;
  bool _flipped = false;
  // 플립 전 판정을 시도하면 힌트 칩을 띄운다 (스와이프 발견성).
  // 카운터만 올리고 표시 수명은 DeckFlipHint 가 관리한다.
  int _flipHintTick = 0;
  // FlipCard re-key용 서빙 카운터 — 카드 전환 시 뒷면(뜻) 선노출 방지
  // (계약: flip_card.dart doc-comment).
  int _serve = 0;
  int _learned = 0;
  final FeedbackCompletionSlot _feedbackCompletion = FeedbackCompletionSlot();

  // ── 코치마크 타겟 ──
  final GlobalKey _cardKey = GlobalKey();

  @override
  String get coachId => 'cpPlay';

  @override
  bool get coachReady => _pack != null && (_pack!.words.isNotEmpty);

  @override
  List<SpotlightStep> buildCoachSteps(BuildContext context) {
    final t = AppL10n.of(context);
    return [
      SpotlightStep(
        targetKey: _cardKey,
        title: t.coachCpPlayTitle,
        body: t.coachCpPlayBody,
        icon: Icons.style_outlined,
      ),
    ];
  }

  @override
  void initState() {
    super.initState();
    _pack = CustomPackService.getById(widget.packId);
    scheduleCoach();
  }

  void _gotIt() {
    final pack = _pack;
    if (pack == null) return;
    HapticFeedback.lightImpact();
    final w = pack.words[_idx];
    Storage.addVokSeen(w.korean);
    // A1: 메인 SRS 에 편입 → "오늘의 복습"에서 다시 만남.
    Storage.srsReview(w.korean, gotIt: true);
    setState(() {
      _learned++;
    });
    _advance();
  }

  /// ← 모름. 이름이 `_skip` 이었지만 **완전한 음성 판정**이다 (SRS 리셋 +
  /// 오답 카운터 증가) — 진짜 스킵은 아무것도 기록하지 않는 [_defer] 다.
  void _dontKnow() {
    HapticFeedback.mediumImpact();
    final pack = _pack;
    if (pack != null) {
      // A1: 모른 단어 → SRS 간격 짧게 리셋 (내일 다시).
      Storage.srsReview(pack.words[_idx].korean, gotIt: false);
      // ignore: discarded_futures
      Storage.incrementWrongCount(pack.words[_idx].korean);
    }
    _advance();
  }

  /// ↓ 스킵 — **기록 없는 전진**. SRS·오답 카운터를 건드리지 않는다.
  /// `_advance()` 가 이미 무기록 경로라 그대로 재사용한다 (재서빙 리셋 포함:
  /// `_flipped=false` + serve 카운터 전진 → 다음 카드가 앞면으로 서빙된다).
  void _defer() {
    HapticFeedback.selectionClick();
    _advance();
  }

  /// 덱 스택 미리보기 — 다음 카드의 **앞면만**(뒷면은 정답 유출).
  Widget? _nextCardPreview() {
    final pack = _pack;
    if (pack == null || _idx + 1 >= pack.words.length) {
      return null;
    }
    return Center(
      child: FractionallySizedBox(
        widthFactor: 1,
        heightFactor: 0.82,
        child: SoriStudyScale(
          child: _Front(
            word: pack.words[_idx + 1],
            deckKoreans: [for (final x in pack.words) x.korean],
          ),
        ),
      ),
    );
  }

  /// 힌트 표시 요청 — 실제 수명(3초)은 [DeckFlipHint] 가 소유한다.
  void _showFlipFirstHint() {
    setState(() => _flipHintTick++);
  }

  void _advance() {
    final pack = _pack;
    if (pack == null) return;
    setState(() {
      _flipped = false;
      _idx++;
      _serve++;
      if (_idx >= pack.words.length) {
        _feedbackCompletion.complete(
          () => FeedbackCompletion.customPackPlay(
            packId: pack.id,
            learned: _learned,
            total: pack.totalWords,
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);

    if (_pack == null) {
      return Scaffold(
        appBar: AppBar(title: Text(t.customPackPlayTitle)),
        body: Center(
          child: SoriEmptyState(
            asset: 'assets/illustrations/mascot/tiger_sitting2.png',
            icon: Icons.help_outline,
            title: t.customPackNotFoundTitle,
            body: t.customPackNotFoundBody,
          ),
        ),
      );
    }
    final pack = _pack!;

    if (pack.words.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: Text(t.customPackPlayTitle)),
        body: Center(
          child: SoriEmptyState(
            asset: 'assets/illustrations/mascot/magpie_encourage.png',
            icon: Icons.style_outlined,
            title: t.customPackEmptyTitle,
            body: t.customPackEmptyBody,
          ),
        ),
      );
    }

    // 끝
    if (_idx >= pack.words.length) {
      return _buildDone(t, pack);
    }

    final w = pack.words[_idx];
    final s = SoriSurfaces.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          pack.displayName(),
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        actions: const [TtsSpeedAction()],
      ),
      body: SafeArea(
        child: SoriStudyClamp(
          child: Padding(
            padding: const EdgeInsets.all(Spacing.lg),
            child: Column(
              children: [
                Row(
                  children: [
                    SoriChip(
                      label: '${_idx + 1} / ${pack.words.length}',
                      accent: SoriColors.info,
                    ),
                    const Spacer(),
                    Text(
                      t.vocabPackTapToFlip,
                      style: TextStyle(fontSize: 12, color: s.textMuted),
                    ),
                  ],
                ),
                const SizedBox(height: Spacing.md),
                Expanded(
                  child: Stack(
                    alignment: Alignment.topCenter,
                    children: [
                      // 카드는 글자 수와 무관하게 영역의 82%로 고정(쪼그라들지 않음) +
                      // 상하 여백으로 코치마크·버튼 공간 확보.
                      // Sori Deck 2.0 — 우=앎 · 좌=모름 · 아래=스킵 (위=저장은 이
                      // 화면에서 비노출). 하단 아이콘 바가 접근성 정본이다.
                      SoriSwipeCard(
                        // §C-1-1: 플립 전 스와이프 금지 — 답을 보지 않은
                        // 카드에 SRS가 기록되는 데이터 버그 방지.
                        enabled: _flipped,
                        onSwipeRight: _gotIt,
                        onSwipeLeft: _dontKnow,
                        // ↑ 저장은 이 화면에서 **비노출**이다: 이 단어들은 정의상
                        // 이미 사용자 팩 소속이라 quickAdd 는 무의미하거나 중복
                        // 복사가 된다 (quickAdd 는 quick pack 내부만 dedupe).
                        onSwipeUp: null,
                        onSwipeDown: _defer,
                        onBlockedHorizontalDrag: _showFlipFirstHint,
                        underlay: _nextCardPreview(),
                        rightBadge: SoriSwipeBadge(
                          label: t.btnGewusst,
                          icon: Icons.check_rounded,
                          color: SoriColors.success,
                          asset: deckActionAsset('know'),
                        ),
                        leftBadge: SoriSwipeBadge(
                          label: t.btnNichtGewusst,
                          icon: Icons.question_mark_rounded,
                          color: SoriColors.danger,
                          asset: deckActionAsset('dontknow'),
                        ),
                        downBadge: SoriSwipeBadge(
                          label: t.btnSkip,
                          icon: Icons.arrow_downward_rounded,
                          color: SoriColors.info,
                          asset: deckActionAsset('skip'),
                        ),
                        child: Center(
                          child: FractionallySizedBox(
                            // 슬롯 핀 (P1) — 카드 rect 는 단어·플립 상태와 무관하다.
                            key: const ValueKey('deck-card-slot'),
                            widthFactor: 1,
                            heightFactor: 0.82,
                            child: SoriStudyScale(
                              // 코치마크 타겟(GlobalKey)은 렌더객체 없는 KeyedSubtree에
                              // 걸고, FlipCard 자체는 서빙 카운터 key로 카드마다 새로
                              // 만든다 (뒷면 선노출 방지).
                              child: KeyedSubtree(
                                key: _cardKey,
                                child: FlipCard(
                                  key: ValueKey('cp-$_serve'),
                                  flipped: _flipped,
                                  onTap: () {
                                    HapticFeedback.selectionClick();
                                    setState(() => _flipped = !_flipped);
                                  },
                                  front: _Front(
                                    word: w,
                                    deckKoreans: [
                                      for (final x in pack.words) x.korean,
                                    ],
                                  ),
                                  back: _Back(word: w),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      DeckFlipHint(trigger: _flipHintTick),
                    ],
                  ),
                ),
                const SizedBox(height: Spacing.md),
                DeckActionBar(
                  onDontKnow: _dontKnow,
                  onKnow: _gotIt,
                  onSkip: _defer,
                  // 저장 없음 — 위 onSwipeUp: null 과 같은 이유.
                  // 버튼도 카드와 같은 플립 게이트를 받는다 (의도된 강화).
                  judgmentEnabled: _flipped,
                  onBlockedJudgment: _showFlipFirstHint,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDone(AppL10n t, CustomPack pack) {
    final feedbackScope = ContentFeedbackControllerScope.maybeOf(context);
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text(
          t.customPackResultTitle,
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: SafeArea(
        child: SoriCenterClamp(
          child: Padding(
            padding: const EdgeInsets.all(Spacing.lg),
            child: ListView(
              children: [
                const SizedBox(height: Spacing.xl),
                CompanionBuilder(
                  builder: (context, kind) => Mascot(
                    kind: kind,
                    emotion: MascotEmotion.celebrate,
                    size: 96,
                    animate: true,
                  ),
                  noneBuilder: (context) => const Icon(
                    Icons.task_alt_rounded,
                    size: 88,
                    color: SoriColors.success,
                  ),
                ),
                const SizedBox(height: Spacing.md),
                Text(
                  t.customPackResultDone,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: Spacing.sm),
                Text(
                  t.customPackResultStats(_learned, pack.totalWords),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: SoriSurfaces.of(context).textMuted,
                  ),
                ),
                if (_feedbackCompletion.current != null &&
                    feedbackScope != null &&
                    feedbackScope.featureGate.isEnabled) ...[
                  const SizedBox(height: Spacing.xl),
                  ContentFeedbackCard(
                    feedbackContext: _feedbackCompletion.current!.context,
                    featureGate: feedbackScope.featureGate,
                    submitFeedback: feedbackScope.submitFeedback,
                    completedMissionIds: feedbackScope.completedMissionIds,
                  ),
                ],
                const SizedBox(height: Spacing.xl),
                SoriButton(
                  label: t.customPackResultAgain,
                  icon: Icons.refresh_rounded,
                  variant: SoriButtonVariant.filled,
                  accent: SoriColors.primary,
                  fullWidth: true,
                  onTap: () => setState(() {
                    _idx = 0;
                    _learned = 0;
                    _flipped = false;
                    _feedbackCompletion.reset();
                  }),
                ),
                const SizedBox(height: Spacing.sm),
                SoriButton(
                  label: t.customPackResultBack,
                  icon: Icons.menu_book_outlined,
                  variant: SoriButtonVariant.outlined,
                  accent: SoriColors.info,
                  fullWidth: true,
                  onTap: () => Navigator.of(context).popUntil(
                    (r) => r.settings.name == '/bookshelf' || r.isFirst,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Front extends StatelessWidget {
  final dynamic word; // ExtractedWord

  /// 팩 전체 표제어 — 제시어 크기를 덱에서 가장 긴 단어 기준으로 한 번 정해
  /// 카드마다 크기가 요동치지 않게 한다 ([soriUniformFitSize]).
  final List<String> deckKoreans;
  const _Front({required this.word, required this.deckKoreans});

  @override
  Widget build(BuildContext context) {
    return SoriCard(
      variant: SoriCardVariant.hero,
      accent: SoriColors.info,
      tinted: true,
      // 슬롯 핀의 이중 안전벨트 (P1) — width 가 null 이면 SoriCard 가 세로
      // 스크롤 자식의 내재폭으로 줄어든다 (단어 길이별 카드 신축 회귀).
      width: double.infinity,
      // 카드 안쪽 높이를 폰트·간격 기준으로 삼아 텍스트가 카드에 비례해 커지고
      // (기기 무관 균일 충전율) 세로는 spaceEvenly 로 카드를 채운다. 콘텐츠가
      // 카드보다 커지는 드문 경우엔 SingleChildScrollView 가 스크롤로 받아낸다.
      child: LayoutBuilder(
        builder: (context, constraints) {
          final h = constraints.maxHeight.isFinite
              ? constraints.maxHeight
              // FlipCard._fitFace scroll-wraps this face → maxHeight is unbounded;
              // the real card height arrives as minHeight from its ConstrainedBox,
              // so text scales with the device instead of a fixed 360 baseline.
              : (constraints.minHeight.isFinite && constraints.minHeight > 0
                    ? constraints.minHeight
                    : 360.0);
          return SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: h),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  if (word.imagePath.isNotEmpty)
                    ManagedMediaImage(
                      reference: word.imagePath,
                      width: 220,
                      height: 120,
                      borderRadius: BorderRadius.circular(SoriRadius.md),
                    ),
                  // 단어 — 카드를 채우는 대형 헤드라인. 크기는 덱 공유값 하나로
                  // 고정 (단어 길이별 요동 금지) — FittedBox 는 실측 오차용
                  // 안전망일 뿐 정상 경로에서는 개입하지 않는다.
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      word.korean,
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      style: TextStyle(
                        fontSize: soriUniformFitSize(
                          context,
                          texts: deckKoreans,
                          maxWidth: constraints.maxWidth,
                          cap: soriFillSize(h, 0.19, 34, 92),
                          min: 30,
                          letterSpacing: -0.5,
                        ),
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ),
                  // 로마자 + 듣기 버튼을 한 묶음으로(발음 정보끼리 붙어 있게).
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (word.romanization.isNotEmpty) ...[
                        Text(
                          '[${word.romanization}]',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: soriFillSize(h, 0.052, 14, 30),
                            color: Colors.black54,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                        SizedBox(height: soriFillSize(h, 0.03, 8, 20)),
                      ],
                      IconButton(
                        icon: Icon(
                          Icons.volume_up_rounded,
                          size: soriFillSize(h, 0.09, 28, 56),
                        ),
                        onPressed: () {
                          // ignore: discarded_futures
                          TtsService.speak(word.korean);
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _Back extends StatelessWidget {
  final dynamic word; // ExtractedWord
  const _Back({required this.word});

  @override
  Widget build(BuildContext context) {
    return SoriCard(
      variant: SoriCardVariant.hero,
      accent: SoriColors.success,
      tinted: true,
      // 앞면과 같은 이중 안전벨트 — 플립 전후 카드 rect 가 같아야 한다.
      width: double.infinity,
      // 앞면과 동일: 카드 안쪽 높이 기준으로 텍스트를 키우고 spaceEvenly 로 채운다.
      child: LayoutBuilder(
        builder: (context, constraints) {
          final h = constraints.maxHeight.isFinite
              ? constraints.maxHeight
              // FlipCard._fitFace scroll-wraps this face → maxHeight is unbounded;
              // the real card height arrives as minHeight from its ConstrainedBox,
              // so text scales with the device instead of a fixed 360 baseline.
              : (constraints.minHeight.isFinite && constraints.minHeight > 0
                    ? constraints.minHeight
                    : 360.0);
          return SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: h),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // 뜻(헤드라인) + 품사를 한 묶음으로 → spaceEvenly 가 흩뜨리지 않는다.
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // 뜻은 고정 크기 + 줄바꿈 — FittedBox 축소는 뜻 길이마다
                      // 카드 글씨를 요동치게 한다 (단어 길이별 크기 변동 금지).
                      Text(
                        word.translationDe.isNotEmpty
                            ? word.translationDe
                            : (word.posDe.isNotEmpty ? word.posDe : '-'),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: soriFillSize(h, 0.085, 22, 38),
                          fontWeight: FontWeight.w800,
                          height: 1.15,
                        ),
                      ),
                      if ((word.posDe as String).isNotEmpty) ...[
                        SizedBox(height: soriFillSize(h, 0.014, 4, 12)),
                        Text(
                          word.posDe,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: soriFillSize(h, 0.05, 13, 30),
                            color: Colors.black54,
                          ),
                        ),
                      ],
                    ],
                  ),
                  // 예문(한국어 + 번역)을 한 묶음으로 — 탭하면 예문 발음,
                  // 길게 누르면 느리게 (인라인 스피커 아이콘이 affordance).
                  if ((word.exampleKorean as String).isNotEmpty)
                    SoriPressable(
                      haptic: SoriHaptic.light,
                      onTap: () {
                        // ignore: discarded_futures
                        TtsService.speak(word.exampleKorean);
                      },
                      onLongPress: () {
                        // ignore: discarded_futures
                        TtsService.speakSlow(word.exampleKorean);
                      },
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text.rich(
                            TextSpan(
                              children: [
                                WidgetSpan(
                                  alignment: PlaceholderAlignment.middle,
                                  child: Icon(
                                    Icons.volume_up_rounded,
                                    size: soriFillSize(h, 0.055, 16, 26),
                                    color: SoriColors.primary,
                                  ),
                                ),
                                const WidgetSpan(child: SizedBox(width: 6)),
                                TextSpan(text: word.exampleKorean),
                              ],
                            ),
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: soriFillSize(h, 0.078, 16, 40),
                              fontWeight: FontWeight.w600,
                              height: 1.25,
                            ),
                          ),
                          if ((word.exampleDe as String).isNotEmpty) ...[
                            SizedBox(height: soriFillSize(h, 0.012, 4, 14)),
                            Text(
                              word.exampleDe,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: soriFillSize(h, 0.05, 13, 30),
                                color: Colors.black54,
                                fontStyle: FontStyle.italic,
                                height: 1.3,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
