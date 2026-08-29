import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ko_lernen_app/l10n/generated/app_localizations.dart';
import 'package:ko_lernen_app/theme.dart';
import 'package:ko_lernen_app/widgets/sori/home_action.dart';

void main() {
  Widget harness({required SoriHomeEscape escape}) {
    return MaterialApp(
      theme: AppTheme.light,
      locale: const Locale('de'),
      supportedLocales: AppL10n.supportedLocales,
      localizationsDelegates: AppL10n.localizationsDelegates,
      routes: {
        '/': (_) => const Scaffold(body: Text('HOME')),
        '/deep': (_) => Scaffold(
          appBar: AppBar(leading: SoriHomeAction(escape: escape)),
        ),
      },
      initialRoute: '/deep',
    );
  }

  testWidgets('라운드 비활성이면 확인 없이 즉시 홈으로', (tester) async {
    await tester.pumpWidget(harness(escape: const SoriHomeEscape()));
    await tester.tap(find.byType(SoriHomeAction));
    await tester.pumpAndSettle();
    expect(find.text('HOME'), findsOneWidget);
  });

  testWidgets('라운드 활성이면 확인 시트가 뜨고, 취소하면 화면에 남는다', (tester) async {
    await tester.pumpWidget(
      harness(escape: const SoriHomeEscape(confirmWhen: true)),
    );
    await tester.tap(find.byType(SoriHomeAction));
    await tester.pumpAndSettle();
    final t = await AppL10n.delegate.load(const Locale('de'));
    expect(find.text(t.homeActionConfirmTitle), findsOneWidget);
    await tester.tap(find.text(t.homeActionConfirmStay));
    await tester.pumpAndSettle();
    expect(find.text('HOME'), findsNothing);
  });

  testWidgets('확인 시트에서 떠나기를 누르면 홈으로', (tester) async {
    await tester.pumpWidget(
      harness(escape: const SoriHomeEscape(confirmWhen: true)),
    );
    await tester.tap(find.byType(SoriHomeAction));
    await tester.pumpAndSettle();
    final t = await AppL10n.delegate.load(const Locale('de'));
    await tester.tap(find.text(t.homeActionConfirmLeave));
    await tester.pumpAndSettle();
    expect(find.text('HOME'), findsOneWidget);
  });

  testWidgets('화면별 확인 제목과 본문을 사용한다', (tester) async {
    await tester.pumpWidget(
      harness(
        escape: const SoriHomeEscape(
          confirmWhen: true,
          confirmTitle: 'Custom title',
          confirmBody: 'Custom body',
        ),
      ),
    );
    await tester.tap(find.byType(SoriHomeAction));
    await tester.pumpAndSettle();

    expect(find.text('Custom title'), findsOneWidget);
    expect(find.text('Custom body'), findsOneWidget);
  });
}
