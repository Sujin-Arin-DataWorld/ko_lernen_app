import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:ko_lernen_app/widgets/sori/intro_tokens.dart';
import 'package:ko_lernen_app/widgets/sori/tokens.dart';

/// 인터페이스/학습 폰트와 Einleitung의 라틴·한글 표시 서체를 검사한다.
///
/// 2026-08-19 발견: `PretendardStd-*.otf` 5개가 라틴 전용 서브셋이라 한글 글리프가
/// 0개였고, 한국어 전부가 OS 폴백 폰트로 그려지고 있었다. pubspec 주석은
/// "한국어 모던 산세리프"라고 적혀 있었다. 의존성 없이 OTF `cmap`(format 4/12)을
/// 직접 읽어 독일어와 완성형 한글을 검사한다.
const _koreanFaces = [
  'assets/fonts/Paperlogy/Paperlogy-Regular.ttf',
  'assets/fonts/Paperlogy/Paperlogy-Medium.ttf',
  'assets/fonts/Paperlogy/Paperlogy-SemiBold.ttf',
  'assets/fonts/Paperlogy/Paperlogy-Bold.ttf',
  'assets/fonts/NotoSansKR/NotoSansKR-Variable.ttf',
];

const _introLatinFaces = [
  'assets/fonts/Roboto/Roboto-Variable.ttf',
  'assets/fonts/RobotoCondensed/RobotoCondensed-Variable.ttf',
  'assets/fonts/Lora/Lora-Variable.ttf',
  'assets/fonts/NotoSerif/NotoSerif-Variable.ttf',
];

const _introKoreanDisplayFaces = [
  'assets/fonts/MaruBuri/MaruBuri-Regular.otf',
  'assets/fonts/MaruBuri/MaruBuri-SemiBold.otf',
];

void main() {
  test(
    'interface lettering is distinct from Korean, German and English learning copy',
    () {
      expect(SoriFonts.sans, 'NotoSansKR');
      expect(SoriFonts.korean, 'NotoSansKR');
      expect(SoriFonts.culture, SoriFonts.korean);
      expect(SoriFonts.interface, 'Paperlogy');
      expect(SoriFonts.learningKorean, SoriFonts.sans);
      expect(SoriFonts.fallback, isEmpty);
    },
  );

  test('every declared font is inventoried and covers German and English', () {
    final pubspec = File('pubspec.yaml').readAsStringSync();
    final assets = RegExp(
      r'asset:\s*(assets/fonts/\S+\.(?:otf|ttf))',
    ).allMatches(pubspec).map((m) => m.group(1)!).toList();
    expect(
      assets,
      unorderedEquals([
        ..._koreanFaces,
        ..._introLatinFaces,
        ..._introKoreanDisplayFaces,
      ]),
    );
    const requiredLatin = <String, int>{
      'A': 0x41,
      'a': 0x61,
      'Z': 0x5A,
      'z': 0x7A,
      '0': 0x30,
      '9': 0x39,
      'Ä': 0xC4,
      'ä': 0xE4,
      'Ö': 0xD6,
      'ö': 0xF6,
      'Ü': 0xDC,
      'ü': 0xFC,
      'ß': 0xDF,
      '€': 0x20AC,
    };
    for (final asset in assets) {
      final cps = _cmapCodepoints(File(asset).readAsBytesSync());
      final missing = requiredLatin.entries
          .where((e) => !cps.contains(e.value))
          .map((e) => e.key)
          .toList();
      expect(missing, isEmpty, reason: '$asset 에 글리프 없음: $missing');
    }
  });

  test('learning and introduction display faces retain complete Korean', () {
    for (final asset in [..._koreanFaces, ..._introKoreanDisplayFaces]) {
      final cps = _cmapCodepoints(File(asset).readAsBytesSync());
      expect(
        cps,
        containsAll([0x3131, 0x314F, 0xAC00, 0xD7A3, ...'안녕하세요'.runes]),
      );
      final hangul = cps.where((c) => c >= 0xAC00 && c <= 0xD7A3).length;
      expect(hangul, 11172, reason: '$asset 한글 음절 $hangul/11172');
    }
  });

  test('Einleitung Korean and mixed copy explicitly select bundled Korean', () {
    expect(IntroFonts.sans, 'Roboto');
    expect(IntroFonts.condensed, 'RobotoCondensed');
    expect(IntroFonts.serif, 'Lora');
    expect(IntroFonts.brand, 'NotoSerif');
    expect(IntroFonts.korean, SoriFonts.korean);
    expect(IntroFonts.koreanDisplay, 'MaruBuri');

    final koreanStyles = {
      'sound glyph': IntroTypography.soundGlyph(44),
      'Korean sentence': IntroTypography.koreanSample,
      'book Korean': IntroTypography.bookInk(18, 24, true, false),
    };
    for (final entry in koreanStyles.entries) {
      expect(
        entry.value.fontFamily,
        IntroFonts.koreanDisplay,
        reason: entry.key,
      );
    }
    expect(IntroTypography.soundGlyph(44).fontWeight?.value, 600);
    expect(IntroTypography.koreanSample.fontWeight?.value, 400);
    expect(IntroTypography.bookInk(18, 24, true, false).fontWeight?.value, 600);
    expect(
      IntroTypography.bookInk(18, 24, true, false).color,
      IntroPalette.calligraphyInk,
    );
    expect(IntroPalette.calligraphyInk.toARGB32(), 0xFF071C21);
    final mixedStyles = {
      'setup': IntroTypography.setupWords(18, 1, false, IntroPalette.ink),
      'companion': IntroTypography.companionWords(
        18,
        24,
        1,
        false,
        IntroPalette.ink,
      ),
      'Gye': IntroTypography.gyeBody(1),
      'body': IntroTypography.body(18, false, IntroPalette.ink),
      'action': IntroTypography.primaryAction(20, true),
    };
    for (final entry in mixedStyles.entries) {
      expect(
        entry.value.fontFamilyFallback,
        ['NotoSansKR'],
        reason: '${entry.key} must not depend on an OS Korean fallback',
      );
    }
  });
}

