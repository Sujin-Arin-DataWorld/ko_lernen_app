import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ko_lernen_app/models/sori_stage_progression.dart';
import 'package:ko_lernen_app/services/learning_focus.dart';
import 'package:ko_lernen_app/services/storage_service.dart';
import 'package:ko_lernen_app/widgets/sori/catalog_card.dart';
import 'package:ko_lernen_app/widgets/sori/collapsing_header.dart';
import 'support/catalog_test_support.dart';
import 'support/real_fonts.dart';
import 'support/sori_stage_pump.dart';

void main() {
  late LearningFocus focus;
  setUpAll(() async {
    await loadSoriRealFonts();
    focus = await loadFirstCatalogFocus();
  });
  setUp(() async {
    Storage.resetForTesting();
    SharedPreferences.setMockInitialValues({});
    await Storage.init();
  });
  for (final tab in [SoriStageTab.learn, SoriStageTab.games]) {
    for (final width in [390.0, 1280.0]) {
      testWidgets(
        '${tab.name} at$width compact header and single48dp end margin',
        (tester) async {
          tester.view.devicePixelRatio = 1;
          tester.view.physicalSize = Size(width, 844);
          addTearDown(tester.view.resetDevicePixelRatio);
          addTearDown(tester.view.resetPhysicalSize);
          final controller = LearningFocusController()..value = focus;
          addTearDown(controller.dispose);
          final scroll = ScrollController();
          addTearDown(scroll.dispose);
          await tester.pumpWidget(
            catalogTestApp(
              tab: tab,
              controller: controller,
              scrollController: scroll,
              locale: 'de',
            ),
          );
          await pumpSoriStage(tester);
          final header = tester.renderObject<RenderSliver>(
            find.byType(SoriCollapsingHeader),
          );
          final first = tab == SoriStageTab.learn
              ? find.byKey(const ValueKey('learning-focus-surface'))
              : find.byKey(const ValueKey('catalog-card-daily_game'));
          expect(
            tester.getTopLeft(first).dy,
            closeTo(20 + header.geometry!.paintExtent + 16, 1),
          );
          if (tab == SoriStageTab.learn) {
            final heading = find.text('Wörter & Sätze');
            final chips = find.byType(ChoiceChip);
            final chipsBottom = chips
                .evaluate()
                .map((e) => tester.getRect(find.byWidget(e.widget)).bottom)
                .reduce((a, b) => a > b ? a : b);
            expect(tester.getRect(heading).top - chipsBottom, closeTo(8, 1));
            expect(
              tester
                      .getRect(
                        find.byKey(const ValueKey('catalog-card-vocab_packs')),
                      )
                      .top -
                  tester.getRect(heading).bottom,
              closeTo(8, 1),
            );
          }
          scroll.jumpTo(scroll.position.maxScrollExtent);
          await pumpSoriStage(tester);
          final cardsBottom = find
              .byType(SoriCatalogCard)
              .evaluate()
              .map((e) => tester.getRect(find.byWidget(e.widget)).bottom)
              .reduce((a, b) => a > b ? a : b);
          final scrollable = find.byType(Scrollable).first;
          final bottom =
              tester.getTopLeft(scrollable).dy +
              scroll.position.viewportDimension;
          expect(bottom - cardsBottom, closeTo(48, 1));
          expect(tester.takeException(), isNull);
        },
      );
    }
  }
}
