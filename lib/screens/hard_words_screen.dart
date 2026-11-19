import '../data/canonical_companion_art.dart';
import 'package:flutter/material.dart';

import '../l10n/generated/app_localizations.dart';
import '../models/vocab.dart';
import '../motion/transitions.dart';
import '../services/liked_content_service.dart';
import '../services/review_deck_service.dart';
import '../services/storage_service.dart';
import '../services/tts_service.dart';
import '../widgets/app_error.dart';
import '../widgets/app_loading.dart';
import '../widgets/sori/button.dart';
import '../widgets/sori/card.dart';
import '../widgets/sori/empty_state.dart';
import '../widgets/sori/mascot.dart';
import '../widgets/sori/screen_coach.dart';
import '../widgets/sori/section_header.dart';
import '../widgets/sori/spotlight_coach.dart';
import '../widgets/sori/standard_page.dart';
import '../widgets/sori/tokens.dart';
import '../widgets/sori/tts_speed_control.dart';
import '../widgets/sori/viewport_pages.dart';
import 'hard_choice_quiz_screen.dart';
import 'review_session_screen.dart';

/// A2 (암기 엔진) — "어려운 단어" 모음.
///
/// 반복해도 안 외워지는 단어(leech)를 SRS 데이터에서 자동 추출해 모아 보여주고,
/// "집중 복습"으로 그 단어들만 묶어 복습 세션을 돌린다. CSV·나만의 단어장·책 한 컷
/// 단어 모두 대상.
class HardWordsScreen extends StatelessWidget {
  /// 테스트용 — 복습 풀 로더 주입 (기본: [ReviewDeckService.allReviewable]).
  final Future<List<Vocab>> Function()? deckLoader;

  const HardWordsScreen({super.key, this.deckLoader});

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);
    return SoriStandardFrame(
      appBarTitle: t.hardWordsTitle,
      actions: const [TtsSpeedAction()],
      particles: true,
      padding: const EdgeInsets.fromLTRB(
        Spacing.lg,
        Spacing.md,
        Spacing.lg,
        Spacing.xxl,
      ),
      builder: (context, padding) =>
          HardWordsBody(deckLoader: deckLoader, padding: padding),
    );
  }
}

/// Difficult-word content that can be hosted by a route frame or a tab hub.
class HardWordsBody extends StatefulWidget {
  const HardWordsBody({
    super.key,
    this.deckLoader,
    this.paged = false,
    this.padding = const EdgeInsets.fromLTRB(
      Spacing.lg,
      Spacing.md,
      Spacing.lg,
      Spacing.xxl,
    ),
  });

  final Future<List<Vocab>> Function()? deckLoader;
  final EdgeInsets padding;
  final bool paged;

  @override
  State<HardWordsBody> createState() => _HardWordsBodyState();
}

