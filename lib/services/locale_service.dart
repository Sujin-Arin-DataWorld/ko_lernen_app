import 'package:flutter/material.dart';
import 'storage_service.dart';

/// Global locale state — bei Änderung rebuildet die ganze App.
/// `null` = Systemsprache.
final ValueNotifier<Locale?> localeNotifier = ValueNotifier<Locale?>(_loadInitial());

Locale? _loadInitial() {
  switch (Storage.localeCode) {
    case 'de': return const Locale('de');
    case 'en': return const Locale('en');
    default:   return null;
  }
}

Future<void> setLocale(Locale? locale) async {
  if (locale == null) {
    await Storage.setLocaleCode('');
  } else {
    await Storage.setLocaleCode(locale.languageCode);
  }
  localeNotifier.value = locale;
}
