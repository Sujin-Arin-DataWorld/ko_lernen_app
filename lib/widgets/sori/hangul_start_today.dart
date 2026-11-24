import 'package:flutter/material.dart';

import '../../l10n/generated/app_localizations.dart';
import '../../screens/hangul_start_screen.dart';
import '../../services/hangul_start_progress.dart';
import 'approved_chrome_assets.dart';
import 'hangul_start_material.dart';
import 'pressable.dart';
import 'toast.dart';
import 'tokens.dart';

class HangulStartCourseCard extends StatelessWidget {
  const HangulStartCourseCard({super.key, required this.onReturn});
  final VoidCallback onReturn;

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);
    return HangulStartPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 8,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  t.soriStageTodayMissionEyebrow,
                  style: HangulStartStyle.body(
                    context,
                    13,
                    color: HangulStartStyle.muted,
                  ),
                ),
              ),
              Text(
                'A1.1',
                style: HangulStartStyle.body(
                  context,
                  13,
                  color: HangulStartStyle.muted,
                ),
              ),
            ],
          ),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: 6,
                  children: [
                    Text(
                      t.hangulStartA11CardTitle,
                      style: HangulStartStyle.heading(context, 25),
                    ),
                    Text(
                      t.hangulStartA11Steps,
                      style: HangulStartStyle.body(
                        context,
                        13,
                        color: HangulStartStyle.muted,
                      ),
                    ),
                  ],
                ),
              ),
              if (!HangulStartStyle.largeText(context))
                HangulStartArt(
                  'greeting-art',
                  width: HangulStartStyle.compact(context) ? 62 : 95,
                ),
            ],
          ),
          HangulStartAction(
            key: const ValueKey('learning-focus-start'),
            label: t.hangulStartContinueA11,
            onTap: () => _openA11AndRefresh(context, onReturn),
          ),
        ],
      ),
    );
  }
}

Future<void> _openA11AndRefresh(
  BuildContext context,
  VoidCallback onReturn,
) async {
  final t = AppL10n.of(context);
  try {
    await openHangulStartA11(context);
    if (context.mounted) onReturn();
  } catch (_) {
    if (!context.mounted) return;
    soriToast(context, t.hangulStartLoadError);
  }
}

class HangulStartTodayCard extends StatelessWidget {
  const HangulStartTodayCard({
    super.key,
    required this.start,
    required this.open,
    required this.openCheck,
  });
  final HangulStartHome start;
  final VoidCallback? open;
  final VoidCallback? openCheck;

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);
    final next = start.nextLesson;
    final started = start.progress.started;
    final compact = HangulStartStyle.compact(context);
    final large = HangulStartStyle.largeText(context);
    final total = start.catalog.lessons.length;
    final done = start.completedCount;
    final language = Localizations.localeOf(context).languageCode;
    return HangulStartPanel(
      padding: EdgeInsets.all(compact ? 10 : 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: compact ? 5 : 8,
        children: [
          Row(
            children: [
              Container(
                width: 3,
                height: compact ? 35 : 44,
                decoration: BoxDecoration(
                  color: HangulStartStyle.wrong,
                  borderRadius: BorderRadius.circular(SoriRadius.micro),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: 6,
                  children: [
                    Text(
                      t.todayFirstSyllable,
                      style: HangulStartStyle.heading(
                        context,
                        compact ? 22 : 25,
                      ),
                    ),
                    Text(
                      t.hangulStartOverviewLabel,
                      style: HangulStartStyle.body(
                        context,
                        13,
                        color: HangulStartStyle.muted,
                      ),
                    ),
                  ],
                ),
              ),
              if (!large) ...[
                const SizedBox(width: Spacing.compact),
                HangulStartArt(
                  'celadon-a',
                  width: compact ? 62 : 96,
                  onPaper: true,
                ),
              ],
            ],
          ),
          Row(
            children: [
              Expanded(
                child: HangulStartProgressMarks(
                  length: total,
                  caption: t.hangulStartDoneCount(done, total),
                  complete: {
                    for (final lesson in start.catalog.lessons)
                      if (start.progress.completed.contains(lesson.id))
                        lesson.order - 1,
                  },
                  current: next == null ? null : next.order - 1,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '$done / $total',
                style: HangulStartStyle.body(
                  context,
                  13,
                  color: HangulStartStyle.muted,
                ),
              ),
            ],
          ),
          if (started && next != null) ...[
            Text(
              '${t.hangulStartNextLetters} ${next.newJamo.isEmpty ? next.title.pick(language) : next.newJamo.join(' ')}',
              style: HangulStartStyle.body(
                context,
                16,
                color: HangulStartStyle.deep,
                strong: true,
              ),
            ),
            if (!compact)
              Text(
                t.hangulStartDurationWithAudio,
                style: HangulStartStyle.body(
                  context,
                  13,
                  color: HangulStartStyle.muted,
                ),
              ),
          ],
          HangulStartAction(
            key: const ValueKey('learning-focus-start'),
            label: started ? t.hangulStartResume : t.todayStartHangul,
            onTap: open,
          ),
          HangulStartAction(
            key: const ValueKey('today-hangul-kurztest'),
            label: t.hangulStartAlreadyRead,
            onTap: openCheck,
            kind: HangulStartActionKind.link,
          ),
        ],
      ),
    );
  }
}

