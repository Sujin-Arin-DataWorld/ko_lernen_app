import 'storage_service.dart';

/// **AgeGateService** — Alters-Gate für Community-Features (계/Gye).
///
/// GDPR-K (Art. 8 DSGVO): in Deutschland gilt die digitale Einwilligungsfähigkeit
/// ab **16 Jahren**. Unter 16 → Gye (Beitritt/Erstellen) deaktiviert.
/// Plan `docs/plans/stately-rising-jongga.md` §9.3.
///
/// Geburtsjahr wird **nur lokal und selbst angegeben** in [Storage.birthYear]
/// gehalten (jahr-genau, minimale Datenerhebung — kein vollständiges
/// Geburtsdatum, nichts verlässt das Gerät). Das ist keine Identitätsprüfung
/// und kein kryptografischer Altersnachweis. 0 = nicht angegeben.
///
/// Best-effort wie die übrigen Services: wirft nie, reine Lese-Logik.
class AgeGateService {
  AgeGateService._();

  static const bool isSelfAttestedOnly = true;

  /// Mindestalter für Gye/Community (Deutschland: 16, DSGVO Art. 8).
  static const int minGyeAge = 16;

  /// Conservative boundary for a year-only self-attestation. Requiring a
  /// 17-year difference prevents admission before the actual 16th birthday
  /// without collecting month or day, at the cost of up to one year's delay.
  static const int conservativeYearDifference = minGyeAge + 1;

  /// Geschätztes Alter aus Geburtsjahr (jahr-genau). null wenn unbekannt/unplausibel.
  static int? get ageEstimate {
    final y = Storage.birthYear;
    if (y <= 0) return null;
    final age = DateTime.now().year - y;
    if (age < 0 || age > 120) return null; // unplausibel → wie unbekannt
    return age;
  }

  /// Geburtsjahr fehlt oder ist unplausibel → UI muss erneut abfragen.
  static bool get needsBirthYear => ageEstimate == null;

  /// Unter Mindestalter? **Nur true** wenn Geburtsjahr gesetzt UND < 16.
  /// (Unbekanntes Alter blockiert nicht — die UI fragt vorher ab.)
  static bool get isUnderMinAge {
    final a = ageEstimate;
    return a != null && a < conservativeYearDifference;
  }

  /// Gye erlaubt? Die jahresgenaue Selbstauskunft passiert den konservativen
  /// Backstop erst bei 17 Jahren Differenz. Unbekannte/unplausible Werte
  /// werden abgelehnt.
  static bool get isGyeAllowed {
    final age = ageEstimate;
    return age != null && age >= conservativeYearDifference;
  }

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
