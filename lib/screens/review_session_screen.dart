import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../l10n/generated/app_localizations.dart';
import '../models/feedback_completion.dart';
import '../models/smalltalk.dart';
import '../models/vocab.dart';
import '../services/review_deck_service.dart';
import '../services/tts_service.dart';
import '../services/culture_notes_service.dart';
import '../widgets/sori/culture_note_card.dart';
import '../widgets/sori/mascot_preference.dart';
import '../services/storage_service.dart';
import '../widgets/app_loading.dart';
import '../widgets/sori/button.dart';
import '../widgets/sori/card.dart';
import '../widgets/sori/celebration.dart';
import '../widgets/sori/character_clip.dart';
import '../widgets/sori/content_feedback_card.dart';
import '../widgets/sori/empty_state.dart';
import '../widgets/sori/mascot.dart';
import '../widgets/sori/pressable.dart';
import '../widgets/sori/screen_background.dart';
import '../widgets/sori/screen_coach.dart';
import '../widgets/sori/spotlight_coach.dart';
import '../widgets/sori/tokens.dart';
import '../widgets/sori/responsive.dart';
import '../widgets/sori/wordbook_add.dart';

String? unambiguousReviewLevel(Iterable<String> deckLevels) {
  const supported = {'A1', 'A2', 'B1', 'B2'};
  final levels = deckLevels.map((level) => level.trim().toUpperCase()).toSet();
  if (levels.length != 1 || !supported.contains(levels.single)) return null;
  return levels.single;
}

/// **Review Session (M2)** — "Heute lernen / 오늘의 학습".
///
/// Zieht die heute fälligen + neuen SRS-Karten (`Storage.todayGoalIds`) und
/// lässt sie als Flip-Karten wiederholen. Jede Antwort speist das SRS
/// (`Storage.srsReview`). So schließt sich der Lern-Loop: Spiele & Packs füllen
/// das SRS, hier wird es abgearbeitet.
class ReviewSessionScreen extends StatefulWidget {
  /// Optionaler vorgegebener Deck (M5: personalisierter Tageskurs). Null →
  /// lädt selbst die heute fälligen SRS-Karten (Standard "Heute lernen").
  final List<Vocab>? deck;
  final String? title;
  final String feedbackContentId;
  final String? feedbackContentLabel;

  /// M5: optionaler Small-talk-Satz, der am Kursende als "한마디" gezeigt wird.
  final SmalltalkPhrase? bonusPhrase;
  const ReviewSessionScreen({
    super.key,
    this.deck,
    this.title,
    this.bonusPhrase,
    this.feedbackContentId = 'today_review',
    this.feedbackContentLabel,
  });

  @override
  State<ReviewSessionScreen> createState() => _ReviewSessionScreenState();
}

