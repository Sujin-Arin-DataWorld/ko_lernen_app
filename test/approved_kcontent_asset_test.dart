import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ko_lernen_app/l10n/generated/app_localizations.dart';
import 'package:ko_lernen_app/screens/onboarding_v2/c_intro_art.dart';
import 'package:ko_lernen_app/screens/onboarding_v2/onboarding_setup_screen.dart';
import 'package:ko_lernen_app/screens/onboarding_v2/onboarding_v2_copy.dart';
import 'package:ko_lernen_app/screens/onboarding_v2/onboarding_v2_presentation.dart';

import 'support/einleitung_capture_assets.dart';
import 'support/real_fonts.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    await loadSoriRealFonts();
    await loadEinleitungFonts();
  });

  test('K-content bundles the exact latest user JPEG and source provenance', () {
    final data = File(CIntroArt.kContentAsset).readAsBytesSync();
    const expected =
        'ff2b2d617a3e582208fd3cd97b8c6a5f8ef735c9082424709d9e8b1d82f5cbe6';
    expect(sha256.convert(data).toString(), expected);
    expect(data.length, 2695887);
    expect(data.take(3), [0xff, 0xd8, 0xff]);
    final manifest =
        jsonDecode(
              File('tool/einleitung_generated_assets.json').readAsStringSync(),
            )
            as Map<String, dynamic>;
    final record = (manifest['files'] as List<dynamic>)
        .cast<Map<String, dynamic>>()
        .singleWhere((item) => item['asset'] == CIntroArt.kContentAsset);
    expect(record['sha256'], expected);
    expect(record['sourceSha256'], expected);
    expect(
      record['source'],
      r'C:\Users\vjinn\ELibrary\Downloads\Gemini_Generated_Image_js0ec6js0ec6js0e.jpg',
    );
    expect(record['byteIdentical'], isTrue);
    expect(record['canvasPx'], [2400, 1792]);
  });

  for (final configuration in [
    (language: 'de', size: const Size(402, 934), scale: 1.0),
    (language: 'de', size: const Size(320, 740), scale: 2.0),
    (language: 'en', size: const Size(402, 874), scale: 1.0),
  ]) {
    testWidgets(
      'K-content purpose uses the approved original and preserves selection '
      '${configuration.language} ${configuration.size.width} ${configuration.scale}',
      (tester) async {
        tester.view.physicalSize = configuration.size;
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        String? selected;
        final copy = onboardingV2Copy(
          lookupAppL10n(Locale(configuration.language)),
        );
        await tester.pumpWidget(
          MaterialApp(
            locale: Locale(configuration.language),
            supportedLocales: AppL10n.supportedLocales,
            localizationsDelegates: AppL10n.localizationsDelegates,
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context).copyWith(
                disableAnimations: true,
                textScaler: TextScaler.linear(configuration.scale),
              ),
              child: child!,
            ),
            home: StatefulBuilder(
              builder: (context, setState) => OnboardingSetupScreen(
                copy: copy,
                selectedPurposeId: selected,
                selectedLevelCode: 'A2',
                onPurposeChanged: (id) => setState(() => selected = id),
                onLevelChanged: (_) {},
                onContinue: (_) {},
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        await settleEinleitungCaptureAssets(tester);
        final purpose = find.byKey(
          const ValueKey(
            'onboarding-purpose-${OnboardingV2Ids.purposeKContent}',
          ),
        );
        final art = find.descendant(
          of: purpose,
          matching: find.byWidgetPredicate(
            (widget) =>
                widget is CIntroArt && widget.name == 'interest-kcontent',
          ),
        );
        expect(art, findsOneWidget);
        final image = tester.widget<Image>(
          find.descendant(of: art, matching: find.byType(Image)),
        );
        expect((image.image as AssetImage).assetName, CIntroArt.kContentAsset);
        await tester.ensureVisible(purpose);
        await tester.pumpAndSettle();
        await tester.tap(purpose);
        await tester.pumpAndSettle();
        expect(selected, OnboardingV2Ids.purposeKContent);
        expect(tester.takeException(), isNull);
      },
    );
  }
}
