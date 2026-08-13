import 'package:flutter/material.dart';

import '../../data/sori_activity_catalog.dart';
import '../../models/sori_stage_progression.dart';
import '../../widgets/sori/button.dart';
import '../../widgets/sori/responsive.dart';
import '../../widgets/sori/tokens.dart';

class SoriStageTodayPreviewScreen extends StatelessWidget {
  const SoriStageTodayPreviewScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: SoriContentClamp(
        base: const EdgeInsets.fromLTRB(20, 20, 20, 48),
        builder: (context, padding) => ListView(
          padding: padding,
          children: const [
            _PreviewHeader(eyebrow: 'HEUTE', title: 'Ein Satz. Ein Bauteil.'),
            SizedBox(height: Spacing.xl),
            _MissionStage(),
            SizedBox(height: Spacing.lg),
            _BojagiCallout(),
            SizedBox(height: Spacing.xl),
            _SectionTitle('Fast geschafft'),
            SizedBox(height: Spacing.sm),
            _QuestRow(
              label: 'Im Café bestellen',
              value: '4 von 5',
              fraction: .8,
            ),
            _QuestRow(
              label: 'Starke Alltagswörter',
              value: '18 von 25',
              fraction: .72,
            ),
            _QuestRow(
              label: 'Sieben Tage dranbleiben',
              value: '5 von 7',
              fraction: .71,
            ),
          ],
        ),
      ),
    ),
  );
}

class SoriStageLessonPreviewScreen extends StatelessWidget {
  const SoriStageLessonPreviewScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: SoriActivityColors.hanokStage,
    body: SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(Spacing.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const _PreviewHeader(
              eyebrow: 'LEKTION 2 VON 4',
              title: '덜 맵게 해 주세요',
              light: true,
            ),
            const SizedBox(height: Spacing.xl),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final horizontal =
                      constraints.maxWidth >= SoriBreakpoints.tablet;
                  final stages = const [
                    _LessonStage(
                      icon: Icons.headphones_rounded,
                      label: 'Hören',
                      detail: 'Natürliches Tempo',
                      color: SoriActivityColors.listening,
                    ),
                    _LessonStage(
                      icon: Icons.mic_rounded,
                      label: 'Sprechen',
                      detail: 'Rhythmus und Mundbild',
                      color: SoriActivityColors.speaking,
                    ),
                    _LessonStage(
                      icon: Icons.memory_rounded,
                      label: 'Erinnern',
                      detail: 'Ohne Hilfe abrufen',
                      color: SoriActivityColors.review,
                    ),
                  ];
                  return horizontal
                      ? Row(
                          children: [
                            for (final stage in stages) Expanded(child: stage),
                          ],
                        )
                      : ListView(children: stages);
                },
              ),
            ),
            const SizedBox(height: Spacing.lg),
            SoriButton(label: 'Mit Hören beginnen', onTap: () {}),
          ],
        ),
      ),
    ),
  );
}

class SoriStageRewardReceiptPreviewScreen extends StatelessWidget {
  const SoriStageRewardReceiptPreviewScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: SoriContentClamp(
        base: const EdgeInsets.all(Spacing.xl),
        builder: (context, padding) => ListView(
          padding: padding,
          children: [
            const _PreviewHeader(
              eyebrow: 'HEUTE VERÄNDERT',
              title: 'Dein Satz trägt jetzt das Dach.',
            ),
            const SizedBox(height: Spacing.xl),
            Container(
              padding: const EdgeInsets.all(Spacing.xl),
              decoration: BoxDecoration(
                color: SoriActivityColors.hanokStage,
                borderRadius: BorderRadius.circular(SoriRadius.lg),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.roofing_rounded, size: 72, color: SoriColors.gold),
                  SizedBox(height: Spacing.lg),
                  Text(
                    'DAEChEONG · BALKEN 3',
                    style: TextStyle(
                      color: SoriColors.gold,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.2,
                    ),
                  ),
                  SizedBox(height: Spacing.xs),
                  Text(
                    '1 neuer Balken im Bauplan',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: Spacing.lg),
            const _ReceiptLine(
              icon: Icons.bolt_rounded,
              title: '+20 XP',
              detail: 'für die abgeschlossene Mission',
            ),
            const _ReceiptLine(
              icon: Icons.task_alt_rounded,
              title: 'Quest +1',
              detail: 'Alltagsszenen · 4 von 10',
            ),
            const _ReceiptLine(
              icon: Icons.home_work_rounded,
              title: 'Hanok +1 Balken',
              detail: 'durch bestätigtes Sprechen',
            ),
            const SizedBox(height: Spacing.xl),
            SoriButton(label: 'Weiter zu Heute', onTap: () {}),
          ],
        ),
      ),
    ),
  );
}

class SoriStageJourneyPreviewScreen extends StatelessWidget {
  const SoriStageJourneyPreviewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final entries = soriActivityCatalog
        .where((entry) => entry.tab == SoriStageTab.learn)
        .take(8);
    return Scaffold(
      body: SafeArea(
        child: SoriContentClamp(
          maxWidth: 840,
          base: const EdgeInsets.fromLTRB(20, 20, 20, 48),
          builder: (context, padding) => ListView(
            padding: padding,
            children: [
              const _PreviewHeader(
                eyebrow: 'DEIN WEG',
                title: 'Alles Lernen baut am selben Ort.',
              ),
              const SizedBox(height: Spacing.xl),
              for (final entry in entries) _ActivityRow(entry: entry),
            ],
          ),
        ),
      ),
    );
  }
}

