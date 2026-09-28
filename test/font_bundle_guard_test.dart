import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:ko_lernen_app/widgets/sori/tokens.dart';

/// 번들 폰트가 자기 역할에 필요한 글리프를 실제로 담고 있는지 검사한다.
///
/// 2026-08-19 발견: `PretendardStd-*.otf` 5개가 라틴 전용 서브셋이라 한글 글리프가
/// 0개였고, 한국어 전부가 OS 폴백 폰트로 그려지고 있었다. pubspec 주석은
/// "한국어 모던 산세리프"라고 적혀 있었다. 의존성 없이 OTF `cmap`(format 4/12)을
/// 직접 읽어 `가`·`힣`·`ㄱ`·`ä`·`ß` 가 있는지 본다.
void main() {
  test('font roles keep UI, Korean learning, and culture display separate', () {
    expect(SoriFonts.sans, 'IBMPlexSans');
    expect(SoriFonts.learningKorean, 'NotoSansKR');
    expect(SoriFonts.culture, 'MaruBuri');
  });

  test('pubspec fonts contain German; Korean roles cover all Hangul', () {
    final pubspec = File('pubspec.yaml').readAsStringSync();
    final assets = RegExp(
      r'asset:\s*(assets/fonts/\S+\.(?:otf|ttf))',
    ).allMatches(pubspec).map((m) => m.group(1)!).toList();
    expect(assets, isNotEmpty, reason: 'pubspec fonts: 블록이 비어 있다');
    const latinRequired = <String, int>{'ä': 0xE4, 'ß': 0xDF, '€': 0x20AC};
    for (final asset in assets) {
      final cps = _cmapCodepoints(File(asset).readAsBytesSync());
      final missing = latinRequired.entries
          .where((e) => !cps.contains(e.value))
          .map((e) => e.key)
          .toList();
      expect(missing, isEmpty, reason: '$asset 에 글리프 없음: $missing');
      if (!asset.contains('/IBMPlexSans/')) {
        expect(cps, containsAll(<int>[0xAC00, 0xD7A3, 0x3131]));
        final hangul = cps.where((c) => c >= 0xAC00 && c <= 0xD7A3).length;
        expect(hangul, 11172, reason: '$asset 한글 음절 $hangul/11172 — 서브셋 금지');
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
