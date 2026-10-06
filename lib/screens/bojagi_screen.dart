import 'dart:async';

import 'package:flutter/material.dart';

import '../l10n/generated/app_localizations.dart';
import '../models/cultural_glossary.dart';
import '../services/account/cloud_write_session.dart';
import '../services/catalog_history_lease.dart';
import '../services/cultural_glossary_repository.dart';
import '../services/decoration_reward_service.dart';
import '../services/local_data_lifetime.dart';
import '../services/storage_service.dart';
import '../widgets/app_error.dart';
import '../widgets/app_loading.dart';
import '../widgets/sori/c_gallery/c_materials.dart';
import '../widgets/sori/empty_state.dart';
import '../widgets/sori/placed_decoration.dart';
import '../widgets/sori/pressable.dart';
import '../widgets/sori/reward_chest/reward_chest_screen.dart';
import '../widgets/sori/reward_chest/reward_cultural_story.dart';
import '../widgets/sori/standard_page.dart';
import '../widgets/sori/toast.dart';
import '../widgets/sori/tokens.dart';
import '../widgets/sori/window_class.dart';

// Stable route remains /bojagi; the approved presentation is a najeon chest.
const kBojagiClosed =
    'assets/illustrations/reward_chest/najeon_chest_closed.png';
const kBojagiOpen = 'assets/illustrations/reward_chest/najeon_chest_open.png';

/// The service commits one item before the approved opening plays. Recovered
/// receipts settle directly on that same item; replay and culture are read-only.
class BojagiScreen extends StatefulWidget {
  const BojagiScreen({super.key, this.offerLoader, this.singleOfferLoader});
  final Future<DecorationRewardOffer> Function()? offerLoader;
  final Future<SingleDecorationRewardOffer> Function()? singleOfferLoader;

  @override
  State<BojagiScreen> createState() => _BojagiScreenState();
}

class _BojagiScreenState extends State<BojagiScreen> {
  SingleDecorationRewardOffer? _offer;
  DecorationRewardOffer? _legacyState;
  DecorationRewardReceipt? _receipt;
  CulturalGlossary? _glossary;
  bool _loading = true, _loadFailed = false, _busy = false;
  bool _animate = false, _storyFailed = false;
  int _generation = 0, _replay = 0;
  CatalogHistoryLease? _lease;

  @override
  void initState() {
    super.initState();
    cloudWriteSessionController.changes.addListener(_accountChanged);
    LocalDataLifetime.changes.addListener(_accountChanged);
    unawaited(_load());
  }

  @override
  void dispose() {
    _generation++;
    cloudWriteSessionController.changes.removeListener(_accountChanged);
    LocalDataLifetime.changes.removeListener(_accountChanged);
    super.dispose();
  }

  void _accountChanged() {
    if (mounted) {
      unawaited(_load());
    }
  }

  bool _current(int generation, CatalogHistoryLease lease) =>
      mounted && generation == _generation && lease.isCurrent;

  Future<void> _load() async {
    final generation = ++_generation;
    final lease = CatalogHistoryLease.capture();
    _lease = lease;
    setState(() {
      _loading = true;
      _loadFailed = false;
      _busy = false;
      _receipt = null;
      _offer = null;
      _legacyState = null;
      _animate = false;
      _glossary = null;
      _storyFailed = false;
    });
    try {
      // Historical test seams can still classify non-ready source states.
      final legacy = await widget.offerLoader?.call();
      final offer =
          legacy != null && legacy.state != DecorationRewardOfferState.ready
          ? null
          : await (widget.singleOfferLoader?.call() ??
                DecorationRewardService.loadSingleOffer());
      if (!_current(generation, lease)) {
        return;
      }
      setState(() {
        _legacyState = legacy;
        _offer = offer;
        _receipt = offer?.receipt;
        _loading = false;
      });
      unawaited(_loadStory(generation, lease));
    } catch (_) {
      if (_current(generation, lease)) {
        setState(() {
          _loading = false;
          _loadFailed = true;
        });
      }
    }
  }

