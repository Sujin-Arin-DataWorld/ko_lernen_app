import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ko_lernen_app/l10n/generated/app_localizations.dart';
import 'package:ko_lernen_app/screens/custom_pack_typing_screen.dart';
import 'package:ko_lernen_app/services/storage_service.dart';
import 'package:ko_lernen_app/theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const packId = 'cp_typing_haptic';
  final packJson = <String, Object?>{
    packId: {
      'name': 'Typing Haptic Test',
      'sourcePageId': 'page_test',
      'createdAt': '2026-01-01T00:00:00.000Z',
      'words': [
        {
          'korean': '학교',
          'romanization': 'hakgyo',
          'posDe': 'N.',
          'translationDe': 'Schule',
          'translationEn': 'School',
          'exampleKorean': '',
          'exampleDe': '',
          'definitionKo': '',
          'imagePath': '',
          'savedToPackId': null,
        },
      ],
    },
  };
  setUp(() async {
    SharedPreferences.setMockInitialValues({
      'kl_user_level': 'a1',
      'kl_custom_packs_v1': jsonEncode(packJson),
    });
    await Storage.init();
  });
  Widget host() => MaterialApp(
    theme: AppTheme.light,
    locale: const Locale('de'),
    supportedLocales: AppL10n.supportedLocales,
    localizationsDelegates: AppL10n.localizationsDelegates,
    home: const CustomPackTypingScreen(packId: packId, speaker: null),
  );
  Future<List<String>> tapAndCollectHaptics(
    WidgetTester tester,
    String input,
  ) async {
    final types = <String>[];
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'HapticFeedback.vibrate') {
          types.add('${call.arguments}');
        }
        return null;
      },
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      ),
    );
    await tester.pumpWidget(host());
    await tester.pump();
    await tester.enterText(find.byType(TextField), input);
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();
    return types;
  }
  testWidgets('정답 제출은 lightImpact 햅틱을 낸다', (tester) async {
    final types = await tapAndCollectHaptics(tester, '학교');
    expect(types, contains('HapticFeedbackType.lightImpact'));
  });
  testWidgets('오답 제출은 mediumImpact 햅틱을 낸다', (tester) async {
    final types = await tapAndCollectHaptics(tester, '틀림');
    expect(types, contains('HapticFeedbackType.mediumImpact'));
  });
}
