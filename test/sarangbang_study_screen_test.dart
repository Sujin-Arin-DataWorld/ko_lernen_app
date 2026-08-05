import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ko_lernen_app/l10n/generated/app_localizations.dart';
import 'package:ko_lernen_app/screens/sarangbang_screen.dart';
import 'package:ko_lernen_app/services/mission_recommender.dart';
import 'package:ko_lernen_app/services/today_learning_snapshot.dart';
import 'package:ko_lernen_app/widgets/sori/button.dart';

void main() {
  testWidgets('opens the recommendation chosen by the existing engine', (
    tester,
  ) async {
    var opens = 0;
    await tester.pumpWidget(
      _host(
        SarangbangStudyScreen(
          loadTodaySnapshot: () async =>
              TodayLearningSnapshot(pick: ReviewPick(dueCount: 12)),
          onOpenRecommendation: (_) async => opens++,
        ),
      ),
    );
    await tester.pump();

    final mission = find.byKey(const ValueKey('sarangbang-study-mission'));
    expect(mission, findsOneWidget);
    await tester.tap(
      find.descendant(of: mission, matching: find.byType(SoriButton)),
    );

    expect(opens, 1);
  });
}

Widget _host(Widget child) => MaterialApp(
  locale: const Locale('en'),
  supportedLocales: AppL10n.supportedLocales,
  localizationsDelegates: AppL10n.localizationsDelegates,
  home: MediaQuery(
    data: const MediaQueryData(disableAnimations: true),
    child: child,
  ),
);
