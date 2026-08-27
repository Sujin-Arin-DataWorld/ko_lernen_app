import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ko_lernen_app/l10n/generated/app_localizations.dart';
import 'package:ko_lernen_app/models/vocab.dart';
import 'package:ko_lernen_app/screens/chosung_quiz_screen.dart';
import 'package:ko_lernen_app/services/data_loader.dart';
import 'package:ko_lernen_app/services/storage_service.dart';
import 'package:ko_lernen_app/theme.dart';
import 'package:ko_lernen_app/widgets/sori/spotlight_coach.dart';
import 'package:ko_lernen_app/widgets/sori/text_field.dart';

/// `AddToWordbookButton` 의 첫 노출 스포트라이트 코치(`wordbook_add.dart:130-164`)
/// 회귀 커버리지 — 지시서 1.24 검수 finding #2.
///
/// T9(피드 북마크 스탬프 48dp 승격 + AppBar 중복 버튼 제거)에서
/// `vocab_pack_screen.dart` 의 AppBar `AddToWordbookButton` 을 지우며,
/// 그 버튼만 앵커하던 `vocab_pack_flipgate_test.dart` 의 코치 시퀀싱
/// 테스트도 함께 지웠다 — 그 버튼이 그 화면에서 완전히 사라졌으니 삭제
/// 자체는 옳았다. 그런데 그 케이스가 이 메커니즘의 **유일한** 커버리지였다.
/// 버튼은 여전히 4개 화면에 남아 있다: book_result(:898)·chosung_quiz(:524)·
/// listening_play(:681)·scenario_player(:1081).
///
/// chosung_quiz 를 골랐다:
///   (a) `coachEnabled` 를 override 하지 않아 기본값 true 로 코치가 실제로
///       뜬다 — listening_play 는 `coachEnabled: false` 를 박아놔서
///       (listening_play_screen.dart:687) 이 메커니즘을 절대 못 켠다.
///   (b) 생성자가 `deck:` 을 직접 받아 CSV 로더 없이 결정적으로 펌프된다 —
///       book_result 는 결과 화면 진입 시퀀스, scenario_player 는 시나리오
///       JSON 로더가 더 필요해 이쪽이 더 무겁다.
///   (c) 자체 첫 진입 코치(`ScreenCoachMixin`, coachId 'chosung')가 있지만
///       `kl_tut_chosung` 로 미리 seen 처리하면 이 테스트와 무관해진다 —
///       vocab_pack 의 "3단계 시트를 먼저 닫아야" 하던 번거로움이 없다.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const deck = [
    Vocab(
      korean: '가방',
      romanization: 'gabang',
      german: 'Tasche',
      level: 'A1',
      posDe: 'Nomen',
      exampleKorean: '가방이 있어요.',
      exampleGerman: 'Da ist eine Tasche.',
      topic: 'test',
    ),
  ];

  setUp(() async {
    Storage.resetForTesting();
    DataLoader.reset();
    SharedPreferences.setMockInitialValues({
      'kl_user_level': 'a1',
      // chosung 자체 3단계 코치는 이 테스트의 관심사가 아니다 — 미리 봄 처리.
      'kl_tut_chosung': true,
      // 핵심 전제: 워드북 코치는 아직 한 번도 못 봤다.
      'kl_tut_wordbook': false,
    });
    await Storage.init();
  });

  Future<void> pump(WidgetTester tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        locale: const Locale('de'),
        supportedLocales: AppL10n.supportedLocales,
        localizationsDelegates: AppL10n.localizationsDelegates,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(disableAnimations: true),
          child: child!,
        ),
        home: const ChosungQuizScreen(deck: deck),
      ),
    );
    // 로딩 → 카드 렌더까지 한 프레임짜리 async 갭이 있다.
    for (var attempt = 0; attempt < 40; attempt++) {
      if (find.byType(SoriTextField).evaluate().isNotEmpty) return;
      await tester.pump(const Duration(milliseconds: 50));
    }
  }

  testWidgets(
    'AddToWordbookButton 코치가 처음엔 큐잉/노출되고, 완료하면 영구 플래그가 선다',
    (tester) async {
      await pump(tester);
      final t = await AppL10n.delegate.load(const Locale('de'));

      expect(Storage.tutWordbookSeen, isFalse, reason: '전제 확인 — 아직 미표시');
      expect(find.byKey(kSpotlightTooltipKey), findsNothing);

      // AddToWordbookButton.initState → addPostFrameCallback → _scheduleCoach
      // → SpotlightCoach.show → 자체 OverlayEntry → 또 addPostFrameCallback
      // (_measure) 까지 프레임이 몇 겹 필요하다. disableAnimations: true 라
      // pulse AnimationController 가 아예 안 생겨(spotlight_coach.dart
      // _SpotlightLayerState.initState) 반복 타이머 없이 안전하게 폴링된다.
      for (var attempt = 0; attempt < 20; attempt++) {
        if (find.byKey(kSpotlightTooltipKey).evaluate().isNotEmpty) break;
        await tester.pump(const Duration(milliseconds: 50));
      }

      expect(
        find.byKey(kSpotlightTooltipKey),
        findsOneWidget,
        reason: 'AddToWordbookButton 의 스포트라이트가 큐잉/노출돼야 한다',
      );
      expect(find.text(t.wbCoachTitle), findsOneWidget);
      expect(find.text(t.wbCoachBody), findsOneWidget);

      await tester.tap(find.text(t.navTourDone));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pump();

      expect(find.byKey(kSpotlightTooltipKey), findsNothing);
      expect(
        Storage.tutWordbookSeen,
        isTrue,
        reason: '완료(onComplete) 시 Storage.setTutWordbookSeen() 이 불려야 한다',
      );
    },
  );
}
