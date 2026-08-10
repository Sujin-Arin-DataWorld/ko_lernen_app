import 'dart:io';

import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:xml/xml.dart';

const _googleServicePlist = 'GoogleService-Info.plist';
const _plistPath = 'ios/Runner/GoogleService-Info.plist';

class IosFirebaseConfigurationResult {
  const IosFirebaseConfigurationResult(this.missing);

  final List<String> missing;

  bool get isValid => missing.isEmpty;
}

int? _matchingDelimiter(
  String source,
  int openingIndex,
  String opening,
  String closing,
) {
  var depth = 0;
  var index = openingIndex;

  while (index < source.length) {
    final current = source[index];
    if (current == "'" || current == '"') {
      final quote = current;
      final tripleDelimiter = '$quote$quote$quote';
      final triple = source.startsWith(tripleDelimiter, index);
      final raw =
          index > 0 && (source[index - 1] == 'r' || source[index - 1] == 'R');
      index += triple ? 3 : 1;
      while (index < source.length) {
        if (!raw && source[index] == '\\' && index + 1 < source.length) {
          index += 2;
          continue;
        }
        if (triple && source.startsWith(tripleDelimiter, index)) {
          index += 3;
          break;
        }
        if (!triple && source[index] == quote) {
          index += 1;
          break;
        }
        index += 1;
      }
      continue;
    }

    if (source.startsWith(opening, index)) {
      depth += 1;
      index += opening.length;
      continue;
    }
    if (source.startsWith(closing, index)) {
      depth -= 1;
      if (depth == 0) {
        return index;
      }
      index += closing.length;
      continue;
    }
    index += 1;
  }

  return null;
}

bool _hasLiveIosFirebaseOptions(String firebaseOptionsSource) {
  final parseResult = parseString(
    content: firebaseOptionsSource,
    throwIfDiagnostics: false,
  );
  if (parseResult.errors.isNotEmpty) {
    return false;
  }

  ClassDeclaration? optionsClass;
  for (final declaration in parseResult.unit.declarations) {
    if (declaration is ClassDeclaration &&
        declaration.namePart.typeName.lexeme == 'DefaultFirebaseOptions') {
      optionsClass = declaration;
      break;
    }
  }
  final classBody = optionsClass?.body;
  if (classBody is! BlockClassBody) {
    return false;
  }

  VariableDeclaration? iosDeclaration;
  for (final field in classBody.members.whereType<FieldDeclaration>()) {
    if (field.staticKeyword == null ||
        !field.fields.isConst ||
        field.fields.type?.toSource() != 'FirebaseOptions') {
      continue;
    }
    for (final variable in field.fields.variables) {
      if (variable.name.lexeme == 'ios' &&
          RegExp(
            r'^FirebaseOptions\s*\(',
          ).hasMatch(variable.initializer?.toSource() ?? '')) {
        iosDeclaration = variable;
        break;
      }
    }
    if (iosDeclaration != null) {
      break;
    }
  }
  if (iosDeclaration == null) {
    return false;
  }
  final staticIosDeclaration = iosDeclaration;

  MethodDeclaration? currentPlatform;
  for (final member in classBody.members.whereType<MethodDeclaration>()) {
    if (member.isStatic &&
        member.isGetter &&
        member.name.lexeme == 'currentPlatform') {
      currentPlatform = member;
      break;
    }
  }
  if (currentPlatform == null) {
    return false;
  }
  final platformGetter = currentPlatform;

  final body = platformGetter.body;
  if (body is BlockFunctionBody) {
    for (final statement in body.block.statements) {
      if (statement is! SwitchStatement ||
          statement.expression.toSource() != 'defaultTargetPlatform') {
        continue;
      }
      for (final member in statement.members) {
        String? caseExpression;
        if (member is SwitchCase) {
          caseExpression = member.expression.toSource();
        } else if (member is SwitchPatternCase) {
          final pattern = member.guardedPattern.pattern;
          if (member.guardedPattern.whenClause == null &&
              pattern is ConstantPattern) {
            caseExpression = pattern.expression.toSource();
          }
        }
        if (caseExpression == 'TargetPlatform.iOS' &&
            member.statements.isNotEmpty &&
            member.statements.first is ReturnStatement &&
            _referencesStaticIosDeclaration(
              (member.statements.first as ReturnStatement).expression,
              platformGetter,
              staticIosDeclaration,
            )) {
          return true;
        }
      }
    }
    return false;
  }

  if (body is ExpressionFunctionBody && body.expression is SwitchExpression) {
    final switchExpression = body.expression as SwitchExpression;
    if (switchExpression.expression.toSource() != 'defaultTargetPlatform') {
      return false;
    }
    return switchExpression.cases.any((switchCase) {
      final pattern = switchCase.guardedPattern.pattern;
      return switchCase.guardedPattern.whenClause == null &&
          pattern is ConstantPattern &&
          pattern.expression.toSource() == 'TargetPlatform.iOS' &&
          _referencesStaticIosDeclaration(
            switchCase.expression,
            platformGetter,
            staticIosDeclaration,
          );
    });
  }

  return false;
}

