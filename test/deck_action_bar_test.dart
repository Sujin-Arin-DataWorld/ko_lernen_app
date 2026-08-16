import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ko_lernen_app/l10n/generated/app_localizations.dart';
import 'package:ko_lernen_app/theme.dart';
import 'package:ko_lernen_app/widgets/sori/deck_action_bar.dart';
import 'package:ko_lernen_app/widgets/sori/pressable.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Widget host({
    required VoidCallback onDontKnow,
    required VoidCallback onKnow,
    required VoidCallback onSkip,
    VoidCallback? onSave,
    bool judgmentsEnabled = true,
    VoidCallback? onBlockedJudgmentTap,
    bool showSave = true,
    bool skipEnabled = true,
  }) => MaterialApp(
    theme: AppTheme.light,
    locale: const Locale('de'),
    supportedLocales: AppL10n.supportedLocales,
    localizationsDelegates: AppL10n.localizationsDelegates,
    home: Scaffold(
      body: Center(
        child: SoriDeckActionBar(
          onDontKnow: onDontKnow,
          onKnow: onKnow,
          onSkip: onSkip,
          onSave: onSave,
          judgmentsEnabled: judgmentsEnabled,
          onBlockedJudgmentTap: onBlockedJudgmentTap,
          showSave: showSave,
          skipEnabled: skipEnabled,
          dontKnowLabel: 'Nicht gewusst',
          knowLabel: 'Gewusst',
          skipLabel: 'Überspringen',
          saveLabel: 'Speichern',
        ),
      ),
    ),
  );

  void tapAction(WidgetTester tester, String name) {
    tester
        .widget<SoriPressable>(
          find.descendant(
            of: find.byKey(deckActionKey(name)),
            matching: find.byType(SoriPressable),
          ),
        )
        .onTap
        ?.call();
  }

  testWidgets('all four actions call their handler exactly once', (
    tester,
  ) async {
    var dontKnow = 0;
    var know = 0;
    var skip = 0;
    var save = 0;
    await tester.pumpWidget(
      host(
        onDontKnow: () => dontKnow++,
        onKnow: () => know++,
        onSkip: () => skip++,
        onSave: () => save++,
      ),
    );

    for (final name in ['dontknow', 'skip', 'save', 'know']) {
      tapAction(tester, name);
    }
    await tester.pump();

    expect([dontKnow, skip, save, know], [1, 1, 1, 1]);
  });

  testWidgets('judgment lock preserves layout and routes taps to hint', (
    tester,
  ) async {
    var judged = 0;
    var blocked = 0;
    var skip = 0;
    var save = 0;
    await tester.pumpWidget(
      host(
        onDontKnow: () => judged++,
        onKnow: () => judged++,
        onSkip: () => skip++,
        onSave: () => save++,
        judgmentsEnabled: false,
        onBlockedJudgmentTap: () => blocked++,
      ),
    );
    final lockedSize = tester.getSize(
      find.byKey(const ValueKey('deck-action-bar')),
    );

    tapAction(tester, 'dontknow');
    tapAction(tester, 'know');
    tapAction(tester, 'skip');
    tapAction(tester, 'save');
    await tester.pump();

    expect(judged, 0);
    expect(blocked, 2);
    expect([skip, save], [1, 1]);

    await tester.pumpWidget(
      host(onDontKnow: () {}, onKnow: () {}, onSkip: () {}, onSave: () {}),
    );
    expect(
      tester.getSize(find.byKey(const ValueKey('deck-action-bar'))),
      lockedSize,
    );
  });

  testWidgets('save can be hidden without removing the other actions', (
    tester,
  ) async {
    await tester.pumpWidget(
      host(onDontKnow: () {}, onKnow: () {}, onSkip: () {}, showSave: false),
    );

    expect(find.byKey(deckActionKey('save')), findsNothing);
    for (final name in ['dontknow', 'skip', 'know']) {
      expect(find.byKey(deckActionKey(name)), findsOneWidget);
    }
  });

  testWidgets('last-card skip stays visible but cannot call defer', (
    tester,
  ) async {
    var skipped = 0;
    await tester.pumpWidget(
      host(
        onDontKnow: () {},
        onKnow: () {},
        onSkip: () => skipped++,
        onSave: () {},
        skipEnabled: false,
      ),
    );

    expect(find.byKey(deckActionKey('skip')), findsOneWidget);
    tapAction(tester, 'skip');
    await tester.pump();

    expect(skipped, 0);
    expect(
      tester
          .widget<Opacity>(
            find.descendant(
              of: find.byKey(deckActionKey('skip')),
              matching: find.byType(Opacity),
            ),
          )
          .opacity,
      0.38,
    );

    final semantics = tester.ensureSemantics();
    final skipSemantics = tester.getSemantics(
      find.bySemanticsLabel('Überspringen'),
    );
    final skipData = skipSemantics.getSemanticsData();
    expect(skipData.label, 'Überspringen');
    expect(skipData.flagsCollection.isButton, isTrue);
    expect(skipData.flagsCollection.isEnabled, ui.Tristate.isFalse);
    expect(skipData.hasAction(ui.SemanticsAction.tap), isFalse);
    semantics.dispose();
  });

  testWidgets('locked judgment remains an accessible hint action', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    var hints = 0;
    await tester.pumpWidget(
      host(
        onDontKnow: () {},
        onKnow: () {},
        onSkip: () {},
        judgmentsEnabled: false,
        onBlockedJudgmentTap: () => hints++,
      ),
    );

    final node = tester.getSemantics(find.bySemanticsLabel('Gewusst'));
    final data = node.getSemanticsData();
    expect(data.label, 'Gewusst');
    expect(data.flagsCollection.isButton, isTrue);
    expect(data.flagsCollection.isEnabled, ui.Tristate.isTrue);
    expect(data.hasAction(ui.SemanticsAction.tap), isTrue);
    tapAction(tester, 'know');
    expect(hints, 1);
    semantics.dispose();
  });

  testWidgets('buttons expose 48dp targets and approved fallback icons', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(
      host(onDontKnow: () {}, onKnow: () {}, onSkip: () {}, onSave: () {}),
    );

    for (final name in ['dontknow', 'skip', 'save', 'know']) {
      expect(
        tester.getSize(find.byKey(deckActionKey(name))).shortestSide,
        greaterThanOrEqualTo(48),
      );
    }
    expect(find.byType(Image), findsNothing);
    expect(find.byIcon(Icons.question_mark_rounded), findsOneWidget);
    expect(find.byIcon(Icons.arrow_downward_rounded), findsOneWidget);
    expect(find.byIcon(Icons.redeem_rounded), findsOneWidget);
    expect(find.byIcon(Icons.check_rounded), findsOneWidget);
    semantics.dispose();
  });

  testWidgets('judgments anchor the edges and vertical actions stay between', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      host(onDontKnow: () {}, onKnow: () {}, onSkip: () {}, onSave: () {}),
    );

    final bar = tester.getRect(find.byKey(const ValueKey('deck-action-bar')));
    final dontKnow = tester.getRect(find.byKey(deckActionKey('dontknow')));
    final skip = tester.getRect(find.byKey(deckActionKey('skip')));
    final save = tester.getRect(find.byKey(deckActionKey('save')));
    final know = tester.getRect(find.byKey(deckActionKey('know')));

    expect(dontKnow.left, closeTo(bar.left, 0.01));
    expect(know.right, closeTo(bar.right, 0.01));
    expect(dontKnow.center.dx, lessThan(skip.center.dx));
    expect(skip.center.dx, lessThan(save.center.dx));
    expect(save.center.dx, lessThan(know.center.dx));
    expect((skip.center.dx + save.center.dx) / 2, closeTo(bar.center.dx, 0.01));
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(
      host(onDontKnow: () {}, onKnow: () {}, onSkip: () {}, showSave: false),
    );
    final compactBar = tester.getRect(
      find.byKey(const ValueKey('deck-action-bar')),
    );
    expect(
      tester.getRect(find.byKey(deckActionKey('dontknow'))).left,
      closeTo(compactBar.left, 0.01),
    );
    expect(
      tester.getRect(find.byKey(deckActionKey('know'))).right,
      closeTo(compactBar.right, 0.01),
    );
    expect(
      tester.getRect(find.byKey(deckActionKey('skip'))).center.dx,
      closeTo(compactBar.center.dx, 0.01),
    );
    expect(tester.takeException(), isNull);
  });
}
