import 'package:flutter/material.dart';

import '../../l10n/generated/app_localizations.dart';
import 'tokens.dart';

/// **스트릭 시각화** — Duolingo 스타일 (홈 상단)
///
/// 🔥 N일 연속 표시 + pulse 애니메이션.
/// 미스 경고(26시간 이상 미활동)는 주황색 → 빨강으로 변경.
class StreakDisplay extends StatefulWidget {
  final int days;
  final DateTime lastActivity;

  const StreakDisplay({
    super.key,
    required this.days,
    required this.lastActivity,
  });

  @override
  State<StreakDisplay> createState() => _StreakDisplayState();
}

class _StreakDisplayState extends State<StreakDisplay>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseCtrl;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);
    final isMissing =
        DateTime.now().difference(widget.lastActivity).inHours > 26;

    return ScaleTransition(
      scale: Tween<double>(begin: 1.0, end: 1.08)
          .animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut)),
      child: GestureDetector(
        onTap: () => _showStreakInfo(context, t),
        child: Chip(
          avatar: Text(
            '🔥',
            style: TextStyle(fontSize: 20),
          ),
          label: Text(
            t.streakDisplay(widget.days),
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: isMissing ? SoriColors.danger : SoriColors.primary,
            ),
          ),
          backgroundColor: isMissing
              ? SoriColors.danger.withValues(alpha: 0.12)
              : SoriColors.primary.withValues(alpha: 0.12),
          shape: StadiumBorder(
            side: BorderSide(
              color: isMissing ? SoriColors.danger : SoriColors.primary,
              width: 1.5,
            ),
          ),
        ),
      ),
    );
  }

  void _showStreakInfo(BuildContext context, AppL10n t) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(t.streakDialogTitle),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(t.streakDialogSubtitle),
            const SizedBox(height: 12),
            Text(
              '🏆 ${t.streakDialogEarned}',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 16),
            Text(t.streakDialogCurrent(widget.days)),
            Text(
              t.streakDialogLastActivity(
                _formatTime(widget.lastActivity),
              ),
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(t.btnClose),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pushNamed(context, '/vocab');
            },
            child: Text(t.streakDialogLearnNow),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);

    if (diff.inMinutes < 1) return '방금 전';
    if (diff.inHours < 1) return '${diff.inMinutes}분 전';
    if (diff.inDays < 1) return '${diff.inHours}시간 전';
    if (diff.inDays == 1) return '어제';
    return '${diff.inDays}일 전';
  }
}
