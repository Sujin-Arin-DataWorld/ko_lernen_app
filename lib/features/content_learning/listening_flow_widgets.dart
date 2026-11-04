import 'package:flutter/material.dart';

import '../../l10n/generated/app_localizations.dart';
import '../../widgets/sori/button.dart';
import '../../widgets/sori/card.dart';
import '../../widgets/sori/c_gallery/c_materials.dart';
import '../../widgets/sori/tokens.dart';
import 'content_learning_models.dart';
import 'content_learning_service.dart';
import 'listening_object_art.dart';
import 'listening_figma_materials.dart';

/// The lesson uses the same shell destinations and a separate, read-only step
/// indicator. A step is never represented as a sixth main-navigation tab.
PreferredSizeWidget listeningFlowHeader(
  BuildContext context,
  Widget leading,
  List<Widget> actions, {
  required String level,
  int? step,
  bool figma = false,
}) {
  final t = AppL10n.of(context);
  final labels = [
    t.listeningTitle,
    t.listeningFlowUnderstand,
    t.listeningFlowResult,
  ];
  final scaler = MediaQuery.textScalerOf(context);
  final large = scaler.scale(1) > 1.25;
  final stepHeight = scaler.scale(13) * 1.3 + 18;
  return AppBar(
    leading: leading,
    actions: actions,
    toolbarHeight: 52,
    titleSpacing: 0,
    foregroundColor: CPalette.paper,
    backgroundColor: CPalette.jade,
    flexibleSpace: const CTexture(CMaterial.jade),
    elevation: 0,
    centerTitle: true,
    title: Text(
      '${t.listeningTitle} · ${level.toUpperCase()}',
      style: TextStyle(
        fontFamily: figma ? 'Manrope' : null,
        fontSize: figma ? 22 : 19,
        fontWeight: figma ? FontWeight.w700 : FontWeight.w600,
        color: CPalette.paper,
      ),
    ),
    bottom: step == null
        ? null
        : PreferredSize(
            preferredSize: Size.fromHeight(stepHeight),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
              child: large
                  ? Text(
                      '${t.contentLearningPosition(step + 1, 3)} · ${labels[step]}',
                      style: const TextStyle(
                        fontSize: 13,
                        height: 1.3,
                        color: CPalette.paper,
                      ),
                    )
                  : Row(
                      children: [
                        for (var index = 0; index < labels.length; index++)
                          Expanded(
                            child: Semantics(
                              selected: index == step,
                              child: Container(
                                padding: const EdgeInsets.only(
                                  bottom: Spacing.sm,
                                ),
                                decoration: BoxDecoration(
                                  border: Border(
                                    bottom: BorderSide(
                                      color: index <= step
                                          ? CPalette.brass
                                          : CPalette.paper.withValues(
                                              alpha: .24,
                                            ),
                                      width: index == step ? 3 : 1,
                                    ),
                                  ),
                                ),
                                child: Text(
                                  labels[index],
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontFamily: figma ? 'Manrope' : null,
                                    fontSize: 13,
                                    height: 1.3,
                                    color: index == step
                                        ? CPalette.paper
                                        : const Color(0xffd3d5c1),
                                    fontWeight: index == step
                                        ? FontWeight.w700
                                        : FontWeight.w400,
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
            ),
          ),
  );
}

class ListeningLessonPicker extends StatelessWidget {
  const ListeningLessonPicker({
    super.key,
    required this.topic,
    required this.title,
    required this.lessons,
    required this.onOpen,
    required this.onOverview,
    required this.onReview,
    required this.reviewable,
    required this.mistakes,
    this.busy = false,
  });
  final String topic, title;
  final List<ContentLesson> lessons;
  final ValueChanged<ContentLesson> onOpen;
  final VoidCallback onOverview;
  final ValueChanged<bool> onReview;
  final bool reviewable, mistakes, busy;

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);
    final lang = Localizations.localeOf(context).languageCode;
    final type = SoriTextTheme.of(context);
    return ListView(
      key: PageStorageKey('listening-lessons-$topic'),
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            style: TextButton.styleFrom(
              foregroundColor: CPalette.paper,
              minimumSize: const Size(48, 48),
            ),
            label: Text(t.contentLearningExit),
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: busy ? null : onOverview,
          ),
        ),
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    t.listeningFlowChoose,
                    style: type.eyebrow.copyWith(color: CPalette.brass),
                  ),
                  const SizedBox(height: 4),
                  Text(title, style: type.h2.copyWith(color: CPalette.paper)),
                ],
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              width: ListeningFigma.topicArtWidth,
              height: ListeningFigma.topicArtHeight,
              child: ListeningObjectArt(topic),
            ),
          ],
        ),
        const SizedBox(height: 12),
        for (var index = 0; index < lessons.length; index++) ...[
          Builder(
            builder: (context) {
              final lesson = lessons[index];
              final progress = ContentLearningService.progress(lesson.id);
              final started =
                  progress.position > 0 ||
                  progress.seenIds.isNotEmpty ||
                  progress.phase != ContentLessonPhase.learn;
              return SoriCard(
                key: ValueKey('content-lesson-${lesson.id}'),
                cMaterial: true,
                raised: true,
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${index + 1}'.padLeft(2, '0'),
                          style: type.h3.copyWith(color: CPalette.jade),
                        ),
                        const SizedBox(width: Spacing.sm),
                        Expanded(
                          child: Text(
                            lesson.title.pick(lang),
                            style: cMaterialText(type.h3),
                          ),
                        ),
                        if (progress.completed)
                          const Icon(
                            Icons.check_circle_rounded,
                            color: CPalette.jade,
                            size: 22,
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      lesson.intro.pick(lang),
                      style: cMaterialText(type.bodySmall),
                    ),
                    const SizedBox(height: 8),
                    SoriButton(
                      key: ValueKey('content-open-${lesson.id}'),
                      cMaterial: true,
                      variant: index == 0
                          ? SoriButtonVariant.filled
                          : SoriButtonVariant.outlined,
                      label: progress.completed
                          ? t.contentLearningDone
                          : started
                          ? t.contentLearningResume
                          : t.contentLearningStart,
                      icon: progress.completed
                          ? Icons.check_rounded
                          : Icons.play_arrow_rounded,
                      onTap: busy ? null : () => onOpen(lesson),
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 8),
        ],
        if (mistakes)
          SoriButton.outlined(
            cMaterial: true,
            label: t.contentLearningReviewMistakes,
            onTap: busy ? null : () => onReview(true),
          ),
        if (reviewable)
          SoriButton.outlined(
            cMaterial: true,
            label: t.contentLearningReviewTopic,
            onTap: busy ? null : () => onReview(false),
          ),
      ],
    );
  }
}

