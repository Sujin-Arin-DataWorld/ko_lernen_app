import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

const _lockPath = 'docs/UIUX_BIBLE_APPLICATION_EXECUTION_LOCK.md';

void main() {
  test('execution lock inventories every registered route exactly once', () {
    final mainSource = File('lib/main.dart').readAsStringSync();
    final switchStart = mainSource.indexOf('onGenerateRoute: (settings) {');
    final switchEnd = mainSource.indexOf('\n            default:', switchStart);
    expect(switchStart, greaterThanOrEqualTo(0));
    expect(switchEnd, greaterThan(switchStart));

    final registered = <String>[];
    final unresolved = <String>[];
    final ambiguous = <String>[];
    final routeSwitch = mainSource.substring(switchStart, switchEnd);
    for (final match in RegExp(
      r"case\s+(?:'([^']+)'|([A-Za-z_]\w*))\s*:",
    ).allMatches(routeSwitch)) {
      final literal = match.group(1);
      final identifier = match.group(2);
      final declarations = identifier == null
          ? const <String>[]
          : _stringConstantValues(identifier);
      if (declarations.length > 1) {
        ambiguous.add(identifier!);
      }
      final route = literal ?? declarations.singleOrNull;
      if (route == null) {
        unresolved.add(identifier!);
      } else {
        registered.add(route);
      }
    }
    expect(unresolved, isEmpty);
    expect(ambiguous, isEmpty);
    expect(registered, hasLength(69));
    expect(registered.toSet(), hasLength(registered.length));

    final lock = File(_lockPath).readAsStringSync();
    final sectionStart = lock.indexOf('## 6. Route-by-route audit');
    expect(sectionStart, greaterThanOrEqualTo(0));
    final sectionEnd = lock.indexOf(
      '\n## 7. Embedded and indirect screen audit',
      sectionStart,
    );
    expect(sectionEnd, greaterThan(sectionStart));
    final routeInventory = lock.substring(sectionStart, sectionEnd);
    final documented = RegExp(
      r'^\| `(/[^`]*)` \|',
      multiLine: true,
    ).allMatches(routeInventory).map((match) => match.group(1)!).toList();
    expect(documented, hasLength(69));
    expect(documented.toSet(), hasLength(documented.length));

    registered.sort();
    documented.sort();
    expect(documented, registered);
  });

  test('execution lock names every public screen-like surface owner', () {
    final lock = File(_lockPath).readAsStringSync();
    final sectionStart = lock.indexOf('## 6. Route-by-route audit');
    expect(sectionStart, greaterThanOrEqualTo(0));
    final sectionEnd = lock.indexOf(
      '\n## 8. Common-component audit',
      sectionStart,
    );
    expect(sectionEnd, greaterThan(sectionStart));
    final inventory = lock.substring(sectionStart, sectionEnd);
    final surfaceNamePattern = RegExp(
      r'^[A-Z][A-Za-z0-9_]*(?:Screen|Layout|App|Shell|Overview|Quest|Sheet)$',
    );
    final documented = RegExp(r'`([^`]+)`')
        .allMatches(inventory)
        .map((match) => match.group(1)!)
        .where(surfaceNamePattern.hasMatch)
        .toSet();
    final seen = <String>{};

    for (final source in _dartFiles(Directory('lib/screens'))) {
      final contents = source.readAsStringSync();
      for (final match in RegExp(
        r'^(?:(?:abstract|base|final|interface|sealed)\s+)*class\s+'
        r'([A-Z][A-Za-z0-9_]*(?:Screen|Layout|App|Shell|Overview|Quest|Sheet))\b',
        multiLine: true,
      ).allMatches(contents)) {
        final className = match.group(1)!;
        seen.add(className);
      }
    }

    expect(seen, hasLength(97));
    expect(documented, hasLength(97));
    expect(seen.difference(documented), isEmpty);
    expect(documented.difference(seen), isEmpty);
  });

  test('execution lock assigns every Sori Dart file to one family', () {
    final lock = File(_lockPath).readAsStringSync();
    final sectionStart = lock.indexOf('## 8. Common-component audit');
    final sectionEnd = lock.indexOf(
      '\nTwo non-Sori state widgets',
      sectionStart,
    );
    expect(sectionStart, greaterThanOrEqualTo(0));
    expect(sectionEnd, greaterThan(sectionStart));

    final listed = <String>[];
    final section = lock.substring(sectionStart, sectionEnd);
    for (final line in section.split('\n')) {
      final cells = line.split('|');
      if (cells.length < 4) {
        continue;
      }
      listed.addAll(
        RegExp(
          r'`([^`]+)`',
        ).allMatches(cells[2]).map((match) => match.group(1)!),
      );
    }

    final root = Directory('lib/widgets/sori').absolute.path;
    final actual = _dartFiles(Directory(root)).map((file) {
      return file.path
          .substring(root.length + 1)
          .replaceAll(r'\', '/')
          .replaceFirst(RegExp(r'\.dart$'), '');
    }).toList();
    expect(actual, hasLength(133));
    expect(actual.toSet(), hasLength(actual.length));
    expect(listed, hasLength(133));
    expect(listed.toSet(), hasLength(listed.length));

    actual.sort();
    listed.sort();
    expect(listed, actual);
  });
}

Iterable<File> _dartFiles(Directory directory) {
  return directory
      .listSync(recursive: true)
      .whereType<File>()
      .where((file) => file.path.endsWith('.dart'));
}

List<String> _stringConstantValues(String identifier) {
  final declaration = RegExp(
    '''const\\s+String\\s+${RegExp.escape(identifier)}\\s*=\\s*['"]([^'"]+)['"]\\s*;''',
  );
  return _dartFiles(Directory('lib'))
      .expand(
        (source) => declaration
            .allMatches(source.readAsStringSync())
            .map((match) => match.group(1)!),
      )
      .toList();
}
