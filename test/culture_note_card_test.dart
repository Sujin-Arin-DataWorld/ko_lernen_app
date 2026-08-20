import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ko_lernen_app/l10n/generated/app_localizations.dart';
import 'package:ko_lernen_app/services/culture_notes_service.dart';
import 'package:ko_lernen_app/widgets/sori/culture_note_card.dart';
import 'package:ko_lernen_app/widgets/sori/tokens.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    CultureNotesService.resetForTesting();
  });

  testWidgets('DE 320dp·200%에서 한국어 표제는 Maru Buri이고 내용이 잘리지 않는다', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await CultureNotesService.load();

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('de'),
        localizationsDelegates: AppL10n.localizationsDelegates,
        supportedLocales: AppL10n.supportedLocales,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: const TextScaler.linear(2)),
          child: child!,
        ),
        home: const Scaffold(
          body: SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: CultureNoteCard(korean: '화이팅'),
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    final korean = tester.widget<Text>(find.text('화이팅'));
    expect(korean.style?.fontFamily, SoriFonts.culture);
    expect(find.byType(CultureNoteCard), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
