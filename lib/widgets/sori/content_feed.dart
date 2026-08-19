import 'dart:async';
import '../../services/custom_pack_service.dart';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../l10n/generated/app_localizations.dart';
import 'deck_action_bar.dart';
import 'deck_coach.dart';
import 'like_burst.dart';
import 'pressable.dart';
import 'tokens.dart';

/// Vertical content feed. Replaces the four-way Tinder deck on live screens.
///
/// - Vertical fling only. Horizontal drags are ignored (system back wins).
/// - Unrevealed vertical fling = [onSkip] if present, else flip hint.
/// - Revealed vertical fling = [onNext] (know / got-it).
/// - Double-tap / ♡ = [onLike] (not bookmark).
/// - Bookmark / `?` / share are icon stamps, not circular Tinder chrome.
class SoriContentFeed extends StatefulWidget {
  const SoriContentFeed({
    super.key,
    required this.child,
    this.underlay,
    this.flipHintTrigger,
    this.judgmentsEnabled = true,
    this.onBlockedJudgment,
    this.onNext,
    this.onPrevious,
    this.onHard,
    this.onSkip,
    this.onLike,
    this.onBookmark,
    this.onShare,
    this.onFlip,
    this.liked = false,
    this.bookmarked = false,
    this.bookmarkKey,
    this.showLike = true,
    this.showBookmark = true,
    this.showShare = true,
    this.showFlip = true,
    this.skipEnabled = true,
    this.knowLabel,
    this.hardLabel,
    this.skipLabel,
    this.flipLabel,
    this.likeLabel,
    this.shareLabel,
    this.bookmarkLabel,
  });

  final Widget child;
  final Widget? underlay;
  final ValueNotifier<int>? flipHintTrigger;
  final bool judgmentsEnabled;
  final VoidCallback? onBlockedJudgment;

  /// Know / got-it after flip. Also the public hook tests call directly.
  final VoidCallback? onNext;
  final VoidCallback? onPrevious;
  final VoidCallback? onHard;
  final VoidCallback? onSkip;
  final VoidCallback? onLike;
  final VoidCallback? onBookmark;
  final VoidCallback? onShare;
  final VoidCallback? onFlip;

  final bool liked;
  final bool bookmarked;

  /// 담김 여부를 스스로 판정할 한국어 키. 주면 [bookmarked] 없이도
  /// 저장소 변경에 맞춰 아이콘이 채워진다 — 화면이 setState 를 잊어도 된다.
  final String? bookmarkKey;
  final bool showLike;
  final bool showBookmark;
  final bool showShare;
  final bool showFlip;
  final bool skipEnabled;

  final String? knowLabel;
  final String? hardLabel;
  final String? skipLabel;
  final String? flipLabel;
  final String? likeLabel;
  final String? shareLabel;
  final String? bookmarkLabel;

  @override
  State<SoriContentFeed> createState() => _SoriContentFeedState();
}

class _SoriContentFeedState extends State<SoriContentFeed> {
  static const double _commitPx = 64;
  static const double _commitVelocity = 700;

  double _dy = 0;
  int _tapCount = 0;
  Timer? _tapReset;
  Timer? _burstHide;
  bool _burst = false;

  @override
  void dispose() {
    _tapReset?.cancel();
    _burstHide?.cancel();
    super.dispose();
  }

  void _springBack() {
    if (!mounted) {
      return;
    }
    setState(() => _dy = 0);
  }

  void _fireLike() {
    widget.onLike?.call();
    if (SoriMotion.reduceMotion(context)) {
      return;
    }
    _burstHide?.cancel();
    setState(() => _burst = true);
    _burstHide = Timer(const Duration(milliseconds: 420), () {
      if (mounted) {
        setState(() => _burst = false);
      }
    });
  }

  void _onPointerUp(PointerUpEvent event) {
    _tapCount += 1;
    if (_tapCount >= 2) {
      _tapCount = 0;
      _tapReset?.cancel();
      _fireLike();
      return;
    }
    _tapReset?.cancel();
    _tapReset = Timer(const Duration(milliseconds: 280), () {
      _tapCount = 0;
    });
  }

  bool get _canFling {
    if (widget.judgmentsEnabled) {
      return widget.onNext != null ||
          widget.onPrevious != null ||
          (widget.onSkip != null && widget.skipEnabled);
    }
    return widget.onSkip != null && widget.skipEnabled;
  }

  void _onVerticalDragUpdate(DragUpdateDetails details) {
    if (!_canFling) {
      return;
    }
    setState(() => _dy += details.delta.dy);
  }

