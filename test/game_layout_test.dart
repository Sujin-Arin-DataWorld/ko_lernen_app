import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
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
void main() {
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

Widget _host(Widget child, Size size) => MaterialApp(
  debugShowCheckedModeBanner: false,
  theme: AppTheme.light,
  locale: const Locale('de'),
  supportedLocales: AppL10n.supportedLocales,
  localizationsDelegates: AppL10n.localizationsDelegates,
  home: MediaQuery(
    data: MediaQueryData(disableAnimations: true, size: size),
    child: child,
  ),
);

Future<void> _pumpSpeedMatch(WidgetTester tester, {required Size size}) async {
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
        items: [
          v('코', 'Nase'),
          v('몸', 'Körper'),
          v('덜', 'weniger'),
          v('있다', 'sein'),
          v('물', 'Wasser'),
          v('불', 'Feuer'),
        ],
      ),
      size,
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
