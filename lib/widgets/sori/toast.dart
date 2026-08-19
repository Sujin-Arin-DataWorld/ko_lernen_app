import 'package:flutter/material.dart';

/// 짧은 실패 알림 하나. **성공에는 쓰지 않는다.**
///
/// 왜 `removeCurrentSnackBar` 인가: `hideCurrentSnackBar()` 는 ~250ms 역방향
/// 애니메이션을 시작할 뿐이고 항목은 dismissed 에서야 큐에서 빠진다. 그래서
/// hide 직후 show 는 **교체가 아니라 큐잉**이 되고, 연타하면 토스트가 사슬처럼
/// 쌓여 "안 사라진다"로 보인다 — Jin 이 책갈피에서 겪은 그 버그다.
/// `removeCurrentSnackBar` 는 역방향을 건너뛰고 즉시 비우므로 큐가 자란다.
///
/// 그리고 액션 버튼을 달지 않는다. Flutter 는 라우트가 current 일 때만
/// 자동 소멸 타이머를 걸기 때문에, 모달 시트 위에서 뜬 액션 달린 바는
/// 영영 안 사라진다.
void soriToast(BuildContext context, String message) {
  final messenger = ScaffoldMessenger.maybeOf(context);
  if (messenger == null) {
    return;
  }
  messenger.removeCurrentSnackBar();
  messenger.showSnackBar(
    SnackBar(
      content: Text(message),
      duration: const Duration(milliseconds: 1200),
      behavior: SnackBarBehavior.floating,
    ),
  );
}
