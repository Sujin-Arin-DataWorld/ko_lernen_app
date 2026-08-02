import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'tester and production build runbooks keep feedback defines explicit',
    () async {
      final betaGuide = await File('BETA_INSTALL_GUIDE.md').readAsString();
      final checklist = await File(
        'docs/store/closed-testing-checklist-v2.md',
      ).readAsString();
      final sessionNotes = await File(
        'docs/SESSION_CHANGES_2026-07-31.md',
      ).readAsString();
      final subscriptionRunbook = await File(
        'docs/store/subscription-setup-runbook.md',
      ).readAsString();

      final testerApk = _fencedBuildBlockAfter(
        betaGuide,
        'Internal tester APK',
      );
      final testerAab = _fencedBuildBlockAfter(
        checklist,
        'Internal closed-testing AAB',
      );
      final testerAabSection = _sectionAfterHeading(
        checklist,
        'Internal closed-testing AAB',
      );
      final sessionTesterAab = _fencedBuildBlockAfter(
        sessionNotes,
        'Internal closed-testing AAB',
      );
      final sessionTesterAabSection = _sectionAfterHeading(
        sessionNotes,
        'Internal closed-testing AAB',
      );
      final productionAab = _fencedBuildBlockAfter(checklist, 'Production AAB');
      final subscriptionProductionAab = _fencedBuildBlockAfter(
        subscriptionRunbook,
        'Production subscription AAB',
      );

      for (final command in [testerApk, testerAab, sessionTesterAab]) {
        expect(command, contains('--dart-define=ENABLE_TESTER_FEEDBACK=true'));
        expect(command, contains('--dart-define=BETA_UNLOCK_ALL=true'));
        expect(command, isNot(contains('/Users/')));
        expect(command, isNot(contains('\\\n')));
      }
      for (final command in [productionAab, subscriptionProductionAab]) {
        expect(command, contains('--dart-define=BETA_UNLOCK_ALL=false'));
        expect(
          command,
          contains(r'--dart-define=RC_ANDROID_KEY=$env:RC_ANDROID_KEY'),
        );
        expect(command, contains(r'IsNullOrWhiteSpace($env:RC_ANDROID_KEY)'));
        expect(command, isNot(contains('ENABLE_TESTER_FEEDBACK')));
        expect(command, isNot(contains('goog_xxxxxxxxxxxxxxxx')));
        expect(command, isNot(contains('/Users/')));
        expect(command, isNot(contains('\\\n')));
      }
      expect(checklist, contains('highest build number already uploaded'));
      expect(testerAabSection, isNot(contains('1.0.1+2')));
      expect(sessionNotes, contains('highest build number already uploaded'));
      expect(sessionTesterAabSection, isNot(contains('2.0.1+5')));
      expect(betaGuide, contains('Windows PC'));
      expect(betaGuide, isNot(contains('Mac 연결')));
      expect(
        checklist,
        contains('Get-Item build/app/outputs/bundle/release/app-release.aab'),
      );
    },
  );
}

String _fencedBuildBlockAfter(String source, String heading) {
  final section = _sectionAfterHeading(source, heading);
  var searchStart = 0;
  while (true) {
    final openingFence = section.indexOf('```', searchStart);
    if (openingFence < 0) return '';
    final contentStart = section.indexOf('\n', openingFence);
    if (contentStart < 0) return '';
    final closingFence = section.indexOf('```', contentStart + 1);
    if (closingFence < 0) return '';
    final content = section.substring(contentStart + 1, closingFence);
    if (content.contains('flutter build ')) return content;
    searchStart = closingFence + 3;
  }
}

String _sectionAfterHeading(String source, String heading) {
  final headingStart = source.indexOf(heading);
  if (headingStart < 0) return '';
  final firstNewline = source.indexOf('\n', headingStart);
  if (firstNewline < 0) return '';
  var sectionEnd = source.length;
  var lineStart = firstNewline + 1;
  var insideFence = false;
  while (lineStart < source.length) {
    final nextNewline = source.indexOf('\n', lineStart);
    final lineEnd = nextNewline < 0 ? source.length : nextNewline;
    final line = source.substring(lineStart, lineEnd).trim();
    if (line.startsWith('```')) {
      insideFence = !insideFence;
    } else if (!insideFence && RegExp(r'^#{1,3} ').hasMatch(line)) {
      sectionEnd = lineStart;
      break;
    }
    lineStart = lineEnd + 1;
  }
  return source.substring(firstNewline + 1, sectionEnd);
}
