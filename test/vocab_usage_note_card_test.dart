import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ko_lernen_app/l10n/generated/app_localizations.dart';
import 'package:ko_lernen_app/models/vocab.dart';
import 'package:ko_lernen_app/models/vocab_pack.dart';
import 'package:ko_lernen_app/screens/vocab_pack_screen.dart';
import 'package:ko_lernen_app/services/data_loader.dart';
import 'package:ko_lernen_app/services/storage_service.dart';
import 'package:ko_lernen_app/theme.dart';
import 'package:ko_lernen_app/widgets/flip_card.dart';
import 'package:ko_lernen_app/widgets/sori/pressable.dart';
import 'package:ko_lernen_app/widgets/sori/speakable.dart';

import 'support/sori_speech_stubs.dart';

/// C9-T0: card-back "쓰임" section (`_UsageNoteExpander` in
/// vocab_pack_screen.dart). Private classes cannot be imported directly, so
/// this drives the real [VocabPackScreen] end to end -- exactly how a
/// learner reaches the card -- and mocks only `usage_notes.json` (the one
/// asset this screen reads via [DataLoader] when no `courseContext` is
/// given; `packLoader`/`siblingPacksLoader` cover the rest).
const _noteWordId = 'test_b1_with_note';
const _noNoteWordId = 'test_a1_no_note';

Vocab _word({
  required String id,
  required String level,
  required String korean,
  required String german,
}) {
  return Vocab(
    id: id,
    korean: korean,
    romanization: korean,
    german: german,
    level: level,
    posDe: 'Nomen',
    exampleKorean: '$korean 예문이에요.',
    exampleGerman: '$german example.',
    topic: 'test',
    packId: '${level.toLowerCase()}_test_1',
    packOrder: 1,
  );
}

void _mockUsageNotesAsset() {
  final payload = jsonEncode({
    'schemaVersion': 1,
    'notes': [
      {
        'id': _noteWordId,
        'level': 'B1',
        'nuance': {
          'ko': '테스트 뉘앙스입니다.',
          'de': 'Test-Nuance auf Deutsch, die auch bei starker Textskalierung nicht überläuft.',
          'en': 'Test nuance in English, long enough to check wrapping under a large text scale.',
        },
        'situation': {
          'ko': '테스트 상황입니다.',
          'de': 'Test-Situation.',
          'en': 'Test situation.',
        },
        'patterns': [
          {'ko': '패턴 KO', 'de': 'Muster DE', 'en': 'pattern EN'},
        ],
        'collocations': [
          {'ko': '연어1', 'de': 'Kollokation1', 'en': 'collocation1'},
          {'ko': '연어2', 'de': 'Kollokation2', 'en': 'collocation2'},
        ],
        'contrasts': [
          {
            'headword': '대조어',
            'vocabId': null,
            'ko': '대조 설명 KO',
            'de': 'Kontrast DE',
            'en': 'contrast EN',
          },
        ],
        'register': 'neutral',
        'examples': [
          {
            'ko': '예문 하나 KO',
            'de': 'Beispiel eins DE',
            'en': 'example one EN',
            'register': 'formal',
          },
          {
            'ko': '예문 둘 KO',
            'de': 'Beispiel zwei DE',
            'en': 'example two EN',
            'register': 'casual',
          },
        ],
      },
    ],
  });
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMessageHandler('flutter/assets', (message) async {
        final asset = const StringCodec().decodeMessage(message);
        if (asset != 'assets/data/usage_notes.json') {
          return null;
        }
        return ByteData.sublistView(Uint8List.fromList(utf8.encode(payload)));
      });
}

Widget _app(Widget home, {Locale locale = const Locale('de')}) {
  return MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: AppTheme.light,
    locale: locale,
    supportedLocales: AppL10n.supportedLocales,
    localizationsDelegates: AppL10n.localizationsDelegates,
    home: home,
  );
}

Future<void> _flipToBack(WidgetTester tester) async {
  tester.widget<FlipCard>(find.byType(FlipCard)).onTap!();
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
}

