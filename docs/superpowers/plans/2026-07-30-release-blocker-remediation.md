# Release Blocker Remediation Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (- [ ]) syntax for tracking.

**Goal:** Remove the audited release blockers so account cleanup, cloud backup lifecycle, and iOS Firebase setup either complete safely or remain explicitly blocked with a resumable user-visible state.

**Architecture:** The existing account-operation state machine remains the authority for full account deletion and anonymous-account replacement. New concrete Firestore/Admin adapters execute its leased cleanup phases, while queue classes receive independent due-work budgets. A small server-owned cloud-backup-delete operation uses the same identity/App Check boundary and client session journal pattern; first durable link and Settings consume typed results instead of assuming success.

**Tech Stack:** Flutter/Dart, Firebase Auth/Firestore/Functions v2/App Check, Node.js 22, Firebase Admin SDK, Firestore emulator tests, Flutter widget/service tests, Firebase Secret Manager parameters.

## Global Constraints

- Do not log, persist, render, or put in a URL any ID token, Apple authorization code, raw deletion proof, private key, or secret value.
- Every protected callable keeps enforceAppCheck: true and consumeAppCheckToken: true; Flutter callers pass HttpsCallableOptions(limitedUseAppCheckToken: true).
- Never re-enable a cloud-write session after an unknown remote deletion outcome; persist a UID-bound journal and only resume that same operation.
- All Firestore root deletion remains server-only. A client must not regain direct User.delete() or root-document delete permission.
- Do not add credentials, Firebase config identifiers, Apple team data, provisioning files, or RevenueCat keys to Git.
- Use TDD for each behavior change, run the narrow test before and after the change, commit each accepted task, and request an independent read-only review after every task.
- Do not deploy, push this follow-up branch, accept Android licenses, set Firebase secrets, create an Apple/Firebase resource, or upload a store build.

---

### Task 1: Fair, due-only account-operation scheduler

**Files:**
- Modify: functions/gye/account_operations_runtime.js:32-82 and createFirestoreAccountOperationRepository
- Modify: functions/gye/account_operations_runtime.test.js
- Modify: firestore.indexes.json
- Modify: functions/gye/index.js:account_deletion_worker

**Interfaces:**
- Produces fetchActionableDeletionCandidates({ collection, limit, nowMillis }) that reserves queue capacity for replacement cleanup, normal deletion phases, and completed Apple checkpoints.
- Produces repository method recordDeletionWorkFailure({ operationId, workerId, operationVersion, leaseVersion, safeCode, nowMillis }) that only records a safe status code and nextAttemptAtMillis.
- Scheduler calls recordDeletionWorkFailure after a worker failure and never logs the original error object.

- [ ] **Step 1: Write the failing Node tests for queue isolation and backoff**

~~~
test("replacement backlog cannot exclude a due deletion candidate", async () => {
  const candidates = await fetchActionableDeletionCandidates({
    collection: fakeOperationsWith({ replacements: 80, deletions: 1, nowMillis: NOW }),
    limit: 50,
    nowMillis: NOW,
  });
  assert(candidates.some((candidate) => candidate.id === "due-deletion"));
});

test("failed worker work is deferred with a safe code", async () => {
  await repository.recordDeletionWorkFailure({
    operationId: requested.operationId,
    workerId: claim.workerId,
    operationVersion: claim.operation.version,
    leaseVersion: claim.leaseVersion,
    safeCode: "worker-failed",
    nowMillis: NOW,
  });
  assert.equal(stored.deletionProgress.statusCode, "worker-failed");
  assert(stored.nextAttemptAtMillis > NOW);
});
~~~

- [ ] **Step 2: Run test to verify it fails**

Run: npm.cmd test -- --test-name-pattern "replacement backlog|failed worker work"

Expected: FAIL because the mixed 50-document query excludes the deletion or the repository method is absent.

- [ ] **Step 3: Write minimal implementation**

~~~
const QUEUE_BUDGETS = Object.freeze({ replacement: 20, deletion: 20, apple: 10 });

