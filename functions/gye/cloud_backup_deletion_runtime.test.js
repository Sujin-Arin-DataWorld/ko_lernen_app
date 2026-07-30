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
  createFirestoreCloudBackupDeletionRepository,
  createFirestoreCloudBackupStore,
} = require("./cloud_backup_deletion_runtime");

function callableRequest(uid, data = {}, {
  app = true,
  alreadyConsumed = false,
  signInProvider = "google.com",
} = {}) {
  return {
    auth: uid == null
      ? undefined
      : {
        uid,
        token: { firebase: { sign_in_provider: signInProvider } },
      },
    app: app ? { appId: "test-app", alreadyConsumed } : undefined,
    data,
  };
}

function maxDepthDocumentPath() {
  const segments = ["users", "durable"];
  // Firestore allows 100 nested collection levels. `users` is level 1 and
  // the fixed backup root is level 2, leaving 98 valid dynamic levels.
  for (let collectionDepth = 2;
    collectionDepth <= 100;
    collectionDepth += 1) {
    segments.push(
      collectionDepth === 2 ? "packs" : `child_${collectionDepth}`,
      `document_${collectionDepth}`,
    );
  }
  return segments.join("/");
}

function expectPageTokenWasUsed(pages, path, token) {
  assert.equal(
    pages.filter((page) =>
      page.collectionPath === path && page.pageToken === token,
    ).length >= 1,
    true,
  );
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

class FakeFirestoreSnapshot {
  constructor(value) {
    this.value = value;
    this.exists = value !== undefined;
  }

  data() {
    return this.value === undefined ? undefined : structuredClone(this.value);
  }
}

class FakeFirestoreDocumentReference {
  constructor(firestore, path) {
    this.firestore = firestore;
    this.path = path;
  }

  collection(name) {
    return new FakeFirestoreCollectionReference(
      this.firestore,
      `${this.path}/${name}`,
    );
  }
}

class FakeFirestoreCollectionReference {
  constructor(firestore, path) {
    this.firestore = firestore;
    this.path = path;
  }

  doc(id) {
    return new FakeFirestoreDocumentReference(this.firestore, `${this.path}/${id}`);
  }
}

class FakeTransactionalFirestore {
  constructor() {
    this.documents = new Map();
  }

  collection(path) {
    return new FakeFirestoreCollectionReference(this, path);
  }

  doc(path) {
    return new FakeFirestoreDocumentReference(this, path);
  }

  seed(path, value) {
    this.documents.set(path, structuredClone(value));
  }

  value(path) {
    const value = this.documents.get(path);
    return value === undefined ? undefined : structuredClone(value);
  }

  runTransaction(callback) {
    const writes = new Map();
    let wrote = false;
    const read = (reference) => writes.has(reference.path)
      ? writes.get(reference.path)
      : this.documents.get(reference.path);
    const transaction = {
      get: async (reference) => {
        assert.equal(
          wrote,
          false,
          "Firestore transactions must finish reads before writes",
        );
        return new FakeFirestoreSnapshot(read(reference));
      },
      set: (reference, value) => {
        wrote = true;
        writes.set(reference.path, structuredClone(value));
      },
      update: (reference, changes) => {
        wrote = true;
        const current = read(reference);
        assert.notEqual(current, undefined, "cannot update a missing document");
        const next = structuredClone(current);
        for (const [field, value] of Object.entries(changes)) {
          if (value === fakeFieldDelete) {
            delete next[field];
          } else {
            next[field] = structuredClone(value);
          }
        }
        writes.set(reference.path, next);
      },
      delete: (reference) => {
        wrote = true;
        writes.set(reference.path, undefined);
      },
    };
    return Promise.resolve(callback(transaction)).then((result) => {
      for (const [path, value] of writes) {
        if (value === undefined) {
          this.documents.delete(path);
        } else {
          this.documents.set(path, value);
        }
      }
      return result;
    });
  }
}

const fakeFieldDelete = Object.freeze({ kind: "field-delete" });

function keysetPage(items, pageToken) {
  const cursor = pageToken == null ? null : pageToken;
  const index = cursor === null
    ? 0
    : items.findIndex((item) => item > cursor);
  if (index < 0) {
    return { item: null, nextPageToken: null };
  }
  return {
    item: items[index],
    nextPageToken: index + 1 < items.length ? items[index] : null,
  };
}

function firestoreDocumentIds(firestore, collectionPath) {
  const prefix = `${collectionPath}/`;
  return Array.from(new Set(Array.from(firestore.documents.keys())
    .filter((path) => path.startsWith(prefix))
    .map((path) => path.slice(prefix.length).split("/")[0])))
    .sort();
}

function firestoreCollectionIds(firestore, parentPath) {
  const prefix = `${parentPath}/`;
  return Array.from(new Set(Array.from(firestore.documents.keys())
    .filter((path) => path.startsWith(prefix))
    .map((path) => path.slice(prefix.length).split("/")[0])))
    .sort();
}

function createTransactionalFirestoreHarness({
  documents = [],
  user = {},
  pageSize = 200,
  onListCollectionIds,
} = {}) {
  const firestore = new FakeTransactionalFirestore();
  firestore.seed("users/durable", user);
  for (const path of documents) {
    firestore.seed(path, {});
  }
  const listDocumentsPage = async ({ collectionPath, pageSize: limit, pageToken }) => {
    assert.equal(limit, 1);
    const page = keysetPage(
      firestoreDocumentIds(firestore, collectionPath),
      pageToken,
    );
    return {
      documentIds: page.item === null ? [] : [page.item],
      nextPageToken: page.nextPageToken,
    };
  };
  const listCollectionIdsPage = async ({ parentPath, pageSize: limit, pageToken }) => {
    assert.equal(limit, 1);
    if (onListCollectionIds) {
      const response = await onListCollectionIds({ parentPath, pageToken });
      if (response !== undefined) return response;
    }
    const page = keysetPage(
      firestoreCollectionIds(firestore, parentPath),
      pageToken,
    );
    return {
      collectionIds: page.item === null ? [] : [page.item],
      nextPageToken: page.nextPageToken,
    };
  };
  const repository = createFirestoreCloudBackupDeletionRepository({
    firestore,
    fieldValue: { delete: () => fakeFieldDelete },
  });
  const store = createFirestoreCloudBackupStore({
    listCollectionIdsPage,
    listDocumentsPage,
  });
  const clock = { now: 1_000 };
  let invocation = 0;
  const handlers = createCloudBackupDeletionRuntime({
    repository,
    store,
    hashRequestKey: () => "a".repeat(64),
    newInvocationId: () => `worker-${++invocation}`,
    nowMillis: () => clock.now,
    pageSize,
    makeError: safeError,
  });
  return { clock, firestore, handlers, repository };
}

class MemoryOperationRepository {
  constructor(store) {
    this.store = store;
    this.records = new Map();
    this.work = new Map();
    this.advanceCalls = 0;
    this.spawnCalls = 0;
    this.claims = 0;
    this.maxWorkCount = 0;
    this.maxOperationBytes = 0;
  }

  _workKey(uid, id) {
    return `${uid}/${id}`;
  }

  _recordState(record) {
    this.maxOperationBytes = Math.max(
      this.maxOperationBytes,
      Buffer.byteLength(JSON.stringify(record), "utf8"),
    );
  }

  _trackWork() {
    this.maxWorkCount = Math.max(this.maxWorkCount, this.work.size);
  }

  _assertLease(record, {
    requestDigest,
    invocationId,
    expectedState,
  }) {
    assert.equal(record.requestDigest, requestDigest);
    assert.equal(record.state.status, "pending");
    assert.equal(record.state.leaseOwner, invocationId);
    if (expectedState !== undefined) {
      assert.equal(record.state.rootIndex, expectedState.rootIndex);
      assert.equal(record.state.currentWorkId, expectedState.currentWorkId);
    }
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
          currentWorkId: null,
          leaseOwner: invocationId,
          leaseUntilMillis: nowMillis + leaseMillis,
        },
        createdAtMillis: nowMillis,
        updatedAtMillis: nowMillis,
      };
      this.records.set(uid, record);
      this._recordState(record);
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
    this._recordState(record);
    return structuredClone(record);
  }

  async currentWork({
    uid,
    requestDigest,
    invocationId,
    expectedState,
  }) {
    const record = this.records.get(uid);
    this._assertLease(record, { requestDigest, invocationId, expectedState });
    if (record.state.currentWorkId === null) return null;
    const work = this.work.get(this._workKey(uid, record.state.currentWorkId));
    assert.ok(work, "current work must have a durable receipt");
    return structuredClone(work);
  }

  async startRoot({
    uid,
    requestDigest,
    invocationId,
    expectedState,
    work,
    nowMillis,
  }) {
    const record = this.records.get(uid);
    this._assertLease(record, { requestDigest, invocationId, expectedState });
    assert.equal(record.state.currentWorkId, null);
    assert.equal(record.state.rootIndex, work.rootIndex);
    assert.equal(work.parentWorkId, null);
    const key = this._workKey(uid, work.id);
    assert.equal(this.work.has(key), false);
    this.work.set(key, structuredClone(work));
    record.state.currentWorkId = work.id;
    record.updatedAtMillis = nowMillis;
    this._trackWork();
    this._recordState(record);
  }

  async advanceWork({
    uid,
    requestDigest,
    invocationId,
    expectedWork,
    nextPageToken,
    nowMillis,
  }) {
    this.advanceCalls += 1;
    const record = this.records.get(uid);
    this._assertLease(record, { requestDigest, invocationId });
    assert.equal(record.state.currentWorkId, expectedWork.id);
    const key = this._workKey(uid, expectedWork.id);
    assert.deepEqual(this.work.get(key), expectedWork);
    this.work.set(key, { ...expectedWork, pageToken: nextPageToken });
    record.updatedAtMillis = nowMillis;
    this._recordState(record);
  }

  async spawnChild({
    uid,
    requestDigest,
    invocationId,
    expectedState,
    expectedParent,
    child,
    parentNextPageToken,
    nowMillis,
  }) {
    this.spawnCalls += 1;
    const record = this.records.get(uid);
    this._assertLease(record, { requestDigest, invocationId, expectedState });
    assert.equal(record.state.currentWorkId, expectedParent.id);
    const parentKey = this._workKey(uid, expectedParent.id);
    assert.deepEqual(this.work.get(parentKey), expectedParent);
    const childKey = this._workKey(uid, child.id);
    assert.equal(this.work.has(childKey), false);
    // The test fake applies the exact production ordering invariant: create
    // the durable child receipt before it advances the parent cursor.
    this.work.set(childKey, structuredClone(child));
    this.work.set(parentKey, {
      ...expectedParent,
      pageToken: parentNextPageToken,
    });
    record.state.currentWorkId = child.id;
    record.updatedAtMillis = nowMillis;
    this._trackWork();
    this._recordState(record);
  }

  async completeWork({
    uid,
    requestDigest,
    invocationId,
    expectedState,
    expectedWork,
    nowMillis,
  }) {
    const record = this.records.get(uid);
    this._assertLease(record, { requestDigest, invocationId, expectedState });
    assert.equal(record.state.currentWorkId, expectedWork.id);
    const key = this._workKey(uid, expectedWork.id);
    assert.deepEqual(this.work.get(key), expectedWork);
    this.work.delete(key);
    if (expectedWork.parentWorkId === null) {
      record.state.currentWorkId = null;
      record.state.rootIndex += 1;
    } else {
      assert.ok(this.work.has(this._workKey(uid, expectedWork.parentWorkId)));
      record.state.currentWorkId = expectedWork.parentWorkId;
    }
    record.updatedAtMillis = nowMillis;
    this._recordState(record);
  }

  async completeOperation({
    uid,
    requestDigest,
    invocationId,
    nowMillis,
  }) {
    const record = this.records.get(uid);
    this._assertLease(record, { requestDigest, invocationId });
    assert.equal(record.state.rootIndex, 7);
    assert.equal(record.state.currentWorkId, null);
    assert.equal(this.work.size, 0);
    record.state.status = "completed";
    record.state.leaseOwner = null;
    record.state.leaseUntilMillis = 0;
    record.updatedAtMillis = nowMillis;
    this._recordState(record);
  }

  async deleteDocumentAndCompleteWork({
    uid,
    requestDigest,
    invocationId,
    expectedState,
    expectedWork,
    nowMillis,
  }) {
    await this.store.deleteDocument({
      documentPath: expectedWork.path,
      uid,
      requestDigest,
      invocationId,
      expectedState,
      expectedWork,
    });
    await this.completeWork({
      uid,
      requestDigest,
      invocationId,
      expectedState,
      expectedWork,
      nowMillis,
    });
  }

  async removeBackupFieldsAndComplete({
    uid,
    requestDigest,
    invocationId,
    expectedState,
    fields,
    nowMillis,
  }) {
    await this.store.removeBackupFields({
      uid,
      fields,
      requestDigest,
      invocationId,
      expectedState,
    });
    await this.completeOperation({
      uid,
      requestDigest,
      invocationId,
      nowMillis,
    });
  }

  async release({ uid, requestDigest, invocationId, nowMillis }) {
    const record = this.records.get(uid);
    if (record.state.status === "completed") return;
    this._assertLease(record, { requestDigest, invocationId });
    record.state.leaseOwner = null;
    record.state.leaseUntilMillis = 0;
    record.updatedAtMillis = nowMillis;
    this._recordState(record);
  }
}

