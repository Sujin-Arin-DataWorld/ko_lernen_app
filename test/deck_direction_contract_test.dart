/// Content-feed gesture contract — 2026-08-19.
///
/// Live screens must not wire the four-way Tinder deck. Movement is vertical
/// only. Left/right swipe is not a judgment or navigation axis.
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  late List<File> dartFiles;
  late List<File> screenFiles;

  setUpAll(() {
    dartFiles = Directory('lib')
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.endsWith('.dart'))
        .toList()
      ..sort((a, b) => a.path.compareTo(b.path));
    screenFiles = dartFiles
        .where((f) => f.path.contains('${Platform.pathSeparator}screens${Platform.pathSeparator}'))
        .toList();
  });

  test('live screens do not construct SoriSwipeCard', () {
    final offenders = <String>[
      for (final file in screenFiles)
        if (file.readAsStringSync().contains('SoriSwipeCard(')) file.path,
    ];
    expect(
      offenders,
      isEmpty,
      reason:
          '틴더 덱은 콘텐츠 화면에서 제거됐다. SoriContentFeed 를 쓴다.\n'
          '${offenders.join("\n")}',
    );
  });

  test('live screens do not construct SoriDeckActionBar', () {
    final offenders = <String>[
      for (final file in screenFiles)
        if (file.readAsStringSync().contains('SoriDeckActionBar(')) file.path,
    ];
    expect(offenders, isEmpty, reason: offenders.join('\n'));
  });

  test('SoriContentFeed is actually used — empty scan must not pass', () {
    final users = dartFiles
        .where((f) => f.readAsStringSync().contains('SoriContentFeed('))
        .length;
    expect(users, greaterThanOrEqualTo(5), reason: '피드 화면 수가 줄었다면 확인 필요');
  });

  test('screens do not bind left/right swipe handlers', () {
    final offenders = <String>[];
    for (final file in screenFiles) {
      final src = file.readAsStringSync();
      if (RegExp(r'onSwipe(?:Left|Right):').hasMatch(src)) {
        offenders.add(file.path);
      }
    }
    expect(
      offenders,
      isEmpty,
      reason: '좌/우 스와이프는 폐기. 이동은 세로 플링이다.\n${offenders.join("\n")}',
    );
  });
}
