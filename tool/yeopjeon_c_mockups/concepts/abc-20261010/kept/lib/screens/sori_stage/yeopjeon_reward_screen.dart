import 'package:flutter/material.dart';

import '../../l10n/generated/app_localizations.dart';
import '../../models/sori_stage_progression.dart';
import '../../models/yeopjeon_wallet.dart';
import '../../services/haptic_service.dart';
import '../../services/account/cloud_write_session.dart';
import '../../services/local_data_lifetime.dart';
import '../../services/storage_service.dart';
import '../../widgets/sori/dokkaebi_reward_movie.dart';
import '../../widgets/sori/video_lease.dart';
import '../../widgets/sori/yeopjeon_coin_scene.dart';
import '../../widgets/sori/yeopjeon_credit_badge.dart';
import '../../widgets/sori/yeopjeon_reward_style.dart';
import 'yeopjeon_ildu_house_screen.dart';

/// A confirmed receipt is displayed once. Playback has no grant authority.
class YeopjeonRewardScreen extends StatefulWidget {
  const YeopjeonRewardScreen({
    super.key,
    required this.receipt,
    this.onOtherRewards,
    this.onPresented,
    this.visitHouse,
    this.reviewControls = false,
  });
  final RewardReceipt receipt;
  final VoidCallback? onOtherRewards, onPresented;

  /// Playback controls belong to a labelled review, not the production receipt.
  final bool reviewControls;
  // Review/test seam; production uses the service-backed house route below.
  final Future<YeopjeonWallet?> Function(BuildContext, YeopjeonWallet)?
  visitHouse;
  @override
  State<YeopjeonRewardScreen> createState() => _YeopjeonRewardScreenState();
}

class _YeopjeonRewardScreenState extends State<YeopjeonRewardScreen> {
  final _lifetime = LocalDataLifetime.capture();
  final _identity = cloudWriteSessionController.identityEpoch;
  final _movie = GlobalKey<DokkaebiRewardMovieState>();
  final _presentation = ValueNotifier<double>(0);
  late final _visibility = VideoLeaseEligibilityBinding(onChanged: _policy);
  late YeopjeonWallet _wallet = widget.receipt.yeopjeonWalletAfter!;
  bool _credit = false, _final = false, _motionOff = false;
  bool _visiting = false;
  bool get _current =>
      mounted &&
      _lifetime.isCurrent &&
      _identity == cloudWriteSessionController.identityEpoch;
  bool get _first => widget.receipt.items.any(
    (item) =>
        item.kind == SoriRewardKind.yeopjeon &&
        item.identity?.startsWith('daily:') == true &&
        item.identity!.endsWith(':first'),
  );
  bool get _second => widget.receipt.items.any(
    (item) =>
        item.kind == SoriRewardKind.yeopjeon &&
        item.identity?.startsWith('daily:') == true &&
        item.identity!.endsWith(':second'),
  );
  bool get _review => widget.receipt.items.any(
    (item) =>
        item.kind == SoriRewardKind.yeopjeon &&
        item.identity?.startsWith('daily:') == true &&
        item.identity!.endsWith(':review'),
  );
  int get _support => widget.receipt.items
      .where(
        (item) =>
            item.kind == SoriRewardKind.yeopjeon &&
            item.identity?.startsWith('milestone:') == true,
      )
      .fold(0, (sum, item) => sum + (item.amount ?? 0));
  bool get _reduced =>
      _motionOff ||
      Storage.reducedMotion ||
      MediaQuery.disableAnimationsOf(context);

  @override
  void initState() {
    super.initState();
    HapticService.preferencesChanged.addListener(_policy);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_current) {
        widget.onPresented?.call();
        if (!_first) {
          _cue();
        }
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _visibility.attach(context);
    _policy();
  }

  void _policy() {
    if (!_current) {
      return;
    }
    if (_reduced || !_visibility.isVisible(context)) {
      // Final confirmed balance remains authoritative when motion is stopped.
      _settle();
    }
  }

  void _cue() {
    if (_current && !_credit) {
      setState(() => _credit = true);
    }
  }

  void _settle() {
    if (_current && !_final) {
      setState(() {
        _credit = true;
        _final = true;
      });
    }
  }

  Future<void> _visit() async {
    if (!_current || _visiting) {
      return;
    }
    _visiting = true;
    _movie.currentState?.settle();
    _settle();
    try {
      final visitHouse = widget.visitHouse;
      if (visitHouse != null) {
        final wallet = await visitHouse(context, _wallet);
        if (_current && wallet != null) {
          setState(() => _wallet = wallet);
        }
        return;
      }
      await Navigator.of(context).push<void>(
        MaterialPageRoute(
          builder: (_) => YeopjeonIlduHouseScreen(initialWallet: _wallet),
          settings: const RouteSettings(name: '/rewards/ildu-house'),
        ),
      );
      if (!mounted || !_current) {
        return;
      }
      final wallet = await YeopjeonIlduHouseScreen.readSavedWallet();
      if (_current) {
        setState(() => _wallet = wallet);
      }
    } catch (_) {
      // Keep the last confirmed snapshot until its owner can refresh it.
    } finally {
      _visiting = false;
    }
  }

