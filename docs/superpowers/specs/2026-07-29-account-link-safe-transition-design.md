# Safe account-link transition and account-deletion design

## Decision

When an anonymous Firebase identity tries to link a Google or Apple credential
that already belongs to another Firebase account, the app will use the
user-approved **safe cleanup then switch** flow. It preserves local learning
data, restores the existing account's cloud data before any automatic upload,
and deliberately removes the old anonymous identity's optional cloud identity
data after an explicit confirmation. It does not attempt to silently migrate
Gye membership, shared packs, or notification ownership to a different person
or account.

## Non-negotiable invariants

- Anonymous-only users never passively upload or restore learning progress or
  bookshelf content.
- A credential collision never changes Firebase UID automatically.
- A confirmed replacement never clears local learning data. It warns that the
  old anonymous account's Gye membership, shared packs, and push ownership are
  removed; the user can rejoin/share again after switching.
- Existing cloud data is fetched and merged before any automatic write. No
  account-link flow may overwrite remote data with a fresh-install default.
- The account deletion operation is idempotent, server-authorized, and works
  for an old anonymous account without relying on Firebase's recent-login
  requirement.
- Raw web-deletion secrets never reach Firestore, logs, analytics,
  Crashlytics, cloud backups, URLs sent to the static site, or RevenueCat.
- Local images remain local and portable-media stripping remains unchanged.

## Account-link flows

### Normal link

If the current anonymous Firebase user can be linked to the selected Google or
Apple credential, Firebase retains the same UID. The app then runs cloud
reconciliation. No Gye, sharing, or push ownership transfer is needed because
the UID did not change.

### Existing-credential collision

If Firebase reports that the Google or Apple credential already belongs to a
different account, the app returns a typed `ExistingAccountLinkConflict` and
does not call `signInWithCredential` automatically. The UI explains the
consequence and offers Cancel or **Keep local learning data and switch
accounts**.

On explicit confirmation:

1. The app removes the old UID's push token through the existing
   `PushOwnershipTransitionCoordinator`.
2. It calls the authenticated server account-deletion endpoint for the old
   anonymous UID. That path removes its Firestore account tree and Auth user;
   the existing retryable `on_user_deleted` trigger cleans/anonymizes Gye
   identity and removes old shared-pack/outbox ownership.
3. The app signs in with the already-confirmed existing Google or Apple
   credential inside the same push ownership transition. The coordinator binds
   the token to the new UID only after the switch succeeds.
4. The app reconciles the new durable account's cloud data before enabling any
   automatic backup writes.

If old-account deletion or target sign-in fails, the old token is rebound when
possible and the local learning data remains intact. The app must not claim a
successful switch.

## Server-authorized account deletion

Add a scoped `europe-west3` HTTPS deletion endpoint in the existing Gye
Functions codebase. It has two authentication modes:

- **App request:** a valid Firebase ID token authorizes deletion of only its
  own UID.
- **Web request:** a one-time 256-bit recovery token authorizes deletion of
  the UID bound to its SHA-256 proof record.

For either mode, the endpoint creates or resumes an `account_deletions/{uid}`
marker, recursively deletes the known `users/{uid}` tree, and deletes the
Firebase Auth user with the Admin SDK. Deleting `users/{uid}` intentionally
invokes the existing retryable Gye cleanup trigger. The endpoint is idempotent:
a retry after user-document deletion but before Auth deletion resumes the Auth
delete rather than reporting false success. It returns only a generic outcome,
never another user's UID or account data.

The mobile full-account deletion workflow keeps Apple reauthentication and
authorization-token revocation before server deletion. It performs local
privacy cleanup only after the server confirms the deletion operation. The
existing client-side direct deletion remains unavailable as a silent fallback
when the server endpoint is missing; a release cannot claim guest deletion is
ready until this endpoint is deployed and exercised.

## Web deletion proof

After Firebase sign-in, the app creates a cryptographically random recovery
token and stores only its SHA-256 hash in a narrowly validated
`account_deletion_proofs/{hash}` Firestore record tied to the current UID. The
raw token is held only in local app storage and can be copied from Settings as
a deletion link using a URL fragment:

`https://hangul-sori.com/account-deletion.html#token=<raw-token>`

Fragments are not sent to the static website host. The deletion page reads the
fragment locally and POSTs the token to the server endpoint over HTTPS. The
endpoint hashes it, consumes the matching proof atomically, and starts the
same idempotent deletion flow. The public page also retains the support email
as a fallback, but does not promise that an unverified description of an
uninstalled guest can identify an account.

The proof rules allow an authenticated user to create only a record for their
own UID with a server timestamp; reads, updates, and ordinary deletes are
denied. The server removes/consumes proof records during deletion. The UI never
logs or displays the raw token except in the user's explicit copy/share action.

## Cloud reconciliation

After any successful durable-account link or safe replacement:

1. Fetch the core cloud payload and apply the existing monotonic numeric/set
   restore rules before writing.
2. Merge pack progress per pack ID using monotonic progress: the higher status,
   learned-word count, total, boss accuracy, and attempts win; cleared state
   cannot regress; the earliest valid cleared timestamp is retained.
3. Merge portable structured maps by union. Identical entries are coalesced.
   A same-ID, different-content conflict is reported as a typed conflict and
   blocks automatic upload rather than silently replacing either side.
4. If no cloud document existed, upload local data after the restore attempt.
   If cloud data existed and no typed conflict remains, write only the merged
   state. Every later manual backup uses the same conflict-safe merge rule.

The link UI surfaces a safe failure for a conflict. It never calls the old
blind `CloudSync.backup()` immediately after sign-in. Pack progress is pulled
and reconciled before future fire-and-forget pack writes can occur.

## Documentation changes

- Reword all EN/DE/KO privacy headings so anonymous learning data has no
  **automatic full backup**, while explicitly requested sharing, Gye, analysis,
  and TTS processing remain exceptions.
- Correct Play disclosure of RevenueCat purchase history to collected,
  required when the configured SDK is present, non-ephemeral, and used for app
  functionality/analytics. Treat the initial RevenueCat anonymous ID and its
  later aliasing to the Firebase UID as identifiers requiring disclosure.
- State that Apple revocation revokes the Apple authorization/user token, not
  an account deletion code.
- Disclose the OS-selected `flutter_tts` fallback: it may be local or handled
  by the device-selected speech provider, which must be verified in final store
  answers.
- Qualify Gye cleanup as dependent on deployed and verified Functions.
- Correct German/Korean reset wording to include both managed book and word
  images, and add the current Xcode 26+/iOS 26 SDK App Store upload requirement
  to the store runbook.
- The legal controller name and serviceable postal address remain an external
  owner-provided release blocker; no address will be invented.

## Verification

- Red/green unit tests for collision decision, explicit confirmation, deletion
  ordering/retry, recovery-token hashing/one-time consumption, and rules.
- Node tests for endpoint state transitions and existing Gye cleanup behavior.
- Dart tests for cloud restore-before-write, structured conflicts, pack
  monotonic merge, durable/anonymous access, and push ownership transitions.
- Full Flutter, Functions, rules, formatting, static-analysis, HTML UTF-8/tab,
  stale-claim, diff, and credential scans.
- No deployment, publishing, push, merge, live deletion, or real secret use.

## External release gates

- Deploy and exercise the scoped deletion endpoint plus the existing Gye
  cleanup trigger before claiming guest deletion works in production.
- Supply the verified public legal controller name and serviceable postal
  address for `docs/impressum.html` and match it in the policy and consoles.
- Verify live Firebase/RevenueCat/processor locations, retention, integrations,
  and store answers against the final signed builds.
