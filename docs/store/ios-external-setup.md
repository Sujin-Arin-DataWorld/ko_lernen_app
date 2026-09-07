# iOS external release setup

The checked-in iOS project intentionally contains the non-secret Firebase app
configuration and Apple team identifier required for Xcode Cloud clean-clone
archives. It does not contain the private signing or distribution credentials.
Its production bundle identifier is exactly:

```text
com.sujinarin.koLernenApp
```

Do not replace it with a lowercase variant. The current Apple team ID,
`GoogleService-Info.plist`, Google client ID, and reversed-client-ID URL scheme
are intentionally tracked non-secret identifiers; do not rotate or replace them
without release-owner approval. Never commit signing certificates, provisioning
profiles, App Store Connect API private keys, APNs private keys, service-account
keys, or RevenueCat secret keys.

The source project declares Push Notifications and Sign in with Apple. Debug uses the APNs `development` entitlement; Profile and Release use `production`.

`dart run tool/verify_ios_firebase_config.dart` is a checked-in release gate and
must pass in a clean checkout for the tracked static configuration. Passing it
does not prove Apple-team ownership, signing credentials, provisioning,
Firebase Console registration, or App Store Connect access; those remain
release-operator gates. Do not weaken or bypass the verifier on any platform.

Web Firebase, Auth-domain, and Web App Check provisioning is a separate
operator step in [the Web Firebase external setup runbook](web-firebase-external-setup.md).
Configure Android, iOS, and Web from the same authorized Firebase project with
FlutterFire; do not hand-copy identifiers between platform configurations.

## 1. Register the Firebase iOS app

Use the existing `ko-lernen-app` Firebase project and its already registered,
case-sensitive bundle ID above. The tracked configuration is the normal build
input. Verify it before every archive:

```bash
set -euo pipefail

test -f pubspec.yaml
git ls-files --error-unmatch ios/Runner/GoogleService-Info.plist >/dev/null
test -s ios/Runner/GoogleService-Info.plist
plutil -lint ios/Runner/GoogleService-Info.plist
test "$(plutil -extract PROJECT_ID raw ios/Runner/GoogleService-Info.plist)" = "ko-lernen-app"
test "$(plutil -extract BUNDLE_ID raw ios/Runner/GoogleService-Info.plist)" = "com.sujinarin.koLernenApp"
export REVERSED_CLIENT_ID="$(plutil -extract REVERSED_CLIENT_ID raw ios/Runner/GoogleService-Info.plist)"
test -n "$REVERSED_CLIENT_ID"
```

Only when the release owner intends to rotate or replace the Firebase app
configuration, run `flutterfire configure` in an isolated branch, review both
`lib/firebase_options.dart` and `ios/Runner/GoogleService-Info.plist`, and rerun
the verifier. Never print private credentials or add them to generated config.

Open `ios/Runner.xcworkspace` in Xcode. Verify that the tracked
`ios/Runner/GoogleService-Info.plist` has Runner target membership and that
Runner > Info > URL Types already contains exactly one scheme matching
`$REVERSED_CLIENT_ID`; do not add duplicate entries. This is the reversed Google
client URL scheme, not the OAuth client ID itself.

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

The non-secret `DEVELOPMENT_TEAM` identifier is checked in for Debug, Profile,
and Release so a clean clone can resolve the intended team. The release operator
must still prove membership in that team and supply valid private signing
certificates and provisioning through Xcode or the approved CI secret store.

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

## 4. Store release without subscriptions

Do not create RevenueCat products or set purchase SDK keys. The app opens all
learning content and contains no purchase or restore flow. Store listing and
App Privacy answers must not promise subscriptions or declare current purchase
processing.

```bash
set -euo pipefail

: "${APPLE_TEAM_ID:?Set APPLE_TEAM_ID to the Apple Team ID}"
bash scripts/build_ios_ipa.sh
```

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
flutter pub get
(
  cd ios
  pod install --repo-update
)
test -f ios/Podfile.lock
grep -Fq 'GoogleMLKit/TextRecognitionKorean' ios/Podfile.lock

flutter build ios --debug --no-codesign

# App Store candidate with all learning content open.
bash scripts/build_ios_ipa.sh
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

These build, signing, notification-delivery, Apple-authentication, Google-authentication, and no-purchase verification checks require macOS, Xcode, real credentials, the final signed archive, and physical-device testing. They cannot be completed on Windows.
