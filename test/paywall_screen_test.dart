import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

import 'package:ko_lernen_app/l10n/generated/app_localizations.dart';
import 'package:ko_lernen_app/models/access_snapshot.dart';
import 'package:ko_lernen_app/screens/paywall_screen.dart';
import 'package:ko_lernen_app/services/premium_service.dart';
import 'package:ko_lernen_app/theme.dart';

void main() {
  testWidgets(
    'annual-only offering disables purchase without a fabricated monthly price',
    (tester) async {
      var purchases = 0;
      const annual = Package(
        'annual',
        PackageType.annual,
        StoreProduct(
          'annual',
          'Annual',
          'Annual',
          50,
          '€50.00',
          'EUR',
          subscriptionPeriod: 'P1Y',
        ),
        _context,
      );
      await tester.pumpWidget(
        _app(
          PaywallScreen(
            requiresSignIn: () => false,
            offeringLoader: () async => const Offering('annual', 'Annual', {}, [
              annual,
            ], annual: annual),
            purchaseOperation: (_) async {
              purchases++;
              return PremiumPurchaseOutcome.purchased;
            },
          ),
        ),
      );
      await tester.pumpAndSettle();
      final t = AppL10n.of(tester.element(find.byType(PaywallScreen)));
      expect(find.text(t.paywallNotAvailable), findsOneWidget);
      expect(find.textContaining('€50.00'), findsNothing);
      final action = tester.widget<Semantics>(
        find.byWidgetPredicate(
          (w) =>
              w is Semantics &&
              w.properties.label == t.paywallCtaStart &&
              w.properties.button == true,
        ),
      );
      expect(action.properties.enabled, isFalse);
      await tester.tap(find.text(t.paywallCtaStart));
      expect(purchases, 0);
    },
  );

  testWidgets(
    'guest goes to existing account connection before purchase or restore',
    (tester) async {
      var purchases = 0;
      await tester.pumpWidget(
        _app(
          PaywallScreen(
            requiresSignIn: () => true,
            offeringLoader: () async => null,
            purchaseOperation: (_) async {
              purchases++;
              return PremiumPurchaseOutcome.purchased;
            },
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Connect account'));
      await tester.pumpAndSettle();
      expect(find.text('Account connection'), findsOneWidget);
      expect(purchases, 0);
    },
  );

  testWidgets(
    'active subscription and approved tester never see duplicate purchase CTA',
    (tester) async {
      final access = ValueNotifier<AccessSnapshot?>(
        _premiumSnapshot('subscription'),
      );
      addTearDown(access.dispose);
      await tester.pumpWidget(
        _app(
          PaywallScreen(
            requiresSignIn: () => false,
            accessListenable: access,
            offeringLoader: () async => _offering,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Unlock Premium'), findsNothing);
      expect(find.text('Premium is already active'), findsOneWidget);
      expect(
        find.text('Manage subscription in its original store'),
        findsOneWidget,
      );
      access.value = _premiumSnapshot('closed_tester_lifetime');
      await tester.pumpAndSettle();
      expect(find.text('Unlock Premium'), findsNothing);
      expect(
        find.text('Your approved tester access is active'),
        findsOneWidget,
      );
      expect(
        find.text('Manage subscription in its original store'),
        findsNothing,
      );
    },
  );

  testWidgets('terms and privacy are working links and quotas are bounded', (
    tester,
  ) async {
    final links = <Uri>[];
    await tester.pumpWidget(
      _app(
        PaywallScreen(
          requiresSignIn: () => false,
          offeringLoader: () async => _offering,
          openLink: (uri) async {
            links.add(uri);
            return true;
          },
        ),
      ),
    );
    await tester.pumpAndSettle();
    final t = AppL10n.of(tester.element(find.byType(PaywallScreen)));
    for (final label in [t.settingsTermsTitle, t.settingsPrivacyTitle]) {
      await tester.ensureVisible(find.text(label));
      await tester.tap(find.text(label));
      await tester.pump();
    }
    expect(links.map((uri) => uri.path), ['/terms', '/privacy']);
    expect(find.text(t.paywallAiLimits(3, 5)), findsOneWidget);
    expect(find.textContaining('20'), findsWidgets);
    expect(find.textContaining('50'), findsWidgets);
    expect(find.textContaining('UTC'), findsWidgets);
  });

  testWidgets(
    'pending purchase keeps paywall open with explicit server confirmation status',
    (tester) async {
      await tester.pumpWidget(
        _app(
          PaywallScreen(
            requiresSignIn: () => false,
            offeringLoader: () async => _offering,
            purchaseOperation: (_) async => PremiumPurchaseOutcome.pending,
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Unlock Premium'));
      await tester.pump();
      final t = AppL10n.of(tester.element(find.byType(PaywallScreen)));
      expect(find.text(t.paywallPending), findsOneWidget);
      expect(find.byType(PaywallScreen), findsOneWidget);
    },
  );
  testWidgets('offering load owns an accessible disabled purchase state', (
    tester,
  ) async {
    final loader = Completer<Offering?>();
    var purchaseCalls = 0;
    await tester.pumpWidget(
      _app(
        PaywallScreen(
          requiresSignIn: () => false,
          offeringLoader: () => loader.future,
          purchaseOperation: (_) async {
            purchaseCalls++;
            return PremiumPurchaseOutcome.purchased;
          },
        ),
      ),
    );
    await tester.pump();

    final t = AppL10n.of(tester.element(find.byType(PaywallScreen)));
    final loadingAction = tester.widget<Semantics>(
      find.byWidgetPredicate(
        (widget) =>
            widget is Semantics &&
            widget.properties.label == t.paywallProcessing &&
            widget.properties.button == true,
      ),
    );
    expect(loadingAction.properties.enabled, isFalse);
    expect(find.bySemanticsLabel(t.paywallProcessing), findsWidgets);

    await tester.tap(find.text(t.paywallProcessing).last);
    await tester.pump();
    expect(purchaseCalls, 0);
    expect(find.byType(SnackBar), findsNothing);

    loader.complete(_offering);
    await tester.pumpAndSettle();
    expect(find.text('Unlock Premium'), findsOneWidget);
  });

  testWidgets('restore stays available while an offering is loading', (
    tester,
  ) async {
    final loader = Completer<Offering?>();
    var restoreCalls = 0;
    await tester.pumpWidget(
      _app(
        PaywallScreen(
          requiresSignIn: () => false,
          offeringLoader: () => loader.future,
          restoreOperation: () async {
            restoreCalls++;
            return PremiumRestoreOutcome.none;
          },
        ),
      ),
    );
    await tester.pump();

    await tester.tap(find.text('Restore purchases'));
    await tester.pump();

    expect(restoreCalls, 1);
    expect(find.text('No previous purchases found.'), findsOneWidget);
    loader.complete(null);
    await tester.pumpAndSettle();
  });

  testWidgets('busy purchase disables every competing paywall action', (
    tester,
  ) async {
    final purchase = Completer<PremiumPurchaseOutcome>();
    await tester.pumpWidget(
      _app(
        PaywallScreen(
          requiresSignIn: () => false,
          offeringLoader: () async => _offering,
          purchaseOperation: (_) => purchase.future,
        ),
      ),
    );
    await tester.pumpAndSettle();

    final context = tester.element(find.byType(PaywallScreen));
    final t = AppL10n.of(context);
    await tester.tap(find.text(t.paywallCtaStart));
    await tester.pump();

    final processing = tester.widget<Semantics>(
      find.byWidgetPredicate(
        (widget) =>
            widget is Semantics &&
            widget.properties.label == t.paywallProcessing &&
            widget.properties.button == true,
      ),
    );
    final restore = tester.widget<Semantics>(
      find.byWidgetPredicate(
        (widget) =>
            widget is Semantics &&
            widget.properties.label == t.paywallCtaRestore &&
            widget.properties.button == true,
      ),
    );
    final close = tester.widget<Semantics>(
      find.byWidgetPredicate(
        (widget) =>
            widget is Semantics &&
            widget.properties.label == t.paywallClose &&
            widget.properties.button == true,
      ),
    );
    expect(processing.properties.enabled, isFalse);
    expect(restore.properties.enabled, isFalse);
    expect(close.properties.enabled, isFalse);
    final closeButtonFinder = find.widgetWithIcon(
      IconButton,
      Icons.close_rounded,
    );
    final closeButton = tester.widget<IconButton>(closeButtonFinder);
    final closeIcon = tester.widget<Icon>(
      find.descendant(
        of: closeButtonFinder,
        matching: find.byIcon(Icons.close_rounded),
      ),
    );
    expect(closeButton.onPressed, isNull);
    expect(closeButton.disabledColor, isNot(closeButton.color));
    expect(closeIcon.color, isNull);

    purchase.complete(PremiumPurchaseOutcome.cancelled);
    await tester.pumpAndSettle();
    expect(find.text(t.paywallCtaStart), findsOneWidget);
  });

  testWidgets('offering failure becomes the localized unavailable state', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(
        PaywallScreen(
          requiresSignIn: () => false,
          offeringLoader: () async => throw StateError('offline'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final t = AppL10n.of(tester.element(find.byType(PaywallScreen)));
    expect(find.text(t.paywallCtaStart), findsOneWidget);
    await tester.tap(find.text(t.paywallCtaStart));
    await tester.pump();
    expect(find.text(t.paywallNotAvailable), findsOneWidget);
  });

  testWidgets('localized close action has a 48dp target', (tester) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(
      _app(
        PaywallScreen(
          requiresSignIn: () => false,
          offeringLoader: () async => _offering,
        ),
        locale: const Locale('de'),
      ),
    );
    await tester.pumpAndSettle();

    final close = find.byTooltip('Vielleicht später');
    expect(close, findsOneWidget);
    expect(tester.getSize(close).width, greaterThanOrEqualTo(48));
    expect(tester.getSize(close).height, greaterThanOrEqualTo(48));
    expect(find.bySemanticsLabel('Vielleicht später'), findsOneWidget);
    semantics.dispose();
  });

  testWidgets('DE and EN viewport matrix keeps every action reachable', (
    tester,
  ) async {
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    const viewports = <({Size size, double textScale})>[
      (size: Size(320, 640), textScale: 2),
      (size: Size(360, 400), textScale: 1),
      (size: Size(390, 844), textScale: 1.3),
      (size: Size(720, 1024), textScale: 1.3),
      (size: Size(1280, 900), textScale: 1.3),
    ];

    for (final locale in const [Locale('de'), Locale('en')]) {
      for (final viewport in viewports) {
        tester.view.physicalSize = viewport.size;
        tester.view.devicePixelRatio = 1;
        await tester.pumpWidget(
          _app(
            PaywallScreen(
              requiresSignIn: () => false,
              offeringLoader: () async => _offering,
            ),
            locale: locale,
            textScale: viewport.textScale,
          ),
        );
        await tester.pumpAndSettle();

        final context = tester.element(find.byType(PaywallScreen));
        final t = AppL10n.of(context);
        expect(find.text(t.paywallCtaStart), findsOneWidget);
        expect(find.text(t.paywallCtaRestore), findsOneWidget);
        expect(find.text(t.paywallLegal), findsOneWidget);
        expect(find.byTooltip(t.paywallClose), findsOneWidget);
        expect(tester.takeException(), isNull);

        for (final label in [
          t.paywallCtaStart,
          t.paywallCtaRestore,
          t.paywallLegal,
          t.settingsTermsTitle,
          t.settingsPrivacyTitle,
        ]) {
          await tester.ensureVisible(find.text(label));
          await tester.pumpAndSettle();
          expect(find.text(label).hitTestable(), findsOneWidget);
          expect(tester.takeException(), isNull);
        }
      }
    }
  });
}

Widget _app(
  Widget home, {
  Locale locale = const Locale('en'),
  double textScale = 1,
}) => MaterialApp(
  theme: AppTheme.light,
  locale: locale,
  supportedLocales: AppL10n.supportedLocales,
  localizationsDelegates: AppL10n.localizationsDelegates,
  builder: (context, child) => MediaQuery(
    data: MediaQuery.of(
      context,
    ).copyWith(textScaler: TextScaler.linear(textScale)),
    child: child!,
  ),
  home: home,
  routes: {'/profile': (_) => const Scaffold(body: Text('Account connection'))},
);

AccessSnapshot _premiumSnapshot(String source) => AccessSnapshot.fromJson({
  'schemaVersion': 1,
  'ownerUid': 'a',
  'environment': 'PRODUCTION',
  'revision': 'a' * 64,
  'source': source,
  'contentAccess': 'all',
  'aiPolicyId': 'premium_v1',
  'bookDailyLimit': 20,
  'pronunciationDailyLimit': 50,
  'serverNow': 172800000,
  'accessUntil': source == 'subscription' ? 259200000 : null,
  'offlineUntil': 259200000,
  'nextResetAt': 259200000,
});

const _context = PresentedOfferingContext('default', null, null);
const _product = StoreProduct(
  'hangul_sori_monthly',
  'Monthly Premium',
  'Hangul Sori Premium',
  5,
  '€5.00',
  'EUR',
  subscriptionPeriod: 'P1M',
);
const _package = Package(
  r'$rc_monthly',
  PackageType.monthly,
  _product,
  _context,
);
const _offering = Offering(
  'default',
  'Default offering',
  <String, Object>{},
  <Package>[_package],
  monthly: _package,
);
