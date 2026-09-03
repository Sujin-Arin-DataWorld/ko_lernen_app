import 'package:flutter/material.dart';

import '../../l10n/generated/app_localizations.dart';
import 'button.dart';
import 'pressable.dart';
import 'sheet.dart';
import 'tokens.dart';

/// **SoriHomeAction** — 지시서 4.16 홈 이스케이프 해치.
///
/// Navigator 1.0 스택 어디서든 `/`(AppShell)까지 단숨에 돌아간다
/// (`pushNamedAndRemoveUntil('/', (route) => false)` — 선례:
/// `gye_tab_screen.dart:178`). [SoriHomeEscape.confirmWhen]이 true면 떠나기
/// 전에 확인 시트를 연다 — 진행 중인 라운드에서 실수로 홈을 눌러 학습
/// 증거를 잃는 사고를 막는다.
final class SoriHomeEscape {
  const SoriHomeEscape({
    this.confirmWhen = false,
    this.confirmTitle,
    this.confirmBody,
  });

  final bool confirmWhen;
  final String? confirmTitle;
  final String? confirmBody;
}

class SoriHomeAction extends StatelessWidget {
  const SoriHomeAction({
    super.key,
    this.escape = const SoriHomeEscape(),
    this.onLeave,
  });

  final SoriHomeEscape escape;

  /// 확인 뒤(또는 확인이 필요 없을 때) 실제 이동 **직전** 호출 — 화면이
  /// 타이머 정지 등 정리를 할 자리.
  final VoidCallback? onLeave;

  Future<void> _leave(BuildContext context) async {
    if (!await showLeaveConfirmSheet(context, escape)) {
      return;
    }
    onLeave?.call();
    if (!context.mounted) return;
    Navigator.of(
      context,
      rootNavigator: true,
    ).pushNamedAndRemoveUntil('/', (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);
    return Semantics(
      button: true,
      label: t.homeActionLabel,
      // §B2(2026-09-03) — see SoriCloseAction.build for why `onTap` is
      // repeated here: ExcludeSemantics below erases the SemanticsAction
      // that SoriPressable's own GestureDetector would otherwise register.
      onTap: () => _leave(context),
      child: ExcludeSemantics(
        child: SoriPressable(
          onTap: () => _leave(context),
          child: const SizedBox(
            width: SoriLayout.chromeRowTouchHeight,
            height: SoriLayout.chromeRowTouchHeight,
            child: Icon(Icons.home_rounded),
          ),
        ),
      ),
    );
  }
}

/// **SoriCloseAction** — §B2(2026-09-03) 좌상단 닫기(X) 슬롯.
///
/// [SoriStudyFrame]의 leading 자리를 차지한다. [SoriHomeAction]과 같은 확인
/// 규칙([SoriHomeEscape.confirmWhen])을 쓰지만, 홈까지 가지 않고 현재 라우트
/// 한 단계만 닫는다 — 시스템 뒤로가기/스와이프백과 같은 목적지.
class SoriCloseAction extends StatelessWidget {
  const SoriCloseAction({
    super.key,
    this.escape = const SoriHomeEscape(),
    this.onLeave,
  });

  final SoriHomeEscape escape;

  /// 확인 뒤(또는 확인이 필요 없을 때) 실제 닫기 **직전** 호출 — 화면이
  /// 타이머 정지 등 정리를 할 자리.
  final VoidCallback? onLeave;

  Future<void> _close(BuildContext context) async {
    if (!await showLeaveConfirmSheet(context, escape)) {
      return;
    }
    onLeave?.call();
    if (!context.mounted) return;
    // `Navigator.maybePop`은 `Route.popDisposition`(PopScope의 `canPop`)을
    // 다시 묻는다 — [SoriStudyFrame]이 바로 이 `escape`로 자신을
    // `PopScope(canPop: !escape.confirmWhen, ...)`로 감싸므로,
    // `confirmWhen`이 true였던 경로에서는 방금 확인을 받고도 그 정적
    // `canPop`에 다시 막혀 아무 일도 안 일어난다(Flutter 공식
    // `pop_scope.0.dart` 예제와 같은 이유로 `pop()`을 직접 쓴다 —
    // 프로그램적 `pop()`은 그 게이트를 우회하고 `didPop`으로만 알린다).
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);
    return Semantics(
      button: true,
      label: t.closeActionLabel,
      // `ExcludeSemantics` 아래는 `SoriPressable`의 GestureDetector가 실제
      // 터치를 직접 처리하지만, 그 기여분은 여기서 지워지므로 스크린리더의
      // 이중 탭(SemanticsAction.tap)이 통할 자리가 없다 — `onTap`을 이
      // Semantics 노드에 직접 달아 스크린리더 활성화 경로를 따로 준다.
      onTap: () => _close(context),
      child: ExcludeSemantics(
        child: SoriPressable(
          onTap: () => _close(context),
          child: const SizedBox(
            width: SoriLayout.chromeRowTouchHeight,
            height: SoriLayout.chromeRowTouchHeight,
            child: Icon(Icons.close_rounded),
          ),
        ),
      ),
    );
  }
}

/// 확인이 필요하면([SoriHomeEscape.confirmWhen]) [_LeaveConfirmSheet]을 열고
/// "떠나기"를 골랐는지 반환한다. 확인이 필요 없으면 즉시 true — [SoriHomeAction]
/// 과 [SoriCloseAction]이 함께 쓰는 단일 확인 경로.
Future<bool> showLeaveConfirmSheet(
  BuildContext context,
  SoriHomeEscape escape,
) async {
  if (!escape.confirmWhen) {
    return true;
  }
  final confirmed = await showSoriSheet<bool>(
    context: context,
    builder: (sheetContext) =>
        _LeaveConfirmSheet(title: escape.confirmTitle, body: escape.confirmBody),
  );
  return confirmed == true;
}

class _LeaveConfirmSheet extends StatelessWidget {
  const _LeaveConfirmSheet({this.title, this.body});

  final String? title;
  final String? body;

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);
    return Padding(
      padding: const EdgeInsets.all(Spacing.lg),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            title ?? t.homeActionConfirmTitle,
            style: SoriTextTheme.of(context).h2,
          ),
          const SizedBox(height: Spacing.sm),
          Text(
            body ?? t.homeActionConfirmBody,
            style: SoriTextTheme.of(context).body,
          ),
          const SizedBox(height: Spacing.lg),
          SoriButton.filled(
            label: t.homeActionConfirmLeave,
            fullWidth: true,
            onTap: () => Navigator.of(context).pop(true),
          ),
          const SizedBox(height: Spacing.sm),
          SoriButton.ghost(
            label: t.homeActionConfirmStay,
            fullWidth: true,
            onTap: () => Navigator.of(context).pop(false),
          ),
        ],
      ),
    );
  }
}
