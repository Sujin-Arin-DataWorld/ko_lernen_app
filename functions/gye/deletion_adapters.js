"use strict";

const crypto = require("node:crypto");

const WORK_COLLECTION = "user_tree_work";
const WORK_CURSOR = "work-v1";
const DEFAULT_PAGE_SIZE = 200;
const MAX_PAGE_SIZE = 200;
const DISCOVERY_INITIAL = "initial";
const DISCOVERY_INITIAL_COMPLETE = "initial-complete";
const DISCOVERY_LATE = "late";
const DISCOVERY_LATE_COMPLETE = "late-complete";
const DISCOVERY_MODES = new Set([
  DISCOVERY_INITIAL,
  DISCOVERY_INITIAL_COMPLETE,
  DISCOVERY_LATE,
  DISCOVERY_LATE_COMPLETE,
]);

function adapterFailure(code) {
  const error = new Error("Account deletion adapter rejected unsafe state.");
  error.code = code;
  return error;
}

function opaqueDocumentId(value, code) {
  if (typeof value !== "string" ||
      value.length < 1 ||
      Buffer.byteLength(value, "utf8") > 1_500 ||
      value === "." ||
      value === ".." ||
      value.includes("/")) {
    throw adapterFailure(code);
  }
  return value;
}

function opaquePageToken(value) {
  if (value === null || value === undefined || value === "") return null;
  if (typeof value !== "string" ||
      Buffer.byteLength(value, "utf8") > 4_096) {
    throw adapterFailure("invalid-deletion-work");
  }
  return value;
}

function effectivePageLimit(limit, pageSize) {
  if (!Number.isInteger(limit) || limit < 1) {
    throw adapterFailure("invalid-deletion-limit");
  }
  return Math.min(limit, pageSize, MAX_PAGE_SIZE);
}

function normalizeGyeIds(values) {
  if (!Array.isArray(values)) return [];
  return Array.from(new Set(values.filter((value) => {
    if (typeof value !== "string" ||
        value.length < 1 ||
        value !== value.trim() ||
        Buffer.byteLength(value, "utf8") > 1_500 ||
        value === "." ||
        value === ".." ||
        value.includes("/")) {
      return false;
    }
    return true;
  }))).sort();
}

function normalizedCollectionPath(path, uid) {
  if (typeof path !== "string" ||
      Buffer.byteLength(path, "utf8") > 6_000) {
    throw adapterFailure("invalid-deletion-work");
  }
  const segments = path.split("/");
  if (segments.length < 3 ||
      segments.length % 2 !== 1 ||
      segments[0] !== "users" ||
      segments[1] !== uid ||
      segments.some((segment) =>
        segment.length < 1 ||
        Buffer.byteLength(segment, "utf8") > 1_500 ||
        segment === "." ||
        segment === "..")) {
    throw adapterFailure("invalid-deletion-work");
  }
  return segments.join("/");
}

function normalizedDocumentPath(path, uid) {
  if (typeof path !== "string" ||
      Buffer.byteLength(path, "utf8") > 6_000) {
    throw adapterFailure("invalid-deletion-work");
  }
  const segments = path.split("/");
  if (segments.length < 2 ||
      segments.length % 2 !== 0 ||
      segments[0] !== "users" ||
      segments[1] !== uid ||
      segments.some((segment) =>
        segment.length < 1 ||
        Buffer.byteLength(segment, "utf8") > 1_500 ||
        segment === "." ||
        segment === "..")) {
    throw adapterFailure("invalid-deletion-work");
  }
  return segments.join("/");
}

function workId(operationId, collectionPath) {
  return crypto
    .createHash("sha256")
    .update(operationId, "utf8")
    .update("\0", "utf8")
    .update(collectionPath, "utf8")
    .digest("hex");
}

function validatedFence(workerFence) {
  if (!workerFence ||
      typeof workerFence.workerId !== "string" ||
      workerFence.workerId.length < 1 ||
      !Number.isInteger(workerFence.operationVersion) ||
      workerFence.operationVersion < 0 ||
      !Number.isInteger(workerFence.leaseVersion) ||
      workerFence.leaseVersion < 1) {
    throw adapterFailure("invalid-worker-fence");
  }
  return {
    workerId: workerFence.workerId,
    operationVersion: workerFence.operationVersion,
    leaseVersion: workerFence.leaseVersion,
  };
}

