"use strict";

const crypto = require("node:crypto");
const {
  buildDeletionCleanupTargetClaim,
} = require("./runtime");

const DEFAULT_PAGE_SIZE = 200;
const MAX_PAGE_SIZE = 400;
const COMMUNITY_COLLECTIONS = Object.freeze([
  "members",
  "departures",
  "bans",
  "decor_dedications",
  "decor_dedication_mutations",
  "processed_packs",
  "notification_outbox",
]);
const DEDICATION_COLLECTIONS = new Set([
  "decor_dedications",
  "decor_dedication_mutations",
]);
const LEGACY_INVOCATION_STEP_BUDGET = 32;

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

function dedicationIdentity(data) {
  if (!data || typeof data.membershipId !== "string" ||
      data.membershipId.length < 16 || data.membershipId.length > 64 ||
      data.membershipId !== data.membershipId.trim() ||
      data.membershipId.includes("/") ||
      !Number.isSafeInteger(data.joinedAtSeconds) ||
      data.joinedAtSeconds < 0 ||
      !Number.isSafeInteger(data.joinedAtNanos) ||
      data.joinedAtNanos < 0 || data.joinedAtNanos >= 1000000000) {
    return null;
  }
  return {
    membershipId: data.membershipId,
    joinedAtSeconds: data.joinedAtSeconds,
    joinedAtNanos: data.joinedAtNanos,
  };
}

function validWorkerFence(value) {
  return value &&
    typeof value.workerId === "string" &&
    value.workerId.length > 0 &&
    Number.isInteger(value.operationVersion) &&
    value.operationVersion >= 0 &&
    Number.isInteger(value.leaseVersion) &&
    value.leaseVersion >= 1;
}