  Widget _control(String label, IconData icon, VoidCallback? tap, {Key? key}) =>
      YeopjeonMediaControl(key: key, onTap: tap, icon: icon, label: label);

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);
    final movie = _movie.currentState;
    final readyToBuild =
        _wallet.nextConstructionGoal > 0 &&
        _wallet.balance >= YeopjeonWallet.nextConstructionCost;
    final reason = [
      if (_first) t.cRewardFirst,
      if (_second) t.cRewardSecond,
      if (_review) t.cRewardReview,
      if (_support > 0) t.cRewardSupport(_support),
    ].join('\n');
    return YeopjeonRewardFrame(
      compactContent: true,
      title: _review
          ? t.cRewardPracticeTitle
          : _support > 0 && !_first && !_second
          ? t.cRewardSupportTitle
          : t.cRewardTitle,
      wallet: YeopjeonCreditBadge(
        receiptId: widget.receipt.receiptId,
        balance: _wallet.balance,
        fromBalance:
            widget.receipt.canRollYeopjeon &&
                _wallet == widget.receipt.yeopjeonWalletAfter
            ? widget.receipt.yeopjeonBalanceBefore
            : null,
        start: _credit,
        reduceMotion: _final || _reduced,
        onTap: _visit,
        onPresentation: (ms) {
          if (_current) _presentation.value = ms;
        },
      ),
      child: YeopjeonResponsiveBody(
        heading: const [],
        sceneAccessory: ValueListenableBuilder<double>(
          valueListenable: _presentation,
          builder: (_, ms, __) => YeopjeonEarnedAmount(
            amount: widget.receipt.earnedYeopjeon,
            started: _credit || _final,
            settled: _final || _reduced,
            presentationMs: ms,
          ),
        ),
        scene: (size) => _first
            ? DokkaebiRewardMovie(
                key: _movie,
                size: size,
                enabled: !_motionOff,
                onCreditCue: _cue,
                onSettled: _settle,
                onPlaybackChanged: () {
                  if (_current) {
                    setState(() {});
                  }
                },
              )
            : YeopjeonCoinScene(size: size),
        content: [
          if (_first && widget.reviewControls)
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 8,
              runSpacing: 4,
              children: [
                _control(
                  movie?.playing == true ? t.cRewardSkip : t.cRewardReplay,
                  movie?.playing == true
                      ? Icons.skip_next_rounded
                      : Icons.replay_rounded,
                  _reduced
                      ? null
                      : () {
                          if (movie?.playing == true) {
                            movie?.settle();
                            _settle();
                          } else {
                            movie?.replay();
                          }
                        },
                  key: const ValueKey('reward-replay-skip'),
                ),
                if (movie?.playing == true)
                  _control(
                    movie?.soundEnabled == true
                        ? t.cRewardSoundOff
                        : t.cRewardSoundOn,
                    movie?.soundEnabled == true
                        ? Icons.volume_off_outlined
                        : Icons.volume_up_outlined,
                    () {
                      movie?.toggleSound();
                    },
                  ),
                _control(
                  _motionOff ? t.cRewardMotionOn : t.cRewardMotionOff,
                  _motionOff ? Icons.play_arrow_rounded : Icons.pause_rounded,
                  () {
                    setState(() => _motionOff = !_motionOff);
                    if (_motionOff) {
                      _movie.currentState?.settle();
                      _settle();
                    } else {
                      _movie.currentState?.replay();
                    }
                  },
                ),
              ],
            ),
          const SizedBox(height: 4),
          Text(
            reason.isEmpty ? t.cRewardConfirmed : reason,
            textAlign: TextAlign.center,
            style: YeopjeonRewardStyle.text(
              14,
              color: YeopjeonRewardStyle.secondary,
            ),
          ),
          const SizedBox(height: 10),
          ValueListenableBuilder<double>(
            valueListenable: _presentation,
            builder: (_, ms, __) => YeopjeonGoalPanel(
              wallet: _wallet,
              fromBalance: _wallet == widget.receipt.yeopjeonWalletAfter
                  ? widget.receipt.yeopjeonBalanceBefore
                  : null,
              presentationMs: ms,
            ),
          ),
        ],
        actions: [
          if (readyToBuild)
            YeopjeonAction(
              key: const ValueKey('reward-visit-house'),
              label: t.cRewardVisit,
              onTap: _visit,
            ),
          if (readyToBuild) const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: YeopjeonAction(
                  key: const ValueKey('receipt-close'),
                  label: t.cRewardContinue,
                  primary: !readyToBuild,
                  onTap: () {
                    _settle();
                    Navigator.pop(context);
                  },
                ),
              ),
              if (widget.onOtherRewards != null)
                IconButton(
                  key: const ValueKey('reward-other-rewards'),
                  constraints: const BoxConstraints(
                    minWidth: 48,
                    minHeight: 48,
                  ),
                  tooltip: t.cRewardMore,
                  onPressed: widget.onOtherRewards,
                  color: YeopjeonRewardStyle.jade,
                  icon: const Icon(Icons.card_giftcard_outlined),
                ),
            ],
          ),
          if (!readyToBuild) const SizedBox(height: 8),
          if (!readyToBuild)
            YeopjeonAction(
              key: const ValueKey('reward-visit-house'),
              label: t.cRewardVisit,
              primary: false,
              onTap: _visit,
            ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _visibility.disposeBinding();
    HapticService.preferencesChanged.removeListener(_policy);
    _presentation.dispose();
    super.dispose();
  }
}
