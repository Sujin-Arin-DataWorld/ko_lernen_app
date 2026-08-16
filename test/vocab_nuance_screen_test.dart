import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ko_lernen_app/l10n/generated/app_localizations.dart';
import 'package:ko_lernen_app/models/book_page.dart';
import 'package:ko_lernen_app/models/custom_pack.dart';
import 'package:ko_lernen_app/screens/vocab_nuance_screen.dart';
import 'package:ko_lernen_app/services/custom_pack_service.dart';
import 'package:ko_lernen_app/services/storage_service.dart';
import 'package:ko_lernen_app/widgets/sori/quiz_choice.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    Storage.resetForTesting();
    SharedPreferences.setMockInitialValues({});
    await Storage.init();
  });

  testWidgets('choosing the formal synonym reveals the Hanja explanation', (
    tester,
  ) async {
    await CustomPackService.save(
      CustomPack.manual(
        id: 'nb-nuance',
        name: 'Heft',
        words: <ExtractedWord>[
          ExtractedWord.manual(korean: '시작', translationDe: 'Anfang'),
          ExtractedWord.manual(korean: '개시', translationDe: 'Beginn'),
        ],
      ),
    );

    await tester.pumpWidget(
      const MaterialApp(
        locale: Locale('de'),
        supportedLocales: AppL10n.supportedLocales,
        localizationsDelegates: AppL10n.localizationsDelegates,
        home: VocabNuanceScreen(packId: 'nb-nuance'),
      ),
    );
    await tester.pump();

    expect(find.text('Welches Wort ist förmlicher?'), findsOneWidget);
    await tester.tap(find.widgetWithText(QuizChoice, '개시  開始'));
    await tester.pump();

    expect(find.textContaining('開始'), findsWidgets);
    expect(find.textContaining('förmlicher'), findsWidgets);
  });
}
