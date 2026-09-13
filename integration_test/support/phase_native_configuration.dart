/// Native QA can relaunch one compiled app for another level or restoration.
/// Invalid routes fail instead of silently certifying a different level.
class PhaseNativeConfiguration {
  const PhaseNativeConfiguration(this.level, this.restoreOnly);

  final String level;
  final bool restoreOnly;
  static const levels = {'A1', 'A2', 'B1', 'B2', 'C1', 'C2'};

  factory PhaseNativeConfiguration.fromRoute(
    String route, {
    String defaultLevel = 'A1',
    bool defaultRestoreOnly = false,
  }) {
    if (route == '/' || route.isEmpty) {
      if (!levels.contains(defaultLevel)) {
        throw ArgumentError.value(defaultLevel, 'defaultLevel');
      }
      return PhaseNativeConfiguration(defaultLevel, defaultRestoreOnly);
    }
    final uri = Uri.parse(route);
    final parts = uri.pathSegments;
    if (uri.hasScheme ||
        uri.hasAuthority ||
        uri.hasQuery ||
        uri.hasFragment ||
        (parts.length != 2 && parts.length != 3) ||
        parts[0] != 'phase-qa' ||
        !levels.contains(parts[1]) ||
        (parts.length == 3 && parts[2] != 'restore')) {
      throw ArgumentError.value(
        route,
        'route',
        'Invalid Phase native QA route',
      );
    }
    return PhaseNativeConfiguration(parts[1], parts.length == 3);
  }
}
