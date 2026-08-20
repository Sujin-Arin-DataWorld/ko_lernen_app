import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ko_lernen_app/l10n/generated/app_localizations.dart';
import 'package:ko_lernen_app/models/book_page.dart';
import 'package:ko_lernen_app/models/custom_pack.dart';
import 'package:ko_lernen_app/models/scenario.dart';
import 'package:ko_lernen_app/screens/bookshelf_screen.dart';
import 'package:ko_lernen_app/screens/scenarios_list_screen.dart';
import 'package:ko_lernen_app/screens/vocab_packs_screen.dart';
import 'package:ko_lernen_app/screens/wordbook_search_screen.dart';
import 'package:ko_lernen_app/services/custom_pack_service.dart';
import 'package:ko_lernen_app/services/data_loader.dart';
import 'package:ko_lernen_app/services/storage_service.dart';
import 'package:ko_lernen_app/services/vocab_pack_service.dart';
import 'package:ko_lernen_app/theme.dart';
import 'package:ko_lernen_app/widgets/sori/pack_card.dart';
import 'package:ko_lernen_app/widgets/sori/type_scale.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    Storage.resetForTesting();
    SharedPreferences.setMockInitialValues({
      'kl_tut_bookshelf': true,
      'kl_tut_scenarios': true,
      'kl_user_level': 'a1',
    });
    await Storage.init();
    DataLoader.reset();
    VocabPackService.reset();
  });

  testWidgets('empty bookshelf CTAs remain reachable at 320dp and 200% text', (
    tester,
  ) async {
    await _configurePhone(tester);
    await tester.pumpWidget(_host(const BookshelfScreen()));
    await tester.pump();

    final t = AppL10n.of(tester.element(find.byType(BookshelfScreen)));
    expect(find.text(t.bookshelfTitle), findsWidgets);
    expect(tester.takeException(), isNull);

    await tester.drag(find.byType(ListView), const Offset(0, -300));
    await tester.pump();
    expect(find.text(t.bookshelfEmptyBody), findsOneWidget);
    final secondary = find.text(t.createWordbookCta);
    await tester.scrollUntilVisible(
      secondary,
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.ensureVisible(secondary);
    await tester.pump();
    expect(secondary, findsOneWidget);
    expect(tester.getRect(secondary).bottom, lessThanOrEqualTo(640 - 34));
    expect(tester.takeException(), isNull);
  });

  testWidgets('word filters grow instead of clipping at 320dp and 200% text', (
    tester,
  ) async {
    await CustomPackService.save(
      CustomPack.manual(
        id: 'responsive-pack',
        name: 'Responsive',
        words: [
          ExtractedWord.manual(
            korean: '마음가짐',
            romanization: 'maeumgajim',
            posDe: 'zusammengesetztes koreanisches Substantiv',
            translationDe: 'innere Haltung und Einstellung',
          ),
        ],
      ),
    );
    await _configurePhone(tester);
    await tester.pumpWidget(_host(const WordbookSearchScreen()));
    await tester.pump();

    expect(find.text('마음가짐'), findsOneWidget);
    expect(
      find.text('zusammengesetztes koreanisches Substantiv'),
      findsNWidgets(2),
    );
    final chip = find.descendant(
      of: find.byType(ChoiceChip),
      matching: find.text('zusammengesetztes koreanisches Substantiv'),
    );
    expect(
      tester
          .getSize(find.ancestor(of: chip, matching: find.byType(ChoiceChip)))
          .height,
      greaterThan(44),
    );
    expect(find.text('innere Haltung und Einstellung'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('scenario titles and CTA stack without truncation at 200%', (
    tester,
  ) async {
    await _configurePhone(tester);
    await tester.pumpWidget(
      _host(
        ScenariosListScreen(
          ignoreLevelLock: true,
          loadScenarios: () async => const [_scenarioFixture],
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    final list = find.byType(ListView).first;
    for (var i = 0; i < 5; i += 1) {
      await tester.drag(list, const Offset(0, -240));
      await tester.pump();
      expect(tester.takeException(), isNull);
    }

    expect(find.text(_scenarioFixture.title.de), findsWidgets);
    final t = AppL10n.of(tester.element(find.byType(ScenariosListScreen)));
    expect(find.text(t.scenariosPathStartCta), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('vocab pack cards use a measured one-column grid at 200%', (
    tester,
  ) async {
    await tester.runAsync(() => VocabPackService.loadAll());
    await _configurePhone(tester);
    await tester.pumpWidget(_host(const VocabPacksScreen()));
    await tester.pump();

    final scrollView = find.byType(CustomScrollView);
    for (
      var i = 0;
      i < 20 && find.byType(PackCard).evaluate().isEmpty;
      i += 1
    ) {
      await tester.pump(const Duration(milliseconds: 50));
      if (scrollView.evaluate().isNotEmpty) {
        await tester.drag(scrollView, const Offset(0, -120));
      }
    }

    expect(find.byType(PackCard), findsWidgets);
    expect(tester.getSize(find.byType(PackCard).first).width, greaterThan(250));
    expect(tester.takeException(), isNull);
  });
}

const _scenarioFixture = Scenario(
  id: 'responsive_scenario',
  level: LearnerLevel.a1,
  emoji: 'tiger',
  register: Register.polite,
  title: LocalizedText(
    ko: '공항에서 길고 자세하게 입국 절차를 묻기',
    de: 'Am Flughafen ausführlich nach dem gesamten Einreiseweg fragen',
    en: 'Ask for the complete arrival route at the airport',
  ),
  intro: LocalizedText(ko: '', de: '', en: ''),
  vocab: [],
  grammarIds: [],
  dialog: [],
  quests: [],
);

Future<void> _configurePhone(WidgetTester tester) async {
  tester.view.physicalSize = const Size(320, 640);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

Widget _host(Widget child) {
  return MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: AppTheme.light,
    locale: const Locale('de'),
    supportedLocales: AppL10n.supportedLocales,
    localizationsDelegates: AppL10n.localizationsDelegates,
    builder: (context, appChild) {
      final media = MediaQuery.of(context);
      const safeInsets = EdgeInsets.only(top: 44, bottom: 34);
      return MediaQuery(
        data: media.copyWith(
          padding: safeInsets,
          viewPadding: safeInsets,
          textScaler: const TextScaler.linear(2),
        ),
        child: SoriTypeScale(child: appChild!),
      );
    },
    home: child,
  );
}
