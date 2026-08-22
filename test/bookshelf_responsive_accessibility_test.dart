import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ko_lernen_app/l10n/generated/app_localizations.dart';
import 'package:ko_lernen_app/screens/bookshelf_screen.dart';
import 'package:ko_lernen_app/services/storage_service.dart';
import 'package:ko_lernen_app/theme.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('long pack name and actions stay complete at 200 percent', (
    tester,
  ) async {
    const packName =
        'Sehr langes persönliches Wortpaket für Restaurant und Geschäftsreise';
    await tester.binding.setSurfaceSize(const Size(320, 640));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    Storage.resetForTesting();
    SharedPreferences.setMockInitialValues({
      'kl_tut_bookshelf': true,
      'kl_bookshelf_v1': '{}',
      'kl_custom_packs_v1': jsonEncode({
        'pack-long': {
          'name': packName,
          'sourcePageId': '',
          'words': <Object>[],
          'createdAt': '2026-08-20T00:00:00.000Z',
        },
      }),
    });
    await Storage.init();

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        locale: const Locale('de'),
        supportedLocales: AppL10n.supportedLocales,
        localizationsDelegates: AppL10n.localizationsDelegates,
        builder: (context, child) {
          final media = MediaQuery.of(context);
          return MediaQuery(
            data: media.copyWith(
              textScaler: const TextScaler.linear(2),
              disableAnimations: true,
              padding: const EdgeInsets.only(top: 44, bottom: 34),
              viewPadding: const EdgeInsets.only(top: 44, bottom: 34),
            ),
            child: child!,
          );
        },
        home: const BookshelfScreen(),
      ),
    );
    await tester.pump();

    final name = find.text(packName);
    await tester.scrollUntilVisible(
      name,
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pump();

    final nameText = tester.widget<Text>(name);
    final t = lookupAppL10n(const Locale('de'));
    expect(nameText.maxLines, isNull);
    expect(nameText.overflow, isNull);
    expect(find.byTooltip('${t.wbEditTooltip}: $packName'), findsOneWidget);
    expect(find.byTooltip('${t.shareTooltip}: $packName'), findsOneWidget);
    expect(find.byTooltip('${t.btnDelete}: $packName'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
