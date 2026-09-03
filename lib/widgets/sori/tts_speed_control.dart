import 'package:flutter/material.dart';

import '../../l10n/generated/app_localizations.dart';
import '../../services/tts_service.dart';
import 'chip.dart';
import 'sheet.dart';
import 'tokens.dart';

/// **전역 음성 속도 컨트롤** (2026-08-13 — "음성 나오는 모든 곳에 속도 바").
///
/// [TtsService.speedNotifier] 하나를 모든 인스턴스가 구독하므로 어느 화면에서
/// 바꿔도 즉시 동기화되고, 다음 발화부터 전역 반영된다 (`Storage.ttsSpeed` 영속).
///
/// 두 표시 모드:
/// - [TtsSpeedControlMode.row] — 아이콘 + 라벨 + 프리셋 칩 행. 듣기가 주 활동인
///   화면(듣기·시나리오·설정)의 컨트롤 영역용.
/// - [TtsSpeedControlMode.compact] — 현재 배속을 보여주는 칩 1개. 탭하면
///   바텀시트로 프리셋 행을 연다. 헤더가 좁은 학습 화면용.
enum TtsSpeedControlMode { row, compact }

/// `AppBar.actions` 슬롯용 compact 칩 래퍼 — 음성이 나오는 화면들의 표준 배치.
class TtsSpeedAction extends StatelessWidget {
  const TtsSpeedAction({super.key});

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.only(right: Spacing.sm),
      child: Center(child: TtsSpeedControl()),
    );
  }
}

class TtsSpeedControl extends StatelessWidget {
  final TtsSpeedControlMode mode;

  /// Minimum height for every speed action. Existing dense callers retain
  /// 44dp; learning/quest surfaces can opt into the 48dp outer-UI contract.
  final double minInteractiveHeight;

  /// 값 변경 직후 호출 (설정 화면의 '안녕하세요' 미리듣기 등).
  final ValueChanged<double>? onChanged;

  const TtsSpeedControl({
    super.key,
    this.mode = TtsSpeedControlMode.compact,
    this.minInteractiveHeight = 44,
    this.onChanged,
  }) : assert(minInteractiveHeight >= 44);

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<double>(
      valueListenable: TtsService.speedNotifier,
      builder: (context, speed, _) {
        switch (mode) {
          case TtsSpeedControlMode.row:
            return _buildRow(context, speed);
          case TtsSpeedControlMode.compact:
            return _buildCompact(context, speed);
        }
      },
    );
  }

  String _fmt(double v) {
    // 1.0 → '1', 0.75 → '0.75' (독일어권도 소수점 표기는 ×배속 관례를 따른다).
    final s = v.toStringAsFixed(2);
    return s.replaceFirst(RegExp(r'0+$'), '').replaceFirst(RegExp(r'\.$'), '');
  }

  Widget _buildRow(BuildContext context, double speed) {
    final t = AppL10n.of(context);
    final s = SoriSurfaces.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.speed_rounded, size: 16, color: s.textMuted),
            const SizedBox(width: Spacing.xs),
            Text(t.ttsSpeedLabel, style: SoriTextTheme.of(context).caption),
          ],
        ),
        const SizedBox(height: Spacing.xs),
        Wrap(
          spacing: Spacing.xs,
          runSpacing: Spacing.xs,
          children: [
            for (final preset in TtsService.speedPresets)
              SoriChip(
                label: t.ttsSpeedChip(_fmt(preset)),
                accent: SoriColors.info,
                selected: (speed - preset).abs() < 0.01,
                fontSize: 13.5,
                horizontalPadding: 7,
                minInteractiveHeight: minInteractiveHeight,
                onTap: () {
                  // ignore: discarded_futures
                  TtsService.setSpeed(preset);
                  onChanged?.call(preset);
                },
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildCompact(BuildContext context, double speed) {
    final t = AppL10n.of(context);
    return SoriChip(
      icon: Icons.speed_rounded,
      label: t.ttsSpeedChip(_fmt(speed)),
      accent: SoriColors.info,
      minInteractiveHeight: minInteractiveHeight,
      onTap: () {
        // ignore: discarded_futures
        showSoriSheet<void>(
          context: context,
          builder: (ctx) => Padding(
            padding: const EdgeInsets.fromLTRB(
              Spacing.lg,
              Spacing.sm,
              Spacing.lg,
              Spacing.lg,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppL10n.of(ctx).ttsSpeedSheetTitle,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: Spacing.md),
                TtsSpeedControl(
                  mode: TtsSpeedControlMode.row,
                  minInteractiveHeight: minInteractiveHeight,
                  onChanged: onChanged,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
