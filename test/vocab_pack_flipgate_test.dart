import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ko_lernen_app/l10n/generated/app_localizations.dart';
import 'package:ko_lernen_app/models/vocab.dart';
import 'package:ko_lernen_app/models/vocab_pack.dart';
import 'package:ko_lernen_app/screens/vocab_pack_screen.dart';
import 'package:ko_lernen_app/services/storage_service.dart';
import 'package:ko_lernen_app/theme.dart';
import 'package:ko_lernen_app/widgets/sori/spotlight_coach.dart';

/// §P2-6 flipgate 센서: vocab_pack Learn — "앞면(미공개) 드래그 시 SRS·
/// wrongCount 0 + 진행 불변". 기존 3화면(review·custom·legacy)과 동형 —
/// **개편 1차부터 뚫려 있던 커버리지 구멍**을 닫는다.
///
/// `enabled: _learnCardRevealed` 배선 한 줄이 지워지면 빨개진다.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Vocab word(int n, String korean, {bool boss = false}) => Vocab(
    id: 'fg_v$n',
    korean: korean,
    romanization: 'r$n',
    german: 'GER-$n',
    level: 'A1',
    posDe: 'Nomen',
    exampleKorean: '$korean 예문',
    exampleGerman: 'Beispiel $n',
    topic: 'test',
    packId: 'a1_fg_1',
    packOrder: n,
    isReviewBoss: boss,
  );

  VocabPack pack() => VocabPack(
    id: 'a1_fg_1',
    level: 'A1',
    words: [word(1, '나무'), word(2, '바다'), word(3, '하늘', boss: true)],
  );

  setUp(() async {
    Storage.resetForTesting();
    SharedPreferences.setMockInitialValues({
      'kl_user_level': 'a1',
      'kl_streak_days': 0,
      'kl_xp': 0,
      // 코치 오버레이(AbsorbPointer)가 드래그를 삼켜 단언이 공허해지는 것 방지.
      'kl_tut_soriDeck': true,
      'kl_tut_wordbook': true,
    });
    await Storage.init();
    await Storage.setTutVocabPackSeen();
    await Storage.setTutPackQuizSeen();
    await Storage.setTutPackBossSeen();
  });

  Future<void> pump(WidgetTester tester) async {
    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        locale: const Locale('de'),
        supportedLocales: AppL10n.supportedLocales,
        localizationsDelegates: AppL10n.localizationsDelegates,
        home: MediaQuery(
          data: const MediaQueryData(
            size: Size(400, 800),
            disableAnimations: true,
          ),
          child: VocabPackScreen(
            packId: 'a1_fg_1',
            packLoader: (_) async => pack(),
            siblingPacksLoader: (_) async => [pack()],
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
  }

  testWidgets('앞면 우측 드래그 → SRS·wrongCount 0 + 진행 불변', (tester) async {
    await pump(tester);
    expect(find.text('나무'), findsOneWidget);
    expect(find.text('1 / 3'), findsOneWidget);

    await tester.drag(find.text('나무'), const Offset(220, 0));
    await tester.pumpAndSettle();

    expect(find.text('나무'), findsOneWidget, reason: '판정 없음 = 같은 카드');
    expect(find.text('1 / 3'), findsOneWidget);
    expect(Storage.srsCard('나무')?.reviewCount ?? 0, 0);
    expect(Storage.wrongCountOf('나무'), 0);
  });

  testWidgets('앞면 좌측 드래그 → SRS·wrongCount 0 + 진행 불변', (tester) async {
    await pump(tester);
    expect(find.text('나무'), findsOneWidget);

    await tester.drag(find.text('나무'), const Offset(-220, 0));
    await tester.pumpAndSettle();

    expect(find.text('나무'), findsOneWidget);
    expect(find.text('1 / 3'), findsOneWidget);
    expect(Storage.srsCard('나무')?.reviewCount ?? 0, 0);
    expect(Storage.wrongCountOf('나무'), 0);
  });

  testWidgets(
    'vocab coach queues wordbook spotlight and excludes deck spotlight',
    (tester) async {
      Storage.resetForTesting();
      SharedPreferences.setMockInitialValues({
        'kl_user_level': 'a1',
        'kl_streak_days': 0,
        'kl_xp': 0,
        'kl_tut_vocab_pack': false,
        'kl_tut_soriDeck': false,
        'kl_tut_wordbook': false,
      });
      await Storage.init();

      await pump(tester);

      expect(find.text('In 3 Schritten lernen'), findsOneWidget);
      expect(find.byKey(kSpotlightTooltipKey), findsNothing);
      expect(
        find.text(
          'Schritt 1 · Lernen: Karte antippen und umdrehen, dann wischen. '
          'Rechts = gewusst, links = nicht gewusst, hoch = merken, runter = '
          'überspringen',
        ),
        findsOneWidget,
      );

    await tester.tap(find.text('Alles klar!'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump();

      expect(find.text('Karte wischen'), findsNothing);
      expect(find.byKey(kSpotlightTooltipKey), findsOneWidget);
      expect(find.text('Wörter hier speichern'), findsOneWidget);
      expect(Storage.tutVocabPackSeen, isTrue);
      expect(Storage.tutSeen('soriDeck'), isFalse);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
}
