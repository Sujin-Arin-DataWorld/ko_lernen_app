import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ko_lernen_app/l10n/generated/app_localizations.dart';
import 'package:ko_lernen_app/models/book_page.dart';
import 'package:ko_lernen_app/models/custom_pack.dart';
import 'package:ko_lernen_app/screens/vocab_notebook_studio_screen.dart';
import 'package:ko_lernen_app/services/custom_pack_service.dart';
import 'package:ko_lernen_app/services/storage_service.dart';
import 'package:ko_lernen_app/widgets/sori/button.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    Storage.resetForTesting();
    SharedPreferences.setMockInitialValues({});
    await Storage.init();
  });

  testWidgets('game buttons follow the words the learner keeps', (tester) async {
    await CustomPackService.save(
      CustomPack.manual(
        id: 'nb-studio',
        name: 'Heft',
        words: <ExtractedWord>[
          ExtractedWord.manual(korean: '학교', translationDe: 'Schule'),
          ExtractedWord.manual(korean: '학생', translationDe: 'Schüler'),
        ],
      ),
    );

    await tester.pumpWidget(
      const MaterialApp(
        locale: Locale('de'),
        supportedLocales: AppL10n.supportedLocales,
        localizationsDelegates: AppL10n.localizationsDelegates,
        home: VocabNotebookStudioScreen(packId: 'nb-studio'),
      ),
    );
    await tester.pump();

    expect(find.text('학교'), findsOneWidget);
    expect(find.text('Spiel aus diesen Wörtern bauen'), findsNothing);
    expect(find.text('Mein Wortspiel'), findsOneWidget);

    var cards = tester.widget<SoriButton>(
      find.widgetWithText(SoriButton, 'Karten lernen'),
    );
    expect(cards.onTap, isNotNull);

    await tester.tap(find.widgetWithText(SoriButton, 'Keine'));
    await tester.pump();

    cards = tester.widget<SoriButton>(
      find.widgetWithText(SoriButton, 'Karten lernen'),
    );
    expect(cards.onTap, isNull);

    await tester.tap(find.widgetWithText(SoriButton, 'Alle nehmen'));
    await tester.pump();

    cards = tester.widget<SoriButton>(
      find.widgetWithText(SoriButton, 'Karten lernen'),
    );
    expect(cards.onTap, isNotNull);
  });
}
