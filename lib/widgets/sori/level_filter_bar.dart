import 'package:flutter/material.dart';

import '../../models/learner_level.dart';
import '../../services/storage_service.dart';
import 'chip.dart';
import 'hanok_tokens.dart';
import 'sheet.dart';
import 'tokens.dart';

/// Opens the compact level picker used by play surfaces.
///
/// [levels] contains the caller's exact state values. CEFR values are rendered
/// in canonical upper-case form; a non-CEFR sentinel such as `Alle` or an empty
/// string is rendered with [allLabel]. This keeps existing nullable/legacy
/// state models out of the shared widget while giving every screen one visual
/// and semantic contract.
///
/// The current value and zero-count values are intentionally non-interactive,
/// so a non-null result always represents a real selection change.
Future<String?> showSoriLevelFilterSheet({
  required BuildContext context,
  required String selected,
  required List<String> levels,
  required String allLabel,
  required int Function(String level) countFor,
}) {
  assert(levels.contains(selected), 'selected must be present in levels');
  assert(levels.toSet().length == levels.length, 'levels must be unique');

  return showSoriSheet<String>(
    context: context,
    builder: (sheetContext) => Align(
      alignment: Alignment.centerLeft,
      child: Wrap(
        spacing: Spacing.sm,
        runSpacing: Spacing.sm,
        children: [
          for (final level in levels)
            Builder(
              builder: (context) {
                final parsed = LearnerLevel.fromCode(level);
                final label = parsed?.display ?? allLabel;
                final count = countFor(level);
                final isSelected = level == selected;
                return SoriChip(
                  key: ValueKey('sori-level-sheet-$level'),
                  label: '$label · $count',
                  accent: parsed == null
                      ? SoriColors.info
                      : HanokLevelPalette.of(parsed.code),
                  selected: isSelected,
                  variant: SoriChipVariant.soft,
                  minInteractiveHeight: SoriLayout.chromeRowTouchHeight,
                  maxLines: null,
                  onTap: isSelected || count == 0
                      ? null
                      : () => Navigator.of(sheetContext).pop(level),
                );
              },
            ),
        ],
      ),
    ),
  );
}

/// **SoriLevelFilterBar** — §17/검수#5 레벨 필터의 단일 문법.
///
/// 13곳의 상이한 구현(Wrap 다단·가로 스크롤·수동 Row)을 대체한다. 각 칩은
/// [SoriChip.minInteractiveHeight] 48을 요구한다 — 행 자체 높이도 48로
/// 맞춘다([SoriLayout.chromeRowTouchHeight]; §15 "44dp 시각"은 칩의 실제
/// 필 모양이 8+텍스트+8≈28-32dp로 얇게 그려지는 것으로 만족한다. 가로
/// `ListView` 안에서 `OverflowBox`로 44→48을 흉내 내면 `Viewport`의 기본
/// clipBehavior가 오버플로를 도로 잘라 터치 영역이 줄어든다 — `SoriChromeRow`
/// 의 단일 아이콘 슬롯과 달리 여기선 그 기법을 쓰지 않는다).
///
/// 색은 [HanokLevelPalette] 사계 6색(검수#8) — 레벨마다 다른 색이라 지금
/// 보는 레벨이 색으로도 구분된다(예전엔 전부 `SoriColors.info` 단색).
class SoriLevelFilterBar extends StatefulWidget {
  const SoriLevelFilterBar({
    super.key,
    required this.selected,
    required this.onChanged,
    this.allLabel,
    this.countFor,
  });

  /// 현재 선택 레벨 코드('a1'..'c2'). null = "전체".
  final String? selected;
  final ValueChanged<String?> onChanged;

  /// "전체" 칩 라벨(보통 `t.filterAll`). null이면 그 칩을 안 그린다.
  final String? allLabel;

  /// 레벨별 개수 배지 — `'C1 · 5'` 형식(스몰톡 기존 계약과 동일). null이면
  /// 접미사를 안 붙인다. 0을 돌려주면 그 칩은 탭을 막는다(빈 레벨 안내).
  final int Function(String? levelCode)? countFor;

