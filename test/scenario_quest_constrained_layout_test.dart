import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ko_lernen_app/l10n/generated/app_localizations.dart';
import 'package:ko_lernen_app/screens/quest_engines/quest_layout.dart';
import 'package:ko_lernen_app/theme.dart';
import 'package:ko_lernen_app/widgets/sori/scenario_c.dart';
import 'package:ko_lernen_app/widgets/sori/pressable.dart';

void main() {
  for (final profile in [
    (width: 768.0, height: 73.0, scale: 1.0),
    (width: 288.0, height: 200.0, scale: 1.6),
  ]) {
    testWidgets('scenario input and submit stay fully reachable at '
        '${profile.height}dp / ${profile.scale}x', (tester) async {
      var selections = 0;
      var submissions = 0;
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          locale: const Locale('de'),
          supportedLocales: AppL10n.supportedLocales,
          localizationsDelegates: AppL10n.localizationsDelegates,
          home: Scaffold(
            body: MediaQuery(
              data: MediaQueryData(
                textScaler: TextScaler.linear(profile.scale),
              ),
              child: ScenarioCTheme(
                child: Align(
                  alignment: Alignment.topLeft,
                  child: SizedBox(
                    width: profile.width,
                    height: profile.height,
                    child: QuestLayout(
                      showTtsSpeed: true,
                      content: Column(
                        children: [
                          const Text('Hör zu und wähle deine Antwort.'),
                          SoriPressable(
                            key: const ValueKey('reachable-word'),
                            onTap: () => selections++,
                            child: ScenarioCWordTile(
                              child: Text(
                                '네',
                                style: ScenarioC.korean.copyWith(fontSize: 16),
                              ),
                            ),
                          ),
                        ],
                      ),
                      action: ScenarioCGoldButton(
                        key: const ValueKey('reachable-submit'),
                        label: 'Antwort prüfen',
                        onTap: () => submissions++,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      for (final key in ['reachable-word', 'reachable-submit']) {
        final target = find.byKey(ValueKey(key));
        await Scrollable.ensureVisible(tester.element(target), alignment: .5);
        await tester.pump();
        final viewport = tester.getRect(find.byType(QuestLayout));
        final rect = tester.getRect(target);
        expect(rect.height, greaterThanOrEqualTo(48));
        expect(rect.intersect(viewport).height, closeTo(rect.height, .01));
        expect(target.hitTestable(), findsOneWidget);
        await tester.tap(target);
        await tester.pump();
        expect(tester.takeException(), isNull);
      }
      expect(selections, 1);
      expect(submissions, 1);
    });
  }
}
