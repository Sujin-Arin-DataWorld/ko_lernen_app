import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ko_lernen_app/l10n/generated/app_localizations.dart';
import 'package:ko_lernen_app/models/vocab.dart';
import 'package:ko_lernen_app/models/vocab_pack.dart';
import 'package:ko_lernen_app/screens/vocab_pack_screen.dart';
import 'package:ko_lernen_app/services/storage_service.dart';
import 'package:ko_lernen_app/theme.dart';
import 'package:ko_lernen_app/widgets/sori/deck_action_bar.dart';
import 'package:ko_lernen_app/widgets/sori/sori_deck_coach.dart';

Vocab _word(int n) => Vocab(
  id: 'fg_v$n',
  korean: '게이트$n',
  romanization: 'gate$n',
  german: 'Gate-$n',
  level: 'A1',
  posDe: 'Nomen',
  exampleKorean: '',
  exampleGerman: '',
  topic: 'test',
  packId: 'a1_fg_1',
  packOrder: n,
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    Storage.resetForTesting();
    SharedPreferences.setMockInitialValues({});
    await Storage.init();
    await Storage.setTutVocabPackSeen();
    await Storage.setTutSeen('soriDeck');
    resetSoriDeckCoachSessionForTest();
  });

  Future<void> pump(WidgetTester tester) async {
    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final pack = VocabPack(
      id: 'a1_fg_1',
      level: 'A1',
      words: [_word(1), _word(2), _word(3)],
    );
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
            packId: pack.id,
            packLoader: (_) async => pack,
            siblingPacksLoader: (_) async => [pack],
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
  }

  testWidgets('앞면 우측 드래그 → SRS·wrongCount 0 + 진행 불변', (tester) async {
    await pump(tester);
    expect(find.text('게이트1'), findsOneWidget);
    expect(find.text('1 / 3'), findsOneWidget);

    await tester.drag(
      find.text('게이트1'),
      const Offset(220, 0),
      warnIfMissed: false,
    );
    await tester.pumpAndSettle();

    expect(Storage.srsCard('게이트1')?.reviewCount, isNull);
    expect(Storage.wrongCountOf('게이트1'), 0);
    expect(find.text('게이트1'), findsOneWidget);
    expect(find.text('1 / 3'), findsOneWidget);
  });

  testWidgets('앞면 좌측 드래그 → SRS·wrongCount 0 + 진행 불변', (tester) async {
    await pump(tester);
    expect(find.text('게이트1'), findsOneWidget);

    await tester.drag(
      find.text('게이트1'),
      const Offset(-220, 0),
      warnIfMissed: false,
    );
    await tester.pumpAndSettle();

    expect(Storage.srsCard('게이트1')?.reviewCount, isNull);
    expect(Storage.wrongCountOf('게이트1'), 0);
    expect(find.text('게이트1'), findsOneWidget);
    expect(find.text('1 / 3'), findsOneWidget);
  });

  testWidgets('앞면 앎 버튼 탭 → SRS 0 (버튼 flipgate)', (tester) async {
    await pump(tester);
    tester.widget<DeckActionBar>(find.byType(DeckActionBar)).onKnow();
    await tester.pumpAndSettle();
    expect(Storage.srsCard('게이트1')?.reviewCount, isNull);
    expect(find.text('게이트1'), findsOneWidget);
    expect(
      tester.widget<DeckActionBar>(find.byType(DeckActionBar)).judgmentEnabled,
      isFalse,
    );
  });
}
