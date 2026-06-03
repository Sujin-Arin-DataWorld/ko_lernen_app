import 'package:flutter/material.dart';

import '../l10n/generated/app_localizations.dart';
import '../l10n/gye_error_text.dart';
import '../services/gye_service.dart';
import '../widgets/sori/button.dart';
import '../widgets/sori/tokens.dart';

/// 계 입장 — 6자리 코드 + 닉네임 → 가입 검증. plan §7.3.
/// (가입 성공 시 계 마당은 Tier 3c — 여기선 확인 후 pop.)
class GyeJoinScreen extends StatefulWidget {
  const GyeJoinScreen({super.key});

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
    return Scaffold(
      appBar: AppBar(
        title: Text(t.gyeJoinTitle,
            style: const TextStyle(fontWeight: FontWeight.w800)),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(Spacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
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
                const Center(child: CircularProgressIndicator())
              else
                SoriButton(
                  label: t.gyeJoinCta,
                  icon: Icons.login_rounded,
                  accent: SoriColors.primary,
                  fullWidth: true,
                  onTap: _join,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
