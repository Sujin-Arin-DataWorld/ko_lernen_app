import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ko_lernen_app/l10n/generated/app_localizations.dart';
import 'package:ko_lernen_app/screens/gye_create_screen.dart';
import 'package:ko_lernen_app/screens/gye_join_screen.dart';
import 'package:ko_lernen_app/services/account/cloud_write_session.dart';
import 'package:ko_lernen_app/theme.dart';
import 'package:ko_lernen_app/widgets/sori/button.dart';

void main() {
  testWidgets('create and join writes fail closed until session is ready', (
    tester,
  ) async {
    final sessions = ValueNotifier<CloudWriteSession?>(null);
    addTearDown(sessions.dispose);

    for (final screen in <Widget>[
      GyeCreateScreen(accountSessions: sessions),
      GyeJoinScreen(accountSessions: sessions),
    ]) {
      await tester.pumpWidget(_wrap(screen));
      await tester.pump();
      expect(_primaryAction(tester).onTap, isNull);

      sessions.value = const CloudWriteSession(
        uid: 'source',
        epoch: 2,
        mode: CloudWriteMode.reconciling,
      );
      await tester.pump();
      expect(_primaryAction(tester).onTap, isNull);

      sessions.value = const CloudWriteSession(
        uid: 'source',
        epoch: 2,
        mode: CloudWriteMode.ready,
      );
      await tester.pump();
      expect(_primaryAction(tester).onTap, isNotNull);
      sessions.value = null;
    }
  });
}

SoriButton _primaryAction(WidgetTester tester) =>
    tester.widget<SoriButton>(find.byType(SoriButton).first);

Widget _wrap(Widget child) {
  return MaterialApp(
    theme: AppTheme.light,
    locale: const Locale('de'),
    supportedLocales: AppL10n.supportedLocales,
    localizationsDelegates: AppL10n.localizationsDelegates,
    home: child,
  );
}
