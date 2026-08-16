import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:ko_lernen_app/models/learner_level.dart';

void main() {
  test('canonical CEFR parser accepts case and surrounding whitespace', () {
    expect(LearnerLevel.fromCode(' a1 '), LearnerLevel.a1);
    expect(LearnerLevel.fromCode('C2'), LearnerLevel.c2);
    expect(LearnerLevel.fromCode(null), isNull);
    expect(LearnerLevel.fromCode(''), isNull);
    expect(LearnerLevel.fromCode('c3'), isNull);
  });

  test('canonical CEFR codes expose stable persistence, display, and rank', () {
    expect(LearnerLevel.values.map((level) => level.code), [
      'a1',
      'a2',
      'b1',
      'b2',
      'c1',
      'c2',
    ]);
    expect(LearnerLevel.values.map((level) => level.display), [
      'A1',
      'A2',
      'B1',
      'B2',
      'C1',
      'C2',
    ]);
    expect(LearnerLevel.values.map((level) => level.rank), [0, 1, 2, 3, 4, 5]);
  });

  test('new runtime files cannot introduce another six-level authority', () {
    const auditedLowercaseLegacy = {
      'lib/screens/cloze_game_screen.dart',
      'lib/screens/placement_diagnostic_screen.dart',
      'lib/screens/satz_arcade_screen.dart',
      'lib/screens/smalltalk_screen.dart',
      'lib/screens/speed_match_screen.dart',
    };
    const auditedUppercaseLegacy = {
      'lib/models/content_feedback.dart',
      'lib/screens/review_session_screen.dart',
      'lib/screens/smalltalk_screen.dart',
      'lib/services/book_analysis_service.dart',
    };
    final lowercaseAuthorities = <String>{};
    final uppercaseAuthorities = <String>{};
    for (final entry in Directory('lib').listSync(recursive: true)) {
      if (entry is! File || !entry.path.endsWith('.dart')) {
        continue;
      }
      final path = entry.path.replaceAll('\\', '/');
      final source = entry.readAsStringSync();
      if (_containsEveryLiteral(source, const [
        "'a1'",
        "'a2'",
        "'b1'",
        "'b2'",
        "'c1'",
        "'c2'",
      ])) {
        lowercaseAuthorities.add(path);
      }
      if (_containsEveryLiteral(source, const [
        "'A1'",
        "'A2'",
        "'B1'",
        "'B2'",
        "'C1'",
        "'C2'",
      ])) {
        uppercaseAuthorities.add(path);
      }
    }

    expect(lowercaseAuthorities, auditedLowercaseLegacy);
    expect(uppercaseAuthorities, auditedUppercaseLegacy);
  });
}

bool _containsEveryLiteral(String source, List<String> literals) =>
    literals.every(source.contains);
