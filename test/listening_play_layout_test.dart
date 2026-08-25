import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ko_lernen_app/l10n/generated/app_localizations.dart';
import 'package:ko_lernen_app/models/scenario.dart';
import 'package:ko_lernen_app/screens/listening_play_screen.dart';
import 'package:ko_lernen_app/services/storage_service.dart';
import 'package:ko_lernen_app/theme.dart';
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
}
