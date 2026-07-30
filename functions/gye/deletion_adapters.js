"use strict";

const crypto = require("node:crypto");

const WORK_COLLECTION = "user_tree_work";
const WORK_CURSOR = "work-v1";
const DEFAULT_PAGE_SIZE = 200;
const MAX_PAGE_SIZE = 200;
const WRITE_BATCH_LIMIT = 400;

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

function chunks(items, size) {
  const result = [];
  for (let index = 0; index < items.length; index += size) {
    result.push(items.slice(index, index + size));
  }
  return result;
}

function createFirestoreDeletionAdapters({
  firestore,
  markerCollection,
  pageSize = DEFAULT_PAGE_SIZE,
} = {}) {
  if (!firestore ||
      typeof firestore.collection !== "function" ||
      typeof firestore.batch !== "function" ||
      !markerCollection ||
      typeof markerCollection.doc !== "function") {
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
      rootRef: firestore.collection("users").doc(safeUid),
      workCollection: markerRef.collection(WORK_COLLECTION),
    };
  }

  async function requireOwnedMarker(context) {
    const snapshot = await context.markerRef.get();
    const marker = snapshot.exists ? snapshot.data() || {} : {};
    if (!snapshot.exists ||
        marker.serverOwned !== true ||
        marker.operationId !== context.operationId ||
        marker.sourceUid !== context.uid) {
      throw adapterFailure("invalid-deletion-marker");
    }
    return marker;
  }

  function validateWorkSnapshot(snapshot, context) {
    const data = snapshot.data() || {};
    const collectionPath = normalizedCollectionPath(
      data.collectionPath,
      context.uid,
    );
    if (snapshot.id !== workId(context.operationId, collectionPath) ||
        data.operationId !== context.operationId ||
        data.uid !== context.uid ||
        !["pending", "complete"].includes(data.state) ||
        (data.lastDocumentId !== null &&
          data.lastDocumentId !== undefined &&
          (typeof data.lastDocumentId !== "string" ||
            data.lastDocumentId.length < 1 ||
            data.lastDocumentId.includes("/")))) {
      throw adapterFailure("invalid-deletion-work");
    }
    return {
      ...data,
      collectionPath,
      lastDocumentId: typeof data.lastDocumentId === "string"
        ? data.lastDocumentId
        : null,
    };
  }

  async function writeBatches(mutations) {
    for (const mutationChunk of chunks(mutations, WRITE_BATCH_LIMIT)) {
      const batch = firestore.batch();
      for (const mutation of mutationChunk) {
        if (mutation.kind === "delete") {
          batch.delete(mutation.ref);
        } else {
          batch.set(mutation.ref, mutation.value, mutation.options);
        }
      }
      await batch.commit();
    }
  }

  async function ensureCollectionWork(context, collectionRefs) {
    const collectionPaths = Array.from(new Set(
      collectionRefs.map((collectionRef) =>
        normalizedCollectionPath(collectionRef.path, context.uid)),
    )).sort();
    const mutations = [];
    for (const collectionPath of collectionPaths) {
      const ref = context.workCollection.doc(
        workId(context.operationId, collectionPath),
      );
      const existing = await ref.get();
      if (existing.exists) {
        validateWorkSnapshot(existing, context);
        continue;
      }
      mutations.push({
        kind: "set",
        ref,
        value: {
          operationId: context.operationId,
          uid: context.uid,
          collectionPath,
          state: "pending",
          lastDocumentId: null,
        },
      });
    }
    await writeBatches(mutations);
  }

  async function captureCommunityTargets({ uid, operationId }) {
    const context = refs({ uid, operationId });
    const marker = await requireOwnedMarker(context);
    const user = await context.rootRef.get();
    const cleanupGyeIds = normalizeGyeIds([
      ...normalizeGyeIds(marker.cleanupGyeIds),
      ...normalizeGyeIds(user.exists ? (user.data() || {}).gyeIds : []),
    ]);
    await context.markerRef.set({ cleanupGyeIds }, { merge: true });
    return cleanupGyeIds;
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

  async function processCollectionPage(context, job, limit) {
    let query = firestore
      .collection(job.data.collectionPath)
      .orderBy("__name__");
    if (job.data.lastDocumentId !== null) {
      query = query.startAfter(job.data.lastDocumentId);
    }
    const snapshot = await query.limit(limit).get();

    for (const document of snapshot.docs) {
      const childCollections = await document.ref.listCollections();
      await ensureCollectionWork(context, childCollections);
      await document.ref.delete();
    }

    const pageFull = snapshot.docs.length === limit;
    const lastDocumentId = pageFull
      ? snapshot.docs.at(-1).id
      : null;
    await job.ref.set({
      state: pageFull ? "pending" : "complete",
      lastDocumentId,
    }, { merge: true });
  }

  async function reopenLateRootWork(context) {
    const rootCollections = await context.rootRef.listCollections();
    let reopened = false;
    for (const collectionRef of rootCollections) {
      const sample = await collectionRef.limit(1).get();
      if (sample.docs.length === 0) continue;
      reopened = true;
      const collectionPath = normalizedCollectionPath(
        collectionRef.path,
        context.uid,
      );
      const ref = context.workCollection.doc(
        workId(context.operationId, collectionPath),
      );
      const existing = await ref.get();
      if (!existing.exists) {
        await ref.set({
          operationId: context.operationId,
          uid: context.uid,
          collectionPath,
          state: "pending",
          lastDocumentId: null,
        });
        continue;
      }
      validateWorkSnapshot(existing, context);
      await ref.set({
        state: "pending",
        lastDocumentId: null,
      }, { merge: true });
    }
    return reopened;
  }

  async function deleteRootAndCleanupReceipts(context, limit) {
    const rootBatch = firestore.batch();
    rootBatch.delete(context.rootRef);
    rootBatch.set(context.markerRef, {
      userTreeRootDeletedOperationId: context.operationId,
    }, { merge: true });
    await rootBatch.commit();

    const work = await context.workCollection
      .where("operationId", "==", context.operationId)
      .limit(limit + 1)
      .get();
    const page = work.docs.slice(0, limit);
    await writeBatches(page.map((document) => ({
      kind: "delete",
      ref: document.ref,
    })));
    return work.docs.length <= limit;
  }

  async function deleteUserTreePage({
    uid,
    operationId,
    cursor,
    limit,
  }) {
    if (cursor !== null && cursor !== undefined && cursor !== WORK_CURSOR) {
      throw adapterFailure("invalid-deletion-cursor");
    }
    const boundedLimit = effectivePageLimit(limit, pageSize);
    const context = refs({ uid, operationId });
    await captureCommunityTargets({
      uid: context.uid,
      operationId: context.operationId,
    });
    await requireOwnedMarker(context);

    const rootCollections = await context.rootRef.listCollections();
    await ensureCollectionWork(context, rootCollections);

    const pending = await nextPendingWork(context);
    if (pending) {
      await processCollectionPage(context, pending, boundedLimit);
      return { done: false, nextCursor: WORK_CURSOR };
    }

    if (await reopenLateRootWork(context)) {
      return { done: false, nextCursor: WORK_CURSOR };
    }

    const done = await deleteRootAndCleanupReceipts(
      context,
      boundedLimit,
    );
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
};
