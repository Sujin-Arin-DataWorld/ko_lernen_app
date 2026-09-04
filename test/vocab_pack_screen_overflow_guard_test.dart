// Learn 카운터 행 + Quiz/Boss 헤더 행 — 좁은 화면(320-360dp) 오버플로 회귀 가드.
//
// 두 리뷰가 같은 결함 클래스를 같은 파일에서 지적했다:
//  - Learn 카운터 행(vocab_pack_screen.dart:957 부근) — Task 2 가 칩 라벨을
//    최대 ~20자("20 / 20 · +11 Wdh.")로 늘렸는데 Row 에 Flexible/Expanded 가
//    없어 320-360dp 에서 오버플로할 수 있었다.
//  - Quiz/Boss 헤더 행(vocab_pack_screen.dart:1081 부근, task_a40bf2a2) —
//    이전부터 있던 같은 모양의 결함(vocab_pack_quiz_save_test.dart 가 이미
//    "지시서 범위 밖의 기존 결함"이라 주석으로 회피해 둔 바로 그 Row).
//
// 두 곳 다 힌트 Text 를 Flexible+ellipsis 로 감싸 칩(숫자)은 항상 온전히
// 보이고 힌트만 먼저 접히도록 고쳤다. 이 파일은 그 수정이 유지되는지를
// 320×640 / 360×640 뷰포트에서 tester.takeException() 으로 검증한다.
//
// 뷰포트마다 별도 testWidgets 로 등록한다(루프 밖) — 한 testWidgets 안에서
// 이 무거운(Storage/Analytics/TTS 부수효과가 있는) 화면을 pumpWidget 을 두 번
// 부르면 이전 반복의 Storage 부수효과(vokSeen 등)가 다음 반복으로 새고, 그
// 결과 두 번째 반복에서 FlipCard 를 못 찾는 문제가 실측됐다. 별도 testWidgets
// 는 각각 독립된 tester + setUp 을 받아 이 누수를 원천 차단한다.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ko_lernen_app/l10n/generated/app_localizations.dart';
import 'package:ko_lernen_app/models/vocab.dart';
import 'package:ko_lernen_app/models/vocab_pack.dart';
import 'package:ko_lernen_app/screens/vocab_pack_screen.dart';
import 'package:ko_lernen_app/services/storage_service.dart';
import 'package:ko_lernen_app/theme.dart';
import 'package:ko_lernen_app/widgets/flip_card.dart';

import 'helpers/deck_actions.dart';

const _narrowSizes = [Size(320, 640), Size(360, 640)];

Vocab _word(int n) => Vocab(
  id: 'ov_v$n',
  korean: '오버플로단어$n',
  romanization: 'overflow$n',
  german: 'OV-GER-$n',
  english: 'OV-EN-$n',
  level: 'A1',
  posDe: 'Nomen',
  exampleKorean: '',
  exampleGerman: '',
  topic: 'test',
  packId: 'a1_ov_1',
  packOrder: n,
);

VocabPack _pack(int n) => VocabPack(
  id: 'a1_ov_1',
  level: 'A1',
  words: [for (var i = 1; i <= n; i++) _word(i)],
);

Widget _host(VocabPack pack) => MaterialApp(
  debugShowCheckedModeBanner: false,
  theme: AppTheme.light,
  locale: const Locale('de'),
  supportedLocales: AppL10n.supportedLocales,
  localizationsDelegates: AppL10n.localizationsDelegates,
  home: VocabPackScreen(
    packId: pack.id,
    packLoader: (_) async => pack,
    siblingPacksLoader: (_) async => [pack],
  ),
);

Future<AppL10n> _pump(WidgetTester tester, VocabPack pack) async {
  await tester.pumpWidget(_host(pack));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 300));
  return AppL10n.delegate.load(const Locale('de'));
}

Future<void> _revealAndTap(WidgetTester tester, String label) async {
  tester.widget<FlipCard>(find.byType(FlipCard)).onTap!();
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
  tapDeckAction(tester, label);
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
}

void _setNarrowView(WidgetTester tester, Size size) {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    Storage.resetForTesting();
    SharedPreferences.setMockInitialValues({});
    await Storage.init();
    await Storage.setTutVocabPackSeen();
    await Storage.setTutPackQuizSeen();
    await Storage.setTutPackBossSeen();
    await Storage.setTutWordbookSeen();
  });

  for (final size in _narrowSizes) {
    testWidgets('Learn 카운터 행 — 재출제 접미사가 붙어도 $size 에서 오버플로하지 않는다', (
      tester,
    ) async {
      _setNarrowView(tester, size);

      final pack = _pack(4);
      final t = await _pump(tester, pack);

      // 1번째 카드 "몰라요" → 큐 끝에 재삽입.
      await _revealAndTap(tester, t.vocabPackDontKnow);
      // 2, 3, 4번째 카드 "알아요" → 큐를 소진해 재출제된 1번 카드가 다시
      // 서빙된다 — 칩 라벨이 "4 / 4 · +1 Wdh." 로 가장 길어지는 상태.
      await _revealAndTap(tester, t.vocabPackGotIt);
      await _revealAndTap(tester, t.vocabPackGotIt);
      await _revealAndTap(tester, t.vocabPackGotIt);

      expect(
        find.textContaining('· +1'),
        findsOneWidget,
        reason: '$size: 재출제 접미사가 붙은 상태를 만들지 못했다',
      );
      expect(
        tester.takeException(),
        isNull,
        reason: '$size 에서 Learn 카운터 행이 RenderFlex 오버플로',
      );
    });
  }

  for (final size in _narrowSizes) {
    testWidgets('Quiz 헤더 행 — $size 에서 오버플로하지 않는다', (tester) async {
      _setNarrowView(tester, size);

      final pack = _pack(2);
      final t = await _pump(tester, pack);

      // Learn 2장을 모두 통과해야 Quiz 로 진입한다. 1번째 탭까지는 아직
      // Learn 카운터 행(별도 가드)이 그려지는 구간이라 — 그쪽 결함과
      // 격리하려고 여기서 누적된 예외를 한 번 비운다. 2번째 탭이 Quiz 로의
      // 전환을 일으키는 그 탭이라 그 뒤로는 비우지 않는다 — 이후
      // takeException() 은 오직 Quiz 헤더 행 자체의 오버플로만 잡는다.
      await _revealAndTap(tester, t.vocabPackGotIt);
      tester.takeException();
      await _revealAndTap(tester, t.vocabPackGotIt);

      expect(
        find.textContaining('1 / 2'),
        findsOneWidget,
        reason: '$size: Quiz 헤더 칩이 안 보인다 — Quiz 진입 실패',
      );
      expect(
        find.text(t.vocabPackQuizHint),
        findsOneWidget,
        reason: '$size: Quiz 헤더 힌트 텍스트가 안 보인다',
      );
      expect(
        tester.takeException(),
        isNull,
        reason: '$size 에서 Quiz 헤더 행이 RenderFlex 오버플로',
      );
    });
  }
}
