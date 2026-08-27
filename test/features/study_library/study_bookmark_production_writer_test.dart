import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ko_lernen_app/features/study_library/study_library.dart';
import 'package:ko_lernen_app/l10n/generated/app_localizations.dart';
import 'package:ko_lernen_app/screens/grammar_screen.dart';
import 'package:ko_lernen_app/screens/smalltalk_screen.dart';
import 'package:ko_lernen_app/services/custom_pack_service.dart';
import 'package:ko_lernen_app/services/data_loader.dart';
import 'package:ko_lernen_app/services/smalltalk_loader.dart';
import 'package:ko_lernen_app/services/storage_service.dart';
import 'package:ko_lernen_app/theme.dart';
import 'package:ko_lernen_app/widgets/sori/content_feed.dart';
import 'package:ko_lernen_app/widgets/sori/type_scale.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'kl_user_level': 'a1',
      'kl_tut_grammar': true,
      'kl_tut_smalltalk': true,
      'kl_tut_wordbook': true,
      'kl_tut_soriDeck': true,
    });
    Storage.resetForTesting();
    await Storage.init();
  });

  testWidgets(
    'GrammarScreen writes a typed grammar and keeps the CustomPack mirror',
    (tester) async {
      TypedStudyBookmarkStore.resetProductionForTesting();
      final grammar = (await tester.runAsync(
        DataLoader.loadGrammar,
      ))!.firstWhere((item) => item.level == 'A1');
      await _pumpScreen(tester, const GrammarScreen());
      await _pumpUntilFeed(tester);
      expect(find.text(grammar.pattern), findsWidgets);

      tester
          .widget<SoriContentFeed>(find.byType(SoriContentFeed))
          .onBookmark!();
      await _pumpUntilBookmark(tester, grammar.pattern);

      final bookmarks = TypedStudyBookmarkStore.production().read().bookmarks;
      expect(bookmarks, hasLength(1));
      expect(bookmarks.single.key.type, StudyLibraryItemType.grammar);
      expect(bookmarks.single.key.id, grammar.pattern);
      expect(bookmarks.single.primaryText, grammar.pattern);
      expect(CustomPackService.containsKorean(grammar.pattern), isTrue);

      final snapshot = await createProductionStudyLibraryRepository().load();
      expect(snapshot.entries, hasLength(1));
      expect(snapshot.entries.single.key.type, StudyLibraryItemType.grammar);
      expect(snapshot.entries.single.primaryText, grammar.pattern);

      expect(
        await TypedStudyBookmarkStore.production().remove(bookmarks.single.key),
        TypedStudyBookmarkMutationResult.removed,
      );
      final afterRemoval = await createProductionStudyLibraryRepository()
          .load();
      expect(afterRemoval.entries, isEmpty);
      expect(
        TypedStudyBookmarkStore.production()
            .read()
            .legacyMirrorSuppressions
            .single
            .type,
        StudyLibraryItemType.grammar,
      );
      // The mirror remains available to vocabulary games even though it must
      // not reappear as a fake word in the Study Library.
      expect(CustomPackService.containsKorean(grammar.pattern), isTrue);
    },
  );

  testWidgets(
    'SmalltalkScreen writes a typed sentence and keeps the CustomPack mirror',
    (tester) async {
      TypedStudyBookmarkStore.resetProductionForTesting();
      await tester.runAsync(SmalltalkLoader.load);
      final phrase = SmalltalkLoader.phrases.firstWhere(
        (item) => item.hasExplicitId,
      );
      await _pumpScreen(tester, SmalltalkScreen(phrases: [phrase]));
      await _pumpUntilFeed(tester);

      tester
          .widget<SoriContentFeed>(find.byType(SoriContentFeed))
          .onBookmark!();
      await _pumpUntilBookmark(tester, phrase.ko);

      final bookmarks = TypedStudyBookmarkStore.production().read().bookmarks;
      expect(bookmarks, hasLength(1));
      expect(bookmarks.single.key.type, StudyLibraryItemType.sentence);
      expect(bookmarks.single.key.id, phrase.id);
      expect(bookmarks.single.primaryText, phrase.ko);
      expect(CustomPackService.containsKorean(phrase.ko), isTrue);

      final snapshot = await createProductionStudyLibraryRepository().load();
      expect(snapshot.entries, hasLength(1));
      expect(snapshot.entries.single.key.type, StudyLibraryItemType.sentence);
      expect(snapshot.entries.single.key.id, phrase.id);
      expect(snapshot.entries.single.primaryText, phrase.ko);
    },
  );

  testWidgets('typed-store quarantine blocks the compatibility mirror', (
    tester,
  ) async {
    TypedStudyBookmarkStore.resetProductionForTesting();
    await Storage.setTypedStudyBookmarksRawJson('{not valid json');
    final grammar = (await tester.runAsync(
      DataLoader.loadGrammar,
    ))!.firstWhere((item) => item.level == 'A1');
    await _pumpScreen(tester, const GrammarScreen());
    await _pumpUntilFeed(tester);

    tester.widget<SoriContentFeed>(find.byType(SoriContentFeed)).onBookmark!();
    await _pumpUntilFailureToast(tester);

    final read = TypedStudyBookmarkStore.production().read();
    expect(read.health, StudyLibraryBookmarkHealth.corrupt);
    expect(read.bookmarks, isEmpty);
    expect(CustomPackService.containsKorean(grammar.pattern), isFalse);
  });

  testWidgets(
    'production callers share one queue and do not lose simultaneous saves',
    (tester) async {
      TypedStudyBookmarkStore.resetProductionForTesting();
      final firstCaller = TypedStudyBookmarkStore.production();
      final secondCaller = TypedStudyBookmarkStore.production();
      expect(identical(firstCaller, secondCaller), isTrue);

      await Future.wait(<Future<TypedStudyBookmarkMutationResult>>[
        firstCaller.upsert(
          TypedStudyBookmark(
            key: StudyItemKey(type: StudyLibraryItemType.grammar, id: '-고 있다'),
            primaryText: '-고 있다',
          ),
        ),
        secondCaller.upsert(
          TypedStudyBookmark(
            key: StudyItemKey(
              type: StudyLibraryItemType.sentence,
              id: 'smalltalk-test',
            ),
            primaryText: '날씨 좋네요.',
          ),
        ),
      ]);

      expect(firstCaller.read().bookmarks, hasLength(2));
    },
  );
}

