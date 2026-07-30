import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:flutter/foundation.dart';

typedef FirebaseAppCheckActivator =
    Future<void> Function({
      required AndroidProvider androidProvider,
      required AppleProvider appleProvider,
    });

class FirebaseAppCheckInitializer {
  FirebaseAppCheckInitializer({required this.isDebug, required this.activate});

  factory FirebaseAppCheckInitializer.production() {
    return FirebaseAppCheckInitializer(
      isDebug: kDebugMode,
      activate: ({required androidProvider, required appleProvider}) {
        return FirebaseAppCheck.instance.activate(
          androidProvider: androidProvider,
          appleProvider: appleProvider,
        );
      },
    );
  }

  final bool isDebug;
  final FirebaseAppCheckActivator activate;

  Future<void> initialize() {
    return activate(
      androidProvider: isDebug
          ? AndroidProvider.debug
          : AndroidProvider.playIntegrity,
      appleProvider: isDebug
          ? AppleProvider.debug
          : AppleProvider.appAttestWithDeviceCheckFallback,
    );
  }
}