class _ReviewSessionScreenState extends State<ReviewSessionScreen>
    with ScreenCoachMixin<ReviewSessionScreen> {
  bool _loading = true;
  List<Vocab> _deck = [];
  int _idx = 0;
  bool _flipped = false;
  int _reviewed = 0;
  bool _done = false;
  final FeedbackCompletionSlot _feedbackCompletion = FeedbackCompletionSlot();

  // ── 코치마크 타겟 ──
  final GlobalKey _cardKey = GlobalKey();
  final GlobalKey _answerRowKey = GlobalKey();

  @override
  String get coachId => 'review';

  @override
  bool get coachReady => !_loading && _deck.isNotEmpty && !_done;

  @override
  List<SpotlightStep> buildCoachSteps(BuildContext context) {
    final t = AppL10n.of(context);
    return [
      SpotlightStep(
        targetKey: _cardKey,
        title: t.coachReviewStep1Title,
        body: t.coachReviewStep1Body,
        icon: Icons.flip_rounded,
      ),
      SpotlightStep(
        targetKey: _answerRowKey,
        title: t.coachReviewStep2Title,
        body: t.coachReviewStep2Body,
        icon: Icons.thumbs_up_down_rounded,
      ),
    ];
  }

  @override
  void initState() {
    super.initState();
    _load();
    scheduleCoach();
    // K-Culture 노트 로드 후 카드 반영.
    CultureNotesService.load().then((_) {
      if (mounted) {
        setState(() {});
      }
    });
  }

  Future<void> _load() async {
    // M5: vorgegebener personalisierter Deck hat Vorrang.
    if (widget.deck != null) {
      setState(() {
        _deck = widget.deck!;
        _loading = false;
      });
      return;
    }
    List<Vocab> deck = [];
    try {
      // A1: CSV + 나만의 단어장 + 책 한 컷 단어를 모두 포함 (한국어 기준 dedup).
      final vocab = await ReviewDeckService.allReviewable();
      // todayGoalIds liefert neue + fällige Karten (gedeckelt). Reihenfolge wie
      // Pool → kuratiert. Filtern erhält diese Reihenfolge.
      final goal = Storage.todayGoalIds(vocab.map((v) => v.korean)).toSet();
      deck = vocab.where((v) => goal.contains(v.korean)).toList();
    } catch (_) {
      // Laden fehlgeschlagen → Empty-State (kein Crash).
    }
    if (!mounted) return;
    setState(() {
      _deck = deck;
      _loading = false;
    });
  }

  Vocab get _card => _deck[_idx];

  String? get _unambiguousDeckLevel {
    return unambiguousReviewLevel(_deck.map((word) => word.level));
  }

  void _answer(bool gotIt) {
    // 답변 순간 촉각 피드백 — 맞으면 강하게, 틀리면 가볍게.
    gotIt ? HapticFeedback.mediumImpact() : HapticFeedback.lightImpact();
    Storage.srsReview(_card.korean, gotIt: gotIt);
    _reviewed++;
    if (_idx + 1 >= _deck.length) {
      _feedbackCompletion.complete(
        () => FeedbackCompletion.review(
          contentId: widget.feedbackContentId,
          contentLabel:
              widget.feedbackContentLabel ??
              widget.title ??
              AppL10n.of(context).reviewTitle,
          level: _unambiguousDeckLevel,
          reviewed: _reviewed,
          total: _deck.length,
        ),
      );
      Storage.addXp(_reviewed * 2);
      setState(() => _done = true);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) SoriCelebration.burst(context);
      });
    } else {
      setState(() {
        _idx++;
        _flipped = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);
    final s = SoriSurfaces.of(context);

    return Scaffold(
      backgroundColor: s.bg,
      appBar: AppBar(
        title: Text(
          widget.title ?? t.reviewTitle,
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        actions: [
          // 오늘의 복습 카드를 바로 내 단어장에 담기 (item 11).
          if (!_loading && _deck.isNotEmpty && !_done)
            AddToWordbookButton(
              korean: _card.korean,
              translationDe: _card.german,
              romanization: _card.romanization,
              posDe: _card.posDe,
              exampleKorean: _card.exampleKorean,
              exampleDe: _card.exampleGerman,
              compact: true,
            ),
        ],
      ),
      body: SoriScreenBackground(
        child: SafeArea(
          child: SoriStudyClamp(
            child: _loading
                ? const AppLoading()
                : _deck.isEmpty
                ? _buildEmpty(t)
                : _done
                ? _buildDone(t, s)
                : _buildCard(t, s),
          ),
        ),
      ),
    );
  }

  Widget _buildEmpty(AppL10n t) => SoriEmptyState(
    asset: 'assets/illustrations/mascot/magpie_celebrate.png',
    icon: Icons.task_alt_rounded,
    title: t.reviewEmptyTitle,
    body: t.reviewEmptyBody,
    ctaLabel: t.btnClose,
    onCta: () => Navigator.of(context).maybePop(),
  );

  Widget _buildDone(AppL10n t, SoriSurfaces s) {
    final tt = SoriTextTheme.of(context);
    final feedbackScope = ContentFeedbackControllerScope.maybeOf(context);
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(Spacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 세션 완료 = 기지개 클립 (배치 계획 §2-11). 폴백은 기존 celebrate.
            CharacterClipPlayer(
              asset: CharacterClips.sessionCompleteFor(
                MascotPreference.kind.value,
              ),
              size: 120,
              // 뒤에 깔린 건 Scaffold 색이 아니라 SoriScreenBackground 의
              // HanjiTexture 베이스 워시(HanokColors.hanjiCream = #FAF6EC)다.
              // 팔레트와 무관한 상수라 s.bg / scaffoldBackgroundColor 가 아니라
              // 같은 상수(SoriColors.lightBg)로 맞춘다 — home_screen 히어로와
              // 동일한 근거. (한지 결 자체는 평면이 아니라 완전 무이음은 불가.)
              blendColor: SoriColors.lightBg,
              fallbackEmotion: MascotEmotion.celebrate,
            ),
            const SizedBox(height: Spacing.lg),
            Text(t.reviewDoneTitle, textAlign: TextAlign.center, style: tt.h1),
            const SizedBox(height: Spacing.sm),
            Text(
              t.reviewDoneBody,
              textAlign: TextAlign.center,
              style: tt.body.copyWith(color: s.textMuted),
            ),
            const SizedBox(height: Spacing.md),
            Text(
              '+${_reviewed * 2} XP',
              style: tt.h2.copyWith(color: SoriColors.gold),
            ),
            // M5: "한마디" — interessen-passender Small-talk-Satz als Bonus.
            if (widget.bonusPhrase != null) ...[
              const SizedBox(height: Spacing.xl),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(Spacing.md),
                decoration: BoxDecoration(
                  color: SoriColors.highlight.withValues(alpha: 0.10),
                  borderRadius: SoriRadius.brMd,
                ),
                child: Column(
                  children: [
                    Text(
                      t.reviewBonusLabel,
                      style: tt.label.copyWith(color: SoriColors.highlight),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      widget.bonusPhrase!.ko,
                      textAlign: TextAlign.center,
                      style: tt.h3,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      widget.bonusPhrase!.translation(
                        Localizations.localeOf(context).languageCode,
                      ),
                      textAlign: TextAlign.center,
                      style: tt.bodySmall.copyWith(color: s.textMuted),
                    ),
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: () => TtsService.speak(widget.bonusPhrase!.ko),
                      child: const Icon(
                        Icons.volume_up_rounded,
                        color: SoriColors.highlight,
                        size: 22,
                      ),
                    ),
                  ],
                ),
              ),
            ],
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
            SoriButton.filled(
              label: t.btnClose,
              fullWidth: true,
              onTap: () => Navigator.of(context).maybePop(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCard(AppL10n t, SoriSurfaces s) {
    final card = _card;
    final total = _deck.length;
    final tt = SoriTextTheme.of(context);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            Spacing.lg,
            Spacing.md,
            Spacing.lg,
            0,
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${_idx + 1} / $total',
                    style: tt.label.copyWith(color: s.textMuted),
                  ),
                  Text(
                    card.level,
                    style: tt.label.copyWith(color: SoriColors.primary),
                  ),
                ],
              ),
              const SizedBox(height: Spacing.sm),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: total == 0 ? 0 : _idx / total,
                  minHeight: 6,
                  backgroundColor: s.text.withValues(alpha: 0.08),
                  valueColor: const AlwaysStoppedAnimation(SoriColors.primary),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(Spacing.lg),
            child: LayoutBuilder(
              builder: (context, constraints) {
                // 카드 크기는 **글자 수와 완전히 무관하게** 기기 화면에만 맞춰
                // 고정한다:
                //  · 높이 = 가용 영역의 82% (짧은 단어여도 쪼그라들지 않음, 남는
                //    상하 여백이 코치마크 말풍선·버튼 공간).
                //  · 너비 = 가용 너비 가득(`width: double.infinity`). ⚠️ 이 너비
                //    고정이 없으면 SoriCard 가 세로 스크롤 자식의 콘텐츠 폭에
                //    맞춰 줄어들어(SingleChildScrollView 는 가로 제약을 그대로
                //    통과시킴) "단어 길이에 따라 카드가 커졌다 작아졌다" 하는
                //    회귀가 재발한다. 절대 지우지 말 것.
                // 가용 폭 자체는 SoriCenterClamp 이 기기별로 최적 클램프하므로
                // 기기 최적화 + 콘텐츠 불변이 동시에 성립한다.
                final h = constraints.maxHeight.isFinite
                    ? constraints.maxHeight
                    : 360.0;
                final cardH = h * 0.82;
                return Center(
                  child: SoriPressable(
                    key: _cardKey,
                    onTap: () => setState(() => _flipped = !_flipped),
                    haptic: SoriHaptic.selection,
                    child: SizedBox(
                      width: double.infinity,
                      height: cardH,
                      child: SoriStudyScale(
                        child: SoriCard(
                          variant: SoriCardVariant.hero,
                          accent: SoriColors.primary,
                          tinted: !_flipped,
                          child: LayoutBuilder(
                            builder: (context, cc) {
                              // 카드 안쪽 높이를 폰트·간격의 기준으로 삼는다 →
                              // 텍스트가 카드 크기에 비례해 커지고(기기 무관 균일
                              // 충전율) 세로는 spaceEvenly 로 카드를 채운다. 콘텐츠가
                              // 카드보다 커지는 드문 경우엔 SingleChildScrollView 가
                              // 스크롤로 받아낸다(오버플로 방지, 기존 계약 유지).
                              final ch = cc.maxHeight.isFinite
                                  ? cc.maxHeight
                                  : 360.0;
                              return SingleChildScrollView(
                                child: ConstrainedBox(
                                  constraints: BoxConstraints(
                                    minHeight: cc.maxHeight,
                                  ),
                                  child: Column(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceEvenly,
                                    children: _flipped
                                        ? _backList(card, s, tt, t, ch)
                                        : _frontList(card, s, tt, t, ch),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(
            Spacing.lg,
            0,
            Spacing.lg,
            Spacing.lg,
          ),
          child: Row(
            key: _answerRowKey,
            children: [
              Expanded(
                child: SoriButton.outlined(
                  label: t.btnNichtGewusst,
                  destructive: true,
                  fullWidth: true,
                  onTap: () => _answer(false),
                ),
              ),
              const SizedBox(width: Spacing.md),
              Expanded(
                child: SoriButton.filled(
                  label: t.btnGewusst,
                  fullWidth: true,
                  onTap: () => _answer(true),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // 카드 안쪽 높이 [h] 에 비례한 폰트/간격 크기 — 짧은 값(lo)과 큰 화면 상한(hi)
  // 사이로 클램프. 카드가 커질수록 텍스트도 커져 충전율이 기기와 무관하게 유지된다.
  static double _sz(double h, double frac, double lo, double hi) =>
      (h * frac).clamp(lo, hi).toDouble();

  List<Widget> _frontList(
    Vocab v,
    SoriSurfaces s,
    SoriTextTheme tt,
    AppL10n t,
    double h,
  ) => [
    // 단어 — 카드를 채우는 대형 헤드라인. 긴 단어는 scaleDown 으로 한 줄에 맞춘다.
    FittedBox(
      fit: BoxFit.scaleDown,
      child: Text(
        v.korean,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontFamily: 'Pretendard',
          fontSize: _sz(h, 0.19, 40, 92),
          fontWeight: FontWeight.w900,
          height: 1.05,
        ),
      ),
    ),
    // 듣기 버튼 + 로마자를 한 묶음으로(발음 정보끼리 붙어 있게).
    Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _SpeakButton(
          text: v.korean,
          label: t.ttsListen,
          size: _sz(h, 0.10, 30, 60),
        ),
        if (v.romanization.isNotEmpty) ...[
          SizedBox(height: _sz(h, 0.03, 8, 20)),
          Text(
            v.romanization,
            textAlign: TextAlign.center,
            style: tt.body.copyWith(
              color: s.textMuted,
              fontSize: _sz(h, 0.052, 16, 30),
            ),
          ),
        ],
      ],
    ),
    Text(
      t.hintTapToFlip,
      textAlign: TextAlign.center,
      style: tt.caption.copyWith(
        color: s.textDim,
        fontSize: _sz(h, 0.038, 13, 22),
      ),
    ),
  ];

  List<Widget> _backList(
    Vocab v,
    SoriSurfaces s,
    SoriTextTheme tt,
    AppL10n t,
    double h,
  ) {
    final lang = Localizations.localeOf(context).languageCode;
    return [
      // 뜻 (헤드라인) — 긴 독일어(예: "Entschuldigung (formell)")가 큰 폰트로
      // 3줄 폭주하지 않도록 FittedBox 로 한 줄에 맞춰 축소한다.
      FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(
          v.translationFor(lang),
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: 'Pretendard',
            fontSize: _sz(h, 0.11, 26, 48),
            fontWeight: FontWeight.w800,
            height: 1.1,
          ),
        ),
      ),
      // 예문(한국어 + 듣기 + 번역)을 한 묶음으로 → spaceEvenly 가 흩뜨리지 않는다.
      if (v.exampleKorean.isNotEmpty)
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              v.exampleKorean,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Pretendard',
                fontSize: _sz(h, 0.068, 20, 34),
                fontWeight: FontWeight.w600,
                height: 1.25,
              ),
            ),
            SizedBox(height: _sz(h, 0.03, 8, 20)),
            _SpeakButton(
              text: v.exampleKorean,
              label: t.ttsListen,
              size: _sz(h, 0.075, 24, 48),
            ),
            if (v.exampleFor(lang).isNotEmpty) ...[
              SizedBox(height: _sz(h, 0.04, 12, 24)),
              Text(
                v.exampleFor(lang),
                textAlign: TextAlign.center,
                style: tt.bodySmall.copyWith(
                  color: s.textMuted,
                  fontSize: _sz(h, 0.055, 16, 30),
                  height: 1.3,
                ),
              ),
            ],
          ],
        ),
      // K-Culture 노트 — 노트가 있을 때만 슬롯을 만든다. 없는데도 SizedBox.shrink
      // 를 spaceEvenly 슬롯으로 두면 콘텐츠가 위로 쏠리고 아래가 비어 답답해진다.
      if (CultureNotesService.noteFor(v.korean) != null)
        SizedBox(
          width: double.infinity,
          child: CultureNoteCard(korean: v.korean),
        ),
    ];
  }
}

/// 발음 듣기 버튼 — 카드 탭(뒤집기)과 분리되도록 InkWell 이 탭을 소비한다.
/// 앞면(단어)·뒷면(예문) 양쪽에서 재사용.
class _SpeakButton extends StatelessWidget {
  final String text;
  final String label;
  final double size;
  const _SpeakButton({required this.text, required this.label, this.size = 28});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: Material(
        color: SoriColors.primary.withValues(alpha: 0.12),
        shape: const CircleBorder(),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => TtsService.speak(text),
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Icon(
              Icons.volume_up_rounded,
              color: SoriColors.primary,
              size: size,
            ),
          ),
        ),
      ),
    );
  }
}
