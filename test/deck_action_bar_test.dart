import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ko_lernen_app/l10n/generated/app_localizations.dart';
import 'package:ko_lernen_app/theme.dart';
import 'package:ko_lernen_app/widgets/sori/deck_action_bar.dart';

void main() {
  Widget host({
    required bool enabled,
    required VoidCallback onDontKnow,
    required VoidCallback onSkip,
    required VoidCallback onKnow,
    VoidCallback? onSave,
    VoidCallback? onBlocked,
    bool showSave = true,
  }) => MaterialApp(
    theme: AppTheme.light,
    locale: const Locale('de'),
    supportedLocales: AppL10n.supportedLocales,
    localizationsDelegates: AppL10n.localizationsDelegates,
    home: Scaffold(
      body: Center(
        child: DeckActionBar(
          judgmentsEnabled: enabled,
          onDontKnow: onDontKnow,
          onSkip: onSkip,
          onSave: onSave,
          onKnow: onKnow,
          onBlockedJudgment: onBlocked,
          showSave: showSave,
        ),
      ),
    ),
  );

  testWidgets('four accessible actions preserve their size hierarchy', (
    tester,
  ) async {
    await tester.pumpWidget(
      host(
        enabled: true,
        onDontKnow: () {},
        onSkip: () {},
        onSave: () {},
        onKnow: () {},
      ),
    );

    expect(find.bySemanticsLabel('Nicht gewusst'), findsOneWidget);
    expect(find.bySemanticsLabel('Überspringen'), findsOneWidget);
    expect(find.bySemanticsLabel('Merken'), findsOneWidget);
    expect(find.bySemanticsLabel('Gewusst'), findsOneWidget);

    final sizes = tester
        .widgetList<Container>(find.byType(Container))
        .map((container) => (container.constraints, container.decoration))
        .where((entry) => entry.$2 is BoxDecoration)
        .map((entry) => entry.$1)
        .whereType<BoxConstraints>()
        .where((constraints) => constraints.isTight)
        .map((constraints) => constraints.biggest)
        .where((size) => size.width == size.height)
        .toList();
    expect(sizes.where((size) => size.width == 64), hasLength(2));
    expect(sizes.where((size) => size.width == 48), hasLength(2));
  });

  testWidgets('judgment gate blocks rating but keeps skip and save active', (
    tester,
  ) async {
    var ratings = 0;
    var skips = 0;
    var saves = 0;
    var blocked = 0;
    await tester.pumpWidget(
      host(
        enabled: false,
        onDontKnow: () => ratings++,
        onSkip: () => skips++,
        onSave: () => saves++,
        onKnow: () => ratings++,
        onBlocked: () => blocked++,
      ),
    );

    await tester.tap(find.bySemanticsLabel('Nicht gewusst'));
    await tester.tap(find.bySemanticsLabel('Gewusst'));
    await tester.tap(find.bySemanticsLabel('Überspringen'));
    await tester.tap(find.bySemanticsLabel('Merken'));
    await tester.pump();

    expect(ratings, 0);
    expect(blocked, 2);
    expect(skips, 1);
    expect(saves, 1);
  });

  testWidgets('custom deck can hide save without changing judgment controls', (
    tester,
  ) async {
    await tester.pumpWidget(
      host(
        enabled: true,
        onDontKnow: () {},
        onSkip: () {},
        onKnow: () {},
        showSave: false,
      ),
    );

    expect(find.bySemanticsLabel('Merken'), findsNothing);
    expect(find.bySemanticsLabel('Nicht gewusst'), findsOneWidget);
    expect(find.bySemanticsLabel('Gewusst'), findsOneWidget);
  });
}
