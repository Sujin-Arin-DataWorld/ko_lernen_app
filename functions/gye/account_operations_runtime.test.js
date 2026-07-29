"use strict";

const assert = require("node:assert/strict");
const test = require("node:test");

const runtime = (() => {
  try {
    return require("./account_operations_runtime");
  } catch {
    return {};
  }
})();

const CALLABLE_NAMES = [
  "prepareAnonymousReplacement",
  "attachReplacementTarget",
  "commitReplacementReconciliation",
  "startSourceCleanup",
  "requestAccountDeletion",
  "getAccountOperation",
];

const NOW_MILLIS = 2_000_000_000_000;
const NOW_SECONDS = Math.floor(NOW_MILLIS / 1000);

class FakeSnapshot {
  constructor(value) {
    this.value = value;
    this.exists = value !== undefined;
  }

  data() {
    return this.value === undefined
      ? undefined
      : structuredClone(this.value);
  }
}

class FakeDocumentReference {
  constructor(firestore, path) {
    this.firestore = firestore;
    this.path = path;
  }
}

class FakeCollectionReference {
  constructor(firestore, path) {
    this.firestore = firestore;
    this.path = path;
  }

  doc(id) {
    return new FakeDocumentReference(this.firestore, `${this.path}/${id}`);
  }
}

class FakeFirestore {
  constructor() {
    this.documents = new Map();
    this.transactionTail = Promise.resolve();
  }

  collection(name) {
    return new FakeCollectionReference(this, name);
  }

  runTransaction(callback) {
    const execute = async () => {
      const writes = new Map();
      const transaction = {
        get: async (reference) => {
          const value = writes.has(reference.path)
            ? writes.get(reference.path)
            : this.documents.get(reference.path);
          return new FakeSnapshot(value);
        },
        set: (reference, value) => {
          writes.set(reference.path, structuredClone(value));
        },
      };
      const result = await callback(transaction);
      for (const [path, value] of writes) {
        this.documents.set(path, value);
      }
      return result;
    };
    const result = this.transactionTail.then(execute);
    this.transactionTail = result.catch(() => {});
    return result;
  }

  valuesIn(collectionName) {
    const prefix = `${collectionName}/`;
    return Array.from(this.documents.entries())
      .filter(([path]) => path.startsWith(prefix))
      .map(([, value]) => structuredClone(value));
  }
}

function decodedToken({
  uid,
  provider = "password",
  issuedAt = NOW_SECONDS - 10,
  authTime = NOW_SECONDS - 10,
} = {}) {
  return {
    uid,
    sub: uid,
    iat: issuedAt,
    auth_time: authTime,
    firebase: {
      sign_in_provider: provider,
      identities: provider === "apple.com"
        ? { "apple.com": ["apple-subject"] }
        : {},
    },
  };
}

function createHarness({
  tokens = {
    anonymous: decodedToken({
      uid: "anonymous-source",
      provider: "anonymous",
    }),
    target: decodedToken({ uid: "durable-target" }),
    other: decodedToken({ uid: "other-account" }),
  },
} = {}) {
  assert.equal(typeof runtime.createFirestoreAccountOperationRepository, "function");
  assert.equal(typeof runtime.createAccountOperationRuntime, "function");

  const firestore = new FakeFirestore();
  let operationSequence = 0;
  const repository = runtime.createFirestoreAccountOperationRepository({
    firestore,
    nowMillis: () => NOW_MILLIS,
    newOperationId: () => `operation-${++operationSequence}`,
  });
  const verificationCalls = [];
  const auth = {
    async verifyIdToken(token, checkRevoked) {
      verificationCalls.push({ token, checkRevoked });
      if (token === "revoked-token") {
        const error = new Error("raw revoked token verifier detail");
        error.code = "auth/id-token-revoked";
        throw error;
      }
      if (!tokens[token]) {
        throw new Error("raw verifier detail");
      }
      return structuredClone(tokens[token]);
    },
  };
  const makeError = (status, safeCode) => {
    const error = new Error("account-operation-request-failed");
    error.code = status;
    error.details = { code: safeCode };
    return error;
  };
  const handlers = runtime.createAccountOperationRuntime({
    auth,
    repository,
    nowMillis: () => NOW_MILLIS,
    makeError,
  });
  return {
    firestore,
    handlers,
    repository,
    verificationCalls,
  };
}

