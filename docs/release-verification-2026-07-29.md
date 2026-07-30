# Account operation release verification — 2026-07-29 branch

Verification was executed on **2026-07-30 (Europe/Berlin)** from
`codex/release-hardening-2026-07-29`, starting at commit
`e31a7331e74bc0dfaedadf4f64d1381e2fe8c358`.

This is a repository and local-environment verification record. It is **not**
evidence of a Firebase deployment, production IAM configuration, a signed
mobile build, a physical-device run, Play Console closed testing, TestFlight,
or App Store review.

## Release verdict

The reviewed branch is **not yet cleared for external testers**.

The local Flutter, Node, browser-page, formatting, static-analysis, and
Firestore emulator gates pass. However, the following release blockers remain:

1. The exact reviewed `functions/gye/index.js` deliberately fails closed for
   Apple revocation and all three destructive deletion adapters. A deployed
   copy of this source cannot complete account deletion until audited
   production adapters replace those fail-closed functions.
2. The Android SDK reports unaccepted licenses. No Android phone is visible to
   Flutter or to the SDK's ADB, so neither USB operation nor a physical-device
   launch has been verified. Per the non-mutating verification rule, no build
   was attempted after this license gate was found.
3. No production evidence was available for Firebase functions/rules/indexes,
   the deletion-proof route, App Check enforcement, least-privilege IAM,
   anonymous Auth cleanup behavior, Apple services, RevenueCat sandbox
   purchases, Google Play, or App Store Connect.

Passing local tests means the tested code paths behaved as specified in this
workspace. It does not mean the production services or stores are configured.

## Code defects found and fixed

The verification and independent review found five repository defects. Each
was reproduced by a failing regression test before the production fix:

1. The callable client did not request a limited-use App Check token even
   though the server consumes tokens. The concrete transport now supplies
   `HttpsCallableOptions(limitedUseAppCheckToken: true)`, including the
   temporary Firebase-app path.
2. Anonymous replacement could enter `sourceCleanupPending` without a worker
   path to finish source user-tree, Auth, community, and processor cleanup.
   The worker now checkpoints and completes that path before target activation.
3. Manual account and bookshelf restore could apply data after the identity
   session changed. Both paths now capture and repeatedly verify the exact
   ready session, including immediately before persistent local writes.
4. Shared-pack publication could write under the previous UID after a session
   change. Collision lookup and the Firestore write now run through the same
   exact-session fence.
5. A single capped scheduler query could be starved by 50 incomplete Apple
   revocation waits. Normal actionable phases and completed Apple-revocation
   checkpoints are now queried separately: incomplete waits consume no normal
   worker slots, while a completed checkpoint still recovers after response
   loss.

The release remains blocked by the external and deliberately fail-closed
conditions listed above; these local fixes do not waive those gates.

## Fresh command evidence

| Gate | Exact command | Result |
| --- | --- | --- |
| Full Flutter suite | `flutter test --reporter compact` | Exit 0; **1,074 passed**, 0 failed. |
| Dart analyzer | `flutter analyze` | Exit 0; `No issues found!`. |
| Changed-Dart formatting, first run | `$dartFiles = @(git diff --name-only --diff-filter=ACMR main...HEAD -- '*.dart'); dart format --output=none --set-exit-if-changed @dartFiles` | Exit 1; 110 files checked and `lib/services/notification_service.dart` was the only file requiring formatting. |
| Changed-Dart formatting, after the mechanical fix | Same gate, expanded to committed, modified, and untracked changed Dart files | Exit 0; 119 files checked, 0 changed. |
| Focused account runtime | `node --test account_operations_runtime.test.js` from `functions/gye` | Exit 0; **49 passed**, 0 failed, including scheduler starvation and completed-Apple recovery. |
| Gye/functions tests | `npm.cmd test` from `functions/gye` | Exit 0; **123 passed**, 0 failed, 0 skipped. |
| Public deletion-page tests | `node --test docs/account-deletion-page.test.js` | Exit 0; **5 passed**, 0 failed, 0 skipped. |
| Firestore rules, first run | `npm.cmd run test:rules` from `functions/gye` | Did not start tests: Firebase CLI could not spawn `java -version` because Java was absent from this shell's `PATH`. |
| Firestore rules, isolated JBR retry | `$env:Path = 'C:\Program Files\Android\Android Studio\jbr\bin;' + $env:Path; npm.cmd run test:rules` | Exit 0; Firestore emulator on demo project; **35 passed**, 0 failed, 0 skipped. The PATH change existed only for this command. |
| Patch whitespace | `git diff --check main...HEAD; git diff --check` | Exit 0; no output. |

The formatter finding was fixed mechanically with:

```powershell
dart format lib/services/notification_service.dart
```

The resulting diff only reformats line wrapping and argument layout. It does
not change notification behavior.

## Focused safety scans

The following scans were run against the reviewed workspace:

| Risk | Command/pattern | Result |
| --- | --- | --- |
| Committed secret signatures | `rg -n -I --hidden` excluding `.git`, build output, lockfiles, and binary assets; patterns included private-key headers, AWS key IDs, Stripe/GitHub token shapes, and a literal 64+ hex `DELETION_PROOF_HMAC_KEY` assignment | **0 matches**. This does not inspect CI, console variables, built artifacts, or production logs. |
| Direct Flutter Auth deletion | `rg -n --glob '*.dart' '(?i)(FirebaseAuth\.instance\s*\.\s*currentUser|currentUser|\buser)\??\s*\.\s*delete\s*\(' lib test` | **0 matches**. |
| Collision/identity signals | `rg -n --glob '*.dart' '(account-exists-with-different-credential|credential-already-in-use|signInWithCredential\s*\(|Purchases\.(logIn|logOut)\s*\()' lib test` | 7 review targets. Collision exceptions return `ExistingAccountLinkConflict`; the two sign-ins are isolated temporary/explicit restoration contexts. RevenueCat binds custom UID to custom UID and does not use logout as the switch intermediary. |
| Safety-critical placeholders | `rg -n --glob '!package-lock.json' --glob '!*.lock' '(?i)(\bTODO\b|\bFIXME\b|\bHACK\b|\bXXX\b|UnimplementedError|not[ -]implemented)' lib/services/account functions/gye firestore.rules docs/account-deletion-page.js` | **0 matches**. The explicit fail-closed production adapters described below do not use placeholder comments and were found by code review. |
| Skipped Dart tests | `rg -n --glob '*.dart' 'skip\s*:' test` | **0 matches**. |

## Android and USB evidence

| Check | Evidence | Status |
| --- | --- | --- |
| Flutter/Android environment | `flutter doctor -v` found Flutter 3.44.8, Dart 3.12.2, Android SDK 36.0.0, platform 36.1, build-tools 36.0.0, Android Studio JBR 21.0.10. | Android toolchain remains warning status because some licenses are not accepted. |
| Flutter device discovery | `flutter devices` listed Windows, Chrome, and Edge only. | **No Android device detected.** |
| ADB on shell PATH | `adb devices -l` wrapper returned `ADB_NOT_ON_PATH`. | Environment issue; `adb` is not directly invokable in the current shell. |
| SDK ADB discovery | `C:\Users\vjinn\AppData\Local\Android\sdk\platform-tools\adb.exe devices -l` printed the device-list header with no rows. | **Zero Android devices attached/authorized from ADB's perspective.** |
| Android app bundle | Not run. | Blocked by unaccepted Android licenses under the non-mutating verification rule. No license was accepted automatically. |
| Physical USB launch | Not run because no phone was detected. | **Not verified and not fixed by this repository review.** |
| iOS archive/device | Not available from this Windows environment. | **Not verified.** Requires macOS/Xcode, signing, TestFlight, and physical-device evidence. |

Before claiming the previous USB problem is fixed, accept the licenses
interactively under the release owner's control, put SDK `platform-tools` on
the intended shell PATH (or use its absolute path), enable phone developer
options and USB debugging, accept the phone's RSA prompt, and re-run both
device commands. A successful claim additionally requires launching the
signed/test build on that phone.

## Repository evidence versus production gates

| Area | Verified in repository/local environment | Still required before testers |
| --- | --- | --- |
| Protected callables/App Check | Node tests assert the callable options and token handling; the concrete Flutter callable transport requests a limited-use App Check token; Flutter selects Play Integrity for Android release and App Attest with DeviceCheck fallback for Apple release. | Register the exact apps, verify signing fingerprints/entitlements, observe metrics, enforce providers in the intended Firebase project, and test signed closed-test/TestFlight builds. |
| Firestore rules | Demo-project emulator tests pass 35/35, including denial of client deletion markers/root user deletes and server-only operation writes. | Deploy the exact reviewed rules and re-test production-safe identities. Emulator success is not deployment evidence. |
| Function triggers and indexes | `firebase.json` and `firestore.indexes.json` are present; source documents the order indexes-ready → rules → functions. | Verify every required index is `READY`, each v2 trigger/scheduler exists in `europe-west3`, retries/alerts are configured, and the deployed revision matches the reviewed commit. |
| Least-privilege IAM | No secret value or service-account key was found in the scanned source. | Assign dedicated service accounts and prove minimal Firestore/Auth/Secret Manager/Scheduler/invoker permissions. The reviewed function declarations do not supply production IAM evidence. Do not use Owner/Editor as a substitute. |
| Anonymous Auth cleanup | The account state machine and cleanup tests are local evidence only. | Record whether Firebase Auth automatic anonymous-user cleanup is enabled. If enabled, prove its timing cannot bypass Firestore/Gye/media cleanup; otherwise document the intentional disabled state and retention policy. |
| Deletion worker | State-machine, lease, retry, replacement source cleanup, Auth user-not-found, Gye, processor, partial-failure, scheduler-starvation, and completed-Apple recovery tests pass locally. | **Code blocker:** replace `deleteUserTreePage`, `cleanupCommunity`, and `cleanupProcessor` fail-closed adapters in `functions/gye/index.js`; stage-test bounded pagination, timeouts, replay, and terminal completion before deployment. |
| Apple deletion | Tests preserve `appleRevocationPending` on transient failure and keep the authorization code out of persisted state/results. | **Code/deployment blocker:** `revokeAppleAuthorizationCode` currently throws `apple/revocation-unavailable`. Implement the audited Apple revoke adapter and stage-test success, response loss, expired code, retryable failure, and already-revoked state. |
| Deletion proof and logging | Node tests cover HMAC proof handling, generic public results, and application-level proof/log redaction; browser tests cover fragment removal and neutral output. | Provision `DELETION_PROOF_HMAC_KEY` through Secret Manager, restrict secret access, verify edge/CDN/function request-body and header redaction using a synthetic proof, and confirm no proof reaches Cloud Logging, analytics, Crashlytics, or support tooling. |
| Public proof route | `firebase.json` contains the same-origin rewrite and the static page uses the fixed first-party path. | Prove `hangul-sori.com` actually routes the path to the reviewed function. `docs/CNAME` may indicate GitHub Pages, which does not itself apply the Firebase Hosting rewrite. Verify TLS, no-store/no-referrer headers, CSP, CORS, body limit, rate limit, and generic responses at the final edge. |
| RevenueCat | Unit tests cover UID fencing and direct custom-ID switching without an anonymous logout intermediary. | Run Android and iOS sandbox purchases, restore, reinstall, cross-device login, existing-account collision, account switch, deletion, and subscription-management flows. Confirm entitlements never alias to the wrong Firebase UID and that deletion does not claim to cancel a store subscription. |
| Google Play/App Store | Repository store notes and manifests exist. | Produce signed artifacts, inspect merged manifests/privacy reports, upload exact artifacts, complete console privacy/data-safety answers, obtain closed-test/TestFlight evidence, and run the checklist below. |

