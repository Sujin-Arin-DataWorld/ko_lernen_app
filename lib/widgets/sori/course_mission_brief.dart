import 'package:flutter/material.dart';

import '../../l10n/generated/app_localizations.dart';
import '../../models/course_mission_brief.dart';
import '../../models/curriculum.dart';
import '../../services/scene_asset_resolver.dart';
import 'c_gallery/c_materials.dart';
import 'empty_state.dart';

typedef CourseMissionBriefOpener = Future<void> Function(ContentLink link);

/// The storage-free departure surface used by the production mission screen
/// and the UX gallery. Its CTA receives the exact first link shown as step 1.
class CourseMissionBriefView extends StatelessWidget {
  const CourseMissionBriefView({
    super.key,
    required this.brief,
    required this.openLink,
    this.onExplain,
  });

  final CourseMissionBrief brief;
  final CourseMissionBriefOpener openLink;
  final VoidCallback? onExplain;

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);
    final lang = Localizations.localeOf(context).languageCode;
    final scenario = brief.targetScenario;
    final firstLink = brief.firstLink;
    final poster = scenario == null
        ? null
        : SceneAssetResolver.posterAsset(scenario);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          '${brief.unit.level.toUpperCase()} ? ${brief.unit.title.pick(lang)}',
          style: const TextStyle(
            fontFamily: 'Paperlogy',
            fontSize: 12,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.15,
            color: CPalette.mutedInk,
          ),
        ),
        const SizedBox(height: 14),
        if (poster != null)
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: AspectRatio(
              aspectRatio: 16 / 9,
              child: Image.asset(
                poster,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) =>
                    const CSceneArt(CScene.book, height: 130),
              ),
            ),
          )
        else
          const CSceneArt(CScene.book, height: 130),
        const SizedBox(height: 18),
        Text(
          brief.unit.title.pick(lang),
          style: const TextStyle(
            fontFamily: 'Paperlogy',
            fontFamilyFallback: ['NotoSansKR'],
            fontSize: 24,
            height: 1.18,
            fontWeight: FontWeight.w700,
            color: CPalette.ink,
          ),
        ),
        const SizedBox(height: 7),
        Text(
          brief.unit.canDo.pick(lang),
          style: const TextStyle(
            fontFamily: 'Paperlogy',
            fontFamilyFallback: ['NotoSansKR'],
            fontSize: 16,
            height: 1.45,
            color: CPalette.mutedInk,
          ),
        ),
        const SizedBox(height: 16),
        Divider(color: CPalette.fineEdge.withValues(alpha: .8)),
        if (brief.isCompleted) ...[
          const SizedBox(height: 12),
          SoriEmptyState(
            icon: Icons.celebration_rounded,
            title: t.courseMissionCompleteTitle,
            body: t.courseMissionCompleteBody,
            illustrationMaxHeight: 120,
          ),
        ] else ...[
          for (final step in brief.visibleSteps)
            _BriefStepRow(
              step: step,
              title: _stepTitle(step.phase, t),
              body: _stepBody(step.phase, t),
            ),
          if (brief.remainingStepCount > 0) ...[
            const SizedBox(height: 4),
            Text(
              t.courseMissionBriefRemaining(brief.remainingStepCount),
              style: const TextStyle(
                fontFamily: 'Paperlogy',
                fontSize: 13,
                color: CPalette.mutedInk,
              ),
            ),
          ],
          if (scenario != null && scenario.vocab.isNotEmpty) ...[
            const SizedBox(height: 18),
            Text(
              lang == 'de'
                  ? 'Deine ersten Ausdr?cke'
                  : 'Your first expressions',
              style: const TextStyle(
                fontFamily: 'Paperlogy',
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: CPalette.ink,
              ),
            ),
            const SizedBox(height: 8),
            for (final item in scenario.vocab.take(4))
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        item.korean,
                        style: const TextStyle(
                          fontFamily: 'NotoSansKR',
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        item.note?.pick(lang) ?? '',
                        textAlign: TextAlign.end,
                        style: const TextStyle(
                          fontFamily: 'Paperlogy',
                          fontSize: 13,
                          color: CPalette.mutedInk,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
          const SizedBox(height: 20),
          if (brief.isCurrent && firstLink != null)
            CMaterialAction(
              key: const ValueKey('course-mission-primary-cta'),
              label: _stepCta(brief.visibleSteps.first.phase, t),
              onTap: () async => openLink(firstLink),
            )
          else if (!brief.isCurrent)
            Text(
              t.courseMissionPreviewNotice,
              style: const TextStyle(
                fontFamily: 'Paperlogy',
                fontSize: 13,
                color: CPalette.mutedInk,
              ),
            ),
          if (onExplain != null)
            TextButton(
              onPressed: onExplain,
              child: Text(t.courseMissionBriefWhy),
            ),
        ],
      ],
    );
  }

  String _stepTitle(CourseMissionPhase phase, AppL10n t) => switch (phase) {
    CourseMissionPhase.listen => t.courseMissionBriefListenTitle,
    CourseMissionPhase.build => t.courseMissionBriefBuildTitle,
    CourseMissionPhase.checkpoint => t.courseMissionBriefCheckpointTitle,
    CourseMissionPhase.scene => t.courseMissionBriefSceneTitle,
  };

  String _stepBody(CourseMissionPhase phase, AppL10n t) => switch (phase) {
    CourseMissionPhase.listen => t.courseMissionBriefListenBody,
    CourseMissionPhase.build => t.courseMissionBriefBuildBody,
    CourseMissionPhase.checkpoint => t.courseMissionBriefCheckpointBody,
    CourseMissionPhase.scene => t.courseMissionBriefSceneBody,
  };

  String _stepCta(CourseMissionPhase phase, AppL10n t) => switch (phase) {
    CourseMissionPhase.listen => t.courseMissionBriefListenCta,
    CourseMissionPhase.build => t.courseMissionBriefBuildCta,
    CourseMissionPhase.checkpoint => t.courseMissionBriefCheckpointCta,
    CourseMissionPhase.scene => t.courseMissionBriefSceneCta,
  };
}

class _BriefStepRow extends StatelessWidget {
  const _BriefStepRow({
    required this.step,
    required this.title,
    required this.body,
  });

  final CourseMissionBriefStep step;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 10),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 36,
          height: 36,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: step.displayIndex == 1 ? CPalette.deepJade : CPalette.paper,
            shape: BoxShape.circle,
            border: Border.all(
              color: step.displayIndex == 1
                  ? CPalette.deepJade
                  : CPalette.fineEdge,
            ),
          ),
          child: Text(
            '${step.displayIndex}',
            style: TextStyle(
              fontFamily: 'Paperlogy',
              fontWeight: FontWeight.w700,
              color: step.displayIndex == 1
                  ? CPalette.paper
                  : CPalette.mutedInk,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontFamily: 'Paperlogy',
                  fontFamilyFallback: ['NotoSansKR'],
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: CPalette.ink,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                body,
                style: const TextStyle(
                  fontFamily: 'Paperlogy',
                  fontFamilyFallback: ['NotoSansKR'],
                  fontSize: 13,
                  color: CPalette.mutedInk,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Text(
          '${step.estimatedMinutes} min',
          style: const TextStyle(
            fontFamily: 'Paperlogy',
            fontSize: 12,
            color: CPalette.mutedInk,
          ),
        ),
      ],
    ),
  );
}
