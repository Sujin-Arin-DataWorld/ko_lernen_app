/// Compile-time rollout gate for the Sori Stage navigation and progression UI.
///
/// The branch intentionally defaults to the new experience. Release builds can
/// still fail closed to the legacy shell with
/// `--dart-define=ENABLE_SORI_STAGE=false` while the route and progress
/// contracts remain unchanged.
class SoriStageFeatureGate {
  const SoriStageFeatureGate({bool? enabled}) : _enabledOverride = enabled;

  static const bool _compileTimeEnabled = bool.fromEnvironment(
    'ENABLE_SORI_STAGE',
    defaultValue: true,
  );

  final bool? _enabledOverride;

  bool get isEnabled => _enabledOverride ?? _compileTimeEnabled;
}
