import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ko_lernen_app/l10n/generated/app_localizations.dart';
import 'package:ko_lernen_app/screens/sori_stage/c_stage_chrome.dart';
import 'package:ko_lernen_app/theme.dart';

import 'support/c_fonts.dart';
import 'support/real_fonts.dart';

void main() {
  setUpAll(() async {
    await loadSoriRealFonts(materialIcons: true);
    await loadCFonts();
  });

  for (final balance in <int?>[null, 0, 80, 9223372036854775807]) {
    testWidgets(
      'C header at 320dp / 200% shows only confirmed balance $balance',
      (tester) async {
        tester.view.physicalSize = const Size(320, 640);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final semantics = tester.ensureSemantics();
        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.light,
            locale: const Locale('de'),
            supportedLocales: AppL10n.supportedLocales,
            localizationsDelegates: AppL10n.localizationsDelegates,
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context).copyWith(
                textScaler: const TextScaler.linear(2),
                disableAnimations: true,
              ),
              child: child!,
            ),
            home: Scaffold(
              body: CStageBackground(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(12),
                  child: CStageHeader(title: 'Dein Hanok', balance: balance),
                ),
              ),
            ),
            routes: {
              '/settings': (_) =>
                  const Scaffold(body: Text('Actual settings route')),
            },
          ),
        );
        await tester.pumpAndSettle();
        final wallet = find.byKey(const ValueKey('yeopjeon-header-balance'));
        expect(wallet, balance == null ? findsNothing : findsOneWidget);
        if (balance != null) {
          expect(find.text('$balance'), findsOneWidget);
          final header = find.byType(CStageHeader);
          expect(
            tester.getRect(wallet).right,
            lessThanOrEqualTo(tester.getRect(header).right),
          );
        }
        final t = AppL10n.of(tester.element(find.byType(CStageHeader)));
        final settings = find.bySemanticsLabel(t.settingsTitle);
        expect(settings, findsOneWidget);
        final node = tester.getSemantics(settings);
        expect(node.getSemanticsData().hasAction(SemanticsAction.tap), isTrue);
        expect(node.getSemanticsData().flagsCollection.isHeader, isFalse);
        node.owner!.performAction(node.id, SemanticsAction.tap);
        await tester.pumpAndSettle();
        expect(find.text('Actual settings route'), findsOneWidget);
        expect(tester.takeException(), isNull);
        semantics.dispose();
      },
    );
  }
}
