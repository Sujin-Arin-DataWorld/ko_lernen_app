# Account transition and account deletion — safety-revised design

> **Status:** specification only. Revised after an independent security,
> data-integrity, and release-readiness review on 2026-07-29. It requires the
> owner's explicit approval before implementation begins.

## What changed after the deep review

The earlier **safe cleanup then switch** product decision remains: an anonymous
user who intentionally connects a credential already owned by another account
keeps the device's learning data, and the old anonymous cloud identity is not
silently migrated to the other person/account.

The order is now safety-corrected to **prepare → verify target → reconcile →
clean source → activate target**. Deleting the old anonymous account before
the target account is proven usable is irreversible and is therefore forbidden.
The revised design also makes account deletion a server-owned, resumable job;
prevents background writers and SDK observers from racing an account switch;
and treats a failed cloud read as a failure, never as an empty account.

## Scope and product boundary

- This flow applies only when the source is the still-current, provider-free
  anonymous Firebase UID and Google/Apple reports that the selected credential
  is already linked to a different durable Firebase account.
- It preserves local learning data and local managed media. It deliberately
  does **not** migrate source Gye membership, shared-pack authorship, FCM
  ownership, reports, or RevenueCat identity/entitlements into the target
  account.
- A durable-account A → B switch, a sign-out followed by a different sign-in,
  a restored session with a different local owner, and a collision involving a
  non-anonymous source must not silently switch or write local data to the new
  UID. They remain blocked pending a separately approved export/import design.
- A normal Google/Apple link that keeps the same Firebase UID is not a switch,
  but it still uses the reconciliation and write fence below.

## Non-negotiable invariants

- Anonymous-only users never passively upload or restore learning progress,
  packs, bookshelf data, or managed media.
- A credential collision never invokes `signInWithCredential` automatically.
- There is no automatic cloud write until the target remote state was read,
  validated, reconciled, and committed successfully.
- `absent` is different from `unavailable` and `invalid`. A network, permission,
  parsing, quota, or cache-only failure must never become permission to upload
  a fresh local default.
- All automatic cloud writers, identity observers, and community listeners are
  fenced by the same transition session. No component may infer that an auth
  change alone means cloud writes are safe.
- Local learning data and local image/media files are never reset, migrated to
  the old server account, or garbage-collected merely because a transition
  fails or the app restarts.
- A full-account deletion is server-authorized, idempotent, observable, and
  not considered complete until its required processor cleanup has a recorded
  terminal outcome.
- Raw ID tokens, Apple authorization codes, recovery tokens, and transition
  secrets never enter Firestore, URLs, analytics, Crashlytics, logs, cloud
  backups, or user-visible raw error text.

## One transition coordinator and one write session

All Google/Apple entry points — Settings, Profile, Account Nudge, startup
restoration, sign-out/sign-in, and any future provider UI — must route through
one `AccountTransitionCoordinator`. Direct calls that currently authenticate
and immediately call `CloudSync.backup()` are removed.

The coordinator owns an exclusive, process-wide `CloudWriteSession` with:

- `localProfileOwnerUid`, a local provenance record for the learning snapshot;
- a monotonically increasing `authEpoch` and `transitionId`;
- `mode: ready | quiesced | reconciling | cleanupPending | blocked`;
- a durable, non-secret local journal containing only IDs, phase, snapshot
  hash/version, remote revisions, and safe error category.

The journal never stores OAuth credentials, Apple codes, Firebase ID tokens,
or raw recovery/transition secrets. A restart restores the fence before any
auth observer or queued write can run. A stale queued operation must carry the
same UID and epoch or be discarded/re-read.

While a session is not `ready`, the following are all paused or reject with a
typed retryable outcome: `CloudSync`, Firestore progress, pack-progress writes,
bookshelf sync, custom-pack sync, Gye streams/actions, FCM registration and
ownership changes, and the RevenueCat Firebase-auth identity binder. Learning
UI mutations are either briefly quiesced for an immutable snapshot or queued
locally under the same epoch; they are never half-read into a backup payload.
The UI shows a non-dismissible transition overlay with an accessible Cancel or
Retry action where safe. It has EN/DE/KO text, screen-reader labels, keyboard/
back behavior, and an offline/timeout explanation; destructive meaning is not
communicated by color alone.

## Account-link state machine

### Preconditions and collision detection

