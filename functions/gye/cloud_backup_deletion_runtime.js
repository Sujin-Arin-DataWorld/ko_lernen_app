"use strict";

const { createHash } = require("node:crypto");

const BACKUP_ROOTS = Object.freeze([
  "packs",
  "quests",
  "bookshelf",
  "custom_packs",
  "custom_words",
  "sync_generations",
  "sync_metadata",
]);
const BACKUP_FIELDS = Object.freeze([
  "vok",
  "chosung",
  "wordle",
  "grammar",
  "app",
  "progress",
  "srs_json",
  "custom_packs_json",
  "bookshelf_json",
  "course_mastery_json",
  "updated_at",
]);
// App Check is advisory here (2026-08-10): enforced attestation stranded
// durable deletion journals forever on devices whose provider was never
// registered (Play Integrity gap), locking the whole account UI. The
// verified, revocation-checked durable auth token below remains mandatory —
// and Firestore rules already allow owner deletes without App Check, so
// enforcement added no real protection to this operation.
const CALLABLE_OPTIONS = Object.freeze({
  region: "europe-west3",
  enforceAppCheck: false,
});
const REQUEST_KEY_PATTERN = /^[A-Za-z0-9_-]{43,128}$/;
const DIGEST_PATTERN = /^[a-f0-9]{64}$/;
const WORK_ID_PATTERN = /^[a-f0-9]{64}$/;
const LEASE_MILLIS = 60_000;
const DEFAULT_WORK_UNITS = 40;
const MAX_WORK_UNITS = 200;
const MAX_PATH_BYTES = 6_000;
const MAX_PATH_SEGMENTS = 200;
const MAX_PAGE_TOKEN_BYTES = 16 * 1024;

class BoundaryFailure extends Error {
  constructor(status, safeCode) {
    super("Cloud backup deletion request rejected.");
    this.status = status;
    this.safeCode = safeCode;
  }
}

function validOpaqueSegment(value) {
  return typeof value === "string" &&
    value.length > 0 &&
    value !== "." &&
    value !== ".." &&
    !value.includes("/") &&
    Buffer.byteLength(value, "utf8") <= 1_500;
}

function validUid(value) {
  return validOpaqueSegment(value) &&
    Buffer.byteLength(value, "utf8") <= 128 &&
    !/[\u0000-\u001f\u007f]/.test(value);
}

function authorizationHeader(request) {
  const headers = request?.rawRequest?.headers;
  const header = headers?.authorization ??
    request?.rawRequest?.get?.("authorization");
  if (typeof header !== "string") return null;
  const match = /^Bearer ([^\s]+)$/i.exec(header);
  return match ? match[1] : null;
}

function signInProvider(token) {
  const provider = token?.firebase?.sign_in_provider;
  return typeof provider === "string" && provider.length > 0
    ? provider
    : null;
}

async function assertRequest(request, auth) {
  if (!request?.app || typeof request.app.appId !== "string") {
    // Advisory only — see CALLABLE_OPTIONS. Log for abuse monitoring.
    console.warn("[deleteCloudBackup] request without App Check context");
  }
  const uid = request?.auth?.uid;
  if (!validUid(uid)) {
    throw new BoundaryFailure(
      "unauthenticated",
      "authentication-required",
    );
  }
  const contextProvider = signInProvider(request?.auth?.token);
  const bearerToken = authorizationHeader(request);
  if (contextProvider === null || bearerToken === null) {
    throw new BoundaryFailure(
      "unauthenticated",
      "authentication-required",
    );
  }
  let decoded;
  try {
    decoded = await auth.verifyIdToken(bearerToken, true);
  } catch {
    throw new BoundaryFailure("unauthenticated", "invalid-auth-token");
  }
  const verifiedUid = decoded?.uid;
  const verifiedProvider = signInProvider(decoded);
  if (!validUid(verifiedUid) ||
      verifiedProvider === null ||
      verifiedUid !== uid ||
      verifiedProvider !== contextProvider) {
    throw new BoundaryFailure("unauthenticated", "invalid-auth-token");
  }
  if (verifiedProvider === "anonymous") {
    throw new BoundaryFailure(
      "unauthenticated",
      "durable-authentication-required",
    );
  }
  const data = request.data;
  if (!data ||
      typeof data !== "object" ||
      Array.isArray(data) ||
      Object.keys(data).length !== 1 ||
      !REQUEST_KEY_PATTERN.test(data.requestKey || "")) {
    throw new BoundaryFailure("invalid-argument", "invalid-request");
  }
  return { uid: verifiedUid, requestKey: data.requestKey };
}

