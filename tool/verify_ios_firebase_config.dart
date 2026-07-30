import 'dart:io';

const _googleServicePlist = 'GoogleService-Info.plist';

class IosFirebaseConfigurationResult {
  const IosFirebaseConfigurationResult(this.missing);

  final List<String> missing;

  bool get isValid => missing.isEmpty;
}

bool _hasRunnerPlistResourceMembership(String projectSource) {
  final plistBuildFileIds = <String>{};
  final plistBuildFile = RegExp(
    r'^\s*([A-Za-z0-9_]+)\s*/\*\s*GoogleService-Info\.plist\s+in\s+Resources\s*\*/\s*=\s*\{([^}]*)\};',
    multiLine: true,
  );
  for (final match in plistBuildFile.allMatches(projectSource)) {
    if (RegExp(r'\bisa\s*=\s*PBXBuildFile\s*;').hasMatch(match.group(2)!)) {
      plistBuildFileIds.add(match.group(1)!);
    }
  }
  if (plistBuildFileIds.isEmpty) {
    return false;
  }

  final runnerTarget = RegExp(
    r'^\s*[A-Za-z0-9_]+\s*/\*\s*Runner\s*\*/\s*=\s*\{([\s\S]*?)^\s*\};',
    multiLine: true,
  );
  for (final targetMatch in runnerTarget.allMatches(projectSource)) {
    final targetBody = targetMatch.group(1)!;
    if (!RegExp(r'\bisa\s*=\s*PBXNativeTarget\s*;').hasMatch(targetBody) ||
        !RegExp(r'\bname\s*=\s*Runner\s*;').hasMatch(targetBody)) {
      continue;
    }

    final buildPhases = RegExp(
      r'\bbuildPhases\s*=\s*\(([\s\S]*?)\);',
    ).firstMatch(targetBody);
    if (buildPhases == null) {
      continue;
    }

    final resourcesPhaseId = RegExp(
      r'([A-Za-z0-9_]+)\s*/\*\s*Resources\s*\*/',
    ).firstMatch(buildPhases.group(1)!);
    if (resourcesPhaseId == null) {
      continue;
    }

    final resourcesPhase = RegExp(
      '^\\s*${RegExp.escape(resourcesPhaseId.group(1)!)}\\s*/\\*\\s*Resources\\s*\\*/\\s*=\\s*\\{([\\s\\S]*?)^\\s*\\};',
      multiLine: true,
    ).firstMatch(projectSource);
    if (resourcesPhase == null ||
        !RegExp(
          r'\bisa\s*=\s*PBXResourcesBuildPhase\s*;',
        ).hasMatch(resourcesPhase.group(1)!)) {
      continue;
    }

    final files = RegExp(
      r'\bfiles\s*=\s*\(([\s\S]*?)\);',
    ).firstMatch(resourcesPhase.group(1)!);
    if (files == null) {
      continue;
    }

    for (final buildFileId in plistBuildFileIds) {
      if (RegExp(
        '(^|\\n)\\s*${RegExp.escape(buildFileId)}\\s*/\\*\\s*GoogleService-Info\\.plist\\s+in\\s+Resources\\s*\\*/\\s*,',
      ).hasMatch(files.group(1)!)) {
        return true;
      }
    }
  }

  return false;
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
  if (!_hasRunnerPlistResourceMembership(projectSource)) {
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
