import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ko_lernen_app/l10n/generated/app_localizations.dart';
import 'package:ko_lernen_app/models/scenario.dart';
import 'package:ko_lernen_app/screens/listening_play_screen.dart';
import 'package:ko_lernen_app/services/storage_service.dart';
import 'package:ko_lernen_app/theme.dart';
import 'package:ko_lernen_app/widgets/sori/tokens.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _firstKo = '오늘 저녁에 친구들이랑 홍대에서 만나서 노래해요';
const _secondKo = '네 좋아요';

Scenario _scenario() => Scenario(
  id: 'play_layout',
  level: LearnerLevel.a1,
  emoji: '📻',
  register: Register.polite,
  shelf: 'a1_friends',
  backdrop: 'home',
  title: const LocalizedText(ko: '약속', de: 'Verabredung', en: 'Meetup'),
  intro: const LocalizedText(
    ko: '주말 약속을 정해요.',
    de: 'Ihr verabredet euch fürs Wochenende.',
    en: 'You make weekend plans.',
  ),
  vocab: const [],
  grammarIds: const [],
  dialog: const [
    DialogLine(
      speaker: 'jieun',
      ko: _firstKo,
      de: 'Lange Zeile',
      en: 'Long line',
    ),
    DialogLine(
      speaker: 'user',
      ko: _secondKo,
      de: 'Ja, gern.',
      en: 'Yes, great.',
    ),
  ],
  quests: const [],
);

Widget _app(Widget home, {double textScale = 1}) => MaterialApp(
  theme: AppTheme.light,
  locale: const Locale('de'),
  supportedLocales: AppL10n.supportedLocales,
  localizationsDelegates: AppL10n.localizationsDelegates,
  builder: (context, child) => MediaQuery(
    data: MediaQuery.of(
      context,
    ).copyWith(textScaler: TextScaler.linear(textScale)),
    child: child!,
  ),
  home: home,
);

Future<void> _pumpUntil(WidgetTester tester, bool Function() condition) async {
  for (var attempt = 0; attempt < 30; attempt++) {
    if (condition()) {
      return;
    }
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    await tester.pump(const Duration(milliseconds: 10));
  }
  expect(
    condition(),
    isTrue,
    reason: 'Expected async UI state did not settle.',
  );
}