function pathSegments(path) {
  if (typeof path !== "string" ||
      Buffer.byteLength(path, "utf8") > MAX_PATH_BYTES) {
    throw new Error("Invalid cloud backup deletion state.");
  }
  const segments = path.split("/");
  if (segments.length > MAX_PATH_SEGMENTS ||
      segments.some((segment) => !validOpaqueSegment(segment))) {
    throw new Error("Invalid cloud backup deletion state.");
  }
  return segments;
}

function assertBackupPath(path, uid, expectedParity) {
  const segments = pathSegments(path);
  if (segments.length < 3 ||
      segments.length % 2 !== expectedParity ||
      segments[0] !== "users" ||
      segments[1] !== uid ||
      !BACKUP_ROOTS.includes(segments[2])) {
    throw new Error("Invalid cloud backup deletion state.");
  }
  return segments.join("/");
}

function opaquePageToken(value) {
  if (value == null) return null;
  if (typeof value !== "string" ||
      value.length === 0 ||
      Buffer.byteLength(value, "utf8") > MAX_PAGE_TOKEN_BYTES) {
    throw new Error("Invalid cloud backup deletion page token.");
  }
  return value;
}

function validWorkId(value) {
  return typeof value === "string" && WORK_ID_PATTERN.test(value);
}

function initialState() {
  return {
    status: "pending",
    rootIndex: 0,
    currentWorkId: null,
    leaseOwner: null,
    leaseUntilMillis: 0,
  };
}

function normalizedState(raw) {
  if (!raw ||
      !["pending", "completed"].includes(raw.status) ||
      !Number.isInteger(raw.rootIndex) ||
      raw.rootIndex < 0 ||
      raw.rootIndex > BACKUP_ROOTS.length ||
      (raw.currentWorkId !== null && !validWorkId(raw.currentWorkId))) {
    throw new Error("Invalid cloud backup deletion state.");
  }
  if (raw.status === "completed" &&
      (raw.rootIndex !== BACKUP_ROOTS.length ||
        raw.currentWorkId !== null)) {
    throw new Error("Invalid completed cloud backup deletion state.");
  }
  return {
    status: raw.status,
    rootIndex: raw.rootIndex,
    currentWorkId: raw.currentWorkId,
    leaseOwner: typeof raw.leaseOwner === "string" ? raw.leaseOwner : null,
    leaseUntilMillis: Number.isFinite(raw.leaseUntilMillis)
      ? raw.leaseUntilMillis
      : 0,
  };
}

function workIdFor({ requestDigest, kind, path, parentWorkId }) {
  if (!DIGEST_PATTERN.test(requestDigest || "") ||
      !["collection", "document"].includes(kind) ||
      (parentWorkId !== null && !validWorkId(parentWorkId))) {
    throw new Error("Invalid cloud backup deletion work ID input.");
  }
  return createHash("sha256")
    .update("cloud-backup-work-v1\0")
    .update(requestDigest)
    .update("\0")
    .update(kind)
    .update("\0")
    .update(parentWorkId || "")
    .update("\0")
    .update(path)
    .digest("hex");
}

function createWork({
  uid,
  requestDigest,
  kind,
  path,
  parentWorkId,
  rootIndex,
}) {
  if (!Number.isInteger(rootIndex) ||
      rootIndex < 0 ||
      rootIndex >= BACKUP_ROOTS.length ||
      !["collection", "document"].includes(kind) ||
      (parentWorkId !== null && !validWorkId(parentWorkId))) {
    throw new Error("Invalid cloud backup deletion work.");
  }
  const normalizedPath = assertBackupPath(
    path,
    uid,
    kind === "collection" ? 1 : 0,
  );
  if (parentWorkId === null &&
      (kind !== "collection" ||
        normalizedPath !== `users/${uid}/${BACKUP_ROOTS[rootIndex]}`)) {
    throw new Error("Invalid cloud backup deletion root work.");
  }
  return {
    id: workIdFor({
      requestDigest,
      kind,
      path: normalizedPath,
      parentWorkId,
    }),
    kind,
    path: normalizedPath,
    parentWorkId,
    rootIndex,
    pageToken: null,
  };
}

