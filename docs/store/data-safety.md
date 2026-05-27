# Data Safety — Play Console Form Answers

> Answers for Google Play "Data Safety" form + Apple "App Privacy" section.
> Source-of-truth for what Hangul Sori collects, shares, and stores.
> **Last verified: 2026-05-27** — siehe Build-Audit unten.

---

## SDK-Audit (v1.0.0 Release-Build)

| SDK | Status in pubspec.yaml | Im Release-Build aktiv? |
|---|---|---|
| `firebase_core` ^3.6.0 | Aktiv | ✅ ja (Initialisierung in `main.dart::_initFirebase`) |
| `firebase_auth` ^5.3.1 | Aktiv | ✅ ja (anonymes Login + optionales Google-Link) |
| `cloud_firestore` ^5.4.4 | Aktiv | ✅ ja (Cloud-Sync nur nach Google-Link opt-in) |
| `firebase_remote_config` ^5.1.4 | Aktiv | ✅ ja (Palette Kill-Switch) |
| `firebase_crashlytics` ^4.3.10 | Aktiv | ✅ ja (Plugin in Gradle, `FlutterError.onError` + `PlatformDispatcher.onError` Hook) |
| `firebase_analytics` ^11.6.0 | Aktiv | ✅ ja (Auto-Collection durch SDK-Linking; keine expliziten Events instrumentiert) |
| `google_sign_in` ^6.2.1 | Aktiv | ✅ ja (optional, nur bei expliziter User-Aktion) |
| `google_mobile_ads` 5.2.0 | **Auskommentiert** in pubspec.yaml | ❌ nein — `ad_service.dart` ist Stub, Android-Manifest **und** iOS-Info.plist (`GADApplicationIdentifier` + `SKAdNetworkItems`) bereinigt (2026-05-27) |

**Konsequenz:** "Keine Werbung / keine cross-app Tracking"-Aussage ist konsistent.
Für die spätere Reaktivierung in v1.1+ siehe `docs/store/target-audience-and-ads.md` Part 2.
Crashlytics + Analytics sind aktiv → diese MÜSSEN deklariert werden (siehe Tabelle unten).

---

## Summary

Hangul Sori ist **anonymous-first**. Die App läuft komplett ohne Account.
Persönlich-identifizierende Daten (Name, E-Mail) berühren wir nur, wenn der
User **explizit** Google Sign-In zur Cloud-Sicherung aktiviert.

Wir **nicht**:
- Anzeigen schalten (kein Ad-SDK im Release-Build).
- Daten zu Marketing-Zwecken mit Dritten teilen.
- Daten verkaufen.
- User über andere Apps oder Websites tracken (kein ATT, kein Cross-App ID-Linking).

Wir **schon**:
- Anonyme Crash-Reports an Firebase Crashlytics senden (Stack Trace, Geräte-Modell, OS-Version, App-Version).
- Anonyme App-Nutzung an Firebase Analytics melden (Session-Dauer, App-Start, Screen-Auto-Logging — keine expliziten Custom Events).

---

## Play Console — Data collected

| Data Type | Collected? | Optional? | Shared? | Purpose | Encrypted in transit? |
|---|---|---|---|---|---|
| **Personal info** — Email address | **Yes** | Yes (nur bei Google-Sign-In opt-in) | No | Account-Management, Cloud-Backup | Yes |
| **Personal info** — Name (display name) | **Yes** | Yes (nur bei Google-Sign-In opt-in) | No | Begrüßung im UI | Yes |
| **Personal info** — User ID (Firebase UID) | **Yes** | No (anonyme UID wird automatisch ausgegeben) | No | Authentifizierungsstatus, Sync-Anker | Yes |
| **App activity** — In-app actions (XP, Streak, Szenario-Fortschritt, Vokabel-SRS-State, Badges) | **Yes** | Yes (nur synchronisiert wenn User Cloud-Backup aktiviert) | No | Lernfortschritt geräteübergreifend synchron halten | Yes |
| **App activity** — Other actions (Analytics auto-events: app_open, screen_view, session_start) | **Yes** | No | No | App-Performance, Nutzungsverständnis (Analytics) | Yes |
| **App info & performance** — Crash logs (Firebase Crashlytics) | **Yes** | No | No | Crashes diagnostizieren | Yes |
| **App info & performance** — Diagnostics (Geräte-Modell, OS-Version, App-Version, Speicherzustand) | **Yes** | No | No | Crash-Kontext | Yes |
| **Device or other IDs** — Firebase Installation ID + Android Advertising ID (Analytics) | **Yes** | No | No | Analytics-Aggregation (nicht zur User-Identifizierung gegenüber Dritten) | Yes |
| Financial info | No | — | — | — | — |
| Health & fitness | No | — | — | — | — |
| Messages, photos, videos, audio | No | — | — | — | — |
| Files & docs | No | — | — | — | — |
| Calendar, contacts | No | — | — | — | — |
| Location | No | — | — | — | — |
| Web browsing | No | — | — | — | — |
| Other | No | — | — | — | — |