class MemoryBackupStore {
  constructor({ documents, user }) {
    this.documents = new Set(documents);
    this.user = structuredClone(user);
    this.deleted = [];
    this.documentPages = [];
    this.collectionPages = [];
    this.listCollectionsCalls = 0;
  }

  _page(items, pageToken) {
    const cursor = pageToken == null ? null : pageToken.slice(2);
    const index = cursor == null
      ? 0
      : items.findIndex((item) => item > cursor);
    assert.ok(index >= 0 || items.length === 0);
    return {
      item: items[index] ?? null,
      nextPageToken: index >= 0 && index + 1 < items.length
        ? `p:${items[index]}`
        : null,
    };
  }

  async listDocumentsPage({ collectionPath, pageSize, pageToken }) {
    assert.equal(pageSize, 1);
    this.documentPages.push({ collectionPath, pageToken });
    const prefix = `${collectionPath}/`;
    const collectionSegments = collectionPath.split("/").length;
    const documentIds = Array.from(new Set(Array.from(this.documents)
      .filter((path) => {
        const segments = path.split("/");
        return path.startsWith(prefix) &&
          segments.length >= collectionSegments + 1;
      })
      .map((path) => path.split("/")[collectionSegments])))
      .sort();
    const page = this._page(documentIds, pageToken);
    return {
      documentIds: page.item === null ? [] : [page.item],
      nextPageToken: page.nextPageToken,
    };
  }