async function fetchActionableDeletionCandidates({ collection, nowMillis, limit = 50 }) {
  const budget = scaleQueueBudgets(limit, QUEUE_BUDGETS);
  const [replacement, deletion, apple] = await Promise.all([
    collection.where("kind", "==", "replacement")
      .where("phase", "==", "sourceCleanupPending")
      .where("nextAttemptAtMillis", "<=", nowMillis)
      .orderBy("nextAttemptAtMillis").orderBy("updatedAtMillis")
      .limit(budget.replacement).get(),
    collection.where("kind", "==", "deletion")
      .where("phase", "in", NORMAL_DELETION_PHASES)
      .where("nextAttemptAtMillis", "<=", nowMillis)
      .orderBy("nextAttemptAtMillis").orderBy("updatedAtMillis")
      .limit(budget.deletion).get(),
    collection.where("phase", "==", "appleRevocationPending")
      .where("deletionProgress.appleRevocationComplete", "==", true)
      .where("nextAttemptAtMillis", "<=", nowMillis)
      .orderBy("nextAttemptAtMillis").orderBy("updatedAtMillis")
      .limit(budget.apple).get(),
  ]);
  return dedupeCandidates([...replacement.docs, ...deletion.docs, ...apple.docs]);
}
~~~

Set nextAttemptAtMillis on every created and transitioned operation, use a capped retry delay, and add the exact composite indexes used by these queries.

- [ ] **Step 4: Run test to verify it passes**

Run: npm.cmd test

Expected: PASS; no emitted record contains a raw adapter/provider error.

- [ ] **Step 5: Commit**

~~~
git add functions/gye/account_operations_runtime.js functions/gye/account_operations_runtime.test.js functions/gye/index.js firestore.indexes.json
git commit -m "fix(functions): schedule account cleanup fairly"
~~~

### Task 2: Persistent, paged Firestore user-tree deletion adapter

**Files:**
- Create: functions/gye/deletion_adapters.js
- Create: functions/gye/deletion_adapters.test.js
- Modify: functions/gye/index.js:accountDeletionWorkerRuntime construction
- Modify: functions/gye/account_operations_runtime.js only if the existing page result needs a typed cursor version marker

**Interfaces:**
- Produces createFirestoreDeletionAdapters({ firestore, markerCollection, pageSize }).
- deleteUserTreePage({ uid, operationId, cursor, limit }) returns { done: boolean, nextCursor: string|null }.
- captureCommunityTargets({ uid, operationId }) preserves only normalized Gye IDs in the server-owned marker before deleting the user root.

- [ ] **Step 1: Write the failing adapter tests with a nested fake Firestore tree**

~~~
test("persists child work before deleting its parent page", async () => {
  const page = await adapters.deleteUserTreePage({
    uid: "source", operationId: "op", cursor: null, limit: 1,
  });
  assert.equal(page.done, false);
  assert.deepEqual(fake.pendingWork("op"), [
    "users/source/packs",
    "users/source/packs/p1/items",
  ]);
  assert.equal(fake.documentExists("users/source/packs/p1"), false);
});

test("deletes the root only after no pending work remains", async () => {
  await drainPages(adapters, { uid: "source", operationId: "op" });
  assert.equal(fake.documentExists("users/source"), false);
});
~~~

- [ ] **Step 2: Run test to verify it fails**

Run: node --test deletion_adapters.test.js

Expected: FAIL with Cannot find module './deletion_adapters'.

- [ ] **Step 3: Write minimal implementation**

~~~
function workId(collectionPath) {
  return createHash("sha256").update(collectionPath, "utf8").digest("hex");
}

async function deleteUserTreePage({ uid, operationId, cursor, limit }) {
  await seedRootCollectionWork(uid, operationId);
  const job = await claimOnePendingCollection(operationId);
  if (job) return processCollectionPage(job, { operationId, limit });
  await seedAnyLateRootCollections(uid, operationId);
  if (await hasPendingCollectionWork(operationId)) {
    return { done: false, nextCursor: "work-v1" };
  }
  await firestore.collection("users").doc(uid).delete();
  return { done: true, nextCursor: null };
}
~~~

processCollectionPage must list each document's child collections before writing deterministic child jobs and deleting the document in bounded chunks. Its cursor is an opaque version marker, never a user-supplied path.

- [ ] **Step 4: Run test to verify it passes**

Run: node --test deletion_adapters.test.js account_operations_runtime.test.js

Expected: PASS; no destructive-adapter-unavailable code remains in production wiring.

- [ ] **Step 5: Commit**

~~~
git add functions/gye/deletion_adapters.js functions/gye/deletion_adapters.test.js functions/gye/index.js functions/gye/account_operations_runtime.js functions/gye/account_operations_runtime.test.js
git commit -m "feat(functions): page server-owned user deletion"
~~~

