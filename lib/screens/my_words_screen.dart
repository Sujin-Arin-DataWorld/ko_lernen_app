import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../l10n/generated/app_localizations.dart';
import '../theme.dart';
import '../widgets/sori/book_capture_choice.dart';
import '../widgets/sori/card.dart';
import '../widgets/sori/learning_stage_navigation.dart';
import '../widgets/sori/standard_page.dart';
import '../widgets/sori/tokens.dart';
import '../widgets/sori/window_class.dart';
import 'bookshelf_screen.dart';
import 'hard_words_screen.dart';
import 'wordbook_search_screen.dart';

enum MyWordsTab { search, shelf, difficult }

MyWordsTab? myWordsTabForRoute(String? routeName) {
  return switch (routeName) {
    '/my_words' || '/wordbook/search' => MyWordsTab.search,
    '/bookshelf' => MyWordsTab.shelf,
    '/hard_words' => MyWordsTab.difficult,
    _ => null,
  };
}

class MyWordsScreen extends StatelessWidget {
  const MyWordsScreen({this.initialTab = MyWordsTab.search, super.key});

  final MyWordsTab initialTab;

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);
    final keyboardOpen = MediaQuery.viewInsetsOf(context).bottom > 0;
    final compactPhotoAction =
        MediaQuery.sizeOf(context).width < 360 ||
        MediaQuery.textScalerOf(context).scale(16) > 24;
    void showPhotoChoices() {
      FocusManager.instance.primaryFocus?.unfocus();
      // ignore: discarded_futures
      showBookCaptureChoice(context);
    }

    return DefaultTabController(
      length: MyWordsTab.values.length,
      initialIndex: initialTab.index,
      child: Theme(
        data: AppTheme.light,
        child: SoriStandardFrame(
          appBarTitle: t.myWordsTitle,
          bottomNavigationBar: keyboardOpen
              ? null
              : const SoriLearningStageNavigation(),
          cMaterial: true,
          cPaperBody: true,
          jadeAppBar: true,
          actions: [
            if (compactPhotoAction)
              IconButton(
                tooltip: t.myWordsPhotoAction,
                constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
                onPressed: showPhotoChoices,
                icon: const Icon(Icons.add_a_photo_outlined),
              )
            else
              TextButton.icon(
                style: TextButton.styleFrom(
                  minimumSize: const Size(48, 48),
                  foregroundColor:
                      MediaQuery.textScalerOf(context).scale(1) <= 1.35
                      ? const Color(0xfff6edde)
                      : null,
                  padding: const EdgeInsets.symmetric(horizontal: Spacing.sm),
                ),
                onPressed: showPhotoChoices,
                icon: const Icon(Icons.add_a_photo_outlined),
                label: Text(t.myWordsPhotoAction),
              ),
          ],
          maxWidth: SoriMaxWidth.hub,
          builder: (context, resolvedPadding) {
            final tabs = DefaultTabController.of(context);
            final bodyPadding = EdgeInsets.fromLTRB(
              resolvedPadding.left + Spacing.md,
              Spacing.md,
              resolvedPadding.right + Spacing.md,
              resolvedPadding.bottom + Spacing.xxl,
            );
            return FocusTraversalGroup(
              policy: OrderedTraversalPolicy(),
              child: LayoutBuilder(
                builder: (context, body) => Column(
                  children: [
                    if (!keyboardOpen)
                      Padding(
                        padding: EdgeInsets.fromLTRB(
                          resolvedPadding.left + Spacing.sm,
                          Spacing.xs,
                          resolvedPadding.right + Spacing.sm,
                          0,
                        ),
                        child: Focus(
                          key: const ValueKey('my-words-tab-focus'),
                          autofocus: !keyboardOpen,
                          onKeyEvent: (node, event) {
                            if (event is! KeyDownEvent) {
                              return KeyEventResult.ignored;
                            }
                            final delta = switch (event.logicalKey) {
                              LogicalKeyboardKey.arrowLeft => -1,
                              LogicalKeyboardKey.arrowRight => 1,
                              _ => 0,
                            };
                            if (delta == 0) {
                              return KeyEventResult.ignored;
                            }
                            final next = (tabs.index + delta).clamp(
                              0,
                              MyWordsTab.values.length - 1,
                            );
                            if (next != tabs.index) {
                              tabs.animateTo(
                                next,
                                duration:
                                    MediaQuery.disableAnimationsOf(context)
                                    ? Duration.zero
                                    : SoriMotion.fast,
                              );
                            }
                            return KeyEventResult.handled;
                          },
                          child: _MyWordsNavigation(
                            controller: tabs,
                            compact: body.maxHeight < 370,
                          ),
                        ),
                      ),
                    Expanded(
                      child: TabBarView(
                        children: [
                          WordbookSearchBody(
                            padding: bodyPadding,
                            boundNotebook: true,
                            keyboardOpen: keyboardOpen,
                          ),
                          BookshelfBody(
                            padding: bodyPadding,
                            showEmbeddedSearchAndPhoto: false,
                            paged: true,
                          ),
                          HardWordsBody(padding: bodyPadding, paged: true),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

/// All three destinations remain visible; enlarged type reflows instead of
/// hiding the last tab beyond a horizontal scroll. The original TabController
/// still owns aliases, keyboard selection, and swipe navigation.
class _MyWordsNavigation extends StatelessWidget {
  const _MyWordsNavigation({required this.controller, required this.compact});

  final TabController controller;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);
    final labels = [
      t.myWordsTabSearch,
      t.myWordsTabShelf,
      t.myWordsTabDifficult,
    ];
    const icons = [
      Icons.search_rounded,
      Icons.bookmark_rounded,
      Icons.favorite_rounded,
    ];
    return AnimatedBuilder(
      key: const ValueKey('my-words-tabs'),
      animation: controller,
      builder: (context, _) => LayoutBuilder(
        builder: (context, constraints) {
          final tiles = [
            for (final tab in MyWordsTab.values)
              SoriCard(
                key: ValueKey('my-words-tab-${tab.name}'),
                variant: SoriCardVariant.compact,
                padding: EdgeInsets.all(compact ? Spacing.xs : Spacing.sm),
                selectable: true,
                selected: controller.index == tab.index,
                semanticLabel: labels[tab.index],
                onTap: () => controller.animateTo(
                  tab.index,
                  duration: MediaQuery.disableAnimationsOf(context)
                      ? Duration.zero
                      : SoriMotion.fast,
                ),
                child: ExcludeSemantics(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(minHeight: 48),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          icons[tab.index],
                          color: SoriColors.primary,
                          size: 20,
                        ),
                        if (!compact) ...[
                          const SizedBox(height: Spacing.xs),
                          Text(
                            labels[tab.index],
                            textAlign: TextAlign.center,
                            style: SoriTextTheme.of(context).label,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
          ];
          final scale = MediaQuery.textScalerOf(context).scale(1);
          final reflow =
              !compact &&
              (constraints.maxWidth - Spacing.sm * 2) / 3 <
                  SoriAdaptiveWidth.myWordsTabColumn * scale;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(child: tiles[0]),
                    const SizedBox(width: Spacing.sm),
                    Expanded(child: tiles[1]),
                    if (!reflow) ...[
                      const SizedBox(width: Spacing.sm),
                      Expanded(child: tiles[2]),
                    ],
                  ],
                ),
              ),
              if (reflow) ...[const SizedBox(height: Spacing.sm), tiles[2]],
            ],
          );
        },
      ),
    );
  }
}
