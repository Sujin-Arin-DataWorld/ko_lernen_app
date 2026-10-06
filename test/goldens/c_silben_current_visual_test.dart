import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ko_lernen_app/l10n/generated/app_localizations.dart';
import 'package:ko_lernen_app/models/silben_puzzle.dart';
import 'package:ko_lernen_app/screens/silben_kreuz_screen.dart';
import 'package:ko_lernen_app/services/storage_service.dart';
import 'package:ko_lernen_app/theme.dart';

import '../support/c_fonts.dart';
import '../support/sori_speech_stubs.dart';
import '../support/sori_stage_pump.dart';

const _across = SilbenWord(
  dir: 'h',
  row: 1,
  col: 0,
  answer: '어제',
  german: 'gestern',
  exampleKo: '어제 친구를 만났어요.',
  exampleDe: 'Gestern habe ich einen Freund getroffen.',
  exampleEn: 'Yesterday I met a friend.',
);
const _down = SilbenWord(
  dir: 'v',
  row: 0,
  col: 1,
  answer: '어렵다',
  german: 'schwierig / schwer',
  exampleKo: '이 문제는 어려워요.',
  exampleDe: 'Diese Aufgabe ist schwierig.',
  exampleEn: 'This problem is difficult.',
);
const _third = SilbenWord(
  dir: 'h',
  row: 3,
  col: 0,
  answer: '다섯',
  german: 'fünf',
  exampleKo: '사과가 다섯 개 있어요.',
  exampleDe: 'Es gibt fünf Äpfel.',
  exampleEn: 'There are five apples.',
);
const _fixture = SilbenPuzzle(
  id: 'c-visual-fixture',
  rows: 4,
  cols: 3,
  words: [_across, _down, _third],
  pool: ['제', '렵', '자', '섯', '어', '겁', '든', '다'],
);

void main() {
  testWidgets('C Silben current Flutter 390x844', (tester) async {
    SharedPreferences.setMockInitialValues({'kl_tut_silben_kreuz': true});
    Storage.resetForTesting();
    await Storage.init();
    await loadCFonts();
    stubSoriSpeech();
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        locale: const Locale('de'),
        localizationsDelegates: AppL10n.localizationsDelegates,
        supportedLocales: AppL10n.supportedLocales,
        home: SilbenKreuzScreen(
          puzzleLoader: () async => {
            'A1': [_fixture],
          },
        ),
      ),
    );
    await pumpSoriStage(tester);
    final context = tester.element(find.byType(SilbenKreuzScreen));
    await tester.runAsync(() async {
      for (final asset in const [
        'assets/illustrations/tactile/dokkaebi/dokkaebi_ready.png',
        'assets/illustrations/concept_c/seal_v2.png',
        'assets/illustrations/concept_c/arrow_v2.png',
        'assets/illustrations/concept_c/cloud_v2.png',
      ]) {
        await precacheImage(AssetImage(asset), context);
      }
    });
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await expectLater(
      find.byType(SilbenKreuzScreen),
      matchesGoldenFile('baselines/c_silben_current_390.png'),
    );
  });
}
