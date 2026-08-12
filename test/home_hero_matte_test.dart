import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
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
