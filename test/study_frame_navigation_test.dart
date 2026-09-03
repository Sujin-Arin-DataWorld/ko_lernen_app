import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ko_lernen_app/l10n/generated/app_localizations.dart';
import 'package:ko_lernen_app/theme.dart';
import 'package:ko_lernen_app/widgets/sori/home_action.dart';
import 'package:ko_lernen_app/widgets/sori/standard_page.dart';
import 'package:ko_lernen_app/widgets/sori/study_frame.dart';

/// §B2/B3(2026-09-03) — verifies the unified exit chrome contract:
///
/// - [SoriStudyFrame] always renders one [SoriCloseAction] (leading) and one
///   [SoriHomeAction] (trailing).
/// - Close and system back share the exact same confirm-before-leaving rule
///   ([SoriHomeEscape.confirmWhen]).
/// - [SoriStandardPage] adds an unconfirmed home action only when the route
///   it lives on can pop (root tabs never get one).
void main() {
  Future<NavigatorState> pumpDeepFrame(
    WidgetTester tester, {
    required SoriHomeEscape homeEscape,
    VoidCallback? onLeave,
  }) async {
    final navigatorKey = GlobalKey<NavigatorState>();
    await tester.pumpWidget(
      MaterialApp(
        navigatorKey: navigatorKey,
        theme: AppTheme.light,
        locale: const Locale('de'),
        supportedLocales: AppL10n.supportedLocales,
        localizationsDelegates: AppL10n.localizationsDelegates,
        home: const Scaffold(body: Text('ROOT')),
      ),
    );
    navigatorKey.currentState!.push(
      MaterialPageRoute<void>(
        builder: (_) => SoriStudyFrame(
          title: 'Deep',
          homeEscape: homeEscape,
          onLeave: onLeave,
          child: const SizedBox.expand(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return navigatorKey.currentState!;
  }

  group('SoriStudyFrame renders both exits', () {
    testWidgets('one close action and one home action', (tester) async {
      await pumpDeepFrame(tester, homeEscape: const SoriHomeEscape());

      expect(find.byType(SoriCloseAction), findsOneWidget);
      expect(find.byType(SoriHomeAction), findsOneWidget);
    });
  });

  group('SoriStudyFrame close action', () {
    testWidgets(
      'confirmWhen true shows a sheet; confirming leaves and pops',
      (tester) async {
        var leaveCalls = 0;
        await pumpDeepFrame(
          tester,
          homeEscape: const SoriHomeEscape(confirmWhen: true),
          onLeave: () => leaveCalls++,
        );

        await tester.tap(find.byType(SoriCloseAction));
        await tester.pumpAndSettle();

        final t = await AppL10n.delegate.load(const Locale('de'));
        expect(find.text(t.homeActionConfirmTitle), findsOneWidget);
        expect(find.text('Deep'), findsOneWidget);
        expect(leaveCalls, 0);

        await tester.tap(find.text(t.homeActionConfirmLeave));
        await tester.pumpAndSettle();

        expect(leaveCalls, 1);
        expect(find.text('ROOT'), findsOneWidget);
        expect(find.text('Deep'), findsNothing);
      },
    );

    testWidgets(
      'confirmWhen true and staying keeps the route and skips onLeave',
      (tester) async {
        var leaveCalls = 0;
        await pumpDeepFrame(
          tester,
          homeEscape: const SoriHomeEscape(confirmWhen: true),
          onLeave: () => leaveCalls++,
        );

        await tester.tap(find.byType(SoriCloseAction));
        await tester.pumpAndSettle();

        final t = await AppL10n.delegate.load(const Locale('de'));
        await tester.tap(find.text(t.homeActionConfirmStay));
        await tester.pumpAndSettle();

        expect(leaveCalls, 0);
        expect(find.text('Deep'), findsOneWidget);
      },
    );

    testWidgets('confirmWhen false pops immediately without a sheet', (
      tester,
    ) async {
      var leaveCalls = 0;
      await pumpDeepFrame(
        tester,
        homeEscape: const SoriHomeEscape(),
        onLeave: () => leaveCalls++,
      );

      await tester.tap(find.byType(SoriCloseAction));
      await tester.pumpAndSettle();

      expect(leaveCalls, 1);
      expect(find.text('ROOT'), findsOneWidget);
    });
  });

  group('SoriStudyFrame system back follows the same rule as close', () {
    testWidgets('confirmWhen true intercepts system back with the sheet', (
      tester,
    ) async {
      await pumpDeepFrame(
        tester,
        homeEscape: const SoriHomeEscape(confirmWhen: true),
      );

      final handled = await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();

      expect(handled, isTrue);
      final t = await AppL10n.delegate.load(const Locale('de'));
      expect(find.text(t.homeActionConfirmTitle), findsOneWidget);
      expect(find.text('Deep'), findsOneWidget);
    });

    testWidgets('confirmWhen false lets system back pop directly', (
      tester,
    ) async {
      await pumpDeepFrame(tester, homeEscape: const SoriHomeEscape());

      final handled = await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();

      expect(handled, isTrue);
      expect(find.text('ROOT'), findsOneWidget);
    });
  });

  group('SoriStandardPage home action', () {
    testWidgets('renders on a route it was pushed onto', (tester) async {
      final navigatorKey = GlobalKey<NavigatorState>();
      await tester.pumpWidget(
        MaterialApp(
          navigatorKey: navigatorKey,
          theme: AppTheme.light,
          locale: const Locale('de'),
          supportedLocales: AppL10n.supportedLocales,
          localizationsDelegates: AppL10n.localizationsDelegates,
          home: const Scaffold(body: Text('ROOT')),
        ),
      );
      navigatorKey.currentState!.push(
        MaterialPageRoute<void>(
          builder: (_) => const SoriStandardPage(
            appBarTitle: 'Pushed',
            children: [SizedBox.shrink()],
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(SoriHomeAction), findsOneWidget);
    });

    testWidgets('is absent at the root, where there is nothing to pop', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          locale: const Locale('de'),
          supportedLocales: AppL10n.supportedLocales,
          localizationsDelegates: AppL10n.localizationsDelegates,
          home: const SoriStandardPage(
            appBarTitle: 'Root',
            children: [SizedBox.shrink()],
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(SoriHomeAction), findsNothing);
    });
  });
}