function callableRequest(token, data = {}, {
  app = true,
  alreadyConsumed = false,
} = {}) {
  return {
    data,
    app: app
      ? { appId: "test-app-id", alreadyConsumed }
      : undefined,
    rawRequest: {
      headers: token
        ? { authorization: `Bearer ${token}` }
        : {},
    },
  };
}

async function rejectsWithSafeCode(promise, status, safeCode) {
  await assert.rejects(
    promise,
    (error) => {
      assert.equal(error.code, status);
      assert.deepEqual(error.details, { code: safeCode });
      assert.equal(error.message, "account-operation-request-failed");
      return true;
    },
  );
}

async function prepareReplacement(handlers, overrides = {}) {
  return handlers.prepareAnonymousReplacement(callableRequest(
    "anonymous",
    {
      requestKey: "replacement-request",
      targetUid: "durable-target",
      ...overrides,
    },
  ));
}

test("registers all six protected callable names with the exact v2 options", () => {
  assert.equal(typeof runtime.createAccountOperationCallables, "function");
  const handlers = Object.fromEntries(
    CALLABLE_NAMES.map((name) => [name, async () => name]),
  );
  const registrations = [];
  const callables = runtime.createAccountOperationCallables({
    handlers,
    onCall(options, handler) {
      registrations.push({ options, handler });
      return { options, handler };
    },
  });

  assert.deepEqual(Object.keys(callables), CALLABLE_NAMES);
  assert.equal(registrations.length, CALLABLE_NAMES.length);
  for (const registration of registrations) {
    assert.deepEqual(registration.options, {
      region: "europe-west3",
      enforceAppCheck: true,
      consumeAppCheckToken: true,
    });
    assert.equal(typeof registration.handler, "function");
  }
});

test("rejects every callable without an Authorization-header bearer token", async () => {
  const { handlers } = createHarness();

  for (const name of CALLABLE_NAMES) {
    await rejectsWithSafeCode(
      handlers[name](callableRequest(null)),
      "unauthenticated",
      "authentication-required",
    );
  }
});

test("rejects every callable when App Check context is missing or already consumed", async () => {
  const { handlers } = createHarness();

  for (const name of CALLABLE_NAMES) {
    await rejectsWithSafeCode(
      handlers[name](callableRequest("anonymous", {}, { app: false })),
      "failed-precondition",
      "app-check-required",
    );
    await rejectsWithSafeCode(
      handlers[name](callableRequest(
        "anonymous",
        {},
        { alreadyConsumed: true },
      )),
      "resource-exhausted",
      "app-check-token-consumed",
    );
  }
});

test("checks token revocation and returns no verifier or raw-token detail", async () => {
  const { handlers, verificationCalls } = createHarness();

  let caught;
  try {
    await handlers.requestAccountDeletion(
      callableRequest("revoked-token", { sourceUid: "victim" }),
    );
  } catch (error) {
    caught = error;
  }

  assert.equal(caught.code, "unauthenticated");
  assert.deepEqual(caught.details, { code: "invalid-auth-token" });
  assert.equal(JSON.stringify(caught).includes("revoked-token"), false);
  assert.equal(
    JSON.stringify(caught).includes("raw revoked token verifier detail"),
    false,
  );
  assert.deepEqual(verificationCalls, [{
    token: "revoked-token",
    checkRevoked: true,
  }]);
});

test("rejects stale connected auth_time even when iat is fresh", async () => {
  const { handlers } = createHarness({
    tokens: {
      staleConnected: decodedToken({
        uid: "durable-target",
        issuedAt: NOW_SECONDS - 1,
        authTime: NOW_SECONDS - 301,
      }),
    },
  });

  await rejectsWithSafeCode(
    handlers.requestAccountDeletion(
      callableRequest("staleConnected", { sourceUid: "someone-else" }),
    ),
    "failed-precondition",
    "recent-authentication-required",
  );
});

test("rejects an anonymous token whose iat is older than 300 seconds", async () => {
  const { handlers } = createHarness({
    tokens: {
      staleAnonymous: decodedToken({
        uid: "anonymous-source",
        provider: "anonymous",
        issuedAt: NOW_SECONDS - 301,
        authTime: NOW_SECONDS - 1,
      }),
    },
  });

  await rejectsWithSafeCode(
    handlers.prepareAnonymousReplacement(callableRequest(
      "staleAnonymous",
      {
        targetUid: "durable-target",
        requestKey: "stale-request",
      },
    )),
    "failed-precondition",
    "fresh-anonymous-token-required",
  );
});