> Hinweis zur Play-Console-UI: "Device or other IDs" → wähle "Wird erhoben" + "Wird NICHT geteilt" + Zweck "Analytics" + "App-Funktionalität". Firebase Analytics linkt diese ID an den Firebase-Account, gibt sie aber nicht an Werbenetzwerke weiter, da kein AdMob im Build ist.

---

## Security practices

- **Data encrypted in transit**: Yes — Firebase uses TLS for all traffic.
- **Users can request deletion**: Yes — sign-out + "Wiederherstellen" / "Restore" toggle clears local. For full account deletion, users can email the team or revoke Google access from their Google account.
- **Independent security review**: No (small team, pre-launch).
- **Complies with Families Policy**: N/A (not targeted at children under 13).

---

## Apple App Privacy — Same data, Apple wording

**Data Linked to You** (when user signs in with Google):
- Contact Info: Email Address
- Identifiers: User ID
- Usage Data: Product Interaction (learning progress)

**Data Not Linked to You** (anonymous default):
- Identifiers: anonymous Firebase UID

**Tracking**: No (we do not use App Tracking Transparency framework — no cross-app tracking).

---

## What to tell users (Privacy Policy link)

`https://hangul-sori.com/privacy.html`

The HTML privacy page is already prepared at `docs/privacy.html` and served via the `hangul-sori.com` GitHub Pages CNAME.

---

## Open questions for Jin (before submission)

- [x] **Firebase Crashlytics aktiv?** — JA. `firebase_crashlytics ^4.3.10` in pubspec, Gradle-Plugin `com.google.firebase.crashlytics` 3.0.1, Hooks in `main.dart::_initFirebase` (FlutterError + PlatformDispatcher). Row im Formular eingetragen.
- [x] **Firebase Analytics aktiv?** — JA. `firebase_analytics ^11.6.0` in pubspec, Auto-Collection durch SDK-Linking (kein expliziter Custom-Event-Code, aber Standard-Events wie `app_open`, `screen_view`, `session_start` werden automatisch erfasst). Zwei zusätzliche Zeilen im Formular: "App activity → Other actions" + "Device or other IDs".
- [x] **AdMob im Release-Build?** — NEIN. `google_mobile_ads` in pubspec auskommentiert, `ad_service.dart` ist Stub, AdMob-Manifest-Eintrag am 2026-05-27 entfernt. "Keine Werbung"-Aussage konsistent.

## Account Deletion (Play-Policy ab Mai 2024)

Google verlangt seit Mai 2024, dass jede App mit User-Accounts einen **App-internen** Lösch-Weg anbietet (nicht nur per E-Mail). Aktuell:

- ✅ **In-App Sign-Out**: Settings → "Aus Google-Account ausloggen" → wieder anonym, lokale Daten bleiben.
- ⚠️ **In-App Account-Delete (Firebase-User + Firestore-Doc löschen)**: aktuell nicht implementiert. Workaround: User schickt E-Mail an `hello@hangul-sori.com` und Jin löscht manuell.
- 🟡 **Empfehlung für v1.0.1**: `AuthService.deleteAccount()` hinzufügen → `user.delete()` + Firestore-Doc-Löschung. Bis dahin in der Privacy-Policy klar dokumentieren.
