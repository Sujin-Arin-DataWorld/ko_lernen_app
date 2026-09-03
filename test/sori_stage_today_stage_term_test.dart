import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ko_lernen_app/l10n/generated/app_localizations.dart';
import 'package:ko_lernen_app/models/cultural_glossary.dart';
import 'package:ko_lernen_app/models/personal_hanok.dart';
import 'package:ko_lernen_app/models/sori_stage_progression.dart';
import 'package:ko_lernen_app/screens/sori_stage/sori_stage_today_screen.dart';
import 'package:ko_lernen_app/services/cultural_glossary_repository.dart';
import 'package:ko_lernen_app/services/hanok_stage_service.dart';
import 'package:ko_lernen_app/services/mission_recommender.dart';
import 'package:ko_lernen_app/services/today_learning_snapshot.dart';
import 'package:ko_lernen_app/theme.dart';
import 'package:ko_lernen_app/widgets/sori/sori_term.dart';

/// §COPY-2/§COPY-3(J8) — Today's `_HanokProgress` next-piece line renders a
/// tappable [SoriTerm] (`hanokStageGlossaryTermId`) when the current
/// structure stage is `sideBuilding` (사랑채). This exercises the full
/// stack: the mapping helper -> a real glossary entry -> the sheet.
void main() {
  late CulturalGlossary catalog;

  setUpAll(() async {
    catalog = CulturalGlossary.fromJsonString(
      await File(CulturalGlossaryRepository.assetPath).readAsString(),
    );
  });

  setUp(() {
    CulturalGlossaryRepository.setLoaderForTesting(() async => catalog);
  });

  tearDown(() {
    CulturalGlossaryRepository.resetForTesting();
  });

  testWidgets(
    'sideBuilding stage renders a SoriTerm(sarangchae) that opens the '
    'glossary sheet on tap',
    (tester) async {
      final semantics = tester.ensureSemantics();
      tester.view.physicalSize = const Size(390, 2400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          locale: const Locale('de'),
          supportedLocales: AppL10n.supportedLocales,
          localizationsDelegates: AppL10n.localizationsDelegates,
          home: MediaQuery(
            data: const MediaQueryData(disableAnimations: true),
            child: SoriStageTodayScreen(
              loadSnapshot: () async => _snapshot(),
              now: () => DateTime(2026, 8, 14, 9),
            ),
          ),
          onGenerateRoute: (_) => MaterialPageRoute<void>(
            builder: (_) => const Scaffold(body: Text('route')),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      final term = find.byWidgetPredicate(
        (widget) => widget is SoriTerm && widget.termId == 'sarangchae',
      );
      expect(term, findsOneWidget);

      await tester.tap(term);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('사랑채'), findsOneWidget);
      semantics.dispose();
    },
  );
}

SoriStageProgressionSnapshot _snapshot() => SoriStageProgressionSnapshot(
  today: const TodayLearningSnapshot(
    pick: ReviewPick(dueCount: 12),
    destination: TodayLearningDestination(route: '/review'),
    dueCount: 12,
  ),
  // a1/a2/b1 완료 + b2 < 50% → computeStage 는 HanokStage.sideBuilding
  // (hanok_stage.dart:94) — hanokStageTerm 이 hanokStageDisplayName 과
  // 달라지는 세 단계 중 하나(hanok_stage_names.dart 주석).
  hanok: PersonalHanokProjection.from(
    const LevelRatios(a1: 1, a2: 1, b1: 1, b2: 0.2),
  ),
  quests: const [],
  pendingBojagiCount: 0,
  stampCount: 0,
  xp: 0,
  streakDays: 0,
  todayReward: null,
);
