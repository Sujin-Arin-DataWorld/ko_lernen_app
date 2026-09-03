import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/access_snapshot.dart';
import '../l10n/generated/app_localizations.dart';
import '../services/analytics_service.dart';
import '../services/premium_service.dart';
import '../widgets/sori/activity_illustration.dart';
import '../widgets/sori/button.dart';
import '../widgets/sori/page_header.dart';
import '../widgets/sori/responsive.dart';
import '../widgets/sori/toast.dart';
import '../widgets/sori/tokens.dart';

/// Monthly Premium paywall, using only the store's localized price.
///
/// Wird via `/paywall` oder [PremiumService.gate] geöffnet und schließt bei
/// erfolgreichem Kauf/Restore mit `Navigator.pop(context, true)`. Ist kein
/// RevenueCat-Offering verfügbar, bleibt der Kauf deaktiviert. Ein Gast wird
/// zuerst zur vorhandenen Kontoverbindung geführt.
class PaywallScreen extends StatefulWidget {
  const PaywallScreen({
    super.key,
    this.placement = 'unspecified',
    this.offeringLoader,
    this.purchaseOperation,
    this.restoreOperation,
    this.requiresSignIn,
    this.accessListenable,
    this.openLink,
  });

  /// Woher die Paywall geöffnet wurde (Analytics placement). Vom Gate/Route
  /// gesetzt; Standard 'unspecified'.
  final String placement;
  final Future<Offering?> Function()? offeringLoader;
  final Future<PremiumPurchaseOutcome> Function(Package package)?
  purchaseOperation;
  final Future<PremiumRestoreOutcome> Function()? restoreOperation;
  final bool Function()? requiresSignIn;
  final ValueListenable<AccessSnapshot?>? accessListenable;
  final Future<bool> Function(Uri uri)? openLink;

  @override
  State<PaywallScreen> createState() => _PaywallScreenState();
}

class _PaywallScreenState extends State<PaywallScreen> {
  Offering? _offering;
  bool _loadingOffering = true;
  bool _busy = false;
  bool _cancelled = false;
  bool get _requiresSignIn =>
      widget.requiresSignIn?.call() ?? PremiumService.requiresSignIn;
  AccessSnapshot? get _access =>
      (widget.accessListenable ?? accessSnapshotNotifier).value;
  bool get _active => _access?.hasPremium ?? false;

  @override
  void initState() {
    super.initState();
    _load();
    Analytics.paywallViewed(placement: widget.placement);
  }

  Future<void> _load() async {
    Offering? offering;
    try {
      offering =
          await (widget.offeringLoader?.call() ??
              PremiumService.currentOffering());
    } on Object {
      debugPrint('PaywallScreen: offering load failed.');
    }
    if (!mounted) return;
    setState(() {
      _offering = offering;
      _loadingOffering = false;
    });
  }

  Package? get _monthly => monthlyOfferingPackage(_offering);

  String _priceLabel(AppL10n t) {
    final pkg = _monthly;
    if (pkg == null) {
      return t.paywallNotAvailable;
    }
    return '${pkg.storeProduct.priceString} ${t.paywallPricePerMonth}';
  }

  Future<void> _start() async {
    if (_requiresSignIn) {
      await _connect();
      return;
    }
    final t = AppL10n.of(context);
    final pkg = _monthly;
    if (pkg == null) {
      soriToast(context, t.paywallNotAvailable);
      return;
    }
    Analytics.subscribeStarted(
      productId: pkg.storeProduct.identifier,
      placement: widget.placement,
    );
    setState(() {
      _busy = true;
      _cancelled = false;
    });
    final outcome =
        await (widget.purchaseOperation?.call(pkg) ??
            PremiumService.purchase(pkg));
    if (!mounted) return;
    setState(() => _busy = false);
    switch (outcome) {
      case PremiumPurchaseOutcome.purchased:
        soriNotice(context, t.paywallSuccess);
        Navigator.of(context).pop(true);
      case PremiumPurchaseOutcome.cancelled:
        setState(() => _cancelled = true);
        return;
      case PremiumPurchaseOutcome.pending:
        soriNotice(context, t.paywallPending);
      case PremiumPurchaseOutcome.signInRequired:
        soriNotice(context, t.paywallSignInRequired);
        await _connect();
      case PremiumPurchaseOutcome.stale:
        return;
      case PremiumPurchaseOutcome.failed:
        soriToast(context, t.paywallFailed);
    }
  }

