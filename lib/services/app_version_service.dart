import 'package:package_info_plus/package_info_plus.dart';

abstract interface class AppVersionReader {
  Future<String> readVersion();
}

class PackageAppVersionReader implements AppVersionReader {
  const PackageAppVersionReader();

  @override
  Future<String> readVersion() async {
    return formatAppVersion(
      await PackageInfo.fromPlatform(),
      commit: AppBuildInfo.gitCommit,
    );
  }
}

/// §RELEASE-2(J13) — single source for the commit the running binary was
/// built from. `--dart-define=GIT_COMMIT=<sha>` is injected by CI/local
/// release scripts; a debug/dev build omits it, so this is empty by default
/// (never `'unknown'` here — callers decide their own empty-value copy).
abstract final class AppBuildInfo {
  static const String gitCommit = String.fromEnvironment(
    'GIT_COMMIT',
    defaultValue: '',
  );
}

/// [commit] may be a full 40-char SHA (CI's `GIT_COMMIT`) or a manual Closed
/// build's 7-char `git rev-parse --short HEAD`
/// (`BETA_INSTALL_GUIDE.md`/`closed-testing-checklist-v2.md`) — clamp to the
/// shorter of 8 or the actual length instead of a bare `substring(0, 8)`,
/// which throws `RangeError` on a 7-char short SHA.
String formatAppVersion(PackageInfo info, {String commit = ''}) {
  final version = info.version.trim();
  final build = info.buildNumber.trim();
  if (version.isEmpty || build.isEmpty) {
    throw StateError('Package version is unavailable.');
  }
  if (commit.isEmpty) {
    return '$version ($build)';
  }
  final short = commit.length > 8 ? commit.substring(0, 8) : commit;
  return '$version ($build) · $short';
}