The coordinator snapshots the current UID, provider list, local-profile owner,
and auth epoch. It refuses the replacement flow unless all of these still
identify the same anonymous source and no account deletion or transition job is
already active. The initial `linkWithCredential` collision is returned as a
typed `ExistingAccountLinkConflict`; it does not sign into the target.

The confirmation explicitly says:

> Keep this device's learning data and switch to the existing account. The old
> anonymous account's Gye membership, shared packs, notification ownership, and
> any source-only cloud identity will be removed after the existing account is
> verified. This cannot be undone; you can rejoin or share again afterwards.

### Prepare, verify, reconcile, then clean

1. **Prepare source without deletion.** After explicit confirmation, the app
   obtains a fresh provider credential only in memory and calls an authenticated
   server `prepareAnonymousReplacement` operation. The server verifies the
   source UID and creates a short-lived, single-use, server-owned transition
   record. It returns an opaque operation ID plus a high-entropy resume secret.
   The secret is kept only in memory unless crash recovery is necessary, in
   which case platform secure storage with Android/iOS backup exclusion is
   required. Expiry means *no source deletion*, not automatic cleanup.
2. **Quiesce and snapshot.** The coordinator enters `quiesced`, stops every
   writer/observer listed above, and takes one versioned immutable local
   snapshot. A user action that lands during this boundary is retained locally
   and either included in a new snapshot or queued for after reconciliation.
3. **Authenticate and verify target.** Only the coordinator may call the
   target sign-in. It immediately verifies that the target is a different,
   durable UID and records it on the server operation using the target's
   verified identity; provider credentials themselves are never persisted.
   RevenueCat, Push, and Gye observers remain dormant despite the Firebase auth
   event. After this point the anonymous source cannot be restored by a normal
   user sign-in, so Cancel becomes **Pause**, not "return to source".
4. **Read authoritative remote state.** Each required domain returns exactly
   one typed result: `present(version, data)`, `absent(authoritative)`,
   `unavailable(retryable)`, or `invalid(actionable)`. Reads must be server
   reads, not cache fallbacks. Any unavailable or invalid result keeps the
   session fenced and offers Retry/Pause; it must not upload local state.
5. **Reconcile and commit target.** Build a deterministic merge from the
   immutable local snapshot and validated target data, then write through a
   revision/CAS transaction or staged manifest. A changed remote revision
   triggers a complete re-read and merge. The final manifest is committed only
   after every required domain is staged; no partial logical backup is marked
   successful. Staging uses immutable generation namespaces; readers use only
   the one CAS-flipped active manifest, never a mixture of staged and active
   generations. Garbage collection may remove only unreferenced, completed or
   safely expired generations after their lease has ended.
6. **Request source cleanup last.** Only after target reconciliation commits,
   the app presents the final source-cleanup state to the server using the
   transition ID and secret. The server starts or resumes the source cleanup
   job. It is the only authority allowed to remove the source UID's remote
   identity. It records `cleanupPending` until the actual cleanup receipt is
   complete. Every inspect, resume, and cleanup request also carries a valid,
   revocation-checked Firebase token for the server-recorded target UID; the
   opaque resume secret is a second factor, never sufficient by itself. The
   server checks source UID, target UID, phase, generation, expiry, and
   single-use state, and redacts all transition identifiers/secrets from logs.
7. **Activate target identity.** Only after the source cleanup receipt is
   terminal-successful may the coordinator enable target Gye actions and bind
   FCM to the target UID. RevenueCat follows an explicit, tested policy below.
   The session then becomes `ready` at the target UID/epoch.

### Failure, restart, and unknown-outcome rules

- If target authentication is cancelled or clearly rejected before a server
  deletion job exists and the source session is still current, the fence may be
  released back to the source. No source cleanup occurs.
- If target authentication succeeds but remote reading or merge fails, the
  target remains signed in, local data remains intact, and the transition
  stays fenced at a resumable phase. It never falls back to a blind source
  upload or source deletion.
- After successful target authentication, the app offers **Resume switch** or
  **Finish source cleanup**, never a misleading "cancel back to guest" action.
  If the app is uninstalled or its resume secret is lost, a verified target
  account can request operator-assisted recovery using the recorded transition
  receipt. After independent target-account verification and an auditable human
  review, the server may issue one replacement, one-time recovery authorization
  bound to that target UID, operation, generation, and current phase. Before
  source cleanup begins, that review may cancel the prepared transition and
  preserve the source; after cleanup begins it may only resume/complete it.
  The server retains a bounded, auditable transition receipt and opens an owner
  reconciliation task before expiry; it never silently deletes a merely
  prepared source or leaves a started cleanup without a recorded
  terminal/retention outcome.
