import 'package:shared_preferences_platform_interface/shared_preferences_platform_interface.dart';

/// Reads the captured legacy backend without replacing the shared app cache.
/// This app uses the legacy plugin's unchanged `flutter.` key prefix.
Future<Map<String, Object>> readLegacyPreferencesNativeSnapshot(
  SharedPreferencesStorePlatform backend,
) async {
  final raw = await backend.getAll();
  return {
    for (final entry in raw.entries)
      if (entry.key.startsWith('flutter.')) entry.key.substring(8): entry.value,
  };
}
