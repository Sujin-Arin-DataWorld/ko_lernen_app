import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  const inlineScreens = <String>{'lib/screens/vocab_packs_screen.dart'};
  const sheetScreens = <String>{
    'lib/screens/chosung_quiz_screen.dart',
    'lib/screens/cloze_game_screen.dart',
    'lib/screens/grammar_screen.dart',
    'lib/screens/legacy_vocab_screen.dart',
    'lib/screens/satz_arcade_screen.dart',
    'lib/screens/silben_kreuz_screen.dart',
    'lib/screens/speed_match_screen.dart',
  };

  const forbidden = <String, List<String>>{
    'lib/screens/vocab_packs_screen.dart': ['PopupMenuButton<String>'],
    'lib/screens/chosung_quiz_screen.dart': ["Key('chosung-level-"],
    'lib/screens/cloze_game_screen.dart': [
      'Widget _levelBar(',
      'Widget _levelChip(',
    ],
    'lib/screens/grammar_screen.dart': ['_dropdown(ctx, t.filterLevel'],
    'lib/screens/legacy_vocab_screen.dart': [
      '_dropdown(AppL10n.of(ctx).filterLevel',
    ],
    'lib/screens/satz_arcade_screen.dart': [
      'Widget _levelBar(',
      'Widget _levelChip(',
    ],
    'lib/screens/silben_kreuz_screen.dart': ['Widget _levelPicker('],
    'lib/screens/speed_match_screen.dart': [
      'Widget _levelBar(',
      'Widget _levelChip(',
    ],
  };

  test(
    'all remaining level selectors use the shared inline or sheet contract',
    () {
      final offenders = <String>[];
      for (final path in inlineScreens) {
        final source = File(path).readAsStringSync();
        if (!source.contains('SoriLevelFilterBar(')) {
          offenders.add('$path: missing SoriLevelFilterBar');
        }
      }
      for (final path in sheetScreens) {
        final source = File(path).readAsStringSync();
        if (!source.contains('SoriChromeRow(')) {
          offenders.add('$path: missing SoriChromeRow');
        }
        if (!source.contains('showSoriLevelFilterSheet(')) {
          offenders.add('$path: missing showSoriLevelFilterSheet');
        }
      }
      for (final entry in forbidden.entries) {
        final source = File(entry.key).readAsStringSync();
        for (final legacy in entry.value) {
          if (source.contains(legacy)) {
            offenders.add('${entry.key}: legacy selector remains: $legacy');
          }
        }
      }

      expect(
        offenders,
        isEmpty,
        reason:
            'Level selector debt is closed with an empty allowlist. Use the '
            'shared inline bar for browse surfaces and the shared sheet from a '
            'single chrome row for play surfaces.\n${offenders.join('\n')}',
      );
    },
  );
}