- A timeout, connection loss, 5xx, malformed response, or `accepted` response
  from a server operation is **unknown**, not failure. The app queries and
  resumes the same operation. It must not rebind the old FCM token or restart
  old cloud writes.
- Rebinding source push/writes is permitted only after the server explicitly
  proves that no deletion/transition marker was created and the old source auth
  session is still valid. No client-side heuristic may make that decision.
- Once the source cleanup job starts, it cannot be cancelled by a stale
  scheduler. A crash/restart resumes from its stored phase/lease. If target
  sign-in later needs a fresh credential, the app asks for it again without
  repeating source cleanup.

## Cloud-data reconciliation contract

### Canonical data and migration prerequisites

The current bookshelf has both a parent JSON backup and a per-book subcollection
path. The implementation must choose and migrate to one canonical source
before enabling safe replacement. The planned canonical form is a versioned
per-book collection with a bounded manifest; legacy `bookshelf_json` is
read-only migration input and is not written after the migration cutover.
Each item gets schema version, portable canonical hash, revision/updated time,
and deletion tombstone/watermark so a stale device cannot resurrect a deletion.

Large or unbounded SRS, custom-pack, and bookshelf JSON must not be treated as
one unbounded `users/{uid}` document. Before a migration is complete, a size
preflight returns typed `tooLarge` and blocks automatic upload rather than
partially overwriting data. The migration uses versioned chunks/subcollections
plus a bounded completion manifest; Firestore's document-size and transaction
limits are release gates, not conditions to discover after switching accounts.

### Domain rules

- **Core progress:** preserve existing monotonic numeric/set rules, validate
  schema and bounds, and commit only with the remote revision still current.
- **Pack progress:** one pure `mergePackProgress(local, remote, catalog)` is
  shared by pull, push, and migration. The shipped catalog defines
  `wordsTotal`; learned counts are clamped to it. Status ordering, accuracy
  ranges, earliest valid `clearedAt`, and the documented counter policy are
  deterministic. It is never a raw remote overwrite or a maximum of arbitrary
  totals.
- **SRS:** raw JSON equality is not a merge algorithm. The implementation must
  either introduce card mutation/event IDs and a deterministic fold, or block
  divergent same-card histories with a clear resolution UI. It may not silently
  choose one device's review history.
- **Custom packs:** normalize portable content before comparing hashes. A
  divergent same-ID pack is never overwritten. An explicit, user-confirmed
  clone with a new ID may preserve both where safe; the fixed quick-pack ID
  requires semantic word-ID deduplication rather than generic cloning.
- **Bookshelf:** merge legacy parent input and canonical items during migration,
  honor tombstones, and preserve image references only locally. Managed-media
  garbage collection is disabled until the final local snapshot/merge result is
  durable.
- **Conflict:** an unsupported or malformed conflict blocks automatic upload,
  persists a typed safe conflict record, and offers retry/export/explicit
  resolution. It never replaces either side silently.

All writes use a server revision/CAS or a staged manifest. The first upload is
allowed only when every canonical domain reports authoritative `absent`; a
mixture of absent and unavailable/invalid remains fenced. Manual backup uses
the same merge and conflict rules, never the former blind `CloudSync.backup()`.

## RevenueCat, push, and Gye identity policy

- The existing `FirebaseAuth.userChanges()`-driven RevenueCat binder is made
  transition-aware. During a replacement it neither calls `Purchases.logIn`
  nor aliases a source anonymous purchaser to the target by accident.
- Before release, the owner must choose and document the intended entitlement
  policy for a source anonymous purchaser versus the target existing account.
  The coordinator then performs only the corresponding explicit `logOut`/
  `logIn` sequence after target activation, with a RevenueCat sandbox test that
  proves no unintended alias, transfer, or entitlement loss.
- Gye streams, cached state, and in-flight community actions carry the session
  epoch and stop across a transition. Until the source cleanup receipt is
  complete, target Gye join/create/share/push actions remain disabled.
- FCM token ownership is removed from the source by the server cleanup job and
  bound to the target only after that receipt. A failed/unknown cleanup cannot
  cause an old-token rebinding race.

