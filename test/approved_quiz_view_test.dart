import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ko_lernen_app/l10n/generated/app_localizations.dart';
import 'package:ko_lernen_app/widgets/sori/approved_games/approved_game_material.dart';
import 'package:ko_lernen_app/widgets/sori/approved_games/approved_quiz_view.dart';

import 'support/viewport_pages.dart';

const _fixtures = [
  (
    name: 'short',
    topic: 'Essen und Trinken',
    korean: '커피',
    meanings: ['Brot', 'Kaffee', 'Wasser', 'Obst'],
    choicesY: 483.0,
  ),
  (
    name: 'medium',
    topic: 'Wohnen',
    korean: '원상복구',
    meanings: [
      'Eigentümergemeinschaft',
      'Mängelbeseitigung',
      'Wiederherstellung des ursprünglichen Zustands',
      'Schlichtungsantrag',
    ],
    choicesY: 463.0,
  ),
  (
    name: 'long',
    topic: 'Technik und Verantwortung',
    korean: '책임을 시스템 탓으로 돌리다',
    meanings: [
      'das Recht auf Widerruf gewährleisten',
      'Verantwortung auf das System schieben',
      'einen Entscheidungsprozess nachverfolgen',
      'Erklärbarkeit sicherstellen',
    ],
    choicesY: 483.0,
  ),
];

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    final latin = FontLoader('Lora')
      ..addFont(rootBundle.load('assets/fonts/Lora/Lora-Variable.ttf'));
    final korean = FontLoader('MaruBuriOTF')
      ..addFont(rootBundle.load('assets/fonts/MaruBuri/MaruBuri-Bold.otf'));
    await Future.wait([latin.load(), korean.load()]);
  });

  for (final fixture in _fixtures) {
    testWidgets(
      '${fixture.name}: approved 402px geometry and complete real text',
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(402, 792));
        addTearDown(() => tester.binding.setSurfaceSize(null));
        await tester.pumpWidget(
          _host(
            topic: fixture.topic,
            korean: fixture.korean,
            options: fixture.meanings,
          ),
        );
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(find.bySemanticsLabel(fixture.korean), findsOneWidget);
        if (fixture.name == 'long') {
          expect(find.text('책임을 시스템\n탓으로 돌리다'), findsOneWidget);
        }
        final first = tester.getRect(
          find.byKey(const ValueKey('approved-quiz-choice-0')),
        );
        final last = tester.getRect(
          find.byKey(const ValueKey('approved-quiz-choice-3')),
        );
        expect(first.left, 29);
        expect(first.width, 344);
        expect(first.top, closeTo(fixture.choicesY, 0.5));
        expect(last.bottom, lessThanOrEqualTo(776));
        for (final meaning in fixture.meanings) {
          expect(find.text(meaning), findsOneWidget);
          final text = tester.widget<Text>(find.text(meaning));
          expect(text.maxLines, isNull);
          expect(text.overflow, isNot(TextOverflow.ellipsis));
        }
      },
    );
  }

  testWidgets(
    '320dp at 200% keeps audio and answers reachable without scroll',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(320, 640));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      tester.view.padding = const FakeViewPadding(top: 24, bottom: 24);
      tester.view.viewPadding = const FakeViewPadding(top: 24, bottom: 24);
      addTearDown(tester.view.resetPadding);
      addTearDown(tester.view.resetViewPadding);
      final fixture = _fixtures.last;
      String? selected;
      var plays = 0;
      await tester.pumpWidget(
        _host(
          topic: fixture.topic,
          korean: fixture.korean,
          options: fixture.meanings,
          scale: 2,
          onOption: (value) => selected = value,
          onListen: () => plays++,
          fullFrame: true,
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.byType(SingleChildScrollView), findsNothing);
      expect(
        find.bySemanticsLabel(fixture.korean).hitTestable(),
        findsOneWidget,
      );
      final listen = find.byKey(const ValueKey('approved-quiz-compact-listen'));
      expect(listen.hitTestable(), findsOneWidget);
      await tester.tap(listen);
      expect(plays, 1);
      for (var i = 0; i < fixture.meanings.length; i++) {
        final choice = find.byKey(ValueKey('approved-quiz-choice-$i'));
        await showViewportSection(tester, choice);
        expect(listen.hitTestable(), findsOneWidget);
        expect(tester.getSize(choice).height, greaterThanOrEqualTo(48));
        expect(tester.takeException(), isNull);
      }
      await tester.tap(find.text(fixture.meanings.last));
      expect(selected, fixture.meanings.last);
      var advances = 0;
      await tester.pumpWidget(
        _host(
          topic: fixture.topic,
          korean: fixture.korean,
          options: fixture.meanings,
          scale: 2,
          picked: selected,
          onNext: () => advances++,
          fullFrame: true,
        ),
      );
      await tester.pumpAndSettle();
      final next = find.byKey(const ValueKey('approved-quiz-compact-next'));
      expect(next.hitTestable(), findsOneWidget);
      expect(tester.getSize(next).height, greaterThanOrEqualTo(48));
      await tester.tap(next);
      expect(advances, 1);
    },
  );

  testWidgets('revealed answer remains fixed and disables all answer taps', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(402, 792));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final fixture = _fixtures.first;
    var calls = 0;
    await tester.pumpWidget(
      _host(
        topic: fixture.topic,
        korean: fixture.korean,
        options: fixture.meanings,
        picked: fixture.meanings.first,
        onOption: (_) => calls++,
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Falsch'), findsOneWidget);
    for (final option in fixture.meanings) {
      await tester.tap(find.text(option));
    }
    expect(calls, 0);
    expect(
      tester
          .getTopLeft(find.byKey(const ValueKey('approved-quiz-choice-0')))
          .dy,
      483,
    );
  });

  for (final fixture in _fixtures) {
    testWidgets(
      '${fixture.name}: native SafeArea keeps all four full targets above navigation',
      (tester) async {
        tester.view.devicePixelRatio = 2.75;
        tester.view.physicalSize = const Size(1080, 2400);
        // Physical inset pixels represent 44dp top and 36dp bottom. The remaining
        // content viewport is 710.73dp after the real 82dp image navigation.
        tester.view.padding = const FakeViewPadding(top: 121, bottom: 99);
        tester.view.viewPadding = const FakeViewPadding(top: 121, bottom: 99);
        addTearDown(tester.view.resetDevicePixelRatio);
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetPadding);
        addTearDown(tester.view.resetViewPadding);
        final selected = <String>[];
        await tester.pumpWidget(
          _host(
            topic: fixture.topic,
            korean: fixture.korean,
            options: fixture.meanings,
            fullFrame: true,
            onOption: selected.add,
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        final navigation = tester.getRect(find.byType(ApprovedGameNavigation));
        final viewport = tester.getRect(
          find.byKey(const ValueKey('approved-quiz-scroll')),
        );
        expect(viewport.top, closeTo(44, .01));
        expect(viewport.height, closeTo(710.727, .01));
        for (var i = 0; i < 4; i++) {
          final choice = find.byKey(ValueKey('approved-quiz-choice-$i'));
          final fullTouchRect = tester.getRect(choice);
          expect(fullTouchRect.height, greaterThanOrEqualTo(48));
          expect(fullTouchRect.top, greaterThanOrEqualTo(viewport.top));
          expect(
            fullTouchRect.bottom + 3 + 16,
            lessThanOrEqualTo(navigation.top + .01),
          );
          // No ensureVisible: each choice must already be directly tappable.
          await tester.tap(find.text(fixture.meanings[i]));
          await tester.pump();
          expect(
            tester.widget<Text>(find.text(fixture.meanings[i])).style!.fontSize,
            greaterThanOrEqualTo(18),
          );
        }
        expect(selected, fixture.meanings);
        final scrollable = tester.state<ScrollableState>(
          find.descendant(
            of: find.byKey(const ValueKey('approved-quiz-scroll')),
            matching: find.byType(Scrollable),
          ),
        );
        expect(scrollable.position.pixels, 0);
        expect(scrollable.position.maxScrollExtent, lessThanOrEqualTo(.01));
        expect(tester.takeException(), isNull);
      },
    );
  }
}

