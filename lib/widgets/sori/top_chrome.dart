import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../l10n/generated/app_localizations.dart';
import '../../models/yeopjeon_wallet.dart';
import '../../services/yeopjeon_wallet_notifier.dart';
import 'approved_chrome_assets.dart';
import 'collapsing_header.dart';
import 'pressable.dart';
import 'settings_button.dart';
import 'tokens.dart';
import 'yeopjeon_wallet_card.dart';

class SoriWalletScope extends InheritedNotifier<YeopjeonWalletNotifier> {
  const SoriWalletScope({
    super.key,
    required super.notifier,
    required super.child,
  });

  static YeopjeonWalletNotifier? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<SoriWalletScope>()?.notifier;
}

/// Uses the shell's confirmed wallet; isolated screen previews may provide a
/// confirmed snapshot without starting another wallet owner.
class SoriWalletBadge extends StatelessWidget {
  const SoriWalletBadge({
    super.key,
    this.compact = false,
    this.fallback,
    this.onReturned,
    this.foreground,
  });
  final bool compact;
  final Color? foreground;
  final YeopjeonWallet? fallback;
  final VoidCallback? onReturned;

  @override
  Widget build(BuildContext context) {
    final owner = SoriWalletScope.maybeOf(context);
    final wallet = owner == null ? fallback : owner.value.wallet;
    if (wallet != null) {
      return YeopjeonWalletBadge(
        wallet: wallet,
        compact: compact,
        onReturned: () {
          if (owner != null) unawaited(owner.refresh());
          onReturned?.call();
        },
      );
    }
    final t = AppL10n.of(context);
    return Semantics(
      button: owner != null,
      label: owner?.value.failed == true
          ? t.yeopjeonSaveFailed
          : t.yeopjeonTitle,
      child: SoriPressable(
        onTap: owner == null ? null : () => unawaited(owner.refresh()),
        child: Container(
          key: const ValueKey('yeopjeon-header-unavailable'),
          constraints: const BoxConstraints(minHeight: 48, minWidth: 48),
          padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            color: SoriActivityColors.actionGold,
            borderRadius: SoriRadius.brLg,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const ApprovedChromeImage(
                asset: ApprovedChromeAssets.coinFront,
                size: 32,
              ),
              const SizedBox(width: 4),
              Text(
                '—',
                style: SoriTextTheme.of(
                  context,
                ).label.copyWith(color: foreground),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Shared brand/confirmed money/settings row above each root's native title.
class SoriTopChrome extends StatelessWidget {
  const SoriTopChrome({
    super.key,
    required this.width,
    this.onWalletReturned,
    this.foreground,
  });
  final double width;
  final VoidCallback? onWalletReturned;
  final Color? foreground;

  static ({double height, double walletWidth, bool stacked, bool wordmark})
  metrics(BuildContext context, double width) {
    final scaler = MediaQuery.textScalerOf(context);
    final wallet = SoriWalletScope.maybeOf(context)?.value.wallet;
    final label = wallet == null ? '—' : '${wallet.balance}';
    final style = SoriTextTheme.of(context).label;
    final natural = TextPainter(
      text: TextSpan(text: label, style: style),
      textDirection: Directionality.of(context),
      textScaler: scaler,
    )..layout();
    final naturalWidth = natural.width;
    natural.dispose();
    final stacked = scaler.scale(16) > 22.4;
    final walletWidth = stacked
        ? width
        : math.min(naturalWidth + 52, math.max(64.0, width - 100));
    final measured = TextPainter(
      text: TextSpan(text: label, style: style),
      textDirection: Directionality.of(context),
      textScaler: scaler,
    )..layout(maxWidth: math.max(1, walletWidth - 52));
    final walletHeight = math.max(48.0, measured.height + 8);
    measured.dispose();
    final brand = TextPainter(
      text: TextSpan(text: 'Hangul Sori', style: style),
      textDirection: Directionality.of(context),
      textScaler: scaler,
    )..layout();
    final wordmark =
        stacked || width >= 44 + brand.width + 8 + walletWidth + 56;
    brand.dispose();
    return (
      height: (stacked ? 52 + walletHeight : walletHeight) + 8,
      walletWidth: walletWidth,
      stacked: stacked,
      wordmark: wordmark,
    );
  }

  @override
  Widget build(BuildContext context) {
    final layout = metrics(context, width);
    final brand = Row(
      children: [
        const ApprovedChromeImage(asset: ApprovedChromeAssets.cloud, size: 36),
        if (layout.wordmark) ...[
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              'Hangul Sori',
              style: SoriTextTheme.of(
                context,
              ).label.copyWith(color: foreground),
            ),
          ),
        ],
      ],
    );
    final badge = SizedBox(
      width: layout.walletWidth,
      child: SoriWalletBadge(
        compact: true,
        onReturned: onWalletReturned,
        foreground: foreground,
      ),
    );
    return Padding(
      key: const ValueKey('sori-root-top-chrome'),
      padding: const EdgeInsets.only(bottom: 8),
      child: layout.stacked
          ? Column(
              children: [
                Row(
                  children: [
                    Expanded(child: brand),
                    const SoriSettingsButton(),
                  ],
                ),
                const SizedBox(height: 4),
                badge,
              ],
            )
          : Row(
              children: [
                Expanded(child: brand),
                badge,
                const SizedBox(width: 8),
                const SoriSettingsButton(),
              ],
            ),
    );
  }
}

/// Adds no scroll surface: the existing collapsing title and help/library
/// actions retain their owner, while the top row stays pinned with them.
class SoriRootHeader extends StatelessWidget {
  const SoriRootHeader({
    super.key,
    required this.title,
    this.trailing,
    this.trailingSlots = 1,
    this.foreground,
    this.background,
  });
  final String title;
  final Widget? trailing;
  final int trailingSlots;
  final Color? foreground;
  final Color? background;

  @override
  Widget build(BuildContext context) => SliverLayoutBuilder(
    builder: (context, constraints) {
      final width = constraints.crossAxisExtent;
      return SoriCollapsingHeader(
        title: title,
        collapsedTitle: title,
        titleStyle: SoriTextTheme.of(
          context,
        ).h1.copyWith(fontSize: 26, height: 1.35, color: foreground),
        trailing: trailing,
        trailingSlots: trailingSlots,
        foreground: foreground,
        background: background,
        topChrome: SoriTopChrome(width: width, foreground: foreground),
        topChromeHeight: SoriTopChrome.metrics(context, width).height,
      );
    },
  );
}
