"use strict";

const assert = require("node:assert/strict");
const test = require("node:test");

const {
  OPERATION_PHASES,
  applyAttemptResult,
  cancelReplacementOperation,
  claimDeletionProof,
  createOrReuseOperation,
  normalizeOperation,
  operationResult,
  recordAttempt,
  transitionOperation,
} = require("./account_operations");

const replacementRequest = Object.freeze({
  id: "replacement-op-1",
  kind: "replacement",
  sourceUid: "anonymous-source",
  targetUid: "durable-target",
  requestKey: "replace-request-1",
});

const deletionRequest = Object.freeze({
  id: "deletion-op-1",
  kind: "deletion",
  sourceUid: "deletion-source",
  requestKey: "delete-request-1",
  appleRevocationRequired: true,
});

function createReplacement() {
  return createOrReuseOperation({
    existingOperations: [],
    request: replacementRequest,
  }).operation;
}

function createDeletion() {
  return createOrReuseOperation({
    existingOperations: [],
    request: deletionRequest,
  }).operation;
}

test("exports every persisted account-operation phase", () => {
  assert.deepEqual(OPERATION_PHASES, [
    "prepared",
    "targetVerified",
    "reconciling",
    "sourceCleanupPending",
    "deletionRequested",
    "userTreeDeleting",
    "authDeleted",
    "appleRevocationPending",
    "communityCleanupPending",
    "processorCleanupPending",
    "completed",
    "blocked",
    "cancelled",
  ]);
});

test("cancels only a pre-cleanup replacement with an exact version", () => {
  let operation = createReplacement();
  for (const phase of ["prepared", "targetVerified", "reconciling"]) {
    if (operation.phase !== phase) {
      operation = transitionOperation(operation, {
        toPhase: phase,
        expectedVersion: operation.version,
      });
    }
    const cancelled = cancelReplacementOperation(operation, {
      expectedVersion: operation.version,
    });
    assert.equal(cancelled.phase, "cancelled");
    assert.equal(cancelled.version, operation.version + 1);
    assert.deepEqual(
      cancelReplacementOperation(cancelled, {
        expectedVersion: operation.version,
      }),
      cancelled,
    );
  }

  assert.throws(
    () => cancelReplacementOperation(createReplacement(), {
      expectedVersion: 99,
    }),
    { code: "stale-operation-version" },
  );
  assert.throws(
    () => cancelReplacementOperation(createDeletion(), {
      expectedVersion: 0,
    }),
    { code: "invalid-operation-transition" },
  );
});

test("rejects cancellation after source cleanup has been accepted", () => {
  const cleanupPending = transitionOperation(
    transitionOperation(
      transitionOperation(createReplacement(), {
        toPhase: "targetVerified",
        expectedVersion: 0,
      }),
      { toPhase: "reconciling", expectedVersion: 1 },
    ),
    { toPhase: "sourceCleanupPending", expectedVersion: 2 },
  );

  assert.throws(
    () => cancelReplacementOperation(cleanupPending, {
      expectedVersion: cleanupPending.version,
    }),
    { code: "invalid-operation-transition" },
  );
});

test("allows only the ordered anonymous replacement path", () => {
  let operation = createReplacement();
  for (const phase of [
    "targetVerified",
    "reconciling",
    "sourceCleanupPending",
    "completed",
  ]) {
    operation = transitionOperation(operation, {
      toPhase: phase,
      expectedVersion: operation.version,
    });
    assert.equal(operation.phase, phase);
  }
  assert.equal(operation.version, 4);
});

test("allows only the ordered deletion path including Apple revocation", () => {
  let operation = createDeletion();
  for (const phase of [
    "deletionRequested",
    "userTreeDeleting",
    "appleRevocationPending",
    "authDeleted",
    "communityCleanupPending",
    "processorCleanupPending",
    "completed",
  ]) {
    operation = transitionOperation(operation, {
      toPhase: phase,
      expectedVersion: operation.version,
    });
    assert.equal(operation.phase, phase);
  }
  assert.equal(operation.version, 7);
});