## Tester handoff checklist

Do not invite external testers until every precondition below is evidenced:

- [ ] All Android SDK licenses are accepted by the release owner, `flutter
  doctor -v` has no Android-toolchain warning, and a fresh signed Android
  artifact builds successfully.
- [ ] At least one real Android phone appears in both `flutter devices` and
  `adb devices -l`, accepts the RSA prompt, and completes a launch plus a cold
  restart.
- [ ] A macOS/Xcode build and physical iPhone/TestFlight run pass with the
  production entitlements and signing profile.
- [ ] The account-deletion pipeline's four fail-closed adapters are replaced
  and pass staging end-to-end tests.
- [ ] Functions, rules, indexes, hosting/proxy route, secret version, IAM,
  App Check providers, scheduler, and alerts are deployed and recorded against
  the intended production project.
- [ ] RevenueCat Android and iOS sandbox purchase/restore/account-switch tests
  pass with the production product, entitlement, and offering identifiers.
- [ ] The release owner reconciles Google Play Data Safety and Apple App
  Privacy answers with the exact uploaded binaries and SDK dashboards.

After those preconditions pass, testers should cover:

- [ ] Fresh install and existing install/upgrade; anonymous progress survives
  restart, offline/online transitions, and normal cloud synchronization.
- [ ] Google and Apple new-account linking, existing-account collision,
  explicit cancel, source-data choice, target-data choice, and deterministic
  merge. No collision may auto-login or silently overwrite data.
- [ ] Kill the app or remove connectivity during prepare, reconciliation,
  cleanup, Apple pending, and local-cleanup phases; reopening must resume the
  same operation without duplicate writes or identity drift.
- [ ] Verify packs, SRS, custom content, bookshelf generations, media,
  Gye membership/feed, push ownership, and premium identity before and after
  each account transition.
- [ ] Non-Apple and Apple account deletion complete end to end. Exercise
  response loss, duplicate taps, retry, Auth user-not-found, Apple partial
  revoke, and local-cleanup failure.
- [ ] Exercise the public proof page with valid, expired, rotated, used,
  malformed, missing, and replayed proofs. The page and endpoint must reveal
  no state difference and must remove the fragment before the request.
- [ ] Verify store subscription management separately from app-account
  deletion; the UI must not imply that deleting the account cancels a Google
  Play or App Store subscription.
- [ ] Review production logs during controlled synthetic failures for raw
  proofs, ID tokens, Apple codes, UIDs, operation IDs, provider exceptions,
  request bodies, and authorization headers.
- [ ] Record device model, OS, app version/build, install source, account
  providers, App Check outcome, network state, operation ID in an access-
  controlled test record, expected result, actual result, and safe log link for
  every failure.

## Independent review

A separate read-only reviewer checked account-transition invariants, writer
fences, callable App Check behavior, scheduler recovery, Firestore rules,
localization, collision behavior, proof handling, and external-deployment
assumptions. The first passes found the five code defects recorded above. After
their test-first fixes, the final re-review returned **APPROVED** with no
actionable regression.

That approval covers the reviewed repository diff only. It does not approve or
substitute for the blocked production adapters, Android/iOS device evidence,
cloud deployment verification, store-console checks, or tester acceptance.
