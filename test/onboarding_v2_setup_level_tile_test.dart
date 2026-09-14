import 'dart:ui' show Tristate;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ko_lernen_app/l10n/generated/app_localizations.dart';
import 'package:ko_lernen_app/screens/onboarding_v2/onboarding_journey_scenes.dart';
import 'package:ko_lernen_app/screens/onboarding_v2/onboarding_setup_screen.dart';
import 'package:ko_lernen_app/screens/onboarding_v2/onboarding_v2_copy.dart';
import 'package:ko_lernen_app/screens/onboarding_v2/onboarding_v2_presentation.dart';
import 'package:ko_lernen_app/screens/onboarding_v2/onboarding_v2_shell.dart';
import 'package:ko_lernen_app/theme.dart';
import 'package:ko_lernen_app/widgets/sori/button.dart';
import 'support/real_fonts.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(loadSoriRealFonts);
  for (final locale in ['de', 'en']) {
    for (final entry in const [
      (Size(360, 800), 1.0),
      (Size(390, 844), 1.3),
      (Size(720, 1152), 1.0),
      (Size(320, 640), 2.0),
    ]) {
      testWidgets(
        '$locale level choices retain scale and readable examples at $entry',
        (tester) async {
          tester.view.physicalSize = entry.$1;
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          final semantics = tester.ensureSemantics();
          OnboardingSetupSelection? submitted;
          await tester.pumpWidget(
            MaterialApp(
              theme: AppTheme.light,
              locale: Locale(locale),
              supportedLocales: AppL10n.supportedLocales,
              localizationsDelegates: AppL10n.localizationsDelegates,
              builder: (context, child) => MediaQuery(
                data: MediaQuery.of(context).copyWith(
                  textScaler: TextScaler.linear(entry.$2),
                  disableAnimations: true,
                ),
                child: child!,
              ),
              home: _Levels(onSubmitted: (value) => submitted = value),
            ),
          );
          await tester.pump();
          expect(_next(tester).onTap, isNull);
          await tester.tap(
            find.byKey(const ValueKey('onboarding-v3-returning')),
          );
          await tester.pump();
          final setup = tester.widget<OnboardingSetupScreen>(
            find.byType(OnboardingSetupScreen),
          );
          final rectangles = <Rect>[];
          for (final level in setup.copy.setup.levels) {
            final tile = find.byKey(
              ValueKey('onboarding-v2-level-${level.code}'),
            );
            final label = find.descendant(
              of: tile,
              matching: find.text(level.code),
            );
            final rect = tester.getRect(tile);
            rectangles.add(rect);
            expect(rect.width, greaterThanOrEqualTo(48));
            expect(rect.height, greaterThanOrEqualTo(48));
            final labelRect = tester.getRect(label);
            expect(rect.inflate(0.5).contains(labelRect.topLeft), isTrue);
            expect(rect.inflate(0.5).contains(labelRect.bottomRight), isTrue);
            final paragraph = tester.renderObject<RenderParagraph>(label);
            expect(
              paragraph.textScaler.scale(12),
              closeTo(12 * entry.$2, 0.01),
            );
            expect(paragraph.didExceedMaxLines, isFalse);
            expect(
              find.ancestor(of: label, matching: find.byType(FittedBox)),
              findsNothing,
            );
            await tester.tap(tile);
            await tester.pump();
            expect(
              tester
                  .getSemantics(tile)
                  .getSemanticsData()
                  .flagsCollection
                  .isSelected,
              Tristate.isTrue,
            );
            final details = find.byType(OnboardingV2DetailsButton);
            if (details.evaluate().isNotEmpty) {
              await tester.tap(details);
              await tester.pumpAndSettle();
              final korean = find.text(level.exampleKorean);
              expect(korean, findsOneWidget);
              expect(find.text(level.exampleTranslation), findsOneWidget);
              expect(tester.widget<Text>(korean).locale, const Locale('ko'));
              expect(
                tester
                    .renderObject<RenderParagraph>(korean)
                    .textScaler
                    .scale(12),
                closeTo(12 * entry.$2, 0.01),
              );
              await tester.sendKeyEvent(LogicalKeyboardKey.escape);
              await tester.pumpAndSettle();
            } else {
              final readings = tester.widgetList<JourneyReading>(
                find.byType(JourneyReading),
              );
              final exampleText = readings
                  .map((value) => value.text)
                  .join('\n');
              expect(exampleText, contains(level.exampleKorean));
              expect(exampleText, contains(level.exampleTranslation));
            }
            expect(_next(tester).onTap, isNotNull);
            expect(tester.takeException(), isNull);
          }
          for (var i = 0; i < rectangles.length; i++) {
            for (var j = i + 1; j < rectangles.length; j++) {
              expect(rectangles[i].overlaps(rectangles[j]), isFalse);
            }
          }
          await tester.tap(
            find.byKey(const ValueKey('onboarding-v2-setup-continue')),
          );
          expect(submitted?.levelCode, 'C2');
          expect(submitted?.purposeId, isNull);
          expect(find.byType(SingleChildScrollView), findsNothing);
          expect(tester.takeException(), isNull);
          semantics.dispose();
        },
      );
    }
  }
}

SoriButton _next(WidgetTester tester) => tester.widget<SoriButton>(
  find.byKey(const ValueKey('onboarding-v2-setup-continue')),
);

class _Levels extends StatefulWidget {
  const _Levels({required this.onSubmitted});
  final ValueChanged<OnboardingSetupSelection> onSubmitted;
  @override
  State<_Levels> createState() => _LevelsState();
}

class _LevelsState extends State<_Levels> {
  String? level;
  @override
  Widget build(BuildContext context) => OnboardingSetupScreen(
    copy: onboardingV2Copy(AppL10n.of(context)),
    selectedPurposeId: null,
    selectedLevelCode: level,
    onPurposeChanged: (_) {},
    onLevelChanged: (value) => setState(() => level = value),
    onContinue: widget.onSubmitted,
  );
}