## Server-owned full-account deletion

### Authorization

Replace client-created `account_deletions` markers, client recursive Firestore
deletion, and client `FirebaseUser.delete()` as the full-account path. Firestore
rules deny client create/read/update/delete for deletion jobs and recovery
proofs. The app asks a scoped `europe-west3` callable endpoint to start or
inspect its own job; the worker uses a dedicated least-privilege service
account.

- For Google/Apple-linked accounts, the server accepts only an `Authorization`
  header ID token, calls `verifyIdToken(..., checkRevoked: true)`, derives the
  UID only from that token, and requires an actual provider reauthentication
  followed by force refresh. The server enforces the resulting token's short
  `auth_time` window; force refresh alone is not reauthentication. No UID in a
  URL or request body is trusted.
- An anonymous account has no provider reauthentication path. Its in-app
  request therefore requires explicit destructive confirmation, a valid
  unrevoked self token issued within a short server-checked `iat` window, App
  Check as an additional control, and per-UID/per-device rate limits. App Check
  supplements, never replaces, Firebase-auth authorization.
- Apple authorization-token revocation is an irreversible job phase. A fresh
  Apple credential is used only in memory for that immediate call; it is never
  recorded. The server creates the deletion job first. If Apple revocation has
  succeeded, later failure leaves the job resumable and the UI accurately says
  deletion is pending rather than claiming that the still-live Firebase account
  is usable or deleted.

### Deletion job lifecycle and data inventory

The server persists an opaque operation ID, generation, phase, lease/attempt
data, and sanitized outcome — not raw secrets. The minimum state machine is:

`requested → user_tree_deleting → auth_deleted → community_cleanup_pending → processor_cleanup_pending → completed`

The worker performs external calls outside Firestore transactions, with a
lease, idempotent checkpoints, page/chunk processing, and retries. A retry
after `auth/user-not-found` treats Auth deletion as complete. A tombstone
scheduler distinguishes an owner-cancelled pre-start request from an
already-started server job and must never delete an active job merely because
it looks old.

The inventory is explicit and is processed even if `users/{uid}` does not
exist: the complete user tree and backup subcollections; shared packs authored
by the UID; Gye membership/ownership/contributions/reports/reactions/bans and
notification outboxes; FCM token ownership; recovery proofs; transition
records; and Firebase Auth. The Gye `on_user_deleted` trigger may invoke the
same idempotent cleanup routine, but the deletion job itself owns a cleanup
receipt so a missing parent user document cannot skip cleanup. A job reports
pending while that receipt is incomplete; it never reports success just after
deleting an Auth user.

RevenueCat is a separate processor step because the app associates an initial
anonymous RevenueCat identity and later Firebase UID with purchase data. Before
release, configure and verify either a server-only RevenueCat erasure action or
an owner-operated, tracked processor workflow with a declared response window,
retention exception, and completion recording. In-app deletion initiates that
work; users are not required to phone or email to complete the app's primary
deletion flow. Store billing/cancellation remains separate and is clearly
explained.

The app performs local privacy cleanup only after the server reports the
required remote job state. It then creates a new unrelated anonymous identity
for continued local use. If post-delete local cleanup fails, the app reports a
sanitized aggregate failure and never claims complete local cleanup.

## Public web deletion route and recovery proof

Because an account-creating Android app needs both an in-app path and a working
web request path, the public deletion page provides two real routes:

1. A self-service proof route for a recovery token the user explicitly copied
   while signed in.
2. A functional, operator-owned minimal request form for a person who no
   longer has the app/token. It explains the identity-verification process,
   contact channel, required minimum information, response window, and records
   a request without promising that an unverified guest description can locate
   an account. The owner must staff and test this route before release.

The app requests a single active 256-bit random proof from the server. The
server stores only its SHA-256 hash, bound UID, issued/expiry time, and
operation state; it never accepts an arbitrary client-created proof record.
The raw proof is shown only for explicit copy/share and is not stored by
default. If durable storage is required for recovery, use platform secure
storage plus Android/iOS backup exclusion. New issuance rotates/revokes the
old proof and is rate limited.

