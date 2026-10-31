import '../../models/ildu_construction_art.dart';
import '../../models/sarangchae_construction.dart';
import 'package:flutter/material.dart';
import 'c_gallery/c_palette.dart';

import '../../l10n/generated/app_localizations.dart';
import '../../models/yeopjeon_wallet.dart';
import '../../services/yeopjeon_service.dart';
import '../../services/sound_service.dart';
import 'button.dart';
import 'card.dart';
import 'celebration.dart';
import 'tokens.dart';
import 'activity_illustration.dart';
import 'toast.dart';
import 'pressable.dart';
import 'sheet.dart';
import 'ildu_r16_process_image.dart';
import 'approved_chrome_assets.dart';

/// Saved money and construction ownership, with no optimistic spending.
class YeopjeonWalletCard extends StatefulWidget {
  const YeopjeonWalletCard({
    super.key,
    this.compact = false,
    this.onBuilt,
    this.loader,
    this.builder,
  });
  final bool compact;
  final VoidCallback? onBuilt;
  final Future<YeopjeonWallet> Function()? loader;
  final Future<YeopjeonTransactionResult> Function(YeopjeonBuilding)? builder;

  @override
  State<YeopjeonWalletCard> createState() => _YeopjeonWalletCardState();
}

class _YeopjeonWalletCardState extends State<YeopjeonWalletCard> {
  late Future<YeopjeonWallet> _future;
  Future<IlDuConstructionArtCatalog>? _art;
  Future<SarangchaeConstruction>? _sarangchae;
  bool _busy = false;
  bool _failed = false;
  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    _future = (widget.loader ?? _readSavedWallet)();
  }

  Future<YeopjeonWallet> _readSavedWallet() async {
    final raw = await YeopjeonService.captureBackupJson();
    if (raw == null) {
      throw StateError('Wallet is not initialized.');
    }
    return YeopjeonWallet.decode(raw);
  }

  void _retryLoad() {
    setState(() {
      _future = (widget.loader ?? YeopjeonService.loadCurrent)();
    });
  }

  Future<void> _build(YeopjeonBuilding building) async {
    if (_busy) {
      return;
    }
    setState(() {
      _busy = true;
      _failed = false;
    });
    try {
      final result = await (widget.builder ?? YeopjeonService.buildNext)(
        building,
      );
      if (!mounted) {
        return;
      }
      if (result.status == YeopjeonTransactionStatus.built &&
          result.wallet != null) {
        setState(() {
          _future = Future.value(result.wallet!);
        });
        SoundService.complete();
        SoriCelebration.burst(context, particles: 26);
        soriNotice(context, AppL10n.of(context).yeopjeonBuilt);
        widget.onBuilt?.call();
      } else {
        setState(() {
          _failed = true;
          _reload();
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _failed = true;
          _reload();
        });
      }
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);
    final type = SoriTextTheme.of(context);
    return FutureBuilder<YeopjeonWallet>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return SoriButton.outlined(
            label: t.yeopjeonSaveFailed,
            onTap: _retryLoad,
          );
        }
        if (!snapshot.hasData) {
          return const SizedBox(
            height: 48,
            child: Center(
              child: ApprovedChromeImage(
                asset: ApprovedChromeAssets.coinFront,
                size: 32,
              ),
            ),
          );
        }
        final wallet = snapshot.requireData;
        return SoriCard(
          key: const ValueKey('yeopjeon-wallet'),
          variant: widget.compact
              ? SoriCardVariant.compact
              : SoriCardVariant.hanji,
          accent: SoriColors.tiger,
          tinted: true,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Image.asset(
                    SoriArtwork.yeopjeon,
                    width: 72,
                    height: 72,
                    excludeFromSemantics: true,
                    errorBuilder: (_, __, ___) =>
                        const Icon(Icons.toll_rounded, size: 40),
                  ),
                  const SizedBox(width: Spacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(t.yeopjeonTitle, style: type.label),
                        Semantics(
                          liveRegion: true,
                          child: Text(
                            t.yeopjeonBalance(wallet.balance),
                            key: const ValueKey('yeopjeon-balance'),
                            style: type.h2,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: Spacing.sm),
              Text(t.yeopjeonIntro, style: type.bodySmall),
              if (widget.compact && wallet.nextConstructionGoal > 0) ...[
                const SizedBox(height: Spacing.sm),
                Text(
                  t.yeopjeonConstructionGoal(
                    YeopjeonWallet.nextConstructionCost,
                  ),
                  style: type.label,
                ),
              ] else if (!widget.compact) ...[
                for (final building in YeopjeonBuilding.values) ...[
                  const SizedBox(height: Spacing.lg),
                  Text(
                    building == YeopjeonBuilding.sarangchae
                        ? t.yeopjeonSarangchae
                        : t.yeopjeonB2,
                    style: type.h3,
                  ),
                  if (wallet.ownedStage(building) >
                      (building == YeopjeonBuilding.sarangchae ? 1 : 0))
                    SizedBox(
                      height: 160,
                      child: building == YeopjeonBuilding.sarangchae
                          ? FutureBuilder<SarangchaeConstruction>(
                              future: _sarangchae ??=
                                  SarangchaeConstruction.load(),
                              builder: (context, art) => art.hasData
                                  ? IlDuR16ProcessImage(
                                      processId:
                                          'ildu.${art.requireData.stage(wallet.sarangchaeOwnedStage).stageId}',
                                      fallbackAsset: art.requireData
                                          .stage(wallet.sarangchaeOwnedStage)
                                          .assetPath,
                                      fit: BoxFit.contain,
                                      cacheHeight: 320,
                                      semanticLabel: t.yeopjeonProgress(
                                        wallet.sarangchaeOwnedStage,
                                        wallet.sarangchaeEligibleStage,
                                      ),
                                    )
                                  : const SizedBox.shrink(),
                            )
                          : FutureBuilder<IlDuConstructionArtCatalog>(
                              future: _art ??=
                                  IlDuConstructionArtCatalog.load(),
                              builder: (context, art) {
                                if (!art.hasData) {
                                  return const SizedBox.shrink();
                                }
                                final reveals = art.requireData
                                    .b2RevealsBetween(
                                      before: 0,
                                      after: wallet.b2OwnedStage,
                                    );
                                return Row(
                                  children: [
                                    for (final reveal in reveals.reversed.take(
                                      1,
                                    ))
                                      Expanded(
                                        child: AnimatedSwitcher(
                                          duration: SoriMotion.respect(
                                            context,
                                            const Duration(milliseconds: 250),
                                          ),
                                          child: IlDuR16ProcessImage(
                                            processId:
                                                'ildu.${reveal.afterStage.id}',
                                            fallbackAsset:
                                                reveal.afterStage.asset,
                                            key: ValueKey(
                                              reveal.afterStage.asset,
                                            ),
                                            fit: BoxFit.contain,
                                            cacheHeight: 320,
                                            semanticLabel: ilduArtText(
                                              reveal.series.name,
                                              Localizations.localeOf(
                                                context,
                                              ).languageCode,
                                            ),
                                          ),
                                        ),
                                      ),
                                  ],
                                );
                              },
                            ),
                    ),
                  Text(
                    t.yeopjeonProgress(
                      wallet.ownedStage(building),
                      wallet.eligibleStage(building),
                    ),
                    style: type.bodySmall,
                  ),
                  const SizedBox(height: Spacing.sm),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: LinearProgressIndicator(
                      minHeight: 10,
                      value: wallet.eligibleStage(building) == 0
                          ? 0
                          : wallet.ownedStage(building) /
                                wallet.eligibleStage(building),
                      color: SoriColors.primary,
                    ),
                  ),
                  const SizedBox(height: Spacing.sm),
                  if (wallet.ownedStage(building) <
                      wallet.eligibleStage(building))
                    SoriButton.filled(
                      key: ValueKey('yeopjeon-build-${building.name}'),
                      label: t.yeopjeonBuild(
                        YeopjeonWallet.nextConstructionCost,
                      ),
                      feedbackOnTap: false,
                      loading: _busy,
                      onTap:
                          _busy ||
                              wallet.balance <
                                  YeopjeonWallet.nextConstructionCost
                          ? null
                          : () => _build(building),
                    )
                  else
                    Text(
                      wallet.ownedStage(building) ==
                              (building == YeopjeonBuilding.sarangchae
                                  ? SarangchaeConstruction.stageCount
                                  : b2ConstructionStageCount)
                          ? t.yeopjeonConstructionComplete
                          : t.yeopjeonNeedLearning,
                      style: type.bodySmall,
                    ),
                ],
                if (_failed) ...[
                  const SizedBox(height: Spacing.sm),
                  Text(t.yeopjeonSaveFailed, style: type.bodySmall),
                ],
                if (wallet.nextConstructionGoal > wallet.balance) ...[
                  const SizedBox(height: Spacing.sm),
                  Text(
                    t.yeopjeonNeedCoins(
                      wallet.nextConstructionGoal - wallet.balance,
                    ),
                    style: type.bodySmall,
                  ),
                ],
                ExpansionTile(
                  tilePadding: EdgeInsets.zero,
                  title: Text(t.yeopjeonTitle, style: type.label),
                  children: [Text(t.yeopjeonRules, style: type.bodySmall)],
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

/// The header reads the already-confirmed progression snapshot, never a
/// preview balance. Opening and closing the wallet refreshes its owner.
class YeopjeonWalletBadge extends StatelessWidget {
  const YeopjeonWalletBadge({
    super.key,
    required this.wallet,
    this.onReturned,
    this.compact = false,
    this.jadeSurface = false,
  });
  final YeopjeonWallet wallet;
  final VoidCallback? onReturned;
  final bool compact;
  final bool jadeSurface;

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);
    return Semantics(
      button: true,
      label: '${t.yeopjeonTitle}. ${t.yeopjeonBalance(wallet.balance)}',
      child: SoriPressable(
        pressOffsetY: 2,
        releaseCurve: SoriMotion.gentle,
        tactileTilt: true,
        onTap: () async {
          await showSoriSheet<void>(
            context: context,
            builder: (_) => const YeopjeonWalletCard(),
          );
          if (context.mounted) {
            onReturned?.call();
          }
        },
        child: _ConfirmedBalanceFeedback(
          balance: wallet.balance,
          child: Container(
            key: const ValueKey('yeopjeon-header-balance'),
            constraints: const BoxConstraints(minHeight: 48),
            padding: EdgeInsets.symmetric(
              horizontal: compact ? 8 : Spacing.md,
              vertical: compact ? 4 : 0,
            ),
            decoration: BoxDecoration(
              color: jadeSurface
                  ? CPalette.deepJade
                  : SoriActivityColors.actionGold,
              borderRadius: SoriRadius.brLg,
              border: jadeSurface ? Border.all(color: SoriColors.gold) : null,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                ApprovedChromeImage(
                  asset: ApprovedChromeAssets.coinFront,
                  size: compact ? 32 : 38,
                ),
                SizedBox(width: compact ? 4 : Spacing.sm),
                if (compact)
                  Flexible(
                    child: Text(
                      '${wallet.balance}',
                      style: SoriTextTheme.of(context).label.copyWith(
                        color: jadeSurface ? CPalette.paper : null,
                      ),
                    ),
                  )
                else
                  Text(
                    '${wallet.balance}',
                    style: SoriTextTheme.of(context).label,
                  ),
                if (!compact) const Icon(Icons.chevron_right_rounded, size: 18),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Emphasizes a confirmed ledger change without inventing intermediate balances.
/// Initial reads, repeated snapshots and returns from a hidden route stay quiet.
class _ConfirmedBalanceFeedback extends StatefulWidget {
  const _ConfirmedBalanceFeedback({required this.balance, required this.child});
  final int balance;
  final Widget child;

  @override
  State<_ConfirmedBalanceFeedback> createState() =>
      _ConfirmedBalanceFeedbackState();
}

class _ConfirmedBalanceFeedbackState extends State<_ConfirmedBalanceFeedback>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    value: 1,
    duration: SoriMotion.medium,
  );
  bool _motionAllowed = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  void _settle() {
    _controller.stop();
    _controller.value = 1;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _motionAllowed =
        !SoriMotion.reduceMotion(context) &&
        TickerMode.valuesOf(context).enabled;
    if (!_motionAllowed) _settle();
  }

  @override
  void didUpdateWidget(covariant _ConfirmedBalanceFeedback oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.balance == widget.balance) return;
    final lifecycle = WidgetsBinding.instance.lifecycleState;
    if (_motionAllowed &&
        (lifecycle == null || lifecycle == AppLifecycleState.resumed)) {
      _controller.forward(from: 0);
    } else {
      _settle();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) _settle();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _controller,
    child: widget.child,
    builder: (_, child) => CustomPaint(
      key: const ValueKey('yeopjeon-confirmed-balance-feedback'),
      foregroundPainter: _BalanceUpdateRim(_controller.value),
      child: child,
    ),
  );
}

class _BalanceUpdateRim extends CustomPainter {
  const _BalanceUpdateRim(this.progress);
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final envelope = progress <= .5 ? progress * 2 : (1 - progress) * 2;
    if (envelope <= 0) return;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        (Offset.zero & size).deflate(1.5),
        const Radius.circular(SoriRadius.lg - 1.5),
      ),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = const Color(0xfffff7de).withValues(alpha: envelope * .9),
    );
  }

  @override
  bool shouldRepaint(covariant _BalanceUpdateRim oldDelegate) =>
      oldDelegate.progress != progress;
}
