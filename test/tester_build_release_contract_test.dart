import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'closed-testing and production runbooks keep release defines explicit',
    () async {
      final betaGuide = await File('BETA_INSTALL_GUIDE.md').readAsString();
      final checklist = await File(
        'docs/store/closed-testing-checklist-v2.md',
      ).readAsString();
      final releaseNotes = await File(
        'docs/store/release-notes-v2.md',
      ).readAsString();
      final sessionNotes = await File(
        'docs/SESSION_CHANGES_2026-07-31.md',
      ).readAsString();
      final subscriptionRunbook = await File(
        'docs/store/subscription-setup-runbook.md',
      ).readAsString();
      final closedWorkflow = await File(
        '.github/workflows/play_closed.yml',
      ).readAsString();
      final normalizedChecklist = checklist.replaceAll(RegExp(r'\s+'), ' ');

      final testerGuideAab = _fencedBuildBlockAfter(
        betaGuide,
        'Release owner only: Closed-testing AAB',
      );
      final testerAab = _fencedBuildBlockAfter(
        checklist,
        '2.4 Closed-testing AAB',
      );
      final testerAabSection = _sectionAfterHeading(
        checklist,
        '2.4 Closed-testing AAB',
      );
      final sessionTesterAab = _fencedBuildBlockAfter(
        sessionNotes,
        'Internal closed-testing AAB (feedback enabled)',
      );
      final sessionTesterAabSection = _sectionAfterHeading(
        sessionNotes,
        'Internal closed-testing AAB (feedback enabled)',
      );
      final subscriptionProductionAab = _fencedBuildBlockAfter(
        subscriptionRunbook,
        'Production subscription AAB (feedback disabled)',
      );

      for (final command in [testerGuideAab, testerAab]) {
        expect(command, contains('--dart-define=ENABLE_TESTER_FEEDBACK=true'));
        expect(command, isNot(contains('BETA_UNLOCK_ALL')));
        expect(command, isNot(contains('/Users/')));
      }
      expect(
        sessionTesterAab,
        contains('--dart-define=ENABLE_TESTER_FEEDBACK=true'),
      );
      expect(sessionTesterAab, contains('--dart-define=BETA_UNLOCK_ALL=true'));
      expect(sessionTesterAab, isNot(contains('/Users/')));
      for (final command in [testerGuideAab, testerAab]) {
        expect(command, contains(r'--dart-define=GIT_COMMIT="$release_sha"'));
      }
      expect(
        closedWorkflow,
        contains('--dart-define=ENABLE_TESTER_FEEDBACK=true'),
      );
      expect(closedWorkflow, isNot(contains('BETA_UNLOCK_ALL')));
      expect(
        closedWorkflow,
        contains(r'--dart-define=GIT_COMMIT=${{ github.sha }}'),
      );
      expect(closedWorkflow, contains('tracks: alpha'));
      expect(
        subscriptionProductionAab,
        contains('--dart-define=BETA_UNLOCK_ALL=false'),
      );
      expect(
        subscriptionProductionAab,
        contains(r'--dart-define=RC_ANDROID_KEY=$env:RC_ANDROID_KEY'),
      );
      expect(
        subscriptionProductionAab,
        contains(r'IsNullOrWhiteSpace($env:RC_ANDROID_KEY)'),
      );
      expect(
        subscriptionProductionAab,
        isNot(contains('ENABLE_TESTER_FEEDBACK')),
      );
      expect(
        subscriptionProductionAab,
        isNot(contains('goog_xxxxxxxxxxxxxxxx')),
      );
      expect(subscriptionProductionAab, isNot(contains('/Users/')));

      expect(normalizedChecklist, contains('12명 이상 연속 opt-in, 14일'));
      expect(checklist, contains('git rev-list --count HEAD'));
      expect(checklist, contains('git diff --exit-code'));
      expect(checklist, contains(r'test -z "$(git status --porcelain)"'));
      expect(
        checklist,
        contains(
          'BETA_UNLOCK_ALL=true는 **내부 테스트 전용** premium entitlement override다.',
        ),
      );
      expect(checklist, contains('Closed Testing 후보에는 주입하지 않는다.'));
      expect(checklist, contains('SoriContentFeed wrapper'));
      expect(checklist, contains('App Check 보호 경로를 거쳐 accepted/delivered 상태'));
      expect(
        normalizedChecklist,
        contains('12명 이상이 14일 연속 opt-in하고 실제 핵심 흐름을'),
      );
      expect(checklist, contains('완료해야 한다.'));
      expect(testerAabSection, isNot(contains('1.0.1+2')));
      expect(sessionNotes, contains('highest build number already uploaded'));
      expect(sessionTesterAabSection, isNot(contains('2.0.1+5')));
      expect(betaGuide, contains('Google Play'));
      expect(betaGuide, contains('Closed Testing'));
      expect(betaGuide, isNot(contains('Windows PC')));
      expect(betaGuide, isNot(contains('Play Protect 경고가 뜰 수 있음')));
      expect(
        releaseNotes,
        contains('Nächster Android Closed-Testing-Kandidat'),
      );
      expect(releaseNotes, contains('Du kannst Wörter freiwillig eintippen.'));
      expect(
        releaseNotes,
        contains(
          'The typing exercise is optional and does not block progress.',
        ),
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
  final headingMatch = RegExp(
    r'^#{1,6}\s+' + RegExp.escape(heading) + r'\s*#*\s*$',
    multiLine: true,
  ).firstMatch(source);
  if (headingMatch == null) return '';
  final firstNewline = source.indexOf('\n', headingMatch.end);
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
    } else if (!insideFence && RegExp(r'^#{1,6} ').hasMatch(line)) {
      sectionEnd = lineStart;
      break;
    }
    lineStart = lineEnd + 1;
  }
  return source.substring(firstNewline + 1, sectionEnd);
}
