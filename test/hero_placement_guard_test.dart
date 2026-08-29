import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// §15/§18 — HanokHeader는 "고르는" 화면 전용이다. `SoriStudyFrame`(플레이
/// 화면) 위에 얹힌 HanokHeader는 §15 "플레이 화면 히어로 0dp"를 어긴다.
///
/// §19 W5 이행으로 플레이 화면의 유예 목록은 비었다. 새 예외는 허용하지
/// 않는다.
void main() {
  const knownViolators = <String>{};

  const chooserScreens = {
    'lib/screens/bookshelf_screen.dart',
    'lib/screens/character_selection_screen.dart',
    'lib/screens/learning_path_screen.dart',
    'lib/screens/quests_screen.dart',
    'lib/screens/scenarios_list_screen.dart',
    'lib/screens/settings_screen.dart',
    'lib/screens/vocab_packs_screen.dart',
  };

  test('HanokHeader( 는 고르는 화면이거나 §19 이행 대기 목록 안에서만 쓰인다', () {
    final offenders = <String>[];
    for (final f
        in Directory('lib/screens')
            .listSync(recursive: true)
            .whereType<File>()
            .where((f) => f.path.endsWith('.dart'))) {
      final content = f.readAsStringSync();
      if (!content.contains('HanokHeader(')) continue;
      final rel = f.path.replaceAll('\\', '/');
      final short = 'lib/screens/${rel.split('lib/screens/').last}';
      if (!chooserScreens.contains(short) && !knownViolators.contains(short)) {
        offenders.add(short);
      }
    }
    expect(
      offenders,
      isEmpty,
      reason:
          '새 화면이 HanokHeader( 를 썼다 — §15 "플레이 화면 히어로 0dp". '
          '고르는 화면이면 chooserScreens에 추가, 학습 화면이면 히어로를 빼고 '
          'SoriChromeRow/SoriLevelFilterBar로 대체할 것.\n'
          '${offenders.join('\n')}',
    );
  });

  test('§19 이행 대기 목록은 비어 있다', () {
    expect(knownViolators, isEmpty);
  });
}
