import 'package:flutter/material.dart';

import '../l10n/generated/app_localizations.dart';
import '../models/gye.dart';
import '../services/gye_service.dart';
import '../widgets/sori/responsive.dart';
import '../widgets/sori/sheet.dart';
import '../widgets/sori/tokens.dart';

/// 계 멤버 목록 + 신고 + 차단. plan §7.4/§9 + Play UGC 정책(사용자 주도 숨김).
/// rules: 멤버만 read, 신고는 본인 reporterUid, 차단은 users/{me}.blockedUids.
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
        title: Text(
          t.gyeMembersTitle,
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: SafeArea(
        child: StreamBuilder<Set<String>>(
          stream: GyeService.blockedUidsStream(),
          builder: (context, bsnap) {
            final blocked = bsnap.data ?? const <String>{};
            return StreamBuilder<List<GyeMember>>(
              stream: GyeService.membersStream(gyeId),
              builder: (context, snap) {
                final members = snap.data ?? const <GyeMember>[];
                if (members.isEmpty) {
                  return const Center(child: CircularProgressIndicator());
                }
                final width = MediaQuery.sizeOf(context).width;
                return ListView.builder(
                  padding: soriClampPadding(
                    width,
                    base: const EdgeInsets.symmetric(
                      horizontal: Spacing.lg,
                      vertical: Spacing.sm,
                    ),
                  ),
                  itemCount: members.length,
                  itemBuilder: (_, i) {
                    final m = members[i];
                    final isSelf = m.uid == me;
                    final isBlocked = blocked.contains(m.uid);
                    return ListTile(
                      onTap: () => _showProfileCard(context, m, isSelf),
                      leading: CircleAvatar(
                        backgroundColor: isBlocked
                            ? s.border
                            : SoriColors.primary.withValues(alpha: 0.18),
                        child: Text(
                          m.nickname.isNotEmpty
                              ? m.nickname.substring(0, 1)
                              : '?',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            color: isBlocked ? s.textDim : SoriColors.primary,
                          ),
                        ),
                      ),
                      title: Text(
                        m.nickname.isEmpty ? '…' : m.nickname,
                        style: isBlocked
                            ? TextStyle(
                                color: s.textDim,
                                decoration: TextDecoration.lineThrough,
                              )
                            : null,
                      ),
                      subtitle: isBlocked
                          ? Text(
                              t.gyeBlockedLabel,
                              style: TextStyle(fontSize: 12, color: s.textDim),
                            )
                          : m.role == GyeRole.owner
                          ? Text(
                              t.gyeRoleOwner,
                              style: TextStyle(
                                fontSize: 12,
                                color: s.textMuted,
                              ),
                            )
                          : null,
                      trailing: isSelf
                          ? Text(
                              t.gyeMemberSelf,
                              style: TextStyle(fontSize: 12, color: s.textDim),
                            )
                          : Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: Icon(
                                    isBlocked
                                        ? Icons.person_add_alt_outlined
                                        : Icons.block_outlined,
                                  ),
                                  tooltip: isBlocked
                                      ? t.gyeUnblock
                                      : t.gyeBlockTitle,
                                  onPressed: () =>
                                      _toggleBlock(context, m, isBlocked),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.flag_outlined),
                                  tooltip: t.gyeReportTitle,
                                  onPressed: () => _report(context, gyeId, m),
                                ),
                              ],
                            ),
                    );
                  },
                );
              },
            );
          },
        ),
      ),
    );
  }
}

/// 멤버 프로필 카드 — denormalize된 level/streak/주간 기여 표시 (탭 시).
/// 듀오링고식 "함께 배우는 사람" 카드: 통계는 자랑이 아니라 인사.
Future<void> _showProfileCard(
  BuildContext context,
  GyeMember m,
  bool isSelf,
) async {
  final t = AppL10n.of(context);
  await showSoriSheet<void>(
    context: context,
    builder: (ctx) {
      final s = SoriSurfaces.of(ctx);
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            radius: 32,
            backgroundColor: SoriColors.primary.withValues(alpha: 0.18),
            child: Text(
              m.nickname.isNotEmpty ? m.nickname.substring(0, 1) : '?',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w900,
                color: SoriColors.primary,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            isSelf ? '${m.nickname} (${t.gyeMemberSelf})' : m.nickname,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
          ),
          if (m.role == GyeRole.owner) ...[
            const SizedBox(height: 2),
            Text(
              '👑 ${t.gyeRoleOwner}',
              style: TextStyle(fontSize: 12, color: s.textMuted),
            ),
          ],
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _ProfileStat(
                icon: Icons.military_tech_outlined,
                color: SoriColors.gold,
                label: t.gyeProfileLevel(m.level),
              ),
              const SizedBox(width: Spacing.lg),
              _ProfileStat(
                icon: Icons.local_fire_department_outlined,
                color: SoriColors.tiger,
                label: t.gyeProfileStreak(m.streakDays),
              ),
              const SizedBox(width: Spacing.lg),
              _ProfileStat(
                icon: Icons.inventory_2_outlined,
                color: SoriColors.primary,
                label: t.gyeProfileWeekly(m.weeklyPacksContributed),
              ),
            ],
          ),
          const SizedBox(height: Spacing.lg),
        ],
      );
    },
  );
}

