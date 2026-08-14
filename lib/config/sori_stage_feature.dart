/// Compile-time rollout gate for the Sori Stage navigation and progression UI.
///
/// **Defaults to the Sori Stage five-tab shell (2026-08-14, UI 개편 Phase 2c).**
///
/// History: the shell was merged in `d2c5f94` and shipped as the default, then
/// turned back on 2026-08-13 for exactly one defect — its text-first Today
/// screen lost the mascot-led entry the legacy home opens with. Phase 2b fixed
/// that defect by porting the legacy home's hero verbatim: Today now opens
/// with [SoriStatsTopBar] + [SoriCharacterHero] (greeting → speech bubble →
/// character clip band) on the same flat hanji matte background contract
/// (`sori_stage_today_matte_test.dart` pins it).
///
/// Rollback: `--dart-define=ENABLE_SORI_STAGE=false` restores the legacy
/// shell without a code change. The legacy `LegacyAppShell`/`home_screen.dart`
/// stay compiled-in for one release as that escape hatch.
class SoriStageFeatureGate {
  const SoriStageFeatureGate({bool? enabled}) : _enabledOverride = enabled;

  static const bool _compileTimeEnabled = bool.fromEnvironment(
    'ENABLE_SORI_STAGE',
    defaultValue: true,
  );

  final bool? _enabledOverride;

  bool get isEnabled => _enabledOverride ?? _compileTimeEnabled;
}