### Task 3: Reusable Gye and processor cleanup adapters

**Files:**
- Create: functions/gye/deletion_cleanup_adapters.js
- Create: functions/gye/deletion_cleanup_adapters.test.js
- Modify: functions/gye/index.js:on_user_deleted and worker construction
- Modify: functions/gye/runtime.js only when exposing a pure reusable cleanup primitive is necessary

**Interfaces:**
- createDeletionCleanupAdapters({ firestore, fieldValue, cleanupGyeForDeletedUser, ... }) exposes cleanupCommunity({ uid, operationId }) and cleanupProcessor({ uid, operationId }).
- Both functions are idempotent. cleanupCommunity consumes preserved marker IDs plus collection-group discovery; cleanupProcessor deletes only owned shared packs, processed packs, and owned notification outboxes.

- [ ] **Step 1: Write the failing tests for legacy Gye IDs, collection-group discovery, and retry**

~~~
test("community cleanup retains a pre-root legacy Gye target", async () => {
  await adapters.cleanupCommunity({ uid: "source", operationId: "op" });
  assert.deepEqual(fake.reconciledGyes, ["legacy-gye", "discovered-gye"]);
});

test("processor cleanup is idempotent and deletes only source-owned documents", async () => {
  await adapters.cleanupProcessor({ uid: "source", operationId: "op" });
  await adapters.cleanupProcessor({ uid: "source", operationId: "op" });
  assert.equal(fake.foreignDocumentDeleted, false);
});
~~~

- [ ] **Step 2: Run test to verify it fails**

Run: node --test deletion_cleanup_adapters.test.js

Expected: FAIL because cleanup lives only inside the trigger and worker adapters are unavailable.

- [ ] **Step 3: Write minimal implementation**

~~~
const cleanupAdapters = createDeletionCleanupAdapters({
  firestore: db,
  fieldValue: admin.firestore.FieldValue,
  cleanupGyeForDeletedUser,
  anonymizeGyeIdentity,
  reconcileMembershipAfterDeletion,
  cleanupOrphanedGyeTree,
  commitDocumentChunks,
});

const accountDeletionWorkerRuntime = createDeletionWorkerRuntime({
  repository: accountOperationRepository,
  auth: admin.auth(),
  deleteUserTreePage: deletionAdapters.deleteUserTreePage,
  cleanupCommunity: cleanupAdapters.cleanupCommunity,
  cleanupProcessor: cleanupAdapters.cleanupProcessor,
});
~~~

The legacy on_user_deleted trigger must call the same adapters only for non-server-owned marker paths and retain its old completion receipt behavior.

- [ ] **Step 4: Run test to verify it passes**

Run: npm.cmd test

Run: $env:JAVA_HOME='C:\Program Files\Android\Android Studio\jbr'; $env:Path='C:\Program Files\Android\Android Studio\jbr\bin;'+$env:Path; npm.cmd run test:rules

Expected: PASS; the emulator still rejects client writes to server-owned cleanup documents.

- [ ] **Step 5: Commit**

~~~
git add functions/gye/deletion_cleanup_adapters.js functions/gye/deletion_cleanup_adapters.test.js functions/gye/index.js functions/gye/runtime.js
git commit -m "feat(functions): execute leased community cleanup"
~~~

### Task 4: Apple revoke adapter using bound secrets only

**Files:**
- Create: functions/gye/apple_revocation_adapter.js
- Create: functions/gye/apple_revocation_adapter.test.js
- Modify: functions/gye/index.js
- Modify: functions/gye/account_operations_runtime.test.js
- Modify: docs/release-readiness.md

**Interfaces:**
- createAppleRevocationAdapter({ getClientId, getTeamId, getKeyId, getPrivateKey, fetch, nowSeconds }) returns revokeAppleAuthorizationCode({ authorizationCode }).
- The adapter sends client_id, a 5-minute ES256 client-secret JWT, client_secret, token, and token_type_hint=authorization_code to https://appleid.apple.com/auth/revoke.

- [ ] **Step 1: Write the failing unit tests for a redacted success request and safe failure**

