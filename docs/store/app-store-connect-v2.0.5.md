# App Store Connect Handoff — Hangul Sori 2.0.5 (13)

This is the single operational handoff for the iOS submission. It prepares the
repo-owned material but does not claim that Apple credentials, a signed archive,
TestFlight, hosting, or review have been completed.

## Release identity

| Field | Value |
|---|---|
| Bundle ID | `com.sujinarin.koLernenApp` |
| Version | `2.0.5` |
| Build | `11` |
| Primary category | Education (recommended; select in App Store Connect) |
| English listing | [listing-en.md](listing-en.md) |
| German listing | [listing-de.md](listing-de.md) |

## Store URLs and contact

Enter these only after you **verify live hosting before submission**:

| Field | Proposed value | Required confirmation |
|---|---|---|
| Support URL | `https://hangul-sori.com/support.html` | Verify live hosting before submission. |
| Support contact | `hello@hangul-sori.com` | Verify that the mailbox receives support requests before submission. |
| Privacy Policy URL | `https://hangul-sori.com/privacy.html` | Verify live hosting before submission. |
| Account deletion URL | `https://hangul-sori.com/account-deletion.html` | Verify live hosting before submission. |

Use [data-safety.md](data-safety.md) to complete the Apple App Privacy
questionnaire. It is a separate worksheet from Google Play Data Safety and must
be reconciled with the final archive, enabled SDKs, and live services.

Do not select an age rating from this document. The release owner must complete
Apple's current age-rating questionnaire from the final build and its actual
content.

## App Review notes and guest path

Paste or adapt this note only after confirming it on the signed archive:

> Hangul Sori can be explored as a guest. Start the app, choose a level if
> prompted, and open the personal Hanok map. Select the Sarangbang to launch
> the app's current recommended next study. The Sarangbang does not use a
> separate lesson catalog. Optional Snap-and-Learn camera/photo access is used
> only when the reviewer chooses that feature; learning content is otherwise
> available without it.

Before sending the app for review, repeat this path on a clean device with no
developer data and verify that any optional permission prompt matches the final
localized text.

## Screenshot submission

Follow [screenshot-shotlist.md](screenshot-shotlist.md). Capture from the final
candidate on a real iOS simulator or device; do not submit app, web, or AI
mockups. For iPad support, capture both the 13-inch landscape `2752 × 2064`
personal Hanok map and portrait `2064 × 2752` flow before upload. Validate PNG
folders locally with `tool/check_app_store_screenshots.py`.

## macOS-only archive and TestFlight gates

1. On an authorized macOS workstation, complete
   [ios-external-setup.md](ios-external-setup.md) without committing secrets:
   Apple Team/signing, `GoogleService-Info.plist`, Firebase iOS options, APNs,
   URL scheme, and any approved purchase configuration.
2. Run `dart run tool/verify_ios_store_contract.dart` and
   `dart run tool/verify_ios_firebase_config.dart`. The Firebase checker is
   expected to fail until the external configuration is complete.
3. Archive the `Runner` target in Xcode with the final bundle identifier and
   version/build. Inspect the archive's privacy report and resolve any required
   privacy-manifest or SDK disclosures using the actual archive, not guesses.
4. Install through TestFlight on an iPad and an iPhone. Verify guest review
   path, navigation, tablet rotations, text scaling, optional camera/photo
   permissions, account deletion, and any configured account or purchase flow.
5. Reconcile App Privacy, URLs, screenshots, review notes, age rating, and
   export-compliance answers in App Store Connect, then submit for review.

## Submission evidence to retain

- Xcode archive validation and upload record.
- TestFlight installation evidence for iPhone and iPad.
- Final screenshot folders and validator output.
- Current Apple App Privacy answers and the final archive's privacy report.
- Live checks for support, privacy, and account-deletion destinations.
