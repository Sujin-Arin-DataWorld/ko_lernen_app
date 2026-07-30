# Account operation release verification — 2026-07-31 source gate

Verification was executed on **2026-07-31 (Europe/Berlin)** from
`codex/release-blockers-2026-07-30` at
`fff94a38d25e5a7f1b6ccaa28833e3bc5cb59b44`, compared with
`origin/main` at `0b95a6e4f09e3d4875d7d05ae343d2d807d52dc0`.

This record covers repository source and local automated verification only. No
deployment, license acceptance, secret configuration, mobile build upload,
physical-device run, sandbox purchase, or store-console action was performed.

## Release verdict

The complete prescribed **source-level gate passes** at the commit above. This
does **not** clear the app for external testers or store release: the external
gates listed below remain unverified until evidence from the intended Firebase,
Apple, Google Play, RevenueCat, device, and store environments exists.

The reviewed source now has concrete worker adapters for bounded user-tree,
community, processor, and Apple-revocation work. Local tests cover their worker
wiring, lease/retry behavior, scheduler fairness, cloud-backup deletion
journal, and resumable first-link backfill. These are source-test claims, not
evidence that any production function, scheduler, rule, index, secret, IAM
binding, provider, or route is deployed.

## Fresh command evidence

| Gate | Exact command | Observed result |
| --- | --- | --- |
| Full Flutter suite required by the brief | `flutter test --reporter compact` | Exit 0; **1,186 passed**, 0 failed. A preliminary 5-second command-wrapper timeout was discarded and the command was rerun to completion. |
| Definitive serialized Flutter suite | `flutter test --reporter compact --concurrency=1` | Exit 0; **1,186 passed**, 0 failed. This serialized run is the definitive Flutter evidence. |
| Dart analyzer | `flutter analyze` | Exit 0; `No issues found!`. |
| Gye/Functions suite | `npm.cmd test` from `functions/gye` | Exit 0; **176 passed**, 0 failed, 0 skipped, 0 todo. |
| Public account-deletion page | `node --test docs/account-deletion-page.test.js` | Exit 0; **5 passed**, 0 failed, 0 skipped, 0 todo. |
| Firestore rules emulator | `$env:JAVA_HOME='C:\Program Files\Android\Android Studio\jbr'; $env:Path='C:\Program Files\Android\Android Studio\jbr\bin;'+$env:Path; npm.cmd run test:rules` from `functions/gye` | Exit 0 against demo project `demo-hangul-sori`; **37 passed**, 0 failed, 0 skipped, 0 todo; emulator shut down. The JBR environment change was command-scoped. Expected `PERMISSION_DENIED` messages were assertions of rejected client operations. |
| Branch whitespace | `git diff --check origin/main...HEAD` | Exit 0; no output. |
| Changed-Dart formatting | `$dartFiles = @(git diff --name-only origin/main...HEAD -- '*.dart'); dart format --output=none --set-exit-if-changed @dartFiles` | Exit 0; **43 files** checked, 0 changed. |

Passing these commands means the tested local source behaved as specified. It
does not prove production deployment, device behavior, signing, or store
acceptance.

## Required static safety scans

Every non-zero-match result was inspected in context.

| Risk | Exact command | Observed result and interpretation |
| --- | --- | --- |
| Client Auth deletion | `rg -n --glob '*.{dart,js}' '(?:currentUser|firebaseUser|user)\??\.delete\(' lib functions` | `rg` exit 1: **0 matches**. No matching client `Auth` user-delete call was found in the scanned source. |
| Proof/token logging | `rg -n --glob '*.{dart,js}' '(?:proof|authorizationCode|idToken).*(?:print|log|debugPrint)' lib functions` | Exit 0: **1 textual match**, `functions/gye/account_operations_runtime.test.js:1330`. It is the test title `redacts raw proofs from callable errors and public logs`; its assertions require the proof to be absent from errors and logs and require allowlisted metadata. It is not a logging implementation. |
| Raw exception rendering | `rg -n --glob '*.dart' '(?:e|error|exception)\.toString\(\)' lib` | Exit 0: **6 matches**, all inspected as normalization/serialization false positives, not caught exception rendering. |

The six `toString()` matches are:

- generated localization canonicalization of `locale.toString()`;
- scalar byte-budget accounting with `value.toString().length`;
- API warning-list normalization with `map((e) => e.toString())`;
- two distractor-list normalization paths with
  `map((e) => e.toString())`; and
