import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ko_lernen_app/l10n/generated/app_localizations.dart';
import 'package:ko_lernen_app/models/book_page.dart';
import 'package:ko_lernen_app/models/custom_pack.dart';
import 'package:ko_lernen_app/screens/custom_pack_quiz_screen.dart';
import 'package:ko_lernen_app/services/custom_pack_service.dart';
import 'package:ko_lernen_app/services/sound_service.dart';
import 'package:ko_lernen_app/services/storage_service.dart';
import 'package:ko_lernen_app/widgets/sori/approved_games/approved_quiz_view.dart';
import 'package:ko_lernen_app/widgets/sori/route_observer.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() async {
    Storage.resetForTesting();
    SharedPreferences.setMockInitialValues({'kl_tut_cpQuiz': true});
    SoundService.playImpl = (_) {};
    await Storage.init();
    await CustomPackService.save(
      CustomPack.manual(
        id: 'quiz-lifecycle',
        name: 'Words',
        words: [
          for (final pair in [
            ('커피', 'Coffee'),
            ('빵', 'Bread'),
            ('물', 'Water'),
            ('차', 'Tea'),
          ])
            ExtractedWord(
              korean: pair.$1,
              translationDe: pair.$2,
              translationEn: pair.$2,
              romanization: '',
              posDe: 'Nomen',
              exampleKorean: '',
              exampleDe: '',
              savedToPackId: null,
            ),
        ],
      ),
    );
  });
  tearDown(() {
    SoundService.resetForTesting();
    Storage.resetForTesting();
  });

  for (final cover in [false, true]) {
    testWidgets(
      '900ms advancement pauses during ${cover ? 'covered route' : 'background'}',
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(402, 874));
        addTearDown(() => tester.binding.setSurfaceSize(null));
        final navigator = GlobalKey<NavigatorState>();
        await tester.pumpWidget(
          MaterialApp(
            navigatorKey: navigator,
            navigatorObservers: [soriRouteObserver],
            locale: const Locale('en'),
            localizationsDelegates: AppL10n.localizationsDelegates,
            supportedLocales: AppL10n.supportedLocales,
            home: const CustomPackQuizScreen(packId: 'quiz-lifecycle'),
          ),
        );
        await tester.pumpAndSettle();
        final initial = tester.widget<ApprovedQuizView>(
          find.byType(ApprovedQuizView),
        );
        initial.onOption(initial.correctOption);
        for (var i = 0; i < 30; i++) {
          await tester.pump();
          final views = find.byType(ApprovedQuizView).evaluate();
          if (views.isNotEmpty &&
              (views.single.widget as ApprovedQuizView).picked != null) {
            break;
          }
        }
        expect(
          tester.widget<ApprovedQuizView>(find.byType(ApprovedQuizView)).picked,
          initial.correctOption,
        );
        final reviewCount = Storage.srsCard(initial.korean)!.reviewCount;
        if (cover) {
          unawaited(
            navigator.currentState!.push(
              MaterialPageRoute<void>(
                builder: (_) => const Scaffold(body: Text('Covered')),
              ),
            ),
          );
          await tester.pump();
        } else {
          tester.binding.handleAppLifecycleStateChanged(
            AppLifecycleState.paused,
          );
        }
        await tester.pump(const Duration(seconds: 2));
        final retained = tester.widget<ApprovedQuizView>(
          find.byType(ApprovedQuizView, skipOffstage: false),
        );
        expect(retained.korean, initial.korean);
        expect(retained.picked, initial.correctOption);
        if (cover) {
          navigator.currentState!.pop();
        } else {
          tester.binding.handleAppLifecycleStateChanged(
            AppLifecycleState.resumed,
          );
        }
        await tester.pump(const Duration(milliseconds: 901));
        await tester.pump();
        expect(
          tester
              .widget<ApprovedQuizView>(find.byType(ApprovedQuizView))
              .progressLabel,
          '2 of 4',
        );
        expect(Storage.srsCard(initial.korean)!.reviewCount, reviewCount);
        expect(tester.takeException(), isNull);
      },
    );
  }
}
