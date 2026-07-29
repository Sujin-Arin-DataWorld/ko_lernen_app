# Task 9A report — cloud privacy and deletion reconciliation

Date: 2026-07-29

Starting commit: `fc9c0f0bd89e73af816c377e5b933d681f18dd6b`

## Root cause

`FirestoreProgressService`, `BookshelfService`, and `CloudSync` selected their
Firestore owner from `AuthService.current?.uid`. Firebase creates an anonymous
user during normal cloud startup, so a non-empty anonymous UID satisfied that
check even though no durable Google/Apple account had been deliberately linked.
The settings UI encouraged account linking, but the service boundary did not
enforce it.

## TDD evidence

The first focused run of
`flutter test test/cloud_backup_access_policy_test.dart --reporter expanded`
failed before production edits with:

```text
Error: Undefined name 'CloudBackupAccessPolicy'.
00:00 +0 -1: Some tests failed.
```

After the minimal policy implementation, the same matrix passed `7/7`. It
covers anonymous-only, no-provider, Google, Apple, mixed durable providers,
missing UID, and blank UID.

## Code changes

- Added pure `CloudBackupAccessPolicy.uidFor`, which returns a UID only when it
  is non-empty and provider metadata contains `google.com` or `apple.com`.
- Added the fail-closed `AuthService.cloudBackupUid` adapter over the current
  Firebase user.
- Routed automatic pack-progress Firestore access, best-effort bookshelf
  Firestore access, and manual whole-app backup/restore through the same durable
  UID selector.
- Left anonymous Firebase Authentication available for optional Gye, sharing,
  RevenueCat identity binding, and push ownership.
- Left local persistence as the learning source of truth and did not alter the
  Task 8 portable-media stripping paths.

## Public/store document changes

- Rewrote `docs/privacy.html` and `docs/account-deletion.html` as clean UTF-8
  English/German/Korean pages with working language tabs.
- Reconciled startup anonymous Firebase Auth, Remote Config, conditional
  RevenueCat startup and `logIn(uid)`, linked purchase history, local-first
  learning data, durable-link backup, independent Analytics/Crashlytics
  opt-ins, FCM token lifecycle, self-attested Gye data, local photos,
  OCR/DeepL translation caching, and dynamic TTS processing.
- Documented the in-app deletion path for guest and linked accounts, fresh
  anonymous identity after successful deletion, retryable Gye cleanup,
  subscription cancellation, and the separate RevenueCat processor-side
  request.
- Replaced the combined store answer sheet with separate Google Play and Apple
  worksheets. RevenueCat sharing/integration answers, Firebase/processor
  regions and retention, signed-build SDK disclosures, and legal controller
  name/address remain explicit owner/console blockers.
- Updated the store README so Play answers are not copied field-for-field into
  Apple App Privacy.

No controller address, universal EU location, universal TLS version, provider
retention period, live deployment state, or console answer was invented.

## Verification evidence

- Dart format check: 5 changed Dart/test files, 0 changes required.
- Focused cloud/account/media test set: `93` tests passed.
- `flutter analyze`: `No issues found`.
- Full `flutter test --reporter compact`: `762` tests passed.
- Python standard-library HTML parse: both public pages decoded as strict UTF-8;
  `en`, `de`, and `ko` tabs each reference a real matching section; one default
  active section per page.
- UTF-8/mojibake structural scan: clean for all four rewritten documents.
- Stale affirmative claim search: no “email only”, “future in-app deletion”,
  uninstall-server-deletion, RevenueCat-after-purchase-only, or automatic
  anonymous-progress-upload claims. Permission/TLS/EU terms remain only in
  explicit removal or anti-claim context.
- `git diff --check`: clean.
- Changed-file allowlist: only the Task 9A code, test, four requested documents,
  and this report.
- Credential-pattern scan: no private-key block, service-account private key,
  Firebase API-key-shaped token, RevenueCat-key-shaped token, secret-key-shaped
  token, or populated DeepL key in the changed files.

The focused commit hash is recorded in the task handoff after the commit is
created.

## External release blockers retained

- Legal controller name and postal address for the published
  Privacy Policy/Impressum.
- Live Firebase service locations, TTL/retention, and enabled SDK settings.
- Live deployment/region confirmation for analysis, Gye, and TTS functions.
- RevenueCat project integrations, Data Safety “shared” treatment, customer
  deletion route, location, and retention.
- Google/Apple provider scopes and returned profile fields.
- Final signed Android/iOS SDK/privacy reports and store-console answers.

No remote service, deployment, publication, push, merge, or release action was
performed.
