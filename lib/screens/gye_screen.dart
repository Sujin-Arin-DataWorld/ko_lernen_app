import 'package:flutter/material.dart';

import '../l10n/generated/app_localizations.dart';
import '../models/gye.dart';
import '../services/gye_service.dart';
import '../widgets/app_loading.dart';
import '../widgets/sori/empty_state.dart';
import '../widgets/sori/gye_feed.dart';
import '../widgets/sori/gye_hanok.dart';
import '../widgets/sori/responsive.dart';
import '../widgets/sori/sticker_picker.dart';
import '../widgets/sori/tokens.dart';
import '../widgets/sori/dure_board.dart';

/// 계 마당 — 상단(이름·멤버수·주간 목표) / 중간(공동 한옥) / 하단(피드). plan §7.4.
/// (스티커 FAB·전송 = Tier 3d. 피드는 3e Cloud Function이 채움.)
class GyeScreen extends StatelessWidget {
  final String gyeId;

  const GyeScreen({super.key, required this.gyeId});

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);
    final s = SoriSurfaces.of(context);
    return StreamBuilder<GyeMeta?>(
      stream: GyeService.metaStream(gyeId),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting && !snap.hasData) {
          return Scaffold(
            appBar: AppBar(title: Text(t.gyeTitle)),
            body: const AppLoading(),
          );
        }
        final meta = snap.data;
        if (meta == null) {
          return Scaffold(
            appBar: AppBar(title: Text(t.gyeTitle)),
            body: Center(
              child: SoriEmptyState(
                icon: Icons.groups_2_outlined,
                title: t.gyeNotFoundTitle,
                body: t.gyeNotFoundBody,
              ),
            ),
          );
        }
        return Scaffold(
          appBar: AppBar(
            title: Text(meta.name,
                style: const TextStyle(fontWeight: FontWeight.w800)),
            actions: [
              Center(
                child: Text(
                  t.gyeMembersN(meta.memberCount),
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: s.textMuted),
                ),
              ),
              PopupMenuButton<String>(
                onSelected: (v) {
                  if (v == 'leave') {
                    _confirmLeaveGye(context, gyeId);
                  } else if (v == 'members') {
                    Navigator.of(context)
                        .pushNamed('/gye/members', arguments: gyeId);
                  }
                },
                itemBuilder: (_) => [
                  PopupMenuItem(value: 'members', child: Text(t.gyeMembersTitle)),
                  PopupMenuItem(value: 'leave', child: Text(t.gyeLeave)),
                ],
              ),
            ],
          ),
          body: SafeArea(
            child: SoriCenterClamp(
              child: Column(
                children: [
                Padding(
                  padding: const EdgeInsets.all(Spacing.lg),
                  child: DureBoard(
                    gyeId: gyeId,
                    meta: meta,
                    myUid: GyeService.currentUid,
                  ),
                ),
                LayoutBuilder(
                  builder: (context, c) {
                    final h = (c.maxWidth * 0.72).clamp(280.0, 380.0);
                    return SizedBox(height: h, child: GyeHanok(meta: meta));
                  },
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                      Spacing.lg, Spacing.md, Spacing.lg, Spacing.xs),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      t.gyeFeedTitle,
                      style: const TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w800),
                    ),
                  ),
                ),
                Expanded(
                  child: StreamBuilder<List<GyeFeedEvent>>(
                    stream: GyeService.feedStream(gyeId),
                    builder: (context, fsnap) =>
                        GyeFeed(events: fsnap.data ?? const []),
                  ),
                ),
              ],
              ),
            ),
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: () => _openGyeStickerPicker(context, gyeId),
            backgroundColor: SoriColors.primary,
            tooltip: t.gyeStickerSend,
            child: const Icon(Icons.emoji_emotions_outlined),
          ),
        );
      },
    );
  }
}

/// 계 나가기 — 확인 후 탈퇴 + 홈 복귀. plan §7/9.
Future<void> _confirmLeaveGye(BuildContext context, String gyeId) async {
  final t = AppL10n.of(context);
  final ok = await showDialog<bool>(
    context: context,
    builder: (dctx) => AlertDialog(
      content: Text(t.gyeLeaveConfirm),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dctx, false),
          child: Text(t.btnCancel),
        ),
        TextButton(
          onPressed: () => Navigator.pop(dctx, true),
          child: Text(t.gyeLeave),
        ),
      ],
    ),
  );
  if (ok == true) {
    await GyeService.leaveGye(gyeId);
    if (context.mounted) {
      Navigator.of(context).pop();
    }
  }
}

/// 스티커 키보드 시트 → 선택 시 전송. 레이트 초과 시 스낵바. plan §8.2.
void _openGyeStickerPicker(BuildContext context, String gyeId) {
  final t = AppL10n.of(context);
  showModalBottomSheet<void>(
    context: context,
    builder: (sheetCtx) => SafeArea(
      child: StickerPicker(
        onPick: (code) async {
          Navigator.of(sheetCtx).pop();
          final ok = await GyeService.sendSticker(gyeId: gyeId, code: code);
          if (!ok && context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(t.gyeStickerRateLimited)),
            );
          }
        },
      ),
    ),
  );
}
