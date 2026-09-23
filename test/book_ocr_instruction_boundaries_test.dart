import 'dart:ui';
import 'package:flutter_test/flutter_test.dart';
import 'package:ko_lernen_app/services/book_ocr_document.dart';

BookOcrDocument _document(String text) => BookOcrDocumentBuilder.build([
  BookOcrLine(
    text: text,
    bounds: const Rect.fromLTWH(0, 0, 300, 30),
    sourceLineId: 'page:0:line:0',
    blockIndex: 0,
    lineIndex: 0,
    confidence: .95,
    recognizedLanguages: const ['ko'],
  ),
]);

void main() {
  for (final text in [
    '쓰다',
    '쓰레기',
    '쓰레기를 버려요.',
    '읽다',
    '읽어요.',
    '읽는 사람이 많아요.',
    '대답이 늦었어요.',
    '완성된 집이에요.',
    '연결이 끊겼어요.',
    '다음 주에 만나요.',
    '보기 좋은 꽃이에요.',
    '맞는 옷을 샀어요.',
    '틀린 답은 없어요.',
    '고르다',
    '알맞은 크기의 상자를 샀어요.',
    '빈칸이 많아요.',
    '단어를 읽었어요.',
    '문장을 쓰고 있어요.',
    '발음을 연습해요.',
    '쓰레기를 버리세요.',
    '읽는 사람을 도와주세요.',
    '다음 주에 전화하세요.',
    '보기 좋은 꽃을 보세요.',
    '맞는 옷을 입으세요.',
    '알맞은 크기의 상자를 고르세요.',
    '다음 표정을 지으세요.',
    '다음 말레이시아 여행을 계획하세요.',
    '주어진 기회를 잡으세요.',
    '표를 받으세요.',
    '그림을 받으세요.',
  ]) {
    test('learning text stays available: $text', () {
      final document = _document(text);
      expect(document.analysisText, text);
      expect(document.analysisUnits, hasLength(1));
      expect(document.units.single.role, isNot(BookOcrUnitRole.instruction));
      expect(document.analysisUnits.single.sourceLineIds, ['page:0:line:0']);
    });
  }
  for (final text in [
    '다음을 읽고 답하세요.',
    '다음 대화를 읽고 물음에 답하세요.',
    '보기에서 알맞은 말을 고르세요.',
    '알맞은 단어를 쓰세요.',
    '맞는 답을 고르세요.',
    '틀린 것을 찾으세요.',
    '빈칸에 알맞은 말을 쓰세요.',
    '연결하세요.',
    '고르세요.',
    '쓰세요.',
    '읽으세요.',
    '대답하세요.',
    '완성하세요.',
    '읽어 보세요.',
    '쓰십시오.',
    '다음 그림을 보고 말해 봅시다.',
    '어휘를 배웁시다.',
    '문장을 완성하세요.',
    '괄호 안의 말을 사용해서 문장을 완성하세요.',
    '보기',
    '연결하기',
    '고르기',
    '쓰기',
    '읽기',
    '대답하기',
    '완성하기',
    '다음 빈칸을 채우시오.',
    '그림을 보고 이야기하세요.',
    '주어진 단어를 사용하세요.',
    '다음 문장을 바꾸세요.',
    '알맞은 답에 동그라미를 치세요.',
    '어휘를 배우세요.',
    '다음 문장을 읽어라.',
    '빈칸에 답을 쓰라.',
    '다음 문장을 읽어 주세요.',
    '다음 질문에 답해 주세요.',
    '다음 단어를 적으세요.',
    '읽어주세요.',
    '답해주세요.',
    '적으세요.',
    '읽고 답하세요.',
    '읽고 쓰세요.',
    '읽고 대답하세요.',
    '그림과 알맞은 단어를 연결하세요.',
    '그림에 맞는 단어를 쓰세요.',
    '표를 완성하세요.',
    '그림에 맞는 단어를 고르세요.',
    '표에서 알맞은 말을 고르세요.',
  ]) {
    test('textbook task stays excluded: $text', () {
      final document = _document(text);
      expect(document.analysisUnits, isEmpty);
      expect(document.units.single.role, BookOcrUnitRole.instruction);
    });
  }
}
