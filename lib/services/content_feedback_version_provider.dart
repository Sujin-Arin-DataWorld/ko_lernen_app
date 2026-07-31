import 'package:package_info_plus/package_info_plus.dart';

abstract interface class ContentFeedbackVersionProvider {
  Future<String> readVersion();
}

class PackageContentFeedbackVersionProvider
    implements ContentFeedbackVersionProvider {
  const PackageContentFeedbackVersionProvider();

  @override
  Future<String> readVersion() async {
    final info = await PackageInfo.fromPlatform();
    final version = info.version.trim();
    final build = info.buildNumber.trim();
    if (version.isEmpty || build.isEmpty) {
      throw StateError('Package version is unavailable.');
    }
    return '$version+$build';
  }
}
