import 'package:flutter/material.dart';

import '../../l10n/generated/app_localizations.dart';
import '../../models/yeopjeon_wallet.dart';
import '../../services/local_data_lifetime.dart';
import '../../services/account/cloud_write_session.dart';
import '../../services/sound_service.dart';
import '../../services/yeopjeon_service.dart';
import '../../widgets/sori/yeopjeon_coin_scene.dart';
import '../../widgets/sori/yeopjeon_credit_badge.dart';
import '../../widgets/sori/yeopjeon_reward_style.dart';

/// The whole Ildu house, with future forms kept private until assets are approved.
class YeopjeonIlduHouseScreen extends StatefulWidget {
  const YeopjeonIlduHouseScreen({
    super.key,
    required this.initialWallet,
    this.loader,
    this.builder,
    this.onBuilt,
  });
  final YeopjeonWallet initialWallet;
  final Future<YeopjeonWallet> Function()? loader;
  final Future<YeopjeonTransactionResult> Function(YeopjeonBuilding)? builder;
  final VoidCallback? onBuilt;
  @override
  State<YeopjeonIlduHouseScreen> createState() =>
      _YeopjeonIlduHouseScreenState();

  static Future<YeopjeonWallet> readSavedWallet() async {
    final raw = await YeopjeonService.captureBackupJson();
    if (raw == null) {
      throw StateError('No confirmed wallet.');
    }
    return YeopjeonWallet.decode(raw);
  }
}

class _YeopjeonIlduHouseScreenState extends State<YeopjeonIlduHouseScreen> {
  final _lifetime = LocalDataLifetime.capture();
  final _identity = cloudWriteSessionController.identityEpoch;
  late YeopjeonWallet _wallet = widget.initialWallet;
  bool _loading = true, _busy = false, _failed = false, _built = false;
  bool get _current =>
      mounted &&
      _lifetime.isCurrent &&
      _identity == cloudWriteSessionController.identityEpoch;
  YeopjeonBuilding? get _next {
    for (final building in YeopjeonBuilding.values) {
      if (_wallet.ownedStage(building) < _wallet.eligibleStage(building)) {
        return building;
      }
    }
    return null;
  }

