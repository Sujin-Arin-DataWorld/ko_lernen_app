import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

import '../l10n/generated/app_localizations.dart';
import '../widgets/app_loading.dart';
import '../l10n/gye_error_text.dart';
import '../services/analytics_service.dart';
import '../services/gye_service.dart';
import '../services/account/cloud_write_session.dart';
import '../widgets/sori/button.dart';
import '../widgets/sori/standard_page.dart';
import '../widgets/sori/tokens.dart';
import '../widgets/sori/window_class.dart';

/// 계 입장 — 6자리 코드 + 닉네임 → 가입 검증. plan §7.3.
/// (가입 성공 시 계 마당은 Tier 3c — 여기선 확인 후 pop.)
class GyeJoinScreen extends StatefulWidget {
  const GyeJoinScreen({super.key, this.accountSessions});

  final ValueListenable<CloudWriteSession?>? accountSessions;

  @override
  State<GyeJoinScreen> createState() => _GyeJoinScreenState();
}

class _GyeJoinScreenState extends State<GyeJoinScreen> {
  final _code = TextEditingController();
  final _nick = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _code.dispose();
    _nick.dispose();
    super.dispose();
  }

  void _snack(String m) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));

  Future<void> _join() async {
    FocusScope.of(context).unfocus();
    setState(() => _busy = true);
    try {
      final meta = await GyeService.joinGye(
        code: _code.text,
        nickname: _nick.text,
      );
      await Analytics.gyeJoined();
      if (!mounted) {
        return;
      }
      _snack(AppL10n.of(context).gyeJoinedSnack(meta.name));
      Navigator.of(context).pushReplacementNamed('/gye', arguments: meta.code);
    } on GyeException catch (e) {
      if (mounted) {
        _snack(gyeErrorMessage(AppL10n.of(context), e.error));
      }
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);
    return ValueListenableBuilder<CloudWriteSession?>(
      valueListenable:
          widget.accountSessions ?? cloudWriteSessionController.changes,
      builder: (context, session, _) => SoriStandardPage(
        appBarTitle: t.gyeJoinTitle,
        maxWidth: SoriMaxWidth.form,
        children: [
          if (session?.mode != CloudWriteMode.ready) ...[
            Text(t.gyeAccountTransitionPaused, textAlign: TextAlign.center),
            const SizedBox(height: Spacing.md),
          ],
          const SizedBox(height: Spacing.md),
          TextField(
            controller: _code,
            maxLength: GyeService.codeLength,
            textCapitalization: TextCapitalization.characters,
            textInputAction: TextInputAction.next,
            decoration: InputDecoration(
              labelText: t.gyeCodeInputLabel,
              border: const OutlineInputBorder(),
            ),
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              letterSpacing: 4,
            ),
          ),
          const SizedBox(height: Spacing.sm),
          TextField(
            controller: _nick,
            maxLength: GyeService.maxNicknameLen,
            decoration: InputDecoration(
              labelText: t.gyeNicknameLabel,
              hintText: t.gyeNicknameHint,
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: Spacing.lg),
          if (_busy)
            const AppLoading()
          else
            SoriButton(
              label: t.gyeJoinCta,
              icon: Icons.login_rounded,
              accent: SoriColors.primary,
              fullWidth: true,
              onTap: session?.mode == CloudWriteMode.ready ? _join : null,
            ),
        ],
      ),
    );
  }
}