class HangulStartTodayLinks extends StatelessWidget {
  const HangulStartTodayLinks({
    super.key,
    required this.reviewDue,
    required this.owned,
    required this.onReturn,
    this.onGames,
    this.reward,
    this.showShortcuts = true,
  });
  final int reviewDue;
  final int owned;
  final VoidCallback onReturn;
  final VoidCallback? onGames;
  final Widget? reward;
  final bool showShortcuts;

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);
    final compact = HangulStartStyle.compact(context);
    Future<void> open(String path) async {
      await Navigator.of(context).pushNamed(path);
      if (context.mounted) onReturn();
    }

    Future<void> openA11() async {
      try {
        await openHangulStartA11(context);
        if (context.mounted) onReturn();
      } catch (_) {
        if (!context.mounted) return;
        soriToast(context, t.hangulStartLoadError);
      }
    }

    Widget pair(Widget left, Widget right) =>
        HangulStartStyle.largeText(context)
        ? Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: 8,
            children: [left, right],
          )
        : Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 8,
            children: [
              Expanded(child: left),
              Expanded(child: right),
            ],
          );
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: compact ? 7 : 10,
        children: [
          _Shortcut(
            title: t.reviewTitle,
            subtitle: reviewDue > 0 ? t.homeReviewDue(reviewDue) : null,
            artwork: const HangulStartArt('review-art', width: 46, height: 40),
            onTap: () => open('/review'),
          ),
          ?reward,
          pair(
            _Shortcut(
              title: t.hangulStartTodayHanok,
              subtitle: '$owned / 16',
              artwork: Image.asset(
                'assets/illustrations/concept_c/today/hanok-entrance.png',
                height: compact ? 30 : 41,
                width: compact ? 31 : 64,
                excludeFromSemantics: true,
              ),
              above: !compact,
              onTap: () => open('/hanok'),
            ),
            _Shortcut(
              key: const ValueKey('today-quick-play'),
              title: t.todayExploreGames,
              artwork: Image.asset(
                ApprovedChromeAssets.games,
                height: compact ? 30 : 41,
                width: compact ? 31 : 57,
                excludeFromSemantics: true,
              ),
              above: !compact,
              onTap: onGames,
            ),
          ),
          if (showShortcuts)
            pair(
              _Shortcut(
                title: t.hangulStartTodayAtelier,
                subtitle: t.hangulStartTodayAtelierDetail,
                artwork: Image.asset(
                  'assets/illustrations/concept_c/hangul_atelier/ink-desk.png',
                  width: compact ? 27 : 38,
                  height: compact ? 28 : 35,
                  excludeFromSemantics: true,
                ),
                onTap: () => open('/hangul'),
              ),
              _Shortcut(
                title: t.hangulStartTodayDirectA11,
                subtitle: t.hangulStartA11CardTitle,
                artwork: HangulStartArt(
                  'greeting-art',
                  width: compact ? 27 : 38,
                  height: compact ? 28 : 35,
                ),
                onTap: openA11,
              ),
            ),
        ],
      ),
    );
  }
}

class _Shortcut extends StatelessWidget {
  const _Shortcut({
    super.key,
    required this.title,
    required this.artwork,
    required this.onTap,
    this.subtitle,
    this.above = false,
  });
  final String title;
  final String? subtitle;
  final Widget artwork;
  final VoidCallback? onTap;
  final bool above;

  @override
  Widget build(BuildContext context) {
    final compact = HangulStartStyle.compact(context);
    final label = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 2,
      children: [
        Text(
          title,
          style: HangulStartStyle.body(
            context,
            compact ? 14 : 16,
            color: HangulStartStyle.deep,
            strong: true,
          ),
        ),
        if (subtitle != null)
          Text(
            subtitle!,
            style: HangulStartStyle.body(
              context,
              compact ? 11 : 13,
              color: HangulStartStyle.muted,
            ),
          ),
      ],
    );
    const arrow = Icon(
      Icons.chevron_right,
      size: 15,
      color: HangulStartStyle.deep,
    );
    return Semantics(
      button: true,
      enabled: onTap != null,
      child: SoriPressable(
        onTap: onTap,
        pressScale: .99,
        pressOffsetY: 1,
        pressDuration: HangulStartStyle.press,
        releaseDuration: HangulStartStyle.settle,
        pressCurve: HangulStartStyle.curve,
        releaseCurve: HangulStartStyle.curve,
        child: Container(
          constraints: BoxConstraints(
            minHeight: above
                ? 90
                : compact
                ? 48
                : 54,
          ),
          decoration: BoxDecoration(
            color: HangulStartStyle.paper,
            borderRadius: BorderRadius.circular(SoriRadius.c5DetailAction),
            border: Border.all(color: HangulStartStyle.seam),
            boxShadow: const [
              BoxShadow(color: Color(0xffac8a56), offset: Offset(0, 2)),
            ],
          ),
          padding: EdgeInsets.symmetric(
            horizontal: compact ? 6 : 8,
            vertical: 5,
          ),
          child: above
              ? Column(
                  mainAxisSize: MainAxisSize.min,
                  spacing: 3,
                  children: [
                    artwork,
                    Row(
                      children: [
                        Expanded(child: label),
                        arrow,
                      ],
                    ),
                  ],
                )
              : Row(
                  children: [
                    artwork,
                    const SizedBox(width: Spacing.dense),
                    Expanded(child: label),
                    arrow,
                  ],
                ),
        ),
      ),
    );
  }
}
