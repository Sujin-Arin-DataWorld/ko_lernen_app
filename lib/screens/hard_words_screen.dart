import 'package:flutter/material.dart';

import '../l10n/generated/app_localizations.dart';
import '../models/vocab.dart';
import '../services/review_deck_service.dart';
import '../services/storage_service.dart';
import '../services/tts_service.dart';
import '../widgets/app_loading.dart';
import '../widgets/sori/button.dart';
import '../widgets/sori/card.dart';
import '../widgets/sori/empty_state.dart';
import '../widgets/sori/mascot.dart';
import '../widgets/sori/responsive.dart';
import '../widgets/sori/screen_background.dart';
import '../widgets/sori/screen_coach.dart';
import '../widgets/sori/spotlight_coach.dart';
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

  Future<void> _load() async {
    List<Vocab> hard = const [];
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
      /* best-effort → empty */
    }
    if (!mounted) return;
    setState(() {
      _hard = hard;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);
    final s = SoriSurfaces.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          t.hardWordsTitle,
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        actions: const [TtsSpeedAction()],
      ),
      body: SoriScreenBackground(
        particles: true,
        child: SafeArea(
          child: _loading
              ? const AppLoading()
              : _hard.isEmpty
              ? Center(
                  child: SoriEmptyState(
                    asset: 'assets/illustrations/mascot/magpie_celebrate.png',
                    icon: Icons.emoji_events_outlined,
                    title: t.hardWordsEmptyTitle,
                    body: t.hardWordsEmptyBody,
                    ctaLabel: t.btnClose,
                    onCta: () => Navigator.of(context).maybePop(),
                  ),
                )
              : Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(
                        Spacing.lg,
                        Spacing.md,
                        Spacing.lg,
                        Spacing.sm,
                      ),
                      child: Row(
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
                      ),
                    ),
                    Expanded(
                      child: ListView.separated(
                        key: _listKey,
                        padding: soriClampPadding(
                          MediaQuery.sizeOf(context).width,
                          base: const EdgeInsets.fromLTRB(12, 0, 12, 96),
                        ),
                        itemCount: _hard.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: Spacing.xs),
                        itemBuilder: (_, i) {
                          final v = _hard[i];
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
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        v.korean,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w800,
                                          fontSize: 16,
                                        ),
                                      ),
                                      if (v.german.isNotEmpty)
                                        Text(
                                          v.german,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            fontSize: 13,
                                            color: s.textMuted,
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  icon: Icon(
                                    Icons.volume_up_rounded,
                                    color: SoriColors.primary,
                                  ),
                                  visualDensity: VisualDensity.compact,
                                  onPressed: () => TtsService.speak(v.korean),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
        ),
      ),
      bottomNavigationBar: _hard.isEmpty
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(Spacing.lg),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // 2단계 연습 — 뜻을 보고 비슷한 철자 4개 중 정답 고르기
                    // (테스터 피드백 ④의 "어려운 보기" 모드).
                    SoriButton(
                      label: t.hardWordsHardQuizCta,
                      variant: SoriButtonVariant.filled,
                      accent: SoriColors.danger,
                      fullWidth: true,
                      onTap: () async {
                        await Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => HardChoiceQuizScreen(
                              deck: _hard,
                              title: t.hardQuizTitle,
                            ),
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
                      accent: SoriColors.danger,
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
                ),
              ),
            ),
    );
  }
}
