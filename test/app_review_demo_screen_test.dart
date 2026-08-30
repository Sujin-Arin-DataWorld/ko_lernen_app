import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ko_lernen_app/l10n/generated/app_localizations.dart';
import 'package:ko_lernen_app/screens/app_review_demo_screen.dart';
import 'package:ko_lernen_app/screens/consent_screen.dart';
import 'package:ko_lernen_app/screens/sori_stage/sori_stage_preview_screens.dart';
import 'package:ko_lernen_app/services/storage_service.dart';
import 'package:ko_lernen_app/theme.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    Storage.resetForTesting();
    SharedPreferences.setMockInitialValues({
      'review_demo_sentinel': 'unchanged',
      'kl_consent_accepted': false,
      'kl_user_level': 'b2',
      'kl_xp': 321,
    });
    await Storage.init();
  });

  testWidgets(
    'fresh learner can inspect the read-only demo without granting consent',
    (tester) async {
      final before = await _preferencesSnapshot();
      await tester.pumpWidget(_host(const ConsentScreen()));

      await tester.ensureVisible(find.text('View demo'));
      await tester.tap(find.text('View demo'));
      await tester.pumpAndSettle();

      expect(find.byType(AppReviewDemoScreen), findsOneWidget);
      expect(find.text('Explore Hangul Sori'), findsOneWidget);
      expect(Storage.consentAccepted, isFalse);
      expect(await _preferencesSnapshot(), equals(before));

      await tester.tap(find.byKey(const ValueKey('app-review-demo-panel-02A')));
      await tester.pumpAndSettle();

      expect(find.byType(SoriStageTodayPreviewScreen), findsOneWidget);
      expect(await _preferencesSnapshot(), equals(before));

      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.text('Explore Hangul Sori'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('app-review-demo-close')));
      await tester.pumpAndSettle();

      expect(find.byType(AppReviewDemoScreen), findsNothing);
      expect(find.byType(ConsentScreen), findsOneWidget);
      expect(Storage.consentAccepted, isFalse);
      expect(await _preferencesSnapshot(), equals(before));
    },
  );

  testWidgets('UX fixture consent does not recursively expose the demo', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(ConsentScreen.preview(onPreviewAccepted: () {})),
    );

    expect(find.text('View demo'), findsNothing);
    expect(find.text('Continue'), findsOneWidget);
  });
}

Widget _host(Widget child) => MaterialApp(
  debugShowCheckedModeBanner: false,
  theme: AppTheme.light,
  locale: const Locale('en'),
  supportedLocales: AppL10n.supportedLocales,
  localizationsDelegates: AppL10n.localizationsDelegates,
  home: MediaQuery(
    data: const MediaQueryData(disableAnimations: true),
    child: child,
  ),
);

Future<Map<String, Object?>> _preferencesSnapshot() async {
  final preferences = await SharedPreferences.getInstance();
  return {for (final key in preferences.getKeys()) key: preferences.get(key)};
}
