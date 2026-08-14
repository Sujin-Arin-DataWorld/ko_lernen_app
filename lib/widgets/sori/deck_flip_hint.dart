import 'dart:async';

import 'package:flutter/material.dart';

import '../../l10n/generated/app_localizations.dart';
import 'tokens.dart';

/// 플립 전 수평 판정 시도 시 카드 상단에 뜨는 힌트 칩.
class DeckFlipHintChip extends StatelessWidget {
  const DeckFlipHintChip({super.key, required this.visible});

  final bool visible;

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);
    final tt = SoriTextTheme.of(context);
    return IgnorePointer(
      child: AnimatedOpacity(
        opacity: visible ? 1 : 0,
        duration: SoriMotion.fast,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: SoriSurfaces.of(context).raised,
            borderRadius: SoriRadius.brPill,
            border: Border.all(
              color: SoriColors.primary.withValues(alpha: 0.35),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: Spacing.md,
              vertical: Spacing.xs,
            ),
            child: Text(
              t.deckFlipFirstHint,
              style: tt.caption.copyWith(color: SoriColors.primaryDark),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );
  }
}

/// 3초 자동 소멸 힌트 상태. 화면 State 가 이 믹스인으로 칩을 켠다.
mixin DeckFlipHintMixin<T extends StatefulWidget> on State<T> {
  bool deckFlipHintVisible = false;
  Timer? _deckFlipHintTimer;

  void showDeckFlipHint() {
    _deckFlipHintTimer?.cancel();
    setState(() => deckFlipHintVisible = true);
    _deckFlipHintTimer = Timer(const Duration(seconds: 3), () {
      if (!mounted) {
        return;
      }
      setState(() => deckFlipHintVisible = false);
    });
  }

  @override
  void dispose() {
    _deckFlipHintTimer?.cancel();
    super.dispose();
  }
}
