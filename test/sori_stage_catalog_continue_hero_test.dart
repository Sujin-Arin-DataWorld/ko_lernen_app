import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ko_lernen_app/data/sori_activity_catalog.dart';
import 'package:ko_lernen_app/models/sori_stage_progression.dart';
import 'package:ko_lernen_app/services/learning_focus.dart';
import 'package:ko_lernen_app/services/storage_service.dart';
import 'package:ko_lernen_app/widgets/sori/catalog_card.dart';
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
  testWidgets(
    'Learn history stays secondary and never replaces the shared goal',
    (tester) async {
      final controller = LearningFocusController()..value = focus;
      addTearDown(controller.dispose);
      await tester.pumpWidget(catalogTestApp(controller: controller));
      await pumpSoriStage(tester);
      for (final entry in soriActivityCatalog.where(
        (e) => e.tab == SoriStageTab.learn,
      )) {
        await Storage.recordCatalogActivity(entry.id);
        await pumpSoriStage(tester);
        expect(find.text(focus.brief!.unit.title.en), findsOneWidget);
        expect(
          tester
              .widgetList<SoriCatalogCard>(find.byType(SoriCatalogCard))
              .where((card) => card.featured),
          isEmpty,
        );
        expect(
          find.byKey(ValueKey('catalog-card-${entry.id}')),
          entry.id == 'course' ? findsNothing : findsOneWidget,
        );
      }
    },
  );
  testWidgets(
    'Games uses its own validated recent hero once; Learn cannot displace it',
    (tester) async {
      await Storage.setLastActivityId('chosung');
      await Storage.initializeCatalogHistory();
      await Storage.recordCatalogActivity('grammar');
      await tester.pumpWidget(catalogTestApp(tab: SoriStageTab.games));
      await pumpSoriStage(tester);
      var cards = tester
          .widgetList<SoriCatalogCard>(find.byType(SoriCatalogCard))
          .toList();
      expect(cards, hasLength(8));
      expect(cards.where((card) => card.featured).single.entry.id, 'chosung');
      expect(cards.where((card) => card.entry.id == 'chosung'), hasLength(1));
      await Storage.recordCatalogActivity('cloze');
      await pumpSoriStage(tester);
      cards = tester
          .widgetList<SoriCatalogCard>(find.byType(SoriCatalogCard))
          .toList();
      expect(cards.where((card) => card.featured).single.entry.id, 'cloze');
      expect(
        cards.where((card) => !card.featured).map((card) => card.entry.id),
        [
          'daily_game',
          'chosung',
          'syllable_cross',
          'speed_match',
          'sentence_arcade',
          'kkeunmari',
          'custom_practice',
        ],
      );
    },
  );
  testWidgets('unrecorded Games defaults to daily with no resume claim', (
    tester,
  ) async {
    await Storage.recordCatalogActivity('grammar');
    await tester.pumpWidget(catalogTestApp(tab: SoriStageTab.games));
    await pumpSoriStage(tester);
    final featured = tester
        .widgetList<SoriCatalogCard>(find.byType(SoriCatalogCard))
        .singleWhere((card) => card.featured);
    expect(featured.entry.id, 'daily_game');
    expect(featured.recent, isFalse);
    expect(find.text('Continue with'), findsNothing);
  });
}
