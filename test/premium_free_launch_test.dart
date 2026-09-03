import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ko_lernen_app/l10n/generated/app_localizations.dart';
import 'package:ko_lernen_app/screens/paywall_screen.dart';
import 'package:ko_lernen_app/services/premium_service.dart';
import 'package:ko_lernen_app/services/storage_service.dart';
import 'package:ko_lernen_app/theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() async {
    SharedPreferences.setMockInitialValues({'kl_premium_cached': true});
    await Storage.init();
  });

  test(
    'legacy cached premium never confers membership or paid-build access',
    () {
      expect(PremiumService.isPremium, isFalse);
      expect(PremiumService.hasContentAccess, PremiumService.fullAccessBuild);
      expect(PremiumService.purchasesEnabled, isFalse);
    },
  );

  testWidgets(
    'free release has open content but no purchase or restore CTA',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          locale: const Locale('en'),
          supportedLocales: AppL10n.supportedLocales,
          localizationsDelegates: AppL10n.localizationsDelegates,
          home: PaywallScreen(
            requiresSignIn: () => false,
            offeringLoader: () async => null,
          ),
        ),
      );
      await tester.pumpAndSettle();
      final t = AppL10n.of(tester.element(find.byType(PaywallScreen)));
      expect(find.text(t.paywallCtaStart), findsNothing);
      expect(find.text(t.paywallCtaRestore), findsNothing);
      expect(find.text(t.paywallFreeLaunch), findsOneWidget);
      expect(PremiumService.isPremium, isFalse);
      expect(PremiumService.hasContentAccess, isTrue);
    },
    skip: !PremiumService.freeLaunch,
  );
}
