import 'storage_service.dart';

/// **AgeGateService** — Alters-Gate für Community-Features (계/Gye).
///
/// GDPR-K (Art. 8 DSGVO): in Deutschland gilt die digitale Einwilligungsfähigkeit
/// ab **16 Jahren**. Unter 16 → Gye (Beitritt/Erstellen) deaktiviert.
/// Plan `docs/plans/stately-rising-jongga.md` §9.3.
///
/// Geburtsjahr wird **nur lokal** in [Storage.birthYear] gehalten (jahr-genau,
/// minimale Datenerhebung — kein vollständiges Geburtsdatum, nichts verlässt das
/// Gerät). 0 = nicht angegeben.
///
/// Best-effort wie die übrigen Services: wirft nie, reine Lese-Logik.
class AgeGateService {
  AgeGateService._();

  /// Mindestalter für Gye/Community (Deutschland: 16, DSGVO Art. 8).
  static const int minGyeAge = 16;

  /// Geschätztes Alter aus Geburtsjahr (jahr-genau). null wenn unbekannt/unplausibel.
  static int? get ageEstimate {
    final y = Storage.birthYear;
    if (y <= 0) return null;
    final age = DateTime.now().year - y;
    if (age < 0 || age > 120) return null; // unplausibel → wie unbekannt
    return age;
  }

  /// Geburtsjahr noch nicht angegeben → UI sollte vor Gye-Nutzung abfragen.
  static bool get needsBirthYear => Storage.birthYear <= 0;

  /// Unter Mindestalter? **Nur true** wenn Geburtsjahr gesetzt UND < 16.
  /// (Unbekanntes Alter blockiert nicht — die UI fragt vorher ab.)
  static bool get isUnderMinAge {
    final a = ageEstimate;
    return a != null && a < minGyeAge;
  }

  /// Gye erlaubt? Unbekannt → erlaubt (UI fragt ab), gesetzt & < 16 → blockiert.
  static bool get isGyeAllowed => !isUnderMinAge;

  /// Plausibles Geburtsjahr? (nicht in der Zukunft, Alter ≤ 120.)
  static bool isPlausibleYear(int year) {
    final now = DateTime.now().year;
    return year >= now - 120 && year <= now;
  }

  /// Geburtsjahr speichern (validiert). Gibt `true` zurück wenn gespeichert.
  static Future<bool> saveBirthYear(int year) async {
    if (!isPlausibleYear(year)) return false;
    await Storage.setBirthYear(year);
    return true;
  }
}
