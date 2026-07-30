"use strict";

const assert = require("node:assert/strict");
const { createHmac } = require("node:crypto");
const test = require("node:test");

const {
  BACKUP_FIELDS,
  BACKUP_ROOTS,
  CALLABLE_OPTIONS,
  createCloudBackupDeletionCallable,
  createCloudBackupDeletionRuntime,
} = require("./cloud_backup_deletion_runtime");

function callableRequest(uid, data = {}, {
  app = true,
  alreadyConsumed = false,
} = {}) {
  return {
    auth: uid == null ? undefined : { uid },
    app: app ? { appId: "test-app", alreadyConsumed } : undefined,
    data,
  };
}

function safeError(status, safeCode) {
  const error = new Error("cloud-backup-deletion-failed");
  error.code = status;
  error.details = { code: safeCode };
  return error;
}

function rejectsWithSafeCode(promise, status, safeCode) {
  return assert.rejects(
    promise,
    (error) => {
      assert.equal(error.code, status);
      assert.deepEqual(error.details, { code: safeCode });
      return true;
    },
  );
}

class MemoryOperationRepository {
  constructor() {
    this.records = new Map();
    this.claims = 0;
  }

  async claim({
    uid,
    requestDigest,
    invocationId,
    nowMillis,
    leaseMillis,
  }) {
    this.claims += 1;
    let record = this.records.get(uid);
    if (!record || (
      record.state.status === "completed" &&
      record.requestDigest !== requestDigest
    )) {
      record = {
        uid,
        requestDigest,
        state: {
          status: "pending",
          rootIndex: 0,
          stack: [],
          leaseOwner: invocationId,
          leaseUntilMillis: nowMillis + leaseMillis,
        },
        createdAtMillis: nowMillis,
        updatedAtMillis: nowMillis,
      };
      this.records.set(uid, record);
      return structuredClone(record);
    }
    if (record.state.status === "completed") {
      return structuredClone(record);
    }
    if (record.state.leaseOwner !== invocationId &&
        record.state.leaseUntilMillis > nowMillis) {
      return {
        ...structuredClone(record),
        busy: true,
      };
    }
    record.state.leaseOwner = invocationId;
    record.state.leaseUntilMillis = nowMillis + leaseMillis;
    record.updatedAtMillis = nowMillis;
    return structuredClone(record);
  }

  async checkpoint({
    uid,
    requestDigest,
    invocationId,
    state,
    nowMillis,
  }) {
    const record = this.records.get(uid);
    assert.equal(record.requestDigest, requestDigest);
    assert.equal(record.state.leaseOwner, invocationId);
    record.state = structuredClone(state);
    record.updatedAtMillis = nowMillis;
    return structuredClone(record);
  }
}

class MemoryBackupStore {
  constructor({ documents, user }) {
    this.documents = new Set(documents);
    this.user = structuredClone(user);
    this.deleted = [];
  }

  async firstDocument(collectionPath) {
    const prefix = `${collectionPath}/`;
    const collectionSegments = collectionPath.split("/").length;
    const documents = Array.from(this.documents)
      .filter((path) => {
        const segments = path.split("/");
        return path.startsWith(prefix) &&
          segments.length === collectionSegments + 1;
      })
      .sort();
    const missingParents = Array.from(this.documents)
      .filter((path) => path.startsWith(prefix))
      .map((path) =>
        path.split("/").slice(0, collectionSegments + 1).join("/"))
      .sort();
    return documents[0] || missingParents[0] || null;
  }

  async firstChildCollection(documentPath) {
    const prefix = `${documentPath}/`;
    const documentSegments = documentPath.split("/").length;
    const child = Array.from(this.documents)
      .filter((path) => path.startsWith(prefix))
      .map((path) => path.split("/"))
      .filter((segments) => segments.length >= documentSegments + 2)
      .map((segments) =>
        segments.slice(0, documentSegments + 1).join("/"))
      .sort();
    return child[0] || null;
  }

  async deleteDocument(documentPath) {
    this.documents.delete(documentPath);
    this.deleted.push(documentPath);
  }

  async removeBackupFields(uid, fields) {
    assert.equal(uid, "durable");
    for (const field of fields) {
      delete this.user[field];
    }
  }
}

function createHarness({
  pageSize = 200,
  documents = [],
  user = {},
} = {}) {
  const repository = new MemoryOperationRepository();
  const store = new MemoryBackupStore({ documents, user });
  let invocation = 0;
  const seenHashInputs = [];
  const handlers = createCloudBackupDeletionRuntime({
    repository,
    store,
    hashRequestKey({ uid, requestKey }) {
      seenHashInputs.push({ uid, requestKey });
      return createHmac("sha256", "unit-test-only-key")
        .update(uid)
        .update("\0")
        .update(requestKey)
        .digest("hex");
    },
    newInvocationId: () => `invocation-${++invocation}`,
    nowMillis: () => 1_000,
    pageSize,
    makeError: safeError,
  });
  return { handlers, repository, seenHashInputs, store };
}

