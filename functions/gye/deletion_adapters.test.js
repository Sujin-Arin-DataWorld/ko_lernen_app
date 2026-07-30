"use strict";

const assert = require("node:assert/strict");
const test = require("node:test");

const {
  createFirestoreDeletionAdapters,
} = require("./deletion_adapters");

function clone(value) {
  return value === undefined ? undefined : structuredClone(value);
}

function directChildDocumentPaths(documents, collectionPath) {
  const prefix = `${collectionPath}/`;
  return Array.from(documents.keys())
    .filter((path) => {
      if (!path.startsWith(prefix)) return false;
      return !path.slice(prefix.length).includes("/");
    })
    .sort();
}

class FakeDocumentSnapshot {
  constructor(reference, value) {
    this.ref = reference;
    this.id = reference.id;
    this.exists = value !== undefined;
    this._value = clone(value);
  }

  data() {
    return clone(this._value);
  }
}

class FakeQuery {
  constructor(collection, {
    filters = [],
    afterId = null,
    limitValue = null,
  } = {}) {
    this.collection = collection;
    this.filters = filters;
    this.afterId = afterId;
    this.limitValue = limitValue;
  }

  _next(change) {
    return new FakeQuery(this.collection, {
      filters: this.filters,
      afterId: this.afterId,
      limitValue: this.limitValue,
      ...change,
    });
  }

  where(field, operator, value) {
    assert.equal(operator, "==");
    return this._next({
      filters: [...this.filters, { field, value }],
    });
  }

  orderBy(field) {
    assert.equal(field, "__name__");
    return this;
  }

  startAfter(id) {
    return this._next({ afterId: id });
  }

  limit(value) {
    return this._next({ limitValue: value });
  }

  async get() {
    let paths = directChildDocumentPaths(
      this.collection.firestore.documents,
      this.collection.path,
    );
    if (this.afterId !== null) {
      paths = paths.filter((path) => path.split("/").at(-1) > this.afterId);
    }
    paths = paths.filter((path) => {
      const value = this.collection.firestore.documents.get(path) || {};
      return this.filters.every(({ field, value: expected }) =>
        value[field] === expected);
    });
    if (this.limitValue !== null) {
      paths = paths.slice(0, this.limitValue);
    }
    return {
      empty: paths.length === 0,
      size: paths.length,
      docs: paths.map((path) => {
        const ref = new FakeDocumentReference(
          this.collection.firestore,
          path,
        );
        return new FakeDocumentSnapshot(
          ref,
          this.collection.firestore.documents.get(path),
        );
      }),
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
    return new FakeQuery(this).where(field, operator, value);
  }

  orderBy(field) {
    return new FakeQuery(this).orderBy(field);
  }

  limit(value) {
    return new FakeQuery(this).limit(value);
  }
}

class FakeDocumentReference {
  constructor(firestore, path) {
    this.firestore = firestore;
    this.path = path;
    this.id = path.split("/").at(-1);
  }

  collection(name) {
    return new FakeCollectionReference(this.firestore, `${this.path}/${name}`);
  }

  async get() {
    return new FakeDocumentSnapshot(
      this,
      this.firestore.documents.get(this.path),
    );
  }

  async set(value, options) {
    const current = this.firestore.documents.get(this.path);
    const next = options?.merge === true
      ? { ...(clone(current) || {}), ...clone(value) }
      : clone(value);
    this.firestore.documents.set(this.path, next);
  }

  async delete() {
    this.firestore.deletedPaths.push(this.path);
    this.firestore.documents.delete(this.path);
  }

