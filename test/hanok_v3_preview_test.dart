import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ko_lernen_app/l10n/generated/app_localizations.dart';
import 'package:ko_lernen_app/models/sarangchae_construction.dart';
import 'package:ko_lernen_app/widgets/sori/hanok_v3_preview.dart';

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

    final image = tester.widget<Image>(
      find.byKey(const ValueKey('sarangchae-stage-artwork-16')),
    );
    expect(
      (image.image as AssetImage).assetName,
      construction.stage(16).assetPath,
    );
    expect(image.fit, BoxFit.contain);
    expect(image.alignment, Alignment.center);
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
    expect(find.byType(Opacity), findsOneWidget);
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

final class _TinyPngBundle extends CachingAssetBundle {
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
