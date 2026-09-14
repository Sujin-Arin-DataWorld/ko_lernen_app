import 'package:flutter/material.dart';

import '../../l10n/generated/app_localizations.dart';
import '../../services/storage_service.dart';
import 'speakable.dart';
import 'toast.dart';

/// C8 (EU AI Act Art. 50(2)) — 앱을 통틀어 [SoriSpeech.speak] 가 처음
/// 트리거되는 순간(직접 호출 스크린이든 [SoriSpeakable]/
/// [SoriSpeechIndicator] 든 가리지 않고) "이 목소리는 AI 로 합성됨" 스낵바를
/// 딱 한 번 띄운다.
///
/// 왜 여기 하나뿐인가: `SoriSpeech.speak()` 호출부가 화면 30여 곳에 흩어져
/// 있어(퀘스트 엔진, 온보딩 데모, 시나리오 자동재생 등) 위젯 여러 곳에
/// 훅을 심으면 커버리지 구멍이 남거나(실제로 첫 라운드에서 그랬다) 두 번
/// 뜰 위험이 생긴다. `SoriSpeech.speak()` 자신은 [BuildContext]/스낵바를
/// 모르는 UI-프리 파사드로 남기고, 대신 이 위젯이
/// [SoriSpeech.aiVoiceNoticePending] 신호 하나만 구독해 실제 스낵바를
/// 띄운다 — `MaterialApp.builder` 아래 정확히 한 번만 마운트해야 한다
/// (그래야 `context` 가 `ScaffoldMessenger`/`Localizations` 조상을
/// 보장받는다).
///
/// R3 — [Storage.setAiVoiceNoticeShownV1] 도 [speak] 가 아니라 **여기,
/// 실제로 스낵바를 띄우는 이 순간에만** 부른다. `speak()` 가 영구 플래그를
/// 직접 쓰면 이 위젯이 안 걸린 화면 트리(미리보기/갤러리 하네스 등)에서도
/// 재생 한 번에 SharedPreferences 가 바뀐다 — `ux_gallery_no_write_test.dart`
/// 가 정확히 이 회귀를 잡아냈다. 이 위젯이 없으면 신호는 대기 상태로 남을
/// 뿐 아무것도 영구화되지 않는다.
class AiVoiceNoticeHost extends StatefulWidget {
  const AiVoiceNoticeHost({super.key, required this.child});

  final Widget child;

  @override
  State<AiVoiceNoticeHost> createState() => _AiVoiceNoticeHostState();
}

class _AiVoiceNoticeHostState extends State<AiVoiceNoticeHost> {
  @override
  void initState() {
    super.initState();
    SoriSpeech.aiVoiceNoticePending.addListener(_onPendingChanged);
  }

  @override
  void dispose() {
    SoriSpeech.aiVoiceNoticePending.removeListener(_onPendingChanged);
    super.dispose();
  }

  void _onPendingChanged() {
    if (!SoriSpeech.aiVoiceNoticePending.value) return;
    // 신호는 1회성이다 — 스낵바를 실제로 띄우기 전에 먼저 꺼서, 리스너가
    // 한 번 더 불려도(예: 같은 프레임 안 재진입) 중복 예약이 안 되게 한다.
    SoriSpeech.aiVoiceNoticePending.value = false;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      Storage.setAiVoiceNoticeShownV1();
      soriNotice(context, AppL10n.of(context).aiVoiceNoticeFirstPlay);
    });
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
