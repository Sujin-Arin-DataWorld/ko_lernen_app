import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ko_lernen_app/l10n/generated/app_localizations.dart';
import 'package:ko_lernen_app/screens/vocab_pack_result_screen.dart';
import 'package:ko_lernen_app/services/storage_service.dart';
import 'package:ko_lernen_app/theme.dart';
import 'package:ko_lernen_app/widgets/sori/consent_invite_sheet.dart';

/// Vertrag für die nachgelagerte Analytics/Crash-Einladung: erscheint genau
/// einmal, nur für einwilligungsfähige Lernende, und Ablehnen lässt beide
/// Zwecke aus (DSGVO/TDDDG Opt-in). Die tatsächliche Firebase-Aktivierung des
/// "Ja"-Pfades ist in privacy_consent_service_test abgedeckt (mit Fake-Clients);
/// hier wird sie nicht getippt, da Firebase im Widget-Test nicht initialisiert
/// ist.
Future<void> _init(Map<String, Object> prefs) async {
  SharedPreferences.setMockInitialValues(prefs);
  await Storage.init();
  Storage.unlockLearningWrites();
}

Future<void> _pump(WidgetTester tester) async {
  await tester.pumpWidget(
    MaterialApp(
      localizationsDelegates: AppL10n.localizationsDelegates,
      supportedLocales: AppL10n.supportedLocales,
      locale: const Locale('de'),
      theme: AppTheme.light,
      home: const Scaffold(
        body: ConsentInviteTrigger(child: SizedBox.shrink()),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Finder get _yes => find.text('Alles erlauben');

Future<void> _pumpPackResult(
  WidgetTester tester, {
  required double bossAccuracy,
  required bool justCleared,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      localizationsDelegates: AppL10n.localizationsDelegates,
      supportedLocales: AppL10n.supportedLocales,
      locale: const Locale('de'),
      theme: AppTheme.light,
      home: VocabPackResultScreen(
        packId: 'a1_survival',
        bossAccuracy: bossAccuracy,
        bossCorrect: bossAccuracy >= 0.7 ? 3 : 1,
        bossTotal: 3,
        quizCorrect: 0,
        quizTotal: 0,
        justCleared: justCleared,
        nextUnlockedPackId: null,
      ),
    ),
  );
  await tester.pump();
}

void main() {
  setUp(() {
    Storage.resetForTesting();
    ConsentInviteSheet.resetForTesting();
  });

  testWidgets('erscheint einmal für einwilligungsfähige Lernende und markiert '
      'sofort als gefragt', (tester) async {
    await _init({
      'kl_consent_accepted': true,
      'kl_birth_year': DateTime.now().year - 25,
    });
    await _pump(tester);

    expect(_yes, findsOneWidget);
    // Beim Anzeigen markiert → ein Scrim-Wegtippen zählt als "Nicht jetzt".
    expect(Storage.consentInviteShown, isTrue);
  });

  testWidgets('erscheint nicht, bevor das Consent-Gate akzeptiert wurde', (
    tester,
  ) async {
    await _init(const {});
    await _pump(tester);

    expect(_yes, findsNothing);
  });

  testWidgets('erscheint nicht erneut, wenn schon einmal gefragt', (
    tester,
  ) async {
    await _init(const {
      'kl_consent_accepted': true,
      'kl_consent_invite_shown': true,
    });
    await _pump(tester);

    expect(_yes, findsNothing);
  });

  testWidgets('erscheint nicht, wenn bereits zugestimmt', (tester) async {
    await _init(const {
      'kl_consent_accepted': true,
      'kl_analytics_consent': true,
    });
    await _pump(tester);

    expect(_yes, findsNothing);
  });

  testWidgets('fragt selbst-angegebene Minderjährige nie (DSGVO Art. 8)', (
    tester,
  ) async {
    final minorYear = DateTime.now().year - 12;
    await _init({'kl_consent_accepted': true, 'kl_birth_year': minorYear});
    await _pump(tester);

    expect(_yes, findsNothing);
  });

  testWidgets(
    'fragt bei unbekanntem Alter nie und verbraucht die Einladung nicht',
    (tester) async {
      await _init(const {'kl_consent_accepted': true});
      await _pump(tester);

      expect(_yes, findsNothing);
      expect(Storage.consentInviteShown, isFalse);
    },
  );

  testWidgets(
    '"Nicht jetzt" lässt beide Zwecke aus, markiert aber als gefragt',
    (tester) async {
      await _init({
        'kl_consent_accepted': true,
        'kl_birth_year': DateTime.now().year - 25,
      });
      await _pump(tester);

      await tester.tap(find.text('Nur das Nötigste'));
      await tester.pumpAndSettle();

      expect(Storage.analyticsConsent, isFalse);
      expect(Storage.crashConsent, isFalse);
      expect(Storage.consentInviteShown, isTrue);
    },
  );

  testWidgets('V2 first successful vocab clear owns the delayed invitation', (
    tester,
  ) async {
    await _init({
      'kl_consent_accepted': true,
      'kl_birth_year': DateTime.now().year - 25,
    });

    await _pumpPackResult(tester, bossAccuracy: 1, justCleared: true);
    await tester.pumpAndSettle();

    expect(find.byType(ConsentInviteTrigger), findsOneWidget);
    expect(_yes, findsOneWidget);
  });

  testWidgets('failed and repeat vocab results never trigger the invitation', (
    tester,
  ) async {
    await _init({
      'kl_consent_accepted': true,
      'kl_birth_year': DateTime.now().year - 25,
    });

    await _pumpPackResult(tester, bossAccuracy: 0.4, justCleared: true);
    await tester.pumpAndSettle();
    expect(find.byType(ConsentInviteTrigger), findsNothing);
    expect(_yes, findsNothing);

    await _pumpPackResult(tester, bossAccuracy: 1, justCleared: false);
    await tester.pumpAndSettle();
    expect(find.byType(ConsentInviteTrigger), findsNothing);
    expect(_yes, findsNothing);
    expect(Storage.consentInviteShown, isFalse);
  });
}
