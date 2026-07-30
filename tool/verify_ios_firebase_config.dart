import 'dart:io';

const _googleServicePlist = 'GoogleService-Info.plist';

class IosFirebaseConfigurationResult {
  const IosFirebaseConfigurationResult(this.missing);

  final List<String> missing;

  bool get isValid => missing.isEmpty;
}

IosFirebaseConfigurationResult inspectIosFirebaseConfiguration({
  required String firebaseOptionsSource,
  required bool plistExists,
  required String projectSource,
}) {
  final missing = <String>[];

  if (!RegExp(
    r'static\s+const\s+FirebaseOptions\s+ios\s*=',
  ).hasMatch(firebaseOptionsSource)) {
    missing.add('firebase_options iOS');
  }
  if (!plistExists) {
    missing.add('ios/Runner/GoogleService-Info.plist');
  }
  if (!RegExp(
    r'/\*\s*GoogleService-Info\.plist\s+in\s+Resources\s*\*/',
  ).hasMatch(projectSource)) {
    missing.add('Xcode Runner target membership for $_googleServicePlist');
  }

  return IosFirebaseConfigurationResult(missing);
}

void main() {
  final firebaseOptions = File('lib/firebase_options.dart');
  final xcodeProject = File('ios/Runner.xcodeproj/project.pbxproj');
  final result = inspectIosFirebaseConfiguration(
    firebaseOptionsSource: firebaseOptions.existsSync()
        ? firebaseOptions.readAsStringSync()
        : '',
    plistExists: File('ios/Runner/GoogleService-Info.plist').existsSync(),
    projectSource: xcodeProject.existsSync()
        ? xcodeProject.readAsStringSync()
        : '',
  );

  if (result.isValid) {
    stdout.writeln('iOS Firebase release configuration is present.');
    return;
  }

  stderr.writeln('iOS Firebase release configuration is incomplete:');
  for (final requirement in result.missing) {
    stderr.writeln('- missing: $requirement');
  }
  stderr.writeln(
    'Complete docs/store/ios-external-setup.md on an authorized macOS release workstation.',
  );
  exitCode = 1;
}
