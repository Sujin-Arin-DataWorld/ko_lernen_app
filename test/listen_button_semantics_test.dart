import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ko_lernen_app/l10n/generated/app_localizations.dart';
import 'package:ko_lernen_app/models/vocab.dart';
import 'package:ko_lernen_app/models/vocab_pack.dart';
import 'package:ko_lernen_app/screens/custom_pack_play_screen.dart';
import 'package:ko_lernen_app/screens/vocab_pack_screen.dart';
import 'package:ko_lernen_app/services/storage_service.dart';
import 'package:ko_lernen_app/theme.dart';
import 'package:ko_lernen_app/widgets/sori/speakable.dart';

import 'support/sori_speech_stubs.dart';

/// PR4-T1 — 단어 카드 듣기 버튼 2곳(`custom_pack_play_screen.dart`,
/// `vocab_pack_screen.dart`)이 raw `IconButton` 대신
/// [SoriSpeechIndicator] 를 써서 (a) Semantics 라벨을 노출하고 (b) 탭하면
/// [SoriSpeech.speakImpl] 이 해당 한국어 문자열로 1회 불리는지 검증한다.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const customPackId = 'cp_listen_button_test';
  final customPackJson = jsonEncode({
    customPackId: {
      'name': 'Listen Button Test Pack',
      'sourcePageId': 'page_test',
      'createdAt': '2026-01-01T00:00:00.000Z',
      'words': [
        {
          'korean': '도서관',
          'romanization': 'doseogwan',
          'pos_de': 'N.',
          'translation_de': 'Bibliothek',
          'translation_en': 'Library',
          'example_korean': '도서관에 가다',
          'example_de': 'In die Bibliothek gehen',
          'definition_ko': '',
          'image_path': '',
          'saved_to_pack_id': null,
        },
      ],
    },
  });

  Vocab vocabWord() => Vocab(
    id: 'listen_v1',
    korean: '나무',
    romanization: 'namu',
    german: 'Baum',
    level: 'A1',
    posDe: 'Nomen',
    exampleKorean: '나무 예문',
    exampleGerman: 'Beispiel',
    topic: 'test',
    packId: 'a1_listen_1',
    packOrder: 1,
  );

  VocabPack vocabPack() =>
      VocabPack(id: 'a1_listen_1', level: 'A1', words: [vocabWord()]);

  Future<void> pumpAndSettleFrames(WidgetTester tester) async {
    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
  }

  group('CustomPackPlayScreen 듣기 버튼', () {
    setUp(() async {
      SharedPreferences.setMockInitialValues({
        'kl_user_level': 'a1',
        'kl_streak_days': 0,
        'kl_xp': 0,
        'kl_tut_cpPlay': true,
        'kl_tut_soriDeck': true,
        'kl_tut_wordbook': true,
        'kl_custom_packs_v1': customPackJson,
      });
      await Storage.init();
    });

    testWidgets('Semantics 라벨 노출 + 탭하면 speakImpl이 word.korean으로 1회 호출', (
      tester,
    ) async {
      final stub = stubSoriSpeech();
      final semantics = tester.ensureSemantics();

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
            child: const CustomPackPlayScreen(packId: customPackId),
          ),
        ),
      );
      await pumpAndSettleFrames(tester);

      final t = await AppL10n.delegate.load(const Locale('de'));
      final indicatorFinder = find.byWidgetPredicate(
        (w) => w is SoriSpeechIndicator && w.text == '도서관',
      );
      expect(
        indicatorFinder,
        findsOneWidget,
        reason: 'SoriSpeechIndicator(text: word.korean) 로 치환돼야 한다',
      );

      expect(
        find.bySemanticsLabel(t.speechIndicatorLabel),
        findsOneWidget,
        reason: '듣기 버튼에 Semantics 라벨이 있어야 한다',
      );

      await tester.tap(indicatorFinder);
      await tester.pump();

      expect(stub.spoken, ['도서관']);
      semantics.dispose();
    });
  });

  group('VocabPackScreen 듣기 버튼', () {
    setUp(() async {
      Storage.resetForTesting();
      SharedPreferences.setMockInitialValues({
        'kl_user_level': 'a1',
        'kl_streak_days': 0,
        'kl_xp': 0,
        'kl_tut_soriDeck': true,
        'kl_tut_wordbook': true,
      });
      await Storage.init();
      await Storage.setTutVocabPackSeen();
      await Storage.setTutPackQuizSeen();
      await Storage.setTutPackBossSeen();
    });

    testWidgets('Semantics 라벨 노출 + 탭하면 speakImpl이 v.korean으로 1회 호출', (
      tester,
    ) async {
      final stub = stubSoriSpeech();
      final semantics = tester.ensureSemantics();

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
              packId: 'a1_listen_1',
              packLoader: (_) async => vocabPack(),
              siblingPacksLoader: (_) async => [vocabPack()],
            ),
          ),
        ),
      );
      await pumpAndSettleFrames(tester);

      final t = await AppL10n.delegate.load(const Locale('de'));
      final indicatorFinder = find.byWidgetPredicate(
        (w) => w is SoriSpeechIndicator && w.text == '나무',
      );
      expect(
        indicatorFinder,
        findsOneWidget,
        reason: 'SoriSpeechIndicator(text: v.korean) 로 치환돼야 한다',
      );

      expect(
        find.bySemanticsLabel(t.speechIndicatorLabel),
        findsOneWidget,
        reason: '듣기 버튼에 Semantics 라벨이 있어야 한다',
      );

      await tester.tap(indicatorFinder);
      await tester.pump();

      expect(stub.spoken, ['나무']);
      semantics.dispose();
    });
  });
}
