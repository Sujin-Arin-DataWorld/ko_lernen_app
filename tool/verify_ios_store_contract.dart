import 'dart:convert';
import 'dart:io';

const _bundleIdentifier = 'com.sujinarin.koLernenApp';

const _deCameraPurpose =
    'Hangul Sori verwendet die Kamera, um Lehrbuchseiten zu fotografieren und koreanische Wörter auf deinem Gerät zu erkennen.';
const _dePhotoPurpose =
    'Hangul Sori ermöglicht dir, ein Foto einer Lehrbuchseite auszuwählen, um koreanische Wörter auf deinem Gerät zu erkennen.';
const _enCameraPurpose =
    'Hangul Sori uses the camera to photograph textbook pages and recognize Korean words on your device.';
const _enPhotoPurpose =
    'Hangul Sori lets you select a textbook-page photo to recognize Korean words on your device.';

class IosStoreContractResult {
  const IosStoreContractResult(this.violations);

  final List<String> violations;

  bool get isValid => violations.isEmpty;
}

class _PbxObject {
  const _PbxObject(this.id, this.body);

  final String id;
  final String body;
}

String _stripPbxComments(String source) {
  final output = StringBuffer();
  var index = 0;
  String? quote;

  while (index < source.length) {
    final current = source[index];
    if (quote != null) {
      output.write(current);
      if (current == '\\' && index + 1 < source.length) {
        output.write(source[index + 1]);
        index += 2;
        continue;
      }
      if (current == quote) {
        quote = null;
      }
      index += 1;
      continue;
    }
    if (current == '"' || current == "'") {
      quote = current;
      output.write(current);
      index += 1;
      continue;
    }
    if (source.startsWith('/*', index)) {
      index += 2;
      while (index < source.length && !source.startsWith('*/', index)) {
        if (source[index] == '\n' || source[index] == '\r') {
          output.write(source[index]);
        } else {
          output.write(' ');
        }
        index += 1;
      }
      if (source.startsWith('*/', index)) {
        index += 2;
      }
      continue;
    }
    output.write(current);
    index += 1;
  }
  return output.toString();
}

int? _matchingBrace(String source, int openingIndex) {
  var depth = 0;
  var index = openingIndex;
  String? quote;
  while (index < source.length) {
    final current = source[index];
    if (quote != null) {
      if (current == '\\' && index + 1 < source.length) {
        index += 2;
        continue;
      }
      if (current == quote) {
        quote = null;
      }
      index += 1;
      continue;
    }
    if (current == '"' || current == "'") {
      quote = current;
      index += 1;
      continue;
    }
    if (current == '{') {
      depth += 1;
    } else if (current == '}') {
      depth -= 1;
      if (depth == 0) {
        return index;
      }
    }
    index += 1;
  }
  return null;
}

Map<String, _PbxObject> _parsePbxObjects(String source) {
  final uncommented = _stripPbxComments(source);
  final result = <String, _PbxObject>{};
  final starts = RegExp(r'^\s*([A-Za-z0-9_]+)\s*=\s*\{', multiLine: true);
  for (final match in starts.allMatches(uncommented)) {
    final opening = uncommented.indexOf('{', match.start);
    final closing = _matchingBrace(uncommented, opening);
    if (closing == null) {
      continue;
    }
    final id = match.group(1)!;
    result.putIfAbsent(
      id,
      () => _PbxObject(id, uncommented.substring(opening + 1, closing)),
    );
  }
  return result;
}

String? _scalar(String body, String key) {
  final match = RegExp(
    '\\b${RegExp.escape(key)}\\s*=\\s*("(?:[^"\\\\]|\\\\.)*"|[^;]+)\\s*;',
  ).firstMatch(body);
  if (match == null) {
    return null;
  }
  final raw = match.group(1)!.trim();
  if (raw.startsWith('"') && raw.endsWith('"') && raw.length >= 2) {
    return raw.substring(1, raw.length - 1);
  }
  return raw;
}

List<String> _listIds(String body, String key) {
  final list = RegExp(
    '\\b${RegExp.escape(key)}\\s*=\\s*\\(([\\s\\S]*?)\\);',
  ).firstMatch(body);
  if (list == null) {
    return const <String>[];
  }
  return RegExp(r'^\s*([A-Za-z0-9_]+)\s*,', multiLine: true)
      .allMatches(list.group(1)!)
      .map((match) => match.group(1)!)
      .toList(growable: false);
}

bool _hasToken(String source, String token) => source.contains(token);