function rootDiscovery(marker, operationId) {
  const stored = marker?.userTreeDiscovery;
  if (!stored || stored.operationId !== operationId) {
    return {
      operationId,
      mode: DISCOVERY_INITIAL,
      pageToken: null,
    };
  }
  if (!DISCOVERY_MODES.has(stored.mode)) {
    throw adapterFailure("invalid-deletion-work");
  }
  return {
    operationId,
    mode: stored.mode,
    pageToken: opaquePageToken(stored.pageToken),
  };
}

function sameDiscovery(left, right) {
  return left.operationId === right.operationId &&
    left.mode === right.mode &&
    left.pageToken === right.pageToken;
}

function createGapicCollectionIdPager({ firestore, client } = {}) {
  if (!firestore || typeof firestore.doc !== "function" ||
      !client || typeof client.listCollectionIds !== "function") {
    throw new TypeError("Firestore collection-ID pager dependencies required.");
  }
  return async function listCollectionIdsPage({
    parentPath,
    pageSize,
    pageToken,
  }) {
    const parent = firestore.doc(parentPath).formattedName;
    const request = {
      parent,
      pageSize,
    };
    if (pageToken) request.pageToken = pageToken;
    const [collectionIds, nextRequest, response] =
      await client.listCollectionIds(
        request,
        { autoPaginate: false },
      );
    const nextPageToken = response?.nextPageToken ||
      nextRequest?.pageToken ||
      null;
    return {
      collectionIds,
      nextPageToken,
    };
  };
}

