"use strict";

const {
  buildDeletionCleanupTargetClaim,
  deletionCleanupTargetClaimMatches,
} = require("./runtime");

const DEFAULT_PAGE_SIZE = 200;
const MAX_PAGE_SIZE = 400;

function cleanupFailure(code) {
  const error = new Error("Account deletion cleanup rejected unsafe state.");
  error.code = code;
  return error;
}

function requiredIdentifier(value, code) {
  if (typeof value !== "string" ||
      value.length < 1 ||
      value !== value.trim() ||
      Buffer.byteLength(value, "utf8") > 1_500 ||
      value === "." ||
      value === ".." ||
      value.includes("/")) {
    throw cleanupFailure(code);
  }
  return value;
}

function normalizeGyeIds(values) {
  if (!Array.isArray(values)) return [];
  const normalized = [];
  for (const value of values) {
    try {
      normalized.push(requiredIdentifier(value, "invalid-gye-id"));
    } catch {
      // Historical malformed cache entries are excluded from server cleanup.
    }
  }
  return Array.from(new Set(normalized)).sort();
}

function boundedPageSize(value) {
  if (!Number.isInteger(value) || value < 1) {
    throw new TypeError("A positive cleanup page size is required.");
  }
  return Math.min(value, MAX_PAGE_SIZE);
}

function gyeIdFromDocument(document, collectionId) {
  const path = document?.ref?.path;
  if (typeof path !== "string") return null;
  const segments = path.split("/");
  if (segments.length !== 4 ||
      segments[0] !== "gye" ||
      segments[2] !== collectionId) {
    return null;
  }
  try {
    return requiredIdentifier(segments[1], "invalid-gye-id");
  } catch {
    return null;
  }
}

async function visitBoundedQuery({
  query,
  documentIdFieldPath,
  pageSize,
  visit,
}) {
  let cursor = null;
  while (true) {
    let pageQuery = query
      .orderBy(documentIdFieldPath)
      .limit(pageSize);
    if (cursor) pageQuery = pageQuery.startAfter(cursor);
    const page = await pageQuery.get();
    if (page.empty) return;
    await visit(page.docs);
    if (page.docs.length < pageSize) return;
    cursor = page.docs.at(-1);
  }
}

