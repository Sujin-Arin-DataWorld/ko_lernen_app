import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ko_lernen_app/l10n/generated/app_localizations.dart';
import 'package:ko_lernen_app/models/sori_stage_progression.dart';
import 'package:ko_lernen_app/screens/sori_stage/sori_stage_today_screen.dart';
import 'package:ko_lernen_app/services/mission_recommender.dart';
import 'package:ko_lernen_app/services/storage_service.dart';
import 'package:ko_lernen_app/services/today_learning_snapshot.dart';
import 'package:ko_lernen_app/theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/c_fonts.dart';
import 'support/hanok_competence_fixture.dart';
import 'support/real_fonts.dart';

void main() {
  setUpAll(() async {
    await loadSoriRealFonts();
    await loadCFonts();
  });
  setUp(() async {
    Storage.resetForTesting();
    SharedPreferences.setMockInitialValues({
      'kl_user_level': 'a1',
      'kl_tut_home_tour': true,
      'kl_reduced_motion': true,
    });
    await Storage.init();
  });

  for (final locale in [const Locale('de'), const Locale('en')]) {
    for (final viewport in [
      (width: 390.0, scale: 1.0),
      (width: 390.0, scale: 2.0),
      (width: 320.0, scale: 2.0),
    ]) {
      testWidgets('${locale.languageCode} Hanok progress keeps whole words at '
          '${viewport.width}dp ${viewport.scale * 100}%', (tester) async {
        tester.view.physicalSize = Size(viewport.width, 2400);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final snapshot = SoriStageProgressionSnapshot(
          today: const TodayLearningSnapshot(
            pick: ReviewPick(dueCount: 1),
            destination: TodayLearningDestination(route: '/review'),
            dueCount: 1,
          ),
          hanokCompetence: hanokCompetenceFixture(),
          quests: const [],
          pendingBojagiCount: 0,
          stampCount: 0,
          xp: 0,
          streakDays: 0,
          todayReward: null,
        );
        String? openedRoute;
        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.light,
            locale: locale,
            supportedLocales: AppL10n.supportedLocales,
            localizationsDelegates: AppL10n.localizationsDelegates,
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context).copyWith(
                disableAnimations: true,
                textScaler: TextScaler.linear(viewport.scale),
              ),
              child: child!,
            ),
            home: SoriStageTodayScreen(
              loadSnapshot: () async => snapshot,
              forceStaticHero: true,
            ),
            onGenerateRoute: (settings) {
              openedRoute = settings.name;
              return MaterialPageRoute<void>(
                builder: (_) => const Scaffold(body: Text('Destination')),
              );
            },
          ),
        );
        await tester.pumpAndSettle();
        final summary = find.byKey(const ValueKey('today-hanok-summary'));
        await tester.ensureVisible(summary);
        await tester.pumpAndSettle();

        final progress = find.byKey(
          const ValueKey('today-hanok-progress-text'),
        );
        final paragraph = tester.renderObject<RenderParagraph>(progress);
        final text = tester.widget<Text>(progress).data!;
        final t = await AppL10n.delegate.load(locale);
        expect(text, t.sarangchaeConstructionProgress(0, 16));
        for (final word in RegExp(r'\S+').allMatches(text)) {
          final boxes = paragraph.getBoxesForSelection(
            TextSelection(baseOffset: word.start, extentOffset: word.end),
          );
          expect(
            boxes,
            hasLength(1),
            reason: '${word.group(0)} must not split inside the word',
          );
        }
        expect(tester.getSize(summary).height, greaterThanOrEqualTo(48));
        expect(tester.takeException(), isNull);
        await tester.tap(summary);
        await tester.pumpAndSettle();
        expect(openedRoute, '/hanok');
        expect(Storage.xp, 0);
        expect(Storage.pendingBoxes, isEmpty);
      });
    }
  }
}
