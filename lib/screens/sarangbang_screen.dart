import 'package:flutter/material.dart';

import '../l10n/generated/app_localizations.dart';
import '../services/room_placement_service.dart';
import '../services/storage_service.dart';
import '../widgets/sori/empty_state.dart';
import '../widgets/sori/placed_decoration.dart';
import '../widgets/sori/room_layer.dart';
import '../widgets/sori/screen_background.dart';
import '../widgets/sori/sheet.dart';
import '../widgets/sori/tokens.dart';

/// "이 자리를 비운다" 를 나타내는 sentinel.
///
/// 시트를 스와이프로 닫으면 Flutter 가 `null` 을 돌려준다. 그래서 비우기를
/// `null` 로 표현하면 **그냥 닫은 것과 구분되지 않아** 시트를 닫을 때마다
/// 슬롯이 비워진다. 비우기는 반드시 별도 값이어야 한다.
const String kSlotPickClear = ' clear';

/// 사랑방 — 보유 장식을 슬롯에 배치하는 화면 (ADR-002 P1).
///
/// 배치 규칙은 전부 [RoomPlacementService] 에 있다. 이 화면은 "어느 슬롯에
/// 무엇을" 만 전달하고 소유권·카테고리·중복 검증은 하지 않는다 —
/// 화면마다 다른 규칙이 생기는 걸 막기 위해서다.
class SarangbangScreen extends StatefulWidget {
  const SarangbangScreen({super.key});

  @override
  State<SarangbangScreen> createState() => _SarangbangScreenState();
}

class _SarangbangScreenState extends State<SarangbangScreen> {
  /// 배경. 아직 없으면 `errorBuilder` 로 조용히 단색이 된다 —
  /// 에셋 배치 전에도 슬롯 동작을 확인할 수 있어야 한다.
  static const String _bg = 'assets/illustrations/hanok/sarangbang_empty.png';

  late RoomPlacement _placement;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    // 저장값은 손상·구버전일 수 있으므로 항상 정규화해서 읽는다.
    _placement = RoomPlacementService.sanitize(Storage.roomPlacement);
  }

  Future<void> _onTapSlot(SlotDef slot) async {
    final current = _placement[slot.id];
    final candidates = RoomPlacementService.candidatesForSlot(
      slot,
      owned: Storage.ownedDecor,
      placement: _placement,
    );
    // 놓을 것도 뺄 것도 없으면 시트를 열지 않는다 — 빈 목록을 띄우는 건
    // 할 수 없는 일을 광고하는 셈이다 ([RoomLayer] 마커 규칙과 같은 근거).
    if (candidates.isEmpty && current == null) return;

    final picked = await showSoriSheet<String>(
      context: context,
      builder: (ctx) => SlotPickerSheet(
        candidates: candidates,
        current: current,
      ),
    );
    if (!mounted || picked == null) return; // 그냥 닫음 → 변경 없음

    await RoomPlacementService.placeInSlot(
      slot.id,
      picked == kSlotPickClear ? null : picked,
    );
    if (!mounted) return;
    setState(_reload);
  }

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);
    final owned = Storage.ownedDecor.toSet();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          t.sarangbangTitle,
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: SoriScreenBackground(
        child: SafeArea(
          child: owned.isEmpty && _placement.isEmpty
              ? Center(
                  child: SoriEmptyState(
                    asset:
                        'assets/illustrations/reward/reward_bojagi_closed.png',
                    icon: Icons.card_giftcard_rounded,
                    title: t.sarangbangEmptyTitle,
                    body: t.sarangbangEmptyBody,
                  ),
                )
              : Center(
                  child: AspectRatio(
                    // 배경이 3:4 세로 — 슬롯 좌표가 이 비율 기준이라 고정한다.
                    aspectRatio: 3 / 4,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        // 배경 PNG 가 아직 없어도 슬롯 동작은 확인할 수
                        // 있어야 한다 — 없으면 조용히 빈 방 색으로 대체.
                        Image.asset(
                          _bg,
                          fit: BoxFit.cover,
                          errorBuilder: (ctx, _, __) => ColoredBox(
                            color: SoriSurfaces.of(ctx).surfaceAlt,
                          ),
                        ),
                        RoomLayer(
                          slots: kSarangbangSlots,
                          placement: _placement,
                          owned: owned,
                          onTapSlot: _onTapSlot,
                        ),
                      ],
                    ),
                  ),
                ),
        ),
      ),
    );
  }
}

