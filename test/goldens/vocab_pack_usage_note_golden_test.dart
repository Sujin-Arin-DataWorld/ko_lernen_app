import 'dart:convert';
import 'dart:io';

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

import '../support/sori_speech_stubs.dart';

/// C9-T0 (D-5 shell freeze exception, card BACK only): golden for the
/// expanded "쓰임" (usage note) section on a B1 flip card back at
/// compact/medium -- the two breakpoints where the flip card grid column
/// count changes (`screen_layout_golden_test.dart`'s convention). `expanded`
/// (tablet landscape) is intentionally not added: the flip card's own width
/// is already capped well under that viewport, so it renders identically to
/// medium and would just double the baseline-maintenance cost for no signal.
///
/// See `screen_layout_golden_test.dart`'s header for the regeneration
/// procedure (Linux/CI baselines only): Actions -> CI -> Run workflow ->
/// task=regenerate-goldens -> download the `goldens-linux-3-44-0` artifact
/// -> commit into `test/goldens/baselines/`.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final baselines = Directory('test/goldens/baselines');
  final ready =
      autoUpdateGoldenFiles ||
      (baselines.existsSync() && baselines.listSync().isNotEmpty);

  const wordId = 'golden_b1_usage_note';
  final word = Vocab(
    id: wordId,
    korean: '협조',
    romanization: 'hyeopjo',
    german: 'Mitwirkung, Kooperation',
    level: 'B1',
    posDe: 'Nomen',
    exampleKorean: '일정 조정에 협조해 주셔서 감사합니다.',
    exampleGerman: 'Danke, dass Sie bei der Terminanpassung mitgewirkt haben.',
    topic: 'work',
    packId: 'b1_golden_1',
    packOrder: 1,
  );
  final pack = VocabPack(id: 'b1_golden_1', level: 'B1', words: [word]);

  final usageNotesPayload = jsonEncode({
    'schemaVersion': 1,
    'notes': [
      {
        'id': wordId,
        'level': 'B1',
        'nuance': {
          'ko': '협조는 상대방에게 도움이나 협력을 정중하게 요청할 때 쓰는 격식 있는 말이다.',
          'de':
              '협조 ist ein formelles Wort, mit dem man jemanden höflich um Unterstützung oder Mitwirkung bittet.',
          'en':
              '협조 is a formal word used to politely request someone\'s help or cooperation.',
        },
        'situation': {
          'ko': '공지문이나 업무 메일에서 상대에게 정해진 절차를 따라 달라고 정중히 부탁할 때 쓴다.',
          'de':
              'Man findet es in Ankündigungen oder Arbeits-E-Mails, wenn man höflich bittet, ein festgelegtes Verfahren einzuhalten.',
          'en':
              'You find it in notices or work emails when politely asking someone to follow a set procedure.',
        },
        'patterns': [
          {
            'ko': 'N에 협조해 주시기 바랍니다',
            'de': 'um Mitwirkung bei etwas bitten',
            'en': 'to kindly ask for cooperation with something',
          },
        ],
        'collocations': [
          {'ko': '협조 요청', 'de': 'Bitte um Mitwirkung', 'en': 'request for cooperation'},
          {'ko': '적극적인 협조', 'de': 'aktive Mitwirkung', 'en': 'active cooperation'},
        ],
        'contrasts': [
          {
            'headword': '협업',
            'vocabId': null,
            'ko': '협조는 정해진 절차를 따라 달라는 정중한 요청에 가깝고, 협업은 여러 사람이 대등하게 함께 작업하는 것을 가리킨다.',
            'de':
                '협조 ist eher die höfliche Bitte, ein Verfahren einzuhalten, 협업 meint, dass mehrere Personen gleichberechtigt gemeinsam arbeiten.',
            'en':
                '협조 is closer to a polite request to follow a procedure, while 협업 refers to several people working together as equals.',
          },
        ],
        'register': 'formal',
        'examples': [
          {
            'ko': '일정 조정에 협조해 주시면 감사하겠습니다.',
            'de': 'Ich wäre dankbar, wenn Sie bei der Terminanpassung mitwirken könnten.',
            'en': 'I would appreciate your cooperation with adjusting the schedule.',
            'register': 'written',
          },
          {
            'ko': '이번 일은 다들 조금씩 협조해 줬으면 좋겠어.',
            'de': 'Ich hoffe, dass diesmal alle ein bisschen mitwirken.',
            'en': 'I hope everyone will pitch in a little on this one.',
            'register': 'casual',
          },
        ],
      },
    ],
  });

  setUp(() async {
    stubSoriSpeech();
    Storage.resetForTesting();
    SharedPreferences.setMockInitialValues({});
    await Storage.init();
    await Storage.setTutVocabPackSeen();
    DataLoader.reset();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMessageHandler('flutter/assets', (message) async {
          final asset = const StringCodec().decodeMessage(message);
          if (asset != 'assets/data/usage_notes.json') {
            return null;
          }
          return ByteData.sublistView(
            Uint8List.fromList(utf8.encode(usageNotesPayload)),
          );
        });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMessageHandler('flutter/assets', null);
    DataLoader.reset();
  });

  group(
    'B1 카드 뒷면 "쓰임" 구획 골든 (compact · medium)',
    skip: !ready
        ? '기준 없음 — flutter test --update-goldens test/goldens 로 1회 생성'
        : (!autoUpdateGoldenFiles && !Platform.isLinux)
        ? 'golden 기준선은 Linux(CI) 정본 — 로컬(Windows/macOS)에선 skip'
        : null,
    () {
      final viewports = <String, Size>{
        'compact': const Size(360, 800),
        'medium': const Size(800, 1280),
      };

      for (final viewport in viewports.entries) {
        testWidgets('vocab pack B1 back @ ${viewport.key}', (tester) async {
          tester.view.physicalSize = viewport.value;
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
              home: VocabPackScreen(
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

          // 카드 뒷면으로 뒤집는다 (좌표 의존 없이 콜백 직접 호출 — 다른
          // vocab_pack 테스트와 같은 관례).
          tester.widget<FlipCard>(find.byType(FlipCard)).onTap!();
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 400));

          // "쓰임" 구획을 펼친다.
          tester
              .widget<SoriPressable>(
                find.byKey(const ValueKey('usageNoteHeaderToggle')),
              )
              .onTap!();
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 200));

          await expectLater(
            find.byType(MaterialApp),
            matchesGoldenFile(
              'baselines/vocab_pack_usage_note_back_${viewport.key}.png',
            ),
          );

          await tester.pumpWidget(const SizedBox.shrink());
          await tester.pump();
        });
      }
    },
  );
}
