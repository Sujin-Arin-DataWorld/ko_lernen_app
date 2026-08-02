import 'package:flutter/material.dart';

import 'tokens.dart';
import 'button.dart';
import 'mascot.dart';
import 'sheet.dart';
import '../../services/auth_service.dart';
import '../../services/account/account_transition_coordinator.dart';
import '../../services/account/account_ui_operations.dart';
import 'account_operation_ui.dart';
import '../../l10n/generated/app_localizations.dart';

/// Soft Konto-Nudge — Bottom-Sheet, der anonyme Nutzer einlädt, ihren
/// Fortschritt per Google zu sichern.
///
/// Duolingo-Muster: **nie blockieren**, immer "Später" anbieten. No-op,
/// wenn bereits ein dauerhaftes Google- oder Apple-Konto verbunden ist.
Future<void> showAccountNudgeSheet(
  BuildContext context, {
  AuthAccountSnapshot? account,
  AccountUiOperations? accountOperations,
}) async {
  final snapshot = account ?? AuthService.accountSnapshot;
  if (snapshot.providers.isDurable) {
    return;
  }
  await showSoriSheet<void>(
    context: context,
    builder: (_) => _AccountNudgeSheet(
      accountOperations:
          accountOperations ?? const ProductionAccountUiOperations(),
    ),
  );
}

class _AccountNudgeSheet extends StatefulWidget {
  const _AccountNudgeSheet({required this.accountOperations});

  final AccountUiOperations accountOperations;

  @override
  State<_AccountNudgeSheet> createState() => _AccountNudgeSheetState();
}

class _AccountNudgeSheetState extends State<_AccountNudgeSheet> {
  bool _busy = false;

  Future<void> _connectWith(AccountLinkProvider provider) async {
    final nav = Navigator.of(context);
    setState(() => _busy = true);
    try {
      await runConfirmedAccountLink(
        context,
        operations: widget.accountOperations,
        provider: provider,
        onCompleted: () async {
          if (mounted) nav.pop();
        },
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);
    final s = SoriSurfaces.of(context);
    // 시트 외형(둥근 상단·handle·SafeArea·maxHeight·스크롤)은 SoriSheet 담당.
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AccountPendingOperationPanel(
          operations: widget.accountOperations,
          onCompleted: () async {
            if (mounted) Navigator.of(context).pop();
          },
        ),
        const Mascot.tiger(
          size: 92,
          emotion: MascotEmotion.smile,
          animate: false,
        ),
        const SizedBox(height: 12),
        Text(
          t.accountNudgeTitle,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: 'Pretendard',
            fontSize: 19,
            fontWeight: FontWeight.w900,
            color: s.text,
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          t.accountNudgeBody,
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 13.5, height: 1.5, color: s.textMuted),
        ),
        const SizedBox(height: 20),
        AccountNewLinkGuard(
          operations: widget.accountOperations,
          builder: (context, linkAvailable) => Column(
            children: [
              SoriButton.filled(
                label: t.accountNudgeConnect,
                icon: Icons.cloud_upload_outlined,
                fullWidth: true,
                onTap: !_busy && linkAvailable
                    ? () => _connectWith(AccountLinkProvider.google)
                    : null,
              ),
              if (widget.accountOperations.appleSignInAvailable) ...[
                const SizedBox(height: 8),
                SoriButton.outlined(
                  label: t.authAppleSignIn,
                  icon: Icons.apple,
                  fullWidth: true,
                  onTap: !_busy && linkAvailable
                      ? () => _connectWith(AccountLinkProvider.apple)
                      : null,
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 4),
        TextButton(
          onPressed: _busy ? null : () => Navigator.of(context).pop(),
          child: Text(
            t.accountNudgeLater,
            style: TextStyle(
              fontFamily: 'Pretendard',
              color: s.textMuted,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}
