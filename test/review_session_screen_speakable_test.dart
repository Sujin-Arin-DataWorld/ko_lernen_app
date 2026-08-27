import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ko_lernen_app/l10n/generated/app_localizations.dart';
import 'package:ko_lernen_app/models/vocab.dart';
import 'package:ko_lernen_app/screens/review_session_screen.dart';
import 'package:ko_lernen_app/services/storage_service.dart';
import 'package:ko_lernen_app/theme.dart';
import 'package:ko_lernen_app/widgets/sori/content_feed.dart';
import 'package:ko_lernen_app/widgets/sori/speakable.dart';

/// T13 (+ fix round 1) — `SoriSpeakable` 배선 표면 계약: `review_session_screen.dart`.
///
/// 카드 진입 시 좌상단에 [SoriSpeechIndicator]가 뜨고, 그걸 탭하면 카드 탭
/// (플립)과 같은 히트테스트 아레나에 섞이지 않고 재생만 트리거된다.
///
/// 진입 + 카드 전환(Skip) 자동재생은 `TtsService.speaking` 플래그가 아니라
/// `SoriSpeech.speakImpl` 가짜 리졸버로 호출된 텍스트를 직접 세어 고정한다 —
/// `speaking` 은 이전 호출의 엔진 Future 가 아직 안 끝났으면(테스트 환경엔
/// 플랫폼 채널이 없어 완료가 보장되지 않는다) true 로 눌어붙어 있을 수 있어
/// "이번 전환이 실제로 새로 발화했는가"를 구분하지 못한다. `speakImpl` 콜
/// 리스트는 결정적이고, `playOnEnter` 호출을 지우면 즉시 실패한다.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final testDeck = [
    const Vocab(
      id: 'rv_1',
      korean: '학교',
      romanization: 'hakgyo',
      german: 'Schule',
      level: 'A1',
      posDe: 'N.',
      exampleKorean: '학교에 가다',
      exampleGerman: 'Zur Schule gehen',
      topic: 'Bildung',
    ),
    const Vocab(
      id: 'rv_2',
      korean: '선생님',
      romanization: 'seonsaengnim',
      german: 'Lehrer',
      level: 'A1',
      posDe: 'N.',
      exampleKorean: '선생님이 오다',
      exampleGerman: 'Der Lehrer kommt',
      topic: 'Bildung',
    ),
  ];

  final speakCalls = <String>[];

  setUp(() async {
    Storage.resetForTesting();
    SharedPreferences.setMockInitialValues({
      'kl_user_level': 'a1',
      'kl_streak_days': 0,
      'kl_xp': 0,
      // 코치 오버레이(AbsorbPointer)가 탭을 삼켜 단언이 공허해지는 것 방지.
      'kl_tut_review': true,
      'kl_tut_soriDeck': true,
      'kl_tut_wordbook': true,
    });
    await Storage.init();
    SoriSpeech.resetForTesting();
    speakCalls.clear();
    SoriSpeech.speakImpl = (text, voice) async {
      speakCalls.add(text);
      return true;
    };
  });

  tearDown(() {
    SoriSpeech.resetForTesting();
  });

  Widget buildScreen() => MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: AppTheme.light,
    locale: const Locale('de'),
    supportedLocales: AppL10n.supportedLocales,
    localizationsDelegates: AppL10n.localizationsDelegates,
    home: MediaQuery(
      data: const MediaQueryData(size: Size(400, 800), disableAnimations: true),
      child: ReviewSessionScreen(deck: testDeck),
    ),
  );

  testWidgets('카드 진입 시 SoriSpeechIndicator 렌더 + 진입 자동재생 트리거', (tester) async {
    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(buildScreen());
    // 로드 완료 + 진입 자동재생 디바운스(150-250ms)를 흘려보낸다 — 대기
    // 타이머를 남기지 않는다.
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('학교'), findsOneWidget);
    expect(find.byType(SoriSpeechIndicator), findsOneWidget);
    // 인디케이터가 떠 있는지와 무관하게, playOnEnter 가 실제로 발동했는지를
    // 직접 고정한다 — 이 어서션 하나로 initState 의 자동재생 배선이 지워지면
    // 곧바로 빨개진다.
    expect(speakCalls, ['학교']);
  });

  testWidgets('SoriSpeechIndicator 탭 → 플립 아님(플립 상태 불변), 재생만 트리거', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(buildScreen());
    await tester.pump(const Duration(milliseconds: 500));

    // 앞면(한국어 헤드라인)이 보여야 함.
    expect(find.text('학교'), findsOneWidget);
    // 진입 자동재생 몫을 걷어내고 탭의 몫만 본다.
    speakCalls.clear();

    await tester.tap(find.byType(SoriSpeechIndicator));
    await tester.pump();

    // 인디케이터는 자기 탭을 SoriPressable 로 직접 처리해 SoriSpeech.speak()
    // 만 트리거한다 — 카드 배경의 더블탭/드래그 Listener 와 아레나가 섞이지
    // 않으므로(content_feed.dart 검수#13①) _toggleFlip 이 불리지 않는다:
    // 여전히 앞면(플립됐다면 헤드라인이 독일어 "Schule"로 바뀌어 사라진다).
    expect(find.text('학교'), findsOneWidget);
    expect(tester.takeException(), isNull);
    expect(speakCalls, ['학교']);
  });

  testWidgets('Skip 전환 시에도 자동재생이 새 카드로 재트리거된다 (fix round 1, finding #1)', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(buildScreen());
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('학교'), findsOneWidget);
    expect(speakCalls, ['학교'], reason: '스킵 전 기준선 — 진입 자동재생');
    speakCalls.clear();

    // _deferCurrent 는 _idx 를 바꾸지 않고 _deck 를 재정렬한다 — onSkip 을
    // 직접 호출해 실제 화면이 쓰는 것과 동일한 콜백을 그대로 태운다(리뷰
    // 화면의 flipgate 테스트가 SoriPressable.onTap 을 직접 호출하는 것과
    // 같은 패턴).
    final feed = tester.widget<SoriContentFeed>(find.byType(SoriContentFeed));
    expect(feed.onSkip, isNotNull, reason: '2장 덱의 첫 카드는 skip 가능해야 함');
    feed.onSkip!();
    await tester.pump();

    // 화면엔 이미 새 카드('선생님')가 앞면으로 보인다 — _idx 는 그대로지만
    // _deck[_idx] 가 가리키는 카드가 바뀌었기 때문. ('학교'는 사라지지
    // 않는다 — 2장 덱이라 스킵된 카드가 이제 "다음 카드" underlay 미리보기로
    // 다시 보인다. 그건 정상 동작이라 부재를 단언하지 않는다.)
    expect(find.text('선생님'), findsOneWidget);

    // 디바운스(150-250ms)를 흘려보내야 playOnEnter 예약이 실제 speak() 로
    // 이어진다.
    await tester.pump(const Duration(milliseconds: 300));

    expect(
      speakCalls,
      ['선생님'],
      reason: 'Skip 으로 넘어간 새 카드도 진입/Next 전환과 동일하게 자동재생돼야 한다',
    );
  });
}
