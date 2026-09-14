import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ko_lernen_app/l10n/generated/app_localizations.dart';
import 'package:ko_lernen_app/l10n/generated/app_localizations_de.dart';
import 'package:ko_lernen_app/l10n/generated/app_localizations_en.dart';
import 'package:ko_lernen_app/services/storage_service.dart';
import 'package:ko_lernen_app/widgets/sori/ai_voice_notice_host.dart';
import 'package:ko_lernen_app/widgets/sori/speakable.dart';

/// C8 (EU AI Act Art. 50(2)) — 한국어 음성이 AI 합성(Google Cloud TTS,
/// Chirp 3 HD)이며 실제 화자가 아니라는 고지.
///
/// R3 재검토(2026-09-15) 이후 구조: `SoriSpeech.speak()` 가 앱을 통틀어
/// 실제 오디오가 나가는 유일한 진입점이므로(직접 호출 스크린 30여 곳 +
/// [SoriSpeakable]/[SoriSpeechIndicator] 전부 여기로 모인다), 첫 재생
/// 감지는 그 파사드 하나에만 있고([SoriSpeech.aiVoiceNoticePending]) —
/// 하지만 `speak()` 는 **Storage 에 쓰지 않는다**. `Storage.
/// setAiVoiceNoticeShownV1()` 은 실제로 스낵바를 띄우는
/// [AiVoiceNoticeHost] 만, 그 순간에만 부른다 — `AiVoiceNoticeHost` 가
/// 안 걸린 화면 트리(미리보기/갤러리 하네스)에서는 `speak()` 를 아무리
/// 불러도 SharedPreferences 가 안 바뀐다(`ux_gallery_no_write_test.dart`
/// 계약).
///
/// 이 테스트는 네 표면을 고정한다:
/// 1. `SoriSpeech.speak()` 를 직접 호출해도(래퍼 위젯 없이) 첫 재생에서
///    스낵바가 정확히 한 번 뜨고, 그 스낵바가 실제로 뜬 **뒤에야**
///    `Storage.aiVoiceNoticeShownV1` 이 켜진다 — 두 번째 재생부터는 다시
///    뜨지 않는다.
/// 2. 플래그가 이미 켜져 있으면 처음부터 아예 뜨지 않는다.
/// 3. 호스트가 처리하기 전에 `speak()` 가 연달아 불려도(예: 같은 프레임
///    안 재진입) 스낵바가 한 번만 뜬다 — `aiVoiceNoticePending` 의 값
///    재대입 무시(멱등) 특성.
/// 4. [AiVoiceNoticeHost] 가 마운트되지 않은 화면 트리에서는 `speak()` 를
///    불러도 `Storage.aiVoiceNoticeShownV1` 이 계속 false 로 남는다.
/// 5. 설정 화면이 참조하는 `AppL10n.aiVoiceNoticeTitle`/`aiVoiceNoticeBody`
///    가 DE/EN 모두 채워져 있다.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    // Storage._prefs 캐시부터 비워야 뒤이은 setMockInitialValues+init 이
    // 실제로 새 값을 준다 — review_session_screen_speakable_test.dart 와
    // 같은 순서(이 호출을 빼먹으면 이전 테스트가 켠
    // kl_ai_voice_notice_shown_v1 이 다음 테스트로 새어 들어온다).
    Storage.resetForTesting();
    SharedPreferences.setMockInitialValues({});
    await Storage.init();
    SoriSpeech.resetForTesting();
    SoriSpeech.speakImpl = (text, voice) async => true;
  });

  tearDown(() {
    SoriSpeech.resetForTesting();
  });

  Widget buildApp() => MaterialApp(
    debugShowCheckedModeBanner: false,
    locale: const Locale('de'),
    supportedLocales: AppL10n.supportedLocales,
    localizationsDelegates: AppL10n.localizationsDelegates,
    // main.dart 가 실제로 하는 배선과 같은 모양 — AiVoiceNoticeHost 를
    // MaterialApp.builder 아래 한 번 마운트해야 context 가
    // ScaffoldMessenger/Localizations 를 보장받는다.
    builder: (context, child) =>
        AiVoiceNoticeHost(child: child ?? const SizedBox()),
    home: const Scaffold(body: SizedBox.shrink()),
  );

  testWidgets(
    'SoriSpeech.speak() 직접 호출만으로도(위젯 탭 없이) 첫 재생에 스낵바가 1회 뜬다 — 플래그는 뜬 뒤에만 켜진다',
    (tester) async {
      expect(Storage.aiVoiceNoticeShownV1, isFalse);

      await tester.pumpWidget(buildApp());

      await SoriSpeech.speak('안녕');
      // speak() 자신은 Storage 를 안 건드린다 — pending 신호만 세운다.
      expect(Storage.aiVoiceNoticeShownV1, isFalse);

      // aiVoiceNoticePending 리스너가 예약한 addPostFrameCallback 을
      // 소진하고, 그 결과로 요청된 스낵바 프레임을 그린다. Storage 쓰기는
      // 바로 이 콜백 안에서, 스낵바를 실제로 띄우는 것과 같은 순간에
      // 일어난다.
      await tester.pump();
      await tester.pump();

      final de = AppL10nDe();
      expect(find.text(de.aiVoiceNoticeFirstPlay), findsOneWidget);
      expect(Storage.aiVoiceNoticeShownV1, isTrue);

      // 스낵바 등장 애니메이션을 먼저 안정화한다 — 자동소멸 Timer 는 등장
      // 애니메이션이 끝나야 돌기 시작한다(sori_toast_test.dart 와 같은
      // 패턴). 그 뒤 Timer 가 끝날 때까지 기다린 뒤 두 번째 재생을 보낸다.
      await tester.pumpAndSettle();
      await tester.pump(const Duration(seconds: 3));
      await tester.pumpAndSettle();

      await SoriSpeech.speak('안녕');
      await tester.pump();
      await tester.pump();

      expect(find.text(de.aiVoiceNoticeFirstPlay), findsNothing);
    },
  );

  testWidgets('이미 고지된 상태(Storage 플래그 true)에서는 재생해도 스낵바가 뜨지 않는다', (
    tester,
  ) async {
    await Storage.setAiVoiceNoticeShownV1();

    await tester.pumpWidget(buildApp());

    await SoriSpeech.speak('안녕');
    await tester.pump();
    await tester.pump();

    final de = AppL10nDe();
    expect(find.text(de.aiVoiceNoticeFirstPlay), findsNothing);
  });

  testWidgets('호스트가 처리하기 전에 speak() 가 연달아 불려도 스낵바는 한 번만 뜬다(멱등)', (
    tester,
  ) async {
    await tester.pumpWidget(buildApp());

    // 둘 다 pending 신호를 세우려 시도한다 — 두 번째 호출 시점엔
    // aiVoiceNoticePending 이 이미 true 라 ValueNotifier 가 리스너를 다시
    // 부르지 않는다(같은 값 재대입 무시), 그래서 addPostFrameCallback 도
    // 한 번만 예약된다.
    await SoriSpeech.speak('안녕');
    await SoriSpeech.speak('안녕');
    await tester.pump();
    await tester.pump();

    final de = AppL10nDe();
    expect(find.text(de.aiVoiceNoticeFirstPlay), findsOneWidget);
    expect(Storage.aiVoiceNoticeShownV1, isTrue);
  });

  testWidgets('AiVoiceNoticeHost 가 없는 화면 트리에서는 speak() 를 불러도 Storage 에 안 쓴다', (
    tester,
  ) async {
    // ux_gallery_no_write_test.dart 의 미리보기/갤러리 하네스처럼,
    // 앱 루트의 MaterialApp.builder 를 거치지 않는 헤드리스 트리 —
    // AiVoiceNoticeHost 를 마운트하지 않는다.
    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        locale: const Locale('de'),
        supportedLocales: AppL10n.supportedLocales,
        localizationsDelegates: AppL10n.localizationsDelegates,
        home: const Scaffold(body: SizedBox.shrink()),
      ),
    );

    expect(Storage.aiVoiceNoticeShownV1, isFalse);

    await SoriSpeech.speak('안녕');
    await tester.pump();
    await tester.pump();
    await tester.pump(const Duration(seconds: 3));

    // 신호는 세워졌지만(SoriSpeech.aiVoiceNoticePending) 아무도 듣지
    // 않으니 영구 플래그도, 스낵바도 없다.
    expect(Storage.aiVoiceNoticeShownV1, isFalse);
    expect(SoriSpeech.aiVoiceNoticePending.value, isTrue);
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
