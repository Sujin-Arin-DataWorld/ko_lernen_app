import 'package:flutter/material.dart';

import 'sheet.dart';
import 'tokens.dart';

enum SoriToastTone { neutral, error }

/// 짧은 실패 알림 하나. **성공에는 쓰지 않는다.**
///
/// 왜 `removeCurrentSnackBar` 인가: `hideCurrentSnackBar()` 는 ~250ms 역방향
/// 애니메이션을 시작할 뿐이고 항목은 dismissed 에서야 큐에서 빠진다. 그래서
/// hide 직후 show 는 **교체가 아니라 큐잉**이 되고, 연타하면 토스트가 사슬처럼
/// 쌓여 "안 사라진다"로 보인다 — Jin 이 책갈피에서 겪은 그 버그다.
/// `removeCurrentSnackBar` 는 역방향을 건너뛰고 즉시 비우므로 큐가 자라지 않는다.
///
/// 그리고 액션 버튼을 달지 않는다. Flutter 는 라우트가 current 일 때만
/// 자동 소멸 타이머를 걸기 때문에, 모달 시트 위에서 뜬 액션 달린 바는
/// 영영 안 사라진다.
ScaffoldFeatureController<SnackBar, SnackBarClosedReason>? showSoriToast(
  BuildContext context,
  String message, {
  SoriToastTone tone = SoriToastTone.error,
  Duration duration = const Duration(milliseconds: 1200),
  bool liveRegion = false,
}) {
  final messenger = ScaffoldMessenger.maybeOf(context);
  if (messenger == null) {
    return null;
  }
  messenger.removeCurrentSnackBar();
  return messenger.showSnackBar(
    SnackBar(
      content: liveRegion
          ? Semantics(
              container: true,
              liveRegion: true,
              label: message,
              excludeSemantics: true,
              child: Text(message),
            )
          : Text(message),
      duration: duration,
      behavior: SnackBarBehavior.floating,
      showCloseIcon: tone == SoriToastTone.neutral,
    ),
  );
}

/// Short, action-free failure feedback.
void soriToast(BuildContext context, String message) {
  showSoriToast(context, message);
}

/// Informational feedback that may need a little more reading time.
///
/// Notices remain action-free. A follow-up action belongs in the page or a
/// Sori sheet so it cannot stall behind another modal route.
void soriNotice(
  BuildContext context,
  String message, {
  Duration duration = const Duration(seconds: 2),
}) {
  showSoriToast(
    context,
    message,
    tone: SoriToastTone.neutral,
    duration: duration,
    liveRegion: true,
  );
}

/// Actionable feedback uses a sheet instead of an action SnackBar.
///
/// Flutter pauses an action SnackBar's dismissal timer behind modal routes.
/// Keeping the action in a Sori sheet makes the message, dismiss control, and
/// follow-up action reachable at large text sizes.
Future<void> showSoriActionNotice({
  required BuildContext context,
  required String message,
  required String dismissLabel,
  required String actionLabel,
  required VoidCallback onAction,
}) {
  return showSoriSheet<void>(
    context: context,
    builder: (sheetContext) => Semantics(
      container: true,
      liveRegion: true,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(message, style: SoriTextTheme.of(sheetContext).body),
          const SizedBox(height: Spacing.lg),
          Wrap(
            alignment: WrapAlignment.end,
            spacing: Spacing.sm,
            runSpacing: Spacing.sm,
            children: [
              TextButton(
                onPressed: () => Navigator.pop(sheetContext),
                child: Text(dismissLabel),
              ),
              FilledButton(
                onPressed: () {
                  Navigator.pop(sheetContext);
                  onAction();
                },
                child: Text(actionLabel),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}