  void _onVerticalDragEnd(DragEndDetails details) {
    final velocity = details.velocity.pixelsPerSecond.dy;
    final committed = _dy.abs() > _commitPx || velocity.abs() > _commitVelocity;
    if (!committed) {
      _springBack();
      return;
    }
    HapticFeedback.selectionClick();
    if (!widget.judgmentsEnabled) {
      if (widget.onSkip != null && widget.skipEnabled) {
        widget.onSkip!();
      } else {
        widget.onBlockedJudgment?.call();
      }
      _springBack();
      return;
    }
    if (_dy < 0 || velocity < 0) {
      widget.onNext?.call();
    } else if (widget.onPrevious != null) {
      widget.onPrevious!();
    } else if (widget.onSkip != null && widget.skipEnabled) {
      widget.onSkip!();
    } else {
      widget.onNext?.call();
    }
    _springBack();
  }

  VoidCallback? _gated(VoidCallback? action) {
    if (action == null) {
      return null;
    }
    if (widget.judgmentsEnabled) {
      return action;
    }
    return widget.onBlockedJudgment;
  }

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);
    final reduce = SoriMotion.reduceMotion(context);
    final offset = reduce ? 0.0 : _dy * 0.35;
    return Column(
      children: [
        Expanded(
          child: Stack(
            fit: StackFit.passthrough,
            children: [
              if (widget.underlay != null)
                Opacity(opacity: 0.18, child: widget.underlay),
              Listener(
                onPointerUp: _onPointerUp,
                child: GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  onVerticalDragUpdate: _onVerticalDragUpdate,
                  onVerticalDragEnd: _onVerticalDragEnd,
                  child: Transform.translate(
                    offset: Offset(0, offset),
                    child: widget.child,
                  ),
                ),
              ),
              if (widget.flipHintTrigger != null)
                Positioned(
                  top: Spacing.sm,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: SoriDeckFlipHint(trigger: widget.flipHintTrigger!),
                  ),
                ),
              Center(child: SoriLikeBurst(visible: _burst)),
            ],
          ),
        ),
        SoriContentActions(
          onFlip: widget.onFlip,
          onShare: widget.onShare,
          onLike: widget.showLike ? _fireLike : null,
          onBookmark: widget.onBookmark,
          onKnow: _gated(widget.onNext),
          onHard: _gated(widget.onHard),
          onSkip: widget.skipEnabled ? widget.onSkip : null,
          liked: widget.liked,
          bookmarked: widget.bookmarked,
          bookmarkKey: widget.bookmarkKey,
          showFlip: widget.showFlip,
          showShare: widget.showShare,
          showLike: widget.showLike,
          showBookmark: widget.showBookmark,
          judgmentsEnabled: widget.judgmentsEnabled,
          flipLabel: widget.flipLabel ?? t.contentActionFlip,
          shareLabel: widget.shareLabel ?? t.contentActionShare,
          likeLabel: widget.likeLabel ?? t.contentActionLike,
          bookmarkLabel: widget.bookmarkLabel ?? t.contentActionBookmark,
          knowLabel: widget.knowLabel,
          hardLabel: widget.hardLabel,
          skipLabel: widget.skipLabel,
        ),
      ],
    );
  }
}

/// Stamp row (`?` · share · ♡ · bookmark) plus optional SRS text actions.
class SoriContentActions extends StatelessWidget {
  const SoriContentActions({
    super.key,
    this.onFlip,
    this.onShare,
    this.onLike,
    this.onBookmark,
    this.onKnow,
    this.onHard,
    this.onSkip,
    this.liked = false,
    this.bookmarked = false,
    this.bookmarkKey,
    this.showFlip = true,
    this.showShare = true,
    this.showLike = true,
    this.showBookmark = true,
    this.judgmentsEnabled = true,
    required this.flipLabel,
    required this.shareLabel,
    required this.likeLabel,
    required this.bookmarkLabel,
    this.knowLabel,
    this.hardLabel,
    this.skipLabel,
  });

  final VoidCallback? onFlip;
  final VoidCallback? onShare;
  final VoidCallback? onLike;
  final VoidCallback? onBookmark;
  final VoidCallback? onKnow;
  final VoidCallback? onHard;
  final VoidCallback? onSkip;
  final bool liked;
  final bool bookmarked;

  /// 담김 여부를 스스로 판정할 한국어 키. 주면 [bookmarked] 없이도
  /// 저장소 변경에 맞춰 아이콘이 채워진다 — 화면이 setState 를 잊어도 된다.
  final String? bookmarkKey;
  final bool showFlip;
  final bool showShare;
  final bool showLike;
  final bool showBookmark;
  final bool judgmentsEnabled;
  final String flipLabel;
  final String shareLabel;
  final String likeLabel;
  final String bookmarkLabel;
  final String? knowLabel;
  final String? hardLabel;
  final String? skipLabel;

