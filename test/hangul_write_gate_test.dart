/// Schreiben 탭 판정·게이트 회귀 — 테스터(Amor, 2026-08-17) 보고 2건.
///
///   ① "일부러 획순을 틀려도 인식하지 못하고 그냥 진행된다"
///   ② "성공 오디오 피드백도 일관되지 않다"
///
/// ②의 정체는 Löschen 이 캔버스만 지우고 획 카운터를 남긴 것이었다 — 한 번
/// 지우면 그 글자는 두 번 다시 판정되지 않아 성공음이 영영 안 났다.
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ko_lernen_app/data/hangul_data.dart' as hangul;
import 'package:ko_lernen_app/data/hangul_strokes.dart';
import 'package:ko_lernen_app/l10n/generated/app_localizations.dart';
import 'package:ko_lernen_app/screens/hangul_screen.dart';
import 'package:ko_lernen_app/services/storage_service.dart';
import 'package:ko_lernen_app/theme.dart';
import 'package:ko_lernen_app/widgets/sori/button.dart';
import 'package:ko_lernen_app/widgets/sori/chip.dart';
import 'package:ko_lernen_app/widgets/stroke_canvas.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({
      'kl_tut_hangul': true,
      'kl_tut_hangulWriteRules': true,
    });
    Storage.resetForTesting();
    await Storage.init();
  });

  testWidgets('틀린 획순은 즉시 잡히고, 몇 번 획인지 알려주고, 진행을 막는다', (
    tester,
  ) async {
    await _openWriteTab(tester);
    await _goToLetter(tester, 'ㅂ');

    // ㅂ 의 4번 획(맨 아래 가로)을 1번 획 자리에 그린다.
    await _traceStroke(tester, 'ㅂ', 3);

    expect(_hint(tester), 'That is stroke 4. Draw stroke 1 first.');
    expect(_progress(tester), 'Stroke 1 / 4');
    // 틀린 획은 판정 대상에서 즉시 빠진다 → 다음 기대 획은 그대로 1번.
    expect(_finishFinder, findsNothing);

    await tester.pump(const Duration(milliseconds: 600));
  });

  testWidgets('맞는 획은 진행 카운터를 올리고, 마지막 획에서 글자가 완성된다', (
    tester,
  ) async {
    await _openWriteTab(tester);
    await _goToLetter(tester, 'ㅂ');

    await _traceStroke(tester, 'ㅂ', 0);
    expect(_progress(tester), 'Stroke 2 / 4');
    expect(_hint(tester), 'Now draw stroke 2.');

    await _traceStroke(tester, 'ㅂ', 1);
    await _traceStroke(tester, 'ㅂ', 2);
    expect(_progress(tester), 'Stroke 4 / 4');

    await _traceStroke(tester, 'ㅂ', 3);
    expect(_progress(tester), 'Stroke 4 / 4');
    expect(_hint(tester), 'ㅂ is done! On to the next one.');
    expect(_finishFinder, findsOneWidget);
    expect(_finishButton(tester).onTap, isNotNull);

    // 자동으로 다음 글자로 넘어간다.
    await tester.pump(const Duration(milliseconds: 700));
    expect(find.text('1 letter done'), findsOneWidget);
  });

  testWidgets('Löschen 뒤에 다시 맞게 그려도 성공 피드백이 난다', (tester) async {
    // ← 테스터가 본 "성공음이 일관되지 않다" 의 회귀 테스트.
    // 예전 코드는 Löschen 이 _currentLetterStrokeCount 를 안 건드려서,
    // 지운 뒤 카운터가 정답 획 수를 넘어가 판정 자체가 다시 돌지 않았다.
    await _openWriteTab(tester);
    await _goToLetter(tester, 'ㅂ');

    await _traceStroke(tester, 'ㅂ', 0);
    expect(_progress(tester), 'Stroke 2 / 4');

    await tester.tap(find.byKey(const Key('hangul-write-clear')));
    await tester.pump();
    expect(_progress(tester), 'Stroke 1 / 4');

    for (var i = 0; i < 4; i++) {
      await _traceStroke(tester, 'ㅂ', i);
    }
    expect(_hint(tester), 'ㅂ is done! On to the next one.');
    expect(_finishFinder, findsOneWidget);

    await tester.pump(const Duration(milliseconds: 700));
  });

  testWidgets('시범 캔버스가 지금 그려야 할 획을 짚어준다', (tester) async {
    await _openWriteTab(tester);
    await _goToLetter(tester, 'ㅂ');

    expect(tester.widget<StrokeCanvas>(_demoCanvas).highlightIndex, 0);
    await _traceStroke(tester, 'ㅂ', 0);
    expect(tester.widget<StrokeCanvas>(_demoCanvas).highlightIndex, 1);

    await tester.pump(const Duration(milliseconds: 600));
  });

  testWidgets('연습 모드에서는 틀려도 지우거나 막지 않는다 — 힌트만 준다', (
    tester,
  ) async {
    await _openWriteTab(tester);
    await _openWriteMenu(tester);
    await tester.tap(find.byKey(const Key('hangul-check-practice')));
    await tester.pump();
    await _goToLetter(tester, 'ㅂ');

    await _traceStroke(tester, 'ㅂ', 3);
    expect(_hint(tester), 'That is stroke 4. Draw stroke 1 first.');

    // 획이 남아 있으므로 나머지를 그으면 그대로 완성된다.
    for (var i = 0; i < 4; i++) {
      await _traceStroke(tester, 'ㅂ', i);
    }
    expect(_finishFinder, findsOneWidget);
    await tester.pump(const Duration(milliseconds: 700));
  });

  testWidgets('연습/검사 선택은 저장된다', (tester) async {
    await _openWriteTab(tester);
    expect(Storage.hangulStrictStrokes, isTrue);

    await _openWriteMenu(tester);
    await tester.tap(find.byKey(const Key('hangul-check-practice')));
    await tester.pump();
    expect(Storage.hangulStrictStrokes, isFalse);

    await _openWriteMenu(tester);
    await tester.tap(find.byKey(const Key('hangul-check-strict')));
    await tester.pump();
    expect(Storage.hangulStrictStrokes, isTrue);
  });

  testWidgets('거꾸로 그으면 검사 모드에서만 방향을 지적한다', (tester) async {
    await _openWriteTab(tester);
    await _goToLetter(tester, 'ㅡ', vowels: true);

    await _traceStroke(tester, 'ㅡ', 0, reversed: true);
    expect(
      _hint(tester),
      'Right line, wrong direction. Stroke 1 goes the other way.',
    );

    await _openWriteMenu(tester);
    await tester.tap(find.byKey(const Key('hangul-check-practice')));
    await tester.pump();
    await _goToLetter(tester, 'ㅡ', vowels: true);
    await _traceStroke(tester, 'ㅡ', 0, reversed: true);
    expect(_hint(tester), 'ㅡ is done! On to the next one.');

    await tester.pump(const Duration(milliseconds: 700));
  });
}

