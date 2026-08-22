import 'package:flutter/material.dart';

import '../l10n/generated/app_localizations.dart';
import '../models/vocab.dart';
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
import '../widgets/sori/spotlight_coach.dart';
import '../widgets/sori/standard_page.dart';
import '../widgets/sori/tokens.dart';
import '../widgets/sori/tts_speed_control.dart';
import 'hard_choice_quiz_screen.dart';
import 'review_session_screen.dart';

/// A2 (암기 엔진) — "어려운 단어" 모음.
///
/// 반복해도 안 외워지는 단어(leech)를 SRS 데이터에서 자동 추출해 모아 보여주고,
/// "집중 복습"으로 그 단어들만 묶어 복습 세션을 돌린다. CSV·나만의 단어장·책 한 컷
/// 단어 모두 대상.
class HardWordsScreen extends StatefulWidget {
  /// 테스트용 — 복습 풀 로더 주입 (기본: [ReviewDeckService.allReviewable]).
  final Future<List<Vocab>> Function()? deckLoader;

  const HardWordsScreen({super.key, this.deckLoader});

  @override
  State<HardWordsScreen> createState() => _HardWordsScreenState();
}

class _HardWordsScreenState extends State<HardWordsScreen>
    with ScreenCoachMixin<HardWordsScreen> {
  bool _loading = true;
  bool _loadFailed = false;
  List<Vocab> _hard = const [];

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
    List<Vocab> hard = const [];
    var loadFailed = false;
    try {
      final all =
          await (widget.deckLoader ?? ReviewDeckService.allReviewable)();
      // Extra-Lernset = SRS leech 휴리스틱 ∪ 명시적 오답 3회+ (레벨 불문).
      // 오답 카운터는 즉시 반응하므로 한 세션에서 3번 틀린 단어도 바로 잡힌다
      // (2026-08-13 테스터 피드백 ③).
      final ids = {
        ...Storage.hardIds(all.map((v) => v.korean)),
        ...Storage.frequentlyMissedIds(all.map((v) => v.korean)),
      };
      hard = all.where((v) => ids.contains(v.korean)).toList();
    } catch (_) {
      loadFailed = true;
    }
    if (!mounted) return;
    setState(() {
      _hard = hard;
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
    final actionBlock = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SoriButton(
          label: t.hardWordsHardQuizCta,
          variant: SoriButtonVariant.filled,
          accent: SoriColors.danger,
          fullWidth: true,
          onTap: () async {
            await Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) =>
                    HardChoiceQuizScreen(deck: _hard, title: t.hardQuizTitle),
              ),
            );
            if (mounted) {
              // ignore: discarded_futures
              _load();
            }
          },
        ),
        const SizedBox(height: Spacing.sm),
        SoriButton(
          label: t.hardWordsStudyCta,
          icon: Icons.bolt_rounded,
          variant: SoriButtonVariant.outlined,
          fullWidth: true,
          onTap: () async {
            await Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => ReviewSessionScreen(
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
      ],
    );

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
      builder: (context, padding) {
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
        if (_hard.isEmpty) {
          return Center(
            child: Padding(
              padding: padding,
              child: SoriEmptyState(
                asset: 'assets/illustrations/mascot/magpie_celebrate.png',
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
        if (inlineActions) {
          return ListView(
            key: _listKey,
            padding: padding,
            children: [
              header,
              const SizedBox(height: Spacing.sm),
              for (final word in _hard) ...[
                _HardWordTile(word: word),
                const SizedBox(height: Spacing.xs),
              ],
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
              child: ListView.separated(
                key: _listKey,
                padding: EdgeInsets.fromLTRB(
                  padding.left,
                  0,
                  padding.right,
                  padding.bottom,
                ),
                itemCount: _hard.length,
                separatorBuilder: (_, __) => const SizedBox(height: Spacing.xs),
                itemBuilder: (_, i) => _HardWordTile(word: _hard[i]),
              ),
            ),
          ],
        );
      },
      bottomNavigationBar: _hard.isEmpty || inlineActions
          ? null
          : SoriBottomActionArea(child: actionBlock),
    );
  }
}

class _HardWordTile extends StatelessWidget {
  const _HardWordTile({required this.word});

  final Vocab word;

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
                Text(word.korean, style: SoriTextTheme.of(context).h3),
                if (translation.isNotEmpty)
                  Text(
                    translation,
                    style: SoriTextTheme.of(
                      context,
                    ).bodySmall.copyWith(color: s.textMuted),
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
