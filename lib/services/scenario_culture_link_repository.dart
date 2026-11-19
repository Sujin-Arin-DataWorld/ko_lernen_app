import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;

import '../models/scenario_culture_link.dart';

/// Optional, read-only bridge between canonical scenarios and cultural terms.
///
/// This repository owns no learning progress, mastery, reward, companion, or
/// scenario state. Missing or malformed data resolves to null so culture
/// presentation can never block the underlying learning flow.
class ScenarioCultureLinkRepository {
  ScenarioCultureLinkRepository._();

  static const assetPath = 'assets/data/scenario_culture_links.json';
  static Future<ScenarioCultureLinkCatalog?>? _cachedCatalog;
  static Future<ScenarioCultureLinkCatalog?> Function()? _loaderForTesting;

  static Future<ScenarioCultureLinkCatalog?> load() {
    return _cachedCatalog ??= (_loaderForTesting?.call() ?? _loadSafely());
  }

  static Future<ScenarioCultureLinkCatalog?> _loadSafely() async {
    try {
      final raw = await rootBundle.loadString(assetPath);
      return ScenarioCultureLinkCatalog.fromJsonString(raw);
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
    Future<ScenarioCultureLinkCatalog?> Function()? loader,
  ) {
    _cachedCatalog = null;
    _loaderForTesting = loader;
  }
}
