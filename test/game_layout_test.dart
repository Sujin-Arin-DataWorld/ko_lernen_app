import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart' show FontLoader;
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ko_lernen_app/l10n/generated/app_localizations.dart';
import 'package:ko_lernen_app/models/vocab.dart';
import 'package:ko_lernen_app/screens/cloze_game_screen.dart';
import 'package:ko_lernen_app/screens/speed_match_screen.dart';
import 'package:ko_lernen_app/services/cloze_loader.dart';
import 'package:ko_lernen_app/services/storage_service.dart';
import 'package:ko_lernen_app/theme.dart';
import 'package:ko_lernen_app/widgets/sori/cloze_prompt.dart';
import 'package:ko_lernen_app/widgets/sori/game_layout.dart';
import 'package:ko_lernen_app/widgets/sori/quiz_choice.dart';

/// 2026-08-07 Jin 실기기(태블릿+폰): "단어카드들이 너무 작아", "빈칸에 뭘
/// 골라야 하는지 표시가 안 돼", "까치를 파란 원에 가두지 말아줘".
///
/// 실측이 먼저였다 — 게임 화면들이 폭만 클램프하고 **세로는 상단 고정**이라
/// 800×1280 에서 Blitz-Paare 는 화면의 63%, Satz bauen 은 57% 가 빈 공간이었고,
/// 보기 버튼은 폰·태블릿 모두 42~53dp 로 **완전히 동일**했다. `SoriStudyScale`
/// 이 붙어 있어도 그건 본문 글씨만 키우고 버튼 높이엔 안 걸린다.
/// 앱이 실제로 쓰는 Paperlogy 를 로드한다.
///
/// ⛔ 이게 없으면 `flutter test` 는 **모든 글자를 같은 폭의 사각형으로 그리는
/// 테스트 폰트**를 쓴다. 글자 폭 기반 판정(`didExceedMaxLines`)이 실기기와
/// 완전히 달라져서, 실제로는 3줄에 여유롭게 들어가는 독일어가 테스트에서만
/// 잘린 것으로 나온다(2026-08-12: `Freut mich, Sie kennenzulernen` 이 130%
/// 배율에서 테스트 폰트로 4/4 잘림 → Pretendard 로 0/4). 글자가 칸에 맞는지
/// 보는 테스트를 가짜 폰트로 돌리면 아무것도 검증하지 못한다.
Future<void> _loadRealFonts() async {
  final loader = FontLoader('Paperlogy');
  for (final path in const [
    'assets/fonts/Paperlogy/Paperlogy-Regular.ttf',
    'assets/fonts/Paperlogy/Paperlogy-Medium.ttf',
    'assets/fonts/Paperlogy/Paperlogy-SemiBold.ttf',
    'assets/fonts/Paperlogy/Paperlogy-Bold.ttf',
  ]) {
    final bytes = File(path).readAsBytesSync();
    loader.addFont(Future.value(ByteData.view(bytes.buffer)));
  }
  await loader.load();
}