bool _referencesStaticIosDeclaration(
  Expression? expression,
  MethodDeclaration currentPlatform,
  VariableDeclaration iosDeclaration,
) {
  if (expression is! SimpleIdentifier ||
      expression.name != iosDeclaration.name.lexeme) {
    return false;
  }

  return _isOnlyIosTokenInGetter(currentPlatform.body, expression);
}

bool _isOnlyIosTokenInGetter(
  FunctionBody body,
  SimpleIdentifier returnedIdentifier,
) {
  // Analyzer 10 represents declaration names, including pattern bindings, as
  // tokens rather than SimpleIdentifier nodes. Comparing parser-owned token
  // identity lets this reject every other `ios` occurrence without listing
  // declaration AST subclasses or matching source text.
  final returnedToken = returnedIdentifier.token;
  final endToken = body.endToken;
  var token = body.beginToken;
  while (true) {
    if (token.lexeme == returnedIdentifier.name &&
        !identical(token, returnedToken)) {
      return false;
    }
    if (identical(token, endToken)) {
      return true;
    }
    final next = token.next;
    if (next == null) {
      return false;
    }
    token = next;
  }
}

bool _isParseablePlist(String source) {
  if (source.trim().isEmpty) {
    return false;
  }
  try {
    final document = XmlDocument.parse(source);
    final root = document.rootElement;
    if (root.name.local != 'plist') {
      return false;
    }
    final dicts = root.childElements
        .where((element) => element.name.local == 'dict')
        .toList(growable: false);
    if (dicts.length != 1) {
      return false;
    }
    final entries = dicts.single.childElements.toList(growable: false);
    for (var index = 0; index + 1 < entries.length; index += 2) {
      if (entries[index].name.local == 'key' &&
          entries[index].innerText.trim() == 'GOOGLE_APP_ID' &&
          entries[index + 1].name.local == 'string' &&
          entries[index + 1].innerText.trim().isNotEmpty) {
        return true;
      }
    }
    return false;
  } on XmlException {
    return false;
  } on StateError {
    return false;
  }
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
      output.write('  ');
      index += 2;
      while (index < source.length && !source.startsWith('*/', index)) {
        final commentCharacter = source[index];
        output.write(
          commentCharacter == '\n' || commentCharacter == '\r'
              ? commentCharacter
              : ' ',
        );
        index += 1;
      }
      if (source.startsWith('*/', index)) {
        output.write('  ');
        index += 2;
      }
      continue;
    }

    output.write(current);
    index += 1;
  }

  return output.toString();
}

Map<String, _PbxObject> _parsePbxObjects(String source) {
  final uncommentedSource = _stripPbxComments(source);
  final result = <String, _PbxObject>{};
  final starts = RegExp(
    r'^\s*([A-Za-z0-9_]+)(?:\s*/\*.*?\*/)?\s*=\s*\{',
    multiLine: true,
  );
  for (final match in starts.allMatches(uncommentedSource)) {
    final opening = uncommentedSource.indexOf('{', match.start);
    final closing = _matchingDelimiter(uncommentedSource, opening, '{', '}');
    if (closing == null) {
      continue;
    }
    final id = match.group(1)!;
    result.putIfAbsent(
      id,
      () => _PbxObject(id, uncommentedSource.substring(opening + 1, closing)),
    );
  }
  return result;
}

String? _pbxScalar(String body, String key) {
  final match = RegExp(
    '\\b${RegExp.escape(key)}\\s*=\\s*("(?:[^"\\\\]|\\\\.)*"|[^;]+)\\s*;',
  ).firstMatch(body);
  if (match == null) {
    return null;
  }
  final raw = match.group(1)!.trim();
  return raw.length >= 2 && raw.startsWith('"') && raw.endsWith('"')
      ? raw.substring(1, raw.length - 1)
      : raw;
}

Set<String> _pbxListIds(String body, String key) {
  final list = RegExp(
    '\\b${RegExp.escape(key)}\\s*=\\s*\\(([\\s\\S]*?)\\);',
  ).firstMatch(body);
  if (list == null) {
    return const <String>{};
  }
  return RegExp(
    r'^\s*([A-Za-z0-9_]+)(?:\s*/\*.*?\*/)?\s*,',
    multiLine: true,
  ).allMatches(list.group(1)!).map((match) => match.group(1)!).toSet();
}

