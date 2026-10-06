import 'package:flutter/material.dart';
import '../../features/dancheong/dancheong_catalog.dart';
import '../../features/dancheong/dancheong_connections.dart';
import '../../features/dancheong/dancheong_screens.dart';
import '../../features/dancheong/dancheong_store.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../models/ildu_construction_art.dart';
import '../../models/sarangchae_construction.dart';
import '../../models/sori_stage_progression.dart';
import '../../models/yeopjeon_reward_moment.dart';
import '../../models/yeopjeon_wallet.dart';
import '../../services/yeopjeon_service.dart';
import '../../services/local_data_lifetime.dart';
import '../../services/storage_service.dart';
import '../../widgets/app_loading.dart';
import '../../widgets/hanok_asset_image.dart';
import '../../widgets/sori/button.dart';
import '../../widgets/sori/game_reward.dart';
import '../../widgets/sori/hanok_v3_preview.dart';
import '../../widgets/sori/reward_icon.dart';
import '../../widgets/sori/sheet.dart';
import '../../widgets/sori/toast.dart';
import '../../widgets/sori/tokens.dart';
import '../../widgets/sori/yeopjeon_reward_presentation.dart';
import '../../widgets/sori/yeopjeon_wallet_card.dart';
import 'sori_stage_common.dart';

class SoriStageRewardReceiptSheet extends StatefulWidget {
  const SoriStageRewardReceiptSheet({
    super.key,
    required this.receipt,
    this.loadConstruction,
    this.loadConstructionArt,
    this.verifyYeopjeon,
    this.recoverYeopjeon,
  });

  final RewardReceipt receipt;

  /// Tests may supply a verified readback; production rechecks only the ledger.
  @visibleForTesting
  final Future<YeopjeonWallet> Function()? verifyYeopjeon;
  @visibleForTesting
  final Future<YeopjeonTransactionResult> Function()? recoverYeopjeon;
  final Future<SarangchaeConstruction> Function()? loadConstruction;
  final Future<IlDuConstructionArtCatalog> Function()? loadConstructionArt;

  @override
  State<SoriStageRewardReceiptSheet> createState() =>
      _SoriStageRewardReceiptSheetState();
}

