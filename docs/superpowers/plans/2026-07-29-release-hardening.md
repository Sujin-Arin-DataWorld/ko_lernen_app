# Hangul Sori Release Hardening Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Remove every repository-level Android/iOS release blocker reproduced in the 2026-07-29 audit, add regression coverage for confirmed product bugs, and leave an explicit checklist for credential-, console-, Mac-, and real-device-only verification.

**Architecture:** Keep the existing local-first Flutter architecture. Make cloud startup ordered and consent-aware, make FCM lifecycle explicit, keep data parsing platform-independent, harden Gye lifecycle both in Firestore rules and Cloud Functions, and validate release artifacts in CI. Do not invent Apple/Firebase/RevenueCat credentials; repository work must fail clearly or document the exact external prerequisite.

**Tech Stack:** Flutter 3.44.8, Dart 3.12.2, Android API 36/AGP 9, iOS 13+, Firebase Auth/Firestore/Messaging/Crashlytics/Analytics, RevenueCat, Node.js 22 Cloud Functions, Python Book Analysis function.

## Global Constraints

- Work only in `C:\Users\vjinn\OneDrive\Desktop\hangulsori\ko_lernen_app-release-hardening` on branch `codex/release-hardening-2026-07-29`.
- Preserve the existing Android application ID `com.sujinarin.ko_lernen_app` and iOS bundle ID `com.sujinarin.koLernenApp`.
- Preserve all existing user data keys and support upgrades from version `2.0.1+4`.
- Add every new user-visible string to both `lib/l10n/app_de.arb` and `lib/l10n/app_en.arb`; regenerate localizations.
- Use braces for every Dart `if`/`else` body.
- Do not commit keystores, `key.properties`, service-account keys, APNs keys, RevenueCat secret keys, or fabricated Firebase iOS values.
- Keep Analytics, Crashlytics, and FCM native collection/auto-init off by default. Enable only after the corresponding stored user choice.
- Do not broadly upgrade dependencies. Change only packages required by a confirmed defect or build blocker.
- Use TDD for Dart/Node/Python behavior: add a focused failing regression first, observe the expected failure, implement the minimum fix, and rerun it.
- Config/build changes use the relevant parser, compiler, merged manifest, signer, or archive inspection as their regression gate.
- Never claim iOS archive readiness from Windows. CI/macOS and a signed TestFlight archive remain mandatory.

---

## Task 1: Repair cross-platform data parsing and deterministic Flutter generation

**Files:**

- Create: `.gitattributes`
- Modify: `lib/services/data_loader.dart`
- Modify: `test/data_integrity_test.dart`
- Create: `test/data_loader_test.dart`
- Modify: `l10n.yaml`
- Modify: `pubspec.yaml`
- Modify: `pubspec.lock`

- [x] Add a production-path test that calls `DataLoader.loadVocab()`, expects exactly 558 bundled vocabulary records, and checks representative records after quoted fields.
- [x] Run `flutter test test/data_loader_test.dart test/data_integrity_test.dart --reporter expanded` and record the 307-row failure.
- [x] Normalize `\r\n` and lone `\r` to `\n` before both vocabulary and grammar CSV parsing. Keep parsing in one shared private helper.
- [x] Make the integrity test line-ending independent so it validates content rather than checkout configuration.
- [x] Add `.gitattributes` rules forcing LF for `*.csv`, `*.json`, and `*.arb`.
- [x] Remove obsolete `synthetic-package` from `l10n.yaml`.
- [x] Move `flutter_native_splash` from `dev_dependencies` to normal `dependencies`; keep the locked version unless `flutter pub get` requires a compatible patch.
- [x] Run `flutter pub get`, `flutter gen-l10n`, and the focused tests. Confirm there is no synthetic-package warning.

## Task 2: Order cloud startup and enforce privacy-safe crash/push lifecycle

**Files:**

- Create: `lib/services/app_startup_coordinator.dart`
- Create: `test/app_startup_coordinator_test.dart`
- Modify: `lib/main.dart`
- Modify: `lib/services/privacy_consent_service.dart`
- Modify: `lib/services/push_service.dart`
- Modify: `lib/services/premium_service.dart`
- Modify: `lib/screens/settings_screen.dart`
- Modify: `lib/services/auth_service.dart`
- Create or modify focused tests under `test/`

