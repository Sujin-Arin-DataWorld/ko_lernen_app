# Store Submission Pack — Hangul Sori

Materials for Google Play Console and Apple App Store Connect.

Status: **pre-launch**. Target: Android and iOS.

Privacy answers in this repository are release-owner review worksheets, not
verified console exports. Google Play Data Safety and Apple App Privacy use
different categories and must be reviewed separately in `data-safety.md`
against the final signed builds and live service configuration.

## Google Play Console

- [ ] Privacy Policy URL entered:
  `https://hangul-sori.com/privacy.html`
- [ ] Account-deletion URL entered:
  `https://hangul-sori.com/account-deletion.html`
- [ ] App category and content-rating questionnaire completed from the actual
  release features; do not rely on a guessed rating.
- [ ] Google Play matrix in `data-safety.md` reconciled with the final signed
  Android manifest, current Firebase/RevenueCat disclosures, and live console.
- [ ] Closed-testing eligibility, required tester count, opt-in continuity, and
  testing duration verified in the Play Console under the current Google rule.
- [ ] Feature graphic and screenshots checked against the current app UI.
- [ ] Play App Signing and the intended upload key confirmed.

## Apple App Store Connect

- [ ] Privacy Policy URL entered:
  `https://hangul-sori.com/privacy.html`
- [ ] Apple App Privacy worksheet in `data-safety.md` reviewed separately; do
  not copy Play answers field-for-field.
- [ ] In-app account deletion, Apple reauthentication/revocation, subscription
  management, and purchase restore verified on a signed iOS build.
- [ ] App category, age-rating questionnaire, screenshots, keywords, and
  description reviewed in App Store Connect.
- [ ] Apple team, signing, entitlements, APNs, Firebase plist, and RevenueCat
  iOS configuration verified on the release archive.

## Both stores

- [ ] Android and iOS release candidates exercised on real devices.
- [ ] Public English, German, and Korean tabs in `privacy.html` and
  `account-deletion.html` reviewed.
- [ ] Legal controller/address, live service regions, retention settings, and
  RevenueCat integration blockers in `data-safety.md` resolved by the owner.
- [ ] Subscriptions are described as requiring separate store cancellation;
  account deletion is not described as cancelling billing.
- [ ] Release notes and support contact
  `hello@hangul-sori.com` verified.

## Files

| File | Purpose |
|---|---|
| `listing-de.md` | German store copy |
| `listing-en.md` | English store copy and keywords |
| `data-safety.md` | Separate Play and Apple privacy worksheets plus external blockers |
| `closed-testing-checklist-v2.md` | Android closed-testing operational checklist |
| `ios-external-setup.md` | iOS external signing/configuration checklist |
| `subscription-setup-runbook.md` | Store and RevenueCat setup |
| `screenshot-shotlist.md` | Required screenshot scenes and sizes |
| `release-notes-v1.md`, `release-notes-v2.md` | Release-note drafts |

Public pages:

- `../privacy.html`
- `../account-deletion.html`
