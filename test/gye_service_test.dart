import 'package:flutter_test/flutter_test.dart';

import 'package:ko_lernen_app/data/profanity_denylist.dart';
import 'package:ko_lernen_app/services/gye_service.dart';

void main() {
  group('GyeService — 입장 코드', () {
    test('generateCode: 6자, 혼동 글자(O0I1L) 없음', () {
      for (var i = 0; i < 50; i++) {
        final c = GyeService.generateCode();
        expect(c.length, 6);
        expect(
          RegExp(r'^[ABCDEFGHJKMNPQRSTUVWXYZ23456789]{6}$').hasMatch(c),
          isTrue,
        );
        expect(c.contains(RegExp(r'[O0I1L]')), isFalse);
      }
    });

    test('isValidCodeFormat', () {
      final c = GyeService.generateCode();
      expect(GyeService.isValidCodeFormat(c), isTrue);
      expect(GyeService.isValidCodeFormat(c.toLowerCase()), isTrue); // 정규화
      expect(GyeService.isValidCodeFormat('ABC'), isFalse); // 짧음
      expect(GyeService.isValidCodeFormat('ABCDEO'), isFalse); // O 미포함
      expect(GyeService.isValidCodeFormat('ABCD1L'), isFalse); // 1·L 미포함
    });
  });

  group('GyeService.validatedName', () {
    test('trim 후 반환', () {
      expect(
        GyeService.validatedName('  Sori  ', 20, GyeError.invalidName),
        'Sori',
      );
    });
    test('빈/초과 길이 → throw', () {
      expect(
        () => GyeService.validatedName('', 20, GyeError.invalidName),
        throwsA(isA<GyeException>()),
      );
      expect(
        () => GyeService.validatedName('x' * 21, 20, GyeError.invalidName),
        throwsA(isA<GyeException>()),
      );
    });
    test('욕설 → throw', () {
      expect(
        () => GyeService.validatedName('shibal', 20, GyeError.invalidName),
        throwsA(isA<GyeException>()),
      );
    });
  });

  group('containsProfanity', () {
    test('EN/DE/KO + 난독화 잡음', () {
      expect(containsProfanity('fuck you'), isTrue);
      expect(containsProfanity('Arschloch!'), isTrue);
      expect(containsProfanity('병신'), isTrue);
      expect(containsProfanity('s.h.i.t'), isTrue);
    });
    test('깨끗한 이름 통과 (한글 보존)', () {
      expect(containsProfanity('안녕하세요'), isFalse);
      expect(containsProfanity('한글소리'), isFalse);
      expect(containsProfanity('Sori Team'), isFalse);
    });
  });
}
