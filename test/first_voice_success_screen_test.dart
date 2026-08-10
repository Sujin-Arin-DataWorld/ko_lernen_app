import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ko_lernen_app/l10n/generated/app_localizations.dart';
import 'package:ko_lernen_app/screens/first_voice_success_screen.dart';
import 'package:ko_lernen_app/services/storage_service.dart';
import 'package:ko_lernen_app/theme.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await Storage.init();
  });

  testWidgets('01C shows the persisted ability and can continue solo', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(400, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        locale: const Locale('de'),
        supportedLocales: AppL10n.supportedLocales,
        localizationsDelegates: AppL10n.localizationsDelegates,
        home: const FirstVoiceSuccessScreen(
          canDo: 'Ich kann jemanden begrüßen.',
        ),
      ),
    );
    await tester.pump();

    expect(
      find.text('Du hast dein erstes Koreanisch verstanden.'),
      findsOneWidget,
    );
    expect(find.text('Ich kann jemanden begrüßen.'), findsOneWidget);
    expect(find.text('Ohne Begleitung zu Heute'), findsOneWidget);

    await tester.tap(find.text('Ohne Begleitung zu Heute'));
    await tester.pump(const Duration(milliseconds: 350));

    expect(Storage.introPreviewSeen, isTrue);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(seconds: 1));
  });
}
