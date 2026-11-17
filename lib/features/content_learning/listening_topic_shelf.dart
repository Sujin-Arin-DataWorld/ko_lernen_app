import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../widgets/sori/button.dart';

import '../../l10n/generated/app_localizations.dart';
import '../../widgets/sori/c_gallery/c_materials.dart';
import '../../widgets/sori/pressable.dart';
import '../../widgets/sori/tokens.dart';
import 'listening_object_art.dart';
import 'listening_figma_materials.dart';

class ListeningTopicChoice {
  const ListeningTopicChoice({
    required this.id,
    required this.title,
    required this.label,
    required this.progress,
    required this.complete,
  });
  final String id, title, label, progress;
  final bool complete;
}

TextStyle _topicTitleStyle(ListeningTopicChoice choice, bool featured) =>
    TextStyle(
      fontFamily: ListeningFigma.font,
      fontSize: featured ? 24 : 17,
      height: featured ? 29 / 24 : 22 / 17,
      fontWeight: FontWeight.w700,
      color: CPalette.ink,
    );

const _focusStyle = TextStyle(
  fontFamily: ListeningFigma.font,
  fontSize: 13,
  height: 1.5,
  color: Color(0xff52634d),
  fontWeight: FontWeight.w500,
);

double _artFraction(ListeningTopicChoice choice, double width) => width < 310
    ? .30
    : choice.title.length > 25
    ? .38
    : .46;

// Long live titles need more paper, not a smaller typeface or clipped lines.
double _featuredHeight(
  BuildContext context,
  double width,
  ListeningTopicChoice choice,
  bool resume,
) {
  final t = AppL10n.of(context);
  final innerWidth = width - 28;
  final copyWidth = innerWidth * (1 - _artFraction(choice, innerWidth)) - 8;
  double height(String text, TextStyle style, double maxWidth) {
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: DefaultTextStyle.of(context).style.merge(style),
      ),
      textDirection: Directionality.of(context),
      textScaler: MediaQuery.textScalerOf(context),
    )..layout(maxWidth: maxWidth);
    final result = painter.height;
    painter.dispose();
    return result;
  }

  final title = _topicTitleStyle(choice, true);
  final actionHeight = math.max(
    48.0,
    height(
          resume ? t.contentLearningResume : t.listeningShelfExplore,
          title.copyWith(fontSize: 15),
          copyWidth - 40,
        ) +
        20,
  );
  return math.max(
    176.0,
    height(
          resume ? t.contentLearningResume : t.listeningShelfFocus,
          _focusStyle,
          copyWidth,
        ) +
        4 +
        height(choice.title, title, copyWidth) +
        8 +
        actionHeight +
        30,
  );
}

