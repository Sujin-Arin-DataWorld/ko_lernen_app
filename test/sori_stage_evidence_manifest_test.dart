import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// §LAYOUT-4(J14) — `docs/screenshots/` is UI-root visual evidence, not a
/// CI comparison gate (see `test/sori_stage_visual_evidence_test.dart` and
/// AGENTS.md's "UI 루트 증거" bullet). This is a lightweight directory scan,
/// not a golden-file diff: it only confirms each captured root still has at
/// least one non-empty PNG on disk with the
/// `sori-{stage|shell}-<root>-<width>[-<state>].png` naming convention, so a
/// careless rename/delete can't silently drop a root's evidence from the
/// repository.
///
/// All five current roots have DE/EN captures. Receipt states remain attached
/// to their owning Today root through the same suffix convention.
void main() {
  test(
    'every captured UI root has at least one non-empty evidence PNG on disk',
    () {
      final directory = Directory('docs/screenshots');
      expect(
        directory.existsSync(),
        isTrue,
        reason: '${directory.path} is missing.',
      );

      final files = directory
          .listSync()
          .whereType<File>()
          .where((f) => f.path.toLowerCase().endsWith('.png'))
          .toList();

      const roots = ['today', 'learn', 'games', 'hanok', 'gye'];
      const requiredRoots = roots;
      final namePattern = RegExp(
        r'^sori-(?:stage|shell)-(today|learn|games|hanok|gye)-\d+(?:-[a-z0-9]+)*\.png$',
      );

      final byRoot = <String, List<File>>{for (final root in roots) root: []};
      final malformed = <String>[];

      for (final file in files) {
        final name = file.uri.pathSegments.last;
        final match = namePattern.firstMatch(name);
        if (match == null) {
          malformed.add(name);
          continue;
        }
        byRoot[match.group(1)!]!.add(file);
      }

      expect(
        malformed,
        isEmpty,
        reason:
            "These docs/screenshots/*.png files don't follow the "
            '`sori-{stage|shell}-<root>-<width>[-<state>].png` naming convention: '
            '${malformed.join(', ')}',
      );

      final missingRoots = <String>[];
      final emptyFiles = <String>[];
      for (final root in requiredRoots) {
        final rootFiles = byRoot[root]!;
        if (rootFiles.isEmpty) {
          missingRoots.add(root);
          continue;
        }
        for (final file in rootFiles) {
          if (file.lengthSync() == 0) {
            emptyFiles.add(file.path);
          }
        }
      }
      expect(
        missingRoots,
        isEmpty,
        reason:
            'These UI roots have no docs/screenshots/*.png evidence: '
            '${missingRoots.join(', ')}',
      );
      expect(
        emptyFiles,
        isEmpty,
        reason: 'These evidence PNGs are 0 bytes: ${emptyFiles.join(', ')}',
      );
    },
  );
}
