import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../l10n/generated/app_localizations.dart';
import '../widgets/sori/book_capture_choice.dart';
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
    return DefaultTabController(
      length: MyWordsTab.values.length,
      initialIndex: initialTab.index,
      child: SoriStandardFrame(
        appBarTitle: t.myWordsTitle,
        actions: [
          TextButton.icon(
            style: TextButton.styleFrom(
              minimumSize: const Size(48, 48),
              padding: const EdgeInsets.symmetric(horizontal: Spacing.sm),
            ),
            onPressed: () {
              // ignore: discarded_futures
              showBookCaptureChoice(context);
            },
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
            child: Column(
              children: [
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    resolvedPadding.left + Spacing.sm,
                    Spacing.xs,
                    resolvedPadding.right + Spacing.sm,
                    0,
                  ),
                  child: Focus(
                    key: const ValueKey('my-words-tab-focus'),
                    autofocus: true,
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
                        tabs.animateTo(next);
                      }
                      return KeyEventResult.handled;
                    },
                    child: TabBar(
                      isScrollable: true,
                      tabAlignment: TabAlignment.start,
                      tabs: [
                        Tab(
                          key: const ValueKey('my-words-tab-search'),
                          icon: const Icon(Icons.search_rounded),
                          iconMargin: const EdgeInsets.only(bottom: Spacing.xs),
                          text: t.myWordsTabSearch,
                        ),
                        Tab(
                          key: const ValueKey('my-words-tab-shelf'),
                          icon: const Icon(Icons.bookmark_rounded),
                          iconMargin: const EdgeInsets.only(bottom: Spacing.xs),
                          text: t.myWordsTabShelf,
                        ),
                        Tab(
                          key: const ValueKey('my-words-tab-difficult'),
                          icon: const Icon(Icons.favorite_rounded),
                          iconMargin: const EdgeInsets.only(bottom: Spacing.xs),
                          text: t.myWordsTabDifficult,
                        ),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  child: TabBarView(
                    children: [
                      WordbookSearchBody(padding: bodyPadding),
                      BookshelfBody(
                        padding: bodyPadding,
                        showEmbeddedSearchAndPhoto: false,
                      ),
                      HardWordsBody(padding: bodyPadding),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
