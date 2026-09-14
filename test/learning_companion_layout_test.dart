import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ko_lernen_app/l10n/generated/app_localizations.dart';
import 'package:ko_lernen_app/services/learning_focus.dart';
import 'package:ko_lernen_app/services/today_learning_snapshot.dart';
import 'package:ko_lernen_app/theme.dart';
import 'package:ko_lernen_app/widgets/sori/learning_companion.dart';
import 'package:ko_lernen_app/widgets/sori/learning_focus.dart';
import 'package:ko_lernen_app/widgets/sori/mascot.dart';

import 'support/real_fonts.dart';

void main() {
  setUpAll(loadSoriRealFonts);
  testWidgets(
    'companion remains grounded through focus states and hides without a blank slot',
    (tester) async {
      final controller = LearningFocusController();
      addTearDown(controller.dispose);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      for (final locale in ['de', 'en']) {
        for (final width in [360.0, 390.0, 430.0, 800.0, 1280.0]) {
          for (final scale in [1.0, 1.6, 2.0]) {
            tester.view.devicePixelRatio = 1;
            tester.view.physicalSize = Size(width, 844);
            Future<void> mount(MascotKind? kind) async {
              await tester.pumpWidget(
                MaterialApp(
                  theme: AppTheme.light,
                  locale: Locale(locale),
                  supportedLocales: AppL10n.supportedLocales,
                  localizationsDelegates: AppL10n.localizationsDelegates,
                  home: MediaQuery(
                    data: MediaQueryData(
                      size: Size(width, 844),
                      textScaler: TextScaler.linear(scale),
                    ),
                    child: LearningFocusScope(
                      controller: controller,
                      open: (_, _, {focus, activityId}) async {},
                      child: Scaffold(
                        body: SingleChildScrollView(
                          padding: const EdgeInsets.all(20),
                          child: SoriLearningFocus(
                            introduction: SoriLearningCompanion(
                              greeting: locale == 'de'
                                  ? 'Schön, dass du da bist.'
                                  : 'Good to see you.',
                              title: locale == 'de' ? 'Heute' : 'Today',
                              kind: kind,
                              forceStatic: true,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
              await tester.pump();
            }

            double? surfaceTop;
            for (final state in ['loading', 'error', 'empty']) {
              controller.loading = state == 'loading';
              controller.error = state == 'error'
                  ? StateError('unavailable')
                  : null;
              controller.value = state == 'empty'
                  ? const LearningFocus(
                      today: TodayLearningSnapshot(pick: null),
                    )
                  : null;
              await mount(MascotKind.tiger);
              final top = tester
                  .getTopLeft(
                    find.byKey(const ValueKey('learning-focus-surface')),
                  )
                  .dy;
              surfaceTop ??= top;
              expect(top, surfaceTop);
              expect(
                tester
                    .getBottomRight(
                      find.byKey(const ValueKey('learning-companion-ground')),
                    )
                    .dy,
                top,
              );
              for (final element in find.byType(Text).evaluate()) {
                final render = element.findRenderObject();
                if (render is RenderParagraph) {
                  expect(render.didExceedMaxLines, isFalse);
                }
              }
              expect(
                tester.takeException(),
                isNull,
                reason: '$locale $width $scale $state',
              );
            }
            await mount(null);
            expect(
              find.byKey(const ValueKey('learning-companion-ground')),
              findsNothing,
            );
            expect(
              tester
                  .getTopLeft(
                    find.byKey(const ValueKey('learning-focus-surface')),
                  )
                  .dy,
              lessThan(surfaceTop!),
            );
            expect(
              find.text(locale == 'de' ? 'Heute' : 'Today'),
              findsOneWidget,
            );
            await tester.pumpWidget(const SizedBox());
          }
        }
      }
    },
  );
}