  async listCollectionIdsPage({ parentPath, pageSize, pageToken }) {
    assert.equal(pageSize, 1);
    this.collectionPages.push({ parentPath, pageToken });
    const prefix = `${parentPath}/`;
    const documentSegments = parentPath.split("/").length;
    const collectionIds = Array.from(new Set(Array.from(this.documents)
      .filter((path) => path.startsWith(prefix))
      .map((path) => path.split("/"))
      .filter((segments) => segments.length >= documentSegments + 2)
      .map((segments) => segments[documentSegments])))
      .sort();
    const page = this._page(collectionIds, pageToken);
    return {
      collectionIds: page.item === null ? [] : [page.item],
      nextPageToken: page.nextPageToken,
    };
  }

  listCollections() {
    this.listCollectionsCalls += 1;
    throw new Error("unbounded listCollections must never be used");
  }

  async deleteDocument({ documentPath }) {
    this.documents.delete(documentPath);
    this.deleted.push(documentPath);
  }

  async removeBackupFields({ uid, fields }) {
    assert.equal(uid, "durable");
    for (const field of fields) {
      delete this.user[field];
    }
  }
}

class TokenCheckpointBackupStore extends MemoryBackupStore {
  constructor(input) {
    super(input);
    this.emittedEmptyPage = false;
  }

