import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

import 'account/cloud_write_session.dart';
import 'storage_service.dart';

/// Globaler Premium-Status. Wie [paletteVariantNotifier] ein Top-Level
/// [ValueNotifier] — Screens können per [ValueListenableBuilder] live darauf
/// reagieren (Lock-Badges ein-/ausblenden, Paywall-Sperren etc.).
final ValueNotifier<bool> premiumNotifier =
    ValueNotifier<bool>(PremiumService.betaUnlockAll);

abstract interface class RevenueCatIdentityClient {
  Future<void> logIn(String uid);
  Future<void> logOut();
}

class PurchasesIdentityClient implements RevenueCatIdentityClient {
  const PurchasesIdentityClient();

  @override
  Future<void> logIn(String uid) async {
    await Purchases.logIn(uid);
  }

  @override
  Future<void> logOut() async {
    await Purchases.logOut();
  }
}

/// Serializes Firebase identity changes into RevenueCat identity changes.
/// Binding state advances only after RevenueCat confirms the transition.
class PremiumIdentityBinder {
  PremiumIdentityBinder(
    this.client, {
    required this.sessions,
    String? initialUid,
  }) : _boundUid = initialUid;

  final RevenueCatIdentityClient client;
  final CloudWriteSessionController sessions;
  String? _boundUid;
  StreamSubscription<void>? _subscription;
  String? _pendingUid;
  bool _hasPendingUid = false;
  VoidCallback? _sessionListener;

  String? get boundUid => _boundUid;

  void start(Stream<String?> userIds, {void Function(Object error)? onError}) {
    if (_subscription != null) {
      return;
    }
    _subscription = userIds
        .asyncMap((uid) async {
          _pendingUid = uid;
          _hasPendingUid = true;
          try {
            final result = await bind(uid);
            if (result == CloudWriteResult.completed && uid == _pendingUid) {
              _hasPendingUid = false;
            }
          } catch (error) {
            onError?.call(error);
            debugPrint('PremiumService: logIn/logOut failed — $error');
          }
        })
        .listen((_) {});
    _sessionListener = () {
      if (_hasPendingUid) {
        unawaited(_retryPending(onError));
      }
    };
    sessions.changes.addListener(_sessionListener!);
  }

  Future<void> _retryPending(void Function(Object error)? onError) async {
    final uid = _pendingUid;
    try {
      final result = await bind(uid);
      if (result == CloudWriteResult.completed && uid == _pendingUid) {
        _hasPendingUid = false;
      }
    } catch (error) {
      onError?.call(error);
      debugPrint('Premium identity retry failed: $error');
    }
  }

  Future<CloudWriteResult> bind(String? uid) async {
    final operationUid = uid ?? _boundUid;
    if (operationUid == null) {
      return CloudWriteResult.completed;
    }
    final fence = CloudWriteFence(sessions);
    if (fence.readySnapshot(operationUid) == null) {
      return CloudWriteResult.blocked;
    }
    if (uid == _boundUid) {
      return CloudWriteResult.completed;
    }
    if (_boundUid == null) {
      return CloudWriteResult.blocked;
    }

    if (uid != null) {
      final loginResult = await fence.run(
        uid: uid,
        action: () => client.logIn(uid),
      );
      if (loginResult != CloudWriteResult.completed) {
        return loginResult;
      }
      _boundUid = uid;
      return CloudWriteResult.completed;
    }
    return CloudWriteResult.blocked;
  }

  Future<void> dispose() async {
    await _subscription?.cancel();
    _subscription = null;
    final listener = _sessionListener;
    if (listener != null) {
      sessions.changes.removeListener(listener);
      _sessionListener = null;
    }
  }
}

PurchasesConfiguration revenueCatConfiguration({
  required String apiKey,
  required String appUserId,
}) {
  final uid = appUserId.trim();
  if (uid.isEmpty) {
    throw ArgumentError.value(appUserId, 'appUserId', 'must not be empty');
  }
  return PurchasesConfiguration(apiKey)..appUserID = uid;
}

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

  /// 🧪 베타 기간: 모든 프리미엄 콘텐츠를 전 사용자에게 무료 해제.
  /// 출시(유료화) 시 반드시 `false`로 되돌릴 것.
  /// (빌드 시 `--dart-define=BETA_UNLOCK_ALL=false`로도 끌 수 있음.)
  static const bool betaUnlockAll =
      bool.fromEnvironment('BETA_UNLOCK_ALL', defaultValue: false);

  static const String _androidKey = String.fromEnvironment('RC_ANDROID_KEY');
  static const String _iosKey = String.fromEnvironment('RC_IOS_KEY');

  static bool _configured = false;
  static PremiumIdentityBinder? _identityBinder;

  /// `true` wenn echtes Abo aktiv, lokaler Dev-Override, ODER Beta-Unlock.
  static bool get isPremium => betaUnlockAll || premiumNotifier.value;

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
    String? uid;
    try {
      uid = FirebaseAuth.instance.currentUser?.uid;
    } catch (_) {
      return;
    }
    if (uid == null ||
        CloudWriteFence(cloudWriteSessionController).readySnapshot(uid) ==
            null) {
      return;
    }

    // 3) RevenueCat konfigurieren + live aktualisieren.
    try {
      await Purchases.configure(
        revenueCatConfiguration(apiKey: key, appUserId: uid),
      );
      _configured = true;
      Purchases.addCustomerInfoUpdateListener(_onCustomerInfo);
      _bindFirebaseIdentity(uid);
      _onCustomerInfo(await Purchases.getCustomerInfo());
    } catch (e) {
      debugPrint('PremiumService: init skipped — $e');
    }
  }

  /// RevenueCat-`appUserID` an die Firebase-UID koppeln, damit das Abo dem
  /// **Konto** folgt (Gerätewechsel, Reinstall, Google/Apple-Login) statt einer
  /// gerätelokalen anonymen RC-ID. Reagiert auf UID-Wechsel (Konto-Wechsel oder
  /// Neu-Anmeldung nach Konto-Löschung). Best-effort — ohne Firebase passiert
  /// nichts, kein Crash.
  static void _bindFirebaseIdentity(String configuredUid) {
    try {
      final binder = _identityBinder ??= PremiumIdentityBinder(
        const PurchasesIdentityClient(),
        sessions: cloudWriteSessionController,
        initialUid: configuredUid,
      );
      binder.start(
        FirebaseAuth.instance.userChanges().map((user) => user?.uid),
      );
    } catch (_) {
      // Firebase nicht verfügbar (z.B. Web ohne Config) — RC bleibt anonym.
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

  /// Effektiver Status = echtes Entitlement, lokaler Dev-Override, ODER Beta-Unlock.
  static void _applyEntitlement(bool active) {
    premiumNotifier.value =
        betaUnlockAll || active || Storage.devPremiumOverride;
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
      // v9+: purchase(PurchaseParams) liefert ein PurchaseResult mit CustomerInfo.
      final result = await Purchases.purchase(PurchaseParams.package(package));
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
    final purchased = await Navigator.of(context).pushNamed('/paywall');
    return purchased == true || isPremium;
  }
}