// ─────────────────────────── 도우미 ───────────────────────────

final Finder _demoCanvas = find.byType(StrokeCanvas);

Future<void> _openWriteMenu(WidgetTester tester) async {
  await tester.tap(find.byKey(const Key('hangul-write-overflow')));
  await tester.pumpAndSettle();
}

Future<void> _openWriteTab(WidgetTester tester) async {
  tester.view.physicalSize = const Size(1200, 2600);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      locale: const Locale('en'),
      supportedLocales: AppL10n.supportedLocales,
      localizationsDelegates: AppL10n.localizationsDelegates,
      home: const HangulScreen(),
    ),
  );
  tester.widget<TabBar>(find.byType(TabBar)).controller!.index = 2;
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 500));
}

/// [letter] 까지 이동한다.
///
/// 2026-08-18: 예전엔 "Pronounce ㄱ" 버튼 라벨로 현재 글자를 찾았는데, 그
/// 버튼이 아이콘(툴팁)으로 줄면서 화면에 글자 텍스트가 없어졌다. 데이터에서
/// 인덱스를 계산해 그만큼 넘기고, 카운터로 도착을 확인한다.
Future<void> _goToLetter(
  WidgetTester tester,
  String letter, {
  bool vowels = false,
}) async {
  if (vowels) {
    await _openWriteMenu(tester);
    await tester.tap(find.widgetWithText(SoriChip, 'Vowels'));
    await tester.pump();
  }
  final pool = vowels ? hangul.vowels : hangul.consonants;
  final target = pool.indexWhere((c) => c.letter == letter);
  expect(target, isNonNegative, reason: '$letter 가 풀에 없다');
  // 지금 어디인지 카운터에서 읽어 **상대 이동**한다 — 한 테스트에서 두 번
  // 불러도 안전해야 한다.
  final current = _currentIndex(tester, pool.length);
  final steps = (target - current + pool.length) % pool.length;
  for (var i = 0; i < steps; i++) {
    await tester.tap(find.byKey(const Key('hangul-write-next')));
    await tester.pump();
  }
  expect(find.text('${target + 1} / ${pool.length}'), findsOneWidget);
}

