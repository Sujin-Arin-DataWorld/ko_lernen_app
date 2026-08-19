import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ko_lernen_app/l10n/generated/app_localizations.dart';
import 'package:ko_lernen_app/models/book_page.dart';
import 'package:ko_lernen_app/services/custom_pack_service.dart';
import 'package:ko_lernen_app/services/storage_service.dart';
import 'package:ko_lernen_app/widgets/sori/wordbook_add.dart';

/// 소스 스캔이 아니라 **실제 동작**으로 잠근다.
///
/// Jin: "책갈피 누르면 added ....to your word list가 안사라져. ... 아니면
/// 밑에 창 안뜨고 하트누르는것처럼 책갈피가 채워지는 효과 나오게해줘."
Future<void> _pump(WidgetTester tester, {required String korean}) async {
  await tester.pumpWidget(
    MaterialApp(
      locale: const Locale('de'),
      localizationsDelegates: AppL10n.localizationsDelegates,
      supportedLocales: AppL10n.supportedLocales,
      home: Scaffold(
        body: Center(
          child: AddToWordbookButton(
            korean: korean,
            translationDe: 'Apfel',
            coachEnabled: false,
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    Storage.resetForTesting();
    await Storage.init();
    CustomPackService.revision.value = 0;
  });

  testWidgets('담기 전에는 비어 있고, 담으면 채워진다', (tester) async {
    await _pump(tester, korean: '사과');
    expect(find.byIcon(Icons.bookmark_add_outlined), findsOneWidget);
    expect(find.byIcon(Icons.bookmark_rounded), findsNothing);

    await tester.tap(find.byType(TextButton));
    await tester.pumpAndSettle();

    expect(
      find.byIcon(Icons.bookmark_rounded),
      findsOneWidget,
      reason: '담긴 것을 아이콘이 말해야 한다 — 알림을 없앤 자리를 이게 채운다',
    );
    expect(CustomPackService.containsKorean('사과'), isTrue);
  });

  testWidgets('성공에 검은 바가 뜨지 않는다 — 연타해도', (tester) async {
    await _pump(tester, korean: '사과');

    for (var i = 0; i < 4; i++) {
      await tester.tap(find.byType(TextButton));
      await tester.pump();
    }
    await tester.pumpAndSettle();

    expect(
      find.byType(SnackBar),
      findsNothing,
      reason: 'hide 직후 show 는 교체가 아니라 큐잉이라 예전엔 여기서 쌓였다',
    );
  });

  testWidgets('화면이 setState 를 안 해도 아이콘이 맞는다', (tester) async {
    // 저장은 이 위젯 밖(피드의 다른 버튼·다른 화면)에서 일어날 수 있다.
    // 예전에는 화면마다 setState 를 기억해야 했고 여러 곳이 잊고 있었다.
    await _pump(tester, korean: '포도');
    expect(find.byIcon(Icons.bookmark_add_outlined), findsOneWidget);

    await CustomPackService.quickAdd(
      defaultPackName: 'quick',
      word: ExtractedWord.manual(korean: '포도', translationDe: 'Traube'),
    );
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.bookmark_rounded), findsOneWidget);
  });
}
