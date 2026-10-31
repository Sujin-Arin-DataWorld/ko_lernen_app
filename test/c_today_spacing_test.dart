import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ko_lernen_app/l10n/generated/app_localizations.dart';
import 'package:ko_lernen_app/services/learning_focus.dart';
import 'package:ko_lernen_app/services/mission_recommender.dart';
import 'package:ko_lernen_app/services/palette_service.dart';
import 'package:ko_lernen_app/services/today_learning_snapshot.dart';
import 'package:ko_lernen_app/theme.dart';
import 'package:ko_lernen_app/widgets/sori/learning_focus.dart';

import 'support/real_fonts.dart';

void main() {
  setUpAll(() => loadSoriRealFonts(materialIcons: true));
  for (final language in ['de', 'en']) {
    for (final size in [const Size(320, 640), const Size(393, 873)]) {
      for (final scale in [1.0, 2.0]) {
        testWidgets(
          'Today related content stays grouped $language $size $scale',
          (tester) async {
            tester.view.physicalSize = size;
            tester.view.devicePixelRatio = 1;
            addTearDown(tester.view.resetPhysicalSize);
            addTearDown(tester.view.resetDevicePixelRatio);
            final controller = LearningFocusController();
            addTearDown(controller.dispose);
            controller.value = const LearningFocus(
              today: TodayLearningSnapshot(
                pick: ReviewPick(dueCount: 3),
                destination: TodayLearningDestination(route: '/review'),
                dueCount: 3,
              ),
              destination: TodayLearningDestination(route: '/review'),
            );
            final locale = Locale(language);
            await tester.pumpWidget(
              MaterialApp(
                locale: locale,
                theme: AppTheme.lightFor(
                  PaletteVariant.dancheong,
                  locale: locale,
                ),
                supportedLocales: AppL10n.supportedLocales,
                localizationsDelegates: AppL10n.localizationsDelegates,
                builder: (context, child) => MediaQuery(
                  data: MediaQuery.of(context).copyWith(
                    textScaler: TextScaler.linear(scale),
                    disableAnimations: true,
                  ),
                  child: child!,
                ),
                home: LearningFocusScope(
                  controller: controller,
                  open: (_, _, {focus, activityId}) async {},
                  child: const Scaffold(
                    body: SingleChildScrollView(
                      padding: EdgeInsets.all(12),
                      child: SoriLearningFocus(
                        conceptC: true,
                        conceptCompactSummary: true,
                      ),
                    ),
                  ),
                ),
              ),
            );
            await tester.pump();
            final title = tester.getRect(
              find.byKey(const ValueKey('learning-focus-title')),
            );
            final art = tester.getRect(
              find.byKey(const ValueKey('learning-focus-art')),
            );
            final context = tester.getRect(
              find.byKey(const ValueKey('learning-focus-context')),
            );
            final action = tester.getRect(
              find.byKey(const ValueKey('learning-focus-start')),
            );
            expect(context.top - title.bottom, closeTo(4, .01));
            expect(art.top - context.bottom, closeTo(0, .01));
            expect(action.top - art.bottom, closeTo(8, .01));
            expect(
              art.height,
              closeTo(160, .01),
              reason:
                  'The reviewed standalone C5 scene keeps its 160dp art slot.',
            );
            expect(
              tester
                  .getSize(find.byKey(const ValueKey('learning-focus-start')))
                  .height,
              greaterThanOrEqualTo(48),
            );
            expect(tester.takeException(), isNull);
          },
        );
      }
    }
  }
}
