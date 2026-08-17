import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ko_lernen_app/l10n/generated/app_localizations.dart';
import 'package:ko_lernen_app/screens/vocab_notebook_result_screen.dart';
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

  testWidgets('saves the photographed pairs and opens playful practice', (
    tester,
  ) async {
    String? opened;
    Object? arguments;
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('de'),
        supportedLocales: AppL10n.supportedLocales,
        localizationsDelegates: AppL10n.localizationsDelegates,
        home: const VocabNotebookResultScreen(
          args: <String, dynamic>{
            'text': '학교 - Schule\n학생 = Schüler\n시작 Anfang\n개시 Eröffnung',
          },
        ),
        onGenerateRoute: (settings) {
          opened = settings.name;
          arguments = settings.arguments;
          return MaterialPageRoute<void>(
            settings: settings,
            builder: (_) => const SizedBox.shrink(),
          );
        },
      ),
    );
    await tester.pump();

    expect(find.text('학교'), findsOneWidget);
    expect(find.text('Schule'), findsOneWidget);
    expect(find.text('學校'), findsOneWidget);
    expect(find.text('학생'), findsOneWidget);

    await tester.tap(find.widgetWithText(SoriButton, 'Genau diese Wörter üben'));
    await tester.pumpAndSettle();

    expect(opened, '/vocab_notebook/practice');
    final packId = arguments as String;
    final pack = CustomPackService.getById(packId);
    expect(pack, isNotNull);
    expect(pack!.words.map((word) => word.korean), containsAll(<String>['학교', '학생', '시작', '개시']));
    expect(pack.words.map((word) => word.translationDe), contains('Schule'));
  });

  testWidgets('photographing another page saves the current pairs first', (
    tester,
  ) async {
    String? opened;
    Object? arguments;
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('de'),
        supportedLocales: AppL10n.supportedLocales,
        localizationsDelegates: AppL10n.localizationsDelegates,
        home: const VocabNotebookResultScreen(
          args: <String, dynamic>{
            'text': '학교 - Schule\n학생 = Schüler\n시작 Anfang\n개시 Eröffnung',
          },
        ),
        onGenerateRoute: (settings) {
          opened = settings.name;
          arguments = settings.arguments;
          return MaterialPageRoute<void>(
            settings: settings,
            builder: (_) => const SizedBox.shrink(),
          );
        },
      ),
    );
    await tester.pump();

    await tester.tap(
      find.widgetWithText(SoriButton, 'Weitere Seite fotografieren'),
    );
    await tester.pumpAndSettle();

    expect(opened, '/vocab_notebook');
    final args = arguments as Map<String, dynamic>;
    final packId = args['existingPackId'] as String;
    final pack = CustomPackService.getById(packId);
    expect(pack, isNotNull);
    expect(
      pack!.words.map((word) => word.korean),
      containsAll(<String>['학교', '학생', '시작', '개시']),
    );
  });
}
