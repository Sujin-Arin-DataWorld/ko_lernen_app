/// 낱자 발음 계약 — 테스터(Amor, 2026-08-17)가 "카드를 누르면 순수 음가가
/// 아니라 예시어 전체가 나온다"고 보고한 건의 재발 방지.
///
/// 낱자 카드는 **음가**를 들려주는 화면이다. 여기서 강제하는 것:
///   1. `speakableJamo` 는 언제나 **1음절**을 돌려준다 (예시어 회귀 차단)
///   2. Dart 예외표와 `tool/generate_tts.py` 예외표가 항상 같다
///   3. 낱자 음성 경로가 화면마다 갈라지지 않는다
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:ko_lernen_app/data/hangul_data.dart';

/// 초성 19 (Unicode 순서)
const leads = [
  'ㄱ', 'ㄲ', 'ㄴ', 'ㄷ', 'ㄸ', 'ㄹ', 'ㅁ', 'ㅂ', 'ㅃ', 'ㅅ', //
  'ㅆ', 'ㅇ', 'ㅈ', 'ㅉ', 'ㅊ', 'ㅋ', 'ㅌ', 'ㅍ', 'ㅎ',
];

/// 중성 21 (Unicode 순서)
const vowelJamo = [
  'ㅏ', 'ㅐ', 'ㅑ', 'ㅒ', 'ㅓ', 'ㅔ', 'ㅕ', 'ㅖ', 'ㅗ', 'ㅘ', 'ㅙ', //
  'ㅚ', 'ㅛ', 'ㅜ', 'ㅝ', 'ㅞ', 'ㅟ', 'ㅠ', 'ㅡ', 'ㅢ', 'ㅣ',
];

/// 주석(`//` 이후)을 지운다 — 설명 속 예시가 실제 항목으로 잡히면 안 된다.
String stripLineComments(String source) => source
    .split('\n')
    .map((line) {
      final at = line.indexOf('//');
      return at < 0 ? line : line.substring(0, at);
    })
    .join('\n');

/// `'ㄱ' => '그',` 꼴을 뽑는다. switch 식이 비어 있으면 빈 맵.
Map<String, String> parseDartCarriers(String rawSource) {
  final source = stripLineComments(rawSource);
  final body = RegExp(
    r'String\?\s+stableJamoCarrier\(String letter\)\s*=>\s*switch\s*\(letter\)\s*\{(.*?)\n\};',
    dotAll: true,
  ).firstMatch(source);
  expect(body, isNotNull, reason: 'stableJamoCarrier 를 찾지 못했다');
  return {
    for (final m in RegExp(
      r"'([^']+)'\s*=>\s*'([^']+)'",
    ).allMatches(body!.group(1)!))
      m.group(1)!: m.group(2)!,
  };
}

/// `"ㄱ": "그",` 꼴을 뽑는다.
Map<String, String> parsePythonCarriers(String rawSource) {
  final source = rawSource
      .split('\n')
      .map((line) {
        final at = line.indexOf('#');
        return at < 0 ? line : line.substring(0, at);
      })
      .join('\n');
  final body = RegExp(
    r'stable_carriers\s*=\s*\{(.*?)\}',
    dotAll: true,
  ).firstMatch(source);
  expect(body, isNotNull, reason: 'stable_carriers 를 찾지 못했다');
  return {
    for (final m in RegExp(
      r'"([^"]+)"\s*:\s*"([^"]+)"',
    ).allMatches(body!.group(1)!))
      m.group(1)!: m.group(2)!,
  };
}

bool isSingleSyllable(String s) {
  final runes = s.runes.toList();
  if (runes.length != 1) {
    return false;
  }
  return runes.first >= 0xAC00 && runes.first <= 0xD7A3;
}