test("rate limits anonymous callable use per verified UID and App Check app", async () => {
  const { handlers } = createHarness();

  for (let index = 0; index < 20; index += 1) {
    await handlers.getAccountOperation(callableRequest("anonymous", {
      operationId: "missing-operation",
    })).catch((error) => {
      assert.equal(error.details.code, "operation-not-found");
    });
  }
  await rejectsWithSafeCode(
    handlers.getAccountOperation(callableRequest("anonymous", {
      operationId: "missing-operation",
    })),
    "resource-exhausted",
    "anonymous-rate-limit-exceeded",
  );
});

test("derives the source UID only from the verified token and ignores a body UID", async () => {
  const { firestore, handlers } = createHarness();

  const result = await prepareReplacement(handlers, {
    sourceUid: "victim-account",
    uid: "another-victim",
  });
  const records = firestore.valuesIn("account_operations");

  assert.equal(result.phase, "prepared");
  assert.equal(records.length, 1);
  assert.equal(records[0].sourceUid, "anonymous-source");
  assert.notEqual(records[0].sourceUid, "victim-account");
  assert.notEqual(records[0].sourceUid, "another-victim");
  assert.notEqual(records[0].requestKey, "replacement-request");
  assert.equal(
    JSON.stringify(records[0]).includes("replacement-request"),
    false,
  );
});

test("transactionally reuses concurrent duplicate replacement preparation", async () => {
  const { firestore, handlers } = createHarness();

  const [first, second] = await Promise.all([
    prepareReplacement(handlers),
    prepareReplacement(handlers),
  ]);

  assert.equal(first.operationId, second.operationId);
  assert.deepEqual(first, {
    operationId: "operation-1",
    kind: "replacement",
    phase: "prepared",
    version: 0,
    attemptCount: 0,
    retryable: true,
    blockedReason: null,
  });
  assert.equal(firestore.valuesIn("account_operations").length, 1);
});

test("serializes replacement and deletion operations for the same source UID", async () => {
  const { handlers } = createHarness();
  await prepareReplacement(handlers);

  await rejectsWithSafeCode(
    handlers.requestAccountDeletion(callableRequest("anonymous", {
      requestKey: "conflicting-deletion-request",
    })),
    "failed-precondition",
    "operation-in-progress",
  );
});

test("keeps an immutable request-key mapping after a newer operation is created", async () => {
  const { handlers, repository } = createHarness();
  const first = await prepareReplacement(handlers);
  let operation = first;
  for (const [name, phase] of [
    ["attachReplacementTarget", "targetVerified"],
    ["commitReplacementReconciliation", "reconciling"],
    ["startSourceCleanup", "sourceCleanupPending"],
  ]) {
    operation = await handlers[name](callableRequest("target", {
      operationId: first.operationId,
      expectedVersion: operation.version,
    }));
    assert.equal(operation.phase, phase);
  }
  await repository.transition({
    operationId: first.operationId,
    actorUid: "durable-target",
    role: "target",
    expectedVersion: operation.version,
    toPhase: "completed",
  });

  const newer = await prepareReplacement(handlers, {
    requestKey: "newer-replacement-request",
  });
  const replay = await prepareReplacement(handlers);

  assert.notEqual(newer.operationId, first.operationId);
  assert.equal(replay.operationId, first.operationId);
  assert.equal(replay.phase, "completed");
});

test("replays an aliased request key after its shared operation is terminal", async () => {
  const { handlers, repository } = createHarness();
  const first = await prepareReplacement(handlers);
  const alias = await prepareReplacement(handlers, {
    requestKey: "aliased-active-request",
  });
  assert.equal(alias.operationId, first.operationId);

  let operation = first;
  for (const name of [
    "attachReplacementTarget",
    "commitReplacementReconciliation",
    "startSourceCleanup",
  ]) {
    operation = await handlers[name](callableRequest("target", {
      operationId: first.operationId,
      expectedVersion: operation.version,
    }));
  }
  await repository.transition({
    operationId: first.operationId,
    actorUid: "durable-target",
    role: "target",
    expectedVersion: operation.version,
    toPhase: "completed",
  });

  const replay = await prepareReplacement(handlers, {
    requestKey: "aliased-active-request",
  });
  assert.equal(replay.operationId, first.operationId);
  assert.equal(replay.phase, "completed");
});