function createDeletionCleanupAdapters({
  firestore,
  fieldValue,
  documentIdFieldPath,
  cleanupGyeForDeletedUserPage,
  notificationOutboxBelongsToUid,
  nowMillis = () => Date.now(),
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
      typeof cleanupGyeForDeletedUserPage !== "function" ||
      typeof notificationOutboxBelongsToUid !== "function" ||
      typeof nowMillis !== "function") {
    throw new TypeError("Complete deletion cleanup dependencies are required.");
  }
  const limit = boundedPageSize(pageSize);

  function markerRefFor(uid) {
    return firestore.collection("account_deletions").doc(uid);
  }

  function targetCollectionFor(uid) {
    return markerRefFor(uid).collection("cleanup_targets");
  }

  function assertDeadline(deadlineMillis) {
    if (deadlineMillis !== undefined &&
        (!Number.isFinite(deadlineMillis) ||
          deadlineMillis < 0 ||
          nowMillis() >= deadlineMillis)) {
      throw cleanupFailure("cleanup-deadline-exceeded");
    }
  }

  function assertMarkerScope({
    marker,
    operationId,
    workerFence,
    legacyGeneration,
  }) {
    if (!marker.exists) throw cleanupFailure("cleanup-marker-missing");
    const data = marker.data() || {};
    if (data.serverOwned === true) {
      if (data.operationId !== operationId) {
        throw cleanupFailure("cleanup-operation-mismatch");
      }
      if (!validWorkerFence(workerFence)) {
        throw cleanupFailure("stale-worker-lease");
      }
    } else if (typeof legacyGeneration !== "string" ||
        legacyGeneration.length === 0 ||
        data.legacyCleanupGeneration !== legacyGeneration) {
      throw cleanupFailure("stale-legacy-cleanup");
    }
    return data;
  }

  async function assertActiveFence({
    transaction,
    marker,
    uid,
    operationId,
    workerFence,
    legacyGeneration,
  }) {
    const markerData = assertMarkerScope({
      marker,
      operationId,
      workerFence,
      legacyGeneration,
    });
    if (markerData.serverOwned !== true) return markerData;

    const operationRef = firestore
      .collection("account_operations")
      .doc(operationId);
    const operation = await transaction.get(operationRef);
    const data = operation.exists ? operation.data() || {} : {};
    const lease = data.workerLease || {};
    if (!operation.exists ||
        data.sourceUid !== uid ||
        data.version !== workerFence.operationVersion ||
        lease.workerId !== workerFence.workerId ||
        lease.leaseVersion !== workerFence.leaseVersion ||
        !Number.isFinite(lease.leaseUntilMillis) ||
        lease.leaseUntilMillis <= nowMillis()) {
      throw cleanupFailure("stale-worker-lease");
    }
    return markerData;
  }

  async function fencedTransaction({
    uid,
    operationId,
    workerFence,
    legacyGeneration,
    deadlineMillis,
    run,
  }) {
    assertDeadline(deadlineMillis);
    const markerRef = markerRefFor(uid);
    return firestore.runTransaction(async (transaction) => {
      const marker = await transaction.get(markerRef);
      const markerData = await assertActiveFence({
        transaction,
        marker,
        uid,
        operationId,
        workerFence,
        legacyGeneration,
      });
      assertDeadline(deadlineMillis);
      return run({ transaction, markerRef, markerData });
    });
  }

  async function ensureCommunityState({
    uid,
    operationId,
    workerFence,
    legacyGeneration,
    deadlineMillis,
  }) {
    return fencedTransaction({
      uid,
      operationId,
      workerFence,
      legacyGeneration,
      deadlineMillis,
      run: async ({ transaction, markerRef, markerData }) => {
        const current = markerData.communityCleanupState;
        if (current?.operationId === operationId) return current;

        const retainedGyeIds = normalizeGyeIds(markerData.cleanupGyeIds);
        for (const gyeId of retainedGyeIds) {
          transaction.set(
            targetCollectionFor(uid).doc(gyeId),
            { operationId, gyeId },
            { merge: true },
          );
        }
        const state = {
          operationId,
          collectionIndex: 0,
          cursor: null,
          discoveryComplete: false,
          done: false,
        };
        transaction.update(markerRef, {
          communityCleanupState: state,
          cleanupGyeIds: fieldValue.delete(),
          cleanupRevision: fieldValue.delete(),
        });
        return state;
      },
    });
  }

  async function discoverCommunityPage({
    uid,
    operationId,
    workerFence,
    legacyGeneration,
    deadlineMillis,
    state,
  }) {
    const collectionId = COMMUNITY_COLLECTIONS[state.collectionIndex];
    let query = firestore
      .collectionGroup(collectionId)
      .where("uid", "==", uid)
      .orderBy(documentIdFieldPath)
      .limit(limit);
    if (typeof state.cursor === "string" && state.cursor.length > 0) {
      query = query.startAfter(state.cursor);
    }
    const page = await query.get();
    assertDeadline(deadlineMillis);

    return fencedTransaction({
      uid,
      operationId,
      workerFence,
      legacyGeneration,
      deadlineMillis,
      run: async ({ transaction, markerRef, markerData }) => {
        const current = markerData.communityCleanupState;
        if (current?.operationId !== operationId ||
            current.collectionIndex !== state.collectionIndex ||
            (current.cursor || null) !== (state.cursor || null)) {
          throw cleanupFailure("cleanup-progress-changed");
        }

        const dedicationDocuments = page.docs.filter((document) =>
          DEDICATION_COLLECTIONS.has(collectionId) &&
          dedicationIdentity(document.data() || {}) !== null,
        );
        const currentDedications = dedicationDocuments.length === 0
          ? []
          : await transaction.getAll(
            ...dedicationDocuments.map((document) => document.ref),
          );
        const currentDedicationByPath = new Map(currentDedications.map(
          (document) => [document.ref.path, document],
        ));

        for (const document of page.docs) {
          const data = document.data() || {};
          if (data.uid !== uid ||
              (collectionId === "notification_outbox" &&
                !notificationOutboxBelongsToUid(data, uid))) {
            continue;
          }
          const gyeId = gyeIdFromDocument(document, collectionId);
          if (!gyeId) continue;
          transaction.set(
            targetCollectionFor(uid).doc(gyeId),
            {
              operationId,
              gyeId,
              ...(collectionId === "departures" &&
                typeof data.nickname === "string"
                ? { departureNickname: data.nickname }
                : {}),
            },
            { merge: true },
          );
          if (!DEDICATION_COLLECTIONS.has(collectionId)) continue;
          const expectedIdentity = dedicationIdentity(data);
          const current = currentDedicationByPath.get(document.ref.path);
          const currentData = current?.exists ? current.data() || {} : null;
          if (expectedIdentity !== null && currentData?.uid === uid &&
              currentData.membershipId === expectedIdentity.membershipId &&
              currentData.joinedAtSeconds === expectedIdentity.joinedAtSeconds &&
              currentData.joinedAtNanos === expectedIdentity.joinedAtNanos) {
            transaction.delete(document.ref);
          }
        }

        const pageComplete = page.docs.length < limit;
        const nextState = {
          ...current,
          collectionIndex: pageComplete
            ? state.collectionIndex + 1
            : state.collectionIndex,
          cursor: pageComplete ? null : page.docs.at(-1).ref.path,
        };
        transaction.update(markerRef, {
          communityCleanupState: nextState,
        });
        return { done: false };
      },
    });
  }

  async function finishCommunityDiscovery({
    uid,
    operationId,
    workerFence,
    legacyGeneration,
    deadlineMillis,
  }) {
    return fencedTransaction({
      uid,
      operationId,
      workerFence,
      legacyGeneration,
      deadlineMillis,
      run: async ({ transaction, markerRef, markerData }) => {
        const current = markerData.communityCleanupState;
        if (current?.operationId !== operationId) {
          throw cleanupFailure("cleanup-progress-changed");
        }
        transaction.update(markerRef, {
          communityCleanupState: {
            ...current,
            discoveryComplete: true,
          },
        });
        return { done: false };
      },
    });
  }

  async function nextCommunityTarget(uid) {
    return targetCollectionFor(uid)
      .orderBy(documentIdFieldPath)
      .limit(1)
      .get();
  }

  async function processCommunityTarget({
    uid,
    operationId,
    workerFence,
    legacyGeneration,
    deadlineMillis,
    target,
  }) {
    const targetRef = target.ref;
    const targetData = await fencedTransaction({
      uid,
      operationId,
      workerFence,
      legacyGeneration,
      deadlineMillis,
      run: async ({ transaction }) => {
        const currentTarget = await transaction.get(targetRef);
        const data = currentTarget.exists ? currentTarget.data() || {} : {};
        if (!currentTarget.exists) {
          return null;
        }
        return data;
      },
    });
    if (!targetData) return { done: false };

    const gyeId = requiredIdentifier(targetData.gyeId, "invalid-gye-id");
    const gref = firestore.collection("gye").doc(gyeId);
    const member = await gref.collection("members").doc(uid).get();
    const nickname = (member.data() || {}).nickname ||
      targetData.departureNickname || "";
    assertDeadline(deadlineMillis);
    const page = await cleanupGyeForDeletedUserPage({
      firestore,
      targetRef,
      targetData,
      gref,
      gyeId,
      uid,
      nickname,
      operationId,
      workerFence,
      legacyGeneration,
      deadlineMillis,
      pageSize: limit,
      runFencedTransaction: (run) => fencedTransaction({
        uid,
        operationId,
        workerFence,
        legacyGeneration,
        deadlineMillis,
        run,
      }),
    });
    assertDeadline(deadlineMillis);
    if (!page || typeof page.done !== "boolean") {
      throw cleanupFailure("invalid-gye-cleanup-page");
    }
    if (!page.done) return { done: false };

    return fencedTransaction({
      uid,
      operationId,
      workerFence,
      legacyGeneration,
      deadlineMillis,
      run: async ({ transaction }) => {
        const currentTarget = await transaction.get(targetRef);
        if (currentTarget.exists) {
          transaction.delete(gref.collection("bans").doc(uid));
          transaction.delete(gref.collection("departures").doc(uid));
          transaction.delete(targetRef);
        }
        return { done: false };
      },
    });
  }

  async function markCommunityDone({
    uid,
    operationId,
    workerFence,
    legacyGeneration,
    deadlineMillis,
  }) {
    return fencedTransaction({
      uid,
      operationId,
      workerFence,
      legacyGeneration,
      deadlineMillis,
      run: async ({ transaction, markerRef, markerData }) => {
        const state = markerData.communityCleanupState;
        if (state?.operationId !== operationId ||
            state.discoveryComplete !== true) {
          throw cleanupFailure("cleanup-progress-changed");
        }
        transaction.update(markerRef, {
          communityCleanupState: { ...state, done: true },
        });
        return { done: true };
      },
    });
  }

  async function cleanupCommunity({
    uid,
    operationId,
    workerFence,
    legacyGeneration,
    deadlineMillis,
  } = {}) {
    const sourceUid = requiredIdentifier(uid, "cleanup-uid-required");
    const operation = requiredIdentifier(
      operationId,
      "cleanup-operation-required",
    );
    assertDeadline(deadlineMillis);
    const state = await ensureCommunityState({
      uid: sourceUid,
      operationId: operation,
      workerFence,
      legacyGeneration,
      deadlineMillis,
    });
    if (state.done === true) return { done: true };
    if (state.discoveryComplete !== true) {
      if (state.collectionIndex < COMMUNITY_COLLECTIONS.length) {
        return discoverCommunityPage({
          uid: sourceUid,
          operationId: operation,
          workerFence,
          legacyGeneration,
          deadlineMillis,
          state,
        });
      }
      return finishCommunityDiscovery({
        uid: sourceUid,
        operationId: operation,
        workerFence,
        legacyGeneration,
        deadlineMillis,
      });
    }

    const targets = await nextCommunityTarget(sourceUid);
    assertDeadline(deadlineMillis);
    if (targets.empty) {
      return markCommunityDone({
        uid: sourceUid,
        operationId: operation,
        workerFence,
        legacyGeneration,
        deadlineMillis,
      });
    }
    return processCommunityTarget({
      uid: sourceUid,
      operationId: operation,
      workerFence,
      legacyGeneration,
      deadlineMillis,
      target: targets.docs[0],
    });
  }

  function processorCategory(index, uid) {
    switch (index) {
      case 0:
        return {
          query: firestore
            .collection("shared_packs")
            .where("createdBy", "==", uid),
          belongs: (data) => data.createdBy === uid,
          cursorFor: (document) => document.id,
        };
      case 1:
        return {
          query: firestore
            .collectionGroup("processed_packs")
            .where("uid", "==", uid),
          belongs: (data) => data.uid === uid,
          cursorFor: (document) => document.ref.path,
        };
      case 2:
        return {
          query: firestore
            .collectionGroup("notification_outbox")
            .where("uid", "==", uid),
          belongs: (data) => notificationOutboxBelongsToUid(data, uid),
          cursorFor: (document) => document.ref.path,
        };
      default:
        return null;
    }
  }

  async function ensureProcessorState({
    uid,
    operationId,
    workerFence,
    legacyGeneration,
    deadlineMillis,
  }) {
    return fencedTransaction({
      uid,
      operationId,
      workerFence,
      legacyGeneration,
      deadlineMillis,
      run: async ({ transaction, markerRef, markerData }) => {
        const current = markerData.processorCleanupState;
        if (current?.operationId === operationId) return current;
        const state = {
          operationId,
          categoryIndex: 0,
          cursor: null,
          done: false,
        };
        transaction.update(markerRef, { processorCleanupState: state });
        return state;
      },
    });
  }

  async function cleanupProcessor({
    uid,
    operationId,
    workerFence,
    legacyGeneration,
    deadlineMillis,
  } = {}) {
    const sourceUid = requiredIdentifier(uid, "cleanup-uid-required");
    const operation = requiredIdentifier(
      operationId,
      "cleanup-operation-required",
    );
    assertDeadline(deadlineMillis);
    const state = await ensureProcessorState({
      uid: sourceUid,
      operationId: operation,
      workerFence,
      legacyGeneration,
      deadlineMillis,
    });
    if (state.done === true) return { done: true };
    const category = processorCategory(state.categoryIndex, sourceUid);
    if (!category) {
      return fencedTransaction({
        uid: sourceUid,
        operationId: operation,
        workerFence,
        legacyGeneration,
        deadlineMillis,
        run: async ({ transaction, markerRef, markerData }) => {
          const current = markerData.processorCleanupState;
          if (current?.operationId !== operation ||
              current.categoryIndex !== state.categoryIndex ||
              (current.cursor || null) !== (state.cursor || null)) {
            throw cleanupFailure("cleanup-progress-changed");
          }
          transaction.update(markerRef, {
            processorCleanupState: { ...current, done: true },
          });
          return { done: true };
        },
      });
    }

    let query = category.query
      .orderBy(documentIdFieldPath)
      .limit(limit);
    if (typeof state.cursor === "string" && state.cursor.length > 0) {
      query = query.startAfter(state.cursor);
    }
    const page = await query.get();
    assertDeadline(deadlineMillis);

    return fencedTransaction({
      uid: sourceUid,
      operationId: operation,
      workerFence,
      legacyGeneration,
      deadlineMillis,
      run: async ({ transaction, markerRef, markerData }) => {
        const current = markerData.processorCleanupState;
        if (current?.operationId !== operation ||
            current.categoryIndex !== state.categoryIndex ||
            (current.cursor || null) !== (state.cursor || null)) {
          throw cleanupFailure("cleanup-progress-changed");
        }
        const currentDocuments = page.docs.length === 0
          ? []
          : await transaction.getAll(
            ...page.docs.map((document) => document.ref),
          );
        for (const document of currentDocuments) {
          if (document.exists &&
              category.belongs(document.data() || {})) {
            transaction.delete(document.ref);
          }
        }
        const pageComplete = page.docs.length < limit;
        const nextCategoryIndex = pageComplete
          ? state.categoryIndex + 1
          : state.categoryIndex;
        const done = nextCategoryIndex >= 3;
        transaction.update(markerRef, {
          processorCleanupState: {
            ...current,
            categoryIndex: nextCategoryIndex,
            cursor: pageComplete
              ? null
              : category.cursorFor(page.docs.at(-1)),
            done,
          },
        });
        return { done };
      },
    });
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
        const legacyGeneration =
          typeof current.legacyCleanupGeneration === "string" &&
          current.legacyCleanupGeneration.length > 0
            ? current.legacyCleanupGeneration
            : crypto.randomUUID();
        const claim = buildDeletionCleanupTargetClaim({
          retainedGyeIds: normalizeGyeIds(current.cleanupGyeIds),
          discoveredGyeIds: normalizeGyeIds(before?.gyeIds),
          currentRevision: current.cleanupRevision,
        });
        const fields = {
          cleanupGyeIds: claim.gyeIds,
          cleanupRevision: claim.revision,
          legacyCleanupGeneration: legacyGeneration,
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
        return { ...claim, legacyGeneration };
      },
    );
    if (initialClaim === "server-owned") {
      return { status: "server-owned" };
    }
    if (initialClaim === "complete") return { status: "complete" };

    const operationId = `legacy-${sourceUid}`;
    const legacyGeneration = initialClaim.legacyGeneration;
    let community = { done: false };
    let processor = { done: false };
    let steps = 0;
    while (!community.done && steps < LEGACY_INVOCATION_STEP_BUDGET) {
      community = await cleanupAdapters.cleanupCommunity({
        uid: sourceUid,
        operationId,
        legacyGeneration,
      });
      steps += 1;
    }
    while (community.done &&
        !processor.done &&
        steps < LEGACY_INVOCATION_STEP_BUDGET) {
      processor = await cleanupAdapters.cleanupProcessor({
        uid: sourceUid,
        operationId,
        legacyGeneration,
      });
      steps += 1;
    }
    if (!community.done || !processor.done) {
      throw cleanupFailure("cleanup-work-pending");
    }

    await firestore.runTransaction(async (transaction) => {
      const marker = await transaction.get(markerRef);
      const current = marker.exists ? marker.data() || {} : {};
      if (current.serverOwned === true ||
          current.legacyCleanupGeneration !== legacyGeneration ||
          current.communityCleanupState?.operationId !== operationId ||
          current.communityCleanupState?.done !== true ||
          current.processorCleanupState?.operationId !== operationId ||
          current.processorCleanupState?.done !== true) {
        throw cleanupFailure("cleanup-targets-changed");
      }
      transaction.update(markerRef, {
        cleanupComplete: true,
        cleanupCompletedAt: fieldValue.serverTimestamp(),
        authMissingSince: fieldValue.delete(),
        cleanupGyeIds: fieldValue.delete(),
        cleanupRevision: fieldValue.delete(),
        legacyCleanupGeneration: fieldValue.delete(),
      });
    });
    return { status: "cleaned" };
  };
}

module.exports = {
  createDeletionCleanupAdapters,
  createLegacyUserDeletionCleanupHandler,
};