- [ ] Add a coordinator test proving Firebase initialization and anonymous auth complete before Premium and Push, Push is skipped when notifications are off, and a failed Firebase initialization prevents dependent SDK access.
- [ ] Make `_initFirebase()` return success/failure and invoke Premium/Push through the ordered coordinator without delaying `runApp()`.
- [ ] Install Crashlytics handlers only as consent-aware handlers: when consent is off, report to the local Flutter error presentation path and do not call Crashlytics.
- [ ] When Crashlytics consent is disabled, disable collection and delete unsent reports. On an explicit off-to-on user transition, delete pre-consent unsent reports before enabling; on startup with already-stored consent, preserve reports recorded while consent was active.
- [ ] Refactor `PushService` so it is idempotent, uses `FirebaseAuth` directly rather than importing `AuthService`, enables FCM auto-init only after notification permission, retries after a prior initialization failure, tracks subscriptions, and removes/deletes the token on disable.
- [ ] Invoke Push enable/disable from the Settings notification switch. Local reminders must continue to work if optional FCM registration fails.
- [ ] Remove the token from the old UID before sign-out/account deletion and persist the token for the new anonymous/current UID after the auth transition when notifications remain enabled.
- [ ] Make RevenueCat binding start only after Firebase/auth initialization and update `_boundUid` only after a successful `Purchases.logIn`/`logOut`, allowing transient same-UID retries.
- [ ] Add focused fake-based tests for initialization ordering, notification-off behavior, push retry/idempotency, old-user token removal/rebinding, and consent decisions.

## Task 3: Fix Android picker policy, signing safety, notification icon, and manifest privacy

**Files:**

- Modify: `lib/screens/book_capture_screen.dart`
- Modify: `android/app/src/main/AndroidManifest.xml`
- Modify: `android/app/build.gradle.kts`
- Modify: `lib/services/notification_service.dart`
- Create: `android/app/src/main/res/drawable/ic_stat_hangul_sori.xml`

- [ ] Remove manual gallery permission requests; keep contextual camera permission and let `image_picker_android` use the system picker.
- [ ] Remove `READ_MEDIA_IMAGES` and legacy `READ_EXTERNAL_STORAGE`. Add `tools:node="remove"` entries if transitive manifests reintroduce broad media access.
- [ ] Disable FCM native auto-init and Firebase Analytics Advertising ID collection in the application metadata.
- [ ] Remove `AD_ID` from the merged manifest, including transitive reintroduction, because the app has no ads and does not need advertising identifiers.
- [ ] Replace the opaque launcher bitmap notification icon with a white alpha-only Android vector small icon and reference it from `NotificationService`.
- [ ] Replace release-to-debug signing fallback with a clear Gradle failure whenever a release task is requested without a complete `android/key.properties` and existing keystore.
- [ ] Verify the missing-key release command fails for the intended reason. Later, use an ephemeral non-debug CI/test keystore to prove release compilation without representing it as the Play upload key.

## Task 4: Prepare correct iOS native capabilities without inventing credentials

**Files:**

- Modify: `ios/Runner/Info.plist`
- Create: `ios/Runner/RunnerDebug.entitlements`
- Create: `ios/Runner/RunnerRelease.entitlements`
- Modify: `ios/Runner.xcodeproj/project.pbxproj`
- Create: `ios/Podfile`
- Create: `docs/store/ios-external-setup.md`

- [ ] Change `CFBundleDisplayName` to `Hangul Sori`.
- [ ] Replace misspelled `FirebaseAnalyticsCollectionEnabled` with exact `FIREBASE_ANALYTICS_COLLECTION_ENABLED=false`.
- [ ] Add `FirebaseMessagingAutoInitEnabled=false` and `UIBackgroundModes` containing `remote-notification`.
- [ ] Add Sign in with Apple and Push capabilities to the Runner target. Use development APNs entitlement for Debug and production APNs entitlement for Profile/Release.
- [ ] Add the standard Flutter CocoaPods fallback Podfile at platform iOS 13 and include locked-compatible `GoogleMLKit/TextRecognitionKorean ~> 6.0.0`.
- [ ] Document the exact bundle ID and external steps for Firebase iOS app creation, `GoogleService-Info.plist`, reversed Google client URL scheme, Apple team/profiles, Sign in with Apple, APNs `.p8`, and RevenueCat.
- [ ] Do not add placeholder client IDs or fake Firebase options. The document must include commands that fail if any required value is absent.