  Future<void> _loadStory(int generation, CatalogHistoryLease lease) async {
    try {
      final glossary = await CulturalGlossaryRepository.load();
      if (!_current(generation, lease)) {
        return;
      }
      setState(() {
        _glossary = glossary;
        _storyFailed = glossary == null;
      });
    } catch (_) {
      if (_current(generation, lease)) {
        setState(() => _storyFailed = true);
      }
    }
  }

  Future<void> _open() async {
    final offer = _offer, lease = _lease;
    if (_busy ||
        offer?.state != SingleDecorationRewardOfferState.ready ||
        lease == null ||
        !lease.isCurrent) {
      return;
    }
    final generation = _generation;
    setState(() => _busy = true);
    try {
      final result = await DecorationRewardService.claimSingleOffer(offer!);
      if (!_current(generation, lease)) {
        return;
      }
      final receipt = result.receipt;
      if (result.result != DecorationRewardClaimResult.claimed ||
          receipt == null) {
        await _load();
        return;
      }
      setState(() {
        _receipt = receipt;
        _animate = true;
        _busy = false;
        _replay++;
      });
    } catch (_) {
      if (_current(generation, lease)) {
        setState(() {
          _busy = false;
          _loadFailed = true;
        });
      }
    }
  }

  Future<bool> _acknowledge() async {
    final receipt = _receipt, lease = _lease;
    if (_busy || receipt == null || lease == null || !lease.isCurrent) {
      return false;
    }
    final generation = _generation;
    setState(() => _busy = true);
    try {
      final saved = await DecorationRewardService.acknowledgeSingleReward(
        receipt,
      );
      if (!_current(generation, lease)) {
        return false;
      }
      if (!saved) {
        throw StateError('Receipt acknowledgment unavailable.');
      }
      setState(() {
        _receipt = receipt.acknowledge();
        _busy = false;
      });
      return true;
    } catch (_) {
      if (mounted && _current(generation, lease)) {
        setState(() => _busy = false);
        soriToast(context, AppL10n.of(context).loadErrorTryAgain);
      }
      return false;
    }
  }

  Future<void> _place() async {
    final lease = _lease, generation = _generation;
    final saved = await _acknowledge();
    if (!mounted || !saved || lease == null || !_current(generation, lease)) {
      return;
    }
    if (ModalRoute.of(context)?.settings.arguments == 'furnish') {
      Navigator.of(context).pop();
    } else {
      // Keeping the receipt route alive restores the same object on return.
      await Navigator.of(context).pushNamed('/sarangbang/furnish');
    }
  }

  Future<void> _next() async {
    final lease = _lease, generation = _generation;
    final saved = await _acknowledge();
    if (mounted && saved && lease != null && _current(generation, lease)) {
      await _load();
    }
  }