function createDeletionCleanupAdapters({
  firestore,
  fieldValue,
  documentIdFieldPath,
  cleanupGyeForDeletedUser,
  anonymizeGyeIdentity,
  reconcileMembershipAfterDeletion,
  cleanupOrphanedGyeTree,
  notificationOutboxBelongsToUid,
  commitDocumentChunks,
  pageSize = DEFAULT_PAGE_SIZE,
} = {}) {
  if (!firestore ||
      typeof firestore.collection !== "function" ||
      typeof firestore.collectionGroup !== "function" ||
      typeof firestore.runTransaction !== "function" ||
      !fieldValue ||
      typeof fieldValue.delete !== "function" ||
      typeof fieldValue.serverTimestamp !== "function" ||
      documentIdFieldPath === undefined ||
      typeof cleanupGyeForDeletedUser !== "function" ||
      typeof anonymizeGyeIdentity !== "function" ||
      typeof reconcileMembershipAfterDeletion !== "function" ||
      typeof cleanupOrphanedGyeTree !== "function" ||
      typeof notificationOutboxBelongsToUid !== "function" ||
      typeof commitDocumentChunks !== "function") {
    throw new TypeError("Complete deletion cleanup dependencies are required.");
  }
  const limit = boundedPageSize(pageSize);

  async function requireCleanupMarker({ uid, operationId }) {
    const markerRef = firestore.collection("account_deletions").doc(uid);
    const marker = await markerRef.get();
    if (!marker.exists) throw cleanupFailure("cleanup-marker-missing");
    const data = marker.data() || {};
    if (data.serverOwned === true && data.operationId !== operationId) {
      throw cleanupFailure("cleanup-operation-mismatch");
    }
    return { markerRef, data };
  }

  async function discoverCommunityTargets(uid) {
    const gyeIds = new Set();
    const departureNicknames = new Map();
    const collectionGroups = [
      "members",
      "departures",
      "bans",
      "processed_packs",
      "notification_outbox",
    ];
    for (const collectionId of collectionGroups) {
      const query = firestore
        .collectionGroup(collectionId)
        .where("uid", "==", uid);
      await visitBoundedQuery({
        query,
        documentIdFieldPath,
        pageSize: limit,
        visit: async (documents) => {
          for (const document of documents) {
            const data = document.data() || {};
            if (data.uid !== uid) continue;
            if (collectionId === "notification_outbox" &&
                !notificationOutboxBelongsToUid(data, uid)) {
              continue;
            }
            const gyeId = gyeIdFromDocument(document, collectionId);
            if (!gyeId) continue;
            gyeIds.add(gyeId);
            if (collectionId === "departures") {
              departureNicknames.set(
                gyeId,
                typeof data.nickname === "string" ? data.nickname : "",
              );
            }
          }
        },
      });
    }
    return { gyeIds: Array.from(gyeIds), departureNicknames };
  }

  async function cleanupCommunity({ uid, operationId } = {}) {
    const sourceUid = requiredIdentifier(uid, "cleanup-uid-required");
    const operation = requiredIdentifier(
      operationId,
      "cleanup-operation-required",
    );
    const { markerRef } = await requireCleanupMarker({
      uid: sourceUid,
      operationId: operation,
    });
    const discovered = await discoverCommunityTargets(sourceUid);
    const cleanupClaim = await firestore.runTransaction(
      async (transaction) => {
        const marker = await transaction.get(markerRef);
        if (!marker.exists) throw cleanupFailure("cleanup-marker-missing");
        const current = marker.data() || {};
        if (current.serverOwned === true &&
            current.operationId !== operation) {
          throw cleanupFailure("cleanup-operation-mismatch");
        }
        if (current.cleanupComplete === true) return null;
        const claim = buildDeletionCleanupTargetClaim({
          retainedGyeIds: normalizeGyeIds(current.cleanupGyeIds),
          discoveredGyeIds: normalizeGyeIds(discovered.gyeIds),
          currentRevision: current.cleanupRevision,
        });
        transaction.update(markerRef, {
          cleanupGyeIds: claim.gyeIds,
          cleanupRevision: claim.revision,
        });
        return claim;
      },
    );
    if (!cleanupClaim) return null;

    for (const gyeId of cleanupClaim.gyeIds) {
      const gref = firestore.collection("gye").doc(gyeId);
      const member = await gref
        .collection("members")
        .doc(sourceUid)
        .get();
      const nickname = (member.data() || {}).nickname ||
        discovered.departureNicknames.get(gyeId) || "";
      await cleanupGyeForDeletedUser({
        anonymizeIdentity: () =>
          anonymizeGyeIdentity(gyeId, sourceUid, nickname),
        reconcileMembership: () =>
          reconcileMembershipAfterDeletion(gyeId, sourceUid),
        cleanupOrphanTree: () =>
          cleanupOrphanedGyeTree(gref, gyeId),
      });
      await gref.collection("bans").doc(sourceUid).delete();
      await gref.collection("departures").doc(sourceUid).delete();
    }
    return cleanupClaim;
  }

  async function deleteOwnedQuery(query, belongsToSource) {
    while (true) {
      const page = await query.limit(limit).get();
      if (page.empty) return;
      const owned = page.docs.filter((document) =>
        belongsToSource(document.data() || {}));
      if (owned.length === 0) return;
      await commitDocumentChunks(
        owned,
        (batch, document) => batch.delete(document.ref),
      );
      if (page.docs.length < limit) return;
    }
  }

  async function cleanupProcessor({ uid, operationId } = {}) {
    const sourceUid = requiredIdentifier(uid, "cleanup-uid-required");
    const operation = requiredIdentifier(
      operationId,
      "cleanup-operation-required",
    );
    await requireCleanupMarker({
      uid: sourceUid,
      operationId: operation,
    });
    await deleteOwnedQuery(
      firestore
        .collection("shared_packs")
        .where("createdBy", "==", sourceUid),
      (data) => data.createdBy === sourceUid,
    );
    await deleteOwnedQuery(
      firestore
        .collectionGroup("processed_packs")
        .where("uid", "==", sourceUid),
      (data) => data.uid === sourceUid,
    );
    await deleteOwnedQuery(
      firestore
        .collectionGroup("notification_outbox")
        .where("uid", "==", sourceUid),
      (data) => notificationOutboxBelongsToUid(data, sourceUid),
    );
  }

  return Object.freeze({
    cleanupCommunity,
    cleanupProcessor,
  });
}

