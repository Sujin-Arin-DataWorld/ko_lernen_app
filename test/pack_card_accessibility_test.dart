import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ko_lernen_app/l10n/generated/app_localizations.dart';
import 'package:ko_lernen_app/models/pack_progress.dart';
import 'package:ko_lernen_app/theme.dart';
import 'package:ko_lernen_app/widgets/sori/pack_card.dart';

void main() {
  testWidgets(
    'legacy locked progress renders as a directly tappable available card',
    (tester) async {
      var taps = 0;
      await tester.binding.setSurfaceSize(const Size(320, 640));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          locale: const Locale('de'),
          supportedLocales: AppL10n.supportedLocales,
          localizationsDelegates: AppL10n.localizationsDelegates,
          home: MediaQuery(
            data: const MediaQueryData(
              size: Size(320, 640),
              textScaler: TextScaler.linear(2),
            ),
            child: Scaffold(
              body: Padding(
                padding: const EdgeInsets.all(16),
                child: SizedBox(
                  width: 288,
                  height: 460,
                  child: PackCard(
                    packId: 'a1_02',
                    title: 'Unterwegs in der Stadt',
                    progress: PackProgress.fresh(
                      packId: 'a1_02',
                      level: 'A1',
                      wordsTotal: 10,
                      status: PackStatus.locked,
                    ),
                    onTap: () => taps++,
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.byIcon(Icons.lock_outline_rounded), findsNothing);

      await tester.tap(find.byType(PackCard));
      await tester.pump();
      expect(taps, 1);
      expect(tester.takeException(), isNull);
    },
  );
}