bool _hasRunnerPlistResourceMembership(String projectSource) {
  final objects = _parsePbxObjects(projectSource);
  final mainGroupIds = objects.values
      .where((object) => _pbxScalar(object.body, 'isa') == 'PBXProject')
      .map((object) => _pbxScalar(object.body, 'mainGroup'))
      .whereType<String>()
      .map((id) => id.split(RegExp(r'\s+')).first)
      .toSet();
  final reachableGroupIds = <String>{};
  final pendingGroupIds = mainGroupIds.toList(growable: true);
  while (pendingGroupIds.isNotEmpty) {
    final groupId = pendingGroupIds.removeLast();
    if (!reachableGroupIds.add(groupId)) {
      continue;
    }
    final group = objects[groupId];
    if (group == null || _pbxScalar(group.body, 'isa') != 'PBXGroup') {
      continue;
    }
    for (final childId in _pbxListIds(group.body, 'children')) {
      if (_pbxScalar(objects[childId]?.body ?? '', 'isa') == 'PBXGroup') {
        pendingGroupIds.add(childId);
      }
    }
  }
  final runnerTargets = objects.values.where(
    (object) =>
        _pbxScalar(object.body, 'isa') == 'PBXNativeTarget' &&
        _pbxScalar(object.body, 'name') == 'Runner',
  );

  for (final target in runnerTargets) {
    for (final phaseId in _pbxListIds(target.body, 'buildPhases')) {
      final phase = objects[phaseId];
      if (phase == null ||
          _pbxScalar(phase.body, 'isa') != 'PBXResourcesBuildPhase') {
        continue;
      }

      for (final buildFileId in _pbxListIds(phase.body, 'files')) {
        final buildFile = objects[buildFileId];
        if (buildFile == null ||
            _pbxScalar(buildFile.body, 'isa') != 'PBXBuildFile') {
          continue;
        }
        final fileReferenceId = _pbxScalar(
          buildFile.body,
          'fileRef',
        )?.split(RegExp(r'\s+')).first;
        final fileReference = objects[fileReferenceId];
        if (fileReference == null ||
            _pbxScalar(fileReference.body, 'isa') != 'PBXFileReference' ||
            _pbxScalar(fileReference.body, 'sourceTree') != '<group>') {
          continue;
        }

        final plistPath = _pbxScalar(fileReference.body, 'path');
        // Xcode can express the same physical resource in either of these
        // valid forms. Adding it inside the Runner group uses the bare name;
        // adding it from the project root retains the Runner/ prefix. In both
        // cases the Runner resources build phase copies the local plist.
        if (plistPath == 'Runner/$_googleServicePlist') {
          return true;
        }
        if (plistPath != _googleServicePlist) {
          continue;
        }

        final belongsToRunnerGroup = reachableGroupIds.any((groupId) {
          final object = objects[groupId];
          return object != null &&
              _pbxScalar(object.body, 'isa') == 'PBXGroup' &&
              _pbxScalar(object.body, 'path') == 'Runner' &&
              _pbxScalar(object.body, 'sourceTree') == '<group>' &&
              _pbxListIds(object.body, 'children').contains(fileReferenceId);
        });
        if (belongsToRunnerGroup) {
          return true;
        }
      }
    }
  }

  return false;
}

IosFirebaseConfigurationResult inspectIosFirebaseConfiguration({
  required String firebaseOptionsSource,
  required String? plistSource,
  required String projectSource,
}) {
  final missing = <String>[];

  if (!_hasLiveIosFirebaseOptions(firebaseOptionsSource)) {
    missing.add('firebase_options iOS');
  }
  if (plistSource == null) {
    missing.add(_plistPath);
  } else if (!_isParseablePlist(plistSource)) {
    missing.add('parseable $_plistPath');
  }
  if (!_hasRunnerPlistResourceMembership(projectSource)) {
    missing.add('Xcode Runner target membership for $_googleServicePlist');
  }

  return IosFirebaseConfigurationResult(missing);
}

void main() {
  final firebaseOptions = File('lib/firebase_options.dart');
  final plist = File(_plistPath);
  final xcodeProject = File('ios/Runner.xcodeproj/project.pbxproj');
  final result = inspectIosFirebaseConfiguration(
    firebaseOptionsSource: firebaseOptions.existsSync()
        ? firebaseOptions.readAsStringSync()
        : '',
    plistSource: plist.existsSync() ? plist.readAsStringSync() : null,
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
