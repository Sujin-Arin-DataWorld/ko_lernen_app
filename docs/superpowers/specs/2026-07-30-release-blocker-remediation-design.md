# Release Blocker Remediation Design

## Goal

Make the currently fail-closed account deletion and account-replacement cleanup paths executable, prevent cloud-data loss or false-success UI states, and make iOS Firebase configuration an explicit release requirement.

## Scope and non-goals

This design covers the release blockers found by the 2026-07-30 independent audit:

- server-owned deletion/replacement cleanup adapters and fair worker scheduling;
- Apple authorization revocation through ephemeral request data and Firebase Secret Manager values;
- safe cloud-backup deletion, initial durable-account backfill, and truthful settings feedback;
- user-safe error rendering; and
- iOS Firebase configuration validation and handoff documentation.

It does not deploy Functions, create Firebase/Apple resources, set secrets, accept Android SDK licenses, or submit either store build. Those actions require the account owner and real credentials.

## 1. Server deletion execution

`account_deletion_worker` remains the only component that deletes a source user tree or activates a replacement target. It will receive concrete Admin SDK adapters instead of deliberate `unavailable` stubs.

### Persistent tree work

The worker must not call an unbounded recursive delete for arbitrary user-created Firestore descendants. A `deletion_work` subcollection under the account-operation document will hold deterministic, idempotent collection jobs. A page invocation will:

1. capture the root user's legacy `gyeIds` in the server-owned deletion marker before the root is removed;
2. page one pending collection job by document ID;
3. discover each document's child collections before deleting that document;
4. atomically enqueue deterministic child jobs and delete the current page; and
5. delete the root document only after no pending collection jobs remain.

The adapter returns the existing `{ done, nextCursor }` contract. A crash after a page either leaves a job pending or leaves its deterministic children queued, so retrying cannot skip descendants.

### Community and processor cleanup

The existing `on_user_deleted` cleanup logic will be extracted into reusable server helpers. The leased worker calls the community helper after Auth deletion and the processor helper afterward; the trigger keeps the same helpers for legacy, non-server-owned deletion markers. The worker obtains Gye targets from the preserved marker plus collection-group discovery, then removes memberships/anonymizes Gye references and deletes owned shared-pack, processed-pack, and notification-outbox data. The repository alone marks the marker complete when all worker phases complete.

### Fair scheduler and retries

Replacement cleanup, normal deletion, and completed-Apple-checkpoint work are queried as separate bounded queues. Each scheduled invocation receives a reserved share, so a large backlog in one class cannot starve another. The repository records only safe failure codes and a bounded next-attempt time; queries include only due work in deterministic order. No raw provider, proof, authorization-code, or token value is persisted or logged.

## 2. Apple authorization revocation

The callable keeps the authorization code transient: it is accepted only in the protected, App-Check-consuming callable, passed to a dedicated adapter, and never written to Firestore, local storage, logs, or user-visible errors.

The adapter signs a short-lived Apple client-secret JWT in memory using Firebase Secret Manager values for the private key, Team ID, Key ID, and client ID, then POSTs the code to Apple's revoke endpoint. The callable gets only the needed secret bindings. A rejected or unavailable revoke produces the existing generic resumable state; it cannot advance Auth deletion. Unit tests use an injected fetch function and fake secrets, never live Apple services.

## 3. Cloud backup correctness

The client must not directly delete protected Firestore generations or claim success after a fenced operation is blocked or stale.

Cloud-backup deletion will be a protected server-owned operation for a verified durable UID. It deletes the defined backup fields and all known backup roots, including legacy bookshelf data, generation documents, active metadata, pack progress, quests, custom packs, and custom words, while preserving account-operational fields. Its operation is idempotent and exposes only a typed safe result. The client quiesces the exact cloud-write session while the request is pending and shows success only after the same authenticated UID and session receive a completed result. Unknown outcomes remain resumable rather than re-enabling writes optimistically.

On the first successful durable link of the same Firebase UID, a bounded backfill coordinator snapshots the ready session and uploads existing local bookshelf and pack progress. Existing-account replacement continues to use its reconciliation path and never uses this first-link uploader. Manual backup returns `CloudWriteResult`; Settings reports success only for `completed`, and shows a retryable neutral message for `blocked` or `stale`.

## 4. iOS Firebase configuration

The app continues to initialize through generated `DefaultFirebaseOptions`; iOS is not treated as an optional local-only fallback. The release handoff requires the account owner to register `com.sujinarin.koLernenApp`, run FlutterFire configuration with iOS included, place the generated Apple configuration in the Xcode target, and verify that `firebase_options.dart` contains an iOS option before archive. A repository validation script/checklist fails closed when the generated iOS option or plist target membership is absent. No Firebase identifiers, Apple IDs, private keys, or provisioning data are committed.

## 5. User-safe UI errors

The four load-error screens found by the audit will use a localized neutral message instead of `Object.toString()`. Their existing retry controls remain unchanged. Widget/source-level regression tests must prove a thrown raw exception is not rendered.

## Acceptance criteria

- a replacement and a deletion can reach `completed` with concrete fake Admin adapters and no direct client Auth deletion;
- Apple revoke success, retryable failure, secret validation, and redaction are covered without a live request;
- a backlog of replacement work cannot prevent a deletion candidate from being scheduled;
- cloud-backup deletion covers generation storage and cannot display false success when fenced or unknown;
- first durable link uploads pre-link pack and bookshelf data without running after existing-account replacement;
- the four UI error paths do not render raw exception text;
- full Flutter, Functions, rules, docs, format, and safety gates pass; and
- external deployment, iOS/Android physical-device, App Check, Apple, RevenueCat, IAM, and store-console checks are recorded separately rather than claimed as completed.
