import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ko_lernen_app/l10n/generated/app_localizations.dart';
import 'package:ko_lernen_app/models/book_page.dart';
import 'package:ko_lernen_app/models/custom_pack.dart';
import 'package:ko_lernen_app/models/vocab.dart';
import 'package:ko_lernen_app/screens/bookshelf_screen.dart';
import 'package:ko_lernen_app/screens/hard_words_screen.dart';
import 'package:ko_lernen_app/screens/wordbook_search_screen.dart';
import 'package:ko_lernen_app/services/custom_pack_service.dart';
import 'package:ko_lernen_app/services/storage_service.dart';
import 'package:ko_lernen_app/theme.dart';
import 'package:ko_lernen_app/widgets/sori/standard_page.dart';
import 'package:ko_lernen_app/widgets/sori/type_scale.dart';

const _savedWord = ExtractedWord(
  korean: '사랑',
  romanization: 'sarang',
  posDe: 'Nomen',
  translationDe: 'Liebe',
  translationEn: 'love',
  translationLanguage: 'en',
  exampleKorean: '',
  exampleDe: '',
  savedToPackId: null,
);

const _hardWord = Vocab(
  id: 'my-words-body-hard',
  korean: '그리움',
  romanization: 'geurium',
  german: 'Sehnsucht',
  english: 'longing',
  level: 'B2',
  posDe: 'Nomen',
  exampleKorean: '',
  exampleGerman: '',
  topic: 'test',
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    Storage.resetForTesting();
    SharedPreferences.setMockInitialValues(<String, Object>{
      'kl_custom_packs_v1': '{}',
      'kl_tut_bookshelf': true,
      'kl_tut_hardWords': true,
    });
    await Storage.init();
    await CustomPackService.save(
      CustomPack.manual(
        id: 'my-words-body-pack',
        name: 'Meine Testwörter',
        words: const <ExtractedWord>[_savedWord],
      ),
    );
    for (var attempt = 0; attempt < 3; attempt += 1) {
      await Storage.incrementWrongCount(_hardWord.korean);
    }
  });

  testWidgets(
    'public word-tool bodies embed in one supplied TabBarView without route chrome',
    (tester) async {
      await tester.pumpWidget(
        _host(
          DefaultTabController(
            length: 3,
            child: Scaffold(
              appBar: const TabBar(
                tabs: <Widget>[
                  Tab(text: 'Search'),
                  Tab(text: 'Shelf'),
                  Tab(text: 'Difficult'),
                ],
              ),
              body: TabBarView(
                children: <Widget>[
                  const WordbookSearchBody(),
                  const BookshelfBody(),
                  HardWordsBody(
                    deckLoader: () async => const <Vocab>[_hardWord],
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(SoriStandardFrame), findsNothing);
      expect(find.text(_savedWord.korean), findsOneWidget);

      await tester.tap(find.text('Shelf'));
      await tester.pumpAndSettle();
      expect(find.text('Meine Testwörter'), findsOneWidget);
      expect(find.byType(SoriStandardFrame), findsNothing);

      await tester.tap(find.text('Difficult'));
      await tester.pumpAndSettle();
      expect(find.text(_hardWord.korean), findsOneWidget);
      expect(find.byType(SoriStandardFrame), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
}

Widget _host(Widget child) {
  return MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: AppTheme.light,
    locale: const Locale('de'),
    supportedLocales: AppL10n.supportedLocales,
    localizationsDelegates: AppL10n.localizationsDelegates,
    builder: (context, appChild) => SoriTypeScale(child: appChild!),
    home: child,
  );
}
