import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ko_lernen_app/l10n/generated/app_localizations.dart';
import 'package:ko_lernen_app/models/vocab.dart';
import 'package:ko_lernen_app/screens/review_session_screen.dart';
import 'package:ko_lernen_app/services/storage_service.dart';
import 'package:ko_lernen_app/theme.dart';
import 'package:ko_lernen_app/widgets/sori/speakable.dart';

/// T13 — `SoriSpeakable` 배선 표면 계약: `review_session_screen.dart`.
///
/// 카드 진입 시 좌상단에 [SoriSpeechIndicator]가 뜨고, 그걸 탭하면 카드 탭
/// (플립)과 같은 히트테스트 아레나에 섞이지 않고 재생만 트리거된다 —
/// `content_feed.dart` 검수#13① 계약(topAccessory 는 카드 배경 Listener 의
/// 형제로 그 위에 얹힌다)이 이 화면에서 실제로 배선됐는지 확인한다.
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

  testWidgets('카드 진입 시 SoriSpeechIndicator 렌더', (tester) async {
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

    await tester.tap(find.byType(SoriSpeechIndicator));
    await tester.pump();

    // 인디케이터는 자기 탭을 SoriPressable 로 직접 처리해 SoriSpeech.speak()
    // 만 트리거한다 — 카드 배경의 더블탭/드래그 Listener 와 아레나가 섞이지
    // 않으므로(content_feed.dart 검수#13①) _toggleFlip 이 불리지 않는다:
    // 여전히 앞면(플립됐다면 헤드라인이 독일어 "Schule"로 바뀌어 사라진다).
    expect(find.text('학교'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