  async listCollections() {
    this.firestore.unboundedListCollectionsCalls += 1;
    if (this.firestore.discoveryStarted) {
      this.firestore.discoveryStarted();
      this.firestore.discoveryStarted = null;
    }
    if (this.firestore.discoveryGate) {
      await this.firestore.discoveryGate;
    }
    if (this.path === "users/source") {
      this.firestore.rootListCount += 1;
      if (this.firestore.rootListCount ===
          this.firestore.injectLateRootOnListNumber) {
        this.firestore.seed("users/source/late/l1", { late: true });
      }
    }
    const prefix = `${this.path}/`;
    const collectionPaths = new Set();
    for (const path of this.firestore.documents.keys()) {
      if (!path.startsWith(prefix)) continue;
      const remainder = path.slice(prefix.length);
      const firstSegment = remainder.split("/")[0];
      if (firstSegment) {
        collectionPaths.add(`${this.path}/${firstSegment}`);
      }
    }
    return Array.from(collectionPaths)
      .sort()
      .map((path) => new FakeCollectionReference(this.firestore, path));
  }
}

class FakeWriteBatch {
  constructor(firestore) {
    this.firestore = firestore;
    this.writes = [];
  }

  set(reference, value, options) {
    this.writes.push({ kind: "set", reference, value, options });
    return this;
  }

  delete(reference) {
    this.writes.push({ kind: "delete", reference });
    return this;
  }

  async commit() {
    assert(this.writes.length <= 450, "batch must stay bounded");
    for (const write of this.writes) {
      if (write.kind === "delete") {
        await write.reference.delete();
      } else {
        await write.reference.set(write.value, write.options);
      }
    }
  }
}

class FakeFirestore {
  constructor() {
    this.documents = new Map();
    this.deletedPaths = [];
    this.unboundedListCollectionsCalls = 0;
    this.rootListCount = 0;
    this.injectLateRootOnListNumber = Number.POSITIVE_INFINITY;
    this.transactionTail = Promise.resolve();
    this.discoveryStarted = null;
    this.discoveryGate = null;
  }

  collection(path) {
    return new FakeCollectionReference(this, path);
  }

  batch() {
    return new FakeWriteBatch(this);
  }

  runTransaction(callback) {
    const execute = async () => {
      const writes = [];
      const transaction = {
        get: async (reference) => reference.get(),
        set: (reference, value, options) => {
          writes.push({ kind: "set", reference, value, options });
        },
        delete: (reference) => {
          writes.push({ kind: "delete", reference });
        },
      };
      const result = await callback(transaction);
      for (const write of writes) {
        if (write.kind === "delete") {
          await write.reference.delete();
        } else {
          await write.reference.set(write.value, write.options);
        }
      }
      return result;
    };
    const result = this.transactionTail.then(execute);
    this.transactionTail = result.catch(() => {});
    return result;
  }

  seed(path, value) {
    this.documents.set(path, clone(value));
  }

  documentExists(path) {
    return this.documents.has(path);
  }

  value(path) {
    return clone(this.documents.get(path));
  }

  reclaimLease({
    operationId = "op",
    workerId,
    leaseVersion,
    leaseUntilMillis,
  }) {
    const path = `account_operations/${operationId}`;
    const operation = this.documents.get(path);
    this.documents.set(path, {
      ...clone(operation),
      workerLease: {
        workerId,
        leaseVersion,
        leaseUntilMillis,
      },
    });
  }

  workDocuments(uid = "source") {
    const prefix = `account_deletions/${uid}/user_tree_work/`;
    return Array.from(this.documents.entries())
      .filter(([path]) => path.startsWith(prefix))
      .map(([, value]) => clone(value));
  }

