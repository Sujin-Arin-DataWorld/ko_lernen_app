# Task 4 report: iOS native release setup

## Status

Implemented the credential-free iOS native capability and dependency configuration requested by Task 4.

## Changed files

- `ios/Runner/Info.plist`
  - Display name is `Hangul Sori`.
  - Uses the exact `FIREBASE_ANALYTICS_COLLECTION_ENABLED=false` key.
  - Keeps Crashlytics disabled by default.
  - Disables Firebase Messaging auto-init by default.
  - Declares `remote-notification` background mode.
- `ios/Runner/RunnerDebug.entitlements`
  - APNs environment is `development`.
  - Sign in with Apple entitlement is `Default`.
- `ios/Runner/RunnerRelease.entitlements`
  - APNs environment is `production`.
  - Sign in with Apple entitlement is `Default`.
- `ios/Runner.xcodeproj/project.pbxproj`
  - Adds Push Notifications and Sign in with Apple target capabilities.
  - Maps Debug to `RunnerDebug.entitlements`.
  - Maps Profile and Release to `RunnerRelease.entitlements`.
  - Preserves `com.sujinarin.koLernenApp` and Flutter build-number macros.
- `ios/Podfile`
  - Uses the current Flutter CocoaPods template structure.
  - Sets iOS platform 13.0.
  - Keeps Flutter's standard plugin installation and post-install helpers.
  - Pins `GoogleMLKit/TextRecognitionKorean` to `~> 6.0.0`, compatible with locked `google_mlkit_text_recognition` 0.13.1.
- `docs/store/ios-external-setup.md`
  - Documents Firebase, the real Google service plist and reversed URL scheme, Apple App ID/team/profiles, Sign in with Apple, APNs `.p8`, RevenueCat, CocoaPods, builds, archive inspection, and physical-device testing.
  - Uses `set -euo pipefail`, required-variable guards, file checks, and extracted-value checks so missing required external values fail explicitly.

## Validation evidence

### Expected failing pre-change gate

The structural validation was run before implementation and failed for the intended missing requirements:

```text
Expected RED: display name; analytics key; messaging auto-init; background remote notification; missing ios/Runner/RunnerDebug.entitlements; missing ios/Runner/RunnerRelease.entitlements; missing ios/Podfile; missing docs/store/ios-external-setup.md; Push capability; Sign in with Apple capability; Debug entitlements setting; release entitlements setting
```

### Passing Windows structural gate

A fresh PowerShell validation completed with exit code 0 and checked:

- XML parsing for `Info.plist` and both entitlements files.
- Exact Info.plist key names and values.
- Development versus production APNs values and Sign in with Apple `Default`.
- Xcode target capability strings.
- Exactly one Debug entitlements mapping and two Profile/Release mappings.
- Exactly three Runner bundle-ID settings using `com.sujinarin.koLernenApp`.
- Preservation of `$(FLUTTER_BUILD_NUMBER)`.
- iOS 13.0 Podfile platform, Flutter helper calls, and the Korean ML Kit pod pin.
- Required external setup sections and fail-fast command variables.
- Absence of credential-like values in the native project files.

Result:

```text
Task 4 structural validation passed: 3 plists parsed; Info.plist, capabilities, 1 Debug + 2 production entitlement mappings, Podfile pin, bundle/version invariants, and setup gate documented.
```

`git diff --check` completed with exit code 0. Git emitted only existing Windows line-ending conversion warnings for the two modified tracked iOS files.

Ruby is unavailable in this Windows environment, so `ruby -c ios/Podfile` could not be executed.

## Self-review

- The changes are restricted to the six task implementation files plus this required report.
- No Apple development team, provisioning profile UUID, Firebase iOS options, `GoogleService-Info.plist`, Google client ID or URL scheme, APNs key, or RevenueCat API key was added.
- Debug, Profile, and Release use coherent capability/entitlement combinations.
- The existing bundle ID and Flutter version/build-number macros were not replaced.
- Entitlement files are referenced by Xcode but are not incorrectly added as copied resources.
- The Podfile follows the Flutter 3.44 SDK template present on this machine, with only the required active platform line and Korean OCR pod addition.
- The external guide distinguishes checked-in source validation from credentialed macOS build, signing, and device verification.

## Concerns and required macOS follow-up

- No iOS build, CocoaPods resolution, Xcode project load, code signing, archive, or device test was claimed or attempted on Windows.
- On macOS, run `flutter pub get`, `pod install --repo-update`, the documented `xcodebuild -showBuildSettings` checks, an unsigned Debug build, and a signed Release IPA/archive with real external configuration.
- Confirm `Podfile.lock` resolves `GoogleMLKit/TextRecognitionKorean`, inspect final signed entitlements, and test push delivery, Google sign-in, Sign in with Apple, and RevenueCat sandbox purchases on a physical device.
- The real Apple team and profiles, Firebase plist and reversed URL scheme, APNs `.p8`, and RevenueCat public Apple SDK key must be supplied by the account owner through the documented process.

## Fix round 1: Firebase plist ignore enforcement

Reviewer feedback identified that the guide required `GoogleService-Info.plist` to remain uncommitted but the repository did not ignore its generated path.

- Added the exact repository-root rule `/ios/Runner/GoogleService-Info.plist` to `.gitignore`.
- Added `git check-ignore -q ios/Runner/GoogleService-Info.plist` to the fail-fast Firebase setup gate before the plist is generated.
- Verified the rule without creating the credential file:

```text
.gitignore:87:/ios/Runner/GoogleService-Info.plist	ios/Runner/GoogleService-Info.plist
```

`git check-ignore -v ios/Runner/GoogleService-Info.plist` exited 0 while the file remained absent.
