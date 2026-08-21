import 'package:flutter/material.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

import '../l10n/generated/app_localizations.dart';
import '../services/analytics_service.dart';
import '../services/premium_service.dart';
import '../widgets/sori/activity_illustration.dart';
import '../widgets/sori/button.dart';
import '../widgets/sori/page_header.dart';
import '../widgets/sori/responsive.dart';
import '../widgets/sori/toast.dart';
import '../widgets/sori/tokens.dart';

/// €5/Monat Premium-Paywall.
///
/// Wird via `/paywall` oder [PremiumService.gate] geöffnet und schließt bei
/// erfolgreichem Kauf/Restore mit `Navigator.pop(context, true)`. Ist kein
/// RevenueCat-Offering verfügbar (Dashboard noch nicht eingerichtet), zeigt
/// die Seite den Fallback-Preis und einen Hinweis — sie crasht nie.
class PaywallScreen extends StatefulWidget {
  const PaywallScreen({
    super.key,
    this.placement = 'unspecified',
    this.offeringLoader,
    this.purchaseOperation,
    this.restoreOperation,
  });

  /// Woher die Paywall geöffnet wurde (Analytics placement). Vom Gate/Route
  /// gesetzt; Standard 'unspecified'.
  final String placement;
  final Future<Offering?> Function()? offeringLoader;
  final Future<PremiumPurchaseOutcome> Function(Package package)?
  purchaseOperation;
  final Future<PremiumRestoreOutcome> Function()? restoreOperation;

  @override
  State<PaywallScreen> createState() => _PaywallScreenState();
}

class _PaywallScreenState extends State<PaywallScreen> {
  Offering? _offering;
  bool _loadingOffering = true;
  bool _busy = false;

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
    } on Object catch (error) {
      debugPrint('PaywallScreen: offering load failed — $error');
    }
    if (!mounted) return;
    setState(() {
      _offering = offering;
      _loadingOffering = false;
    });
  }

  Package? get _monthly {
    final o = _offering;
    if (o == null) return null;
    return o.monthly ??
        (o.availablePackages.isNotEmpty ? o.availablePackages.first : null);
  }

  String _priceLabel(AppL10n t) {
    final pkg = _monthly;
    if (pkg == null) return t.paywallPriceFallback;
    return '${pkg.storeProduct.priceString} ${t.paywallPricePerMonth}';
  }

  Future<void> _start() async {
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
    setState(() => _busy = true);
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
        return;
      case PremiumPurchaseOutcome.failed:
        soriToast(context, t.paywallFailed);
    }
  }

  Future<void> _restore() async {
    final t = AppL10n.of(context);
    setState(() => _busy = true);
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
      case PremiumRestoreOutcome.failed:
        soriToast(context, t.paywallRestoreFailed);
    }
  }

  @override
  Widget build(BuildContext context) {
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
          SoriButton.filled(
            label: _busy || _loadingOffering
                ? t.paywallProcessing
                : t.paywallCtaStart,
            icon: Icons.bolt_rounded,
            fullWidth: true,
            onTap: _busy || _loadingOffering ? null : _start,
          ),
          const SizedBox(height: Spacing.sm),
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