function normalizedWork(raw, uid, requestDigest) {
  if (!raw ||
      !validWorkId(raw.id) ||
      !["collection", "document"].includes(raw.kind) ||
      (raw.parentWorkId !== null && !validWorkId(raw.parentWorkId)) ||
      !Number.isInteger(raw.rootIndex) ||
      raw.rootIndex < 0 ||
      raw.rootIndex >= BACKUP_ROOTS.length) {
    throw new Error("Invalid cloud backup deletion work.");
  }
  const work = createWork({
    uid,
    requestDigest,
    kind: raw.kind,
    path: raw.path,
    parentWorkId: raw.parentWorkId,
    rootIndex: raw.rootIndex,
  });
  if (work.id !== raw.id) {
    throw new Error("Invalid cloud backup deletion work ID.");
  }
  return {
    ...work,
    pageToken: opaquePageToken(raw.pageToken),
  };
}

function sameWork(left, right) {
  return left.id === right.id &&
    left.kind === right.kind &&
    left.path === right.path &&
    left.parentWorkId === right.parentWorkId &&
    left.rootIndex === right.rootIndex &&
    left.pageToken === right.pageToken;
}

function assertParentChild(parent, child) {
  const parentSegments = pathSegments(parent.path);
  const childSegments = pathSegments(child.path);
  if (child.parentWorkId !== parent.id ||
      child.rootIndex !== parent.rootIndex ||
      childSegments.length !== parentSegments.length + 1 ||
      childSegments.slice(0, -1).join("/") !== parent.path ||
      (parent.kind === "collection" && child.kind !== "document") ||
      (parent.kind === "document" && child.kind !== "collection")) {
    throw new Error("Invalid cloud backup deletion work relationship.");
  }
}

function normalizedPage(page, itemName, currentPageToken) {
  if (!page || !Array.isArray(page[itemName]) || page[itemName].length > 1) {
    throw new Error("Invalid cloud backup deletion discovery page.");
  }
  const item = page[itemName][0];
  if (item !== undefined && !validOpaqueSegment(item)) {
    throw new Error("Invalid cloud backup deletion discovery page.");
  }
  const nextPageToken = opaquePageToken(page.nextPageToken);
  if (nextPageToken !== null &&
      nextPageToken === opaquePageToken(currentPageToken)) {
    throw new Error("Invalid cloud backup deletion discovery page.");
  }
  return {
    item: item === undefined ? null : item,
    nextPageToken,
  };
}

function resultFor(activeDigest, requestedDigest, state) {
  return {
    state: activeDigest === requestedDigest && state === "completed"
      ? "completed"
      : "pending",
  };
}