class _HardWordsBodyState extends State<HardWordsBody>
    with ScreenCoachMixin<HardWordsBody> {
  bool _loading = true;
  bool _loadFailed = false;
  List<Vocab> _hard = const [];
  // 지시서 1.6 룰링(Fable): Schwierig 탭 = 자동 산출(leech/오답) ∪ 하트한
  // 단어. 두 출처를 따로 들고 있다가 렌더링에서만 섹션 헤더로 나눠 보여준다
  // — _hard 자체는(퀴즈/집중복습 CTA 가 쓰는) 합집합 그대로 유지한다.
  List<Vocab> _hardAuto = const [];
  List<Vocab> _hardLiked = const [];

  // ── 코치마크 타겟 ──
  final GlobalKey _listKey = GlobalKey();

  @override
  String get coachId => 'hardWords';

  @override
  bool get coachReady => !_loading && _hard.isNotEmpty;

  @override
  List<SpotlightStep> buildCoachSteps(BuildContext context) {
    final t = AppL10n.of(context);
    return [
      SpotlightStep(
        targetKey: _listKey,
        title: t.coachHardWordsTitle,
        body: t.coachHardWordsBody,
        icon: Icons.bolt_rounded,
      ),
    ];
  }

  @override
  void initState() {
    super.initState();
    _load();
    scheduleCoach();
  }

  Future<void> _load({bool showLoading = false}) async {
    if (showLoading && mounted) {
      setState(() {
        _loading = true;
        _loadFailed = false;
      });
    }
    List<Vocab> hardAuto = const [];
    List<Vocab> hardLiked = const [];
    var loadFailed = false;
    try {
      final all =
          await (widget.deckLoader ?? ReviewDeckService.allReviewable)();
      // Extra-Lernset = SRS leech 휴리스틱 ∪ 명시적 오답 3회+ (레벨 불문).
      // 오답 카운터는 즉시 반응하므로 한 세션에서 3번 틀린 단어도 바로 잡힌다
      // (2026-08-13 테스터 피드백 ③).
      final autoIds = {
        ...Storage.hardIds(all.map((v) => v.korean)),
        ...Storage.frequentlyMissedIds(all.map((v) => v.korean)),
      };
      hardAuto = all.where((v) => autoIds.contains(v.korean)).toList();
      // 지시서 1.6 룰링: Schwierig 탭에 하트한 단어도 포함한다.
      // LikedContentService.vocab 종류의 id 는 legacy_vocab/review_session/
      // vocab_pack/custom_pack_play 의 _likeCurrent 가 전부 word.korean 을
      // 그대로 쓰므로, 여기서도 같은 키로 안전하게 대조할 수 있다(스키마
      // 변경 불필요).
      final likedVocabIds = {
        for (final item in LikedContentService.all())
          if (item.kind == LikedContentService.vocab) item.id,
      };
      hardLiked = all
          .where(
            (v) =>
                likedVocabIds.contains(v.korean) && !autoIds.contains(v.korean),
          )
          .toList();
    } catch (_) {
      loadFailed = true;
    }
    if (!mounted) return;
    setState(() {
      _hardAuto = hardAuto;
      _hardLiked = hardLiked;
      _hard = [...hardAuto, ...hardLiked];
      _loading = false;
      _loadFailed = loadFailed;
    });
  }

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);
    final inlineActions =
        MediaQuery.textScalerOf(context).scale(1) >= 1.6 ||
        MediaQuery.sizeOf(context).height < 700;
    final practiceActions = [
      SoriButton(
        label: t.hardWordsHardQuizCta,
        variant: SoriButtonVariant.filled,
        accent: SoriColors.danger,
        fullWidth: true,
        onTap: () async {
          await Navigator.of(context).push(
            SoriTransitions.page(
              (_) => HardChoiceQuizScreen(deck: _hard, title: t.hardQuizTitle),
            ),
          );
          if (mounted) {
            // ignore: discarded_futures
            _load();
          }
        },
      ),
      SoriButton(
        label: t.hardWordsStudyCta,
        icon: Icons.bolt_rounded,
        variant: SoriButtonVariant.outlined,
        fullWidth: true,
        onTap: () async {
          await Navigator.of(context).push(
            SoriTransitions.page(
              (_) => ReviewSessionScreen(
                deck: _hard,
                title: t.hardWordsTitle,
                feedbackContentId: 'hard_words',
                feedbackContentLabel: t.hardWordsTitle,
              ),
            ),
          );
          if (mounted) {
            // ignore: discarded_futures
            _load();
          }
        },
      ),
    ];
    final actionBlock = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        practiceActions.first,
        const SizedBox(height: Spacing.sm),
        practiceActions.last,
      ],
    );

    final padding = widget.padding;
    if (_loading) {
      return const AppLoading();
    }
    if (_loadFailed) {
      return AppError(
        message: t.loadErrorTryAgain,
        messageLiveRegion: true,
        onRetry: () => _load(showLoading: true),
      );
    }
    if (_hard.isEmpty && widget.paged) {
      final type = SoriTextTheme.of(context);
      return Padding(
        padding: EdgeInsets.fromLTRB(
          padding.left,
          padding.top,
          padding.right,
          Spacing.lg,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: SoriViewportPages(
                sections: [
                  Text(t.hardWordsEmptyTitle, style: type.h2),
                  const SizedBox(height: Spacing.sm),
                  Text(
                    t.hardWordsEmptyBody,
                    style: _hardWordBodyStyle(context),
                  ),
                  const Mascot.magpie(
                    emotion: MascotEmotion.celebrate,
                    size: 80,
                    animate: false,
                  ),
                ],
              ),
            ),
            const SizedBox(height: Spacing.sm),
            SoriButton.filled(
              label: t.btnClose,
              onTap: () => Navigator.of(context).maybePop(),
            ),
          ],
        ),
      );
    }
    if (_hard.isEmpty) {
      return Center(
        child: Padding(
          padding: padding,
          child: SoriEmptyState(
            asset: CanonicalCompanionArt.magpieCelebrate,
            icon: Icons.emoji_events_outlined,
            title: t.hardWordsEmptyTitle,
            body: t.hardWordsEmptyBody,
            ctaLabel: t.btnClose,
            onCta: () => Navigator.of(context).maybePop(),
          ),
        ),
      );
    }

    final header = Row(
      children: [
        const Mascot.tiger(
          emotion: MascotEmotion.thinking,
          size: 72,
          animate: false,
        ),
        const SizedBox(width: Spacing.md),
        Expanded(
          child: Text(
            t.hardWordsSubtitle(_hard.length),
            style: SoriTextTheme.of(context).bodySmall,
          ),
        ),
      ],
    );
    if (widget.paged) {
      return Padding(
        padding: EdgeInsets.fromLTRB(
          padding.left,
          padding.top,
          padding.right,
          Spacing.lg,
        ),
        child: LayoutBuilder(
          builder: (context, constraints) => Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: LayoutBuilder(
                  builder: (context, body) => SoriViewportPages(
                    key: _listKey,
                    sections: [
                      if (body.maxHeight >= 260)
                        header
                      else
                        Text(
                          t.hardWordsSubtitle(_hard.length),
                          style: _hardWordBodyStyle(context),
                        ),
                      const SizedBox(height: Spacing.sm),
                      ..._sectionedTiles(t, body: body),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: Spacing.sm),
              if (constraints.maxHeight < 420)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: practiceActions.first),
                    const SizedBox(width: Spacing.sm),
                    Expanded(child: practiceActions.last),
                  ],
                )
              else
                actionBlock,
            ],
          ),
        ),
      );
    }
    if (inlineActions) {
      return ListView(
        key: _listKey,
        padding: padding,
        children: [
          header,
          const SizedBox(height: Spacing.sm),
          ..._sectionedTiles(t),
          const SizedBox(height: Spacing.md),
          actionBlock,
        ],
      );
    }
    return Column(
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(
            padding.left,
            padding.top,
            padding.right,
            Spacing.sm,
          ),
          child: header,
        ),
        Expanded(
          child: ListView(
            key: _listKey,
            padding: EdgeInsets.fromLTRB(
              padding.left,
              0,
              padding.right,
              padding.bottom,
            ),
            children: _sectionedTiles(t),
          ),
        ),
        SoriBottomActionArea(child: actionBlock),
      ],
    );
  }

  /// 자동 산출 ∪ 하트한 단어 타일들. 두 출처가 실제로 섞일 때만(하트한
  /// 단어가 있을 때만) 섹션 헤더 2개로 나눠 보여준다 — 하트한 단어가 없으면
  /// 지금까지와 동일하게 헤더 없이 자동 목록만 보인다.
  List<Widget> _sectionedTiles(AppL10n t, {BoxConstraints? body}) {
    if (_hardLiked.isEmpty) {
      return [
        for (final word in _hardAuto) ...[
          ..._wordSections(word, body),
          const SizedBox(height: Spacing.xs),
        ],
      ];
    }
    return [
      if (_hardAuto.isNotEmpty) ...[
        SoriSectionHeader(t.hardWordsSectionAuto),
        for (final word in _hardAuto) ...[
          ..._wordSections(word, body),
          const SizedBox(height: Spacing.xs),
        ],
      ],
      SoriSectionHeader(t.hardWordsSectionLiked),
      for (final word in _hardLiked) ...[
        ..._wordSections(word, body),
        const SizedBox(height: Spacing.xs),
      ],
    ];
  }

  Iterable<Widget> _wordSections(Vocab word, BoxConstraints? body) sync* {
    if (body == null) {
      yield _HardWordTile(word: word);
      return;
    }
    final style = _hardWordBodyStyle(context);
    final language = Localizations.localeOf(context).languageCode;
    final meaning = word.translationFor(language);
    final available = body.maxHeight - SoriViewportPages.controlsHeight;
    final titleStyle = SoriTextTheme.of(context).h3;
    final textWidth = (body.maxWidth - Spacing.xl - 48).clamp(
      1.0,
      double.infinity,
    );
    final titlePages = soriViewportTextPages(
      context,
      word.korean,
      style: titleStyle,
      width: textWidth,
      height: (available * .45).clamp(1.0, double.infinity),
    );
    final translationPages = soriViewportTextPages(
      context,
      meaning,
      style: style,
      width: textWidth,
      height: (available * .55 - Spacing.lg).clamp(1.0, double.infinity),
    );
    final summary = titlePages.length > 1 || translationPages.length > 1;
    yield _HardWordTile(word: word, summary: summary, paged: true);
    if (summary) {
      for (final (text, textStyle) in [
        if (titlePages.length > 1) (word.korean, titleStyle),
        if (meaning.isNotEmpty) (meaning, style),
      ]) {
        for (final page in soriViewportTextPages(
          context,
          text,
          style: textStyle,
          width: (body.maxWidth - Spacing.xl).clamp(1.0, double.infinity),
          height: (available - Spacing.xl).clamp(1.0, double.infinity),
        )) {
          yield SoriCard(
            padding: const EdgeInsets.all(Spacing.md),
            child: Text(page, style: textStyle),
          );
        }
      }
    }
  }
}

