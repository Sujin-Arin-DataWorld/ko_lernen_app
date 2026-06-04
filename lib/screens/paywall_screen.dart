import 'package:flutter/material.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

import '../l10n/generated/app_localizations.dart';
import '../services/premium_service.dart';
import '../widgets/sori/button.dart';
import '../widgets/sori/responsive.dart';
import '../widgets/sori/tokens.dart';

/// €5/Monat Premium-Paywall.
///
/// Wird via `/paywall` oder [PremiumService.gate] geöffnet und schließt bei
/// erfolgreichem Kauf/Restore mit `Navigator.pop(context, true)`. Ist kein
/// RevenueCat-Offering verfügbar (Dashboard noch nicht eingerichtet), zeigt
/// die Seite den Fallback-Preis und einen Hinweis — sie crasht nie.
class PaywallScreen extends StatefulWidget {
  const PaywallScreen({super.key});

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
  }

  Future<void> _load() async {
    final offering = await PremiumService.currentOffering();
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
      _snack(t.paywallNotAvailable);
      return;
    }
    setState(() => _busy = true);
    final ok = await PremiumService.purchase(pkg);
    if (!mounted) return;
    setState(() => _busy = false);
    if (ok) {
      _snack(t.paywallSuccess);
      Navigator.of(context).pop(true);
    } else {
      _snack(t.paywallFailed);
    }
  }

  Future<void> _restore() async {
    final t = AppL10n.of(context);
    setState(() => _busy = true);
    final ok = await PremiumService.restore();
    if (!mounted) return;
    setState(() => _busy = false);
    if (ok) {
      _snack(t.paywallSuccess);
      Navigator.of(context).pop(true);
    } else {
      _snack(t.paywallRestoreNone);
    }
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(msg)));
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

    final screenWidth = MediaQuery.sizeOf(context).width;
    return Scaffold(
      backgroundColor: s.bg,
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.topRight,
              child: IconButton(
                icon: Icon(Icons.close_rounded, color: s.textMuted),
                onPressed:
                    _busy ? null : () => Navigator.of(context).maybePop(false),
              ),
            ),
            Expanded(
              child: ListView(
                padding: soriClampPadding(
                  screenWidth,
                  base: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                ),
                children: [
                  Center(
                    child: Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        color: SoriColors.gold.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.workspace_premium_rounded,
                        size: 40,
                        color: SoriColors.gold,
                      ),
                    ),
                  ),
                  const SizedBox(height: Spacing.lg),
                  Text(t.paywallTitle,
                      textAlign: TextAlign.center, style: tt.display),
                  const SizedBox(height: Spacing.sm),
                  Text(
                    t.paywallSubtitle,
                    textAlign: TextAlign.center,
                    style: tt.body.copyWith(color: s.textMuted),
                  ),
                  const SizedBox(height: Spacing.xl),
                  ...benefits.map(
                    (b) => Padding(
                      padding: const EdgeInsets.only(bottom: Spacing.md),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.check_circle_rounded,
                              size: 22, color: SoriColors.primary),
                          const SizedBox(width: Spacing.md),
                          Expanded(child: Text(b, style: tt.body)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: soriClampPadding(
                screenWidth,
                base: const EdgeInsets.fromLTRB(24, 0, 24, 16),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_loadingOffering)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  else
                    Text(
                      _priceLabel(t),
                      textAlign: TextAlign.center,
                      style: tt.h2.copyWith(color: s.text),
                    ),
                  const SizedBox(height: Spacing.md),
                  SoriButton.filled(
                    label: _busy ? t.paywallProcessing : t.paywallCtaStart,
                    icon: Icons.bolt_rounded,
                    fullWidth: true,
                    onTap: _busy ? null : _start,
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
            ),
          ],
        ),
      ),
    );
  }
}