function createLegacyUserDeletionCleanupHandler({
  firestore,
  fieldValue,
  cleanupAdapters,
} = {}) {
  if (!firestore ||
      typeof firestore.collection !== "function" ||
      typeof firestore.runTransaction !== "function" ||
      !fieldValue ||
      typeof fieldValue.delete !== "function" ||
      typeof fieldValue.serverTimestamp !== "function" ||
      !cleanupAdapters ||
      typeof cleanupAdapters.cleanupCommunity !== "function" ||
      typeof cleanupAdapters.cleanupProcessor !== "function") {
    throw new TypeError("Complete legacy cleanup dependencies are required.");
  }

  return async function handleLegacyUserDeletion({ uid, before } = {}) {
    const sourceUid = requiredIdentifier(uid, "cleanup-uid-required");
    const markerRef = firestore.collection("account_deletions").doc(sourceUid);
    const initialClaim = await firestore.runTransaction(
      async (transaction) => {
        const marker = await transaction.get(markerRef);
        const current = marker.exists ? marker.data() || {} : {};
        if (current.serverOwned === true) return "server-owned";
        if (current.cleanupComplete === true) return "complete";
        const claim = buildDeletionCleanupTargetClaim({
          retainedGyeIds: normalizeGyeIds(current.cleanupGyeIds),
          discoveredGyeIds: normalizeGyeIds(before?.gyeIds),
          currentRevision: current.cleanupRevision,
        });
        const fields = {
          cleanupGyeIds: claim.gyeIds,
          cleanupRevision: claim.revision,
        };
        if (marker.exists) {
          transaction.update(markerRef, fields);
        } else {
          transaction.set(markerRef, {
            state: "active",
            createdAt: fieldValue.serverTimestamp(),
            ...fields,
          });
        }
        return claim;
      },
    );
    if (initialClaim === "server-owned") {
      return { status: "server-owned" };
    }
    if (initialClaim === "complete") return { status: "complete" };

    const operationId = `legacy-${sourceUid}`;
    const cleanupClaim = await cleanupAdapters.cleanupCommunity({
      uid: sourceUid,
      operationId,
    });
    if (!cleanupClaim) return { status: "complete" };
    await cleanupAdapters.cleanupProcessor({
      uid: sourceUid,
      operationId,
    });
    await firestore.runTransaction(async (transaction) => {
      const marker = await transaction.get(markerRef);
      const current = marker.exists ? marker.data() || {} : {};
      if (current.serverOwned === true ||
          !deletionCleanupTargetClaimMatches(current, cleanupClaim)) {
        throw cleanupFailure("cleanup-targets-changed");
      }
      transaction.update(markerRef, {
        cleanupComplete: true,
        cleanupCompletedAt: fieldValue.serverTimestamp(),
        authMissingSince: fieldValue.delete(),
        cleanupGyeIds: fieldValue.delete(),
        cleanupRevision: fieldValue.delete(),
      });
    });
    return { status: "cleaned" };
  };
}

module.exports = {
  createDeletionCleanupAdapters,
  createLegacyUserDeletionCleanupHandler,
};
