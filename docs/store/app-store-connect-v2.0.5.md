# App Store Connect Handoff — Hangul Sori 2.0.5 (14)

This is the single operational handoff for the iOS submission. It prepares the
repo-owned material but does not claim that Apple credentials, a signed archive,
TestFlight, hosting, or review have been completed.

## Release identity

| Field | Value |
|---|---|
| Bundle ID | `com.sujinarin.koLernenApp` |
| Version | `2.0.5` |
| Build | `14` |
| Primary category | Education (recommended; select in App Store Connect) |
| English listing | [listing-en.md](listing-en.md) |
| German listing | [listing-de.md](listing-de.md) |

## Store URLs and contact

Enter these only after you **verify live hosting before submission**:

| Field | Proposed value | Required confirmation |
|---|---|---|
| Support URL | `https://hangul-sori.com/support` | Verify live hosting before submission. |
| Support contact | `hello@hangul-sori.com` | Verify that the mailbox receives support requests before submission. |
| Privacy Policy URL | `https://hangul-sori.com/privacy` | Verify live hosting before submission. |
| Account deletion URL | `https://hangul-sori.com/account-deletion` | Verify live hosting before submission. |

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

## Storefront composition

Keep the first screenshots practical. They should show what someone can learn
and how the Hanok makes progress visible, not a sequence of similar menus.
Capture the final iOS build in both German and English before choosing the
localized sets.

| Order | Screen | German caption | English caption |
|---:|---|---|---|
| 1 | Personal Hanok map | `Dein Hanok wächst mit dir` | `Your hanok grows with you` |
| 2 | Sarangbang and today's study | `Heute im Sarangbang lernen` | `Study in the Sarangbang today` |
| 3 | Hangul lesson or vocabulary pack | `Koreanisch Schritt für Schritt` | `Korean step by step` |
| 4 | Everyday scenario | `Koreanisch für den Alltag` | `Korean for everyday life` |
| 5 | Quest reward or room furnishing | `Gestalte deinen Lernort` | `Make your learning place your own` |
| 6 | Progress view | `Dein Fortschritt auf einen Blick` | `See your progress at a glance` |

Use the same story for iPhone and iPad, but do not resize one device's image
for the other. The iPad set should begin with the landscape Hanok map.

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
   and URL scheme. The app no longer contains a purchase SDK or paid learning
   gates, so do not configure subscription products for this archive.
2. Run `dart run tool/verify_ios_store_contract.dart` and
   `dart run tool/verify_ios_firebase_config.dart`. The Firebase checker is
   expected to fail until the external configuration is complete.
3. Archive the `Runner` target in Xcode with the final bundle identifier and
   version/build. Inspect the archive's privacy report and resolve any required
   privacy-manifest or SDK disclosures using the actual archive, not guesses.
4. Install through TestFlight on an iPad and an iPhone. Verify guest review
   path, navigation, tablet rotations, text scaling, optional camera/photo
   permissions, and account deletion. Confirm that every learning pack opens
   without a purchase or subscription prompt.
5. Reconcile App Privacy, URLs, screenshots, review notes, age rating, and
   export-compliance answers in App Store Connect, then submit for review.

## Submission evidence to retain

- Xcode archive validation and upload record.
- TestFlight installation evidence for iPhone and iPad.
- Final screenshot folders and validator output.
- Current Apple App Privacy answers and the final archive's privacy report.
- Live checks for support, privacy, and account-deletion destinations.
