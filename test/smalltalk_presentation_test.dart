import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ko_lernen_app/l10n/generated/app_localizations.dart';
import 'package:ko_lernen_app/models/smalltalk.dart';
import 'package:ko_lernen_app/screens/smalltalk_screen.dart';
import 'package:ko_lernen_app/services/smalltalk_loader.dart';
import 'package:ko_lernen_app/services/storage_service.dart';
import 'package:ko_lernen_app/theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    Storage.resetForTesting();
    SharedPreferences.setMockInitialValues({'kl_user_level': 'c1'});
    await Storage.init();
    await Storage.setTutSeen('smalltalk');
    SmalltalkLoader.reset();
  });

  test('relationship contexts have learner-facing safety guidance', () {
    expect(
      SmalltalkRelationshipContext.classmate.labelFor('de'),
      'Kursbekanntschaft',
    );
    expect(
      SmalltalkRelationshipContext.closeFriend.labelFor('en'),
      'close friend',
    );
    expect(
      SmalltalkRelationshipContext.service.labelFor('de'),
      'Service-Situation',
    );
  });

  testWidgets('unscoped smalltalk starts at the learner C1 level', (
    tester,
  ) async {
    await tester.runAsync(SmalltalkLoader.load);
    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        locale: const Locale('en'),
        supportedLocales: AppL10n.supportedLocales,
        localizationsDelegates: AppL10n.localizationsDelegates,
        home: const SmalltalkScreen(),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('새 안내 방식이 실제로 접근성을 높였는지 어떻게 확인할까요?'), findsOneWidget);
    expect(find.text('날씨 좋네요.'), findsNothing);
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });
}
