import 'package:flutter/material.dart';

import '../../l10n/generated/app_localizations.dart';
import '../../services/tts_service.dart';
import 'tokens.dart';

/// 발음이 안 나올 때 **왜** 안 나오는지 한 줄로 알려준다.
///
/// 왜 필요한가: 2026-08-19 에 OS 음성 폴백을 지웠다. 프리미엄을 못 받으면
/// 이제 아무 소리도 안 난다 — 그건 의도지만, 이유 없는 무음은 고장과
/// 구분이 안 된다. Jin 이 "소리 안나와" 로 겪은 게 정확히 그거였다
/// (그때는 원인이 Android 벨소리 라우팅이었는데 화면에 아무 단서도 없었다).
///
/// 왜 SnackBar 가 아닌가: 스낵바는 `hideCurrentSnackBar()` 직후
/// `showSnackBar()` 가 교체가 아니라 **큐잉**이라 연타하면 쌓이고, 모달이
/// 떠 있으면 자동 소멸 타이머가 아예 안 걸린다 — 책갈피 토스트가 안
/// 사라진다는 불만의 원인이 그것이다. 이건 상태를 그대로 비추는
/// 위젯이라 쌓일 것이 없다.
class TtsUnavailableBanner extends StatelessWidget {
  const TtsUnavailableBanner({super.key, required this.child});

  final Widget child;

  static String messageFor(AppL10n t, TtsUnavailableReason reason) {
    switch (reason) {
      case TtsUnavailableReason.channelOff:
        return t.ttsUnavailableChannelOff;
      case TtsUnavailableReason.quota:
        return t.ttsUnavailableQuota;
      case TtsUnavailableReason.pendingSynthesis:
        return t.ttsUnavailablePending;
      case TtsUnavailableReason.offline:
      case TtsUnavailableReason.timeout:
        return t.ttsUnavailableOffline;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: ValueListenableBuilder<TtsUnavailableReason?>(
            valueListenable: TtsService.unavailable,
            builder: (context, reason, _) {
              if (reason == null) {
                return const SizedBox.shrink();
              }
              return _Strip(reason: reason);
            },
          ),
        ),
      ],
    );
  }
}

class _Strip extends StatelessWidget {
  const _Strip({required this.reason});

  final TtsUnavailableReason reason;

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);
    final tt = SoriTextTheme.of(context);
    final s = SoriSurfaces.of(context);
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        child: Material(
          color: s.surface,
          borderRadius: BorderRadius.circular(SoriRadius.md),
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                Icon(Icons.volume_off_rounded, size: 18, color: s.textMuted),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    TtsUnavailableBanner.messageFor(t, reason),
                    style: tt.caption.copyWith(color: s.text),
                  ),
                ),
                IconButton(
                  key: const Key('tts-unavailable-dismiss'),
                  visualDensity: VisualDensity.compact,
                  iconSize: 18,
                  color: s.textMuted,
                  tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
                  onPressed: TtsService.clearUnavailable,
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
