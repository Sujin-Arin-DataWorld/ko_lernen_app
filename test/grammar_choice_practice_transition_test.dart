import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ko_lernen_app/l10n/generated/app_localizations.dart';
import 'package:ko_lernen_app/motion/transitions.dart';
import 'package:ko_lernen_app/screens/grammar_choice_quiz_screen.dart';
import 'package:ko_lernen_app/screens/grammar_screen.dart';
import 'package:ko_lernen_app/services/data_loader.dart';
import 'package:ko_lernen_app/services/storage_service.dart';

import 'support/sori_speech_stubs.dart';

/// §NAV-2(J4) — `GrammarScreen._openChoicePractice` (the free-practice CTA,
/// `grammar-choice-cta`) moved off `SoriTransitions.fadeScale` onto
/// `SoriTransitions.page`. `grammar_choice_quiz_route_test.dart` only
/// exercises the named `/grammar_choice_quiz` route (plan-driven entry via
/// `KoLernenApp`), which never calls `_openChoicePractice` — this is a
/// dedicated, lighter-weight harness for that specific call site.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    // GrammarScreen/GrammarChoiceQuizScreen are auto-speech screens
    // (content_audio_policy_guard_test.dart's targetScreens) — stub
    // SoriSpeech so an unmocked speak() doesn't fall through to the real
    // TtsService and lock an in-flight key forever (PR1 T3 trap,
    // test/auto_speech_test_stub_guard_test.dart).
    stubSoriSpeech();
    Storage.resetForTesting();
    SharedPreferences.setMockInitialValues(<String, Object>{});
    await Storage.init();
    // 4방향 덱 코치가 전체 화면 스포트라이트로 탭을 삼키지 않도록
    // (grammar_filter_position_test.dart 와 같은 이유).
    await Storage.setTutSeen('grammar');
    await Storage.setTutSeen('soriDeck');
    DataLoader.reset();
    // 실제 asset(rootBundle)에서 읽는 콜드 로드라 위젯 pump 예산과 경합할
    // 수 있다 — `setUp()`은 testWidgets의 fake-async 존 밖이라 이 await가
    // 안전하게 완료된다(grammar_filter_position_test.dart와 같은 이유).
    await DataLoader.loadGrammar();
  });

  testWidgets(
    'grammar choice-practice CTA opens the quiz through SoriTransitions.page',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          debugShowCheckedModeBanner: false,
          locale: const Locale('de'),
          supportedLocales: AppL10n.supportedLocales,
          localizationsDelegates: AppL10n.localizationsDelegates,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(disableAnimations: true),
            child: child!,
          ),
          home: const GrammarScreen(),
        ),
      );
      // pumpAndSettle is not used here: the screen's SoriEntrance stagger
      // animations mean it never truly settles (same reason
      // grammar_filter_position_test.dart's `_settle()` avoids it) — two
      // short pumps are enough for the pre-warmed asset load to land.
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      // Dismiss the plan-onboarding sheet if it auto-opened (same guard as
      // grammar_filter_position_test.dart's `_settle()`) — it sits on top
      // of the legacy-browse CTA and would otherwise absorb the tap below.
      if (find
          .byKey(const Key('grammar-plan-onboarding-sheet'))
          .evaluate()
          .isNotEmpty) {
        await tester.tapAt(const Offset(8, 8));
        await tester.pump(const Duration(milliseconds: 300));
      }

      final cta = find.byKey(const Key('grammar-choice-cta'));
      expect(cta, findsOneWidget);
      await tester.tap(cta);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(
        find.byType(GrammarChoiceQuizScreen, skipOffstage: false),
        findsOneWidget,
      );
      final route = ModalRoute.of(
        tester.element(
          find.byType(GrammarChoiceQuizScreen, skipOffstage: false),
        ),
      );
      expect(route, isA<SoriPageRoute<dynamic>>());
    },
  );
}
