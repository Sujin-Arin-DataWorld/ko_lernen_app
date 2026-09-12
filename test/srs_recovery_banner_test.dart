import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_platform_interface.dart';
import 'package:ko_lernen_app/l10n/generated/app_localizations.dart';
import 'package:ko_lernen_app/services/storage_service.dart';
import 'package:ko_lernen_app/services/srs_commit_journal.dart';
import 'package:ko_lernen_app/theme.dart';
import 'package:ko_lernen_app/widgets/sori/srs_recovery_banner.dart';
import 'package:ko_lernen_app/widgets/sori/button.dart';
import 'support/reward_preferences_platform.dart';
import 'support/real_fonts.dart';
import 'srs_process_recovery_test.dart' show journal;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(loadSoriRealFonts);
  for (final language in ['en', 'de']) {
    for (final scale in [1.0, 2.0]) {
      testWidgets(
        '$language scale=$scale recovery has 48dp retry and preserves navigation',
        (tester) async {
          Storage.resetForTesting();
          SharedPreferences.setMockInitialValues({});
          final native = RewardPreferencesPlatform();
          final record = journal();
          native.values.addAll({
            SrsCommitJournal.key: record.encode(),
            record.historyKey: record.beforeHistory!,
          });
          native.rejectKey = 'kl_srs_v1';
          SharedPreferencesStorePlatform.instance = native;
          await Storage.init();
          var navigated = false;
          tester.view.physicalSize = const Size(320, 568);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          await tester.pumpWidget(
            MaterialApp(
              theme: AppTheme.light,
              locale: Locale(language),
              supportedLocales: AppL10n.supportedLocales,
              localizationsDelegates: AppL10n.localizationsDelegates,
              builder: (context, child) => MediaQuery(
                data: MediaQuery.of(
                  context,
                ).copyWith(textScaler: TextScaler.linear(scale)),
                child: SrsRecoveryBanner(child: child!),
              ),
              home: Scaffold(
                appBar: AppBar(
                  leading: IconButton(
                    key: const Key('underlying-back'),
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () => navigated = true,
                  ),
                ),
                body: const Center(child: Text('Settings')),
              ),
            ),
          );
          await tester.pump();
          final t = AppL10n.of(tester.element(find.byType(SrsRecoveryBanner)));
          expect(find.text(t.srsRecoveryPending), findsOneWidget);
          expect(
            find.byWidgetPredicate(
              (widget) =>
                  widget is Semantics && widget.properties.liveRegion == true,
            ),
            findsWidgets,
          );
          await tester.tap(find.byKey(const Key('underlying-back')));
          expect(navigated, isTrue);
          final retry = find.widgetWithText(SoriButton, t.srsRecoveryRetry);
          final hitSize = tester.getSize(retry);
          expect(hitSize.height, greaterThanOrEqualTo(48));
          expect(hitSize.width, greaterThanOrEqualTo(48));
          await tester.ensureVisible(find.text(t.srsRecoveryRetry));
          await tester.tap(find.text(t.srsRecoveryRetry));
          await tester.pump();
          expect(Storage.srsRecoveryPending, isTrue);
          native.rejectKey = null;
          await tester.ensureVisible(find.text(t.srsRecoveryRetry));
          await tester.tap(find.text(t.srsRecoveryRetry));
          await tester.pump();
          await tester.pump();
          expect(Storage.srsRecoveryPending, isFalse);
          expect(find.text(t.srsRecoveryPending), findsNothing);
          expect(tester.takeException(), isNull);
        },
      );
    }
  }

  testWidgets('timeout leaves native work serialized and retry UI usable', (
    tester,
  ) async {
    Storage.resetForTesting();
    SharedPreferences.setMockInitialValues({});
    final record = journal();
    final release = Completer<void>();
    final native = RewardPreferencesPlatform()
      ..rejectKey = 'kl_srs_v1'
      ..releaseWrite = release
      ..commitBeforeFailure = true;
    native.values.addAll({
      SrsCommitJournal.key: record.encode(),
      record.historyKey: record.beforeHistory!,
    });
    SharedPreferencesStorePlatform.instance = native;
    await Storage.init();
    var result = true;
    unawaited(Storage.retrySrsRecovery().then((value) => result = value));
    await tester.pump();
    await tester.pump(const Duration(seconds: 6));
    expect(result, isFalse);
    expect(Storage.srsRecoveryStatus.value, SrsRecoveryStatus.retryRequired);
    expect(Storage.srsRecoveryPending, isTrue);
    unawaited(Storage.retrySrsRecovery());
    await tester.pump();
    expect(native.writes['kl_srs_v1'], 1);
    release.complete();
    await tester.pump();
    expect(Storage.srsRecoveryPending, isFalse);
    expect(Storage.srsCard('original')!.reviewCount, 1);
  });
}
