import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ko_lernen_app/l10n/generated/app_localizations.dart';
import 'package:ko_lernen_app/widgets/sori/decoration_layer.dart';
import 'package:ko_lernen_app/widgets/sori/reward_thumb.dart';

void main() {
  // §W-C H6: decorName now returns the German/English name only (the
  // Hangul/romanization parenthetical moved to the new decorTerm), so the
  // semantics label this test checks for changed from 'Jangdokdae (jar
  // terrace)' to just 'Jar terrace'.
  testWidgets('quest reward and courtyard decoration expose their name', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        supportedLocales: AppL10n.supportedLocales,
        localizationsDelegates: AppL10n.localizationsDelegates,
        home: const Scaffold(
          body: Column(
            children: [
              SoriRewardThumb(slug: 'decoration_jangdokdae', earned: true),
              SizedBox(
                width: 300,
                height: 200,
                child: DecorationLayer(completedQuestIds: ['q_jangdokdae']),
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.bySemanticsLabel('Jar terrace'), findsNWidgets(2));
    semantics.dispose();
  });

  testWidgets('a labeled card can own the reward thumbnail semantics', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        supportedLocales: AppL10n.supportedLocales,
        localizationsDelegates: AppL10n.localizationsDelegates,
        home: const Scaffold(
          body: Row(
            children: [
              Text('Jar terrace'),
              SoriRewardThumb(
                slug: 'decoration_jangdokdae',
                earned: true,
                semantic: '',
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.bySemanticsLabel('Jar terrace'), findsOneWidget);
    semantics.dispose();
  });
}