  @override
  Widget build(BuildContext context) {
    final tt = SoriTextTheme.of(context);
    final s = SoriSurfaces.of(context);
    final visibleSkip = skipLabel != null && onSkip != null;
    final showJudgments =
        knowLabel != null || hardLabel != null || visibleSkip;
    return Padding(
      padding: const EdgeInsets.only(top: Spacing.sm),
      child: Column(
        key: const ValueKey('deck-action-bar'),
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              if (showFlip)
                _Stamp(
                  name: 'flip',
                  label: flipLabel,
                  icon: Icons.question_mark_rounded,
                  color: SoriColors.contentCta,
                  onTap: onFlip,
                ),
              if (showShare)
                _Stamp(
                  name: 'share',
                  label: shareLabel,
                  icon: Icons.ios_share_rounded,
                  color: SoriColors.contentCta,
                  onTap: onShare,
                ),
              if (showLike)
                _Stamp(
                  name: 'like',
                  label: likeLabel,
                  icon: liked
                      ? Icons.favorite_rounded
                      : Icons.favorite_border_rounded,
                  color: liked ? SoriColors.like : s.text,
                  onTap: onLike,
                ),
              if (showBookmark)
                // 담긴 상태는 저장소가 직접 말한다. 예전에는 저장 성공을
                // 스낵바로 알렸는데 그게 안 사라졌다 — 알림을 없앤 자리를
                // 채워지는 아이콘이 대신한다.
                ValueListenableBuilder<int>(
                  valueListenable: CustomPackService.revision,
                  builder: (context, _, __) {
                    final key = bookmarkKey;
                    final saved =
                        bookmarked ||
                        (key != null && CustomPackService.containsKorean(key));
                    return _Stamp(
                      name: 'save',
                      label: bookmarkLabel,
                      icon: saved
                          ? Icons.bookmark_rounded
                          : Icons.bookmark_border_rounded,
                      color: saved ? SoriColors.like : s.text,
                      onTap: onBookmark,
                    );
                  },
                ),
            ],
          ),
          if (showJudgments) ...[
            const SizedBox(height: Spacing.sm),
            Row(
              children: [
                if (hardLabel != null)
                  Expanded(
                    child: _TextAction(
                      name: 'dontknow',
                      label: hardLabel!,
                      style: tt.meta.copyWith(
                        color: judgmentsEnabled
                            ? SoriColors.accent
                            : s.textDim,
                      ),
                      onTap: onHard,
                      dimmed: !judgmentsEnabled,
                    ),
                  ),
                if (visibleSkip)
                  Expanded(
                    child: _TextAction(
                      name: 'skip',
                      label: skipLabel!,
                      style: tt.meta,
                      onTap: onSkip,
                    ),
                  ),
                if (knowLabel != null)
                  Expanded(
                    child: _TextAction(
                      name: 'know',
                      label: knowLabel!,
                      style: tt.meta.copyWith(
                        color: judgmentsEnabled
                            ? SoriColors.contentCta
                            : s.textDim,
                        fontWeight: FontWeight.w700,
                      ),
                      onTap: onKnow,
                      dimmed: !judgmentsEnabled,
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _Stamp extends StatelessWidget {
  const _Stamp({
    required this.name,
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final String name;
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      enabled: onTap != null,
      label: label,
      onTap: onTap,
      child: ExcludeSemantics(
        child: SoriPressable(
          onTap: onTap,
          haptic: SoriHaptic.selection,
          child: Container(
            key: deckActionKey(name),
            width: 44,
            height: 44,
            alignment: Alignment.center,
            child: Icon(icon, size: 22, color: color),
          ),
        ),
      ),
    );
  }
}

class _TextAction extends StatelessWidget {
  const _TextAction({
    required this.name,
    required this.label,
    required this.style,
    required this.onTap,
    this.dimmed = false,
  });

  final String name;
  final String label;
  final TextStyle style;
  final VoidCallback? onTap;
  final bool dimmed;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      enabled: onTap != null,
      label: label,
      onTap: onTap,
      child: ExcludeSemantics(
        child: SoriPressable(
          onTap: onTap,
          haptic: SoriHaptic.selection,
          child: ConstrainedBox(
            key: deckActionKey(name),
            constraints: const BoxConstraints(minWidth: 48, minHeight: 44),
            child: Opacity(
              opacity: dimmed ? 0.38 : 1,
              child: Center(
                child: Text(
                  label,
                  style: style,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
