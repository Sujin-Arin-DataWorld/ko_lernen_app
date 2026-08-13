/// Compile-time rollout gate for the Sori Stage navigation and progression UI.
///
/// Defaults to the legacy shell (2026-08-13). The Sori Stage five-tab shell was
/// merged in `d2c5f94` and shipped as the default, but its text-first home lost
/// the mascot-led entry the legacy shell opens with, so the default was turned
/// back. Nothing was reverted: the Sori Stage screens, reward receipts, quests,
/// SRS, Gye triggers and pronunciation assessment all stay on `main` and are
/// reachable again with `--dart-define=ENABLE_SORI_STAGE=true`.
class SoriStageFeatureGate {
  const SoriStageFeatureGate({bool? enabled}) : _enabledOverride = enabled;

  static const bool _compileTimeEnabled = bool.fromEnvironment(
    'ENABLE_SORI_STAGE',
    defaultValue: false,
  );

  final bool? _enabledOverride;

  bool get isEnabled => _enabledOverride ?? _compileTimeEnabled;
}
