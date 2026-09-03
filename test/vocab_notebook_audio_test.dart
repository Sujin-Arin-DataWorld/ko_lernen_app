import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ko_lernen_app/l10n/generated/app_localizations.dart';
import 'package:ko_lernen_app/models/book_page.dart';
import 'package:ko_lernen_app/models/custom_pack.dart';
import 'package:ko_lernen_app/screens/vocab_notebook_result_screen.dart';
import 'package:ko_lernen_app/screens/vocab_notebook_studio_screen.dart';
import 'package:ko_lernen_app/services/custom_pack_service.dart';
import 'package:ko_lernen_app/services/storage_service.dart';
import 'package:ko_lernen_app/theme.dart';
import 'package:ko_lernen_app/widgets/sori/speakable.dart';
import 'support/sori_speech_stubs.dart';

/// Task 4 — vocab_notebook_result/studio 무음 표면. 두 화면 모두 단어 카드의
/// 한국어 텍스트를 `SoriSpeakable`로 감싸 탭=재생을 배선한다. 하네스는 기존
/// `vocab_notebook_result_screen_test.dart`/`vocab_notebook_studio_screen_test.dart`의
/// pumpWidget 생성자 인자를 그대로 옮겨 온다.
const _resultText = '학교 - Schule\n학생 = Schüler';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late SoriSpeechStub stub;
  setUp(() async {
    Storage.resetForTesting();
    SharedPreferences.setMockInitialValues({});
    await Storage.init();
    stub = stubSoriSpeech();
  });

  testWidgets('vocab_notebook_result_screen: 단어 카드 탭으로 발음을 재생할 수 있다', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        locale: const Locale('de'),
        supportedLocales: AppL10n.supportedLocales,
        localizationsDelegates: AppL10n.localizationsDelegates,
        home: const VocabNotebookResultScreen(
          args: <String, dynamic>{'text': _resultText},
        ),
      ),
    );
    await tester.pump();

    expect(find.byType(SoriSpeakable), findsWidgets);
    final wordCard = find.ancestor(
      of: find.text('학교'),
      matching: find.byType(SoriSpeakable),
    );
    expect(wordCard, findsOneWidget);
    await tester.tap(wordCard);
    await tester.pump();

    expect(stub.spoken, ['학교']);
  });

  testWidgets('vocab_notebook_studio_screen: 단어 카드 탭으로 발음을 재생할 수 있다', (
    tester,
  ) async {
    await CustomPackService.save(
      CustomPack.manual(
        id: 'nb-studio-audio',
        name: 'Heft',
        words: <ExtractedWord>[
          ExtractedWord.manual(korean: '학교', translationDe: 'Schule'),
        ],
      ),
    );

    await tester.pumpWidget(
      const MaterialApp(
        locale: Locale('de'),
        supportedLocales: AppL10n.supportedLocales,
        localizationsDelegates: AppL10n.localizationsDelegates,
        home: VocabNotebookStudioScreen(packId: 'nb-studio-audio'),
      ),
    );
    await tester.pump();

    expect(find.byType(SoriSpeakable), findsWidgets);
    final wordCard = find.ancestor(
      of: find.text('학교'),
      matching: find.byType(SoriSpeakable),
    );
    expect(wordCard, findsOneWidget);
    await tester.tap(wordCard);
    await tester.pump();

    expect(stub.spoken, ['학교']);
  });
}
