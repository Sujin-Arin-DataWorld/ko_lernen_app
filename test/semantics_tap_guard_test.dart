import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// §NAV-4(J3) — `Semantics(button: true, label: ...)` wrapping
/// `ExcludeSemantics` strips the tap action from any inner
/// GestureDetector/InkWell/SoriPressable/SoriCard child. A screen reader
/// still announces "button", but double-tap does nothing unless the outer
/// `Semantics` repeats the same `onTap` callback (see
/// `lib/widgets/sori/home_action.dart:56-62`/`:114-121`, the precedent this
/// guard generalizes to the rest of `lib/`).
///
/// This is a *file-level ratchet*, not a zero-tolerance gate:
/// `lib/screens/discover_screen.dart` is a known offender left untouched
/// because W-I deletes the whole screen — fixing it here would be wasted
/// work. When that deletion lands, shrink [knownOffenders] to empty.
void main() {
  const knownOffenders = <String>{'lib/screens/discover_screen.dart'};

  test('self-check: defect / defect-variant / clean fixtures', () {
    const defect = '''
      Semantics(
        button: true,
        label: 'Close',
        child: ExcludeSemantics(
          child: SoriPressable(onTap: _exit, child: Icon(Icons.close)),
        ),
      )
    ''';
    const defectVariant = '''
      Semantics(
        button: true,
        label: 'Open',
        child: ExcludeSemantics(
          child: SoriCard(onTap: _open, child: Text('x')),
        ),
      )
    ''';
    const clean = '''
      Semantics(
        button: true,
        label: 'Close',
        onTap: _exit,
        child: ExcludeSemantics(
          child: SoriPressable(onTap: _exit, child: Icon(Icons.close)),
        ),
      )
    ''';

    expect(
      _excludeSemanticsTapOffenses(_blankStringsAndComments(defect)),
      1,
    );
    expect(
      _excludeSemanticsTapOffenses(_blankStringsAndComments(defectVariant)),
      1,
    );
    expect(_excludeSemanticsTapOffenses(_blankStringsAndComments(clean)), 0);
  });

  test(
    'Semantics(button) wrapping ExcludeSemantics repeats onTap on the outer node',
    () {
      final offenders = <String>{};
      for (final file
          in Directory('lib')
              .listSync(recursive: true)
              .whereType<File>()
              .where((f) => f.path.endsWith('.dart'))) {
        final clean = _blankStringsAndComments(file.readAsStringSync());
        if (_excludeSemanticsTapOffenses(clean) > 0) {
          offenders.add(_relativeLibPath(file));
        }
      }

      expect(
        offenders,
        knownOffenders,
        reason:
            'Semantics(button: true) wrapping ExcludeSemantics must repeat '
            'the inner onTap on the outer Semantics node, or a screen '
            "reader's double-tap does nothing. New offenders beyond "
            '$knownOffenders (discover_screen.dart, pending deletion in '
            'W-I) need the same fix as scenario_player_screen.dart and '
            'sori_stage_today_screen.dart.\n${offenders.join('\n')}',
      );
    },
  );
}

/// Counts `Semantics(button-ish)` call sites in [clean] whose `child:` is an
/// `ExcludeSemantics(...)` subtree containing an `onTap:` somewhere inside,
/// while the outer `Semantics(...)` itself has no top-level `onTap:`.
int _excludeSemanticsTapOffenses(String clean) {
  var count = 0;
  for (final span in _constructorSpans(clean, 'Semantics')) {
    final body = clean.substring(span.start, span.end);
    final inner = body.substring('Semantics('.length, body.length - 1);
    final args = _topLevelArgs(inner);
    String? childValue;
    var hasTopOnTap = false;
    for (final arg in args) {
      final match = RegExp(r'^\s*(\w+)\s*:').firstMatch(arg);
      if (match == null) {
        continue;
      }
      final key = match.group(1);
      if (key == 'onTap') {
        hasTopOnTap = true;
      }
      if (key == 'child') {
        childValue = arg.substring(match.end).trim();
      }
    }
    if (childValue == null) {
      continue;
    }
    final isExcludeSemanticsChild =
        childValue.startsWith('ExcludeSemantics(') ||
        childValue.startsWith('const ExcludeSemantics(');
    if (!isExcludeSemanticsChild) {
      continue;
    }
    final childHasOnTap = RegExp(r'onTap\s*:').hasMatch(childValue);
    if (childHasOnTap && !hasTopOnTap) {
      count++;
    }
  }
  return count;
}

/// Splits a constructor's argument-list text into top-level comma-separated
/// arguments, ignoring commas nested inside `()`/`{}`/`[]`.
List<String> _topLevelArgs(String body) {
  final args = <String>[];
  var depth = 0;
  var start = 0;
  for (var i = 0; i < body.length; i++) {
    final c = body[i];
    if (c == '(' || c == '{' || c == '[') {
      depth++;
    } else if (c == ')' || c == '}' || c == ']') {
      depth--;
    } else if (c == ',' && depth == 0) {
      args.add(body.substring(start, i));
      start = i + 1;
    }
  }
  final rest = body.substring(start).trim();
  if (rest.isNotEmpty) {
    args.add(rest);
  }
  return args;
}

class _Span {
  const _Span(this.start, this.end);
  final int start;
  final int end;
}

/// Finds balanced-paren spans of `name(...)` calls, requiring a non-identifier
/// character (or start-of-string) immediately before `name(` so e.g.
/// `ExcludeSemantics(`/`MergeSemantics(` never match a search for
/// `Semantics(`.
List<_Span> _constructorSpans(String clean, String name) {
  final spans = <_Span>[];
  final matches = RegExp(
    r'(^|[^A-Za-z0-9_$])' + RegExp.escape(name) + r'\(',
  ).allMatches(clean);
  for (final match in matches) {
    final start = match.end - name.length - 1;
    var depth = 0;
    for (var index = start; index < clean.length; index++) {
      if (clean[index] == '(') {
        depth++;
      } else if (clean[index] == ')') {
        depth--;
        if (depth == 0) {
          spans.add(_Span(start, index + 1));
          break;
        }
      }
    }
  }
  return spans;
}

String _relativeLibPath(File file) {
  final path = file.path.replaceAll('\\', '/');
  return 'lib/${path.split('lib/').last}';
}

String _blankStringsAndComments(String src) {
  final out = src.split('');
  final n = src.length;
  var i = 0;
  while (i < n) {
    final c = src[i];
    if (c == '/' && i + 1 < n && src[i + 1] == '/') {
      var j = src.indexOf('\n', i);
      if (j < 0) {
        j = n;
      }
      for (var k = i; k < j; k++) {
        out[k] = ' ';
      }
      i = j;
    } else if (c == '/' && i + 1 < n && src[i + 1] == '*') {
      var j = src.indexOf('*/', i + 2);
      j = j < 0 ? n : j + 2;
      for (var k = i; k < j; k++) {
        out[k] = ' ';
      }
      i = j;
    } else if (c == "'" || c == '"') {
      final quote = c;
      var j = i + 1;
      while (j < n) {
        if (src[j] == r'\') {
          j += 2;
          continue;
        }
        if (src[j] == quote) {
          j++;
          break;
        }
        if (src[j] == '\n') {
          break;
        }
        j++;
      }
      final end = j < n ? j : n;
      for (var k = i; k < end; k++) {
        out[k] = ' ';
      }
      i = j;
    } else {
      i++;
    }
  }
  return out.join();
}
