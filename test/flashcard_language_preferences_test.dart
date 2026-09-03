import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ko_lernen_app/l10n/generated/app_localizations.dart';
import 'package:ko_lernen_app/models/book_page.dart';
import 'package:ko_lernen_app/models/custom_pack.dart';
import 'package:ko_lernen_app/models/vocab.dart';
import 'package:ko_lernen_app/models/vocab_pack.dart';
import 'package:ko_lernen_app/screens/custom_pack_play_screen.dart';
import 'package:ko_lernen_app/screens/custom_pack_edit_screen.dart';
import 'package:ko_lernen_app/screens/bookshelf_page_screen.dart';
import 'package:ko_lernen_app/screens/vocab_pack_screen.dart';
import 'package:ko_lernen_app/services/saved_word_localization.dart';
import 'package:ko_lernen_app/services/custom_pack_service.dart';
import 'package:ko_lernen_app/services/bookshelf_service.dart';
import 'package:ko_lernen_app/services/book_image_service.dart';
import 'package:ko_lernen_app/services/storage_service.dart';
import 'package:ko_lernen_app/theme.dart';
import 'package:ko_lernen_app/widgets/flip_card.dart';
import 'package:ko_lernen_app/widgets/sori/button.dart';
import 'package:ko_lernen_app/widgets/sori/text_field.dart';

const _word = ExtractedWord(
  korean: '안녕하세요',
  romanization: 'annyeonghaseyo',
  posDe: 'Interjektion',
  translationDe: 'Guten Tag',
  translationEn: 'Hello',
  exampleKorean: '안녕하세요. 저는 학생이에요.',
  exampleDe: 'Guten Tag. Ich bin Schüler.',
  exampleEn: 'Hello. I am a student.',
  savedToPackId: null,
);