~~~
test("posts the transient authorization code without logging or retaining it", async () => {
  const revoke = createAppleRevocationAdapter({ ...fakeSecrets, fetch: fakeFetch });
  await revoke({ authorizationCode: "one-time-code" });
  assert.equal(fakeFetch.url, "https://appleid.apple.com/auth/revoke");
  assert.match(fakeFetch.body, /token=one-time-code/);
  assert.equal(fake.persistence, []);
});

test("invalid secret material fails without returning the authorization code", async () => {
  await assert.rejects(() => revoke({ authorizationCode: "never-log-me" }));
  assert.equal(fakeLogger.entries.join(""), "");
});
~~~

- [ ] **Step 2: Run test to verify it fails**

Run: node --test apple_revocation_adapter.test.js

Expected: FAIL with Cannot find module './apple_revocation_adapter'.

- [ ] **Step 3: Write minimal implementation**

~~~
const appleClientId = defineSecret("APPLE_REVOKE_CLIENT_ID");
const appleTeamId = defineSecret("APPLE_REVOKE_TEAM_ID");
const appleKeyId = defineSecret("APPLE_REVOKE_KEY_ID");
const applePrivateKey = defineSecret("APPLE_REVOKE_PRIVATE_KEY");

const revokeAppleAuthorizationCode = createAppleRevocationAdapter({
  getClientId: () => appleClientId.value(),
  getTeamId: () => appleTeamId.value(),
  getKeyId: () => appleKeyId.value(),
  getPrivateKey: () => applePrivateKey.value(),
  fetch,
});
~~~

Bind all four secrets only to completeAppleRevocation. Throw a generic adapter error for non-2xx responses and never include a response body in logs or HttpsError details.

- [ ] **Step 4: Run test to verify it passes**

Run: npm.cmd test

Expected: PASS, including the existing pending-retry and redaction tests.

- [ ] **Step 5: Commit**

~~~
git add functions/gye/apple_revocation_adapter.js functions/gye/apple_revocation_adapter.test.js functions/gye/index.js functions/gye/account_operations_runtime.test.js docs/release-readiness.md
git commit -m "feat(functions): revoke Apple authorization safely"
~~~

### Task 5: Server-owned cloud-backup deletion with a resumable session journal

**Files:**
- Create: functions/gye/cloud_backup_deletion_runtime.js
- Create: functions/gye/cloud_backup_deletion_runtime.test.js
- Modify: functions/gye/index.js
- Modify: firestore.rules
- Create: lib/services/account/cloud_backup_deletion.dart
- Create: test/services/account/cloud_backup_deletion_test.dart
- Modify: lib/services/auth_service.dart
- Modify: lib/screens/settings_screen.dart

**Interfaces:**
- Server callable deleteCloudBackup accepts only { requestKey }, derives the durable UID from the verified token, and returns { state: "completed" | "pending" } without user-data details.
- CloudBackupDeletionCoordinator.run() persists a UID-bound request key, transitions the exact session to cleanupPending, resumes the same request after restart, and returns CloudWriteResult.completed, stale, or blocked.
- The server operation deletes backup roots packs, quests, bookshelf, custom_packs, custom_words, sync_generations, and sync_metadata, then removes UserDataDeletionCoordinator.backupFields; it preserves gyeIds, blockedUids, and FCM operational fields.

- [ ] **Step 1: Write failing Node and Dart tests for generation deletion and unknown outcomes**

~~~
test("cloud backup deletion removes generations and active metadata but preserves operational fields", async () => {
  const result = await handlers.deleteCloudBackup(callableRequest("durable", { requestKey: "key" }));
  assert.equal(result.state, "completed");
  assert.equal(fake.exists("users/durable/sync_generations/g1/bookshelf/p1"), false);
  assert.equal(fake.exists("users/durable/sync_metadata/bookshelf_active"), false);
  assert.deepEqual(fake.user("durable").gyeIds, ["gye-a"]);
});
~~~

~~~
test('unknown remote outcome keeps the exact session pending', () async {
  final outcome = await coordinator.run();
  expect(outcome, CloudWriteResult.blocked);
  expect(sessions.current!.mode, CloudWriteMode.cleanupPending);
  expect(await journal.read(), isNotNull);
});
~~~

- [ ] **Step 2: Run test to verify it fails**

Run: node --test cloud_backup_deletion_runtime.test.js

Run: flutter test test/services/account/cloud_backup_deletion_test.dart

Expected: FAIL because deleteCloudBackup and CloudBackupDeletionCoordinator are absent.

