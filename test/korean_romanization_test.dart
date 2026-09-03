import 'package:flutter_test/flutter_test.dart';
import 'package:ko_lernen_app/services/korean_romanization.dart';

void main() {
  test('example reading preserves spaces and punctuation', () {
    expect(
      romanizeKorean('안녕하세요. 저는 학생이에요.'),
      'annyeonghaseyo. jeoneun haksaengieyo.',
    );
    expect(romanizeKorean('잘 지내요?'), 'jal jinaeyo?');
  });

  test('common connected sounds follow Revised Romanization', () {
    const examples = {
      '감사합니다': 'gamsahamnida',
      '죄송합니다': 'joesonghamnida',
      '한국어': 'hangugeo',
      '먹어요': 'meogeoyo',
      '읽어요': 'ilgeoyo',
      '읽고': 'ilgo',
      '읽기': 'ilgi',
      '닭고기': 'dakgogi',
      '흙길': 'heukgil',
      '좋아요': 'joayo',
      '괜찮아요': 'gwaenchanayo',
      '같이': 'gachi',
      '신라': 'silla',
      '설날': 'seollal',
      '독립': 'dongnip',
      '좋다': 'jota',
      '놓고': 'noko',
      '국화': 'gukhwa',
    };
    for (final entry in examples.entries) {
      expect(romanizeKorean(entry.key), entry.value, reason: entry.key);
    }
  });
}
