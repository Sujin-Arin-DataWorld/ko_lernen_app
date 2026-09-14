import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ko_lernen_app/l10n/generated/app_localizations.dart';
import 'package:ko_lernen_app/l10n/generated/app_localizations_de.dart';
import 'package:ko_lernen_app/l10n/generated/app_localizations_en.dart';
import 'package:ko_lernen_app/services/storage_service.dart';
import 'package:ko_lernen_app/widgets/sori/speakable.dart';

/// C8 (EU AI Act Art. 50(2)) — 한국어 음성이 AI 합성(Google Cloud TTS,
/// Chirp 3 HD)이며 실제 화자가 아니라는 고지.
///
/// 두 표면을 고정한다:
/// 1. 첫 TTS 재생 시 [SoriSpeakable]/[SoriSpeechIndicator] 탭 지점에서
///    스낵바가 정확히 한 번만 뜨고 `Storage.aiVoiceNoticeShownV1` 이 켜진다
///    — 두 번째 재생부터는 다시 뜨지 않는다.
/// 2. 설정 화면이 참조하는 `AppL10n.aiVoiceNoticeTitle`/`aiVoiceNoticeBody`
///    가 DE/EN 모두 채워져 있다.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await Storage.init();
    SoriSpeech.resetForTesting();
    SoriSpeech.speakImpl = (text, voice) async => true;
  });

  tearDown(() {
    SoriSpeech.resetForTesting();
  });

  Widget buildApp(Widget child) => MaterialApp(
    debugShowCheckedModeBanner: false,
    locale: const Locale('de'),
    supportedLocales: AppL10n.supportedLocales,
    localizationsDelegates: AppL10n.localizationsDelegates,
    home: Scaffold(body: Center(child: child)),
  );

  testWidgets('첫 재생에서 AI 음성 고지 스낵바가 1회 뜨고 플래그가 저장된다 — 두 번째 재생엔 안 뜬다', (
    tester,
  ) async {
    expect(Storage.aiVoiceNoticeShownV1, isFalse);

    await tester.pumpWidget(
      buildApp(const SoriSpeakable(text: '학교', child: Text('학교'))),
    );

    await tester.tap(find.byType(SoriSpeakable));
    // 스낵바 등장 애니메이션을 먼저 안정화한다 — sori_toast_test.dart 와
    // 같은 패턴. 자동소멸 Timer 는 등장 애니메이션이 끝나야 돌기 시작한다.
    await tester.pumpAndSettle();

    final de = AppL10nDe();
    expect(find.text(de.aiVoiceNoticeFirstPlay), findsOneWidget);
    expect(Storage.aiVoiceNoticeShownV1, isTrue);

    // 자동소멸 Timer 가 끝날 때까지 기다린 뒤 두 번째 탭을 보낸다.
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();

    await tester.tap(find.byType(SoriSpeakable));
    await tester.pump();

    expect(find.text(de.aiVoiceNoticeFirstPlay), findsNothing);
  });

  testWidgets('이미 고지된 상태(Storage 플래그 true)에서는 재생해도 스낵바가 뜨지 않는다', (
    tester,
  ) async {
    await Storage.setAiVoiceNoticeShownV1();

    await tester.pumpWidget(
      buildApp(const SoriSpeakable(text: '학교', child: Text('학교'))),
    );

    await tester.tap(find.byType(SoriSpeakable));
    await tester.pump();

    final de = AppL10nDe();
    expect(find.text(de.aiVoiceNoticeFirstPlay), findsNothing);
  });

  test('설정 화면이 쓰는 AI 음성 고지 제목/본문이 DE/EN 모두 채워져 있다', () {
    for (final t in <AppL10n>[AppL10nDe(), AppL10nEn()]) {
      expect(t.aiVoiceNoticeTitle.trim(), isNotEmpty, reason: t.localeName);
      expect(t.aiVoiceNoticeBody.trim(), isNotEmpty, reason: t.localeName);
      expect(
        t.aiVoiceNoticeBody,
        isNot(equals(t.aiVoiceNoticeTitle)),
        reason: t.localeName,
      );
    }
  });
}