TextStyle _hardWordBodyStyle(BuildContext context) {
  final style = SoriTextTheme.of(context).body;
  return Theme.of(context).platform == TargetPlatform.iOS
      ? style.copyWith(fontSize: 17)
      : style;
}

class _HardWordTile extends StatelessWidget {
  const _HardWordTile({
    required this.word,
    this.summary = false,
    this.paged = false,
  });

  final Vocab word;
  final bool summary;
  final bool paged;

  @override
  Widget build(BuildContext context) {
    final s = SoriSurfaces.of(context);
    final t = AppL10n.of(context);
    final languageCode = Localizations.localeOf(context).languageCode;
    final translation = word.translationFor(languageCode);
    final ttsLabel = '${t.ttsListen}: ${word.korean}';
    void speak() {
      // ignore: discarded_futures
      TtsService.speak(word.korean);
    }

    return SoriCard(
      accent: SoriColors.danger,
      padding: const EdgeInsets.symmetric(
        horizontal: Spacing.md,
        vertical: Spacing.sm,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  word.korean,
                  style: SoriTextTheme.of(context).h3,
                  maxLines: summary ? 1 : null,
                  overflow: summary ? TextOverflow.ellipsis : null,
                ),
                if (!summary && translation.isNotEmpty)
                  Text(
                    translation,
                    style:
                        (paged
                                ? _hardWordBodyStyle(context)
                                : SoriTextTheme.of(context).bodySmall)
                            .copyWith(color: s.textMuted),
                  ),
              ],
            ),
          ),
          Semantics(
            container: true,
            button: true,
            enabled: true,
            label: ttsLabel,
            onTap: speak,
            excludeSemantics: true,
            child: IconButton(
              tooltip: ttsLabel,
              constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
              icon: const Icon(
                Icons.volume_up_rounded,
                color: SoriColors.primary,
              ),
              onPressed: speak,
            ),
          ),
        ],
      ),
    );
  }
}