/// Navigation and progress stay in ContentLearningHub; this is presentation only.
class ListeningTopicShelf extends StatelessWidget {
  const ListeningTopicShelf({
    super.key,
    required this.topics,
    required this.page,
    required this.onPage,
    required this.onTopic,
    required this.goalLabel,
    required this.onEditGoal,
    this.resumeTopic,
    this.onResume,
  });
  final List<ListeningTopicChoice> topics;
  final int page;
  final ValueChanged<int> onPage;
  final ValueChanged<String> onTopic;
  final String goalLabel;
  final VoidCallback onEditGoal;
  final String? resumeTopic;
  final VoidCallback? onResume;

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);
    return LayoutBuilder(
      builder: (context, bounds) {
        final enlarged = MediaQuery.textScalerOf(context).scale(1) > 1.25;
        // A short phone gets fewer choices per page, preserving readable art
        // and reachable navigation instead of shrinking the whole interface.
        final pageSize = enlarged || bounds.maxHeight >= 560
            ? 5
            : bounds.maxHeight >= 400
            ? 3
            : 1;
        final pages = (topics.length / pageSize).ceil();
        final current = page.clamp(0, math.max(0, pages - 1)).toInt();
        final visible = topics.skip(current * pageSize).take(pageSize).toList();
        final scroll = enlarged;
        final featuredHeight = visible.isEmpty || scroll
            ? 176.0
            : _featuredHeight(
                context,
                bounds.maxWidth,
                visible.first,
                visible.first.id == resumeTopic && onResume != null,
              );
        final available = bounds.maxHeight - 88;
        final rows = math.max(1, ((visible.length - 1) / 2).ceil());
        final tileHeight = ((available - featuredHeight - rows * 12) / rows)
            .clamp(136.0, 150.0);
        Widget card(ListeningTopicChoice choice, bool featured) =>
            _TopicObjectCard(
              choice: choice,
              featured: featured,
              onTap: featured && choice.id == resumeTopic && onResume != null
                  ? onResume!
                  : () => onTopic(choice.id),
              resume: featured && choice.id == resumeTopic && onResume != null,
              stacked: scroll,
            );
        final contents = <Widget>[
          if (visible.isNotEmpty)
            SizedBox(
              height: scroll ? null : featuredHeight,
              child: card(visible.first, true),
            ),
          for (
            var index = 1;
            index < visible.length;
            index += scroll ? 1 : 2
          ) ...[
            const SizedBox(height: 12),
            if (scroll)
              card(visible[index], false)
            else
              SizedBox(
                height: tileHeight,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(child: card(visible[index], false)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: index + 1 < visible.length
                          ? card(visible[index + 1], false)
                          : const SizedBox.shrink(),
                    ),
                  ],
                ),
              ),
          ],
        ];
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              t.listeningShelfPrompt,
              style: const TextStyle(
                fontFamily: ListeningFigma.font,
                fontSize: 17,
                fontWeight: FontWeight.w500,
                height: 22 / 17,
                color: CPalette.paper,
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: AnimatedSwitcher(
                duration: SoriMotion.respect(
                  context,
                  const Duration(milliseconds: 180),
                ),
                switchInCurve: Curves.easeOutCubic,
                layoutBuilder: (current, previous) => Stack(
                  alignment: Alignment.topCenter,
                  children: [...previous, if (current != null) current],
                ),
                child: SingleChildScrollView(
                  key: PageStorageKey(
                    'listening-shelf-$pageSize-$current-${topics.firstOrNull?.id}',
                  ),
                  padding: const EdgeInsets.fromLTRB(1, 1, 1, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: contents,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                IconButton(
                  key: const ValueKey('listening-page-previous'),
                  tooltip: t.contentLearningPrevious,
                  color: CPalette.paper,
                  disabledColor: CPalette.paper.withValues(alpha: .35),
                  constraints: const BoxConstraints(
                    minWidth: 48,
                    minHeight: 48,
                  ),
                  onPressed: current > 0 ? () => onPage(current - 1) : null,
                  icon: const Icon(Icons.chevron_left),
                ),
                Expanded(
                  child: SoriTextAction(
                    label:
                        '$goalLabel. ${t.contentLearningPosition(current + 1, pages)} · ${t.contentLearningEditGoal}',
                    key: const ValueKey('listening-edit-goal'),
                    style: TextButton.styleFrom(
                      foregroundColor: CPalette.paper,
                      minimumSize: const Size(48, 48),
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                    ),
                    onPressed: onEditGoal,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          goalLabel,
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 13, height: 1.25),
                        ),
                        const SizedBox(height: Spacing.xs),
                        Text(
                          '${t.contentLearningPosition(current + 1, pages)} · ${t.contentLearningEditGoal}',
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 13, height: 1.25),
                        ),
                      ],
                    ),
                  ),
                ),
                IconButton(
                  key: const ValueKey('listening-page-next'),
                  tooltip: t.contentLearningNext,
                  color: CPalette.paper,
                  disabledColor: CPalette.paper.withValues(alpha: .35),
                  constraints: const BoxConstraints(
                    minWidth: 48,
                    minHeight: 48,
                  ),
                  onPressed: current + 1 < pages
                      ? () => onPage(current + 1)
                      : null,
                  icon: const Icon(Icons.chevron_right),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}

PreferredSizeWidget listeningShelfHeader(
  BuildContext context,
  Widget leading,
  List<Widget> actions,
  String level,
  VoidCallback onLevel,
) {
  final t = AppL10n.of(context);
  final scaler = MediaQuery.textScalerOf(context);
  final large = scaler.scale(1) > 1.25;
  final titleStyle = TextStyle(
    fontFamily: ListeningFigma.font,
    fontSize: large ? 26 : 36,
    height: 1.2,
    color: CPalette.paper,
    fontWeight: FontWeight.w700,
  );
  final title = Text(t.listeningTitle, style: titleStyle);
  final selector = SoriTextAction(
    label: level.toUpperCase(),
    key: const ValueKey('listening-level-picker'),
    onPressed: onLevel,
    style: OutlinedButton.styleFrom(
      foregroundColor: CPalette.paper,
      backgroundColor: ListeningFigma.jade,
      side: const BorderSide(color: CPalette.brass),
      minimumSize: const Size(70, 48),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      textStyle: const TextStyle(
        fontFamily: ListeningFigma.font,
        fontSize: 14,
        fontWeight: FontWeight.w700,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(SoriRadius.sm),
      ),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(level.toUpperCase()),
        const SizedBox(width: 4),
        const Icon(Icons.expand_more, size: 18),
      ],
    ),
  );
  final titleHeight = scaler.scale(large ? 26 : 34) * 1.2;
  final rowHeight = large
      ? titleHeight + scaler.scale(16) * 1.2 + 40
      : math.max(48.0, titleHeight);
  return PreferredSize(
    preferredSize: Size.fromHeight(48 + rowHeight + 12),
    child: AppBar(
      toolbarHeight: 48,
      leading: leading,
      actions: actions,
      foregroundColor: CPalette.paper,
      backgroundColor: const Color(0xff07594e),
      flexibleSpace: const CTexture(CMaterial.jade),
      elevation: 0,
      centerTitle: true,
      title: const Text(
        'HANGUL SORI',
        style: TextStyle(
          fontFamily: ListeningFigma.font,
          fontSize: 13,
          color: CPalette.brass,
        ),
      ),
      bottom: PreferredSize(
        preferredSize: Size.fromHeight(rowHeight + 12),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          child: large
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    title,
                    const SizedBox(height: 8),
                    Align(alignment: Alignment.centerRight, child: selector),
                  ],
                )
              : Row(
                  children: [
                    Expanded(child: title),
                    const SizedBox(width: 8),
                    selector,
                  ],
                ),
        ),
      ),
    ),
  );
}