class _ProfileStat extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  const _ProfileStat({
    required this.icon,
    required this.color,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    final s = SoriSurfaces.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 22, color: color),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.w700,
            color: s.text,
          ),
        ),
      ],
    );
  }
}

/// 차단/해제 토글 — 차단은 확인 다이얼로그, 해제는 즉시.
Future<void> _toggleBlock(
  BuildContext context,
  GyeMember target,
  bool isBlocked,
) async {
  final t = AppL10n.of(context);
  if (isBlocked) {
    final ok = await GyeService.unblockUser(target.uid);
    if (context.mounted && !ok) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(t.gyeErrNetwork)));
    }
    return;
  }
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dctx) => AlertDialog(
      title: Text(t.gyeBlockTitle),
      content: Text(t.gyeBlockBody),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dctx, false),
          child: Text(t.btnCancel),
        ),
        TextButton(
          onPressed: () => Navigator.pop(dctx, true),
          child: Text(t.gyeBlockConfirm),
        ),
      ],
    ),
  );
  if (confirmed == true) {
    final ok = await GyeService.blockUser(target.uid);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(ok ? t.gyeBlockedSnack : t.gyeErrNetwork)),
      );
    }
  }
}

String _reasonLabel(AppL10n t, GyeReportReason r) => switch (r) {
  GyeReportReason.spam => t.gyeReportReasonSpam,
  GyeReportReason.inappropriate => t.gyeReportReasonInappropriate,
  GyeReportReason.harassment => t.gyeReportReasonHarassment,
  GyeReportReason.other => t.gyeReportReasonOther,
};

Future<void> _report(
  BuildContext context,
  String gyeId,
  GyeMember target,
) async {
  final t = AppL10n.of(context);
  // ⚠️ 컨트롤러를 여기서 만들고 `await showDialog` 직후 dispose하면 퇴장
  // 애니메이션 중 리빌드가 "used after disposed" → `_dependents.isEmpty`
  // 레드스크린(실기기 gye 크래시 동일 패턴). State가 소유하게 한다.
  final result = await showDialog<({GyeReportReason reason, String note})>(
    context: context,
    builder: (_) => const _ReportDialog(),
  );
  if (result != null) {
    final ok = await GyeService.reportMember(
      gyeId: gyeId,
      targetUid: target.uid,
      reason: result.reason,
      note: result.note,
    );
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(ok ? t.gyeReportSent : t.gyeErrNetwork)),
      );
    }
  }
}

class _ReportDialog extends StatefulWidget {
  const _ReportDialog();

  @override
  State<_ReportDialog> createState() => _ReportDialogState();
}

class _ReportDialogState extends State<_ReportDialog> {
  final TextEditingController _noteCtrl = TextEditingController();
  GyeReportReason _reason = GyeReportReason.spam;

  @override
  void dispose() {
    _noteCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);
    return AlertDialog(
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
                    _reason == r
                        ? Icons.radio_button_checked
                        : Icons.radio_button_unchecked,
                    color: SoriColors.primary,
                  ),
                  title: Text(_reasonLabel(t, r)),
                  onTap: () => setState(() => _reason = r),
                ),
              TextField(
                controller: _noteCtrl,
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
          onPressed: () => Navigator.pop(context),
          child: Text(t.btnCancel),
        ),
        TextButton(
          onPressed: () =>
              Navigator.pop(context, (reason: _reason, note: _noteCtrl.text)),
          child: Text(t.gyeReportSubmit),
        ),
      ],
    );
  }
}