test("cloud backup deletion removes every root and descendant while preserving operational fields", async () => {
  const documents = [
    "users/durable/packs/p1",
    "users/durable/quests/q1",
    "users/durable/bookshelf/b1",
    "users/durable/custom_packs/c1",
    "users/durable/custom_packs/c1/items/i1",
    "users/durable/custom_words/w1",
    "users/durable/sync_generations/g1",
    "users/durable/sync_generations/g1/bookshelf/p1",
    "users/durable/sync_metadata/bookshelf_active",
    "users/durable/sync_metadata/pack_progress",
  ];
  const user = {
    gyeIds: ["gye-a"],
    blockedUids: ["blocked"],
    fcmTokens: ["token"],
    progress: { xp: 12 },
    bookshelf_json: "legacy",
    displayName: "operational profile",
  };
  const { handlers, store } = createHarness({ documents, user });

  const result = await handlers.deleteCloudBackup(
    callableRequest("durable", { requestKey: "A".repeat(43) }),
  );

  assert.deepEqual(result, { state: "completed" });
  assert.deepEqual(Array.from(store.documents), []);
  assert.deepEqual(store.user.gyeIds, ["gye-a"]);
  assert.deepEqual(store.user.blockedUids, ["blocked"]);
  assert.deepEqual(store.user.fcmTokens, ["token"]);
  assert.equal(store.user.displayName, "operational profile");
  for (const field of BACKUP_FIELDS) {
    assert.equal(Object.hasOwn(store.user, field), false);
  }
  assert.deepEqual(BACKUP_ROOTS, [
    "packs",
    "quests",
    "bookshelf",
    "custom_packs",
    "custom_words",
    "sync_generations",
    "sync_metadata",
  ]);
});

test("bounded work returns pending and resumes the same digest idempotently", async () => {
  const { handlers, repository, seenHashInputs, store } = createHarness({
    pageSize: 1,
    documents: [
      "users/durable/packs/p1",
      "users/durable/packs/p2",
    ],
    user: { progress: 1 },
  });
  const request = callableRequest("durable", {
    requestKey: "B".repeat(43),
  });

  let result = await handlers.deleteCloudBackup(request);
  assert.deepEqual(result, { state: "pending" });
  for (let attempt = 0;
    attempt < 40 && result.state === "pending";
    attempt += 1) {
    result = await handlers.deleteCloudBackup(request);
  }

  assert.deepEqual(result, { state: "completed" });
  assert.deepEqual(Array.from(store.documents), []);
  assert.equal(repository.records.size, 1);
  assert.equal(repository.records.get("durable").requestDigest.length, 64);
  assert.equal(
    JSON.stringify(repository.records.get("durable"))
      .includes("B".repeat(43)),
    false,
  );
  assert.deepEqual(seenHashInputs, Array.from(
    { length: repository.claims },
    () => ({ uid: "durable", requestKey: "B".repeat(43) }),
  ));
});

test("a different request cannot race an active deletion", async () => {
  const { handlers, repository } = createHarness({
    pageSize: 1,
    documents: ["users/durable/packs/p1"],
  });
  const first = "C".repeat(43);
  const second = "D".repeat(43);

  assert.deepEqual(
    await handlers.deleteCloudBackup(
      callableRequest("durable", { requestKey: first }),
    ),
    { state: "pending" },
  );
  const firstDigest = repository.records.get("durable").requestDigest;
  assert.deepEqual(
    await handlers.deleteCloudBackup(
      callableRequest("durable", { requestKey: second }),
    ),
    { state: "pending" },
  );
  assert.equal(repository.records.get("durable").requestDigest, firstDigest);
});

test("callable derives UID from auth and rejects extra or malformed data", async () => {
  const { handlers, seenHashInputs } = createHarness();

  await rejectsWithSafeCode(
    handlers.deleteCloudBackup(
      callableRequest(null, { requestKey: "E".repeat(43) }),
    ),
    "unauthenticated",
    "authentication-required",
  );
  await rejectsWithSafeCode(
    handlers.deleteCloudBackup(
      callableRequest("durable", { requestKey: "E".repeat(43) }, {
        app: false,
      }),
    ),
    "failed-precondition",
    "app-check-required",
  );
  await rejectsWithSafeCode(
    handlers.deleteCloudBackup(
      callableRequest("durable", { requestKey: "E".repeat(43) }, {
        alreadyConsumed: true,
      }),
    ),
    "resource-exhausted",
    "app-check-token-consumed",
  );
  await rejectsWithSafeCode(
    handlers.deleteCloudBackup(callableRequest("durable", {
      requestKey: "E".repeat(43),
      uid: "victim",
    })),
    "invalid-argument",
    "invalid-request",
  );
  await rejectsWithSafeCode(
    handlers.deleteCloudBackup(callableRequest("durable", {
      requestKey: "short",
    })),
    "invalid-argument",
    "invalid-request",
  );

  assert.deepEqual(seenHashInputs, []);
});

test("registers the callable with App Check enforcement and token consumption", () => {
  const registrations = [];
  const callable = createCloudBackupDeletionCallable({
    handler: async () => ({ state: "pending" }),
    onCall(options, handler) {
      registrations.push({ options, handler });
      return { options, handler };
    },
    secrets: [{ name: "DELETION_PROOF_HMAC_KEY" }],
  });

  assert.deepEqual(registrations[0].options, {
    ...CALLABLE_OPTIONS,
    secrets: [{ name: "DELETION_PROOF_HMAC_KEY" }],
  });
  assert.deepEqual(callable.options, registrations[0].options);
  assert.equal(callable.handler, registrations[0].handler);
});
