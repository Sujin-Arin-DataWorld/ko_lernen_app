import 'dart:io';
import 'package:flutter/services.dart';
import 'package:ko_lernen_app/models/ildu_r16_art.dart';

/// Keeps the real catalog under test without a background JSON isolate in the
/// widget test's fake clock. Image bytes still come from the bundled assets.
class R16TestAssetBundle extends CachingAssetBundle {
  static final _catalog = File(IlDuR16ArtCatalog.assetPath).readAsStringSync();

  @override
  Future<String> loadString(String key, {bool cache = true}) =>
      key == IlDuR16ArtCatalog.assetPath
      ? Future.value(_catalog)
      : rootBundle.loadString(key, cache: cache);

  @override
  Future<ByteData> load(String key) => rootBundle.load(key);
}
