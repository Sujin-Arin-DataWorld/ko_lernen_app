import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ko_lernen_app/l10n/generated/app_localizations.dart';
import 'package:ko_lernen_app/models/course_practice_context.dart';
import 'package:ko_lernen_app/models/curriculum.dart';
import 'package:ko_lernen_app/screens/vocab_packs_screen.dart';
import 'package:ko_lernen_app/services/curriculum_catalog.dart';
import 'package:ko_lernen_app/services/data_loader.dart';
import 'package:ko_lernen_app/services/pack_progress_service.dart';
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
    DataLoader.reset();
    VocabPackService.reset();
    CurriculumCatalog.reset();
  });

  testWidgets('shows exact mission context only for a typed vocab route', (
    tester,
  ) async {
    late ContentLink link;
    await tester.runAsync(() async {
      final catalog = await CurriculumCatalog.load();
      link = catalog.contentLinks.firstWhere(
        (entry) => entry.contentKind == CurriculumContentKind.vocab,
      );
      await PackProgressService.loadLevelView('A1');
    });

    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        locale: const Locale('en'),
        supportedLocales: AppL10n.supportedLocales,
        localizationsDelegates: AppL10n.localizationsDelegates,
        home: VocabPacksScreen(
          courseUnitId: link.courseUnitId,
          courseContext: CoursePracticeContext.fromLink(link),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byType(MissionContextBar), findsOneWidget);
    expect(find.text('Current mission'), findsOneWidget);
    expect(find.textContaining('Step '), findsOneWidget);
    // Scoped view explains the subset and offers an exit to the full library.
    expect(find.text('Only packs for your current mission.'), findsOneWidget);
    expect(find.text('Browse all vocab packs'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('keeps direct vocab browsing free of mission context', (
    tester,
  ) async {
    await tester.runAsync(() => PackProgressService.loadLevelView('A1'));

    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        locale: const Locale('en'),
        supportedLocales: AppL10n.supportedLocales,
        localizationsDelegates: AppL10n.localizationsDelegates,
        home: const VocabPacksScreen(),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byType(MissionContextBar), findsNothing);
    // Direct browsing already shows the whole library — no scope banner.
    expect(find.text('Browse all vocab packs'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