bool _hasIpadOrientations(String infoPlistSource) {
  final array = RegExp(
    r'<key>\s*UISupportedInterfaceOrientations~ipad\s*</key>\s*<array>([\s\S]*?)</array>',
  ).firstMatch(infoPlistSource)?.group(1);
  if (array == null) {
    return false;
  }
  return const <String>[
    'UIInterfaceOrientationPortrait',
    'UIInterfaceOrientationPortraitUpsideDown',
    'UIInterfaceOrientationLandscapeLeft',
    'UIInterfaceOrientationLandscapeRight',
  ].every((orientation) => array.contains('<string>$orientation</string>'));
}

bool _hasLocalizedPermissions(
  String source, {
  required String cameraPurpose,
  required String photoPurpose,
}) {
  return source.contains('"NSCameraUsageDescription" = "$cameraPurpose";') &&
      source.contains('"NSPhotoLibraryUsageDescription" = "$photoPurpose";');
}

bool _hasIcon(String source, {required String size, required String idiom}) {
  try {
    final decoded = jsonDecode(source);
    if (decoded is! Map<String, dynamic> || decoded['images'] is! List) {
      return false;
    }
    return (decoded['images'] as List).any(
      (image) =>
          image is Map && image['size'] == size && image['idiom'] == idiom,
    );
  } on FormatException {
    return false;
  }
}

String? _firstId(
  Map<String, _PbxObject> objects,
  bool Function(_PbxObject object) matches,
) {
  for (final object in objects.values) {
    if (matches(object)) {
      return object.id;
    }
  }
  return null;
}

bool _isType(_PbxObject object, String type) =>
    _scalar(object.body, 'isa') == type;

bool _hasKnownGermanRegion(String projectSource) {
  final withoutComments = _stripPbxComments(projectSource);
  final regions = RegExp(
    r'\bknownRegions\s*=\s*\(([\s\S]*?)\);',
  ).firstMatch(withoutComments)?.group(1);
  return regions != null &&
      RegExp(r'(^|\s)de\s*,', multiLine: true).hasMatch(regions);
}

bool _hasCompleteVariantGroup(Map<String, _PbxObject> objects) {
  final variantId = _firstId(
    objects,
    (object) =>
        _isType(object, 'PBXVariantGroup') &&
        _scalar(object.body, 'name') == 'InfoPlist.strings',
  );
  if (variantId == null) {
    return false;
  }
  final deRef = _firstId(
    objects,
    (object) =>
        _isType(object, 'PBXFileReference') &&
        _scalar(object.body, 'path') == 'de.lproj/InfoPlist.strings',
  );
  final enRef = _firstId(
    objects,
    (object) =>
        _isType(object, 'PBXFileReference') &&
        _scalar(object.body, 'path') == 'en.lproj/InfoPlist.strings',
  );
  if (deRef == null || enRef == null) {
    return false;
  }
  final children = _listIds(objects[variantId]!.body, 'children');
  return children.where((id) => id == deRef).length == 1 &&
      children.where((id) => id == enRef).length == 1;
}

String? _infoPlistVariantId(Map<String, _PbxObject> objects) => _firstId(
  objects,
  (object) =>
      _isType(object, 'PBXVariantGroup') &&
      _scalar(object.body, 'name') == 'InfoPlist.strings',
);

String? _runnerGroupId(Map<String, _PbxObject> objects) => _firstId(
  objects,
  (object) =>
      _isType(object, 'PBXGroup') &&
      _scalar(object.body, 'path') == 'Runner' &&
      _scalar(object.body, 'sourceTree') == '<group>',
);

String? _runnerResourcesPhaseId(Map<String, _PbxObject> objects) {
  final runnerTargetId = _firstId(
    objects,
    (object) =>
        _isType(object, 'PBXNativeTarget') &&
        _scalar(object.body, 'name') == 'Runner',
  );
  if (runnerTargetId == null) {
    return null;
  }
  for (final phaseId in _listIds(
    objects[runnerTargetId]!.body,
    'buildPhases',
  )) {
    final phase = objects[phaseId];
    if (phase != null && _isType(phase, 'PBXResourcesBuildPhase')) {
      return phaseId;
    }
  }
  return null;
}

bool _isExactlyOnceInRunnerGroup(Map<String, _PbxObject> objects) {
  final groupId = _runnerGroupId(objects);
  final variantId = _infoPlistVariantId(objects);
  if (groupId == null || variantId == null) {
    return false;
  }
  return _listIds(
        objects[groupId]!.body,
        'children',
      ).where((id) => id == variantId).length ==
      1;
}

