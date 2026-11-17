import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ko_lernen_app/l10n/generated/app_localizations.dart';
import 'package:ko_lernen_app/widgets/sori/approved_chrome_assets.dart';
import 'package:ko_lernen_app/widgets/sori/approved_figma_scene.dart';
import 'package:ko_lernen_app/widgets/sori/c_gallery/c_objects.dart';
import 'package:ko_lernen_app/widgets/sori/tokens.dart';

import 'support/real_fonts.dart';

void main() {
  setUpAll(loadSoriRealFonts);

  test('Figma assets resolve locally and chrome uses the latest originals', () {
    final mapping =
        jsonDecode(
              File(
                '${ApprovedFigmaScene.root}figma-assets.json',
              ).readAsStringSync(),
            )
            as Map<String, dynamic>;
    for (final path in mapping.values.cast<String>()) {
      expect(File(path).existsSync(), isTrue, reason: path);
    }
    expect(mapping.values, contains(ApprovedChromeAssets.cloud));
    expect(mapping.values, contains(ApprovedChromeAssets.coinFront));
    expect(mapping.values, contains(ApprovedChromeAssets.settings));
    expect(CObjectArt.path(CObject.cloud), ApprovedChromeAssets.cloud);
    expect(CObjectArt.path(CObject.coin), ApprovedChromeAssets.coinFront);
    expect(CObjectArt.path(CObject.settings), ApprovedChromeAssets.settings);
    expect(CObjectArt.path(CObject.book), ApprovedChromeAssets.learn);
  });

  for (final language in ['de', 'en']) {
    for (final width in [320.0, 393.0]) {
      for (final scale in [1.0, 2.0]) {
        testWidgets(
          'C5 native text and action $language ${width}dp ${scale}x',
          (tester) async {
            tester.view.physicalSize = Size(width, 873);
            tester.view.devicePixelRatio = 1;
            addTearDown(tester.view.resetPhysicalSize);
            addTearDown(tester.view.resetDevicePixelRatio);
            final data = await tester.runAsync(
              () => ApprovedFigmaScene.load('spiele-65.json'),
            );
            await tester.runAsync(
              () => ApprovedFigmaScene.load('figma-assets.json'),
            );
            final labels = <String, String>{
              '65:420': language == 'en' ? 'Preview' : 'Vorschau',
              '65:421': language == 'en' ? 'Syllable puzzle' : 'Silben-Rätsel',
              '65:423': language == 'en' ? 'Start session' : 'Runde starten',
              '65:427': language == 'en' ? 'Daily challenge' : 'Tageschallenge',
              '65:430': language == 'en' ? 'First sounds' : 'Anlaut-Quiz',
              '65:433': language == 'en' ? 'Fill the gaps' : 'Lückentext',
              '65:436': language == 'en' ? 'Quick pairs' : 'Blitz-Paare',
              '65:439': language == 'en' ? 'Sentence arcade' : 'Satz-Arcade',
              '65:442': 'Kkeunmari',
              '65:445': language == 'en' ? 'Your own words' : 'Eigene Wörter',
            };
            var starts = 0;
            await tester.pumpWidget(
              MaterialApp(
                locale: Locale(language),
                supportedLocales: AppL10n.supportedLocales,
                localizationsDelegates: AppL10n.localizationsDelegates,
                builder: (context, child) => MediaQuery(
                  data: MediaQuery.of(context).copyWith(
                    textScaler: TextScaler.linear(scale),
                    disableAnimations: true,
                  ),
                  child: child!,
                ),
                home: Scaffold(
                  body: SingleChildScrollView(
                    child: ApprovedFigmaScene(
                      scene: 'spiele-65.json',
                      top: 110,
                      bottom: 898.838,
                      text: labels,
                      actions: [
                        FigmaSceneAction(
                          const Rect.fromLTWH(16.986, 435.972, 368.028, 59.451),
                          labels['65:423']!,
                          () => starts++,
                          key: const ValueKey('native-start'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
            expect(data, isNotNull);
            await tester.pumpAndSettle();
            for (final text in tester.widgetList<Text>(find.byType(Text))) {
              expect(text.style?.fontSize, greaterThanOrEqualTo(16));
              expect([
                SoriLocaleFonts.forLocale(Locale(language)).heading,
                SoriLocaleFonts.forLocale(Locale(language)).body,
              ], contains(text.style?.fontFamily));
            }
            final start = find.byKey(const ValueKey('native-start'));
            await tester.ensureVisible(start);
            await tester.pumpAndSettle();
            expect(tester.getSize(start).height, greaterThanOrEqualTo(48));
            expect(tester.getSize(start).width, greaterThanOrEqualTo(48));
            await tester.tap(start);
            await tester.pump();
            expect(starts, 1);
            expect(tester.takeException(), isNull);
            await tester.pumpWidget(const SizedBox.shrink());
            await tester.pumpAndSettle();
          },
        );
      }
    }
  }
}
