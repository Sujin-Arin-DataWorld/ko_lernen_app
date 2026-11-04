import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ko_lernen_app/l10n/generated/app_localizations.dart';
import 'package:ko_lernen_app/models/book_page.dart';
import 'package:ko_lernen_app/models/custom_pack.dart';
import 'package:ko_lernen_app/screens/custom_pack_matching_screen.dart';
import 'package:ko_lernen_app/screens/custom_pack_quiz_screen.dart';
import 'package:ko_lernen_app/screens/sori_stage/sori_stage_shell.dart';
import 'package:ko_lernen_app/services/custom_pack_service.dart';
import 'package:ko_lernen_app/services/sound_service.dart';
import 'package:ko_lernen_app/services/storage_service.dart';
import 'package:ko_lernen_app/widgets/sori/approved_games/approved_game_material.dart';
import 'package:ko_lernen_app/widgets/sori/approved_games/approved_matching_view.dart';
import 'package:ko_lernen_app/widgets/sori/approved_games/approved_quiz_view.dart';
import 'package:ko_lernen_app/widgets/sori/route_observer.dart';

const _packId = 'approved-game-navigation';
final _words = [
  for (final pair in [
    ('학교', 'school'),
    ('학생', 'student'),
    ('친구', 'friend'),
    ('선생님', 'teacher'),
  ])
    ExtractedWord(
      korean: pair.$1,
      romanization: '',
      posDe: 'Nomen',
      translationDe: pair.$2,
      translationEn: pair.$2,
      exampleKorean: '',
      exampleDe: '',
      savedToPackId: null,
    ),
];

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() async {
    Storage.resetForTesting();
    SoundService.playImpl = (_) {};
    SharedPreferences.setMockInitialValues({
      'kl_tut_cpQuiz': true,
      'kl_tut_cpMatching': true,
      'kl_snd_speech': false,
    });
    await Storage.init();
    await CustomPackService.save(
      CustomPack.manual(id: _packId, name: 'Navigation', words: _words),
    );
  });
  tearDown(() {
    SoundService.resetForTesting();
    Storage.resetForTesting();
  });

  testWidgets(
    'matching survives all four tab detours with selection and evidence intact',
    (tester) async {
      final navigator = GlobalKey<NavigatorState>();
      final routes = _RouteLog();
      await _pump(
        tester,
        navigator,
        routes,
        const CustomPackMatchingScreen(packId: _packId),
      );
      final originalState = tester.state(find.byType(CustomPackMatchingScreen));
      final initial = _matching(tester);
      final leftOrder = initial.leftTiles.map((tile) => tile.label).toList();
      final rightOrder = initial.rightTiles.map((tile) => tile.label).toList();
      final korean = initial.leftTiles.first.label;
      initial.leftTiles.first.onTap!();
      await _settle(tester);

      // Selecting the already active Games tab must not add a route or end play.
      final pushes = routes.pushes;
      _navigation(tester).onSelected(2);
      expect(routes.pushes, pushes);
      expect(Storage.srsTotalReviewed(), 0);

      for (final tab in [0, 1, 3, 4]) {
        final before = _matching(tester);
        final answer = before.rightTiles
            .singleWhere((tile) => tile.label == _meaning(korean))
            .onTap!;
        await _detour(tester, navigator, routes, tab, whileCovered: answer);
        final after = _matching(tester);
        expect(
          tester.state(find.byType(CustomPackMatchingScreen)),
          same(originalState),
        );
        expect(
          after.leftTiles.singleWhere((tile) => tile.selected).label,
          korean,
        );
        expect(after.leftTiles.map((tile) => tile.label), leftOrder);
        expect(after.rightTiles.map((tile) => tile.label), rightOrder);
        expect(after.counter, before.counter);
        expect(Storage.srsTotalReviewed(), 0);
        expect(Storage.xp, 0);
      }

      _matching(tester).rightTiles
          .singleWhere((tile) => tile.label == _meaning(korean))
          .onTap!();
      await _settle(tester);
      expect(Storage.srsTotalReviewed(), 1);
      final next = _matching(
        tester,
      ).leftTiles.firstWhere((tile) => !tile.matched);
      next.onTap!();
      await _settle(tester);
      for (final tab in [0, 1, 3, 4]) {
        final before = _matching(tester);
        final pendingAnswer = before.rightTiles
            .singleWhere((tile) => tile.label == _meaning(next.label))
            .onTap!;
        await _detour(
          tester,
          navigator,
          routes,
          tab,
          whileCovered: pendingAnswer,
        );
        final after = _matching(tester);
        expect(
          after.leftTiles.singleWhere((tile) => tile.selected).label,
          next.label,
        );
        expect(
          after.leftTiles.singleWhere((tile) => tile.matched).label,
          korean,
        );
        expect(after.rightTiles.where((tile) => tile.matched), hasLength(1));
        expect(after.counter, before.counter);
        expect(Storage.srsTotalReviewed(), 1);
        expect(Storage.srsCard(korean)!.reviewCount, 1);
        expect(Storage.xp, 0);
      }
      await tester.pumpWidget(const SizedBox());
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'quiz tab detours retain current question and never replay grading',
    (tester) async {
      final navigator = GlobalKey<NavigatorState>();
      final routes = _RouteLog();
      await _pump(
        tester,
        navigator,
        routes,
        const CustomPackQuizScreen(packId: _packId),
      );
      final originalState = tester.state(find.byType(CustomPackQuizScreen));
      final initial = _quiz(tester);
      for (final tab in [0, 1, 3, 4]) {
        final before = _quiz(tester);
        await _detour(
          tester,
          navigator,
          routes,
          tab,
          whileCovered: () => before.onOption(before.correctOption),
        );
        final after = _quiz(tester);
        expect(
          tester.state(find.byType(CustomPackQuizScreen)),
          same(originalState),
        );
        expect(after.korean, initial.korean);
        expect(after.options, initial.options);
        expect(after.progressLabel, initial.progressLabel);
        expect(after.picked, isNull);
        expect(Storage.srsTotalReviewed(), 0);
      }

      _quiz(tester).onOption(initial.correctOption);
      await _settle(tester);
      expect(Storage.srsTotalReviewed(), 1);
      for (final tab in [0, 1, 3, 4]) {
        final before = _quiz(tester);
        expect(before.onNext, isNotNull);
        await _detour(
          tester,
          navigator,
          routes,
          tab,
          whileCovered: before.onNext!,
        );
        final after = _quiz(tester);
        expect(after.korean, initial.korean);
        expect(after.picked, initial.correctOption);
        expect(after.progressLabel, initial.progressLabel);
        expect(after.scoreLabel, before.scoreLabel);
        after.onOption(initial.correctOption);
        await _settle(tester);
        expect(Storage.srsCard(initial.korean)!.reviewCount, 1);
        expect(Storage.srsTotalReviewed(), 1);
        expect(Storage.xp, 0);
      }
      await tester.pumpWidget(const SizedBox());
      expect(tester.takeException(), isNull);
    },
  );
}