void main() {
  setUpAll(_loadRealFonts);

  setUp(() async {
    Storage.resetForTesting();
    SharedPreferences.setMockInitialValues({'kl_user_level': 'a1'});
    await Storage.init();
  });

  group('soriFairTileHeight — 남는 세로만 나눠 갖는다', () {
    test('공간이 빠듯하면 최소값을 지킨다 (폰에서 기존 크기 보존)', () {
      // 5장이 300dp 를 나누면 장당 52 미만 → 최소값으로 떨어진다.
      expect(soriFairTileHeight(available: 300, count: 5), 52);
      expect(soriFairTileHeight(available: 100, count: 5), 52);
    });

    test('남으면 실제로 커진다', () {
      // 균등 배분값이 상한(140) 아래인 구간에서 실제 배분값이 나온다.
      final h = soriFairTileHeight(available: 600, count: 5, gap: 8);
      expect(h, greaterThan(52));
      expect(h, closeTo((600 - 8 * 5) / 5, 0.01));
    });

    test('상한이 있어 카드 3장짜리 라운드에서 한 장이 화면을 먹지 않는다', () {
      expect(soriFairTileHeight(available: 1200, count: 3), 140);
    });

    test('퇴화 입력에도 안전하다', () {
      expect(soriFairTileHeight(available: 0, count: 0), 52);
      expect(soriFairTileHeight(available: double.infinity, count: 5), 52);
    });
  });

  group('soriSpeedMatchSlotCount', () {
    test('regular viewport keeps five pairs', () {
      expect(
        soriSpeedMatchSlotCount(viewportHeight: 800, textScaleFactor: 1),
        5,
      );
    });

    test('short viewport or 130 percent text uses four pairs', () {
      expect(
        soriSpeedMatchSlotCount(viewportHeight: 640, textScaleFactor: 1),
        4,
      );
      expect(
        soriSpeedMatchSlotCount(viewportHeight: 800, textScaleFactor: 1.3),
        4,
      );
    });
  });

  group('splitClozeSlot — 빈칸 갈아 끼우기', () {
    test('빈칸을 고른 단어로 바꾼다', () {
      final r = splitClozeSlot('＿＿＿ 더워요.', filled: '너무');
      expect(r.before, '');
      expect(r.slot, '너무');
      expect(r.after, ' 더워요.');
    });

    test('안 골랐으면 빈칸 표시가 그대로 남는다', () {
      final r = splitClozeSlot('＿＿＿ 더워요.');
      expect(r.slot, '＿＿＿');
    });

    test('문장 가운데 빈칸도 앞뒤가 보존된다', () {
      final r = splitClozeSlot('오늘 ＿＿ 좋아요', filled: '날씨가');
      expect(r.before, '오늘 ');
      expect(r.slot, '날씨가');
      expect(r.after, ' 좋아요');
    });

    test('빈칸 표시가 없으면 문장을 훼손하지 않는다', () {
      final r = splitClozeSlot('빈칸 없음', filled: '무시');
      expect(r.before, '빈칸 없음');
      expect(r.slot, '');
      expect(r.after, '');
    });
  });

  group('Blitz-Paare — 카드가 남는 세로를 나눠 갖는다', () {
    for (final size in <Size>[
      Size(360, 800),
      Size(800, 1280),
      Size(1280, 800),
    ]) {
      final label = '${size.width.toInt()}x${size.height.toInt()}';
      testWidgets('$label 카드가 52dp 고정을 넘어선다', (tester) async {
        await _pumpSpeedMatch(tester, size: size);
        final heights = _tapHeights(tester);
        expect(heights, isNotEmpty);
        // 변경 전에는 모든 화면에서 정확히 52dp 였다.
        expect(heights.first, greaterThan(52), reason: label);
      });
    }

    testWidgets('태블릿 세로가 폰보다 확실히 크다', (tester) async {
      await _pumpSpeedMatch(tester, size: const Size(360, 800));
      final phone = _tapHeights(tester).first;
      await _pumpSpeedMatch(tester, size: const Size(800, 1280));
      final tablet = _tapHeights(tester).first;
      expect(tablet, greaterThan(phone));
    });
  });

  group('Blitz-Paare — long German labels stay in one viewport', () {
    const longGerman = 'Freut mich, Sie kennenzulernen';
    const entries = <(String, String)>[
      ('처음 뵙겠습니다', longGerman),
      ('반갑습니다', longGerman),
      ('어서 오세요', longGerman),
      ('잘 부탁드립니다', longGerman),
      ('만나서 반가워요', longGerman),
    ];
    const scenarios = [
      (
        name: '360x640 uses four pairs',
        size: Size(360, 640),
        textScaler: TextScaler.noScaling,
        expectedPairs: 4,
      ),
      (
        name: '360x800 at 130 percent text uses four pairs',
        size: Size(360, 800),
        textScaler: TextScaler.linear(1.3),
        expectedPairs: 4,
      ),
      (
        name: '360x800 at regular text keeps five pairs',
        size: Size(360, 800),
        textScaler: TextScaler.noScaling,
        expectedPairs: 5,
      ),
    ];

    for (final scenario in scenarios) {
      testWidgets(scenario.name, (tester) async {
        await _pumpSpeedMatch(
          tester,
          size: scenario.size,
          textScaler: scenario.textScaler,
          entries: entries,
        );

        final visibleRightTiles = <Finder>[];
        for (final entry in entries) {
          final tile = find.byKey(ValueKey('speed-match-right-${entry.$1}'));
          if (tile.evaluate().isNotEmpty) {
            visibleRightTiles.add(tile);
          }
        }
        expect(visibleRightTiles, hasLength(scenario.expectedPairs));

        final scaffoldRect = tester.getRect(find.byType(Scaffold).first);
        final heights = <double>[];
        for (final tile in visibleRightTiles) {
          final rect = tester.getRect(tile);
          final hitTarget = find.descendant(
            of: tile,
            matching: find.byType(InkWell),
          );
          heights.add(rect.height);
          expect(hitTarget, findsOneWidget);
          expect(tester.getSize(hitTarget).height, greaterThanOrEqualTo(44));
          expect(rect.bottom, lessThanOrEqualTo(scaffoldRect.bottom + 0.01));
          expect(
            find.ancestor(
              of: tile,
              matching: find.byType(SingleChildScrollView),
            ),
            findsNothing,
          );
        }
        // 높이는 "같아야" 하지만 Set 동일성으로 보면 안 된다 — 배분 계산이
        // 부동소수점이라 118.39999999999998 과 118.40000000000003 이 서로 다른
        // 원소가 된다(차이 5e-14). 의미상 같은 높이이므로 허용오차로 본다.
        final spread =
            heights.reduce((a, b) => a > b ? a : b) -
            heights.reduce((a, b) => a < b ? a : b);
        expect(spread, lessThan(0.01), reason: '타일 높이가 서로 달라졌다: $heights');

        final labels = find.text(longGerman);
        expect(labels, findsNWidgets(scenario.expectedPairs));
        for (final element in labels.evaluate()) {
          final renderObject = element.renderObject;
          expect(renderObject, isA<RenderParagraph>());
          expect((renderObject! as RenderParagraph).didExceedMaxLines, isFalse);
          expect((element.widget as Text).maxLines, 3);
        }
        expect(tester.takeException(), isNull);
      });
    }
  });

  testWidgets(
    'Blitz-Paare pauses its countdown while the app is backgrounded',
    (tester) async {
      await _pumpSpeedMatch(tester, size: const Size(360, 800));

      expect(find.text('60s'), findsOneWidget);
      await tester.pump(const Duration(seconds: 2));
      expect(find.text('58s'), findsOneWidget);

      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      await tester.pump(const Duration(seconds: 5));
      expect(find.text('58s'), findsOneWidget);

      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pump(const Duration(seconds: 1));
      expect(find.text('57s'), findsOneWidget);
    },
  );

  group('Lückentext — 빈칸 표시·선택 반영·재시도', () {
    testWidgets('고르기 전에는 빈칸 표시가 문장에 남는다', (tester) async {
      await _pumpCloze(tester);
      expect(find.textContaining('＿'), findsWidgets);
    });

    testWidgets('오답을 고르면 그 단어가 문장에 들어가고, 정답은 아직 안 드러난다', (tester) async {
      await _pumpCloze(tester);
      await tester.tap(find.text('곧장').last);
      await tester.pump();

      // 고른 오답이 문장 빈칸에 들어갔다.
      final card = tester.widget<ClozePromptCard>(find.byType(ClozePromptCard));
      expect(card.picked, '곧장');
      expect(card.pickedWrong, isTrue);

      // 정답 보기는 초록으로 드러나지 않는다 — 드러나면 재시도가 무의미하다.
      final correct = tester.widget<QuizChoice>(
        find.widgetWithText(QuizChoice, '너무').last,
      );
      expect(correct.revealCorrect, isFalse);
      await _drainTimers(tester);
    });

    testWidgets('오답 뒤 빈칸이 되돌아오고 다시 고를 수 있다', (tester) async {
      await _pumpCloze(tester);
      await tester.tap(find.text('곧장').last);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 800));

      final card = tester.widget<ClozePromptCard>(find.byType(ClozePromptCard));
      expect(card.picked, isNull, reason: '빈칸이 되돌아와야 한다');

      // 같은 문제에 그대로 머물러 다시 고를 수 있다.
      await tester.tap(find.text('너무').last);
      await tester.pump();
      final after = tester.widget<ClozePromptCard>(
        find.byType(ClozePromptCard),
      );
      expect(after.picked, '너무');
      expect(after.pickedWrong, isFalse);
      await _drainTimers(tester);
    });

    testWidgets('정답이면 정답이 문장에 들어간 채 드러난다', (tester) async {
      await _pumpCloze(tester);
      await tester.tap(find.text('너무').last);
      await tester.pump();

      final card = tester.widget<ClozePromptCard>(find.byType(ClozePromptCard));
      expect(card.picked, '너무');
      expect(card.pickedWrong, isFalse);
      final correct = tester.widget<QuizChoice>(
        find.widgetWithText(QuizChoice, '너무').last,
      );
      expect(correct.revealCorrect, isTrue);
      await _drainTimers(tester);
    });

    testWidgets('오답 선택지는 색과 무관하게 의미 값으로도 드러난다', (tester) async {
      final semantics = tester.ensureSemantics();
      await _pumpCloze(tester);
      await tester.tap(find.bySemanticsLabel('곧장'));
      await tester.pump();

      expect(tester.getSemantics(find.bySemanticsLabel('곧장')).value, 'Falsch');
      await _drainTimers(tester);
      semantics.dispose();
    });
  });

  group('HanokHeader — 선언 비율이 에셋 실제 비율과 맞는가', () {
    // Wortkette 히어로가 1254×700(1.79) 인데 10/3(3.33) 프레임에 cover 로
    // 들어가 세로의 46% 가 잘려 나갔다("동영상이 잘려"). 프레임을 에셋에
    // 맞추면 에셋 재작업 없이 해결된다.
    test('kkeunmari_hero 는 잘리지 않는다', () {
      final r = _pngAspect('assets/illustrations/hanok/kkeunmari_hero.png');
      expect(r, closeTo(1254 / 700, 0.001));
    });
  });
}

