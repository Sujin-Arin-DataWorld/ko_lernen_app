import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ko_lernen_app/l10n/generated/app_localizations.dart';
import 'package:ko_lernen_app/screens/quest_engines/quest_flow.dart';
import 'package:ko_lernen_app/screens/quest_engines/satz_bauen_quest.dart';
import 'package:ko_lernen_app/widgets/sori/mascot_pop.dart';

void main() {
  testWidgets('Satz bauen no longer celebrates per item', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('de'),
        supportedLocales: AppL10n.supportedLocales,
        localizationsDelegates: AppL10n.localizationsDelegates,
        home: Scaffold(
          body: SatzBauenQuest(
            data: const {
              'targetKo': '우유 어디 있어요?',
              'promptDe': 'Wo ist die Milch?',
              'promptEn': 'Where is the milk?',
              'distractors': <String>[],
            },
            onComplete: (_) {},
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.byType(MascotPartner), findsNothing);
    expect(find.byType(SoriPromptCard), findsOneWidget);
    expect(find.text('Deine Antwort bauen'), findsOneWidget);
    expect(find.byType(SoriDottedAnswerSlot), findsWidgets);
  });
}