class _TopicObjectCard extends StatelessWidget {
  const _TopicObjectCard({
    required this.choice,
    required this.featured,
    required this.onTap,
    required this.resume,
    required this.stacked,
  });
  final ListeningTopicChoice choice;
  final bool featured, resume, stacked;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);
    final titleStyle = _topicTitleStyle(choice, featured);
    final art = ListeningObjectArt(choice.id);
    final label = Text(
      featured ? choice.title : choice.label,
      textAlign: featured ? TextAlign.start : TextAlign.center,
      style: titleStyle,
    );
    final action = Container(
      constraints: const BoxConstraints(minHeight: 48),
      padding: const EdgeInsets.all(Spacing.sm),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(ListeningFigma.bubbleActionRadius),
        border: Border.all(color: CPalette.brass),
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xfff9db97), Color(0xffdca64d)],
        ),
        boxShadow: const [
          BoxShadow(color: Color(0xff96703c), offset: Offset(0, 3)),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              resume ? t.contentLearningResume : t.listeningShelfExplore,
              textAlign: TextAlign.center,
              style: titleStyle.copyWith(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const Icon(Icons.chevron_right, size: 18, color: CPalette.ink),
        ],
      ),
    );
    final copy = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          resume ? t.contentLearningResume : t.listeningShelfFocus,
          style: _focusStyle,
        ),
        const SizedBox(height: 4),
        label,
        const SizedBox(height: 8),
        action,
      ],
    );
    Widget content;
    if (featured) {
      content = CPaperPanel(
        radius: 18,
        padding: const EdgeInsets.all(12),
        child: stacked
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(height: ListeningFigma.shelfArtHeight, child: art),
                  const SizedBox(height: 8),
                  copy,
                ],
              )
            : LayoutBuilder(
                builder: (context, bounds) {
                  final imageWidth =
                      bounds.maxWidth * _artFraction(choice, bounds.maxWidth);
                  return Row(
                    children: [
                      Expanded(child: copy),
                      const SizedBox(width: 8),
                      SizedBox(
                        width: imageWidth,
                        height: ListeningFigma.shelfCompactArtHeight,
                        child: art,
                      ),
                    ],
                  );
                },
              ),
      );
    } else {
      final paperLabel = CPaperPanel(
        radius: 8,
        padding: const EdgeInsets.all(Spacing.sm),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 28),
          child: Center(child: label),
        ),
      );
      content = Container(
        padding: const EdgeInsets.fromLTRB(8, 4, 8, 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(ListeningFigma.paperInsetRadius),
          border: Border.all(color: const Color(0xffc7b18f)),
          color: ListeningFigma.jade,
          boxShadow: const [
            BoxShadow(color: Color(0xff02362d), offset: Offset(0, 4)),
            BoxShadow(
              color: Color(0x55001d19),
              offset: Offset(0, 8),
              blurRadius: 10,
            ),
          ],
        ),
        child: stacked
            ? Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(height: ListeningFigma.shelfArtHeight, child: art),
                  const SizedBox(height: 4),
                  paperLabel,
                ],
              )
            : Column(
                children: [
                  Expanded(child: art),
                  const SizedBox(height: 4),
                  paperLabel,
                ],
              ),
      );
    }
    return Semantics(
      key: ValueKey('content-topic-${choice.id}'),
      button: true,
      label:
          '${choice.title}. ${resume ? t.contentLearningResume : t.listeningShelfExplore}. ${choice.progress}',
      onTap: onTap,
      child: ExcludeSemantics(
        child: SoriPressable(
          onTap: onTap,
          surfaceDepth: 3,
          surfaceRadius: 18,
          surfaceEdgeColor: featured
              ? const Color(0xff967243)
              : const Color(0xff02362d),
          tactileTilt: true,
          child: Stack(
            children: [
              content,
              if (choice.complete)
                Positioned(
                  top: 8,
                  right: 8,
                  child: DecoratedBox(
                    decoration: const BoxDecoration(
                      color: CPalette.paper,
                      shape: BoxShape.circle,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(Spacing.xs),
                      child: Icon(Icons.check, color: CPalette.ink, size: 18),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
