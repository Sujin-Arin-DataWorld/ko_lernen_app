import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/hanja_lexicon.dart';
import '../l10n/generated/app_localizations.dart';
import '../models/book_page.dart';
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
import '../widgets/sori/content_feed.dart';
import '../widgets/sori/deck_coach.dart';
import '../services/content_share_service.dart';
import '../services/liked_content_service.dart';
import '../widgets/sori/content_feedback_card.dart';
import '../widgets/sori/empty_state.dart';
import '../widgets/sori/mascot.dart';
import '../widgets/sori/pressable.dart';
import '../widgets/sori/responsive.dart';
import '../widgets/sori/screen_coach.dart';
import '../widgets/sori/scroll_if_needed.dart';
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
  final List<ExtractedWord>? words;
  const CustomPackPlayScreen({super.key, required this.packId, this.words});

  @override
  State<CustomPackPlayScreen> createState() => _CustomPackPlayScreenState();
}

class _CustomPackPlayScreenState extends State<CustomPackPlayScreen>
    with ScreenCoachMixin<CustomPackPlayScreen> {
  CustomPack? _pack;
  int _idx = 0;
  bool _flipped = false;
  // 앞면으로 다시 돌아와도 이 카드의 답을 이미 본 사실은 유지한다.
  // 판정/스킵으로 다음 카드가 서빙될 때만 초기화한다.
  bool _cardRevealed = false;
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
    final pack = CustomPackService.getById(widget.packId);
    _pack = pack == null || widget.words == null
        ? pack
        : pack.copyWith(words: widget.words);
    scheduleCoach();
  }

  // §P2-5 플립 게이트 힌트 칩 트리거.
  final ValueNotifier<int> _flipHintTrigger = ValueNotifier<int>(0);

  @override
  void dispose() {
    _flipHintTrigger.dispose();
    super.dispose();
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

  /// §P2-2 개명: 옛 `_skip` — 이름과 달리 **완전한 음성 판정**이다
  /// (srsReview(gotIt:false) + incrementWrongCount). 라벨도 btnNichtGewusst
  /// 로 정정 (기존 btnSkip 오표기).
  void _dontKnow() {
    HapticFeedback.selectionClick();
    final pack = _pack;
    if (pack != null) {
      // A1: 모른 단어 → SRS 간격 짧게 리셋 (내일 다시).
      Storage.srsReview(pack.words[_idx].korean, gotIt: false);
      // ignore: discarded_futures
      Storage.incrementWrongCount(pack.words[_idx].korean);
    }
    _advance();
  }

  /// ↓ 스킵 (§P2-2) — **기록 없는 전진**. `_advance` 는 완료 슬롯 외 아무
  /// 기록도 남기지 않는 무기록 경로다.
  void _defer() {
    HapticFeedback.selectionClick();
    _advance();
  }

  Future<void> _likeCurrent() async {
    final pack = _pack;
    if (pack == null || _idx >= pack.words.length) {
      return;
    }
    await LikedContentService.toggle(
      kind: LikedContentService.vocab,
      id: pack.words[_idx].korean,
    );
    if (mounted) {
      setState(() {});
    }
  }

  void _shareCurrent() {
    final pack = _pack;
    if (pack == null || _idx >= pack.words.length) {
      return;
    }
    final w = pack.words[_idx];
    final t = AppL10n.of(context);
    // ignore: discarded_futures
    ContentShareService.shareStorySlip(
      korean: w.korean,
      gloss: w.translationDe,
      caption: t.contentShareBody(w.korean, w.translationDe),
    );
  }

  void _advance() {
    final pack = _pack;
    if (pack == null) return;
    setState(() {
      _flipped = false;
      _cardRevealed = false;
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

  void _toggleFlip() {
    HapticFeedback.selectionClick();
    setState(() {
      if (!_flipped) {
        _cardRevealed = true;
      }
      _flipped = !_flipped;
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

    // §P2-5: 4방향 덱 코치 — 기존 cpPlay 코치가 이미 표시된 뒤에만 (겹침 방지).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        maybeShowSoriDeckCoach(
          context,
          targetKey: _cardKey,
          afterCoachIds: const ['cpPlay'],
          supportsSave: false,
        );
      }
    });

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
                  child: SoriContentFeed(
                    judgmentsEnabled: _cardRevealed,
                    onBlockedJudgment: () => _flipHintTrigger.value++,
                    flipHintTrigger: _flipHintTrigger,
                    onNext: _gotIt,
                    onHard: _dontKnow,
                    onSkip: _defer,
                    onLike: _likeCurrent,
                    onShare: _shareCurrent,
                    onFlip: _toggleFlip,
                    showBookmark: false,
                    liked: LikedContentService.isLiked(
                      kind: LikedContentService.vocab,
                      id: w.korean,
                    ),
                    underlay: _idx + 1 < pack.words.length
                        ? _faceSlot(pack, pack.words[_idx + 1])
                        : null,
                    knowLabel: t.btnGewusst,
                    hardLabel: t.btnNichtGewusst,
                    skipLabel: t.btnSkip,
                    child: Center(
                      child: FractionallySizedBox(
                        heightFactor: 0.82,
                        child: SizedBox(
                          key: const ValueKey('deck-card-slot'),
                          width: double.infinity,
                          child: SoriStudyScale(
                            child: KeyedSubtree(
                              key: _cardKey,
                              child: FlipCard(
                                key: ValueKey('cp-$_serve'),
                                flipped: _flipped,
                                onTap: _toggleFlip,
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
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// 덱 스택 underlay 용 앞면 슬롯 — 본 카드와 동일한 지오메트리 경로.
  Widget _faceSlot(CustomPack pack, dynamic word) {
    return Center(
      child: FractionallySizedBox(
        heightFactor: 0.82,
        child: SizedBox(
          width: double.infinity,
          child: SoriStudyScale(
            child: _Front(
              word: word,
              deckKoreans: [for (final x in pack.words) x.korean],
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
                    _cardRevealed = false;
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
      // P1 이중 안전벨트: 슬롯 핀과 별개로 카드 자체도 항상 가용폭을 채운다.
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
            physics: kSoriCardFacePhysics,
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
                        fontWeight: FontWeight.w700,
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
      // P1 이중 안전벨트 — _Front 와 동일 계약.
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
            physics: kSoriCardFacePhysics,
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
                          fontWeight: FontWeight.w700,
                          height: 1.15,
                        ),
                      ),
                      if ((HanjaLexicon.lookup(word.korean as String)?.hanja ??
                              '')
                          .isNotEmpty) ...[
                        SizedBox(height: soriFillSize(h, 0.012, 4, 10)),
                        Text(
                          HanjaLexicon.lookup(word.korean as String)!.hanja,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: soriFillSize(h, 0.05, 13, 24),
                            fontWeight: FontWeight.w700,
                            color: SoriColors.goldOnLight,
                          ),
                        ),
                      ],
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
