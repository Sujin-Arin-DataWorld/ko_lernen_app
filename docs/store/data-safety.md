# Data Safety — Play Console Form Answers

> Answers for Google Play "Data Safety" form + Apple "App Privacy" section.
> Source-of-truth for what Hangul Sori collects, shares, and stores.

---

## Summary

Hangul Sori is **anonymous-first**. The app runs fully without any account.
The only personal data we touch is when a user **opts in** to Google Sign-In for cloud backup of their learning progress.

We do **not**:
- Show ads (no ad-network SDKs).
- Share data with third parties for marketing.
- Sell data.
- Track users across other apps or websites.

---

## Play Console — Data collected

| Data Type | Collected? | Optional? | Shared? | Purpose | Encrypted in transit? |
|---|---|---|---|---|---|
| Email address | **Yes** | Yes (only with Google Sign-In opt-in) | No | Account management, cloud backup | Yes |
| User ID (Firebase UID) | **Yes** | No (anonymous UID auto-issued) | No | Authentication state | Yes |
| App activity — In-app actions (XP, streak, scenario progress, vocab SRS state, badges) | **Yes** | Yes (only synced when user enables cloud backup) | No | Sync progress across devices | Yes |
| App info & performance — Crash logs (Firebase Crashlytics, if enabled in build) | **Yes** | No | No | Diagnose crashes | Yes |
| Device or other IDs | No | — | — | — | — |
| Personal info (name, address, phone) | No | — | — | — | — |
| Financial info | No | — | — | — | — |
| Health & fitness | No | — | — | — | — |
| Messages, photos, videos, audio | No | — | — | — | — |
| Files & docs | No | — | — | — | — |
| Calendar, contacts | No | — | — | — | — |
| Location | No | — | — | — | — |
| Web browsing | No | — | — | — | — |
| Other | No | — | — | — | — |

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

- [ ] Is Firebase Crashlytics actually enabled in the release build? If not, remove that row.
- [ ] Is Firebase Analytics enabled? If yes, add "Analytics → App activity" row (and disclose "App functionality + analytics" purpose).
- [ ] Is AdMob in the release build? If yes, the entire "no ads / no tracking" framing must be revised — re-do this form.
