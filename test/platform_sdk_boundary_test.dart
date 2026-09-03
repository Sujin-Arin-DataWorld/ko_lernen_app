import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

import 'package:ko_lernen_app/l10n/generated/app_localizations.dart';
import 'package:ko_lernen_app/screens/paywall_screen.dart';
import 'package:ko_lernen_app/services/premium_service.dart';
import 'package:ko_lernen_app/theme.dart';

void main() {
  test('platform and SDK calls stay behind their app-owned boundaries', () {
    expect(_filesContaining('Permission.camera.request()'), <String>{
      'lib/screens/book_capture_screen.dart',
      'lib/services/word_image_service.dart',
    });
    expect(
      _filesContaining('NotificationService.requestPermission()'),
      <String>{'lib/screens/settings_screen.dart'},
    );
    expect(_filesContaining('_recorder.requestPermission()'), <String>{
      'lib/screens/pronunciation_studio_screen.dart',
    });
    expect(_filesContaining('Purchases.purchase('), <String>{
      'lib/services/premium_service.dart',
    });
    expect(_filesContaining('Purchases.restorePurchases()'), <String>{
      'lib/services/premium_service.dart',
    });
    expect(_filesContaining('GoogleOAuthClient.signIn()'), <String>{
      'lib/services/auth_service.dart',
    });
    expect(_filesContaining('SignInWithApple.getAppleIDCredential'), <String>{
      'lib/services/account/apple_oauth_request.dart',
    });
  });

  test('RevenueCat cancellation stays distinct from an SDK failure', () {
    expect(
      premiumPurchaseOutcomeForError(PlatformException(code: '1')),
      PremiumPurchaseOutcome.cancelled,
    );
    expect(
      premiumPurchaseOutcomeForError(PlatformException(code: '10')),
      PremiumPurchaseOutcome.failed,
    );
    expect(
      premiumPurchaseOutcomeForError(StateError('offline')),
      PremiumPurchaseOutcome.failed,
    );
  });

  testWidgets('cancelled store purchase returns quietly to the paywall', (
    tester,
  ) async {
    var purchaseCalls = 0;
    await tester.pumpWidget(
      _app(
        PaywallScreen(
          requiresSignIn: () => false,
          offeringLoader: () async => _offering,
          purchaseOperation: (_) async {
            purchaseCalls++;
            return PremiumPurchaseOutcome.cancelled;
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Unlock Premium'));
    await tester.pumpAndSettle();

    expect(purchaseCalls, 1);
    expect(find.byType(PaywallScreen), findsOneWidget);
    expect(find.byType(SnackBar), findsNothing);
  });

  testWidgets('store failure returns an app-owned retryable error state', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(
        PaywallScreen(
          requiresSignIn: () => false,
          offeringLoader: () async => _offering,
          purchaseOperation: (_) async => PremiumPurchaseOutcome.failed,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Unlock Premium'));
    await tester.pump();

    expect(find.text('Purchase not completed.'), findsOneWidget);
    expect(find.text('Unlock Premium'), findsOneWidget);
  });

  testWidgets('restore SDK failure is not reported as no prior purchase', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(
        PaywallScreen(
          requiresSignIn: () => false,
          offeringLoader: () async => _offering,
          restoreOperation: () async => PremiumRestoreOutcome.failed,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Restore purchases'));
    await tester.pump();

    expect(
      find.text('Purchases could not be restored. Try again.'),
      findsOneWidget,
    );
    expect(find.text('No previous purchases found.'), findsNothing);
  });
}

Widget _app(Widget home) => MaterialApp(
  theme: AppTheme.light,
  locale: const Locale('en'),
  supportedLocales: AppL10n.supportedLocales,
  localizationsDelegates: AppL10n.localizationsDelegates,
  home: home,
);

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

Set<String> _filesContaining(String token) => Directory('lib')
    .listSync(recursive: true)
    .whereType<File>()
    .where((file) => file.path.endsWith('.dart'))
    .where((file) => file.readAsStringSync().contains(token))
    .map((file) => file.path.replaceAll('\\', '/'))
    .toSet();
