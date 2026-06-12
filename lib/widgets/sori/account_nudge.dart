import 'package:flutter/material.dart';

import 'tokens.dart';
import 'button.dart';
import 'mascot.dart';
import 'sheet.dart';
import '../../services/auth_service.dart';
import '../../services/cloud_sync.dart';
import '../../l10n/generated/app_localizations.dart';

/// Soft Konto-Nudge — Bottom-Sheet, der anonyme Nutzer einlädt, ihren
/// Fortschritt per Google zu sichern.
///
/// Duolingo-Muster: **nie blockieren**, immer "Später" anbieten. No-op,
/// wenn bereits mit Google verbunden (oder Firebase nicht verfügbar →
/// `isGoogleLinked == false`, Sheet zeigt sich, Verbinden bricht sauber ab).
Future<void> showAccountNudgeSheet(BuildContext context) async {
  if (AuthService.isGoogleLinked) {
    return;
  }
  await showSoriSheet<void>(
    context: context,
    builder: (_) => const _AccountNudgeSheet(),
  );
}

class _AccountNudgeSheet extends StatefulWidget {
  const _AccountNudgeSheet();

  @override
  State<_AccountNudgeSheet> createState() => _AccountNudgeSheetState();
}

class _AccountNudgeSheetState extends State<_AccountNudgeSheet> {
  bool _busy = false;

  Future<void> _connectWith(Future<dynamic> Function() link) async {
    final t = AppL10n.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final nav = Navigator.of(context);
    setState(() => _busy = true);
    try {
      final user = await link();
      if (user != null) {
        await CloudSync.backup();
      }
      if (mounted) {
        nav.pop();
      }
    } catch (e) {
      if (!mounted) {
        return;
      }
      setState(() => _busy = false);
      messenger.showSnackBar(
        SnackBar(content: Text(t.settingsCloudAuthFailed(e.toString()))),
      );
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
        const Mascot.tiger(
          size: 92,
          emotion: MascotEmotion.smile,
          animate: true,
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
        SoriButton.filled(
          label: t.accountNudgeConnect,
          icon: Icons.cloud_upload_outlined,
          fullWidth: true,
          onTap: _busy ? null : () => _connectWith(AuthService.linkWithGoogle),
        ),
        if (AuthService.appleSignInAvailable) ...[
          const SizedBox(height: 8),
          SoriButton.outlined(
            label: t.authAppleSignIn,
            icon: Icons.apple,
            fullWidth: true,
            onTap: _busy ? null : () => _connectWith(AuthService.linkWithApple),
          ),
        ],
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