- [ ] **Step 3: Write minimal implementation**

~~~
final result = await CloudBackupDeletionCoordinator(
  sessions: cloudWriteSessionController,
  currentUid: () => AuthService.cloudBackupUid,
  journalStore: SharedPreferencesCloudBackupDeletionJournalStore(prefs),
  gateway: FirebaseCloudBackupDeletionGateway(),
).run();
~~~

The server persists only uid, a keyed request digest, state, and safe timestamps. Duplicate requests resume the same work and never return document lists. The client never calls _FirestoreUserDataDeletionStore in production.

- [ ] **Step 4: Bind Settings pending UI and remove false success**

~~~
switch (await _cloudBackupDeletion.run()) {
  case CloudWriteResult.completed:
    messenger.showSnackBar(SnackBar(content: Text(t.settingsCloudDeleteDataSuccess)));
  case CloudWriteResult.blocked || CloudWriteResult.stale:
    messenger.showSnackBar(SnackBar(content: Text(t.accountOperationRetryBody)));
}
~~~

Disable cloud backup, restore, link, and a second delete request while the persisted deletion state is pending; expose only retry of the same request.

- [ ] **Step 5: Run test to verify it passes**

Run: flutter test test/services/account/cloud_backup_deletion_test.dart test/widgets/settings_screen_test.dart

Run: flutter analyze

Run: npm.cmd test

Run the Task 3 emulator command.

Expected: PASS; rules continue to reject direct client removal of generations/metadata.

- [ ] **Step 6: Commit**

~~~
git add functions/gye/cloud_backup_deletion_runtime.js functions/gye/cloud_backup_deletion_runtime.test.js functions/gye/index.js firestore.rules lib/services/account/cloud_backup_deletion.dart test/services/account/cloud_backup_deletion_test.dart lib/services/auth_service.dart lib/screens/settings_screen.dart test/widgets/settings_screen_test.dart
git commit -m "fix(cloud): delete backup through a safe operation"
~~~

### Task 6: First durable-link backfill and truthful backup result

**Files:**
- Create: lib/services/account/first_link_backfill.dart
- Create: test/services/account/first_link_backfill_test.dart
- Modify: lib/services/auth_service.dart
- Modify: lib/services/bookshelf_service.dart
- Modify: lib/services/pack_progress_service.dart
- Modify: lib/services/cloud_sync.dart
- Modify: lib/screens/settings_screen.dart
- Modify: test/services/auth_service_test.dart
- Modify: test/services/bookshelf_service_test.dart
- Modify: test/services/pack_progress_service_test.dart

**Interfaces:**
- FirstDurableLinkBackfill.run({ required CloudWriteSession session, required String uid }) uploads a local Bookshelf generation and local pack progress only when the source UID remains the same and no replacement journal exists.
- CloudSync.backupWithResult() is the canonical Settings API. CloudSync.backup() may delegate but must not discard a non-completed result in a UI caller.

- [ ] **Step 1: Write failing tests for normal same-UID link, collision replacement, stale session, and Settings feedback**

~~~
test('same-UID durable link uploads pre-link local bookshelf and packs', () async {
  final result = await backfill.run(session: session, uid: 'source');
  expect(result, CloudWriteResult.completed);
  expect(events, ['bookshelf:source', 'packs:source']);
});

test('existing-account replacement never runs the first-link uploader', () async {
  await transition.confirm(conflict, catalog: catalog);
  expect(events, isEmpty);
});

testWidgets('backup shows success only for a completed cloud result', (tester) async {
  await pumpSettings(backupResult: CloudWriteResult.blocked);
  await tester.tap(find.text('Jetzt sichern'));
  expect(find.text('Backup erfolgreich'), findsNothing);
});
~~~

- [ ] **Step 2: Run test to verify it fails**

Run: flutter test test/services/account/first_link_backfill_test.dart test/services/auth_service_test.dart test/services/bookshelf_service_test.dart test/services/pack_progress_service_test.dart test/widgets/settings_screen_test.dart

Expected: FAIL because activation only sets the session ready and Settings assumes success.

- [ ] **Step 3: Write minimal implementation**

~~~
Future<void> _activateSignedInUser(User? user) async {
  final uid = user?.uid;
  if (uid == null) return;
  final session = cloudWriteSessionController.acquire(uid);
  await firstDurableLinkBackfill.runIfFirstLink(
    uid: uid,
    session: session,
    hasReplacementJournal: _replacementJournalExists,
  );
}
~~~

