import 'package:flutter/foundation.dart';

/// Production gate for the optional Android tester-feedback experience.
///
/// Supplying [enabled] is intentionally a test seam; production callers use
/// the default constructor and therefore require both the compile-time define
/// and an Android runtime.
class TesterFeedbackFeatureGate {
  const TesterFeedbackFeatureGate({bool? enabled}) : _enabledOverride = enabled;

  static const bool _compileTimeEnabled = bool.fromEnvironment(
    'ENABLE_TESTER_FEEDBACK',
    defaultValue: false,
  );

  final bool? _enabledOverride;

  bool get isEnabled =>
      _enabledOverride ??
      (_compileTimeEnabled &&
          !kIsWeb &&
          defaultTargetPlatform == TargetPlatform.android);
}
