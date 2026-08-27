import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ko_lernen_app/l10n/generated/app_localizations.dart';
import 'package:ko_lernen_app/models/course_practice_context.dart';
import 'package:ko_lernen_app/models/curriculum.dart';
import 'package:ko_lernen_app/screens/vocab_pack_result_screen.dart';
import 'package:ko_lernen_app/screens/vocab_pack_screen.dart';
import 'package:ko_lernen_app/services/storage_service.dart';
import 'package:ko_lernen_app/services/vocab_pack_service.dart';
import 'package:ko_lernen_app/theme.dart';
import 'package:ko_lernen_app/widgets/sori/dancheong_stamp.dart';
import 'package:ko_lernen_app/widgets/sori/tokens.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    Storage.resetForTesting();
    SharedPreferences.setMockInitialValues({});
    await Storage.init();
  });

  test(
    'result copy describes completion and a later review, not mastery',
    () async {
      final de = await AppL10n.delegate.load(const Locale('de'));
      final en = await AppL10n.delegate.load(const Locale('en'));

      expect(
        de.vocabPackResultCleared.toLowerCase(),
        contains('abgeschlossen'),
      );
      expect(en.vocabPackResultCleared.toLowerCase(), contains('completed'));
      expect(
        de.vocabPackResultClearedAgain.toLowerCase(),
        contains('abgeschlossen'),
      );
      expect(
        en.vocabPackResultClearedAgain.toLowerCase(),
        contains('completed'),
      );
      expect(de.vocabPackResultGeschafft.toLowerCase(), contains('später'));
      expect(en.vocabPackResultGeschafft.toLowerCase(), contains('later'));
      expect(
        de.vocabPackResultGeschafft.toLowerCase(),
        isNot(contains('gemeistert')),
      );
      expect(
        en.vocabPackResultGeschafft.toLowerCase(),
        isNot(contains('master')),
      );
      expect(
        de.vocabPackResultClearedAgain.toLowerCase(),
        isNot(contains('gemeistert')),
      );
      expect(
        en.vocabPackResultClearedAgain.toLowerCase(),
        isNot(contains('master')),
      );
    },
  );

  test(
    'hard-word practice is offered only for a threshold-reaching session miss',
    () async {
      for (var i = 0; i < 3; i++) {
        await Storage.incrementWrongCount('missed-word');
      }

      expect(shouldOfferHardWordPractice(['missed-word']), isTrue);
      expect(shouldOfferHardWordPractice(['other-word']), isFalse);
      expect(shouldOfferHardWordPractice(const []), isFalse);
    },
  );

  testWidgets(
    'result hierarchy uses Sori type tokens and stable metric semantics',
    (tester) async {
      final semantics = tester.ensureSemantics();
      final t = await AppL10n.delegate.load(const Locale('en'));
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          locale: const Locale('en'),
          supportedLocales: AppL10n.supportedLocales,
          localizationsDelegates: AppL10n.localizationsDelegates,
          home: const VocabPackResultScreen(
            packId: 'a1_greetings_1',
            bossAccuracy: 1,
            bossCorrect: 2,
            bossTotal: 2,
            quizCorrect: 3,
            quizTotal: 3,
            justCleared: true,
            nextUnlockedPackId: null,
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 1100));

      final context = tester.element(find.byType(VocabPackResultScreen));
      final tt = SoriTextTheme.of(context);
      final packTitle = VocabPackService.displayLabel(
        'a1_greetings_1',
        lang: 'en',
      );
      expect(tester.widget<Text>(find.text(packTitle)).style, tt.h3);
      expect(
        tester.widget<Text>(find.text(t.vocabPackResultCleared)).style,
        tt.h2,
      );
      expect(
        tester.widget<Text>(find.text(t.vocabPackResultBossLabel)).style,
        tt.caption,
      );
      expect(tester.widget<Text>(find.text('2 / 2 (100%)')).style, tt.label);
      expect(
        tester.widget<Text>(find.text('+45 XP')).style,
        tt.h3.copyWith(color: SoriColors.gold),
      );
      expect(
        tester
            .widget<Semantics>(find.byKey(const Key('vocab-result-pack-title')))
            .properties
            .header,
        isTrue,
      );
      expect(
        tester
            .widget<Semantics>(
              find.byKey(
                ValueKey<String>(
                  'vocab-result-metric-${t.vocabPackResultBossLabel}',
                ),
              ),
            )
            .properties
            .label,
        '${t.vocabPackResultBossLabel}: 2 / 2 (100%)',
      );
      expect(
        tester
            .widget<Semantics>(find.byKey(const Key('vocab-result-xp')))
            .properties
            .label,
        '${t.vocabPackResultXpLabel}: +45 XP',
      );
      semantics.dispose();
    },
  );

  testWidgets(
    'result exposes the optional Hard Words route only when flagged',
    (tester) async {
      final t = await AppL10n.delegate.load(const Locale('de'));
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          locale: const Locale('de'),
          supportedLocales: AppL10n.supportedLocales,
          localizationsDelegates: AppL10n.localizationsDelegates,
          routes: {
            '/hard_words': (_) =>
                const Scaffold(body: Text('hard-words-route')),
          },
          home: const VocabPackResultScreen(
            packId: 'a1_test_1',
            bossAccuracy: 1,
            bossCorrect: 2,
            bossTotal: 2,
            quizCorrect: 3,
            quizTotal: 3,
            justCleared: true,
            nextUnlockedPackId: null,
            showHardWordsCta: true,
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 1100));

      final hardWordsCta = find.text(t.vocabPackResultHardWordsCta);
      expect(hardWordsCta, findsOneWidget);
      await tester.ensureVisible(hardWordsCta);
      await tester.tap(hardWordsCta);
      await tester.pumpAndSettle();
      expect(find.text('hard-words-route'), findsOneWidget);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          locale: const Locale('de'),
          supportedLocales: AppL10n.supportedLocales,
          localizationsDelegates: AppL10n.localizationsDelegates,
          home: const VocabPackResultScreen(
            packId: 'a1_test_1',
            bossAccuracy: 1,
            bossCorrect: 2,
            bossTotal: 2,
            quizCorrect: 3,
            quizTotal: 3,
            justCleared: true,
            nextUnlockedPackId: null,
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 1100));
      expect(find.text(t.vocabPackResultHardWordsCta), findsNothing);
    },
  );

  testWidgets('cleared result names the earned stamp for assistive tech', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    final t = await AppL10n.delegate.load(const Locale('en'));

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        locale: const Locale('en'),
        supportedLocales: AppL10n.supportedLocales,
        localizationsDelegates: AppL10n.localizationsDelegates,
        home: const VocabPackResultScreen(
          packId: 'a1_greetings_1',
          bossAccuracy: 1,
          bossCorrect: 2,
          bossTotal: 2,
          quizCorrect: 3,
          quizTotal: 3,
          justCleared: true,
          nextUnlockedPackId: null,
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 1100));

    expect(
      find.bySemanticsLabel(dancheongMotifName(t, DancheongMotif.lotus)),
      findsOneWidget,
    );
    semantics.dispose();
  });

  testWidgets('automaticallyImplyLeading 가 없어 기본 뒤로가기가 보인다', (
    tester,
  ) async {
    // 기존 하네스로 VocabPackResultScreen 을 courseContext 없이 pump —
    // 결과 화면 아래에 실제 경로가 하나 있어야(canPop) 기본 뒤로가기가
    // 나타나는지 의미 있게 검증된다(단일 route 스택에선 항상 숨는다).
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        locale: const Locale('de'),
        supportedLocales: AppL10n.supportedLocales,
        localizationsDelegates: AppL10n.localizationsDelegates,
        home: const Scaffold(body: Text('home-route')),
      ),
    );
    tester.state<NavigatorState>(find.byType(Navigator)).push(
      MaterialPageRoute(
        builder: (_) => const VocabPackResultScreen(
          packId: 'a1_test_1',
          bossAccuracy: 0.5,
          bossCorrect: 1,
          bossTotal: 2,
          quizCorrect: 2,
          quizTotal: 3,
          justCleared: false,
          nextUnlockedPackId: null,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(BackButton), findsOneWidget);
  });

  testWidgets(
    '"Zurück zum Grid" 는 코스 미션 진입에서도 pop 1회만 한다 (courseContext 유무 무관)',
    (tester) async {
      // Navigator 스택을 [Home, CourseMission, VocabPackResult] 로 세팅한 뒤
      // (courseContext 포함) "Zurück zum Grid" 탭 → CourseMission 라우트로
      // 정확히 1회 pop 했는지 검증. onTap 이 무조건 pop() 하나로 단순화된
      // 뒤에도(리뷰 라운드 1에서 courseContext 분기 제거) 이 시나리오가
      // 여전히 맞는지 지키는 회귀 가드다 — 스택 어디에도 '/vocab' 이름의
      // route 가 없으므로, 예전 popUntil('/vocab' || isFirst) 로직이면
      // isFirst(Home) 까지 밀려나 이 검증이 실패한다.
      const courseContext = CoursePracticeContext(
        courseUnitId: 'a1_greetings',
        contentKind: CurriculumContentKind.vocab,
        initialContentId: 'a1_greetings_1',
        contentLinkId: 'vocab-mission-link',
      );
      final t = await AppL10n.delegate.load(const Locale('de'));

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          locale: const Locale('de'),
          supportedLocales: AppL10n.supportedLocales,
          localizationsDelegates: AppL10n.localizationsDelegates,
          home: const Scaffold(body: Text('home-route')),
        ),
      );
      final navigator = tester.state<NavigatorState>(find.byType(Navigator));
      navigator.push(
        MaterialPageRoute(
          builder: (_) => const Scaffold(body: Text('course-mission-route')),
        ),
      );
      await tester.pumpAndSettle();
      navigator.push(
        MaterialPageRoute(
          builder: (_) => const VocabPackResultScreen(
            packId: 'a1_greetings_1',
            bossAccuracy: 0.5,
            bossCorrect: 1,
            bossTotal: 2,
            quizCorrect: 2,
            quizTotal: 3,
            justCleared: false,
            nextUnlockedPackId: null,
            courseContext: courseContext,
          ),
        ),
      );
      await tester.pumpAndSettle();

      final backToGrid = find.text(t.vocabPackResultBackToGrid);
      expect(backToGrid, findsOneWidget);
      await tester.ensureVisible(backToGrid);
      await tester.tap(backToGrid);
      await tester.pumpAndSettle();

      expect(find.text('course-mission-route'), findsOneWidget);
      expect(find.text('home-route'), findsNothing);
    },
  );

  testWidgets(
    '"Zurück zum Grid" 는 /path(학습 경로) 진입에서도 pop 1회만 한다',
    (tester) async {
      // 실사용 회귀(리뷰 라운드 1 지적): LearningPathScreen 은
      // (learning_path_screen.dart:364) courseContext 없이 '/vocab/pack' 을
      // pushNamed 하므로, 결과 화면 도달 시 courseContext 는 null 이고 스택
      // 어디에도 '/vocab' 이름의 route 가 없다 — 옛 popUntil('/vocab' ||
      // isFirst) 로직은 isFirst(Home) 까지 밀려나 학습 경로 화면을 건너뛰고
      // 만다. 무조건 pop() 은 정확히 1단계만 되돌아가 '/path' 로 돌아온다.
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          locale: const Locale('de'),
          supportedLocales: AppL10n.supportedLocales,
          localizationsDelegates: AppL10n.localizationsDelegates,
          home: const Scaffold(body: Text('home-route')),
        ),
      );
      final navigator = tester.state<NavigatorState>(find.byType(Navigator));
      navigator.push(
        MaterialPageRoute(
          settings: const RouteSettings(name: '/path'),
          builder: (_) => const Scaffold(body: Text('learning-path-route')),
        ),
      );
      await tester.pumpAndSettle();
      navigator.push(
        MaterialPageRoute(
          builder: (_) => const VocabPackResultScreen(
            packId: 'a1_test_1',
            bossAccuracy: 0.5,
            bossCorrect: 1,
            bossTotal: 2,
            quizCorrect: 2,
            quizTotal: 3,
            justCleared: false,
            nextUnlockedPackId: null,
          ),
        ),
      );
      await tester.pumpAndSettle();

      final t = await AppL10n.delegate.load(const Locale('de'));
      final backToGrid = find.text(t.vocabPackResultBackToGrid);
      expect(backToGrid, findsOneWidget);
      await tester.ensureVisible(backToGrid);
      await tester.tap(backToGrid);
      await tester.pumpAndSettle();

      expect(find.text('learning-path-route'), findsOneWidget);
      expect(find.text('home-route'), findsNothing);
    },
  );
}