/// 슬롯 하나에 무엇을 놓을지 고르는 시트.
///
/// [showSoriSheet] 셸이 핸들·패딩·최대높이·스크롤을 이미 준다. 그래서 여기서
/// 자체 스크롤러를 만들지 않는다 — 중첩하면 unbounded 제약으로 붕괴한다.
///
/// 고른 결과는 `Navigator.pop` 으로 돌려준다:
/// 슬러그 = 그걸 놓는다 · [kSlotPickClear] = 비운다 · null(그냥 닫음) = 변경 없음.
class SlotPickerSheet extends StatelessWidget {
  /// 이 슬롯에 놓을 수 있는 보유 장식. 순서는 호출자가 정한다.
  final List<String> candidates;

  /// 지금 이 슬롯에 놓여 있는 것 — 체크 표시와 "비우기" 노출 여부를 결정한다.
  final String? current;

  const SlotPickerSheet({
    super.key,
    required this.candidates,
    this.current,
  });

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);
    final s = SoriSurfaces.of(context);
    // 퀘스트 이름과 같은 규칙 — en 이 아니면 독일어(앱 기본 언어).
    final german = Localizations.localeOf(context).languageCode != 'en';

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          header: true,
          child: Text(
            t.sarangbangPickTitle,
            style: TextStyle(
              fontFamily: 'Pretendard',
              color: s.text,
              fontWeight: FontWeight.w800,
              fontSize: 17,
              height: 1.3,
              letterSpacing: -0.2,
            ),
          ),
        ),
        const SizedBox(height: Spacing.md),
        for (final slug in candidates)
          _PickRow(
            slug: slug,
            label: decorName(slug, german: german),
            selected: slug == current,
            onTap: () => Navigator.of(context).pop(slug),
          ),
        if (current != null)
          _PickRow(
            label: t.sarangbangClear,
            selected: false,
            onTap: () => Navigator.of(context).pop(kSlotPickClear),
          ),
      ],
    );
  }
}

/// 시트의 한 줄 — 썸네일 + 이름 (+ 현재 선택 체크).
///
/// [slug] 가 null 이면 "비우기" 행이다.
class _PickRow extends StatelessWidget {
  final String? slug;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _PickRow({
    this.slug,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final s = SoriSurfaces.of(context);
    final thumb = slug;

    return Semantics(
      button: true,
      selected: selected,
      child: InkWell(
        onTap: onTap,
        borderRadius: SoriRadius.brMd,
        child: Padding(
          padding: const EdgeInsets.all(Spacing.sm),
          child: Row(
            children: [
              SizedBox(
                width: 52,
                height: 52,
                // 장식마다 세로 비율이 제각각(병풍은 세로로 길다). 폭만 주면
                // 52 박스를 넘쳐 오버플로가 난다 — FittedBox 로 담는다.
                child: thumb == null
                    ? Icon(
                        Icons.remove_circle_outline,
                        size: 26,
                        color: s.textMuted,
                      )
                    : FittedBox(
                        fit: BoxFit.contain,
                        child: SoriDecorationImage(slug: thumb, size: 46),
                      ),
              ),
              const SizedBox(width: Spacing.md),
              Expanded(
                child: Text(
                  label,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Pretendard',
                    color: thumb == null ? s.textMuted : s.text,
                    fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                    fontSize: 15,
                    height: 1.3,
                  ),
                ),
              ),
              if (selected)
                const Icon(
                  Icons.check_circle_rounded,
                  size: 22,
                  color: SoriColors.primary,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