ApprovedMatchingView _matching(WidgetTester tester) =>
    tester.widget<ApprovedMatchingView>(find.byType(ApprovedMatchingView));
ApprovedQuizView _quiz(WidgetTester tester) =>
    tester.widget<ApprovedQuizView>(find.byType(ApprovedQuizView));
ApprovedGameNavigation _navigation(WidgetTester tester) =>
    tester.widget<ApprovedGameNavigation>(find.byType(ApprovedGameNavigation));
String _meaning(String korean) =>
    _words.singleWhere((word) => word.korean == korean).translationEn;

Future<void> _pump(
  WidgetTester tester,
  GlobalKey<NavigatorState> navigator,
  _RouteLog routes,
  Widget game,
) async {
  await tester.binding.setSurfaceSize(const Size(402, 874));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(
    MaterialApp(
      navigatorKey: navigator,
      navigatorObservers: [soriRouteObserver, routes],
      locale: const Locale('en'),
      supportedLocales: AppL10n.supportedLocales,
      localizationsDelegates: AppL10n.localizationsDelegates,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(disableAnimations: true),
        child: child!,
      ),
      home: game,
    ),
  );
  await _settle(tester);
}

/// Exercise the real frame's route push/pop and RouteAware notifications. Pop
/// before the next frame so this bounded test never starts the five unrelated
/// tab roots, Firebase reads or learning-focus loaders. The production visit's
/// onResumeGame performs this same Navigator.pop; its Shell wiring is reviewed
/// separately. This is navigation/state proof, not a rendered Shell E2E test.
Future<void> _detour(
  WidgetTester tester,
  GlobalKey<NavigatorState> navigator,
  _RouteLog routes,
  int tab, {
  required VoidCallback whileCovered,
}) async {
  final gameRoute = routes.stack.last;
  final pushes = routes.pushes;
  _navigation(tester).onSelected(tab);
  expect(routes.pushes, pushes + 1);
  expect(routes.stack.last, isA<MaterialPageRoute<void>>());
  expect(gameRoute.isActive, isTrue);
  expect(gameRoute.isCurrent, isFalse);
  whileCovered();
  navigator.currentState!.pop();
  await _settle(tester);
  expect(routes.stack.last, same(gameRoute));
  expect(gameRoute.isCurrent, isTrue);
  expect(find.byType(SoriStageShell), findsNothing);
  expect(tester.takeException(), isNull);
}

Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 8; i++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
}

class _RouteLog extends NavigatorObserver {
  final stack = <Route<dynamic>>[];
  int pushes = 0;
  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    pushes++;
    stack.add(route);
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    stack.remove(route);
  }
}
