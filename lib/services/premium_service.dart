import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

import 'storage_service.dart';

/// Globaler Premium-Status. Wie [paletteVariantNotifier] ein Top-Level
/// [ValueNotifier] — Screens können per [ValueListenableBuilder] live darauf
/// reagieren (Lock-Badges ein-/ausblenden, Paywall-Sperren etc.).
final ValueNotifier<bool> premiumNotifier = ValueNotifier<bool>(false);

/// **PremiumService** — €5/Monat Abo über RevenueCat (`purchases_flutter`).
///
/// Designprinzip (wie [AuthService] bei Firebase): **läuft immer, crasht nie**.
/// Ohne konfigurierte RevenueCat-Keys (oder auf Web) bleibt der Nutzer schlicht
/// "kostenlos" — keine Exception, kein roter Screen.
///
/// Keys werden via `--dart-define` injiziert (nicht ins Repo committen):
/// ```
/// flutter run --dart-define=RC_ANDROID_KEY=goog_xxx --dart-define=RC_IOS_KEY=appl_xxx
/// ```
/// Im RevenueCat-Dashboard: ein Entitlement `premium` + ein Offering (mit
/// monatlichem Paket) anlegen, die Store-Produkte in Play Console / App Store
/// Connect verknüpfen.
class PremiumService {
  PremiumService._();

  /// Entitlement-ID aus dem RevenueCat-Dashboard.
  static const String entitlementId = 'premium';

  static const String _androidKey = String.fromEnvironment('RC_ANDROID_KEY');
  static const String _iosKey = String.fromEnvironment('RC_IOS_KEY');

  static bool _configured = false;

  /// `true` wenn echtes Abo aktiv ODER lokaler Dev-Override gesetzt ist.
  static bool get isPremium => premiumNotifier.value;

  /// Ob RevenueCat erfolgreich konfiguriert wurde (für Settings/Debug-Anzeige).
  static bool get isConfigured => _configured;

  /// Best-effort Init in `main()` — wirft nie. Der synchron laufende erste
  /// Teil (Cache anwenden) sorgt dafür, dass Gating sofort korrekt ist, auch
  /// wenn `init()` nicht awaited wird.
  static Future<void> init() async {
    // 1) Lokalen Cache sofort anwenden → Gating ist instant & offline-fähig.
    _applyEntitlement(Storage.premiumCached);

    // 2) Web / fehlende Keys → kostenlos, ohne RevenueCat.
    if (kIsWeb) return;
    final key = _platformKey();
    if (key.isEmpty) return;

    // 3) RevenueCat konfigurieren + live aktualisieren.
    try {
      await Purchases.configure(PurchasesConfiguration(key));
      _configured = true;
      Purchases.addCustomerInfoUpdateListener(_onCustomerInfo);
      _onCustomerInfo(await Purchases.getCustomerInfo());
    } catch (e) {
      debugPrint('PremiumService: init skipped — $e');
    }
  }

  static String _platformKey() {
    if (defaultTargetPlatform == TargetPlatform.iOS ||
        defaultTargetPlatform == TargetPlatform.macOS) {
      return _iosKey;
    }
    return _androidKey;
  }

  static void _onCustomerInfo(CustomerInfo info) {
    final active = info.entitlements.active.containsKey(entitlementId);
    _applyEntitlement(active);
    // Nur den ECHTEN Entitlement-Status cachen (Dev-Override nicht persistieren).
    // ignore: discarded_futures
    Storage.setPremiumCached(active);
  }

  /// Effektiver Status = echtes Entitlement ODER lokaler Dev-Override.
  static void _applyEntitlement(bool active) {
    premiumNotifier.value = active || Storage.devPremiumOverride;
  }

  /// Aktuelles Offering (für die Paywall). `null` wenn nicht konfiguriert
  /// oder kein Offering hinterlegt.
  static Future<Offering?> currentOffering() async {
    if (!_configured) return null;
    try {
      return (await Purchases.getOfferings()).current;
    } catch (e) {
      debugPrint('PremiumService: getOfferings failed — $e');
      return null;
    }
  }

  /// Kauf eines Pakets. Gibt `true` zurück, wenn das Premium-Entitlement
  /// danach aktiv ist. User-Abbruch und Fehler liefern beide `false`.
  static Future<bool> purchase(Package package) async {
    if (!_configured) return false;
    try {
      // v9+: purchasePackage liefert PurchaseResult (nicht mehr CustomerInfo).
      // TODO(jin): Auf `Purchases.purchase(PurchaseParams(package: package))`
      //   migrieren, sobald ein echter Sandbox-Kauf getestet werden kann.
      //   purchasePackage ist in v10 deprecated, funktioniert aber weiterhin.
      // ignore: deprecated_member_use
      final result = await Purchases.purchasePackage(package);
      _onCustomerInfo(result.customerInfo);
      return isPremium;
    } catch (e) {
      debugPrint('PremiumService: purchase not completed — $e');
      return false;
    }
  }

  /// Käufe wiederherstellen (Pflicht für Store-Review). `true` wenn danach
  /// Premium aktiv ist.
  static Future<bool> restore() async {
    if (!_configured) return false;
    try {
      _onCustomerInfo(await Purchases.restorePurchases());
      return isPremium;
    } catch (e) {
      debugPrint('PremiumService: restore failed — $e');
      return false;
    }
  }

  /// Lokaler Test-Schalter (Settings → Debug). Erlaubt das Prüfen von Gating +
  /// Paywall ohne RevenueCat-Dashboard. Verändert NICHT den echten Kaufstatus.
  static Future<void> setDevOverride(bool v) async {
    await Storage.setDevPremiumOverride(v);
    _applyEntitlement(Storage.premiumCached);
  }

  /// Gate-Helfer. Gibt `true` zurück wenn Premium aktiv ist; sonst öffnet es
  /// die Paywall (`/paywall`) und gibt zurück, ob danach Premium aktiv ist.
  ///
  /// ```dart
  /// if (!await PremiumService.gate(context)) return; // abgebrochen
  /// ```
  static Future<bool> gate(BuildContext context) async {
    if (isPremium) return true;
    if (!context.mounted) return false;
    final purchased = await Navigator.of(context).pushNamed<bool>('/paywall');
    return purchased == true || isPremium;
  }
}
