/// 덱 제스처 **방향 계약** 래칫 — 2026-08-18 신설.
///
///   좌 = 모름 · 우 = 앎 · 위 = 저장 · 아래 = 넘어가기   (Jin 확정)
///
/// 이 가드가 생긴 이유는 실제 사고다. 한글 카드 탭을 `SoriSwipeCard` 로 옮기면서
/// `onSwipeLeft: _next` / `onSwipeRight: _prev` 로 붙였다 — 좌/우를 판정이 아니라
/// 이전/다음에 쓴 것이다. 화면마다 좌/우 뜻이 갈리면 "말 안 해도 방향을 안다"는
/// 목표가 무너지고, 배지를 안 넘긴 탓에 레일 색까지 정반대로 떴다
/// (다음 = 빨강/danger, 이전 = 초록).
///
/// 사람 리뷰로 잡을 종류가 아니라서 CI 로 옮긴다.
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// 좌/우에 붙으면 안 되는 **이동용** 핸들러 이름.
/// 좌/우는 판정 축이다 — 이동은 아래(넘어가기)나 버튼이 맡는다.
final _navigationHandler = RegExp(
  r'on(?:Swipe)?(?:Left|Right):\s*_?(next|prev|previous|advance|goNext|goPrev)\b',
  caseSensitive: false,
);

/// `SoriSwipeCard(` 한 건의 인자 영역을 대략 잘라온다.
/// `child:` 가 나오면 그 위젯의 본문이므로 거기서 멈춘다.
String _argumentWindow(List<String> lines, int start) {
  final buffer = StringBuffer();
  for (var i = start; i < lines.length && i < start + 60; i++) {
    final line = lines[i];
    if (i > start && RegExp(r'^\s{0,22}child:').hasMatch(line)) {
      break;
    }
    buffer.writeln(line);
  }
  return buffer.toString();
}

void main() {
  late List<File> dartFiles;

  setUpAll(() {
    dartFiles = Directory('lib')
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.endsWith('.dart'))
        .toList()
      ..sort((a, b) => a.path.compareTo(b.path));
  });

  test('좌/우 스와이프를 이전/다음 이동에 쓰지 않는다', () {
    final offenders = <String>[];
    for (final file in dartFiles) {
      final lines = file.readAsLinesSync();
      for (var i = 0; i < lines.length; i++) {
        if (!lines[i].contains('SoriSwipeCard(')) {
          continue;
        }
        final window = _argumentWindow(lines, i);
        for (final m in _navigationHandler.allMatches(window)) {
          offenders.add('${file.path}:${i + 1}  ->  ${m.group(0)}');
        }
      }
    }
    expect(
      offenders,
      isEmpty,
      reason:
          '좌 = 모름 · 우 = 앎 이다. 이전/다음 이동은 아래(넘어가기)나 버튼으로 '
          '보낼 것 — 화면마다 좌/우 뜻이 달라지면 손버릇이 깨진다.\n'
          '${offenders.join("\n")}',
    );
  });

  test('의미를 쓰는 방향은 배지로 선언한다', () {
    // 배지가 없으면 레일이 중립색으로 빠져 "무슨 일이 일어날지" 가 안 보인다.
    const pairs = {
      'onSwipeLeft': 'leftBadge',
      'onSwipeRight': 'rightBadge',
      'onSwipeUp': 'upBadge',
      'onSwipeDown': 'downBadge',
    };
    final offenders = <String>[];
    for (final file in dartFiles) {
      final lines = file.readAsLinesSync();
      for (var i = 0; i < lines.length; i++) {
        if (!lines[i].contains('SoriSwipeCard(')) {
          continue;
        }
        final window = _argumentWindow(lines, i);
        pairs.forEach((handler, badge) {
          final wired = RegExp('$handler:\\s*(?!null)').hasMatch(window);
          if (wired && !window.contains('$badge:')) {
            offenders.add('${file.path}:${i + 1}  ->  $handler 에 $badge 없음');
          }
        });
      }
    }
    expect(offenders, isEmpty, reason: offenders.join('\n'));
  });

  test('SoriSwipeCard 를 쓰는 화면이 실제로 존재한다 — 스캔이 비면 가드가 죽는다', () {
    final users = dartFiles
        .where((f) => f.readAsStringSync().contains('SoriSwipeCard('))
        .length;
    expect(users, greaterThanOrEqualTo(5), reason: '덱 화면 수가 줄었다면 확인 필요');
  });
}
