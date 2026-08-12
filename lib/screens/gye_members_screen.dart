import 'package:flutter/material.dart';
import '../widgets/app_loading.dart';
import 'package:flutter/foundation.dart';

import '../l10n/generated/app_localizations.dart';
import '../models/gye.dart';
import '../services/gye_service.dart';
import '../services/account/cloud_write_session.dart';
import '../widgets/sori/responsive.dart';
import '../widgets/sori/card.dart';
import '../widgets/sori/sheet.dart';
import '../widgets/sori/tokens.dart';

/// 계 멤버 목록 + 신고 + 차단. plan §7.4/§9 + Play UGC 정책(사용자 주도 숨김).
/// rules: 멤버만 read, 신고는 본인 reporterUid, 차단은 users/{me}.blockedUids.
class GyeMembersScreen extends StatelessWidget {
  final String gyeId;
  final ValueListenable<CloudWriteSession?>? accountSessions;
  final Stream<Set<String>>? blockedUids;
  final Stream<List<GyeMember>>? members;

  const GyeMembersScreen({
    super.key,
    required this.gyeId,
    this.accountSessions,
    this.blockedUids,
    this.members,
  });

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);
    final s = SoriSurfaces.of(context);
    final me = GyeService.currentUid;
    return ValueListenableBuilder<CloudWriteSession?>(
      valueListenable: accountSessions ?? cloudWriteSessionController.changes,
      builder: (context, session, _) {
        final writesAvailable = session?.mode == CloudWriteMode.ready;
        return Scaffold(
          appBar: AppBar(
            title: Text(
              t.gyeMembersTitle,
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
          body: SafeArea(
            child: Column(
              children: [
                if (!writesAvailable)
                  Padding(
                    padding: const EdgeInsets.all(Spacing.md),
                    child: Text(
                      t.gyeAccountTransitionPaused,
                      textAlign: TextAlign.center,
                    ),
                  ),
                Expanded(
                  child: StreamBuilder<Set<String>>(
                    stream: blockedUids ?? GyeService.blockedUidsStream(),
                    builder: (context, bsnap) {
                      final blocked = bsnap.data ?? const <String>{};
                      return StreamBuilder<List<GyeMember>>(
                        stream: members ?? GyeService.membersStream(gyeId),
                        builder: (context, snap) {
                          final members = snap.data ?? const <GyeMember>[];
                          if (members.isEmpty) {
                            // §8.1: 스피너 단독 금지 — 표준 로딩. (계는 항상
                            // 소유자 1명 이상이라 empty ≈ 로딩 중.)
                            return const AppLoading();
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
                            itemCount: members.length + 1,
                            itemBuilder: (_, i) {
                              if (i == 0) {
                                return const Padding(
                                  padding: EdgeInsets.only(bottom: Spacing.sm),
                                  child: _GyeSafetyRulesCard(),
                                );
                              }
                              final m = members[i - 1];
                              final isSelf = m.uid == me;
                              final isBlocked = blocked.contains(m.uid);
                              return ListTile(
                                onTap: () =>
                                    _showProfileCard(context, m, isSelf),
                                leading: CircleAvatar(
                                  backgroundColor: isBlocked
                                      ? s.border
                                      : SoriColors.primary.withValues(
                                          alpha: 0.18,
                                        ),
                                  child: Text(
                                    m.nickname.isNotEmpty
                                        ? m.nickname.substring(0, 1)
                                        : '?',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w800,
                                      color: isBlocked
                                          ? s.textDim
                                          : SoriColors.primary,
                                    ),
                                  ),
                                ),
                                title: Text(
                                  m.nickname.isEmpty ? '…' : m.nickname,
                                  style: isBlocked
                                      ? TextStyle(
                                          color: s.textDim,
                                          decoration:
                                              TextDecoration.lineThrough,
                                        )
                                      : null,
                                ),
                                subtitle: isBlocked
                                    ? Text(
                                        t.gyeBlockedLabel,
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: s.textDim,
                                        ),
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
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: s.textDim,
                                        ),
                                      )
                                    : Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          IconButton(
                                            icon: Icon(
                                              isBlocked
                                                  ? Icons
                                                        .person_add_alt_outlined
                                                  : Icons.block_outlined,
                                            ),
                                            tooltip: isBlocked
                                                ? t.gyeUnblock
                                                : t.gyeBlockTitle,
                                            onPressed: writesAvailable
                                                ? () => _toggleBlock(
                                                    context,
                                                    m,
                                                    isBlocked,
                                                  )
                                                : null,
                                          ),
                                          IconButton(
                                            icon: const Icon(
                                              Icons.flag_outlined,
                                            ),
                                            tooltip: t.gyeReportTitle,
                                            onPressed: writesAvailable
                                                ? () =>
                                                      _report(context, gyeId, m)
                                                : null,
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
              ],
            ),
          ),
        );
      },
    );
  }
}

class _GyeSafetyRulesCard extends StatelessWidget {
  const _GyeSafetyRulesCard();

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);
    return Semantics(
      container: true,
      child: SoriCard(
        tinted: true,
        accent: SoriColors.primary,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.shield_outlined, color: SoriColors.primary),
            const SizedBox(width: Spacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    t.gyeRulesTitle,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: Spacing.xs),
                  Text(t.gyeRulesBody),
                ],
              ),
            ),
          ],
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
