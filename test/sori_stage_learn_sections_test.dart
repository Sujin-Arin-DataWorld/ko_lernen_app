import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ko_lernen_app/data/sori_activity_catalog.dart';
import 'package:ko_lernen_app/models/sori_stage_progression.dart';
import 'package:ko_lernen_app/services/storage_service.dart';
import 'package:ko_lernen_app/widgets/sori/catalog_card.dart';
import 'support/catalog_test_support.dart';
import 'support/real_fonts.dart';
import 'support/sori_stage_pump.dart';

void main() {
  setUpAll(loadSoriRealFonts);
  setUp(() async {
    Storage.resetForTesting();
    SharedPreferences.setMockInitialValues({});
    await Storage.init();
  });
  test(
    'all eleven practice entries belong to one catalog-owned group; course is separate',
    () {
      final expected = {
        SoriLearnSection.words: ['vocab_packs', 'grammar', 'word_web'],
        SoriLearnSection.listen: [
          'pronunciation',
          'listening',
          'scenarios',
          'smalltalk',
        ],
        SoriLearnSection.hangul: ['hangul', 'calligraphy'],
        SoriLearnSection.review: ['srs', 'my_words'],
      };
      for (final group in expected.entries) {
        expect(
          soriActivityCatalog
              .where((e) => e.learnSection == group.key)
              .map((e) => e.id),
          group.value,
        );
      }
      expect(
        soriActivityCatalog.singleWhere((e) => e.id == 'course').learnSection,
        isNull,
      );
      expect(
        soriActivityCatalog
            .where((e) => e.tab == SoriStageTab.games)
            .every((e) => e.learnSection == null),
        isTrue,
      );
    },
  );
  testWidgets('Learn exposes four ordered groups with every activity once', (
    tester,
  ) async {
    await tester.pumpWidget(catalogTestApp());
    await pumpSoriStage(tester);
    final headings = [
      'Words & sentences',
      'Listen & speak',
      'Hangul & writing',
      'Review & my words',
    ];
    final tops = headings
        .map((title) => tester.getTopLeft(find.text(title)).dy)
        .toList();
    expect(tops.toList()..sort(), tops);
    final cards = tester
        .widgetList<SoriCatalogCard>(find.byType(SoriCatalogCard))
        .toList();
    expect(cards.map((c) => c.entry.id).toSet(), hasLength(11));
    expect(find.byType(ChoiceChip), findsNWidgets(4));
  });
  testWidgets('Games retains eight catalog entries without learning chips', (
    tester,
  ) async {
    await tester.pumpWidget(catalogTestApp(tab: SoriStageTab.games));
    await pumpSoriStage(tester);
    expect(find.byType(ChoiceChip), findsNothing);
    expect(find.byType(SoriCatalogCard), findsNWidgets(8));
  });
}