Future<void> _pumpScreen(WidgetTester tester, Widget child) async {
  tester.view.physicalSize = const Size(400, 800);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      locale: const Locale('de'),
      supportedLocales: AppL10n.supportedLocales,
      localizationsDelegates: AppL10n.localizationsDelegates,
      builder: (context, child) => SoriTypeScale(child: child!),
      home: child,
    ),
  );
  await tester.pump();
}

Future<void> _pumpUntilFeed(WidgetTester tester) async {
  for (var attempt = 0; attempt < 30; attempt++) {
    if (find.byType(SoriContentFeed).evaluate().isNotEmpty) {
      return;
    }
    await tester.pump(const Duration(milliseconds: 100));
  }
  expect(find.byType(SoriContentFeed), findsOneWidget);
}

Future<void> _pumpUntilBookmark(WidgetTester tester, String korean) async {
  for (var attempt = 0; attempt < 30; attempt++) {
    final bookmarks = TypedStudyBookmarkStore.production().read().bookmarks;
    if (bookmarks.isNotEmpty && CustomPackService.containsKorean(korean)) {
      return;
    }
    await tester.pump(const Duration(milliseconds: 50));
  }
  expect(TypedStudyBookmarkStore.production().read().bookmarks, isNotEmpty);
  expect(CustomPackService.containsKorean(korean), isTrue);
}

Future<void> _pumpUntilFailureToast(WidgetTester tester) async {
  final context = tester.element(find.byType(GrammarScreen));
  final message = AppL10n.of(context).wbAddFailed;
  for (var attempt = 0; attempt < 30; attempt++) {
    if (find.text(message).evaluate().isNotEmpty) return;
    await tester.pump(const Duration(milliseconds: 50));
  }
  expect(find.text(message), findsOneWidget);
}