Preserve the target-reconciliation path. BookshelfService exposes a fenced local-generation upload seam and PackProgressService exposes a fenced saveManyWithResult(getAll().values) seam; neither takes an unbounded or unauthenticated UID.

- [ ] **Step 4: Implement typed Settings feedback and pending-state guard**

~~~
final result = await CloudSync.backupWithResult();
if (result == CloudWriteResult.completed) {
  showBackupSuccess();
} else {
  showRetryableCloudMessage();
}
~~~

The durable action list must be disabled whenever AccountUiPendingState or CloudBackupDeletionJournal is pending.

- [ ] **Step 5: Run test to verify it passes**

Run: flutter test --reporter compact

Run: flutter analyze

Run: dart format --output=none --set-exit-if-changed lib/services/account/first_link_backfill.dart lib/services/auth_service.dart lib/services/bookshelf_service.dart lib/services/pack_progress_service.dart lib/services/cloud_sync.dart lib/screens/settings_screen.dart

Expected: PASS.

- [ ] **Step 6: Commit**

~~~
git add lib/services/account/first_link_backfill.dart test/services/account/first_link_backfill_test.dart lib/services/auth_service.dart lib/services/bookshelf_service.dart lib/services/pack_progress_service.dart lib/services/cloud_sync.dart lib/screens/settings_screen.dart test/services/auth_service_test.dart test/services/bookshelf_service_test.dart test/services/pack_progress_service_test.dart test/widgets/settings_screen_test.dart
git commit -m "fix(sync): backfill local data after first link"
~~~

### Task 7: Localized safe load failures and mounted guards

**Files:**
- Modify: lib/l10n/app_de.arb
- Modify: lib/l10n/app_en.arb
- Modify: lib/l10n/generated/app_localizations.dart
- Modify: lib/l10n/generated/app_localizations_de.dart
- Modify: lib/l10n/generated/app_localizations_en.dart
- Modify: lib/screens/book_result_screen.dart
- Modify: lib/screens/quests_screen.dart
- Modify: lib/screens/vocab_packs_screen.dart
- Modify: lib/screens/vocab_pack_screen.dart
- Create: test/ui_error_redaction_test.dart
- Modify: test/book_analysis_language_test.dart

**Interfaces:**
- AppL10n.loadErrorTryAgain is a localized neutral user message.
- Every audited screen stores AppL10n.of(context).loadErrorTryAgain, never Object.toString().

- [ ] **Step 1: Write the failing widget/source regression tests**

~~~
testWidgets('book analysis failure never renders the raw exception', (tester) async {
  await pumpBookResult(analyzer: (_) => Future.error(StateError('private backend detail')));
  await tester.pumpAndSettle();
  expect(find.text('private backend detail'), findsNothing);
  expect(find.text('Something went wrong. Please try again.'), findsOneWidget);
});

test('all audited loaders use the localized neutral message', () {
  for (final path in auditedScreens) {
    expect(File(path).readAsStringSync(), isNot(contains('e.toString()')));
    expect(File(path).readAsStringSync(), contains('loadErrorTryAgain'));
  }
});
~~~

- [ ] **Step 2: Run test to verify it fails**

Run: flutter test test/book_analysis_language_test.dart test/ui_error_redaction_test.dart

Expected: FAIL because the raw exception text is still stored/rendered.

- [ ] **Step 3: Write minimal implementation**

~~~
if (!mounted) return;
setState(() {
  _loading = false;
  _error = AppL10n.of(context).loadErrorTryAgain;
});
~~~

Add the ARB key in both languages, run flutter gen-l10n, and add missing mounted checks after asynchronous VocabPack loading calls.

- [ ] **Step 4: Run test to verify it passes**

Run: flutter test test/book_analysis_language_test.dart test/ui_error_redaction_test.dart

Run: flutter analyze

Expected: PASS.

- [ ] **Step 5: Commit**

~~~
git add lib/l10n lib/screens/book_result_screen.dart lib/screens/quests_screen.dart lib/screens/vocab_packs_screen.dart lib/screens/vocab_pack_screen.dart test/book_analysis_language_test.dart test/ui_error_redaction_test.dart
git commit -m "fix(ui): redact load failures"
~~~

### Task 8: iOS Firebase configuration validation and release handoff