void main() {
  group('speakableJamo 는 언제나 1음절이다', () {
    test('초성 19자', () {
      for (final letter in leads) {
        final spoken = speakableJamo(letter);
        expect(
          isSingleSyllable(spoken),
          isTrue,
          reason: '$letter -> "$spoken" 은 1음절이 아니다. 낱자 카드는 음가를 '
              '들려주는 화면이라 예시어를 읽으면 안 된다.',
        );
      }
    });

    test('중성 21자', () {
      for (final letter in vowelJamo) {
        final spoken = speakableJamo(letter);
        expect(
          isSingleSyllable(spoken),
          isTrue,
          reason: '$letter -> "$spoken" 은 1음절이 아니다.',
        );
      }
    });

    test('예외표에 등록하더라도 1음절이어야 한다', () {
      final carriers = parseDartCarriers(
        File('lib/data/hangul_data.dart').readAsStringSync(),
      );
      for (final entry in carriers.entries) {
        expect(
          isSingleSyllable(entry.value),
          isTrue,
          reason: '${entry.key} => "${entry.value}" — 예외표에도 예시어(2음절 '
              '이상)를 넣지 말 것. 1음절만 허용한다.',
        );
      }
    });

    test('한글 화면에 있는 낱자는 전부 커버된다', () {
      for (final c in [...consonants, ...vowels]) {
        expect(
          isSingleSyllable(speakableJamo(c.letter)),
          isTrue,
          reason: '${c.letter} 는 화면에 노출되는데 1음절 음가가 없다',
        );
      }
    });
  });

  test('Dart 예외표와 generate_tts.py 예외표가 같다', () {
    // 두 파일이 어긋나면 사전 생성한 음성과 앱이 요청하는 텍스트의 sha1 이
    // 달라져 그 낱자만 조용히 OS 폴백 음성으로 떨어진다.
    final dart = parseDartCarriers(
      File('lib/data/hangul_data.dart').readAsStringSync(),
    );
    final python = parsePythonCarriers(
      File('tool/generate_tts.py').readAsStringSync(),
    );
    expect(
      python,
      equals(dart),
      reason: 'lib/data/hangul_data.dart 의 stableJamoCarrier 와 '
          'tool/generate_tts.py 의 stable_carriers 는 항상 같아야 한다.',
    );
  });

  group('낱자 음성 경로가 화면마다 갈라지지 않는다', () {
    test('daily_char_sheet 는 자체 자모 이름표를 두지 않는다', () {
      // 이 화면은 낱자 "이름"(기역·치읓)을 읽어 한글 탭과 다른 소리를 냈고,
      // 그 표에는 ㅡ->'은', ㅢ->'응', ㅖ->'외', ㅚ->'오' 같은 오류까지 있었다.
      final source = File(
        'lib/screens/daily_char_sheet.dart',
      ).readAsStringSync();
      expect(
        source.contains('_getJamoName'),
        isFalse,
        reason: '낱자 발음은 speakableJamo() 하나로만 간다.',
      );
      expect(
        source.contains('기역'),
        isFalse,
        reason: '낱자 이름 대신 음가를 읽어야 한다.',
      );
      expect(
        source.contains('speakableJamo'),
        isTrue,
        reason: 'speakableJamo() 를 써야 한다.',
      );
    });

    test('한글 카드 전체 탭은 예시어를 재생하지 않는다', () {
      // 카드 뒷면 예시어 칩을 GestureDetector 로 통째로 감싸면 카드 탭을
      // 가로채 예시어가 나온다. 예시어는 스피커 아이콘으로만 재생한다.
      final source = File('lib/screens/hangul_screen.dart').readAsStringSync();
      expect(
        RegExp(r'GestureDetector\(\s*onTap:\s*\(\)\s*=>\s*TtsService\.speak\(')
            .hasMatch(source),
        isFalse,
        reason: '예시어 재생은 명시적인 IconButton 으로만 노출한다.',
      );
    });

    test('FlipCard 호출은 전부 key 를 넘긴다', () {
      // key 없이 내용만 바뀌면 State 가 재사용돼 다음 카드의 뒷면이 ~190ms
      // 먼저 노출되고, 그동안 예시어 히트영역이 살아 있다 (flip_card.dart 계약).
      final offenders = <String>[];
      for (final file in Directory('lib')
          .listSync(recursive: true)
          .whereType<File>()
          .where((f) => f.path.endsWith('.dart'))) {
        final lines = file.readAsLinesSync();
        for (var i = 0; i < lines.length; i++) {
          if (!RegExp(r'\bFlipCard\($').hasMatch(lines[i].trim())) {
            continue;
          }
          final window = lines.skip(i + 1).take(3).join(' ');
          if (!window.contains('key:')) {
            offenders.add('${file.path}:${i + 1}');
          }
        }
      }
      expect(
        offenders,
        isEmpty,
        reason: 'FlipCard 는 내용이 바뀔 때 새 key 가 필요하다: '
            '${offenders.join(", ")}',
      );
    });
  });
}
