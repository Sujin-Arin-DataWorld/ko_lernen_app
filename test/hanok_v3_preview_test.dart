import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ko_lernen_app/l10n/generated/app_localizations.dart';
import 'package:ko_lernen_app/models/sarangchae_construction.dart';
import 'package:ko_lernen_app/widgets/sori/hanok_v3_preview.dart';
import 'package:ko_lernen_app/widgets/sori/ildu_r16_layer_artwork.dart';
import 'support/r16_test_asset_bundle.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final construction = _construction();

  testWidgets('earned stage 16 shows the approved original without filters', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(
        SizedBox(
          width: 390,
          height: 292.5,
          child: SarangchaeStageArtwork(
            construction: construction,
            earnedStageCount: 16,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final image = tester.widget<IlDuR16LayerArtwork>(
      find.byType(IlDuR16LayerArtwork),
    );
    expect(image.processId, 'ildu.${construction.stage(16).stageId}');
    expect(image.fit, BoxFit.contain);
    expect(image.opacity, 1);
    expect(find.byType(ColorFiltered), findsNothing);
    expect(find.byType(Opacity), findsNothing);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });

  testWidgets('unearned construction is clearly locked', (tester) async {
    await tester.pumpWidget(
      _app(
        SizedBox(
          width: 390,
          height: 292.5,
          child: SarangchaeStageArtwork(
            construction: construction,
            earnedStageCount: 0,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('sarangchae-stage-artwork-1')),
      findsOneWidget,
    );
    // The paint alpha preserves neutral-white shadow corners. An outer
    // opacity saveLayer would reintroduce a white rectangle while fading.
    expect(find.byType(Opacity), findsNothing);
    expect(
      tester
          .widget<IlDuR16LayerArtwork>(find.byType(IlDuR16LayerArtwork))
          .opacity,
      .24,
    );
    expect(find.byIcon(Icons.lock_rounded), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });
}

Widget _app(Widget home) => MaterialApp(
  locale: const Locale('en'),
  supportedLocales: AppL10n.supportedLocales,
  localizationsDelegates: AppL10n.localizationsDelegates,
  home: DefaultAssetBundle(
    bundle: _TinyPngBundle(),
    child: Scaffold(body: home),
  ),
);

final class _TinyPngBundle extends R16TestAssetBundle {
  static final Uint8List _png = base64Decode(
    'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVQIHWP4z8DwHwAFgAI/OSvDPwAAAABJRU5ErkJggg==',
  );

  @override
  Future<ByteData> load(String key) => key.endsWith('.png')
      ? Future<ByteData>.value(ByteData.sublistView(_png))
      : rootBundle.load(key);
}

SarangchaeConstruction _construction() => SarangchaeConstruction.fromJson(
  jsonDecode(File(SarangchaeConstruction.assetPath).readAsStringSync()),
);
