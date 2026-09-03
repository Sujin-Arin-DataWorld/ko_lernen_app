import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// §B2(2026-09-03) — [lib/widgets/sori/study_frame.dart]'s `SoriStudyFrame`
/// owns the sole close (X, leading) and home (trailing) actions; it no
/// longer accepts a custom `leading` widget. This guard pins the 27-screen
/// inventory, the confirm-before-leaving contract each active screen wires
/// through `SoriHomeEscape`, and that the pre-§B2 per-screen close-button
/// builders (`leading: IconButton(...)`, `Icons.arrow_back_ios_new`,
/// `_buildCloseButton`) are fully gone.
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
    'lib/screens/hangul_screen.dart',
    'lib/screens/hard_choice_quiz_screen.dart',
    'lib/screens/kkeunmari_screen.dart',
    'lib/screens/legacy_vocab_screen.dart',
    'lib/screens/listening_play_screen.dart',
    'lib/screens/pronunciation_studio_screen.dart',
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
    'lib/screens/pronunciation_studio_screen.dart':
        '_captureBusy || _assessing',
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
  const staticImmediateEscapeScreens = <String>{
    'lib/screens/custom_pack_play_screen.dart',
    'lib/screens/grammar_screen.dart',
    'lib/screens/hangul_screen.dart',
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
    expect(expectedStudyFrameScreens, hasLength(27));
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

  test('active and static home-escape decisions cover all 27 screens', () {
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

  test(
    // §B2: SoriStudyFrame deleted its `leading` parameter — the close (X)
    // slot is exclusively frame-owned (SoriCloseAction), same as home. No
    // SoriStudyFrame( invocation may pass one anymore (the compiler already
    // rejects it; this is a static belt-and-suspenders check that survives
    // even if the parameter is ever reintroduced by mistake).
    'no StudyFrame invocation passes a custom leading',
    () {
      final offenders = <String>[];
      for (final path in expectedStudyFrameScreens) {
        final source = _blankStringsAndComments(
          File(path).readAsStringSync(),
        );
        final hasLeadingArg = _constructorInvocations(source, 'SoriStudyFrame')
            .any((invocation) => RegExp(r'\bleading\s*:').hasMatch(invocation));
        if (hasLeadingArg) {
          offenders.add(path);
        }
      }

      expect(
        offenders,
        isEmpty,
        reason:
            'SoriStudyFrame no longer has a leading parameter — the frame '
            'always renders SoriCloseAction.\n${offenders.join('\n')}',
      );
    },
  );

  test(
    'the pre-§B2 per-screen close-button builders are fully gone',
    () {
      // `Icons.arrow_back_ios_new` was the 2-screen minority of the old
      // custom-leading inventory (chosung_quiz_screen.dart,
      // silben_kreuz_screen.dart); `_buildCloseButton` was the ad-hoc
      // builder name several screens used for the `Icons.close` majority
      // and for scenario_player_screen.dart's raw-Scaffold exit button
      // (renamed `_scenarioExitButton` — the one screen that still needs a
      // bespoke close widget, since it must route through
      // `ScenarioPlayerScreen.onExit` instead of a bare pop when embedded
      // by the onboarding journey).
      final dartFiles = Directory('lib')
          .listSync(recursive: true)
          .whereType<File>()
          .where((file) => file.path.endsWith('.dart'));

      final arrowBackOffenders = <String>[];
      final buildCloseButtonOffenders = <String>[];
      for (final file in dartFiles) {
        final source = file.readAsStringSync();
        if (source.contains('Icons.arrow_back_ios_new')) {
          arrowBackOffenders.add(_relativeLibPath(file));
        }
        if (source.contains('_buildCloseButton')) {
          buildCloseButtonOffenders.add(_relativeLibPath(file));
        }
      }

      expect(
        arrowBackOffenders,
        isEmpty,
        reason: 'Icons.arrow_back_ios_new should be fully retired by §B2.',
      );
      expect(
        buildCloseButtonOffenders,
        isEmpty,
        reason: '_buildCloseButton should be fully retired by §B2.',
      );
    },
  );

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

  test('pronunciation protects all capture transitions and assessment', () {
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
              _normalizeWhitespace('confirmWhen: _captureBusy || _assessing,'),
            ) ||
            escape.contains(
              _normalizeWhitespace('confirmWhen: _captureBusy || _assessing)'),
            ),
      ),
      isTrue,
    );
    // Keep the helper's full safety contract explicit: preparation and PCM
    // finalization still own audio resources even when _recording is false.
    expect(
      _normalizeWhitespace(source),
      contains(
        _normalizeWhitespace(
          'bool get _captureBusy => '
          '_preparingRecording || _recording || _finishingRecording;',
        ),
      ),
    );
  });

  test(
    'no screen in the inventory builds a raw Scaffold with SoriAppBar',
    () {
      // §NAV-1(J2): SoriStudyFrame owns appbar/close/home for every study
      // screen. A raw `Scaffold(appBar: SoriAppBar(...))` bypasses that
      // frame and its confirm-before-leaving contract — the one exception
      // is scenario_player_screen.dart, whose embedded-onboarding exit path
      // (`ScenarioPlayerMode.onboardingFirstScene`) still needs a bespoke
      // Scaffold (see the close-button comment above).
      const allowlist = <String>{'lib/screens/scenario_player_screen.dart'};
      final offenders = <String>[];
      for (final path in expectedStudyFrameScreens) {
        if (allowlist.contains(path)) {
          continue;
        }
        final source = _blankStringsAndComments(File(path).readAsStringSync());
        final rawScaffoldWithAppBar = _constructorInvocations(
          source,
          'Scaffold',
        ).any((invocation) => invocation.contains('appBar: SoriAppBar('));
        if (rawScaffoldWithAppBar) {
          offenders.add(path);
        }
      }

      expect(
        offenders,
        isEmpty,
        reason:
            'SoriStudyFrame owns appBar/close/home for study screens — use '
            'it instead of a raw Scaffold(appBar: SoriAppBar(...)).\n'
            '${offenders.join('\n')}',
      );
    },
  );
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

String _relativeLibPath(File file) {
  final path = file.path.replaceAll('\\', '/');
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
