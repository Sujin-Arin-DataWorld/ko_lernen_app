import 'package:flutter/services.dart';

Future<void> loadCFonts() async {
  final loader = FontLoader('Paperlogy');
  for (final weight in ['Regular', 'Medium', 'SemiBold', 'Bold']) {
    loader.addFont(
      rootBundle.load('assets/fonts/Paperlogy/Paperlogy-$weight.ttf'),
    );
  }
  await loader.load();
  final korean = FontLoader('NotoSansKR')
    ..addFont(
      rootBundle.load('assets/fonts/NotoSansKR/NotoSansKR-Variable.ttf'),
    );
  await korean.load();
}