/// 지연 타이머(오답 되돌리기 700ms · 정답 진행 1100ms)를 흘려보낸다.
///
/// ⚠️ teardown 이 아니라 **테스트 본문 끝**에서 불러야 한다 —
/// `_verifyInvariants`("Timer is still pending")가 addTearDown 보다 **먼저**
/// 돌기 때문에 teardown 에서 pump 하면 이미 늦는다.
Future<void> _drainTimers(WidgetTester tester) async {
  await tester.pump(const Duration(seconds: 3));
}

double _pngAspect(String path) {
  final bytes = File(path).readAsBytesSync();
  final d = ByteData.sublistView(Uint8List.fromList(bytes));
  return d.getUint32(16) / d.getUint32(20);
}

List<double> _tapHeights(WidgetTester tester) {
  final out = <double>[];
  for (final e in find.byType(InkWell).evaluate()) {
    final ro = e.renderObject;
    if (ro is! RenderBox || !ro.hasSize) continue;
    if (ro.size.height > 8 && ro.size.width > 40) out.add(ro.size.height);
  }
  out.sort();
  return out;
}

Widget _host(
  Widget child,
  Size size, {
  TextScaler textScaler = TextScaler.noScaling,
}) => MaterialApp(
  debugShowCheckedModeBanner: false,
  theme: AppTheme.light,
  locale: const Locale('de'),
  supportedLocales: AppL10n.supportedLocales,
  localizationsDelegates: AppL10n.localizationsDelegates,
  home: MediaQuery(
    data: MediaQueryData(
      disableAnimations: true,
      size: size,
      textScaler: textScaler,
    ),
    child: child,
  ),
);

