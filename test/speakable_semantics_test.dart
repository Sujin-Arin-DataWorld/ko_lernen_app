import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ko_lernen_app/l10n/generated/app_localizations.dart';
import 'package:ko_lernen_app/services/tts_service.dart';
import 'package:ko_lernen_app/theme.dart';
import 'package:ko_lernen_app/widgets/sori/speakable.dart';

/// 최종 픽스 항목 2 — `SoriSpeechIndicator` 는 Semantics 가 전혀 없어
/// TalkBack/VoiceOver 에서 이름 없는 탭 가능 사각형이었다(`SoriPressable` 은
/// 탭 액션만 주고 버튼 role/이름은 안 준다). `_Stamp`(content_feed.dart:593-598)
/// 와 같은 패턴 — Semantics(button/label/value) + ExcludeSemantics — 로
/// 고정하고, 재생 중/대기 상태가 값(value)으로 실제 접근성 트리에 도달하는지
/// 검증한다.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Widget host() => MaterialApp(
    theme: AppTheme.light,
    locale: const Locale('de'),
    supportedLocales: AppL10n.supportedLocales,
    localizationsDelegates: AppL10n.localizationsDelegates,
    home: const Scaffold(body: Center(child: SoriSpeechIndicator(text: '학교'))),
  );

  setUp(() {
    TtsService.speaking.value = false;
  });

  tearDown(() {
    TtsService.speaking.value = false;
  });

  testWidgets('버튼 role + 이름을 노출하고, 대기 상태에서 idle 값을 읽어준다', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(host());

    final t = await AppL10n.delegate.load(const Locale('de'));
    final node = tester.getSemantics(
      find.bySemanticsLabel(t.speechIndicatorLabel),
    );
    final data = node.getSemanticsData();
    expect(data.label, t.speechIndicatorLabel);
    expect(data.flagsCollection.isButton, isTrue);
    expect(data.hasAction(ui.SemanticsAction.tap), isTrue);
    expect(data.value, t.speechIndicatorIdle);
    semantics.dispose();
  });

  testWidgets('재생 중 값은 대기 값과 다르다', (tester) async {
    final semantics = tester.ensureSemantics();
    TtsService.speaking.value = true;
    await tester.pumpWidget(host());
    await tester.pump();

    final t = await AppL10n.delegate.load(const Locale('de'));
    final node = tester.getSemantics(
      find.bySemanticsLabel(t.speechIndicatorLabel),
    );
    final data = node.getSemanticsData();
    expect(data.value, t.speechIndicatorSpeaking);
    expect(data.value, isNot(t.speechIndicatorIdle));
    semantics.dispose();
  });
}
