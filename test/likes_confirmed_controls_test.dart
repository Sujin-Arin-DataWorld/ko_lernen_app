import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_platform_interface.dart';

import 'package:ko_lernen_app/data/hangul_data.dart';
import 'package:ko_lernen_app/l10n/generated/app_localizations.dart';
import 'package:ko_lernen_app/models/course_practice_context.dart';
import 'package:ko_lernen_app/models/curriculum.dart';
import 'package:ko_lernen_app/models/guide_contract.dart';
import 'package:ko_lernen_app/models/scenario.dart';
import 'package:ko_lernen_app/models/vocab.dart';
import 'package:ko_lernen_app/screens/custom_pack_play_screen.dart';
import 'package:ko_lernen_app/screens/grammar_screen.dart';
import 'package:ko_lernen_app/screens/hangul_screen.dart';
import 'package:ko_lernen_app/screens/legacy_vocab_screen.dart';
import 'package:ko_lernen_app/screens/listening_play_screen.dart';
import 'package:ko_lernen_app/screens/review_session_screen.dart';
import 'package:ko_lernen_app/services/liked_content_service.dart';
import 'package:ko_lernen_app/services/storage_service.dart';
import 'package:ko_lernen_app/theme.dart';
import 'package:ko_lernen_app/widgets/sori/confirmed_choice_action.dart';
import 'package:ko_lernen_app/widgets/sori/chip.dart';
import 'package:ko_lernen_app/widgets/sori/content_feed.dart';

import 'support/reward_preferences_platform.dart';
import 'support/sori_speech_stubs.dart';

const _word = Vocab(
  id: 'legacy_apple',
  korean: '사과',
  romanization: 'sagwa',
  german: 'Apfel',
  english: 'apple',
  level: 'A1',
  posDe: 'N.',
  exampleKorean: '사과를 먹어요.',
  exampleGerman: 'Ich esse einen Apfel.',
  exampleEnglish: 'I eat an apple.',
  topic: 'Alltag',
);

const _otherWord = Vocab(
  id: 'legacy_teacher',
  korean: '선생님',
  romanization: 'seonsaengnim',
  german: 'Lehrer',
  english: 'teacher',
  level: 'A1',
  posDe: 'N.',
  exampleKorean: '선생님이 와요.',
  exampleGerman: 'Der Lehrer kommt.',
  exampleEnglish: 'The teacher comes.',
  topic: 'Alltag',
);

const _line = '오늘 저녁에 노래해요';
const _otherLine = '내일 아침에 만나요';

final _scenario = Scenario(
  id: 'confirmed_like_scene',
  level: LearnerLevel.a1,
  emoji: '📻',
  register: Register.polite,
  shelf: 'a1_friends',
  backdrop: 'home',
  title: const LocalizedText(ko: '약속', de: 'Verabredung', en: 'Meetup'),
  intro: const LocalizedText(
    ko: '주말 약속을 정해요.',
    de: 'Ihr verabredet euch.',
    en: 'You make plans.',
  ),
  vocab: const [],
  grammarIds: const [],
  dialog: const <DialogLine>[
    DialogLine(
      speaker: 'jieun',
      ko: _line,
      de: 'Heute Abend singen wir.',
      en: 'We sing tonight.',
    ),
  ],
  quests: const [],
);

