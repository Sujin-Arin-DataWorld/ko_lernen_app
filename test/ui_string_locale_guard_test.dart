/// UI 문자열 로케일 **래칫** — 2026-08-18 신설.
///
/// 테스터(Amor, 2026-08-17): "EN 인터페이스인데 번역·연상 힌트가 독일어로
/// 나오고, 한국어도 인터페이스에 섞여 있다."
///
/// `docs/SESSION_LOG.md` 를 보면 이 부류의 버그를 최소 8번 수동으로 쓸어냈고
/// 매번 다시 생겼다 (4331·6665·8867·8880·9508·10453·10542·10904행). 사람이
/// 기억으로 막을 수 있는 종류가 아니라서 CI 로 옮긴다.
///
/// **막는 것**: `lib/screens`·`lib/widgets` 의 UI 텍스트 자리에 들어간
/// 한국어·독일어 리터럴. 정당한 이유가 있으면 같은 줄이나 바로 윗줄에
/// `// l10n: exempt — <사유>` 를 단다.
///
/// **한계** (알고도 이렇게 둔다): 독일어 판별은 움라우트·ß 에만 의존한다.
/// "Premium" 처럼 특수문자 없는 독일어는 못 잡는다. 오탐 0 을 우선했다 —
/// 오탐이 나기 시작하면 exempt 가 남발되고 가드가 죽는다.
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// UI 에 그대로 보이는 문자열이 들어가는 자리.
final _uiTextSlot = RegExp(
  r'(\bText\(|\blabel:|\blabelText:|\btitle:|\bhintText:|\btooltip:'
  r'|\bsemanticsLabel:|\bmessage:|\bsubtitle:|\bhelperText:)',
);

/// 작은따옴표 문자열 리터럴.
final _literal = RegExp(r"'([^'\\]*(?:\\.[^'\\]*)*)'");

final _hangul = RegExp(r'[가-힣ㄱ-ㆎ]');
final _germanOnly = RegExp(r'[äöüßÄÖÜ]');

/// 디버그 전용 갤러리 — ko/de/en 3종을 나란히 들고 있는 게 이 화면의 목적이다.
/// `UxPreviewFeatureGate` 로 프로덕션 빌드에서 빠진다.
const _exemptFiles = {'lib/screens/ux_preview_app.dart'};

String _stripComment(String line) {
  final at = line.indexOf('//');
  return at < 0 ? line : line.substring(0, at);
}

void main() {
  test('lib/screens·lib/widgets 의 UI 텍스트에 한국어·독일어 하드코딩 0건', () {
    final offenders = <String>[];
    final exempt = <String>[];

    final files = [
      for (final dir in ['lib/screens', 'lib/widgets'])
        ...Directory(dir)
            .listSync(recursive: true)
            .whereType<File>()
            .where((f) => f.path.endsWith('.dart')),
    ]..sort((a, b) => a.path.compareTo(b.path));

    for (final file in files) {
      final path = file.path.replaceAll(r'\', '/');
      if (_exemptFiles.contains(path)) {
        continue;
      }
      final lines = file.readAsLinesSync();
      for (var i = 0; i < lines.length; i++) {
        final code = _stripComment(lines[i]);
        final slot = _uiTextSlot.firstMatch(code);
        if (slot == null) {
          continue;
        }
        // 자리 표시자 뒤부터 두 줄까지 본다 — 값이 다음 줄로 넘어가는 게 흔하다.
        final window = [
          code.substring(slot.start),
          if (i + 1 < lines.length) _stripComment(lines[i + 1]),
          if (i + 2 < lines.length) _stripComment(lines[i + 2]),
        ].join('\n');

        final flagged = _literal
            .allMatches(window)
            .map((m) => m.group(1)!)
            .where((v) => _hangul.hasMatch(v) || _germanOnly.hasMatch(v))
            .toList();
        if (flagged.isEmpty) {
          continue;
        }

        final prev = i > 0 ? lines[i - 1] : '';
        final where = '$path:${i + 1}';
        if (lines[i].contains('l10n: exempt') ||
            prev.contains('l10n: exempt')) {
          exempt.add(where);
        } else {
          offenders.add('$where  ->  ${flagged.join(" | ")}');
        }
      }
    }

    expect(
      offenders,
      isEmpty,
      reason:
          'UI 텍스트는 AppL10n.of(context).xxx 를 쓴다 (AGENTS.md §규칙). '
          '정당한 사유가 있으면 "// l10n: exempt — <사유>" 를 달 것.\n'
          '${offenders.join("\n")}',
    );

    // exempt 남발 방지 — 늘려야 하면 사유를 코드와 이 상한에 함께 남길 것.
    expect(
      exempt.length,
      lessThanOrEqualTo(4),
      reason: '현재 exempt: ${exempt.join(", ")}',
    );
  });
}