## Task 5: Make account/provider behavior correct for Apple and subscriptions

**Files:**

- Modify: `lib/services/auth_service.dart`
- Modify: `lib/screens/profile_screen.dart`
- Modify: `lib/widgets/sori/account_nudge.dart`
- Modify: `lib/screens/settings_screen.dart`
- Modify: `lib/l10n/app_de.arb`
- Modify: `lib/l10n/app_en.arb`
- Add focused tests under `test/`

- [ ] Return the Apple authorization code from reauthentication and call `FirebaseAuth.revokeTokenWithAuthorizationCode` before deleting an Apple-linked Firebase account.
- [ ] Treat either Google or Apple linking as a durable account in profile/nudge/provider labels.
- [ ] Add an account-deletion warning that store subscriptions are not cancelled by account deletion and expose the platform subscription-management route.
- [ ] Ensure cleanup/revocation failure does not show the success state.
- [ ] Add tests for provider-state presentation and the deletion sequence through injected/fake account operations.

## Task 6: Repair restore semantics, English Book Analysis, and TTS playback speed

**Files:**

- Modify: `lib/services/cloud_sync.dart`
- Modify: `test/cloud_sync_test.dart`
- Modify: `lib/screens/book_result_screen.dart`
- Modify: `lib/services/book_analysis_service.dart`
- Modify: `functions/analyze_korean_text/main.py`
- Create or modify Python tests in `functions/analyze_korean_text/`
- Modify: `lib/services/tts_service.dart`
- Modify: `lib/screens/listening_screen.dart`
- Create or modify focused Dart tests under `test/`

- [ ] Add failing restore tests for every cumulative counter, cursor policy, Chosung wrong, all Wordle stats, app streak, and best streak.
- [ ] Restore cumulative counters with max-merge; restore missing fields emitted by backup; keep local nonempty structured data from being clobbered.
- [ ] Pass the current app language (`de` or `en`) from Book Result to analysis.
- [ ] Make the Python grammar-analysis prompt and fallback output language-aware and add a pure unit test for German and English prompts.
- [ ] Add an explicit playback-rate/multiplier input to TTS so cached/cloud audio and OS fallback use the same effective rate.
- [ ] Remove Listening’s temporary writes to the global TTS preference; 0.75x, 1.0x, and 1.25x must be request-local and safe under overlap.
- [ ] Run all focused Dart and Python tests.

## Task 7: Harden Gye ownership, suspension, caps, and deletion lifecycle

**Files:**

- Modify: `lib/services/gye_service.dart`
- Modify: `lib/screens/gye_screen.dart`
- Modify: `lib/models/gye.dart` only if a new explicit error is needed
- Modify: `lib/l10n/app_de.arb`
- Modify: `lib/l10n/app_en.arb`
- Modify: `firestore.rules`
- Modify: `functions/gye/index.js`
- Create: `functions/gye/lifecycle.js`
- Create: `functions/gye/lifecycle.test.js`
- Modify: `functions/gye/package.json`
- Modify: `functions/gye/package-lock.json`
- Add focused Dart tests under `test/`

- [ ] Add failing tests proving an owner cannot use normal Leave and a failed leave write is surfaced instead of swallowed.
- [ ] Block owner leave in `GyeService` and keep the screen open with a localized explanation. Do not expose normal leave until a deliberate ownership-transfer or group-deletion flow exists.
- [ ] Add server-owned `bans/{uid}` tombstones when a member is suspended; rules must deny suspended-member deletion and deny member recreation while a ban exists.
- [ ] Tighten member creation/update rules so `memberCount` cannot exceed 10 and the post-write user `gyeIds` list cannot exceed 3.
- [ ] Add a retryable member-deletion trigger that irreversibly anonymizes the departed member’s feed/report identity in that Gye.
- [ ] Add a retryable user-document deletion trigger that cleans or irreversibly anonymizes the user’s Gye feed/reports/shared packs, removes membership, and transfers owner role to an active member or deletes an empty group. Remove the conflicting client-side owner-membership deletion and let the durable trigger own that cleanup.
- [ ] Extract pure lifecycle selection/anonymization helpers and cover them with Node’s built-in test runner.
- [ ] Keep the 16+ check explicitly described as self-attested unless a verifiable server identity source is added; do not pretend local birth year is cryptographic age verification.
- [ ] Run Dart tests, `npm test`, `node --check`, and Firestore rule compilation/emulator tests when the local Firebase emulator is available.

