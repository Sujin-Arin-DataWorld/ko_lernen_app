import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ko_lernen_app/l10n/generated/app_localizations.dart';
import 'package:ko_lernen_app/screens/quest_engines/satz_bauen_quest.dart';
import 'package:ko_lernen_app/widgets/sori/mascot_pop.dart';

void main() {
  testWidgets('Satz bauen configures a centered six-times burst', (
    tester,
  ) async {
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

    final partner = tester.widget<MascotPartner>(find.byType(MascotPartner));
    expect(partner.burstScale, 6);
    expect(partner.burstOrigin, Alignment.center);
  });
}