  async listDocumentsPage({ collectionPath, pageSize, pageToken }) {
    if (!this.emittedEmptyPage &&
        collectionPath === "users/durable/custom_words" &&
        pageToken === null) {
      this.emittedEmptyPage = true;
      this.documentPages.push({ collectionPath, pageToken });
      assert.equal(pageSize, 1);
      return { documentIds: [], nextPageToken: "p:0" };
    }
    return super.listDocumentsPage({ collectionPath, pageSize, pageToken });
  }
}

class CursorPagingBackupStore extends MemoryBackupStore {
  async listDocumentsPage({ collectionPath, pageSize, pageToken }) {
    if (collectionPath !== "users/durable/custom_words") {
      return super.listDocumentsPage({ collectionPath, pageSize, pageToken });
    }
    assert.equal(pageSize, 1);
    this.documentPages.push({ collectionPath, pageToken });
    const firstPath = "users/durable/custom_words/first";
    const secondPath = "users/durable/custom_words/second";
    if (!this.documents.has(firstPath) && !this.documents.has(secondPath)) {
      return { documentIds: [], nextPageToken: null };
    }
    if (pageToken === null) {
      assert.equal(this.documents.has(firstPath), true,
        "a discovered page must resume through its returned opaque cursor");
      return {
        documentIds: ["first"],
        nextPageToken: "after-first",
      };
    }
    if (pageToken === "after-first") {
      return {
        documentIds: ["second"],
        nextPageToken: null,
      };
    }
    throw new Error("unexpected opaque document cursor");
  }
}