## Task 8: Stop orphaning captured and custom-word images

**Files:**

- Create: `lib/services/book_image_service.dart`
- Modify: `lib/screens/book_capture_screen.dart`
- Modify: `lib/screens/book_result_screen.dart`
- Modify: `lib/services/bookshelf_service.dart`
- Modify: `lib/screens/bookshelf_page_screen.dart`
- Modify: `lib/services/word_image_service.dart`
- Modify: `lib/screens/custom_pack_edit_screen.dart`
- Modify: `lib/services/custom_pack_service.dart`
- Modify: `lib/screens/settings_screen.dart`
- Add focused tests under `test/`

- [ ] Add filesystem-oriented tests using temporary directories for copy, replace, cancel, page delete, word delete, pack delete, and delete-all.
- [ ] Copy accepted crop output from cache into an app-documents `book_images` directory before persistence.
- [ ] Delete temporary crop output when the flow is cancelled or fails and delete permanent page images when the page/account is deleted.
- [ ] Track newly selected word images so cancel removes the new file, save removes the replaced old file, remove-photo deletes the file, and word/pack/account deletion removes all owned files.
- [ ] Keep deletion best-effort for missing files but never leave persisted models pointing at a deliberately deleted path.

## Task 9: Add release CI gates and reconcile store/privacy documentation

**Files:**

- Modify: `.github/workflows/ci.yml`
- Modify: `docs/store/closed-testing-checklist-v2.md`
- Modify: `PLAY_CONSOLE_GUIDE.md`
- Modify: `docs/store/README.md`
- Modify: `docs/store/data-safety.md`
- Modify: `docs/privacy.html`
- Modify: `CLAUDE.md`

- [ ] Add `flutter test` to the Ubuntu CI job.
- [ ] Add an Android release-build job that creates an ephemeral non-debug test keystore, builds an AAB with an explicit non-secret RevenueCat placeholder, validates the bundle, and verifies the signer is not `Android Debug`. Never publish that AAB.
- [ ] Add a `macos-26` iOS no-codesign compile job using Xcode 26 and the CocoaPods fallback. It is a compile gate, not an archive/signing claim.
- [ ] Correct Play closed-testing guidance to 12 opted-in testers for 14 continuous days where the personal-account rule applies.
- [ ] Make every release command include `RC_ANDROID_KEY`/`RC_IOS_KEY` and fail preflight when subscription testing is in scope but the key is empty.
- [ ] Reconcile age-rating, FCM identifiers, Crashlytics queue behavior, anonymous Firebase UID, RevenueCat purchase data, Apple sign-in, Gye community data, and deletion timing across store/privacy documents.
- [ ] Update `CLAUDE.md` “현재 진행 중인 작업” and add the audit/verification outcome without marking device/console work complete.

## Task 10: Run clean release verification and hand off external blockers

**Files:**

- Update: this plan’s checkboxes and SDD ledger
- Create: `docs/store/release-verification-2026-07-29.md`

- [ ] Run `git diff --check`.
- [ ] Run `flutter pub get` and `flutter gen-l10n`.
- [ ] Run `dart format --output=none --set-exit-if-changed lib test`.
- [ ] Run `flutter analyze`.
- [ ] Run `flutter test --reporter expanded`.
- [ ] Run Node and Python function tests and syntax checks.
- [ ] Prove release build fails clearly without the upload-key configuration.
- [ ] Create a temporary non-debug keystore outside tracked files, build `flutter build apk --debug`, `flutter build apk --release`, and `flutter build appbundle --release`, then delete the temporary signing material.
- [ ] Validate the AAB with bundletool, verify its signer, inspect the merged manifest for forbidden permissions/default-on collection, confirm R8 mapping, and recheck arm64/x86_64 16 KB alignment.
- [ ] Run `flutter doctor -v`, explicit SDK `adb devices -l`, and Windows PnP detection. Record that a physical phone cannot be claimed tested unless it appears and launches the app.
- [ ] Record the exact remaining iOS Firebase/Google/Apple/APNs/RevenueCat values and Mac/TestFlight checks; do not mark App Store readiness complete until the signed Xcode 26 archive passes them.
- [ ] Run a final whole-branch code review, resolve all release-blocking findings, and leave the branch/worktree ready for user review.