function createFirestoreDeletionAdapters({
  firestore,
  markerCollection,
  listCollectionIdsPage,
  nowMillis = () => Date.now(),
  pageSize = DEFAULT_PAGE_SIZE,
} = {}) {
  if (!firestore ||
      typeof firestore.collection !== "function" ||
      typeof firestore.runTransaction !== "function" ||
      !markerCollection ||
      typeof markerCollection.doc !== "function" ||
      typeof listCollectionIdsPage !== "function" ||
      typeof nowMillis !== "function") {
    throw new TypeError("Firestore deletion adapter dependencies are required.");
  }
  if (!Number.isInteger(pageSize) ||
      pageSize < 1 ||
      pageSize > MAX_PAGE_SIZE) {
    throw new TypeError("Deletion page size must be between 1 and 200.");
  }

  function refs({ uid, operationId }) {
    const safeUid = opaqueDocumentId(uid, "invalid-deletion-uid");
    const safeOperationId = opaqueDocumentId(
      operationId,
      "invalid-deletion-operation",
    );
    const markerRef = markerCollection.doc(safeUid);
    return {
      uid: safeUid,
      operationId: safeOperationId,
      markerRef,
      operationRef:
        firestore.collection("account_operations").doc(safeOperationId),
      rootRef: firestore.collection("users").doc(safeUid),
      workCollection: markerRef.collection(WORK_COLLECTION),
    };
  }

  function requireOwnedMarker(snapshot, context) {
    const marker = snapshot.exists ? snapshot.data() || {} : {};
    if (!snapshot.exists ||
        marker.serverOwned !== true ||
        marker.operationId !== context.operationId ||
        marker.sourceUid !== context.uid) {
      throw adapterFailure("invalid-deletion-marker");
    }
    return marker;
  }

  function assertActiveLease(snapshot, fence) {
    const operation = snapshot.exists ? snapshot.data() || {} : {};
    const lease = operation.workerLease || {};
    if (!snapshot.exists ||
        operation.version !== fence.operationVersion ||
        lease.workerId !== fence.workerId ||
        lease.leaseVersion !== fence.leaseVersion ||
        !Number.isFinite(lease.leaseUntilMillis) ||
        lease.leaseUntilMillis <= nowMillis()) {
      throw adapterFailure("stale-worker-lease");
    }
  }

  async function runFencedTransaction(context, fence, callback) {
    return firestore.runTransaction(async (transaction) => {
      const operation = await transaction.get(context.operationRef);
      assertActiveLease(operation, fence);
      const markerSnapshot = await transaction.get(context.markerRef);
      const marker = requireOwnedMarker(markerSnapshot, context);
      return callback(transaction, marker, markerSnapshot);
    });
  }

  function validateWorkSnapshot(snapshot, context) {
    const data = snapshot.data() || {};
    const collectionPath = normalizedCollectionPath(
      data.collectionPath,
      context.uid,
    );
    const activeDocumentId = data.activeDocumentId === null ||
      data.activeDocumentId === undefined
      ? null
      : opaqueDocumentId(
        data.activeDocumentId,
        "invalid-deletion-work",
      );
    const lastDocumentId = data.lastDocumentId === null ||
      data.lastDocumentId === undefined
      ? null
      : opaqueDocumentId(
        data.lastDocumentId,
        "invalid-deletion-work",
      );
    if (snapshot.id !== workId(context.operationId, collectionPath) ||
        data.operationId !== context.operationId ||
        data.uid !== context.uid ||
        !["pending", "complete"].includes(data.state)) {
      throw adapterFailure("invalid-deletion-work");
    }
    return {
      ...data,
      collectionPath,
      activeDocumentId,
      discoveryPageToken: opaquePageToken(data.discoveryPageToken),
      lastDocumentId,
    };
  }

  function newWork(context, collectionPath) {
    return {
      operationId: context.operationId,
      uid: context.uid,
      collectionPath,
      state: "pending",
      lastDocumentId: null,
      activeDocumentId: null,
      discoveryPageToken: null,
    };
  }

  function collectionPathsFromPage(context, parentPath, response, limit) {
    const collectionIds = Array.isArray(response?.collectionIds)
      ? response.collectionIds
      : null;
    if (!collectionIds || collectionIds.length > limit) {
      throw adapterFailure("invalid-discovery-page");
    }
    const parent = normalizedDocumentPath(parentPath, context.uid);
    return Array.from(new Set(collectionIds.map((collectionId) => {
      const id = opaqueDocumentId(
        collectionId,
        "invalid-discovery-page",
      );
      return normalizedCollectionPath(`${parent}/${id}`, context.uid);
    }))).sort();
  }

  async function safeDiscoveryPage({
    context,
    parentPath,
    pageToken,
    limit,
  }) {
    let response;
    try {
      response = await listCollectionIdsPage({
        parentPath,
        pageSize: limit,
        pageToken,
      });
    } catch {
      throw adapterFailure("deletion-discovery-failed");
    }
    const collectionPaths = collectionPathsFromPage(
      context,
      parentPath,
      response,
      limit,
    );
    const nextPageToken = opaquePageToken(response.nextPageToken);
    if (nextPageToken !== null && nextPageToken === pageToken) {
      throw adapterFailure("invalid-discovery-page");
    }
    return { collectionPaths, nextPageToken };
  }

  async function captureCommunityTargets({
    uid,
    operationId,
    workerFence,
  }) {
    const context = refs({ uid, operationId });
    const fence = validatedFence(workerFence);
    return runFencedTransaction(context, fence, async (
      transaction,
      marker,
    ) => {
      const user = await transaction.get(context.rootRef);
      const cleanupGyeIds = normalizeGyeIds([
        ...normalizeGyeIds(marker.cleanupGyeIds),
        ...normalizeGyeIds(user.exists ? (user.data() || {}).gyeIds : []),
      ]);
      transaction.set(
        context.markerRef,
        { cleanupGyeIds },
        { merge: true },
      );
      return cleanupGyeIds;
    });
  }

  async function markerState(context) {
    const snapshot = await context.markerRef.get();
    const marker = requireOwnedMarker(snapshot, context);
    return rootDiscovery(marker, context.operationId);
  }

  async function persistRootDiscoveryPage({
    context,
    fence,
    state,
    collectionPaths,
    nextPageToken,
  }) {
    return runFencedTransaction(context, fence, async (
      transaction,
      marker,
    ) => {
      const current = rootDiscovery(marker, context.operationId);
      if (!sameDiscovery(current, state)) {
        throw adapterFailure("stale-deletion-work");
      }
      const work = [];
      for (const collectionPath of collectionPaths) {
        const ref = context.workCollection.doc(
          workId(context.operationId, collectionPath),
        );
        work.push({ ref, snapshot: await transaction.get(ref), collectionPath });
      }
      for (const item of work) {
        if (!item.snapshot.exists) {
          transaction.set(
            item.ref,
            newWork(context, item.collectionPath),
          );
        } else {
          validateWorkSnapshot(item.snapshot, context);
          if (state.mode === DISCOVERY_LATE) {
            transaction.set(item.ref, {
              state: "pending",
              lastDocumentId: null,
              activeDocumentId: null,
              discoveryPageToken: null,
            }, { merge: true });
          }
        }
      }
      const mode = nextPageToken !== null
        ? state.mode
        : state.mode === DISCOVERY_INITIAL
          ? DISCOVERY_INITIAL_COMPLETE
          : DISCOVERY_LATE_COMPLETE;
      transaction.set(context.markerRef, {
        userTreeDiscovery: {
          operationId: context.operationId,
          mode,
          pageToken: nextPageToken,
        },
      }, { merge: true });
    });
  }

  async function processRootDiscoveryPage(context, fence, state, limit) {
    if (state.mode !== DISCOVERY_INITIAL &&
        state.mode !== DISCOVERY_LATE) {
      return false;
    }
    const page = await safeDiscoveryPage({
      context,
      parentPath: context.rootRef.path,
      pageToken: state.pageToken,
      limit,
    });
    await persistRootDiscoveryPage({
      context,
      fence,
      state,
      collectionPaths: page.collectionPaths,
      nextPageToken: page.nextPageToken,
    });
    return true;
  }

  async function nextPendingWork(context) {
    const snapshot = await context.workCollection
      .where("operationId", "==", context.operationId)
      .where("state", "==", "pending")
      .limit(1)
      .get();
    if (snapshot.docs.length === 0) return null;
    const document = snapshot.docs[0];
    return {
      ref: document.ref,
      data: validateWorkSnapshot(document, context),
    };
  }

  async function nextParentDocument(context, job) {
    const collection = firestore.collection(job.data.collectionPath);
    if (job.data.activeDocumentId !== null) {
      const ref = collection.doc(job.data.activeDocumentId);
      return {
        id: job.data.activeDocumentId,
        ref,
        snapshot: await ref.get(),
      };
    }
    let query = collection.orderBy("__name__");
    if (job.data.lastDocumentId !== null) {
      query = query.startAfter(job.data.lastDocumentId);
    }
    const snapshot = await query.limit(1).get();
    if (snapshot.docs.length === 0) return null;
    const document = snapshot.docs[0];
    return {
      id: document.id,
      ref: document.ref,
      snapshot: document,
    };
  }

  function sameJobProgress(current, expected) {
    return current.state === expected.state &&
      current.lastDocumentId === expected.lastDocumentId &&
      current.activeDocumentId === expected.activeDocumentId &&
      current.discoveryPageToken === expected.discoveryPageToken;
  }

  async function completeEmptyCollection(context, fence, job) {
    await runFencedTransaction(context, fence, async (transaction) => {
      const currentSnapshot = await transaction.get(job.ref);
      if (!currentSnapshot.exists) {
        throw adapterFailure("stale-deletion-work");
      }
      const current = validateWorkSnapshot(currentSnapshot, context);
      if (!sameJobProgress(current, job.data)) {
        throw adapterFailure("stale-deletion-work");
      }
      transaction.set(job.ref, {
        state: "complete",
        activeDocumentId: null,
        discoveryPageToken: null,
      }, { merge: true });
    });
  }

  async function persistChildDiscoveryPage({
    context,
    fence,
    job,
    parent,
    collectionPaths,
    nextPageToken,
  }) {
    await runFencedTransaction(context, fence, async (transaction) => {
      const currentSnapshot = await transaction.get(job.ref);
      if (!currentSnapshot.exists) {
        throw adapterFailure("stale-deletion-work");
      }
      const current = validateWorkSnapshot(currentSnapshot, context);
      if (!sameJobProgress(current, job.data)) {
        throw adapterFailure("stale-deletion-work");
      }
      const children = [];
      for (const collectionPath of collectionPaths) {
        const ref = context.workCollection.doc(
          workId(context.operationId, collectionPath),
        );
        children.push({
          ref,
          snapshot: await transaction.get(ref),
          collectionPath,
        });
      }
      for (const child of children) {
        if (!child.snapshot.exists) {
          transaction.set(
            child.ref,
            newWork(context, child.collectionPath),
          );
        } else {
          validateWorkSnapshot(child.snapshot, context);
        }
      }
      if (nextPageToken !== null) {
        transaction.set(job.ref, {
          activeDocumentId: parent.id,
          discoveryPageToken: nextPageToken,
        }, { merge: true });
        return;
      }
      transaction.delete(parent.ref);
      transaction.set(job.ref, {
        state: "pending",
        lastDocumentId: parent.id,
        activeDocumentId: null,
        discoveryPageToken: null,
      }, { merge: true });
    });
  }

  async function processCollectionWork(context, fence, job, limit) {
    const parent = await nextParentDocument(context, job);
    if (!parent) {
      await completeEmptyCollection(context, fence, job);
      return;
    }
    const parentPath = normalizedDocumentPath(parent.ref.path, context.uid);
    const page = await safeDiscoveryPage({
      context,
      parentPath,
      pageToken: job.data.discoveryPageToken,
      limit,
    });
    await persistChildDiscoveryPage({
      context,
      fence,
      job,
      parent,
      collectionPaths: page.collectionPaths,
      nextPageToken: page.nextPageToken,
    });
  }

  async function startLateDiscovery(context, fence, expectedState) {
    await runFencedTransaction(context, fence, async (
      transaction,
      marker,
    ) => {
      const current = rootDiscovery(marker, context.operationId);
      if (!sameDiscovery(current, expectedState) ||
          current.mode !== DISCOVERY_INITIAL_COMPLETE) {
        throw adapterFailure("stale-deletion-work");
      }
      transaction.set(context.markerRef, {
        userTreeDiscovery: {
          operationId: context.operationId,
          mode: DISCOVERY_LATE,
          pageToken: null,
        },
      }, { merge: true });
    });
  }

  async function deleteRootAndCleanupReceipts({
    context,
    fence,
    expectedState,
    limit,
  }) {
    const work = await context.workCollection
      .where("operationId", "==", context.operationId)
      .limit(limit + 1)
      .get();
    const page = work.docs.slice(0, limit);
    for (const document of page) {
      validateWorkSnapshot(document, context);
    }
    await runFencedTransaction(context, fence, async (
      transaction,
      marker,
    ) => {
      const current = rootDiscovery(marker, context.operationId);
      if (!sameDiscovery(current, expectedState) ||
          current.mode !== DISCOVERY_LATE_COMPLETE) {
        throw adapterFailure("stale-deletion-work");
      }
      transaction.delete(context.rootRef);
      for (const document of page) {
        transaction.delete(document.ref);
      }
      transaction.set(context.markerRef, {
        userTreeRootDeletedOperationId: context.operationId,
      }, { merge: true });
    });
    return work.docs.length <= limit;
  }

  async function deleteUserTreePage({
    uid,
    operationId,
    cursor,
    limit,
    workerFence,
  }) {
    if (cursor !== null && cursor !== undefined && cursor !== WORK_CURSOR) {
      throw adapterFailure("invalid-deletion-cursor");
    }
    const boundedLimit = effectivePageLimit(limit, pageSize);
    const context = refs({ uid, operationId });
    const fence = validatedFence(workerFence);
    await captureCommunityTargets({
      uid: context.uid,
      operationId: context.operationId,
      workerFence: fence,
    });

    let state = await markerState(context);
    if (await processRootDiscoveryPage(
      context,
      fence,
      state,
      boundedLimit,
    )) {
      return { done: false, nextCursor: WORK_CURSOR };
    }

    const pending = await nextPendingWork(context);
    if (pending) {
      await processCollectionWork(
        context,
        fence,
        pending,
        boundedLimit,
      );
      return { done: false, nextCursor: WORK_CURSOR };
    }

    state = await markerState(context);
    if (state.mode === DISCOVERY_INITIAL_COMPLETE) {
      await startLateDiscovery(context, fence, state);
      return { done: false, nextCursor: WORK_CURSOR };
    }
    if (state.mode !== DISCOVERY_LATE_COMPLETE) {
      throw adapterFailure("invalid-deletion-work");
    }

    const done = await deleteRootAndCleanupReceipts({
      context,
      fence,
      expectedState: state,
      limit: boundedLimit,
    });
    return {
      done,
      nextCursor: done ? null : WORK_CURSOR,
    };
  }

  return Object.freeze({
    captureCommunityTargets,
    deleteUserTreePage,
  });
}

module.exports = {
  createFirestoreDeletionAdapters,
  createGapicCollectionIdPager,
};