/// 카운터 'n / m' 에서 0-based 현재 인덱스.
int _currentIndex(WidgetTester tester, int poolLength) {
  final finder = find.textContaining(' / $poolLength');
  expect(finder, findsWidgets, reason: '진행 카운터를 찾지 못했다');
  final label = tester.widgetList<Text>(finder).first.data!;
  return int.parse(label.split(' / ').first.trim()) - 1;
}

/// Finish 는 글자를 하나라도 정확히 완성하기 전엔 **아예 없다**(비활성이
/// 아니라 미렌더). 죽은 공간을 없애 캔버스에 세로 공간을 넘긴 결과다.
final Finder _finishFinder = find.byKey(const Key('hangul-writing-finish'));

SoriButton _finishButton(WidgetTester tester) => tester.widget<SoriButton>(
  find.byKey(const Key('hangul-writing-finish')),
);

String _hint(WidgetTester tester) =>
    tester.widget<Text>(find.byKey(const Key('hangul-stroke-hint'))).data!;

String _progress(WidgetTester tester) => tester
    .widget<SoriChip>(find.byKey(const Key('hangul-stroke-progress')))
    .label;

/// [letter] 의 [index] 번 기준 획을 실제 좌표로 따라 그린다.
Future<void> _traceStroke(
  WidgetTester tester,
  String letter,
  int index, {
  bool reversed = false,
}) async {
  final canvas = find.byKey(const Key('hangul-practice-canvas'));
  await tester.ensureVisible(canvas);
  await tester.pump();
  final bounds = tester.getRect(canvas);
  final scaleX = bounds.width / strokeCanvas.width;
  final scaleY = bounds.height / strokeCanvas.height;
  Offset at(Offset p) =>
      Offset(bounds.left + p.dx * scaleX, bounds.top + p.dy * scaleY);

  final stroke = hangulStrokes[letter]![index];
  var points = switch (stroke) {
    LineStroke(:final points) => points,
    CircleStroke(:final center, :final radius) => [
      for (var i = 0; i <= 24; i++)
        Offset(
          center.dx + radius * math.cos(i / 24 * 2 * math.pi),
          center.dy + radius * math.sin(i / 24 * 2 * math.pi),
        ),
    ],
  };
  if (reversed) {
    points = points.reversed.toList();
  }

  final gesture = await tester.startGesture(at(points.first));
  for (final p in points.skip(1)) {
    await gesture.moveTo(at(p));
  }
  await gesture.up();
  await tester.pump();
}
