/// Audio prefetch, explicit grading and native Atelier gesture contracts.
library;

import 'dart:io';
import 'support/real_fonts.dart';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ko_lernen_app/data/hangul_data.dart' as hangul;
import 'package:ko_lernen_app/l10n/generated/app_localizations.dart';
import 'package:ko_lernen_app/models/guide_contract.dart';
import 'package:ko_lernen_app/screens/hangul_screen.dart';
import 'package:ko_lernen_app/services/storage_service.dart';
import 'package:ko_lernen_app/services/tts_recorded_jamo.dart';
import 'package:ko_lernen_app/theme.dart';
import 'package:ko_lernen_app/widgets/flip_card.dart';
import 'package:ko_lernen_app/widgets/sori/c_gallery/c_atelier_materials.dart';
import 'package:ko_lernen_app/widgets/trace_canvas.dart';

String? _sourceSection(
  String source, {
  required String startMarker,
  required String endMarker,
}) {
  final start = source.indexOf(startMarker);
  if (start < 0) return null;
  final end = source.indexOf(endMarker, start + startMarker.length);
  if (end < 0) return null;
  return source.substring(start, end);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() => loadSoriRealFonts(materialIcons: true));

  late List<String> prefetched;

  setUp(() async {
    SharedPreferences.setMockInitialValues({
      'kl_tut_hangul': true,
      'kl_tut_hangulWriteRules': true,
      'kl_hangul_auto_advance_v1': false,
    });
    Storage.resetForTesting();
    await Storage.init();
    prefetched = <String>[];
  });

  Future<void> pumpScreen(
    WidgetTester tester, {
    int tab = 1,
    Future<bool> Function(String text)? speechPlayer,
    Future<void> Function(String text)? textPrefetcher,
  }) async {
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
          initialTarget: HangulTarget.values[tab],
          speechPlayer: speechPlayer ?? (_) async => true,
          textPrefetcher:
              textPrefetcher ?? (text) async => prefetched.add(text),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  group('② 음성 미리받기', () {
    testWidgets('화면에 들어오면 녹음이 없는 낱자만 미리 받는다', (tester) async {
      await pumpScreen(tester);
      for (final c in [...hangul.consonants, ...hangul.vowels]) {
        if (TtsRecordedJamo.hasLetter(c.letter)) {
          continue;
        }
        expect(
          prefetched,
          contains(hangul.speakableJamo(c.letter)),
          reason: '${c.letter} 의 음가를 미리 받지 않았다',
        );
      }
      expect(prefetched, isNot(contains('드')));
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

  group('②-1 즉시 재생 + 전환 자동재생', () {
    testWidgets('카드가 처음 보이는 프레임에 현재 낱자를 자동재생한다', (tester) async {
      final spoken = <String>[];
      await pumpScreen(
        tester,
        speechPlayer: (text) async {
          spoken.add(text);
          return true;
        },
      );

      expect(spoken, contains(hangul.speakableJamo('ㄱ')));
    });

    testWidgets('카드 뒤집기가 인식되면 현재 낱자 재생을 시작한다', (tester) async {
      final spoken = <String>[];
      await pumpScreen(
        tester,
        speechPlayer: (text) async {
          spoken.add(text);
          return true;
        },
      );
      spoken.clear();

      await tester.tap(find.byType(FlipCard).first);
      expect(spoken, isEmpty, reason: 'double tap 판단 전에는 뒤집지 않는다');
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pumpAndSettle();

      expect(spoken, [hangul.speakableJamo('ㄱ')]);
    });

    testWidgets('다음 카드 전환은 재생을 먼저 게시하고 이웃을 뒤에서 미리 받는다', (tester) async {
      final events = <String>[];
      await pumpScreen(
        tester,
        speechPlayer: (text) async {
          events.add('speak:$text');
          return true;
        },
        textPrefetcher: (text) async => events.add('prefetch:$text'),
      );
      events.clear();

      tester
          .widget<CAtelierButton>(_button(_l10n(tester).atelierSkip))
          .onTap!();

      expect(events, isNotEmpty);
      expect(events.first, 'speak:${hangul.speakableJamo('ㄴ')}');
      expect(
        events,
        contains('prefetch:${hangul.speakableJamo('ㄱ')}'),
        reason: '새 현재 카드 재생과 동시에 녹음이 없는 이웃도 계속 데워야 한다',
      );
      expect(events, isNot(contains('prefetch:드')));
      await tester.pump();
      expect(find.text('2 / 19'), findsOneWidget);
    });
  });

  group('③ Atelier 카드 — 세로 탐색과 명시적 판정', () {
    testWidgets('앞면에서는 앎과 모름이 막히고 건너뛰기와 소셜 조작은 유지된다', (tester) async {
      await pumpScreen(tester);
      final t = _l10n(tester);
      expect(
        tester.widget<CAtelierButton>(_button(t.atelierKnown)).onTap,
        isNull,
      );
      expect(
        tester.widget<CAtelierButton>(_button(t.atelierNotYet)).onTap,
        isNull,
      );
      expect(
        tester.widget<CAtelierButton>(_button(t.atelierSkip)).onTap,
        isNotNull,
      );
      expect(find.text(t.atelierRemember), findsOneWidget);
      expect(find.text(t.atelierShare), findsOneWidget);
      expect(find.byKey(const Key('atelier-feed-ㄱ')), findsOneWidget);
      expect(Storage.hangulHard, isEmpty);
    });

    testWidgets('위로 탐색하면 뒤집지 않아도 다음 카드로 가며 판정하지 않는다', (tester) async {
      await pumpScreen(tester);
      expect(find.text('1 / 19'), findsOneWidget);
      await tester.fling(find.byType(FlipCard), const Offset(0, -180), 1200);
      await tester.pumpAndSettle();
      expect(find.text('2 / 19'), findsOneWidget);
      expect(Storage.hangulHard, isEmpty);
    });

    testWidgets('아래로 탐색하면 이전 카드로 가며 앞면 판정은 계속 막힌다', (tester) async {
      await pumpScreen(tester);
      await tester.fling(find.byType(FlipCard), const Offset(0, 180), 1200);
      await tester.pumpAndSettle();
      expect(find.text('19 / 19'), findsOneWidget);
      expect(Storage.hangulHard, isEmpty);
      expect(
        tester
            .widget<CAtelierButton>(_button(_l10n(tester).atelierKnown))
            .onTap,
        isNull,
      );
      expect(
        tester
            .widget<CAtelierButton>(_button(_l10n(tester).atelierNotYet))
            .onTap,
        isNull,
      );
    });

    testWidgets('뒤집은 뒤 모름 버튼이 실제 어려운 글자를 기록하고 넘어간다', (tester) async {
      await pumpScreen(tester);
      await tester.tap(find.byType(FlipCard));
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pumpAndSettle();
      await tester.tap(_button(_l10n(tester).atelierNotYet));
      await tester.runAsync(() => Future<void>.delayed(Duration.zero));
      await tester.pumpAndSettle();
      expect(Storage.hangulHard, contains('ㄱ'));
      expect(find.text('2 / 19'), findsOneWidget);
    });
  });

  group('① Atelier Write 입력과 조작', () {
    testWidgets('필기 가이드와 실제 입력은 같은 종이 영역을 사용한다', (tester) async {
      await pumpScreen(tester, tab: 2);
      final guide = tester.getRect(
        find.byKey(const Key('hangul-writing-guide')),
      );
      final practice = tester.getRect(find.byKey(const Key('trace-canvas')));
      expect(guide, practice);
      expect(practice.width, greaterThan(200));
      expect(
        tester.widget<TraceCanvas>(find.byType(TraceCanvas)).enabled,
        isTrue,
      );
    });

    testWidgets('종이 위 가로 드래그는 획이며 글자를 넘기지 않는다', (tester) async {
      await pumpScreen(tester, tab: 2);
      expect(find.text('1 / 34'), findsOneWidget);
      final canvas = find.byKey(const Key('trace-canvas'));
      final bounds = tester.getRect(canvas);
      final gesture = await tester.startGesture(
        Offset(bounds.left + 20, bounds.center.dy),
      );
      await gesture.moveTo(Offset(bounds.right - 20, bounds.center.dy));
      await gesture.up();
      await tester.pump();
      expect(find.text('1 / 34'), findsOneWidget);
      expect(tester.widget<TraceCanvas>(find.byType(TraceCanvas)).ghost, 'ㄱ');
      await tester.pump(const Duration(milliseconds: 600));
    });

    testWidgets('쓰기 글자 이동은 종이 스와이프가 아닌 다음 버튼으로 한다', (tester) async {
      await pumpScreen(tester, tab: 2);
      await tester.fling(
        find.byKey(const Key('trace-canvas')),
        const Offset(-180, 0),
        1200,
      );
      await tester.pumpAndSettle();
      expect(find.text('1 / 34'), findsOneWidget);
      await tester.tap(_button(_l10n(tester).btnNext));
      await tester.pumpAndSettle();
      expect(find.text('2 / 34'), findsOneWidget);
    });

    testWidgets('필기 선택과 이동·지우기·더 보기 조작은 한 행과 48dp 영역을 유지한다', (tester) async {
      await pumpScreen(tester, tab: 2);
      final t = _l10n(tester);
      final controls = [
        _button(t.btnPrev),
        find.byKey(const Key('hangul-writing-selection')),
        _button(t.btnNext),
        _button(t.hangulClearBtn),
        _button(t.atelierMore),
      ];
      final centerY = tester.getRect(controls.first).center.dy;
      for (final control in controls) {
        final bounds = tester.getRect(control);
        expect(bounds.center.dy, closeTo(centerY, .1));
        expect(math.min(bounds.width, bounds.height), greaterThanOrEqualTo(48));
      }
      expect(_button(t.cHangulListen), findsOneWidget);
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
      final body = _sourceSection(
        source,
        startMarker: 'static Future<void> prefetch(',
        endMarker: 'static final Set<String> _prefetchAttempted',
      );
      expect(body, isNotNull);
      expect(
        body,
        contains('SoundChannel.speech'),
        reason: '절대 못 들을 파일을 내려받지 않는다',
      );
    });

    test('같은 텍스트를 세션 내 두 번 시도하지 않는다', () {
      final source = File('lib/services/tts_service.dart').readAsStringSync();
      final body = _sourceSection(
        source,
        startMarker: 'static Future<void> prefetch(',
        endMarker: 'static final Set<String> _prefetchAttempted',
      );
      expect(body, isNotNull);
      expect(body, contains('_prefetchAttempted'));
    });

    test('프리페치는 Cloud Function 동적 합성을 하지 않는다', () {
      // 누르지도 않은 낱자를 투기적으로 합성하면 합성 할당량을 태우고
      // 12초 타임아웃까지 잡아먹는다. 로컬 캐시 + Storage 까지만 본다.
      final source = File('lib/services/tts_service.dart').readAsStringSync();
      final prefetchBody = _sourceSection(
        source,
        startMarker: 'static Future<void> prefetch(',
        endMarker: 'static final Set<String> _prefetchAttempted',
      );
      expect(prefetchBody, isNotNull, reason: 'prefetch 를 찾지 못했다');
      expect(
        prefetchBody,
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
              initialTarget: HangulTarget.write,
              speechPlayer: (_) async => true,
              textPrefetcher: (_) async {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final finish = find.byKey(const Key('hangul-finish-writing'));
      await tester.ensureVisible(finish);
      await tester.pumpAndSettle();
      expect(tester.getSize(finish).height, greaterThanOrEqualTo(48));
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
            initialTarget: HangulTarget.cards,
            speechPlayer: (_) async => true,
            textPrefetcher: (_) async {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.fling(
        find.byType(FlipCard).first,
        const Offset(0, 400),
        1200,
      );
      await tester.pump(const Duration(milliseconds: 40)); // 정착 전
      await tester.pumpWidget(const MaterialApp(home: SizedBox.shrink()));
      await tester.pump(const Duration(milliseconds: 600));
      expect(tester.takeException(), isNull);
    });
  });
}

AppL10n _l10n(WidgetTester tester) =>
    AppL10n.of(tester.element(find.byType(HangulScreen)));

Finder _button(String label) =>
    find.byWidgetPredicate((w) => w is CAtelierButton && w.label == label);
