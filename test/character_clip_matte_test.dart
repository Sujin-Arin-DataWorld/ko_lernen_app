import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:ko_lernen_app/widgets/sori/hanok_header.dart';

/// Guards every bundled character MP4 against a non-white matte, because
/// CharacterClipPlayer uses BlendMode.multiply to absorb a white background.
void main() {
  final clipDir = Directory('assets/video/character');
  final loopDir = Directory('assets/video/loops');
  final reportFile = File('tool/clip_matte_report.json');

  late Map<String, Map<String, dynamic>> byName;

  List<File> clips() => clipDir
      .listSync()
      .whereType<File>()
      .where((file) => file.path.endsWith('.mp4'))
      .toList()
    ..sort((a, b) => a.path.compareTo(b.path));

  setUpAll(() {
    expect(reportFile.existsSync(), isTrue,
        reason: 'Run `python tool/check_clip_matte.py` first.');
    final report =
        json.decode(reportFile.readAsStringSync()) as Map<String, dynamic>;
    byName = {
      for (final entry in (report['clips'] as List).cast<Map<String, dynamic>>())
        entry['path'] as String: entry,
    };
  });

  test('report covers exactly every bundled character clip', () {
    expect(clipDir.existsSync(), isTrue);
    final onDisk = clips().map((file) => file.uri.pathSegments.last).toSet();
    final inReport = byName.keys.toSet();
    expect(onDisk.difference(inReport), isEmpty,
        reason: 'Run `python tool/check_clip_matte.py` to add new clips.');
    expect(inReport.difference(onDisk), isEmpty,
        reason: 'Run `python tool/check_clip_matte.py` to remove stale clips.');
  });

  test('report byte sizes match bundled character clips', () {
    final drifted = <String>[];
    for (final file in clips()) {
      final name = file.uri.pathSegments.last;
      final entry = byName[name];
      if (entry != null && entry['bytes'] != file.lengthSync()) {
        drifted.add(name);
      }
    }
    expect(drifted, isEmpty,
        reason: 'Run `python tool/check_clip_matte.py` after replacing clips.');
  });

  test('every bundled character clip has a white multiply-safe matte', () {
    final bad = <String>[];
    for (final entry in byName.values) {
      if (entry['ok'] != true) {
        bad.add('${entry['path']}: ${entry['matte']} -- ${entry['reason']}');
      }
    }
    expect(bad, isEmpty,
        reason: 'Non-white mattes remain visible through BlendMode.multiply.');
  });

  /// 모서리 검사(위 테스트)를 통과해도 **화면 안쪽**에 구워진 접지 그림자는
  /// 그대로 남는다. 조이(까치) 클립 전량이 그 상태로 몇 달을 통과했고, 캐릭터
  /// 선택 화면에서 회색 얼룩으로 보였다(Jin 2026-08-25). 08-17 수정은
  /// `assets/video/home_hero/*_hanji.mp4` 두 개만 다시 구웠기 때문에, 나머지
  /// 화면에서는 증상이 **한 번도 사라진 적이 없다** — 되돌아온 게 아니다.
  ///
  /// multiply 는 **순백만** 배경색에 정확히 얹으므로 런타임으로는 못 지운다.
  /// 픽셀을 고쳐야 한다: `python tool/whiten_clip_matte.py --clip <파일>`.
  /// 임계는 **클립마다** 다르다. 절대 임계 하나로는 못 가른다 — 실측상 처리본
  /// 최댓값(20.0%)과 미처리 클립(21.0%)이 겹친다. `check_clip_matte.py` 의
  /// `FLOOR_GREY_BUDGET` 이 클립별로 "검수해서 통과시킨 값"을 들고 있고, 예산을
  /// 올리려면 그 파일을 고쳐야 한다 — 그 수정이 리뷰에 남는 게 잠금이다.
  test('no character clip carries a baked floor shadow', () {
    final report =
        json.decode(reportFile.readAsStringSync()) as Map<String, dynamic>;
    final tolerance = (report['floor_grey_tolerance'] as num).toDouble();
    final offenders = <String>[];
    for (final entry in byName.values) {
      final grey = (entry['floor_grey'] as num?)?.toDouble();
      final budget = (entry['floor_grey_budget'] as num?)?.toDouble();
      expect(grey, isNotNull,
          reason: '${entry['path']}: floor_grey 없음 — '
              'python tool/check_clip_matte.py 로 리포트를 다시 만드세요.');
      expect(budget, isNotNull,
          reason: '${entry['path']}: floor_grey_budget 없음 — '
              'python tool/check_clip_matte.py 로 리포트를 다시 만드세요.');
      if (grey! > budget! + tolerance) {
        offenders.add('${entry['path']}: '
            '${(grey * 100).toStringAsFixed(1)}% > 예산 '
            '${(budget * 100).toStringAsFixed(1)}% + 여유 '
            '${(tolerance * 100).toStringAsFixed(0)}%');
      }
    }
    expect(offenders, isEmpty,
        reason: '구워진 바닥 그림자가 multiply 를 통과해 회색 얼룩으로 보입니다:\n'
            '${offenders.join('\n')}');
  });

  test('CharacterClips ↔ 번들 클립이 양방향으로 일치한다', () {
    final source =
        File('lib/widgets/sori/character_clip.dart').readAsStringSync();
    final references = RegExp(r"\$_base/([a-zA-Z0-9_.-]+\.mp4)")
        .allMatches(source)
        .map((match) => match.group(1)!)
        .toSet();
    expect(references, isNotEmpty);
    final onDisk = clips().map((file) => file.uri.pathSegments.last).toSet();

    // 참조 → 디스크: 상수가 없는 파일을 가리키면 재생이 통째로 실패한다.
    expect(
      references.difference(onDisk),
      isEmpty,
      reason: 'CharacterClips 가 번들에 없는 파일을 가리킵니다',
    );

    // 디스크 → 참조 (2026-08-07 신설). 이 방향이 없어서 `tiger_magpie_play.mp4`
    // 1.1MB 가 아무 화면도 재생하지 않은 채 AAB 에 실려 나갔다. `video/loops` 가
    // 유일하게 고아 0 인 것은 우연이 아니라 아래 루프 테스트가 처음부터 양방향
    // 이었기 때문이다 — 같은 형태로 맞춘다.
    expect(
      onDisk.difference(references),
      isEmpty,
      reason: '이 클립들은 번들에 들어가는데 CharacterClips 가 안 부릅니다 — '
          '상수를 추가하거나 assets_unused/pending_review/ 로 격리하세요',
    );
  });

  test('HanokHeader loop manifest matches bundled loop clips', () {
    expect(loopDir.existsSync(), isTrue);
    final onDisk = loopDir
        .listSync()
        .whereType<File>()
        .where((file) => file.path.endsWith('.mp4'))
        .map((file) => file.uri.pathSegments.last.replaceAll('.mp4', ''))
        .toSet();
    expect(HanokHeader.kLoopAssets.difference(onDisk), isEmpty);
    expect(onDisk.difference(HanokHeader.kLoopAssets), isEmpty);
  });
}
