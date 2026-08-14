import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ko_lernen_app/l10n/generated/app_localizations.dart';
import 'package:ko_lernen_app/models/vocab.dart';
import 'package:ko_lernen_app/models/vocab_pack.dart';
import 'package:ko_lernen_app/screens/vocab_pack_screen.dart';
import 'package:ko_lernen_app/services/storage_service.dart';
import 'package:ko_lernen_app/theme.dart';

Vocab _v(int n, String ko, String de) => Vocab(
  id: 'fg_v$n',
  korean: ko,
  romanization: 'r$n',
  german: de,
  level: 'A1',
  posDe: 'Nomen',
  exampleKorean: '$ko 예문.',
  exampleGerman: 'Beispiel $de.',
  topic: 'fg',
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
    await Storage.setTutPackQuizSeen();
    await Storage.setTutPackBossSeen();
  });

  group('VocabPackScreen FlipGate Sensor', () {
    testWidgets('front horizontal left/right drag does not record SRS or wrongCount', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1170, 2532);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final pack = VocabPack(
        id: 'a1_fg_1',
        level: 'A1',
        words: [_v(1, '단어1', 'Wort1'), _v(2, '단어2', 'Wort2')],
      );

      await tester.pumpWidget(
        MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light,
          locale: const Locale('de'),
          supportedLocales: AppL10n.supportedLocales,
          localizationsDelegates: AppL10n.localizationsDelegates,
          home: VocabPackScreen(
            packId: pack.id,
            packLoader: (_) async => pack,
            siblingPacksLoader: (_) async => [pack],
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Attempt left swipe on front face
      await tester.drag(find.text('단어1'), const Offset(-220, 0));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(Storage.srsReviews['단어1'], isNull, reason: '앞면 좌측 스와이프는 SRS 기록 없음');
      expect(Storage.wrongCount('단어1'), 0, reason: '앞면 좌측 스와이프는 wrongCount 없음');
      expect(find.text('단어1'), findsOneWidget, reason: '카드가 넘어가지 않음');

      // Attempt right swipe on front face
      await tester.drag(find.text('단어1'), const Offset(220, 0));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(Storage.srsReviews['단어1'], isNull, reason: '앞면 우측 스와이프는 SRS 기록 없음');
      expect(find.text('단어1'), findsOneWidget, reason: '카드가 넘어가지 않음');
    });
  });
}