final _otherScenario = Scenario(
  id: 'confirmed_like_scene_other',
  level: LearnerLevel.a1,
  emoji: '🌅',
  register: Register.polite,
  shelf: 'a1_friends',
  backdrop: 'home',
  title: const LocalizedText(ko: '아침', de: 'Morgen', en: 'Morning'),
  intro: const LocalizedText(
    ko: '아침 약속을 정해요.',
    de: 'Ihr verabredet euch morgens.',
    en: 'You make morning plans.',
  ),
  vocab: const [],
  grammarIds: const [],
  dialog: const <DialogLine>[
    DialogLine(
      speaker: 'jieun',
      ko: _otherLine,
      de: 'Wir treffen uns morgen früh.',
      en: 'We meet tomorrow morning.',
    ),
  ],
  quests: const [],
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final originalPlatform = SharedPreferencesStorePlatform.instance;
  late RewardPreferencesPlatform platform;

  setUp(() async {
    stubSoriSpeech();
    Storage.resetForTesting();
    SharedPreferences.setMockInitialValues({});
    platform = RewardPreferencesPlatform()
      ..values.addAll(<String, Object>{
        'kl_user_level': 'a1',
        'kl_tut_legacyVocab': true,
        'kl_tut_soriDeck': true,
        'kl_tut_wordbook': true,
        'kl_tut_listening_play': true,
        'kl_tut_cpPlay': true,
        'kl_tut_review': true,
        'kl_tut_grammar': true,
        'kl_tut_hangul': true,
        'kl_custom_packs_v1': jsonEncode({
          'old-pack': {
            'name': 'Old',
            'sourcePageId': 'old-page',
            'createdAt': '2026-01-01T00:00:00.000Z',
            'words': [_customWord('옛말', 'old')],
          },
          'new-pack': {
            'name': 'New',
            'sourcePageId': 'new-page',
            'createdAt': '2026-01-02T00:00:00.000Z',
            'words': [_customWord('새말', 'new')],
          },
        }),
      });
    SharedPreferencesStorePlatform.instance = platform;
    await Storage.init();
    platform.writes.clear();
  });

  tearDown(() {
    Storage.resetForTesting();
    SharedPreferences.setMockInitialValues({});
    SharedPreferencesStorePlatform.instance = originalPlatform;
  });

  testWidgets(
    'listening like control waits for native confirmation and offers retry',
    (tester) async {
      await _pump(
        tester,
        ListeningPlayScreen(
          scenario: _scenario,
          speechPlayer: (text, {required voice}) async => true,
          stopPlayer: () async {},
        ),
      );
      final t = AppL10n.of(tester.element(find.byType(ListeningPlayScreen)));
      await tester.tap(find.text(t.listeningDialogueStart));
      await _pumpUntil(
        tester,
        () => find.text(t.listeningCompleteTitle).evaluate().isNotEmpty,
      );
      await tester.tap(find.text(t.listeningReviewCta));
      await tester.pump();
      platform.rejectKey = 'kl_liked_content_v1';

      await tester.tap(find.text(_line));
      await tester.pump(const Duration(milliseconds: 50));
      await tester.tap(find.text(_line));
      await _pumpUntil(
        tester,
        () => platform.writes['kl_liked_content_v1'] == 1,
      );
      await _flush(tester);

      expect(platform.values['kl_liked_content_v1'], isNull);
      expect(
        LikedContentService.isLiked(
          kind: LikedContentService.listening,
          id: 'confirmed_like_scene:0',
        ),
        isFalse,
      );
      expect(find.text(t.btnRetry), findsOneWidget);
      expect(find.textContaining(_line), findsWidgets);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'legacy star control publishes only a confirmed favorite and offers retry',
    (tester) async {
      await _pump(
        tester,
        LegacyVocabScreen(vocabLoader: () async => const <Vocab>[_word]),
      );
      await _pumpUntil(
        tester,
        () => find.byType(SoriContentFeed).evaluate().isNotEmpty,
      );
      final t = AppL10n.of(tester.element(find.byType(LegacyVocabScreen)));
      platform.rejectKey = 'kl_vok_favorites';

      tester
          .widget<SoriContentFeed>(find.byType(SoriContentFeed))
          .onBookmark!();
      await _pumpUntil(tester, () => platform.writes['kl_vok_favorites'] == 1);
      await _flush(tester);

      expect(platform.values['kl_vok_favorites'], isNull);
      expect(Storage.isVokFavorite('사과'), isFalse);
      expect(
        tester.widget<SoriContentFeed>(find.byType(SoriContentFeed)).bookmarked,
        isFalse,
      );
      expect(find.text(t.btnRetry), findsOneWidget);
      expect(find.textContaining('사과'), findsWidgets);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'custom-pack rejects an old rendered callback after source swap',
    (tester) async {
      const screenKey = ValueKey<String>('custom-pack-source-swap');
      await _pump(
        tester,
        const CustomPackPlayScreen(key: screenKey, packId: 'old-pack'),
      );
      await _pumpUntil(
        tester,
        () => find.byType(SoriContentFeed).evaluate().isNotEmpty,
      );
      final oldLike = tester
          .widget<SoriContentFeed>(find.byType(SoriContentFeed))
          .onLike!;

      await _pump(
        tester,
        const CustomPackPlayScreen(key: screenKey, packId: 'new-pack'),
      );
      oldLike();
      await _flush(tester);
      expect(platform.writes['kl_liked_content_v1'], isNull);

      tester.widget<SoriContentFeed>(find.byType(SoriContentFeed)).onLike!();
      await _pumpUntil(
        tester,
        () => platform.writes['kl_liked_content_v1'] == 1,
      );
      expect(platform.values['kl_liked_content_v1'], <String>['vocab|새말']);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('listening rejects an old rendered callback after source swap', (
    tester,
  ) async {
    const screenKey = ValueKey<String>('listening-source-swap');
    Widget screen(Scenario scenario) => ListeningPlayScreen(
      key: screenKey,
      scenario: scenario,
      speechPlayer: (text, {required voice}) async => true,
      stopPlayer: () async {},
    );
    await _pump(tester, screen(_scenario));
    final t = AppL10n.of(tester.element(find.byType(ListeningPlayScreen)));
    await tester.tap(find.text(t.listeningDialogueStart));
    await _pumpUntil(
      tester,
      () => find.text(t.listeningCompleteTitle).evaluate().isNotEmpty,
    );
    await tester.tap(find.text(t.listeningReviewCta));
    await tester.pump();
    final oldLike = tester
        .widgetList<GestureDetector>(
          find.ancestor(
            of: find.text(_line),
            matching: find.byType(GestureDetector),
          ),
        )
        .firstWhere((gesture) => gesture.onDoubleTap != null)
        .onDoubleTap!;

    await _pump(tester, screen(_otherScenario));
    oldLike();
    await _flush(tester);
    expect(platform.writes['kl_liked_content_v1'], isNull);

    final currentLike = tester
        .widgetList<GestureDetector>(
          find.ancestor(
            of: find.text(_otherLine),
            matching: find.byType(GestureDetector),
          ),
        )
        .firstWhere((gesture) => gesture.onDoubleTap != null)
        .onDoubleTap!;
    currentLike();
    await _pumpUntil(tester, () => platform.writes['kl_liked_content_v1'] == 1);
    expect(platform.values['kl_liked_content_v1'], <String>[
      'listening|confirmed_like_scene_other:0',
    ]);
    expect(tester.takeException(), isNull);
  });

  testWidgets('review rejects an old rendered callback after source swap', (
    tester,
  ) async {
    const screenKey = ValueKey<String>('review-source-swap');
    await _pump(
      tester,
      ReviewSessionScreen(
        key: screenKey,
        deck: const <Vocab>[_word],
        cultureNotesLoader: () async {},
      ),
    );
    await _pumpUntil(
      tester,
      () => find.byType(SoriContentFeed).evaluate().isNotEmpty,
    );
    final oldLike = tester
        .widget<SoriContentFeed>(find.byType(SoriContentFeed))
        .onLike!;

    await _pump(
      tester,
      ReviewSessionScreen(
        key: screenKey,
        deck: const <Vocab>[_otherWord],
        cultureNotesLoader: () async {},
      ),
    );
    oldLike();
    await _flush(tester);

    expect(platform.writes['kl_liked_content_v1'], isNull);
    expect(tester.takeException(), isNull);
  });

  testWidgets('legacy rejects an old rendered callback after source swap', (
    tester,
  ) async {
    const screenKey = ValueKey<String>('legacy-source-swap');
    Future<List<Vocab>> oldLoader() async => const <Vocab>[_word];
    Future<List<Vocab>> newLoader() async => const <Vocab>[_otherWord];
    await _pump(
      tester,
      LegacyVocabScreen(key: screenKey, vocabLoader: oldLoader),
    );
    await _pumpUntil(
      tester,
      () => find.byType(SoriContentFeed).evaluate().isNotEmpty,
    );
    final oldLike = tester
        .widget<SoriContentFeed>(find.byType(SoriContentFeed))
        .onLike!;

    await _pump(
      tester,
      LegacyVocabScreen(key: screenKey, vocabLoader: newLoader),
    );
    oldLike();
    await _flush(tester);

    expect(platform.writes['kl_liked_content_v1'], isNull);
    expect(tester.takeException(), isNull);
  });

  testWidgets('grammar rejects an old rendered callback after source swap', (
    tester,
  ) async {
    const screenKey = ValueKey<String>('grammar-source-swap');
    await _pump(tester, const GrammarScreen(key: screenKey));
    await _pumpUntil(
      tester,
      () => find.byType(SoriContentFeed).evaluate().isNotEmpty,
    );
    final oldLike = tester
        .widget<SoriContentFeed>(find.byType(SoriContentFeed))
        .onLike!;

    await _pump(
      tester,
      const GrammarScreen(
        key: screenKey,
        courseContext: CoursePracticeContext(
          courseUnitId: 'changed-unit',
          contentKind: CurriculumContentKind.grammar,
          initialContentId: 'changed-content',
          contentLinkId: 'changed-link',
        ),
      ),
    );
    oldLike();
    await _flush(tester);

    expect(platform.writes['kl_liked_content_v1'], isNull);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Hangul rejects an old callback after hard-source replacement', (
    tester,
  ) async {
    for (final item in consonants) {
      await Storage.markHangulHard(item.letter);
    }
    platform.writes.clear();
    await _pump(
      tester,
      HangulScreen(
        initialTarget: HangulTarget.cards,
        cardsRandom: math.Random(7),
        speechPlayer: (_) async => true,
        textPrefetcher: (_) async {},
      ),
    );
    await _pumpUntil(
      tester,
      () => find.byType(SoriContentFeed).evaluate().isNotEmpty,
    );
    final oldLike = tester
        .widget<SoriContentFeed>(find.byType(SoriContentFeed))
        .onLike!;
    await tester.tap(find.byKey(const Key('hangul-cards-mode-selector')));
    await tester.pump();
    tester
        .widget<SoriChip>(find.byKey(const Key('hangul-cards-hard-only')))
        .onTap!();
    await _flush(tester);

    oldLike();
    await _flush(tester);

    expect(platform.writes['kl_liked_content_v1'], isNull);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'retry remains bound to the failed target after ordinary card advance',
    (tester) async {
      platform.rejectKey = 'kl_liked_content_v1';
      await _pump(tester, const _ChoiceHarness(sourceId: 'source'));

      await tester.tap(find.byKey(const Key('choice-like')));
      await _pumpUntil(
        tester,
        () => platform.writes['kl_liked_content_v1'] == 1,
      );
      await _flush(tester);
      await tester.tap(find.byKey(const Key('choice-advance')));
      await tester.pump();
      expect(find.text('B'), findsWidgets);

      platform.rejectKey = null;
      await tester.tap(
        find.byKey(const Key('confirmed-choice-retry-liked:vocab|A')),
      );
      await _pumpUntil(
        tester,
        () => LikedContentService.isLiked(
          kind: LikedContentService.vocab,
          id: 'A',
        ),
      );

      expect(
        LikedContentService.isLiked(kind: LikedContentService.vocab, id: 'B'),
        isFalse,
      );
      expect(platform.values['kl_liked_content_v1'], <String>['vocab|A']);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('an admitted target completes across ordinary card advance', (
    tester,
  ) async {
    final entered = Completer<void>();
    final release = Completer<void>();
    platform
      ..rejectKey = 'kl_liked_content_v1'
      ..commitBeforeFailure = true
      ..successfulReply = true
      ..writeEntered = entered
      ..releaseWrite = release;
    await _pump(tester, const _ChoiceHarness(sourceId: 'source'));

    await tester.tap(find.byKey(const Key('choice-like')));
    await entered.future;
    await tester.tap(find.byKey(const Key('choice-advance')));
    await tester.pump();
    release.complete();
    await _pumpUntil(
      tester,
      () =>
          LikedContentService.isLiked(kind: LikedContentService.vocab, id: 'A'),
    );

    expect(find.text('B'), findsWidgets);
    expect(platform.values['kl_liked_content_v1'], <String>['vocab|A']);
    expect(tester.takeException(), isNull);
  });

  testWidgets('same-State source replacement retires an admitted target', (
    tester,
  ) async {
    final entered = Completer<void>();
    final release = Completer<void>();
    platform
      ..rejectKey = 'kl_liked_content_v1'
      ..commitBeforeFailure = true
      ..successfulReply = true
      ..writeEntered = entered
      ..releaseWrite = release;
    const harnessKey = ValueKey<String>('same-choice-harness');
    await _pump(
      tester,
      const _ChoiceHarness(key: harnessKey, sourceId: 'old-source'),
    );

    await tester.tap(find.byKey(const Key('choice-like')));
    await entered.future;
    await _pump(
      tester,
      const _ChoiceHarness(key: harnessKey, sourceId: 'new-source'),
    );
    release.complete();
    await _flush(tester);

    expect(platform.values['kl_liked_content_v1'], <String>['vocab|A']);
    expect(
      LikedContentService.isLiked(kind: LikedContentService.vocab, id: 'A'),
      isFalse,
    );
    expect(find.byKey(const Key('confirmed-choice-feedback')), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('real parent pop prevents stale confirmation publication', (
    tester,
  ) async {
    final entered = Completer<void>();
    final release = Completer<void>();
    platform
      ..rejectKey = 'kl_liked_content_v1'
      ..commitBeforeFailure = true
      ..successfulReply = true
      ..writeEntered = entered
      ..releaseWrite = release;
    final navigatorKey = GlobalKey<NavigatorState>();
    await tester.pumpWidget(
      MaterialApp(
        navigatorKey: navigatorKey,
        theme: AppTheme.light,
        locale: const Locale('en'),
        supportedLocales: AppL10n.supportedLocales,
        localizationsDelegates: AppL10n.localizationsDelegates,
        home: const SizedBox.shrink(),
      ),
    );
    navigatorKey.currentState!.push<void>(
      MaterialPageRoute<void>(
        builder: (_) => const _ChoiceHarness(sourceId: 'route-source'),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('choice-like')));
    await entered.future;
    navigatorKey.currentState!.pop();
    await tester.pump();
    release.complete();
    await _flush(tester);

    expect(platform.values['kl_liked_content_v1'], <String>['vocab|A']);
    expect(
      LikedContentService.isLiked(kind: LikedContentService.vocab, id: 'A'),
      isFalse,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('Retry semantics identifies its retained target', (tester) async {
    platform.rejectKey = 'kl_liked_content_v1';
    await _pump(tester, const _ChoiceHarness(sourceId: 'semantics'));
    await tester.tap(find.byKey(const Key('choice-like-a')));
    await _pumpUntil(tester, () => platform.writes['kl_liked_content_v1'] == 1);
    await _flush(tester);

    final retry = find.byKey(const Key('confirmed-choice-retry-liked:vocab|A'));
    final semantics = tester.getSemantics(retry);
    expect(semantics.label, contains('Try again'));
    expect(semantics.label, contains('A'));
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'compact large-text panel scrolls multiple failures and keeps Close reachable',
    (tester) async {
      tester.view.physicalSize = const Size(320, 320);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      platform.rejectKey = 'kl_liked_content_v1';
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          locale: const Locale('en'),
          supportedLocales: AppL10n.supportedLocales,
          localizationsDelegates: AppL10n.localizationsDelegates,
          home: const MediaQuery(
            data: MediaQueryData(
              size: Size(320, 320),
              textScaler: TextScaler.linear(2),
              disableAnimations: true,
            ),
            child: _ChoiceHarness(sourceId: 'compact'),
          ),
        ),
      );
      await _flush(tester);

      await tester.tap(find.byKey(const Key('choice-like-a')));
      await _pumpUntil(
        tester,
        () => platform.writes['kl_liked_content_v1'] == 1,
      );
      await _flush(tester);
      await tester.tap(find.byKey(const Key('confirmed-choice-dismiss')));
      await tester.pump();
      await tester.ensureVisible(find.byKey(const Key('choice-like-b')));
      await tester.tap(find.byKey(const Key('choice-like-b')));
      await _pumpUntil(
        tester,
        () => platform.writes['kl_liked_content_v1'] == 2,
      );
      await _flush(tester);

      expect(
        find.byKey(const Key('confirmed-choice-feedback-scroll')),
        findsOneWidget,
      );
      expect(find.textContaining('\nA'), findsOneWidget);
      expect(find.textContaining('\nB'), findsOneWidget);
      final retryA = find.byKey(
        const Key('confirmed-choice-retry-liked:vocab|A'),
      );
      final dismiss = find.byKey(const Key('confirmed-choice-dismiss'));
      await tester.ensureVisible(retryA);
      expect(tester.getSize(retryA).height, greaterThanOrEqualTo(48));
      final retrySemantics = tester.getSemantics(retryA);
      expect(retrySemantics.label, contains('Try again'));
      expect(retrySemantics.label, contains('A'));
      expect(dismiss, findsOneWidget);
      expect(tester.getSize(dismiss).height, greaterThanOrEqualTo(48));
      await tester.ensureVisible(dismiss);
      await tester.tap(dismiss);
      await tester.pump();
      expect(find.byKey(const Key('confirmed-choice-feedback')), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
}

Map<String, Object?> _customWord(String korean, String english) =>
    <String, Object?>{
      'korean': korean,
      'romanization': '',
      'pos_de': 'N.',
      'translation_de': english,
      'translation_en': english,
      'example_korean': '',
      'example_de': '',
      'definition_ko': '',
      'image_path': '',
      'saved_to_pack_id': null,
    };

Future<void> _pump(WidgetTester tester, Widget home) async {
  tester.view.physicalSize = const Size(800, 1600);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light,
      locale: const Locale('en'),
      supportedLocales: AppL10n.supportedLocales,
      localizationsDelegates: AppL10n.localizationsDelegates,
      home: MediaQuery(
        data: const MediaQueryData(
          size: Size(800, 1600),
          disableAnimations: true,
        ),
        child: home,
      ),
    ),
  );
  await _flush(tester);
}

Future<void> _pumpUntil(WidgetTester tester, bool Function() condition) async {
  for (var attempt = 0; attempt < 60 && !condition(); attempt += 1) {
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    await tester.pump(const Duration(milliseconds: 25));
  }
  expect(
    condition(),
    isTrue,
    reason: 'Expected bounded UI state did not settle.',
  );
}

Future<void> _flush(WidgetTester tester) async {
  for (var attempt = 0; attempt < 12; attempt += 1) {
    await tester.pump(const Duration(milliseconds: 25));
  }
}

class _ChoiceHarness extends StatefulWidget {
  const _ChoiceHarness({super.key, required this.sourceId});

  final String sourceId;

  @override
  State<_ChoiceHarness> createState() => _ChoiceHarnessState();
}

class _ChoiceHarnessState extends State<_ChoiceHarness> {
  late final ConfirmedChoiceActionOwner _owner;
  var _cardIndex = 0;

  String get _card => _cardIndex == 0 ? 'A' : 'B';

  @override
  void initState() {
    super.initState();
    _owner = ConfirmedChoiceActionOwner(
      isCurrentSource: () =>
          mounted && (ModalRoute.of(context)?.isActive ?? false),
      onConfirmed: () {
        if (mounted) {
          setState(() {});
        }
      },
    );
  }

  @override
  void didUpdateWidget(covariant _ChoiceHarness oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.sourceId != widget.sourceId) {
      _owner.replaceSource();
    }
  }

  @override
  void dispose() {
    _owner.dispose();
    super.dispose();
  }

  void _like(String id) {
    unawaited(
      _owner.toggle(
        context,
        ConfirmedChoiceTarget.liked(
          kind: LikedContentService.vocab,
          id: id,
          label: id,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final card = _card;
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: <Widget>[
            Text(card),
            ElevatedButton(
              key: const Key('choice-like'),
              onPressed: () => _like(card),
              child: const Text('Like current'),
            ),
            ElevatedButton(
              key: const Key('choice-like-a'),
              onPressed: () => _like('A'),
              child: const Text('Like A'),
            ),
            ElevatedButton(
              key: const Key('choice-like-b'),
              onPressed: () => _like('B'),
              child: const Text('Like B'),
            ),
            ElevatedButton(
              key: const Key('choice-advance'),
              onPressed: () => setState(() => _cardIndex = 1),
              child: const Text('Advance'),
            ),
          ],
        ),
      ),
    );
  }
}
