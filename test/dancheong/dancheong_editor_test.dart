import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ko_lernen_app/features/dancheong/dancheong_screens.dart';
import 'package:ko_lernen_app/features/dancheong/dancheong_store.dart';
import 'package:ko_lernen_app/l10n/generated/app_localizations.dart';
import 'package:ko_lernen_app/services/account/cloud_write_session.dart';
import '../support/real_fonts.dart';

void main() {
  setUpAll(loadSoriRealFonts);
  for (final locale in ['de', 'en']) {
    testWidgets(
      '360px $locale 200% text keeps typed Hangul and blocks empty finish',
      (tester) async {
        tester.view.physicalSize = const Size(360, 800);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        var raw = '';
        final store = DancheongStore(
          readRaw: () => raw,
          writeRaw: (value, guard) async {
            guard();
            raw = value;
          },
          sessions: CloudWriteSessionController()..acquire('editor-owner'),
        );
        await tester.pumpWidget(
          MaterialApp(
            locale: Locale(locale),
            localizationsDelegates: AppL10n.localizationsDelegates,
            supportedLocales: AppL10n.supportedLocales,
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context).copyWith(
                textScaler: const TextScaler.linear(2),
                disableAnimations: true,
              ),
              child: child!,
            ),
            home: DancheongEditorScreen(
              arguments: const DancheongEditorArgs(),
              store: store,
              owned: () => {},
            ),
          ),
        );
        await tester.pump();
        await tester.scrollUntilVisible(
          find.byKey(const ValueKey('dancheong-korean-text')),
          300,
        );
        await tester.enterText(
          find.byKey(const ValueKey('dancheong-korean-text')),
          '안녕, Jürgen',
        );
        await tester.pump(const Duration(milliseconds: 450));
        await tester.pump();
        for (
          var attempt = 0;
          attempt < 10 && store.currentOwner().drafts.isEmpty;
          attempt++
        ) {
          await tester.pump(const Duration(milliseconds: 50));
        }
        expect(tester.takeException(), isNull);
        expect(
          store.currentOwner().drafts.single.composition.koreanText,
          '안녕, Jürgen',
        );
        await tester.pumpWidget(const SizedBox());
      },
    );
  }
}
