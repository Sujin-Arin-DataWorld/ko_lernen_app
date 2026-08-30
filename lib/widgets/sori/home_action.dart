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
    if (escape.confirmWhen) {
      final confirmed = await showSoriSheet<bool>(
        context: context,
        builder: (sheetContext) => _LeaveConfirmSheet(
          title: escape.confirmTitle,
          body: escape.confirmBody,
        ),
      );
      if (confirmed != true) {
        return;
      }
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