  Future<void> _restore() async {
    if (_requiresSignIn) {
      await _connect();
      return;
    }
    final t = AppL10n.of(context);
    setState(() {
      _busy = true;
      _cancelled = false;
    });
    final outcome =
        await (widget.restoreOperation?.call() ?? PremiumService.restore());
    if (!mounted) return;
    setState(() => _busy = false);
    switch (outcome) {
      case PremiumRestoreOutcome.restored:
        soriNotice(context, t.paywallSuccess);
        Navigator.of(context).pop(true);
      case PremiumRestoreOutcome.none:
        soriNotice(context, t.paywallRestoreNone);
      case PremiumRestoreOutcome.pending:
        soriNotice(context, t.paywallPending);
      case PremiumRestoreOutcome.signInRequired:
        soriNotice(context, t.paywallSignInRequired);
        await _connect();
      case PremiumRestoreOutcome.cancelled:
      case PremiumRestoreOutcome.stale:
        return;
      case PremiumRestoreOutcome.failed:
        soriToast(context, t.paywallRestoreFailed);
    }
  }

  Future<void> _connect() async {
    await Navigator.of(context).pushNamed('/profile');
    if (mounted) {
      setState(() => _loadingOffering = true);
      await _load();
    }
  }

  Future<void> _open(Uri uri) async {
    try {
      final opened =
          await (widget.openLink?.call(uri) ??
              launchUrl(uri, mode: LaunchMode.externalApplication));
      if (!opened && mounted) {
        soriToast(context, AppL10n.of(context).paywallNotAvailable);
      }
    } on Object {
      if (mounted) {
        soriToast(context, AppL10n.of(context).paywallNotAvailable);
      }
    }
  }

  Future<void> _manage() async {
    final uri = await PremiumService.managementUrl();
    if (!mounted) {
      return;
    }
    if (uri == null) {
      soriNotice(context, AppL10n.of(context).paywallManageUnavailable);
    } else {
      await _open(uri);
    }
  }

  @override
  Widget build(BuildContext context) => ValueListenableBuilder<AccessSnapshot?>(
    valueListenable: widget.accessListenable ?? accessSnapshotNotifier,
    builder: (context, _, _) => _build(context),
  );