- deterministic quest token normalization from list values.

The regular expression matches the `e.toString()` substring inside `locale`
and `value` as well as generic collection elements. None of the six sites
renders a caught provider error or exception to a user. The Flutter suite also
includes the UI error-redaction tests. This source scan cannot prove that
external edge, provider, Cloud Logging, Crashlytics, analytics, or support
systems redact production values.

## Source claims reviewed

| Area | Repository/local evidence | Limit of the claim |
| --- | --- | --- |
| Concrete deletion worker wiring | The 176-test Functions suite loads the exported index and exercises bounded tree deletion, community cleanup, processor cleanup, Apple revocation, leases, retries, and terminal replay. | The real Firebase project, deployed revisions, runtime service accounts, quotas, timeouts, and provider credentials were not inspected. |
| Scheduler fairness and recovery | Functions tests exercise due deletion/replacement selection, bounded legacy backfill, Apple-wait starvation resistance, completed Apple checkpoint recovery, and retry deferral. | No deployed Cloud Scheduler job, alert, retry policy, or production backlog was observed. |
| Cloud-backup deletion journal | The serialized Flutter suite and Functions suite exercise durable admission, UID/operation fencing, bounded work discovery, restart/retry, and completion-only success. Rules tests deny client writes to server-owned deletion state. | No production Firestore dataset or real callable invocation was used. |
| First-link path | The serialized Flutter suite exercises durable first-link admission, pending-journal resume, local backfill, exact-session fences, and safe UI locking. | Google/Apple first-link flows were not run on a signed device against real providers. |
| Raw errors and sensitive proofs | Required scans were adjudicated above; Flutter/Node tests cover safe UI/public results and proof/log redaction. | Production logs, proxies, crash reporting, analytics, and support tooling remain external gates. |

## External gates — explicitly not verified

The following are release blockers until current, environment-specific evidence
exists:

- **Firebase deploy, IAM, secrets, and operations:** deploy the exact reviewed
  Functions, Firestore rules, indexes, and hosting/proxy route to the intended
  project; prove deployed revisions/regions, index readiness, callable and
  scheduler configuration, least-privilege service accounts, Secret Manager
  versions/access, logs/alerts, retry behavior, and synthetic proof redaction.
  No Firebase resource was created or changed by this verification.
- **Apple revocation sandbox:** configure authorized Apple credentials and test
  real authorization-code exchange/revocation, success, response loss,
  already-revoked/expired input, and retryable failure without logging secrets.
  Source tests do not constitute Apple sandbox evidence.
- **Android licenses, USB/device, and AAB:** the release owner must accept any
  required Android licenses interactively, build and inspect the signed AAB,
  attach and authorize a real Android device, and record install, launch, cold
  restart, account, deletion, and upgrade evidence. None was verified here.
- **iOS/macOS/Xcode/TestFlight:** an authorized macOS operator must configure
  the exact Firebase iOS app and Runner target membership, inspect
  entitlements/signing/privacy artifacts, archive with Xcode, upload the exact
  build, and record TestFlight plus physical-device results. None was verified
  from this Windows source gate.
- **App Check:** register the exact Android/iOS apps and signing identities,
  configure Play Integrity and App Attest/DeviceCheck, observe metrics, enable
  intended enforcement, and test protected calls from signed builds. Local
  option and handler tests are not provider evidence.
- **RevenueCat sandbox:** verify production identifiers and run Android and iOS
  sandbox purchase, restore, reinstall, cross-device, account-switch,
  collision, deletion, and subscription-management scenarios. No purchase was
  attempted.
- **Google Play and App Store consoles:** upload exact signed artifacts,
  reconcile Data Safety/App Privacy and SDK disclosures, configure tester
  tracks, and collect review/closed-test evidence. No console was opened or
  changed.

Physical-device behavior, Android USB recovery, AAB/archive production,
TestFlight/closed testing, and store acceptance must not be claimed from this
document.

## Independent review

Independent review is **not completed by this source-verification record**.
The release controller owns the fresh read-only review of the final Task 9 diff
and the claims above. That review must still check concrete worker wiring,
scheduler fairness, cloud-backup journal behavior, the first-link path,
raw-error redaction, sensitive-value leakage, and the separation between source
verification and external deployment evidence. No approval is claimed here,
and the branch must not be treated as release-approved until that separate
review has an evidence-backed disposition.
