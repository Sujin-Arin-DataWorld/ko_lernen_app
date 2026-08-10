import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ko_lernen_app/l10n/generated/app_localizations.dart';
import 'package:ko_lernen_app/models/gye.dart';
import 'package:ko_lernen_app/theme.dart';
import 'package:ko_lernen_app/widgets/sori/gye_feed.dart';

void main() {
  testWidgets(
    'goal events never surface an MVP identity in the courtyard feed',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          locale: const Locale('en'),
          supportedLocales: AppL10n.supportedLocales,
          localizationsDelegates: AppL10n.localizationsDelegates,
          home: Scaffold(
            body: GyeFeed(
              events: [
                GyeFeedEvent(
                  id: 'goal-1',
                  type: GyeFeedType.goalAchieved,
                  actorUid: 'system',
                  actorNickname: 'System',
                  payload: const {'mvp': 'Mina', 'progress': 5},
                ),
              ],
            ),
          ),
        ),
      );

      expect(
        find.text('Weekly goal reached! Your hanok grows.'),
        findsOneWidget,
      );
      expect(find.textContaining('MVP'), findsNothing);
      expect(find.text('Mina'), findsNothing);
    },
  );
}
