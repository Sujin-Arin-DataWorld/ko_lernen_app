import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('every shipped scenario has playable Korean dialogue data', () {
    final files =
        Directory('assets/data')
            .listSync()
            .whereType<File>()
            .where(
              (file) =>
                  RegExp(r'scenarios_[a-z0-9]+\.json$').hasMatch(file.path),
            )
            .toList()
          ..sort((a, b) => a.path.compareTo(b.path));
    final problems = <String>[];
    final speakerIds = <String>{};
    var scenarioCount = 0;
    var longestKoreanLine = 0;

    for (final file in files) {
      final root = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
      final scenarios = root['scenarios'] as List<dynamic>? ?? const [];
      for (final raw in scenarios.cast<Map<String, dynamic>>()) {
        scenarioCount++;
        final id = (raw['id'] as String?)?.trim() ?? '';
        final dialog = raw['dialog'] as List<dynamic>? ?? const [];
        if (id.isEmpty || dialog.isEmpty) {
          problems.add('${file.path}:$id has no dialogue');
          continue;
        }
        for (final item in dialog.cast<Map<String, dynamic>>()) {
          final speaker = (item['speaker'] as String?)?.trim() ?? '';
          final korean = (item['ko'] as String?)?.trim() ?? '';
          if (speaker.isEmpty || korean.isEmpty) {
            problems.add(
              '${file.path}:$id has an empty speaker or Korean line',
            );
          }
          speakerIds.add(speaker);
          if (korean.length > longestKoreanLine) {
            longestKoreanLine = korean.length;
          }
        }
      }
    }

    expect(files, hasLength(6));
    expect(scenarioCount, 126);
    expect(problems, isEmpty, reason: problems.take(20).join('\n'));
    expect(longestKoreanLine, greaterThanOrEqualTo(60));
    expect(
      speakerIds.difference({'user', 'jieun', 'minsu', 'narrator'}),
      isNotEmpty,
      reason: 'Generic neutral speaker icons must keep supporting catalog IDs.',
    );
  });
}
