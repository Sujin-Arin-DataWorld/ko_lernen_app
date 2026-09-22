import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ko_lernen_app/l10n/generated/app_localizations.dart';
import 'package:ko_lernen_app/models/scenario.dart';
import 'package:ko_lernen_app/screens/listening_screen.dart';
import 'package:ko_lernen_app/services/storage_service.dart';
import 'package:ko_lernen_app/theme.dart';
import 'package:ko_lernen_app/widgets/sori/spotlight_coach.dart';
import 'package:ko_lernen_app/widgets/sori/illustrated_card.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/real_fonts.dart';

void main() {
  setUpAll(loadSoriRealFonts);

  testWidgets(
    'listening coach follows its loaded card through route entry, scroll and rotation',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(390, 844);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);
      Storage.resetForTesting();
      SharedPreferences.setMockInitialValues({'kl_user_level': 'a1'});
      await Storage.init();
      await Storage.resetTutorials();
      final loaded = Completer<List<Scenario>>();
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          locale: const Locale('de'),
          supportedLocales: AppL10n.supportedLocales,
          localizationsDelegates: AppL10n.localizationsDelegates,
          home: Builder(
            builder: (context) => TextButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) =>
                      ListeningScreen(scenariosLoader: () => loaded.future),
                ),
              ),
              child: const Text('Listen'),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Listen'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 80));
      expect(find.byKey(kSpotlightTooltipKey), findsNothing);
      loaded.complete([
        Scenario(
          id: 'coach-fixture',
          level: LearnerLevel.a1,
          emoji: '📻',
          register: Register.polite,
          shelf: 'a1_friends',
          backdrop: 'home',
          title: const LocalizedText(ko: '친구', de: 'Freunde', en: 'Friends'),
          intro: const LocalizedText(ko: '', de: '', en: ''),
          vocab: const [],
          grammarIds: const [],
          quests: const [],
          dialog: const [
            DialogLine(
              speaker: 'jieun',
              ko: '안녕하세요.',
              de: 'Hallo.',
              en: 'Hello.',
            ),
          ],
        ),
      ]);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 40));
      await tester.pump();

      void expectAnchored() {
        final card = tester.getRect(find.byType(SoriIllustratedCard).first);
        final paint = tester
            .widgetList<CustomPaint>(find.byType(CustomPaint))
            .singleWhere(
              (item) =>
                  item.painter.runtimeType.toString() == '_SpotlightPainter',
            );
        final hole = (paint.painter as dynamic).hole as Rect;
        expect(hole.left, closeTo(card.left - 8, 0.1));
        expect(hole.top, closeTo(card.top - 8, 0.1));
        expect(hole.right, closeTo(card.right + 8, 0.1));
        expect(hole.bottom, closeTo(card.bottom + 8, 0.1));
        final tooltip = tester.getRect(find.byKey(kSpotlightTooltipKey));
        final size = tester.view.physicalSize;
        expect(tooltip.left, greaterThanOrEqualTo(0));
        expect(tooltip.top, greaterThanOrEqualTo(0));
        expect(tooltip.right, lessThanOrEqualTo(size.width));
        expect(tooltip.bottom, lessThanOrEqualTo(size.height));
        expect(tester.takeException(), isNull);
      }

      expectAnchored();
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pump();
      expectAnchored();
      final scroll = tester.state<ScrollableState>(
        find
            .descendant(
              of: find.byType(ListeningScreen),
              matching: find.byType(Scrollable),
            )
            .first,
      );
      scroll.position.jumpTo(35);
      await tester.pump();
      await tester.pump();
      expectAnchored();
      tester.view.physicalSize = const Size(844, 390);
      await tester.pump();
      await tester.pump();
      expectAnchored();
      await tester.tap(find.text('Fertig'));
      await tester.pump(const Duration(milliseconds: 400));
      expect(Storage.tutSeen('listening'), isTrue);
      expect(find.byKey(kSpotlightTooltipKey), findsNothing);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  for (final nested in [false, true]) {
    testWidgets('coach tracks painted card and resize (nested=$nested)', (
      tester,
    ) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(800, 1000);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);
      final movement = ValueNotifier<double>(0);
      addTearDown(movement.dispose);
      final target = GlobalKey();
      final surface = GlobalKey();

      Widget page(BuildContext context) => Scaffold(
        key: surface,
        body: LayoutBuilder(
          builder: (context, constraints) => Stack(
            children: [
              ValueListenableBuilder<double>(
                valueListenable: movement,
                builder: (_, dy, _) => Positioned(
                  left: (constraints.maxWidth - 200) / 2,
                  top: constraints.maxHeight / 5,
                  child: Transform.translate(
                    offset: Offset(0, dy),
                    child: SizedBox(key: target, width: 200, height: 100),
                  ),
                ),
              ),
              TextButton(
                onPressed: () => SpotlightCoach.show(
                  context,
                  steps: [
                    SpotlightStep(
                      targetKey: target,
                      title: 'Hören',
                      body: 'Wähle eine Kategorie.',
                    ),
                  ],
                  onComplete: () {},
                ),
                child: const Text('Show guide'),
              ),
            ],
          ),
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          locale: const Locale('de'),
          supportedLocales: AppL10n.supportedLocales,
          localizationsDelegates: AppL10n.localizationsDelegates,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(disableAnimations: true),
            child: child!,
          ),
          home: nested
              ? Padding(
                  padding: const EdgeInsets.fromLTRB(100, 80, 60, 50),
                  child: Navigator(
                    onGenerateRoute: (_) =>
                        MaterialPageRoute<void>(builder: page),
                  ),
                )
              : Builder(builder: page),
        ),
      );
      await tester.tap(find.text('Show guide'));
      await tester.pump();
      await tester.pump();

      void expectAligned() {
        final card = tester.getRect(find.byKey(target));
        final tooltip = tester.getRect(find.byKey(kSpotlightTooltipKey));
        final bounds = tester.getRect(find.byKey(surface));
        expect(tooltip.top, closeTo(card.bottom + 12, 0.1));
        expect(tooltip.center.dx, closeTo(card.center.dx, 0.1));
        expect(tooltip.left, greaterThanOrEqualTo(bounds.left));
        expect(tooltip.right, lessThanOrEqualTo(bounds.right));
        expect(tooltip.bottom, lessThanOrEqualTo(bounds.bottom));
        expect(tester.takeException(), isNull);
      }

      expectAligned();
      movement.value = 60;
      await tester.pump();
      await tester.pump();
      expectAligned();

      tester.view.physicalSize = const Size(1000, 800);
      await tester.pump();
      await tester.pump();
      expectAligned();

      await tester.tap(find.text('Fertig'));
      await tester.pumpAndSettle();
      expect(find.byKey(kSpotlightTooltipKey), findsNothing);
      expect(tester.binding.hasScheduledFrame, isFalse);
    });
  }
}