Future<void> _pumpSpeedMatch(
  WidgetTester tester, {
  required Size size,
  TextScaler textScaler = TextScaler.noScaling,
  List<(String, String)>? entries,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  Vocab v(String k, String d) => Vocab(
    korean: k,
    romanization: k,
    german: d,
    level: 'a1',
    posDe: 'N',
    exampleKorean: k,
    exampleGerman: d,
    topic: 't',
  );

  await tester.pumpWidget(
    _host(
      SpeedMatchScreen(
        items:
            (entries ??
                    const [
                      ('코', 'Nase'),
                      ('몸', 'Körper'),
                      ('덜', 'weniger'),
                      ('있다', 'sein'),
                      ('물', 'Wasser'),
                      ('불', 'Feuer'),
                    ])
                .map((entry) => v(entry.$1, entry.$2))
                .toList(),
      ),
      size,
      textScaler: textScaler,
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
  addTearDown(() async {
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(seconds: 2));
  });
}

Future<void> _pumpCloze(
  WidgetTester tester, {
  Size size = const Size(800, 1280),
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  final items = List.generate(
    5,
    (_) => ClozeItem(
      level: 'a1',
      sentenceKo: '＿＿＿ 더워요.',
      answer: '너무',
      fullKo: '너무 더워요.',
      de: 'Es ist zu heiß.',
      en: 'It is too hot.',
      distractors: const ['곧장', '많이', '같이'],
    ),
  );

  await tester.pumpWidget(_host(ClozeGameScreen(items: items), size));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
  addTearDown(() async {
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(seconds: 2));
  });
}
