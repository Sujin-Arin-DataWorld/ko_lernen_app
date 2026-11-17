import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ko_lernen_app/models/ildu_r16_art.dart';
import 'package:ko_lernen_app/widgets/hanok_asset_image.dart';
import 'package:ko_lernen_app/widgets/sori/ildu_r16_process_image.dart';
import 'support/sori_stage_pump.dart';

IlDuR16ArtCatalog catalog() => IlDuR16ArtCatalog.fromJson(
  jsonDecode(File(IlDuR16ArtCatalog.assetPath).readAsStringSync()),
);
const fallback =
    'assets/illustrations/personal_hanok_v3/sarangchae/stage_01_site.png';

void main() {
  testWidgets(
    'resolves the exact original process ID without an index or purchase',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: SizedBox(
            height: 240,
            child: IlDuR16ProcessImage(
              processId: 'ildu.sarangchae-foundation',
              fallbackAsset: fallback,
              loader: () async => catalog(),
            ),
          ),
        ),
      );
      await pumpUntilFound(
        tester,
        find.byKey(const ValueKey('r16-ildu.sarangchae-foundation')),
      );
      expect(
        find.byKey(const ValueKey('r16-ildu.sarangchae-foundation')),
        findsOneWidget,
      );
      expect(find.byType(HanokAssetImage), findsNothing);
    },
  );
  testWidgets('catalog loading does not start prefetching an old pack', (
    tester,
  ) async {
    final pending = Completer<IlDuR16ArtCatalog>();
    await tester.pumpWidget(
      MaterialApp(
        home: IlDuR16ProcessImage(
          processId: 'ildu.sarangchae-site',
          fallbackAsset: fallback,
          loader: () => pending.future,
        ),
      ),
    );
    expect(find.byType(HanokAssetImage), findsNothing);
    pending.complete(catalog());
    await pumpSoriStage(tester);
  });
  testWidgets('a separate gate or failed catalog keeps the approved fallback', (
    tester,
  ) async {
    for (final fail in [false, true]) {
      await tester.pumpWidget(
        MaterialApp(
          home: IlDuR16ProcessImage(
            key: ValueKey(fail),
            processId: 'ildu.hyeopmun-foundation',
            fallbackAsset: fallback,
            loader: () async {
              if (fail) throw const FormatException('Unavailable');
              return catalog();
            },
          ),
        ),
      );
      await pumpUntilFound(tester, find.byType(HanokAssetImage));
      expect(
        tester.widget<HanokAssetImage>(find.byType(HanokAssetImage)).assetPath,
        fallback,
      );
    }
  });
}
