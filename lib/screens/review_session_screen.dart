import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../l10n/generated/app_localizations.dart';
import '../models/smalltalk.dart';
import '../models/vocab.dart';
import '../services/review_deck_service.dart';
import '../services/tts_service.dart';
import '../services/storage_service.dart';
import '../widgets/app_loading.dart';
import '../widgets/sori/button.dart';
import '../widgets/sori/card.dart';
import '../widgets/sori/celebration.dart';
import '../widgets/sori/empty_state.dart';
import '../widgets/sori/mascot.dart';
import '../widgets/sori/pressable.dart';
import '../widgets/sori/screen_background.dart';
import '../widgets/sori/screen_coach.dart';
import '../widgets/sori/spotlight_coach.dart';
import '../widgets/sori/tokens.dart';
import '../widgets/sori/responsive.dart';
import '../widgets/sori/wordbook_add.dart';

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

  /// M5: optionaler Small-talk-Satz, der am Kursende als "한마디" gezeigt wird.
  final SmalltalkPhrase? bonusPhrase;
  const ReviewSessionScreen({
    super.key,
    this.deck,
    this.title,
    this.bonusPhrase,
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

  void _answer(bool gotIt) {
    // 답변 순간 촉각 피드백 — 맞으면 강하게, 틀리면 가볍게.
    gotIt ? HapticFeedback.mediumImpact() : HapticFeedback.lightImpact();
    Storage.srsReview(_card.korean, gotIt: gotIt);
    _reviewed++;
    if (_idx + 1 >= _deck.length) {
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
          child: SoriCenterClamp(
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
    icon: Icons.task_alt_rounded,
    title: t.reviewEmptyTitle,
    body: t.reviewEmptyBody,
    ctaLabel: t.btnClose,
    onCta: () => Navigator.of(context).maybePop(),
  );

  Widget _buildDone(AppL10n t, SoriSurfaces s) {
    final tt = SoriTextTheme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(Spacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Mascot.tiger(
              size: 120,
              emotion: MascotEmotion.celebrate,
              animate: true,
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
                // 카드는 글자 수와 무관하게 영역의 고정 비율(82%) 높이를 유지한다
                // (단어가 짧아도 쪼그라들지 않음). 남는 위/아래 여백이 코치마크
                // 말풍선·버튼 공간이 되어 잘림을 막는다.
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
                      height: cardH,
                      child: SoriCard(
                        variant: SoriCardVariant.hero,
                        accent: SoriColors.primary,
                        tinted: !_flipped,
                        child: LayoutBuilder(
                          builder: (context, cc) => SingleChildScrollView(
                            child: ConstrainedBox(
                              constraints: BoxConstraints(
                                minHeight: cc.maxHeight,
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: _flipped
                                    ? _backList(card, s, tt, t)
                                    : _frontList(card, s, tt, t),
                              ),
                            ),
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

  List<Widget> _frontList(
    Vocab v,
    SoriSurfaces s,
    SoriTextTheme tt,
    AppL10n t,
  ) => [
    Text(
      v.korean,
      textAlign: TextAlign.center,
      style: const TextStyle(
        fontFamily: 'Pretendard',
        fontSize: 40,
        fontWeight: FontWeight.w900,
      ),
    ),
    const SizedBox(height: Spacing.md),
    _SpeakButton(text: v.korean, label: t.ttsListen),
    if (v.romanization.isNotEmpty) ...[
      const SizedBox(height: Spacing.sm),
      Text(v.romanization, style: tt.body.copyWith(color: s.textMuted)),
    ],
    const SizedBox(height: Spacing.lg),
    Text(t.hintTapToFlip, style: tt.caption.copyWith(color: s.textDim)),
  ];

  List<Widget> _backList(Vocab v, SoriSurfaces s, SoriTextTheme tt, AppL10n t) {
    final lang = Localizations.localeOf(context).languageCode;
    return [
      Text(
        v.translationFor(lang),
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontFamily: 'Pretendard',
          fontSize: 26,
          fontWeight: FontWeight.w800,
        ),
      ),
      if (v.exampleKorean.isNotEmpty) ...[
        const SizedBox(height: Spacing.lg),
        Text(v.exampleKorean, textAlign: TextAlign.center, style: tt.body),
        const SizedBox(height: Spacing.sm),
        _SpeakButton(text: v.exampleKorean, label: t.ttsListen, size: 22),
      ],
      if (v.exampleGerman.isNotEmpty) ...[
        const SizedBox(height: Spacing.xs),
        Text(
          v.exampleFor(lang),
          textAlign: TextAlign.center,
          style: tt.bodySmall.copyWith(color: s.textMuted),
        ),
      ],
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
