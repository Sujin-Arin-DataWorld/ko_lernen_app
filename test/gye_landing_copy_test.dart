import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ko_lernen_app/l10n/generated/app_localizations.dart';
import 'package:ko_lernen_app/l10n/sticker_localizations.dart';
import 'package:ko_lernen_app/data/sticker_catalog.dart';
import 'package:ko_lernen_app/models/gye.dart';
import 'package:ko_lernen_app/theme.dart';
import 'package:ko_lernen_app/widgets/sori/gye_feed.dart';
import 'package:ko_lernen_app/widgets/sori/sticker_image.dart';

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

  testWidgets('feed stickers share localized, memory-bounded rendering', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    final t = await AppL10n.delegate.load(const Locale('en'));

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        locale: const Locale('en'),
        supportedLocales: AppL10n.supportedLocales,
        localizationsDelegates: AppL10n.localizationsDelegates,
        home: const Scaffold(
          body: GyeFeed(
            events: [
              GyeFeedEvent(
                id: 'sticker-1',
                type: GyeFeedType.sticker,
                actorUid: 'learner-1',
                actorNickname: 'Mina',
                payload: {'stickerCode': 16},
              ),
              GyeFeedEvent(
                id: 'milestone-1',
                type: GyeFeedType.packCleared,
                actorUid: 'learner-2',
                actorNickname: 'Joon',
              ),
              GyeFeedEvent(
                id: 'reaction-1',
                type: GyeFeedType.sticker,
                actorUid: 'learner-3',
                actorNickname: 'Ara',
                payload: {'stickerCode': 19, 'targetEventId': 'milestone-1'},
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pump();

    final stickerImages = find.byType(StickerImage);
    expect(stickerImages, findsNWidgets(2));
    expect(
      tester.getSemantics(stickerImages.at(0)).label,
      contains(stickerName(t, stickerByCode(16)!)),
    );
    expect(
      tester.getSemantics(stickerImages.at(1)).label,
      contains(stickerName(t, stickerByCode(19)!)),
    );
    for (final image in tester.widgetList<Image>(find.byType(Image))) {
      expect(image.image, isA<ResizeImage>());
    }
    semantics.dispose();
  });
}
