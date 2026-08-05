# iOS·iPad App Store Readiness Design

**Status:** Local iOS/iPad readiness implementation complete; macOS/Xcode and Apple owner gates remain pending. The global analyzer is currently non-green only because of an unrelated concurrent `vocab_pack_screen.dart` unused-element warning; the scoped iOS readiness analyzer passed clean.

## Goal

Make Hangul Sori ready for a truthful iOS/iPad App Store submission workflow: current product-page copy, iPad screenshot requirements, local static release checks, localized permission explanations, and an app-visible build version. Keep Apple, Firebase, APNs, RevenueCat, and signing credentials out of the repository.

## Evidence and constraints

- The Runner target already supports iPhone and iPad (`TARGETED_DEVICE_FAMILY = "1,2"`), iOS 13+, all iPad orientations, indirect input, complete iPad icons, and Flutter tablet layouts.
- The source version is `2.0.5+11`; the Settings screen instead displays a stale hard-coded `2.0.3`.
- Current source facts are 558 vocabulary rows, 64 nonempty pack IDs, 39 scenarios, and 17 special quests.
- `dart run tool/verify_ios_firebase_config.dart` must continue failing in this credential-free Windows checkout until a macOS release operator configures iOS Firebase. Do not commit `GoogleService-Info.plist`, team identifiers, provisioning profiles, APNs keys, or RevenueCat keys.
- Apple requires iPad screenshots for an iPad app. The submission pack uses real 13-inch iPad simulator/device captures only; generated mockups and web screenshots are not submission screenshots.
- Apple requires an accurate App Privacy response and a privacy-policy URL. The repository worksheet remains an owner-reviewed worksheet, not a claimed console export. The final archive's Xcode privacy report decides whether an app-owned `PrivacyInfo.xcprivacy` is necessary; no guessed manifest is added here.

## Chosen approach

Create an **iOS Store Readiness Pack** in four bounded layers:

1. **Runtime correctness.** Replace the Settings hard-coded version with a small injected `AppVersionReader` backed by `package_info_plus`. It renders `version (build)` when native package metadata is available and a neutral unavailable state if metadata cannot be read.
2. **Native iPad contract.** Add localized German and English `InfoPlist.strings` permission explanations, register them as Runner resources, and add a static executable/test that checks target family, iPad orientations, icons, permission strings, bundle identifier, deployment target, and resource membership without requiring Xcode.
3. **App Store materials.** Refresh DE/EN listing facts and create one versioned App Store Connect handoff with product-page fields, review notes, App Privacy handoff, and real-capture requirements. Update the existing shot list to prioritize the personal Hanok world and explicitly include 13-inch iPad portrait and landscape captures.
4. **Capture validation and external handoff.** Add a dependency-free PNG checker for one-to-ten screenshots, alpha-free files, and accepted iPhone/iPad target dimensions. Extend the macOS runbook with the exact archive, privacy-report, TestFlight, and physical iPad gates. It remains impossible to produce a signed `.ipa` or prove iPad behavior on this Windows host.

## File boundaries

| File | Responsibility |
| --- | --- |
| `lib/services/app_version_service.dart` | Native package-version formatting and failure-safe reader interface. |
| `lib/screens/settings_screen.dart` | Asynchronously show the app's actual native version; no release number is duplicated in UI source. |
| `ios/Runner/{de,en}.lproj/InfoPlist.strings` | Localized camera/photo permission purpose strings only. |
| `ios/Runner.xcodeproj/project.pbxproj` | Register the localized strings as Runner resources; no signing settings or secrets. |
| `tool/verify_ios_store_contract.dart` | Credential-free static inspection of iPad/iOS project invariants. |
| `test/app_version_service_test.dart`, `test/ios_store_contract_test.dart`, `test/widgets/settings_screen_test.dart` | Regression coverage for version formatting, native static contract, and injected Settings display. |
| `tool/check_app_store_screenshots.py`, `tool/test_check_app_store_screenshots.py` | Validate real App Store screenshot folders without Pillow or a macOS dependency. |
| `docs/store/listing-{de,en}.md` | Current, copy-ready DE/EN product-page metadata. |
| `docs/store/app-store-connect-v2.0.5.md` | Console fields, review note, privacy handoff, macOS/archive gate, and ownership boundaries. |
| `docs/store/screenshot-shotlist.md` | Real iPhone/iPad capture order, data state, captions, and accepted pixels. |
| `docs/store/README.md` | Navigation to the new iOS submission material. |

## User flow and data flow

`pubspec.yaml` feeds native `CFBundleShortVersionString` and `CFBundleVersion` during an iOS archive. `PackageInfo` reads those values at runtime, and `SettingsScreen` displays the formatted value without a second version source. The static contract reads committed iOS text files only; it never accesses Firebase, Apple, or a signing key.

On macOS, the release operator first passes the existing iOS Firebase gate, archives the app with the public RevenueCat iOS key supplied only as a `--dart-define`, checks the final Xcode privacy report, then captures the running signed/simulator app. The PNG checker validates those capture files before App Store Connect upload. App Store Connect, TestFlight, and device testing are explicit external gates, not completion claims from this repository.

## Acceptance criteria

- Settings shows a supplied native package version as `2.0.5 (11)` and does not surface a stale literal.
- Both German and English purpose strings exist and are valid Runner resources.
- The static iOS checker rejects a missing iPad target, iPad orientation, iPad icon, permission key, or strings resource; it passes the checked-in credential-free project.
- Current DE/EN copy consistently uses 558 vocabulary rows, 64 packs, 39 scenarios, and 17 quests.
- Screenshot material requires real, alpha-free 13-inch iPad captures in accepted Apple dimensions and distinguishes them from working mockups.
- Static Dart/Python checks pass on Windows. The result explicitly leaves iOS Firebase setup, signing, archive/IPA, privacy report, TestFlight, App Store Connect, and physical iPad verification for the authorized macOS operator.

## Non-goals

- Do not add a speculative `PrivacyInfo.xcprivacy`; only Xcode's final privacy report determines its required-reason declarations.
- Do not create, upload, or claim a signed `.ipa`/TestFlight build from Windows.
- Do not change Firebase, Apple Developer, App Store Connect, APNs, RevenueCat, privacy policy hosting, or legal operator data.
- Do not fabricate App Store screenshots from web captures or generated art.
