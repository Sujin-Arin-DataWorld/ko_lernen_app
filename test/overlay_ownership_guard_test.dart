import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('app overlays are owned by the Sori entry points', () {
    final rules = <String, ({RegExp pattern, String owner})>{
      'showDialog': (
        pattern: RegExp(r'\bshowDialog\s*(?:<[^>]+>)?\s*\('),
        owner: 'lib/widgets/sori/dialog.dart',
      ),
      'showGeneralDialog': (
        pattern: RegExp(r'\bshowGeneralDialog\s*(?:<[^>]+>)?\s*\('),
        owner: 'lib/widgets/sori/dialog.dart',
      ),
      'showModalBottomSheet': (
        pattern: RegExp(r'\bshowModalBottomSheet\s*(?:<[^>]+>)?\s*\('),
        owner: 'lib/widgets/sori/sheet.dart',
      ),
      'showSnackBar': (
        pattern: RegExp(r'\bshowSnackBar\s*\('),
        owner: 'lib/widgets/sori/toast.dart',
      ),
      'SnackBar': (
        pattern: RegExp(r'\bSnackBar\s*\('),
        owner: 'lib/widgets/sori/toast.dart',
      ),
    };
    final violations = <String>[];

    for (final entity in Directory('lib').listSync(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.dart')) continue;
      final path = entity.path.replaceAll('\\', '/');
      final source = _withoutComments(entity.readAsStringSync());
      for (final rule in rules.entries) {
        if (path != rule.value.owner && rule.value.pattern.hasMatch(source)) {
          violations.add('$path uses raw ${rule.key}');
        }
      }
    }

    expect(
      violations,
      isEmpty,
      reason:
          'Use showSoriDialog, showSoriSheet, soriToast, soriNotice, or '
          'showSoriActionNotice:\n${violations.join('\n')}',
    );
  });
}

String _withoutComments(String source) {
  final withoutBlocks = source.replaceAll(
    RegExp(r'/\*.*?\*/', dotAll: true),
    '',
  );
  return withoutBlocks.replaceAll(RegExp(r'//.*$', multiLine: true), '');
}
