import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ko_lernen_app/widgets/sori/share_slip.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const pngSignature = [137, 80, 78, 71, 13, 10, 26, 10];

  testWidgets('ShareSlip builds with Korean + gloss text visible', (
    tester,
  ) async {
    await tester.pumpWidget(
      const Directionality(
        textDirection: TextDirection.ltr,
        child: ShareSlip(
          korean: '안녕하세요',
          gloss: 'Hallo',
          size: Size(360, 640),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('안녕하세요'), findsOneWidget);
    expect(find.text('Hallo'), findsOneWidget);
  });

  testWidgets('renderShareSlipToPng returns a valid PNG', (tester) async {
    final bytes = await renderShareSlipToPng(
      korean: '안녕하세요',
      gloss: 'Hallo, wie geht es dir?',
      size: const Size(360, 640),
    );

    expect(bytes, isNotNull);
    expect(bytes!.length, greaterThan(pngSignature.length));
    expect(bytes.sublist(0, pngSignature.length), pngSignature);
  });

  testWidgets('renderShareSlipToPng is deterministic for the same input', (
    tester,
  ) async {
    final first = await renderShareSlipToPng(
      korean: '고맙습니다',
      gloss: 'Danke',
      size: const Size(360, 640),
    );
    final second = await renderShareSlipToPng(
      korean: '고맙습니다',
      gloss: 'Danke',
      size: const Size(360, 640),
    );

    expect(first, isNotNull);
    expect(second, isNotNull);
    expect(first, second);
  });

  testWidgets('renderShareSlipToPng returns null for empty Korean text', (
    tester,
  ) async {
    final bytes = await renderShareSlipToPng(korean: '', gloss: 'Hallo');
    expect(bytes, isNull);
  });

  testWidgets('long Korean text does not throw a layout overflow', (
    tester,
  ) async {
    final bytes = await renderShareSlipToPng(
      korean: '오늘 저녁에 친구들과 함께 맛있는 음식을 먹으러 갈 예정입니다',
      gloss:
          'Heute Abend werde ich mit meinen Freunden essen gehen, das wird bestimmt schön',
      size: const Size(360, 640),
    );

    expect(bytes, isNotNull);
    expect(tester.takeException(), isNull);
  });
}