Set<int> _cmapCodepoints(Uint8List bytes) {
  final d = ByteData.sublistView(bytes);
  final numTables = d.getUint16(4);
  int? cmapOffset;
  for (var i = 0; i < numTables; i++) {
    final rec = 12 + i * 16;
    final tag = String.fromCharCodes(bytes.sublist(rec, rec + 4));
    if (tag == 'cmap') {
      cmapOffset = d.getUint32(rec + 8);
    }
  }
  if (cmapOffset == null) {
    throw StateError('cmap 테이블 없음');
  }
  final out = <int>{};
  final n = d.getUint16(cmapOffset + 2);
  for (var i = 0; i < n; i++) {
    final sub = cmapOffset + d.getUint32(cmapOffset + 4 + i * 8 + 4);
    final format = d.getUint16(sub);
    if (format == 4) {
      final segX2 = d.getUint16(sub + 6);
      final ends = sub + 14;
      final starts = ends + segX2 + 2;
      final deltas = starts + segX2;
      final rangeOffsets = deltas + segX2;
      for (var s = 0; s < segX2 ~/ 2; s++) {
        final end = d.getUint16(ends + s * 2);
        final start = d.getUint16(starts + s * 2);
        if (start == 0xFFFF) {
          continue;
        }
        for (var c = start; c <= end; c++) {
          final delta = d.getInt16(deltas + s * 2);
          final rangeOffset = d.getUint16(rangeOffsets + s * 2);
          final glyph = rangeOffset == 0
              ? (c + delta) & 0xffff
              : d.getUint16(
                  rangeOffsets + s * 2 + rangeOffset + (c - start) * 2,
                );
          if (glyph != 0 &&
              (rangeOffset == 0 || ((glyph + delta) & 0xffff) != 0)) {
            out.add(c);
          }
        }
      }
    } else if (format == 12) {
      final nGroups = d.getUint32(sub + 12);
      for (var g = 0; g < nGroups; g++) {
        final base = sub + 16 + g * 12;
        final start = d.getUint32(base);
        final end = d.getUint32(base + 4);
        final firstGlyph = d.getUint32(base + 8);
        for (var c = start; c <= end; c++) {
          if (firstGlyph + c - start != 0) {
            out.add(c);
          }
        }
      }
    }
  }
  return out;
}
