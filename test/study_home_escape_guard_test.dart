import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  const expectedStudyFrameScreens = <String>{
    'lib/screens/chosung_quiz_screen.dart',
    'lib/screens/cloze_game_screen.dart',
    'lib/screens/custom_pack_matching_screen.dart',
    'lib/screens/custom_pack_play_screen.dart',
    'lib/screens/custom_pack_quiz_screen.dart',
    'lib/screens/custom_pack_typing_screen.dart',
    'lib/screens/daily_challenge_screen.dart',
    'lib/screens/grammar_choice_quiz_screen.dart',
    'lib/screens/grammar_screen.dart',
    'lib/screens/hard_choice_quiz_screen.dart',
    'lib/screens/kkeunmari_screen.dart',
    'lib/screens/legacy_vocab_screen.dart',
    'lib/screens/listening_play_screen.dart',
    'lib/screens/review_session_screen.dart',
    'lib/screens/satz_arcade_screen.dart',
    'lib/screens/scenario_player_screen.dart',
    'lib/screens/silben_kreuz_screen.dart',
    'lib/screens/smalltalk_screen.dart',
    'lib/screens/speed_match_screen.dart',
    'lib/screens/vocab_nuance_screen.dart',
    'lib/screens/vocab_pack_recall_screen.dart',
    'lib/screens/vocab_pack_result_screen.dart',
    'lib/screens/vocab_pack_screen.dart',
    'lib/screens/word_web_quiz_screen.dart',
    'lib/screens/word_web_study_screen.dart',
  };
  const duplicateAllowlist = <String>{};
  const activeConfirmContracts = <String, String>{
    'lib/screens/chosung_quiz_screen.dart':
        '!_roundComplete && (_roundIndex > 0 || _state != _State.waiting)',
    'lib/screens/cloze_game_screen.dart':
        '_idx > 0 || _picked != null || _retried',
    'lib/screens/custom_pack_matching_screen.dart':
        '!_roundDone && (_matched.isNotEmpty || _misses > 0)',
    'lib/screens/custom_pack_quiz_screen.dart': '_qIdx > 0 || _picked != null',
    'lib/screens/custom_pack_typing_screen.dart':
        '_idx > 0 || _correct != null',
    'lib/screens/daily_challenge_screen.dart':
        '_idx > 0 || _picked != null || _retried',
    'lib/screens/grammar_choice_quiz_screen.dart':
        '!_isDone && (_index > 0 || _answered)',
    'lib/screens/hard_choice_quiz_screen.dart':
        '!_done && (_idx > 0 || _locked)',
    'lib/screens/kkeunmari_screen.dart': '_end == _End.none && _remaining > 0',
    'lib/screens/review_session_screen.dart': '!_done && _reviewed > 0',
    'lib/screens/satz_arcade_screen.dart': '_hasSubmittedAnswer',
    'lib/screens/scenario_player_screen.dart': '_stage > 0 && !_isResultStage',
    'lib/screens/silben_kreuz_screen.dart':
        '!_solved && (_locked.isNotEmpty || _wrongTick > 0)',
    'lib/screens/speed_match_screen.dart': '_running',
    'lib/screens/vocab_nuance_screen.dart': '_index > 0 || _picked != null',
    'lib/screens/vocab_pack_recall_screen.dart':
        '!_done && (_index > 0 || _feedback != null)',
    'lib/screens/vocab_pack_screen.dart': '_hasSubmittedAssessment',
    'lib/screens/word_web_quiz_screen.dart': '!_done && (_idx > 0 || _locked)',
  };
  const customLeadingScreens = <String>{
    'lib/screens/chosung_quiz_screen.dart',
    'lib/screens/cloze_game_screen.dart',
    'lib/screens/custom_pack_matching_screen.dart',
    'lib/screens/custom_pack_play_screen.dart',
    'lib/screens/custom_pack_quiz_screen.dart',
    'lib/screens/custom_pack_typing_screen.dart',
    'lib/screens/daily_challenge_screen.dart',
    'lib/screens/grammar_screen.dart',
    'lib/screens/satz_arcade_screen.dart',
    'lib/screens/scenario_player_screen.dart',
    'lib/screens/silben_kreuz_screen.dart',
    'lib/screens/speed_match_screen.dart',
    'lib/screens/vocab_pack_recall_screen.dart',
    'lib/screens/vocab_pack_screen.dart',
  };
  const staticImmediateEscapeScreens = <String>{
    'lib/screens/custom_pack_play_screen.dart',
    'lib/screens/grammar_screen.dart',
    'lib/screens/legacy_vocab_screen.dart',
    'lib/screens/listening_play_screen.dart',
    'lib/screens/smalltalk_screen.dart',
    'lib/screens/vocab_pack_result_screen.dart',
    'lib/screens/word_web_study_screen.dart',
  };

  test('the StudyFrame inventory stays explicit and complete', () {
    final actual = Directory('lib/screens')
        .listSync(recursive: true)
        .whereType<File>()
        .where((file) => file.path.endsWith('.dart'))
        .where(
          (file) => _blankStringsAndComments(
            file.readAsStringSync(),
          ).contains('SoriStudyFrame('),
        )
        .map(_relativePath)
        .toSet();

    expect(actual, expectedStudyFrameScreens);
    expect(expectedStudyFrameScreens, hasLength(25));
  });

  test('all StudyFrame screens rely on the frame-owned home action', () {
    final offenders = <String>[];
    for (final path in expectedStudyFrameScreens) {
      final source = _blankStringsAndComments(File(path).readAsStringSync());
      final ownsHomeInsideFrame = _constructorInvocations(
        source,
        'SoriStudyFrame',
      ).any((invocation) => invocation.contains('SoriHomeAction('));
      if (ownsHomeInsideFrame && !duplicateAllowlist.contains(path)) {
        offenders.add(path);
      }
    }

    expect(duplicateAllowlist, isEmpty);
    expect(
      offenders,
      isEmpty,
      reason:
          'SoriStudyFrame owns the sole home action. Pass SoriHomeEscape to '
          'the frame instead of rendering SoriHomeAction in a screen.\n'
          '${offenders.join('\n')}',
    );
  });

  test('active and static home-escape decisions cover all 25 screens', () {
    expect(
      activeConfirmContracts.keys.toSet().intersection(
        staticImmediateEscapeScreens,
      ),
      isEmpty,
    );
    expect({
      ...activeConfirmContracts.keys,
      ...staticImmediateEscapeScreens,
    }, expectedStudyFrameScreens);
  });

  test('the custom-leading screen inventory stays explicit', () {
    final actual = expectedStudyFrameScreens.where((path) {
      final source = _blankStringsAndComments(File(path).readAsStringSync());
      return RegExp(r'\bleading\s*:').hasMatch(source);
    }).toSet();

    expect(actual, customLeadingScreens);
  });

  test('every active surface wires its exact confirmation state', () {
    final failures = <String>[];
    for (final entry in activeConfirmContracts.entries) {
      final source = _blankStringsAndComments(
        File(entry.key).readAsStringSync(),
      );
      final escapes = _constructorInvocations(
        source,
        'SoriHomeEscape',
      ).map(_normalizeWhitespace);
      final exactContract = _normalizeWhitespace(
        'confirmWhen: ${entry.value},',
      );
      final exactClosedContract = _normalizeWhitespace(
        'confirmWhen: ${entry.value})',
      );
      final matched = escapes.any(
        (escape) =>
            escape.contains(exactContract) ||
            escape.contains(exactClosedContract),
      );
      if (!matched) {
        failures.add('${entry.key}: ${entry.value}');
      }
    }

    expect(
      failures,
      isEmpty,
      reason:
          'Active learning surfaces must pass their real progress state to '
          'SoriHomeEscape.\n${failures.join('\n')}',
    );
  });

  test('pronunciation protects recording and assessment only', () {
    final source = _blankStringsAndComments(
      File('lib/screens/pronunciation_studio_screen.dart').readAsStringSync(),
    );
    final escapes = _constructorInvocations(
      source,
      'SoriHomeEscape',
    ).map(_normalizeWhitespace);

    expect(
      escapes.any(
        (escape) =>
            escape.contains(
              _normalizeWhitespace('confirmWhen: _recording || _assessing,'),
            ) ||
            escape.contains(
              _normalizeWhitespace('confirmWhen: _recording || _assessing)'),
            ),
      ),
      isTrue,
    );
  });
}

Iterable<String> _constructorInvocations(String source, String name) sync* {
  final needle = '$name(';
  var searchFrom = 0;
  while (searchFrom < source.length) {
    final start = source.indexOf(needle, searchFrom);
    if (start < 0) {
      return;
    }
    var depth = 0;
    var cursor = start + name.length;
    for (; cursor < source.length; cursor++) {
      final char = source[cursor];
      if (char == '(') {
        depth++;
      } else if (char == ')') {
        depth--;
        if (depth == 0) {
          yield source.substring(start, cursor + 1);
          cursor++;
          break;
        }
      }
    }
    searchFrom = cursor;
  }
}

String _normalizeWhitespace(String value) =>
    value.replaceAll(RegExp(r'\s+'), ' ').trim();

String _relativePath(File file) {
  final path = file.path.replaceAll('\\', '/');
  return 'lib/screens/${path.split('lib/screens/').last}';
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
      for (var blank = index; blank < cursor; blank++) {
        output[blank] = ' ';
      }
      index = cursor;
      continue;
    }
    index++;
  }
  return output.join();
}