function createCloudBackupDeletionRuntime({
  auth,
  repository,
  store,
  hashRequestKey,
  newInvocationId,
  nowMillis = () => Date.now(),
  pageSize = DEFAULT_WORK_UNITS,
  makeError,
} = {}) {
  if (!auth ||
      typeof auth.verifyIdToken !== "function" ||
      !repository ||
      typeof repository.claim !== "function" ||
      typeof repository.currentWork !== "function" ||
      typeof repository.startRoot !== "function" ||
       typeof repository.advanceWork !== "function" ||
       typeof repository.spawnChild !== "function" ||
       typeof repository.completeWork !== "function" ||
       typeof repository.deleteDocumentAndCompleteWork !== "function" ||
       typeof repository.removeBackupFieldsAndComplete !== "function" ||
       typeof repository.release !== "function" ||
       !store ||
       typeof store.listCollectionIdsPage !== "function" ||
       typeof store.listDocumentsPage !== "function" ||
       typeof hashRequestKey !== "function" ||
      typeof newInvocationId !== "function" ||
      typeof nowMillis !== "function" ||
      typeof makeError !== "function") {
    throw new TypeError(
      "Cloud backup deletion dependencies are required.",
    );
  }
  if (!Number.isInteger(pageSize) ||
      pageSize < 1 ||
      pageSize > MAX_WORK_UNITS) {
    throw new TypeError(
      "Cloud backup deletion work units must be between 1 and 200.",
    );
  }

  async function processClaim({
    claim,
    uid,
    requestedDigest,
    invocationId,
  }) {
    const activeDigest = claim.requestDigest;
    if (!DIGEST_PATTERN.test(activeDigest || "")) {
      throw new Error("Invalid cloud backup deletion operation.");
    }
    let state = normalizedState(claim.state);
    if (state.status === "completed") {
      return resultFor(activeDigest, requestedDigest, "completed");
    }
    if (claim.busy === true) {
      return { state: "pending" };
    }

    let completed = false;
    try {
      for (let unit = 0; unit < pageSize; unit += 1) {
        if (state.currentWorkId === null) {
          if (state.rootIndex >= BACKUP_ROOTS.length) {
            await repository.removeBackupFieldsAndComplete({
              uid,
              requestDigest: activeDigest,
              invocationId,
              expectedState: state,
              fields: BACKUP_FIELDS,
              nowMillis: nowMillis(),
            });
            completed = true;
            return resultFor(activeDigest, requestedDigest, "completed");
          }
          const rootWork = createWork({
            uid,
            requestDigest: activeDigest,
            kind: "collection",
            path: `users/${uid}/${BACKUP_ROOTS[state.rootIndex]}`,
            parentWorkId: null,
            rootIndex: state.rootIndex,
          });
          await repository.startRoot({
            uid,
            requestDigest: activeDigest,
            invocationId,
            expectedState: state,
            work: rootWork,
            nowMillis: nowMillis(),
          });
          state = { ...state, currentWorkId: rootWork.id };
          continue;
        }

        const work = await repository.currentWork({
          uid,
          requestDigest: activeDigest,
          invocationId,
          expectedState: state,
          nowMillis: nowMillis(),
        });
        if (work == null) {
          throw new Error("Missing current cloud backup deletion work.");
        }
        const normalized = normalizedWork(work, uid, activeDigest);
        if (normalized.id !== state.currentWorkId) {
          throw new Error("Mismatched current cloud backup deletion work.");
        }

        if (normalized.kind === "collection") {
          const page = normalizedPage(
            await store.listDocumentsPage({
              collectionPath: normalized.path,
              pageSize: 1,
              pageToken: normalized.pageToken,
            }),
            "documentIds",
            normalized.pageToken,
          );
          if (page.item === null) {
            if (page.nextPageToken !== null) {
              await repository.advanceWork({
                uid,
                requestDigest: activeDigest,
                invocationId,
                expectedWork: normalized,
                nextPageToken: page.nextPageToken,
                nowMillis: nowMillis(),
              });
              continue;
            }
            await repository.completeWork({
              uid,
              requestDigest: activeDigest,
              invocationId,
              expectedState: state,
              expectedWork: normalized,
              nowMillis: nowMillis(),
            });
            state = normalized.parentWorkId === null
              ? {
                ...state,
                currentWorkId: null,
                rootIndex: state.rootIndex + 1,
              }
              : { ...state, currentWorkId: normalized.parentWorkId };
            continue;
          }
          const child = createWork({
            uid,
            requestDigest: activeDigest,
            kind: "document",
            path: assertBackupPath(
              `${normalized.path}/${page.item}`,
              uid,
              0,
            ),
            parentWorkId: normalized.id,
            rootIndex: normalized.rootIndex,
          });
          await repository.spawnChild({
            uid,
            requestDigest: activeDigest,
            invocationId,
            expectedState: state,
            expectedParent: normalized,
            child,
            // Persist the opaque continuation cursor with the child receipt.
            // The pager's contract is that this cursor resumes after the
            // discovered item; the receipt makes a retry safe before any
            // destructive child work starts.
            parentNextPageToken: page.nextPageToken,
            nowMillis: nowMillis(),
          });
          state = { ...state, currentWorkId: child.id };
          continue;
        }

        const page = normalizedPage(
          await store.listCollectionIdsPage({
            parentPath: normalized.path,
            pageSize: 1,
            pageToken: normalized.pageToken,
          }),
          "collectionIds",
          normalized.pageToken,
        );
        if (page.item === null) {
          if (page.nextPageToken !== null) {
            await repository.advanceWork({
              uid,
              requestDigest: activeDigest,
              invocationId,
              expectedWork: normalized,
              nextPageToken: page.nextPageToken,
              nowMillis: nowMillis(),
            });
            continue;
          }
          await repository.deleteDocumentAndCompleteWork({
            uid,
            requestDigest: activeDigest,
            invocationId,
            expectedState: state,
            expectedWork: normalized,
            nowMillis: nowMillis(),
          });
          state = normalized.parentWorkId === null
            ? {
              ...state,
              currentWorkId: null,
              rootIndex: state.rootIndex + 1,
            }
            : { ...state, currentWorkId: normalized.parentWorkId };
          continue;
        }
        const child = createWork({
          uid,
          requestDigest: activeDigest,
          kind: "collection",
          path: assertBackupPath(
            `${normalized.path}/${page.item}`,
            uid,
            1,
          ),
          parentWorkId: normalized.id,
          rootIndex: normalized.rootIndex,
        });
        await repository.spawnChild({
          uid,
          requestDigest: activeDigest,
          invocationId,
          expectedState: state,
          expectedParent: normalized,
          child,
          parentNextPageToken: page.nextPageToken,
          nowMillis: nowMillis(),
        });
        state = { ...state, currentWorkId: child.id };
      }
      return { state: "pending" };
    } finally {
      if (!completed) {
        await repository.release({
          uid,
          requestDigest: activeDigest,
          invocationId,
          nowMillis: nowMillis(),
        });
      }
    }
  }

  async function deleteCloudBackup(request) {
    try {
      const { uid, requestKey } = await assertRequest(request, auth);
      const requestedDigest = await hashRequestKey({ uid, requestKey });
      if (!DIGEST_PATTERN.test(requestedDigest || "")) {
        throw new Error("Invalid cloud backup deletion digest.");
      }
      const invocationId = newInvocationId();
      if (!validOpaqueSegment(invocationId)) {
        throw new Error("Invalid cloud backup deletion invocation.");
      }
      const claim = await repository.claim({
        uid,
        requestDigest: requestedDigest,
        invocationId,
        nowMillis: nowMillis(),
        leaseMillis: LEASE_MILLIS,
      });
      return await processClaim({
        claim,
        uid,
        requestedDigest,
        invocationId,
      });
    } catch (error) {
      if (error instanceof BoundaryFailure) {
        throw makeError(error.status, error.safeCode);
      }
      throw makeError(
        "unavailable",
        "cloud-backup-deletion-unavailable",
      );
    }
  }

  return Object.freeze({ deleteCloudBackup });
}

