import 'package:package_info_plus/package_info_plus.dart';

abstract interface class AppVersionReader {
  Future<String> readVersion();
}

class PackageAppVersionReader implements AppVersionReader {
  const PackageAppVersionReader();

  @override
  Future<String> readVersion() async {
    return formatAppVersion(await PackageInfo.fromPlatform());
  }
}

String formatAppVersion(PackageInfo info) {
  final version = info.version.trim();
  final build = info.buildNumber.trim();
  if (version.isEmpty || build.isEmpty) {
    throw StateError('Package version is unavailable.');
  }
  return '$version ($build)';
}