class _SoriStageRewardReceiptSheetState
    extends State<SoriStageRewardReceiptSheet> {
  Future<SarangchaeConstruction>? _constructionFuture;
  Future<IlDuConstructionArtCatalog>? _constructionArtFuture;

  bool _detailsExpanded = false;
  final _lifetime = LocalDataLifetime.capture();
  bool _verifying = false;
  bool _resolvedPending = false;
  YeopjeonRewardMoment? _recheckedMoment;
  final Set<String> _knownClaims = {};

  @override
  void initState() {
    super.initState();
    _knownClaims.addAll(
      widget.receipt.yeopjeonReward?.claims.keys ?? const <String>[],
    );
    _knownClaims.addAll(_receiptClaimIds);
  }

  Iterable<String> get _receiptClaimIds => widget.receipt.items
      .where((item) => item.kind == SoriRewardKind.yeopjeon)
      .map((item) => item.identity)
      .whereType<String>();

  Future<void> _recheckYeopjeon() async {
    final receiptId = widget.receipt.receiptId;
    final pending = widget.receipt.pendingYeopjeon;
    if (_verifying || pending == null || !_lifetime.isCurrent) {
      return;
    }
    setState(() => _verifying = true);
    try {
      YeopjeonRewardMoment? independentlyConfirmed;
      YeopjeonWallet? recoveredWallet;
      if (widget.recoverYeopjeon != null || widget.verifyYeopjeon == null) {
        final result =
            await (widget.recoverYeopjeon ??
                YeopjeonService.recoverConfirmedLearningRewards)();
        _lifetime.assertCurrent();
        independentlyConfirmed = result.rewardMoment(
          source: YeopjeonRewardSource.recovery,
        );
        if (result.status == YeopjeonTransactionStatus.granted ||
            result.status == YeopjeonTransactionStatus.noReward ||
            result.status == YeopjeonTransactionStatus.alreadyClaimed) {
          recoveredWallet = result.wallet;
        }
      }
      late final YeopjeonWallet wallet;
      try {
        if (widget.verifyYeopjeon != null) {
          wallet = await widget.verifyYeopjeon!();
        } else {
          final raw = await YeopjeonService.captureBackupJson();
          if (raw == null) {
            throw StateError('Ledger confirmation unavailable');
          }
          wallet = YeopjeonWallet.decode(raw);
        }
      } catch (_) {
        if (recoveredWallet == null) {
          rethrow;
        }
        // A confirmed commit is sufficient even if an optional second read fails.
        wallet = recoveredWallet;
      }
      _lifetime.assertCurrent();
      if (!mounted || widget.receipt.receiptId != receiptId) {
        return;
      }
      final claims = <String, int>{
        for (final entry in wallet.claims.entries)
          if (entry.value > 0 &&
              ((pending.hasClaimBaseline &&
                      !pending.baselineClaimIds.contains(entry.key)) ||
                  independentlyConfirmed?.claims[entry.key] == entry.value) &&
              !_knownClaims.contains(entry.key))
            entry.key: entry.value,
      };
      if (mounted) {
        setState(() {
          _resolvedPending = wallet.completedSourceIds.containsAll(
            pending.sourceIds,
          );
          if (claims.isNotEmpty) {
            _knownClaims.addAll(claims.keys);
            _recheckedMoment = YeopjeonRewardMoment(
              claims: claims,
              balance: wallet.balance,
              source: YeopjeonRewardSource.recovery,
              day: YeopjeonRewardMoment.dayKey(DateTime.now()),
            );
          }
        });
      }
    } catch (_) {
      // Keep the confirmed learning and any earlier reward. Retry never saves XP.
    } finally {
      if (mounted && widget.receipt.receiptId == receiptId) {
        setState(() => _verifying = false);
      }
    }
  }

  @override
  void didUpdateWidget(covariant SoriStageRewardReceiptSheet oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.receipt.receiptId != widget.receipt.receiptId) {
      _verifying = false;
      _resolvedPending = false;
      _recheckedMoment = null;
      _knownClaims
        ..clear()
        ..addAll(widget.receipt.yeopjeonReward?.claims.keys ?? const <String>[])
        ..addAll(_receiptClaimIds);
      _detailsExpanded = false;
      _constructionFuture = null;
      _constructionArtFuture = null;
    }
  }

  void _openDetails() {
    setState(() {
      _detailsExpanded = true;
      if (widget.receipt.hasSarangchaeUpgrade) {
        _constructionFuture =
            (widget.loadConstruction ?? SarangchaeConstruction.load)();
      }
      if (widget.receipt.hasB2ConstructionUpgrade) {
        _constructionArtFuture =
            (widget.loadConstructionArt ?? IlDuConstructionArtCatalog.load)();
      }
    });
  }

  void _openAchievement(RewardReceiptItem item) {
    if (!_lifetime.isCurrent) {
      return;
    }
    if (item.kind == SoriRewardKind.hanokProgress &&
        (widget.receipt.hasSarangchaeUpgrade ||
            widget.receipt.hasB2ConstructionUpgrade)) {
      _openDetails();
      return;
    }
    if (item.kind == SoriRewardKind.stamp) {
      _openDancheong();
      return;
    }
    final route = switch (item.kind) {
      SoriRewardKind.xp || SoriRewardKind.personalBest => '/stats',
      SoriRewardKind.questProgress => '/quests',
      SoriRewardKind.bojagi => '/bojagi',
      SoriRewardKind.gyeLantern => '/gye/hub',
      _ => null,
    };
    final t = AppL10n.of(context);
    showSoriSheet<void>(
      context: context,
      maxTextScaleFactor: double.infinity,
      builder: (detailContext) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            '+${item.amount ?? 0} ${localCopy(context, item.label)}',
            style: SoriTextTheme.of(context).h3,
          ),
          if (item.kind == SoriRewardKind.xp) ...[
            const SizedBox(height: Spacing.md),
            Text(t.rewardXpDetails, style: SoriTextTheme.of(context).body),
          ],
          if (route != null) ...[
            const SizedBox(height: Spacing.lg),
            SoriButton(
              label:
                  item.kind == SoriRewardKind.xp ||
                      item.kind == SoriRewardKind.personalBest
                  ? t.rewardViewProgress
                  : localCopy(context, item.label),
              sculpted: true,
              trailingIcon: Icons.arrow_forward_rounded,
              onTap: () {
                final navigator = Navigator.of(detailContext);
                final isReceiptRoute = ModalRoute.of(context) is PopupRoute;
                navigator.pop();
                if (isReceiptRoute) {
                  navigator.pop();
                }
                navigator.pushNamed(route);
              },
              fullWidth: true,
            ),
          ],
        ],
      ),
    );
  }

  Widget _detailsFailure(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Text(AppL10n.of(context).rewardDetailsUnavailable),
      const SizedBox(height: Spacing.sm),
      SoriButton(
        label: AppL10n.of(context).btnRetry,
        sculpted: true,
        onTap: _openDetails,
      ),
    ],
  );

  void _openDancheong() {
    final navigator = Navigator.of(context);
    try {
      DancheongStore().captureGuard()();
      final motif = confirmedOwnedReceiptMotif(
        widget.receipt,
        knownOwnedMotifs(Storage.earnedStamps),
      );
      navigator.pop();
      if (motif != null) {
        navigator.pushNamed(
          '/dancheong-studio/edit',
          arguments: DancheongEditorArgs(motifSlug: motif),
        );
      } else {
        navigator.pushNamed('/dancheong-studio');
      }
    } catch (_) {
      soriNotice(context, AppL10n.of(context).rewardDetailsUnavailable);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);
    final tt = SoriTextTheme.of(context);
    final receipt = widget.receipt;
    final money = _recheckedMoment ?? receipt.yeopjeonReward;
    final coins = receipt.items.where(
      (item) => item.kind == SoriRewardKind.yeopjeon,
    );
    final compact =
        MediaQuery.sizeOf(context).width < 360 ||
        MediaQuery.textScalerOf(context).scale(16) > 22;
    final sidePadding = compact ? Spacing.md : Spacing.xl;
    return Semantics(
      container: true,
      explicitChildNodes: true,
      liveRegion: money == null && coins.isEmpty,
      label: t.soriStageReceiptSemantics,
      child: SafeArea(
        child: LayoutBuilder(
          builder: (context, bounds) {
            return SizedBox(
              height: bounds.hasBoundedHeight
                  ? bounds.maxHeight
                  : MediaQuery.sizeOf(context).height * .8,
              child: Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      padding: EdgeInsets.fromLTRB(
                        sidePadding,
                        Spacing.sm,
                        sidePadding,
                        Spacing.md,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Semantics(
                                  header: true,
                                  child: Text(
                                    t.soriStageReceiptTitle,
                                    style: tt.h3,
                                  ),
                                ),
                              ),
                              IconButton(
                                key: const Key('receipt-close'),
                                tooltip: t.btnClose,
                                onPressed: () => Navigator.pop(context),
                                icon: const Icon(Icons.close_rounded),
                              ),
                            ],
                          ),
                          const SizedBox(height: Spacing.sm),
                          if (_recheckedMoment != null &&
                              receipt.yeopjeonReward != null)
                            Text(
                              t.yeopjeonEarned(receipt.yeopjeonReward!.amount),
                              style: tt.bodySmall,
                            ),
                          if (money != null) ...[
                            YeopjeonRewardPresentation(
                              key: ValueKey(
                                'receipt-yeopjeon-${money.claims.keys.join('|')}',
                              ),
                              moment: money,
                            ),
                            const SizedBox(height: Spacing.md),
                          ] else if (coins.isNotEmpty) ...[
                            // Older callers can omit presentation provenance. They never
                            // qualify for the daily-first film or a guessed balance.
                            Text(
                              t.yeopjeonEarned(
                                coins.fold<int>(
                                  0,
                                  (sum, item) => sum + (item.amount ?? 0),
                                ),
                              ),
                              key: const ValueKey('receipt-yeopjeon-earned'),
                              style: tt.h2,
                            ),
                            const SizedBox(height: Spacing.md),
                            const YeopjeonWalletCard(compact: true),
                          ],
                          if (receipt.pendingYeopjeon != null &&
                              !_resolvedPending) ...[
                            Text(
                              t.yeopjeonConfirmationPending,
                              key: const ValueKey('receipt-yeopjeon-pending'),
                              style: tt.body,
                            ),
                            const SizedBox(height: Spacing.sm),
                            SoriButton(
                              key: const ValueKey('receipt-recheck-yeopjeon'),
                              sculpted: true,
                              label: t.yeopjeonCheckAgain,
                              loading: _verifying,
                              onTap: _recheckYeopjeon,
                            ),
                            const SizedBox(height: Spacing.md),
                          ],
                          for (final item in receipt.items.where(
                            (item) => item.kind != SoriRewardKind.yeopjeon,
                          ))
                            _RewardLine(
                              item: item,
                              onTap: () => _openAchievement(item),
                            ),
                          if (coins.isNotEmpty && money == null) ...[
                            const SizedBox(height: Spacing.md),
                            SoriButton(
                              label: t.yeopjeonTitle,
                              sculpted: true,
                              onTap: () => showSoriSheet<void>(
                                context: context,
                                builder: (_) => const YeopjeonWalletCard(),
                              ),
                            ),
                          ],
                          if (receipt.hasSarangchaeUpgrade ||
                              receipt.hasB2ConstructionUpgrade) ...[
                            const SizedBox(height: Spacing.md),
                            SoriButton(
                              key: const ValueKey(
                                'receipt-construction-details',
                              ),
                              label: t.rewardConstructionDetails,
                              sculpted: true,
                              icon: Icons.home_work_rounded,
                              onTap: _openDetails,
                            ),
                            if (_detailsExpanded) ...[
                              const SizedBox(height: Spacing.md),
                              if (receipt.hasSarangchaeUpgrade) ...[
                                Text(
                                  t.sarangchaeNewStages(
                                    receipt.sarangchaeStageAfter -
                                        receipt.sarangchaeStageBefore,
                                  ),
                                  style: tt.h3,
                                ),
                                const SizedBox(height: Spacing.sm),
                                Text(
                                  t.sarangchaeStageTransition(
                                    receipt.sarangchaeStageBefore,
                                    receipt.sarangchaeStageAfter,
                                  ),
                                  style: tt.label,
                                ),
                                const SizedBox(height: Spacing.md),
                                FutureBuilder<SarangchaeConstruction>(
                                  future: _constructionFuture,
                                  builder: (context, snapshot) {
                                    if (snapshot.hasError) {
                                      return _detailsFailure(context);
                                    }
                                    if (!snapshot.hasData) {
                                      return const AppLoading();
                                    }
                                    return Column(
                                      children: [
                                        _SarangchaeBeforeAfter(
                                          construction: snapshot.data!,
                                          before: receipt.sarangchaeStageBefore,
                                          after: receipt.sarangchaeStageAfter,
                                        ),
                                        const SizedBox(height: Spacing.lg),
                                        SarangchaeConstructionExperience(
                                          construction: snapshot.data!,
                                          earnedStageCount:
                                              receipt.sarangchaeStageAfter,
                                          minimumSelectableStage:
                                              receipt.sarangchaeStageBefore + 1,
                                          showLockedStages: false,
                                          compact: true,
                                        ),
                                      ],
                                    );
                                  },
                                ),
                              ],
                              if (receipt.hasB2ConstructionUpgrade)
                                FutureBuilder<IlDuConstructionArtCatalog>(
                                  future: _constructionArtFuture,
                                  builder: (context, snapshot) {
                                    if (snapshot.hasError) {
                                      return _detailsFailure(context);
                                    }
                                    if (!snapshot.hasData) {
                                      return const AppLoading();
                                    }
                                    return Column(
                                      children: [
                                        for (final reveal
                                            in snapshot.data!.b2RevealsBetween(
                                              before: receipt
                                                  .b2ConstructionStageBefore,
                                              after: receipt
                                                  .b2ConstructionStageAfter,
                                            )) ...[
                                          _ConstructionArtBeforeAfter(
                                            reveal: reveal,
                                          ),
                                          const SizedBox(height: Spacing.lg),
                                        ],
                                      ],
                                    );
                                  },
                                ),
                            ],
                          ],
                          if (receipt.items.any(
                            (item) => item.kind == SoriRewardKind.stamp,
                          )) ...[
                            const SizedBox(height: Spacing.md),
                            SoriButton(
                              label: t.dancheongReceipt,
                              sculpted: true,
                              fullWidth: true,
                              onTap: _openDancheong,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.fromLTRB(
                      sidePadding,
                      Spacing.sm,
                      sidePadding,
                      Spacing.md,
                    ),
                    child: SoriButton(
                      key: const ValueKey('receipt-continue'),
                      label: t.soriStageReceiptContinue,
                      sculpted: true,
                      accent: SoriColors.gold,
                      trailingIcon: Icons.arrow_forward_rounded,
                      onTap: () => Navigator.pop(context),
                      fullWidth: true,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _ConstructionArtBeforeAfter extends StatelessWidget {
  const _ConstructionArtBeforeAfter({required this.reveal});

  final IlDuConstructionArtReveal reveal;

  @override
  Widget build(BuildContext context) {
    final language = Localizations.localeOf(context).languageCode;
    final text = SoriTextTheme.of(context);
    final after = reveal.afterStage;
    final term = after.glossary.isEmpty
        ? after.title['ko']!
        : after.glossary.first.label['ko']!;
    return Column(
      key: ValueKey('construction-reveal-${reveal.series.id}'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(reveal.series.name['ko']!, style: text.h3),
        const SizedBox(height: Spacing.sm),
        Row(
          children: [
            Expanded(
              child: _ConstructionReceiptImage(
                key: ValueKey('construction-before-${reveal.series.id}'),
                stage: reveal.beforeStage,
                fallbackAspectRatio: after.width / after.height,
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: Spacing.sm),
              child: Icon(Icons.arrow_forward_rounded),
            ),
            Expanded(
              child: _ConstructionReceiptImage(
                key: ValueKey('construction-after-${reveal.series.id}'),
                stage: after,
                fallbackAspectRatio: after.width / after.height,
              ),
            ),
          ],
        ),
        const SizedBox(height: Spacing.md),
        Text(term, style: text.h2),
        const SizedBox(height: Spacing.xs),
        Text(ilduArtText(after.observe, language), style: text.body),
      ],
    );
  }
}

class _ConstructionReceiptImage extends StatelessWidget {
  const _ConstructionReceiptImage({
    super.key,
    required this.stage,
    required this.fallbackAspectRatio,
  });

  final IlDuConstructionArtStage? stage;
  final double fallbackAspectRatio;

  @override
  Widget build(BuildContext context) => AspectRatio(
    aspectRatio: stage == null
        ? fallbackAspectRatio
        : stage!.width / stage!.height,
    child: ClipRRect(
      borderRadius: SoriRadius.brLg,
      child: stage == null
          ? ColoredBox(
              color: SoriSurfaces.of(context).surfaceAlt,
              child: const Center(child: Icon(Icons.home_work_outlined)),
            )
          : HanokAssetImage(
              stage!.asset,
              fit: BoxFit.contain,
              semanticLabel: stage!.title['ko'],
              prefetchPack: false,
            ),
    ),
  );
}

class _SarangchaeBeforeAfter extends StatelessWidget {
  const _SarangchaeBeforeAfter({
    required this.construction,
    required this.before,
    required this.after,
  });

  final SarangchaeConstruction construction;
  final int before;
  final int after;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: AspectRatio(
          aspectRatio: 4 / 3,
          child: KeyedSubtree(
            key: const ValueKey('sarangchae-before-artwork'),
            child: before == 0
                ? Semantics(
                    image: true,
                    label: AppL10n.of(context).sarangchaeStageLocked(0),
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: SoriSurfaces.of(context).surfaceAlt,
                        borderRadius: SoriRadius.brLg,
                      ),
                      child: const Center(
                        child: Icon(Icons.home_work_outlined, size: 28),
                      ),
                    ),
                  )
                : SarangchaeStageArtwork(
                    construction: construction,
                    earnedStageCount: before,
                    sequence: before,
                  ),
          ),
        ),
      ),
      const Padding(
        padding: EdgeInsets.symmetric(horizontal: Spacing.sm),
        child: Icon(Icons.arrow_forward_rounded),
      ),
      Expanded(
        child: AspectRatio(
          aspectRatio: 4 / 3,
          child: KeyedSubtree(
            key: const ValueKey('sarangchae-after-artwork'),
            child: SarangchaeStageArtwork(
              construction: construction,
              earnedStageCount: after,
              sequence: after,
            ),
          ),
        ),
      ),
    ],
  );
}

class _RewardLine extends StatelessWidget {
  const _RewardLine({required this.item, required this.onTap});

  final RewardReceiptItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: Spacing.sm),
    child: SoriRewardSurface(
      onTap: onTap,
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: SoriActivityColors.reward.withValues(alpha: .24),
              borderRadius: BorderRadius.circular(SoriRadius.sm),
            ),
            child: Icon(
              soriRewardIcon(item.kind),
              color: SoriSurfaces.of(context).brightness == Brightness.light
                  ? SoriColors.goldOnLight
                  : SoriColors.gold,
            ),
          ),
          const SizedBox(width: Spacing.md),
          Expanded(
            child: Text(
              '${item.amount == null ? '' : '+${item.amount} '}'
              '${localCopy(context, item.label)}',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(width: Spacing.sm),
          const Icon(Icons.chevron_right_rounded),
        ],
      ),
    ),
  );
}

Future<void> showSoriStageRewardReceipt(
  BuildContext context,
  RewardReceipt receipt,
) => showSoriSheet<void>(
  context: context,
  scrollable: false,
  maxHeightFactor: .96,
  maxTextScaleFactor: double.infinity,
  contentPadding: const EdgeInsets.only(top: Spacing.sm),
  builder: (_) => SoriStageRewardReceiptSheet(receipt: receipt),
);
