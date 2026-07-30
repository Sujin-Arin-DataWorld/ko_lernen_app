# Task 6 report: server-owned deletion worker and restrictive rules

## Status

Complete for the mock/injected release-hardening boundary. No function, rule,
credential, Apple service, Auth deletion, Firestore deletion, or processor
cleanup was deployed or invoked against a live project.

The production entrypoint is deliberately fail-closed for the Apple,
user-tree, community, and processor destructive adapters until those adapters
are supplied and verified for a live deployment.

## Changed files

- `functions/gye/account_operations.js`
  - Corrected the Apple-linked deletion order so revocation is required before
    Firebase Auth deletion.
- `functions/gye/account_operations.test.js`
  - Added the Task 3 compatibility regression for the corrected ordering.
- `functions/gye/account_operations_runtime.js`
  - Added transactionally fenced worker claim, renewal, progress checkpoint,
    page cursor, and server-owned marker persistence.
  - Added the paged/idempotent deletion runtime with injected Firestore/Auth,
    community, and processor adapters.
  - Added the authenticated `completeAppleRevocation` transient-code boundary,
    safe resumable failure metadata, and response-loss recovery.
  - Added legacy tombstone isolation for server-owned markers.
- `functions/gye/account_operations_runtime.test.js`
  - Added runtime tests for Apple success/failure, Apple/Auth response-loss
    recovery, lease renewal/fencing, worker replay, Auth user-not-found, paging,
    explicit cleanup phases, and legacy marker isolation.
- `functions/gye/index.js`
  - Exported the protected Apple callable and scheduled server worker.
  - Kept all unprovisioned destructive/Apple adapters fail-closed.
  - Prevented the legacy user-delete trigger and tombstone scheduler from
    claiming server-owned operations.
- `functions/gye/firestore.rules.test.js`
  - Updated emulator coverage for server-only markers/root deletion and
    owner-only single-operation status reads.
- `functions/gye/package.json`
  - Added the focused `test:deletion-worker` script.
- `firestore.rules`
  - Denied client create/update/delete on `account_deletions`.
  - Denied client root `users/{uid}` deletion.
  - Allowed only owner `get` for deletion marker/operation polling; denied
    list and all client writes.

No plan, ledger, Flutter, public HTML, hosting rewrite, or live configuration
was modified.

## RED evidence

The prescribed focused command was run after the Task 6 tests were added and
before the runtime implementation:

```text
npm.cmd test -- --test account_operations_runtime.test.js
tests 108
pass 97
fail 11
```

All failures were the expected absent Task 6 contracts: missing
`completeAppleRevocation`, worker runtime, lease repository methods, legacy
isolation helper, and index exports.

The Apple ordering regression was then run before changing the Task 3 graph:

```text
node --test account_operations.test.js
tests 16
pass 15
fail 1
Missing expected exception
```

The server-marker UID-key and Apple/Auth response-loss regressions were also
observed failing before their corresponding fixes.

## GREEN evidence

Fresh full Node verification:

```text
npm.cmd test
tests 111
pass 111
fail 0
```

Focused worker/state-machine verification:

```text
npm.cmd run test:deletion-worker
tests 55
pass 55
fail 0
```

Firestore rules compiled and executed in the local emulator after prepending
the already-installed Android Studio JBR to `PATH`:

```text
$env:Path = 'C:\Program Files\Android\Android Studio\jbr\bin;' + $env:Path
npm.cmd run test:rules
tests 32
pass 32
fail 0
```

The requested direct command was also checked:

```text
firebase firestore:rules:compile --project demo-project-id
Error: firestore:rules:compile is not a Firebase command
```

The emulator load is therefore the available offline rules compile/evaluation
gate. Java 21.0.10 was already installed; no SDK or license action occurred.

Syntax checks for both account-operation modules/tests and `index.js`, JSON
parsing for `package.json`, and `git diff --check` all exited zero.

## Worker and Apple safety review

- Every destructive page/phase runs outside a Firestore transaction only after
  a transactionally claimed and renewed lease. Checkpointing revalidates the
  operation version, worker identity, lease version, and lease expiry.
- A checkpoint releases the lease while monotonically advancing its version.
  A lost checkpoint replays the same idempotent page/phase; no cursor is
  advanced speculatively.
- Auth `user-not-found` is terminal success. Other Auth failures leave the
  phase resumable.
- Apple-linked operations enter `appleRevocationPending` before Auth deletion,
  preserving a valid authenticated client boundary for the transient code.
- Raw Apple authorization codes are passed only to the injected revoker. They
  are never persisted, logged, returned, or included in errors.
- A successful revocation persists only
  `appleRevocationComplete: true`. This lets the server worker recover an Auth
  deletion/checkpoint response-loss window without a deleted user's token.
- A revocation failure persists only
  `apple-revocation-retryable` and leaves the operation pending; it never
  reports deletion complete.
- Completion follows community/Gye cleanup and processor cleanup. The legacy
  root-delete trigger exits for server-owned markers, so it cannot race or
  certify the explicit worker phases.
- Server markers use `account_deletions/{sourceUid}`, carry
  `serverOwned: true` plus the opaque operation ID, and are always retained by
  legacy tombstone maintenance.
- Firestore rules preserve unrelated access while denying client ownership of
  all destructive account-operation writes.

## Commit

`feat(functions): add server-owned deletion worker and rules`

This report is included in that Task 6 commit.

## External gates and concerns

- Live Apple revocation needs a verified provider adapter that consumes only
  the transient authorization code and treats already-revoked responses
  idempotently. No permanent fallback credential/key was added.
- Live user-tree paging, Gye/community cleanup, and processor cleanup adapters
  remain deliberately unavailable in `index.js`; the scheduled worker fails
  closed until they are supplied and integration-tested.
- Firestore emulator tests cover rules and real transaction state changes
  without cloud credentials. Production transaction contention, scheduler
  retries, IAM, App Check, Apple service behavior, Auth token invalidation, and
  destructive-adapter idempotency remain deployment-stage integration gates.
- The worker lease is 60 seconds. Each live page/phase adapter must remain
  bounded below that lease or add an adapter-specific renewal strategy before
  deployment.