test("requires Apple revocation before Auth deletion for Apple-linked accounts",
() => {
  const requested = transitionOperation(createDeletion(), {
    toPhase: "deletionRequested",
    expectedVersion: 0,
  });
  const deleting = transitionOperation(requested, {
    toPhase: "userTreeDeleting",
    expectedVersion: 1,
  });

  assert.throws(
    () => transitionOperation(deleting, {
      toPhase: "authDeleted",
      expectedVersion: 2,
    }),
    { code: "invalid-operation-transition" },
  );
  // A persisted early revocation (deletionProgress.appleRevocationComplete)
  // lets the worker skip the appleRevocationPending hop.
  const directAfterEarlyRevocation = transitionOperation(deleting, {
    toPhase: "authDeleted",
    expectedVersion: 2,
    appleRevocationComplete: true,
  });
  assert.equal(directAfterEarlyRevocation.phase, "authDeleted");
  const revocationPending = transitionOperation(deleting, {
    toPhase: "appleRevocationPending",
    expectedVersion: 2,
  });
  const authDeleted = transitionOperation(revocationPending, {
    toPhase: "authDeleted",
    expectedVersion: 3,
  });
  assert.equal(authDeleted.phase, "authDeleted");
});

test("rejects skipped and cross-kind phases without changing the record", () => {
  const operation = createReplacement();

  assert.throws(
    () => transitionOperation(operation, {
      toPhase: "reconciling",
      expectedVersion: operation.version,
    }),
    { code: "invalid-operation-transition" },
  );
  assert.throws(
    () => transitionOperation(operation, {
      toPhase: "deletionRequested",
      expectedVersion: operation.version,
    }),
    { code: "invalid-operation-transition" },
  );
  assert.equal(operation.phase, "prepared");
  assert.equal(operation.version, 0);
});

test("blocks an active operation but never advances a blocked or completed operation", () => {
  const blocked = transitionOperation(createReplacement(), {
    toPhase: "blocked",
    expectedVersion: 0,
    blockedReason: "durable-account-transition-not-supported",
  });

  assert.equal(blocked.phase, "blocked");
  assert.throws(
    () => transitionOperation(blocked, {
      toPhase: "targetVerified",
      expectedVersion: blocked.version,
    }),
    { code: "terminal-operation" },
  );

  const completed = transitionOperation(
    transitionOperation(
      transitionOperation(
        transitionOperation(createReplacement(), {
          toPhase: "targetVerified",
          expectedVersion: 0,
        }),
        { toPhase: "reconciling", expectedVersion: 1 },
      ),
      { toPhase: "sourceCleanupPending", expectedVersion: 2 },
    ),
    { toPhase: "completed", expectedVersion: 3 },
  );
  assert.throws(
    () => transitionOperation(completed, {
      toPhase: "blocked",
      expectedVersion: completed.version,
    }),
    { code: "terminal-operation" },
  );
});

test("reuses an active operation for duplicate identity requests", () => {
  const first = createOrReuseOperation({
    existingOperations: [],
    request: replacementRequest,
  });
  const retry = createOrReuseOperation({
    existingOperations: [first.operation],
    request: { ...replacementRequest, id: "replacement-op-duplicate" },
  });

  assert.equal(first.reused, false);
  assert.equal(retry.reused, true);
  assert.equal(retry.operation.id, "replacement-op-1");
});

test("rejects a replacement whose target is its source", () => {
  assert.throws(
    () => createOrReuseOperation({
      existingOperations: [],
      request: { ...replacementRequest, targetUid: "anonymous-source" },
    }),
    { code: "source-and-target-must-differ" },
  );
});

test("rejects a stale operation version before applying a transition", () => {
  const operation = transitionOperation(createReplacement(), {
    toPhase: "targetVerified",
    expectedVersion: 0,
  });

  assert.throws(
    () => transitionOperation(operation, {
      toPhase: "reconciling",
      expectedVersion: 0,
    }),
    { code: "stale-operation-version" },
  );
});

test("fails closed for malformed persisted phases or versions even at version zero", () => {
  const malformedRecords = [
    { ...replacementRequest, phase: "unknownPersistedPhase", version: 0 },
    { ...replacementRequest, phase: "prepared", version: -1 },
    { ...replacementRequest, phase: "prepared", version: "0" },
  ];

  for (const record of malformedRecords) {
    assert.throws(
      () => normalizeOperation(record),
      { code: "invalid-operation" },
    );
    assert.throws(
      () => transitionOperation(record, {
        toPhase: "targetVerified",
        expectedVersion: 0,
      }),
      { code: "invalid-operation" },
    );
  }
});

test("keeps attempt counters monotonic and rejects out-of-order attempts", () => {
  const operation = createReplacement();
  const once = recordAttempt(operation, {
    phase: "prepared",
    attempt: 1,
    expectedVersion: 0,
  });
  const twice = recordAttempt(once, {
    phase: "prepared",
    attempt: 2,
    expectedVersion: 1,
  });

  assert.equal(twice.attemptCount, 2);
  assert.equal(twice.phaseAttempts.prepared, 2);
  assert.throws(
    () => recordAttempt(twice, {
      phase: "prepared",
      attempt: 2,
      expectedVersion: twice.version,
    }),
    { code: "non-monotonic-attempt" },
  );
});