  Future<void> _archive() async {
    if (_busy) {
      return;
    }
    final lease = _lease;
    if (lease == null || !lease.isCurrent) {
      return;
    }
    final generation = _generation;
    setState(() => _busy = true);
    try {
      await DecorationRewardService.archiveCompleteCollectionBox(
        expectedSourceQuestId:
            _offer?.sourceQuestId ?? _legacyState?.sourceQuestId,
      );
      if (_current(generation, lease)) {
        await _load();
      }
    } catch (_) {
      if (_current(generation, lease)) {
        setState(() {
          _busy = false;
          _loadFailed = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);
    final receipt = _receipt;
    if (receipt != null) {
      final slug = receipt.decorationSlug;
      final asset = 'assets/illustrations/decorations/$slug.png';
      final termId = _glossary?.termIdForDecoration(slug);
      final entry = termId == null ? null : _glossary?.entry(termId);
      return Stack(
        children: [
          RewardChestScreen(
            key: ValueKey('receipt-${receipt.id}-$_replay'),
            itemAsset: asset,
            itemName: decorName(t, slug),
            subtitle: decorTerm(t, slug),
            itemDescription: entry
                ?.localized(Localizations.localeOf(context).languageCode)
                .meaning,
            totalXp: receipt.totalXp,
            xpLevel: receipt.xpLevel,
            xpToNext: receipt.xpToNext,
            previewSecond: _animate ? null : 4,
            showBlueMagic: true,
            continueBusy: _busy,
            continueLabel: t.rewardChestPlaceSarangbang,
            onContinue: () => unawaited(_place()),
            onLearnMore: entry == null
                ? null
                : () => showRewardCulturalStory(
                    context,
                    entry: entry,
                    itemAsset: asset,
                    itemName: decorName(t, slug),
                  ),
          ),
          Positioned(
            top: MediaQuery.paddingOf(context).top + 4,
            right: 8,
            child: SafeArea(
              top: false,
              bottom: false,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_storyFailed)
                    IconButton(
                      tooltip: t.btnRetry,
                      onPressed: () => _loadStory(_generation, _lease!),
                      icon: const Icon(Icons.refresh_rounded),
                    ),
                  if (Storage.pendingBoxes.isNotEmpty)
                    IconButton(
                      tooltip: t.bojagiNext,
                      onPressed: _busy ? null : () => unawaited(_next()),
                      icon: const Icon(Icons.card_giftcard_rounded),
                    ),
                  IconButton(
                    tooltip: t.rewardChestReplay,
                    onPressed: _busy
                        ? null
                        : () {
                            setState(() {
                              _animate = true;
                              _replay++;
                            });
                          },
                    icon: const Icon(Icons.replay_rounded),
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    }
    return SoriStandardFrame(
      appBarTitle: t.rewardChestTitle,
      maxWidth: SoriMaxWidth.prose,
      builder: (context, padding) => SingleChildScrollView(
        key: const ValueKey('bojagi-scroll'),
        padding: padding,
        child: _body(t),
      ),
    );
  }

  Widget _body(AppL10n t) {
    if (_loading) {
      return AppLoading(message: t.bojagiLoading);
    }
    if (_loadFailed) {
      return AppError(message: t.bojagiProblemBody, onRetry: _load);
    }
    final state = _offer?.state;
    if (state == SingleDecorationRewardOfferState.ready) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            t.rewardChestTitle,
            style: SoriTextTheme.of(context).h2,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Semantics(
            button: true,
            label: t.rewardChestOpen,
            enabled: !_busy,
            child: SoriPressable(
              key: const Key('bojagi_knot'),
              onTap: _busy ? null : () => unawaited(_open()),
              child: ExcludeSemantics(
                child: Image.asset(
                  kBojagiClosed,
                  width: 300,
                  height: 300,
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          CMaterialAction(
            key: const ValueKey('reward-chest-open-action'),
            label: _busy ? t.bojagiLoading : t.rewardChestOpen,
            onTap: _busy ? null : () => unawaited(_open()),
            child: _busy
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: CPalette.ink,
                    ),
                  )
                : null,
          ),
        ],
      );
    }
    final legacy = _legacyState?.state;
    if (state == SingleDecorationRewardOfferState.noPendingBox ||
        legacy == DecorationRewardOfferState.noPendingBox) {
      return SoriEmptyState(
        asset: kBojagiClosed,
        title: t.bojagiEmptyTitle,
        body: t.bojagiEmptyBody,
      );
    }
    if (state == SingleDecorationRewardOfferState.collectionComplete ||
        legacy == DecorationRewardOfferState.collectionComplete) {
      return SoriEmptyState(
        asset: kBojagiOpen,
        title: t.bojagiCollectionCompleteTitle,
        body: t.bojagiCollectionCompleteBody,
        ctaLabel: t.bojagiArchiveComplete,
        onCta: _busy ? null : _archive,
      );
    }
    if (state == SingleDecorationRewardOfferState.noEligibleCandidates ||
        legacy == DecorationRewardOfferState.noEligibleCandidates) {
      return SoriEmptyState(
        asset: kBojagiOpen,
        title: t.bojagiAllOwnedTitle,
        body: t.bojagiAllOwnedBody,
      );
    }
    return AppError(message: t.bojagiProblemBody, onRetry: _load);
  }
}
