import 'dart:ui' show Tristate;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ko_lernen_app/l10n/generated/app_localizations.dart';
import 'package:ko_lernen_app/screens/onboarding_v2/c_onboarding.dart';
import 'package:ko_lernen_app/screens/onboarding_v2/onboarding_setup_screen.dart';
import 'package:ko_lernen_app/screens/onboarding_v2/onboarding_v2_copy.dart';
import 'package:ko_lernen_app/screens/onboarding_v2/onboarding_v2_presentation.dart';
import 'package:ko_lernen_app/theme.dart';
import 'support/real_fonts.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    await loadSoriRealFonts(materialIcons: true);
    for (final family in ['Roboto', 'RobotoCondensed', 'Lora', 'NotoSerif']) {
      final loader = FontLoader(family);
      loader.addFont(
        rootBundle.load('assets/fonts/$family/$family-Variable.ttf'),
      );
      await loader.load();
    }
  });
  for (final locale in ['de', 'en']) {
    for (final entry in const [
      (Size(360, 800), 1.0),
      (Size(390, 844), 1.3),
      (Size(720, 1152), 1.0),
      (Size(320, 640), 2.0),
    ]) {
      testWidgets('$locale level choices retain scale and staged apply at $entry', (
        tester,
      ) async {
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
        await _tapVisible(
          tester,
          find.byKey(const ValueKey('c-onboarding-change-level')),
        );
        expect(
          tester
              .widget<IntroAction>(
                find.byKey(const ValueKey('intro-level-apply')),
              )
              .onTap,
          isNull,
        );
        final setup = tester.widget<OnboardingSetupScreen>(
          find.byType(OnboardingSetupScreen),
        );
        String? previous;
        for (final level in setup.copy.setup.levels) {
          final tile = find.byKey(
            ValueKey('onboarding-v2-level-${level.code}'),
          );
          final label = find.descendant(
            of: tile,
            matching: find.text(level.code),
          );
          await tester.ensureVisible(tile);
          await tester.pumpAndSettle();
          final rect = tester.getRect(tile);
          final rectangles = [
            for (final choice in setup.copy.setup.levels)
              tester.getRect(
                find.byKey(ValueKey('onboarding-v2-level-${choice.code}')),
              ),
          ];
          for (var i = 0; i < rectangles.length; i++) {
            for (var j = i + 1; j < rectangles.length; j++) {
              expect(
                rectangles[i].overlaps(rectangles[j]),
                isFalse,
                reason:
                    'Level choices $i and $j must not overlap in the same sheet.',
              );
            }
          }
          expect(rect.width, greaterThanOrEqualTo(48));
          expect(rect.height, greaterThanOrEqualTo(48));
          final labelRect = tester.getRect(label);
          expect(rect.inflate(.5).contains(labelRect.topLeft), isTrue);
          expect(rect.inflate(.5).contains(labelRect.bottomRight), isTrue);
          final paragraph = tester.renderObject<RenderParagraph>(label);
          expect(paragraph.textScaler.scale(12), closeTo(12 * entry.$2, .01));
          expect(paragraph.didExceedMaxLines, isFalse);
          expect(
            find.ancestor(of: label, matching: find.byType(FittedBox)),
            findsNothing,
          );
          await _tapVisible(tester, tile);
          expect(
            tester
                .getSemantics(_selectionSemantics(tile))
                .getSemanticsData()
                .flagsCollection
                .isSelected,
            Tristate.isTrue,
          );
          expect(
            tester
                .widget<OnboardingSetupScreen>(
                  find.byType(OnboardingSetupScreen),
                )
                .selectedLevelCode,
            previous,
            reason: 'A draft choice must not commit before Apply.',
          );
          final apply = find.byKey(const ValueKey('intro-level-apply'));
          expect(tester.widget<IntroAction>(apply).onTap, isNotNull);
          await _tapVisible(tester, apply);
          expect(apply, findsNothing);
          expect(
            tester
                .widget<OnboardingSetupScreen>(
                  find.byType(OnboardingSetupScreen),
                )
                .selectedLevelCode,
            level.code,
          );
          expect(_next(tester).onTap, isNotNull);
          previous = level.code;
          await _tapVisible(
            tester,
            find.byKey(const ValueKey('c-onboarding-change-level')),
          );
          expect(tester.takeException(), isNull);
        }
        // Cancel keeps the last applied C2 value; it does not reset the draft owner.
        await _tapVisible(
          tester,
          find.byKey(const ValueKey('onboarding-v3-new')),
        );
        await _tapVisible(
          tester,
          find.byKey(const ValueKey('c-onboarding-sheet-close')),
        );
        expect(
          tester
              .widget<OnboardingSetupScreen>(find.byType(OnboardingSetupScreen))
              .selectedLevelCode,
          'C2',
        );
        await _tapVisible(
          tester,
          find.byKey(const ValueKey('onboarding-v2-setup-continue')),
        );
        expect(submitted?.levelCode, 'C2');
        expect(submitted?.purposeId, isNull);
        // Beginner is a distinct choice even though its learning level is A1.
        await _tapVisible(
          tester,
          find.byKey(const ValueKey('c-onboarding-change-level')),
        );
        await _tapVisible(
          tester,
          find.byKey(const ValueKey('onboarding-v3-new')),
        );
        await _tapVisible(
          tester,
          find.byKey(const ValueKey('intro-level-apply')),
        );
        final beginner = tester.widget<OnboardingSetupScreen>(
          find.byType(OnboardingSetupScreen),
        );
        expect(beginner.selectedLevelCode, 'A1');
        expect(beginner.beginnerSelected, isTrue);
        expect(tester.takeException(), isNull);
        semantics.dispose();
      });
    }
  }
}

IntroAction _next(WidgetTester tester) => tester.widget<IntroAction>(
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
  bool beginner = false;
  @override
  Widget build(BuildContext context) => OnboardingSetupScreen(
    copy: onboardingV2Copy(AppL10n.of(context)),
    selectedPurposeId: null,
    selectedLevelCode: level,
    onPurposeChanged: (_) {},
    beginnerSelected: beginner,
    onLevelChanged: (value) => setState(() {
      level = value;
      beginner = false;
    }),
    onBeginnerSelected: () => setState(() {
      level = 'A1';
      beginner = true;
    }),
    onContinue: widget.onSubmitted,
  );
}

Future<void> _tapVisible(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  final scrolls = find.ancestor(of: finder, matching: find.byType(Scrollable));
  var rect = tester.getRect(finder);
  if (scrolls.evaluate().isNotEmpty) {
    rect = rect.intersect(tester.getRect(scrolls.first));
  }
  expect(rect.width, greaterThanOrEqualTo(48));
  expect(rect.height, greaterThanOrEqualTo(48));
  await tester.tapAt(rect.center);
  await tester.pumpAndSettle();
}

Finder _selectionSemantics(Finder tile) {
  final selected = find.byWidgetPredicate(
    (widget) => widget is Semantics && widget.properties.selected != null,
  );
  final descendants = find.descendant(of: tile, matching: selected);
  return descendants.evaluate().isNotEmpty
      ? descendants.first
      : find.ancestor(of: tile, matching: selected).first;
}
