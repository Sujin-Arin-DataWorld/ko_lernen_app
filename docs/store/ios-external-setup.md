# iOS external release setup

The checked-in iOS project is intentionally credential-free. Its production bundle identifier is exactly:

```text
com.sujinarin.koLernenApp
```

Do not replace it with a lowercase variant. Do not commit an Apple team ID, provisioning profile UUID, `GoogleService-Info.plist`, Google client ID or reversed-client-ID URL scheme, APNs private key, or RevenueCat API key.

The source project declares Push Notifications and Sign in with Apple. Debug uses the APNs `development` entitlement; Profile and Release use `production`.

`dart run tool/verify_ios_firebase_config.dart` is a checked-in release gate.
It intentionally exits with code 1 in a clean checkout until the authorized
release operator has generated the iOS Firebase configuration locally, kept
`GoogleService-Info.plist` out of Git, and enabled its Runner target
membership. Do not weaken or bypass this failure on Windows or by committing
the generated plist.

## 1. Register the Firebase iOS app

Use the existing Firebase project and register the exact case-sensitive bundle
ID above before generating local configuration. If the Firebase iOS app is not
yet registered, create it in the Firebase Console or with the Firebase CLI; if
it already exists, select that existing app. Then, from a macOS release
workstation, use FlutterFire to generate the local iOS option:

```bash
set -euo pipefail

: "${FIREBASE_PROJECT_ID:?Set FIREBASE_PROJECT_ID to the existing Firebase project ID}"
test -f pubspec.yaml
command -v flutterfire >/dev/null
git check-ignore -q ios/Runner/GoogleService-Info.plist

flutterfire configure --project "$FIREBASE_PROJECT_ID" --platforms ios
test -s ios/Runner/GoogleService-Info.plist
plutil -lint ios/Runner/GoogleService-Info.plist
export REVERSED_CLIENT_ID="$(plutil -extract REVERSED_CLIENT_ID raw ios/Runner/GoogleService-Info.plist)"
test -n "$REVERSED_CLIENT_ID"
```

Review the generated `lib/firebase_options.dart` before any macOS archive: its
`TargetPlatform.iOS` branch must return a generated `ios` Firebase option. The
review must not copy generated values into source, a ticket, or a build log.
Keep the generated `ios/Runner/GoogleService-Info.plist` local and ignored;
never add it to a commit.

Open `ios/Runner.xcworkspace` in Xcode. Add the real `ios/Runner/GoogleService-Info.plist` to the `Runner` group with “Copy items if needed” disabled and `Runner` target membership enabled. Under Runner > Info > URL Types, add one URL scheme whose value is the extracted `$REVERSED_CLIENT_ID`. This is the reversed Google client URL scheme, not the OAuth client ID itself.

After those Xcode changes, these checks must succeed:

```bash
set -euo pipefail
test -s ios/Runner/GoogleService-Info.plist
grep -Fq 'GoogleService-Info.plist' ios/Runner.xcodeproj/project.pbxproj
grep -Fq "$(plutil -extract REVERSED_CLIENT_ID raw ios/Runner/GoogleService-Info.plist)" \
  ios/Runner/Info.plist
dart run tool/verify_ios_firebase_config.dart
```

Enable the required providers in Firebase Console > Authentication > Sign-in method:

- Google.
- Apple. Follow Firebase's Apple-provider flow, including the Service ID, Apple Team ID, Sign in with Apple private key, and key ID. Register `https://FIREBASE_PROJECT_ID.firebaseapp.com/__/auth/handler` as the return URL and configure Apple's private email relay if Firebase will email relay addresses.