  /// 화면이 아직 시작 레벨을 정하지 못했을 때 쓰는 단일 판정.
  ///
  /// 검수#5 "시작 레벨 소스 3종 단일화" — `browseLevelCode`(라이브러리 필터
  /// 의도) → `placementLevelCode`(코스 배치) → `userLevelCode`(레거시) →
  /// A1 순으로 첫 값을 채택한다. `Storage`의 세 게터/세터 자체는 손대지
  /// 않는다 — `course_mastery_service.dart`의 계약이 그 위에서 돈다. 이
  /// 함수는 그 3종을 **읽기만** 해서 "필터가 처음 열릴 때 어느 레벨을
  /// 보여줄까"라는 좁은 질문 하나에만 답한다.
  static String resolveStartLevel() =>
      Storage.browseLevelCode ??
      Storage.placementLevelCode ??
      Storage.userLevelCode ??
      LearnerLevel.a1.code;

  @override
  State<SoriLevelFilterBar> createState() => _SoriLevelFilterBarState();
}

class _SoriLevelFilterBarState extends State<SoriLevelFilterBar> {
  final _controller = ScrollController();
  late final Map<String?, GlobalKey> _keys = {
    null: GlobalKey(),
    for (final l in LearnerLevel.values) l.code: GlobalKey(),
  };

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _ensureVisible());
  }

  @override
  void didUpdateWidget(covariant SoriLevelFilterBar old) {
    super.didUpdateWidget(old);
    if (old.selected != widget.selected) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _ensureVisible());
    }
  }

  void _ensureVisible() {
    final ctx = _keys[widget.selected]?.currentContext;
    if (ctx == null || !mounted || !_controller.hasClients) {
      return;
    }
    final target = ctx.findRenderObject();
    if (target == null) {
      return;
    }
    _controller.position.ensureVisible(
      target,
      duration: SoriMotion.fast,
      alignment: 0.5,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = SoriSurfaces.of(context);
    final chips = <Widget>[
      if (widget.allLabel != null) _chip(null, widget.allLabel!),
      for (final level in LearnerLevel.values) _chip(level.code, level.display),
    ];
    return SizedBox(
      height: SoriLayout.chromeRowTouchHeight,
      child: Stack(
        children: [
          ListView.separated(
            controller: _controller,
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: Spacing.lg),
            itemCount: chips.length,
            separatorBuilder: (_, __) => const SizedBox(width: Spacing.xs),
            itemBuilder: (_, i) => chips[i],
          ),
          _edgeFade(s, alignment: Alignment.centerLeft),
          _edgeFade(s, alignment: Alignment.centerRight),
        ],
      ),
    );
  }

  Widget _chip(String? code, String label) {
    final count = widget.countFor?.call(code);
    final text = count == null ? label : '$label · $count';
    final color = code == null ? SoriColors.info : HanokLevelPalette.of(code);
    return Center(
      key: _keys[code],
      child: SoriChip(
        label: text,
        accent: color,
        selected: widget.selected == code,
        variant: SoriChipVariant.soft,
        minInteractiveHeight: SoriLayout.chromeRowTouchHeight,
        onTap: count == 0 ? null : () => widget.onChanged(code),
      ),
    );
  }

  Widget _edgeFade(SoriSurfaces s, {required Alignment alignment}) {
    final left = alignment == Alignment.centerLeft;
    return Positioned(
      left: left ? 0 : null,
      right: left ? null : 0,
      top: 0,
      bottom: 0,
      child: IgnorePointer(
        child: Container(
          width: Spacing.xl,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: left ? Alignment.centerLeft : Alignment.centerRight,
              end: left ? Alignment.centerRight : Alignment.centerLeft,
              colors: [s.bg, s.bg.withValues(alpha: 0)],
            ),
          ),
        ),
      ),
    );
  }
}
