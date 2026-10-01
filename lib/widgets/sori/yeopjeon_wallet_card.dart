import '../../models/ildu_construction_art.dart';
import '../../models/sarangchae_construction.dart';
import '../hanok_asset_image.dart';
import 'package:flutter/material.dart';

import '../../l10n/generated/app_localizations.dart';
import '../../models/yeopjeon_wallet.dart';
import '../../services/yeopjeon_service.dart';
import '../../services/sound_service.dart';
import 'button.dart';
import 'card.dart';
import 'celebration.dart';
import 'tokens.dart';
import 'toast.dart';

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
              child: Icon(Icons.toll_rounded, color: SoriColors.gold),
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
                    'assets/illustrations/stamps/stamp_yeopjeon.png',
                    width: 48,
                    height: 48,
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
                  if (wallet.ownedStage(building) > 0)
                    SizedBox(
                      height: 160,
                      child: building == YeopjeonBuilding.sarangchae
                          ? FutureBuilder<SarangchaeConstruction>(
                              future: _sarangchae ??=
                                  SarangchaeConstruction.load(),
                              builder: (context, art) => art.hasData
                                  ? HanokAssetImage(
                                      art.requireData
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
                                          child: HanokAssetImage(
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
