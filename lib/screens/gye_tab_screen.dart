import 'package:flutter/material.dart';

import '../l10n/generated/app_localizations.dart';
import '../models/gye.dart';
import '../services/gye_service.dart';
import '../widgets/sori/empty_state.dart';
import '../widgets/sori/responsive.dart';
import '../widgets/sori/tokens.dart';
import 'home_screen.dart'; // showGyeChooser

/// **계 탭** — BottomNav 탭 3.
///
/// 내 계 목록을 표시하고 탭하면 [GyeScreen]으로 이동.
/// 내 계가 없으면 [SoriEmptyState] + 만들기/입장 CTA.
/// age-gate는 [showGyeChooser] 내부에서 처리됨.
class GyeTabScreen extends StatelessWidget {
  const GyeTabScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(t.navGye)),
      body: SafeArea(
        child: SoriContentClamp(
          base: const EdgeInsets.fromLTRB(
            Spacing.lg,
            Spacing.md,
            Spacing.lg,
            Spacing.xl,
          ),
          builder: (context, padding) => FutureBuilder<List<GyeMeta>>(
            future: GyeService.myGyeMetas(),
            builder: (context, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              final gyeList = snap.data ?? const <GyeMeta>[];
              if (gyeList.isEmpty) {
                return _EmptyState(padding: padding);
              }
              return _GyeList(gyeList: gyeList, padding: padding);
            },
          ),
        ),
      ),
    );
  }
}

// ── 빈 상태 ───────────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final EdgeInsets padding;

  const _EmptyState({required this.padding});

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);
    return Padding(
      padding: padding,
      child: SoriEmptyState(
        icon: Icons.groups_2_outlined,
        title: t.gyeChooserTitle,
        body: t.gyeEntryDesc,
        ctaLabel: t.gyeChooserCreate,
        onCta: () => showGyeChooser(context),
        secondaryLabel: t.gyeChooserJoin,
        onSecondary: () => showGyeChooser(context),
        accent: SoriColors.primary,
      ),
    );
  }
}

// ── 계 목록 ───────────────────────────────────────────────────────────────────

class _GyeList extends StatelessWidget {
  final List<GyeMeta> gyeList;
  final EdgeInsets padding;

  const _GyeList({required this.gyeList, required this.padding});

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);
    return ListView(
      padding: padding,
      children: [
        for (final gye in gyeList) ...[
          _GyeCard(gye: gye),
          const SizedBox(height: Spacing.md),
        ],
        const SizedBox(height: Spacing.lg),
        TextButton.icon(
          onPressed: () => showGyeChooser(context),
          icon: const Icon(Icons.add_rounded),
          label: Text(t.gyeChooserCreate),
        ),
      ],
    );
  }
}

class _GyeCard extends StatelessWidget {
  final GyeMeta gye;

  const _GyeCard({required this.gye});

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);
    final s = SoriSurfaces.of(context);
    return Card(
      elevation: 0,
      color: s.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(SoriRadius.lg),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(SoriRadius.lg),
        onTap: () =>
            Navigator.pushNamed(context, '/gye', arguments: gye.id),
        child: Padding(
          padding: const EdgeInsets.all(Spacing.md),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: SoriColors.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(SoriRadius.md),
                ),
                alignment: Alignment.center,
                child: const Icon(Icons.groups_2_outlined,
                    color: SoriColors.primary, size: 24),
              ),
              const SizedBox(width: Spacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      gye.name,
                      style: TextStyle(
                        fontFamily: 'Pretendard',
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: s.text,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      t.gyeMembersN(gye.memberCount),
                      style: TextStyle(
                        fontFamily: 'Pretendard',
                        fontSize: 12,
                        color: s.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: s.textMuted),
            ],
          ),
        ),
      ),
    );
  }
}
