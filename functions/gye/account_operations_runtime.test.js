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
  "cancelAnonymousReplacement",
  "requestAccountDeletion",
  "issueDeletionProof",
  "completeAppleRevocation",
  "getAccountOperation",
];

const NOW_MILLIS = 2_000_000_000_000;
const NOW_SECONDS = Math.floor(NOW_MILLIS / 1000);
const FIRST_PARTY_ORIGIN = "https://hangul-sori.com";
const GENERIC_PUBLIC_RESULT = Object.freeze({
  status: "request-received",
});

function rawProof(fill) {
  return Buffer.alloc(32, fill).toString("base64url");
}

function keyedProofHash(proof) {
  return `keyed-hash-${proof.slice(0, 8)}`;
}

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

class FakeQueryDocumentSnapshot extends FakeSnapshot {
  constructor(firestore, path, value) {
    super(value);
    this.id = path.split("/").at(-1);
    this.ref = new FakeDocumentReference(firestore, path);
  }
}

class FakeQuery {
  constructor(firestore, path, {
    conditions = [],
    orderings = [],
    startAfterValues = null,
    queryLimit = null,
  } = {}) {
    this.firestore = firestore;
    this.path = path;
    this.conditions = conditions;
    this.orderings = orderings;
    this.startAfterValues = startAfterValues;
    this.queryLimit = queryLimit;
  }

  withChange(change) {
    return new FakeQuery(this.firestore, this.path, {
      conditions: this.conditions,
      orderings: this.orderings,
      startAfterValues: this.startAfterValues,
      queryLimit: this.queryLimit,
      ...change,
    });
  }

  where(field, operator, value) {
    return this.withChange({
      conditions: [...this.conditions, { field, operator, value }],
    });
  }

  orderBy(field, direction = "asc") {
    return this.withChange({
      orderings: [...this.orderings, { field, direction }],
    });
  }

  startAfter(...values) {
    return this.withChange({ startAfterValues: values });
  }

  limit(limit) {
    return this.withChange({ queryLimit: limit });
  }

  valueAt(candidate, field) {
    if (field === "__name__") return candidate.id;
    return field
      .split(".")
      .reduce((value, part) => value?.[part], candidate.value);
  }

  compareValues(left, right) {
    if (left === right) return 0;
    return left < right ? -1 : 1;
  }

  compareCandidate(left, right) {
    for (const ordering of this.orderings) {
      const comparison = this.compareValues(
        this.valueAt(left, ordering.field),
        this.valueAt(right, ordering.field),
      );
      if (comparison !== 0) {
        return ordering.direction === "desc" ? -comparison : comparison;
      }
    }
    return 0;
  }

  compareToCursor(candidate) {
    for (let index = 0; index < this.orderings.length; index += 1) {
      const ordering = this.orderings[index];
      const comparison = this.compareValues(
        this.valueAt(candidate, ordering.field),
        this.startAfterValues[index],
      );
      if (comparison !== 0) {
        return ordering.direction === "desc" ? -comparison : comparison;
      }
    }
    return 0;
  }