bool _isExactlyOnceInRunnerResources(Map<String, _PbxObject> objects) {
  final phaseId = _runnerResourcesPhaseId(objects);
  final variantId = _infoPlistVariantId(objects);
  if (phaseId == null || variantId == null) {
    return false;
  }
  final matchingBuildIds = <String>[];
  for (final buildId in _listIds(objects[phaseId]!.body, 'files')) {
    final build = objects[buildId];
    if (build != null &&
        _isType(build, 'PBXBuildFile') &&
        _scalar(build.body, 'fileRef') == variantId) {
      matchingBuildIds.add(buildId);
    }
  }
  return matchingBuildIds.length == 1;
}

IosStoreContractResult inspectIosStoreContract({
  required String projectSource,
  required String infoPlistSource,
  required String appIconSource,
  required String deStringsSource,
  required String enStringsSource,
}) {
  final violations = <String>[];
  final objects = _parsePbxObjects(projectSource);

  if (!_hasToken(
    projectSource,
    'PRODUCT_BUNDLE_IDENTIFIER = $_bundleIdentifier;',
  )) {
    violations.add('Runner bundle identifier is missing');
  }
  if (!_hasToken(projectSource, 'IPHONEOS_DEPLOYMENT_TARGET = 13.0;')) {
    violations.add('iOS 13.0 deployment target is missing');
  }
  if (!_hasToken(projectSource, 'TARGETED_DEVICE_FAMILY = "1,2";')) {
    violations.add('iPad target family is missing');
  }
  if (!_hasIpadOrientations(infoPlistSource)) {
    violations.add('iPad orientations are incomplete');
  }
  if (!infoPlistSource.contains('<key>NSCameraUsageDescription</key>')) {
    violations.add('camera permission key is missing');
  }
  if (!infoPlistSource.contains('<key>NSPhotoLibraryUsageDescription</key>')) {
    violations.add('photo library permission key is missing');
  }
  if (!_hasLocalizedPermissions(
    deStringsSource,
    cameraPurpose: _deCameraPurpose,
    photoPurpose: _dePhotoPurpose,
  )) {
    violations.add('German InfoPlist.strings content is incomplete');
  }
  if (!_hasLocalizedPermissions(
    enStringsSource,
    cameraPurpose: _enCameraPurpose,
    photoPurpose: _enPhotoPurpose,
  )) {
    violations.add('English InfoPlist.strings content is incomplete');
  }
  if (!_hasCompleteVariantGroup(objects)) {
    violations.add('InfoPlist.strings variant group is incomplete');
  }
  if (!_isExactlyOnceInRunnerGroup(objects)) {
    violations.add(
      'InfoPlist.strings is not registered in the Runner group exactly once',
    );
  }
  if (!_isExactlyOnceInRunnerResources(objects)) {
    violations.add(
      'InfoPlist.strings is not registered in Runner Resources exactly once',
    );
  }
  if (!_hasKnownGermanRegion(projectSource)) {
    violations.add('German is missing from Xcode knownRegions');
  }
  if (!_hasIcon(appIconSource, size: '83.5x83.5', idiom: 'ipad')) {
    violations.add('83.5x83.5 iPad icon is missing');
  }
  if (!_hasIcon(appIconSource, size: '1024x1024', idiom: 'ios-marketing')) {
    violations.add('1024x1024 iOS marketing icon is missing');
  }

  return IosStoreContractResult(violations);
}

String readIosStoreSource(String path) {
  try {
    final file = File(path);
    return file.existsSync() ? file.readAsStringSync() : '';
  } on FileSystemException {
    return '';
  } on FormatException {
    return '';
  }
}

void main() {
  final result = inspectIosStoreContract(
    projectSource: readIosStoreSource('ios/Runner.xcodeproj/project.pbxproj'),
    infoPlistSource: readIosStoreSource('ios/Runner/Info.plist'),
    appIconSource: readIosStoreSource(
      'ios/Runner/Assets.xcassets/AppIcon.appiconset/Contents.json',
    ),
    deStringsSource: readIosStoreSource(
      'ios/Runner/de.lproj/InfoPlist.strings',
    ),
    enStringsSource: readIosStoreSource(
      'ios/Runner/en.lproj/InfoPlist.strings',
    ),
  );
  if (result.isValid) {
    stdout.writeln('iOS/iPad static store contract passed.');
    return;
  }

  stderr.writeln('iOS/iPad static store contract is incomplete:');
  for (final violation in result.violations) {
    stderr.writeln('- $violation');
  }
  exitCode = 1;
}