Official references: [add Firebase to an Apple project](https://firebase.google.com/docs/ios/setup), [Google sign-in URL scheme](https://firebase.google.com/docs/auth/ios/firebaseui), and [Firebase Sign in with Apple](https://firebase.google.com/docs/auth/ios/apple).

## 2. Configure the Apple App ID, signing, and profiles

In Apple Developer > Certificates, Identifiers & Profiles:

1. Create or select the explicit App ID `com.sujinarin.koLernenApp`.
2. Enable Push Notifications.
3. Enable Sign in with Apple and configure this App ID as the primary App ID unless it must join an existing Sign in with Apple group.
4. Regenerate any profiles invalidated by the capability changes. Create/install an iOS App Development profile for Debug and an App Store distribution profile for Profile/Release, or let Xcode automatic signing regenerate them.
5. In Xcode, select Runner > Signing & Capabilities and choose the real team for Debug, Profile, and Release. Confirm Push Notifications and Sign in with Apple appear. Keep Sign in with Apple set to `Default`.

No `DEVELOPMENT_TEAM` is checked in because only the Apple account owner can supply the real team.

Run these source and resolved-build-setting checks on macOS:

```bash
set -euo pipefail

: "${APPLE_TEAM_ID:?Set APPLE_TEAM_ID to the real 10-character Apple Team ID}"
test "${#APPLE_TEAM_ID}" -eq 10

test "$(plutil -extract aps-environment raw ios/Runner/RunnerDebug.entitlements)" = development
test "$(plutil -extract aps-environment raw ios/Runner/RunnerRelease.entitlements)" = production
test "$(/usr/libexec/PlistBuddy -c 'Print :com.apple.developer.applesignin:0' ios/Runner/RunnerDebug.entitlements)" = Default
test "$(/usr/libexec/PlistBuddy -c 'Print :com.apple.developer.applesignin:0' ios/Runner/RunnerRelease.entitlements)" = Default

for configuration in Debug Profile Release; do
  settings="$(mktemp)"
  xcodebuild \
    -workspace ios/Runner.xcworkspace \
    -scheme Runner \
    -configuration "$configuration" \
    -showBuildSettings > "$settings"
  grep -Fq "PRODUCT_BUNDLE_IDENTIFIER = com.sujinarin.koLernenApp" "$settings"
  grep -Fq "DEVELOPMENT_TEAM = $APPLE_TEAM_ID" "$settings"
  if [ "$configuration" = Debug ]; then
    grep -Fq "CODE_SIGN_ENTITLEMENTS = Runner/RunnerDebug.entitlements" "$settings"
  else
    grep -Fq "CODE_SIGN_ENTITLEMENTS = Runner/RunnerRelease.entitlements" "$settings"
  fi
  rm "$settings"
done
```

Official references: [enable App ID capabilities](https://developer.apple.com/help/account/identifiers/enable-app-capabilities/) and [configure Sign in with Apple](https://developer.apple.com/documentation/xcode/configuring-sign-in-with-apple).

## 3. Create and upload the APNs key

In Apple Developer > Keys, create an Apple Push Notification service authentication key for the correct team and download its `.p8` file once. Record its Key ID and the Apple Team ID. Store the key outside the repository.

In Firebase Console > Project settings > Cloud Messaging > the iOS configuration for `com.sujinarin.koLernenApp`, upload the `.p8` key and enter the matching Key ID and Team ID. Apple states an APNs signing key works with both development and production; Firebase may show separate upload slots.

Before upload, fail fast on missing or mismatched local inputs:

```bash
set -euo pipefail

: "${APNS_KEY_PATH:?Set APNS_KEY_PATH to the downloaded .p8 file}"
: "${APNS_KEY_ID:?Set APNS_KEY_ID to the Apple key ID}"
: "${APPLE_TEAM_ID:?Set APPLE_TEAM_ID to the Apple Team ID}"
test -s "$APNS_KEY_PATH"
test "${APNS_KEY_PATH##*.}" = p8
test -n "$APNS_KEY_ID"
test "${#APPLE_TEAM_ID}" -eq 10
grep -Fq 'BEGIN PRIVATE KEY' "$APNS_KEY_PATH"
```

Never print the private key or add it to source control. See [Firebase Cloud Messaging for Apple platforms](https://firebase.google.com/docs/cloud-messaging/ios/get-started) and [Apple APNs token authentication](https://developer.apple.com/help/account/capabilities/communicate-with-apns-using-authentication-tokens/).

## 4. Configure RevenueCat

In App Store Connect, create the app with bundle ID `com.sujinarin.koLernenApp`, finish agreements/tax/banking, and create the subscription products. In RevenueCat:

1. Create/select the project and add an Apple App Store app with the same bundle ID.
2. Connect App Store Connect credentials.
3. Import the products, create the `premium` entitlement, attach products, and create the current offering.
4. Copy the app-specific **public Apple SDK key** from Project Settings > API keys. Never use a RevenueCat secret key in the app.

The app expects the key through `RC_IOS_KEY`. Verify and pass it without committing it:

```bash
set -euo pipefail

: "${RC_IOS_KEY:?Set RC_IOS_KEY to the RevenueCat public Apple SDK key}"
case "$RC_IOS_KEY" in
  appl_*) ;;
  *) echo 'RC_IOS_KEY is not an Apple public SDK key (expected appl_ prefix)' >&2; exit 1 ;;
esac

flutter build ipa --release \
  --dart-define="RC_IOS_KEY=$RC_IOS_KEY"
```

See RevenueCat's [SDK quickstart](https://www.revenuecat.com/docs/getting-started/quickstart) and [SDK configuration](https://www.revenuecat.com/docs/getting-started/configuring-sdk).

## 5. macOS dependency and archive gate

Flutter 3.44 uses Swift Package Manager where supported and falls back to CocoaPods for plugins that do not support it. The locked `google_mlkit_text_recognition` 0.13.1 plugin needs `GoogleMLKit/TextRecognitionKorean ~> 6.0.0`, which is pinned in `ios/Podfile`.

On a clean macOS checkout with the real external values configured:

```bash
set -euo pipefail

command -v flutter >/dev/null
command -v pod >/dev/null
command -v xcodebuild >/dev/null
test -s ios/Runner/GoogleService-Info.plist
: "${APPLE_TEAM_ID:?Set APPLE_TEAM_ID}"
: "${RC_IOS_KEY:?Set RC_IOS_KEY}"

flutter pub get
(
  cd ios
  pod install --repo-update
)
test -f ios/Podfile.lock
grep -Fq 'GoogleMLKit/TextRecognitionKorean' ios/Podfile.lock

flutter build ios --debug --no-codesign
flutter build ipa --release --dart-define="RC_IOS_KEY=$RC_IOS_KEY"
```

Open the generated archive in Xcode Organizer and inspect the signed app before upload:

```bash
set -euo pipefail

: "${ARCHIVED_APP:?Set ARCHIVED_APP to the absolute path of Runner.app inside the archive}"
test -d "$ARCHIVED_APP"
codesign -d --entitlements :- "$ARCHIVED_APP" > /tmp/hangul-sori-entitlements.plist
test "$(plutil -extract application-identifier raw /tmp/hangul-sori-entitlements.plist | sed 's/^[^.]*\.//')" = com.sujinarin.koLernenApp
test "$(plutil -extract aps-environment raw /tmp/hangul-sori-entitlements.plist)" = production
test "$(/usr/libexec/PlistBuddy -c 'Print :com.apple.developer.applesignin:0' /tmp/hangul-sori-entitlements.plist)" = Default
```

These build, signing, notification-delivery, Apple-authentication, Google-authentication, and purchase checks require macOS, Xcode, real credentials, and physical-device/sandbox testing. They cannot be completed on Windows.
