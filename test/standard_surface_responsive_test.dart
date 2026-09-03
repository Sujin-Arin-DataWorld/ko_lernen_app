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
import 'package:ko_lernen_app/widgets/sori/hanok_header.dart';
import 'package:ko_lernen_app/widgets/sori/level_filter_bar.dart';
import 'package:ko_lernen_app/widgets/sori/pack_card.dart';
import 'package:ko_lernen_app/widgets/sori/standard_page.dart';
import 'package:ko_lernen_app/widgets/sori/study_frame.dart';
import 'package:ko_lernen_app/widgets/sori/text_field.dart';
import 'package:ko_lernen_app/widgets/sori/tokens.dart';
import 'package:ko_lernen_app/widgets/sori/type_scale.dart';
import 'package:ko_lernen_app/widgets/sori/window_class.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // Wordbook search also reads the vocabulary now. Warm the real bundle before
  // any widget test can leave a pending asset future in its fake async zone.
  setUpAll(() async {
    expect(await DataLoader.loadVocab(), isNotEmpty);
  });

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
      final levelLabel = find.text(t.filterLevel);

      // 히어로·부제·섹션헤더는 2026-08-23 에 제거됐다 (Hören 새 단장 P1).
      // AppBar 제목이 화면 이름을 이미 말하므로 선반이 첫 화면 요소다.
      expect(find.byType(HanokHeader), findsNothing);
      expect(find.text(t.listeningSubtitle), findsNothing);
      expect(find.text(t.listeningSelectScenario), findsNothing);
      expect(find.text(t.listeningPickFirst), findsNothing);

      expect(levelLabel, findsOneWidget);
      expect(tester.widget<Text>(levelLabel).style, text.label);
      expect(
        tester.getTopLeft(levelLabel).dy,
        lessThan(tester.getTopLeft(find.byType(ChaekgadoShelfCase)).dy),
      );
      // SoriLevelFilterBar의 가로 ListView는 320dp/200%에서 6칩을 동시에
      // 마운트하지 못한다(뷰포트 폭 기준 가상화 — cacheExtent 무관, 실측
      // 2026-08-27). find.byType(SoriChip) 단일 스냅샷 대신 스크롤 위치를
      // 처음부터 끝까지 훑으며 만난 칩을 누적한다(제스처 드래그는 좌표가
      // 프레임 사이 밀릴 수 있어 ScrollPosition을 직접 이동시킨다) — 검수#5
      // 계약 ①③ 값(48 / 6개)은 그대로, 새 위젯 트리에 맞춰 확인 방식만
      // 바꾼다. DE/EN 두 로케일을 도는 바깥 루프가 같은 키 없는 서브트리를
      // 재사용해 스크롤 위치가 넘어올 수 있으므로 매번 0으로 되감는다.
      final levelBar = find.byType(SoriLevelFilterBar);
      final barScrollable = find.descendant(
        of: levelBar,
        matching: find.byType(Scrollable),
      );
      final scrollState = tester.state<ScrollableState>(barScrollable);
      final seenLabels = <String>{};
      void collectVisibleLevelChips() {
        for (final chip in tester.widgetList<SoriChip>(
          find.descendant(of: levelBar, matching: find.byType(SoriChip)),
        )) {
          expect(chip.minInteractiveHeight, 48);
          seenLabels.add(chip.label);
        }
      }

      scrollState.position.jumpTo(0);
      await tester.pump();
      collectVisibleLevelChips();
      final maxExtent = scrollState.position.maxScrollExtent;
      for (var offset = 80.0; offset < maxExtent; offset += 80.0) {
        scrollState.position.jumpTo(offset);
        await tester.pump();
        collectVisibleLevelChips();
      }
      scrollState.position.jumpTo(maxExtent);
      await tester.pump();
      collectVisibleLevelChips();
      expect(seenLabels, hasLength(LearnerLevel.values.length));

      final c2Chip = find.descendant(
        of: levelBar,
        matching: find.widgetWithText(SoriChip, 'C2'),
      );
      expect(c2Chip, findsOneWidget);
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