test("persists deletionRequested when advancing a reused prepared deletion", async () => {
  const { repository } = createHarness();
  const request = {
    kind: "deletion",
    sourceUid: "anonymous-source",
    requestKey: "seeded-prepared-deletion",
    appleRevocationRequired: false,
  };
  const prepared = await repository.createOrReuseReplacement(request);
  const requested = await repository.createOrReuseDeletion(request);
  const persisted = await repository.get({
    operationId: prepared.id,
    actorUid: "anonymous-source",
  });

  assert.equal(requested.phase, "deletionRequested");
  assert.equal(requested.version, 1);
  assert.equal(persisted.phase, "deletionRequested");
  assert.equal(persisted.version, 1);
});

test("advances replacement phases only for the verified target with version fencing", async () => {
  const { handlers } = createHarness();
  const prepared = await prepareReplacement(handlers);

  await rejectsWithSafeCode(
    handlers.attachReplacementTarget(callableRequest("other", {
      operationId: prepared.operationId,
      expectedVersion: prepared.version,
    })),
    "permission-denied",
    "operation-not-authorized",
  );

  const attached = await handlers.attachReplacementTarget(callableRequest(
    "target",
    {
      operationId: prepared.operationId,
      expectedVersion: prepared.version,
      targetUid: "body-uid-must-not-authorize",
    },
  ));
  const duplicateAttach =
    await handlers.attachReplacementTarget(callableRequest("target", {
      operationId: prepared.operationId,
      expectedVersion: prepared.version,
    }));

  assert.deepEqual(duplicateAttach, attached);
  assert.equal(attached.phase, "targetVerified");
  assert.equal(attached.version, 1);

  await rejectsWithSafeCode(
    handlers.commitReplacementReconciliation(callableRequest("target", {
      operationId: prepared.operationId,
      expectedVersion: 0,
    })),
    "aborted",
    "stale-operation-version",
  );

  const reconciling =
    await handlers.commitReplacementReconciliation(callableRequest("target", {
      operationId: prepared.operationId,
      expectedVersion: attached.version,
    }));
  const cleanupPending =
    await handlers.startSourceCleanup(callableRequest("target", {
      operationId: prepared.operationId,
      expectedVersion: reconciling.version,
    }));

  assert.equal(reconciling.phase, "reconciling");
  assert.equal(cleanupPending.phase, "sourceCleanupPending");
  assert.equal(cleanupPending.version, 3);
});

test("creates or reuses deletionRequested without deleting any user data", async () => {
  const { firestore, handlers } = createHarness();

  const first = await handlers.requestAccountDeletion(callableRequest(
    "target",
    {
      requestKey: "deletion-request",
      uid: "victim-account",
      appleRevocationRequired: true,
    },
  ));
  const duplicate = await handlers.requestAccountDeletion(callableRequest(
    "target",
    {
      requestKey: "deletion-request",
      uid: "another-victim",
    },
  ));

  assert.deepEqual(duplicate, first);
  assert.equal(first.phase, "deletionRequested");
  assert.equal(first.version, 1);
  assert.equal(firestore.valuesIn("account_operations").length, 1);
  assert.equal(firestore.valuesIn("users").length, 0);
  assert.equal(firestore.valuesIn("account_deletions").length, 0);
});

test("allows only an operation participant to read a safe operation result", async () => {
  const { handlers } = createHarness();
  const prepared = await prepareReplacement(handlers);

  await rejectsWithSafeCode(
    handlers.getAccountOperation(callableRequest("other", {
      operationId: prepared.operationId,
      uid: "anonymous-source",
    })),
    "permission-denied",
    "operation-not-authorized",
  );
  const result = await handlers.getAccountOperation(callableRequest(
    "anonymous",
    {
      operationId: prepared.operationId,
      uid: "other-account",
    },
  ));

  assert.deepEqual(result, prepared);
  for (const forbidden of [
    "sourceUid",
    "targetUid",
    "requestKey",
    "credential",
    "idToken",
    "appleAuthorizationCode",
    "deletionProof",
    "proofHash",
  ]) {
    assert.equal(Object.hasOwn(result, forbidden), false);
  }
});

test("rejects operation IDs that cannot be opaque Firestore document IDs", async () => {
  const { handlers } = createHarness();

  await rejectsWithSafeCode(
    handlers.getAccountOperation(callableRequest("target", {
      operationId: "nested/path",
    })),
    "invalid-argument",
    "invalid-operation-id",
  );
  await rejectsWithSafeCode(
    handlers.getAccountOperation(callableRequest("target", {
      operationId: "   ",
    })),
    "invalid-argument",
    "invalid-operation-id",
  );
});

test("index exports the six required callable functions", () => {
  const deployed = require("./index");
  for (const name of CALLABLE_NAMES) {
    assert.equal(typeof deployed[name], "function", `${name} export`);
  }
});