test("classifies retryable failures and retains a resumable Apple partial failure", () => {
  const operation = transitionOperation(
    transitionOperation(
      createDeletion(), {
        toPhase: "deletionRequested",
        expectedVersion: 0,
      },
    ),
    { toPhase: "userTreeDeleting", expectedVersion: 1 },
  );
  const pendingApple = transitionOperation(operation, {
    toPhase: "appleRevocationPending",
    expectedVersion: 2,
  });
  const result = applyAttemptResult(pendingApple, {
    phase: "appleRevocationPending",
    attempt: 1,
    expectedVersion: pendingApple.version,
    errorCode: "apple/revocation-unavailable",
  });

  assert.equal(result.phase, "appleRevocationPending");
  assert.equal(result.retry.classification, "retryable");
  assert.equal(result.attemptCount, 1);
});

test("treats Auth user-not-found as a terminal successful deletion result", () => {
  let operation = createOrReuseOperation({
    existingOperations: [],
    request: {
      ...deletionRequest,
      appleRevocationRequired: false,
    },
  }).operation;
  for (const phase of ["deletionRequested", "userTreeDeleting"]) {
    operation = transitionOperation(operation, {
      toPhase: phase,
      expectedVersion: operation.version,
    });
  }

  const handled = applyAttemptResult(operation, {
    phase: "userTreeDeleting",
    attempt: 1,
    expectedVersion: operation.version,
    errorCode: "auth/user-not-found",
  });

  assert.equal(handled.phase, "authDeleted");
  assert.equal(handled.retry.classification, "terminal-success");
});

test("hard-expires deletion proofs and resumes the same claimed proof after response loss", () => {
  const proof = {
    proofHash: "hash-only-proof",
    expiresAtMillis: 10_000,
    claimedOperationId: null,
  };

  const first = claimDeletionProof(proof, {
    proofHash: "hash-only-proof",
    nowMillis: 9_999,
    operationId: "deletion-op-proof",
  });
  const resumed = claimDeletionProof(first.proof, {
    proofHash: "hash-only-proof",
    nowMillis: 9_999,
    operationId: "different-id-must-not-win",
  });
  const expired = claimDeletionProof(proof, {
    proofHash: "hash-only-proof",
    nowMillis: 10_000,
    operationId: "too-late",
  });

  assert.equal(first.accepted, true);
  assert.equal(first.operationId, "deletion-op-proof");
  assert.equal(resumed.accepted, true);
  assert.equal(resumed.operationId, "deletion-op-proof");
  assert.equal(expired.accepted, false);
  assert.equal(expired.reason, "expired");
});

test("normalizes operation records and exposes only safe public result fields", () => {
  const normalized = normalizeOperation({
    ...replacementRequest,
    phase: "targetVerified",
    version: 3,
    attemptCount: -8,
    phaseAttempts: { prepared: 4, targetVerified: 2 },
    credential: "never-persist-this",
    idToken: "never-persist-this",
    appleAuthorizationCode: "never-persist-this",
    deletionProof: "never-persist-this",
    proofHash: "hash-is-private-too",
  });
  const result = operationResult(normalized);

  assert.equal(normalized.attemptCount, 6);
  assert.deepEqual(result, {
    operationId: "replacement-op-1",
    kind: "replacement",
    phase: "targetVerified",
    version: 3,
    attemptCount: 6,
    retryable: true,
    blockedReason: null,
  });
  for (const forbidden of [
    "credential",
    "idToken",
    "appleAuthorizationCode",
    "deletionProof",
    "proofHash",
  ]) {
    assert.equal(Object.hasOwn(result, forbidden), false);
  }
});

test("maps untrusted blocked reasons to a safe reason code before persistence or output", () => {
  const secretLikeReason = "appleAuthorizationCode=top-secret-id-token";
  const blocked = transitionOperation(createReplacement(), {
    toPhase: "blocked",
    expectedVersion: 0,
    blockedReason: secretLikeReason,
  });
  const persistedUnsafeReason = {
    ...createReplacement(),
    phase: "blocked",
    blockedReason: secretLikeReason,
  };

  assert.equal(blocked.blockedReason, "operation-blocked");
  assert.equal(operationResult(blocked).blockedReason, "operation-blocked");
  assert.equal(
    operationResult(persistedUnsafeReason).blockedReason,
    "operation-blocked",
  );
  assert.equal(JSON.stringify(operationResult(blocked)).includes(secretLikeReason), false);
});
