import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ko_lernen_app/l10n/generated/app_localizations.dart';
import 'package:ko_lernen_app/models/silben_puzzle.dart';
import 'package:ko_lernen_app/screens/grammar_screen.dart';
import 'package:ko_lernen_app/screens/silben_kreuz_screen.dart';
import 'package:ko_lernen_app/services/data_loader.dart';
import 'package:ko_lernen_app/services/storage_service.dart';
import 'package:ko_lernen_app/theme.dart';

import 'support/sori_speech_stubs.dart';

/// 스윕 sub-48dp 회귀 가드.
///
/// 접근성 최소 터치 영역(48×48)에 못 미치던 두 지점을 고정한다:
/// (a) 문법 화면의 되돌리기 아이콘(예전 44×44),
/// (b) silben_kreuz 격자 셀(하한 없이 좁은 화면에서 48 아래로 내려갔다).
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    Storage.resetForTesting();
    SharedPreferences.setMockInitialValues({});
    await Storage.init();
    await Storage.setTutSeen('grammar');
    await Storage.setTutSeen('soriDeck');
    DataLoader.reset();
    await DataLoader.loadGrammar();
    stubSoriSpeech();
  });

  testWidgets('문법 화면 되돌리기 아이콘의 터치 영역은 48×48 이상이다', (tester) async {
    await tester.pumpWidget(_wrap(const GrammarScreen()));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    if (find
        .byKey(const Key('grammar-plan-onboarding-sheet'))
        .evaluate()
        .isNotEmpty) {
      await tester.tapAt(const Offset(8, 8));
      await tester.pump(const Duration(milliseconds: 300));
    }

    final undoButton = find.byKey(const Key('grammar-undo'));
    expect(undoButton, findsOneWidget);

    // IconButton 을 감싼 SizedBox 가 실제 터치 영역을 정한다.
    final sizedBox = find.ancestor(
      of: undoButton,
      matching: find.byType(SizedBox),
    );
    final size = tester.getSize(sizedBox.first);
    expect(size.width, greaterThanOrEqualTo(48));
    expect(size.height, greaterThanOrEqualTo(48));
  });

  testWidgets('silben_kreuz 격자 셀은 360×640 뷰포트에서도 48 이상이다', (tester) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        locale: const Locale('en'),
        localizationsDelegates: AppL10n.localizationsDelegates,
        supportedLocales: AppL10n.supportedLocales,
        home: SilbenKreuzScreen(
          puzzleLoader: () async => const {
            'A1': [_wideCrossPuzzle],
          },
        ),
      ),
    );
    for (var i = 0; i < 20; i++) {
      await tester.pump(const Duration(milliseconds: 50));
      if (find
          .byKey(const ValueKey('silben-cell-surface-0-0'))
          .evaluate()
          .isNotEmpty) {
        break;
      }
    }
    expect(find.byKey(const ValueKey('silben-cell-surface-0-0')), findsOneWidget);

    final cellSizes = <Size>[];
    for (var c = 0; c < _wideCrossPuzzle.cols; c++) {
      final finder = find.byKey(ValueKey('silben-cell-surface-0-$c'));
      expect(finder, findsOneWidget);
      cellSizes.add(tester.getSize(finder));
    }

    final minCellSide = cellSizes
        .map((s) => math.min(s.width, s.height))
        .reduce(math.min);
    expect(minCellSide, greaterThanOrEqualTo(48));
  });
}

const _wideAcross = SilbenWord(
  dir: 'h',
  row: 0,
  col: 0,
  answer: '가나다라마바',
  german: 'wide across',
  exampleKo: '◯◯◯◯◯◯를 읽어요.',
  exampleDe: 'Read the wide across word.',
);

// cols=6 이어야 328dp 안쪽 폭(360dp 뷰포트 - 좌우 16 패딩)에서 gap=10 기준
// 셀이 48 아래로 내려간다 — 하한 로직이 없으면 이 테스트가 RED 다.
const _wideCrossPuzzle = SilbenPuzzle(
  id: 'wide-cross-48dp',
  rows: 1,
  cols: 6,
  words: [_wideAcross],
  pool: ['가', '나', '다', '라', '마', '바'],
);

Widget _wrap(Widget child) => MaterialApp(
  debugShowCheckedModeBanner: false,
  theme: AppTheme.light,
  locale: const Locale('de'),
  supportedLocales: AppL10n.supportedLocales,
  localizationsDelegates: AppL10n.localizationsDelegates,
  builder: (context, child) {
    final media = MediaQuery.of(context);
    return MediaQuery(
      data: media.copyWith(disableAnimations: true),
      child: child!,
    );
  },
  home: child,
);
