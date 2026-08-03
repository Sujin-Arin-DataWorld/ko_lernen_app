import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

import '../l10n/generated/app_localizations.dart';
import '../widgets/app_loading.dart';
import '../l10n/gye_error_text.dart';
import '../services/gye_service.dart';
import '../services/account/cloud_write_session.dart';
import '../widgets/sori/button.dart';
import '../widgets/sori/card.dart';
import '../widgets/sori/responsive.dart';
import '../widgets/sori/tokens.dart';

/// 계 만들기 — 이름·닉네임 입력 → 6자리 코드 생성·공유. plan §7.3.
/// (가입 후 계 마당은 Tier 3c에서 — 여기선 코드 생성·공유까지.)
class GyeCreateScreen extends StatefulWidget {
  const GyeCreateScreen({super.key, this.accountSessions});

  final ValueListenable<CloudWriteSession?>? accountSessions;

  @override
  State<GyeCreateScreen> createState() => _GyeCreateScreenState();
}

class _GyeCreateScreenState extends State<GyeCreateScreen> {
  final _name = TextEditingController();
  final _nick = TextEditingController();
  bool _busy = false;
  String? _code;
  String? _gyeName;

  @override
  void dispose() {
    _name.dispose();
    _nick.dispose();
    super.dispose();
  }

  void _snack(String m) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));

  Future<void> _create() async {
    FocusScope.of(context).unfocus();
    setState(() => _busy = true);
    try {
      final meta = await GyeService.createGye(
        name: _name.text,
        nickname: _nick.text,
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _code = meta.code;
        _gyeName = meta.name;
      });
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
      builder: (context, session, _) => Scaffold(
        appBar: AppBar(
          title: Text(
            t.gyeCreateTitle,
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
        ),
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) => SingleChildScrollView(
              padding: soriClampPadding(
                constraints.maxWidth,
                base: const EdgeInsets.all(Spacing.lg),
              ),
              child: _code == null
                  ? _form(t, session?.mode == CloudWriteMode.ready)
                  : _created(t),
            ),
          ),
        ),
      ),
    );
  }

  Widget _form(AppL10n t, bool writesAvailable) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (!writesAvailable) ...[
          Text(t.gyeAccountTransitionPaused, textAlign: TextAlign.center),
          const SizedBox(height: Spacing.md),
        ],
        const SizedBox(height: Spacing.md),
        TextField(
          controller: _name,
          maxLength: GyeService.maxNameLen,
          textInputAction: TextInputAction.next,
          decoration: InputDecoration(
            labelText: t.gyeNameLabel,
            hintText: t.gyeNameHint,
            border: const OutlineInputBorder(),
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
            label: t.gyeCreateCta,
            icon: Icons.add_home_outlined,
            accent: SoriColors.primary,
            fullWidth: true,
            onTap: writesAvailable ? _create : null,
          ),
      ],
    );
  }

  Widget _created(AppL10n t) {
    final s = SoriSurfaces.of(context);
    final code = _code ?? '';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: Spacing.lg),
        const Icon(Icons.celebration_rounded, size: 56, color: SoriColors.gold),
        const SizedBox(height: Spacing.md),
        Center(
          child: Text(
            t.gyeCreatedTitle,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
          ),
        ),
        const SizedBox(height: Spacing.xs),
        Center(
          child: Text(_gyeName ?? '', style: TextStyle(color: s.textMuted)),
        ),
        const SizedBox(height: Spacing.lg),
        SoriCard(
          variant: SoriCardVariant.hero,
          accent: SoriColors.primary,
          tinted: true,
          child: Column(
            children: [
              Text(
                t.gyeCodeLabel,
                style: TextStyle(color: s.textMuted, fontSize: 12),
              ),
              const SizedBox(height: 6),
              Text(
                code,
                style: const TextStyle(
                  fontSize: 34,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 6,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: Spacing.lg),
        SoriButton(
          label: t.gyeShareCode,
          icon: Icons.ios_share,
          accent: SoriColors.primary,
          fullWidth: true,
          onTap: () => Share.share(t.gyeShareMessage(code)),
        ),
        const SizedBox(height: Spacing.sm),
        SoriButton(
          label: t.gyeCopyCode,
          icon: Icons.copy_rounded,
          variant: SoriButtonVariant.outlined,
          accent: SoriColors.info,
          fullWidth: true,
          onTap: () {
            Clipboard.setData(ClipboardData(text: code));
            _snack(t.gyeCodeCopied);
          },
        ),
        const SizedBox(height: Spacing.sm),
        SoriButton(
          label: t.gyeOpenCta,
          icon: Icons.meeting_room_outlined,
          variant: SoriButtonVariant.outlined,
          accent: SoriColors.primary,
          fullWidth: true,
          onTap: () => Navigator.of(
            context,
          ).pushReplacementNamed('/gye', arguments: code),
        ),
        const SizedBox(height: Spacing.sm),
        SoriButton(
          label: t.btnClose,
          variant: SoriButtonVariant.ghost,
          fullWidth: true,
          onTap: () => Navigator.of(context).pop(),
        ),
      ],
    );
  }
}