const _vocab = Vocab(
  korean: '안녕하세요',
  romanization: 'annyeonghaseyo',
  german: 'Guten Tag',
  english: 'Hello',
  level: 'A1',
  posDe: 'Interjektion',
  posEn: 'Interjection',
  exampleKorean: '안녕하세요. 저는 학생이에요.',
  exampleGerman: 'Guten Tag. Ich bin Schüler.',
  exampleEnglish: 'Hello. I am a student.',
  topic: 'Begrüßung',
  packId: 'a1_greetings_1',
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory mediaRoot;

  setUp(() async {
    Storage.resetForTesting();
    SharedPreferences.setMockInitialValues({
      'kl_user_level': 'a1',
      'kl_tut_cpPlay': true,
      'kl_tut_cpEdit': true,
      'kl_tut_soriDeck': true,
      'kl_tut_wordbook': true,
      'kl_custom_packs_v1': jsonEncode({
        'cp_language': CustomPack.manual(
          id: 'cp_language',
          name: 'My notes',
          words: const [_word],
        ).toLocalJson(),
      }),
    });
    await Storage.init();
    mediaRoot = Directory.systemTemp.createTempSync('flashcard-language-');
    BookImageService.setStoreForTesting(
      ManagedMediaStore(
        documentsDirectory: Directory('${mediaRoot.path}/documents'),
        temporaryDirectory: Directory('${mediaRoot.path}/temporary'),
      ),
    );
    await Storage.setTutVocabPackSeen();
    await Storage.setTutPackQuizSeen();
    await Storage.setTutPackBossSeen();
  });
  tearDown(() {
    BookImageService.setStoreForTesting(null);
    mediaRoot.deleteSync(recursive: true);
  });

  test('English examples survive local and portable storage', () {
    for (final decoded in [
      ExtractedWord.fromLocalJson(_word.toLocalJson()),
      ExtractedWord.fromPortableJson(_word.toPortableJson()),
      _word.copyWithEditable(translationEn: 'Good day'),
      _word.copyWith(savedToPackId: 'saved'),
    ]) {
      expect(decoded.exampleFor('en'), 'Hello. I am a student.');
      expect(decoded.exampleFor('de'), 'Guten Tag. Ich bin Schüler.');
      expect(decoded.posFor('en'), 'Interjection');
      expect(decoded.toPortableJson()['exampleLanguage'], 'de');
    }
  });

  test('legacy curated cards gain English without rewriting user meanings', () {
    final legacy = _word.copyWithEditable(translationEn: '', exampleEn: '');
    final resolved = localizeSavedWord(legacy, const [_vocab]);
    expect(resolved.translationFor('en'), 'Hello');
    expect(resolved.exampleFor('en'), 'Hello. I am a student.');
    expect(legacy.exampleKorean, contains('\n'));
    expect(legacy.translationEn, isEmpty);
    final custom = legacy.copyWithEditable(translationDe: 'My personal cue');
    expect(
      identical(localizeSavedWord(custom, const [_vocab]), custom),
      isTrue,
    );
    expect(custom.exampleFor('en'), isEmpty);
  });

  test('legacy English OCR examples never masquerade as German', () {
    const legacy = ExtractedWord(
      korean: '안녕하세요',
      romanization: '',
      posDe: '',
      translationDe: 'Hello',
      translationEn: 'Hello',
      translationLanguage: 'en',
      exampleKorean: '안녕하세요. 저는 학생이에요.',
      exampleDe: 'Hello. I am a student.',
      savedToPackId: null,
    );
    final withEnglishSlot = legacy.copyWithEditable(
      exampleEn: legacy.exampleDe,
    );
    expect(withEnglishSlot.exampleFor('de'), isEmpty);
    final localized = localizeSavedWord(legacy, const [_vocab]);
    expect(localized.exampleFor('de'), _vocab.exampleGerman);
    expect(localized.exampleFor('en'), legacy.exampleDe);
    final restored = ExtractedWord.fromPortableJson(localized.toPortableJson());
    expect(restored.exampleFor('de'), _vocab.exampleGerman);
  });

  Future<void> pump(WidgetTester tester, Widget screen) async {
    tester.view.physicalSize = const Size(393, 852);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        locale: const Locale('en'),
        supportedLocales: AppL10n.supportedLocales,
        localizationsDelegates: AppL10n.localizationsDelegates,
        home: screen,
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
  }

  testWidgets('custom cards move romanization to back and remember it', (
    tester,
  ) async {
    await pump(tester, const CustomPackPlayScreen(packId: 'cp_language'));
    expect(find.text('[annyeonghaseyo]'), findsOneWidget);
    await tester.tap(find.byTooltip('Romanization'));
    await tester.pumpAndSettle();
    await tester.tap(
      find.byWidgetPredicate(
        (w) => w is CheckedPopupMenuItem<bool> && w.value == false,
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('[annyeonghaseyo]'), findsNothing);
    expect(Storage.flashcardRomanizationOnFront, isFalse);
    tester.widget<FlipCard>(find.byType(FlipCard)).onTap!();
    await tester.pumpAndSettle();
    expect(find.text('[annyeonghaseyo]'), findsOneWidget);
    expect(find.text('Hello'), findsOneWidget);
    expect(find.text('Guten Tag'), findsNothing);
    expect(find.text('Interjektion'), findsNothing);
    expect(find.text('Hello. I am a student.'), findsOneWidget);
    expect(find.text('annyeonghaseyo.\njeoneun haksaengieyo.'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    Storage.resetForTesting();
    await Storage.init();
    await pump(tester, const CustomPackPlayScreen(packId: 'cp_language'));
    expect(find.text('[annyeonghaseyo]'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'saving a missing translation unchanged preserves the original meaning',
    (tester) async {
      final legacy = _word.copyWithEditable(translationEn: '', exampleEn: '');
      await CustomPackService.save(
        CustomPack.manual(id: 'cp_language', name: 'My notes', words: [legacy]),
      );
      await pump(tester, const CustomPackEditScreen(packId: 'cp_language'));
      final edit = find.bySemanticsLabel(
        '${lookupAppL10n(const Locale('en')).wbEditWordTitle}: 안녕하세요',
      );
      await tester.ensureVisible(edit);
      await tester.tap(edit);
      await tester.pumpAndSettle();
      final save = find.byWidgetPredicate(
        (w) =>
            w is SoriButton &&
            w.label == lookupAppL10n(const Locale('en')).wbSaveWord,
      );
      await tester.ensureVisible(save);
      await tester.tap(save);
      await tester.pumpAndSettle();
      final saved = CustomPackService.getById('cp_language')!.words.single;
      expect(saved.translationDe, legacy.translationDe);
      expect(saved.translationEn, isEmpty);
      expect(saved.translationLanguage, 'de');
      expect(saved.exampleFor('de'), legacy.exampleDe);
    },
  );

  testWidgets('typing an English meaning preserves a legacy German card', (
    tester,
  ) async {
    final legacy = _word.copyWithEditable(translationEn: '', exampleEn: '');
    await CustomPackService.save(
      CustomPack.manual(id: 'cp_language', name: 'My notes', words: [legacy]),
    );
    await pump(tester, const CustomPackEditScreen(packId: 'cp_language'));
    final edit = find.bySemanticsLabel(
      '${lookupAppL10n(const Locale('en')).wbEditWordTitle}: 안녕하세요',
    );
    await tester.ensureVisible(edit);
    await tester.tap(edit);
    await tester.pumpAndSettle();
    final meaning = find.descendant(
      of: find.byWidgetPredicate(
        (w) =>
            w is SoriTextField &&
            w.labelText == lookupAppL10n(const Locale('en')).wbFieldMeaning,
      ),
      matching: find.byType(TextField),
    );
    expect(tester.widget<TextField>(meaning).controller!.text, isEmpty);
    expect(find.text('Original saved meaning: Guten Tag'), findsOneWidget);
    await tester.enterText(meaning, 'Good day');
    final save = find.byWidgetPredicate(
      (w) =>
          w is SoriButton &&
          w.label == lookupAppL10n(const Locale('en')).wbSaveWord,
    );
    await tester.ensureVisible(save);
    await tester.tap(save);
    await tester.pumpAndSettle();
    final saved = CustomPackService.getById('cp_language')!.words.single;
    expect(saved.translationDe, 'Guten Tag');
    expect(saved.translationEn, 'Good day');
    expect(saved.translationLanguage, 'en');
    expect(saved.exampleFor('en'), isEmpty);
    expect(saved.exampleFor('de'), legacy.exampleDe);
  });

  testWidgets(
    'English saved page keeps Korean when translated prose is absent',
    (tester) async {
      await BookshelfService.save(
        const BookPage(
          id: 'language-page',
          localThumbnailPath: null,
          extractedText: '새로운 문장이에요.',
          note: '',
          words: [_word],
          grammar: [
            GrammarHit(
              patternId: 'custom-pattern',
              nameDe: 'Deutscher Hinweis',
              matchedText: '문장이에요',
              level: 'A1',
              explanationDe: 'Eine Erklärung',
            ),
          ],
          sentences: [
            TranslatedSentence(
              korean: '새로운 문장이에요.',
              translationDe: 'Das ist ein neuer Satz.',
            ),
          ],
          capturedAtIso: '2026-09-02T00:00:00Z',
          customPackId: null,
        ),
      );
      await pump(tester, const BookshelfPageScreen(pageId: 'language-page'));
      expect(find.text('Deutscher Hinweis'), findsNothing);
      expect(find.text('Das ist ein neuer Satz.'), findsNothing);
      expect(find.text('문장이에요'), findsOneWidget);
      expect(find.text('새로운 문장이에요.'), findsWidgets);
      expect(
        find.text(lookupAppL10n(const Locale('en')).booksSavedOtherLanguage),
        findsOneWidget,
      );
    },
  );

  testWidgets('curated card title and back use English and saved placement', (
    tester,
  ) async {
    await Storage.setFlashcardRomanizationOnFront(false);
    const pack = VocabPack(id: 'a1_greetings_1', level: 'A1', words: [_vocab]);
    await pump(
      tester,
      VocabPackScreen(
        packId: pack.id,
        packLoader: (_) async => pack,
        siblingPacksLoader: (_) async => [pack],
      ),
    );
    expect(find.text('Greetings & Politeness (1)'), findsOneWidget);
    expect(find.text('[annyeonghaseyo]'), findsNothing);
    tester.widget<FlipCard>(find.byType(FlipCard)).onTap!();
    await tester.pumpAndSettle();
    expect(find.text('[annyeonghaseyo]'), findsOneWidget);
    expect(find.text('Hello'), findsOneWidget);
    expect(find.text('annyeonghaseyo. jeoneun haksaengieyo.'), findsOneWidget);
    expect(find.text('Hello. I am a student.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
