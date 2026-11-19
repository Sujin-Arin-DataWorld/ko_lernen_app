import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;

import '../models/culture_story_arc.dart';

/// Optional read-only grouping metadata for Culture Stories.
///
/// The catalog owns no completion, mastery, XP, rewards, or persistence.
/// Missing/malformed data resolves to null so it can never block learning.
class CultureStoryArcRepository {
  CultureStoryArcRepository._();

  static const assetPath = 'assets/data/culture_story_arcs.json';
  static Future<CultureStoryArcCatalog?>? _cachedCatalog;
  static Future<CultureStoryArcCatalog?> Function()? _loaderForTesting;

  static Future<CultureStoryArcCatalog?> load() {
    return _cachedCatalog ??= (_loaderForTesting?.call() ?? _loadSafely());
  }

  static Future<CultureStoryArcCatalog?> _loadSafely() async {
    try {
      final raw = await rootBundle.loadString(assetPath);
      return CultureStoryArcCatalog.fromJsonString(raw);
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
    Future<CultureStoryArcCatalog?> Function()? loader,
  ) {
    _cachedCatalog = null;
    _loaderForTesting = loader;
  }
}