Widget _host({
  required String topic,
  required String korean,
  required List<String> options,
  double scale = 1,
  String? picked,
  ValueChanged<String>? onOption,
  VoidCallback? onListen,
  VoidCallback? onNext,
  bool fullFrame = false,
}) {
  Widget view(Widget leading) => ApprovedQuizView(
    title: 'Wörter-Quiz',
    topic: topic,
    scoreLabel: '0 richtig',
    progressLabel: '1 von 6',
    question: 'Was bedeutet dieses Wort?',
    instruction: 'Wähle die Bedeutung.',
    korean: korean,
    options: options,
    correctOption: options[1],
    picked: picked,
    listenLabel: 'Anhören',
    correctFeedback: 'Richtig',
    wrongFeedback: 'Falsch',
    nextLabel: 'Weiter',
    leading: leading,
    onOption: onOption ?? (_) {},
    onListen: onListen ?? () {},
    onNext: onNext,
    speedControl: const SizedBox(),
  );
  return MaterialApp(
    locale: const Locale('de'),
    localizationsDelegates: AppL10n.localizationsDelegates,
    supportedLocales: AppL10n.supportedLocales,
    builder: (context, child) => MediaQuery(
      data: MediaQuery.of(
        context,
      ).copyWith(textScaler: TextScaler.linear(scale)),
      child: child!,
    ),
    home: fullFrame
        ? ApprovedGameFrame(
            title: 'Wörter-Quiz',
            contentBuilder: (_, close) => view(close),
          )
        : Scaffold(body: view(const SizedBox())),
  );
}
