/// 2026-08-18 후속 UX 3건 — 테스터 → Jin 전달.
///
///   ① 획순 카드가 작다        → 세로 2단, 둘 다 같은 크기
///   ② 카드 음성이 늦게 나온다 → 화면 진입 시 낱자 34개 미리받기
///   ③ 좌우 슬라이딩이 느리다  → 공용 SoriSwipeCard 로 교체
///
/// ②·③ 은 눈으로만 확인하면 조용히 되돌아간다. 여기서 계약으로 못박는다.
library;

import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ko_lernen_app/data/hangul_data.dart' as hangul;
import 'package:ko_lernen_app/l10n/generated/app_localizations.dart';
import 'package:ko_lernen_app/screens/hangul_screen.dart';
import 'package:ko_lernen_app/services/storage_service.dart';
import 'package:ko_lernen_app/theme.dart';
import 'package:ko_lernen_app/widgets/flip_card.dart';
import 'package:ko_lernen_app/widgets/sori/content_feed.dart';
import 'package:ko_lernen_app/widgets/stroke_canvas.dart';

import 'helpers/deck_actions.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late List<String> prefetched;

  setUp(() async {
    SharedPreferences.setMockInitialValues({'kl_tut_hangul': true});
    Storage.resetForTesting();
    await Storage.init();
    prefetched = <String>[];
  });

  Future<void> pumpScreen(WidgetTester tester, {int tab = 1}) async {
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
        home: HangulScreen(
          speechPlayer: (_) async => true,
          textPrefetcher: (text) async => prefetched.add(text),
        ),
      ),
    );
    tester.widget<TabBar>(find.byType(TabBar)).controller!.index = tab;
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
  }

  group('② 음성 미리받기', () {
    testWidgets('화면에 들어오면 낱자 34개를 미리 받는다', (tester) async {
      await pumpScreen(tester);
      for (final c in [...hangul.consonants, ...hangul.vowels]) {
        expect(
          prefetched,
          contains(hangul.speakableJamo(c.letter)),
          reason: '${c.letter} 의 음가를 미리 받지 않았다',
        );
      }
    });

    testWidgets('미리받는 건 예시어가 아니라 1음절 음가다', (tester) async {
      await pumpScreen(tester);
      // ㅃ 은 예전에 예시어 '빵' 을 읽었다 — 웜업이 그 회귀를 되살리면 안 된다.
      expect(prefetched, contains('쁘'));
    });

    testWidgets('카드 탭은 좌우 이웃까지 미리 받는다', (tester) async {
      await pumpScreen(tester);
      // 자음 첫 카드(ㄱ) 기준 이웃 = 마지막(ㅉ) 과 두 번째(ㄴ).
      expect(prefetched, contains(hangul.speakableJamo('ㄴ')));
      expect(prefetched, contains(hangul.speakableJamo('ㅉ')));
      // 예시어도 함께 (칩의 스피커 버튼용).
      expect(prefetched, contains('가방'));
    });
  });

  group('③ 카드 스와이프 — 세로 피드 계약', () {
    testWidgets('공용 SoriContentFeed 를 쓰고 틴더 축을 쓰지 않는다', (tester) async {
      await pumpScreen(tester);
      expect(find.byType(SoriContentFeed), findsOneWidget);
      final feed = tester.widget<SoriContentFeed>(find.byType(SoriContentFeed));

      expect(feed.onNext, isNotNull, reason: '뒤집은 뒤 세로 다음 = 앎');
      expect(feed.onHard, isNotNull, reason: '모름은 텍스트 판정');
      expect(feed.onSkip, isNotNull, reason: '뒤집기 전 세로 = 넘어가기');
      expect(feed.showBookmark, isFalse, reason: '자모는 단어장 대상이 아니다');
      expect(feed.underlay, isNotNull);
    });

    testWidgets('아래로 밀면 넘어간다 — 뒤집지 않아도 된다', (tester) async {
      await pumpScreen(tester);
      expect(find.text('1 / 19'), findsOneWidget);
      await tester.fling(find.byType(FlipCard).first, const Offset(0, 400), 1200);
      await tester.pumpAndSettle();
      expect(find.text('2 / 19'), findsOneWidget);
    });

    testWidgets('뒤집기 전에는 좌/우 판정이 일어나지 않는다', (tester) async {
      // flipgate 계약 — 못 본 낱자에 앎/모름이 기록되면 안 된다.
      await pumpScreen(tester);
      await tester.fling(find.byType(FlipCard).first, const Offset(400, 0), 1200);
      await tester.pumpAndSettle();
      expect(find.text('1 / 19'), findsOneWidget);
      expect(Storage.hangulHard, isEmpty);
    });

    testWidgets('뒤집은 뒤 모름 텍스트로 기록하고 넘어간다', (tester) async {
      await pumpScreen(tester);
      await tester.tap(find.byType(FlipCard).first);
      await tester.pumpAndSettle();
      tapDeckAction(tester, 'Didn\'t know');
      await tester.pumpAndSettle();
      expect(Storage.hangulHard, contains('ㄱ'));
      expect(find.text('2 / 19'), findsOneWidget);
    });
  });

  group('① Write 탭 레이아웃', () {
    testWidgets('시범·연습 캔버스가 세로로 쌓이고 크기가 같다', (tester) async {
      await pumpScreen(tester, tab: 2);
      final demo = tester.getRect(find.byType(StrokeCanvas));
      final practice = tester.getRect(
        find.byKey(const Key('hangul-practice-canvas')),
      );
      expect(
        demo.size.width,
        closeTo(practice.size.width, 1),
        reason: '둘 다 같은 크기여야 한다',
      );
      expect(
        demo.size.height,
        closeTo(practice.size.height, 1),
      );
      // 세로 배치 — 연습이 시범 **아래**.
      expect(practice.top, greaterThan(demo.bottom - 1));
      // 좌우 반반(165pt)보다 확실히 커졌다.
      expect(demo.size.width, greaterThan(200));
    });

    testWidgets('연습 캔버스 위 드래그는 획이 될 뿐 글자를 넘기지 않는다', (
      tester,
    ) async {
      // 이게 이번 변경에서 가장 깨지기 쉬운 계약이다 — 스와이프 내비게이션을
      // 붙였는데 큰 연습 캔버스가 그걸 먹으면 글씨를 못 쓴다. 반대로 캔버스가
      // 제스처를 독점하지 않으면 획을 그으려다 글자가 넘어간다.
      await pumpScreen(tester, tab: 2);
      expect(find.text('1 / 19'), findsOneWidget);

      final canvas = find.byKey(const Key('hangul-practice-canvas'));
      final bounds = tester.getRect(canvas);
      final gesture = await tester.startGesture(
        Offset(bounds.left + 20, bounds.center.dy),
      );
      await gesture.moveTo(Offset(bounds.right - 20, bounds.center.dy));
      await gesture.up();
      await tester.pump();

      expect(
        find.text('1 / 19'),
        findsOneWidget,
        reason: '캔버스 위 가로 드래그는 획이어야 한다 — 글자가 넘어가면 안 된다',
      );
    });

    testWidgets('Write 탭은 좌우 스와이프로 넘기지 않는다 — 방향 계약 보호', (
      tester,
    ) async {
      // 여기서만 좌/우를 이전/다음으로 쓰면 카드 덱에서 익힌 손버릇과
      // 정반대가 된다(우 = 앎). 이동은 ‹ › 아이콘이 정본이다.
      await pumpScreen(tester, tab: 2);
      expect(find.text('1 / 19'), findsOneWidget);
      await tester.fling(find.byType(StrokeCanvas), const Offset(-400, 0), 1200);
      await tester.pumpAndSettle();
      expect(find.text('1 / 19'), findsOneWidget);

      await tester.tap(find.byKey(const Key('hangul-write-next')));
      await tester.pump();
      expect(find.text('2 / 19'), findsOneWidget);
    });

    testWidgets('컴팩트 아이콘 행이 예전 전폭 버튼 4줄을 대신한다', (tester) async {
      await pumpScreen(tester, tab: 2);
      for (final key in [
        'hangul-write-prev',
        'hangul-write-next',
        'hangul-write-speak',
        'hangul-write-clear',
      ]) {
        expect(find.byKey(Key(key)), findsOneWidget, reason: key);
      }
      // 44pt 터치 타깃 (접근성).
      for (final key in ['hangul-write-prev', 'hangul-write-next']) {
        final size = tester.getSize(find.byKey(Key(key)));
        expect(math.min(size.width, size.height), greaterThanOrEqualTo(44.0));
      }
    });
  });

  group('회귀 방어', () {
    test('캐시 파일은 원자적으로 쓴다 — 부분 파일이 재생되면 안 된다', () {
      // 프리페치(쓰기)와 재생(읽기)이 같은 mp3 를 동시에 만진다.
      // isUsableAudio 는 길이·앞바이트만 보므로 쓰다 만 파일도 통과한다.
      final source = File('lib/services/tts_service.dart').readAsStringSync();
      expect(
        source.contains('.rename('),
        isTrue,
        reason: '임시 파일 + rename 으로 갈아끼워야 한다',
      );
      expect(
        RegExp(r'await file\.writeAsBytes\(').hasMatch(source),
        isFalse,
        reason: '캐시 파일에 직접 쓰지 말 것 — _writeAtomically 를 쓴다',
      );
    });

    test('음성 채널이 꺼져 있으면 미리받지 않는다', () {
      final source = File('lib/services/tts_service.dart').readAsStringSync();
      final body = RegExp(
        r'static Future<void> prefetch\(.*?\n  \}',
        dotAll: true,
      ).firstMatch(source);
      expect(body, isNotNull);
      expect(
        body!.group(0),
        contains('SoundChannel.speech'),
        reason: '절대 못 들을 파일을 내려받지 않는다',
      );
    });

    test('같은 텍스트를 세션 내 두 번 시도하지 않는다', () {
      final source = File('lib/services/tts_service.dart').readAsStringSync();
      final body = RegExp(
        r'static Future<void> prefetch\(.*?\n  \}',
        dotAll: true,
      ).firstMatch(source);
      expect(body!.group(0), contains('_prefetchAttempted'));
    });

    test('프리페치는 Cloud Function 동적 합성을 하지 않는다', () {
      // 누르지도 않은 낱자를 투기적으로 합성하면 합성 할당량을 태우고
      // 12초 타임아웃까지 잡아먹는다. 로컬 캐시 + Storage 까지만 본다.
      final source = File('lib/services/tts_service.dart').readAsStringSync();
      final prefetchBody = RegExp(
        r'static Future<void> prefetch\(.*?\n  \}',
        dotAll: true,
      ).firstMatch(source);
      expect(prefetchBody, isNotNull, reason: 'prefetch 를 찾지 못했다');
      expect(
        prefetchBody!.group(0),
        contains('allowSynthesis: false'),
        reason: '프리페치는 반드시 allowSynthesis: false 로 호출한다',
      );
    });

    testWidgets('프리페치가 실패해도 화면은 정상 동작한다', (tester) async {
      // best-effort 계약 — 못 받아도 탭하면 평소 경로로 재생된다.
      tester.view.physicalSize = const Size(1200, 2600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          locale: const Locale('en'),
          supportedLocales: AppL10n.supportedLocales,
          localizationsDelegates: AppL10n.localizationsDelegates,
          home: HangulScreen(
            speechPlayer: (_) async => true,
            textPrefetcher: (_) async => throw StateError('오프라인'),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(tester.takeException(), isNull);
      expect(find.byType(HangulScreen), findsOneWidget);
    });

    testWidgets('Write 탭이 작은 폰 + 큰 글자에서 오버플로하지 않는다', (tester) async {
      // 캔버스를 240pt 로 키우고 규칙 카드를 유지했으므로 세로가 빡빡하다.
      // 스크롤로 받아내야 하고 RenderFlex 가 넘치면 안 된다.
      tester.view.physicalSize = const Size(360, 780);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          locale: const Locale('de'), // 독일어가 영어보다 20~30% 길다
          supportedLocales: AppL10n.supportedLocales,
          localizationsDelegates: AppL10n.localizationsDelegates,
          home: MediaQuery(
            data: const MediaQueryData(
              size: Size(360, 780),
              textScaler: TextScaler.linear(1.3),
            ),
            child: HangulScreen(
              speechPlayer: (_) async => true,
              textPrefetcher: (_) async {},
            ),
          ),
        ),
      );
      tester.widget<TabBar>(find.byType(TabBar)).controller!.index = 2;
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(tester.takeException(), isNull, reason: 'Write 탭 오버플로');
    });

    testWidgets('스와이프 도중 화면을 벗어나도 터지지 않는다', (tester) async {
      // 애니메이션 정착 전에 dispose 되는 경로 — 컨트롤러 수명 사고가 잦은 곳.
      tester.view.physicalSize = const Size(1200, 2600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          locale: const Locale('en'),
          supportedLocales: AppL10n.supportedLocales,
          localizationsDelegates: AppL10n.localizationsDelegates,
          home: HangulScreen(
            speechPlayer: (_) async => true,
            textPrefetcher: (_) async {},
          ),
        ),
      );
      tester.widget<TabBar>(find.byType(TabBar)).controller!.index = 1;
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      await tester.fling(find.byType(FlipCard).first, const Offset(0, 400), 1200);
      await tester.pump(const Duration(milliseconds: 40)); // 정착 전
      await tester.pumpWidget(const MaterialApp(home: SizedBox.shrink()));
      await tester.pump(const Duration(milliseconds: 600));
      expect(tester.takeException(), isNull);
    });
  });
}