**Files:**
- Create: tool/verify_ios_firebase_config.dart
- Create: test/ios_firebase_configuration_test.dart
- Modify: docs/store/ios-external-setup.md
- Modify: docs/release-readiness.md
- Modify: docs/release-verification-2026-07-29.md

**Interfaces:**
- dart run tool/verify_ios_firebase_config.dart exits non-zero unless a generated iOS Firebase option exists, ios/Runner/GoogleService-Info.plist exists locally, and Xcode target membership references it.
- The test uses only checked-in fixture/source text; it does not require or expose real Firebase values.

- [ ] **Step 1: Write the failing validation test for the absent iOS option**

~~~
test('release configuration rejects an absent iOS Firebase option', () {
  final result = inspectIosFirebaseConfiguration(
    firebaseOptionsSource: fixtureWithoutIos,
    plistExists: true,
    projectSource: 'GoogleService-Info.plist',
  );
  expect(result.isValid, isFalse);
  expect(result.missing, contains('firebase_options iOS'));
});
~~~

- [ ] **Step 2: Run test to verify it fails**

Run: flutter test test/ios_firebase_configuration_test.dart

Expected: FAIL with an unresolved validator import.

- [ ] **Step 3: Write minimal implementation**

~~~
final result = inspectIosFirebaseConfiguration(
  firebaseOptionsSource: File('lib/firebase_options.dart').readAsStringSync(),
  plistExists: File('ios/Runner/GoogleService-Info.plist').existsSync(),
  projectSource: File('ios/Runner.xcodeproj/project.pbxproj').readAsStringSync(),
);
if (!result.isValid) exitCode = 1;
~~~

The documentation requires flutterfire configure --project "$FIREBASE_PROJECT_ID" --platforms ios after registering the exact case-sensitive bundle ID, then requires review of generated firebase_options.dart before the macOS archive. It never tells a user to commit downloaded plist or credential values.

- [ ] **Step 4: Run test to verify it passes**

Run: flutter test test/ios_firebase_configuration_test.dart

Run: dart run tool/verify_ios_firebase_config.dart

Expected: test PASS; validator exits non-zero locally with an explicit missing-iOS-config message, recorded as an external gate.

- [ ] **Step 5: Commit**

~~~
git add tool/verify_ios_firebase_config.dart test/ios_firebase_configuration_test.dart docs/store/ios-external-setup.md docs/release-readiness.md docs/release-verification-2026-07-29.md
git commit -m "docs(ios): verify Firebase release configuration"
~~~

### Task 9: Full verification, independent review, and release handoff

**Files:**
- Modify: docs/release-verification-2026-07-29.md

- [ ] **Step 1: Run the complete source-level gate**

Run: flutter test --reporter compact

Run: flutter analyze

Run: npm.cmd test from functions/gye

Run: node --test docs/account-deletion-page.test.js

Run: the Task 3 emulator rule command.

Run: git diff --check origin/main...HEAD

Run: dart format --output=none --set-exit-if-changed on every Dart file changed from origin/main...HEAD.

- [ ] **Step 2: Run static safety scans and inspect every non-zero hit**

~~~
rg -n --glob '*.{dart,js}' '(?:currentUser|firebaseUser|user)\??\.delete\(' lib functions
rg -n --glob '*.{dart,js}' '(?:proof|authorizationCode|idToken).*(?:print|log|debugPrint)' lib functions
rg -n --glob '*.dart' '(?:e|error|exception)\.toString\(\)' lib
~~~

Expected: no client Auth delete, proof/token logging, or user-rendered raw exception hit. Data normalization uses must be inspected and documented separately.

- [ ] **Step 3: Ask a fresh independent reviewer to inspect the final diff and all release claims**

Reviewer must check the concrete worker wiring, scheduler fairness, cloud-backup journal, first-link path, no raw error text, no secret leaks, and the separation of source verification from external deployment evidence.

- [ ] **Step 4: Record exact outcomes and external blockers**

The report must state that real Firebase deploy/IAM/secrets, Apple revocation sandbox, Android USB/device, Android licenses/AAB, iOS/macOS/Xcode/TestFlight, App Check, RevenueCat sandbox, and store consoles are not verified until evidence exists.

- [ ] **Step 5: Commit**

~~~
git add docs/release-verification-2026-07-29.md
git commit -m "docs: record remediation verification"
~~~
