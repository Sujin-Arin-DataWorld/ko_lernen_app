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
/// `gye_tab_screen.dart:178`). [isRoundActive]가 true를 돌려주면 떠나기
/// 전에 확인 시트를 연다 — 타이머 있는 라운드 중간에 실수로 홈을 눌러
/// 진행을 잃는 사고를 막는다.
class SoriHomeAction extends StatelessWidget {
  const SoriHomeAction({super.key, this.isRoundActive, this.onLeave});

  /// true면 확인 시트를 연다. null이면 항상 무확인 이동(라운드 개념이
  /// 없는 화면).
  final bool Function()? isRoundActive;

  /// 확인 뒤(또는 확인이 필요 없을 때) 실제 이동 **직전** 호출 — 화면이
  /// 타이머 정지 등 정리를 할 자리.
  final VoidCallback? onLeave;

  Future<void> _leave(BuildContext context) async {
    if (isRoundActive?.call() ?? false) {
      final confirmed = await showSoriSheet<bool>(
        context: context,
        builder: (sheetContext) => const _LeaveConfirmSheet(),
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
  const _LeaveConfirmSheet();

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);
    return Padding(
      padding: const EdgeInsets.all(Spacing.lg),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(t.homeActionConfirmTitle, style: SoriTextTheme.of(context).h2),
          const SizedBox(height: Spacing.sm),
          Text(t.homeActionConfirmBody, style: SoriTextTheme.of(context).body),
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