  async get() {
    const prefix = `${this.path}/`;
    let candidates = Array.from(this.firestore.documents.entries())
      .filter(([path]) => {
        if (!path.startsWith(prefix)) return false;
        return !path.slice(prefix.length).includes("/");
      })
      .map(([path, value]) => ({
        id: path.slice(prefix.length),
        path,
        value: structuredClone(value),
      }))
      .filter((candidate) => this.conditions.every((condition) => {
        const actual = this.valueAt(candidate, condition.field);
        if (condition.operator === "<=") {
          return actual !== undefined && actual <= condition.value;
        }
        return actual === condition.value;
      }))
      .sort((left, right) => this.compareCandidate(left, right));
    if (this.startAfterValues) {
      candidates = candidates.filter(
        (candidate) => this.compareToCursor(candidate) > 0,
      );
    }
    if (this.queryLimit !== null) {
      candidates = candidates.slice(0, this.queryLimit);
    }
    return {
      docs: candidates.map((candidate) => new FakeQueryDocumentSnapshot(
        this.firestore,
        candidate.path,
        candidate.value,
      )),
    };
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

  where(field, operator, value) {
    return new FakeQuery(this.firestore, this.path)
      .where(field, operator, value);
  }

  orderBy(field, direction) {
    return new FakeQuery(this.firestore, this.path)
      .orderBy(field, direction);
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
          if (reference instanceof FakeQuery) {
            return reference.get();
          }
          const value = writes.has(reference.path)
            ? writes.get(reference.path)
            : this.documents.get(reference.path);
          return new FakeSnapshot(value);
        },
        set: (reference, value) => {
          writes.set(reference.path, structuredClone(value));
        },
        delete: (reference) => {
          writes.set(reference.path, undefined);
        },
      };
      const result = await callback(transaction);
      for (const [path, value] of writes) {
        if (value === undefined) {
          this.documents.delete(path);
        } else {
          this.documents.set(path, value);
        }
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

function fakeAccountOperationCollection(source) {
  const valueAt = (candidate, field) => field
    .split(".")
    .reduce((value, part) => value?.[part], candidate);
  const buildQuery = (conditions = [], orderings = [], queryLimit = null) => ({
    where(field, operator, value) {
      return buildQuery(
        [...conditions, { field, operator, value }],
        orderings,
        queryLimit,
      );
    },
    orderBy(field) {
      return buildQuery(
        conditions,
        [...orderings, field],
        queryLimit,
      );
    },
    limit(limit) {
      return buildQuery(conditions, orderings, limit);
    },
    async get() {
      const docs = (typeof source === "function" ? source() : source)
        .filter((candidate) => conditions.every((condition) => {
          const actual = valueAt(candidate, condition.field);
          if (condition.operator === "in") {
            return condition.value.includes(actual);
          }
          if (condition.operator === "<=") {
            return actual <= condition.value;
          }
          return actual === condition.value;
        }))
        .sort((left, right) => {
          for (const field of orderings) {
            const comparison = valueAt(left, field) - valueAt(right, field);
            if (comparison !== 0) return comparison;
          }
          return 0;
        });
      return {
        docs: queryLimit === null ? docs : docs.slice(0, queryLimit),
      };
    },
  });
  return buildQuery();
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
  proofs = [rawProof(1), rawProof(2), rawProof(3), rawProof(4)],
  hashDeletionProof = async (proof) => keyedProofHash(proof),
  logger = {
    warn() {},
  },
  revokeAppleAuthorizationCode = async () => {},
} = {}) {
  assert.equal(typeof runtime.createFirestoreAccountOperationRepository, "function");
  assert.equal(typeof runtime.createAccountOperationRuntime, "function");

  const firestore = new FakeFirestore();
  const clock = { now: NOW_MILLIS };
  let operationSequence = 0;
  let proofSequence = 0;
  const repository = runtime.createFirestoreAccountOperationRepository({
    firestore,
    nowMillis: () => clock.now,
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
    async deleteUser() {},
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
    nowMillis: () => clock.now,
    newDeletionProof: () => proofs[proofSequence++],
    hashDeletionProof,
    logger,
    makeError,
    revokeAppleAuthorizationCode,
  });
  return {
    clock,
    firestore,
    handlers,
    hashDeletionProof,
    logger,
    repository,
    verificationCalls,
  };
}

async function createDeletionOperation(handlers, token = "target") {
  return handlers.requestAccountDeletion(callableRequest(token, {
    requestKey: `delete-${token}`,
  }));
}

async function runWorkerUntil(worker, operationId, phase, limit = 20) {
  let result;
  for (let index = 0; index < limit; index += 1) {
    result = await worker.processDeletionOperation({
      operationId,
      workerId: "worker-one",
    });
    if (result.phase === phase) return result;
  }
  assert.fail(`worker did not reach ${phase}`);
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

function publicRequest(proof, {
  method = "POST",
  origin = FIRST_PARTY_ORIGIN,
  contentType = "application/json",
  rawBody,
  query = {},
} = {}) {
  const body = { proof };
  const encodedBody = rawBody ?? Buffer.from(JSON.stringify(body), "utf8");
  const headers = {
    origin,
    "content-type": contentType,
    "content-length": String(encodedBody.length),
  };
  return {
    body,
    headers,
    method,
    query,
    rawBody: encodedBody,
    get(name) {
      return headers[name.toLowerCase()];
    },
  };
}

function publicResponse() {
  return {
    body: undefined,
    headers: {},
    statusCode: 200,
    set(name, value) {
      this.headers[name.toLowerCase()] = value;
      return this;
    },
    status(value) {
      this.statusCode = value;
      return this;
    },
    json(value) {
      this.body = structuredClone(value);
      return this;
    },
  };
}

async function invokePublic(handler, request) {
  const response = publicResponse();
  await handler(request, response);
  return response;
}

test("registers every protected callable name with the exact v2 options", () => {
  assert.equal(typeof runtime.createAccountOperationCallables, "function");
  const handlers = Object.fromEntries(
    CALLABLE_NAMES.map((name) => [name, async () => name]),
  );
  const appleSecrets = [
    { name: "APPLE_REVOKE_CLIENT_ID" },
    { name: "APPLE_REVOKE_TEAM_ID" },
    { name: "APPLE_REVOKE_KEY_ID" },
    { name: "APPLE_REVOKE_PRIVATE_KEY" },
  ];
  const registrations = [];
  const callables = runtime.createAccountOperationCallables({
    handlers,
    onCall(options, handler) {
      registrations.push({ options, handler });
      return { options, handler };
    },
    optionsByName: {
      completeAppleRevocation: {
        secrets: appleSecrets,
      },
    },
  });

  assert.deepEqual(Object.keys(callables), CALLABLE_NAMES);
  assert.equal(registrations.length, CALLABLE_NAMES.length);
  for (const [index, registration] of registrations.entries()) {
    const expected = {
      region: "europe-west3",
      enforceAppCheck: true,
      consumeAppCheckToken: true,
    };
    if (CALLABLE_NAMES[index] === "completeAppleRevocation") {
      expected.secrets = appleSecrets;
    }
    assert.deepEqual(registration.options, expected);
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
  const duplicateCleanup =
    await handlers.startSourceCleanup(callableRequest("target", {
      operationId: prepared.operationId,
      expectedVersion: reconciling.version,
    }));

  assert.equal(reconciling.phase, "reconciling");
  assert.equal(cleanupPending.phase, "sourceCleanupPending");
  assert.equal(cleanupPending.version, 3);
  assert.deepEqual(duplicateCleanup, cleanupPending);
});

test("cancels a replacement only for its verified anonymous source", async () => {
  const { handlers } = createHarness({
    tokens: {
      anonymous: decodedToken({
        uid: "anonymous-source",
        provider: "anonymous",
      }),
      attacker: decodedToken({
        uid: "other-anonymous",
        provider: "anonymous",
      }),
      target: decodedToken({ uid: "durable-target" }),
    },
  });
  const prepared = await prepareReplacement(handlers);

  await rejectsWithSafeCode(
    handlers.cancelAnonymousReplacement(callableRequest("target", {
      operationId: prepared.operationId,
      expectedVersion: prepared.version,
    })),
    "failed-precondition",
    "anonymous-account-required",
  );
  await rejectsWithSafeCode(
    handlers.cancelAnonymousReplacement(callableRequest("attacker", {
      operationId: prepared.operationId,
      expectedVersion: prepared.version,
    })),
    "permission-denied",
    "operation-not-authorized",
  );

  const cancelled = await handlers.cancelAnonymousReplacement(callableRequest(
    "anonymous",
    {
      operationId: prepared.operationId,
      expectedVersion: prepared.version,
      sourceUid: "body-uid-must-not-authorize",
    },
  ));
  const replay = await handlers.cancelAnonymousReplacement(callableRequest(
    "anonymous",
    {
      operationId: prepared.operationId,
      expectedVersion: prepared.version,
    },
  ));

  assert.deepEqual(replay, cancelled);
  assert.equal(cancelled.phase, "cancelled");
  assert.equal(cancelled.version, 1);
  assert.equal(cancelled.retryable, false);
});

test("cancellation releases the owner for replacement and deletion retries", async () => {
  for (const retryKind of [
    "same-target-replacement",
    "different-target-replacement",
    "deletion",
  ]) {
    const { handlers } = createHarness();
    const prepared = await prepareReplacement(handlers);
    await handlers.cancelAnonymousReplacement(callableRequest("anonymous", {
      operationId: prepared.operationId,
      expectedVersion: prepared.version,
    }));

    const retried = retryKind === "deletion"
      ? await handlers.requestAccountDeletion(callableRequest("anonymous", {
        requestKey: "after-cancel-deletion",
      }))
      : await prepareReplacement(handlers, {
        requestKey: `after-cancel-${retryKind}`,
        targetUid: retryKind === "same-target-replacement"
          ? "durable-target"
          : "different-target",
      });

    assert.notEqual(retried.operationId, prepared.operationId);
    assert.equal(
      retried.phase,
      retryKind === "deletion" ? "deletionRequested" : "prepared",
    );
  }
});

test("an old cancellation replay never releases a newer operation owner", async () => {
  const { handlers } = createHarness();
  const first = await prepareReplacement(handlers);
  await handlers.cancelAnonymousReplacement(callableRequest("anonymous", {
    operationId: first.operationId,
    expectedVersion: first.version,
  }));
  const newer = await prepareReplacement(handlers, {
    requestKey: "newer-after-cancel",
  });

  const replay = await handlers.cancelAnonymousReplacement(callableRequest(
    "anonymous",
    {
      operationId: first.operationId,
      expectedVersion: first.version,
    },
  ));
  assert.equal(replay.phase, "cancelled");
  await rejectsWithSafeCode(
    handlers.requestAccountDeletion(callableRequest("anonymous", {
      requestKey: "must-not-bypass-new-owner",
    })),
    "failed-precondition",
    "operation-in-progress",
  );
  const duplicate = await prepareReplacement(handlers, {
    requestKey: "newer-after-cancel",
  });
  assert.equal(duplicate.operationId, newer.operationId);
});

test("rejects stale cancellation and cancellation after cleanup acceptance", async () => {
  const { handlers } = createHarness();
  const prepared = await prepareReplacement(handlers);
  const attached = await handlers.attachReplacementTarget(callableRequest(
    "target",
    {
      operationId: prepared.operationId,
      expectedVersion: prepared.version,
    },
  ));

  await rejectsWithSafeCode(
    handlers.cancelAnonymousReplacement(callableRequest("anonymous", {
      operationId: prepared.operationId,
      expectedVersion: prepared.version,
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

  await rejectsWithSafeCode(
    handlers.cancelAnonymousReplacement(callableRequest("anonymous", {
      operationId: prepared.operationId,
      expectedVersion: cleanupPending.version,
    })),
    "failed-precondition",
    "invalid-operation-transition",
  );
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

test("issues a server-generated 256-bit proof and persists no raw proof", async () => {
  const proof = rawProof(11);
  const { firestore, handlers } = createHarness({ proofs: [proof] });

  const result = await handlers.issueDeletionProof(callableRequest("target"));
  const storedProofs = firestore.valuesIn("account_deletion_proofs");

  assert.deepEqual(result, {
    proof,
    expiresAtMillis: NOW_MILLIS + 86_400_000,
  });
  assert.equal(Buffer.from(result.proof, "base64url").length, 32);
  assert.equal(storedProofs.length, 1);
  assert.equal(storedProofs[0].proofHash, keyedProofHash(proof));
  assert.equal(storedProofs[0].sourceUid, "durable-target");
  assert.equal(storedProofs[0].claimedOperationId, null);
  assert.equal(
    JSON.stringify(Array.from(firestore.documents.entries())).includes(proof),
    false,
  );
});

test("rotates to one active proof per account", async () => {
  const firstProof = rawProof(12);
  const secondProof = rawProof(13);
  const { firestore, handlers } = createHarness({
    proofs: [firstProof, secondProof],
  });

  await handlers.issueDeletionProof(callableRequest("target"));
  const second = await handlers.issueDeletionProof(callableRequest("target"));
  const storedProofs = firestore.valuesIn("account_deletion_proofs");

  assert.equal(second.proof, secondProof);
  assert.equal(storedProofs.length, 1);
  assert.equal(storedProofs[0].proofHash, keyedProofHash(secondProof));
  assert.equal(JSON.stringify(storedProofs).includes(firstProof), false);
  assert.equal(
    JSON.stringify(Array.from(firestore.documents.keys()))
      .includes(keyedProofHash(firstProof)),
    false,
  );
});

test("bounds proof issuance and returns only a safe callable error", async () => {
  const proofs = [rawProof(14), rawProof(15), rawProof(16), rawProof(17)];
  const { firestore, handlers } = createHarness({ proofs });

  for (let index = 0; index < 3; index += 1) {
    await handlers.issueDeletionProof(callableRequest("target"));
  }
  await rejectsWithSafeCode(
    handlers.issueDeletionProof(callableRequest("target")),
    "resource-exhausted",
    "proof-issuance-rate-exceeded",
  );

  assert.equal(firestore.valuesIn("account_deletion_proofs").length, 1);
  assert.equal(
    JSON.stringify(Array.from(firestore.documents.entries()))
      .includes(proofs[3]),
    false,
  );
});

test("claims once and reuses the opaque operation after public response loss", async () => {
  const proof = rawProof(21);
  const { firestore, handlers, repository, hashDeletionProof } =
    createHarness({ proofs: [proof] });
  await handlers.issueDeletionProof(callableRequest("target"));
  const publicHandler = runtime.createDeletionProofHttpHandler({
    repository,
    hashDeletionProof,
    consumeRateLimit: async () => true,
  });

  const first = await invokePublic(publicHandler, publicRequest(proof));
  const replay = await invokePublic(publicHandler, publicRequest(proof));
  const operations = firestore.valuesIn("account_operations");
  const storedProof = firestore.valuesIn("account_deletion_proofs")[0];

  assert.equal(first.statusCode, 202);
  assert.deepEqual(first.body, GENERIC_PUBLIC_RESULT);
  assert.equal(replay.statusCode, first.statusCode);
  assert.deepEqual(replay.body, first.body);
  assert.equal(operations.length, 1);
  assert.equal(operations[0].id, storedProof.claimedOperationId);
  assert.match(operations[0].id, /^[A-Za-z0-9_-]{1,128}$/);
  assert.equal(operations[0].phase, "deletionRequested");
  assert.equal(firestore.valuesIn("users").length, 0);
  assert.equal(firestore.valuesIn("account_deletions").length, 0);
  assert.equal(
    JSON.stringify(Array.from(firestore.documents.entries())).includes(proof),
    false,
  );
});

test("makes Apple revocation sticky when a proof reuses a deletion operation", async () => {
  const proof = rawProof(31);
  const sharedUid = "shared-deletion-account";
  const { firestore, handlers, repository, hashDeletionProof } =
    createHarness({
      proofs: [proof],
      tokens: {
        password: decodedToken({
          uid: sharedUid,
          provider: "password",
        }),
        apple: decodedToken({
          uid: sharedUid,
          provider: "apple.com",
        }),
      },
    });
  const existing = await handlers.requestAccountDeletion(callableRequest(
    "password",
    { requestKey: "existing-non-apple-deletion" },
  ));
  assert.equal(
    firestore.valuesIn("account_operations")[0].appleRevocationRequired,
    false,
  );
  await handlers.issueDeletionProof(callableRequest("apple"));
  const publicHandler = runtime.createDeletionProofHttpHandler({
    repository,
    hashDeletionProof,
    consumeRateLimit: async () => true,
  });

  await invokePublic(publicHandler, publicRequest(proof));
  const afterClaim = firestore.valuesIn("account_operations");
  await invokePublic(publicHandler, publicRequest(proof));
  const afterReplay = firestore.valuesIn("account_operations");

  assert.equal(afterClaim.length, 1);
  assert.equal(afterClaim[0].id, existing.operationId);
  assert.equal(afterClaim[0].appleRevocationRequired, true);
  assert.equal(afterReplay.length, 1);
  assert.equal(afterReplay[0].id, existing.operationId);
  assert.equal(afterReplay[0].appleRevocationRequired, true);
});

test("returns the identical generic result for every proof state", async () => {
  const usedProof = rawProof(22);
  const expiredProof = rawProof(23);
  const unknownProof = rawProof(24);
  const { clock, firestore, handlers, repository, hashDeletionProof } =
    createHarness({ proofs: [usedProof, expiredProof] });
  const publicHandler = runtime.createDeletionProofHttpHandler({
    repository,
    hashDeletionProof,
    consumeRateLimit: async () => true,
  });

  await handlers.issueDeletionProof(callableRequest("target"));
  const accepted = await invokePublic(
    publicHandler,
    publicRequest(usedProof),
  );
  const used = await invokePublic(publicHandler, publicRequest(usedProof));
  const claimedOperationId =
    firestore.valuesIn("account_deletion_proofs")[0].claimedOperationId;
  firestore.documents.delete(`account_operations/${claimedOperationId}`);
  const deleted = await invokePublic(publicHandler, publicRequest(usedProof));

  const issuedExpired =
    await handlers.issueDeletionProof(callableRequest("target"));
  clock.now = issuedExpired.expiresAtMillis;
  const expired = await invokePublic(
    publicHandler,
    publicRequest(expiredProof),
  );
  const invalid = await invokePublic(
    publicHandler,
    publicRequest(unknownProof),
  );
  const malformed = await invokePublic(
    publicHandler,
    publicRequest("not-a-proof"),
  );

  for (const response of [
    accepted,
    used,
    deleted,
    expired,
    invalid,
    malformed,
  ]) {
    assert.equal(response.statusCode, 202);
    assert.deepEqual(response.body, GENERIC_PUBLIC_RESULT);
    assert.equal(response.headers["cache-control"], "no-store");
    assert.equal(response.headers["referrer-policy"], "no-referrer");
  }
});

test("rejects non-first-party, non-POST, non-JSON, query, and oversized requests", async () => {
  let hashCalls = 0;
  let rateCalls = 0;
  const { repository } = createHarness();
  const handler = runtime.createDeletionProofHttpHandler({
    repository,
    getRateLimitKey: async () => "safe-network-key",
    hashDeletionProof: async () => {
      hashCalls += 1;
      return "must-not-run";
    },
    consumeRateLimit: async () => {
      rateCalls += 1;
      return true;
    },
  });
  const proof = rawProof(25);
  const cases = [
    [publicRequest(proof, { origin: "https://attacker.example" }), 403],
    [publicRequest(proof, { method: "GET" }), 405],
    [publicRequest(proof, { contentType: "text/plain" }), 415],
    [publicRequest(proof, { query: { proof } }), 400],
    [publicRequest(proof, { rawBody: Buffer.alloc(1_025, 65) }), 413],
  ];

  for (const [request, expectedStatus] of cases) {
    const response = await invokePublic(handler, request);
    assert.equal(response.statusCode, expectedStatus);
    assert.deepEqual(response.body, GENERIC_PUBLIC_RESULT);
  }
  assert.equal(hashCalls, 0);
  assert.equal(rateCalls, 0);
});

test("applies the public rate hook before hashing the proof", async () => {
  let hashCalls = 0;
  let rateMetadata;
  const { repository } = createHarness();
  const handler = runtime.createDeletionProofHttpHandler({
    repository,
    getRateLimitKey: async () => "safe-network-key",
    hashDeletionProof: async () => {
      hashCalls += 1;
      return "must-not-run";
    },
    consumeRateLimit: async (metadata) => {
      rateMetadata = structuredClone(metadata);
      return false;
    },
  });

  const response = await invokePublic(
    handler,
    publicRequest(rawProof(26)),
  );

  assert.equal(response.statusCode, 429);
  assert.deepEqual(response.body, GENERIC_PUBLIC_RESULT);
  assert.equal(hashCalls, 0);
  assert.deepEqual(rateMetadata, {
    key: "safe-network-key",
    origin: FIRST_PARTY_ORIGIN,
  });
});

test("redacts raw proofs from callable errors and public logs", async () => {
  const proof = rawProof(27);
  const logEntries = [];
  const logger = {
    warn(message, metadata) {
      logEntries.push({ message, metadata });
    },
  };
  const failingHasher = async () => {
    throw new Error(`sensitive hashing detail ${proof}`);
  };
  const { handlers, repository } = createHarness({
    proofs: [proof],
    hashDeletionProof: failingHasher,
    logger,
  });

  let callableError;
  try {
    await handlers.issueDeletionProof(callableRequest("target"));
  } catch (error) {
    callableError = error;
  }
  const handler = runtime.createDeletionProofHttpHandler({
    repository,
    hashDeletionProof: failingHasher,
    consumeRateLimit: async () => true,
    logger,
  });
  const response = await invokePublic(handler, publicRequest(proof));

  assert.equal(callableError.code, "internal");
  assert.deepEqual(callableError.details, {
    code: "account-operation-failed",
  });
  assert.equal(JSON.stringify(callableError).includes(proof), false);
  assert.equal(response.statusCode, 202);
  assert.deepEqual(response.body, GENERIC_PUBLIC_RESULT);
  assert.equal(JSON.stringify(logEntries).includes(proof), false);
  assert.deepEqual(logEntries, [{
    message: "deletion-proof-request-failed",
    metadata: { code: "proof-request-failed" },
  }]);
});

test("registers the public endpoint with an exact first-party CORS origin", () => {
  const handler = async () => {};
  const registrations = [];
  const endpoint = runtime.createDeletionProofHttpEndpoint({
    handler,
    onRequest(options, registeredHandler) {
      registrations.push({ options, registeredHandler });
      return { options, registeredHandler };
    },
  });

  assert.deepEqual(registrations, [{
    options: {
      region: "europe-west3",
      cors: [FIRST_PARTY_ORIGIN],
    },
    registeredHandler: handler,
  }]);
  assert.deepEqual(endpoint, registrations[0]);
});

test("derives domain-separated HMACs from a canonical 32-byte hex secret", () => {
  const digest = runtime.createKeyedDeletionProofDigest({
    getSecret: () =>
      "000102030405060708090a0b0c0d0e0f" +
      "101112131415161718191a1b1c1d1e1f",
  });

  assert.equal(
    digest("proof", "test-proof"),
    "d2d8a60cf5d45496f7aea8425abc930a650c4ab9b1a171fbaedc1605f44878be",
  );
  assert.equal(
    digest("rate", "test-proof"),
    "4e818ce4bcd5bc30e9a87cf7b0f04e979c6814250235a6dc17825b9c5a1129d4",
  );
});

test("rejects missing short and malformed HMAC secrets with one safe error", () => {
  const invalidSecrets = [
    undefined,
    "",
    "00".repeat(31),
    "AA".repeat(32),
    "gg".repeat(32),
    `${"00".repeat(32)}0`,
  ];

  for (const secret of invalidSecrets) {
    const digest = runtime.createKeyedDeletionProofDigest({
      getSecret: () => secret,
    });
    assert.throws(
      () => digest("proof", "raw-proof-must-not-leak"),
      (error) => {
        assert.equal(error.message, "deletion-proof-secret-unavailable");
        assert.equal(
          JSON.stringify(error).includes("raw-proof-must-not-leak"),
          false,
        );
        if (secret) {
          assert.equal(JSON.stringify(error).includes(secret), false);
        }
        return true;
      },
    );
  }

  const accessorFailure = runtime.createKeyedDeletionProofDigest({
    getSecret() {
      throw new Error("provider detail containing raw-secret-material");
    },
  });
  assert.throws(
    () => accessorFailure("proof", "raw-proof-must-not-leak"),
    (error) => {
      assert.equal(error.message, "deletion-proof-secret-unavailable");
      assert.equal(
        JSON.stringify(error)
          .includes("provider detail containing raw-secret-material"),
        false,
      );
      assert.equal(
        JSON.stringify(error).includes("raw-proof-must-not-leak"),
        false,
      );
      return true;
    },
  );
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

test("completes Apple revocation through a transient code without persisting or returning it",
async () => {
  const rawAppleCode = "apple-one-time-code-must-stay-transient";
  const revokedCodes = [];
  const harness = createHarness({
    tokens: {
      apple: decodedToken({
        uid: "apple-account",
        provider: "apple.com",
      }),
    },
    revokeAppleAuthorizationCode: async ({ authorizationCode, uid }) => {
      revokedCodes.push({ authorizationCode, uid });
    },
  });
  const requested = await createDeletionOperation(harness.handlers, "apple");
  const worker = runtime.createDeletionWorkerRuntime({
    repository: harness.repository,
    auth: { async deleteUser() {} },
    deleteUserTreePage: async () => ({ done: true, nextCursor: null }),
    cleanupCommunity: async () => {},
    cleanupProcessor: async () => {},
    nowMillis: () => harness.clock.now,
  });
  const pending = await runWorkerUntil(
    worker,
    requested.operationId,
    "appleRevocationPending",
  );

  const result = await harness.handlers.completeAppleRevocation(
    callableRequest("apple", {
      operationId: requested.operationId,
      expectedVersion: pending.version,
      authorizationCode: rawAppleCode,
    }),
  );

  assert.equal(result.phase, "authDeleted");
  assert.deepEqual(revokedCodes, [{
    authorizationCode: rawAppleCode,
    uid: "apple-account",
  }]);
  assert.equal(
    JSON.stringify(Array.from(harness.firestore.documents.entries()))
      .includes(rawAppleCode),
    false,
  );
  assert.equal(JSON.stringify(result).includes(rawAppleCode), false);
});

test("keeps Apple revocation pending with only a safe resumable failure code",
async () => {
  const rawAppleCode = "apple-code-that-must-not-enter-a-failure";
  const harness = createHarness({
    tokens: {
      apple: decodedToken({
        uid: "apple-failure-account",
        provider: "apple.com",
      }),
    },
    revokeAppleAuthorizationCode: async () => {
      throw new Error(`provider rejected ${rawAppleCode}`);
    },
  });
  const requested = await createDeletionOperation(harness.handlers, "apple");
  const worker = runtime.createDeletionWorkerRuntime({
    repository: harness.repository,
    auth: { async deleteUser() {} },
    deleteUserTreePage: async () => ({ done: true, nextCursor: null }),
    cleanupCommunity: async () => {},
    cleanupProcessor: async () => {},
    nowMillis: () => harness.clock.now,
  });
  const pending = await runWorkerUntil(
    worker,
    requested.operationId,
    "appleRevocationPending",
  );

  await rejectsWithSafeCode(
    harness.handlers.completeAppleRevocation(callableRequest("apple", {
      operationId: requested.operationId,
      expectedVersion: pending.version,
      authorizationCode: rawAppleCode,
    })),
    "internal",
    "account-operation-failed",
  );

  const stored = harness.firestore
    .valuesIn("account_operations")
    .find((operation) => operation.id === requested.operationId);
  assert.equal(stored.phase, "appleRevocationPending");
  assert.equal(
    stored.deletionProgress.statusCode,
    "apple-revocation-retryable",
  );
  assert.equal(JSON.stringify(stored).includes(rawAppleCode), false);
});

test("renews a server worker lease and fences the superseded lease token",
async () => {
  const harness = createHarness();
  const requested = await createDeletionOperation(harness.handlers);
  const first = await harness.repository.claimDeletionWork({
    operationId: requested.operationId,
    workerId: "worker-one",
    leaseMillis: 60_000,
  });
  assert.equal(
    harness.firestore.documents
      .get("account_deletions/durable-target")?.operationId,
    requested.operationId,
  );
  harness.clock.now += 10_000;
  const renewed = await harness.repository.renewDeletionLease({
    operationId: requested.operationId,
    workerId: "worker-one",
    operationVersion: first.operation.version,
    leaseVersion: first.leaseVersion,
    leaseMillis: 60_000,
  });

  assert.equal(renewed.leaseVersion, first.leaseVersion + 1);
  assert.equal(renewed.leaseUntilMillis, harness.clock.now + 60_000);
  await assert.rejects(
    harness.repository.checkpointDeletionWork({
      operationId: requested.operationId,
      workerId: "worker-one",
      operationVersion: first.operation.version,
      leaseVersion: first.leaseVersion,
      progress: { cursor: "stale" },
    }),
    { code: "stale-worker-lease" },
  );
});

test("server deletion takeover clears a legacy completion receipt before " +
    "community cleanup", async () => {
  const harness = createHarness();
  const requested = await createDeletionOperation(harness.handlers);
  harness.firestore.documents.set("account_deletions/durable-target", {
    state: "complete",
    cleanupComplete: true,
    cleanupCompletedAt: "legacy-server-time",
    cleanupGyeIds: ["legacy-gye"],
    cleanupRevision: 7,
    retainedLegacyAudit: "keep",
  });

  await harness.repository.claimDeletionWork({
    operationId: requested.operationId,
    workerId: "takeover-worker",
    leaseMillis: 60_000,
  });

  const takenOver = harness.firestore.documents.get(
    "account_deletions/durable-target",
  );
  assert.equal(takenOver.serverOwned, true);
  assert.equal(takenOver.operationId, requested.operationId);
  assert.equal(takenOver.cleanupComplete, false);
  assert.deepEqual(takenOver.cleanupGyeIds, ["legacy-gye"]);
  assert.equal(takenOver.retainedLegacyAudit, "keep");

  harness.clock.now += 60_001;
  let cleanupReceipt;
  const worker = runtime.createDeletionWorkerRuntime({
    repository: harness.repository,
    auth: { async deleteUser() {} },
    deleteUserTreePage: async () => ({ done: true, nextCursor: null }),
    cleanupCommunity: async () => {
      cleanupReceipt = harness.firestore.documents.get(
        "account_deletions/durable-target",
      ).cleanupComplete;
    },
    cleanupProcessor: async () => {},
    nowMillis: () => harness.clock.now,
  });

  await runWorkerUntil(
    worker,
    requested.operationId,
    "processorCleanupPending",
  );

  assert.equal(cleanupReceipt, false);
});

test("source replacement takeover also clears a legacy completion receipt",
async () => {
  const harness = createHarness();
  const prepared = await prepareReplacement(harness.handlers);
  let operation = prepared;
  for (const name of [
    "attachReplacementTarget",
    "commitReplacementReconciliation",
    "startSourceCleanup",
  ]) {
    operation = await harness.handlers[name](callableRequest("target", {
      operationId: prepared.operationId,
      expectedVersion: operation.version,
    }));
  }
  harness.firestore.documents.set("account_deletions/anonymous-source", {
    state: "complete",
    cleanupComplete: true,
    cleanupGyeIds: ["legacy-gye"],
    cleanupRevision: 3,
  });

  await harness.repository.claimDeletionWork({
    operationId: prepared.operationId,
    workerId: "replacement-takeover-worker",
    leaseMillis: 60_000,
  });

  const takenOver = harness.firestore.documents.get(
    "account_deletions/anonymous-source",
  );
  assert.equal(operation.phase, "sourceCleanupPending");
  assert.equal(takenOver.serverOwned, true);
  assert.equal(takenOver.operationId, prepared.operationId);
  assert.equal(takenOver.cleanupComplete, false);
  assert.deepEqual(takenOver.cleanupGyeIds, ["legacy-gye"]);
});

test("an active server-owned operation retains its own cleanup receipt on " +
    "lease recovery", async () => {
  const harness = createHarness();
  const requested = await createDeletionOperation(harness.handlers);
  await harness.repository.claimDeletionWork({
    operationId: requested.operationId,
    workerId: "first-worker",
    leaseMillis: 60_000,
  });
  const markerPath = "account_deletions/durable-target";
  const activeMarker = harness.firestore.documents.get(markerPath);
  harness.firestore.documents.set(markerPath, {
    ...activeMarker,
    cleanupComplete: true,
    cleanupGyeIds: ["already-cleaned"],
    cleanupRevision: 9,
  });
  harness.clock.now += 60_001;

  await harness.repository.claimDeletionWork({
    operationId: requested.operationId,
    workerId: "recovery-worker",
    leaseMillis: 60_000,
  });

  const recovered = harness.firestore.documents.get(markerPath);
  assert.equal(recovered.serverOwned, true);
  assert.equal(recovered.operationId, requested.operationId);
  assert.equal(recovered.cleanupComplete, true);
  assert.deepEqual(recovered.cleanupGyeIds, ["already-cleaned"]);
  assert.equal(recovered.cleanupRevision, 9);
});

test("rejects a second active claim even when it repeats the same worker ID",
async () => {
  const harness = createHarness();
  const requested = await createDeletionOperation(harness.handlers);
  await harness.repository.claimDeletionWork({
    operationId: requested.operationId,
    workerId: "deterministic-worker-id",
    leaseMillis: 60_000,
  });

  await assert.rejects(
    harness.repository.claimDeletionWork({
      operationId: requested.operationId,
      workerId: "deterministic-worker-id",
      leaseMillis: 60_000,
    }),
    { code: "worker-lease-held" },
  );
});

test("same worker label cannot invoke a destructive adapter concurrently",
async () => {
  const harness = createHarness();
  const requested = await createDeletionOperation(harness.handlers);
  let releaseFirst;
  const firstGate = new Promise((resolve) => {
    releaseFirst = resolve;
  });
  let deleteCalls = 0;
  const nonces = ["invocation-one", "invocation-two"];
  const worker = runtime.createDeletionWorkerRuntime({
    repository: harness.repository,
    auth: { async deleteUser() {} },
    deleteUserTreePage: async () => {
      deleteCalls += 1;
      if (deleteCalls === 1) await firstGate;
      return { done: true, nextCursor: null };
    },
    cleanupCommunity: async () => {},
    cleanupProcessor: async () => {},
    newWorkerInvocationId: () => nonces.shift(),
    nowMillis: () => harness.clock.now,
  });
  const first = worker.processDeletionOperation({
    operationId: requested.operationId,
    workerId: "scheduled-operation-1",
  });
  await new Promise((resolve) => setImmediate(resolve));

  try {
    await assert.rejects(
      worker.processDeletionOperation({
        operationId: requested.operationId,
        workerId: "scheduled-operation-1",
      }),
      { code: "worker-lease-held" },
    );
    assert.equal(deleteCalls, 1);
  } finally {
    releaseFirst();
    await first.catch(() => {});
  }
});

test("replays a completed deletion worker operation without repeating destructive work",
async () => {
  const harness = createHarness();
  const requested = await createDeletionOperation(harness.handlers);
  const calls = [];
  const worker = runtime.createDeletionWorkerRuntime({
    repository: harness.repository,
    auth: {
      async deleteUser(uid) {
        calls.push(`auth:${uid}`);
      },
    },
    deleteUserTreePage: async ({ uid }) => {
      calls.push(`tree:${uid}`);
      return { done: true, nextCursor: null };
    },
    cleanupCommunity: async ({ uid }) => calls.push(`community:${uid}`),
    cleanupProcessor: async ({ uid }) => calls.push(`processor:${uid}`),
    nowMillis: () => harness.clock.now,
  });

  await runWorkerUntil(worker, requested.operationId, "completed");
  const completedCalls = calls.slice();
  const replay = await worker.processDeletionOperation({
    operationId: requested.operationId,
    workerId: "worker-two",
  });

  assert.equal(replay.phase, "completed");
  assert.deepEqual(calls, completedCalls);
});

test("server worker completes replacement source cleanup before target activation",
async () => {
  const harness = createHarness();
  const prepared = await prepareReplacement(harness.handlers);
  const attached = await harness.handlers.attachReplacementTarget(
    callableRequest("target", {
      operationId: prepared.operationId,
      expectedVersion: prepared.version,
    }),
  );
  const reconciling =
    await harness.handlers.commitReplacementReconciliation(
      callableRequest("target", {
        operationId: prepared.operationId,
        expectedVersion: attached.version,
      }),
    );
  const pending = await harness.handlers.startSourceCleanup(
    callableRequest("target", {
      operationId: prepared.operationId,
      expectedVersion: reconciling.version,
    }),
  );
  const calls = [];
  const worker = runtime.createDeletionWorkerRuntime({
    repository: harness.repository,
    auth: {
      async deleteUser(uid) {
        calls.push(`auth:${uid}`);
      },
    },
    deleteUserTreePage: async ({ uid }) => {
      calls.push(`tree:${uid}`);
      return { done: true, nextCursor: null };
    },
    cleanupCommunity: async ({ uid }) => calls.push(`community:${uid}`),
    cleanupProcessor: async ({ uid }) => calls.push(`processor:${uid}`),
    nowMillis: () => harness.clock.now,
  });

  const completed = await runWorkerUntil(
    worker,
    pending.operationId,
    "completed",
  );

  assert.equal(completed.kind, "replacement");
  assert.deepEqual(calls, [
    "tree:anonymous-source",
    "auth:anonymous-source",
    "community:anonymous-source",
    "processor:anonymous-source",
  ]);
});

test("treats Auth user-not-found as successful Auth deletion",
async () => {
  const harness = createHarness();
  const requested = await createDeletionOperation(harness.handlers);
  const worker = runtime.createDeletionWorkerRuntime({
    repository: harness.repository,
    auth: {
      async deleteUser() {
        const error = new Error("no such user");
        error.code = "auth/user-not-found";
        throw error;
      },
    },
    deleteUserTreePage: async () => ({ done: true, nextCursor: null }),
    cleanupCommunity: async () => {},
    cleanupProcessor: async () => {},
    nowMillis: () => harness.clock.now,
  });

  const result = await runWorkerUntil(
    worker,
    requested.operationId,
    "communityCleanupPending",
  );

  assert.equal(result.retryable, true);
  const stored = harness.firestore
    .valuesIn("account_operations")
    .find((operation) => operation.id === requested.operationId);
  assert.equal(stored.phase, "communityCleanupPending");
});

test("server worker resumes Auth deletion only after persisted Apple revocation proof",
async () => {
  const harness = createHarness({
    tokens: {
      apple: decodedToken({
        uid: "apple-resume-account",
        provider: "apple.com",
      }),
    },
  });
  const requested = await createDeletionOperation(harness.handlers, "apple");
  const setupWorker = runtime.createDeletionWorkerRuntime({
    repository: harness.repository,
    auth: { async deleteUser() {} },
    deleteUserTreePage: async () => ({ done: true, nextCursor: null }),
    cleanupCommunity: async () => {},
    cleanupProcessor: async () => {},
    nowMillis: () => harness.clock.now,
  });
  const pending = await runWorkerUntil(
    setupWorker,
    requested.operationId,
    "appleRevocationPending",
  );
  let claim = await harness.repository.claimDeletionWork({
    operationId: requested.operationId,
    workerId: "revocation-boundary",
    allowAppleRevocationInput: true,
  });
  claim = await harness.repository.renewDeletionLease({
    operationId: requested.operationId,
    workerId: "revocation-boundary",
    operationVersion: pending.version,
    leaseVersion: claim.leaseVersion,
  });
  await harness.repository.checkpointDeletionWork({
    operationId: requested.operationId,
    workerId: "revocation-boundary",
    operationVersion: pending.version,
    leaseVersion: claim.leaseVersion,
    progress: { appleRevocationComplete: true },
  });

  let authDeletes = 0;
  const recoveryWorker = runtime.createDeletionWorkerRuntime({
    repository: harness.repository,
    auth: {
      async deleteUser() {
        authDeletes += 1;
        const error = new Error("already gone after response loss");
        error.code = "auth/user-not-found";
        throw error;
      },
    },
    deleteUserTreePage: async () => {
      assert.fail("user tree must not be deleted again");
    },
    cleanupCommunity: async () => {},
    cleanupProcessor: async () => {},
    nowMillis: () => harness.clock.now,
  });

  const recovered = await recoveryWorker.processDeletionOperation({
    operationId: requested.operationId,
    workerId: "recovery-worker",
  });

  assert.equal(recovered.phase, "authDeleted");
  assert.equal(authDeletes, 1);
});

test("incomplete Apple input wait is never leased and can complete immediately",
async () => {
  const rawAppleCode = "immediate-apple-authorization-code";
  const harness = createHarness({
    tokens: {
      apple: decodedToken({
        uid: "apple-wait-account",
        provider: "apple.com",
      }),
    },
  });
  const requested = await createDeletionOperation(harness.handlers, "apple");
  const schedulerWorker = runtime.createDeletionWorkerRuntime({
    repository: harness.repository,
    auth: { async deleteUser() {} },
    deleteUserTreePage: async () => ({ done: true, nextCursor: null }),
    cleanupCommunity: async () => {},
    cleanupProcessor: async () => {},
    newWorkerInvocationId: () => "scheduler-invocation",
    nowMillis: () => harness.clock.now,
  });
  const pending = await runWorkerUntil(
    schedulerWorker,
    requested.operationId,
    "appleRevocationPending",
  );
  const beforeWait = structuredClone(
    harness.firestore.documents.get(
      `account_operations/${requested.operationId}`,
    ),
  );

  const waiting = await schedulerWorker.processDeletionOperation({
    operationId: requested.operationId,
    workerId: `scheduled-${requested.operationId}`,
  });
  const afterWait = harness.firestore.documents.get(
    `account_operations/${requested.operationId}`,
  );

  assert.equal(waiting.phase, "appleRevocationPending");
  assert.deepEqual(afterWait.workerLease, beforeWait.workerLease);
  const completed = await harness.handlers.completeAppleRevocation(
    callableRequest("apple", {
      operationId: requested.operationId,
      expectedVersion: pending.version,
      authorizationCode: rawAppleCode,
    }),
  );
  assert.equal(completed.phase, "authDeleted");
});

test("persists paged user-tree continuation before Auth deletion",
async () => {
  const harness = createHarness();
  const requested = await createDeletionOperation(harness.handlers);
  const cursors = [];
  let authDeletes = 0;
  const worker = runtime.createDeletionWorkerRuntime({
    repository: harness.repository,
    auth: {
      async deleteUser() {
        authDeletes += 1;
      },
    },
    deleteUserTreePage: async ({ cursor }) => {
      cursors.push(cursor ?? null);
      return cursor === "page-two"
        ? { done: true, nextCursor: null }
        : { done: false, nextCursor: "page-two" };
    },
    cleanupCommunity: async () => {},
    cleanupProcessor: async () => {},
    nowMillis: () => harness.clock.now,
  });

  const first = await worker.processDeletionOperation({
    operationId: requested.operationId,
    workerId: "worker-one",
  });
  const firstStored = harness.firestore
    .valuesIn("account_operations")
    .find((operation) => operation.id === requested.operationId);
  const second = await worker.processDeletionOperation({
    operationId: requested.operationId,
    workerId: "worker-one",
  });

  assert.equal(first.phase, "userTreeDeleting");
  assert.equal(firstStored.deletionProgress.cursor, "page-two");
  assert.equal(second.phase, "userTreeDeleting");
  assert.deepEqual(cursors, [null, "page-two"]);
  assert.equal(authDeletes, 0);
});

test("passes the renewed operation lease fence into each destructive tree page",
async () => {
  const harness = createHarness();
  const requested = await createDeletionOperation(harness.handlers);
  const fences = [];
  const worker = runtime.createDeletionWorkerRuntime({
    repository: harness.repository,
    auth: { async deleteUser() {} },
    deleteUserTreePage: async ({ workerFence }) => {
      fences.push(workerFence);
      return { done: false, nextCursor: "work-v1" };
    },
    cleanupCommunity: async () => {},
    cleanupProcessor: async () => {},
    nowMillis: () => harness.clock.now,
  });

  const result = await worker.processDeletionOperation({
    operationId: requested.operationId,
    workerId: "scheduled-operation",
  });

  assert.equal(fences.length, 1);
  assert.equal(typeof fences[0].workerId, "string");
  assert(fences[0].workerId.length > 0);
  assert.equal(fences[0].operationVersion, result.version);
  assert.equal(fences[0].leaseVersion, 2);
});

test("does not complete before Gye community and processor cleanup phases finish",
async () => {
  const harness = createHarness();
  const requested = await createDeletionOperation(harness.handlers);
  const phases = [];
  let releaseCommunity;
  const communityGate = new Promise((resolve) => {
    releaseCommunity = resolve;
  });
  const worker = runtime.createDeletionWorkerRuntime({
    repository: harness.repository,
    auth: { async deleteUser() {} },
    deleteUserTreePage: async () => ({ done: true, nextCursor: null }),
    cleanupCommunity: async () => {
      phases.push("community-started");
      await communityGate;
      phases.push("community-finished");
    },
    cleanupProcessor: async () => phases.push("processor-finished"),
    nowMillis: () => harness.clock.now,
  });
  await runWorkerUntil(
    worker,
    requested.operationId,
    "communityCleanupPending",
  );

  const communityRun = worker.processDeletionOperation({
    operationId: requested.operationId,
    workerId: "worker-one",
  });
  await new Promise((resolve) => setImmediate(resolve));
  const during = harness.firestore
    .valuesIn("account_operations")
    .find((operation) => operation.id === requested.operationId);
  assert.equal(during.phase, "communityCleanupPending");
  releaseCommunity();
  const afterCommunity = await communityRun;
  assert.equal(afterCommunity.phase, "processorCleanupPending");
  assert.deepEqual(phases, ["community-started", "community-finished"]);

  const completed = await worker.processDeletionOperation({
    operationId: requested.operationId,
    workerId: "worker-one",
  });
  assert.equal(completed.phase, "completed");
  assert.deepEqual(phases, [
    "community-started",
    "community-finished",
    "processor-finished",
  ]);
});

test("never lets legacy tombstone cleanup abandon a server-owned marker",
() => {
  assert.equal(
    runtime.legacyAccountTombstoneCleanupAction({
      marker: {
        state: "active",
        serverOwned: true,
        operationId: "operation-1",
      },
      authUserExists: true,
      firestoreUserExists: true,
      cleanupComplete: false,
      cleanupStarted: false,
      nowMillis: NOW_MILLIS,
    }),
    "retain",
  );
});

test("replacement backlog cannot exclude a due deletion candidate", async () => {
  const source = [
    ...Array.from({ length: 80 }, (_, index) => ({
      id: `replacement-${index}`,
      kind: "replacement",
      phase: "sourceCleanupPending",
      nextAttemptAtMillis: NOW_MILLIS,
      updatedAtMillis: NOW_MILLIS + index,
    })),
    {
      id: "due-deletion",
      kind: "deletion",
      phase: "deletionRequested",
      nextAttemptAtMillis: NOW_MILLIS,
      updatedAtMillis: NOW_MILLIS + 100,
    },
  ];

  const candidates = await runtime.fetchActionableDeletionCandidates({
    collection: fakeAccountOperationCollection(source),
    limit: 50,
    nowMillis: NOW_MILLIS,
  });

  assert(candidates.some((candidate) => candidate.id === "due-deletion"));
});

test("scheduler excludes deletion work whose retry time is not due", async () => {
  const source = [
    {
      id: "due-deletion",
      kind: "deletion",
      phase: "deletionRequested",
      nextAttemptAtMillis: NOW_MILLIS,
      updatedAtMillis: NOW_MILLIS,
    },
    {
      id: "future-deletion",
      kind: "deletion",
      phase: "deletionRequested",
      nextAttemptAtMillis: NOW_MILLIS + 1,
      updatedAtMillis: NOW_MILLIS,
    },
  ];

  const candidates = await runtime.fetchActionableDeletionCandidates({
    collection: fakeAccountOperationCollection(source),
    limit: 50,
    nowMillis: NOW_MILLIS,
  });

  assert.deepEqual(
    candidates.map((candidate) => candidate.id),
    ["due-deletion"],
  );
});

test("failed worker work is deferred with a safe code", async () => {
  const rawAdapterError = "provider-secret-error-detail";
  const warnings = [];
  const harness = createHarness();
  const requested = await createDeletionOperation(harness.handlers);
  const workerRuntime = runtime.createDeletionWorkerRuntime({
    repository: harness.repository,
    auth: { async deleteUser() {} },
    deleteUserTreePage: async () => {
      throw new Error(rawAdapterError);
    },
    cleanupCommunity: async () => {},
    cleanupProcessor: async () => {},
    newWorkerInvocationId: () => "failed-invocation",
    nowMillis: () => harness.clock.now,
  });

  await runtime.runScheduledDeletionCandidate({
    candidate: { id: requested.operationId },
    repository: harness.repository,
    workerRuntime,
    logger: {
      warn(...args) {
        warnings.push(args);
      },
    },
    nowMillis: () => harness.clock.now,
  });

  const stored = harness.firestore.documents.get(
    `account_operations/${requested.operationId}`,
  );
  assert.equal(stored.deletionProgress.statusCode, "worker-failed");
  assert(stored.nextAttemptAtMillis > NOW_MILLIS);
  assert(stored.nextAttemptAtMillis <= NOW_MILLIS + 3_600_000);
  assert.equal(JSON.stringify(stored).includes(rawAdapterError), false);
  assert.equal(JSON.stringify(warnings).includes(rawAdapterError), false);
  assert.deepEqual(warnings, [
    ["account-deletion-worker-failed", { code: "worker-failed" }],
  ]);
});

test("legacy scheduler backfills a due operation before due-only selection",
async () => {
  const harness = createHarness();
  const requested = await createDeletionOperation(harness.handlers);
  const operationPath = `account_operations/${requested.operationId}`;
  const legacy = harness.firestore.documents.get(operationPath);
  delete legacy.nextAttemptAtMillis;
  const collection = fakeAccountOperationCollection(() =>
    harness.firestore.valuesIn("account_operations"));

  const candidates = await runtime.fetchStagedActionableDeletionCandidates({
    repository: harness.repository,
    collection,
    limit: 50,
    legacyBackfillLimit: 50,
    nowMillis: NOW_MILLIS,
  });

  assert(candidates.some(({ id }) => id === requested.operationId));
  assert.equal(
    harness.firestore.documents.get(operationPath).nextAttemptAtMillis,
    NOW_MILLIS,
  );
  assert.equal(
    harness.firestore.documents.get(
      "account_operation_migrations/deletion-scheduler-next-at-v1",
    ).complete,
    true,
  );
});

test("legacy scheduler keeps due-only work moving during bounded backfill",
async () => {
  const harness = createHarness();
  const legacy = await createDeletionOperation(harness.handlers);
  const currentDue = await createDeletionOperation(
    harness.handlers,
    "other",
  );
  delete harness.firestore.documents
    .get(`account_operations/${legacy.operationId}`).nextAttemptAtMillis;
  harness.firestore.documents.set("account_operations/operation-1a", {
    id: "operation-1a",
    kind: "deletion",
    phase: "deletionRequested",
    sourceUid: "second-legacy-account",
    version: 1,
    updatedAtMillis: NOW_MILLIS,
  });
  harness.firestore.documents.set("account_operations/zz-future", {
    id: "zz-future",
    kind: "deletion",
    phase: "deletionRequested",
    sourceUid: "future-account",
    version: 1,
    nextAttemptAtMillis: NOW_MILLIS + 1,
    updatedAtMillis: NOW_MILLIS,
  });
  const collection = fakeAccountOperationCollection(() =>
    harness.firestore.valuesIn("account_operations"));
  const options = {
    repository: harness.repository,
    collection,
    limit: 50,
    legacyBackfillLimit: 1,
    nowMillis: NOW_MILLIS,
  };

  const staged = await runtime.fetchStagedActionableDeletionCandidates(options);

  assert.deepEqual(
    staged.map(({ id }) => id).sort(),
    [legacy.operationId, currentDue.operationId].sort(),
  );
  assert.equal(
    harness.firestore.valuesIn("account_operations")
      .filter((operation) => Number.isFinite(operation.nextAttemptAtMillis))
      .length,
    3,
  );
  assert.equal(
    harness.firestore.documents.get(
      "account_operation_migrations/deletion-scheduler-next-at-v1",
    ).complete,
    false,
  );
  assert.equal(
    harness.firestore.documents.get(
      "account_operation_migrations/deletion-scheduler-next-at-v1",
    ).backfilledCount,
    1,
  );
  assert.equal(
    harness.firestore.documents.get(
      "account_operations/operation-1a",
    ).nextAttemptAtMillis,
    undefined,
  );
});

test("scheduler candidates cannot be starved by more than fifty Apple waits",
async () => {
  const source = [
    ...Array.from({ length: 51 }, (_, index) => ({
      id: `apple-${index}`,
      kind: "deletion",
      phase: "appleRevocationPending",
      nextAttemptAtMillis: NOW_MILLIS,
      updatedAtMillis: NOW_MILLIS + index,
    })),
    {
      id: "actionable-deletion",
      kind: "deletion",
      phase: "deletionRequested",
      nextAttemptAtMillis: NOW_MILLIS,
      updatedAtMillis: NOW_MILLIS + 100,
    },
  ];

  const candidates = await runtime.fetchActionableDeletionCandidates({
    collection: fakeAccountOperationCollection(source),
    limit: 50,
    nowMillis: NOW_MILLIS,
  });

  assert.deepEqual(
    candidates.map((candidate) => candidate.id),
    ["actionable-deletion"],
  );
});

test("scheduler includes completed Apple checkpoints but excludes incomplete waits",
async () => {
  const source = [
    ...Array.from({ length: 51 }, (_, index) => ({
      id: `incomplete-apple-${index}`,
      kind: "deletion",
      phase: "appleRevocationPending",
      deletionProgress: { appleRevocationComplete: false },
      nextAttemptAtMillis: NOW_MILLIS,
      updatedAtMillis: NOW_MILLIS + index,
    })),
    {
      id: "completed-apple-checkpoint",
      kind: "deletion",
      phase: "appleRevocationPending",
      deletionProgress: { appleRevocationComplete: true },
      nextAttemptAtMillis: NOW_MILLIS,
      updatedAtMillis: NOW_MILLIS + 100,
    },
    {
      id: "actionable-deletion",
      kind: "deletion",
      phase: "deletionRequested",
      nextAttemptAtMillis: NOW_MILLIS,
      updatedAtMillis: NOW_MILLIS + 101,
    },
  ];

  const candidates = await runtime.fetchActionableDeletionCandidates({
    collection: fakeAccountOperationCollection(source),
    limit: 50,
    nowMillis: NOW_MILLIS,
  });

  assert.deepEqual(
    candidates.map((candidate) => candidate.id),
    ["actionable-deletion", "completed-apple-checkpoint"],
  );
});

test("index exports the protected callables and public proof endpoint", () => {
  const deployed = require("./index");
  for (const name of CALLABLE_NAMES) {
    assert.equal(typeof deployed[name], "function", `${name} export`);
  }
  assert.equal(
    typeof deployed.requestDeletionByProof,
    "function",
    "requestDeletionByProof export",
  );
  assert.equal(
    typeof deployed.account_deletion_worker,
    "function",
    "account_deletion_worker export",
  );
  const appleSecretNames = [
    "APPLE_REVOKE_CLIENT_ID",
    "APPLE_REVOKE_TEAM_ID",
    "APPLE_REVOKE_KEY_ID",
    "APPLE_REVOKE_PRIVATE_KEY",
  ];
  assert.deepEqual(
    deployed.completeAppleRevocation.__endpoint.secretEnvironmentVariables
      .map((secret) => secret.key),
    appleSecretNames,
  );
  assert.equal(
    deployed.account_deletion_worker.__endpoint.secretEnvironmentVariables,
    undefined,
  );
  for (const name of CALLABLE_NAMES.filter(
    (callableName) => callableName !== "completeAppleRevocation",
  )) {
    const boundNames = (deployed[name].__endpoint.secretEnvironmentVariables ||
      []).map((secret) => secret.key);
    assert.equal(
      boundNames.some((secretName) => appleSecretNames.includes(secretName)),
      false,
      `${name} must not bind Apple revocation secrets`,
    );
  }
});