  Widget _build(BuildContext context) {
    final s = SoriSurfaces.of(context);
    final t = AppL10n.of(context);
    final tt = SoriTextTheme.of(context);
    final benefits = <String>[
      t.paywallBenefit1,
      t.paywallBenefit2,
      t.paywallBenefit3,
      t.paywallBenefit4,
      t.paywallBenefit5,
    ];
    final nowMillis = DateTime.now().toUtc().millisecondsSinceEpoch;
    final recordedReset = _access?.nextResetAt;
    final nextReset = DateTime.fromMillisecondsSinceEpoch(
      recordedReset != null && recordedReset > nowMillis
          ? recordedReset
          : (nowMillis ~/ 86400000 + 1) * 86400000,
      isUtc: true,
    );

    final media = MediaQuery.of(context);
    final screenWidth = media.size.width;
    final closeOperation = _busy
        ? null
        : () => Navigator.of(context).maybePop(false);
    final closeAction = Align(
      alignment: Alignment.topRight,
      child: Semantics(
        label: t.paywallClose,
        button: true,
        enabled: !_busy,
        onTap: closeOperation,
        excludeSemantics: true,
        child: IconButton(
          tooltip: t.paywallClose,
          constraints: const BoxConstraints.tightFor(width: 48, height: 48),
          color: s.textMuted,
          disabledColor: s.textDim,
          icon: const Icon(Icons.close_rounded),
          onPressed: closeOperation,
        ),
      ),
    );
    final mainContent = Padding(
      padding: soriClampPadding(
        screenWidth,
        base: const EdgeInsets.fromLTRB(24, 8, 24, 24),
      ),
      child: Column(
        children: [
          // §H: 일러스트 히어로 — 규약 `reward/paywall_hero.webp`,
          // 미도착 시 보자기 폴백 (화면이 아트보다 먼저 배포된다).
          ClipRRect(
            borderRadius: SoriRadius.brLg,
            child: AspectRatio(
              aspectRatio: 16 / 9,
              child: Image.asset(
                rewardIllustrationAsset('paywall_hero'),
                fit: BoxFit.cover,
                filterQuality: FilterQuality.high,
                errorBuilder: (_, _, _) => ColoredBox(
                  color: SoriColors.gold.withValues(alpha: 0.12),
                  child: Padding(
                    padding: const EdgeInsets.all(Spacing.lg),
                    child: Image.asset(
                      'assets/illustrations/reward/reward_bojagi_closed.png',
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: Spacing.xl),
          SoriPageHeader(
            eyebrow: t.paywallEyebrow,
            title: t.paywallTitle,
            body: t.paywallSubtitle,
          ),
          const SizedBox(height: Spacing.xl),
          ...benefits.map(
            (b) => Padding(
              padding: const EdgeInsets.only(bottom: Spacing.md),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.check_rounded,
                    size: 22,
                    color: SoriColors.success,
                  ),
                  const SizedBox(width: Spacing.md),
                  Expanded(child: Text(b, style: tt.body)),
                ],
              ),
            ),
          ),
          Text(
            t.paywallAiLimits(
              _access?.bookDailyLimit ?? 3,
              _access?.pronunciationDailyLimit ?? 5,
            ),
            style: tt.body,
          ),
          const SizedBox(height: Spacing.sm),
          Text(
            t.paywallNextReset(
              DateFormat('yyyy-MM-dd HH:mm').format(nextReset),
            ),
            style: tt.caption,
          ),
        ],
      ),
    );
    final actions = Padding(
      padding: soriClampPadding(
        screenWidth,
        base: const EdgeInsets.fromLTRB(24, 0, 24, 16),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // §H: 가격 카드 — raised 바탕 + primary 강조 테두리(선택 상태
          // 규격) + numeral 가격.
          if (!_active && !PremiumService.fullAccessBuild)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                horizontal: Spacing.lg,
                vertical: Spacing.md,
              ),
              decoration: BoxDecoration(
                color: SoriColors.lightSurfaceRaised,
                borderRadius: SoriRadius.brLg,
                border: Border.all(color: SoriColors.primary, width: 1.5),
              ),
              child: _loadingOffering
                  ? Center(
                      child: SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          semanticsLabel: t.paywallProcessing,
                        ),
                      ),
                    )
                  : Text(
                      _priceLabel(t),
                      textAlign: TextAlign.center,
                      style: tt.numeral.copyWith(color: s.text, fontSize: 24),
                    ),
            ),
          const SizedBox(height: Spacing.md),
          if (PremiumService.fullAccessBuild)
            Text(
              t.paywallFreeLaunch,
              textAlign: TextAlign.center,
              style: tt.body,
            )
          else if (_active) ...[
            Text(
              _access?.source == 'closed_tester_lifetime'
                  ? t.paywallTesterActive
                  : t.paywallActive,
              textAlign: TextAlign.center,
              style: tt.body,
            ),
            if (_access?.source == 'subscription')
              SoriButton.ghost(
                label: t.paywallManage,
                fullWidth: true,
                onTap: _busy ? null : _manage,
              ),
          ] else
            SoriButton.filled(
              label: _busy || _loadingOffering
                  ? t.paywallProcessing
                  : _requiresSignIn
                  ? t.paywallSignInToContinue
                  : t.paywallCtaStart,
              icon: Icons.bolt_rounded,
              fullWidth: true,
              onTap:
                  _busy ||
                      _loadingOffering ||
                      (!_requiresSignIn && _monthly == null)
                  ? null
                  : _start,
            ),
          const SizedBox(height: Spacing.sm),
          if (_cancelled && !_active)
            Semantics(
              liveRegion: true,
              child: Text(
                t.paywallCancelled,
                textAlign: TextAlign.center,
                style: tt.caption,
              ),
            ),
          if (!PremiumService.fullAccessBuild)
            SoriButton.ghost(
              label: t.paywallCtaRestore,
              fullWidth: true,
              onTap: _busy ? null : _restore,
            ),
          const SizedBox(height: Spacing.sm),
          Text(
            t.paywallLegal,
            textAlign: TextAlign.center,
            style: tt.caption.copyWith(color: s.textDim),
          ),
          Wrap(
            alignment: WrapAlignment.center,
            children: [
              TextButton(
                onPressed: _busy
                    ? null
                    : () => _open(Uri.parse('https://hangul-sori.com/terms')),
                child: Text(t.settingsTermsTitle),
              ),
              TextButton(
                onPressed: _busy
                    ? null
                    : () => _open(Uri.parse('https://hangul-sori.com/privacy')),
                child: Text(t.settingsPrivacyTitle),
              ),
            ],
          ),
        ],
      ),
    );
    final requiresFullScroll =
        media.size.height <= 480 || media.textScaler.scale(1) >= 1.5;

    return Scaffold(
      backgroundColor: s.bg,
      body: SafeArea(
        child: requiresFullScroll
            ? SingleChildScrollView(
                child: Column(children: [closeAction, mainContent, actions]),
              )
            : Column(
                children: [
                  closeAction,
                  Expanded(child: SingleChildScrollView(child: mainContent)),
                  actions,
                ],
              ),
      ),
    );
  }
}
