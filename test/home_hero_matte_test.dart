import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ko_lernen_app/widgets/sori/character_clip.dart';
import 'package:ko_lernen_app/widgets/sori/tokens.dart';

void main() {
  final clipDir = Directory('assets/video/home_hero');
  final reportFile = File('tool/home_hero_matte_report.json');

  late Map<String, Map<String, dynamic>> byName;

  List<File> clips() =>
      clipDir
          .listSync()
          .whereType<File>()
          .where((file) => file.path.endsWith('.mp4'))
          .toList()
        ..sort((a, b) => a.path.compareTo(b.path));

  setUpAll(() {
    expect(
      reportFile.existsSync(),
      isTrue,
      reason: 'Run `python tool/check_home_hero_matte.py` first.',
    );
    final report =
        json.decode(reportFile.readAsStringSync()) as Map<String, dynamic>;
    expect(report['target'], '#FAF6EC');
    expect(report['tolerance'], 2);
    expect(SoriColors.lightBg, const Color(0xFFFAF6EC));
    byName = {
      for (final entry
          in (report['clips'] as List).cast<Map<String, dynamic>>())
        entry['path'] as String: entry,
    };
  });

  test('HomeHeroClips.matte 가 클립의 실측 매트와 같다', () {
    // 홈 히어로 배경은 이 상수를 그대로 깐다(home_screen.dart `_kHeroMatte`).
    // 어긋나면 영상 사각형이 배경 위에 액자처럼 뜬다 — Jin 이 2026-08-06 부터
    // 세 번 지적한 "동영상 흰 배경"이 정확히 그 증상이었다. 원인은 디자인 값
    // (#FAF6EC)과 H.264 가 실제로 내놓는 값(#F9F4EB)의 1~2 차이였고, 검사
    // 도구의 TOLERANCE=2 가 그걸 통과시켜 오래 안 잡혔다.
    final mattes = byName.values.map((e) => e['matte'] as String).toSet();
    expect(
      mattes,
      hasLength(1),
      reason: '클립마다 매트가 다르면 배경 하나로는 맞출 수 없다',
    );
    final hex = mattes.single.replaceFirst('#', '');
    expect(
      HomeHeroClips.matte,
      Color(int.parse('FF$hex', radix: 16)),
      reason:
          '클립을 새로 내보냈으면 python tool/check_home_hero_matte.py 를 다시 '
          '돌리고 HomeHeroClips.matte 를 보고서 값에 맞춰라.',
    );
  });

  test('report covers exactly the two bundled home hero clips', () {
    final onDisk = clips().map((file) => file.uri.pathSegments.last).toSet();
    expect(onDisk, {'magpie_walking_front_hanji.mp4', 'tiger_rise_hanji.mp4'});
    expect(byName.keys.toSet(), onDisk);
  });

  test('report byte sizes match bundled home hero clips', () {
    final drifted = <String>[];
    for (final file in clips()) {
      final name = file.uri.pathSegments.last;
      if (byName[name]?['bytes'] != file.lengthSync()) {
        drifted.add(name);
      }
    }
    expect(
      drifted,
      isEmpty,
      reason:
          'Run `python tool/check_home_hero_matte.py` after replacing clips.',
    );
  });

  test('report SHA-256 hashes match bundled home hero clips', () {
    final drifted = <String>[];
    for (final file in clips()) {
      final name = file.uri.pathSegments.last;
      final actual = sha256
          .convert(file.readAsBytesSync())
          .toString()
          .toUpperCase();
      if (byName[name]?['sha256'] != actual) {
        drifted.add(name);
      }
    }
    expect(
      drifted,
      isEmpty,
      reason:
          'Run `python tool/check_home_hero_matte.py` after replacing clips.',
    );
  });

  test('every home hero frame keeps the precomposited Hanji matte', () {
    final bad = <String>[];
    for (final entry in byName.values) {
      if (entry['ok'] != true || (entry['match_ratio'] as num) < 0.99) {
        bad.add('${entry['path']}: ${entry['matte']} -- ${entry['reason']}');
      }
    }
    expect(bad, isEmpty);
  });

  test('derived clips preserve the source frame counts', () {
    expect(byName['magpie_walking_front_hanji.mp4']?['frames_sampled'], 113);
    expect(byName['tiger_rise_hanji.mp4']?['frames_sampled'], 121);
  });
}