  bool get _canBuild =>
      !_loading &&
      !_failed &&
      !_busy &&
      _next != null &&
      _wallet.balance >= YeopjeonWallet.nextConstructionCost;
  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final wallet =
          await (widget.loader ?? YeopjeonIlduHouseScreen.readSavedWallet)();
      if (_current) {
        setState(() {
          _wallet = wallet;
          _failed = false;
        });
      }
    } catch (_) {
      if (_current) {
        setState(() => _failed = true);
      }
    } finally {
      if (_current) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _confirm() async {
    if (!_current || !_canBuild) {
      return;
    }
    // Covers both the dialog and the durable writer, including repeated taps.
    setState(() => _busy = true);
    try {
      final latest =
          await (widget.loader ?? YeopjeonIlduHouseScreen.readSavedWallet)();
      if (!mounted ||
          !_lifetime.isCurrent ||
          _identity != cloudWriteSessionController.identityEpoch) {
        return;
      }
      setState(() => _wallet = latest);
      final building = _next;
      if (building == null ||
          latest.balance < YeopjeonWallet.nextConstructionCost) {
        return;
      }
      final t = AppL10n.of(context);
      const cost = YeopjeonWallet.nextConstructionCost;
      final approved = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => Dialog(
          backgroundColor: YeopjeonRewardStyle.paper,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: Color(0xffae8551)),
          ),
          child: SizedBox(
            width: 340,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Semantics(
                    header: true,
                    child: Text(
                      t.cRewardConfirmTitle,
                      style: YeopjeonRewardStyle.text(22, bold: true),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    t.cRewardConfirmBody(cost),
                    style: YeopjeonRewardStyle.text(15),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '${t.cRewardBalanceNow}: ${latest.balance}',
                    key: const ValueKey('house-confirm-before'),
                    style: YeopjeonRewardStyle.text(15),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${t.cRewardBalanceAfter}: ${latest.balance - cost}',
                    key: const ValueKey('house-confirm-after'),
                    style: YeopjeonRewardStyle.text(15, bold: true),
                  ),
                  const SizedBox(height: 20),
                  YeopjeonAction(
                    key: const ValueKey('house-confirm-spend'),
                    label: t.cRewardUse(cost),
                    onTap: () => Navigator.pop(dialogContext, true),
                  ),
                  const SizedBox(height: 8),
                  YeopjeonAction(
                    label: t.btnCancel,
                    primary: false,
                    onTap: () => Navigator.pop(dialogContext, false),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      if (approved != true || !_current) {
        return;
      }
      final result = await (widget.builder ?? YeopjeonService.buildNext)(
        building,
      );
      if (!_current) {
        return;
      }
      if (result.status == YeopjeonTransactionStatus.built &&
          result.wallet != null) {
        setState(() {
          _wallet = result.wallet!;
          _built = true;
          _failed = false;
        });
        SoundService.complete();
        widget.onBuilt?.call();
      } else {
        // No optimistic balance or art. A retry reads the confirmed ledger.
        setState(() => _failed = true);
      }
    } catch (_) {
      if (_current) {
        setState(() => _failed = true);
      }
    } finally {
      if (_current) {
        setState(() => _busy = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);
    return YeopjeonRewardFrame(
      title: t.cRewardHouse,
      wallet: YeopjeonCreditBadge(
        receiptId: 'house',
        balance: _wallet.balance,
        fromBalance: null,
        start: false,
      ),
      child: YeopjeonResponsiveBody(
        heading: [
          Text(
            _built ? t.cRewardBuiltTitle : t.cRewardSurprise,
            textAlign: TextAlign.center,
            style: YeopjeonRewardStyle.text(18, bold: true),
          ),
          const SizedBox(height: 4),
          Text(
            _built ? t.cRewardBuiltBody : t.cRewardGrowth,
            textAlign: TextAlign.center,
            style: YeopjeonRewardStyle.text(
              14,
              color: YeopjeonRewardStyle.secondary,
            ),
          ),
        ],
        scene: (size) => YeopjeonCoinScene(size: size),
        content: [
          Text(
            t.cRewardCoinHint,
            textAlign: TextAlign.center,
            style: YeopjeonRewardStyle.text(
              12,
              color: YeopjeonRewardStyle.secondary,
            ),
          ),
          const SizedBox(height: 6),
          if (_loading)
            Text(
              t.cRewardWaiting,
              style: YeopjeonRewardStyle.text(14),
              textAlign: TextAlign.center,
            ),
          if (_failed)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                t.yeopjeonSaveFailed,
                key: const ValueKey('house-save-failed'),
                style: YeopjeonRewardStyle.text(13),
                textAlign: TextAlign.center,
              ),
            ),
          YeopjeonGoalPanel(wallet: _wallet, showFuture: true),
        ],
        actions: [
          if (_canBuild || _loading || _busy || _failed)
            YeopjeonAction(
              key: const ValueKey('house-build'),
              label: _failed
                  ? t.btnRetry
                  : t.cRewardBuild(YeopjeonWallet.nextConstructionCost),
              busy: _busy || _loading,
              onTap: _loading
                  ? null
                  : _failed
                  ? () {
                      setState(() => _loading = true);
                      _load();
                    }
                  : _canBuild
                  ? _confirm
                  : null,
            ),
          if (_canBuild || _loading || _busy || _failed)
            const SizedBox(height: 8),
          YeopjeonAction(
            key: const ValueKey('house-close'),
            label: t.cRewardContinue,
            primary: !(_canBuild || _loading || _busy || _failed),
            onTap: _busy ? null : () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }
}