  pendingWork(uid = "source") {
    return this.workDocuments(uid)
      .filter((value) => value.state === "pending")
      .map((value) => value.collectionPath)
      .sort();
  }
}

function createHarness({
  pageSize = 2,
  root = { gyeIds: ["XYZ789", "", 42, "ABC234", "ABC234"] },
  pager,
} = {}) {
  const firestore = new FakeFirestore();
  const clock = { now: 2_000_000_000_000 };
  const workerFence = {
    workerId: "worker-one",
    operationVersion: 3,
    leaseVersion: 2,
  };
  firestore.seed("account_deletions/source", {
    serverOwned: true,
    operationId: "op",
    sourceUid: "source",
    cleanupGyeIds: ["LEGACY1"],
  });
  firestore.seed("account_operations/op", {
    id: "op",
    version: workerFence.operationVersion,
    workerLease: {
      workerId: workerFence.workerId,
      leaseVersion: workerFence.leaseVersion,
      leaseUntilMillis: clock.now + 60_000,
    },
  });
  if (root !== null) firestore.seed("users/source", root);
  const pagerCalls = [];
  let failPage = null;
  const listCollectionIdsPage = pager || (async ({
    parentPath,
    pageSize: requestedPageSize,
    pageToken,
  }) => {
    if (parentPath === "users/source") {
      firestore.rootListCount += 1;
      if (firestore.rootListCount ===
          firestore.injectLateRootOnListNumber) {
        firestore.seed("users/source/late/l1", { late: true });
      }
    }
    if (firestore.discoveryStarted) {
      firestore.discoveryStarted();
      firestore.discoveryStarted = null;
    }
    if (firestore.discoveryGate) {
      await firestore.discoveryGate;
    }
    pagerCalls.push({
      parentPath,
      pageSize: requestedPageSize,
      pageToken: pageToken || null,
    });
    if (failPage &&
        failPage.parentPath === parentPath &&
        failPage.pageToken === (pageToken || null) &&
        failPage.remaining > 0) {
      failPage.remaining -= 1;
      throw new Error("provider detail must stay private");
    }
    const prefix = `${parentPath}/`;
    const ids = new Set();
    for (const path of firestore.documents.keys()) {
      if (!path.startsWith(prefix)) continue;
      const collectionId = path.slice(prefix.length).split("/")[0];
      if (collectionId) ids.add(collectionId);
    }
    const sorted = Array.from(ids).sort();
    const start = pageToken ? Number(pageToken.slice(2)) : 0;
    const collectionIds = sorted.slice(start, start + requestedPageSize);
    const nextIndex = start + collectionIds.length;
    return {
      collectionIds,
      nextPageToken: nextIndex < sorted.length ? `p:${nextIndex}` : null,
    };
  });
  const rawAdapters = createFirestoreDeletionAdapters({
    firestore,
    markerCollection: firestore.collection("account_deletions"),
    pageSize,
    listCollectionIdsPage,
    nowMillis: () => clock.now,
  });
  const adapters = {
    captureCommunityTargets(args) {
      return rawAdapters.captureCommunityTargets({
        ...args,
        workerFence,
      });
    },
    deleteUserTreePage(args) {
      return rawAdapters.deleteUserTreePage({
        ...args,
        workerFence,
      });
    },
  };
  return {
    adapters,
    rawAdapters,
    firestore,
    clock,
    workerFence,
    pagerCalls,
    failNextPage(parentPath, pageToken = null) {
      failPage = { parentPath, pageToken, remaining: 1 };
    },
  };
}

async function drainPages(adapters, {
  uid = "source",
  operationId = "op",
  limit = 2,
  maxPages = 50,
} = {}) {
  let cursor = null;
  for (let pageNumber = 0; pageNumber < maxPages; pageNumber += 1) {
    const result = await adapters.deleteUserTreePage({
      uid,
      operationId,
      cursor,
      limit,
    });
    if (result.done) return result;
    cursor = result.nextCursor;
  }
  throw new Error("adapter did not drain within the page bound");
}

async function drainRawPages(rawAdapters, {
  workerFence,
  uid = "source",
  operationId = "op",
  limit = 2,
  maxPages = 100,
} = {}) {
  let cursor = null;
  for (let pageNumber = 0; pageNumber < maxPages; pageNumber += 1) {
    const result = await rawAdapters.deleteUserTreePage({
      uid,
      operationId,
      cursor,
      limit,
      workerFence,
    });
    if (result.done) return result;
    cursor = result.nextCursor;
  }
  throw new Error("raw adapter did not drain within the page bound");
}

test("persists nested child work before deleting its parent document", async () => {
  const { adapters, firestore } = createHarness({ pageSize: 1 });
  firestore.seed("users/source/packs/p1", { state: "active" });
  firestore.seed("users/source/packs/p1/items/i1", { word: "one" });

  const first = await adapters.deleteUserTreePage({
    uid: "source",
    operationId: "op",
    cursor: null,
    limit: 1,
  });
  const page = await adapters.deleteUserTreePage({
    uid: "source",
    operationId: "op",
    cursor: first.nextCursor,
    limit: 1,
  });

  assert.deepEqual(page, { done: false, nextCursor: "work-v1" });
  assert.deepEqual(firestore.pendingWork(), [
    "users/source/packs",
    "users/source/packs/p1/items",
  ]);
  assert.equal(firestore.documentExists("users/source/packs/p1"), false);
  assert.equal(firestore.documentExists("users/source/packs/p1/items/i1"), true);
});

test("drains an arbitrarily nested tree and deletes the user root last", async () => {
  const { adapters, firestore } = createHarness();
  firestore.seed("users/source/packs/p1", { state: "active" });
  firestore.seed("users/source/packs/p1/items/i1", { word: "one" });
  firestore.seed("users/source/packs/p1/items/i1/audio/a1", { url: "safe" });
  firestore.seed("users/source/quests/q1", { progress: 1 });

  await drainPages(adapters);

  assert.equal(
    Array.from(firestore.documents.keys())
      .some((path) => path === "users/source" ||
        path.startsWith("users/source/")),
    false,
  );
  const rootDelete = firestore.deletedPaths.indexOf("users/source");
  for (const path of [
    "users/source/packs/p1",
    "users/source/packs/p1/items/i1",
    "users/source/packs/p1/items/i1/audio/a1",
    "users/source/quests/q1",
  ]) {
    assert(firestore.deletedPaths.indexOf(path) < rootDelete);
  }
});

test("resumes from persistent work without duplicating a nested job", async () => {
  const { adapters, firestore } = createHarness({ pageSize: 1 });
  firestore.seed("users/source/packs/p1", { state: "active" });
  firestore.seed("users/source/packs/p1/items/i1", { word: "one" });
  firestore.seed("users/source/packs/p2", { state: "active" });

  const first = await adapters.deleteUserTreePage({
    uid: "source",
    operationId: "op",
    cursor: null,
    limit: 1,
  });
  const workCount = firestore.workDocuments().length;
  const second = await adapters.deleteUserTreePage({
    uid: "source",
    operationId: "op",
    cursor: first.nextCursor,
    limit: 1,
  });
  const third = await adapters.deleteUserTreePage({
    uid: "source",
    operationId: "op",
    cursor: second.nextCursor,
    limit: 1,
  });

  assert.deepEqual(third, { done: false, nextCursor: "work-v1" });
  assert.equal(
    firestore.workDocuments()
      .filter((work) =>
        work.collectionPath === "users/source/packs/p1/items")
      .length,
    1,
  );
  assert(firestore.workDocuments().length >= workCount);
  await drainPages(adapters, { limit: 1 });
  assert.equal(firestore.documentExists("users/source"), false);
});

test("bounds each document page even when a caller supplies a larger limit",
async () => {
  const { adapters, firestore } = createHarness({ pageSize: 2 });
  for (let index = 0; index < 6; index += 1) {
    firestore.seed(`users/source/packs/p${index}`, { index });
  }

  const before = firestore.deletedPaths.length;
  const result = await adapters.deleteUserTreePage({
    uid: "source",
    operationId: "op",
    cursor: null,
    limit: 10_000,
  });
  const second = await adapters.deleteUserTreePage({
    uid: "source",
    operationId: "op",
    cursor: result.nextCursor,
    limit: 10_000,
  });

  assert.deepEqual(second, { done: false, nextCursor: "work-v1" });
  assert.equal(firestore.deletedPaths.length - before, 1);
  assert.equal(firestore.documentExists("users/source"), true);
});

test("discovers high-fanout root collection IDs one persisted page at a time",
async () => {
  const { adapters, firestore, pagerCalls } = createHarness({ pageSize: 2 });
  for (let index = 0; index < 7; index += 1) {
    firestore.seed(`users/source/root_${index}/doc`, { index });
  }

  const first = await adapters.deleteUserTreePage({
    uid: "source",
    operationId: "op",
    cursor: null,
    limit: 10_000,
  });

  assert.deepEqual(first, { done: false, nextCursor: "work-v1" });
  assert.deepEqual(pagerCalls, [{
    parentPath: "users/source",
    pageSize: 2,
    pageToken: null,
  }]);
  assert.equal(firestore.unboundedListCollectionsCalls, 0);
  assert.equal(firestore.deletedPaths.length, 0);
  assert.equal(firestore.workDocuments().length, 2);
});

test("discovers high-fanout child collection IDs before deleting the parent",
async () => {
  const { adapters, firestore, pagerCalls } = createHarness({ pageSize: 2 });
  firestore.seed("users/source/packs/p1", { state: "active" });
  for (let index = 0; index < 5; index += 1) {
    firestore.seed(
      `users/source/packs/p1/child_${index}/doc`,
      { index },
    );
  }

  await adapters.deleteUserTreePage({
    uid: "source",
    operationId: "op",
    cursor: null,
    limit: 2,
  });
  await adapters.deleteUserTreePage({
    uid: "source",
    operationId: "op",
    cursor: "work-v1",
    limit: 2,
  });

  assert.deepEqual(pagerCalls, [
    {
      parentPath: "users/source",
      pageSize: 2,
      pageToken: null,
    },
    {
      parentPath: "users/source/packs/p1",
      pageSize: 2,
      pageToken: null,
    },
  ]);
  assert.equal(firestore.unboundedListCollectionsCalls, 0);
  assert.equal(firestore.documentExists("users/source/packs/p1"), true);
  assert.equal(
    firestore.pendingWork()
      .filter((path) => path.includes("/child_"))
      .length,
    2,
  );
});

test("retries the same bounded discovery page without losing child work",
async () => {
  const {
    adapters,
    firestore,
    pagerCalls,
    failNextPage,
  } = createHarness({ pageSize: 2 });
  firestore.seed("users/source/packs/p1", { state: "active" });
  for (let index = 0; index < 3; index += 1) {
    firestore.seed(
      `users/source/packs/p1/child_${index}/doc`,
      { index },
    );
  }

  await adapters.deleteUserTreePage({
    uid: "source",
    operationId: "op",
    cursor: null,
    limit: 2,
  });
  failNextPage("users/source/packs/p1");

  await assert.rejects(
    adapters.deleteUserTreePage({
      uid: "source",
      operationId: "op",
      cursor: "work-v1",
      limit: 2,
    }),
    { code: "deletion-discovery-failed" },
  );
  assert.equal(firestore.documentExists("users/source/packs/p1"), true);
  assert.equal(
    firestore.pendingWork()
      .filter((path) => path.includes("/child_"))
      .length,
    0,
  );

  await adapters.deleteUserTreePage({
    uid: "source",
    operationId: "op",
    cursor: "work-v1",
    limit: 2,
  });
  await adapters.deleteUserTreePage({
    uid: "source",
    operationId: "op",
    cursor: "work-v1",
    limit: 2,
  });

  assert.deepEqual(
    pagerCalls
      .filter((call) =>
        call.parentPath === "users/source/packs/p1")
      .map((call) => call.pageToken),
    [null, null, "p:2"],
  );
  assert.equal(
    firestore.pendingWork()
      .filter((path) => path.includes("/child_"))
      .length,
    3,
  );
  assert.equal(firestore.documentExists("users/source/packs/p1"), false);
});

test("a reclaimed lease prevents the expired worker from mutating its page",
async () => {
  const {
    rawAdapters,
    firestore,
    clock,
    workerFence,
  } = createHarness({ pageSize: 2 });
  firestore.seed("users/source/packs/p1", { state: "active" });
  let releaseDiscovery;
  firestore.discoveryGate = new Promise((resolve) => {
    releaseDiscovery = resolve;
  });
  let discoveryStarted;
  const started = new Promise((resolve) => {
    discoveryStarted = resolve;
  });
  firestore.discoveryStarted = discoveryStarted;

  const expiredAttempt = rawAdapters.deleteUserTreePage({
    uid: "source",
    operationId: "op",
    cursor: null,
    limit: 2,
    workerFence,
  });
  await started;
  clock.now += 70_000;
  const recoveredFence = {
    workerId: "worker-two",
    operationVersion: workerFence.operationVersion,
    leaseVersion: workerFence.leaseVersion + 1,
  };
  firestore.reclaimLease({
    workerId: recoveredFence.workerId,
    leaseVersion: recoveredFence.leaseVersion,
    leaseUntilMillis: clock.now + 60_000,
  });
  releaseDiscovery();

  await assert.rejects(expiredAttempt, { code: "stale-worker-lease" });
  assert.equal(firestore.documentExists("users/source/packs/p1"), true);
  assert.equal(firestore.workDocuments().length, 0);

  await drainRawPages(rawAdapters, {
    workerFence: recoveredFence,
    limit: 2,
  });
  assert.equal(firestore.documentExists("users/source"), false);
});

test("reopens work discovered by the late root scan before deleting the root",
async () => {
  const { adapters, firestore } = createHarness({ pageSize: 1 });
  firestore.seed("users/source/packs/p1", { state: "active" });
  firestore.injectLateRootOnListNumber = 2;

  let cursor = null;
  let page;
  for (let invocation = 0; invocation < 5; invocation += 1) {
    page = await adapters.deleteUserTreePage({
      uid: "source",
      operationId: "op",
      cursor,
      limit: 1,
    });
    cursor = page.nextCursor;
  }

  assert.deepEqual(page, { done: false, nextCursor: "work-v1" });
  assert.equal(firestore.documentExists("users/source"), true);
  assert.equal(firestore.documentExists("users/source/late/l1"), true);
  await drainPages(adapters, { limit: 1 });
  assert.equal(firestore.documentExists("users/source"), false);
});

test("captures only normalized Gye IDs in the server-owned marker", async () => {
  const { adapters, firestore } = createHarness();

  await adapters.captureCommunityTargets({
    uid: "source",
    operationId: "op",
  });

  const marker = firestore.value("account_deletions/source");
  assert.deepEqual(marker.cleanupGyeIds, [
    "ABC234",
    "LEGACY1",
    "XYZ789",
  ]);
  assert.equal(Object.hasOwn(marker, "gyeIds"), false);
});

test("rejects an arbitrary cursor before touching either user tree", async () => {
  const { adapters, firestore } = createHarness();
  firestore.seed("users/foreign/packs/private", { mustRemain: true });
  const before = clone(Array.from(firestore.documents.entries()));

  await assert.rejects(
    adapters.deleteUserTreePage({
      uid: "source",
      operationId: "op",
      cursor: "users/foreign/packs",
      limit: 1,
    }),
    { code: "invalid-deletion-cursor" },
  );

  assert.deepEqual(Array.from(firestore.documents.entries()), before);
});

test("rejects forged persisted work outside the operation user root", async () => {
  const { adapters, firestore } = createHarness();
  firestore.seed("users/foreign/packs/private", { mustRemain: true });
  firestore.seed("account_deletions/source/user_tree_work/forged", {
    operationId: "op",
    uid: "source",
    collectionPath: "users/foreign/packs",
    state: "pending",
    lastDocumentId: null,
  });

  const first = await adapters.deleteUserTreePage({
    uid: "source",
    operationId: "op",
    cursor: null,
    limit: 1,
  });
  await assert.rejects(
    adapters.deleteUserTreePage({
      uid: "source",
      operationId: "op",
      cursor: first.nextCursor,
      limit: 1,
    }),
    { code: "invalid-deletion-work" },
  );

  assert.equal(
    firestore.documentExists("users/foreign/packs/private"),
    true,
  );
  assert.equal(firestore.documentExists("users/source"), true);
});

test("is idempotent after the root and transient work receipts are gone",
async () => {
  const { adapters, firestore } = createHarness({ root: { gyeIds: [] } });

  const first = await drainPages(adapters);
  const second = await adapters.deleteUserTreePage({
    uid: "source",
    operationId: "op",
    cursor: null,
    limit: 2,
  });

  assert.deepEqual(first, { done: true, nextCursor: null });
  assert.deepEqual(second, { done: true, nextCursor: null });
  assert.equal(firestore.workDocuments().length, 0);
});
