import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ko_lernen_app/l10n/generated/app_localizations.dart';
import 'package:ko_lernen_app/widgets/sori/ko_wrap.dart';
import 'package:ko_lernen_app/widgets/sori/chip.dart';
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

    // 한국어 한 줄은 이제 문단 하나로 그려진다. 예전 SoriPhraseWrap 은
    // 어절마다 Text 를 쪼갰는데(그래서 `find.text('접근성을')` 이 맞았다),
    // 그 구조가 줄간격·maxLines·텍스트 선택을 죽이고 TalkBack 이 문장을
    // 단어 단위로 읽게 만들어서 단일 문단 + word joiner 로 바꿨다.
    // 한국어 한 줄은 이제 문단 하나로 그려지고, 어절 안에는 줄바꿈을 막는
    // U+2060 WORD JOINER 가 끼어 있다. 예전 SoriPhraseWrap 은 어절마다 Text 를
    // 쪼갰는데(그래서 `find.text('접근성을')` 이 맞았다), 그 구조가 줄간격·
    // maxLines·텍스트 선택을 죽이고 TalkBack 이 문장을 단어 단위로 읽게 만들어
    // 단일 문단으로 바꿨다. 파인더도 같은 형태를 써야 한다.
    final c1Chip = tester.widget<SoriChip>(
      find.byWidgetPredicate(
        (widget) => widget is SoriChip && widget.label.startsWith('C1 ·'),
      ),
    );
    expect(c1Chip.selected, isTrue);
    expect(find.byKey(const Key('smalltalk-ko')), findsOneWidget);
    expect(find.textContaining(soriJoinEojeol('날씨 좋네요.')), findsNothing);
    expect(find.text('Listen'), findsNothing);
    expect(find.byKey(const Key('smalltalk-speak')), findsOneWidget);
    expect(
      tester.getTopLeft(find.byKey(const Key('smalltalk-ko'))).dx,
      greaterThanOrEqualTo(16),
    );
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });
}
