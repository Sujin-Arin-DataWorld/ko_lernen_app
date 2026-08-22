import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

import '../l10n/generated/app_localizations.dart';
import '../models/gye.dart';
import '../models/gye_weekly_promise.dart';
import '../widgets/app_loading.dart';
import '../l10n/gye_error_text.dart';
import '../services/analytics_service.dart';
import '../services/gye_service.dart';
import '../services/account/cloud_write_session.dart';
import '../widgets/sori/button.dart';
import '../widgets/sori/card.dart';
import '../widgets/sori/standard_page.dart';
import '../widgets/sori/text_field.dart';
import '../widgets/sori/toast.dart';
import '../widgets/sori/tokens.dart';
import '../widgets/sori/window_class.dart';

typedef GyeCreateOperation =
    Future<GyeMeta> Function({
      required String name,
      required String nickname,
      required String weeklyPromiseId,
    });

/// 계 만들기 — 이름·닉네임 입력 → 6자리 코드 생성·공유. plan §7.3.
/// (가입 후 계 마당은 Tier 3c에서 — 여기선 코드 생성·공유까지.)
class GyeCreateScreen extends StatefulWidget {
  const GyeCreateScreen({super.key, this.accountSessions, this.createGye});

  final ValueListenable<CloudWriteSession?>? accountSessions;
  final GyeCreateOperation? createGye;

  @override
  State<GyeCreateScreen> createState() => _GyeCreateScreenState();
}

class _GyeCreateScreenState extends State<GyeCreateScreen> {
  final _name = TextEditingController();
  final _nick = TextEditingController();
  bool _busy = false;
  String? _code;
  String? _gyeName;
  String _weeklyPromiseId = GyeWeeklyPromises.defaultId;

  @override
  void dispose() {
    _name.dispose();
    _nick.dispose();
    super.dispose();
  }

  void _snack(String m) => soriToast(context, m);

  Future<void> _create() async {
    FocusScope.of(context).unfocus();
    setState(() => _busy = true);
    try {
      final meta = widget.createGye == null
          ? await GyeService.createGye(
              name: _name.text,
              nickname: _nick.text,
              weeklyPromiseId: _weeklyPromiseId,
            )
          : await widget.createGye!(
              name: _name.text,
              nickname: _nick.text,
              weeklyPromiseId: _weeklyPromiseId,
            );
      if (!mounted) {
        return;
      }
      setState(() {
        _code = meta.code;
        _gyeName = meta.name;
      });
      await Analytics.gyeCreated();
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
        appBarTitle: t.gyeCreateTitle,
        maxWidth: SoriMaxWidth.form,
        children: [
          _code == null
              ? _form(t, session?.mode == CloudWriteMode.ready)
              : _created(t),
        ],
      ),
    );
  }

  Widget _form(AppL10n t, bool writesAvailable) {
    final type = SoriTextTheme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (!writesAvailable) ...[
          Semantics(
            container: true,
            liveRegion: true,
            label: t.gyeAccountTransitionPaused,
            child: ExcludeSemantics(
              child: Text(
                t.gyeAccountTransitionPaused,
                textAlign: TextAlign.center,
                style: type.bodySmall,
              ),
            ),
          ),
          const SizedBox(height: Spacing.md),
        ],
        const SizedBox(height: Spacing.md),
        SoriTextField(
          controller: _name,
          maxLength: GyeService.maxNameLen,
          textInputAction: TextInputAction.next,
          labelText: t.gyeNameLabel,
          hintText: t.gyeNameHint,
        ),
        const SizedBox(height: Spacing.sm),
        SoriTextField(
          controller: _nick,
          maxLength: GyeService.maxNicknameLen,
          labelText: t.gyeNicknameLabel,
          hintText: t.gyeNicknameHint,
        ),
        const SizedBox(height: Spacing.sm),
        DropdownButtonFormField<String>(
          initialValue: _weeklyPromiseId,
          isExpanded: true,
          itemHeight: null,
          decoration: InputDecoration(
            labelText: t.gyePromisePickerLabel,
            border: const OutlineInputBorder(),
          ),
          items: GyeWeeklyPromises.all
              .map(
                (promise) => DropdownMenuItem(
                  value: promise.id,
                  child: Text(_promiseLabel(t, promise.id)),
                ),
              )
              .toList(growable: false),
          onChanged: writesAvailable
              ? (id) {
                  if (id != null) setState(() => _weeklyPromiseId = id);
                }
              : null,
        ),
        const SizedBox(height: Spacing.lg),
        if (_busy)
          Semantics(
            container: true,
            liveRegion: true,
            label: t.gyeCreatingLoading,
            child: ExcludeSemantics(
              child: AppLoading(message: t.gyeCreatingLoading),
            ),
          )
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

  String _promiseLabel(AppL10n t, String promiseId) => switch (promiseId) {
    GyeWeeklyPromises.cafeOrder => t.gyePromiseCafeOrder,
    GyeWeeklyPromises.directions => t.gyePromiseDirections,
    GyeWeeklyPromises.selfIntroduction => t.gyePromiseSelfIntroduction,
    _ => t.gyePromiseCafeOrder,
  };

  Widget _created(AppL10n t) {
    final type = SoriTextTheme.of(context);
    final code = _code ?? '';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: Spacing.lg),
        Semantics(
          container: true,
          liveRegion: true,
          label: t.gyeCreatedAnnouncement(_gyeName ?? '', code),
          child: ExcludeSemantics(
            child: Column(
              children: [
                const Icon(
                  Icons.celebration_rounded,
                  size: 56,
                  color: SoriColors.gold,
                ),
                const SizedBox(height: Spacing.md),
                Text(t.gyeCreatedTitle, style: type.h2),
                const SizedBox(height: Spacing.xs),
                Text(_gyeName ?? '', style: type.bodySmall),
                const SizedBox(height: Spacing.lg),
                SoriCard(
                  variant: SoriCardVariant.hero,
                  accent: SoriColors.primary,
                  tinted: true,
                  child: Column(
                    children: [
                      Text(t.gyeCodeLabel, style: type.caption),
                      const SizedBox(height: Spacing.xs),
                      Text(
                        code,
                        style: type.numeral.copyWith(letterSpacing: 6),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: Spacing.lg),
        SoriButton(
          label: t.gyeShareCode,
          icon: Icons.ios_share,
          accent: SoriColors.primary,
          fullWidth: true,
          onTap: () async {
            await SharePlus.instance.share(
              ShareParams(text: t.gyeShareMessage(code)),
            );
          },
        ),
        const SizedBox(height: Spacing.sm),
        SoriButton(
          label: t.gyeCopyCode,
          icon: Icons.copy_rounded,
          variant: SoriButtonVariant.outlined,
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
