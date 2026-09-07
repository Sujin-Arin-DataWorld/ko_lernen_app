import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ko_lernen_app/l10n/generated/app_localizations.dart';
import 'package:ko_lernen_app/services/tts_service.dart';
import 'package:ko_lernen_app/widgets/sori/tts_unavailable_banner.dart';

/// 4단(OS 음성)을 지운 뒤로 서버 오디오를 못 받으면 무음이다. 그건 의도지만
/// **이유 없는 무음은 고장과 구분이 안 된다** — Jin 이 "소리 안나와" 로
/// 겪은 게 정확히 그 상태였다. 이 배너가 그 구분을 만든다.
Future<void> _pump(WidgetTester tester) async {
  await tester.pumpWidget(
    MaterialApp(
      locale: const Locale('de'),
      localizationsDelegates: AppL10n.localizationsDelegates,
      supportedLocales: AppL10n.supportedLocales,
      home: const TtsUnavailableBanner(
        child: Scaffold(body: Center(child: Text('content'))),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  tearDown(TtsService.clearUnavailable);

  testWidgets('문제가 없으면 아무것도 안 그린다', (tester) async {
    TtsService.clearUnavailable();
    await _pump(tester);

    expect(find.text('content'), findsOneWidget);
    expect(find.byIcon(Icons.volume_off_rounded), findsNothing);
  });

  testWidgets('사유마다 사람이 읽을 문구가 있다', (tester) async {
    for (final reason in TtsUnavailableReason.values) {
      TtsService.unavailable.value = reason;
      await _pump(tester);

      expect(
        find.byIcon(Icons.volume_off_rounded),
        findsOneWidget,
        reason: '$reason 에 배너가 없다',
      );
      final text = tester
          .widgetList<Text>(find.byType(Text))
          .map((w) => w.data ?? '')
          .firstWhere((d) => d != 'content', orElse: () => '');
      expect(text, isNotEmpty, reason: '$reason 의 문구가 비어 있다');
    }
  });

  testWidgets('닫으면 사라지고, 다시 안 뜬다', (tester) async {
    TtsService.unavailable.value = TtsUnavailableReason.offline;
    await _pump(tester);
    expect(find.byIcon(Icons.volume_off_rounded), findsOneWidget);

    await tester.tap(find.byKey(const Key('tts-unavailable-dismiss')));
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.volume_off_rounded), findsNothing);
    expect(TtsService.unavailable.value, isNull);
  });

  testWidgets('배너는 SnackBar 가 아니다 — 쌓이지 않는다', (tester) async {
    // 스낵바는 hide 직후 show 가 교체가 아니라 큐잉이라 연타하면 쌓인다.
    // 이건 상태를 그대로 비추므로 몇 번을 바꿔도 하나뿐이다.
    for (final reason in TtsUnavailableReason.values) {
      TtsService.unavailable.value = reason;
      await _pump(tester);
    }

    expect(find.byType(SnackBar), findsNothing);
    expect(find.byIcon(Icons.volume_off_rounded), findsOneWidget);
  });
}
