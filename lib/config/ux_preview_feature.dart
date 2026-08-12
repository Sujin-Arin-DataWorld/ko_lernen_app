import 'package:flutter/foundation.dart';

/// Debug-only gate for the UX rebuild preview gallery.
///
/// The gallery contains deterministic fixture states and must never replace
/// the normal production entry point. Production callers use the default
/// constructor; tests may provide [enabled] to verify both branches.
class UxPreviewFeatureGate {
  const UxPreviewFeatureGate({bool? enabled}) : _enabledOverride = enabled;

  static const bool _compileTimeEnabled = bool.fromEnvironment(
    'ENABLE_UX_GALLERY',
    defaultValue: false,
  );

  final bool? _enabledOverride;

  bool get isEnabled => _enabledOverride ?? (kDebugMode && _compileTimeEnabled);
}