/// Topic context stays small; the original lesson text remains fully readable.
class ListeningLessonHeading extends StatelessWidget {
  const ListeningLessonHeading({
    super.key,
    required this.lesson,
    this.intro = false,
    this.compact = false,
  });
  final ContentLesson lesson;
  final bool intro;
  final bool compact;
  @override
  Widget build(BuildContext context) {
    final lang = Localizations.localeOf(context).languageCode;
    final type = SoriTextTheme.of(context);
    final large = MediaQuery.textScalerOf(context).scale(1) > 1.25;
    return Padding(
      padding: EdgeInsets.only(bottom: compact ? 8 : 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  lesson.title.pick(lang),
                  style: type.h3.copyWith(color: CPalette.paper),
                ),
                if (intro) ...[
                  const SizedBox(height: 4),
                  Text(
                    lesson.intro.pick(lang),
                    style: type.bodySmall.copyWith(color: CPalette.paper),
                  ),
                ],
              ],
            ),
          ),
          if (!large) ...[
            const SizedBox(width: 8),
            SizedBox(
              width: intro
                  ? 100
                  : compact
                  ? 40
                  : 64,
              height: intro
                  ? 100
                  : compact
                  ? 40
                  : 64,
              child: ListeningObjectArt(lesson.topicId),
            ),
          ],
        ],
      ),
    );
  }
}
