# Store Submission Pack — Hangul Sori

This folder separates copy-ready store material from external proof that must
be completed by the release owner.

## Apple App Store Connect: start here

Read [app-store-connect-v2.0.5.md](app-store-connect-v2.0.5.md) for the single
handoff for `2.0.5 (13)`: identifiers, review path, iPad screenshots, and the
Mac-only archive/TestFlight gates.

[APPSTORE_UPLOAD_KO.md](APPSTORE_UPLOAD_KO.md) (Korean) is the operator's
running order for the same submission — Bundle ID registration, app-record
creation, the one-command `.ipa` build (`scripts/build_ios_ipa.sh`), upload,
and TestFlight. It sequences the documents below rather than replacing them.

### Copy-ready source

| File | Use it for |
|---|---|
| [listing-de.md](listing-de.md) | German name, subtitle, description, keywords, and What's New copy |
| [listing-en.md](listing-en.md) | English name, subtitle, description, keywords, and What's New copy |
| [screenshot-shotlist.md](screenshot-shotlist.md) | Exact real-iOS capture brief and screenshot folder contract |

### External proof required before submission

| File | Owner action |
|---|---|
| [data-safety.md](data-safety.md) | Complete the separate Apple App Privacy worksheet from the final archive and live services |
| [ios-external-setup.md](ios-external-setup.md) | Configure Apple signing, Firebase, APNs, URL scheme, and any approved purchase configuration on macOS |
| [screenshot-shotlist.md](screenshot-shotlist.md) | Capture real iPhone and iPad screenshots; no web or AI substitutes |

Privacy, support, deletion, signing, device testing, TestFlight, and App
Review completion are external evidence, not claims made true by these source
files.

## Google Play Console

Use the localized listing files above with the Android-specific documents:

- [data-safety.md](data-safety.md) for the Play Data Safety worksheet.
- [closed-testing-checklist-v2.md](closed-testing-checklist-v2.md) for internal
  or closed-testing operational proof.
- [release-notes-v1.md](release-notes-v1.md) and
  [release-notes-v2.md](release-notes-v2.md) for release-note history.

## Public pages to verify live before either submission

- [Privacy page](../privacy.html)
- [Account-deletion page](../account-deletion.html)
- [Support page](../support.html)
- Support contact: `hello@hangul-sori.com`

The repository copies do not prove that these pages are publicly hosted or
legally complete. The release owner must verify their live URLs and contents.