class NonAdvancingDocumentTokenBackupStore extends MemoryBackupStore {
  async listDocumentsPage({ collectionPath, pageSize, pageToken }) {
    if (collectionPath !== "users/durable/packs") {
      return super.listDocumentsPage({ collectionPath, pageSize, pageToken });
    }
    assert.equal(pageSize, 1);
    this.documentPages.push({ collectionPath, pageToken });
    if (pageToken === null) {
      return {
        documentIds: ["first"],
        nextPageToken: "after-first",
      };
    }
    if (pageToken === "after-first") {
      return {
        documentIds: ["second"],
        nextPageToken: "after-first",
      };
    }
    throw new Error("unexpected opaque document cursor");
  }
}

class NonAdvancingCollectionTokenBackupStore extends MemoryBackupStore {
  async listCollectionIdsPage({ parentPath, pageSize, pageToken }) {
    if (parentPath !== "users/durable/packs/parent") {
      return super.listCollectionIdsPage({ parentPath, pageSize, pageToken });
    }
    assert.equal(pageSize, 1);
    this.collectionPages.push({ parentPath, pageToken });
    if (pageToken === null) {
      return {
        collectionIds: [],
        nextPageToken: "after-empty-page",
      };
    }
    if (pageToken === "after-empty-page") {
      return {
        collectionIds: [],
        nextPageToken: "after-empty-page",
      };
    }
    throw new Error("unexpected opaque collection cursor");
  }
}

class FencedMemoryBackupStore extends MemoryBackupStore {
  constructor(input) {
    super(input);
    this.documentFences = [];
    this.fieldFences = [];
  }

  async deleteDocument(input) {
    assert.equal(typeof input, "object");
    assert.equal(input.uid, "durable");
    assert.equal(input.expectedWork.kind, "document");
    assert.equal(
      input.expectedState.currentWorkId,
      input.expectedWork.id,
    );
    this.documentFences.push(structuredClone(input));
    return super.deleteDocument(input);
  }

  async removeBackupFields(input) {
    assert.equal(typeof input, "object");
    assert.equal(input.uid, "durable");
    assert.equal(input.expectedState.rootIndex, BACKUP_ROOTS.length);
    assert.equal(input.expectedState.currentWorkId, null);
    this.fieldFences.push(structuredClone(input));
    return super.removeBackupFields(input);
  }
}