class _MissionStage extends StatelessWidget {
  const _MissionStage();
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(Spacing.xl),
    decoration: BoxDecoration(
      color: SoriActivityColors.hanokStage,
      borderRadius: BorderRadius.circular(SoriRadius.xl),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'WENIGER SCHARF BESTELLEN',
          style: TextStyle(
            color: SoriColors.gold,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.1,
          ),
        ),
        const SizedBox(height: Spacing.sm),
        const Text(
          'Hören. Sprechen. Im Alltag anwenden.',
          style: TextStyle(
            color: Colors.white,
            fontSize: 28,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: Spacing.xl),
        const Row(
          children: [
            Icon(Icons.roofing_rounded, color: SoriColors.gold),
            SizedBox(width: Spacing.sm),
            Expanded(
              child: Text(
                'Abschließen → 20 XP + 1 Hanok-Balken',
                style: TextStyle(
                  color: SoriActivityColors.onHanokStage,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: Spacing.lg),
        SoriButton(label: 'Mission starten', onTap: () {}),
      ],
    ),
  );
}

class _BojagiCallout extends StatelessWidget {
  const _BojagiCallout();
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(Spacing.lg),
    decoration: BoxDecoration(
      color: SoriColors.gold.withValues(alpha: .2),
      border: Border.all(color: SoriColors.gold),
      borderRadius: BorderRadius.circular(SoriRadius.md),
    ),
    child: const Row(
      children: [
        Icon(Icons.redeem_rounded, color: SoriColors.goldOnLight, size: 32),
        SizedBox(width: Spacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '1 Bojagi wartet',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
              Text('Wähle eines von drei Stücken für dein Zimmer.'),
            ],
          ),
        ),
      ],
    ),
  );
}

class _PreviewHeader extends StatelessWidget {
  const _PreviewHeader({
    required this.eyebrow,
    required this.title,
    this.light = false,
  });
  final String eyebrow;
  final String title;
  final bool light;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        eyebrow,
        style: TextStyle(
          color: light ? SoriColors.gold : SoriColors.accent,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.2,
        ),
      ),
      const SizedBox(height: Spacing.xs),
      Text(
        title,
        style: TextStyle(
          color: light ? Colors.white : null,
          fontSize: 32,
          height: 1.05,
          fontWeight: FontWeight.w700,
        ),
      ),
    ],
  );
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.label);
  final String label;
  @override
  Widget build(BuildContext context) => Text(
    label,
    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
  );
}

class _QuestRow extends StatelessWidget {
  const _QuestRow({
    required this.label,
    required this.value,
    required this.fraction,
  });
  final String label;
  final String value;
  final double fraction;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: Spacing.sm),
    child: Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
              const SizedBox(height: 6),
              LinearProgressIndicator(
                value: fraction,
                minHeight: 8,
                borderRadius: BorderRadius.circular(8),
                color: SoriColors.primary,
              ),
            ],
          ),
        ),
        const SizedBox(width: Spacing.md),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w700)),
      ],
    ),
  );
}

class _LessonStage extends StatelessWidget {
  const _LessonStage({
    required this.icon,
    required this.label,
    required this.detail,
    required this.color,
  });
  final IconData icon;
  final String label;
  final String detail;
  final Color color;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(Spacing.xs),
    child: Container(
      padding: const EdgeInsets.all(Spacing.lg),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(SoriRadius.lg),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 48),
          const SizedBox(height: Spacing.md),
          Text(
            label,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: Spacing.xs),
          Text(detail, textAlign: TextAlign.center),
        ],
      ),
    ),
  );
}

class _ReceiptLine extends StatelessWidget {
  const _ReceiptLine({
    required this.icon,
    required this.title,
    required this.detail,
  });
  final IconData icon;
  final String title;
  final String detail;
  @override
  Widget build(BuildContext context) => ListTile(
    contentPadding: EdgeInsets.zero,
    minVerticalPadding: Spacing.md,
    leading: CircleAvatar(
      backgroundColor: SoriColors.primarySoft,
      child: Icon(icon, color: SoriColors.primaryDark),
    ),
    title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
    subtitle: Text(detail),
  );
}

class _ActivityRow extends StatelessWidget {
  const _ActivityRow({required this.entry});
  final ActivityCatalogEntry entry;
  @override
  Widget build(BuildContext context) {
    final color = _activityColor(entry.colorRole);
    return Container(
      margin: const EdgeInsets.only(bottom: Spacing.sm),
      padding: const EdgeInsets.all(Spacing.lg),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .18),
        borderRadius: BorderRadius.circular(SoriRadius.md),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.play_arrow_rounded),
          ),
          const SizedBox(width: Spacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.title.de,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  '${entry.minutes} Min. · ${entry.reward.items.map((item) => item.label.de).join(' · ')}',
                  maxLines: 2,
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded),
        ],
      ),
    );
  }
}

Color _activityColor(SoriActivityColorRole role) => switch (role) {
  SoriActivityColorRole.listening => SoriActivityColors.listening,
  SoriActivityColorRole.speaking => SoriActivityColors.speaking,
  SoriActivityColorRole.review => SoriActivityColors.review,
  SoriActivityColorRole.completion => SoriColors.primary,
  SoriActivityColorRole.reward => SoriColors.gold,
  SoriActivityColorRole.collaboration => SoriColors.highlight,
  SoriActivityColorRole.hanok => SoriActivityColors.hanokStage,
};