void main() {
  setUp(() async {
    Storage.resetForTesting();
    SharedPreferences.setMockInitialValues({
      'kl_tut_listening_play': true,
      'kl_user_level': 'a1',
    });
    await Storage.init();
  });

  testWidgets('entry is silent, then bubbles accumulate in speaker order', (
    tester,
  ) async {
    final pending = <Completer<bool>>[];
    final spoken = <String>[];
    var stops = 0;
    await tester.pumpWidget(
      _app(
        ListeningPlayScreen(
          scenario: _scenario(),
          speechPlayer: (text, {required voice}) {
            spoken.add(text);
            final completer = Completer<bool>();
            pending.add(completer);
            return completer.future;
          },
          stopPlayer: () async => stops++,
        ),
      ),
    );
    await tester.pump();
    final t = AppL10n.of(tester.element(find.byType(ListeningPlayScreen)));

    expect(spoken, isEmpty);
    expect(find.text(_firstKo), findsNothing);
    expect(find.text(t.listeningDialogueStart), findsOneWidget);

    await tester.tap(find.text(t.listeningDialogueStart));
    await tester.pump();
    expect(spoken, [_firstKo]);
    expect(find.text(_firstKo), findsOneWidget);
    expect(find.text(_secondKo), findsNothing);

    pending.first.complete(true);
    await tester.pump();
    expect(spoken, [_firstKo, _secondKo]);
    expect(find.text(_firstKo), findsOneWidget);
    expect(find.text(_secondKo), findsOneWidget);
    expect(
      tester.getCenter(find.text('Jieun')).dx,
      lessThan(tester.getCenter(find.text(t.listeningSpeakerYou)).dx),
    );

    await tester.tap(find.text(t.listeningShowTranslation).last);
    await tester.pump();
    expect(stops, greaterThanOrEqualTo(1));
    expect(find.text(t.listeningResume), findsOneWidget);
    expect(find.text('Ja, gern.'), findsOneWidget);
  });

  testWidgets('TTS failure holds the current Korean line and offers retry', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(
        ListeningPlayScreen(
          scenario: _scenario(),
          speechPlayer: (text, {required voice}) async => false,
          stopPlayer: () async {},
        ),
      ),
    );
    await tester.pump();
    final t = AppL10n.of(tester.element(find.byType(ListeningPlayScreen)));
    await tester.ensureVisible(find.text(t.listeningDialogueStart));
    await tester.tap(find.text(t.listeningDialogueStart));
    await tester.pump();

    expect(find.text(_firstKo), findsOneWidget);
    expect(find.text(_secondKo), findsNothing);
    expect(find.text(t.listeningTtsFailedTitle), findsOneWidget);
    expect(find.text(t.listeningRetry), findsOneWidget);
  });

  testWidgets('current bubble alone has blue and gold outlines', (
    tester,
  ) async {
    final pending = <Completer<bool>>[];
    await tester.pumpWidget(
      _app(
        ListeningPlayScreen(
          scenario: _scenario(),
          speechPlayer: (text, {required voice}) {
            final completer = Completer<bool>();
            pending.add(completer);
            return completer.future;
          },
          stopPlayer: () async {},
        ),
      ),
    );
    await tester.pump();
    final t = AppL10n.of(tester.element(find.byType(ListeningPlayScreen)));

    await tester.tap(find.text(t.listeningDialogueStart));
    await tester.pump();

    Set<Color> borderColors(String text) => tester
        .widgetList<Container>(
          find.ancestor(of: find.text(text), matching: find.byType(Container)),
        )
        .map((container) => container.decoration)
        .whereType<BoxDecoration>()
        .map((decoration) => decoration.border)
        .whereType<Border>()
        .map((border) => border.top.color)
        .toSet();

    expect(
      borderColors(_firstKo),
      containsAll({
        SoriColors.listeningCurrentOutline,
        SoriColors.listeningCurrentInnerOutline,
      }),
    );

    pending.first.complete(true);
    await tester.pump();
    expect(
      borderColors(_firstKo),
      isNot(contains(SoriColors.listeningCurrentOutline)),
    );
    expect(
      borderColors(_secondKo),
      containsAll({
        SoriColors.listeningCurrentOutline,
        SoriColors.listeningCurrentInnerOutline,
      }),
    );

    pending.last.complete(false);
    await tester.pump();
  });

  testWidgets('completion grants once and review exposes every line', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(
        ListeningPlayScreen(
          scenario: _scenario(),
          speechPlayer: (text, {required voice}) async => true,
          stopPlayer: () async {},
        ),
        textScale: 2,
      ),
    );
    await tester.pump();
    final t = AppL10n.of(tester.element(find.byType(ListeningPlayScreen)));
    await tester.ensureVisible(find.text(t.listeningDialogueStart));
    await tester.tap(find.text(t.listeningDialogueStart));
    await tester.pump();
    await tester.pump();
    await _pumpUntil(
      tester,
      () => Storage.completedScenarios.contains('play_layout'),
    );

    expect(find.text(t.listeningCompleteTitle), findsOneWidget);
    expect(Storage.completedScenarios, contains('play_layout'));
    expect(Storage.xp, 40);
    await tester.ensureVisible(find.text(t.listeningReviewCta));
    await tester.tap(find.text(t.listeningReviewCta));
    await tester.pump();
    expect(find.text(_firstKo), findsOneWidget);
    expect(find.text(_secondKo), findsOneWidget);
    expect(find.byTooltip(t.contentActionLike), findsWidgets);
    await tester.tap(find.text(t.listeningReplay).first);
    await tester.pump();
    expect(Storage.xp, 40);
    expect(tester.takeException(), isNull);
  });

  testWidgets('screen re-entry completes without granting XP again', (
    tester,
  ) async {
    Future<void> finish() async {
      await tester.ensureVisible(find.text('Dialog anhören'));
      await tester.tap(find.text('Dialog anhören'));
      await tester.pump();
      await tester.pump();
      await _pumpUntil(
        tester,
        () => find.text('Geschafft!').evaluate().isNotEmpty,
      );
    }

    await tester.pumpWidget(
      _app(
        ListeningPlayScreen(
          scenario: _scenario(),
          speechPlayer: (text, {required voice}) async => true,
          stopPlayer: () async {},
        ),
      ),
    );
    await tester.pump();
    await finish();
    await _pumpUntil(tester, () => Storage.xp == 40);
    expect(Storage.xp, 40);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    await tester.pumpWidget(
      _app(
        ListeningPlayScreen(
          scenario: _scenario(),
          speechPlayer: (text, {required voice}) async => true,
          stopPlayer: () async {},
        ),
      ),
    );
    await tester.pump();
    final t = AppL10n.of(tester.element(find.byType(ListeningPlayScreen)));
    await finish();
    await _pumpUntil(
      tester,
      () => find
          .text(t.listeningCompleteReplayBody(_scenario().dialog.length))
          .evaluate()
          .isNotEmpty,
    );

    expect(Storage.xp, 40);
    expect(
      find.text(t.listeningCompleteReplayBody(_scenario().dialog.length)),
      findsOneWidget,
    );
  });
}
