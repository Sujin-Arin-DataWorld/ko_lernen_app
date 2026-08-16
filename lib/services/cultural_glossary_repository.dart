import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter/foundation.dart';
import 'package:ko_lernen_app/models/cultural_glossary.dart';

class CulturalGlossaryRepository {
  CulturalGlossaryRepository._();

  static const assetPath = 'docs/data/cultural_glossary.json';
  static Future<CulturalGlossary?>? _cachedCatalog;
  static Future<CulturalGlossary?> Function()? _loaderForTesting;

  /// Loads and validates the offline catalog once per app process.
  ///
  /// A malformed or missing catalog deliberately resolves to `null`: cultural
  /// help is optional and must never interrupt learning or reward flows.
  static Future<CulturalGlossary?> load() {
    return _cachedCatalog ??= (_loaderForTesting?.call() ?? _loadSafely());
  }

  static Future<CulturalGlossary?> _loadSafely() async {
    try {
      final raw = await rootBundle.loadString(assetPath);
      return CulturalGlossary.fromJsonString(raw);
    } on Object {
      return null;
    }
  }

  static void resetForTesting() {
    _cachedCatalog = null;
    _loaderForTesting = null;
  }

  @visibleForTesting
  static void setLoaderForTesting(
    Future<CulturalGlossary?> Function()? loader,
  ) {
    _cachedCatalog = null;
    _loaderForTesting = loader;
  }
}
