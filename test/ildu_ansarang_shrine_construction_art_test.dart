import 'package:flutter_test/flutter_test.dart';
import 'package:ko_lernen_app/models/ildu_construction_art.dart';

import 'support/r16_runtime_contract.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
    '34 R16 Ansarang and shrine stages preserve learning boundaries',
    () async {
      await verifyR16Series({'ansarangchae', 'sadangmun', 'sadang'});
    },
  );
  test('global B2 boundaries split crossing receipts by building', () async {
    final catalog = await IlDuConstructionArtCatalog.load();

    final atAnsarangBoundary = catalog.b2RevealsBetween(before: 14, after: 15);
    expect(atAnsarangBoundary.single.series.id, 'sadangmun');
    expect(atAnsarangBoundary.single.beforeSequence, 0);
    expect(atAnsarangBoundary.single.afterSequence, 1);

    final atGateBoundary = catalog.b2RevealsBetween(before: 22, after: 23);
    expect(atGateBoundary.single.series.id, 'sadang');
    expect(atGateBoundary.single.beforeSequence, 0);
    expect(atGateBoundary.single.afterSequence, 1);

    final firstCrossing = catalog.b2RevealsBetween(before: 11, after: 17);
    expect(firstCrossing.map((item) => item.series.id), [
      'ansarangchae',
      'sadangmun',
    ]);
    expect(
      firstCrossing.map((item) => (item.beforeSequence, item.afterSequence)),
      [(11, 14), (0, 3)],
    );

    final secondCrossing = catalog.b2RevealsBetween(before: 22, after: 28);
    expect(secondCrossing.map((item) => item.series.id), ['sadang']);
    expect(secondCrossing.single.beforeSequence, 0);
    expect(secondCrossing.single.afterSequence, 6);
    expect(catalog.b2RevealsBetween(before: 34, after: 34), isEmpty);
  });
}
