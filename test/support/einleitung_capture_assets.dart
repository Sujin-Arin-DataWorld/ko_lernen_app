import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'real_fonts.dart';

bool _fontsLoaded = false;

/// The introduction Latin and Korean display faces plus the main text families.
/// Does not depend on gallery fonts or the broader C integration test helpers.
Future<void> loadEinleitungFonts() async {
  if (_fontsLoaded) {
    return;
  }
  // Keep measurements on the same localized faces used by the application.
  await loadSoriRealFonts();
  const families = {
    'Roboto': ['assets/fonts/Roboto/Roboto-Variable.ttf'],
    'RobotoCondensed': [
      'assets/fonts/RobotoCondensed/RobotoCondensed-Variable.ttf',
    ],
    'Lora': ['assets/fonts/Lora/Lora-Variable.ttf'],
    'NotoSerif': ['assets/fonts/NotoSerif/NotoSerif-Variable.ttf'],
    'MaruBuri': [
      'assets/fonts/MaruBuri/MaruBuri-Regular.otf',
      'assets/fonts/MaruBuri/MaruBuri-SemiBold.otf',
    ],
    'NotoSansKR': ['assets/fonts/NotoSansKR/NotoSansKR-Variable.ttf'],
    'Paperlogy': [
      'assets/fonts/Paperlogy/Paperlogy-Regular.ttf',
      'assets/fonts/Paperlogy/Paperlogy-Medium.ttf',
      'assets/fonts/Paperlogy/Paperlogy-SemiBold.ttf',
      'assets/fonts/Paperlogy/Paperlogy-Bold.ttf',
    ],
  };
  for (final entry in families.entries) {
    final loader = FontLoader(entry.key);
    for (final asset in entry.value) {
      loader.addFont(rootBundle.load(asset));
    }
    await loader.load();
  }
  // Framework icon glyphs are optional on CI, as in main's real_fonts helper.
  // This adds no application font or external package dependency.
  var directory = File(Platform.resolvedExecutable).parent;
  while (true) {
    final fonts = '${directory.path}/bin/cache/artifacts/material_fonts';
    final icon = [
      File('$fonts/MaterialIcons-Regular.otf'),
      File('$fonts/materialicons-regular.otf'),
    ].where((file) => file.existsSync()).firstOrNull;
    if (icon != null) {
      final bytes = icon.readAsBytesSync();
      await (FontLoader(
        'MaterialIcons',
      )..addFont(Future<ByteData>.value(ByteData.view(bytes.buffer)))).load();
      break;
    }
    final parent = directory.parent;
    if (parent.path == directory.path) {
      break;
    }
    directory = parent;
  }
  _fontsLoaded = true;
}

/// Decode whole Image widgets before capture, outside the widget-test clock.
/// Einleitung renders independent images and has no atlas/cache dependency.
Future<void> settleEinleitungCaptureAssets(WidgetTester tester) async {
  final context = tester.element(find.byType(MaterialApp).first);
  final providers = tester
      .widgetList<Image>(find.byType(Image))
      .map((image) => image.image)
      .toSet();
  await tester.runAsync(() async {
    await Future.wait([
      for (final provider in providers)
        precacheImage(provider, context).timeout(
          const Duration(seconds: 15),
          onTimeout: () =>
              throw StateError('Image decode timed out: $provider'),
        ),
    ]);
  });
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 250));
}
