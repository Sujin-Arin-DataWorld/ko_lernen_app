import 'package:flutter/material.dart';

import 'package:ko_lernen_app/l10n/generated/app_localizations.dart';
import 'package:ko_lernen_app/screens/settings_screen.dart';
import 'package:ko_lernen_app/services/storage_service.dart';
import 'package:ko_lernen_app/theme.dart';
import 'package:ko_lernen_app/widgets/sori/approved_games/approved_game_material.dart';
import 'package:ko_lernen_app/widgets/sori/approved_games/approved_matching_view.dart';
import 'package:ko_lernen_app/widgets/sori/approved_games/approved_quiz_view.dart';
import 'package:ko_lernen_app/widgets/sori/route_observer.dart';

/// A standalone presentation review entry point, never imported by app main.
///
/// flutter run -t tool/visual_review/approved_game_gallery.dart
///   --dart-define=APPROVED_GAME_FIXTURE=0
///
/// Indices 0..2 are Quiz A/B/C; 3..5 are Matching A/B/C. These explicit
/// fixtures exercise production view widgets, not the grading/storage engine.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Storage.init();
  runApp(const ApprovedGameGalleryApp());
}

const approvedGameFixtureNames = [
  'quiz-a',
  'quiz-b',
  'quiz-c',
  'matching-a',
  'matching-b',
  'matching-c',
];

// Explicit line breaks below are copied from the six approved Figma text
// overrides solely for this comparison fixture. Production views do not import
// this file and never use per-word layout tables.
const _topics = ['Essen und Trinken', 'Wohnen', 'Technik und Verantwortung'];
const _quizKorean = ['커피', '원상복구', '책임을 시스템\n탓으로 돌리다'];
const _quizMeanings = [
  ['Brot', 'Kaffee', 'Wasser', 'Obst'],
  [
    'Eigentümergemeinschaft',
    'Mängelbeseitigung',
    'Wiederherstellung des\nursprünglichen Zustands',
    'Schlichtungsantrag',
  ],
  [
    'das Recht auf Widerruf\ngewährleisten',
    'Verantwortung auf das\nSystem schieben',
    'einen Entscheidungsprozess\nnachverfolgen',
    'Erklärbarkeit\nsicherstellen',
  ],
];
const _matchingKorean = [
  ['커피', '채소', '물', '과일', '빵', '고기'],
  ['하자 보수', '원상복구', '증거 사진', '관리단', '사용 제한', '조정 신청'],
  [
    '설명 가능성을\n확보하다',
    '책임을 시스템\n탓으로 돌리다',
    '철회할 권리를\n보장하다',
    '결정 과정을\n추적하다',
    '데이터의 출처를\n소명하다',
    '이의 제기 절차를\n마련하다',
  ],
];
const _matchingMeanings = [
  ['Obst', 'Wasser', 'Fleisch', 'Brot', 'Kaffee', 'Gemüse'],
  [
    'Nutzungsbeschränkung',
    'Beweisfoto',
    'Schlichtungsantrag',
    'Wiederherstellung des\nursprünglichen\nZustands',
    'Mängelbeseitigung',
    'Eigentümergemeinschaft',
  ],
  [
    'die Herkunft von\nDaten belegen',
    'das Recht auf\nWiderruf\ngewährleisten',
    'einen Entscheidungs-\nprozess\nnachverfolgen',
    'ein Einspruchs-\nverfahren\neinrichten',
    'Verantwortung auf\ndas System\nschieben',
    'Erklärbarkeit\nsicherstellen',
  ],
];

class ApprovedGameGalleryApp extends StatelessWidget {
  const ApprovedGameGalleryApp({
    super.key,
    this.fixture = const int.fromEnvironment('APPROVED_GAME_FIXTURE'),
    this.captureKey,
    this.normalizeCapture = false,
  }) : assert(fixture >= 0 && fixture < 6);

  final int fixture;
  final Key? captureKey;
  final bool normalizeCapture;

  @override
  Widget build(BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: AppTheme.light,
    locale: const Locale('de'),
    localizationsDelegates: AppL10n.localizationsDelegates,
    supportedLocales: AppL10n.supportedLocales,
    navigatorObservers: [soriRouteObserver],
    routes: {'/settings': (_) => const SettingsScreen()},
    builder: (context, child) {
      final media = MediaQuery.of(context);
      return MediaQuery(
        data: normalizeCapture
            ? media.copyWith(
                padding: EdgeInsets.zero,
                viewPadding: EdgeInsets.zero,
                viewInsets: EdgeInsets.zero,
                textScaler: TextScaler.noScaling,
                disableAnimations: true,
              )
            : media,
        child: RepaintBoundary(key: captureKey, child: child!),
      );
    },
    home: approvedGameFixtureWidget(fixture),
  );
}

/// Public fixture factory shared by native review and raster evidence capture.
Widget approvedGameFixtureWidget(int fixture) {
  if (fixture < 0 || fixture >= approvedGameFixtureNames.length) {
    throw RangeError.range(fixture, 0, 5, 'fixture');
  }
  final quiz = fixture < 3;
  final family = fixture % 3;
  final title = quiz ? 'Wörter-Quiz' : 'Paare finden';
  return ApprovedGameFrame(
    key: ValueKey(approvedGameFixtureNames[fixture]),
    title: title,
    navigationArt: fixture >= 3
        ? 'jade_geometric_legacy'
        : 'jade_organic_final',
    contentBuilder: (context, close) {
      void reviewAction() => ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Visuelle Prüfansicht. Hier wird kein Lernfortschritt gespeichert.',
          ),
        ),
      );
      if (quiz) {
        return ApprovedQuizView(
          title: title,
          topic: _topics[family],
          scoreLabel: '0 richtig',
          progressLabel: '1 von 6',
          question: 'Was bedeutet dieses Wort?',
          instruction: 'Wähle die Bedeutung.',
          korean: _quizKorean[family],
          options: _quizMeanings[family],
          correctOption: _quizMeanings[family][family == 1 ? 2 : 1],
          listenLabel: 'Anhören',
          correctFeedback: 'Richtig',
          wrongFeedback: 'Falsch',
          nextLabel: 'Weiter',
          leading: close,
          onOption: (_) => reviewAction(),
          onListen: reviewAction,
        );
      }
      return ApprovedMatchingView(
        title: title,
        topic: _topics[family],
        counter: '${family == 2 ? 1 : 0} von 6 Paaren',
        koreanLabel: 'Koreanisch',
        meaningLabel: 'Bedeutung',
        instruction: [
          'Tippe zuerst auf ein koreanisches Wort.',
          'Wähle jetzt die passende Bedeutung.',
          'Tippe auf ein koreanisches Wort.',
        ][family],
        footer: [
          'Erst Koreanisch, dann die Bedeutung.',
          'Tippe auf die passende Bedeutung.',
          'Ein Paar gefunden.',
        ][family],
        leading: close,
        leftTiles: [
          for (var i = 0; i < 6; i++)
            ApprovedMatchingTile(
              label: _matchingKorean[family][i],
              selected: family == 1 && i == 1,
              matched: family == 2 && i == 0,
              onTap: family == 2 && i == 0 ? null : reviewAction,
            ),
        ],
        rightTiles: [
          for (var i = 0; i < 6; i++)
            ApprovedMatchingTile(
              label: _matchingMeanings[family][i],
              matched: family == 2 && i == 5,
              onTap: family == 1 ? reviewAction : null,
            ),
        ],
      );
    },
  );
}