function createHarness({
  pageSize = 200,
  documents = [],
  user = {},
  Store = MemoryBackupStore,
} = {}) {
  const store = new Store({ documents, user });
  const repository = new MemoryOperationRepository(store);
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

test("callable rejects an anonymous Firebase token without hashing the request", async () => {
  const { handlers, seenHashInputs } = createHarness();

  await rejectsWithSafeCode(
    handlers.deleteCloudBackup(
      callableRequest("durable", { requestKey: "F".repeat(43) }, {
        signInProvider: "anonymous",
      }),
    ),
    "unauthenticated",
    "durable-authentication-required",
  );

  assert.deepEqual(seenHashInputs, []);
});

test("a valid 100-collection-depth chain resumes to completion", async () => {
  const { handlers, repository, store } = createHarness({
    pageSize: 1,
    documents: [maxDepthDocumentPath()],
    user: { progress: 1 },
  });
  const request = callableRequest("durable", {
    requestKey: "G".repeat(43),
  });

  let result = { state: "pending" };
  for (let attempt = 0;
    attempt < 1000 && result.state === "pending";
    attempt += 1) {
    result = await handlers.deleteCloudBackup(request);
  }

  assert.deepEqual(result, { state: "completed" });
  assert.deepEqual(Array.from(store.documents), []);
  assert.equal(repository.records.get("durable").state.status, "completed");
});

test("high fanout uses bounded durable work and never calls listCollections", async () => {
  const documents = Array.from({ length: 240 }, (_, index) =>
    `users/durable/custom_words/word_${String(index).padStart(3, "0")}`,
  );
  const { handlers, repository, store } = createHarness({
    pageSize: 1,
    documents,
    user: { progress: 1 },
  });
  const request = callableRequest("durable", {
    requestKey: "H".repeat(43),
  });

  let result = { state: "pending" };
  for (let attempt = 0;
    attempt < 2_000 && result.state === "pending";
    attempt += 1) {
    result = await handlers.deleteCloudBackup(request);
  }

  assert.deepEqual(result, { state: "completed" });
  assert.deepEqual(Array.from(store.documents), []);
  assert.equal(store.listCollectionsCalls, 0);
  assert.ok(repository.maxWorkCount <= 2);
  assert.ok(repository.maxOperationBytes < 1_024);
});

test("discovery resumes from a checkpointed opaque page token", async () => {
  const { handlers, repository, store } = createHarness({
    pageSize: 1,
    documents: ["users/durable/custom_words/word"],
    Store: TokenCheckpointBackupStore,
  });
  const request = callableRequest("durable", {
    requestKey: "I".repeat(43),
  });

  let result = { state: "pending" };
  for (let attempt = 0;
    attempt < 100 && result.state === "pending";
    attempt += 1) {
    result = await handlers.deleteCloudBackup(request);
  }

  assert.deepEqual(result, { state: "completed" });
  expectPageTokenWasUsed(
    store.documentPages,
    "users/durable/custom_words",
    "p:0",
  );
  assert.deepEqual(Array.from(store.documents), []);
  assert.equal(repository.records.get("durable").state.status, "completed");
});

test("discovery persists the returned cursor before deleting a child", async () => {
  const { handlers, store } = createHarness({
    pageSize: 1,
    documents: [
      "users/durable/custom_words/first",
      "users/durable/custom_words/second",
    ],
    Store: CursorPagingBackupStore,
  });
  const request = callableRequest("durable", {
    requestKey: "J".repeat(43),
  });

  let result = { state: "pending" };
  for (let attempt = 0;
    attempt < 100 && result.state === "pending";
    attempt += 1) {
    result = await handlers.deleteCloudBackup(request);
  }

  assert.deepEqual(result, { state: "completed" });
  assert.equal(
    store.documentPages.some((page) =>
      page.collectionPath === "users/durable/custom_words" &&
      page.pageToken === "after-first"),
    true,
  );
});

test("document discovery rejects a non-advancing opaque token before spawning", async () => {
  const { handlers, repository, store } = createHarness({
    pageSize: 1,
    documents: [
      "users/durable/packs/first",
      "users/durable/packs/second",
    ],
    Store: NonAdvancingDocumentTokenBackupStore,
  });
  const request = callableRequest("durable", {
    requestKey: "Q".repeat(43),
  });

  assert.deepEqual(await handlers.deleteCloudBackup(request), {
    state: "pending",
  });
  assert.deepEqual(await handlers.deleteCloudBackup(request), {
    state: "pending",
  });
  assert.deepEqual(await handlers.deleteCloudBackup(request), {
    state: "pending",
  });

  await rejectsWithSafeCode(
    handlers.deleteCloudBackup(request),
    "unavailable",
    "cloud-backup-deletion-unavailable",
  );

  const record = repository.records.get("durable");
  const rootWork = repository.work.get(`durable/${record.state.currentWorkId}`);
  assert.equal(rootWork.pageToken, "after-first");
  assert.equal(repository.spawnCalls, 1);
  assert.equal(repository.work.size, 1);
  assert.equal(store.documents.has("users/durable/packs/second"), true);
});

test("collection discovery rejects a non-advancing opaque token before advancing", async () => {
  const { handlers, repository } = createHarness({
    pageSize: 1,
    documents: ["users/durable/packs/parent"],
    Store: NonAdvancingCollectionTokenBackupStore,
  });
  const request = callableRequest("durable", {
    requestKey: "R".repeat(43),
  });

  assert.deepEqual(await handlers.deleteCloudBackup(request), {
    state: "pending",
  });
  assert.deepEqual(await handlers.deleteCloudBackup(request), {
    state: "pending",
  });
  assert.deepEqual(await handlers.deleteCloudBackup(request), {
    state: "pending",
  });

  await rejectsWithSafeCode(
    handlers.deleteCloudBackup(request),
    "unavailable",
    "cloud-backup-deletion-unavailable",
  );

  const record = repository.records.get("durable");
  const documentWork = repository.work.get(
    `durable/${record.state.currentWorkId}`,
  );
  assert.equal(documentWork.pageToken, "after-empty-page");
  assert.equal(repository.advanceCalls, 1);
  assert.equal(repository.work.size, 2);
});

test("destructive work carries the current operation and work fence", async () => {
  const { handlers, store } = createHarness({
    documents: ["users/durable/packs/one"],
    user: { progress: 1 },
    Store: FencedMemoryBackupStore,
  });

  const result = await handlers.deleteCloudBackup(callableRequest("durable", {
    requestKey: "K".repeat(43),
  }));

  assert.deepEqual(result, { state: "completed" });
  assert.equal(store.documentFences.length, 1);
  assert.equal(store.fieldFences.length, 1);
  assert.deepEqual(Array.from(store.documents), []);
  assert.equal(Object.hasOwn(store.user, "progress"), false);
});

test("Firestore repository atomically drains work and clears legacy fields", async () => {
  const { firestore, handlers } = createTransactionalFirestoreHarness({
    documents: ["users/durable/packs/one"],
    user: {
      progress: 1,
      fcmTokens: ["operational-token"],
    },
    pageSize: 1,
  });

  const request = callableRequest("durable", {
    requestKey: "L".repeat(43),
  });
  let result = { state: "pending" };
  for (let attempt = 0;
    attempt < 100 && result.state === "pending";
    attempt += 1) {
    result = await handlers.deleteCloudBackup(request);
  }

  assert.deepEqual(result, { state: "completed" });
  assert.equal(firestore.value("users/durable/packs/one"), undefined);
  assert.equal(firestore.value("users/durable").progress, undefined);
  assert.deepEqual(firestore.value("users/durable").fcmTokens, [
    "operational-token",
  ]);
  assert.equal(
    firestore.value("cloud_backup_deletions/durable").state.status,
    "completed",
  );
  assert.deepEqual(
    Array.from(firestore.documents.keys()).filter((path) =>
      path.startsWith("cloud_backup_deletions/durable/work/")),
    [],
  );
});

test("an expired worker cannot erase data written after successor completion", async () => {
  let resolveFirstLeafPage;
  const firstLeafPage = new Promise((resolve) => {
    resolveFirstLeafPage = resolve;
  });
  let enteredFirstLeafPage;
  const firstLeafEntered = new Promise((resolve) => {
    enteredFirstLeafPage = resolve;
  });
  let holdFirstLeafPage = true;
  const { clock, firestore, handlers } = createTransactionalFirestoreHarness({
    documents: ["users/durable/packs/one"],
    user: { progress: 1 },
    onListCollectionIds: ({ parentPath }) => {
      if (holdFirstLeafPage && parentPath === "users/durable/packs/one") {
        holdFirstLeafPage = false;
        enteredFirstLeafPage();
        return firstLeafPage;
      }
      return undefined;
    },
  });
  const request = callableRequest("durable", {
    requestKey: "M".repeat(43),
  });

  const expiredWorker = handlers.deleteCloudBackup(request);
  await firstLeafEntered;

  clock.now = 62_000;
  assert.deepEqual(
    await handlers.deleteCloudBackup(request),
    { state: "completed" },
  );
  firestore.seed("users/durable/packs/fresh", {});
  firestore.seed("users/durable", { progress: 999 });

  resolveFirstLeafPage({ collectionIds: [], nextPageToken: null });
  await rejectsWithSafeCode(
    expiredWorker,
    "unavailable",
    "cloud-backup-deletion-unavailable",
  );

  assert.deepEqual(firestore.value("users/durable/packs/fresh"), {});
  assert.equal(firestore.value("users/durable").progress, 999);
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
