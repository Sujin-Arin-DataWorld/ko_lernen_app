# Task 11 production audit remediation report

## Status

Task 11 is implemented and all required local automated gates pass. The two
Important findings from the first independent review were corrected and the
same reviewer explicitly approved the follow-up diff with no remaining
Critical or Important findings.

No Firebase deployment, branch integration, push, beta publication, AAB build,
or signing action occurred.

## Production changes

- Feedback submission now checks both server-owned deletion state sources in
  the same Firestore transaction before any feedback, passport, or quota write:
  `account_deletions/{uid}` and the authoritative per-UID
  `account_operation_owners/{sha256}` mapping plus its referenced
  `account_operations/{operationId}` document. Active deletion operations and
  replacement source-cleanup phases fail closed with the safe
  `account-deletion-active` code.
- A deterministic cross-runtime regression starts with the real
  `requestAccountDeletion` handler and proves that the resulting authoritative
  operation blocks feedback before a worker creates a deletion marker. A
  second regression proves that a feedback transaction observes a concurrently
  committed deletion intent on retry and makes no feedback write.
- The server enforces 20 newly accepted completions per rolling 24 hours for
  each authenticated UID and verified App Check app ID. The private counter is
  stored at
  `users/{uid}/tester_feedback_rate_limits/{sha256(appId)}` using only server
  time. Same-feedback retries and duplicate-completion acknowledgements consume
  no slot. The 21st completion returns the safe
  `feedback-rate-limit-exceeded` resource-exhausted response.
- Firestore rules explicitly deny all client access, including nested access,
  to `tester_feedback_rate_limits` and exclude that collection from generic
  owner fallbacks.
- The client has an injectable read-only passport reader. Production reads only
  `users/{authenticatedUid}/tester_passport/state`, rechecks the authenticated
  UID after the asynchronous read, validates the shared catalog version and
  ordered known mission IDs, and converts missing, malformed, foreign, or
  failed reads to an empty state without exposing UID, errors, or feedback text.
- Passport response parsing now carries an explicit
  `passportStateAuthoritative` flag through client, service, and card. A valid
  delivered response immediately replaces restored state; malformed response
  metadata can no longer cancel or erase valid restored progress.
- The existing controller scope supplies the stable read-only passport reader.
  Cards restore on a new completion/session while stale in-flight reads cannot
  overwrite an authoritative delivered response. A disabled feature gate
  performs no passport read.
- Korean `docs/privacy.html` content now states the same optional structured
  and free-text feedback, Firebase UID association, metadata, no-raw-answer or
  device-ID, recipient, and account-deletion facts as English and German. No
  Korean app UI localization was added.
- Grammar level/type/difficulty filtering now clears the explicit interaction
  set and resets the feedback completion slot. Finish after a filter change
  reports only interactions from the current filtered study context.

## TDD evidence

The new regressions were observed failing before their production changes:

- a concurrent authoritative deletion operation was not observed;
- feedback submitted immediately after `requestAccountDeletion` did not return
  the required deletion fence;
- a 21st new completion was accepted;
- the private rate-limit collection was client-accessible through fallback
  rules;
- the passport production API and restoration behavior were absent;
- malformed delivered passport metadata erased valid restored progress;
- the Korean privacy parity assertion failed;
- Grammar Finish remained enabled after a filter changed the study set.

Each targeted regression passed after its corresponding implementation.

## Final verification

- `node --test tester_feedback_runtime.test.js account_operations_runtime.test.js`
  — 123/123 passed.
- Focused Flutter feedback/passport/privacy/Grammar suite — 74/74 passed.
- `npm.cmd test` in `functions/gye` — 247/247 passed.
- Firestore Emulator `npm.cmd run test:rules` with the Android Studio JBR on
  this process's `PATH` — 41/41 passed; emulator shut down normally.
- `flutter test --no-pub` — 1,328/1,328 passed.
- `flutter analyze --no-pub` — no issues found.
- `git diff --check` — exit 0; only Git's existing LF-to-CRLF checkout warnings
  were printed.
- Independent read-only re-review — explicit approval, no remaining Critical or
  Important findings.

## Release boundary and remaining manual validation

This work is source-, unit-, widget-, analyzer-, and emulator-verified only. It
does not establish live Firebase deployment state, Firebase Console state,
real App Check behavior, physical-device behavior, release signing, or beta AAB
contents. Those remain release-handoff activities after the isolated commit is
integrated through the parent workflow.

The pre-existing untracked
`docs/superpowers/plans/2026-07-31-content-feedback-implementation.md` file was
not edited or staged.
