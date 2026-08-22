import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ko_lernen_app/l10n/generated/app_localizations.dart';
import 'package:ko_lernen_app/data/quest_catalog.dart';
import 'package:ko_lernen_app/models/book_page.dart';
import 'package:ko_lernen_app/models/custom_pack.dart';
import 'package:ko_lernen_app/models/quest.dart';
import 'package:ko_lernen_app/models/scenario.dart';
import 'package:ko_lernen_app/models/vocab.dart';
import 'package:ko_lernen_app/screens/bookshelf_screen.dart';
import 'package:ko_lernen_app/screens/custom_pack_edit_screen.dart';
import 'package:ko_lernen_app/screens/dojangcheop_screen.dart';
import 'package:ko_lernen_app/screens/hard_words_screen.dart';
import 'package:ko_lernen_app/screens/listening_screen.dart';
import 'package:ko_lernen_app/screens/profile_screen.dart';
import 'package:ko_lernen_app/screens/quests_screen.dart';
import 'package:ko_lernen_app/screens/scenarios_list_screen.dart';
import 'package:ko_lernen_app/screens/stats_screen.dart';
import 'package:ko_lernen_app/screens/vocab_packs_screen.dart';
import 'package:ko_lernen_app/screens/vocab_pack_result_screen.dart';
import 'package:ko_lernen_app/screens/wordbook_search_screen.dart';
import 'package:ko_lernen_app/services/custom_pack_service.dart';
import 'package:ko_lernen_app/services/data_loader.dart';
import 'package:ko_lernen_app/services/storage_service.dart';
import 'package:ko_lernen_app/services/vocab_pack_service.dart';
import 'package:ko_lernen_app/services/word_image_service.dart';
import 'package:ko_lernen_app/theme.dart';
import 'package:ko_lernen_app/widgets/sori/dancheong_stamp.dart';
import 'package:ko_lernen_app/widgets/app_loading.dart';
import 'package:ko_lernen_app/widgets/sori/chaekgado/shelf_case.dart';
import 'package:ko_lernen_app/widgets/sori/chip.dart';
import 'package:ko_lernen_app/widgets/sori/empty_state.dart';
import 'package:ko_lernen_app/widgets/sori/pack_card.dart';
import 'package:ko_lernen_app/widgets/sori/section_header.dart';
import 'package:ko_lernen_app/widgets/sori/standard_page.dart';
import 'package:ko_lernen_app/widgets/sori/study_frame.dart';
import 'package:ko_lernen_app/widgets/sori/text_field.dart';
import 'package:ko_lernen_app/widgets/sori/tokens.dart';
import 'package:ko_lernen_app/widgets/sori/type_scale.dart';
import 'package:ko_lernen_app/widgets/sori/window_class.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    Storage.resetForTesting();
    SharedPreferences.setMockInitialValues({
      'kl_tut_bookshelf': true,
      'kl_tut_scenarios': true,
      'kl_tut_profile': true,
      'kl_tut_quests': true,
      'kl_tut_hardWords': true,
      'kl_tut_listening': true,
      'kl_tut_dojang': true,
      'kl_user_level': 'a1',
      'kl_streak_days': 3,
      'kl_xp': 40,
      'kl_stamps_earned': <String>['lotus'],
    });
    await Storage.init();
    for (final coachId in <String>[
      'profile',
      'stats',
      'quests',
      'hardWords',
      'listening',
      'dojang',
      'cpEdit',
    ]) {
      await Storage.setTutSeen(coachId);
    }
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

    expect(find.byType(SoriTextField), findsOneWidget);
    expect(find.text('마음가짐'), findsOneWidget);
    expect(
      find.text('zusammengesetztes koreanisches Substantiv'),
      findsNWidgets(2),
    );
    final chip = find.byKey(
      const ValueKey('wordbook-pos-zusammengesetztes koreanisches Substantiv'),
    );
    final soriChip = tester.widget<SoriChip>(chip);
    expect(soriChip.maxLines, isNull);
    expect(soriChip.minInteractiveHeight, greaterThanOrEqualTo(48));
    expect(tester.getSize(chip).height, greaterThanOrEqualTo(48));
    expect(find.text('innere Haltung und Einstellung'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('custom pack actions and user text stay complete at 200%', (
    tester,
  ) async {
    const translation =
        'eine besonders ausführliche innere Haltung und Einstellung';
    await CustomPackService.save(
      CustomPack.manual(
        id: 'responsive-edit-pack',
        name: 'Mein ausführliches koreanisches Lernwörterbuch',
        words: [
          ExtractedWord.manual(korean: '마음가짐', translationDe: translation),
        ],
      ),
    );
    await _configurePhone(tester);
    await tester.pumpWidget(
      _host(const CustomPackEditScreen(packId: 'responsive-edit-pack')),
    );
    await tester.pump();

    final t = AppL10n.of(tester.element(find.byType(CustomPackEditScreen)));
    final cards = find.text(t.wbStudyCards);
    final matching = find.text(t.wbMatching);
    expect(find.byType(SoriStandardFrame), findsOneWidget);
    expect(tester.takeException(), isNull);
    expect(find.byType(ListView), findsOneWidget);
    expect(tester.getSize(find.byType(ListView)).height, greaterThan(0));
    expect(
      find.text('Mein ausführliches koreanisches Lernwörterbuch'),
      findsOneWidget,
    );
    expect(cards, findsOneWidget);
    expect(matching, findsOneWidget);
    expect(
      tester.getRect(matching).top,
      greaterThan(tester.getRect(cards).bottom),
    );
    expect(find.text(t.wbAddWord), findsOneWidget);

    final translationFinder = find.text(translation);
    await tester.scrollUntilVisible(
      translationFinder,
      240,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pump();
    expect(translationFinder, findsOneWidget);
    expect(
      tester.renderObject<RenderParagraph>(translationFinder).didExceedMaxLines,
      isFalse,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('word photo denial stays in the editor with a clear message', (
    tester,
  ) async {
    await CustomPackService.save(
      CustomPack.manual(id: 'camera-denied-pack', name: 'Mein Wörterbuch'),
    );
    var pickerCalls = 0;
    await _configurePhone(tester);
    await tester.pumpWidget(
      _host(
        CustomPackEditScreen(
          packId: 'camera-denied-pack',
          wordImagePicker: (source, {required workflowId}) async {
            pickerCalls++;
            throw const CameraPermissionDeniedException();
          },
        ),
      ),
    );
    await tester.pump();

    final addWord = find.text('Wort hinzufügen');
    await tester.scrollUntilVisible(
      addWord,
      220,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(addWord);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Kamera'));
    await tester.pumpAndSettle();

    expect(pickerCalls, 1);
    expect(find.textContaining('Berechtigung verweigert'), findsOneWidget);
    expect(find.text('Galerie'), findsOneWidget);
  });

  for (final locale in const [Locale('de'), Locale('en')]) {
    testWidgets(
      '${locale.languageCode} vocab result stacks stats and keeps the final CTA reachable',
      (tester) async {
        await _configurePhone(tester);
        await tester.pumpWidget(
          _host(
            const VocabPackResultScreen(
              packId: 'a1_greetings_1',
              bossAccuracy: 1 / 3,
              bossCorrect: 1,
              bossTotal: 3,
              quizCorrect: 2,
              quizTotal: 4,
              justCleared: false,
              nextUnlockedPackId: null,
            ),
            locale: locale,
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 1100));

        final t = AppL10n.of(
          tester.element(find.byType(VocabPackResultScreen)),
        );
        final bossLabel = find.text(t.vocabPackResultBossLabel);
        final bossValue = find.text('1 / 3 (33%)');
        expect(find.byType(SoriStudyFrame), findsOneWidget);
        expect(bossLabel, findsOneWidget);
        expect(bossValue, findsOneWidget);
        expect(
          tester.getRect(bossValue).top,
          greaterThanOrEqualTo(tester.getRect(bossLabel).bottom),
        );

        final finalCta = find.text(t.vocabPackResultBackToGrid);
        await tester.scrollUntilVisible(
          finalCta,
          240,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.pump();
        expect(finalCta, findsOneWidget);
        expect(
          tester.renderObject<RenderParagraph>(finalCta).didExceedMaxLines,
          isFalse,
        );
        expect(tester.takeException(), isNull);
      },
    );
  }

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

  testWidgets('profile copy and final stats action remain reachable at 200%', (
    tester,
  ) async {
    await _configurePhone(tester);
    await tester.pumpWidget(_host(const ProfileScreen()));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    final t = AppL10n.of(tester.element(find.byType(ProfileScreen)));
    final target = find.text(t.profileViewStats);
    await tester.scrollUntilVisible(
      target,
      240,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.ensureVisible(target);
    await tester.pump();

    expect(find.byType(SoriStandardFrame), findsOneWidget);
    expect(tester.getRect(target).bottom, lessThanOrEqualTo(640 - 34));
    expect(tester.takeException(), isNull);
  });

  testWidgets('stats keep the final game summary reachable at 200%', (
    tester,
  ) async {
    await _configurePhone(tester);
    await tester.pumpWidget(_host(const StatsScreen()));
    await tester.pump();

    final t = AppL10n.of(tester.element(find.byType(StatsScreen)));
    final target = find.text(t.gameWordleTitle);
    await tester.scrollUntilVisible(
      target,
      240,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.ensureVisible(target);
    await tester.pump();

    expect(target, findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('quest title and action are not compressed into badge chrome', (
    tester,
  ) async {
    final definition = kQuestCatalog.first;
    final progress = QuestProgress(
      questId: definition.id,
      current: 1,
      target: definition.target,
      active: true,
      completed: false,
      completedAtIso: null,
    );
    await _configurePhone(tester);
    await tester.pumpWidget(
      _host(
        QuestsScreen(
          loadQuests: () async => [progress],
          persistNewCompletions: (_) async {},
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    final title = find.text(definition.name.de);
    final list = find.byType(ListView).first;
    for (var i = 0; i < 5 && title.evaluate().isEmpty; i += 1) {
      await tester.drag(list, const Offset(0, -180));
      await tester.pump();
    }
    expect(title, findsOneWidget);
    expect(find.byType(SoriStandardFrame), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('hard-word translation and both bottom actions stay visible', (
    tester,
  ) async {
    for (var i = 0; i < 3; i += 1) {
      await Storage.incrementWrongCount(_hardWordFixture.korean);
    }
    await _configurePhone(tester);
    await tester.pumpWidget(
      _host(HardWordsScreen(deckLoader: () async => [_hardWordFixture])),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    final t = AppL10n.of(tester.element(find.byType(HardWordsScreen)));
    final list = find.byType(ListView).first;
    for (
      var i = 0;
      i < 4 && find.text(t.hardWordsStudyCta).evaluate().isEmpty;
      i += 1
    ) {
      await tester.drag(list, const Offset(0, -180));
      await tester.pump();
    }
    final translation = tester.widget<Text>(find.text(_hardWordFixture.german));
    expect(translation.overflow, isNull);
    expect(find.text(t.hardWordsHardQuizCta), findsOneWidget);
    expect(find.text(t.hardWordsStudyCta), findsOneWidget);
    expect(find.byType(SoriBottomActionArea), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('DE/EN listening hierarchy labels filters at 200% text', (
    tester,
  ) async {
    await _configurePhone(tester);
    final semantics = tester.ensureSemantics();
    for (final locale in const [Locale('de'), Locale('en')]) {
      await tester.pumpWidget(
        _host(
          ListeningScreen(
            scenariosLoader: () async => const [_scenarioFixture],
          ),
          locale: locale,
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      final screenContext = tester.element(find.byType(ListeningScreen));
      final t = AppL10n.of(screenContext);
      final text = SoriTextTheme.of(screenContext);
      final subtitle = find.text(t.listeningSubtitle);
      final section = find.text(t.listeningSelectScenario);
      final instruction = find.text(t.listeningPickFirst);
      final levelLabel = find.text(t.filterLevel);

      expect(tester.widget<Text>(subtitle).style, text.bodySmall);
      expect(
        find.widgetWithText(SoriSectionHeader, t.listeningSelectScenario),
        findsOneWidget,
      );
      expect(tester.widget<Text>(section).style, text.h2);
      expect(
        tester
            .getSemantics(section)
            .getSemanticsData()
            .flagsCollection
            .isHeader,
        isTrue,
      );
      expect(tester.widget<Text>(instruction).style, text.meta);
      expect(levelLabel, findsOneWidget);
      expect(tester.widget<Text>(levelLabel).style, text.label);
      expect(
        tester.getTopLeft(section).dy,
        lessThan(tester.getTopLeft(instruction).dy),
      );
      expect(
        tester.getTopLeft(instruction).dy,
        lessThan(tester.getTopLeft(levelLabel).dy),
      );
      expect(find.text('A1'), findsWidgets);
      expect(find.text('C2'), findsWidgets);
      final levelChips = tester.widgetList<SoriChip>(find.byType(SoriChip));
      expect(levelChips, hasLength(LearnerLevel.values.length));
      expect(
        levelChips.every((chip) => chip.minInteractiveHeight == 48),
        isTrue,
      );
      final c2Chip = find.widgetWithText(SoriChip, 'C2');
      await tester.ensureVisible(c2Chip);
      await tester.pump();
      await tester.tap(c2Chip);
      await tester.pump();
      expect(tester.widget<SoriChip>(c2Chip).selected, isTrue);
      expect(find.byType(ChaekgadoShelfCase), findsOneWidget);
      expect(tester.takeException(), isNull);
    }
    semantics.dispose();
  });

  testWidgets('listening loading and empty states use shared surfaces', (
    tester,
  ) async {
    await _configurePhone(tester);
    final scenarios = Completer<List<Scenario>>();
    await tester.pumpWidget(
      _host(ListeningScreen(scenariosLoader: () => scenarios.future)),
    );
    await tester.pump();
    expect(find.byType(AppLoading), findsOneWidget);

    scenarios.complete(const []);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    final t = AppL10n.of(tester.element(find.byType(ListeningScreen)));
    expect(find.byType(SoriEmptyState), findsOneWidget);
    expect(find.text(t.listeningEmptyTitle), findsOneWidget);
    expect(find.text(t.listeningEmptyBody), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'listening shelf reflows across short, phone, tablet and desktop',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      for (final size in const [
        Size(360, 400),
        Size(390, 844),
        Size(720, 1024),
        Size(1280, 900),
      ]) {
        for (final locale in const [Locale('de'), Locale('en')]) {
          tester.view.physicalSize = size;
          await tester.pumpWidget(
            _host(
              ListeningScreen(
                scenariosLoader: () async => const [_scenarioFixture],
              ),
              locale: locale,
              textScale: size.height <= 400 ? 1 : 1.3,
            ),
          );
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 100));

          final screenContext = tester.element(find.byType(ListeningScreen));
          final t = AppL10n.of(screenContext);
          expect(find.text(t.listeningSelectScenario), findsOneWidget);
          expect(find.text(t.filterLevel), findsOneWidget);
          expect(find.byType(ChaekgadoShelfCase), findsOneWidget);
          expect(
            tester.getSize(find.byType(ChaekgadoShelfCase)).width,
            lessThanOrEqualTo(SoriMaxWidth.hub),
          );
          expect(tester.takeException(), isNull);
        }
      }
    },
  );

  testWidgets('dojang stamps shrink inside the 320dp three-column grid', (
    tester,
  ) async {
    await _configurePhone(tester);
    await tester.pumpWidget(_host(const DojangcheopScreen()));
    await tester.pump();

    final list = find.byType(ListView).first;
    for (var i = 0; i < 4; i += 1) {
      await tester.drag(list, const Offset(0, -200));
      await tester.pump();
    }

    final stamps = tester.widgetList<DancheongStamp>(
      find.byType(DancheongStamp),
    );
    expect(stamps, isNotEmpty);
    expect(stamps.every((stamp) => stamp.size < 96), isTrue);
    expect(tester.takeException(), isNull);
  });
}

const _scenarioFixture = Scenario(
  id: 'responsive_scenario',
  level: LearnerLevel.a1,
  emoji: 'tiger',
  register: Register.polite,
  shelf: 'a1_friends',
  title: LocalizedText(
    ko: '공항에서 길고 자세하게 입국 절차를 묻기',
    de: 'Am Flughafen ausführlich nach dem gesamten Einreiseweg fragen',
    en: 'Ask for the complete arrival route at the airport',
  ),
  intro: LocalizedText(ko: '', de: '', en: ''),
  vocab: [],
  grammarIds: [],
  dialog: [
    DialogLine(
      speaker: 'jieun',
      ko: '도와주세요.',
      de: 'Bitte helfen Sie mir.',
      en: 'Please help me.',
    ),
  ],
  quests: [],
);

const _hardWordFixture = Vocab(
  id: 'responsive_hard_word',
  korean: '마음가짐',
  romanization: 'maeumgajim',
  german: 'eine besonders ausführliche innere Haltung und Einstellung',
  level: 'B2',
  posDe: 'Nomen',
  exampleKorean: '',
  exampleGerman: '',
  topic: 'test',
);

Future<void> _configurePhone(WidgetTester tester) async {
  tester.view.physicalSize = const Size(320, 640);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

Widget _host(
  Widget child, {
  Locale locale = const Locale('de'),
  double textScale = 2,
}) {
  return MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: AppTheme.light,
    locale: locale,
    supportedLocales: AppL10n.supportedLocales,
    localizationsDelegates: AppL10n.localizationsDelegates,
    builder: (context, appChild) {
      final media = MediaQuery.of(context);
      const safeInsets = EdgeInsets.only(top: 44, bottom: 34);
      return MediaQuery(
        data: media.copyWith(
          padding: safeInsets,
          viewPadding: safeInsets,
          textScaler: TextScaler.linear(textScale),
        ),
        child: SoriTypeScale(child: appChild!),
      );
    },
    home: child,
  );
}
