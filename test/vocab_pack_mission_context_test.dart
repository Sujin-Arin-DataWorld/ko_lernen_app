import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ko_lernen_app/l10n/generated/app_localizations.dart';
import 'package:ko_lernen_app/models/course_practice_context.dart';
import 'package:ko_lernen_app/models/curriculum.dart';
import 'package:ko_lernen_app/models/vocab.dart';
import 'package:ko_lernen_app/models/vocab_pack.dart';
import 'package:ko_lernen_app/screens/vocab_pack_screen.dart';
import 'package:ko_lernen_app/services/curriculum_catalog.dart';
import 'package:ko_lernen_app/services/data_loader.dart';
import 'package:ko_lernen_app/services/storage_service.dart';
import 'package:ko_lernen_app/services/vocab_pack_service.dart';
import 'package:ko_lernen_app/theme.dart';
import 'package:ko_lernen_app/widgets/sori/mission_context_bar.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    Storage.resetForTesting();
    SharedPreferences.setMockInitialValues({});
    await Storage.init();
    await Storage.setTutVocabPackSeen();
    DataLoader.reset();
    VocabPackService.reset();
    CurriculumCatalog.reset();
  });

  testWidgets('shows mission context only for the pack with its source word', (
    tester,
  ) async {
    late ContentLink link;
    late VocabPack pack;
    await tester.runAsync(() async {
      final catalog = await CurriculumCatalog.load();
      final words = await DataLoader.loadVocab();
      final wordsById = {for (final word in words) word.id: word};
      link = catalog.contentLinks.firstWhere(
        (entry) =>
            entry.contentKind == CurriculumContentKind.vocab &&
            wordsById[entry.contentId]?.packId.isNotEmpty == true,
      );
      final Vocab source = wordsById[link.contentId]!;
      pack = (await VocabPackService.findById(source.packId))!;
    });

    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        locale: const Locale('en'),
        supportedLocales: AppL10n.supportedLocales,
        localizationsDelegates: AppL10n.localizationsDelegates,
        home: VocabPackScreen(
          packId: pack.id,
          courseContext: CoursePracticeContext.fromLink(link),
          packLoader: (_) async => pack,
          siblingPacksLoader: (_) async => [pack],
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byType(MissionContextBar), findsOneWidget);
    expect(find.text('Current mission'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