function createFirestoreCloudBackupDeletionRepository({
  firestore,
  fieldValue,
  collectionName = "cloud_backup_deletions",
} = {}) {
  if (!firestore ||
      typeof firestore.collection !== "function" ||
      typeof firestore.runTransaction !== "function") {
    throw new TypeError(
      "Firestore cloud backup deletion repository is required.",
    );
  }
  if (!fieldValue || typeof fieldValue.delete !== "function") {
    throw new TypeError(
      "Firestore cloud backup deletion field values are required.",
    );
  }
  const collection = firestore.collection(collectionName);

  function operationRef(uid) {
    return collection.doc(uid);
  }

  function workRef(uid, workId) {
    return operationRef(uid).collection("work").doc(workId);
  }

  function normalizedRecord(snapshot, uid) {
    if (!snapshot.exists) return null;
    const record = snapshot.data() || {};
    if (record.uid !== uid || !DIGEST_PATTERN.test(record.requestDigest || "")) {
      throw new Error("Invalid cloud backup deletion operation.");
    }
    return { ...record, state: normalizedState(record.state) };
  }

  function assertLease(record, {
    requestDigest,
    invocationId,
    expectedState,
    nowMillis,
  }) {
    if (record.requestDigest !== requestDigest ||
        record.state.status !== "pending" ||
        record.state.leaseOwner !== invocationId ||
        !Number.isFinite(nowMillis) ||
        record.state.leaseUntilMillis <= nowMillis ||
        (expectedState !== undefined &&
          (record.state.rootIndex !== expectedState.rootIndex ||
            record.state.currentWorkId !== expectedState.currentWorkId))) {
      throw new Error("Stale cloud backup deletion lease.");
    }
  }

  function normalizedSnapshotWork(snapshot, uid, requestDigest) {
    if (!snapshot.exists) {
      throw new Error("Missing cloud backup deletion work.");
    }
    return normalizedWork(snapshot.data() || {}, uid, requestDigest);
  }

  async function claim({
    uid,
    requestDigest,
    invocationId,
    nowMillis,
    leaseMillis,
  }) {
    const ref = operationRef(uid);
    return firestore.runTransaction(async (transaction) => {
      const snapshot = await transaction.get(ref);
      const stored = normalizedRecord(snapshot, uid);
      if (!stored || (
        stored.state.status === "completed" &&
        stored.requestDigest !== requestDigest
      )) {
        const record = {
          uid,
          requestDigest,
          state: {
            ...initialState(),
            leaseOwner: invocationId,
            leaseUntilMillis: nowMillis + leaseMillis,
          },
          createdAtMillis: nowMillis,
          updatedAtMillis: nowMillis,
        };
        transaction.set(ref, record);
        return record;
      }
      if (stored.state.status === "completed") {
        return stored;
      }
      if (stored.state.leaseOwner !== null &&
          stored.state.leaseOwner !== invocationId &&
          stored.state.leaseUntilMillis > nowMillis) {
        return { ...stored, busy: true };
      }
      const claimed = {
        ...stored,
        state: {
          ...stored.state,
          leaseOwner: invocationId,
          leaseUntilMillis: nowMillis + leaseMillis,
        },
        updatedAtMillis: nowMillis,
      };
      transaction.set(ref, claimed);
      return claimed;
    });
  }

  async function currentWork({
    uid,
    requestDigest,
    invocationId,
    expectedState,
    nowMillis,
  }) {
    const ref = operationRef(uid);
    return firestore.runTransaction(async (transaction) => {
      const operationSnapshot = await transaction.get(ref);
      const record = normalizedRecord(operationSnapshot, uid);
      if (record === null) {
        throw new Error("Missing cloud backup deletion operation.");
      }
      assertLease(record, {
        requestDigest,
        invocationId,
        expectedState,
        nowMillis,
      });
      if (record.state.currentWorkId === null) return null;
      const snapshot = await transaction.get(
        workRef(uid, record.state.currentWorkId),
      );
      return normalizedSnapshotWork(snapshot, uid, requestDigest);
    });
  }

  async function startRoot({
    uid,
    requestDigest,
    invocationId,
    expectedState,
    work,
    nowMillis,
  }) {
    const ref = operationRef(uid);
    const normalized = normalizedWork(work, uid, requestDigest);
    return firestore.runTransaction(async (transaction) => {
      const operationSnapshot = await transaction.get(ref);
      const record = normalizedRecord(operationSnapshot, uid);
      if (record === null) {
        throw new Error("Missing cloud backup deletion operation.");
      }
      assertLease(record, {
        requestDigest,
        invocationId,
        expectedState,
        nowMillis,
      });
      if (record.state.currentWorkId !== null ||
          record.state.rootIndex !== normalized.rootIndex ||
          normalized.parentWorkId !== null) {
        throw new Error("Invalid cloud backup deletion root transition.");
      }
      const childRef = workRef(uid, normalized.id);
      const workSnapshot = await transaction.get(childRef);
      if (workSnapshot.exists) {
        throw new Error("Unexpected existing cloud backup root work.");
      }
      transaction.set(childRef, normalized);
      transaction.set(ref, {
        ...record,
        state: { ...record.state, currentWorkId: normalized.id },
        updatedAtMillis: nowMillis,
      });
    });
  }

  async function advanceWork({
    uid,
    requestDigest,
    invocationId,
    expectedWork,
    nextPageToken,
    nowMillis,
  }) {
    const ref = operationRef(uid);
    const expected = normalizedWork(expectedWork, uid, requestDigest);
    const nextToken = opaquePageToken(nextPageToken);
    return firestore.runTransaction(async (transaction) => {
      const operationSnapshot = await transaction.get(ref);
      const record = normalizedRecord(operationSnapshot, uid);
      if (record === null) {
        throw new Error("Missing cloud backup deletion operation.");
      }
      assertLease(record, { requestDigest, invocationId, nowMillis });
      if (record.state.currentWorkId !== expected.id) {
        throw new Error("Stale cloud backup deletion work.");
      }
      const current = normalizedSnapshotWork(
        await transaction.get(workRef(uid, expected.id)),
        uid,
        requestDigest,
      );
      if (!sameWork(current, expected)) {
        throw new Error("Stale cloud backup deletion work.");
      }
      transaction.set(workRef(uid, expected.id), {
        ...current,
        pageToken: nextToken,
      });
      transaction.set(ref, { ...record, updatedAtMillis: nowMillis });
    });
  }

  async function spawnChild({
    uid,
    requestDigest,
    invocationId,
    expectedState,
    expectedParent,
    child,
    parentNextPageToken,
    nowMillis,
  }) {
    const ref = operationRef(uid);
    const parent = normalizedWork(expectedParent, uid, requestDigest);
    const next = normalizedWork(child, uid, requestDigest);
    const nextToken = opaquePageToken(parentNextPageToken);
    assertParentChild(parent, next);
    return firestore.runTransaction(async (transaction) => {
      const operationSnapshot = await transaction.get(ref);
      const record = normalizedRecord(operationSnapshot, uid);
      if (record === null) {
        throw new Error("Missing cloud backup deletion operation.");
      }
      assertLease(record, {
        requestDigest,
        invocationId,
        expectedState,
        nowMillis,
      });
      if (record.state.currentWorkId !== parent.id) {
        throw new Error("Stale cloud backup deletion parent work.");
      }
      const parentRef = workRef(uid, parent.id);
      const childRef = workRef(uid, next.id);
      const parentSnapshot = await transaction.get(parentRef);
      const childSnapshot = await transaction.get(childRef);
      const currentParent = normalizedSnapshotWork(
        parentSnapshot,
        uid,
        requestDigest,
      );
      if (!sameWork(currentParent, parent) || childSnapshot.exists) {
        throw new Error("Stale cloud backup deletion parent work.");
      }
      // The child receipt and the parent cursor are one transaction: a parent
      // can never advance past a discovered descendant without durable work.
      transaction.set(childRef, next);
      transaction.set(parentRef, {
        ...currentParent,
        pageToken: nextToken,
      });
      transaction.set(ref, {
        ...record,
        state: { ...record.state, currentWorkId: next.id },
        updatedAtMillis: nowMillis,
      });
    });
  }

  async function completeWorkInTransaction(transaction, {
    uid,
    requestDigest,
    record,
    expected,
  }) {
    if (record.state.currentWorkId !== expected.id) {
      throw new Error("Stale cloud backup deletion work.");
    }
    const current = normalizedSnapshotWork(
      await transaction.get(workRef(uid, expected.id)),
      uid,
      requestDigest,
    );
    if (!sameWork(current, expected)) {
      throw new Error("Stale cloud backup deletion work.");
    }
    let nextState;
    if (current.parentWorkId === null) {
      if (record.state.rootIndex !== current.rootIndex) {
        throw new Error("Invalid cloud backup deletion root completion.");
      }
      nextState = {
        ...record.state,
        currentWorkId: null,
        rootIndex: record.state.rootIndex + 1,
      };
    } else {
      const parent = normalizedSnapshotWork(
        await transaction.get(workRef(uid, current.parentWorkId)),
        uid,
        requestDigest,
      );
      assertParentChild(parent, current);
      nextState = {
        ...record.state,
        currentWorkId: parent.id,
      };
    }
    transaction.delete(workRef(uid, current.id));
    return nextState;
  }

  async function completeWork({
    uid,
    requestDigest,
    invocationId,
    expectedState,
    expectedWork,
    nowMillis,
  }) {
    const ref = operationRef(uid);
    const expected = normalizedWork(expectedWork, uid, requestDigest);
    return firestore.runTransaction(async (transaction) => {
      const operationSnapshot = await transaction.get(ref);
      const record = normalizedRecord(operationSnapshot, uid);
      if (record === null) {
        throw new Error("Missing cloud backup deletion operation.");
      }
      assertLease(record, {
        requestDigest,
        invocationId,
        expectedState,
        nowMillis,
      });
      const nextState = await completeWorkInTransaction(transaction, {
        uid,
        requestDigest,
        record,
        expected,
      });
      transaction.set(ref, {
        ...record,
        state: nextState,
        updatedAtMillis: nowMillis,
      });
    });
  }

  async function deleteDocumentAndCompleteWork({
    uid,
    requestDigest,
    invocationId,
    expectedState,
    expectedWork,
    nowMillis,
  }) {
    const ref = operationRef(uid);
    const expected = normalizedWork(expectedWork, uid, requestDigest);
    if (expected.kind !== "document") {
      throw new Error("Invalid cloud backup deletion document work.");
    }
    return firestore.runTransaction(async (transaction) => {
      const operationSnapshot = await transaction.get(ref);
      const record = normalizedRecord(operationSnapshot, uid);
      if (record === null) {
        throw new Error("Missing cloud backup deletion operation.");
      }
      assertLease(record, {
        requestDigest,
        invocationId,
        expectedState,
        nowMillis,
      });
      const nextState = await completeWorkInTransaction(transaction, {
        uid,
        requestDigest,
        record,
        expected,
      });
      // The target delete and queue transition share the same transaction, so
      // an expired invocation can never delete data after a successor starts.
      // Complete work first because Firestore transactions require every read
      // to happen before their writes.
      transaction.delete(firestore.doc(expected.path));
      transaction.set(ref, {
        ...record,
        state: nextState,
        updatedAtMillis: nowMillis,
      });
    });
  }

  async function removeBackupFieldsAndComplete({
    uid,
    requestDigest,
    invocationId,
    expectedState,
    fields,
    nowMillis,
  }) {
    if (!Array.isArray(fields) ||
        fields.length !== BACKUP_FIELDS.length ||
        fields.some((field, index) => field !== BACKUP_FIELDS[index])) {
      throw new Error("Invalid cloud backup deletion fields.");
    }
    const ref = operationRef(uid);
    const userRef = firestore.collection("users").doc(uid);
    return firestore.runTransaction(async (transaction) => {
      const operationSnapshot = await transaction.get(ref);
      const record = normalizedRecord(operationSnapshot, uid);
      if (record === null) {
        throw new Error("Missing cloud backup deletion operation.");
      }
      assertLease(record, {
        requestDigest,
        invocationId,
        expectedState,
        nowMillis,
      });
      if (record.state.rootIndex !== BACKUP_ROOTS.length ||
          record.state.currentWorkId !== null) {
        throw new Error("Cloud backup deletion is not ready to complete.");
      }
      const userSnapshot = await transaction.get(userRef);
      if (userSnapshot.exists) {
        transaction.update(userRef, Object.fromEntries(
          fields.map((field) => [field, fieldValue.delete()]),
        ));
      }
      transaction.set(ref, {
        ...record,
        state: {
          ...record.state,
          status: "completed",
          leaseOwner: null,
          leaseUntilMillis: 0,
        },
        updatedAtMillis: nowMillis,
      });
    });
  }

  async function release({
    uid,
    requestDigest,
    invocationId,
    nowMillis,
  }) {
    const ref = operationRef(uid);
    return firestore.runTransaction(async (transaction) => {
      const operationSnapshot = await transaction.get(ref);
      const record = normalizedRecord(operationSnapshot, uid);
      if (record === null || record.state.status === "completed") {
        return;
      }
      assertLease(record, { requestDigest, invocationId, nowMillis });
      transaction.set(ref, {
        ...record,
        state: {
          ...record.state,
          leaseOwner: null,
          leaseUntilMillis: 0,
        },
        updatedAtMillis: nowMillis,
      });
    });
  }

  return Object.freeze({
    advanceWork,
    claim,
    completeWork,
    currentWork,
    deleteDocumentAndCompleteWork,
    removeBackupFieldsAndComplete,
    release,
    spawnChild,
    startRoot,
  });
}

function createFirestoreCloudBackupStore({
  listCollectionIdsPage,
  listDocumentsPage,
} = {}) {
  if (typeof listCollectionIdsPage !== "function" ||
      typeof listDocumentsPage !== "function") {
    throw new TypeError("Firestore cloud backup store is required.");
  }

  return Object.freeze({
    listCollectionIdsPage,
    listDocumentsPage,
  });
}

function createCloudBackupDeletionCallable({
  handler,
  onCall,
  secrets = [],
} = {}) {
  if (typeof handler !== "function" || typeof onCall !== "function") {
    throw new TypeError("Cloud backup deletion callable dependencies required.");
  }
  return onCall(
    {
      ...CALLABLE_OPTIONS,
      ...(secrets.length === 0 ? {} : { secrets }),
    },
    handler,
  );
}

module.exports = {
  BACKUP_FIELDS,
  BACKUP_ROOTS,
  CALLABLE_OPTIONS,
  createCloudBackupDeletionCallable,
  createCloudBackupDeletionRuntime,
  createFirestoreCloudBackupDeletionRepository,
  createFirestoreCloudBackupStore,
};
