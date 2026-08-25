import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ko_lernen_app/l10n/generated/app_localizations.dart';
import 'package:ko_lernen_app/models/scenario.dart';
import 'package:ko_lernen_app/screens/scenario_player_screen.dart';
import 'package:ko_lernen_app/services/scene_asset_resolver.dart';
import 'package:ko_lernen_app/theme.dart';

/// Regression: das Szenen-Poster (24 % Höhe) darf die Antwortoptionen nicht
/// unter die Falz drücken. Vorher wurde bei "Einreise am Flughafen"
/// (Hörverstehen, 4 Antworten, 393x873 dp) die letzte Option am Scroll-Rand
/// hart angeschnitten; nach dem Scrollen war stattdessen die Frage-Karte oben
/// angeschnitten (Jin 2026-08-23, Gerätescreenshot). Das Poster gibt jetzt den
/// gemessenen Überlauf ab (bis minimal 96 dp).
const _scene = Scenario(
  id: 'airport_arrival',
  level: LearnerLevel.a1,
  emoji: '✈️',
  register: Register.polite,
  backdrop: 'airport',
  title: LocalizedText(
    ko: '공항 입국',
    de: 'Einreise am Flughafen',
    en: 'Airport arrival',
  ),
  intro: LocalizedText(ko: '', de: '', en: ''),
  vocab: [],
  grammarIds: [],
  quests: [
    QuestSpec(
      type: QuestType.hoerverstehen,
      data: {
        'audioKo': '한국 처음이세요?',
        'correctIndex': 0,
        'options': [
          {'de': 'Erstes Mal in Korea?', 'en': 'First time in Korea?'},
          {'de': 'Wie lange bleiben Sie?', 'en': 'How long are you staying?'},
          {'de': 'Wo kommen Sie her?', 'en': 'Where are you from?'},
          {
            'de': 'Sind Sie geschäftlich hier?',
            'en': 'Are you here on business?',
          },
        ],
      },
    ),
  ],
  dialog: [
    DialogLine(
      speaker: 'officer',
      ko: '여권 보여주세요.',
      de: 'Bitte Ihren Pass.',
      en: 'Passport, please.',
    ),
  ],
);

Widget _host({double textScale = 1.0}) => MaterialApp(
  theme: AppTheme.light,
  locale: const Locale('de'),
  supportedLocales: AppL10n.supportedLocales,
  localizationsDelegates: AppL10n.localizationsDelegates,
  builder: (context, child) => MediaQuery(
    data: MediaQuery.of(context).copyWith(
      textScaler: TextScaler.linear(textScale),
      disableAnimations: true,
      padding: const EdgeInsets.only(top: 32, bottom: 16),
      viewPadding: const EdgeInsets.only(top: 32, bottom: 16),
    ),
    child: child!,
  ),
  home: ScenarioPlayerScreen.preview(
    fixture: ScenarioPlayerPreviewFixture.action(
      scenario: _scene,
      stage: ScenarioStage.quest,
      questIndex: 0,
    ),
  ),
);

Future<void> _pumpSettled(WidgetTester tester, Widget widget) async {
  await tester.pumpWidget(widget);
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 300));
  // Metrics-Microtask + Poster-Konzession brauchen einen weiteren Frame.
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 300));
}

void main() {
  testWidgets('poster yields height so all four answers sit above the fold', (
    tester,
  ) async {
    await SceneAssetResolver.load();
    tester.view.physicalSize = const Size(393 * 3, 873 * 3);
    tester.view.devicePixelRatio = 3.0;
    await tester.binding.setSurfaceSize(const Size(393, 873));
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
      tester.binding.setSurfaceSize(null);
    });

    await _pumpSettled(tester, _host());

    // Der Quest-Scrollbereich darf nach der Poster-Konzession keinen
    // vertikalen Überlauf mehr haben: alles ist ohne Scrollen sichtbar.
    final scrollables = find
        .byType(Scrollable)
        .evaluate()
        .map((e) => (e as StatefulElement).state as ScrollableState);
    final questScrolls = scrollables.where(
      (s) =>
          s.position.axis == Axis.vertical &&
          s.position.viewportDimension < 873,
    );
    expect(questScrolls, isNotEmpty);
    for (final s in questScrolls) {
      expect(
        s.position.maxScrollExtent,
        lessThan(1),
        reason: 'quest content must fit without scrolling at 1.0x on 393x873',
      );
    }

    // Alle vier Antworten liegen vollständig über der angehefteten Aktion.
    final submitTop = tester
        .getRect(find.byKey(const ValueKey('quest-submit')))
        .top;
    for (var i = 0; i < 4; i++) {
      final rect = tester.getRect(find.byKey(ValueKey('answer-$i')));
      expect(
        rect.bottom,
        lessThanOrEqualTo(submitTop),
        reason: 'answer $i must not be cut at the fold',
      );
    }

    // Das Poster bleibt sichtbar — es schrumpft, verschwindet aber nicht.
    final poster = tester.getRect(find.byType(Image).first);
    expect(poster.height, greaterThanOrEqualTo(96));
    expect(tester.takeException(), isNull);
  });

  testWidgets('large text keeps scroll reachability without shrinking below '
      'the small-format poster', (tester) async {
    await SceneAssetResolver.load();
    tester.view.physicalSize = const Size(393 * 3, 873 * 3);
    tester.view.devicePixelRatio = 3.0;
    await tester.binding.setSurfaceSize(const Size(393, 873));
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
      tester.binding.setSurfaceSize(null);
    });

    await _pumpSettled(tester, _host(textScale: 2.0));

    // Bei 200 % Text existiert weiter ein scrollbarer Weg zu jeder Option.
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('answer-3')),
      120,
      scrollable: find
          .ancestor(
            of: find.byKey(const ValueKey('quest-audio')),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    expect(find.byKey(const ValueKey('answer-3')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
