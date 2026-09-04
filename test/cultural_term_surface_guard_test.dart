import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:ko_lernen_app/models/cultural_glossary.dart';
import 'package:ko_lernen_app/services/cultural_glossary_repository.dart';

/// §RELEASE-2(J13) — every hardcoded `termId: '…'` literal handed to
/// `CulturalHelpButton(`/`SoriTerm(`/`SoriTerm.span(`, and every literal
/// second argument to `showCulturalTermSheetForId(`, must resolve to a real
/// [CulturalGlossary] entry — a `?` button or dotted term that opens a
/// missing-entry sheet is a dead surface a real device Jin-checklist walk
/// would otherwise have to catch by hand.
///
/// Variable-fed termIds (e.g. `SoriTerm(termId: someLocalVariable, ...)`,
/// as in `hanok_stage_names.dart`'s `hanokStageGlossaryTermId`) are out of
/// scope for this literal-string scan — those are covered by
/// `test/hanok_stage_term_ids_test.dart` instead.
void main() {
  late CulturalGlossary catalog;

  setUpAll(() async {
    catalog = CulturalGlossary.fromJsonString(
      await File(CulturalGlossaryRepository.assetPath).readAsString(),
    );
  });

  test(
    'every literal termId passed to a cultural-term surface exists in the glossary',
    () {
      final knownTermIds = catalog.entries.map((e) => e.termId).toSet();
      final offenders = <String>[];

      for (final file
          in Directory('lib')
              .listSync(recursive: true)
              .whereType<File>()
              .where((f) => f.path.endsWith('.dart'))) {
        final clean = _blankStringsAndComments(file.readAsStringSync());
        final relativePath = _relativeLibPath(file);

        for (final constructor in const [
          'CulturalHelpButton',
          'SoriTerm',
          'SoriTerm.span',
        ]) {
          for (final span in _constructorSpans(clean, constructor)) {
            final body = clean.substring(span.start, span.end);
            final match = RegExp(
              r"termId\s*:\s*'([^']+)'",
            ).firstMatch(body);
            if (match == null) {
              continue; // variable-fed or no termId arg — out of scope.
            }
            final termId = match.group(1)!;
            if (!knownTermIds.contains(termId)) {
              offenders.add(
                "$relativePath: $constructor(termId: '$termId') — no "
                'glossary entry.',
              );
            }
          }
        }

        for (final match
            in RegExp(
              r"showCulturalTermSheetForId\(\s*[a-zA-Z_][\w.]*\s*,\s*'([^']+)'",
            ).allMatches(clean)) {
          final termId = match.group(1)!;
          if (!knownTermIds.contains(termId)) {
            offenders.add(
              "$relativePath: showCulturalTermSheetForId(.., '$termId') — "
              'no glossary entry.',
            );
          }
        }
      }

      expect(
        offenders,
        isEmpty,
        reason:
            'Every literal termId at a cultural-term surface must exist in '
            'docs/data/cultural_glossary.json.\n${offenders.join('\n')}',
      );
    },
  );
}

class _Span {
  const _Span(this.start, this.end);
  final int start;
  final int end;
}

/// Finds balanced-paren spans of `name(...)` calls, requiring a
/// non-identifier character (or start-of-string) immediately before `name(`
/// so e.g. a plain `SoriTerm(` search never matches inside
/// `SoriTerm.span(` at the wrong offset, and vice versa the dotted search
/// only matches the dotted call.
List<_Span> _constructorSpans(String clean, String name) {
  final spans = <_Span>[];
  final matches = RegExp(
    r'(^|[^A-Za-z0-9_$.])' + RegExp.escape(name) + r'\(',
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
  final path = file.path.replaceAll(String.fromCharCode(92), '/');
  return 'lib/${path.split('lib/').last}';
}

String _blankStringsAndComments(String source) {
  final output = source.split('');
  var index = 0;
  while (index < source.length) {
    if (source.startsWith('//', index)) {
      final end = source.indexOf('\n', index);
      final limit = end < 0 ? source.length : end;
      for (var cursor = index; cursor < limit; cursor++) {
        output[cursor] = ' ';
      }
      index = limit;
      continue;
    }
    if (source.startsWith('/*', index)) {
      final end = source.indexOf('*/', index + 2);
      final limit = end < 0 ? source.length : end + 2;
      for (var cursor = index; cursor < limit; cursor++) {
        output[cursor] = ' ';
      }
      index = limit;
      continue;
    }
    final quote = source[index];
    if (quote == "'" || quote == '"') {
      var cursor = index + 1;
      while (cursor < source.length) {
        if (source[cursor] == r'\') {
          cursor += 2;
          continue;
        }
        if (source[cursor] == quote) {
          cursor++;
          break;
        }
        cursor++;
      }
      // Keep the literal itself intact (blank the quotes/backslashes' outer
      // shell only would be wrong) — this pass only blanks *other* string
      // literals so termId regexes below still see them; overwritten by
      // callers who need to. Here we leave string contents as-is because the
      // regexes above specifically look for `termId: '...'` — blanking
      // quotes would destroy that. Only comments are blanked above; string
      // literals pass through unchanged.
      index = cursor;
      continue;
    }
    index++;
  }
  return output.join();
}