/// Invokes the "쓰임" header's onTap directly via its test key rather than
/// hit-testing a screen coordinate -- at 1.6x text scale (and in general,
/// same precedent as vocab_pack_flip_spoiler_test.dart's `FlipCard.onTap!()`
/// call) the taller card can shift other on-screen controls under the tap
/// point, so this avoids depending on exact layout geometry.
Future<void> _expandUsageNoteSection(WidgetTester tester) async {
  tester
      .widget<SoriPressable>(
        find.byKey(const ValueKey('usageNoteHeaderToggle')),
      )
      .onTap!();
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 200));
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    stubSoriSpeech();
    Storage.resetForTesting();
    SharedPreferences.setMockInitialValues({});
    await Storage.init();
    await Storage.setTutVocabPackSeen();
    DataLoader.reset();
    _mockUsageNotesAsset();
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMessageHandler('flutter/assets', null);
    DataLoader.reset();
  });

  testWidgets(
    'B1 word with a note shows a collapsed 쓰임 section that expands to '
    'nuance/patterns/collocations/contrast/examples with play buttons',
    (tester) async {
      final word = _word(
        id: _noteWordId,
        level: 'B1',
        korean: '테스트단어',
        german: 'Testwort',
      );
      final pack = VocabPack(id: 'b1_test_1', level: 'B1', words: [word]);

      await tester.pumpWidget(
        _app(
          VocabPackScreen(
            packId: pack.id,
            packLoader: (_) async => pack,
            siblingPacksLoader: (_) async => [pack],
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      // 비동기 usage-note 로드가 setState 로 반영될 시간을 준다.
      await tester.pump();
      await tester.pump();

      await _flipToBack(tester);

      final t = await AppL10n.delegate.load(const Locale('de'));
      // 접힌 기본 상태: 헤더는 보이지만 본문/재생 버튼은 아직 없다.
      expect(find.text(t.usageNoteTitle), findsOneWidget);
      expect(find.byType(SoriSpeechIndicator), findsNothing);
      expect(find.text(t.usageNoteExamples), findsNothing);

      await _expandUsageNoteSection(tester);

      expect(find.text(t.usageNoteNuance), findsNothing); // no-label body text
      expect(find.textContaining('Test-Nuance auf Deutsch'), findsOneWidget);
      expect(find.text(t.usageNoteSituation), findsOneWidget);
      expect(find.text(t.usageNotePatterns), findsOneWidget);
      expect(find.text(t.usageNoteCollocations), findsOneWidget);
      expect(find.textContaining(t.usageNoteContrast), findsOneWidget);
      expect(find.text(t.usageNoteExamples), findsOneWidget);
      expect(find.text('예문 하나 KO'), findsOneWidget);
      expect(find.text('예문 둘 KO'), findsOneWidget);
      // 예문마다 재생 버튼 1개 (기존 example-audio 위젯 재사용).
      expect(find.byType(SoriSpeechIndicator), findsNWidgets(2));
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('A1 word without a note leaves the card back unchanged', (
    tester,
  ) async {
    final word = _word(
      id: _noNoteWordId,
      level: 'A1',
      korean: '기본단어',
      german: 'Grundwort',
    );
    final pack = VocabPack(id: 'a1_test_1', level: 'A1', words: [word]);

    await tester.pumpWidget(
      _app(
        VocabPackScreen(
          packId: pack.id,
          packLoader: (_) async => pack,
          siblingPacksLoader: (_) async => [pack],
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump();
    await tester.pump();

    await _flipToBack(tester);

    final t = await AppL10n.delegate.load(const Locale('de'));
    expect(find.text('Grundwort'), findsOneWidget);
    expect(find.text(t.usageNoteTitle), findsNothing);
    expect(find.byType(SoriSpeechIndicator), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('usage note labels come from ARB (DE/EN) and read correctly', (
    tester,
  ) async {
    final word = _word(
      id: _noteWordId,
      level: 'B1',
      korean: '테스트단어',
      german: 'Testwort',
    );
    final pack = VocabPack(id: 'b1_test_1', level: 'B1', words: [word]);

    await tester.pumpWidget(
      _app(
        VocabPackScreen(
          packId: pack.id,
          packLoader: (_) async => pack,
          siblingPacksLoader: (_) async => [pack],
        ),
        locale: const Locale('en'),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump();
    await tester.pump();

    await _flipToBack(tester);

    final t = await AppL10n.delegate.load(const Locale('en'));
    expect(t.usageNoteTitle, 'Usage');
    expect(find.text('Usage'), findsOneWidget);
    await _expandUsageNoteSection(tester);
    expect(find.text(t.usageNoteExamples), findsOneWidget);
    expect(find.textContaining('example one EN'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('usage note section survives 1.6x text scale with no overflow', (
    tester,
  ) async {
    final word = _word(
      id: _noteWordId,
      level: 'B1',
      korean: '테스트단어',
      german: 'Testwort',
    );
    final pack = VocabPack(id: 'b1_test_1', level: 'B1', words: [word]);

    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(textScaler: TextScaler.linear(1.6)),
        child: _app(
          VocabPackScreen(
            packId: pack.id,
            packLoader: (_) async => pack,
            siblingPacksLoader: (_) async => [pack],
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump();
    await tester.pump();

    await _flipToBack(tester);

    final t = await AppL10n.delegate.load(const Locale('de'));
    await _expandUsageNoteSection(tester);

    expect(find.text(t.usageNoteExamples), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