The copied URL uses a fragment, for example
`https://hangul-sori.com/account-deletion.html#token=<raw-token>`. The page
parses it locally, immediately removes it with `history.replaceState`, and
POSTs JSON only to the public endpoint. The endpoint atomically claims the
valid, unexpired proof and creates/reuses the same UID-bound deletion operation
before doing any deletion. A repeated proof request resumes that operation;
response loss cannot strand a user after token consumption. Hard expiry is
enforced by endpoint logic; database TTL is cleanup only.

The static page and endpoint require HTTPS/HSTS, exact CORS-origin allowlists,
no wildcard credentials, `Cache-Control: no-store`, `Referrer-Policy:
no-referrer`, a restrictive CSP, no third-party scripts/analytics, request-size
limits, rate limits, generic non-enumerating responses, and redaction of URL,
headers, body, and exception details. Hosting/CDN/proxy logging and retention
are verified separately; fragment behavior alone is not considered proof of
secrecy.

## Documentation, operations, and release gates

- Rewrite EN/DE/KO policy and deletion pages only after the endpoints and
  processor workflow are deployed and verified. Until then, they must not call
  the route "current release" behavior or promise Gye/RevenueCat completion.
- Correct Play disclosures for RevenueCat purchase history and the initial
  anonymous-to-Firebase identity association; disclose the OS-selected
  `flutter_tts` fallback; use the correct Apple authorization-token revocation
  wording; and include book **and** word images in DE/KO reset text.
- Include the current Xcode 26+/iOS 26 SDK upload requirement in the App Store
  runbook, but verify the exact live requirement before submission.
- Add ownership, sanitized operation metrics, alerts, retry/dead-letter
  handling, a manual reconciliation runbook, and a public-page version/header
  release check. Do not emit UIDs, proofs, Apple codes, or ID tokens to logs,
  analytics, or Crashlytics.
- CI must run Functions unit tests, Rules tests, Flutter tests/analyze, release
  AAB signing inspection, static HTML UTF-8/tab/header checks, secret scans,
  and endpoint contract tests. A signed iOS archive/TestFlight test and a
  signed Android real-device test remain external gates.

## Required verification matrix

- Unit/emulator red/green tests for every state-machine phase, restart, lease,
  retry, timeout, generic response, concurrent proof request, proof rotation/
  expiry, and client-rule denial.
- Collision tests for normal same-UID link; anonymous collision; target cancel;
  target credential expiry; target remote unavailable/invalid/absent; CAS
  conflict; source-cleanup timeout; restart at every phase; and no old-token
  rebind on unknown outcome.
- Writer-fence tests that invoke CloudSync, pack progress, bookshelf, custom
  packs, Gye, FCM, RevenueCat, and stale listeners during every transition
  phase; none may write/bind the wrong UID.
- Data tests for two-device concurrent merge, canonical bookshelf migration,
  deletion tombstone non-resurrection, divergent SRS/custom/quick-pack cases,
  pack catalog totals, payload-size preflight, media retention, and a source
  user document that is absent but still owns shared/community data.
- Deletion tests for anonymous and durable accounts, fresh-auth checks, Apple
  revocation partial failure, `auth/user-not-found`, parent-document absence,
  Gye owner cleanup/retry, processor pending/completion, and no secret leakage.
- Before store submission, deploy to a controlled environment and exercise
  Google and Apple collision/deletion paths, web proof/form path, App Check,
  hosting headers/log redaction, cleanup trigger behavior, RevenueCat sandbox
  identity behavior, and real Android/iOS builds. Use test accounts only.

## External owner decisions and blockers

- A verified legal controller name and serviceable postal address are still
  required for `docs/impressum.html`; no address is invented.
- The owner must supply and test the public web-form operator, response window,
  hosting/CDN configuration, exact permitted origins, and log-retention policy.
- The owner must choose the RevenueCat entitlement and erasure operating model,
  provide any server-only credentials through approved secret management, and
  verify it against the production project/sandbox.
- Live Firebase/Auth anonymous-cleanup settings, Function IAM/service-account
  privileges, Firestore indexes, deployed Gye cleanup trigger, Apple/Google
  console configuration, processor locations/retention, Android upload key,
  and iOS signing/archive remain external release gates.
- The callable deletion/transition functions must have App Check enforcement
  enabled in their deployed configuration, with Android Play Integrity and iOS
  App Attest/DeviceCheck providers verified on signed release builds. Invocation
  IAM, exact CORS origins for the separate public endpoint, and the verifier
  service-account role are deploy gates, not merely test assumptions.
