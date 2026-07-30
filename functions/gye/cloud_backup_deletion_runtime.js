"use strict";

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
  "updated_at",
]);
const CALLABLE_OPTIONS = Object.freeze({
  region: "europe-west3",
  enforceAppCheck: true,
  consumeAppCheckToken: true,
});
const REQUEST_KEY_PATTERN = /^[A-Za-z0-9_-]{43,128}$/;
const DIGEST_PATTERN = /^[a-f0-9]{64}$/;
const LEASE_MILLIS = 60_000;
const DEFAULT_PAGE_SIZE = 40;
const MAX_PAGE_SIZE = 200;
const MAX_PATH_BYTES = 6_000;

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

function assertRequest(request) {
  if (!request?.app || typeof request.app.appId !== "string") {
    throw new BoundaryFailure(
      "failed-precondition",
      "app-check-required",
    );
  }
  if (request.app.alreadyConsumed === true) {
    throw new BoundaryFailure(
      "resource-exhausted",
      "app-check-token-consumed",
    );
  }
  const uid = request?.auth?.uid;
  if (!validUid(uid)) {
    throw new BoundaryFailure(
      "unauthenticated",
      "authentication-required",
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
  return { uid, requestKey: data.requestKey };
}

function pathSegments(path) {
  if (typeof path !== "string" ||
      Buffer.byteLength(path, "utf8") > MAX_PATH_BYTES) {
    throw new Error("Invalid cloud backup deletion state.");
  }
  const segments = path.split("/");
  if (segments.some((segment) => !validOpaqueSegment(segment))) {
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

function initialState() {
  return {
    status: "pending",
    rootIndex: 0,
    stack: [],
    leaseOwner: null,
    leaseUntilMillis: 0,
  };
}

function normalizedState(raw, uid) {
  if (!raw ||
      raw.status !== "pending" ||
      !Number.isInteger(raw.rootIndex) ||
      raw.rootIndex < 0 ||
      raw.rootIndex > BACKUP_ROOTS.length ||
      !Array.isArray(raw.stack) ||
      raw.stack.length > 100) {
    throw new Error("Invalid cloud backup deletion state.");
  }
  const stack = raw.stack.map((frame) => {
    if (!frame || !["collection", "document"].includes(frame.kind)) {
      throw new Error("Invalid cloud backup deletion state.");
    }
    return {
      kind: frame.kind,
      path: assertBackupPath(
        frame.path,
        uid,
        frame.kind === "collection" ? 1 : 0,
      ),
    };
  });
  return {
    status: "pending",
    rootIndex: raw.rootIndex,
    stack,
    leaseOwner:
      typeof raw.leaseOwner === "string" ? raw.leaseOwner : null,
    leaseUntilMillis: Number.isFinite(raw.leaseUntilMillis)
      ? raw.leaseUntilMillis
      : 0,
  };
}

function releasedState(state, status = "pending") {
  return {
    ...state,
    status,
    leaseOwner: null,
    leaseUntilMillis: 0,
  };
}

function createCloudBackupDeletionRuntime({
  repository,
  store,
  hashRequestKey,
  newInvocationId,
  nowMillis = () => Date.now(),
  pageSize = DEFAULT_PAGE_SIZE,
  makeError,
} = {}) {
  if (!repository ||
      typeof repository.claim !== "function" ||
      typeof repository.checkpoint !== "function" ||
      !store ||
      typeof store.firstDocument !== "function" ||
      typeof store.firstChildCollection !== "function" ||
      typeof store.deleteDocument !== "function" ||
      typeof store.removeBackupFields !== "function" ||
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
      pageSize > MAX_PAGE_SIZE) {
    throw new TypeError(
      "Cloud backup deletion page size must be between 1 and 200.",
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
    if (claim.state?.status === "completed") {
      return {
        state: activeDigest === requestedDigest ? "completed" : "pending",
      };
    }
    if (claim.busy === true) {
      return { state: "pending" };
    }

    let state = normalizedState(claim.state, uid);
    for (let unit = 0; unit < pageSize; unit += 1) {
      if (state.stack.length === 0) {
        if (state.rootIndex >= BACKUP_ROOTS.length) {
          await store.removeBackupFields(uid, BACKUP_FIELDS);
          state = releasedState({
            ...state,
            stack: [],
          }, "completed");
          await repository.checkpoint({
            uid,
            requestDigest: activeDigest,
            invocationId,
            state,
            nowMillis: nowMillis(),
          });
          return {
            state: activeDigest === requestedDigest
              ? "completed"
              : "pending",
          };
        }
        state.stack.push({
          kind: "collection",
          path: `users/${uid}/${BACKUP_ROOTS[state.rootIndex]}`,
        });
      }

      const frame = state.stack.at(-1);
      if (frame.kind === "collection") {
        const documentPath = await store.firstDocument(frame.path);
        if (documentPath === null) {
          state.stack.pop();
          if (state.stack.length === 0) {
            state.rootIndex += 1;
          }
          continue;
        }
        state.stack.push({
          kind: "document",
          path: assertBackupPath(documentPath, uid, 0),
        });
        continue;
      }

      const childCollectionPath =
        await store.firstChildCollection(frame.path);
      if (childCollectionPath !== null) {
        state.stack.push({
          kind: "collection",
          path: assertBackupPath(childCollectionPath, uid, 1),
        });
        continue;
      }
      await store.deleteDocument(frame.path);
      state.stack.pop();
    }

    state = releasedState(state);
    await repository.checkpoint({
      uid,
      requestDigest: activeDigest,
      invocationId,
      state,
      nowMillis: nowMillis(),
    });
    return { state: "pending" };
  }

  async function deleteCloudBackup(request) {
    try {
      const { uid, requestKey } = assertRequest(request);
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
  collectionName = "cloud_backup_deletions",
} = {}) {
  if (!firestore ||
      typeof firestore.collection !== "function" ||
      typeof firestore.runTransaction !== "function") {
    throw new TypeError(
      "Firestore cloud backup deletion repository is required.",
    );
  }
  const collection = firestore.collection(collectionName);

  async function claim({
    uid,
    requestDigest,
    invocationId,
    nowMillis,
    leaseMillis,
  }) {
    const ref = collection.doc(uid);
    return firestore.runTransaction(async (transaction) => {
      const snapshot = await transaction.get(ref);
      const stored = snapshot.exists ? snapshot.data() || {} : null;
      if (!stored || (
        stored.state?.status === "completed" &&
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
      if (stored.uid !== uid ||
          !DIGEST_PATTERN.test(stored.requestDigest || "")) {
        throw new Error("Invalid cloud backup deletion operation.");
      }
      if (stored.state?.status === "completed") {
        return stored;
      }
      const state = normalizedState(stored.state, uid);
      if (state.leaseOwner !== null &&
          state.leaseOwner !== invocationId &&
          state.leaseUntilMillis > nowMillis) {
        return { ...stored, state, busy: true };
      }
      const claimed = {
        ...stored,
        state: {
          ...state,
          leaseOwner: invocationId,
          leaseUntilMillis: nowMillis + leaseMillis,
        },
        updatedAtMillis: nowMillis,
      };
      transaction.set(ref, claimed);
      return claimed;
    });
  }

  async function checkpoint({
    uid,
    requestDigest,
    invocationId,
    state,
    nowMillis,
  }) {
    const ref = collection.doc(uid);
    return firestore.runTransaction(async (transaction) => {
      const snapshot = await transaction.get(ref);
      const stored = snapshot.exists ? snapshot.data() || {} : {};
      if (stored.uid !== uid ||
          stored.requestDigest !== requestDigest ||
          stored.state?.leaseOwner !== invocationId) {
        throw new Error("Stale cloud backup deletion lease.");
      }
      const next = {
        ...stored,
        state,
        updatedAtMillis: nowMillis,
      };
      transaction.set(ref, next);
      return next;
    });
  }

  return Object.freeze({ claim, checkpoint });
}

function createFirestoreCloudBackupStore({
  firestore,
  fieldValue,
  listCollectionIdsPage,
  listDocumentsPage,
} = {}) {
  if (!firestore ||
      typeof firestore.doc !== "function" ||
      typeof firestore.runTransaction !== "function" ||
      !fieldValue ||
      typeof fieldValue.delete !== "function" ||
      typeof listCollectionIdsPage !== "function" ||
      typeof listDocumentsPage !== "function") {
    throw new TypeError("Firestore cloud backup store is required.");
  }

  async function firstDocument(collectionPath) {
    const page = await listDocumentsPage({
      collectionPath,
      pageSize: 1,
      pageToken: null,
    });
    if (!Array.isArray(page?.documentIds) ||
        page.documentIds.length > 1) {
      throw new Error("Invalid cloud backup document page.");
    }
    const documentId = page.documentIds[0];
    if (documentId === undefined) return null;
    if (!validOpaqueSegment(documentId)) {
      throw new Error("Invalid cloud backup document page.");
    }
    return `${collectionPath}/${documentId}`;
  }

  async function firstChildCollection(documentPath) {
    const page = await listCollectionIdsPage({
      parentPath: documentPath,
      pageSize: 1,
      pageToken: null,
    });
    if (!Array.isArray(page?.collectionIds) ||
        page.collectionIds.length > 1) {
      throw new Error("Invalid cloud backup collection page.");
    }
    const collectionId = page.collectionIds[0];
    if (collectionId === undefined) return null;
    if (!validOpaqueSegment(collectionId)) {
      throw new Error("Invalid cloud backup collection page.");
    }
    return `${documentPath}/${collectionId}`;
  }

  async function deleteDocument(documentPath) {
    await firestore.doc(documentPath).delete();
  }

  async function removeBackupFields(uid, fields) {
    const ref = firestore.collection("users").doc(uid);
    await firestore.runTransaction(async (transaction) => {
      const snapshot = await transaction.get(ref);
      if (!snapshot.exists) return;
      transaction.update(ref, Object.fromEntries(
        fields.map((field) => [field, fieldValue.delete()]),
      ));
    });
  }

  return Object.freeze({
    deleteDocument,
    firstChildCollection,
    firstDocument,
    removeBackupFields,
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
