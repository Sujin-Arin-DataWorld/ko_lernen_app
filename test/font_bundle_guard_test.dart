import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:ko_lernen_app/widgets/sori/tokens.dart';

/// 라틴 UI와 한글 폴백의 글리프가 실제 번들에 있는지 검사한다.
///
/// 2026-08-19 발견: `PretendardStd-*.otf` 5개가 라틴 전용 서브셋이라 한글 글리프가
/// 0개였고, 한국어 전부가 OS 폴백 폰트로 그려지고 있었다. pubspec 주석은
/// "한국어 모던 산세리프"라고 적혀 있었다. 의존성 없이 OTF `cmap`(format 4/12)을
/// 직접 읽어 Plex의 독일어와 Noto의 완성형 한글을 검사한다.
void main() {
  test('Latin UI uses Plex and Korean falls back to bundled Noto', () {
    expect(SoriFonts.sans, 'IBMPlexSans');
    expect(SoriFonts.korean, 'NotoSansKR');
    expect(SoriFonts.culture, SoriFonts.korean);
    expect(SoriFonts.fallback, [SoriFonts.korean]);
  });

  test('pubspec 폰트는 독일어와 한글 폴백 글리프를 포함한다', () {
    final pubspec = File('pubspec.yaml').readAsStringSync();
    final assets = RegExp(
      r'asset:\s*(assets/fonts/\S+\.(?:otf|ttf))',
    ).allMatches(pubspec).map((m) => m.group(1)!).toList();
    expect(assets, isNotEmpty, reason: 'pubspec fonts: 블록이 비어 있다');
    expect(
      assets,
      contains('assets/fonts/IBMPlexSans/IBMPlexSans-Variable.ttf'),
    );
    expect(assets, contains('assets/fonts/NotoSansKR/NotoSansKR-Variable.ttf'));
    const requiredLatin = <String, int>{
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
      if (asset.contains('NotoSansKR')) {
        expect(cps, containsAll([0x3131, 0xAC00, 0xD7A3]));
        final hangul = cps.where((c) => c >= 0xAC00 && c <= 0xD7A3).length;
        expect(hangul, 11172, reason: '$asset 한글 음절 $hangul/11172');
      } else if (asset.contains('IBMPlexSans')) {
        expect(
          cps.contains(0xAC00),
          isFalse,
          reason: '한글은 명시한 Noto fallback으로 렌더되어야 한다',
        );
      }
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
      for (var s = 0; s < segX2 ~/ 2; s++) {
        final end = d.getUint16(ends + s * 2);
        final start = d.getUint16(starts + s * 2);
        if (start == 0xFFFF) {
          continue;
        }
        for (var c = start; c <= end; c++) {
          out.add(c);
        }
      }
    } else if (format == 12) {
      final nGroups = d.getUint32(sub + 12);
      for (var g = 0; g < nGroups; g++) {
        final base = sub + 16 + g * 12;
        final start = d.getUint32(base);
        final end = d.getUint32(base + 4);
        for (var c = start; c <= end; c++) {
          out.add(c);
        }
      }
    }
  }
  return out;
}
