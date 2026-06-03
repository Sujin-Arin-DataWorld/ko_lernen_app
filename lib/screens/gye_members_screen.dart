import 'package:flutter/material.dart';

import '../l10n/generated/app_localizations.dart';
import '../models/gye.dart';
import '../services/gye_service.dart';
import '../widgets/sori/tokens.dart';

/// 계 멤버 목록 + 신고. plan §7.4/§9. rules: 멤버만 read, 신고는 본인 reporterUid.
class GyeMembersScreen extends StatelessWidget {
  final String gyeId;

  const GyeMembersScreen({super.key, required this.gyeId});

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);
    final s = SoriSurfaces.of(context);
    final me = GyeService.currentUid;
    return Scaffold(
      appBar: AppBar(
        title: Text(t.gyeMembersTitle,
            style: const TextStyle(fontWeight: FontWeight.w800)),
      ),
      body: SafeArea(
        child: StreamBuilder<List<GyeMember>>(
          stream: GyeService.membersStream(gyeId),
          builder: (context, snap) {
            final members = snap.data ?? const <GyeMember>[];
            if (members.isEmpty) {
              return const Center(child: CircularProgressIndicator());
            }
            return ListView.builder(
              itemCount: members.length,
              itemBuilder: (_, i) {
                final m = members[i];
                final isSelf = m.uid == me;
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: SoriColors.primary.withValues(alpha: 0.18),
                    child: Text(
                      m.nickname.isNotEmpty ? m.nickname.substring(0, 1) : '?',
                      style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          color: SoriColors.primary),
                    ),
                  ),
                  title: Text(m.nickname.isEmpty ? '…' : m.nickname),
                  subtitle: m.role == GyeRole.owner
                      ? Text(t.gyeRoleOwner,
                          style: TextStyle(fontSize: 12, color: s.textMuted))
                      : null,
                  trailing: isSelf
                      ? Text(t.gyeMemberSelf,
                          style: TextStyle(fontSize: 12, color: s.textDim))
                      : IconButton(
                          icon: const Icon(Icons.flag_outlined),
                          tooltip: t.gyeReportTitle,
                          onPressed: () => _report(context, gyeId, m),
                        ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

String _reasonLabel(AppL10n t, GyeReportReason r) => switch (r) {
      GyeReportReason.spam => t.gyeReportReasonSpam,
      GyeReportReason.inappropriate => t.gyeReportReasonInappropriate,
      GyeReportReason.harassment => t.gyeReportReasonHarassment,
      GyeReportReason.other => t.gyeReportReasonOther,
    };

Future<void> _report(
    BuildContext context, String gyeId, GyeMember target) async {
  final t = AppL10n.of(context);
  final noteCtrl = TextEditingController();
  var reason = GyeReportReason.spam;
  final submitted = await showDialog<bool>(
    context: context,
    builder: (dctx) => StatefulBuilder(
      builder: (dctx, setLocal) => AlertDialog(
        title: Text(t.gyeReportTitle),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final r in GyeReportReason.values)
                  ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(
                      reason == r
                          ? Icons.radio_button_checked
                          : Icons.radio_button_unchecked,
                      color: SoriColors.primary,
                    ),
                    title: Text(_reasonLabel(t, r)),
                    onTap: () => setLocal(() => reason = r),
                  ),
                TextField(
                  controller: noteCtrl,
                  maxLength: 200,
                  maxLines: 2,
                  decoration: InputDecoration(hintText: t.gyeReportNoteHint),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dctx, false),
            child: Text(t.btnCancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dctx, true),
            child: Text(t.gyeReportSubmit),
          ),
        ],
      ),
    ),
  );
  if (submitted == true) {
    final ok = await GyeService.reportMember(
      gyeId: gyeId,
      targetUid: target.uid,
      reason: reason,
      note: noteCtrl.text,
    );
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(ok ? t.gyeReportSent : t.gyeErrNetwork)),
      );
    }
  }
  noteCtrl.dispose();
}
