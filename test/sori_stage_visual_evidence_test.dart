import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show FontLoader;
import 'package:flutter_test/flutter_test.dart';
import 'package:ko_lernen_app/l10n/generated/app_localizations.dart';
import 'package:ko_lernen_app/models/personal_hanok.dart';
import 'package:ko_lernen_app/models/sori_stage_progression.dart';
import 'package:ko_lernen_app/screens/sori_stage/sori_stage_catalog_screen.dart';
import 'package:ko_lernen_app/screens/sori_stage/sori_stage_today_screen.dart';
import 'package:ko_lernen_app/services/hanok_stage_service.dart';
import 'package:ko_lernen_app/services/mission_recommender.dart';
import 'package:ko_lernen_app/services/today_learning_snapshot.dart';
import 'package:ko_lernen_app/theme.dart';

const _captureEvidence = bool.fromEnvironment('CAPTURE_SORI_STAGE_EVIDENCE');

void main() {
  setUpAll(_loadRealFonts);

  testWidgets('capture Today at 390dp', skip: !_captureEvidence, (
    tester,
  ) async {
    _setViewport(tester, const Size(390, 844));
    await tester.pumpWidget(
      _app(
        locale: const Locale('en'),
        home: SoriStageTodayScreen(loadSnapshot: () async => _snapshot()),
      ),
    );
    await tester.pumpAndSettle();

    await expectLater(
      find.byType(SoriStageTodayScreen),
      matchesGoldenFile('../docs/screenshots/sori-stage-today-390.png'),
    );
  });

  testWidgets('capture Learn at 1280dp', skip: !_captureEvidence, (
    tester,
  ) async {
    _setViewport(tester, const Size(1280, 900));
    await tester.pumpWidget(
      _app(
        locale: const Locale('de'),
        home: const SoriStageCatalogScreen(tab: SoriStageTab.learn),
      ),
    );
    await tester.pumpAndSettle();

    await expectLater(
      find.byType(SoriStageCatalogScreen),
      matchesGoldenFile('../docs/screenshots/sori-stage-learn-1280.png'),
    );
  });
}

Future<void> _loadRealFonts() async {
  final loader = FontLoader('Pretendard');
  for (final path in const <String>[
    'assets/fonts/Pretendard/PretendardStd-Regular.otf',
    'assets/fonts/Pretendard/PretendardStd-Medium.otf',
    'assets/fonts/Pretendard/PretendardStd-SemiBold.otf',
    'assets/fonts/Pretendard/PretendardStd-Bold.otf',
    'assets/fonts/Pretendard/PretendardStd-ExtraBold.otf',
  ]) {
    final bytes = File(path).readAsBytesSync();
    loader.addFont(Future<ByteData>.value(ByteData.view(bytes.buffer)));
  }
  await loader.load();

  var flutterRoot = File(Platform.resolvedExecutable).parent;
  File materialPath;
  while (true) {
    materialPath = File(
      '${flutterRoot.path}/bin/cache/artifacts/material_fonts/'
      'materialicons-regular.otf',
    );
    if (materialPath.existsSync()) break;
    final parent = flutterRoot.parent;
    if (parent.path == flutterRoot.path) {
      throw StateError('Flutter Material Icons font was not found.');
    }
    flutterRoot = parent;
  }
  final materialBytes = materialPath.readAsBytesSync();
  await (FontLoader('MaterialIcons')
        ..addFont(Future<ByteData>.value(ByteData.view(materialBytes.buffer))))
      .load();
}

SoriStageProgressionSnapshot _snapshot() => SoriStageProgressionSnapshot(
  today: const TodayLearningSnapshot(
    pick: ReviewPick(dueCount: 12),
    destination: TodayLearningDestination(route: '/review'),
    dueCount: 12,
  ),
  hanok: PersonalHanokProjection.from(
    const LevelRatios(a1: 1, a2: 1, b1: .5, b2: 0),
  ),
  quests: const [],
  pendingBojagiCount: 1,
  stampCount: 4,
  xp: 320,
  streakDays: 6,
  todayReward: const RewardContract(
    activityId: 'srs',
    condition: SoriLocalizedCopy(
      de: 'Wenn du die Runde abschließt',
      en: 'When you finish the session',
    ),
    items: <RewardContractItem>[
      RewardContractItem(
        kind: SoriRewardKind.xp,
        amount: 15,
        label: SoriLocalizedCopy(de: 'Lern-XP', en: 'Learning XP'),
      ),
      RewardContractItem(
        kind: SoriRewardKind.questProgress,
        label: SoriLocalizedCopy(de: 'Passende Quest', en: 'Related quest'),
      ),
    ],
  ),
);

Widget _app({required Locale locale, required Widget home}) => MaterialApp(
  debugShowCheckedModeBanner: false,
  theme: AppTheme.light,
  locale: locale,
  supportedLocales: AppL10n.supportedLocales,
  localizationsDelegates: AppL10n.localizationsDelegates,
  home: MediaQuery(
    data: const MediaQueryData(disableAnimations: true),
    child: home,
  ),
  onGenerateRoute: (_) => MaterialPageRoute<void>(
    builder: (_) => const Scaffold(body: Text('route')),
  ),
);

void _setViewport(WidgetTester tester, Size size) {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}
