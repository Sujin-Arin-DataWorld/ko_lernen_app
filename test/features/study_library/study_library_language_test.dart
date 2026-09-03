import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ko_lernen_app/features/study_library/study_library.dart';
import 'package:ko_lernen_app/l10n/generated/app_localizations.dart';
import 'package:ko_lernen_app/models/book_page.dart';
import 'package:ko_lernen_app/models/custom_pack.dart';
import 'package:ko_lernen_app/screens/study_library_screen.dart';
import 'package:ko_lernen_app/screens/wordbook_search_screen.dart';
import 'package:ko_lernen_app/screens/custom_pack_play_screen.dart';
import 'package:ko_lernen_app/services/custom_pack_service.dart';
import 'package:ko_lernen_app/services/data_loader.dart';
import 'package:ko_lernen_app/services/storage_service.dart';
import 'package:ko_lernen_app/theme.dart';
import 'package:ko_lernen_app/widgets/flip_card.dart';
import 'package:ko_lernen_app/widgets/sori/wordbook_add.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _bilingual = ExtractedWord(
  korean: '내말',
  romanization: '',
  posDe: 'Nomen',
  translationDe: 'Meine eigene Bedeutung',
  translationEn: 'My own meaning',
  exampleKorean: '',
  exampleDe: '',
  savedToPackId: null,
);
const _unknown = ExtractedWord(
  korean: '나만의말',
  romanization: '',
  posDe: 'Nomen',
  translationDe: 'Meine unveränderte Notiz',
  translationEn: '',
  exampleKorean: '',
  exampleDe: '',
  savedToPackId: null,
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({
      'kl_tut_cpPlay': true,
      'kl_tut_soriDeck': true,
      'kl_tut_wordbook': true,
    });
    Storage.resetForTesting();
    await Storage.init();
    TypedStudyBookmarkStore.resetProductionForTesting();
    // Load real authored assets outside the widget fake-async clock.
    await createProductionStudyLibraryRepository(languageCode: 'en').load();
  });

  Future<void> saveWords(List<ExtractedWord> words) => CustomPackService.save(
    CustomPack.manual(id: 'language-pack', name: 'Personal', words: words),
  );

  test(
    'production adapters use current locale and preserve unknown source text',
    () async {
      final vocab = (await DataLoader.loadVocab()).first;
      await saveWords([
        _bilingual,
        _unknown,
        ExtractedWord.manual(korean: vocab.korean, translationDe: vocab.german),
      ]);
      final before = Storage.customPacksRawJson;
      for (final language in ['en', 'de']) {
        final records = await ProductionStudyLibraryCustomPackReader(
          languageCode: language,
        ).readCustomPackItems();
        expect(
          records
              .singleWhere((r) => r.key.id == _bilingual.korean)
              .secondaryText,
          language == 'en'
              ? _bilingual.translationEn
              : _bilingual.translationDe,
        );
        expect(
          records.singleWhere((r) => r.key.id == _unknown.korean).secondaryText,
          language == 'en' ? isNull : _unknown.translationDe,
        );
        expect(
          records.singleWhere((r) => r.key.id == vocab.korean).secondaryText,
          language == 'en' ? vocab.english : vocab.german,
        );
      }
      expect(Storage.customPacksRawJson, before);
    },
  );

  test(
    'legacy typed bookmarks resolve vocabulary and grammar by stable id',
    () async {
      final vocab = (await DataLoader.loadVocab()).first;
      final grammar = (await DataLoader.loadGrammar()).firstWhere(
        (g) => g.id == 'grammar_b2_as_you_see',
      );
      final store = TypedStudyBookmarkStore.production();
      for (final bookmark in [
        TypedStudyBookmark(
          key: StudyItemKey(type: StudyLibraryItemType.word, id: vocab.id),
          primaryText: vocab.korean,
          secondaryText: vocab.german,
        ),
        TypedStudyBookmark(
          key: StudyItemKey(
            type: StudyLibraryItemType.grammar,
            id: grammar.pattern,
          ),
          primaryText: grammar.pattern,
          secondaryText: grammar.explanationDe,
          sourceUnitId: grammar.id,
        ),
        TypedStudyBookmark(
          key: StudyItemKey(type: StudyLibraryItemType.sentence, id: 'unknown'),
          primaryText: _unknown.korean,
          secondaryText: _unknown.translationDe,
        ),
      ]) {
        await store.upsert(bookmark);
      }
      final before = store.read().bookmarks.map((b) => b.toJson()).toList();
      final snapshot = await ProductionStudyLibraryBookmarkReader(
        store,
        languageCode: 'en',
      ).readBookmarks();
      expect(
        snapshot.records.singleWhere((r) => r.key.id == vocab.id).secondaryText,
        vocab.english,
      );
      expect(
        snapshot.records
            .singleWhere((r) => r.key.id == grammar.pattern)
            .secondaryText,
        grammar.explanationEn,
      );
      expect(
        snapshot.records
            .singleWhere((r) => r.key.id == 'unknown')
            .secondaryText,
        isNull,
      );
      expect(store.read().bookmarks.map((b) => b.toJson()).toList(), before);
    },
  );

  testWidgets('production library switches language without reopening', (
    tester,
  ) async {
    await saveWords([_bilingual]);
    await Storage.toggleLikedContent('vocab|${_bilingual.korean}');
    final language = ValueNotifier(const Locale('en'));
    addTearDown(language.dispose);
    await tester.pumpWidget(
      ValueListenableBuilder<Locale>(
        valueListenable: language,
        builder: (_, locale, child) => _app(child!, locale: locale),
        child: const StudyLibraryScreen(),
      ),
    );
    await tester.runAsync(
      () => createProductionStudyLibraryRepository(languageCode: 'en').load(),
    );
    await tester.pumpAndSettle();
    expect(find.text('My own meaning'), findsOneWidget);
    language.value = const Locale('de');
    await tester.pump();
    await tester.runAsync(
      () => createProductionStudyLibraryRepository(languageCode: 'de').load(),
    );
    await tester.pumpAndSettle();
    expect(find.text('Meine eigene Bedeutung'), findsOneWidget);
    expect(find.text('My own meaning'), findsNothing);
    language.value = const Locale('en');
    await tester.pump();
    await tester.runAsync(
      () => createProductionStudyLibraryRepository(languageCode: 'en').load(),
    );
    await tester.pumpAndSettle();
    expect(find.text('My own meaning'), findsOneWidget);
    expect(find.text('Meine eigene Bedeutung'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'unknown legacy words have a truthful missing state in search and cards',
    (tester) async {
      await saveWords([_unknown]);
      await tester.pumpWidget(_app(const WordbookSearchScreen()));
      await tester.pumpAndSettle();
      expect(find.text('No English translation is saved yet.'), findsOneWidget);
      expect(find.text(_unknown.translationDe), findsNothing);
      expect(find.text('Nomen'), findsNothing);
      expect(find.text('Noun'), findsWidgets);
      await tester.pumpWidget(
        _app(const CustomPackPlayScreen(packId: 'language-pack')),
      );
      await tester.pumpAndSettle();
      tester.widget<FlipCard>(find.byType(FlipCard)).onTap!();
      await tester.pumpAndSettle();
      expect(find.text('No English translation is saved yet.'), findsOneWidget);
      expect(find.text('Add a translation'), findsOneWidget);
      expect(find.text(_unknown.translationDe), findsNothing);
      expect(
        CustomPackService.getById('language-pack')!.words.single.translationDe,
        _unknown.translationDe,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'typed writer records the selected fallback language in bookmark and mirror',
    (tester) async {
      late BuildContext saveContext;
      await tester.pumpWidget(
        _app(
          Builder(
            builder: (context) {
              saveContext = context;
              return const SizedBox();
            },
          ),
        ),
      );
      await tester.pumpAndSettle();
      for (final (requested, de, en, expected, korean) in [
        ('en', 'Deutscher Text', '', 'de', '첫문장'),
        ('de', '', 'English text', 'en', '둘문장'),
        ('en', 'Deutscher Text', 'English text', 'en', '셋문장'),
      ]) {
        await tester.runAsync(
          () => addTypedBookmarkWithWordbookMirror(
            saveContext,
            itemType: StudyLibraryItemType.sentence,
            itemId: korean,
            korean: korean,
            translationDe: de,
            translationEn: en,
            translationLanguage: requested,
          ),
        );
        final bookmark = TypedStudyBookmarkStore.production()
            .read()
            .bookmarks
            .singleWhere((b) => b.key.id == korean);
        expect(bookmark.secondaryLanguage, expected);
        final mirror = CustomPackService.getById(
          CustomPackService.quickPackId,
        )!.words.singleWhere((w) => w.korean == korean);
        expect(mirror.translationLanguage, expected);
        expect(
          mirror.translationFor(requested),
          requested == expected ? bookmark.secondaryText : isEmpty,
        );
      }
      // The provenance field is actually persisted, not just present in memory.
      final preferences = await SharedPreferences.getInstance();
      expect(
        jsonDecode(
          preferences.getString(Storage.typedStudyBookmarksPreferenceKey)!,
        )['items'],
        everyElement(contains('secondaryLanguage')),
      );
    },
  );
}

Widget _app(Widget screen, {Locale locale = const Locale('en')}) => MaterialApp(
  locale: locale,
  theme: AppTheme.light,
  supportedLocales: AppL10n.supportedLocales,
  localizationsDelegates: AppL10n.localizationsDelegates,
  home: screen,
);
