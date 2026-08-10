import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ko_lernen_app/main.dart';
import 'package:ko_lernen_app/screens/consent_screen.dart';
import 'package:ko_lernen_app/screens/onboarding_start_screen.dart';
import 'package:ko_lernen_app/services/data_migration_service.dart';
import 'package:ko_lernen_app/services/storage_service.dart';

void main() {
  setUp(() async {
    Storage.resetForTesting();
    DataMigrationService.resetForTesting();
    Storage.unlockLearningWrites();
  });

  testWidgets('fresh startup reaches consent before any onboarding choice', (
    tester,
  ) async {
    await _launch(tester, const {});

    expect(find.byType(ConsentScreen), findsOneWidget);
    expect(find.byType(OnboardingStartScreen), findsNothing);
  });

  testWidgets('consented learner without placement reaches one start choice', (
    tester,
  ) async {
    await _launch(tester, const {'kl_consent_accepted': true});

    expect(find.byType(OnboardingStartScreen), findsOneWidget);
    expect(find.byType(ConsentScreen), findsNothing);
  });
}

Future<void> _launch(
  WidgetTester tester,
  Map<String, Object> preferences,
) async {
  SharedPreferences.setMockInitialValues(preferences);
  await Storage.init();

  await tester.pumpWidget(const KoLernenApp());
  await tester.pump();
  await tester.pump(const Duration(seconds: 2));
  await tester.pump(const Duration(milliseconds: 400));
  await tester.pump(const Duration(milliseconds: 1200));
}
